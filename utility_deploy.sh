#!/bin/bash

# Function to check if a port is available
function check_port {
    local port=$1
    nc -z localhost $port
    return $?
}

# Function to find available ports
function find_available_ports {
    local needed_ports=$1
    local available_ports=()

    for ((port=27000; port<=30000; port++)); do
        if ! check_port $port; then
            available_ports+=($port)
            if [ ${#available_ports[@]} -eq $needed_ports ]; then
                echo "${available_ports[@]}"
                return
            fi
        fi
    done

    echo "Not enough available ports found in the range 27000-30000."
    exit 1
}

# Function to install standalone MongoDB instance
function install_standalone_mongodb {
    local port
    port=$(find_available_ports 1)

    # Create directory for MongoDB installation
    mkdir -p ~/mongodb-standalone
    cd ~/mongodb-standalone

    # Copy MongoDB binaries from another location on the host
    cp -r /path/to/other/location/mongodb-binaries ~/mongodb

    # Create data and log directories
    mkdir -p ~/mongodb-standalone/data
    mkdir -p ~/mongodb-standalone/logs

    # Start MongoDB instance
    ~/mongodb/bin/mongod --port $port --dbpath ~/mongodb-standalone/data --logpath ~/mongodb-standalone/logs/mongod.log --fork --pidfilepath ~/mongodb-standalone/mongod.pid --bind_ip 127.0.0.1,0.0.0.0

    echo "Standalone MongoDB instance installed successfully."
    echo "Connection String: mongodb://<your-ip>:$port"
}

# Function to install MongoDB replica set
function install_replica_set {
    local ports
    ports=($(find_available_ports 3))
    local port1=${ports[0]}
    local port2=${ports[1]}
    local port3=${ports[2]}

    # Create directory for MongoDB installation
    mkdir -p ~/mongodb-replica-set
    cd ~/mongodb-replica-set

    # Copy MongoDB binaries from another location on the host
    cp -r /path/to/other/location/mongodb-binaries ~/mongodb

    # Create data and log directories
    mkdir -p ~/mongodb-replica-set/data-{1,2,3}
    mkdir -p ~/mongodb-replica-set/logs

    # Start MongoDB instances
    ~/mongodb/bin/mongod --port $port1 --dbpath ~/mongodb-replica-set/data-1 --logpath ~/mongodb-replica-set/logs/mongod1.log --fork --pidfilepath ~/mongodb-replica-set/mongod1.pid --bind_ip 127.0.0.1,0.0.0.0 --replSet rs0
    ~/mongodb/bin/mongod --port $port2 --dbpath ~/mongodb-replica-set/data-2 --logpath ~/mongodb-replica-set/logs/mongod2.log --fork --pidfilepath ~/mongodb-replica-set/mongod2.pid --bind_ip 127.0.0.1,0.0.0.0 --replSet rs0
    ~/mongodb/bin/mongod --port $port3 --dbpath ~/mongodb-replica-set/data-3 --logpath ~/mongodb-replica-set/logs/mongod3.log --fork --pidfilepath ~/mongodb-replica-set/mongod3.pid --bind_ip 127.0.0.1,0.0.0.0 --replSet rs0

    echo "MongoDB replica set installed successfully."
    echo "Connection String: mongodb://<your-ip>:$port1,localhost:$port2,localhost:$port3/?replicaSet=rs0"

    # Initialize the replica set
    sleep 5 # Wait for the instances to start
    ~/mongodb/bin/mongo --port $port1 --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "localhost:'$port1'"}, {_id: 1, host: "localhost:'$port2'"}, {_id: 2, host: "localhost:'$port3'"}]})'
    echo "Replica set initialized."
}

# Function to stop MongoDB processes
function stop_mongodb {
    local pidfile=$1

    if [ -f $pidfile ]; then
        pid=$(cat $pidfile)
        kill $pid
        echo "Stopped MongoDB process with PID $pid"
        rm $pidfile
    fi
}

# Function to remove MongoDB installation directory
function remove_mongodb {
    local installation_dir=$1

    if [ -d $installation_dir ]; then
        rm -rf $installation_dir
        echo "Removed MongoDB installation directory $installation_dir"
    else
        echo "No MongoDB installation found in $installation_dir"
    fi
}

# Function to show CRUD operations and index management
function show_crud_operations {
    local port=$1

    cat <<EOL
To perform CRUD operations, use the following MongoDB shell commands:

1. Connect to MongoDB:
   mongo --port $port

2. Create a database and a collection:
   use mydatabase
   db.createCollection("mycollection")

3. Insert documents:
   db.mycollection.insertOne({name: "Alice", age: 30})
   db.mycollection.insertMany([{name: "Bob", age: 25}, {name: "Charlie", age: 35}])

4. Read documents:
   db.mycollection.find()
   db.mycollection.find({name: "Alice"})

5. Update documents:
   db.mycollection.updateOne({name: "Alice"}, {\$set: {age: 31}})
   db.mycollection.updateMany({}, {\$inc: {age: 1}})

6. Delete documents:
   db.mycollection.deleteOne({name: "Bob"})
   db.mycollection.deleteMany({age: {\$gte: 30}})

7. Create an index:
   db.mycollection.createIndex({name: 1})

8. List indexes:
   db.mycollection.getIndexes()

9. Get collection schema:
   db.mycollection.find().limit(1).pretty()
EOL
}

# Function to display usage
function display_usage {
    echo "Usage: $0 [s|r|c|d|crud]"
    echo "Options:"
    echo "  s    Install standalone MongoDB instance"
    echo "  r    Install MongoDB replica set"
    echo "  c    Cleanup MongoDB installation (after installation)"
    echo "  d    Remove MongoDB installation"
    echo "  crud Show CRUD operations and index management"
}

# Main script starts here
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

if [ "$1" == "s" ]; then
    install_standalone_mongodb
elif [ "$1" == "r" ]; then
    install_replica_set
elif [ "$1" == "c" ]; then
    read -p "Enter 's' to cleanup standalone MongoDB or 'r' to cleanup replica set installation: " cleanup_option
    if [ "$cleanup_option" == "s" ]; then
        stop_mongodb ~/mongodb-standalone/mongod.pid
        remove_mongodb ~/mongodb-standalone
    elif [ "$cleanup_option" == "r" ]; then
        stop_mongodb ~/mongodb-replica-set/mongod1.pid
        stop_mongodb ~/mongodb-replica-set/mongod2.pid
        stop_mongodb ~/mongodb-replica-set/mongod3.pid
        remove_mongodb ~/mongodb-replica-set
    else
        echo "Invalid option. Please enter 's' for standalone or 'r' for replica set."
        exit 1
    fi
elif [ "$1" == "d" ]; then
    read -p "Enter 's' to remove standalone MongoDB or 'r' to remove replica set installation: " removal_option
    if [ "$removal_option" == "s" ]; then
        remove_mongodb ~/mongodb-standalone
    elif [ "$removal_option" == "r" ]; then
        remove_mongodb ~/mongodb-replica-set
    else
        echo "Invalid option. Please enter 's' for standalone or 'r' for replica set."
        exit 1
    fi
elif [ "$1" == "crud" ]; then
    read -p "Enter port for MongoDB instance (default: 27017): " crud_port
    crud_port=${crud_port:-27017}  # Set default port to 27017 if empty
    show_crud_operations $crud_port
else
    echo "Invalid option. Please enter 's' for standalone, 'r' for replica set, 'c' for cleanup, 'd' for removal, or 'crud' for CRUD operations."
    display_usage
    exit 1
fi

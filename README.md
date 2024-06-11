# mongoutility
Utility to install mongodb in local environment
Overview
This MongoDB Utility Script is designed to streamline the setup, management, and maintenance of MongoDB instances. The script supports the installation of standalone MongoDB instances and replica sets, and includes options for cleanup, removal, demonstrating CRUD operations, index management, and schema information.

Features
Standalone MongoDB Installation: Install a standalone MongoDB instance.
Replica Set Installation: Install a three-member MongoDB replica set.
Port Availability Check: Ensure that specified ports are available before installation.
Remote Access Configuration: Configure MongoDB to allow remote connections by binding to 127.0.0.1 and 0.0.0.0.
CRUD Operations: Display basic CRUD operations, index management, and schema information.
Cleanup and Removal: Options to cleanup or remove MongoDB installations.
Usage
Script Execution
To run the script, use the following command format:

bash
Copy code
python mongodb_utility.py [option]
Options
s: Install a standalone MongoDB instance.
r: Install a MongoDB replica set.
c: Cleanup MongoDB installation.
d: Remove MongoDB installation.
crud: Show CRUD operations, index management, and schema information.

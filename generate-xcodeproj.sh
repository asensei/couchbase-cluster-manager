#!/bin/bash

# Generates the Xcode project through Swift Package Manager
swift package -Xswiftc -I/usr/local/opt/openssl/include -Xlinker -L/usr/local/opt/openssl/lib generate-xcodeproj

# Rename the organisation name
PROJECT_PATH=./CouchbaseClusterManager.xcodeproj
ruby Scripts/update_xcodeproj_settings.rb $PROJECT_PATH "Asensei Inc." "CouchbaseClusterManager"

# Ask the user if they want to open the newly generated project
while true; do
    read -p "Do you wish to open the newly generated Xcode project? (y/n): " yn
    case $yn in
        [Yy]* ) open $PROJECT_PATH; exit;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

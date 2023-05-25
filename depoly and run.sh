#!/bin/bash

#  install Node.js 
install_nodejs() {
  echo "Installing Node.js 14.x..."
  curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "Node.js 14.x installed."
}

#  create an IP configuration file
create_ip_config() {
  echo "Creating IP configuration file..."

   sudo tee /etc/netplan/01-network-manager-all.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [10.0.2.15/24]
      gateway4: 10.0.2.2
      nameservers:
          addresses: [192.168.1.1,172.20.10.1]

EOF
  sudo netplan apply
  sudo systemctl restart NetworkManager
  handel_errors "Failed to create ip config"
}

# Function to create a Linux user
create_linux_user() {
  echo "Creating Linux user 'node'..."
  sudo adduser node
  echo "Linux user 'node' created."
}

# Function to retrieve the IP address using a regular expression
retrieve_ip_address() {
  echo "Retrieving IP address..."
  IP_ADDRESS=$(ip -o -4 addr show enp0s3 | awk '{print $4}' | sed 's/\/.*$//')
  echo "IP address retrieved: $IP_ADDRESS"
}

# Function to deploy and configure PostgreSQL
install_postgres() {
    sudo apt update
    sudo apt install postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sudo systemctl status postgresql
    sudo -u postgres psql -c "CREATE USER moustafa WITH PASSWORD '161122';"
    sudo -u postgres createdb demo_db
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE demo_db TO moustafa;"

}

# Function to run UI tests in a coprocess
run_ui_tests() {
  echo "Running UI tests..."
  cd pern-stack-example/ui
  npm run test &
  echo "UI tests running in the background."
}

# Function to build the UI
build_ui() {
  echo "Building UI..."
  cd pern-stack-example/ui
  npm install
  npm run build
  echo "UI built."
}

# Function to create the backend environment
create_backend_environment() {
  echo "Creating backend environment..."
  cd pern-stack-example/api
  npm install
  npm audit fix
  sed -i "/if (env === "demo") {/a\    process.env.HOST = "'"$IP_ADDRESS"'";\n    process.env.PGUSER = "Moustafa Tarek";\n    process.env.PGPASSWORD = "161122";\n    process.env.PGHOST = "'"$IP_ADDRESS"'";\n    process.env.PGPORT = "5000";\n    process.env.PGDATABASE = "demo_app_db";" webpack.config.js
  ENVIRONMENT=demo npm run build
}

  echo "Backend environment created."


# Function to package and start the application
start_application() {
  echo "Packaging and starting the application..."
  cd pern-stack-example
  cp -r api/dist/* .
  cp api/swagger.css .
  node api.bundle.js
  echo "Application started."
  handel_errors "Failed to start app"

}

# Main script

# Install Node.js 14.x
install_nodejs

# Create IP configuration file
create_ip_config

# Create Linux user 'node'
create_linux_user

# Retrieve the IP address using a regular expression
retrieve_ip_address

# Deploy and configure PostgreSQL
install_postgres

# Run UI tests in a coprocess
run_ui_tests

# Build the UI
build_ui

# Create the backend environment
create_backend_environment

# Package

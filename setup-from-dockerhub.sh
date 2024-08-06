#!/bin/bash
echo "This script is going to clone and  all necessary repositories for the Laravel Microservice Example."
set -e

check_create_network() {
  network_name=$1
  if ! docker network ls | grep -q $network_name; then
    echo "Network $network_name does not exist. Creating..."
    docker network create $network_name
  else
    echo "Network $network_name already exists."
  fi
}

if ping -c 4 "8.8.8.8" > /dev/null; then
  echo "Starting..."
else
  echo "Internet is not available! Please fix it first!"
  exit 1
fi

echo "Cloning Kafka..."
git clone git@github.com:miloskec/kafka.git
cd kafka
cp .env.example .env
cd -
echo "Cloning Gateway..."
git clone git@github.com:miloskec/gateway.git
cd gateway
git checkout production-prepare
cp .env.example .env
cd -
echo "Cloning Authentication..."
git clone git@github.com:miloskec/authentication.git
cd authentication
git checkout production-prepare
cp .env.example .env
cd -
echo "Cloning Authorization..."
git clone git@github.com:miloskec/authorization.git
cd authorization
git checkout production-prepare
cp .env.example .env
cd -
echo "Cloning Profile..."
git clone git@github.com:miloskec/profile.git
cd profile
git checkout production-prepare
cp .env.example .env
cd -
echo "Cloning Datadog..."
git clone git@github.com:miloskec/datadog.git
cd datadog
cp .env.example .env
cd -

echo "Script is now going to set related branch for each repo and to build and deploy image/containers"
echo "Before we continue with the script you will need to check if the '.env' file exist and to update it if necessary"

# Ask the user a question
echo "Did you check/set environment files? Please confirm it? (yes/no)"
read answer
# Convert the answer to lowercase for case-insensitive comparison
lowercase_answer=$(echo $answer | tr '[:upper:]' '[:lower:]')


# Check the user's answer
if [[ "$lowercase_answer" == "yes" ]] || [[ "${lowercase_answer:0:1}" == "y" ]]; then
    check_create_network "sail"
    echo "Building kafka container..."
    cd kafka
    docker-compose up -d
    echo "Setting the topic..."
    docker exec kafka /bin/bash -c "kafka-topics.sh --create --topic user_created_topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1  2>/dev/null" 
    echo "Done."
    cd -
    cd gateway
    echo "Building gateway service..."
    docker-compose -f docker-compose.dev.yml up -d --build
    echo "Waiting for services in gateway to be healthy..."
    while ! docker-compose -f docker-compose.dev.yml ps | grep -q 'healthy'; do
      sleep 10
    done
    echo "Services in gateway are healthy"
    sleep 5
    echo "Migrating data..."
    docker exec gateway-gateway-1 bash -c "php artisan migrate" 
    echo "Done."
    cd -
    cd authentication
    echo "Building authentication service..."
    docker-compose -f docker-compose.dev.yml up -d --build
    echo "Waiting for services in authentication to be healthy..."
    while ! docker-compose -f docker-compose.dev.yml ps | grep -q 'healthy'; do
      sleep 10
    done
    echo "Services in authentication are healthy"
    sleep 5
    echo "Migrating data..."
    docker exec authentication-authentication-1 bash -c "php artisan migrate" 
    echo "Running the queue..."
    nohup docker exec authentication-authentication-1 bash -c "php artisan queue:work >> authentication_setup.log 2>&1" > auth_output.log 2>&1 &
    echo "Done."
    cd -
    cd authorization
    echo "Building authorization service..."
    docker-compose -f docker-compose.dev.yml up -d --build
    echo "Waiting for services in authorization to be healthy..."
    while ! docker-compose -f docker-compose.dev.yml ps | grep -q 'healthy'; do
      sleep 10
    done
    echo "Services in authorization are healthy"
    sleep 5
    echo "Migrating data..."
    docker exec authorization-authorization-1 bash -c "php artisan migrate" 
    echo "Seeding data..."
    docker exec authorization-authorization-1 bash -c "php artisan db:seed --class=RoleSeeder" 
    echo "Setting the Kafka consumer..."
    nohup docker exec authorization-authorization-1 bash -c "php artisan app:consume-kafka-messages >> authorization_setup.log 2>&1" > autz_output.log 2>&1 &
    echo "Done."
    cd -
    cd profile
    echo "Building profile service..."
    docker-compose -f docker-compose.dev.yml up -d --build
    echo "Waiting for services in profile to be healthy..."
    while ! docker-compose -f docker-compose.dev.yml ps | grep -q 'healthy'; do
      sleep 10
    done
    echo "Services in profile are healthy"
    sleep 5
    echo "Migrating data..."
    docker exec profile-profile-1 bash -c "php artisan migrate" 
    echo "Setting the Kafka consumer..."
    nohup docker exec profile-profile-1 bash -c "php artisan app:consume-kafka-messages >> profile_setup.log 2>&1" > profile_output.log 2>&1 &
    echo "Done."
    cd -
    cd datadog
    echo "Building datadog service..."
    docker-compose up -d
    echo "Done."	
else
    echo "Exiting the script."
    exit 0
fi
echo "All operations completed successfully."
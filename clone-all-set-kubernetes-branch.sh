#!/bin/bash
echo "This script is going to clone and  all necessary repositories for the Laravel Microservice Example."
set -e

echo "Cloning Kafka..."
git clone git@github.com:miloskec/kafka.git
cd kafka
git checkout kubernetes-example
cp .env.example .env
cd -
echo "Cloning Gateway..."
git clone git@github.com:miloskec/gateway.git
cd gateway
git checkout kubernetes-example
cp .env.example .env
cd -
echo "Cloning Authentication..."
git clone git@github.com:miloskec/authentication.git
cd authentication
git checkout kubernetes-example
cp .env.example .env
cd -
echo "Cloning Authorization..."
git clone git@github.com:miloskec/authorization.git
cd authorization
git checkout kubernetes-example
cp .env.example .env
cd -
echo "Cloning Profile..."
git clone git@github.com:miloskec/profile.git
cd profile
git checkout kubernetes-example
cp .env.example .env
cd -
echo "Cloning Datadog..."
git clone git@github.com:miloskec/datadog.git
cd datadog
git checkout kubernetes-example
cp .env.example .env
cd -
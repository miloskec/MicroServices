#!/bin/bash
echo "This script is going to clone and  all necessary repositories for the Laravel Microservice Example."
set -e

#!/bin/bash

# Default branch name
branch_name="${1:-kubernetes-example}"

echo "This script is going to clone and set up all necessary repositories for the Laravel Microservice Example."
set -e

repos=("kafka" "gateway" "authentication" "authorization" "profile")

for repo in "${repos[@]}"
do
    echo "Cloning ${repo}..."
    git clone git@github.com:miloskec/${repo}.git
    cd ${repo}
    git checkout $branch_name
    cp .env.example .env
    cd -
done

echo "Cloning Datadog..."
git clone git@github.com:miloskec/datadog.git
cd datadog
git checkout kubernetes-example
cp .env.example .env
cd -

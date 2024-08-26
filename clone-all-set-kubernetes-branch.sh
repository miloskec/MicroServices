#!/bin/bash
echo "This script is going to clone and  all necessary repositories for the Laravel Microservice Example."
set -e

# Prompt user to select a branch
echo "Please select a branch number for cloning the repositories:"
select branch_name in "kubernetes-example" "kubernetes-nodes-example"
do
    if [[ -n $branch_name ]]; then
        echo "You selected $branch_name"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

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

# Datadog repository is cloned separately - doesnot have kubernetes-nodes-example branch
echo "Cloning Datadog..."
git clone git@github.com:miloskec/datadog.git
cd datadog
git checkout kubernetes-example
cp .env.example .env
cd -

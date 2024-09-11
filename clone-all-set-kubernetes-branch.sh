#!/bin/bash
echo "This script is going to clone and  all necessary repositories for the Laravel Microservice Example."
set -e

# Prompt user to select a branch
echo "Please select a branch number for cloning the repositories:"
select branch_name in "kubernetes-example" "kubernetes-nodes-example"; do
    if [[ -n $branch_name ]]; then
        echo "You selected $branch_name"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Ask if the user wants to install with Ingress
echo "Do you want to install with Ingress? (yes/no)"
read install_with_ingress

with_ingress= false
if [[ "$install_with_ingress" == "yes" ]]; then
    echo "Note: Ingress must be enabled for Minikube before proceeding."
    echo "You can enable it by running: minikube addons enable ingress"
    with_ingress= true
else
    echo "Proceeding without Ingress."
fi

repos=("kafka" "gateway" "authentication" "authorization" "profile")

for repo in "${repos[@]}"; do
    echo "Cloning ${repo}..."
    git clone git@github.com:miloskec/${repo}.git
    cd ${repo}
    # check if with_ingress is true and branch_name is kubernetes-example
    if [[ "$with_ingress" == true && "$branch_name" == "kubernetes-example" ]]; then
        git checkout kubernetes-ingress-example
    else
        git checkout $branch_name
    fi
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

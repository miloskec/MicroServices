#!/bin/bash

# Define directories and respective YAML files clearly
declare -A services
services=(
    ["kafka"]="zookeeper-deployment-service.yaml kafka-deployment-service.yaml"
    ["gateway"]="gateway-deployment-service.yaml memcached-deployment-service.yaml mysql-gateway-deployment-service.yaml"
    ["authentication"]="mysql-authentication-deployment-service.yaml authentication-deployment-service.yaml"
    ["authorization"]="mysql-authorization-deployment-service.yaml authorization-deployment-service.yaml"
    ["profile"]="mysql-profile-deployment-service.yaml profile-deployment-service.yaml"
    ["datadog"]="datadog-daemon-set.yaml datadog-agent-clusterrolebinding.yaml datadog-agent-clusterrole.yaml datadoghq.com_datadogagents.yaml"
)

# Function to delete Kubernetes resources from given directory
delete_k8s_resources() {
    local service_dir=$1
    shift
    # Navigate to the service directory
    pushd "$service_dir" > /dev/null

    # Iterate over the files and attempt to delete resources
    for file in "$@"; do
        echo "Attempting to delete $file in $service_dir..."
        if kubectl delete -f "$file"; then
            echo "Successfully deleted $file"
        else
            echo "Failed to delete $file or it may not exist"
        fi
    done

    # Return to the previous directory
    popd > /dev/null
}

# Main function to process all services
main() {
    for service in "${!services[@]}"; do
        echo "Processing $service..."
        delete_k8s_resources "$service" ${services[$service]}
    done
}

# Run the main function
main
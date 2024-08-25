#!/bin/bash

# Helper function to apply Kubernetes configurations
apply_k8s_configs() {
    local service_dir=$1
    shift
    for file in "$@"; do
        kubectl apply -f "${service_dir}/${file}"
        if [ $? -ne 0 ]; then
            echo "Failed to apply $file in $service_dir"
            exit 1
        fi
    done
}

# Function to wait for MySQL service to become ready
wait_for_mysql() {
    local service=$1
    echo "Waiting for service $service to be ready..."
    sleep 10
    kubectl wait --for=condition=ready pod -l app=$service --timeout=300s
    if [ $? -ne 0 ]; then
        echo "Timeout waiting for $service to become ready"
        exit 1
    fi
}

# Function to create topics in Kafka
create_kafka_topics() {
    local pod_name=$(kubectl get pod -l app=kafka -o jsonpath='{.items[0].metadata.name}')
    kubectl exec "$pod_name" -- kafka-topics.sh --create --topic user_created_topic --bootstrap-server kafka-service:9092 --partitions 1 --replication-factor 1  2>/dev/null
}

# Function to set up services (gateway, authentication, etc.)
setup_service() {
    local service=$1
    local pod_name=$(kubectl get pod -l app="$service" -o jsonpath='{.items[0].metadata.name}')

    # No need for directory management here as the commands are executed inside the pods
    kubectl exec -it "$pod_name" -- cp .env.example .env
    kubectl exec -it "$pod_name" -- php artisan migrate:fresh

    if [[ "$service" == "authentication" ]]; then
        local log_file="${service}_setup.log"
        local output_file="${service}_output.log"
        local command="php artisan queue:work"
        
        kubectl exec "$pod_name" -- nohup $command >> "$log_file" 2>&1 > "$output_file" 2>&1 &
    elif [[ "$service" == "authorization" ]]; then
        local log_file="authorization_setup.log"
        local output_file="autz_output.log"
        local command="php artisan db:seed --class=RoleSeeder"

        # Seed the database first
        kubectl exec "$pod_name" -- $command

        # Then start consuming Kafka messages
        command="php artisan app:consume-kafka-messages"
        kubectl exec "$pod_name" -- nohup $command >> "$log_file" 2>&1 > "$output_file" 2>&1 &
    elif [[ "$service" == "profile" ]]; then
        local log_file="profile_setup.log"
        local output_file="profile_output.log"

        local command="php artisan app:consume-kafka-messages"

        kubectl exec "$pod_name" -- nohup $command >> "$log_file" 2>&1 > "$output_file" 2>&1 &
    fi
}

# Function to check if the secret exists
check_secret() {
    if kubectl get secret datadog-secret -n default > /dev/null 2>&1; then
        echo "Secret datadog-secret exists in the namespace default."
    else
        echo "Secret datadog-secret does not exist in the namespace default."
        exit 1
    fi
    if kubectl get secret mysql-secret -n default > /dev/null 2>&1; then
        echo "Secret mysql-secret exists in the namespace default."
    else
        echo "Secret mysql-secret does not exist in the namespace default."
        exit 1
    fi
}
# Main script execution
main() {
    # Check if secret is set
    check_secret
    # Kafka
    apply_k8s_configs "kafka" zookeeper-deployment-service.yaml kafka-deployment-service.yaml
    # Gateway
    apply_k8s_configs "gateway" memcached-deployment-service.yaml mysql-gateway-deployment-service.yaml 
    wait_for_mysql "mysql"
    apply_k8s_configs "gateway" gateway-deployment-service.yaml
    # Authentication
    apply_k8s_configs "authentication" mysql-authentication-deployment-service.yaml 
    wait_for_mysql "mysql-authentication"
    apply_k8s_configs "authentication" authentication-deployment-service.yaml
    # Authorization
    apply_k8s_configs "authorization" mysql-authorization-deployment-service.yaml 
    wait_for_mysql "mysql-authorization"
    apply_k8s_configs "authorization" authorization-deployment-service.yaml
    # Profile
    apply_k8s_configs "profile" mysql-profile-deployment-service.yaml 
    wait_for_mysql "mysql-profile"
    apply_k8s_configs "profile" profile-deployment-service.yaml
    # Datadog
    apply_k8s_configs "datadog" datadoghq.com_datadogagents.yaml 
    sleep 30
    apply_k8s_configs "datadog" datadog-agent-clusterrole.yaml datadog-agent-clusterrolebinding.yaml
    sleep 30
    apply_k8s_configs "datadog" datadog-daemon-set.yaml
    # Run the code after 30 seconds to ensure that the services are up and running
    sleep 30
    create_kafka_topics
    # Run the code after 1 minute to ensure that the kafka is configured up and running
    wait_for_mysql "gateway"
    setup_service gateway
    wait_for_mysql "authentication"
    setup_service authentication
    wait_for_mysql "authorization"
    setup_service authorization
    wait_for_mysql "profile"
    setup_service profile
}

# Run the main function
main

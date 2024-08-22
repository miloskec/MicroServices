# Setup script
This script will set up all microservices required for the project.

## Instructions 
Follow these steps to properly execute the setup script: 
- **Download the Script:** Ensure you download the script into an empty folder. 
- **Set Execution Permissions:** Modify the script's permissions to allow execution. 
- **Run the Script:** Execute the script. It will automatically download all the necessary services for the project. 
- **Update Environment Files:** When prompted, update the .env files located inside each project directory. 
- **Confirm Completion:** After updating the .env files, return to the console and confirm that the updates are complete. 
- **Finalize Setup:** The script will then continue to finalize the setup process. 

## Script usages
- **setup.sh** should be used when you want to build images and to use those local images
- **setup-from-dockerhub.sh** should be used in case that you want to use already created images (dokcerhub)
- **clone-all-set-kubernetes-branch.sh** should be used to clone project repos and to set to the kubernetes related branch
- **kubernetes-setup.sh** should be used to setup kubernetes project(s) (yaml files and specific commands per project)
- **kubernetes-remove-services.sh** should be used to "uninstall" kubernetes project(s) (remove resources using yaml files/reverse)

## Multinode setup 
Please have in mind that in order to run **kubernetes-setup.sh** as a multinode setup you will need to: 
- prepare kubernetes multinode profile
  - Ensure you are using the Node authorizer and have enabled the NodeRestriction admission plugin.
  - Add labels with the node-restriction.kubernetes.io/ prefix to your nodes, and use those labels in your node selectors.
    - ```sh
      minikube start --nodes 6 -p multinode --extra-config=apiserver.enable-admission-plugins=NodeRestriction
  
      kubectl label nodes multinode-m02 node-restriction.kubernetes.io/gateway=true
      kubectl label nodes multinode-m03 node-restriction.kubernetes.io/authentication=true
      kubectl label nodes multinode-m04 node-restriction.kubernetes.io/authorization=true
      kubectl label nodes multinode-m05 node-restriction.kubernetes.io/profile=true
      kubectl label nodes multinode-m06 node-restriction.kubernetes.io/kafka=true
      ```
      You  can then check if everything is set as expected:
      ```sh
      kubectl get nodes
      NAME            STATUS   ROLES           AGE    VERSION
      multinode       Ready    control-plane   0d1h   v1.30.0
      multinode-m02   Ready    <none>          0d1h   v1.30.0
      multinode-m03   Ready    <none>          0d1h   v1.30.0
      multinode-m04   Ready    <none>          0d1h   v1.30.0
      multinode-m05   Ready    <none>          0d1h   v1.30.0
      multinode-m06   Ready    <none>          0d1h   v1.30.0
      ```
- switch to the **kubernetes-nodes-example** in every repository

  Once when kubernetes-setup.sh finish you should get something like:
  ```sh
  kubectl get pods
  NAME                                              READY   STATUS    RESTARTS        
  authentication-deployment-6cd66c7874-v9w8t        1/1     Running   1 (107s ago)    
  authorization-deployment-bd6844d74-9p795          1/1     Running   2 (100s ago)    
  datadog-agent-2mknx                               1/1     Running   2 (86s ago)     
  datadog-agent-4qwdj                               1/1     Running   2 (2m12s ago)   
  datadog-agent-b99tz                               1/1     Running   2 (107s ago)    
  datadog-agent-k9mk9                               1/1     Running   2 (100s ago)    
  datadog-agent-pcdfb                               1/1     Running   2 (93s ago)     
  datadog-agent-rttkb                               1/1     Running   2 (114s ago)    
  gateway-deployment-799d4956-v74kj                 1/1     Running   2 (114s ago)    
  kafka-deployment-d7875c446-hv567                  1/1     Running   2 (86s ago)     
  memcached-deployment-5cbc9cfcdc-ztdqh             1/1     Running   2 (114s ago)    
  mysql-authent-deployment-6945d54fbd-vffwb         1/1     Running   2 (107s ago)    
  mysql-authorization-deployment-7cfc847646-47lms   1/1     Running   2 (100s ago)    
  mysql-deployment-5b9976cdc-9xprf                  1/1     Running   2 (114s ago)    
  mysql-profile-deployment-7989b64df8-z26xh         1/1     Running   2 (93s ago)     
  profile-deployment-5c6b78dcb-qfnz6                1/1     Running   2 (93s ago)     
  zookeeper-deployment-b756855fd-v8v76              1/1     Running   2 (86s ago)     
  ```
  

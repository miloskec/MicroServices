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

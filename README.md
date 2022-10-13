# selfhostedviya

# Define environment variables

  
export az_subscription=subscription        # Replace with the subscription you want to create the resources.  <br /> 
export az_region=region                    # Replace with the azure region you want to create the resources. <br />
export az_project=projectname              # Replace with the name of the project you want. <br />
export az_public_access_cidrs="x.x.x.x/16" # Replace with the públic IP CIDR that will be used to access the resources.  <br />

# Clone this repository

git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Azure Resources

chmod +x selfhostedviya/prepareAzureResources.sh <br />
selfhostedviya/prepareAzureResources.sh

# SSH to the Virtual Machine created

ssh -i ~/.ssh/id_rsa azureuser@${az_project}-vm

# Clone this repository 

git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Kubernetes Resources

chmod +x selfhostedviya/prepareKubernetesResources.sh <br />
selfhostedviya/prepareKubernetesResources.sh

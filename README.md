# selfhostedviya

# Define environment variables

  # Replace with the subscription you want to create the resources.  <br /> 
  export az_subscription=subscription <br /> 
  # Replace with the azure region you want to create the resources. <br />
  export az_region=region <br /> 
  # Replace with the name of the project you want, will be used as prefixes to the azure resources that will be created by the prepareAzureResources.sh. <br />
  export az_project=projectname <br />
  # Replace with the públic IP CIDR that will be used to access the resources.  <br />
  export az_public_access_cidrs="x.x.x.x/16 x.x.x.x/32"  <br />

# Clone this repository

git clone https://github.com/sbrser/selfhostedviya.git

# Execute the script 

chmod +x selfhostedviya/prepareAzureResources.sh
selfhostedviya/prepareAzureResources.sh

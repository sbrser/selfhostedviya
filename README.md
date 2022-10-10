# selfhostedviya

# Define environment variables

export az_subscription=<subscription> <br /> # Replace the <subscription> with the subscription you want to create the resources.
export az_region=<region> <br /> # Replace the <region> with the azure region you want to create the resources.
export az_project=<projectname> <br /> # Replace the <projectname> with the name of the project you want, this will be used as prefixes to the azure resources that will be created by the prepareAzureResources.sh.
export az_public_access_cidrs="x.x.x.x/16 x.x.x.x/32" # Replace the x with the públic IP CIDR that will be used to access the resources.

# Clone this repository

git clone https://github.com/sbrser/selfhostedviya.git

# Execute the script 

chmod +x selfhostedviya/prepareAzureResources.sh
selfhostedviya/prepareAzureResources.sh

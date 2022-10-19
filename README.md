# selfhostedviya

# Open the cloud Shell at the Azure Portal 

https://portal.azure.com/

![image](https://user-images.githubusercontent.com/115498782/195679636-5a242d10-14a5-4326-b387-86eaa4a4f370.png)

# Define environment variables

cloudshellIP=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'` <br /> 
export az_subscription=subscription        # Replace with the subscription you want to create the resources.  <br /> 
export az_region=region                    # Replace with the azure region you want to create the resources. <br />
export az_project=projectname              # Replace with the name of the project you want. <br />
export az_public_access_cidrs="x.x.x.x/16 $cloudshellIP" # Replace with the públic IP CIDR that will be used to access the resources.  <br />
export az_vm_size=Standard_E16ds_v5        # Standard_E16ds_v5 is the minimal required to this project. <br />
export az_vm_disk_size_gb=300              # OS disk size 300GB is the minimal required to this project. <br />


# Clone this repository into the Azure Cloud Shell

git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Azure Resources

chmod +x selfhostedviya/prepareAzureResources.sh <br />
selfhostedviya/prepareAzureResources.sh

# SSH to the Virtual Machine created

ssh -i .ssh/id_rsa -l azureuser ${vmIP}

- Enter yes when this message appear: <br />
![image](https://user-images.githubusercontent.com/115498782/195848242-e0cb5e04-928f-48e5-8002-84fafe5f20a7.png)

 
# Clone this repository into the Azure Virtual Machine

sudo yum install -y git # Install git in the VM <br />
git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Kubernetes Resources

chmod +x selfhostedviya/prepareKubernetesResources.sh <br />
selfhostedviya/prepareKubernetesResources.sh

## Verify if everything is running:

kubectl get pods --all-namespaces

# Execute the script to prepare OpenLDAP

chmod +x selfhostedviya/prepareOpenLDAP.sh <br />
selfhostedviya/prepareOpenLDAP.sh

## Verify if ldap is running:

kubectl get pods -n kubectl -n ldap-basic

# Execute the script to Install Viya

- Define the Environment Variables below replacing with the correct values
- SASAPIKey and SASAPISecret must be created at SAS Viya Orders API, instructions at https://apiportal.sas.com/get-started

![image](https://user-images.githubusercontent.com/115498782/196185492-58e5332f-112f-4583-a07c-8683a400c21c.png)

export SASAPIKey=key                 # Replace with the API Key from your created application at https://apiportal.sas.com.  <br /> 
export SASAPISecret=secret           # Replace with the API Sectret from your created application at https://apiportal.sas.com.  <br /> 
export VIYA_ORDER=order_number       # Replace with the Viya Order Number you wish to install located at https://my.sas.com/en/home.html. <br /> 

chmod +x selfhostedviya/installViya.sh <br />
selfhostedviya/installViya.sh





# selfhostedviya

# Open the cloud Shell at the Azure Portal 

https://portal.azure.com/

![image](https://user-images.githubusercontent.com/115498782/195679636-5a242d10-14a5-4326-b387-86eaa4a4f370.png)

# Define environment variables

cloudshellIP=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
  
export az_subscription=subscription        # Replace with the subscription you want to create the resources.  <br /> 
export az_region=region                    # Replace with the azure region you want to create the resources. <br />
export az_project=projectname              # Replace with the name of the project you want. <br />
export az_public_access_cidrs="x.x.x.x/16 $cloudshellIP" # Replace with the públic IP CIDR that will be used to access the resources.  <br />
export az_vm_size=Standard_E16ds_v5        # Standard_E16ds_v5 is the minimal required to this project. <br />

# Clone this repository into the Azure Cloud Shell

git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Azure Resources

chmod +x selfhostedviya/prepareAzureResources.sh <br />
selfhostedviya/prepareAzureResources.sh

# SSH to the Virtual Machine created

"vmIP=`az vm list-ip-addresses -g ${az_project}-rg -n ${az_project}-vm | grep ipAddress | cut -d ":" -f 2 | sed 's/"//' | sed 's/",//'`" <br />
ssh -i .ssh/id_rsa -l azureuser ${vmIP}

Enter yes when this message appear: <br />
![image](https://user-images.githubusercontent.com/115498782/195848242-e0cb5e04-928f-48e5-8002-84fafe5f20a7.png)

 
# Clone this repository into the Azure Virtual Machine

sudo yum install -y git # Install git in the VM

git clone https://github.com/sbrser/selfhostedviya.git <br />

# Execute the script to prepare the Kubernetes Resources

chmod +x selfhostedviya/prepareKubernetesResources.sh <br />
selfhostedviya/prepareKubernetesResources.sh

Verify if everything is running:

kubectl get pods --all-namespaces





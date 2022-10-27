# selfhostedviya for Azure Cloud

This project allow you to install Viya in a single Virtual Machine at Microsoft Azure. Follow the steps below to install.

# Requirements

- Azure Subscription
- Your Azure User Account should belong to Azure Subscription Roles "Owner" or "Contributor"
- SASAPIKey and SASAPISecret (SAS Viya Orders API - https://apiportal.sas.com/get-started)
- SAS Viya Order

# Steps

## Open the cloud Shell at the Azure Portal 

https://portal.azure.com/

![image](https://user-images.githubusercontent.com/115498782/195679636-5a242d10-14a5-4326-b387-86eaa4a4f370.png)

## Define environment variables

cloudshellIP=\`curl -s checkip.dyndns.org | sed -e 's/.\*Current IP Address: //' -e 's/<.*$//'\` <br /> 
export az_subscription=subscription        # Replace with the subscription you want to create the resources.  <br /> 
export az_region=region                    # Replace with the azure region you want to create the resources. <br />
export az_project=projectname              # Replace with the name of the project you want. <br />
export az_public_access_cidrs="x.x.x.x/16 $cloudshellIP" # Replace with the public IP CIDR that will be used to access Viya.  <br />
export az_vm_size=Standard_E32s_v5        # Standard_E32s_v5 is the suggestion for this project. <br />
export az_vm_disk_size_gb=300              # OS disk size 300GB is the minimal required to this project. <br />


## Clone this repository into the Azure Cloud Shell

git clone https://github.com/sbrser/selfhostedviya.git <br />

## Execute the script to prepare the Azure Resources

chmod +x selfhostedviya/prepareAzureResources.sh <br />
source selfhostedviya/prepareAzureResources.sh

## SSH to the Virtual Machine created

ssh -i .ssh/id_rsa -l azureuser ${vmIP}

- Enter yes when this message appear: <br />
![image](https://user-images.githubusercontent.com/115498782/195848242-e0cb5e04-928f-48e5-8002-84fafe5f20a7.png)

 
## Clone this repository into the Azure Virtual Machine

sudo yum install -y git # Install git in the VM <br />
git clone https://github.com/sbrser/selfhostedviya.git <br />

## Execute the script to prepare the Kubernetes Resources

chmod +x selfhostedviya/prepareKubernetesResources.sh <br />
source selfhostedviya/prepareKubernetesResources.sh

- Verify if everything is running:

kubectl get pods --all-namespaces

![image](https://user-images.githubusercontent.com/115498782/198282950-2a44cb44-2477-4ce3-a65d-89d1cae099f4.png)

## Execute the script to prepare OpenLDAP

chmod +x selfhostedviya/prepareOpenLDAP.sh <br />
source selfhostedviya/prepareOpenLDAP.sh

- Verify if ldap is running:

kubectl get pods -n kubectl -n ldap-basic

![image](https://user-images.githubusercontent.com/115498782/198283198-2c3741f6-4acf-4284-8e37-1981de9e6b9a.png)

## Execute the script to Install Viya

- Define the Environment Variables below replacing with the correct values
- SASAPIKey and SASAPISecret must be created at SAS Viya Orders API, instructions at https://apiportal.sas.com/get-started

![image](https://user-images.githubusercontent.com/115498782/196185492-58e5332f-112f-4583-a07c-8683a400c21c.png)

export SASAPIKey=key                 # Replace with the API Key from your created application at https://apiportal.sas.com.  <br /> 
export SASAPISecret=secret           # Replace with the API Sectret from your created application at https://apiportal.sas.com.  <br /> 
export VIYA_ORDER=order_number       # Replace with the Viya Order Number you wish to install located at https://my.sas.com/en/home.html. <br /> 

chmod +x selfhostedviya/installViya.sh <br />
source selfhostedviya/installViya.sh

## Execute the command below to wait to the environment to get ready:

time kubectl -n viya wait --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness' --timeout=2700s
    
## When the time command return the environment is ready to use

![image](https://user-images.githubusercontent.com/115498782/198111084-10e83014-e81a-418e-98e6-069467df93be.png)

### Get the URL with the command:

echo https://$ingress_alias

![image](https://user-images.githubusercontent.com/115498782/198131967-5c48b7a3-beb8-442e-8067-ae5ab01c1640.png)


### Use the login information:

SAS Administrator: sasadm <br /> 
Password: lnxsas <br /> 

SAS Demo User: sasdemo <br /> 
Password: lnxsas <br /> 

### Alternative users:

SAS Test User 1: sastest1 <br /> 
Password: lnxsas <br /> 

SAS Test User 2: sastest2 <br /> 
Password: lnxsas <br /> 

# LDAP Information

![image](https://user-images.githubusercontent.com/115498782/198134563-0bf8fb48-f496-4d3f-a2fc-f829bbfccc15.png)

# Data Information

## Path /data was create at CAS and Compute pods, you can use it to copy files; create libnames and caslibs

- Upload files using the SAS Server file navigation at SAS Studio.

![image](https://user-images.githubusercontent.com/115498782/198370464-de702033-3c0e-4851-a9f9-3aeea09b96cd.png)

- Libname command example:

  libname myLib "/data";

- Caslib command example: 

  cas mySession; <br /> 
  caslib myCaslib datasource=(srctype="path") path="/data" sessref=mySession subdirs; <br /> 
  libname myCaslib cas; <br /> 
  caslib _all_ assign; <br /> 

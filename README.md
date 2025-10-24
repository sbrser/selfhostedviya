# selfhostedviya for Azure Cloud

This project allow you to install Viya in a single Virtual Machine at Microsoft Azure. Follow the steps below to install.

# Requirements

- Azure Subscription
- Your Azure User Account should belong to Azure Subscription Roles "Owner" or "Contributor"
- SAS Viya Order
- SASAPIKey and SASAPISecret from a user that can access the SAS Viya Order (SAS Viya Orders API - https://apiportal.sas.com/get-started)


# Azure infrastructure that will be created

![SelfHostedViya-Page-2 (1)](https://user-images.githubusercontent.com/115498782/198652428-d845f5fd-8487-4a2c-9281-d8a162df012d.png)

# Steps

## Open the cloud Shell at the Azure Portal 

https://portal.azure.com/

![image](https://user-images.githubusercontent.com/115498782/195679636-5a242d10-14a5-4326-b387-86eaa4a4f370.png)

## Define environment variables
``` BASH
cloudshellIP=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
export az_subscription=subscription        # Replace with the subscription name you want to create the resources.  
export az_region=region                    # Replace with the azure region you want to create the resources (Ex.: eastus, westus2...) 
export az_project=projectname              # Replace with the name of the project you want. **USE ONLY LETTERS WITH NO SPACES.  
export az_public_access_cidrs="x.x.x.x/yy $cloudshellIP" # Replace with the public IP CIDR that will be used to access Viya.  
export az_vm_size=Standard_E32as_v5         # Standard_E32s_v5 is the suggestion for this project. 
export az_vm_disk_size_gb=300              # OS disk size 300GB is the suggestion for this project. 
```

## Clone this repository into the Azure Cloud Shell
``` BASH
git clone https://github.com/sbrser/selfhostedviya.git
```
## Execute the script to prepare the Azure Resources
``` BASH
chmod +x selfhostedviya/scripts/prepareAzureResources.sh
source selfhostedviya/scripts/prepareAzureResources.sh
```
## SSH to connect the Azure Virtual Machine created
``` BASH
export vmIP=`az vm list-ip-addresses -g ${az_project}-rg -n ${az_project}-vm | grep ipAddress | cut -d ":" -f 2 | sed 's/"//' | sed 's/",//'`
ssh -i .ssh/id_rsa -l azureuser ${vmIP}
```
- Enter yes when this message appear: <br />
![image](https://user-images.githubusercontent.com/115498782/195848242-e0cb5e04-928f-48e5-8002-84fafe5f20a7.png)

 
## Clone this repository into the Azure Virtual Machine
``` BASH
sudo yum install -y git # Install git in the VM 
git clone https://github.com/sbrser/selfhostedviya.git
```
## Execute the script to prepare the Kubernetes Resources
``` BASH
chmod +x selfhostedviya/scripts/prepareKubernetesResources.sh
source selfhostedviya/scripts/prepareKubernetesResources.sh
```
- Verify and wait till all pods are in Status Running or Completed and Ready 1/1 or 2/2:
``` BASH
kubectl get pods --all-namespaces
```
![image](https://user-images.githubusercontent.com/115498782/198282950-2a44cb44-2477-4ce3-a65d-89d1cae099f4.png)

## Execute the script to prepare OpenLDAP
``` BASH
chmod +x selfhostedviya/scripts/prepareOpenLDAP.sh
source selfhostedviya/scripts/prepareOpenLDAP.sh
```
- Verify and wait till LDAP pod is in Status Running and Ready 1/1:
``` BASH
kubectl get pods -n kubectl -n ldap-basic
```
![image](https://user-images.githubusercontent.com/115498782/198283198-2c3741f6-4acf-4284-8e37-1981de9e6b9a.png)

## Execute the script to Install Viya

- Define the Environment Variables below replacing with the correct values
- SASAPIKey and SASAPISecret must be created at SAS Viya Orders API, instructions at https://apiportal.sas.com/get-started

![image](https://user-images.githubusercontent.com/115498782/196185492-58e5332f-112f-4583-a07c-8683a400c21c.png)
``` BASH
export SASAPIKey=key                 # Replace with the API Key from your created application at https://apiportal.sas.com.  
export SASAPISecret=secret           # Replace with the API Sectret from your created application at https://apiportal.sas.com.  
export VIYA_ORDER=order_number       # Replace with the Viya Order Number you wish to install located at https://my.sas.com/en/home.html. 
```
``` BASH
chmod +x selfhostedviya/scripts/installViya.sh
source selfhostedviya/scripts/installViya.sh
```
## Execute the command below and wait till the environment get condition ready:
``` BASH
time kubectl -n viya wait --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness' --timeout=2700s
```  
## When the time command return the environment is ready to use

![image](https://user-images.githubusercontent.com/115498782/198111084-10e83014-e81a-418e-98e6-069467df93be.png)

### Get the URL with the command:
```
echo https://$ingress_alias
```
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

# Start and Stop

## STOP the environment

- Simple stop de Azure Virtual Machine

![image](https://user-images.githubusercontent.com/115498782/198690314-1cb23cbf-c556-4bb0-a752-4fa8c6bc726d.png)


## START the environment

- Simple start de Azure Virtual Machine

![image](https://user-images.githubusercontent.com/115498782/198690610-49cae4f2-b11a-4501-894e-8d6e58c13e61.png)

# Monitoring and Logging

You can monitor and check the logs using this two methods:

## With Kubectl commands in the Azure Virtual Machine created. <br /> 

- SSH to the Azure Virtual Machine
``` BASH
export az_project=projectname              # Replace with the name of the project you defined. 
export vmIP=`az vm list-ip-addresses -g ${az_project}-rg -n ${az_project}-vm | grep ipAddress | cut -d ":" -f 2 | sed 's/"//' | sed 's/",//'`
ssh -i .ssh/id_rsa -l azureuser ${vmIP}
```
- Execute the kubectl command
``` BASH
kubectl -n viya get pods
```

## With Lens (https://k8slens.dev/) <br /> 

- To use with Lens, copy the content of the kube config file in the folder ~/.kube (Azure Virtual Machine)
- Replace the "server:" parameter from the local IP 192.168.0.4 to your $ingress-alias value
- Add the full content at the Add Cluster in Lens application

![image](https://user-images.githubusercontent.com/115498782/198714032-655a7f21-cbf9-4a41-85b4-d75f4b83ca89.png)

# LDAP Information

![image](https://user-images.githubusercontent.com/115498782/198134563-0bf8fb48-f496-4d3f-a2fc-f829bbfccc15.png)

# Data Information

## Path /data was create at CAS and Compute pods, you can use it to copy files; create libnames and caslibs

- Upload files using the SAS Server file navigation at SAS Studio.

![image](https://user-images.githubusercontent.com/115498782/198370464-de702033-3c0e-4851-a9f9-3aeea09b96cd.png)

- Libname command example:
``` SAS
  libname myLib "/data";
```
- Caslib command example: 
``` SAS
  cas mySession; 
  caslib myCaslib datasource=(srctype="path") path="/data" sessref=mySession subdirs; 
  libname myCaslib cas;  
  caslib _all_ assign; 
```
# Acknowledgments

Henrique Danc (Principal Solutions Architect) <br /> 
Vitor Conde (Sr. Systems Engineer) <br /> 
Gustavo Peixinho (Cloud Technical Lead) <br /> 



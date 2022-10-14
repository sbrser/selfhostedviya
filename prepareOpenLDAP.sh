
# Configure OpenLDAP

tar -xf selfhostedviya/ldap-basic.tar

INGRESS_ALIAS_PHP="phpldapadmin.sbrserviya4single.eastus.cloudapp.azure.com"

sed -i -e 's, _INGRESS_ALIAS_, '$INGRESS_ALIAS_PHP',g' ldap-basic/07-php-ldap-admin-ingress.yml

kubectl create ns ldap-basic

kubectl apply -f ldap-basic/01-ldap-basic-namespace.yml

kubectl apply -f ldap-basic/02-openldap-configmap.yml --namespace=ldap-basic
kubectl apply -f ldap-basic/03-openldap-deployment.yml --namespace=ldap-basic
kubectl apply -f ldap-basic/04-openldap-service.yml --namespace=ldap-basic

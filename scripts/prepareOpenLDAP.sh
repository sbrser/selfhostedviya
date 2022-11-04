#!/bin/bash

# Configure OpenLDAP

# Unpack files
tar -xf selfhostedviya/ldap/ldap-basic.tar

# Create Namespace
kubectl create ns ldap-basic

# Apply Configurations
kubectl apply -f ldap-basic/01-ldap-basic-namespace.yml
kubectl apply -f ldap-basic/02-openldap-configmap.yml --namespace=ldap-basic
kubectl apply -f ldap-basic/03-openldap-deployment.yml --namespace=ldap-basic
kubectl apply -f ldap-basic/04-openldap-service.yml --namespace=ldap-basic

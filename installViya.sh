# Install Viya

# Clone Viya 4 Order Cli and get the assets
git clone https://github.com/sassoftware/viya4-orders-cli.git

cd viya4-orders-cli
sudo chown $USER /var/run/docker.sock
docker build . -t viya4-orders-cli
mkdir sasfiles

clientCredentialsId=`echo -n $SASAPIKey | base64`
clientCredentialsSecret=`echo -n $SASAPISecret | base64`

echo clientCredentialsId: $clientCredentialsId >> .viya4-orders-cli.yaml
echo clientCredentialsSecret: $clientCredentialsSecret >> .viya4-orders-cli.yaml

echo "docker run -v ~/viya4-orders-cli:/sas viya4-orders-cli deploymentAssets $VIYA_ORDER stable --config /sas/.viya4-orders-cli.yaml --file-path /sas/sasfiles --file-name ${VIYA_ORDER}_depassets" | bash 

# Configure assets to install

cd sasfiles 
tar -zxf ${VIYA_ORDER}_depassets.tgz

# Copy the openssl cert manager

mkdir -p site-config/security
cp sas-bases/examples/security/openssl-generated-ingress-certificate.yaml site-config/security

# Copy the postgres config

mkdir -p site-config/postgres
cp -R sas-bases/examples/configure-postgres/internal/pgo-client site-config/postgres/
sed 's/{{ REPLICAS-COUNT }}/0/' sas-bases/examples/postgres/replicas/postgres-replicas-transformer.yaml > site-config/postgres/postgres-replicas-transformer.yaml


# Create the storageclass.yaml file

cat > ~/viya4-orders-cli/sasfiles/site-config/storageclass.yaml <<-EOF
kind: RWXStorageClass
metadata:
 name: wildcard
spec:
 storageClassName: sas
EOF

# Create sitedefault.yaml file

tee  ~/viya4-orders-cli/sasfiles/site-config/sitedefault.yaml > /dev/null << "EOF"
config:
    application:
        sas.identities.providers.ldap.connection:
            host: openldap-service.ldap-basic.svc.cluster.local
            password: lnxsas
            port: 389
            userDN: cn=admin,dc=acme,dc=com
            url: ldap://${sas.identities.providers.ldap.connection.host}:${sas.identities.providers.ldap.connection.port}
        sas.identities.providers.ldap.group:
            accountId: 'cn'
            baseDN: 'dc=acme,dc=com'
            objectFilter: '(objectClass=groupOfUniqueNames)'
        sas.identities.providers.ldap.user:
            accountId: 'cn'
            baseDN: 'dc=acme,dc=com'
            objectFilter: '(objectClass=person)'
        sas.identities:
            administrator: 'sasadm'
        sas.logon.initial:
            user: sasboot
            password: lnxsas
EOF


# Define ingress_alias
curl -H Metadata:true http://169.254.169.254/metadata/instance?api-version=2017-03-01| python -m json.tool > vminfo.txt
vm_location=`cat vminfo.txt | grep location | cut -d ":" -f 2 | sed 's/ "//' | sed 's/",//'`
dns_prefix=`hostname | sed 's/-vm//'`
export ingress_alias=${dns_prefix}.${vm_location}.cloudapp.azure.com

echo Ingress Alias: $ingress_alias

# Create kustomization.yaml file
cat > ~/viya4-orders-cli/sasfiles/kustomization.yaml <<-EOF
---
namespace: viya
resources:
- sas-bases/base
- sas-bases/overlays/network/networking.k8s.io 
- site-config/security/openssl-generated-ingress-certificate.yaml 
- sas-bases/overlays/cas-server
- sas-bases/overlays/internal-postgres
- site-config/postgres/pgo-client 
# If your deployment contains SAS Data Science Programming, comment out the next line
- sas-bases/overlays/internal-elasticsearch
- sas-bases/overlays/update-checker
#- sas-bases/overlays/cas-server/auto-resources 
configurations:
- sas-bases/overlays/required/kustomizeconfig.yaml
transformers:
# If your deployment does not support privileged containers or if your deployment
# contains SAS Data Science Programming, comment out the next line
- sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml
- sas-bases/overlays/required/transformers.yaml
#- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml 
# If your deployment contains SAS Data Science Programming, comment out the next line
- sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml
# Mount information
# - site-config/{{ DIRECTORY-PATH }}/cas-add-host-mount.yaml
- sas-bases/overlays/scaling/single-replica/transformer.yaml
- site-config/postgres/postgres-replicas-transformer.yaml
components:
- sas-bases/components/security/core/base/full-stack-tls 
- sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls 
patches:
- path: site-config/storageclass.yaml 
  target:
    kind: PersistentVolumeClaim
    annotationSelector: sas.com/component-name in (sas-backup-job,sas-data-quality-services,sas-commonfiles,sas-cas-operator,sas-pyconfig)
# License information
# secretGenerator:
# - name: sas-license
#   type: sas.com/license
#   behavior: merge
#   files:
#   - SAS_LICENSE=license.jwt
configMapGenerator:
- name: ingress-input
  behavior: merge
  literals:
  - INGRESS_HOST=${ingress_alias}
- name: sas-shared-config
  behavior: merge
  literals:
  - SAS_SERVICES_URL=https://${ingress_alias}:443 
  # - SAS_URL_EXTERNAL_VIYA={{ EXTERNAL-PROXY-URL }}
  
secretGenerator:
  - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
    behavior: merge
    files:
      - SITEDEFAULT_CONF=site-config/sitedefault.yaml ## with 2020.1.5, the sitedefault.yaml config becomes a secretGenerator
EOF

# Build site.yaml file
../../kustomize build -o site.yaml

# Apply cluster-api resources to the cluster. 

kubectl create ns viya

kubectl apply --selector="sas.com/admin=cluster-api" --server-side --force-conflicts -f site.yaml

kubectl wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-api" crd

kubectl apply --selector="sas.com/admin=cluster-wide" -f site.yaml

kubectl apply --selector="sas.com/admin=cluster-local" -f site.yaml --prune

kubectl apply --selector="sas.com/admin=namespace" -f site.yaml --prune

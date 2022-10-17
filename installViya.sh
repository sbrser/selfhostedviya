git clone https://github.com/sassoftware/viya4-orders-cli.git

clientCredentialsId=`echo -n $SASAPIKey | base64`
clientCredentialsSecret=`echo -n $SASAPISecret | base64`

echo clientCredentialsId: $clientCredentialsId >> .viya4-orders-cli.yaml
echo clientCredentialsSecret: $clientCredentialsSecret >> .viya4-orders-cli.yaml

cd viya4-orders-cli
docker build . -t viya4-orders-cli
mkdir sasfiles

echo "docker run -v ~/viya4-orders-cli:/sas viya4-orders-cli deploymentAssets $VIYA_ORDER stable --config /sas/.viya4-orders-cli.yaml --file-path /sas/sasfiles --file-name ${VIYA_ORDER}_stable_depassets" | bash 

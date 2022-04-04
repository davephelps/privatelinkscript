
#az login
#az account set --subscription "subs"

$subs="15abae6c-7021-4f45-a569-3801fc087656"
# STORAGE
$accName="dpprivatestorage1"
$location="northeurope"
$vnetname="logicappsv2-vnet"
$ResourceGroupName="privatefunc"

$blobPrivateEndpointName="blobprivateendpoint5"
$filePrivateEndpointName="fileprivateendpoint5"

# vnet
$vnetsubnetname="funcvnetintegration"
$blobsubnetname="blobprivateendpoint"
$filesubnetname="fileprivateendpoint"

# Private Link/Zones
$blobzoneName="privatelink.blob.core.windows.net"
$blobzoneLinkName="dpprivatebloblink"
$filezoneName="privatelink.file.core.windows.net"
$filezoneLinkName="dpprivatefilelink"
$blobGroupName="dpblobZoneGroup"
$fileGroupName="dpfileZoneGroup"
$privateLinkName="privateendpoint5"
$zoneName="privatelink.azurewebsites.net"
$zoneLinkName="dpprivatefunctiontest5link"

# Function App
$functionAppPlanName="PrivateFunctionAppPlan5"
$functionAppName="dpprivatefunctiontest5"
$privateendpointsubnetname="funcprivateendpoint"

$resourceid="/subscriptions/" + $subs + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Web/sites/" + $functionAppName


# Create Storage Account
az storage account create --name $accName --kind StorageV2 --sku Standard_LRS --location $location -g $ResourceGroupName
az storage account show --name $accName --resource-group $ResourceGroupName --query "id" --output tsv

# Create Subnets
$ResourceGroupName="logicappsv2"
az network vnet subnet create -g $ResourceGroupName --vnet-name $vnetname -n $blobsubnetname --address-prefixes 173.0.9.0/24 --disable-private-endpoint-network-policies true
$blobprivateendpointsubnetid  =$(az network vnet subnet show  --name $blobsubnetname --resource-group $ResourceGroupName --vnet-name $vnetname --query "id")

az network vnet subnet create -g $ResourceGroupName --vnet-name $vnetname -n $filesubnetname --address-prefixes 173.0.8.0/24 --disable-private-endpoint-network-policies true
$fileprivateendpointsubnetid  =$(az network vnet subnet show  --name $filesubnetname --resource-group $ResourceGroupName --vnet-name $vnetname --query "id")

$ResourceGroupName="privatefunc"
$str_acc_id=$(az storage account show --name $accName --resource-group $ResourceGroupName --query "id" --output tsv)
az network private-endpoint create --name $blobPrivateEndpointName --resource-group $ResourceGroupName --subnet $blobprivateendpointsubnetid  --connection-name privatelinkconn --private-connection-resource-id $str_acc_id --group-id blob
az network private-endpoint create --name $filePrivateEndpointName --resource-group $ResourceGroupName --subnet $fileprivateendpointsubnetid  --connection-name privatelinkconn --private-connection-resource-id $str_acc_id --group-id file

az network private-dns zone create --name $blobzoneName --resource-group $ResourceGroupName
az network private-dns link vnet create --name $blobzoneLinkName --resource-group $ResourceGroupName --registration-enabled false --virtual-network $vnetid --zone-name $blobzoneName
az network private-endpoint dns-zone-group create --name $blobGroupName --resource-group $ResourceGroupName --endpoint-name $blobPrivateEndpointName --private-dns-zone $blobzoneName --zone-name $blobzoneName

az network private-dns zone create --name $filezoneName --resource-group $ResourceGroupName
az network private-dns link vnet create --name $filezoneLinkName --resource-group $ResourceGroupName --registration-enabled false --virtual-network $vnetid --zone-name $filezoneName
az network private-endpoint dns-zone-group create --name $fileGroupName --resource-group $ResourceGroupName --endpoint-name $filePrivateEndpointName --private-dns-zone $filezoneName --zone-name $filezoneName

# Create Function App Plan and Function App
$ResourceGroupName="privatefunc"
#az group create --location northeurope --resource-group $ResourceGroupName
az functionapp plan create -g $ResourceGroupName -n $functionAppPlanName --min-instances 1 --max-burst 10 --sku EP1  --location northeurope
az functionapp create -g $ResourceGroupName  -p $functionAppPlanName -n $functionAppName -s $accName --functions-version 2

$ResourceGroupName="logicappsv2"
# this is for VNET connectivity
# https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#subnets
az network vnet subnet create -g $ResourceGroupName --vnet-name $vnetname -n $vnetsubnetname --address-prefixes 173.0.6.0/24 --delegations Microsoft.Web/serverFarms
$vnetsubnetid=$(az network vnet subnet show  --name $vnetsubnetname --resource-group $ResourceGroupName --vnet-name $vnetname --query "id")
$vnetid=$(az network vnet show  --name $vnetname --resource-group $ResourceGroupName --query "id")

# this is for private endpoint
az network vnet subnet create -g $ResourceGroupName --vnet-name $vnetname -n $privateendpointsubnetname --address-prefixes 173.0.7.0/24 --disable-private-endpoint-network-policies true
$privateendpointsubnetid=$(az network vnet subnet show  --name $privateendpointsubnetname --resource-group $ResourceGroupName --vnet-name $vnetname --query "id")

# VNET and Private Link
$ResourceGroupName="privatefunc"

# Add VNET connectivity to function app
$ResourceGroupName="privatefunc"
az functionapp vnet-integration add -g $ResourceGroupName -n $functionAppName --vnet $vnetId --subnet $vnetsubnetname

# Create private endpoint
az network private-endpoint create --name $privateLinkName --resource-group $ResourceGroupName --subnet $privateendpointsubnetid  --connection-name privatelinkconn --private-connection-resource-id $resourceid --group-id sites

# Create Private zone
az network private-dns zone create --name $zoneName --resource-group $ResourceGroupName
az network private-dns link vnet create --name $zoneLinkName --resource-group $ResourceGroupName --registration-enabled false --virtual-network $vnetid --zone-name $zoneName
az network private-endpoint dns-zone-group create --name myZoneGroup --resource-group $ResourceGroupName --endpoint-name $privateLinkName --private-dns-zone $zoneName --zone-name $zoneName

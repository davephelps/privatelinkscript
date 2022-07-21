$ResourceGroupName="privatefunc5"
$location="northeurope"
$appName='PrivateFunctionApp2'
az group create --name $ResourceGroupName --location $location
az deployment group create --resource-group $ResourceGroupName --template-file private_func.bicep --parameters functionAppName=$appName location=$location planResourceGroup=privatefunc functionAppPlanName=PrivateFunctionAppPlan5


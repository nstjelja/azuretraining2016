Param (
    [string] $subscriptionId,
    [string] $resourceGroupName

)
Login-AzureRmAccount -SubscriptionId  $subscriptionId
New-AzureRmResourceGroup -Name $resourceGroupName -Location 'West Europe'

$vnet = New-AzureRmVirtualNetwork -Name HQTestVNet -ResourceGroupName $resourceGroupName -Location 'West Europe' -AddressPrefix 10.1.0.0/16
$vnet | Out-String

$subNet = New-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd -AddressPrefix 10.1.0.0/24 
$subNet | Out-String

Add-AzureRmVirtualNetworkSubnetConfig -Name $subNet.Name -AddressPrefix $subNet.AddressPrefix -VirtualNetwork $vnet

Set-AzureRMVirtualNetwork -VirtualNetwork $vnet


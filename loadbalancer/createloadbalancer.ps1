Param (
    [string] $subscriptionId,
    [string] $resourceGroupName

)

Login-AzureRmAccount -SubscriptionId $subscriptionId

New-AzureRmResourceGroup -Name $resourceGroupName -Location 'North Europe'

$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet1 -AddressPrefix 10.0.2.0/24 
$subnet | Out-String

$vm = New-AzureRmVirtualNetwork -Name NRPVNet -ResourceGroupName $resourceGroupName -Location 'North Europe' -AddressPrefix 10.0.0.0/16 -Subnet $subnet
$vm | Out-String

$publicIP = New-AzureRmPublicIpAddress -Name NRPPublicIP -ResourceGroupName $resourceGroupName `
            -Location 'West US' -AllocationMethod Static -DomainNameLabel loadbalacernrpnik

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-FrontEnd -PublicIpAddressId $publicIP

$beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name LB-backend

$inboundNATRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP1 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3441 -BackendPort 3389
$inboundNATRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP2 -FrontendIpConfigurationId $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -RequestPath '/HealthProbe.aspx' -Protocol Http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name HTTP -FrontendIpConfiguration $frontendIP -BackendAddressPool $beaddresspool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$nrpbl = New-AzureRmLoadBalancer -ResourceGroupName $resourceGroupName -Name NRP-LB -Location 'West US' -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNATRule2 -LoadBalancingRule $lbrule -BackendAddressPool $beaddresspool -Probe $healthProbe

$backendnic1 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name lb-nic1-be -Location 'West US' -PrivateIpAddress 10.0.2.6 -Subnet $subnet -LoadBalancerBackendAddressPool $nrpbl.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrpbl.InboundNatRules[0]

$backendnic2 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name lb-nic2-be -Location 'North Europe' -PrivateIpAddress 10.0.2.7 -Subnet $subnet -LoadBalancerBackendAddressPool $nrpbl.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrpbl.InboundNatRules[1]

$vm1 = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name "nikola1machine"
$vm2 = Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name "nikola2machine"

Add-AzureRmVMNetworkInterface -VM $vm1 -NetworkInterface $backendnic1
Add-AzureRmVMNetworkInterface -VM $vm2 -NetworkInterface $backendnic2

$nrpbl = Get-AzureRmLoadBalancer -Name $nrpbl.Name -ResourceGroupName $resourceGroupName

$backend = Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name LB-backend -LoadBalancer $nrpbl

$nic = Get-AzureRmNetworkInterface -Name $backendnic1.Name -ResourceGroupName $resourceGroupName
$nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $backend

Set-AzureRmNetworkInterface -NetworkInterface $nic
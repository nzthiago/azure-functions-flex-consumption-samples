@description('Specifies the name of the virtual network.')
param vNetName string

@description('Specifies the location.')
param location string = resourceGroup().location

@description('Specifies the name of the subnet for the Service Bus private endpoint.')
param sbSubnetName string = 'sb'

@description('Specifies the name of the subnet for Function App virtual network integration.')
param appSubnetName string = 'app'

@description('Specifies the name of the subnet for Azure Bastion.')
var bastionSubnetName = 'AzureBastionSubnet'

@description('Specifies the name of the subnet for the Azure VM.')
var vmSubnetName = 'vm'

@description('Specifies if a virtual machine should be created in the virtual network.')
param useVM bool = false

param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: sbSubnetName
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'sb')
        properties: {
          addressPrefixes: [
            '10.0.1.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: appSubnetName
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'app')
        properties: {
          addressPrefixes: [
            '10.0.2.0/23'
          ]
          delegations: [
            {
              name: 'delegation'
              id: '${resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'app')}/delegations/delegation'
              properties: {
                //Microsoft.App/environments is the correct delegation for Flex Consumption VNet integration
                serviceName: 'Microsoft.App/environments'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = if (useVM){
  name: bastionSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.4.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = if (useVM){
  name: vmSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.5.0/24'
  }
}

output sbSubnetName string = virtualNetwork.properties.subnets[0].name
output sbSubnetID string = virtualNetwork.properties.subnets[0].id
output appSubnetName string = virtualNetwork.properties.subnets[1].name
output appSubnetID string = virtualNetwork.properties.subnets[1].id
output bastionSubnetName string = useVM ? bastionSubnet.name : ''
output bastionSubnetID string =  useVM ? bastionSubnet.id : ''
output vmSubnetName string =  useVM ? vmSubnet.name : ''
output vmSubnetID string =  useVM ? vmSubnet.id : ''

param addressSpace string
param splitVnet bool = false
@minValue(1)
@maxValue(10)
param splitVnetCount int = 2
@minValue(20)
@maxValue(32)
param subnetRange int = 28
param tags object = {}
param useDnsResolver bool = false
param resourceLocation string = resourceGroup().location

var cidrs = [for i in range(0, splitVnetCount): cidrSubnet(addressSpace, subnetRange, i)]
var subnetsAddresses = array(splitVnet ? cidrs : addressSpace)

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${deployment().name}-${uniqueString(deployment().name)}'
  location: resourceLocation
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for (item, index) in subnetsAddresses: {
      name: 'subnet-${index}'
      properties: {
        addressPrefix: item
        delegations: useDnsResolver && index < 2 ?  [
          {
            name: 'Microsoft.Network.dnsResolvers'
            properties: {
              serviceName: 'Microsoft.Network/dnsResolvers'
            }
          }
        ] : []
      }
    }]
  }
}

output id string = vnet.id
output name string = vnet.name
output subnetIds array = [for (item, index) in subnetsAddresses: {
  id: vnet.properties.subnets[index].id
}]

param groupId string
param subnetRef string
param privateLinkServiceId string
param recordName string
param privateDnsZoneName string

param tags object = {
}
param resourceLocation string = resourceGroup().location

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'plink-${uniqueString(deployment().name)}'
  location: resourceLocation
  properties: {
    subnet: {
      id: subnetRef
    }
    privateLinkServiceConnections: [
      {
        name: 'plink-${uniqueString(deployment().name)}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
  tags: tags
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: recordName
  parent: privateDnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

targetScope='subscription'

param userName string
@secure()
param password string

param expirationDate string= utcNow('yyyy-MM-dd')

param resourceLocation string = deployment().location

var tags = {
  environment: 'demo'
  lab: 'basic-config'
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'labprivatelink-${deployment().name}-rg'
  location: resourceLocation
  tags: {
    AutoDelete: 'true'
    ExpirationDate: expirationDate
  }
}

module vnetWithPrivateDnsZone './modules/vnet.bicep' = {
  name: 'vnetWithPrivateDnsZone-${deployment().name}'
  scope: rg
  params: {
    addressSpace: '10.0.0.0/24'
    splitVnet: true
    splitVnetCount: 2
    subnetRange: 25
    tags: tags
  }
}

module privateDnsZone './modules/privatezone.bicep' = {
  scope: rg
  name: 'privatelink.blob.${environment().suffixes.storage}'
  params: {
    tags: tags
  }
}

module privateDnsZoneLink './modules/vnetlink.bicep' = {
  scope: rg
  name: 'vnetLink-${deployment().name}'
  params: {
    vnetId: vnetWithPrivateDnsZone.outputs.id
    privateDnsZoneName: privateDnsZone.outputs.name
    tags: tags
  }
}

module storage './modules/storage.bicep' = {
  scope: rg
  name: 'demostorage-${deployment().name}'
  params: {
    tags: tags
  }
}

module storagePrivateEndpoint './modules/privateEndpoint.bicep' = {
  scope: rg
  name: 'storagePrivateEndpoint-${deployment().name}'
  params: {
    groupId: 'blob'
    privateLinkServiceId: storage.outputs.id
    subnetRef: vnetWithPrivateDnsZone.outputs.subnetIds[0].id
    privateDnsZoneName: privateDnsZone.outputs.name
    recordName: storage.outputs.name
    tags: tags
  }
}

module vmplk './modules/vm.bicep' = {
  scope: rg
  name: 'vmplk-${deployment().name}'
  params: {
    subnetId: vnetWithPrivateDnsZone.outputs.subnetIds[1].id
    password: password
    userName: userName
    prefix: 'vmpl'
    tags: tags
  }
}

output rgName string = rg.name
output vms array = [vmplk.outputs.name]
output storageName string = storage.outputs.name

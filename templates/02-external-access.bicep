targetScope='subscription'

param userName string
@secure()
param password string

param expirationDate string= utcNow('yyyy-MM-dd')
param resourceLocation string = deployment().location


var tagsInternal = {
  environment: 'demo'
  lab: 'external-access'
  'lab-purpose': 'customer A'
}
var tagsExternal = {
  environment: 'demo'
  lab: 'external-access'
  'lab-purpose': 'customer B'
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
    tags: tagsInternal
  }
}

module vnetWithoutPrivateDnsZone './modules/vnet.bicep' = {
  scope: rg
  name: 'vnetWithoutPrivateDnsZone-${deployment().name}'
  params: {
    addressSpace: '10.1.0.0/24'
    splitVnet: true
    splitVnetCount: 2
    subnetRange: 25
    tags: tagsExternal
  }
}

module privateDnsZone './modules/privatezone.bicep' = {
  scope: rg
  name: 'privatelink.blob.${environment().suffixes.storage}'
  params: {
    tags: tagsInternal
  }
}

module privateDnsZoneLink './modules/vnetlink.bicep' = {
  scope: rg
  name: 'vnetLink-${deployment().name}'
  params: {
    vnetId: vnetWithPrivateDnsZone.outputs.id
    privateDnsZoneName: privateDnsZone.outputs.name
    tags: tagsInternal
  }
}

module storage './modules/storage.bicep' = {
  scope: rg
  name: 'demostorage-${deployment().name}'
  params: {
    tags: tagsInternal
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
    tags: tagsInternal
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
    tags: tagsInternal
  }
}

module vmnoplk './modules/vm.bicep' = {
  scope: rg
  name: 'vmnoplk-${deployment().name}'
  params: {
    subnetId: vnetWithoutPrivateDnsZone.outputs.subnetIds[1].id
    password: password
    userName: userName
    prefix: 'vmnopl'
    tags: tagsExternal
  }
}

output rgName string = rg.name
output vms array = [vmplk.outputs.name, vmnoplk.outputs.name]
output storageName string = storage.outputs.name

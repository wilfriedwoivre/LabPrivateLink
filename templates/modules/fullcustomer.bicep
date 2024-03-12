targetScope = 'resourceGroup'

param userName string
@secure()
param password string
param addressSpace string
param tags object = {}

param noStorage bool = false
param noPrivateDNSZone bool = false
param noDnsResolver bool = true

param customerAStorageName string = ''

module vnetWithPrivateDnsZone './vnet.bicep' = {
  name: 'vnetWithPrivateDnsZone-${deployment().name}'
  params: {
    addressSpace: addressSpace
    splitVnet: true
    splitVnetCount: 4
    subnetRange: 26
    tags: tags
    useDnsResolver: !noDnsResolver
  }
}

module privateDnsZone './privatezone.bicep' = if (!noPrivateDNSZone) {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  params: {
    tags: tags
  }
}

module privateDnsZoneLink './vnetlink.bicep' = if (!noPrivateDNSZone) {
  name: 'vnetLink-${deployment().name}'
  params: {
    vnetId: vnetWithPrivateDnsZone.outputs.id
    privateDnsZoneName: privateDnsZone.outputs.name
    tags: tags
  }
}

module storage './storage.bicep' = if (!noStorage) {
  name: 'demostorage-${deployment().name}'
  params: {
    tags: tags
  }
}

module storagePrivateEndpoint './privateEndpoint.bicep' = if (!noStorage && !noPrivateDNSZone) {
  name: 'storagePrivateEndpoint-${deployment().name}'
  params: {
    groupId: 'blob'
    privateLinkServiceId: noStorage ? '' : storage.outputs.id
    subnetRef: vnetWithPrivateDnsZone.outputs.subnetIds[2].id
    privateDnsZoneName: noPrivateDNSZone ? '' : privateDnsZone.outputs.name
    recordName: noStorage ? '' : storage.outputs.name
    tags: tags
  }
}

module vm './vm.bicep' = {
  name: 'vm-${deployment().name}'
  params: {
    subnetId: vnetWithPrivateDnsZone.outputs.subnetIds[3].id
    password: password
    userName: userName
    prefix: 'vm'
    tags: tags
  }
}

module resolver './dnsresolver.bicep' = if (!noDnsResolver) {
  name: 'dnsresolver-${deployment().name}'
  params: {
    tags: tags
    virtualNetworkId: vnetWithPrivateDnsZone.outputs.id
    subnets: vnetWithPrivateDnsZone.outputs.subnetIds
    storageDomainName: customerAStorageName
  }

}

output vms array = [ vm.outputs.name ]
output storageName string = noStorage ? 'nostorage' : storage.outputs.name

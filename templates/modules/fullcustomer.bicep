targetScope = 'resourceGroup'

param userName string
@secure()
param password string
param addressSpace string
param tags object = {}

param noPrivateDNSZone bool = false
param noDnsResolver bool = true

@minValue(0)
@maxValue(10)
param storageCount int = 1

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

module storage './storage.bicep' = [for i in range(0, storageCount): {
  name: 'demostorage-${deployment().name}-${i}'
  params: {
    tags: tags
  }
}]


module storagePrivateEndpoint './privateEndpoint.bicep' = [for i in range(0, storageCount): if (!noPrivateDNSZone) {
  name: 'storagePrivateEndpoint-${deployment().name}-${i}'
  params: {
    groupId: 'blob'
    privateLinkServiceId: storage[i].outputs.id
    subnetRef: vnetWithPrivateDnsZone.outputs.subnetIds[2].id
    privateDnsZoneName: noPrivateDNSZone ? '' : privateDnsZone.outputs.name
    recordName: storage[i].outputs.name
    tags: tags
  }
}]

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
output storageNames array = [for i in range(0, storageCount): {
  name: storage[i].outputs.name
}]

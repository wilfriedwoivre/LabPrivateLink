param tags object = {
}

resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

output id string = privateZone.id
output name string = privateZone.name

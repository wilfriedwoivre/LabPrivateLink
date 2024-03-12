Write-Host "Deploy to Azure"

. "$PSScriptRoot\common.ps1"

$userName = 'randomusr'
$password = Generate-Password | ConvertTo-SecureString -AsPlainText -Force


[Array]$templateNames = (ls -Path ".\templates" -Filter "*.bicep").Name
1..$templateNames.Length | foreach-object { Write-Output "$($_): $($templateNames[$_-1])" }


Write-Output "Please choose a template:"

[ValidateScript({ $_ -ge 1 -and $_ -le $templateNames.Length })]
[int]$number = Read-Host "Press the number to select a template"

if ($?) {

    $template = $templateNames[$number - 1]
    Write-Output "You choose: $template"
    $deploymentName = ($($templateNames[$number - 1]) -split '.bicep')[0]

    $outputs = New-AzDeployment -Name $deploymentName -Location 'west europe' -TemplateFile ".\templates\$template" -userName $userName -password $password -WarningAction SilentlyContinue  

    $outputs
    $vms = $outputs.Outputs.vms.Value

    $filePath = ".\outputs\$($deploymentName)-$((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmm")).json"

    mkdir -Force -Path ".\outputs" | Out-Null
    "" | Out-File -FilePath $filePath  -Encoding utf8 -Force

    [Array]$storageNames = @()
    if ($null -eq $outputs.Outputs.storageNames) {
        $storageNames += @{ name = $outputs.Outputs.storageName.Value }
    } else {
        $storageNames = ($outputs.Outputs.storageNames | convertto-json | ConvertFrom-Json).Value
    }
    $cmds = @()
    foreach ($storageName in $storageNames) {
        $cmds += "nslookup $($storageName.name).blob.core.windows.net"
        $cmds += "nslookup $($storageName.name).blob.core.windows.net 8.8.8.8"
    }
    
    foreach ($vm in $vms) {
        foreach ($cmd in $cmds) {
            Write-Information "Execute $cmd on $vm"
            $result = Invoke-AzVMRunCommand -resourceGroupName $outputs.Outputs.rgName.Value -VMName $vm -CommandId 'RunShellScript' -ScriptString $cmd
    
            "[VM]" | Out-File -Append -FilePath $filePath -Encoding utf8
            $vm | Out-File -Append -FilePath $filePath -Encoding utf8
            "[Run cmd]" | Out-File -Append -FilePath $filePath -Encoding utf8
            $cmd | Out-File -Append -FilePath $filePath -Encoding utf8
            $result.Value[0].Message | Out-File -Append -FilePath $filePath -Encoding utf8

            '------------------------------------------' | Out-File -Append -FilePath $filePath -Encoding utf8
        }
    } 

    Write-Host "See tests results -> $filePath"
}

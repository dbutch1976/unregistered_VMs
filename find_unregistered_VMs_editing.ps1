#$Datastores = Get-Datastore -Name "ddc1_pod3_infra_fc_vol02_lun01"
$Datastores = Get-Datastore | Where-Object {$_.name -notmatch "local" -and $_.name -notmatch "NFS"}
$unregistered = @()
ForEach ($datastore in $datastores) {
    $psds = Get-Datastore -Name $datastore
    New-PSDrive -Name TgtDS -Location $psds -PSProvider VimDatastore -Root '\' | Out-Null
    $VMXS = Get-ChildItem -Path TgtDS: -Recurse -Filter *.vmx | Where-Object {$_.name -notmatch "vCLS-*" -and $_.name -notmatch "zerto*"}
    Write-Host "Starting $datastore"
    foreach ($VMX in $VMXS) {
        try {
                Get-VM -datastore $datastore -name $VMX.name.replace('.vmx','') -ErrorAction:Stop | Out-Null
                } 
            catch {
                $unregistered += [PSCustomObject] @{
                    Name = $vmx.Name
                    DatastoreFullPath = $vmx.DatastoreFullPath
                    LastWriteTime = $vmx.LastWriteTime
                }
            }
        }
        Write-Host "Done"
        Remove-PSDrive -Name TgtDS
}
$unregistered | export-csv -Path C:\output\ddc1-vc02.dm.mckesson.com\Orphaned_VMDKs\sources\UnregisteredVms1.csv -NoTypeInformation
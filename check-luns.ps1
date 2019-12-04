# Need to connect  to v-Center host before running this
# Can be done via Power-Cli - Connect-VIServer vCenterName
$ESXHosts = Get-VMHost
$output = "{0},{1},{2},{3},{4},{6}`n`r" -f "Hostname", "Device Name", "VAAIPluginName", "ATSStatus", "CloneStatus", "DeleteStatus", "ZeroStatus"
foreach($EsxHost in $ESXHosts){
  $esxcli = Get-VMHost $EsxHost | Get-EsxCli -V2
  $esxclioutput = $esxcli.storage.core.device.vaai.status.get.Invoke()
  foreach ($LUN in $esxclioutput){
    #Output should be: Hostname, Device Name, VAAIPluginName, ATSStatus, CloneStatus, DeleteStatus, ZeroStatus
    $output = "{0}{1},{2},{3},{4},{6},{7}`n`r" -f $output, $esxHost, $LUN.Device, $LUN.VAAIPluginName, $LUN.ATSStatus,$LUN.CloneStatus, $LUN.DeleteStatus, $LUN.ZeroStatus
  }
}

Write-Host $output
# Starts collects state of VAAI for all LUNs Connected to All ESX hosts in a particular vCenter Server.

# Define v-Center Name 
$vCenterName = "VC1"

# Inialize the job tracker array
$arrayJobs = @()

### Code Begins Here

# Connect to vCenter Server
$connection = Connect-VIServer $vCenterName

# Get List of ESX Hosts Connected to vCenter Server
$ESXHosts = Get-VMHost

# Loop through list of Hosts and Execute a Job to collect the LUN information. This is run multi-threaded so that we don't have to wait for completion to get next server.
foreach($EsxHost in $ESXHosts){
  $arrayJobs += Start-Job -ScriptBlock {
    # Import Power-cli Modules
    if (!(Get-module | where {$_.Name -eq "VMware.VimAutomation.Core"})) {Import-Module VMware.VimAutomation.Core}
    $connection - Connect-VIServer $args[0]
    $esxcli = Get-VMHost $args[1] | Get-EsxCli -V2
    $esxclioutput = $esxcli.storage.core.device.vaai.status.get.Invoke()
    foreach ($LUN in $esxclioutput) {
      #Output should be: Hostname, Device Name, VAAIPluginName, ATSStatus, CloneStatus, DeleteStatus, ZeroStatus
      $output = "{0},{1},{2},{3},{4},{5},{6}" -f $args[1], $LUN.Device, $LUN.VAAIPluginName, $LUN.ATSStatus,$LUN.CloneStatus, $LUN.DeleteStatus, $LUN.ZeroStatus
      Write-Output $output
    }
  } -ArgumentList $vCenterName, $EsxHost
}

# Initialize loop completion variable
$complete = $false
while (-not $complete) {
    $arrayJobsInProgress = $arrayJobs |
        Where-Object { $_.State -match 'running'}
    if (-not $arrayJobsInProgress) { $complete = $true }
}

$output = "{0},{1},{2},{3},{4},{5},{6}" -f "Hostname", "Device Name", "VAAIPluginName", "ATSStatus", "CloneStatus", "DeleteStatus", "ZeroStatus"
Write-Output $output
foreach($job in $arrayJobs) {
  $job | Receive-Job
}


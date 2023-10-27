param(
    [Parameter(Position=0, Mandatory=$true, HelpMessage="IP or FQDN of the Veeam B&R Server")]
    [string]$VBRHost,
    
    [Parameter(Position=1, Mandatory=$true, HelpMessage="User credential for the Veeam B&R Server")]
    [string]$VBRUser,
    
    [Parameter(Position=2, Mandatory=$true, HelpMessage="Password credential for the Veeam B&R Server")]
    [string]$VBRPassword  
)

function Connect-Veeam {
    # Disconnect from Veeam server just in case
    Disconnect-VBRServer

    # Connect to the Veeam B&R Server
    Connect-VBRServer -User $VBRUser -Password $VBRPassword -Server $VBRHost
}

function Get-JobData {
    # Get names and results of backups
    $VBRJobs = Get-VBRJob | Select Name, {$_.GetLastResult()} | Group Name

    # Get names of disabled backups
    $VBRDisabledJobs = Get-VBRJob | where {$_.IsScheduleEnabled -eq $False} | select Name
    
    # Remove disabled jobs
    $VBRJobs = $VBRJobs | Where-Object {$VBRDisabledJobs.Name -notcontains $_.Name} 

    # Get value for main sensor
    $resultMain = 0
    foreach ($c in $VBRJobs) {
        $check = $c.Group | select -ExpandProperty '$_.GetLastResult()'
        # also check if result is already 2 -> it has to stay 2
        if ($check -like 'Warning' -and $resultMain -ne 2) {
            $resultMain = 1
        }
        if ($check -like 'Failed') {
            $resultMain = 2
        }
    }

    # Return job data
    return $resultMain, $VBRJobs
}

function Write-Output {
    # Receive job data
    $resultMain, $VBRJobs = Get-JobData

    # Start PRTG XML return message
    Write-Host "<prtg>"

    # Write main sensor return message
    Write-Host
        "<result>"
        "<channel>Veeam Backups</channel>"
        "<value>$resultMain</value>"
        "<LimitMaxWarning>0</LimitMaxWarning>"
        "<LimitWarningMsg>Atleast one backup with Warning</LimitWarningMsg>"
        "<LimitMaxError>1</LimitMaxError>"
        "<LimitErrorMsg>Atleast one backup with Error</LimitErrorMsg>"
        "<LimitMode>1</LimitMode>"
        "</result>"

    # Call "Write-Result" function for every object
    foreach ($b in $VBRJobs) {
        $VMName = $b.Group | Select -ExpandProperty 'Name'
        $result = $b.Group | select -ExpandProperty '$_.GetLastResult()'
        if($result -eq 'Success') {
            $value = 0
        }
        elseif($result -eq 'Warning') {
            $value = 1
        }
        elseif($result -eq 'Failed') {
            $value = 2
        }
        else {
            $value = 3
        }
        Write-Result $VMName $result $value
    }

    # End PRTG XML return message
    Write-Host "</prtg>"
}

function Write-Result {
    param(
        [Parameter(Position=0, Mandatory=$true, HelpMessage="Name of the backup job")]
        [string]$name,
    
        [Parameter(Position=1, Mandatory=$true, HelpMessage="Result of the backup job")]
        [string]$result,
    
        [Parameter(Position=2, Mandatory=$true, HelpMessage="Value from 0 to 3 for PRTG state classification")]
        [string]$value 
    )

    # Write XML return message
    Write-Host
        "<result>"
        "<channel>$name</channel>"
        "<CustomUnit>$result</CustomUnit>"
        "<value>$value</value>"
        "<LimitMaxWarning>1</LimitMaxWarning>"
        "<LimitWarningMsg></LimitWarningMsg>"
        "<LimitMaxError>2</LimitMaxError>"
        "<LimitErrorMsg></LimitErrorMsg>"
        "<LimitMode>1</LimitMode>"
        "</result>"
}

# Load required PS snapin
Add-PSSnapin VeeamPSSnapin

# Call functions
Connect-Veeam
Write-Output

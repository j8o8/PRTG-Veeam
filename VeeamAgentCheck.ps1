param(
    [Parameter(Position=0, Mandatory=$true, HelpMessage="IP or FQDN of the Veeam B&R Server")]
    [string]$VBRHost,
    
    [Parameter(Position=1, Mandatory=$true, HelpMessage="User credential for the Veeam B&R Server")]
    [string]$VBRUser,
    
    [Parameter(Position=2, Mandatory=$true, HelpMessage="Password credential for the Veeam B&R Server")]
    [string]$VBRPassword  
)

#region CONFIGURATION
    # Prioritised agents:
        $aPrio = 'PLACEHOLDER'
        # Example: $aPrio = 'NAME1', 'NAME2', 'NAME3'

    # All treshholds have to be determined in days
        # Warning treshhold for prioritised agents
            $dWarnPrio = 1
        # Error treshhold for prioritised agents
            $dErrPrio = 2
        # Warning treshhold for non important agents
            $dWarn = 7
        # Error treshhold for non important agents
            $dErr = 14
#endregion CONFIGURATION

function Connect-Veeam {
    # Disconnect from Veeam server just in case
    Disconnect-VBRServer

    # Connect to the Veeam B&R Server
    Connect-VBRServer -User $VBRUser -Password $VBRPassword -Server $VBRHost
}

function Get-JobData {
    # Set variable for today
    $today = Get-Date

    # Get names and days since last successfull result of endpoint backups (excluding orphaned jobs)
    $VBRDays = Get-VBRBackup | ?{$_.JobType -eq 'EndpointBackup' -and $_.JobId -ne '00000000-0000-0000-0000-000000000000'} |
    Get-VBRRestorePoint |
    Sort vmname, CreationTime |
    Select vmname, @{n='d'; e={(New-TimeSpan -Start $_.creationtime -End $today).days}} |
    Group vmname

    # Return job data
    return $VBRDays
}

function Write-Output {
    # Receive job data
    $VBRDays = Get-JobData

    # Start PRTG XML return message
    Write-Host '<prtg>'

    # Get value for main sensor
    $resultMain = 0
    foreach ($d in $VBRDays) {
        $age = $d.Group | select -ExpandProperty 'd' -last 1
        if ($age -gt $dWarn -and $resultMain -le 2) {
            $resultMain = 1
        }
        if ($age -gt $dErr) {
            $resultMain = 2
        }
    }

    # Write main sensor return message
    Write-Host
        '<result>'
        '<channel>Veeam Agents</channel>'
        "<value>$resultMain</value>"
        '<LimitMaxWarning>1</LimitMaxWarning>'
        '<LimitWarningMsg></LimitWarningMsg>'
        '<LimitMaxError>2</LimitMaxError>'
        '<LimitErrorMsg></LimitErrorMsg>'
        '<LimitMode>1</LimitMode>'
        '</result>'

    # Call "Write-Result" function for every object
    foreach ($d in $VBRDays) {
        $VMName = $d.Group | Select -ExpandProperty 'vmname' -last 1
        $age = $d.Group | Select -ExpandProperty 'd' -last 1
        if ($aPrio -contains $VMName) {
            Write-Result $VMName $age $dWarnPrio $dErrPrio
        } else {
            Write-Result $VMName $age $dWarn $dErr
        }
    }

    # End PRTG XML return message
    Write-Host '</prtg>'
}

function Write-Result {
    param(
            [Parameter(Position=0, Mandatory=$true, HelpMessage="Name of the backup job")]
            [string]$name,
    
            [Parameter(Position=1, Mandatory=$true, HelpMessage="Days since the backup job was successful")]
            [string]$days,
    
            [Parameter(Position=2, Mandatory=$true, HelpMessage="Warning treshhold")]
            [string]$warn,

            [Parameter(Position=3, Mandatory=$true, HelpMessage="Error treshhold")]
            [string]$err
    )

    # Write XML return message
    Write-Host
        '<result>'
        "<channel>$name</channel>"
        '<CustomUnit>Days</CustomUnit>'
        "<value>$days</value>"
        "<LimitMaxWarning>$warn</LimitMaxWarning>"
        '<LimitWarningMsg></LimitWarningMsg>'
        "<LimitMaxError>$err</LimitMaxError>"
        '<LimitErrorMsg></LimitErrorMsg>'
        '<LimitMode>1</LimitMode>'
        '</result>'
}

# Load required PS snapin
Add-PSSnapin VeeamPSSnapin

# Call functions
Connect-Veeam
Write-Output

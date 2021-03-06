$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xWSManHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name
	)

	$MaxConcurrentUsers = (Get-Item -Path "WSMan:\$Name\Shell\MaxConcurrentUsers").Value
	$MaxProcessesPerShell = (Get-Item -Path "WSMan:\$Name\Shell\MaxProcessesPerShell").Value
	$MaxMemoryPerShellMB = (Get-Item -Path "WSMan:\$Name\Shell\MaxMemoryPerShellMB").Value
	$MaxShellsPerUser = (Get-Item -Path "WSMan:\$Name\Shell\MaxShellsPerUser").Value

	$returnValue = @{
		Name = $Name
		MaxConcurrentUsers = $MaxConcurrentUsers
		MaxProcessesPerShell = $MaxProcessesPerShell
    	MaxMemoryPerShellMB = $MaxMemoryPerShellMB
		MaxShellsPerUser = $MaxShellsPerUser
	}

    $returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.Byte]
		$MaxConcurrentUsers,

		[System.String]
		$MaxProcessesPerShell,

		[System.String]
		$MaxMemoryPerShellMB,

		[System.String]
		$MaxShellsPerUser
	)

    foreach($WSManSetting in @('MaxConcurrentUsers','MaxProcessesPerShell','MaxMemoryPerShellMB','MaxShellsPerUser'))
    {
        if($PSBoundParameters.ContainsKey($WSManSetting))
        {
            Write-Verbose "Setting WSMan:\$Name\Shell\$WSManSetting to $((Get-Variable -Name $WSManSetting).Value)"
            Set-Item -Path "WSMan:\$Name\Shell\$WSManSetting" -Value (Get-Variable -Name $WSManSetting).Value
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String]
		$MaxConcurrentUsers,

		[System.String]
		$MaxProcessesPerShell,

		[System.String]
		$MaxMemoryPerShellMB,

		[System.String]
		$MaxShellsPerUser
	)

    if((Get-Service -Name WinRM).Status -ne 'Running')
    {
        throw New-TerminatingError -ErrorType WinRMServiceNotRunning -ErrorCategory InvalidResult
    }

    $WSMan = Get-TargetResource -Name $Name

    $result = $true
        
    foreach($WSManSetting in @('MaxConcurrentUsers','MaxProcessesPerShell','MaxMemoryPerShellMB','MaxShellsPerUser'))
    {
        if($PSBoundParameters.ContainsKey($WSManSetting))
        {
            $CurrentWSManSetting = $WSMan."$WSManSetting"
            $DesiredWSManSetting = (Get-Variable -Name $WSManSetting).Value
            if($CurrentWSManSetting -ne $DesiredWSManSetting)
            {
                Write-Verbose "Failed $WSManSetting test, setting is $CurrentWSManSetting and should be $DesiredWSManSetting"
                $result = $false
            }
        }
    }

	$result
}


Export-ModuleMember -Function *-TargetResource
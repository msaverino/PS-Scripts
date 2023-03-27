<#
	.SYNOPSIS
		The Remove-GPOUnknownSIDs function removes the broken SIDs from a GPO by analyzing its permissions. Broken SIDs are SIDs that cannot be resolved to a valid security principal.
	
	.DESCRIPTION
		The Remove-GPOUnknownSIDs function removes the broken SIDs from a GPO by analyzing its permissions. Broken SIDs are SIDs that cannot be resolved to a valid security principal. These can be the result of deleted or orphaned accounts, or of accounts from a different domain or forest that the GPO cannot resolve.
	
	.PARAMETER Id
		Specifies the GPO ID to analyze.
	
	.PARAMETER DisplayName
		Specifies the GPO display name to analyze. This parameter has an alias of GpoDisplayName and Name.
	
	.PARAMETER Server
		Specifies the domain controller or AD LDS instance to connect to. This parameter defaults to the current user's domain.
	
	.EXAMPLE
		PS C:\> Remove-GPOUnknownSIDs -Id '16e0b32b-8c4e-4c9a-965a-0382d8e797b2'
		
		Removes the broken SIDs in the GPO with ID 16e0b32b-8c4e-4c9a-965a-0382d8e797b2, in the current user's domain.

	.EXAMPLE
		PS C:\> Get-GPO -DisplayName 'Default Domain Policy' | Remove-GPOUnknownSIDs
	
	.NOTES
		Author: Michael Saverino
		Date: 03/26/2023
		Version: 1.0
#>
function Remove-GPOUnknownSIDs
{
	[CmdletBinding(DefaultParameterSetName = 'ByDisplayName',
				   SupportsShouldProcess = $true)]
	param
	(
		[Parameter(ParameterSetName = 'ById',
				   Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Identity')]
		[string]$Id,
		[Parameter(ParameterSetName = 'ByDisplayName',
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[Alias('GpoDisplayName', 'Name')]
		[string]$DisplayName,
		[string]$Server = $env:USERDOMAIN
	)
	
	begin
	{
		# Import the Group Policy module if not already loaded
		if (-not (Get-Module GroupPolicy))
		{
			Import-Module GroupPolicy
		}
	}
	
	Process
	{
		# Find the GPO
		if ($Id)
		{
			$gpo = Get-GPO -Server $Server -Id $Id -ErrorAction SilentlyContinue
		}
		elseif ($DisplayName)
		{
			$gpo = Get-GPO -Server $Server -DisplayName $DisplayName -ErrorAction SilentlyContinue
		}
		
		# Validate the GPO exists
		if (-not ($gpo))
		{
			Write-Warning "GPO not found on server $Server."
			return
		}
		
		# Get the current GPO Security
		$gposecurity = $gpoObject.GetSecurityInfo()
		
		# Find all the broken SIDs.
		$unknownSIDS = (Get-GPPermissions -Guid $gpo.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.SidType -eq "Unknown" } | Select-Object -ExpandProperty Sid).Value
		
		# Validate we have broken SID's
		if (-not ($unknownSIDS))
		{
			# Return if we do not have any.
			Write-Verbose "No Unkown SIDs for $($gpo.DisplayName)"
			return
		}
		
		
		Write-Verbose "There are a total of $($unknownSIDS.Count) unkown Sid(s)."
		foreach ($unknownsid in $unknownSIDS)
		{
			# If we have "-WhatIf"
			if ($PSCmdlet.ShouldProcess($gpo.DisplayName, "Remove SID $unknownsid"))
			{
				Write-Verbose "Removing SID $unknownsid"
				$gposecurity.RemoveTrustee($unknownsid)
			}
		}
		
		# Commit the change.
		if ($PSCmdlet.ShouldProcess($gpo.DisplayName, "Save Changes"))
		{
			$GPO.SetSecurityInfo($gposecurity)
		}
	}
}

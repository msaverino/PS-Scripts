<#
	.SYNOPSIS
		Gets the broken SIDs in a Group Policy Object (GPO).
	
	.DESCRIPTION
		The Get-GPOUnkownSids function retrieves the broken SIDs in a GPO by analyzing its permissions. Broken SIDs are SIDs that cannot be resolved to a valid security principal. These can be the result of deleted or orphaned accounts, or of accounts from a different domain or forest that the GPO cannot resolve.
	
	.PARAMETER Identity
		Specifies the GPO to analyze. You can specify the GPO ID or display name, as a string. This parameter is mandatory and can accept pipeline input.
	
	.PARAMETER Server
		Specifies the domain controller or AD LDS instance to connect to. This parameter defaults to the current user's domain. If you specify multiple values, the cmdlet selects the domain controller or AD LDS instance with the lowest priority (closest match).
	
	.PARAMETER DisplayName
		Specifies the GPO display name to analyze. This parameter is an alias for the GpoDisplayName parameter.
	
	.EXAMPLE
		PS C:\> Get-GPOUnkownSids -Id '16e0b32b-8c4e-4c9a-965a-0382d8e797b2'
		
		Gets the broken SIDs in the GPO with ID 16e0b32b-8c4e-4c9a-965a-0382d8e797b2, in the current user's domain.
	
	.EXAMPLE
		PS C:\> Get-GPO -DisplayName 'Default Domain Policy' | Get-GPOUnkownSids
		
		Gets the broken SIDs in the GPO named 'Default Domain Policy', using pipeline input to pass the GPO object to the function.
	
	.NOTES
		Author: Michael Saverino
		Date: 03/26/2023
		Version: 1.0
#>
function Get-GPOUnkownSids
{
	[CmdletBinding(DefaultParameterSetName = 'ByDisplayName')]
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
		
		# Find all the broken SIDs.
		$unkownSids = (Get-GPPermissions -Guid $gpo.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.SidType -eq "Unknown" } | Select-Object -ExpandProperty Sid).Value
		
		if (-not ($unkownSids))
		{
			Write-Verbose "There are no Unkown SIDS."
		}
		return $unkownSids
	}
}

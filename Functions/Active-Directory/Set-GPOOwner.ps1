<#
	.SYNOPSIS
	A PowerShell function to set the owner of a GPO to a specified Active Directory group.
	.DESCRIPTION
	The Set-GPOOwner function allows you to set the owner of a Group Policy Object (GPO) to a specified Active Directory group. By default, the function will set the owner to the "Domain Admins" group in the default domain.
	.PARAMETER GPOId
	The ID of the GPO you would like to update.
	.PARAMETER Domain
	The domain where the GPO resides. The default value is "ad.saverino.win".
	.PARAMETER GroupName
	The name of the Active Directory group you would like to set as the owner of the GPO. The default value is "Domain Admins".
	.EXAMPLE
	PS C:> "GPO-ID" | Set-GPOOwner
	This example sets the owner of the "GPO-ID" GPO to the "Domain Admins" group in the default domain.
	.NOTES
	Author: Michael Saverino
	Date: 03/26/2023
	Version: 1.0
#>
function Set-GPOOwner {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[string]$GPOId,
		[string]$Domain = 'ad.saverino.win',
		[string]$GroupName = 'Domain Admins'
	)
	
	# Get the specified Active Directory group
	$DomainGroup = Get-ADGroup -Identity $GroupName -Server $Domain
	
	# Process each GPO ID passed in via pipeline
	Process
	{
		try {
			# Format the GPO ID as a string
			$WorkingGPOID = "{$GPOID}"
			
			# Get the GPO object
			$GPO = Get-ADObject -Filter "Name -like '$WorkingGPOID'"
			
			# Create a SecurityIdentifier object for the specified AD group
			$Owner = New-Object System.Security.Principal.SecurityIdentifier ($DomainGroup.SID)
			
			# Get the Access Control List (ACL) for the GPO
			$ACL = Get-Acl -Path "ad:$($GPO.DistinguishedName)"
			
			# Set the owner of the ACL to the specified AD group
			$ACL.SetOwner($Owner)
			
			# Set the ACL on the GPO object
			Set-Acl -Path "ad:$($GPO.DistinguishedName)" -AclObject $ACL
		}
		catch {
			Write-Host "Unable to update the GPO: $($WorkingGPO)" -BackgroundColor Red -ForegroundColor white
		}
	}
}

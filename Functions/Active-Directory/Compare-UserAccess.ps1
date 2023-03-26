<#
	.SYNOPSIS
	A PowerShell function to compare user access and highlight the differences in an Excel file.

	.DESCRIPTION
	The Compare-UserAccess function allows you to compare the access rights of multiple users and output the results in an Excel file. The function supports highlighting the differences in access rights between the users with color-coded boxes.

	.PARAMETER Users
	A string array of the user(s) you would like to lookup.

	.PARAMETER ExcelFilePath
	The output folder and file name of the Excel file. If the file already exists, the function will append to it.

	.PARAMETER Domain
	The domain you would like to lookup. This can be a string array if you want to compare more than two domains.

	.PARAMETER ColorBoxes
	A switch parameter to choose whether to highlight the differences in access rights between the domains with color-coded boxes. The default value is $false.

	.EXAMPLE
	PS C:> Compare-UserAccess -Users "m_saverino", "k_smith" -ExcelFilePath "C:\temp\UserCompare.xlsx"

		This example compares the access rights of the "m_saverino" and "k_smith" users in the default domain and outputs the results in the "C:\temp\UserCompare.xlsx" file.


	.NOTES
	Author: Michael Saverino
	Date: 03/26/2023
	Version: 1.1
#>



function Compare-UserAccess
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[Alias('Accounts', 'Profiles')]
		[string[]]$Users,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[ValidateNotNullOrEmpty()]
		[Alias('Excel', 'Dir', 'ExcelPath')]
		[string]$ExcelFilePath,
		[Parameter(Position = 3)]
		[Alias('Server')]
		[string]$Domain = $env:USERDNSDOMAIN,
		[Parameter(Position = 4)]
		[Alias('HighlightBoxes')]
		[bool]$ColorBoxes = $false
	)
	
	# Create a new Excel workbook
	$excel = New-Object -ComObject Excel.Application
	$workbook = $excel.Workbooks.Add()
	$worksheet = $workbook.Worksheets.Item(1)
	
	# Set the initial row and column values
	$row = 1
	$col = 1
	
	# Write the Title, Description, and Info note.
	$worksheet.Cells.Item($row, $col) = "Group Name"
	$col++
	
	$worksheet.Cells.Item($row, $col) = "Group Description"
	$col++
	
	$worksheet.Cells.Item($row, $col) = "Group Information"
	$col++
	
	# Write the user names to the spreadsheet
	foreach ($user in $Users)
	{
		$displayName = (Get-ADUser -Identity $user -Properties DisplayName | Select-Object -Property DisplayName).DisplayName
		$worksheet.Cells.Item($row, $col) = "$user ($displayName)"
		$col++
	}
	
	# Get a list of all groups that at least one of the users is a member of
	$groups = foreach ($user in $Users)
	{
		Get-ADUser -Server $Domain -Identity $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Get-ADGroup -Server $Domain -Properties Description, Info | Select-Object Name, Description, Info -Unique
	}
	
	# Loop through each group and check which users are members
	foreach ($group in $groups)
	{
		$groupRow = $row + 1
		$groupCol = 1
		
		# Write the group information to the spreadsheet
		$worksheet.Cells.Item($groupRow, $groupCol) = $group.Name
		$groupCol++
		$worksheet.Cells.Item($groupRow, $groupCol) = $group.Description
		$groupCol++
		$worksheet.Cells.Item($groupRow, $groupCol) = $group.Info
		
		# Loop through each user and check if they are a member of the group
		foreach ($user in $Users)
		{
			$userCol = $Users.IndexOf($user) + 4
			$isMember = (Get-ADUser -Server $Domain -Identity $user -Properties MemberOf).MemberOf | Get-ADGroup -Server $Domain | Where-Object { $_.Name -eq $group.Name } | Select-Object -First 1
			if ($isMember)
			{
				$worksheet.Cells.Item($groupRow, $userCol) = "Yes"
				if ($ColorBoxes)
				{
					$worksheet.Cells.Item($groupRow, $userCol).Interior.ColorIndex = 4 # Set the cell background color to red
				}
			}
			else
			{
				$worksheet.Cells.Item($groupRow, $userCol) = "No"
				if ($ColorBoxes)
				{
					$worksheet.Cells.Item($groupRow, $userCol).Interior.ColorIndex = 3 # Set the cell background color to red
				}
			}
		}
		
		# Set the cell background color to green if all users are members of the group
		$groupMembers = Get-ADGroupMember -Server $Domain -Identity $group.Name -Recursive | Select-Object -ExpandProperty SamAccountName
		if (($groupMembers | Where-Object { $Users -contains $_ }).Count -eq $Users.Count)
		{
			$worksheet.Range("A$groupRow:X$groupRow").Interior.ColorIndex = 4 # Set the cell background color to green
		}
		
		$row++
	}
	
	# Autofit the columns
	$worksheet.Columns.AutoFit() | Out-Null
	
	# Save the workbook and close Excel
	$workbook.SaveAs($ExcelFilePath)
	$excel.Quit()
}

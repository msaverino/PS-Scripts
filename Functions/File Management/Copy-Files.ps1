<#
.SYNOPSIS
Copies image and video files from a source directory to a destination directory, grouping them into subdirectories based on file type and adding a unique number to the file name if a duplicate is detected.
.DESCRIPTION
The `Copy-Files` function scans the source directory specified by the `-src` parameter for image and video files (including .jpg, .jpeg, .png, .gif, .bmp, .mp4, .avi, and .mov file extensions) and copies them to the destination directory specified by the `-dst` parameter. The `-baseFolder` parameter is used to specify a subdirectory within the destination directory where the copied files will be placed.

The function groups the copied files into subdirectories based on their file type (e.g. "Images" for image files and "Videos" for video files). If a file with the same name as the copied file already exists in the destination directory, a unique number is added to the file name to avoid overwriting it (e.g. "1 - image.jpg", "2 - image.jpg", etc.).

The function also checks the integrity of the copied files by calculating the MD5 hash of the original file and the copied file, and comparing the two hashes. If the hashes do not match, a warning message is displayed indicating that the copied file may be corrupt.
.PARAMETER src
Specifies the path to the source directory where the image and video files are located. The default value is "F:\".

.PARAMETER dst
Specifies the path to the destination directory where the copied files will be placed. The default value is "Z:\".

.PARAMETER baseFolder
Specifies the name of the subdirectory within the destination directory where the copied files will be placed. This parameter is mandatory and must not contain any of the following illegal characters: '\', '/', ':', '*', '?', '"', '<', '>', '|', '@'.

.EXAMPLE
Copy-Files -src "C:\Users\John\Pictures" -dst "D:\MyBackup\Files" -baseFolder "John's Pictures"

In this example, the Copy-Files function is called with the -src parameter set to "C:\Users\John\Pictures" (the source directory), the -dst parameter set to "D:\MyBackup\Files" (the destination directory), and the -baseFolder parameter set to "John's Pictures" (the name of the subdirectory within the destination directory where the copied files will be placed). This command will copy all image and video files from the "C:\Users\John\Pictures" directory to the "D:\MyBackup\Files\John's Pictures" directory, grouping them into "Images" and "Videos" subdirectories as needed.

.EXAMPLE
Copy-Files -src "E:\Vacation Videos" -dst "F:\Vacation Backup" -baseFolder "2019 Trip"

In this example, the Copy-Files function is called with the -src parameter set to "E:\Vacation Videos" (the source directory), the -dst parameter set to "F:\Vacation Backup" (the destination directory), and the -baseFolder parameter set to "2019 Trip" (the name of the subdirectory within the destination directory where the copied files will be placed). This command

#>
function Copy-Files {
  [CmdletBinding()]
  param(
    #[ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$src = "F:\",

    #[ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$dst = "Z:\",

    [Parameter(Mandatory=$true)]
    [ValidateScript({ $_ -notmatch '[\\\/:*?"<>|@]' })]
    [string]$baseFolder

  )

  # Define the destination path
  $dst = "$($dst)\$($baseFolder)"
  

  # Create the destination folder if it doesn't exist
  if (!(Test-Path $dst)) {
    New-Item $dst -ItemType Directory | Out-Null
  }

  # Get a list of all image files in the source path
  $files = Get-ChildItem $src -Include *.jpg, *.jpeg, *.png, *.gif, *.bmp, *.mp4, *.avi, *.mov -Recurse

  # Loop through each file
  foreach ($file in $files) {
    # Calculate the MD5 hash of the file
    $hash = (Get-FileHash $file.FullName).Hash
    

    # Determine the destination folder based on the file extension
    $ext = $file.Extension
    if ($ext -eq ".jpg" -or $ext -eq ".jpeg" -or $ext -eq ".png" -or $ext -eq ".gif" -or $ext -eq ".bmp") {
      $folder = "Images"
    }
    elseif ($ext -eq ".mp4" -or $ext -eq ".avi" -or $ext -eq ".mov") {
      $folder = "Videos"
    }
    else {
      # Unknown file type, skip this file
      continue
    }

    # Create the destination folder if it doesn't exist
    if (!(Test-Path "$dst\$folder")) {
      New-Item "$dst\$folder" -ItemType Directory | Out-Null
    }

    $i = 0
    # Checking if a duplicate file exists. If it does, we don't want to over-write it. 
    # Generate a new file name in the format "NNNN - original_file_name"
    while (Test-Path "$dst\$folder\$i - $($file.Name)") {
      $i++
    }
    $newName = "$i - $($file.Name)"

    # Copy the file to the destination folder with the new name
    Copy-Item $file.FullName "$dst\$folder\$newName" | Out-Null

    # Calculate the MD5 hash of the copied file
    $copiedHash = (Get-FileHash "$dst\$folder\$newName").Hash

    # Compare the hashes to make sure the copy matches the original
    if ($hash -ne $copiedHash) {
      Write-Host "The copied file $newName does not match the original file. The hashes do not match."
    }
  }
}

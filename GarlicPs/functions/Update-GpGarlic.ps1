function Update-GpGarlic {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $false)]
		[string]$LocalFile,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[string]$TargetPath,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $false,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		# Path to extract Garlic to
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOSUpdate"
		$garlicUpdateZip = "RG35XX-CopyPasteOnTopOfStock.7z"
		$garlicUpdateUri = "https://www.patreon.com/file?h=76561333&i=13249818" # This changes with each update, should take in as param or scrape 

		# Cleanup/Create temp path for Garlic extraction
		New-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		# Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath -GarlicZip $garlicZip -GarlicUri $garlicUri
			}
			else {
				$garlicZipPath = $LocalFile
			}
		}
		catch {
			Write-Error -Message "Error downloading GarlicOS: $($_.Exception.Message)"
		}

		# Decompress the archive
		try {
			Expand-7Zip -ArchiveFileName $garlicZipPath -TargetPath $garlicPath
		}
		catch {
			Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
		}

		# Doesn't seem to be an easy way to parse the actual version of GarlicOS we have
		# so for now it we'll just overwrite regardless.
		# Would be nice to do a compare before proceeding though...

		# Install GarlicOS
		try {
			# Copy Misc
			$miscDir = "misc"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $miscDir) -Destination $TargetPath -Recurse -Force -Confirm:$false

			# Copy ROMS
			$romDir = "roms"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $romDir) -Destination $TargetPath -Recurse -Force -Confirm:$false
		}
		catch {
			Write-Error -Message "Error installing GarlicOS: $($_.Exception.Message)"
		}

		# Copy personal files
		Copy-GpPersonalFiles -BIOSPath $BIOSPath -ROMPath $ROMPath -Destination $TargetPath
		
	
		catch {
			Write-Error -Message "Error copying personal game files: $($_.Exception.Message)"
		}

		# Tada!
		Invoke-GpThanks
	}
}

# GarlicPs Module

## Install-GpGarlic

### Synopsis

Install GarlicOS\!

### Syntax

```powershell

Install-GpGarlic [[-LocalFile] <String>] [[-TempPath] <String>] [-TargetDevice] <String> [[-ClearTempPath] <Boolean>] [[-BIOSPath] <String>] [[-ROMPath] <String>] [<CommonParameters>]




```

### Parameters

| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>LocalFile</nobr> |  | The full path of a copy of RG35XX-MicroSDCardImage.7z locally available. If not supplied, it is downloaded. | false | false |  |
| <nobr>TempPath</nobr> |  | Optional. Where files will be downloaded and decompressed to during the installation. | false | false | \\(Join-Path -Path \\(\\[System.IO.Path\\]::GetTempPath\\(\\)\\) "\\GarlicPs"\\) |
| <nobr>TargetDevice</nobr> |  | The target device of the SD card. Must be the DeviceID returned from 'GET-WMIOBJECT -Query "SELECT \* FROM Win32\\_DiskDrive"' | true | false |  |
| <nobr>ClearTempPath</nobr> |  | Optional. Whether to recursively empty the TempPath before using it. Recommended. | false | false | False |
| <nobr>BIOSPath</nobr> |  | Optional. Path to personal BIOS files that will be copied after installation. | false | false |  |
| <nobr>ROMPath</nobr> |  | Optional. Path to personal ROM files that will be copied after installation. | false | false |  |

### Examples

**EXAMPLE 1**

```powershell
TBD
```

## Update-GpGarlic

### Syntax

```powershell
Update-GpGarlic [[-LocalFile] <string>] [[-TempPath] <string>] [-TargetPath] <string> [[-ClearTempPath] <bool>] [[-BIOSPath] <string>] [[-ROMPath] <string>] [<CommonParameters>]
```

### Parameters

| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>BIOSPath</nobr> | None |  | false | false |  |
| <nobr>ClearTempPath</nobr> | None |  | false | false |  |
| <nobr>LocalFile</nobr> | None |  | false | false |  |
| <nobr>ROMPath</nobr> | None |  | false | false |  |
| <nobr>TargetPath</nobr> | None |  | true | false |  |
| <nobr>TempPath</nobr> | None |  | false | false |  |

# GarlicPs

Unofficial helper PowerShell module for installing and updating [GarlicOS by Black Seraph][garlic] on the [Anbernic RG35xx][rg35xx] handheld game system.

Only tested on Windows, YMMV.

## Requirements

This module relies on [7zip4powershell][7z4p].
Before importing, ensure this module is present:

```pwsh
Install-Module 7zip4powershell
```

## Contributing

Contributions are welcome! Please adhere to the linting rules and try to follow existing style.

## Roadmap

Potential improvements:

- Find a way to parse the os version to avoid accidental downgrades or reinstalls of same version
- Publish module to PS Gallery for easier upkeep
- Handle USB Gamepad support enabling
- Handle ADB support enabling

[7z4p]: https://www.powershellgallery.com/packages/7Zip4Powershell/
[garlic]: https://www.patreon.com/posts/garlicos-for-76561333
[rg35xx]: https://anbernic.com/products/rg35xx

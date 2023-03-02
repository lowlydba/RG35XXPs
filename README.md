# GarlicPs

Unofficial helper PowerShell module for installing and updating [GarlicOS by Black Seraph][garlic] on the [Anbernic RG35xx][rg35xx] handheld game system.

Only tested on Windows, YMMV.

Docs @ <https://lowlydba.github.io/GarlicPs/>

## Requirements

### Other

* [balena-cli][balena-cli] (command line version of balenaEtcher) installed and added to PATH
* 7Zip - Specifically the cli, which should be part of the default installation

## Contributing

Contributions are welcome! Please adhere to the linting rules and try to follow existing style.

## Roadmap

Potential improvements:

* Find a way to parse the os version to avoid accidental downgrades or reinstalls of same version
* Publish module to PS Gallery for easier upkeep
* Handle USB Gamepad support enabling
* Handle ADB support enabling
* Also support [MinUI](https://github.com/shauninman/union-minui/) install/update
* Use a progress bar

[balena-cli]: https://github.com/balena-io/balena-cli/blob/master/INSTALL.md
[garlic]: https://www.patreon.com/posts/garlicos-for-76561333
[rg35xx]: https://anbernic.com/products/rg35xx

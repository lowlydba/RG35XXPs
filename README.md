# GarlicPs

Unofficial helper PowerShell module for installing and updating [GarlicOS by Black Seraph][garlic] on the [Anbernic RG35xx][rg35xx] handheld game system.

Only tested on Windows, YMMV.

Docs @ <https://lowlydba.github.io/GarlicPs/>

## Requirements

### Other

* [balena-cli][balena-cli] (command line version of balenaEtcher) installed and added to PATH
* [7Zip][7zip] - Specifically the cli, which should be part of the default installation

## Contributing

Contributions are welcome! Please adhere to the linting rules and try to follow existing style.

## Limitations

### Resizing Partitions

Right now re/sizing FAT32 volumes (i.e. the ROMS partition) on Windows > 32GB isn't doable without third party tools.
I haven't been able to find a reliable CLI tool to do this, but please open an enhancement request if you know of one.

In the mean time, you can add a 👍🏻 emoji to the [request][balena-request] to include this capability
as a feature in balena-cli.

## Roadmap

Potential improvements:

* Find a way to parse the os version to avoid accidental downgrades or reinstalls of same version
* Publish module to PS Gallery for easier upkeep
* Handle USB Gamepad support enabling
* Handle ADB support enabling
* Also support [MinUI](https://github.com/shauninman/union-minui/) install/update

[7zip]: https://www.7-zip.org/
[balena-cli]: https://github.com/balena-io/balena-cli/blob/master/INSTALL.md
[balena-request]: https://github.com/balena-io/etcher/issues/1451
[garlic]: https://www.patreon.com/posts/garlicos-for-76561333
[rg35xx]: https://anbernic.com/products/rg35xx

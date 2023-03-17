# RG35xxPs

Powershell installer/updated for custom [Batocera firmware](https://github.com/rg35xx-cfw) on the [Anbernic RG35xx][rg35xx] handheld game system.

Only tested on Windows, YMMV.

Docs @ <https://lowlydba.github.io/RG35XXPs/>

## Requirements

* [balena-cli][balena-cli] (command line version of balenaEtcher)

## Contributing

Contributions are welcome! Please adhere to the linting rules and try to follow existing style.

## Instructions

## Limitations

### Resizing Partitions

Right now re/sizing FAT32 volumes (i.e. the ROMS partition) on Windows for > 32GB isn't doable without third party tools.
I haven't been able to find a reliable CLI tool to do this, but please open an enhancement request if you know of one.

In the mean time, you can add a 👍🏻 to the [request][balena-request] to include this capability
as a feature in balena-cli so that large SD cards could be auto-formatted and loaded with ROMs via this module.

## Roadmap

Potential improvements:

* Publish module to PS Gallery for easier upkeep

[balena-cli]: https://github.com/balena-io/balena-cli/blob/master/INSTALL.md
[balena-request]: https://github.com/balena-io/etcher/issues/1451
[rg35xx]: https://anbernic.com/products/rg35xx

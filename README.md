# GPS-Simulator

GPS-Simulator simulates the movement history using idevicelocation from the log of GPX file.


# Requirements

The following is required, so please install it.
* [idevicelocation](https://github.com/JonGabilondoAngulo/idevicelocation)
* xmlstarlet
* gdate (for macOS)


# Usage

```shell
Usage: gpssim.sh [OPTIONS] GPX_FILE
  -u | --udid UDID    Target specific device by its device UDID.
  -v | --verbose      View simulation verbose
  --dry-run           Don't actually simulate location, just show they.
  -h | --help         Show this message and exit
```


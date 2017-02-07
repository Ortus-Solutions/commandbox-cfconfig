This is a CommandBox module that provides a CLI for reading, writing, and storing configuration for all CF engines.

## Main Features

1. Generic JSON storage of any CF engine's settings
2. Engine-specific mappings for all major engines to convert their config to and from the generic JSON format

This does not use RDS and doesn't need the server to be running.  It just needs access to the installation folder for a server to locate its config files. 

## Possible Uses

Uses for this library include but are not limited to:

* Export config from a server as a backup
* Import config to a server to speed/automate setup
* Copy config from one server to another.  Servers could be different engines-- i.e. copy config from Adobe CF11 to Lucee 5.
* Merge config from multiple servers together. Ex: combine several Lucee web contexts into a single config (mappings, datasources, etc)
* Facilitate the external management of any server's settings

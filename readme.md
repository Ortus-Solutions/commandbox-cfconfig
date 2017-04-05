```
   ____ _____ ____             __ _          ____ _     ___ 
  / ___|  ___/ ___|___  _ __  / _(_) __ _   / ___| |   |_ _|
 | |   | |_ | |   / _ \| '_ \| |_| |/ _` | | |   | |    | | 
 | |___|  _|| |__| (_) | | | |  _| | (_| | | |___| |___ | | 
  \____|_|   \____\___/|_| |_|_| |_|\__, |  \____|_____|___|
                                    |___/                   
```

<img src="https://www.ortussolutions.com/__media/logos/CfConfigLogo300.png" class="img-thumbnail"/>

>Copyright 2012 by Ortus Solutions, Corp - https://www.ortussolutions.com

This is a CommandBox module that provides a CLI for reading, writing, and storing configuration for all CF engines.

## Main Features

1. Generic JSON storage of any CF engine's settings
2. Engine-specific providers for all major engines to convert their config to and from the generic JSON format

This does not use RDS and doesn't need the server to be running.  It just needs access to the installation folder for a server to locate its config files.  You will need to restart the server for the change to take effect unless you have configured the server to scan it's config files for changes. 

## Possible Uses

Uses for this library include but are not limited to:

* Export config from a server as a backup
* Import config to a server to speed/automate setup
* Copy config from one server to another.  Servers could be different engines-- i.e. copy config from Adobe CF11 to Lucee 5.
* Merge config from multiple servers together. Ex: combine several Lucee web contexts into a single config (mappings, datasources, etc)
* Facilitate the external management of any server's settings

## Usage

Here are some examples of commands you can run.  Use the built-in help to get full details on all commands.
Each command allows you to specify a `from` and/or a `to` location, based on what you are doing.  A location can be any one of the following:

* Nothing-- we'll look in the current working directory for a CommandBox server
* The name of a CommandBox server (doesn't need to be running)
* The path to a server home as defined by the rules in the help.

When interacting with CommandBox servers, we try really hard to figure out the type and version of server you're dealing with.  When you simply point to a folder on the hard drive that contains a server home, you'll need to tell us what format you would like the config read or written as.  When writing config, the target directory doesn't need to exist.  We'll create everything for you so you can `import` configuration before you even start the server the first time.  Proper formats look like one of these:

* **adobe@11** - Read/write from an Adobe server, version 11.x
* **luceeServer@4.5** - Read/write from the Lucee server context, expecting version 4.5.x
* **luceeWeb@5** - Read/write from the Lucee web context, expecting version 5.x.x

### Export config from a server

```
cfconfig export myConfig.json
cfconfig export myConfig.json serverName
cfconfig export myConfig.json /path/to/server/install/home luceeWeb@4.5
```

### Import config to a server
```
cfconfig import myConfig.json
cfconfig import myConfig.json serverName
cfconfig import myConfig.json /path/to/server/install/home luceeWeb@4.5
```

### Transfer config between two servers
Note the two servers do not need to be the same kind.  CFConfig will translate the config for you.
```
cfconfig transfer server1 server2
cfconfig transfer from=/path/to/server1/install/home to=/path/to/server2/install/home fromFormat=adobe@11 toFormat=luceeServer@5
```

### View all configuration
```
cfconfig show
cfconfig show serverName
cfconfig show /path/to/server/install/home
```

### View a specific configuration setting
```
cfconfig show requestTimeout
cfconfig show requestTimeout serverName
cfconfig show requestTimeout /path/to/server/install/home adobe@11
```

### Diff settings between two servers.
You can diff any two locations, meaning two servers, two JSON files, a server and a JSON file, etc, etc.
```
cfconfig diff server1 server2
cfconfig diff file1.json file2.json
cfconfig diff servername file.json
cfconfig diff from=path/to/servers1/home to=path/to/server2/home
```

You can even filter what config settings you see:
```
cfconfig diff to=serverName --all
cfconfig diff to=serverName --valuesDiffer --toOnly --fromOnly
```

### Set a configuration setting
Note, this command requires named parameters.

```
cfconfig set adminPassword=commandbox
cfconfig set adminPassword=commandbox to=serverName
cfconfig set adminPassword=commandbox to=/path/to/server/install/home toFormat=adobe@11
```

You can actually use `cfconfig set` to manage the static contents of a JSON export. The JSON file is, after all, just another location you can read from or write to.
```
# Pull current config from server into JSON file
cfconfig export myConfig.json
# Edit JSON file directly
cfconfig set adminPassword=commandbox to=myConfig.json
```

### Manage CF Mappings
There are three commands to manage CF mappings.
```
cfconfig cfmapping list
cfconfig cfmapping save /foo C:/foo
cfconfig cfmapping delete /foo
```

### Manage Datasources
There are three commands to manage datasources.
```
cfconfig datasource list
cfconfig datasource save myDS
cfconfig datasource delete myDS
```

### Manage Mail Servers
There are three commands to manage Mail Servers.
```
cfconfig mailserver list
cfconfig mailserver save smtp.mail.com
cfconfig mailserver delete smtp.mail.com
```

### Manage Lucee Caches
There are three commands to manage Lucee caches.
```
cfconfig cache list
cfconfig cache save myCache
cfconfig cache delete myCache
```

## Future Development

This is very much a work in progess.  Features yet to come include:

* Listen to CommandBox server installs, and auto-migrate settings when a new engine is installed.
* More complete support for all engines. (looking for community contributions for this since there's so much to support).
* If you think of something else, please submit a ticket!

And remember, this project is just the CLI component. If you'd like to build a custom process of managing your server's config, the entire service layer is available as a separate project, which can operate outside of CommandBox. https://www.forgebox.io/view/cfconfig-services


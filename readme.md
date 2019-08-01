```
   ____ _____ ____             __ _          ____ _     ___ 
  / ___|  ___/ ___|___  _ __  / _(_) __ _   / ___| |   |_ _|
 | |   | |_ | |   / _ \| '_ \| |_| |/ _` | | |   | |    | | 
 | |___|  _|| |__| (_) | | | |  _| | (_| | | |___| |___ | | 
  \____|_|   \____\___/|_| |_|_| |_|\__, |  \____|_____|___|
                                    |___/                   
```

<img src="https://www.ortussolutions.com/__media/logos/CfConfigLogo300.png" class="img-thumbnail"/>

>Copyright 2017 by Ortus Solutions, Corp - https://www.ortussolutions.com

This is a CommandBox module that provides a CLI for reading, writing, and storing configuration for all CF engines.

Please enter tickets for bugs or enhancements here:
https://ortussolutions.atlassian.net/browse/CFCONFIG

Documentation is found here:
https://cfconfig.ortusbooks.com

## Main Features

1. Generic JSON storage of any CF engine's settings
2. Engine-specific providers for all major engines to convert their config to and from the generic JSON format

This does not use RDS and doesn't need the server to be running.  It just needs access to the installation folder for a server to locate its config files.  You will need to restart the server for the change to take effect unless you have configured the server to scan it's config files for changes. 

## Uses

This library is a CommandBox module that provides a CLI interface sitting on top of the `cfconfig-services` project.  You must use CommandBox to use this project, but the servers themselves don't need to have been started by CommandBox.  You can manage the configuration of any server using this.  Uses for this library include but are not limited to:

* Export config from a server as a backup
* Import config to a server to speed/automate setup
* Copy config from one server to another.  Servers could be different engines-- i.e. copy config from Adobe CF11 to Lucee 5.
* Merge config from multiple servers together. Ex: combine several Lucee web contexts into a single config (mappings, datasources, etc)
* Facilitate the external management of any server's settings
* Compare settings between two sources

## Command Installation

Once you have Commandbox installed run the following command to install the `cfconfig` command:

```
box install commandbox-cfconfig
```

You can check to ensure you have the latest version of CFConfig like so:

```
box update --system
```


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

```bash
cfconfig export myConfig.json
cfconfig export myConfig.json serverName
cfconfig export myConfig.json /path/to/server/install/home
```

### Import config to a server
```bash
cfconfig import myConfig.json
cfconfig import myConfig.json serverName
cfconfig import from=myConfig.json to=/path/to/server/install/home toFormat=luceeWeb@4.5
```

### Transfer config between two servers
Note the two servers do not need to be the same kind.  CFConfig will translate the config for you.
```bash
cfconfig transfer server1 server2
cfconfig transfer from=/path/to/server1/install/home to=/path/to/server2/install/home fromFormat=adobe@11 toFormat=luceeServer@5
```

### View all configuration
```bash
cfconfig show
cfconfig show from=serverName
cfconfig show from="/path/to/server/install/home"
```

### View a specific configuration setting
```bash
cfconfig show requestTimeout
cfconfig show requestTimeout serverName
cfconfig show requestTimeout /path/to/server/install/home adobe@11
```

### Diff settings between two servers.
You can diff any two locations, meaning two servers, two JSON files, a server and a JSON file, etc, etc.
```bash
cfconfig diff server1 server2
cfconfig diff file1.json file2.json
cfconfig diff servername file.json
cfconfig diff from=path/to/servers1/home to=path/to/server2/home
```

You can even filter what config settings you see:
```bash
cfconfig diff to=serverName --all
cfconfig diff to=serverName --valuesDiffer --toOnly --fromOnly
```

### Set a configuration setting
Note, this command requires named parameters.

```bash
cfconfig set adminPassword=commandbox
cfconfig set adminPassword=commandbox to=serverName
cfconfig set adminPassword=commandbox to=/path/to/server/install/home toFormat=adobe@11
```

You can actually use `cfconfig set` to manage the static contents of a JSON export. The JSON file is, after all, just another location you can read from or write to.
```bash
# Pull current config from server into JSON file
cfconfig export myConfig.json
# Edit JSON file directly
cfconfig set adminPassword=commandbox to=myConfig.json
```

### Manage CF Mappings
There are three commands to manage CF mappings.
```bash
cfconfig cfmapping list
cfconfig cfmapping save /foo C:/foo
cfconfig cfmapping delete /foo
```

### Manage Datasources
There are three commands to manage datasources.
```bash
cfconfig datasource list
cfconfig datasource save myDS
cfconfig datasource delete myDS
```

### Manage Mail Servers
There are three commands to manage Mail Servers.
```bash
cfconfig mailserver list
cfconfig mailserver save smtp.mail.com
cfconfig mailserver delete smtp.mail.com
```

### Manage Lucee Caches
There are three commands to manage Lucee caches.
```bash
cfconfig cache list
cfconfig cache save myCache
cfconfig cache delete myCache
```

### Manage Custom Tag Paths
There are three commands to manage Custom Tag Paths.
```bash
cfconfig customtagpath list
cfconfig customtagpath save /foo C:/foo/bar
cfconfig customtagpath delete /foo
```

### Manage Event Gateway Configurations
There are three commands to manage Event Gateway onfig.
```bash
cfconfig eventgatewayconfig list
cfconfig eventgatewayconfig save myType "description of gateway" "java.class" 30 true
cfconfig eventgatewayconfig delete myType
```

### Manage Event Gatway Instances
There are three commands to manage Event Gatway Instances.
```bash
cfconfig eventgatewayinstance list
cfconfig eventgatewayinstance save myInstanceId CFML "/path1/some.cfc,/path2/code.cfc"
cfconfig eventgatewayinstance delete myInstanceId
```

### Manage Lucee Loggers
There are three commands to manage Lucee Loggers.
```bash
cfconfig logger list
cfconfig logger save name=application appender=resource appenderArguments:path={lucee-config}/logs/application.log
cfconfig logger delete application
```

### Manage Scheduled Tasks
There are three commands to manage Scheduled Tasks.
```bash
cfconfig task list
cfconfig task save myTask http://www.google.com Once 4/13/2018 "5:00 PM"
cfconfig task delete myTask myGroup
```


## Notes

If you notice a missing feature, please send a pull request or enter a ticket so we can track it.

And remember, this project is just the CLI component. If you'd like to build a custom process of managing your server's config, the entire service layer is available as a separate project, which can operate outside of CommandBox. https://www.forgebox.io/view/cfconfig-services


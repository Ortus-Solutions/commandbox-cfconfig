component {
	property name='fileSystemUtil'	inject='FileSystem';
	property name='serverService'	inject='ServerService';
	property name='systemSettings'	inject='SystemSettings';
	property name='consoleLogger'	inject='logbox:logger:console';
	property name='ConfigService'	inject='ConfigService';
	property name='semanticVersion'	inject='provider:semanticVersion@semver';
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';

	function onDIComplete() {
		jobEnabled = getWirebox().getBinder().mappingExists( 'interactiveJob' );
	}

	function onServerInstall( interceptData ) {
		interceptData.serverInfo.multiContext = interceptData.serverInfo.multiContext ?: false;
		interceptData.serverInfo.verbose = interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug;

		var en = interceptData.installDetails.engineName;
		// Bail right now if this server isn't a CF engine.
		if( !( en contains 'lucee' || en contains 'railo' || en contains 'adobe' ) ) {
			return;
		}

		if( jobEnabled ) {
			var job = wirebox.getInstance( 'interactiveJob' );
			job.start( 'Loading CFConfig into server' );
		}

		var results = findCFConfigFile( interceptData );
		var CFConfigFiles = results.CFConfigFiles;
		var pauseTasks = results.pauseTasks;
		var previousAdminPassPlain = '';
		var previousAdminPassHashed = '';
		var previousAdminPassSalt = '';

		// Get the config settings
		var configSettings = ConfigService.getconfigSettings();

		// Does the user want us to export setting when the server stops?
		var autoTransferOnUpgrade = configSettings.modules[ 'commandbox-cfconfig' ].autoTransferOnUpgrade ?: true;

		// Clean up some slash nonsense
		interceptData.installDetails.installDir = normalizeSlashes( interceptData.installDetails.installDir );
		interceptData.serverInfo.customServerFolder = normalizeSlashes( interceptData.serverInfo.customServerFolder );

		// If we found a CFConfig JSON file, let's import it!
		if( CFConfigFiles.count() ) {

			for( var toFormat in CFConfigFiles ) {
				var CFConfigFileArray = CFConfigFiles[ toFormat ];
				var firstOfThisFormat = true;
				for( var CFConfigFile in CFConfigFileArray ) {
					var rawJSON = fileRead( CFConfigFile );
					if( isJSON( rawJSON ) ) {

						if( interceptData.serverInfo.verbose ) {
							logDebug( '#( firstOfThisFormat ? "Importing" : "Appending" )# #toFormat# config from [#CFConfigFile#]' );
						}

						command( 'cfconfig import' )
							.params(
								from=CFConfigFile,
								fromFormat='JSON',
								to=interceptData.serverInfo.name,
								pauseTasks=pauseTasks,
								toFormat=toFormat,
								// If there is more than one config file for the same format, append all subsequent imports
								append=!firstOfThisFormat
							).run();

						// Extra check for adminPassword on Lucee.  Set the web context as well
						var cfconfigJSON = deserializeJSON( rawJSON );
						// And swap out any system settings
						systemSettings.expandDeepSystemSettings( cfconfigJSON );
						if( cfconfigJSON.keyExists( 'adminPassword' ) ) {
							previousAdminPassPlain = cfconfigJSON.adminPassword;
						}
						if( cfconfigJSON.keyExists( 'hspw' ) && cfconfigJSON.keyExists( 'adminSalt' ) ) {
							previousAdminPassHashed = cfconfigJSON.hspw;
							previousAdminPassSalt = cfconfigJSON.adminSalt;
						}

					} else {
						logError( 'CFConfig file doesn''t contain valid JSON! [#CFConfigFile#]' );
					}

					firstOfThisFormat = false;
				}
			}
		// No JSON file found to import and this is the initial install
		} else if( interceptData.installDetails.initialInstall
			// And the user wants to auto transfer setting to a new server on upgrade
			&& autoTransferOnUpgrade
			// The the server is being installed in the default directory (as opposed to a custom server home)
			&& interceptData.installDetails.installDir.find( interceptData.serverInfo.customServerFolder )
			// And this is a standard engine as opposed to some custom war that might not even be CFML!
			&& interceptData.installDetails.engineName.len() ) {

			var thisEngine = interceptData.installDetails.engineName;
			var thisVersion = interceptData.installDetails.version;
			var thisInstallDir = interceptData.installDetails.installDir;

			// This will get a list of all engine-versions we've ever started for this server
			// based on what folders exist in the custom server folder
			var serverDirectories = directoryList( interceptData.serverInfo.customServerFolder );
			var previousServerFolder = '';
			var previousVersion = '';

			serverDirectories.each( function( path ){
				// Curse you Perry the Mixaslashapus
				path = normalizeSlashes( path );

				// Ignore ourselves
				if( path != thisInstallDir ) {
					var engineTagFile = path & '/.engineInstall';
					if( fileExists( engineTagFile ) ) {
						var engineTag = fileRead( engineTagFile ).trim();
						if( engineTag.listLen( '@' ) > 1 ) {
							// Version is everything after the last @
							var otherVersion = engineTag.listLast( '@' );
							// Engine is everything up to the last @.  Could be @ortus/customSlug@1.2.3
							var otherEngine =  engineTag.replace( '@#otherVersion#', '' );

							// If the engine matches (lucee=lucee)
							if( thisEngine == otherEngine
								// and EITHER we haven't come across another version of this engine yet
								&& ( !previousVersion.len()
									// OR the currently installed version is newer than the one we just found
									|| ( semanticVersion.isNew( otherVersion, thisVersion )
											// And the one we just found is newer than the previous ones we found
											&& semanticVersion.isNew( previousVersion, otherVersion )
									    )
									)
								) {

								// Assert: Here is the most recent previous version of this engine we've found thus far.
								previousVersion = otherVersion;
								previousServerFolder = path;

							} // Version of interest

						} // Engine tag has proper contents
					} // engine tag exists
				} // ignore ourselves
			} ); // server dir each

			// Did we find a previous version of this engine?
			if( previousServerFolder.len() ) {
				logWarn( 'Auto importing settings from your previous [#thisEngine#@#previousVersion#] server.' );
				logWarn( 'Turn off this feature with [config set modules.commandbox-cfconfig.autoTransferOnUpgrade=false]' );

				try {

					if( thisEngine == 'adobe' ) {

						if( interceptData.serverInfo.verbose ) {
							logDebug( 'Copying from [#previousServerFolder#/WEB-INF/cfusion] to [#thisInstallDir#/WEB-INF/cfusion]' );
						}
						CFConfigService.transfer(
							from		= previousServerFolder & '/WEB-INF/cfusion',
							to			= thisInstallDir & '/WEB-INF/cfusion',
							fromFormat	= 'adobe',
							toFormat	= 'adobe',
							fromVersion	= previousVersion,
							toVersion	= thisVersion
						);

					} else if ( thisEngine == 'lucee' ) {


						// Crappy workaround for CommandBox bug where this logic is being done on the fly, but not saved back into the serverInfo struct!
						if( interceptData.serverInfo.multiContext && not interceptData.serverInfo.webConfigDir contains '{web-root-directory}' && not interceptData.serverInfo.webConfigDir contains '{web-context-hash}'  ) {
							interceptData.serverInfo.webConfigDir &= '-{web-context-hash}'
						}

						// Guess where the previous server/web context was. This won't be correct if there was a
						// webConfigDir or serverConfigDir, but in that case it doesn't matter since there's nothing to copy anyway
						var previousWebContext = interceptData.serverInfo.webConfigDir;
						var previousServerContext = interceptData.serverInfo.serverConfigDir & '/lucee-server/';

						if( previousWebContext.uCase().startsWith( '/WEB-INF' ) ) {
							previousWebContext = previousServerFolder & previousWebContext;
						}
						if( previousServerContext.uCase().startsWith( '/WEB-INF' ) ) {
							previousServerContext = previousServerFolder & previousServerContext;
						}

						// We know this for sure...
						var newWebContext = interceptData.serverInfo.webConfigDir;
						//Lucee's server config dir doesn't include the "lucee-server" but CFConfig expects it for the server home.
						var newServerContext = interceptData.serverInfo.serverConfigDir & '/lucee-server';

						if( newWebContext.uCase().startsWith( '/WEB-INF' ) ) {
							newWebContext = thisInstallDir & newWebContext;
						}
						if( newServerContext.uCase().startsWith( '/WEB-INF' ) ) {
							newServerContext = thisInstallDir & newServerContext;
						}

						// Hard-coded server contexts outside of the server home will be ignored
						if( directoryExists( previousServerContext ) ) {

							if( interceptData.serverInfo.verbose ) {
								logDebug( 'Copying from [#previousServerContext#] to [#newServerContext#]' );
							}
							CFConfigService.transfer(
								from		= previousServerContext,
								to			= newServerContext,
								fromFormat	= 'luceeServer',
								toFormat	= 'luceeServer',
								fromVersion	= previousVersion,
								toVersion	= thisVersion
							);

						}

						// Hard-coded server contexts outside of the server home will be ignored
						if( previousWebContext contains '/WEB-INF' ) {
							var oldWebContexts = [];
							if( interceptData.serverInfo.webConfigDir == '/WEB-INF/lucee-web-{web-context-hash}' && interceptData.serverInfo.multiContext ) {
								directoryList( path=previousServerFolder & '/WEB-INF/', listInfo='name', type='dir' )
									.filter( (f)=>f.lCase().startsWith( 'lucee-web-' ) )
									.each( (f)=>oldWebContexts.append( {
										old : previousServerFolder & '/WEB-INF/' & f,
										new : thisInstallDir & '/WEB-INF/' & f
									} ) );
							} else if( directoryExists( previousWebContext ) ) {
								oldWebContexts.append( {
									old : previousWebContext,
									new : newWebContext
								} );
							}
							oldWebContexts.each( (c)=>{
								if( interceptData.serverInfo.verbose ) {
									logDebug( 'Copying from [#c.old#] to [#c.new#]' );
								}
								CFConfigService.transfer(
									from		= c.old,
									to			= c.new,
									fromFormat	= 'luceeWeb',
									toFormat	= 'luceeWeb',
									fromVersion	= previousVersion,
									toVersion	= thisVersion
								);
							} );

						}


					}
				} catch( any var e ) {
					logError( 'Oh, snap! We had an error auto-importing your settings.  Please report this error.' );
					logError( e.message );
					logError( e.detail );
					logError( '    ' & e.tagContext[ 1 ].template & ':' &  e.tagContext[ 1 ].line );
				}
			}
		}

		// Look for individual CFConfig settings to import.
		var system = createObject( 'java', 'java.lang.System' );
		// Gatter the settings here first, then import all at once.
		var settingsToImport = {};
		var processVarsUDF = function( envVar, value, title ) {
			// Loop over any that look like cfconfig_xxx
			if( envVar.len() > 9 && ( left( envVar, 9 ) == 'cfconfig_' || left( envVar, 9 ) == 'cfconfig.' ) ) {
				var name = right( envVar, len( envVar ) - 9 );
				var toFormat = createFormat( interceptData, 'server' );
				if( name.left( 4 ) == 'web_' ) {
					var name = right( name, len( name ) - 4 );
					toFormat = createFormat( interceptData, 'web' );
				}
				if( name.left( 7 ) == 'server_' ) {
					var name = right( name, len( name ) - 7 );
				}
				name = name.replace( '_', '.', 'all' );

				if( interceptData.serverInfo.verbose ) {
					logDebug( 'Found #title# [#envVar#]' );
				}

				settingsToImport[ toFormat ] = settingsToImport[ toFormat ] ?: {};
				getInstance( 'JSONService' ).set( settingsToImport[ toFormat ], { '#name#' : value }, true );

				if( name == 'adminPassword' ) {
					previousAdminPassPlain = value;
				}
				if( name == 'hspw' ) {
					previousAdminPassHashed = value;
				}
				if( name == 'adminSalt' ) {
					previousAdminPassSalt = value;
				}

			}
		};

		// Get all OS env vars
		var envVars = system.getenv();
		for( var envVar in envVars ) {
			processVarsUDF( envVar, envVars[ envVar ], 'OS environment variable' );
		}

		// Get all System Properties
		var props = system.getProperties();
		for( var prop in props ) {
			processVarsUDF( prop, props[ prop ], 'system property' );
		}

		// Ignore this on older versions of CommandBox
		if( structKeyExists( systemSettings, 'getAllEnvironmentsFlattened' ) ) {
			// Get all box environemnt variable
			var envVars = systemSettings.getAllEnvironmentsFlattened();
			for( var envVar in envVars ) {
				processVarsUDF( envVar, envVars[ envVar ], 'box environment variable' );
			}
		}

		// Now that we've collected all the env vars from above, let's import them en masse
		// We do them together so, for example, an entire datasoruce could be specified across
		// a handful of env vars, but the entire thing would be saved at once.
		// Loop over each unique format being imported
		settingsToImport.each( (toFormat,formatSettings)=>{
			if( interceptData.serverInfo.verbose ) {
				logDebug( 'Importing into [#toFormat#]...' );
			}
			var params = {
				to=interceptData.serverInfo.name,
				toFormat = toFormat
			};
			params.append = true;
			formatSettings.each( (settingName,settingValue)=>{
				params[settingName]=isSimpleValue( settingValue ) ? settingValue : serializeJSON( settingValue );
			} );

			command( 'cfconfig set' )
				.params( argumentCollection=params )
				.run();
		} );


		var util = application.wirebox.getInstance( 'util@commandbox-cfconfig' );
		// Check for missing passwords
		var fromDetails = Util.resolveServerDetails( interceptData.serverInfo.name, '', 'from' );
		var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version ).setCFHomePath( fromDetails.path );
		var currentServerSettings = {};
		if( oConfig.CFHomePathExists() ) {
			currentServerSettings = oConfig.read().getMemento();
		}

		var randomPass = createUUID().replace( '-', '', 'all' );
		if( en contains 'adobe' && (interceptData.serverInfo.profile ?: '') == 'production' ) {
			if( ( !len( currentServerSettings.adminPassword ?: '' ) && !len( currentServerSettings.ACF11Password ?: '' ) ) || ( currentServerSettings.adminPassword ?: '' ) == 'commandbox' ) {
				if( ( currentServerSettings.adminPassword ?: '' ) == 'commandbox' ) {
					logWarn( 'Insecure default admin password found and profile is production. Setting your admin password to [#randomPass#]' );
				} else {
					logWarn( 'No admin password found and profile is production. Setting your admin password to [#randomPass#]' );
				}
				command( 'cfconfig set' )
					.params(
						to=interceptData.serverInfo.name,
						append = true,
						adminPassword = randomPass
					).run();
			}

		} else if( ( en contains 'lucee' || en contains 'railo' ) ) {
			if( !len( currentServerSettings.adminPassword ?: '' ) && !len( currentServerSettings.hspw ?: '' ) && !len( currentServerSettings.pw ?: '' ) ) {
				if( len( previousAdminPassPlain ) ) {
					logWarn( 'No Server context admin password found. Setting your admin password to the same as your Web context password.' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							append = true,
							adminPassword = previousAdminPassPlain
						).run();
				} else if( len( previousAdminPassHashed ) && len( previousAdminPassSalt ) ) {
					logWarn( 'No Server context admin password found. Setting your admin password to the same as your Web context password.' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							append = true,
							hspw = previousAdminPassHashed,
							adminSalt = previousAdminPassSalt
						).run();
				} else if( (interceptData.serverInfo.profile ?: '') == 'production' ) {
					logWarn( 'No Server context admin password found and profile is production. Setting your admin password to [#randomPass#]' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							append = true,
							adminPassword = randomPass
						).run();
				}
			} // end server context check

			var thisFormat = ( en contains 'lucee' ? 'lucee' : 'railo' ) & 'web';
			var fromDetails = Util.resolveServerDetails( interceptData.serverInfo.name, thisFormat, 'from' );
			var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version ).setCFHomePath( fromDetails.path );
			var currentWebSettings = {};
			if( oConfig.CFHomePathExists() ) {
				currentWebSettings = oConfig.read().getMemento();
			}

			if( !len( currentWebSettings.adminPassword ?: '' ) && !len( currentWebSettings.hspw ?: '' ) && !len( currentWebSettings.pw ?: '' ) ) {
				if( len( previousAdminPassPlain ) ) {
					logWarn( 'No Web context admin password found. Setting your admin password to the same as your Server context password.' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							toFormat=thisFormat,
							append = true,
							adminPassword = previousAdminPassPlain
						).run();
				} else if( len( previousAdminPassHashed ) && len( previousAdminPassSalt ) ) {
					logWarn( 'No Web context admin password found. Setting your admin password to the same as your Server context password.' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							toFormat=thisFormat,
							append = true,
							hspw = previousAdminPassHashed,
							adminSalt = previousAdminPassSalt
						).run();
				} else if( (interceptData.serverInfo.profile ?: '') == 'production' ) {
					logWarn( 'No Web context admin password found and profile is production. Setting your admin password to [#randomPass#]' );
					command( 'cfconfig set' )
						.params(
							to=interceptData.serverInfo.name,
							toFormat=thisFormat,
							append = true,
							adminPassword = randomPass
						).run();
				}
			} // end webcontext check

		} // end what engine?

		// If there is a custom Adobe /cf_scripts/scripts path, let CommandBox know about it
		if( !isNull( currentServerSettings.CFFormScriptDirectory ) && len( currentServerSettings.CFFormScriptDirectory ) && currentServerSettings.CFFormScriptDirectory != '/cf_scripts/scripts/' && isNull( interceptData.serverInfo.adobeScriptsAlias ) ) {
			if( jobEnabled ) {
				job.addLog( 'Setting custom CFConfig Adobe cfscripts alias into CommandBox [#currentServerSettings.CFFormScriptDirectory#]' );
			}
			interceptData.serverInfo.adobeScriptsAlias = currentServerSettings.CFFormScriptDirectory;
		//If there is a custom script path in CommandBox, it into the server.
		} if( !len( currentServerSettings.CFFormScriptDirectory ?: '' ) && !isNull( interceptData.serverInfo.adobeScriptsAlias ) && len( interceptData.serverInfo.adobeScriptsAlias ) && interceptData.serverInfo.adobeScriptsAlias != '/cf_scripts/scripts/' ) {
			if( jobEnabled ) {
				job.addLog( 'Setting custom CommandBox Adobe cfscripts alias into CFConfig [#interceptData.serverInfo.adobeScriptsAlias#]' );
			}
			command( 'cfconfig set' )
				.params(
					to=interceptData.serverInfo.name,
					append = true,
					CFFormScriptDirectory = interceptData.serverInfo.adobeScriptsAlias
				).run();
		}

		if( jobEnabled ) {
    		job.complete( interceptData.serverInfo.verbose );
		}

	} // end function

	function onServerStop( interceptData ) {

		var en = interceptData.serverInfo.engineName;
		// Bail right now if this server isn't a CF engine.
		if( !( en contains 'lucee' || en contains 'railo' || en contains 'adobe' ) ) {
			return;
		}

		// Get the config settings
		var configSettings = ConfigService.getconfigSettings();

		// Does the user want us to export setting when the server stops?
		var exportOnStop = configSettings.modules[ 'commandbox-cfconfig' ].exportOnStop ?: false;
		if( exportOnStop ) {
			var results = findCFConfigFile( interceptData );
			var CFConfigFiles = results.CFConfigFiles;

			if( CFConfigFiles.count() ) {
				for( var fromFormat in CFConfigFiles ) {
					var CFConfigFileArray = CFConfigFiles[ fromFormat ];
					var CFConfigFile = CFConfigFileArray.first();

					if( interceptData.serverInfo.verbose ) {
						logDebug( 'Exporting CFConfig from #fromFormat# into [#CFConfigFile#]' );
					}

					command( 'cfconfig export' )
						.params(
							to=CFConfigFile,
							toFormat='JSON',
							from=interceptData.serverInfo.name,
							fromFormat=fromFormat
						).run();
				}
			}

		}

	}

	private function createFormat( interceptData, context='' ) {
		var en = interceptData.installDetails.engineName ?: interceptData.serverInfo.engineName;
		var baseEngineName = 'adobe';
		if( en contains 'lucee' ) {
			baseEngineName = 'lucee';
		}
		if( en contains 'railo' ) {
			baseEngineName = 'railo';
		}
		if( baseEngineName == 'adobe' ) {
			return baseEngineName;
		}
		return baseEngineName & context;
	}

	private function addConfigFile( interceptData, context='', CFConfigFiles, thisFile, foundLocation ) {
		var thisFormat = createFormat( interceptData, context );

		CFConfigFiles[ thisFormat ] = CFConfigFiles[ thisFormat ] ?: [];
		CFConfigFiles[ thisFormat ].append( thisFile );

		if( interceptData.serverInfo.verbose ) {
			logDebug( 'Found CFConfig JSON in #foundLocation#.' );
		}

	}

	private struct function findCFConfigFile( interceptData ) {
		var serverInfo = interceptData.serverInfo;
		// Exists for onServerInstall, but not onServerStop
		if( !isNull( interceptData.serverJSON ) ) {
			var serverJSON = interceptData.serverJSON;
		} else {
			var serverJSON = {};
			if( serverInfo.keyExists( 'serverConfigFile' )
				&& serverInfo.serverConfigFile.len()
				&& fileExists( serverInfo.serverConfigFile ) ) {
					// Read it in
					serverJSON = serverService.readServerJSON( serverInfo.serverConfigFile );
					// And swap out any system settings
					systemSettings.expandDeepSystemSettings( serverJSON );
					if( structKeyExists( serverService, 'loadOverrides' ) ) {
						serverService.loadOverrides( serverJSON, serverInfo )
					}
			}
		}

		var results = {
			CFConfigFiles = {
			},
			pauseTasks = false
		};

		// An env var of cfconfig wins
		if( systemSettings.getSystemSetting( 'cfconfigfile', '' ).len() ) {
			var thisFile = systemSettings.getSystemSetting( 'cfconfigfile' );
			thisFile = fileSystemUtil.resolvePath( thisFile, serverInfo.webroot );
			addConfigFile( interceptData, 'server', results.CFConfigFiles, thisFile, '"cfconfigfile" environment variable' );
		}
		if( systemSettings.getSystemSetting( 'cfconfigweb', '' ).len() ) {
			var thisFile = systemSettings.getSystemSetting( 'cfconfigweb' );
			thisFile = fileSystemUtil.resolvePath( thisFile, serverInfo.webroot );
			addConfigFile( interceptData, 'web', results.CFConfigFiles, thisFile, '"cfconfigweb" environment variable' );
		}
		if( systemSettings.getSystemSetting( 'cfconfigserver', '' ).len() ) {
			var thisFile = systemSettings.getSystemSetting( 'cfconfigserver' );
			thisFile = fileSystemUtil.resolvePath( thisFile, serverInfo.webroot );
			addConfigFile( interceptData, 'server', results.CFConfigFiles, thisFile, '"cfconfigserver" environment variable' );
		}

		// If there is a CFConfig specified, let's use it.
		if( serverJSON.keyExists( 'CFConfigFile' )
			&& serverJSON.CFConfigFile.len() ) {

				// Resolve paths to be relative to the location of the server.json
				var thisFile = fileSystemUtil.resolvePath( serverJSON.CFConfigFile, getDirectoryFromPath( serverInfo.serverConfigFile ) );
				addConfigFile( interceptData, 'server', results.CFConfigFiles, thisFile, '"CFConfigFile" server.json key' );
		}
		// If there is a CFConfig object.
		if( serverJSON.keyExists( 'CFConfig' )
			&& isStruct( serverJSON.CFConfig ) ) {

			if( serverJSON.CFConfig.keyExists( 'File' )
				&& serverJSON.CFConfig.File.len() ) {
					// Resolve paths to be relative to the location of the server.json
					var thisFile = fileSystemUtil.resolvePath( serverJSON.CFConfig.File, getDirectoryFromPath( serverInfo.serverConfigFile ) );
					addConfigFile( interceptData, 'server', results.CFConfigFiles, thisFile, '"CFConfig.file" server.json key' );
			}

			if( serverJSON.CFConfig.keyExists( 'server' )
				&& serverJSON.CFConfig.server.len() ) {
					// Resolve paths to be relative to the location of the server.json
					var thisFile = fileSystemUtil.resolvePath( serverJSON.CFConfig.server, getDirectoryFromPath( serverInfo.serverConfigFile ) );
					addConfigFile( interceptData, 'server', results.CFConfigFiles, thisFile, '"CFConfig.server" server.json key' );
			}

			// Look for cfconfig.file.web as well as cfconfig.file['web-/path/to/webroot']
			serverJSON.CFConfig.each( (k,v)=>{
				if( ( k == 'web' || ( k.lCase().startsWith( 'web-' ) && serverInfo.multiContext ) ) && len( v ) ) {
					// Resolve paths to be relative to the location of the server.json
					var thisFile = fileSystemUtil.resolvePath( v, getDirectoryFromPath( serverInfo.serverConfigFile ) );
					addConfigFile( interceptData, k, results.CFConfigFiles, thisFile, '"CFConfig.#k#" server.json key' );
				}
			} )

			// Check for flag to keep tasks paused.
			if( serverJSON.CFConfig.keyExists( 'pauseTasks' )
				&& isBoolean( serverJSON.CFConfig.pauseTasks ) ) {

					// Resolve paths to be relative to the location of the server.json
					results.pauseTasks = serverJSON.CFConfig.pauseTasks;

					if( serverInfo.verbose && results.pauseTasks ) {
						logDebug( 'CFConfig will import scheduled tasks as paused.' );
					}
			}

		}

		// Check for flag to keep tasks paused.
		if( serverJSON.keyExists( 'CFConfigPauseTasks' )
			&& isBoolean( serverJSON.CFConfigPauseTasks ) ) {

				// Resolve paths to be relative to the location of the server.json
				results.pauseTasks = serverJSON.CFConfigPauseTasks;

				if( serverInfo.verbose && results.pauseTasks ) {
					logDebug( 'CFConfig will import scheduled tasks as paused.' );
				}
		}

		// fall back to file name by convention
		var conventionLocationRoot = normalizeSlashes( serverInfo.webroot );
		if( conventionLocationRoot.endsWith( '/' ) ) {
			conventionLocationRoot = conventionLocationRoot.left( -1 );
		}
		var conventionLocation = conventionLocationRoot & '/.cfconfig.json';
		var conventionLocationWeb = conventionLocationRoot & '/.cfconfig-web.json';
		var conventionLocationServer = conventionLocationRoot & '/.cfconfig-server.json';

		// We only look for a .cfconfig.json file by convention if we already haven't found any JSON for adobe or the lucee server context
		if( !results.CFConfigFiles.keyExists( createFormat( interceptData, 'server' ) ) && fileExists( conventionLocation ) ) {
				addConfigFile( interceptData, 'server', results.CFConfigFiles, conventionLocation, '".cfconfig.json" file in web root by convention' );
		}
		// We only look for a .cfconfig-web.json file by convention if we already haven't found any JSON for railo or the lucee server context
		if( !results.CFConfigFiles.keyExists( createFormat( interceptData, 'server' ) ) && fileExists( conventionLocationServer ) ) {
			addConfigFile( interceptData, 'server', results.CFConfigFiles, conventionLocationServer, '".cfconfig-server.json" file in web root by convention' );
		}
		// We only look for a .cfconfig-server.json file by convention if we already haven't found any JSON for railo or the lucee web context
		if( !results.CFConfigFiles.keyExists( createFormat( interceptData, 'web' ) ) && fileExists( conventionLocationWeb ) ) {
			addConfigFile( interceptData, 'web', results.CFConfigFiles, conventionLocationWeb, '".cfconfig-web.json" file in web root by convention' );
		}

		return results;
	}

	/*
	* Turns all slashes in a path to forward slashes except for \\ in a Windows UNC network share
	*/
	function normalizeSlashes( string path ) {
		if( path.left( 2 ) == '\\' ) {
			return '\\' & path.replace( '\', '/', 'all' ).right( -2 );
		} else {
			return path.replace( '\', '/', 'all' );
		}
	}

	// CommandBox 3/4 shim
	private function logError( message ) {
		if( jobEnabled && wirebox.getInstance( 'interactiveJob' ).isActive() ) {
			if( message == '.' ) { return; }
			var job = wirebox.getInstance( 'interactiveJob' );
			job.addErrorLog( message );
		} else {
			consoleLogger.error( message );
		}
	}

	private function logWarn( message ) {
		if( jobEnabled && wirebox.getInstance( 'interactiveJob' ).isActive() ) {
			if( message == '.' ) { return; }
			var job = wirebox.getInstance( 'interactiveJob' );
			job.addWarnLog( message );
		} else {
			consoleLogger.warn( message );
		}
	}

	private function logDebug( message ) {
		if( jobEnabled && wirebox.getInstance( 'interactiveJob' ).isActive() ) {
			if( message == '.' ) { return; }
			var job = wirebox.getInstance( 'interactiveJob' );
			job.addLog( message );
		} else {
			consoleLogger.debug( message );
		}
	}


	/**
	 * Run another command by DSL.
	 * @name The name of the command to run.
 	 **/
	function command( required name ) {
		return getinstance( name='CommandDSL', initArguments={ name : arguments.name } );
	}

}

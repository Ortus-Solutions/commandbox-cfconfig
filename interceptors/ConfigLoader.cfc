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
		var en = interceptData.installDetails.engineName;
		// Bail right now if this server isn't a CF engine.
		if( !( en contains 'lucee' || en contains 'railo' || en contains 'adobe' ) ) {
			return;
		}
		
		var results = findCFConfigFile( interceptData.serverInfo );
		var CFConfigFile = results.CFConfigFile;
		var pauseTasks = results.pauseTasks;
		
		// Get the config settings
		var configSettings = ConfigService.getconfigSettings();

		// Does the user want us to export setting when the server stops?
		var autoTransferOnUpgrade = configSettings.modules[ 'commandbox-cfconfig' ].autoTransferOnUpgrade ?: true; 
		
		// Clean up some slash nonsense
		interceptData.installDetails.installDir = normalizeSlashes( interceptData.installDetails.installDir );
		interceptData.serverInfo.customServerFolder = normalizeSlashes( interceptData.serverInfo.customServerFolder );
		
		// If we found a CFConfig JSON file, let's import it!
		if( CFConfigFile.len() ) {
			var rawJSON = fileRead( CFConfigFile );
			if( isJSON( rawJSON ) ) {
				
				if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
					logDebug( 'Importing CFConfig into server [#interceptData.serverInfo.name#]' );
				}
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig import' } )
					.params(
						from=CFConfigFile,
						fromFormat='JSON',
						to=interceptData.serverInfo.name,
						pauseTasks=pauseTasks
					).run();
					
				// Extra check for adminPassword on Lucee.  Set the web context as well
				var cfconfigJSON = deserializeJSON( rawJSON );
				// And swap out any system settings
				systemSettings.expandDeepSystemSettings( cfconfigJSON );
				if( interceptData.serverInfo.engineName == 'lucee' && cfconfigJSON.keyExists( 'adminPassword' ) ) {
					
					if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
						logDebug( 'Also setting adminPassword to Lucee web context.' );
					}
					
					getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
						.params( 
							to=interceptData.serverInfo.name,
							toFormat='luceeWeb',
							adminPassword=cfconfigJSON.adminPassword
						 ).run();
				}
						
			} else {
				logError( 'CFConfig file doesn''t contain valid JSON! [#CFConfigFile#]' );
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
						
						if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
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
						// Guess where the previous server/web context was. This won't be correct if there was a 
						// webConfigDir or serverConfigDir, but in that case it doesn't matter since there's nothing to copy anyway
						var previousWebContext = previousServerFolder & '/WEB-INF/lucee-web';
						var previousServerContext = previousServerFolder & '/WEB-INF/lucee-server';
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
						
						if( directoryExists( previousServerContext ) ) {
							
							if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
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

						if( directoryExists( previousWebContext ) ) {
								
							if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
								logDebug( 'Copying from [#previousWebContext#] to [#newWebContext#]' );
							}
							CFConfigService.transfer(
								from		= previousWebContext,
								to			= newWebContext,
								fromFormat	= 'luceeWeb',
								toFormat	= 'luceeWeb',
								fromVersion	= previousVersion,
								toVersion	= thisVersion
							);
							
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
		
		var processVarsUDF = function( envVar, value, title ) {
			// Loop over any that look like cfconfig_xxx
			if( envVar.len() > 9 && left( envVar, 9 ) == 'cfconfig_' ) {
				var name = right( envVar, len( envVar ) - 9 ).replace( '_', '.', 'all' );;
			
				if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
					logDebug( 'Found #title# [#envVar#]' );
				}				
				
				var params = {
					to=interceptData.serverInfo.name
				};
				params[ name ] = value;
				params.append = true;
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
					.params( argumentCollection=params )
					.run();
					
				// Extra check for adminPassword on Lucee.  Set the web context as well
				if( interceptData.serverInfo.engineName == 'lucee' && name == 'adminPassword' ) {
					
					if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
						logDebug( 'Also setting adminPassword to Lucee web context.' );
					}
					
					params.toFormat = 'luceeWeb';
					getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
						.params( argumentCollection=params )
						.run();
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
		
	}
	
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
			var results = findCFConfigFile( interceptData.serverInfo );
			var CFConfigFile = results.CFConfigFile;
		
			if( CFConfigFile.len() ) {
				
				if( interceptData.serverInfo.verbose ?: interceptData.serverInfo.debug ) {
					logDebug( 'Exporting CFConfig from server into [#CFConfigFile#]' );
				}
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig export' } )
					.params(
						to=CFConfigFile,
						toFormat='JSON',
						from=interceptData.serverInfo.name
					).run();
			}
			
		}
				
	}
	
	private struct function findCFConfigFile( serverInfo ) {
		var results = {
			CFConfigFile = '',
			pauseTasks = false
		};
		
		// An env var of cfconfig wins
		if( systemSettings.getSystemSetting( 'cfconfigfile', '' ).len() ) {
			
			results.CFConfigFile = systemSettings.getSystemSetting( 'cfconfigfile' );
			
			if( serverInfo.debug ) {
				logDebug( 'Found CFConfigFile environment variable.' );
				logDebug( 'CFConfig file set to [#results.CFConfigFile#].' );
			}
			
		}
		
		// If there is a server.json file for this server
		var serverJSON = {};
		if( !results.CFConfigFile.len()
			&& serverInfo.keyExists( 'serverConfigFile' ) 
			&& serverInfo.serverConfigFile.len()
			&& fileExists( serverInfo.serverConfigFile ) ) {
				// Read it in
				serverJSON = serverService.readServerJSON( serverInfo.serverConfigFile );
				// And swap out any system settings
				systemSettings.expandDeepSystemSettings( serverJSON );
		}
		
		// If there is a CFConfig specified, let's use it.
		if( serverJSON.keyExists( 'CFConfigFile' )
			&& serverJSON.CFConfigFile.len() ) {
				
				// Resolve paths to be relative to the location of the server.json
				results.CFConfigFile = fileSystemUtil.resolvePath( serverJSON.CFConfigFile, getDirectoryFromPath( serverInfo.serverConfigFile ) );
				
				if( serverInfo.debug ) {
					logDebug( 'Found CFConfig file in [#serverInfo.serverConfigFile#].' );
					logDebug( 'CFConfig file set to [#results.CFConfigFile#].' );
				}
		}
		
		// Check for flag to keep tasks paused.
		if( serverJSON.keyExists( 'CFConfigPauseTasks' )
			&& isBoolean( serverJSON.CFConfigPauseTasks ) ) {
				
				// Resolve paths to be relative to the location of the server.json
				results.pauseTasks = serverJSON.CFConfigPauseTasks;
				
				if( serverInfo.debug && results.pauseTasks ) {
					logDebug( 'CFConfig will import scheduled tasks as paused.' );
				}
		}

		// fall back to file name by convention
		var conventionLocation = normalizeSlashes( serverInfo.webroot ) & '/.cfconfig.json';
			
		if( !results.CFConfigFile.len()
			&& fileExists( conventionLocation ) ) {
				
				if( serverInfo.debug ) {
					logDebug( 'Found CFConfig file by convention in webroot.' );
					logDebug( 'CFConfig file set to [#conventionLocation#].' );
				}
				
				results.CFConfigFile = conventionLocation;
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
	
}
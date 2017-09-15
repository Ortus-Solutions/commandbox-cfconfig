component {
	property name='fileSystemUtil'	inject='FileSystem';
	property name='serverService'	inject='ServerService';
	property name='systemSettings'	inject='SystemSettings';
	property name='consoleLogger'	inject='logbox:logger:console';
	property name='ConfigService'	inject='ConfigService';
	property name='semanticVersion'	inject='provider:semanticVersion@semver';
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
		
	function onServerInstall( interceptData ) {
		var CFConfigFile = findCFConfigFile( interceptData.serverInfo );
		
		// Get the config settings
		var configSettings = ConfigService.getconfigSettings();

		// Does the user want us to export setting when the server stops?
		var autoTransferOnUpgrade = configSettings.modules[ 'commandbox-cfconfig' ].autoTransferOnUpgrade ?: true; 
		
		// Clean up some slash nonsense
		interceptData.installDetails.installDir = interceptData.installDetails.installDir.replace( '\', '/', 'all' );
		interceptData.serverInfo.customServerFolder = interceptData.serverInfo.customServerFolder.replace( '\', '/', 'all' );
		
		// If we found a CFConfig JSON file, let's import it!
		if( CFConfigFile.len() ) {
			var rawJSON = fileRead( CFConfigFile );
			if( isJSON( rawJSON ) ) {
				
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Importing CFConfig into server [#interceptData.serverInfo.name#]' );
				}
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig import' } )
					.params(
						from=CFConfigFile,
						fromFormat='JSON',
						to=interceptData.serverInfo.name
					).run();
					
				// Extra check for adminPassword on Lucee.  Set the web context as well
				var cfconfigJSON = deserializeJSON( rawJSON );
				// And swap out any system settings
				systemSettings.expandDeepSystemSettings( cfconfigJSON );
				if( interceptData.serverInfo.engineName == 'lucee' && cfconfigJSON.keyExists( 'adminPassword' ) ) {
					
					if( interceptData.serverInfo.debug ) {
						consoleLogger.info( 'Also setting adminPassword to Lucee web context.' );
					}
					
					getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
						.params( 
							to=interceptData.serverInfo.name,
							toFormat='luceeWeb',
							adminPassword=cfconfigJSON.adminPassword
						 ).run();
				}
						
			} else {
				consoleLogger.error( 'CFConfig file doesn''t contain valid JSON! [#CFConfigFile#]' );
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
				path = path.replace( '\', '/', 'all' );
				
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
							
						} // Enging tag has proper contents
					} // enginet tag exists
				} // ignore ourselves
			} ); // server dir each

			// Did we find a previous version of this engine?
			if( previousServerFolder.len() ) {
				consoleLogger.warn( 'Auto importing settings from your previous [#thisEngine#@#previousVersion#] server.' );
				consoleLogger.warn( 'Turn off this feature with [config set modules.commandbox-cfconfig.autoTransferOnUpgrade=false]' );
				
				try {
					
					if( thisEngine == 'adobe' ) {
						
						if( interceptData.serverInfo.debug ) {
							consoleLogger.debug( 'Copying from [#previousServerFolder#/WEB-INF/cfusion] to [#thisInstallDir#/WEB-INF/cfusion]' );
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
											
						
						if( interceptData.serverInfo.debug ) {
							consoleLogger.debug( 'Copying from [#previousServerFolder#/WEB-INF/lucee-server] to [#thisInstallDir#/WEB-INF/lucee-server]' );
						}
						CFConfigService.transfer(
							from		= previousServerFolder & '/WEB-INF/lucee-server',
							to			= thisInstallDir & '/WEB-INF/lucee-server',
							fromFormat	= 'luceeServer',
							toFormat	= 'luceeServer',
							fromVersion	= previousVersion,
							toVersion	= thisVersion
						);
											
						
						if( interceptData.serverInfo.debug ) {
							consoleLogger.debug( 'Copying from [#previousServerFolder#/WEB-INF/lucee-web] to [#thisInstallDir#/WEB-INF/lucee-web]' );
						}
						CFConfigService.transfer(
							from		= previousServerFolder & '/WEB-INF/lucee-web',
							to			= thisInstallDir & '/WEB-INF/lucee-web',
							fromFormat	= 'luceeWeb',
							toFormat	= 'luceeWeb',
							fromVersion	= previousVersion,
							toVersion	= thisVersion
						);
					
					}
				} catch( any var e ) {
					consoleLogger.error( 'Oh, snap! We had an error auto-importing your settings.  Please report this error.' );
					consoleLogger.error( e.message );
					consoleLogger.error( e.detail );
					consoleLogger.error( '    ' & e.tagContext[ 1 ].template & ':' &  e.tagContext[ 1 ].line );
				}
			}				
		}

		// Look for individual CFConfig settings to import.
		var system = createObject( 'java', 'java.lang.System' );
		// Get all env vars
		var envVars = system.getenv();
		for( var envVar in envVars ) {
			// Loop over any that look like cfconfig_xxx
			if( envVar.len() > 9 && left( envVar, 9 ) == 'cfconfig_' ) {
				var value = envVars[ envVar ];
				var name = right( envVar, len( envVar ) - 9 );
			
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Found environment variable [#envVar#]' );
				}				
				
				var params = {
					to=interceptData.serverInfo.name
				};
				params[ name ] = value;
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
					.params( argumentCollection=params )
					.run();
					
				// Extra check for adminPassword on Lucee.  Set the web context as well
				if( interceptData.serverInfo.engineName == 'lucee' && name == 'adminPassword' ) {
					
					if( interceptData.serverInfo.debug ) {
						consoleLogger.info( 'Also setting adminPassword to Lucee web context.' );
					}
					
					params.toFormat = 'luceeWeb';
					getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig set' } )
						.params( argumentCollection=params )
						.run();
				}
				
			}
		}
	}
	
	function onServerStop( interceptData ) {

		// Get the config settings
		var configSettings = ConfigService.getconfigSettings();

		// Does the user want us to export setting when the server stops?
		var exportOnStop = configSettings.modules[ 'commandbox-cfconfig' ].exportOnStop ?: false; 
		if( exportOnStop ) {
			var CFConfigFile = findCFConfigFile( interceptData.serverInfo );
		
			if( CFConfigFile.len() ) {
				
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Exporting CFConfig from server into [#CFConfigFile#]' );
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
	
	private function findCFConfigFile( serverInfo ) {
		var CFConfigFile = '';
		
		// An env var of cfconfig wins
		if( systemSettings.getSystemSetting( 'cfconfigfile', '' ).len() ) {
			
			CFConfigFile = systemSettings.getSystemSetting( 'cfconfigfile' );
			
			if( serverInfo.debug ) {
				consoleLogger.info( 'Found CFConfigFile environment variable.' );
				consoleLogger.info( 'CFConfig file set to [#CFConfigFile#].' );
			}
			
		}
		
		// If there is a server.json file for this server
		var serverJSON = {};
		if( !CFConfigFile.len()
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
				CFConfigFile = fileSystemUtil.resolvePath( serverJSON.CFConfigFile, getDirectoryFromPath( serverInfo.serverConfigFile ) );
				
				if( serverInfo.debug ) {
					consoleLogger.info( 'Found CFConfig file in [#serverInfo.serverConfigFile#].' );
					consoleLogger.info( 'CFConfig file set to [#CFConfigFile#].' );
				}
		}

		// fall back to file name by convention
		var conventionLocation = serverInfo.webroot
			// Normalize slashes
			.replace( '\', '/', 'all' )
			// Remove trailing slashes
			.listChangeDelims( '/', '/' )
			// Append file name
			.listAppend( '.cfconfig.json', '/' );
			
		// On *nix OSes we need the leading slash back
		if( serverInfo.webroot.left( 1 ) == '/' ) {
			conventionLocation = '/' & conventionLocation;
		}
			
		if( !CFConfigFile.len()
			&& fileExists( conventionLocation ) ) {
				
				if( serverInfo.debug ) {
					consoleLogger.info( 'Found CFConfig file by convention in webroot.' );
					consoleLogger.info( 'CFConfig file set to [#conventionLocation#].' );
				}
				
				CFConfigFile = conventionLocation;
			}
			
		return CFConfigFile;		
	}
	
}
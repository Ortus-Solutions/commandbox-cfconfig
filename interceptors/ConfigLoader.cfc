component {
	property name='fileSystemUtil'	inject='FileSystem';
	property name='serverService'	inject='ServerService';
	property name='systemSettings'	inject='SystemSettings';
	property name='consoleLogger'	inject='logbox:logger:console';
	property name='ConfigService'	inject='ConfigService';
	
	function onServerInstall( interceptData ) {
		var CFConfigFile = findCFConfigFile( interceptData.serverInfo );
		
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
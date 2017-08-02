component {
	property name='fileSystemUtil'	inject='FileSystem';
	property name='serverService'	inject='ServerService';
	property name='systemSettings'	inject='SystemSettings';
	property name='consoleLogger'	inject='logbox:logger:console';
	
	function onServerInstall( interceptData ) {
		var serverJSON = {};
		var CFConfigFile = '';
		
		// An env var of cfconfig wins
		if( systemSettings.getSystemSetting( 'cfconfig', '' ).len() ) {
			
			CFConfigFile = systemSettings.getSystemSetting( 'cfconfig' );
			
			if( interceptData.serverInfo.debug ) {
				consoleLogger.info( 'Found CFConfig file in environment variable.' );
				consoleLogger.info( 'CFConfig file set to [#CFConfigFile#].' );
			}
			
		}
		
		// If there is a server.json file for this server
		if( !CFConfigFile.len()
			&& interceptData.serverInfo.keyExists( 'serverConfigFile' ) 
			&& interceptData.serverInfo.serverConfigFile.len()
			&& fileExists( interceptData.serverInfo.serverConfigFile ) ) {
				// Read it in
				serverJSON = serverService.readServerJSON( interceptData.serverInfo.serverConfigFile );
				// And swap out any system settings
				systemSettings.expandDeepSystemSettings( serverJSON );
			}
		
		// If there is a CFConfig specified, let's use it.
		if( serverJSON.keyExists( 'CFConfigFile' )
			&& serverJSON.CFConfigFile.len() ) {
				
				// Resolve paths to be relative to the location of the server.json
				CFConfigFile = fileSystemUtil.resolvePath( serverJSON.CFConfigFile, getDirectoryFromPath( interceptData.serverInfo.serverConfigFile ) );
				
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Found CFConfig file in [#interceptData.serverInfo.serverConfigFile#].' );
					consoleLogger.info( 'CFConfig file set to [#CFConfigFile#].' );
				}
		}

		// fall back to file name by convention
		var conventionLocation = interceptData.serverInfo.webroot
			// Normalize slashes
			.replace( '\', '/', 'all' )
			// Remove trailing slashes
			.listChangeDelims( '/', '/' )
			// Append file name
			.listAppend( '.cfconfig.json', '/' );
			
		if( !CFConfigFile.len()
			&& fileExists( conventionLocation ) ) {
				
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Found CFConfig file by convention in webroot.' );
					consoleLogger.info( 'CFConfig file set to [#conventionLocation#].' );
				}
				
				CFConfigFile = conventionLocation;
			}
		
		// If we found a CFConfig JSON file, let's import it!
		if( CFConfigFile.len() ) {
			
			if( isJSON( fileRead( CFConfigFile ) ) ) {
			
				if( interceptData.serverInfo.debug ) {
					consoleLogger.info( 'Importing CFConfig into server [#interceptData.serverInfo.name#]' );
				}
				
				getWirebox().getInstance( name='CommandDSL', initArguments={ name : 'cfconfig import' } )
					.params(
						from=CFConfigFile,
						fromFormat='JSON',
						to=interceptData.serverInfo.name
					).run();
						
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
				
			}
		}
	}
	
}
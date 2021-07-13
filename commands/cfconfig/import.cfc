/**
* Import configuration to a server.  If you don't specify a to, we look for a CommandBox server using the current working
* directory.  Only rely on this if you have a single CommandBox server running in the current directory.  
* 
* {code:bash}
* cfconfig import myConfig.json
* cfconfig import serverNameToImportFrom
* cfconfig import to=/path/to/server/home/to/import/from
* {code}
* 
* When specifying the direct path to the server home, here are the rules based on the engine you're using:
* For Lucee's web context, point to the folder containing the lucee-web.xml.cfm file.
* Ex: <webroot>/WEB-INF/lucee
* 
* For Lucee's server context, point to be the "lucee-server" folder containing the /context/lucee-server.xml file.
* Ex: /opt/lucee/lib/lucee-server
*
* For Adobe servers, point to the "cfusion" folder containing the lib/neo-runtime.xml file.
* Ex: C:/ColdFusion11/cfusion
*   
* For CommandBox servers, we'll get the engine/version out of CommandBox's metadata.  For non-CommandBox servers, you'll need to help me out by
* specifying what kind of file format to use.
* 
* For the fromFormat and toFormat, use the name of the engine followed by @ and then the engine version like engine@version.  
* For lucee, specify the web or sever context.  Valid engines are "luceeWeb", "luceeServer", and "adobe".  
* For partial versions, the missing pieces will be interpreted as zeros.  Meaning adobe@11 is the same as adobe@11.0.0.
* Examples are:
* - adobe@11.0.11
* - luceeWeb@5
* - luceeServer@4.5
* 
* {code:bash}
* cfconfig import from=/path/to/.CFConfig.json to=/path/to/server/home toFormat=luceeServer@5.1
* {code}
* 
* The version number can be left off toFormat and fromFormat when reading or writing to a CFConfig JSON file or a CommandBox server since we already know the version.
* If you don't specify a Lucee web or Server context, we default to server. Use a format of "luceeWeb" to switch.
* 
* You can customize what config settings are transferred with the includeList and excludeList params.  If at least one include pattern is provided, ONLY matching 
* settings will be included.  Nested keys such as datasources.myDSN or mailservers[1] can be used.  You may also use basic wildcards in your pattern.  A single *
* will match any number of chars inside a key name.  A double ** will match any number of nested keys.
* 
* {code:bash}
* # Include all settings starting with "event"
* cfconfig import from=.CFConfig.json includeList=event*
* # Exclude all keys called "password" regardless of what struct they are in
* cfconfig import from=.CFConfig.json excludeList=**.password
* {code}
* 
* Use the append parameter to merge incoming data with any data already present.  For example, if a server already has one datasource defined and you import
* a JSON file with 2 more unique datasources, the --append flag will not remove the pre-existing one.
* 
* {code:bash}
* cfconfig import from=.CFConfig.json includeList=datasources --append
* {code}
* 
*/
component {
	property name="serverService" inject="ServerService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @fromFormat The format to read from when "from" is a directory. Ex: LuceeServer@5
	* @toFormat The format to write to when "to" is a directory. Ex: LuceeServer@5
	* @pauseTasks It set to true, all scheduled tasks will be saved to the "to" server in a "Paused" state
	* @includeList List of properties to include in transfer. Use * for wildcard. i.e. mailservers,datasources.myDSN,event*
	* @includeList.optionsUDF propertyComplete
	* @excludeList List of properties to exclude from transfer. Use * for wildcard. i.e. mailservers,datasources.myDSN,event*
	* @excludeList.optionsUDF propertyComplete
	* @replace regex/replacement matches to swap data with env var expansions. i.e. replace:datasources.*.password=DB_PASSWORD
	* @dotenvFile Absolute path to .env file for replace feature. Empty string turns off feature.
	* @append Append config to destination instead of overwriting. Datasources, caches, etc will be merged instead of removed.
	*/	
	function run(
		string from,
		string to,
		string fromFormat,
		string toFormat,
		boolean pauseTasks=false,
		string includeList='',
		string excludeList='',
		struct replace={},
		string dotenvFile=getCWD() & '.env',
		boolean append=false
		) {

		CFConfigService = getInstance( 'CFConfigService@cfconfig-services' );
		Util = getInstance( 'util@commandbox-cfconfig' );
		moduleSettings = getInstance( dsl='commandbox:moduleSettings:commandbox-cfconfig' );

		if( len( dotenvFile ) ) {
			dotenvFile = resolvePath( dotenvFile );
		}
		
		arguments.from = arguments.from ?: '';
		arguments.to = arguments.to ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		arguments.toFormat = arguments.toFormat ?: '';
		
		if( !from.len() && !to.len() ) {
			error( "Please specify either a 'from' or a 'to' location.  I'm not sure what to copy where." );
		}
				
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat, 'from' );
			var toDetails = Util.resolveServerDetails( to, toFormat, 'to' );
		
			if( toDetails.format == 'json' ) {
				// Add in any global JSON expansions
				replace.append( moduleSettings.JSONExpansions, false );	
			}
			
			if( !fromDetails.path.len() ) {
				error( "The location for the 'from' server couldn't be determined.  Please check your spelling." );
			}
			
			if( !directoryExists( fromDetails.path ) && !fileExists( fromDetails.path ) ) {
				error( "The CF Home directory for the 'from' server doesn't exist.  [#fromDetails.path#]" );				
			}
			
			if( !toDetails.path.len() ) {
				error( "The location for the 'to' server couldn't be determined.  Please check your spelling." );
			}
			
			CFConfigService.transfer(
				from				= fromDetails.path,
				to					= toDetails.path,
				fromFormat			= fromDetails.format,
				toFormat			= toDetails.format,
				fromVersion			= fromDetails.version,
				toVersion			= toDetails.version,
				pauseTasks			= pauseTasks,
				includeList			= includeList,
				excludeList			= excludeList,
				replace				= replace,
				dotenvFile			= dotenvFile,
				append				= append
			);
			
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		} catch( cfconfigNoProviderFound var e ) {
			error( e.message, e.detail ?: '' );
		}
		
		print.greenLine( 'Config transferred!' );
		
		/* command( 'cfconfig transfer' )
			.params( argumentCollection = arguments )
			.run(); */
	}

	function propertyComplete() {
		return getInstance( 'BaseConfig@cfconfig-services' ).getConfigProperties();
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
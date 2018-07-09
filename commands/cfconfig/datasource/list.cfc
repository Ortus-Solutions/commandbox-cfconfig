/**
* List all datasources for a server.
* 
* {code}
* cfconfig datasource list
* cfconfig datasource list from=serverName
* cfconfig datasource list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig datasource list --JSON
* {code}
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	* @JSON Set to try to receive mappings back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		if( !fromDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}
		
		if( !directoryExists( fromDetails.path ) && !fileExists( fromDetails.path ) ) {
			error( "The CF Home directory for the server doesn't exist.  [#fromDetails.path#]" );
		}
		
		// Read the config
		var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version )
			.read( fromDetails.path );

		// Get the mappings, remembering it can be null
		var datasources = oConfig.getDatasources() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( datasources ) );
		} else {
			if( datasources.len() ) {
				for( var datasource in datasources ) {
					var datasourceDetails = datasources[ datasource ];
					print.boldLine( 'Name: #datasource#' );
					print.indentedLine( 'DB Driver: #datasourceDetails.dbdriver#' );
					if( !isNull( datasourceDetails.host ) && len( datasourceDetails.host ) ) { print.indentedLine( 'Host: #datasourceDetails.host#' ); }
					if( !isNull( datasourceDetails.port ) && len( datasourceDetails.port ) ) { print.indentedLine( 'Port: #datasourceDetails.port#' ); }
					if( !isNull( datasourceDetails.database ) && len( datasourceDetails.database ) ) { print.indentedLine( 'Database: #datasourceDetails.database#' ); }
					if( !isNull( datasourceDetails.username ) && len( datasourceDetails.username ) ) { print.indentedLine( 'Username: #datasourceDetails.username#' ); }
					if( !isNull( datasourceDetails.password ) && len( datasourceDetails.password ) ) { print.indentedLine( 'Password: #datasourceDetails.password#' ); }
					if( datasourceDetails.dbdriver == 'other' ) {
						if( !isNull( datasourceDetails.dsn ) && len( datasourceDetails.dsn ) ) { print.indentedLine( 'JDBC URL: #datasourceDetails.dsn#' ); }
						if( !isNull( datasourceDetails.class ) && len( datasourceDetails.class ) ) { print.indentedLine( 'Class: #datasourceDetails.class#' ); }					
					}
				print.line();
				}
			} else {
				print.line( 'No datasources defined.' );
			}
		}
			
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
/**
* List all event gateway instances for a server.
* 
* {code}
* cfconfig eventgatewayinstance list
* cfconfig eventgatewayinstance list from=serverName
* cfconfig eventgatewayinstance list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig eventgatewayinstance list --JSON
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
		var eventGatewayInstances = oConfig.getEventGatewayInstances() ?: [];
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( eventGatewayInstances ) );
		} else {
			if( eventGatewayInstances.len() ) {
				for( var eventGatewayInstance in eventGatewayInstances ) {
					print.boldLine( 'Gateway ID: #eventGatewayInstance.gatewayId#' );
					print.indentedLine( 'Type: #eventGatewayInstance.type#' );
					print.indentedLine( 'CFC Paths: #eventGatewayInstance.cfcPaths.toList()#' );
					print.indentedLine( 'Startup: #eventGatewayInstance.mode#' );
					print.indentedLine( 'Configuration path: #eventGatewayInstance.configurationPath#' );
					print.line();
				}
			} else {
				print.line( 'No event gateway instances defined.' );
			}
		}

	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
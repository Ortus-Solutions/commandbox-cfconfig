/**
* List all Lucee event gateway instances for a server.
* 
* {code}
* cfconfig eventgatewaylucee list
* cfconfig eventgatewaylucee list from=serverName
* cfconfig eventgatewaylucee list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig eventgatewaylucee list --JSON
* {code}
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	property name="ConfigService" inject="ConfigService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	* @JSON Set to try to receive mappings back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat='luceeWeb',
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat, 'from' );
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
		var eventGatewayInstances = oConfig.getEventGatewaysLucee() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
					
			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( eventGatewayInstances );
			} else {
				print.line( formatterUtil.formatJSON( eventGatewayInstances ) );	
			}
			
		} else {
			if( eventGatewayInstances.count() ) {
				for( var id in eventGatewayInstances ) {
					var eventGatewayInstance = eventGatewayInstances[ id ];
					print.boldLine( 'Gateway ID: #id#' );
					if( !isNull( eventGatewayInstance.CFCPath ) ) { print.indentedLine( 'CFC Path: #eventGatewayInstance.CFCPath#' ); }
					if( !isNull( eventGatewayInstance.listenerCFCPath ) ) { print.indentedLine( 'Listener CFC Path: #eventGatewayInstance.listenerCFCPath#' ); }
					if( !isNull( eventGatewayInstance.startupMode ) ) { print.indentedLine( 'Startup: #eventGatewayInstance.startupMode#' ); }
					print.line();
				}
			} else {
				print.line( 'No Lucee event gateway instances defined.' );
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
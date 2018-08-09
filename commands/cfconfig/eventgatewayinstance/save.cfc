/**
* Add a new event gateway instance or update an existing event gateway config. Existing event gateway instance will be matched based on gateway Id.
* 
* {code}
* cfconfig eventgatewayinstance save myInstance CFML "/path1/some.cfc,/path2/code.cfc"
* cfconfig eventgatewayinstance save gatewayId=myInstance type=CFML cfcPaths="/path1/some.cfc,/path2/code.cfc" configurationPath="path3" to=serverName
* {code}
*
*/

component {
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @gatewayId An event gateway ID to identify the specific event gateway instance.
	* @type The event gateway type, which you select from the available event gateway types, such as SMS or Socket.
	* @cfcPaths A comma separated list with the absolute path (or paths) to the listener CFC or CFCs that handle incoming messages.
	* @mode The event gateway start-up status; one of the following: automatic, manual, disabled
	* @configurationPath A configuration file, if necessary for this event gateway type or instance.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(required string gatewayId,
				 required string type,
				 required string cfcPaths,
				 string mode,
				 string configurationPath,
				 string to,
				 string toFormat)
	{
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';

		try {
			var toDetails = Util.resolveServerDetails( to, toFormat );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		if( !toDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}
				
		// Read existing config
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version );
		try {
			oConfig.read( toDetails.path );	
		} catch( any e ) {
			// Handle this better by specifically checking if there's config 
		}
		
		// Preserve this as a struct, not an array
		var gatewayInstanceParams = duplicate( {}.append( arguments ) );
		gatewayInstanceParams.cfcPaths = listToArray(gatewayInstanceParams.cfcPaths);
		gatewayInstanceParams.delete( 'to' );
		gatewayInstanceParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addGatewayInstance( argumentCollection = gatewayInstanceParams )
			.write( toDetails.path );
				
		print.greenLine( 'Event gateway instance [#arguments.gatewayId#] saved.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

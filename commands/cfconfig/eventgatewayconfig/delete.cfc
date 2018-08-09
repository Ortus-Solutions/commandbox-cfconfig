/**
* Delete a event gateway config. Identify the event gateway config uniquely by the type.
* 
* {code}
* cfconfig eventgatewayconfig delete myType
* cfconfig eventgatewayconfig delete myType serverName
* cfconfig eventgatewayconfig delete myType  /path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @type The event gateway type.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(
		required string type,
		string to,
		string toFormat
	) {
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
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version )
			.read( toDetails.path );

		// Get the event gateway configurations and remove the requested one
		var eventGatewayConfigurations = oConfig.getEventGatewayConfigurations() ?: [];
		var i=0;
		for( var thisEventGatewayConfiguration in eventGatewayConfigurations ) {
			i++;
			if( thisEventGatewayConfiguration.type == arguments.type ) {
				eventGatewayConfigurations.deleteAt( i );
				break;
			}
		}
		
		// Set remaining mappings back and save
		oConfig.setEventGatewayConfigurations( eventGatewayConfigurations )
			.write( toDetails.path );		
			
		print.greenLine( 'Event gateway configuration [#arguments.type#] deleted.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
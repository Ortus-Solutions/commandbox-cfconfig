/**
* Delete a event gateway instance. Identify the event gateway instance uniquely by the id.
* 
* {code}
* cfconfig eventgatewayinstance delete myInstanceId
* cfconfig eventgatewayinstance delete myInstanceId serverName
* cfconfig eventgatewayinstance delete myInstanceId /path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @gatewayId The event gateway id to be deleted.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(
		required string gatewayId,
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

		// Get the event gateway instances and remove the requested one
		var eventGatewayInstances = oConfig.getEventGatewayInstances() ?: [];
		var i=0;
		for( var thisEventGatewayInstance in eventGatewayInstances ) {
			i++;
			if( thisEventGatewayInstance.gatewayId == arguments.gatewayId ) {
				eventGatewayInstances.deleteAt( i );
				break;
			}
		}
		
		// Set remaining mappings back and save
		oConfig.setEventGatewayInstances( eventGatewayInstances )
			.write( toDetails.path );		
			
		print.greenLine( 'Event gateway instance [#arguments.gatewayId#] deleted.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
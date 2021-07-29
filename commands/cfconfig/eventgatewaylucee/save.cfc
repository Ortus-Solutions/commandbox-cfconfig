/**
* Add a new lucee event gateway instance or update an existing event gateway config. Existing event gateway instance will be matched based on gateway Id.
* 
* {code}
* cfconfig eventgatewaylucee save myGateway lucee.extension.gateway.AsynchronousEvents
* cfconfig eventgatewaylucee save gatewayid=myGateway cfcpath=lucee.extension.gateway.AsynchronousEvents startupMode=disabled
* {code}
*
*/

component {
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @gatewayId An event gateway ID to identify the specific event gateway instance.
	* @CFCPath Component path (dot delimieted) to the gateway CFC
	* @ListenerCFCPath Component path (dot delimieted) to the listener CFC
	* @custom A struct of additional configuration for this gateway
	* @startupMode The startup mode of the gateway.  Values: manual, automatic, disabled
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(required string gatewayID,
					required string CFCPath,
					string listenerCFCPath,
					struct custom={},
					string startupMode="automatic"
					string to,
					string toFormat='luceeWeb')
	{
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';

		try {
			var toDetails = Util.resolveServerDetails( to, toFormat, 'to' );
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
		gatewayInstanceParams.delete( 'to' );
		gatewayInstanceParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addGatewayLucee( argumentCollection = gatewayInstanceParams )
			.write( toDetails.path );
				
		print.greenLine( 'Lucee Event gateway instance [#arguments.gatewayId#] saved.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

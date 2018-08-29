/**
* Add a new event gateway config or update an existing event gateway config. Existing event gateway config will be matched based on type.
* 
* {code}
* cfconfig eventgatewayconfig save myType "description of gateway" "java.class" 30 true
* cfconfig eventgatewayconfig save type=myType description="description of gateway" class="java.class" starttimeout=30 killontimeout=true to=serverName
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @type The event gateway type, which you will use when adding an event gateway config.
	* @description Description
	* @class Java Class
	* @starttimeout Startup Timeout(in seconds)
	* @killontimeout Stop on Startup Timeout
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(required string type,
				 required string description,
				 required string class,
				 numeric starttimeout,
				 boolean killontimeout,
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
		var gatewayConfigurationParams = duplicate( {}.append( arguments ) );
		gatewayConfigurationParams.delete( 'to' );
		gatewayConfigurationParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addGatewayConfiguration( argumentCollection = gatewayConfigurationParams )
			.write( toDetails.path );
				
		print.greenLine( 'Event gateway configuration [#arguments.type#] saved.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

/**
* Delete a CF Mapping.  Identify the mapping uniquely by the virtual path.
* 
* {code}
* cfconfig cfmapping delete /foo
* cfconfig cfmapping delete /foo serverName
* cfconfig cfmapping delete /foo /path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	/**
	* @virtual The virtual path such as /foo
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string virtual,
		string to,
		string toFormat
	) {		
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
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version )
			.read( toDetails.path );

		// Get the CF mappings and remove the requested one
		var CFMappings = oConfig.getCFMappings() ?: {};
		CFMappings.delete( virtual );	
		
		// Set remaining mappings back and save
		oConfig.setCFMappings( CFMappings )
			.write( toDetails.path );		
			
		print.greenLine( 'CF Mapping [#virtual#] deleted.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
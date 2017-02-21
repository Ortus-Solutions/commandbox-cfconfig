/**
* Add a mew CF mapping or update an existing CF Mapping.  Existing mappings will be matched based on the virtual path.
* 
* {code}
* cfconfig cfmapping save /foo C:/foo/bar
* cfconfig cfmapping save virtual=/foo physical=C:/foo/bar to=serverName
* cfconfig cfmapping save virtual=/foo physical=C:/foo/bar to=/path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @virtual The virtual path such as /foo
	* @physical The physical path that the mapping points to
	* @archive Path to the Lucee/Railo archive
	* @inspectTemplate String containing one of "never", "once", "always", "" (inherit)
	* @listenerMode 
	* @listenerType 
	* @primary Strings containing one of "physical", "archive"
	* @readOnly True/false
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string virtual,
		string physical,
		string archive,
		string inspectTemplate,
		string listenerMode,
		string listenerType,
		string primary,
		boolean readOnly,
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
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version );
			//.read( toDetails.path );
		
		// Preserve this as a struct, not an array
		var CFMappingParams = duplicate( {}.append( arguments ) );
		CFMappingParams.delete( 'to' );
		CFMappingParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addCFMapping( argumentCollection = CFMappingParams )
			.write( toDetails.path );
				
		print.greenLine( 'CF Mapping [#virtual#] saved.' );		
	}
	
}
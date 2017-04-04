/**
* Add a mew cache or update an existing cache.  Existing caches will be matched based on the name.
* 
* {code}
* cfconfig cache save myCache lucee.runtime.cache.ram.RamCache
* cfconfig cache save name=myCache class=lucee.runtime.cache.ram.RamCache to=serverName
* cfconfig cache save name=myCache class=lucee.runtime.cache.ram.RamCache to=/path/to/server/home
* {code}
* 
* If your cache provider expects custom properties, pass them as additional parameters to this
* command prefixed with the text "custom-". This requires named parameters, of course.
* 
* {code}
* cfconfig cache save name=myCache class=lucee.runtime.cache.ram.RamCache custom-timeToIdleSeconds=0 custom-timeToLiveSeconds=0
* {code}
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @name The name of the cache to save
	* @class Java class of implementing provider
	* @readOnly No idea what this does
	* @storage Is this cache used for session or client scope storage?
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string name,
		string class,
		boolean readOnly,
		boolean storage,
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
		try {
			oConfig.read( toDetails.path );	
		} catch( any e ) {
			// Handle this better by specifically checking if there's config 
		}
		
		// Preserve this as a struct, not an array
		var cacheParams = duplicate( {}.append( arguments ) );
		cacheParams.delete( 'to' );
		cacheParams.delete( 'toFormat' );
		if( !isNull( cacheParams.readOnly ) ) { cacheParams[ 'read-only' ] = cacheParams.readOnly; }
		
		// Loop over command arguments and look for custom-XXX
		var customStruct = {};
		for( var arg in cacheParams ) {
			if( left( arg, 7 ) == 'custom-' ) {
				customStruct[ arg.listRest( '-' ) ] = cacheParams[ arg ];
			}
		}
		
		// If we found at least one custom property, add the struct
		if( customStruct.count() ) {
			cacheParams.custom = customStruct;
		}
		
		
		// Add cache to config and save.
		oConfig.addCache( argumentCollection = cacheParams )
			.write( toDetails.path );
				
		print.greenLine( 'Cache [#name#] saved.' );		
	}
	
}
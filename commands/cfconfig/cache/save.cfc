/**
* Add a new cache or update an existing cache.  Existing caches will be matched based on the name.
* 
* You can use a the "type" parameter as a shortcut for specifying the full Java class, which may change between versions.
* 
* {code}
* cfconfig cache save myCache RAM
* cfconfig cache save name=myOtherCache type=EHCache
* {code}
* 
* Alternatively, specify the full class name.
* 
* {code}
* cfconfig cache save myCache lucee.runtime.cache.ram.RamCache
* cfconfig cache save name=myCache class=lucee.runtime.cache.ram.RamCache to=serverName
* cfconfig cache save name=myCache class=lucee.runtime.cache.ram.RamCache to=/path/to/server/home
* {code}
* 
* If your cache provider expects custom properties, pass them as additional parameters to this
* command prefixed with the text "custom:". This requires named parameters, of course.
* 
* {code}
* cfconfig cache save name=myCache type=RAM custom:timeToIdleSeconds=0 custom:timeToLiveSeconds=0
* {code}
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @name The name of the cache to save
	* @type The type of cache. This is a shortcut for providing the "class" parameter. Values "ram", and "ehcache".
	* @type.options RAM,EHCache
	* @class Java class of implementing provider
	* @readOnly No idea what this does
	* @storage Is this cache used for session or client scope storage?
	* @custom A collection of custom values for this cache type in the format custom:timeToIdleSeconds=0
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string name,
		string type,
		string class,
		boolean storage,
		boolean readOnly,
		struct custom,
		string to,
		string toFormat
	) {		
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';
		
		if( !( type ?: '' ).len() && !( class ?: '' ).len() ) {
			error( 'Please provider either a "type" (ram,ehcache) or a "class" for this cache.' );
		}

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
		
		// Add cache to config and save.
		oConfig.addCache( argumentCollection = cacheParams )
			.write( toDetails.path );
				
		print.greenLine( 'Cache [#name#] saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

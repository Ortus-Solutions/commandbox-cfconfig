/**
* Add a new Custom Tag Path
* 
* {code}
* cfconfig customtagpath save /foo C:/foo/bar
* cfconfig customtagpath save virtual=/foo physical=C:/foo/bar to=serverName
* cfconfig customtagpath save virtual=/foo physical=C:/foo/bar to=/path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* Custom tags have no unique identifier.  In Adobe, there's a made up
	* "virtual" key of /WEB-INF/customtags(somenumber), but it's never shown
	* topside.  In Lucee, you *could* name a path, but you don't have to.
	*
	* So, internally, we search for combinations of physical and archive paths
	* to determine uniqueness, specifically:
	*   "physical:(physical path)_archive:(archivepath)"
	*
	* @physical The physical path that the engine should search
	* @archive Path to the Lucee/Railo archive
	* @name Name of the Custom Tag Path
	* @inspectTemplate String containing one of "never", "once", "always", "" (inherit)
	* @primary Strings containing one of "physical", "archive"
	* @trusted true/false
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		string physical="",
		string archive="",
		string name,
		string inspectTemplate,
		string primary,
		boolean trusted,
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

		if( !Len( physical ) && !Len( archive ) ) {
			error( "You must specify a physical or archive location. (or both)" );
		}
				
		// Read existing config
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version );
		try {
			oConfig.read( toDetails.path );	
		} catch( any e ) {
			// Handle this better by specifically checking if there's config 
		}
		
		// Add path to config and save.
		var CustomTagPathParams = duplicate( {}.append( arguments ) );
		CustomTagPathParams.delete( 'to' );
		CustomTagPathParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addCustomTagPath( argumentCollection = CustomTagPathParams )
			.write( toDetails.path );

		print.greenLine( 'Custom Tag Path saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

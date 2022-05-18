/**
* Add a new Component Path
* 
* {code}
* cfconfig componentpath save /foo C:/foo/bar
* cfconfig componentpath save virtual=/foo physical=C:/foo/bar to=serverName
* cfconfig componentpath save virtual=/foo physical=C:/foo/bar to=/path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @name The name of the path component path
	* @physical The physical path that the engine should search
	* @archive Path to the Lucee/Railo archive
	* @inspectTemplate String containing one of "never", "once", "always", "" (inherit)
	* @inspectTemplate.options never,once,always
	* @primary Strings containing one of "physical", "archive"
	* @primary.options physical,archive
	* @readonly true/false
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		string name,
		string physical="",
		string archive="",
		string inspectTemplate,
		string primary,
		boolean readonly=false,
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
		var componentpathParams = duplicate( {}.append( arguments ) );
		componentpathParams.delete( 'to' );
		componentpathParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addcomponentpath( argumentCollection = componentpathParams )
			.write( toDetails.path );

		print.greenLine( 'Component Path saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

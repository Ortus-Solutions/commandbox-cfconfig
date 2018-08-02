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
	* @physical The physical path that the Custom Tag Path points to
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string physical,
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
		
		// Add path to config and save.
		oConfig.addCustomTagPath( arguments.physical )
			.write( toDetails.path );
				
		print.greenLine( 'Custom Tag Path [#physical#] saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

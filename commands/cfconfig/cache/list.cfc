/**
* List all caches for a server.
* 
* {code}
* cfconfig cache list
* cfconfig cache list from=serverName
* cfconfig cache list from=/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig cache list --JSON
* {code}
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	* @JSON Set to try to receive caches back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		if( !fromDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}
		
		if( !directoryExists( fromDetails.path ) && !fileExists( fromDetails.path ) ) {
			error( "The CF Home directory for the server doesn't exist.  [#fromDetails.path#]" );				
		}
		
		// Read the config
		var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version )
			.read( fromDetails.path );

		// Get the caches, remembering it can be null
		var CFCaches = oConfig.getCaches() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( CFCaches ) );
		} else {
			if( CFCaches.len() ) {
				for( var cache in CFCaches ) {
					var cacheDetails = CFCaches[ cache ];
					// The only guaranteed piece of info is name
					print.boldLine( 'Name: #cache#' );
					
					if( !isNull( cacheDetails.type ) ) {
						print.indentedLine( 'Type: #cacheDetails.type#' );
					} else if( !isNull( cacheDetails.class ) ) {
						print.indentedLine( 'Class: #cacheDetails.class#' );
					}
					
					if( !isNull( cacheDetails.storage ) ) { print.indentedLine( 'Storage: #yesNoFormat( cacheDetails.storage )#' ); }
											
				print.line();
				}
			} else {
				print.line( 'No Caches defined.' );				
			}
		}
			
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
/**
* List all Custom Tag Paths for a server.
* 
* {code}
* cfconfig customtagpath list
* cfconfig customtagpath list from=serverName
* cfconfig customtagpath list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig customtagpath list --JSON
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
	* @JSON Set to try to receive custom tag paths back as a parsable JSON object
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

		// Get the CustomTagPaths, remembering it can be null
		var CustomTagPaths = oConfig.getCustomTagPaths() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( CustomTagPaths ) );
		} else {
			if( CustomTagPaths.len() ) {
				for( var i = 1; i <= CustomTagPaths.len(); i++) {
					var CustomTagPathDetails = CustomTagPaths[ i ];
					// The only guaranteed piece of info is virtual
					print.boldLine( 'CFConfig Index: #i#' );
					if( !isNull( CustomTagPathDetails.name ) ) { print.indentedLine( 'Name: #CustomTagPathDetails.name#' ); }
					if( !isNull( CustomTagPathDetails.physical ) ) { print.indentedLine( 'Physical Path: #CustomTagPathDetails.physical#' ); }
					if( !isNull( CustomTagPathDetails.archive ) ) { print.indentedLine( 'Archive Path: #CustomTagPathDetails.archive#' ); }
					if( !isNull( CustomTagPathDetails.inspectTemplate ) ) { print.indentedLine( 'Inspect Template: #CustomTagPathDetails.inspectTemplate#' ); }
					if( !isNull( CustomTagPathDetails.primary ) ) { print.indentedLine( 'Primary: #CustomTagPathDetails.primary#' ); }
					if( !isNull( CustomTagPathDetails.trusted ) ) { print.indentedLine( 'Read Only: #CustomTagPathDetails.trusted#' ); }						
				print.line();
				}
			} else {
				print.line( 'No Custom Tag Paths defined.' );				
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

/**
* List all Component  Paths for a server.
* 
* {code}
* cfconfig componentpath list
* cfconfig componentpath list from=serverName
* cfconfig componentpath list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig componentpath list --JSON
* {code}
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	property name="ConfigService" inject="ConfigService";
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	* @JSON Set to try to receive Component  paths back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat, 'from' );
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

		// Get the componentpaths, remembering it can be null
		var componentpaths = oConfig.getcomponentpaths() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
					
			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( componentpaths );
			} else {
				print.line( formatterUtil.formatJSON( componentpaths ) );	
			}
			
		} else {
			if( componentpaths.len() ) {
				for (var path in componentpaths){

					var componentpath = componentpaths[path];

					print.indentedLine( 'Name: #path#' );
					if( !isNull( componentpath.physical ) ) { print.indentedLine( 'Physical Path: #componentpath.physical#' ); }
					if( !isNull( componentpath.archive ) ) { print.indentedLine( 'Archive Path: #componentpath.archive#' ); }
					if( !isNull( componentpath.primary ) ) { print.indentedLine( 'Primary: #componentpath.primary#' ); }
					if( !isNull( componentpath.inspectTemplate ) ) { print.indentedLine( 'Inspect Template: #componentpath.inspectTemplate#' ); }
					if( !isNull( componentpath.readonly ) ) { print.indentedLine( 'Read Only: #componentpath.readOnly#' ); }
					print.line();
				}
				
			} else {
				print.line( 'No Component Paths defined.' );				
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

/**
* List all CF Mappings for a server
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @fromFormat The format to read from. Ex: LuceeServer@5
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
		
		var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version )
			.read( fromDetails.path );
			
		var CFMappings = oConfig.getCFMappings() ?: {};
	
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( CFMappings ) );
		} else {
			if( CFMappings.len() ) {
				for( var CFMapping in CFMappings ) {
					var CFMappingDetails = CFMappings[ CFMapping ];
					print.boldLine( 'Virtual Path: #CFMapping#' );
					if( !isNull( CFMappingDetails.physical ) ) { print.indentedLine( 'Physical Path: #CFMappingDetails.physical#' ); }
					if( !isNull( CFMappingDetails.archive ) ) { print.indentedLine( 'Archive Path: #CFMappingDetails.archive#' ); }
					if( !isNull( CFMappingDetails.inspectTemplate ) ) { print.indentedLine( 'Inspect Template: #CFMappingDetails.inspectTemplate#' ); }
					if( !isNull( CFMappingDetails.listenerMode ) ) { print.indentedLine( 'Listener Mode	: #CFMappingDetails.listenerMode#' ); }
					if( !isNull( CFMappingDetails.listenerType ) ) { print.indentedLine( 'Listener Type: #CFMappingDetails.listenerType#' ); }
					if( !isNull( CFMappingDetails.primary ) ) { print.indentedLine( 'Primary: #CFMappingDetails.primary#' ); }
					if( !isNull( CFMappingDetails.readOnly ) ) { print.indentedLine( 'Read Only: #CFMappingDetails.readOnly#' ); }						
				print.line();
				}
			} else {
				print.line( 'No CF Mappings defined.' );				
			}
		}
			
	}
	
}
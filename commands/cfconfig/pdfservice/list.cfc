/**
* List all PDF services for a server.
* 
* {code}
* cfconfig pdfservice list
* cfconfig pdfservice list from=serverName
* cfconfig pdfservice list from==/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig pdfservice list --JSON
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
	* @JSON Set to try to receive PDF services back as a parsable JSON object
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

		// Get the pdfservice, remembering it can be null
		var PDFServiceManagers = oConfig.getPDFServiceManagers() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
					
			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( PDFServiceManagers );
			} else {
				print.line( formatterUtil.formatJSON( PDFServiceManagers ) );	
			}
			
		} else {
			if( PDFServiceManagers.len() ) {
				for( var PDFServiceManager in PDFServiceManagers ) {
					var PDFServiceManagerDetails = PDFServiceManagers[ PDFServiceManager ];
					// The only guaranteed piece of info is name
					print.boldText( 'Name: #PDFServiceManager#' ).line( '  (#(PDFServiceManagerDetails.isEnabled ? 'enabled' : 'disabled')#)' );
					if( !isNull( PDFServiceManagerDetails.hostname ) ) { print.indentedLine( 'Host/port: #PDFServiceManagerDetails.hostname#:#PDFServiceManagerDetails.port?:0#' ); }
					if( !isNull( PDFServiceManagerDetails.weight ) ) { print.indentedLine( 'Weight: #PDFServiceManagerDetails.weight#' ); }
					if( !isNull( PDFServiceManagerDetails.isHTTPS ) ) { print.indentedLine( 'HTTPS: #PDFServiceManagerDetails.isHTTPS#' ); }
				print.line();
				}
			} else {
				print.line( 'No PDF Services defined.' );
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
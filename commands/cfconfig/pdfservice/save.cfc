/**
* Add a new PDF Service or update an existing PDF Service.  Existing PDF Services will be matched based on the name.
* 
* {code}
* cfconfig pdfservice save myService localhost 8991
* cfconfig pdfservice save name=myService hostname=localhost port=8991 to=serverName
* cfconfig pdfservice save name=myService hostname=localhost port=8991 to=/path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @name name of the PDF Service Manager to save or update
	* @hostname The host of the PDF service
	* @port The port of the PDF service
	* @isHTTPS True/false whether the remote service is using HTTPS
	* @weight A number to set the weight for this service
	* @isLocal True for local host
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string name,
		required string hostname,
		required string port,
		boolean isHTTPS=false,
		numeric weight=2,
		boolean isLocal
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
				
		// Read existing config
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version );
		try {
			oConfig.read( toDetails.path );	
		} catch( any e ) {
			// Handle this better by specifically checking if there's config 
		}
		
		// Preserve this as a struct, not an array
		var PDFServiceParams = duplicate( {}.append( arguments ) );
		PDFServiceParams.delete( 'to' );
		PDFServiceParams.delete( 'toFormat' );
		
		// Add service to config and save.
		oConfig.addPDFServiceManager( argumentCollection = PDFServiceParams )
			.write( toDetails.path );
				
		print.greenLine( 'PDF Service [#name#] saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

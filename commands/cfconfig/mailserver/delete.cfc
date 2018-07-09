/**
* Delete a mail server.  Identify the mail server uniquely by the host name.
* 
* {code}
* cfconfig mailserver delete /foo
* cfconfig mailserver delete /foo serverName
* cfconfig mailserver delete /foo /path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	/**
	* @smtp Host address of mail server
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string smtp,
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
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version )
			.read( toDetails.path );

		// Get the mail servers and remove the requested one
		var mailservers = oConfig.getMailservers() ?: [];
		var i=0;
		for( var thisServer in mailservers ) {
			i++;
			if( thisServer.smtp == smtp ) {
				mailservers.deleteAt( i );
				break;
			}
		}
		
		// Set remaining mappings back and save
		oConfig.setMailservers( mailservers )
			.write( toDetails.path );		
			
		print.greenLine( 'mail server [#smtp#] deleted.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
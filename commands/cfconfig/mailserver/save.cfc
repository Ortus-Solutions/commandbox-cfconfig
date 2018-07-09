/**
* Add a mew mail server or update an existing mail server.  Existing mail servers will be matched based on the host name.
* 
* {code}
* cfconfig mailserver save smtp.server.com
* cfconfig mailserver save smtp=smtp.server.com to=serverName
* cfconfig mailserver save smtp=smtp.server.com to=/path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @idleTimout Idle timeout in seconds
	* @lifeTimeout Overall timeout in seconds
	* @password Plain text password for mail server
	* @port Port for mail server
	* @smtp Host address of mail server
	* @ssl True/False to use SSL for connection
	* @tls True/False to use TLS for connection
	* @username Username for mail server
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		string smtp,
		numeric port,
		string username,
		string password,
		numeric idleTimeout,
		numeric lifeTimeout,
		boolean SSL,
		boolean TLS,
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
		
		// Preserve this as a struct, not an array
		var mailserverParams = duplicate( {}.append( arguments ) );
		mailserverParams.delete( 'to' );
		mailserverParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addMailserver( argumentCollection = mailserverParams )
			.write( toDetails.path );
				
		print.greenLine( 'mail server [#smtp#] saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( ( i ) => {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
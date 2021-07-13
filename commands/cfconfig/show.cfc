/**
* Show a configuration setting for a server
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	property name="ConfigService" inject="ConfigService";
	property name="JSONService" inject="JSONService";
	
	/**
	* @property name of the property to view.  Empty for everything.
	* @property.optionsUDF propertyComplete
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from.optionsFileComplete true
	* @from.optionsUDF serverNameComplete
	* @fromFormat The format to read from. Ex: LuceeServer@5
	*/	
	function run( 
		string property,
		string from,
		string fromFormat
	 ) {
		arguments.property = arguments.property ?: '';
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
		
		try {
			var oConfig = CFConfigService.determineProvider( fromDetails.format, fromDetails.version )
				.read( fromDetails.path );
		} catch( cfconfigNoProviderFound var e ) {
			error( e.message, e.detail ?: '' );
		}

		try {
			print.line( getInstance( 'JSONService' ).show( oConfig.getMemento(), arguments.property ) );	
		} catch( JSONException var e ) {
			error( e.message, e.detail );
		} catch( any var e ) {
			rethrow;
		}
			
	}

	function propertyComplete() {
		return getInstance( 'BaseConfig@cfconfig-services' ).getConfigProperties();
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}
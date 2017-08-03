/**
* Set a configuration setting into a server
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @_ name of the property to set.
	* @_.optionsUDF propertyComplete
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run( 
		string _,
		string to,
		string toFormat
	 ) {
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';
		
		// Remove dummy args
		structDelete( arguments, '_' );
		structDelete( arguments, 'to' );
		structDelete( arguments, 'toFormat' );
		
		var property = listFirst( structkeyList( arguments ) );
		
		try {
			var toDetails = Util.resolveServerDetails( to, toFormat );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		if( !toDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}
				
		try {
			var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version );
		} catch( cfconfigNoProviderFound var e ) {
			error( e.message, e.detail ?: '' );
		}

		try {
			oConfig.read( toDetails.path );	
		} catch( any e ) {
			// Handle this better by specifically checking if there's config 
		}
				
		var validProperties = oConfig.getConfigProperties();
		if( !validProperties.findNoCase( property ) ) {
			error( "[#property#] is not a valid property" );
		}
		oConfig[ 'set#property#' ]( arguments[ property ] )
			.write( toDetails.path );

		print.line( "[#property#] set." );
	
	}

	function propertyComplete() {
		return getInstance( 'BaseConfig@cfconfig-services' ).getConfigProperties();
	}
	
}
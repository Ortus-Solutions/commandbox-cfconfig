/**
* Set a configuration setting into a server
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	property name="JSONService" inject="JSONService";
	
	/**
	* @_ name of the property to set.
	* @_.optionsUDF propertyComplete
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	* @append.hint Append struct/array setting, instead of overwriting.
	*/	
	function run( 
		string _,
		string to,
		string toFormat,
		boolean append=false
	 ) {
		var thisAppend = arguments.append;
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';
		
		// Remove dummy args
		structDelete( arguments, '_' );
		structDelete( arguments, 'to' );
		structDelete( arguments, 'toFormat' );
		structDelete( arguments, 'append' );
				
		try {
			var toDetails = Util.resolveServerDetails( to, toFormat, 'to' );
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

		if( oConfig.CFHomePathExists( toDetails.path ) ) {
			oConfig.read( toDetails.path );	
		}
				
		print.line( arguments )
		var memento = oConfig.getMemento();
		JSONService.set( memento, arguments, thisAppend );
		
		oConfig
			.setMemento( memento )
			.write( toDetails.path );

		for( var property in arguments ) {
			print.line( "[#property#] set." );
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
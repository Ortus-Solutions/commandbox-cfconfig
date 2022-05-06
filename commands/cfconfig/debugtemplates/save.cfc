/**
* Add a new Debug Template or update an existing cache.  Existing caches will be matched based on the name.
* 
* You can use a the "type" parameter as a shortcut for the debug template
* 
* {code}
* cfconfig debugtemplates save myDebugTemplate lucee-modern
* cfconfig debugtemplates save name=myDebugTemplate type=lucee-modern
* {code}
* 
* 
* If your debug template expects custom properties, pass them as additional parameters to this
* command prefixed with the text "custom:". This requires named parameters, of course.
* 
* {code}
* cfconfig debugtemplates save name=myDebugTemplate type=lucee-modern custom:tab_Reference=Enabled custom:colorHighlight=Enable
* {code}
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @label Custom name of this template
	* @type Type of debugging template e.g: lucee-modern
	*  - lucee-classic
	*  - lucee-comment
	*  - lucee-modern
	*  - lucee-simple
	* @iprange A comma separated list of strings of ip definitions
	* @fullname CFC invocation path to the component that declares the fields for this template (defaulted for known types)
	* @path File system path to component that declares the fields for this template (defaulted for known types)
	* @id Id of Template
	* @custom A struct of settings that are meaningful to this debug template.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string label,
		required string type,
		string id,
		string fullname,
		string iprange,
		string path,
		struct custom			
		string to,
		string toFormat
	) {		
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';
		
		if( !( type ?: '' ).len() ) {
			error( 'Please define a type of debugging template either a "type" (lucee-classic, lucee-comment, lucee-modern, lucee-simple)' );
		}

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
		var templateParams = duplicate( {}.append( arguments ) );
		templateParams.delete( 'to' );
		templateParams.delete( 'toFormat' );
		
		// Add cache to config and save.
		oConfig.addDebuggingTemplate( argumentCollection = templateParams )
			.write( toDetails.path );
				
		print.greenLine( 'Debug template [#label#] saved.' );		
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

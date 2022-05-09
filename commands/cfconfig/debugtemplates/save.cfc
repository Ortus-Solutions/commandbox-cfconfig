/**
* Add a new Debug Template or update an existing one.  Existing debug templates will be matched based on the name.
* 
* You can use a the "type" parameter as a shortcut for the debug template
* 
* {code}
* cfconfig debugtemplates save myDebugTemplate Modern
* cfconfig debugtemplates save label=myDebugTemplate type=Modern
* {code}
* 
* 
* If your debug template expects custom properties, pass them as additional parameters to this
* command prefixed with the text "custom:". This requires named parameters, of course.
* 
* {code}
* cfconfig debugtemplates save label=myDebugTemplate type=Modern custom:tab_Reference=Enabled custom:colorHighlight=Enable
* {code}
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	
	/**
	* @label Custom name of this template
	* @type Type of debugging template e.g: Modern
	*  - Classic
	*  - Comment
	*  - Modern
	*  - Simple
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
		string iprange,
		string fullname,
		string path,
		string id,
		struct custom			
		string to,
		string toFormat
	) {		
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';
		
		if( !( type ?: '' ).len() ) {
			error( 'Please define a type of debugging template either a "type" (Classic, Comment, Modern, Simple)' );
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
		
		try {
			// Add debug template to config and save.
			oConfig.addDebuggingTemplate( argumentCollection = templateParams )
				.write( toDetails.path );
		} catch( cfconfigException e ) {
			error( e.message, e.datail ); 
		}
				
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

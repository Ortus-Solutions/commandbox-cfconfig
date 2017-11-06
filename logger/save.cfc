/**
* Add a new logger or update an existing logger.  Existing loggers will be matched based on the name.
* 
* {code}
* cfconfig logger save name=application appender=resource appenderArguments:path={lucee-config}/logs/application.log
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @name The name of the logger to save
	* @appender resource or console
	* @appenderClass A full class path to a Appender class
	* @appenderArguments A collection of arguments for this appender class in the format appenderArguments:key=value
	* @layout one of 'classic', 'html', 'xml', or 'pattern'
	* @layoutArguments A collection of arguments for this layout class in the format layoutArguments:key=value
	* @layoutClass A full class path to a Layout class
	* @level log level	
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string name,
		string appender,
		string appenderClass,
		struct appenderArguments,
		string layout,
		string layoutClass,
		struct layoutArguments,
		string level,
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
		var loggerParams = duplicate( {}.append( arguments ) );
		loggerParams.delete( 'to' );
		loggerParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		var test = oConfig.addLogger( argumentCollection = loggerParams );
		print.line(formatterUtil.formatJSON( test.getLoggers() ));
		print.line(toDetails.path);
		test.write( toDetails.path );
				
		print.greenLine( 'Logger [#name#] saved.' );	
	}
	
}
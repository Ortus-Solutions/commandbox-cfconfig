/**
* List all loggers for a server.
* 
* {code}
* cfconfig logger list
* cfconfig logger list from=serverName
* cfconfig logger list from=/path/to/server/home
* {code}
* 
* To receive the data back as JSON, use the --JSON flag.
* 
* {code}
* cfconfig logger list --JSON
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
	* @JSON Set to try to receive loggers back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat );
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

		// Get the loggers, remembering it can be null
		var loggers = oConfig.getLoggers() ?: {};
		
		// If outputting JSON
		if( arguments.JSON ?: false ) {
					
			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( loggers );
			} else {
				print.line( formatterUtil.formatJSON( loggers ) );	
			}
			
		} else {
			if( loggers.len() ) {
				var sortedLoggerNames = loggers.keyArray().sort( 'text' );
				for( var logger in sortedLoggerNames ) {
					var loggerDetails = loggers[ logger ];
					// The only guaranteed piece of info is name
					print.boldLine( 'Name: #logger#' );
					
					if( !isNull( loggerDetails.appender ) ) { print.indentedLine( 'Appender: #loggerDetails.appender#' ); }
					if( !isNull( loggerDetails.appenderClass ) ) { print.indentedLine( 'Appender Class: #loggerDetails.appenderClass#' ); }
					if( !isNull( loggerDetails.appenderArguments ) ) { 
						for ( var argName in loggerDetails.appenderArguments ) {
							print.indentedLine( 'Appender Argument: #argName#=#loggerDetails.appenderArguments[ argName ]#' ); 
						}
					}
					if( !isNull( loggerDetails.layout ) ) { print.indentedLine( 'Layout: #loggerDetails.layout#' ); }
					if( !isNull( loggerDetails.layoutClass ) ) { print.indentedLine( 'Layout Class: #loggerDetails.layoutClass#' ); }				
					if( !isNull( loggerDetails.layoutArguments ) ) { 
						for ( var argName in loggerDetails.layoutArguments ) {
							print.indentedLine( 'Layout Argument: #argName#=#loggerDetails.layoutArguments[ argName ]#' ); 
						}
					}
					if( !isNull( loggerDetails.level ) ) { print.indentedLine( 'Level: #loggerDetails.level#' ); }
											
					print.line();
				}
			} else {
				print.line( 'No loggers defined.' );				
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
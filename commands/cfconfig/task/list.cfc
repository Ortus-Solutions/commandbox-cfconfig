/**
* List all scheduled tasks for a server.
*
* {code}
* cfconfig task list
* cfconfig task list from=serverName
* cfconfig task list from==/path/to/server/home
* {code}
*
* To receive the data back as JSON, use the --JSON flag.
*
* {code}
* cfconfig task list --JSON
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
	* @JSON Set to try to receive mappings back as a parsable JSON object
	*/
	function run(
		string from,
		string fromFormat,
		boolean JSON
	) {
		arguments.from = arguments.from ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';

		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat, 'from', true );
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

		// Get the mappings, remembering it can be null
		var tasks = oConfig.getScheduledTasks() ?: {};

		// If outputting JSON
		if( arguments.JSON ?: false ) {

			// Detect if this installed version of CommandBox can handle automatic JSON formatting (and coloring)
			if( configService.getPossibleConfigSettings().findNoCase( 'JSON.ANSIColors.constant' ) ) {
				print.line( tasks );
			} else {
				print.line( formatterUtil.formatJSON( tasks ) );
			}

		} else {
			if( tasks.count() ) {
				for( var taskName in tasks ) {
					var task = tasks[ taskName ];

					print.boldLine( 'Task: #taskName#' );
					if( !isNull( task.URL ) ) { print.indentedLine( 'URL: #task.URL#' ); }
					if( !isNull( task.interval ) ) {
						print.indentedText( 'Interval: ' );
						if( isNumeric( task.interval ) ) {
							print.line( 'Every #formatExecTime( task.interval * 1000 )#' );
						} else {
							print.line( task.interval.UCFirst() );
						}
					}
					if( !isNull( task.status ) ) { print.indentedLine( 'Status: #task.status#' ); }
				print.line();
				}
			} else {
				print.line( 'No scheduled tasks defined.' );
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

	function formatExecTime( ms ) {

		var day = 0;
		var hr = 0;
		var min = 0;
		var sec = 0;

		while( ms >= 1000 ) {

		  ms = (ms - 1000);
		  sec = sec + 1;
		  if (sec >= 60) min = min + 1;
		  if (sec == 60) sec = 0;
		  if (min >= 60) hr = hr + 1;
		  if (min == 60) min = 0;
		  if (hr >= 24) {
		    hr = (hr - 24);
		    day = day + 1;
		  }

		}
		var outputTime = [];
		// Output days if > 0
		if( day ) outputTime.append( '#day#d' );
		if( hr  ) outputTime.append( '#hr#hr' );
		if( min  ) outputTime.append( '#min#min' );
		if( ( sec  ) ) outputTime.append( '#sec#sec' );

		return outputTime.toList( ' ' );
	}
}
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
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
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

		// Get the mappings, remembering it can be null
		var tasks = oConfig.getScheduledTasks() ?: {};
	
		// If outputting JSON
		if( arguments.JSON ?: false ) {
			print.line( formatterUtil.formatJSON( tasks ) );
		} else {
			if( tasks.count() ) {
				for( var taskName in tasks ) {
					var task = tasks[ taskName ];
					
					print.boldLine( 'Task: #task.group ?: 'default'#:#task.task#' );
					if( !isNull( task.URL ) ) { print.indentedLine( 'URL: #task.URL#' ); }
					if( !isNull( task.status ) ) { print.indentedLine( 'Status: #task.status#' ); }
				print.line();
				}
			} else {
				print.line( 'No scheduled tasks defined.' );
			}
		}
			
	}
	
}
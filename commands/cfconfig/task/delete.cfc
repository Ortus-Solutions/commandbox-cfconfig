/**
* Delete a scheduled task.  Identify the task uniquely by the task name and group.
*
* {code}
* cfconfig task delete myTask myGroup
* cfconfig task delete myTask myGroup serverName
* cfconfig task delete myTask myGroup /path/to/server/home
* {code}
*
*/
component {

	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	/**
	* @task name of the task
	* @group group of the task
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(
		required string task,
		string group,
		string to,
		string toFormat
	) {
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';

		try {
			var toDetails = Util.resolveServerDetails( to, toFormat, 'to', true );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}

		if( !toDetails.path.len() ) {
			error( "The location for the server couldn't be determined.  Please check your spelling." );
		}

		// Read existing config
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version )
			.read( toDetails.path );

		// Get the tasks and remove the requested one
		var tasks = oConfig.getScheduledTasks() ?: {};
		var taskID = arguments.task;
		if( toDetails.format contains 'adobe' ) {
			arguments.group = arguments.group ?: 'default';
		}
		if( !isNull( arguments.group ) && len( arguments.group ) ) {
			taskID = arguments.group & ':' & arguments.task;
		}
		tasks.delete( taskID );

		// Set remaining mappings back and save
		oConfig.setScheduledTasks( tasks )
			.write( toDetails.path );

		print.greenLine( 'Scheduled task [#taskID#] deleted.' );
	}

	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}

}
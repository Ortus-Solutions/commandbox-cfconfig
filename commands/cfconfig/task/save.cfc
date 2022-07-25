/**
* Add a new scheduled task or update an existing scheduled task.  Existing scheduled tasks will be matched based on the host name.
*
* {code}
* cfconfig task save myTask http://www.google.com Once 4/13/2018 "5:00 PM"
* cfconfig task save task=myTask url=http://www.google.com interval=Once startDate=4/13/2018 startTime="5:00 PM" to=serverName
* cfconfig task save task=myTask url=http://www.google.com interval=Once startDate=4/13/2018 startTime="5:00 PM" to=/path/to/server/home
* {code}
*
*/
component {

	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @task The name of the task
	* @url The full URL to hit
	* @group The group for the task (Adobe only)
	* @chained Is this task chained? (Adobe only)
	* @clustered Is this task clustered? (Adobe only)
	* @crontime Schedule in Cron format (Adobe only)
	* @endDate Date when task will end as 1/1/2000
	* @endTime Time when task will end as 9:57:00 AM
	* @eventhandler Specify a dot-delimited CFC path under webroot, for example a.b.server (without the CFC extension). The CFC should implement CFIDE.scheduler.ITaskEventHandler. (Adobe only)
	* @exclude Comma-separated list of dates or date range for exclusion in the schedule period. (Adobe only)
	* @file Save output of task to this file
	* @httpPort The port for the main task URL
	* @httpProxyPort The port for the proxy server
	* @interval The type of schedule. Once, Weekly, Daily, Monthly, an integer containing the number of seconds between runs
	* @misfire What to do in case of a misfire.  Ignore, FireNow, invokeHander (Adobe only)
	* @oncomplete Comma-separated list of chained tasks to be run after the completion of the current task (task1:group1,task2:group2...) (Adobe only)
	* @onexception Specify what to do if a task results in error. Ignore, Pause, ReFire, InvokeHandler (Adobe only)
	* @overwrite Overwrite the log file? (Adobe only)
	* @password Basic auth password to use when hitting URL
	* @priority An integer that indicates the priority of the task. (Adobe only)
	* @proxyPassword Proxy server password
	* @proxyServer Name of the proxy server to use
	* @proxyUser Proxy server username
	* @saveOutputToFile Save output to a file?
	* @repeat -1 to repeat forever, otherwise integer.
	* @requestTimeOut Number of seconds to timeout the request.  Empty string for none.
	* @resolveurl When saving output of task to file, Resolve internal URLs so that links remain intact.
	* @retrycount The number of reattempts if the task results in an error. (Adobe only)
	* @startDate The date to start executing the task
	* @startTime The date to end excuting the task
	* @status The current status of the task.  Running, Paused
	* @username Basic auth username to use when hitting URL
	* @autoDelete (Lucee only)
	* @hidden Do not show in admin UI (Lucee only)
	* @unique  If set run the task only once at time. Every time a task is started, it will check if still a task from previous round is running, if so no new test is started. (Lucee only)
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/
	function run(
		required string task,
		string url,
		string interval,
		string startDate,
		string startTime,
		string endDate,
		string endTime,
		string repeat,
		string group,
		string crontime,
		boolean chained,
		boolean clustered,
		string eventhandler,
		string exclude,
		string file,
		string httpPort,
		string httpProxyPort,
		string misfire,
		string oncomplete,
		string onexception,
		string overwrite,
		string password,
		string priority,
		string proxyPassword,
		string proxyServer,
		string proxyUser,
		boolean saveOutputToFile,
		string requestTimeOut,
		boolean resolveurl,
		string retryCount,
		string status,
		string username,
		string autoDelete,
		string hidden,
		string unique
	) {
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';

		try {
			var toDetails = Util.resolveServerDetails( to, toFormat, 'to', true );
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}

		if( toDetails.format contains 'adobe' ) {
			arguments.group = arguments.group ?: 'default';
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
		var taskParams = duplicate( {}.append( arguments ) );
		taskParams.delete( 'to' );
		taskParams.delete( 'toFormat' );

		// Add mapping to config and save.
		oConfig.addScheduledTask( argumentCollection = taskParams )
			.write( toDetails.path );

		print.greenLine( 'scheduled task [#task#] saved.' );
	}

	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}

}

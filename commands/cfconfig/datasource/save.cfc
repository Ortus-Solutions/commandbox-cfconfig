/**
* Add a new datasource or update an existing datasource.  Existing datasources will be matched based on the name.
*
* Valid dbdriver options are
*  - MSSQL -- SQL Server driver
*  - MSSQL2 -- jTDS driver
*  - PostgreSql
*  - Oracle
*  - Other -- Custom JDBC URL
*  - MySQL
*  - H2
*
* {code}
* cfconfig datasource save myDS
* cfconfig datasource save name=myDS to=serverName
* cfconfig datasource save name=myDS to=/path/to/server/home
* {code}
*
*/
component {

	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";

	/**
	* @name Name of datasource
	* @allowSelect Allow select operations
	* @allowDelete Allow delete operations
	* @allowUpdate Allow update operations
	* @allowInsert Allow insert operations
	* @allowCreate Allow create operations
	* @allowGrant Allow grant operations
	* @allowRevoke Allow revoke operations
	* @allowDrop Allow drop operations
	* @allowAlter Allow alter operations
	* @allowStoredProcs Allow Stored proc calls
	* @blob Enable blob
	* @blobBuffer Number of bytes to retreive in binary fields
	* @class Java class of driver
	* @clob Enable clob
	* @clobBuffer Number of chars to retreive in long text fields
	* @maintainConnections Maintain connections accross client requests
	* @sendStringParametersAsUnicode Enable High ASCII characters and Unicode for data sources configured for non-Latin characters
	* @connectionLimit Max number of connections. -1 means unlimimted
	* @connectionTimeout Connectiontimeout in minutes
	* @connectionTimeoutInterval Number of seconds connections are checked to see if they've timed out
	* @liveTimeout Connection timeout in minutes
	* @maxPooledStatements Max pooled statements if maintain connections is on.
	* @queryTimeout Max time in seconds a query is allowed to run.  Set to 0 to disable
	* @disableConnections Suspend all client connections
	* @loginTimeout Number of seconds for login timeout
	* @custom Extra JDBC URL query string without leading &
	* @database name of database
	* @dbdriver Type of database driver
	*  - MSSQL -- SQL Server driver
	*  - MSSQL2 -- jTDS driver
	*  - PostgreSql
	*  - Oracle
	*  - Other -- Custom JDBC URL
	*  - MySQL
	*  - H2
	* @dbdriver.options MSSQL,MSSQL2,PostgreSql,Oracle,Other,MySQL,H2
	* @dsn JDBC URL (jdbc:mysql://{host}:{port}/{database})
	* @host name of host
	* @metaCacheTimeout Not sure-- Lucee had this in the XML
	* @password Unencrypted password
	* @port Port to connect on
	* @storage True/False use this datasource as client/session storage (Lucee)
	* @username Username to connect with
	* @validate Enable validating this datasource connection every time it's used
	* @validationQuery Query to run when validating datasource connection
	* @logActivity Enable logging queries to a text file
	* @logActivityFile A file path ending with .txt to log to
	* @disableAutogeneratedKeyRetrieval Disable retrieval of autogenerated keys
	* @SID Used for Oracle datasources
	* @serviceName Used for Oracle datasources
	* @linkedServers Enable Oracle linked servers support
	* @clientHostname Client Information - Client hostname
	* @clientUsername Client Information - Client username
	* @clientApplicationName Client Information - Application name
	* @clientApplicationNamePrefix Client Information - Application name prefix
	* @description Description of this datasource.  Informational only.
	* @requestExclusive Exclusive connections for request
	* @alwaysSetTimeout Always set timeout on queries
	* @bundleName OSGI bundle name to load the class from
	* @bundleVersion OSGI bundle version to load the class from
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	* @timezone Default timezone to set on the datasource.
	*/
	function run(
		required string name,
		required string dbdriver,
		boolean blob,
		numeric blobBuffer,
		string class,
		boolean clob,
		numeric clobBuffer,
		boolean maintainConnections,
		boolean sendStringParametersAsUnicode,
		numeric connectionLimit,
		numeric connectionTimeout,
		numeric connectionTimeoutInterval,
		numeric liveTimeout,
		numeric maxPooledStatements,
		numeric queryTimeout,
		numeric loginTimeout,
		boolean disableConnections,
		string custom,
		string database,
		string dsn,
		string host,
		numeric metaCacheTimeout,
		string password, // Unencrypted
		string port,
		boolean storage,
		string username,
		boolean validate,
		string validationQuery,
		boolean logActivity,
		string logActivityFile,
		boolean disableAutogeneratedKeyRetrieval,
		string SID,
		string serviceName,
		boolean linkedServers,
		boolean clientHostname,
		boolean clientUsername,
		boolean clientApplicationName,
		string clientApplicationNamePrefix,
		string description,
		boolean allowSelect,
		boolean allowDelete,
		boolean allowUpdate,
		boolean allowInsert,
		boolean allowCreate,
		boolean allowGrant,
		boolean allowRevoke,
		boolean allowDrop,
		boolean allowAlter,
		boolean allowStoredProcs,
		boolean requestExclusive,
		boolean alwaysSetTimeout,
		string bundleName,
		string bundleVersion,
		string to,
		string toFormat,
		string timezone
	) {
		var to = arguments.to ?: '';
		var toFormat = arguments.toFormat ?: '';

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
		var datasourceParams = duplicate( {}.append( arguments ) );
		datasourceParams.delete( 'to' );
		datasourceParams.delete( 'toFormat' );

		// Add mapping to config and save.
		oConfig.addDatasource( argumentCollection = datasourceParams )
			.write( toDetails.path );

		print.greenLine( 'Datasource [#name#] saved.' );
	}

	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}

}

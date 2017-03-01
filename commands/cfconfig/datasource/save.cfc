/**
* Add a mew datasource or update an existing datasource.  Existing datasources will be matched based on the name.
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
	
	/**
	* @name Name of datasource
	* @allow Bitmask of allowed operations
	* @blob Enable blob?
	* @class Java class of driver
	* @clob Enable clob?
	* @connectionLimit Max number of connections. -1 means unlimimted
	* @connectionTimeout Connectiontimeout in minutes
	* @custom Extra JDBC URL query string without leading &
	* @database name of database
	* @dbdriver Type of database driver
	*  - MSSQL -- SQL Server driver
	*  - MSSQL2 -- jTDS driver
	*  - PostgreSql
	*  - Oracle
	*  - Other -- Custom JDBC URL
	*  - MySQL
	* @dsn JDBC URL (jdbc:mysql://{host}:{port}/{database})
	* @host name of host
	* @metaCacheTimeout Not sure-- Lucee had this in the XML
	* @password Unencrypted password
	* @port Port to connect on
	* @storage True/False use this datasource as client/session storage (Lucee)
	* @username Username to connect with
	* @validate Validate this datasource connectin every time it's used?
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		required string name,
		required string dbdriver,
		string host,
		string port,
		string database,
		string username,
		string password, // Unencrypted
		string class,
		string dsn,
		string allow,
		boolean blob,
		boolean clob,
		numeric connectionLimit,
		numeric connectionTimeout,
		string custom,
		numeric metaCacheTimeout,
		boolean storage,
		boolean validate,
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
		var datasourceParams = duplicate( {}.append( arguments ) );
		datasourceParams.delete( 'to' );
		datasourceParams.delete( 'toFormat' );
		
		// Add mapping to config and save.
		oConfig.addDatasource( argumentCollection = datasourceParams )
			.write( toDetails.path );
				
		print.greenLine( 'Datasource [#name#] saved.' );		
	}
	
}
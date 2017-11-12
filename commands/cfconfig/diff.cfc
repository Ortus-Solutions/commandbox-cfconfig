/**
* Diff all configuration between to locations. A location can be a CommandBox server (by name), a directory
* that points to a server home, or a CF Config JSON file.
* 
* {code:bash}
* cfconfig diff server1 server2
* cfconfig diff file1.json file2.json
* cfconfig diff servername file.json
* cfconfig diff from=path/to/servers1/home to=path/to/server2/home 
* {code}
*
* Both the "to" or the "from" parameters will default to the CommandBox server in the current working directory
* but you need to at least specicy one of them to be different.  To easily compare the CommandBox server in your CWD
* you can just specify one alternative location to compare with
* 
* {code:bash}
* cfconfig diff to=path/to/.CFConfig.json 
* {code}
* 
* CFConfig will guess the to and from format based on the files in the directory.  The toFormat and fromFormat
* are only needed in case CFConfig can't guess the server formats, or is guessing incorrectly.
*
* By default, this command will show properties that are populated in at least one location.  (The equivilent
* of (toOnly, fromOnly, and bothPopulated).  You may override this to control which values you see.  If you specify more than one
* filter, they are additive, or a logical "OR".
*
* {code}
* cfconfig diff to=serverName --all
* cfconfig diff to=serverName --valuesDiffer --toOnly --fromOnly
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @fromFormat The format to read from when "from" is a directory. Ex: LuceeServer@5
	* @toFormat The format to read from when "to" is a directory. Ex: LuceeServer@5
	* @fromOnly Display properties only present in the "from" location
	* @toOnly Display properties only present in the "to" location
	* @bothPopulated Display properties that have a value populated for both locations
	* @bothEmpty Display properties that are empty for both locations
	* @valuesMatch Display properties that have matching values
	* @valuesDiffer Display properties that have differing values
	* @all Display all properties
	* @verbose Show details for datasources and CF Mappings
	*/	
	function run(
		string from,
		string to,
		string fromFormat,
		string toFomat,
		boolean fromOnly = false,
		boolean toOnly = false,
		boolean bothPopulated = false,
		boolean bothEmpty = false,
		boolean valuesMatch = false,
		boolean valuesDiffer = false,
		boolean all = false,
		boolean verbose = false
	) {
		arguments.from = arguments.from ?: '';
		arguments.to = arguments.to ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		arguments.toFormat = arguments.toFormat ?: '';
		
		// Defaults if the user doesn't specify at least one filter
		if( !(fromOnly || toOnly || bothPopulated || bothEmpty || valuesMatch || valuesDiffer || all ) ) {
			fromOnly = true;
			toOnly = true;
			bothPopulated = true;
		}
		
		if( !from.len() && !to.len() ) {
			error( "Please specify either a 'from' or a 'to' location.  I'm not sure what to compare." );
		}
				
		try {
			var fromDetails = Util.resolveServerDetails( from, fromFormat );
			var toDetails = Util.resolveServerDetails( to, toFormat );
			
			if( !fromDetails.path.len() ) {
				error( "The location for the 'from' server couldn't be determined.  Please check your spelling." );
			}
			
			if( !directoryExists( fromDetails.path ) && !fileExists( fromDetails.path ) ) {
				error( "The CF Home directory for the 'from' server doesn't exist.  [#fromDetails.path#]" );				
			}
			
			if( !toDetails.path.len() ) {
				error( "The location for the 'to' server couldn't be determined.  Please check your spelling." );
			}
			
			var qryDiff = CFConfigService.diff(
				from		= fromDetails.path,
				to			= toDetails.path,
				fromFormat	= fromDetails.format,
				toFormat	= toDetails.format,
				fromVersion	= fromDetails.version,
				toVersion	= toDetails.version
			);
			
			qryDiff = queryExecute( 
				'SELECT * FROM qryDiff ORDER BY propertyName',
				{},
				{ dbtype='query' }
			 );
			
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		} catch( cfconfigNoProviderFound var e ) {
			error( e.message, e.detail ?: '' );
		}
		
		var longestProp = 2 + qryDiff.reduce( function( prev=0, row ) { 
			return ( row.propertyName.len() > prev ? row.propertyName.len() : prev );
		} );
		var longestToValue = 2 + qryDiff.reduce( function( prev=0, row ) { 
			return ( len( row.toValue ) > prev ? len( row.toValue ) : prev );
		} );
		var longestFromValue = 2 + qryDiff.reduce( function( prev=0, row ) { 
			return ( len( row.fromValue ) > prev ? len( row.fromValue ) : prev );
		} );
		
		// Terminal width (minus 2 for good measure)
		var termWidth = shell.getTermWidth()-2;
		// column with (minus 6 for center column and minus longest property name)
		var columnWidth = ( termWidth -6-longestProp )/2;
		
		toColumnWidth = min( columnWidth, longestToValue );
		fromColumnWidth = min( columnWidth, longestFromValue );
		
		print
			.line()
			.boldUnderscoredLine( 
				printColumnValue( 'Property Name', longestProp ) 
				& printColumnValue( '"From" Server ', fromColumnWidth )
				& '      '
				& printColumnValue( '"To" Server', toColumnWidth ) );
	
		var previousPrefix = '~';
		// propertyName,fromValue,toValue,fromOnly,toOnly,bothPopulated,bothEmpty,valuesMatch,valuesDiffer
		for( var row in qryDiff ) {
			if( row.propertyName.startsWith( previousPrefix )
				&& ( 
					row.propertyName.startsWith( 'CFMappings-' ) 
					|| row.propertyName.startsWith( 'datasources-' ) 
					|| row.propertyName.startsWith( 'mailServers-' ) 
					|| row.propertyName.startsWith( 'caches-' )
					|| row.propertyName.startsWith( 'clientStorageLocations-' )
					|| row.propertyName.startsWith( 'loggers-' )
					) 
				) {
				var nested = true;
				// If not verbose output, skip nested values
				if( !verbose ) {
					continue;
				}
			} else {
				var nested = false;
				previousPrefix = row.propertyName & '-';
			}
			
			if( 
				( fromOnly && row.fromOnly )
				|| ( toOnly && row.toOnly )
				|| ( bothPopulated && row.bothPopulated )
				|| ( bothEmpty && row.bothEmpty )
				|| ( valuesMatch && row.valuesMatch )
				|| ( valuesDiffer && row.valuesDiffer )
				|| all
				) {
				
				if( row.valuesMatch ) {
					var equality = '  ==  ';
					var lineColor = 'green';
				} else if ( row.valuesDiffer ) {
					var lineColor = 'red';
					var equality = '  <>  ';
				} else if ( row.fromOnly ) {
					var lineColor = 'yellow';
					var equality = '  <-  ';
				} else if ( row.toOnly ) {
					var lineColor = 'yellow';
					var equality = '  ->  ';
				} else {
					var lineColor = '';
					var equality = '      ';
				}
				
				print.line( 
					printColumnValue( ( nested ? '  ' : '' ) & row.propertyName & ': ', longestProp )
					& printColumnValue( ( row.toOnly || row.bothEmpty ? '-' : row.FromValue ), fromColumnWidth )
					& equality
					& printColumnValue( ( row.fromOnly || row.bothEmpty ? '-' : row.toValue ), toColumnWidth ),
					lineColor
					
				);
																
			}
		}
		
	}

	/**
	* Pads value with spaces or truncates as neccessary
	*/
	private function printColumnValue( required string text, required number columnWidth ) {
		if( len( text ) > columnWidth ) {
			return left( text, columnWidth-3 ) & '...';
		} else {
			return text & repeatString( ' ', columnWidth-len( text ) );			
		}
	}
	
}
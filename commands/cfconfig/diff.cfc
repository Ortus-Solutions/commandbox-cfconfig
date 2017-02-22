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
* CFConfig will guess the to and from format based on the files in the directory.  The toFormat and fromFormat
* are only needed in case CFConfig can't guess the server formats, or is guessing incorrectly.
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
	*/	
	function run(
		string from,
		string to,
		string fromFormat,
		string toFormat
	) {
		arguments.from = arguments.from ?: '';
		arguments.to = arguments.to ?: '';
		arguments.fromFormat = arguments.fromFormat ?: '';
		arguments.toFormat = arguments.toFormat ?: '';
		
		if( !from.len() && !to.len() ) {
			error( "Please specify either a 'from' or a 'to' location.  I'm not sure what to copy where." );
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
			
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		} catch( cfconfigNoProviderFound var e ) {
			error( e.message, e.detail ?: '' );
		}
			
		// systemOutput( qryDiff, true );
	
	
		print.line( 'From Server     /      To Server' );
	
		// propertyName,fromValue,toValue,fromOnly,toOnly,bothPopulated,bothEmpty,valuesMatch,valuesDiffer
		for( var row in qryDiff ) {
			if( row.bothPopulated || row.fromOnly || row.toOnly ) {
				print.text( ( row.toOnly ? 'N/A' : row.FromValue ) );
				
				if( row.valuesMatch ) {
					print.text( '  ==   ' );
				} else if ( row.valuesDiffer ) {
					print.text( '  <>   ' );
				} else if ( row.fromOnly ) {
					print.text( '  <==   ' );
				} else if ( row.toOnly ) {
					print.text( '  ==>   ' );
				}
								
				print.line( ( row.fromOnly ? 'N/A' : row.toValue ) );				
			}
		}
		
	}
	
}
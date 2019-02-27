/**
* Delete a Custom Tag Path
* 
* {code}
* cfconfig customtagpath delete /foo
* cfconfig customtagpath delete /foo serverName
* cfconfig customtagpath delete /foo /path/to/server/home
* {code}
*
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	property name="serverService" inject="ServerService";
	/**
	* This will delete ALL mappings that match the supplied parameters
	*
	* @index The CFConfig Index of the mapping
	* @physical The physical path that the engine should search
	* @archive Path to the Lucee/Railo archive
	* @name Name of the Custom Tag Path
	* @inspectTemplate String containing one of "never", "once", "always", "" (inherit)
	* @primary Strings containing one of "physical", "archive"
	* @trusted true/false
	*
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to.optionsFileComplete true
	* @to.optionsUDF serverNameComplete
	* @toFormat The format to write to. Ex: LuceeServer@5
	*/	
	function run(
		numeric index,
		string physical,
		string archive,
		string name,
		string inspectTemplate,
		string primary,
		boolean trusted,
		boolean dryRun = true,
		string to,
		string toFormat
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

		var atLeastOne = false;
		atLeastOne = atLeastOne || !isNull( index );
		atLeastOne = atLeastOne || !isNull( physical );
		atLeastOne = atLeastOne || !isNull( archive );
		atLeastOne = atLeastOne || !isNull( name );
		atLeastOne = atLeastOne || !isNull( inspectTemplate );
		atLeastOne = atLeastOne || !isNull( primary );
		atLeastOne = atLeastOne || !isNull( trusted );
		if( !atLeastOne ) {
			error( "Must specify at least one filter" );
		}

		// Read existing config
		var oConfig = CFConfigService.determineProvider( toDetails.format, toDetails.version )
			.read( toDetails.path );

		// Get the Custom Tag Paths and remove the requested one
		var CustomTagPaths = oConfig.getCustomTagPaths() ?: [];
		var i = 0;
		var deleted = 0;
		while( ++i <= CustomTagPaths.len() ) {
			if( !isNull( index ) && ! ( i EQ index ) ) { continue; };
			if( !isNull( physical ) && ! ( Compare( physical, CustomTagPaths[ i ].physical?:"" ) EQ 0 ) ) { continue; };
			if( !isNull( archive ) && ! ( Compare( archive, CustomTagPaths[ i ].archive?:"" ) EQ 0 ) ) { continue; };
			if( !isNull( name ) && ! ( Compare( name, CustomTagPaths[ i ].name?:"" ) EQ 0 ) ) { continue; };
			if( !isNull( inspectTemplate ) && ! ( Compare( inspectTemplate, CustomTagPaths[ i ].inspectTemplate?:"" ) EQ 0 ) ) { continue; };
			if( !isNull( primary ) && ! ( Compare( primary, CustomTagPaths[ i ].primary?:"" ) EQ 0 ) ) { continue; };
			if( !isNull( trusted ) && ! ( ( trusted&&( CustomTagPaths[ i ].trusted?:false ) ) || ( !trusted&&!( CustomTagPaths[ i ].trusted?:false ) ) ) ) { continue; };

			// We match!
			deleted++;
			if( dryRun ) {
				print.boldLine( 'Would delete CFConfig Index: #i#' );
				if( !isNull( CustomTagPaths[ i ].name ) ) { print.indentedLine( 'Name: #CustomTagPaths[ i ].name#' ); }
				if( !isNull( CustomTagPaths[ i ].physical ) ) { print.indentedLine( 'Physical Path: #CustomTagPaths[ i ].physical#' ); }
				if( !isNull( CustomTagPaths[ i ].archive ) ) { print.indentedLine( 'Archive Path: #CustomTagPaths[ i ].archive#' ); }
				if( !isNull( CustomTagPaths[ i ].inspectTemplate ) ) { print.indentedLine( 'Inspect Template: #CustomTagPaths[ i ].inspectTemplate#' ); }
				if( !isNull( CustomTagPaths[ i ].primary ) ) { print.indentedLine( 'Primary: #CustomTagPaths[ i ].primary#' ); }
				if( !isNull( CustomTagPaths[ i ].trusted ) ) { print.indentedLine( 'Read Only: #CustomTagPaths[ i ].trusted#' ); }
			} else {
				CustomTagPaths.delete( i );
				i--;
			}
			// Index match can only work once, otherwise, we'd keep deleting everything AFTER that point.
			if( !isNull( index ) ) { break; }
		}
		
		// Set remaining mappings back and save
		/*
		oConfig.setCustomTagPaths( CustomTagPaths )
			.write( toDetails.path );		
			*/
			
		print.greenLine( '#deleted# Custom Tag' & ( deleted eq 1 ? "" : "s" ) & ' ' & ( dryRun ? "would be ":"" ) & 'deleted.' );
	}
	
	function serverNameComplete() {
		return serverService
			.getServerNames()
			.map( function( i ) {
				return { name : i, group : 'Server Names' };
			} );
	}
	
}

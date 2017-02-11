component singleton {
	
	property name='serverService' inject='serverService';
	property name='shell' inject='shell';
	property name='fileSystemUtil' inject='fileSystem';
	
	
	function resolveServerDetails( string from, string format ) {
		var results = {
			format : '',
			version : '',
			path : ''
		};
		
		// If there's a name, check for a server with that name
		if( from.len() ) {
			var serverDetails = serverService.resolveServerDetails( { name : arguments.from } );
		// If there's no from, check for a server in this working directory
		} else {
			var serverDetails = serverService.resolveServerDetails( { directory : shell.pwd() } );
		}
		var serverInfo = serverDetails.serverInfo;
		
		// If we found a server with this name
		if( !serverDetails.serverIsNew ) {
			results.format = listFirst( format, '@' );
			results.version = serverInfo.engineVersion;
			if( !results.version.len() && format.listLen( '@' ) > 1 ) {
				results.version = listLast( format, '@' );
			}
			
			if( serverInfo.engineName == 'adobe' ) {
				results.path = serverInfo.serverHomeDirectory & '/WEB-INF/cfusion/lib';
			} else if ( results.format == 'luceeServer' ) {
				results.path = serverInfo.serverConfigDir & '/lucee-server/';				
			} else if ( results.format == 'luceeWeb' ) {
				results.path = serverInfo.webConfigDir;
			} else {
				throw( 
					message="I couldn't find the CF Home for CommandBox server [#serverInfo.name#]. #( !format.len() ? 'Please give me a hint with the format parameter' : '' )#",
					detail="#( serverInfo.engineName == 'lucee' ? 'This is a Lucee server, so you need to tell me if you want the web or server context. (luceeWeb/luceeServer format)' : '' )#",
					type="cfconfigException"
				);
			}
						
			if( !results.path.len() ) {
				throw( message="The server home for the CommandBox server [#from#] wasn't found. Try starting the server to make sure it hasn't been deleted from disk.", type="cfconfigException" );	
			}
			
			// Lucee can have a relative web or server context path.  It's relative to the server home directory
			if( results.path.listFirst( '/\' ) == 'WEB-INF' ) {
				results.path = serverInfo.serverHomeDirectory & results.path;	
			}
			
		// not a CommandBox server, so assume to be a directory
		} else {
			
			from = fileSystemUtil.resolvePath( from );
			
			// If the path is a JSON file, we know this.
			if( from.listLast( '.' ) == 'JSON' ) {
				results.format = 'JSON';
				results.version = 0;	
			} else {
				results.format = listFirst( format, '@' );
				results.version = ( format.listLen( '@' ) > 1 ? listLast( format, '@' ) : 0 );
			}
			results.path = arguments.from;
			
		}
		
		return results;	
	}
	
}
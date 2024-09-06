/**
*********************************************************************************
* Copyright Since 2017 CommandBox by Ortus Solutions, Corp
* www.ortussolutions.com
********************************************************************************
* @author Brad Wood
*/
component singleton {

	property name='serverService' inject='serverService';
	property name='shell' inject='shell';
	property name='fileSystemUtil' inject='fileSystem';
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';


	/**
	* @from The to or from value specified to the command
	* @format The given format of the to or from value
	* @fromToName The desinator "to" or "from" to know what we're looking up for better error messages
	*/
	function resolveServerDetails( string from, string format, string fromToName='', boolean preferWeb=false ) {
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
			var serverDetails = serverService.resolveServerDetails( {} );
		}
		var serverInfo = serverDetails.serverInfo;
		var engineName = serverInfo.enginename ?: '';
		if( !len( engineName ) ) {
			engineName = serverInfo.CFEngine ?: '';
		}

		// Backwards compat for people on old CommandBox
		serverInfo.multiContext = serverInfo.multiContext ?: false;

		// If we found a server with this name
		if( !serverDetails.serverIsNew ) {
			results.format = listFirst( format, '@' );
			results.version = serverInfo.engineVersion;
			if( !results.version.len() && format.listLen( '@' ) > 1 ) {
				results.version = listLast( format, '@' );
			}

			// If this is a Lucee server, assume the server context.  It's just way too much of a pain to specify this every single time!
			if(  engineName contains 'lucee' && !results.format.len() ) {
				results.format = ( preferWeb ? 'luceeWeb' : 'luceeServer' );
			}

			// If this is a Railo server, assume the server context.  It's just way too much of a pain to specify this every single time!
			if(  engineName contains 'railo' && !results.format.len() ) {
				results.format = 'railoServer';
			}

			if( engineName contains 'boxlang' ) {
				results.path = serverInfo.serverHomeDirectory & '/WEB-INF/boxlang/config';
				results.format = 'boxlang';
			} else if( engineName contains 'adobe' ) {
				results.path = serverInfo.serverHomeDirectory & '/WEB-INF/cfusion';
				results.format = 'adobe';
			} else if ( results.format == 'luceeServer' ) {
				results.path = serverInfo.serverConfigDir & '/lucee-server';
			} else if ( results.format == 'railoServer' ) {
				results.path = serverInfo.serverConfigDir & '/railo-server';
			// Web root can be provided as luceeWeb-/path/to/webroot
			} else if ( (var webrootSearch = reFindNoCase( '^(lucee|railo)Web(-(.*))?', results.format, 1, true ) ).pos[1] ) {
				// Strip web root from format
				results.format = listFirst( results.format, '-' );

				// Crappy workaround for CommandBox bug where this logic is being done on the fly, but not saved back into the serverInfo struct!
				if( serverInfo.multiContext && not serverInfo.webConfigDir contains '{web-root-directory}' && not serverInfo.webConfigDir contains '{web-context-hash}'  ) {
					serverInfo.webConfigDir &= '-{web-context-hash}'
				}

				// Web context has Lucee placeholders
				if( serverInfo.webConfigDir.find( '{' ) ) {
					// If no web root was provided, use the default web root
					var webroot = serverInfo.webroot;
					// Otherwise, extract it from the format
					if( webrootSearch.pos.len() == 4 && webrootSearch.pos[4] ) {
						webroot = webrootSearch.match[4];
					}

					// This will create the same canonicalized path that Lucee uses to hash, which includes
					// OS-specific slashes and no trailing slash.
					webroot = createObject( 'java', 'java.io.File' ).init( webroot ).toString();

					// Replace common placeholders we know how to handle
					results.path = serverInfo.webConfigDir
						.replaceNoCase( '{web-root-directory}', webroot, 'all' )
						.replaceNoCase( '{web-context-hash}', lCase( hash( webroot ) ), 'all' );

					// If there are still placeholders, we fail
					if( results.path.find( '{' ) ) {
						throw(
							message="CFConfig couldn't find the CF web context for CommandBox server [#serverInfo.name#], it contains a placeholder we don't know how to resolve.",
							detail="The web context directory is [#serverInfo.webConfigDir#]",
							type="cfconfigException"
						);
					}

				// Web context is just plain absolute path
				} else {
					results.path = serverInfo.webConfigDir;
				}


			}

			// Lucee can have a relative web or server context path.  It's relative to the server home directory
			if( results.path.listFirst( '/\' ) == 'WEB-INF' ) {
				results.path = serverInfo.serverHomeDirectory & results.path;
			}

			if( !results.path.len() ) {
				throw(
					message="CFConfig couldn't find the CF Home for [#fromToName#] CommandBox server [#serverInfo.name#]. #( !format.len() ? 'Please give me a hint with the format parameter' : '' )#",
					detail="#( engineName contains 'lucee' ? 'This is a Lucee server, so you need to tell me if you want the web or server context. (luceeWeb/luceeServer format)' : '' )#",
					type="cfconfigException"
				);
			}
			// A custom engine won't have an engineVersion in serverInfo
			if( !results.version.len() ) {
				var guessedFormat = CFConfigService.guessFormat( results.path );
				if( results.version != '0' ) {
					results.version = guessedFormat.version;
				}
			}

		// not a CommandBox server, so assume to be a directory
		} else if( from.len() ){

			from = fileSystemUtil.resolvePath( from );
			// Try to infer the format and version based on the files in place
			var guessedFormat = CFConfigService.guessFormat( from );
			// Use these as defaults
			results.format = guessedFormat.format;
			results.version = guessedFormat.version;

			// Overrid with user-provided format
			if( format.len() ) {
				results.format = listFirst( format, '@' );
			}

			// Overrid with user-provided version
			if( format.listLen( '@' ) > 1 ) {
				results.version = listLast( format, '@' );
			}

			results.path = arguments.from;

			if( !results.format.len() ) {
				throw( message="You gave the location of the [#fromToName#] server, but we couldn't figure out the format to use.", detail="Please help us by adding [#fromToName#Format=...] to your command.", type="cfconfigException" );
			}

		} else {
			// Is the current working directory of the server identify as a server home?
			var guessedFormat = CFConfigService.guessFormat( shell.pwd() );

			if( guessedFormat.format.len() ) {
				return results = {
					format : guessedFormat.format,
					version : guessedFormat.version,
					path : shell.pwd()
				};
			}

			throw( message="We couldn't find your [#fromToName#] server.  You didn't give us a path and this directory isn't a CommandBox server.", detail="Please help us by adding [#fromToName#=...] to your command.", type="cfconfigException" );
		}

		return results;
	}

}
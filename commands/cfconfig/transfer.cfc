/**
* Transfer configuration from one location/server to another.  If you don't specify a from or to, we look for a CommandBox server using the current working
* directory.  Only rely on this if you have a single CommandBox server running in the current directory.  You must specify at least a from or a to.
* 
* {code:bash}
* cfconfig transfer from=servername to=anotherServername
* cfconfig transfer from=serverName
* cfconfig transfer to=serverName
* {code}
* 
* When specifying the direct path to the server home, here are the rules based on the engine you're using:
* For Lucee's web context, point to the folder containing the lucee-web.xml.cfm file.
* Ex: <webroot>/WEB-INF/lucee
* 
* For Lucee's server context, point to be the "lucee-server" folder containing the /context/lucee-server.xml file.
* Ex: /opt/lucee/lib/lucee-server
*
* For Adobe servers, point to the "cfusion" folder containing the lib/neo-runtime.xml file.
* Ex: C:/ColdFusion11/cfusion
* 
* {code:bash}
* cfconfig transfer from=/path/to/server/home to=/path/to/another/server/home
* cfconfig transfer from=/path/to/server/home
* cfconfig transfer to=/path/to/server/home
* {code}
*
* When transfering configuration to or from a generic CFConfig JSON file, use the full path to the JSON file:
* 
* {code:bash}
* cfconfig transfer from=/path/to/.CFConfig.json
* cfconfig transfer to=/path/to/.CFConfig.json
* {code}
*   
* For CommandBox servers, we'll get the engine/version out of CommandBox's metadata.  For non-CommandBox servers, you'll need to help me out by
* specifying what kind of file format to use.
* 
* For the fromFormat and toFormat, use the name of the engine followed by @ and then the engine version like engine@version.  
* For lucee, specify the web or sever context.  Valid engines are "luceeWeb", "luceeServer", and "adobe".  
* For partial versions, the missing pieces will be interpreted as zeros.  Meaning adobe@11 is the same as adobe@11.0.0.
* Examples are:
* - adobe@11.0.11
* - luceeWeb@5
* - luceeServer@4.5
* 
* {code:bash}
* cfconfig transfer from=/path/to/.CFConfig.json to=/path/to/server/home toFormat=luceeServer@5.1
* {code}
* 
* The version number can be left off toFormat and fromFormat when reading or writing to a CFConfig JSON file or a CommandBox server since we already know the version.
* If you don't specify a Lucee web or Server context, we default to server. Use a format of "luceeWeb" to switch.
* 
*/
component {
	
	property name='CFConfigService' inject='CFConfigService@cfconfig-services';
	property name='Util' inject='util@commandbox-cfconfig';
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @fromFormat The format to read from when "from" is a directory. Ex: LuceeServer@5
	* @toFormat The format to write to when "to" is a directory. Ex: LuceeServer@5
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
			
			CFConfigService.transfer(
				from		= fromDetails.path,
				to			= toDetails.path,
				fromFormat	= fromDetails.format,
				toFormat	= toDetails.format,
				fromVersion	= fromDetails.version,
				toVersion	= toDetails.version
			);
			
		} catch( cfconfigException var e ) {
			error( e.message, e.detail ?: '' );
		}
		
		print.greenLine( 'Config transfered!' );
	}
	
}
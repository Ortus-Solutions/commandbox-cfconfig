/**
* Export configuration from a server.  If you don't specify a to, we look for a CommandBox server using the current working
* directory.  Only rely on this if you have a single CommandBox server running in the current directory.  
* 
* {code:bash}
* cfconfig export myConfig.json
* cfconfig export serverNameToExportTo
* cfconfig export to=/path/to/server/home/to/export/to
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
* cfconfig export to=/path/to/.CFConfig.json from=/path/to/server/home fromFormat=luceeServer@5.1
* {code}
* 
* The version number can be left off toFormat and fromFormat when reading or writing to a CFConfig JSON file or a CommandBox server since we already know the version.
* If you don't specify a Lucee web or Server context, we default to server. Use a format of "luceeWeb" to switch.
* 
*/
component {
	
	/**
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @toFormat The format to write to when "to" is a directory. Ex: LuceeServer@5
	* @fromFormat The format to read from when "from" is a directory. Ex: LuceeServer@5
	*/	
	function run(
		string to,
		string from,
		string toFormat,
		string fromFormat
		) {
		command( 'cfconfig transfer' )
			.params( argumentCollection = arguments )
			.run();
	}
	
}
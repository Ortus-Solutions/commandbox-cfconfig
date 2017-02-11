/**
* Import configuration 
*/
component {
	
	/**
	* @from CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @to CommandBox server name, server home path, or CFConfig JSON file. Defaults to CommandBox server in CWD.
	* @fromFormat The format to read from when "from" is a directory. Ex: LuceeServer@5
	* @toFormat The format to write to when "to" is a directory. Ex: LuceeServer@5
	*/	
	function run(
		string from,
		string fromFormat,
		string to,
		string toFormat,
		) {
		command( 'cfconfig transfer' )
			.params( argumentCollection = arguments )
			.run();
	}
	
}
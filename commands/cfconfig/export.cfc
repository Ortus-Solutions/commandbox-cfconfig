/**
* Export configuration 
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
		string toFormat,
		string from,
		string fromFormat
		) {
		command( 'cfconfig transfer' )
			.params( argumentCollection = arguments )
			.run();
	}
	
}
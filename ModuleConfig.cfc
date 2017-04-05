/**
*********************************************************************************
* Copyright Since 2017 CommandBox by Ortus Solutions, Corp
* www.ortussolutions.com
********************************************************************************
* @author Brad Wood
*/
component {
	
	this.title 				= "CFConfig CI";
	this.modelNamespace		= "commandbox-cfconfig";
	this.cfmapping			= "commandbox-cfconfig";
	this.autoMapModels		= true;
	// Need these loaded up first so I can do my job.
	this.dependencies 		= [ 'cfconfig-services' ];

	function configure() {
		settings = {
			
		};
	}
}
/**
*********************************************************************************
* Copyright Since 2017 CommandBox by Ortus Solutions, Corp
* www.ortussolutions.com
********************************************************************************
* @author Brad Wood
*/
component singleton {
	property name='fileSystemUtil' inject='fileSystem';

	function generateReport( required query qryDiff, required string reportPath, struct fromDetails, struct toDetails, options ) {
		// If we were given a directory
		if( !( reportPath.right( 5 ) == '.html' || reportPath.right( 4 ) == '.htm' ) ){
			// Make up a file name
			reportPath &= '/index.html';
		}
		
		pagePoolClear();
		
		var html = generateHTML( argumentCollection=arguments );
		
		directoryCreate( getDirectoryFromPath( reportPath ), true, true );
		fileWrite( reportPath, local.html );
		return reportPath;
	}
	
	function generateHTML() {
		savecontent variable='local.html' {
			include '/commandbox-cfconfig/views/HTMLReport.cfm';
		}
		return local.html;
	}
	
}
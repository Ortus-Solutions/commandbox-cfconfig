/**
*********************************************************************************
* Copyright Since 2017 CommandBox by Ortus Solutions, Corp
* www.ortussolutions.com
********************************************************************************
* @author Brad Wood
*/
component singleton {
	property name='fileSystemUtil' inject='fileSystem';
	property name='HTMLReport' inject='HTMLReport@commandbox-cfconfig';

	function generateReport( required query qryDiff, required string reportPath, struct fromDetails, struct toDetails, options ) {
		// If we were given a directory
		if( !reportPath.right( 4 ) == '.pdf' ){
			// Make up a file name
			reportPath &= '/cfconfig-diff-report-#dateTimeFormat( now(), 'yyyy-mm-dd-HHMMSS' )#.pdf';
		}
		
		var html = HTMLReport.generateHTML( argumentCollection=arguments );
		
		
		directoryCreate( getDirectoryFromPath( reportPath ), true, true );
		cfdocument( filename=reportPath, overwrite=true ) {
			echo( html );
		}
		return reportPath;
	}
	
}
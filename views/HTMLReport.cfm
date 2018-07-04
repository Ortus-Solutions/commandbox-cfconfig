<cfoutput>
	<h1>Server Config Diff Report</h1>
	Created on #datetimeFormat( now() )#<br>
	<h2>"From" Server: #fromDetails.format# #fromDetails.version# </h2>
	#fromDetails.path#
	<h2>"To" Server: #toDetails.format# #toDetails.version# </h2>
	#toDetails.path#
	<h2>Filters applied</h2>
	<ul>
		<cfif options.fromOnly><li>From Only</li></cfif>
		<cfif options.toOnly><li>To Only</li></cfif>
		<cfif options.bothPopulated><li>Both Populated</li></cfif>
		<cfif options.bothEmpty><li>Both Empty</li></cfif>
		<cfif options.valuesMatch><li>Values Match</li></cfif>
		<cfif options.valuesDiffer><li>Values Differ</li></cfif>
		<cfif options.all><li>All</li></cfif>
		<cfif options.verbose><li>Verbose</li></cfif>
	</ul>
	<br>
	<br>
	<table border="1" cellspacing="0" cellpadding="3">
		<tr>
			<td><b>Property name</b></td>
			<td><b>From Value</b></td>
			<td>&nbsp;</td>
			<td><b>To Value</b></td>
		</tr>
		<cfloop query="qryDiff">
			<cfscript>
				if( valuesMatch ) {
					var equality = '  ==  ';
					var lineColor = 'green';
				} else if ( valuesDiffer ) {
					var lineColor = 'red';
					var equality = '  &lt;&gt;  ';
				} else if ( fromOnly ) {
					var lineColor = 'yellow';
					var equality = '  &lt;-  ';
				} else if ( toOnly ) {
					var lineColor = 'yellow';
					var equality = '  -&gt;  ';
				} else {
					var lineColor = '';
					var equality = '      ';
				}
			</cfscript>
			
			<tr bgcolor="#lineColor#">
				<td>#propertyName#</td>
				<td>#left( fromValue, 50 )#&nbsp;</td>
				<td>#equality#&nbsp;</td>
				<td>#left( toValue, 50 )#&nbsp;</td>
			</tr>
		</cfloop>
	</table>
	<!---<cfdump var="#qryDiff#">--->
</cfoutput>
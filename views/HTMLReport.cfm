<cfoutput>
	<style>
	.container {
		/*text-align: center;*/
		font-family: Arial, Helvetica, sans-serif;
		padding: 10px;
	}

	h1 {
		font-family: Arial Black, Gadget, sans-serif;
	}

	h2 {
		margin-bottom: 5px;
	}
	/*
	table {
		border-collapse: collapse;
		margin: auto; 
	}
	*/
	tr {
		background-color: ##d3d3d3;
	}

	th {
		padding-top: 18px;
    	padding-bottom: 18px;
		font-family: Arial Black, Gadget, sans-serif;
		font-size: 18px;
		color: ##fff;
		line-height: 1.4;
		background-color: ##212121;
		text-align: left;
	}

	td {
		padding-top: 16px;
    	padding-bottom: 16px;
		font-size: 15px;
		color: ##212121;
		line-height: 1.4;
	}

	tr:first-child th:first-child { border-top-left-radius: 10px; }
	tr:first-child th:last-child { border-top-right-radius: 10px; }
	tr:last-child td:first-child { border-bottom-left-radius: 10px; }
	tr:last-child td:last-child { border-bottom-right-radius: 10px; }

	.column-first {
		padding-left: 40px;
		padding-right: 10px;
	}
	.column2 {
		padding: 0 10px;
	}
	.column3 {
		text-align: center;
		font-size: 30px;
		padding: 0 25px;
	}
	.column-last {
		padding-left: 10px;
		padding-right: 40px;
	}
	.indent {
		padding-left: 80px;
	}
	/*
	.filters {
		width: 120px;
		text-align: left;
		margin: auto; 
	}
	*/
	</style>
<div class="container">
	<h1>Server Config Diff Report</h1>
	<p>Created on #datetimeFormat( now() )#<p>
	<table>
		<thead>
			<tr>
				<th class="column-first">#(isNull(options.fromDisplayName)?'"From" ':'')#Server</th>
				<th class="column2">Format</th>
				<th class="column-last">Version</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td class="column-first">#options.fromDisplayName ?: fromDetails.path#</td>
				<td class="column2">#fromDetails.format#</td>
				<td class="column-last">#fromDetails.version#</td>
			</tr>
		</tbody>
	</table>
	<br>
	<table>
		<thead>
			<tr>
				<th class="column-first">#(isNull(options.toDisplayName)?'"To" ':'')# Server</th>
				<th class="column2">Format</th>
				<th class="column-last">Version</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td class="column-first">#options.toDisplayName ?: toDetails.path#</td>
				<td class="column2">#toDetails.format#</td>
				<td class="column-last">#toDetails.version# </td>
			</tr>
		</tbody>
	</table>
	
	<h2>Filters applied</h2>
	<ul class="filters">
		<cfif options.fromOnly><li>#options.fromDisplayName ?: 'From'# Only</li></cfif>
		<cfif options.toOnly><li>#options.toDisplayName ?: 'To'# Only</li></cfif>
		<cfif options.bothPopulated><li>Both Populated</li></cfif>
		<cfif options.bothEmpty><li>Both Empty</li></cfif>
		<cfif options.valuesMatch><li>Values Match</li></cfif>
		<cfif options.valuesDiffer><li>Values Differ</li></cfif>
		<cfif options.all><li>All</li></cfif>
		<cfif options.verbose><li>Verbose</li></cfif>
	</ul>
	<br>
	<br>

	<table>
		<thead>
			<tr>
				<th class="column-first">Property name</th>
				<th class="column2">#options.fromDisplayName ?: 'From'# Value</th>
				<th class="column3">&nbsp;</th>
				<th class="column-last">#options.toDisplayName ?: 'To'# Value</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="qryDiff">
				<cfscript>
					if( valuesMatch ) {
						var lineColor = '##87d870'; // green
						var equality = '=';			// EQ
					} else if ( valuesDiffer ) {
						var lineColor = '##fcb5a1'; // red
						var equality = '&##8800';   // NEQ
					} else if ( fromOnly ) {
						var lineColor = '##f9ed8b'; // yellow
						var equality = '&##8592';   // left arrow
					} else if ( toOnly ) {
						var lineColor = '##f9ed8b'; // yellow
						var equality = '&##8594';   // right arrow
					} else {
						var lineColor = '';
						var equality = '';
					}
				</cfscript>
				
				<tr style="background-color: #lineColor#;">
					<td class="column-first <cfif propertyName.reFindNoCase( '.*-.*-.*' )>indent</cfif>">
						#propertyName#
					</td>
					<td class="column2">#left( fromValue, 50 )#</td>
					<td class="column3">#equality#</td>
					<td class="column-last">#left( toValue, 50 )#&nbsp;</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</div>
	<!---<cfdump var="#qryDiff#">--->
</cfoutput>
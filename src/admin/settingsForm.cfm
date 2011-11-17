<cfoutput>

<form method="post" action="#cgi.script_name#">
<fieldset>
<legend>Comfigure RiaApps</legend>
	<p>
	<!--- <input type="text" id="riaAppsTitle" name="feedMeTitle" >
	Title: #variables.riaAppsTitle#
	</input> --->
	 <br />
	 <br />
	<!---  <input type="text" id="feedMefeed" name="feedMefeed" >
	 Current feed: #variables.feedMefeed#
	 </input>
	    <br />
	    <br />
	    <input type="text" id="feedMeNumber" name="feedMeNumber">
	    Number: #variables.feedMeNumber#
	    </input> --->
	</p>
</fieldset>

<div class="actions">
	<input type="submit" class="primaryAction" value="Submit"/>
	<input type="hidden" value="event" name="action" />
	<input type="hidden" value="showRiaAppsSettings" name="event" />
	<input type="hidden" value="true" name="apply" />
	<input type="hidden" value="riaApps" name="selected" />
</div>
  
</form>

</cfoutput>

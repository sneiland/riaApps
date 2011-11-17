<cfcomponent output="false" extends="org.mangoblog.plugins.BasePlugin">
	
	
	<cffunction name="init" access="public" output="false" returntype="any"
			hint="initializes the riaApps plugin"	
				>
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
        
        	<cfset setManager(arguments.mainManager) />
			<cfset setPreferencesManager(arguments.preferences) />
			<cfset setPackage("com/cftips/riaApps") />
		
			<cfset path = getManager().getBlog().getBasePath() />
			<cfset variables.mode = getPreferencesManager().get(path,"mode","") />
			<cfset variables.riaAppsTitle = getPreferencesManager().get(path,"riaAppsTitle","") />
			<cfset variables.title = getPreferencesManager().get(path,"podTitle","") />
			
			<!--- <cfset variables.riaApps = createObject("component","riaApps").init()> --->
			
		<cfreturn this/>
	</cffunction>
	
	
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfset path = getManager().getBlog().getBasePath() />
		<cfset getPreferencesManager().put(path,"mode","") />
		
		<cfreturn "The riaApps plugin activated. Would you like to <a href='generic_settings.cfm?event=showRiaAppsSettings&amp;owner=riaApps&amp;selected=showRiaAppsSettings'>configure it now</a>?" />
	</cffunction>
	
	
	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn />
	</cffunction>
	

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />

		<cfset var feedMefeed = "" />
		<cfset var feedMeTitle = "RiaApps Feed" />
		<cfset var feedMeNumber = 3 />
		<cfset var outputData = "" />
		<cfset var link = "" />
		<cfset var page = "" />
		<cfset var data = ""/>
		<cfset var path = "" />
		<cfset var admin = "" />
		<cfset var eventName = arguments.event.name />
		
		<cfswitch expression="#eventName#">
			<cfcase value = "getPods">
				<cfset outputData =  arguments.event.getOutputData() />
				<cfset feedurl = #variables.feedMefeed#>
				<cffeed action="read" source="#feedurl#" properties="meta" query="entries">	
				<cfsavecontent variable="content">
				<cfoutput>
				<cfif variables.feedMefeed neq "">
					<cfloop query="entries" startrow="1" endrow="#variables.feedMeNumber#">
					<p>
					<b><a href="#rsslink#">#title#</a></b>
					</p>
					</cfloop>
				</cfif>
				</cfoutput></cfsavecontent>
				<cfset arguments.event.setOutputData(outputData & variables.content) />
				
				<cfset pod = structnew() />
				<cfset pod.title = variables.feedMeTitle />
				<cfset pod.content = variables.content />
				<cfset pod.id = "feedMe" />
				<cfset arguments.event.addPod(pod)>
			</cfcase>
			
			<!--- Add a link to the Ria Apps Settings form to the Admin navigation --->
			<cfcase value = "settingsNav">
				<cfset link = structnew() />
				<cfset link.owner = "riaApps">
				<cfset link.page = "settings" />
				<cfset link.title = "RiaApps" />
				<cfset link.eventName = "showRiaAppsSettings" />
				
				<cfset arguments.event.addLink(link)>
			</cfcase>
			
			<!--- Show the RiaApps Settings form in the admin system --->
			<cfcase value = "showRiaAppsSettings">
				<cfset data = arguments.event.getData() />		
				
				<!--- If form.apply hidden field exists (is form has been submitted) then update the settings --->		
				<cfif structkeyexists(data.externaldata,"apply")>
					<cfset variables.feedMefeed = data.externaldata.feedMefeed />
                    <cfset variables.feedMeNumber = data.externaldata.feedMeNumber />
                    <cfset variables.feedMeTitle = data.externaldata.feedMeTitle />
					
					<cfset path = getManager().getBlog().getBasePath() />
					<cfset getPreferencesManager().put(path,"feedMefeed",variables.feedMefeed) />
                    <cfset getPreferencesManager().put(path,"feedMeNumber",variables.feedMeNumber) />
                    <cfset getPreferencesManager().put(path,"feedMeTitle",variables.feedMeTitle) />
					<cfset data.message.setstatus("success") />
					<cfset data.message.setType("settings") />
					<cfset data.message.settext("feedMe updated successfully")/>
				</cfif>
			
				<cfsavecontent variable="page">
					<cfinclude template="admin/settingsForm.cfm">
				</cfsavecontent>
				
				<!--- change message --->
				<cfset data.message.setTitle("RiaApps Settings") />
				<cfset data.message.setData(page) />
			</cfcase>
			
			<!--- no content, just title and id --->
			<cfcase value = "getPodsList">
				<cfset pod = structnew() />
				<cfset pod.title = "feedMe" />
				<cfset pod.id = "feedMe" />
				<cfset arguments.event.addPod(pod)>
			</cfcase>
		</cfswitch>
		
		<cfreturn arguments.event />
	</cffunction>
	
	
</cfcomponent>
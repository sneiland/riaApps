<!--- 	
	Project:
		riaApps.cfc
		
	Author: Steven Neiland
			@sneiland
			steven.neiland@gmail.com
			http://www.neiland.net
	
	Version: 1.0.1
	
	Description:
		This cfc creates a cached array of projects from the riaforge website which can then be displayed on your site/blog
	
	Usage:
		See the readme.txt file for installation usage instructions
		
	Update:
		22-sept-2011 : Fixed arrayAppend error in update
		22-sept-2011 : Fixed bug where recent mode ignored displayNum property
		
 --->

<cfcomponent displayName="riaApps" output="false">

	<cfset variables.apiUrl = "http://www.riaforge.org/boltapi/api.cfc">
	<cfset variables.feedUrl = "http://www.riaforge.org/index.cfm?event=page.categoryrss&cid=">
	
	<cfset variables.returnFormat = "json">
	<cfset variables.projectArray = arrayNew(1)><!--- Used to house a list of projects from the api call --->
	<cfset variables.recentArray = arrayNew(1)><!--- Used to house a list of recently updated projects from the rss feed --->
	
	<cfset variables.startIndex = 1><!--- The index number from which to start getting the next set of projects --->
	<cfset variables.lastUpdate = ""><!--- When was the last update successfully completed --->
	<cfset variables.reloadTime = 60><!--- Number of minutes to wait before allowing next reload (ignored if calling "update" function directly) --->
	
	<cfset variables.mode = "default"><!--- Determines mode of operation for the update --->
	<cfset variables.categoryId = 1><!--- The ColdFusion Category --->
	<cfset variables.displayNum = 10><!--- Number of projects to get and display --->
	<cfset variables.maxProjectId = 0><!--- The maximum project Id available from the api --->
	
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="randomStart" type="boolean" required="false" default="false" hint="Start from a random page in the list of projects">
		<cfargument name="mode" type="string" required="false" default="default" hint="Sets the update mode: default,recent,both">
		<cfargument name="categoryId" type="numeric" required="false" default="1" hint="Sets the category of projects - defaulted to 1: ColdFusion">
		<cfargument name="displayNum" type="numeric" required="false" default="10" hint="Sets the number of projects to display">
		
		<cfset setMode(arguments.mode)>
		<cfset setCategoryId(arguments.categoryId)>
		<cfset setDisplayNum(arguments.displayNum)>
		
		<!--- Make one initial call to the api to set the max project ID we can retrieve --->
		<cfset setMaxProjectId(determineMaxProjectId())>
		
		<cfif arguments.randomStart>
			<cfset setStartIndex(RandRange(1,getMaxProjectId())) />
		</cfif>
		
		<!--- On initial load try get a set of projects --->
		<cfset update() />
		
		<cfreturn this />
	</cffunction>
	
	
	<!--- GETTERS / SETTERS --->
	<cffunction name="setStartIndex" access="public" output="false" returnType="void">
		<cfargument name="startIndex" required="true" type="numeric">
		<cfset variables.startIndex = arguments.startIndex />
	</cffunction>
	<cffunction name="getStartIndex" access="public" output="false" returnType="numeric">
		<cfreturn variables.startIndex/>
	</cffunction>
	
	
	<cffunction name="setMode" access="public" output="false" returnType="void">
		<cfargument name="mode" required="true" type="string">
		<cfset variables.mode = arguments.mode />
	</cffunction>
	<cffunction name="getMode" access="public" output="false" returnType="string">
		<cfreturn variables.mode/>
	</cffunction>
	
	
	<cffunction name="setProjectArray" access="public" output="false" returnType="void">
		<cfargument name="projectArray" required="true" type="array">
		<cfset variables.projectArray = arguments.projectArray>
	</cffunction>
	<cffunction name="getProjectArray" access="public" output="false" returnType="array">
		<cfreturn variables.projectArray />
	</cffunction>
	
	
	<cffunction name="setRecentArray" access="public" output="false" returnType="void">
		<cfargument name="recentArray" required="true" type="array">
		<cfset variables.recentArray = arguments.recentArray/>
	</cffunction>
	<cffunction name="getRecentArray" access="public" output="false" returnType="array">
		<cfreturn variables.recentArray />
	</cffunction>
	
	
	<cffunction name="setCategoryId" access="public" output="false" returnType="void">
		<cfargument name="categoryId" required="true" type="numeric">
		<cfset variables.categoryId = arguments.categoryId/>
	</cffunction>
	<cffunction name="getCategoryId" access="public" output="false" returnType="numeric">
		<cfreturn variables.categoryId />
	</cffunction>
	
	
	<cffunction name="setDisplayNum" access="public" output="false" returnType="void">
		<cfargument name="displayNum" required="true" type="numeric">
		<cfset variables.displayNum = arguments.displayNum/>
	</cffunction>
	<cffunction name="getDisplayNum" access="public" output="false" returnType="numeric">
		<cfreturn variables.displayNum />
	</cffunction>
		
	<cffunction name="setMaxProjectId" access="public" output="false" returnType="void">
		<cfargument name="maxProjectId" required="true" type="numeric">
		<cfset variables.maxProjectId = arguments.maxProjectId/>
	</cffunction>
	<cffunction name="getMaxProjectId" access="public" output="false" returnType="numeric">
		<cfreturn variables.maxProjectId />
	</cffunction>
	
	<!--- Public Functions --->
	
	
	<cffunction name="timedUpdate" access="public" output="false" returnType="void" 
			hint="If the number of minutes between reloads has passed then update the project list">
				
		<!--- If timeout has been passed create a lock on the update code --->
		<cfif dateCompare(now(),dateAdd("n",variables.reloadTime,variables.lastUpdate),"n") GTE 0>
			<cflock type="exclusive" name="lockTimedUpdate" timeout="10" throwontimeout="true">
				<!--- If the timeout has still been exceeded when this code is reached ie not been updated by a previous lock then update --->
				<cfif dateCompare(now(),dateAdd("n",variables.reloadTime,variables.lastUpdate),"n") GTE 0>
					<cfset update() />
				</cfif>
			</cflock>
		</cfif>
	</cffunction>
		
		
	<cffunction name="update" access="public" output="false" returnType="void" 
			hint="Loads the next set of projects from the appropriate source(s)">
				
		<cflock type="exclusive" name="lockUpdate" timeout="10" throwontimeout="true">
			<cfswitch expression="#variables.mode#">
				<cfcase value="recent">
					<!--- Recent: just pull projects from the recent rss feed --->
					<cfset updateRecent()>
				</cfcase>
				
				<cfcase value="both">
					<!--- both: Pull from both sources --->
					<cfset updateRecent()>
					<cfset updateProjects()>
				</cfcase>
							
				<cfdefaultcase>
					<!--- Default: just pull projects from the main api --->
					<cfset updateProjects()>
				</cfdefaultcase>
			</cfswitch>
		</cflock>
	</cffunction>
	
	
	<cffunction name="getAppsList" access="public" output="false" returnType="string" >
		<cfset var appArray = arrayNew(1)>
		<cfset var content = "">
				
		<cflock type="readOnly" name="lockGetAppsList" timeout="10" throwontimeout="true">
			<cfset appArray = getProjectArray()>
			<cfset content = buildHTMLList(appArray)>
		</cflock>	
		
		<cfreturn content/>
	</cffunction>
	
	
	<cffunction name="getRecentAppsList" access="public" output="false" returnType="string" >
		<cfset var appArray = arrayNew(1)>
		<cfset var content = "">
		
		<cflock type="readOnly" name="lockRecentAppsList" timeout="10" throwontimeout="true">
			<cfset appArray = getRecentArray()>
			<cfset content = buildHTMLList(appArray)>
		</cflock>
		
		<cfreturn content/>
	</cffunction>
	
	
	<!--- Curtesy functions --->
	
	
	<cffunction name="getCategories" access="public" output="false" returnType="array"
			hint="Returns all the categories available in RiaForge - This is included as a curtesy but is not actually used">
				
		<cfset var categories = "" />
		<cfset var returnArray = arrayNew(1) />
		
		<cfhttp url="#variables.apiUrl#?method=getCategories&returnFormat=#variables.returnFormat#" charset="utf-8" method="GET" result="categories">
		
		<cfif refind("200",categories.statusCode)>
			<cfif IsJSON(categories.fileContent)>
				<cfset returnArray = jsonToStructArray(categories.fileContent) />
			</cfif>
		</cfif>
		
		<cfreturn returnArray />
	</cffunction>
	
	
	<cffunction name="getProjectDetailsFromApi" access="public" output="false" returnType="array"
			hint="Returns the details of a particular project based on the project id - This is included as a curtesy but is not actually used">
					
		<cfargument name="projectId" required="true" type="numeric">
		
		<cfset var project = "">
		<cfset var returnArray = arrayNew(1)>
		
		<cfhttp 
			url="#variables.apiUrl#?method=getProject&id=#arguments.projectId#&returnFormat=#variables.returnFormat#" 
			charset="utf-8" 
			method="GET" 
			result="project" />
			
		<cfif refind("200",project.statusCode)>
			<cfif IsJSON(project.fileContent)>
				<cfset returnArray = jsonToStructArray(project.fileContent)>
			</cfif>
		</cfif>
		
		<cfreturn returnArray />
	</cffunction>
	
	
	<!--- Private functions --->
	
	
	<cffunction name="updateProjects" access="private" output="false" returnType="boolean" 
			hint="Updates the default projects array from the riaForge api">
		
		<cfset var updateSuccess = FALSE>
		<cfset var maxId = getMaxProjectId()>
		<cfset var newProjects = arrayNew(1)>
		<cfset var additionalProjects = arrayNew(1)>
		<cfset var nextPageAmt = 0>
		<cfset var i = 0>
		<cfset var start = variables.startIndex>
		<cfset var nextAmt = variables.displayNum>
		
		<cfif variables.startIndex GT maxId>
			<cfset start = 1>
			<cfset newProjects = getProjectsFromApi(categoryId=getCategoryId(),start=start,page=nextAmt) />
			
		<cfelseif (variables.startIndex + variables.displayNum) GT maxId>
			<cfset newProjects = getProjectsFromApi(categoryId=getCategoryId(),start=start,page=nextAmt) />
			
			<cfset nextAmt = variables.displayNum - (maxId - start) >
			<cfset start = 1>
			
			<cfset additionalProjects = getProjectsFromApi(categoryId=getCategoryId(),start=start,page=nextAmt) />
						
			<cfif arrayLen(additionalProjects)>
				<cfloop from="1" to="#arrayLen(additionalProjects)#" index="i">
					<cfset arrayappend(newProjects,additionalProjects[i])>
				</cfloop>
			</cfif>
						
		<cfelse>
			<cfset newProjects = getProjectsFromApi(categoryId=getCategoryId(),start=start,page=nextAmt) />
		</cfif>
		
		<cfif arrayLen(newProjects)>
			<cfset variables.startIndex = start + nextAmt />
			<cfset variables.projectArray = newProjects />
			<cfset variables.lastUpdate = now() />		
			<cfset updateSuccess = TRUE>
		</cfif>
		
		<cfreturn updateSuccess/>
	</cffunction>
	
	
	<cffunction name="updateRecent" access="private" output="false" returnType="boolean"
			hint="Updates the recent projects array from the riaForge rss feed">
		
		<cfset var recentRss = "">
		<cfset var updateSuccess = FALSE>
		<cfset var rssXML = "">
		<cfset var itemArray = arrayNew(1)>
		<cfset var recentArray = arrayNew(1)>
		<cfset var i = 0>
		<cfset var title = "">
		<cfset var link = "">
		<cfset var description = "">
		<cfset var maxItem = 0>
		
		<cfhttp url="#variables.feedUrl##variables.categoryId#" method="GET" result="recentRss">
		
		<cfif structKeyExists(recentRss,"statusCode") AND reFindNoCase("200",recentRss.statusCode)>
			<cfset rssXML = xmlParse(recentRss.filecontent)>
			<cfset itemArray = XmlSearch(rssXML, "rss/channel/item")>
			
			<cfif arrayLen(itemArray) GT variables.displayNum>
				<cfset maxItem = variables.displayNum>
			<cfelse>
				<cfset maxItem = arrayLen(itemArray)>
			</cfif>
			
			<cfif arrayLen(itemArray)>
				<cfloop from="1" to="#maxItem#" index="i">
					<cfset title = XmlSearch(itemArray[i],"title")>
					<cfset link = XmlSearch(itemArray[i],"link")>
					<cfset description = XmlSearch(itemArray[i],"description")>
					
					<cfset recentArray[i] = structNew()>
					<cfset recentArray[i].urlname = getUrlNameFromLink(link[1].xmlText)>
					<cfset recentArray[i].name = title[1].xmlText>
					<cfset recentArray[i].shortdescription = description[1].xmlText>			
				</cfloop>
			</cfif>
		</cfif>
		
		<!--- If the new array of recent projects is not empty then update --->
		<cfif arrayLen(recentArray)>
			<cfset setRecentArray(recentArray)>
			<cfset updateSuccess = TRUE>
			<cfset variables.lastUpdate = now() />
		</cfif>
		
		<cfreturn updateSuccess>
	</cffunction>
	
	
	<cffunction name="getProjectsFromApi" access="private" output="false" returnType="array"
				hint="Gets an array of projects from the riaForge API">
					
		<cfargument name="categoryId" required="true" type="numeric" hint="The numeric category for which to get a set of projects - 1 for CF">
		<cfargument name="page" required="false" type="numeric" default="10" hint="Number of projects to get for a single page of data">
		<cfargument name="start" required="false" type="numeric" default="1" hint="Index of the first project to get">
		
		<cfset var projects = "" />
		<cfset var returnArray = arrayNew(1) />
		
		<cfhttp 
			url="#variables.apiUrl#?method=getProjects&categoryId=#arguments.categoryId#&start=#arguments.start#&page=#arguments.page#&getitall=0&returnFormat=#variables.returnFormat#" 
			charset="utf-8" 
			method="GET" 
			result="projects" />
		
		<cfif refind("200",projects.statusCode)>
			<cfif IsJSON(projects.fileContent)>
				<cfset returnArray = jsonToStructArray(projects.fileContent) />
			</cfif>
		</cfif>
		
		<cfreturn returnArray />
	</cffunction>
	
	
	<cffunction name="determineMaxProjectId" access="private" output="false" returnType="string" 
			hint="Makes a single call to the api to determine what the max project ID is">
		<cfset var maxId = 0>
		<cfset var appArray = getProjectsFromApi(
			categoryId=getCategoryId(),
			page=1,
			start=1) />
		
		<cfif arrayLen(appArray)>
			<cfset maxId = appArray[1].total>
		</cfif>

		<cfreturn maxId/>
	</cffunction>
	
	
	<cffunction name="jsonToStructArray" access="private" output="false" returnType="array" hint="Returns an array of structures from a json dataset">
		<cfargument name="jsonData" required="true" type="any">
	
		<cfset var returnArray = arrayNew(1) />
		<cfset var cfData = DeserializeJSON(arguments.jsonData) />
		<cfset var colList = ArrayToList(cfData.COLUMNS) />
		<cfset var i = 0 />
		<cfset var colName = "" />
		<cfset var counter = 0 />
		<cfset var tempStruct = structNew() />
		
		<cfloop from="1" to="#ArrayLen(cfData.DATA)#" index="i">
			<cfset returnArray[i] = structNew()>
			<cfset tempStruct = structNew()>
			<cfset counter = 0>
			
			<cfloop list="#colList#" index="colName">
				<cfset counter = counter + 1>
				<cfset "tempStruct.#colName#" = cfData.DATA[i][counter]>
			</cfloop>
			
			<cfset returnArray[i] = tempStruct>
		</cfloop>
		
		<cfreturn returnArray />
	</cffunction>
	
	
	<cffunction name="buildHTMLList" access="private" output="false" returnType="string"
				hint="Build an unordered list from the supplied app array">
					
		<cfargument name="appArray" required="true" type="array">
		
		<cfset var content = "">
		<cfset var i = 0>
		
		<cfsavecontent variable="content">
		<cfoutput>
			<cfif arrayLen(appArray)>
				<ul>
				<cfloop from="1" to="#arrayLen(appArray)#" index="i">
					<li><a href="http://#appArray[i].urlname#.riaforge.com" title="#appArray[i].shortdescription#">#appArray[i].name#</a></li>
				</cfloop>
				</ul>
			</cfif>
		</cfoutput>
		</cfsavecontent>
 
		<cfreturn content />
	</cffunction>
	
	
	<cffunction name="getUrlNameFromLink" access="private" output="false" returnType="string"
				hint="Extracts the project urlname from the full link url">
					
		<cfargument name="link" required="true" type="string">
		
		<cfset var matchStruct = refindnocase("http://([^\.]+)",arguments.link,1,true)>
		<cfset var i = 0>
		<cfset var urlName = "">
				
		<cfloop from="1" to="#ArrayLen( matchStruct.Pos )#" index="i">
			<cfif matchStruct.Pos[i] GT 0 AND i EQ arrayLen(matchStruct.Pos)>
			<cfset urlName = Mid(arguments.link,matchStruct.Pos[i],matchStruct.Len[i])>
			</cfif>
		</cfloop>
 
		<cfreturn urlName />
	</cffunction>
	
	
</cfcomponent>
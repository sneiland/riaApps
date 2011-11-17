<cfcomponent output="false" extends="mxunit.framework.TestCase">
	
	
	<!--- this will run before every single test in this test case --->
	<cffunction name="setUp" returntype="void" access="public" hint="put things here that you want to run before each test">
        <cfset variables.obj = createObject("component","riaApps.riaApps").init()>
    </cffunction>
	 
    <!--- this will run after every single test in this test case --->
    <cffunction name="tearDown" returntype="void" access="public" hint="put things here that you want to run after each test">
    </cffunction>
	
	<!--- this will run once after initialization and before setUp() --->
	<cffunction name="beforeTests" returntype="void" access="public" hint="put things here that you want to run before all tests">
		<!--- <cfset obj = createObject("component","ObjectUnderTest")> --->
    </cffunction>
	 
    <!--- this will run once after all tests have been run --->
    <cffunction name="afterTests" returntype="void" access="public" hint="put things here that you want to run after all tests">
	 
    </cffunction>
	
	<cffunction name="testUpdate" access="public" returntype="void">
		<cfset variables.obj.update()>
   <!---  expected = 2;
    actual = mycomponent.add(1,1);
    assertEquals(expected,actual); --->
	</cffunction>
	
	<cffunction name="testUpdateIndexWrap" access="public" returntype="void">
		<cfset var newStartIndex = variables.obj.getMaxProjectId() - 1>
		<cfset variables.obj.setStartIndex(newStartIndex)>
		<cfset variables.obj.update()>
   <!---  expected = 2;
    actual = mycomponent.add(1,1);
    assertEquals(expected,actual); --->
	</cffunction>
</cfcomponent>
<!--- -->
<fusedoc fuse="test-notifier.cfm" language="ColdFusion" specification="2.0">
	<responsibilities>
		Very simple test script to check the output format of notification XML
		based on the v2.2 API XSD provided by Airbrake.
	</responsibilities>
</fusedoc>
--->

<!--- define each test to run --->
<cfset tests = [
	{ name = "Simple" },
	{ name = "With full init params", init = { environment = "dev", use_ssl = TRUE, app_version = "1.2.3-rc4" } },
	{ name = "With session data",     args = { session = { foo = "bar", foz = "baz" } } },
	{ name = "With arbitrary params", args = { params = { foo = "bar", foz = "baz" } } },
	{ name = "Some of everything",
		init = { environment = "dev", use_ssl = TRUE, app_version = "1.2.3-rc4" },
		args = {
			session = { foo = "bar", foz = "baz" },
			params  = { foo = "bar", foz = "baz" }
		}
	}
]>

<!--- generate an error that we can test with --->
<cftry><cfthrow message="ARGH!"><cfcatch><cfset e = cfcatch></cfcatch></cftry>

<!--- grab the XSD file to validate against --->
<cffile action="read" file="#expandpath('./airbrake_2_2.xsd')#" variable="xsd">

<!--- function for rendering the output of a test --->
<cffunction name="renderTest" returntype="string" output="false">
	<cfargument name="description" type="string" required="true">
	<cfargument name="validation" type="struct" required="true">
	<cfset local = { out = "#arguments.description#: ", status = "PASS", colour = "green" }>
	<cfif NOT arguments.validation.status>
		<cfset local.status = "FAIL">
		<cfset local.colour = "red">
	</cfif>
	<cfset local.out = local.out & '<span style="color: #local.colour#">#local.status#</span>'>
	<cfreturn local.out>
</cffunction>

<!--- function to run an individual test --->
<cffunction name="runTest" output="false">
	<cfargument name="description" type="string" required="true">
	<cfargument name="exception" type="any" required="true">
	<cfargument name="init" type="struct" required="false" default="#{}#">
	<cfargument name="args" type="struct" required="false" default="#{}#">
	<cfset var local = {}>
	<cfset local.eargs = { error = arguments.exception } >
	<cfset arguments.init.api_key = "abc123">
	<cfset local.n = createobject("component", "AirbrakeNotifier").init(argumentcollection=arguments.init)>
	<cfset structappend(local.eargs, arguments.args, FALSE)>
	<cfset local.r = local.n.build_request(argumentcollection = local.eargs)>
	<cfset local.res = local.n.send(argumentcollection = local.eargs)>
	<cfset local.v = xmlvalidate(local.r, xsd)>
	<cfreturn renderTest(arguments.description, local.v)>
</cffunction>

<!--- run each test in turn --->
<cfloop array="#tests#" index="test">
	<cfparam name="test.init" default="#{}#">
	<cfparam name="test.args" default="#{}#">
	<cfoutput>#runTest(test.name, e, test.init, test.args)#<br></cfoutput>
</cfloop>

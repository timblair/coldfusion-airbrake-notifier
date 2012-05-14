<!--- -->
<fusedoc fuse="AirbrakeNotifier.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am an error reporting component, used for sending errors to Airbrake.
	</responsibilities>
	<properties>
		<note>
			ColdFusion Airbrake notifier, using V2.1 of the Airbrake API
			[http://help.airbrakeapp.com/faqs/api-2/notifier-api-v2]

			Airbrake was formally known as Hoptoad
			[http://robots.thoughtbot.com/post/7665411707/hoptoad-is-now-airbrake]
		</note>
	</properties>
</fusedoc>
--->

<cfcomponent output="false">

	<!--- notifier meta data --->
	<cfset variables.meta = {
		name    = "CF Airbrake Notifier",
		version = "3.0.0",
		url     = "http://github.com/timblair/coldfusion-airbrake-notifier"
	}>

	<!--- secured and unsecured notifier endpoints --->
	<cfset variables.airbrake_endpoint = {
		default = "http://api.airbrake.io/notifier_api/v2/notices/",
		secure  = "https://api.airbrake.io/notifier_api/v2/notices/"
	}>

	<!--- default instance variables --->
	<cfset variables.instance = {
		api_key     = "",
		environment = "production",
		use_ssl     = FALSE,
		app_version = ""
	}>

	<cffunction name="init" access="public" returntype="any" output="no" hint="Initialise the instance with the appropriate API key">
		<cfargument name="api_key" type="string" required="yes" hint="The Airbrake API key for the account to submit errors to">
		<cfargument name="environment" type="string" required="no" default="production" hint="The enviroment name to report to Airbrake">
		<cfargument name="use_ssl" type="boolean" required="no" default="FALSE" hint="Should we use SSL when submitting to Airbrake?">
		<cfargument name="app_version" type="string" required="no" default="" hint="An optional application version number.  Errors older than the project's app version will be ignored.  Should follow http://semver.org/">
		<cfset setApiKey(arguments.api_key)>
		<cfset setEnvironment(arguments.environment)>
		<cfset setUseSSL(arguments.use_ssl)>
		<cfset setAppVersion(arguments.app_version)>
		<cfreturn this>
	</cffunction>

	<cffunction name="setApiKey" access="public" returntype="void" output="no" hint="Set the project API key to use when POSTing data to Airbrake">
		<cfargument name="api_key" type="string" required="yes" hint="The Airbrake project's API key">
		<cfset variables.instance.api_key = arguments.api_key>
	</cffunction>
	<cffunction name="getApiKey" access="public" returntype="string" output="no" hint="The configured project API key">
		<cfreturn variables.instance.api_key>
	</cffunction>

	<cffunction name="setEnvironment" access="public" returntype="void" output="no" hint="Set the name of the environment we're running in">
		<cfargument name="environment" type="string" required="yes" hint="The environment name">
		<cfset variables.instance.environment = arguments.environment>
	</cffunction>
	<cffunction name="getEnvironment" access="public" returntype="string" output="no" hint="The name of the configured environment">
		<cfreturn variables.instance.environment>
	</cffunction>

	<cffunction name="setUseSSL" access="public" returntype="void" output="no" hint="Should we use SSL encryption when POSTing to Airbrake?">
		<cfargument name="use_ssl" type="boolean" required="yes" hint="">
		<cfset variables.instance.use_ssl = arguments.use_ssl>
	</cffunction>
	<cffunction name="getUseSSL" access="public" returntype="boolean" output="no" hint="The SSL encryption status">
		<cfreturn variables.instance.use_ssl>
	</cffunction>
	<cffunction name="getEndpointURL" access="public" returntype="string" output="no" hint="Get the endpoint URL to POST to">
		<cfreturn iif(getUseSSL(), "variables.airbrake_endpoint.secure", "variables.airbrake_endpoint.default")>
	</cffunction>

	<cffunction name="setAppVersion" access="public" returntype="void" output="no" hint="Sets the application version to report to Airbrake.">
		<cfargument name="version" type="string" required="yes" hint="The application version">
		<cfset variables.instance.app_version = arguments.version>
	</cffunction>
	<cffunction name="getAppVersion" access="public" returntype="string" output="no" hint="The application version.">
		<cfreturn variables.instance.app_version>
	</cffunction>

	<cffunction name="send" access="public" returntype="struct" output="no" hint="Send an error notification to Airbrake">
		<cfargument name="error" type="any" required="yes" hint="The error structure to notify Airbrake about">
		<cfargument name="session" type="struct" required="no" hint="Any additional session variables to report">
		<cfargument name="params" type="struct" required="no" hint="Any additional request params to report">
		<cfset var local = {}>
		<!--- we want to be dealing with a plain old structure here --->
		<cfif NOT isstruct(arguments.error)><cfset arguments.error = errorToStruct(arguments.error)></cfif>
		<!--- make sure we're looking at the error root --->
		<cfif structkeyexists(error, "RootCause")><cfset arguments.error = error["RootCause"]></cfif>
		<!--- create the backtrace --->
		<cfset local.backtrace = []>
		<cfif structkeyexists(arguments.error, "tagcontext") AND isarray(arguments.error["tagcontext"])>
			<cfset local.backtrace = build_backtrace(arguments.error["tagcontext"])>
		</cfif>
		<!--- default any messages we don't actually have but should do --->
		<cfif NOT structkeyexists(arguments.error, "type")><cfset arguments.error.type = "Unknown"></cfif>
		<cfif NOT structkeyexists(arguments.error, "message")><cfset arguments.error.message = ""></cfif>

		<!--- build the XML packet to send (easier to use strings; more efficient to use string buffers) --->
		<cfset local.xml = createobject("java", "java.lang.StringBuffer").init()>
		<cfset local.xml.append('<?xml version="1.0" encoding="UTF-8"?><notice version="2.0">')>
		<cfset local.xml.append('<api-key>#xmlformat(getApiKey())#</api-key>')>
		<cfset local.xml.append('<notifier><name>#xmlformat(variables.meta.name)#</name><version>#xmlformat(variables.meta.version)#</version><url>#xmlformat(variables.meta.url)#</url></notifier>')>
		<!--- error info and backtrace --->
		<cfset local.xml.append('<error><class>#xmlformat(arguments.error.type)#</class><message>#xmlformat(arguments.error.type)#: #xmlformat(arguments.error.message)#</message>')>
		<cfif arraylen(local.backtrace)>
			<cfset local.xml.append('<backtrace>')>
			<cfloop array="#local.backtrace#" index="local.line">
				<cfset local.xml.append('<line file="#xmlformat(local.line.file)#" number="#xmlformat(local.line.line)#"')>
				<cfif len(local.line.method)><cfset local.xml.append(' method="#xmlformat(local.line.method)#"')></cfif>
				<cfset local.xml.append(' />')>
			</cfloop>
			<cfset local.xml.append('</backtrace>')>
		</cfif>
		<cfset local.xml.append('</error>')>
		<!--- overall request object --->
		<cfset local.xml.append('<request>')>
		<cfset local.xml.append('<url>' & xmlformat(getPageContext().getRequest().getRequestUrl() & iif(len(cgi.query_string), "'?#cgi.query_string#'", "''")) & '</url>')>
		<cfif arraylen(local.backtrace) AND listlast(local.backtrace[1].file, ".") EQ "cfc">
			<cfset local.component = reverse(listfirst(reverse(local.backtrace[1].file), "/"))>
			<cfset local.xml.append('<component>#xmlformat(local.component)#</component>')>
			<cfif len(local.backtrace[1].method)>
				<cfset local.xml.append('<action>#xmlformat(local.backtrace[1].method)#</action>')>
			<cfelse>
				<cfset local.xml.append('<action />')>
			</cfif>
		<cfelse>
			<cfset local.xml.append('<component /><action />')>
		</cfif>
		<!--- CGI and environment variables --->
		<cfset local.xml.append('<cgi-data>')>
		<cfloop collection="#cgi#" item="local.key">
			<cfif len(cgi[local.key])><cfset local.xml.append('<var key="#xmlformat(ucase(local.key))#">#xmlformat(cgi[local.key])#</var>')></cfif>
		</cfloop>
		<!--- we'll also include any simple value fields from the error struct --->
		<cfset local.xml.append('<var key="CF_HOST">' & xmlformat(createObject("java", "java.net.InetAddress").getLocalHost().getHostName()) & "</var>")>
		<cfloop collection="#arguments.error#" item="local.key">
			<cfif issimplevalue(arguments.error[local.key]) AND len(arguments.error[local.key])>
				<cfset local.xml.append('<var key="CF_#xmlformat(ucase(local.key))#">#xmlformat(arguments.error[local.key])#</var>')>
			</cfif>
		</cfloop>
		<cfset local.xml.append('</cgi-data>')>
		<!--- session data --->
		<cfif structkeyexists(arguments, "session")>
			<cfset local.xml.append('<session>')>
			<cfloop collection="#arguments.session#" item="local.key">
				<cfif issimplevalue(arguments.session[local.key])>
					<cfset local.xml.append('<var key="#xmlformat(ucase(local.key))#">#xmlformat(arguments.session[local.key])#</var>')>
				</cfif>
			</cfloop>
			<cfset local.xml.append('</session>')>
		</cfif>
		<!--- arbitrary call params --->
		<cfif structkeyexists(arguments, "params")>
			<cfset local.xml.append('<params>')>
			<cfloop collection="#arguments.params#" item="local.key">
				<cfif issimplevalue(arguments.params[local.key])>
					<cfset local.xml.append('<var key="#xmlformat(ucase(local.key))#">#xmlformat(arguments.params[local.key])#</var>')>
				</cfif>
			</cfloop>
			<cfset local.xml.append('</params>')>
		</cfif>
		<cfset local.xml.append('</request>')>
		<!--- server environment settings --->
		<cfset local.xml.append('<server-environment>')>
		<cfset local.xml.append('<project-root>#xmlformat(expandpath("."))#</project-root>')>
		<cfset local.xml.append('<environment-name>#xmlformat(getEnvironment())#</environment-name>')>
		<cfif len(getAppVersion())><cfset local.xml.append('<app-version>#xmlformat(getAppVersion())#</app-version>')></cfif>
		<cfset local.xml.append('</server-environment>')>
		<cfset local.xml.append('</notice>')>

		<!--- send the XML to Airbrake --->
		<cfhttp method="post" url="#getEndpointURL()#" timeout="0" result="local.http">
			<cfhttpparam type="header" name="Accept" value="text/xml, application/xml">
			<cfhttpparam type="header" name="Content-type" value="text/xml">
			<cfhttpparam type="body" value="#local.xml.toString()#">
		</cfhttp>

		<!--- parse the returned XML back to a structure --->
		<cfset local.ret = { endpoint = getEndpointURL(), request = local.xml.toString(), response = local.http, status = local.http.statusCode, id = 0, url = "" }>
		<cfif isxml(local.http.filecontent)>
			<cfset local.ret_xml = xmlparse(local.http.filecontent)>
			<cfif structkeyexists(local.ret_xml, "notice")>
				<cfset local.ret.id = local.ret_xml.notice.id.XmlText>
				<cfset local.ret.url = local.ret_xml.notice.url.XmlText>
			</cfif>
		</cfif>

		<cfreturn local.ret>
	</cffunction>

	<cffunction name="build_backtrace" access="private" returntype="array" output="no" hint="Cleans up the context array and pulls out the information required for the backtrace">
		<cfargument name="context" type="array" required="yes" hint="The context element of the error structure">
		<cfset var lines = []>
		<cfset var line = {}>
		<cfset var item = {}>
		<cfloop array="#arguments.context#" index="item">
			<cfset line = { line = 0, file = "", method = "" }>
			<cfif structkeyexists(item, "line")><cfset line.line = item.line></cfif>
			<cfif structkeyexists(item, "template")><cfset line.file = item.template></cfif>
			<cfif structkeyexists(item, "raw_trace") AND refind("at cf.*?\$func([A-Z_-]+)\.runFunction", item.raw_trace)>
				<cfset line.method = lcase(trim(rereplace(item.raw_trace, "at cf.*?\$func([A-Z_-]+)\.runFunction.*", "\1")))>
			</cfif>
			<cfset arrayappend(lines, line)>
		</cfloop>
		<cfreturn lines>
	</cffunction>

	<cffunction name="exceptionHandler" access="public" returntype="void" output="no" hint="Backwards compatible façade for original CF notifier">
		<cfargument name="exception" type="any" required="yes" hint="The exception to handle and send to Airbrake">
		<cfargument name="action" type="string" required="no" default="" hint="The action to report">
		<cfargument name="controller" type="string" required="no" default="" hint="The controller to report">
		<cfset var error = errorToStruct(arguments.exception)>
		<cfset var params = {}>
		<cfif len(arguments.action)><cfset params.action = arguments.action></cfif>
		<cfif len(arguments.controller)><cfset params.controller = arguments.controller></cfif>
		<cfset this.send(error=error, params=params)>
	</cffunction>

	<cffunction name="errorToStruct" access="private" returntype="struct" output="no" hint="Converts a CFCATCH to a proper structure (or just shallow-copies if it's already a structure)">
		<cfargument name="catch" type="any" required="yes" hint="The CFCATCH to convert">
		<cfset var error = {}>
		<cfset var key = "">
		<cfloop collection="#arguments.catch#" item="key">
			<cfset error[key] = arguments.catch[key]>
		</cfloop>
		<cfreturn error>
	</cffunction>

</cfcomponent>

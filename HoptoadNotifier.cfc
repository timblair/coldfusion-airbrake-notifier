<cfcomponent output="false">
	<cfset Hashtable  = CreateObject("java", "java.util.Hashtable") />
	<cfset ArrayList = CreateObject("java", "java.util.ArrayList") />
	
	<cffunction name="init" output="false" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset setApiKey(arguments.apiKey) />
		<cfset configureJavaLoader() />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="exceptionHandler" output="false" access="public">
		<cfargument name="exception" type="coldfusion.runtime.EventHandlerException" required="true" />
		<cfset var local = {} />
		
		<cfset local.context = IIf(StructKeyExists(arguments.exception, "cause"),
			"arguments.exception.cause", "arguments.exception") />
		
		<cfset notifyHoptoad(
			apiKey		= getApiKey(),
			message		= local.context.message,
			file		= local.context.tagContext[1].template,
			line		= local.context.tagContext[1].line,
			trace		= createTrace(local.context.tagContext),
			errorClass	= local.context.type
		) />
	</cffunction>
	
	<cffunction name="notifyHoptoad" output="false" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfargument name="message" type="string" required="true" />
		<cfargument name="file" type="string" required="true" />
		<cfargument name="line" type="numeric" required="true" />
		<cfargument name="trace" type="array" required="true" />
		<cfargument name="errorClass" type="string" default="" />
		<cfset var local = {} />
		
		<cfset local.request.params["url"] = mapify(URL) />
		<cfset local.request.params["form"] = mapify(FORM) />
		<cfset local.request.params["request"] = mapify(REQUEST) />

		<cfset local.request["params"] = mapify(local.request.params) />

		<cfset local.request["url"] = IIf(cgi.https EQ "on", "'https'", "'http'") & "://"
			& cgi.http_host & cgi.path_info & IIf(Len(cgi.query_string), "'?#cgi.query_string#'", "''") />
		
		<cfset local.session["key"] = "" />
		<cfset local.session["data"] = mapify(SESSION) />
		<cfset local.session = mapify(local.session) />
		
		<cfset local.body = {} />
		<cfset local.body["api_key"] = arguments.apiKey />
		<cfset local.body["error_class"] = arguments.errorClass />
		<cfset local.body["error_message"] = arguments.message />
		<cfset local.body["backtrace"] = arguments.trace />
		<cfset local.body["request"] = mapify(local.request) />
		<cfset local.body["session"] = mapify(local.session) />
		<cfset local.body["environment"] = mapify(CGI) />
		
		<cfhttp method="post" url="http://hoptoadapp.com/notices/" timeout="2">
			<cfhttpparam type="header" name="Accept" value="text/xml, application/xml" />
			<cfhttpparam type="header" name="Content-type" value="application/x-yaml" />
			<cfhttpparam type="body" value="#createNotice(local.body)#" />
		</cfhttp>
	</cffunction>
	
	<cffunction name="createNotice" output="false" access="public">
		<cfargument name="body" type="struct" required="true" />
		<cfset var local = {} />
		<cfset local.hash = Hashtable.init() />
		<cfset local.hash.put("notice", mapify(arguments.body)) />
		<cfset local.yaml = getYaml().dump(local.hash, "true") />
		<cfset local.yaml = ReplaceNoCase(local.yaml, "!java.util.Hashtable", "", "all") />
		<cfreturn local.yaml />
	</cffunction>
	
	<cffunction name="createTrace" output="false" access="public">
		<cfargument name="trace" type="array" required="true" />
		<cfset var local = {} />
		<cfset local.array = ArrayList.init() />
		<cfloop index="local.trace" array="#arguments.trace#">
			<cfset local.array.add(local.trace.template & ":" & local.trace.line) />
		</cfloop>
		<cfreturn local.array />
	</cffunction>
	
	<cffunction name="configureJavaLoader" output="false" access="private">
		<cfset var local = {} />
		<cfset local.jars = [getDirectoryFromPath(getCurrentTemplatePath()) & "lib/jyaml-1.3.jar"] />
		<cfset local.JavaLoader = CreateObject("component", "javaloader.JavaLoader").init(local.jars) />
		<cfset setYaml(local.JavaLoader.create("org.ho.yaml.Yaml").init()) />
	</cffunction>
	
	<cffunction name="mapify" output="false" access="public">
		<cfargument name="struct" type="struct" required="true" />
		<cfset var local = {} />
		<cfset local.hash = Hashtable.init() />
		<cfset local.hash.putAll(arguments.struct) />
		<cfreturn local.hash />
	</cffunction>
	
	<cffunction name="getApiKey" output="false" access="public">
		<cfreturn variables.instance.apiKey />
	</cffunction>

	<cffunction name="setApiKey" output="false" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset variables.instance.apiKey = arguments.apiKey />
	</cffunction>
	
	<cffunction name="getYaml" output="false" access="public">
		<cfreturn variables.instance.Yaml />
	</cffunction>

	<cffunction name="setYaml" output="false" access="public">
		<cfargument name="Yaml" type="org.ho.yaml.Yaml" required="true" />
		<cfset variables.instance.Yaml = arguments.Yaml />
	</cffunction>
</cfcomponent>
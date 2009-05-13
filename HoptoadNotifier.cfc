<cfcomponent output="false">	
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
		
		<cfset local.request.params["url"] = URL />
		<cfset local.request.params["form"] = FORM />
		<cfset local.request.params["request"] = REQUEST />

		<cfset local.request["url"] = IIf(cgi.https EQ "on", "'https'", "'http'") & "://"
			& cgi.http_host & cgi.path_info & IIf(Len(cgi.query_string), "'?#cgi.query_string#'", "''") />
		
		<cfset local.session["key"] = IIf(StructKeyExists(SESSION, "sessionId"), "'#SESSION.sessionId#'", "''") />
		<cfset local.session["data"] = SESSION />
		
		<cfset local.body = {} />
		<cfset local.body["api_key"] = arguments.apiKey />
		<cfset local.body["error_class"] = arguments.errorClass />
		<cfset local.body["error_message"] = arguments.message />
		<cfset local.body["backtrace"] = arguments.trace />
		<cfset local.body["request"] = local.request />
		<cfset local.body["session"] = local.session />
		<cfset local.body["environment"] = CGI />
		
		<cfhttp method="post" url="http://hoptoadapp.com/notices/" timeout="2">
			<cfhttpparam type="header" name="Accept" value="text/xml, application/xml" />
			<cfhttpparam type="header" name="Content-type" value="application/x-yaml" />
			<cfhttpparam type="body" value="#createNotice(local.body)#" />
		</cfhttp>
	</cffunction>
	
	<cffunction name="createNotice" output="false" access="public">
		<cfargument name="body" type="struct" required="true" />
		<cfset var local = {} />
		<cfset local.data["notice"] = arguments.body />
		<cfreturn getYaml().dump(local.data) />
	</cffunction>
	
	<cffunction name="createTrace" output="false" access="public">
		<cfargument name="trace" type="array" required="true" />
		<cfset var local = {} />
		<cfset local.array = ArrayNew(1) />
		<cfloop index="local.trace" array="#arguments.trace#">
			<cfset ArrayAppend(local.array, local.trace.template & ":" & local.trace.line) />
		</cfloop>
		<cfreturn local.array />
	</cffunction>
	
	<cffunction name="configureJavaLoader" output="false" access="private">
		<cfset var local = {} />
		<cfset local.jars = [GetDirectoryFromPath(GetCurrentTemplatePath()) & "lib/SnakeYAML-1.2.jar"] />
		<cfset local.JavaLoader = CreateObject("component", "javaloader.JavaLoader").init(local.jars) />
		<cfset setYaml(local.JavaLoader.create("org.yaml.snakeyaml.Yaml").init()) />
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
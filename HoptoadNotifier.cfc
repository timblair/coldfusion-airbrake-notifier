<cfcomponent output="false">	
	<cffunction name="init" output="false" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset setApiKey(arguments.apiKey) />
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
		
		<cfset local.request["params"]["url"] = URL />
		<cfset local.request["params"]["form"] = FORM />
		<cfset local.request["params"]["request"] = REQUEST />

		<cfset local.request["url"] = getPageContext().getRequest().GetRequestUrl()
			& IIf(Len(cgi.query_string), "'?#cgi.query_string#'", "''") />
		
		<cfset local.session["key"] = IIf(StructKeyExists(SESSION, "sessionId"), "'#SESSION.sessionId#'", "''") />
		<cfset local.session["data"] = SESSION />
		
		<cfset local.data = {} />
		<cfset local.data["api_key"] = arguments.apiKey />
		<cfset local.data["error_class"] = arguments.errorClass />
		<cfset local.data["error_message"] = arguments.message />
		<cfset local.data["backtrace"] = arguments.trace />
		<cfset local.data["request"] = local.request />
		<cfset local.data["session"] = local.session />
		<cfset local.data["environment"] = CGI />
		
		<cfset local.body["notice"] = local.data />
		
		<cfhttp method="post" url="http://hoptoadapp.com/notices/" timeout="2">
			<cfhttpparam type="header" name="Accept" value="text/xml, application/xml" />
			<cfhttpparam type="header" name="Content-type" value="application/json" />
			<cfhttpparam type="body" value="#SerializeJSON(local.body)#" />
		</cfhttp>
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
	
	<cffunction name="getApiKey" output="false" access="public">
		<cfreturn variables.instance.apiKey />
	</cffunction>

	<cffunction name="setApiKey" output="false" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset variables.instance.apiKey = arguments.apiKey />
	</cffunction>
</cfcomponent>
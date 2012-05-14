# ColdFusion Airbrake Notifier

CF Airbrake Notifier if a simple CFC for handling errors and exceptions from ColdFusion and sending them to [Airbrake](http://www.airbrakeapp.com/); it uses v2.2 of the [Airbrake API](http://help.airbrake.io/kb/api-2/notifier-api-version-22).  CF Airbrake Notifier requires ColdFusion 8+.

## Example Usage

    <!--- Application.cfc --->
    <cfcomponent>
        <cffunction name="onApplicationStart">
            <cfset application.notifier = createobject("component", "AirbrakeNotifier").init(API_KEY)>
        </cffunction>
        <cffunction name="onError">
            <cfargument name="exception">
            <cfset application.notifier.send(arguments.exception)>
        </cffunction>
    </cfcomponent>

## Replacement for coldfusion-hoptoad-notifier

This is a completely rewritten-from-scratch, drop-in replacement for [Shayne Sweeney](
http://workgoodfast.com/)'s [coldfusion-hoptoad-notifier](http://github.com/shayne/coldfusion-hoptoad-notifier) that works with v2 of the Airbrake API.

## Project Name Change

ColdFusion Airbrake Notifier used to be known as ColdFusion Hoptoad Notifier.  To avoid a potential trademark infrigement, thoughtbot (the makers of Hoptoad/Airbrake) [changed the name](http://robots.thoughtbot.com/post/7665411707/hoptoad-is-now-airbrake); this project was renamed and updated appropriately.

## Licensing and Attribution

This project is released under the MIT license as detailed in the LICENSE file that should be distributed with this library; the source code is [freely available](http://github.com/timblair/coldfusion-airbrake-notifier).

This project was developed by [Tim Blair](http://tim.bla.ir/) during work on [White Label Dating](http://www.whitelabeldating.com/), while employed by [Global Personals Ltd](http://www.globalpersonals.co.uk).  Global Personals Ltd have kindly agreed to the extraction and release of this software under the license terms above.

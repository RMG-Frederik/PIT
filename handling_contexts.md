# Handling context
In PIT, a context is a small collection of four parameters:
- Log level (10, 20, .. 70)
- Trace level (10, 20, .. 50)
- Trace timing flag (Y|N)
- List of output modules (PIT_TABLE:PIT_APEX ...)

You may have any number of contexts defined for your application. To define a context, you create a parameter with the naming convention `CONTEXT_<Name>` and a string value of the four beforementioned parameters, separated by pipe signs (|). Package `pit_admin` provides to methods to help you create these parameters name `pit_admin.create_named_context`. The methods are overloaded and give you the choice of passing the four parameters in separately or as a preformatted settings string. Using these methods has the advantage of cross checking the values and giving you exceptions of you try to define values which are not supported.

One special context is called `CONTEXT_DEFAULT`. It servers as the basic setting for your logging. You define it differently on development and production systems, but you should make sure that it's always present. If you want to switch off logging completely, you can pass in `10|10|N|´ to indicate this, but as a best practice it is recommended to allow at least fatal and error log levels to be captured. This then in turn requires you to define at least on output module.

One context name is reserved and therefor can't be used by you. This context is called `CONTEXT_ACTIVE`. The active context is used as an alternative to default logging. This then makes it possible to log during a certain time period or certain sessions only without affecting the log settings for other sessions or the need to adjust the default settings. Any named context you define may be switched active and afterwards be reset to default again.

## How PIT stores logging options

Logging is controlled by the default context basically. If you simply start your code with PIT being installed, the default settings apply. Which options you have in regard to controlling your logging depends on the initial parameters you set before you install PIT.

Log settings need to be stored in a place where any session running PIT is able to see it. If the settings were set in a package variable, only the session setting the variables could see the changes. So if you change the log settings in one session, other sessions wouldn't be able to see those changes.

There are basically two places within the database every session has access to: Tables and SGA. I decided to persist all parameters in a parameter table but to copy some of the more important parameters to the SGA. Reason is that I wanted to be able not only to switch logging for a given session on and off without affecting other sessions, but to trace and log activities of a given application user, even if she uses different sessions while working on her application. This in turns makes it necessary to define the focus of visibility of these parameters. Luckily, Oracle provides a structure to maintain those settings on a fine granularity: A globally accessed context.

### Globally accessed contexts

A context is a memory structure where SQL as well as PL/SQL have access to without environment switches. This makes contexts very fast and convenient. On the other side, contexts are limited to short key value pairs of type varchar2 only. Another downside of a context is that normally they store their values in the PGA, granting access to the actual values to the active session only. This makes them less interesting for inter session purposes. A globally accessed context on the other side stores it's values in SGA and therefore makes them accessible to all session. Plus, these contexts allow to control the visibility of the information. Because of this, PIT stores all it's cross-session information in a global context. Changing settings means that all other sessions are aware of these changes immediately without any action. Changing parameters in the database on the other side means that you have to re-initialize PIT to make it aware of the parameter changes.

As per default, context may contain information that is visible to every user, to a specific database user only or to a session that has a specific client identifier set. As matter of fact, these options are not too intuitive to use when using a context out of the box. It would be highly appreciated to have a "fallback" for a given parameter if a user does not have a matching client identifier. In this case, it would be nice if this user could instead see the more widely visible parameter of the same name. Unfortunately, this is not possible. To allow for this, PIT wrapps the usage of the globally accessed context in a helper package called `utl_context`.

### UTL_CONTEXT
`utl_context` offers different types of globally accessed contexts to control how the context should behave. This wrapper is not only interesting for PIT but for other uses as well which can accept that this package writes to the context. Here is a list of the different context modes `utl_context` provides:
- `utl_context.c_global`: ... for any user and any session
- `utl_context.c_force_user`: ... only if database username matches
- `utl_context.c_force_client_id`: ... only if client_identifier matches
- `utl_context.c_force_user_client_id`: ... only if user AND client_identifier matches
- `utl_context.c_prefer_client_id`: ... if a matching value for that client_identifier exists, it is visible, otherwise a default value is provided
- `utl_context.c_prefer_user_client_id`: ... if a matching value for that user AND client_identifier exists, it is visible, otherwise a default value is provided
- `utl_context.c_session`: ... only within the session that set the value (pseduo local context)

To use one of those context types, you simply choose the constant value as value for PIT parameter `CONTEXT_TYPE`.

### Logging choices
Now that we understand that the memory of PIT is the globally accessed context, we need to understand what options we have to control these settings.

If you want to change the actual log settings, a best practice is to create a named context using the `pit_admin.create_named_context` method and to switch to it. This is achieved by calling `pit.set_context(<NAME>);`, This will work immediately and across all sessions that can see the global context value. Another option is convenient during testing: You can call the overloaded version ot ´pit.set_context` which allows you to set all log parameters directly without the need to create a named context upfront.

How and when this method is called is up to you. You may bind it to an external toggle or call a script to switch it, as soon as you call the method, it gets switched. What the focus of this switch will be depends on the kind of context you have. In an environment with client server connections, you may opt for a ´utl_context.c_force_user´ if your application users are proxy or database users. If, on the other side, you work in a connection pool environment, you may choose ´utl_context.c_prefer_user_client_id` to control logging on a per user basis, even if they utilize different sessions per call.

### Toggle context
Another option to control the log session is to switch logging on and of for a given list of methods or packages. Idea is that in your code you may have packages that are well maintained and tested, whereas other packages need testing and logging. In this case, you can provide a "white list" to switch logging on or a "black list" to switch logging off or anything in between, just how you see it fit.

To enable this option, a parameter called `ALLOW_TOGGLE` needs to be set to TRUE. Named contexts to switch to need to be defined and a list of parameters with the naming convention `TOGGLE_<NAME>` need to be generated. Let's make things clearer by providing an example. In an application, packages UTIL and method MAIL.SEND shall not be traced, whereas packages BL_FORM, BL_MODE and method BL_ORDER.SUBMIT shall be traced. Parameter `ALLOW_TOGGLE` is set to true. The following named contexts are defined:

- `CONTEXT_LOG_ALL`, settings: `70|70|Y|PIT_CONSOLE`
- `CONTEXT_LOG_OFF`, settings: `10|10|N|`

Now, two parameters to toggle the settings are defined:

- `TOGGLE_ON`, string value: `BL_FORM:BL_MODE:BL_ORDER.SUBMIT|CONTEXT_LOG_ALL`
- `TOGGLE_OFF`, string value: `UTIL:MAIL.SEND|CONTEXT_LOG_OFF`

Now, your code enters method FOO. As no setting is defined for this package, CONTEXT_DEFAULT is used. FOO calls BL_FORM. The context toggles to CONTEXT_LOG_ALL and logs anything on output module PIT_CONSOLE. Now, BL_FORM calls another package FOO2. As this does not change the settings, CONTEXT_LOG_ALL remains active. If MAIL.SEND is called, logging is switched off. But if you leave MAIL.SEND, Logging resumes to the last setting that was active befor MAIL.SEND was called, so in our example it resumes CONTEXT_LOG_ALL and logging continues. If you leave BL_FORM, logging switches back to CONTEXT_DEFAULT, as no active context was active before BL_FORM was called.

Switching parameter `ALLOW_TOGGLE` on forces PIT to maintain minimal tracing information to gather the information whether a context should be switched or not. Therefore, if you don't need the toggle, switch parameter `ALLOW_TOGGLE` to FALSE again to avoid this unnecessary work.

## PIT_ADMIN and PIT
As you can see throughout this page, `pit_admin` is used to create parameters, whereas `pit` is used to switch between existing parameters. This is by design. It allows to install `pit_admin` on development systems only and to discard it when deploying to production. If you want to create all parameters using `pit_admin` upon deployment, you may choose to throw `pit_admin` away after deployment. It is not used for the normal operation of PIT, only for administrative purposes.
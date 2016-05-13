create or replace package pit_pkg
as
  /* Package to implement the core PIT logic. This package is called by PIT
     as the API for PIT_PKG only.
   */
  /* PUBLIC PACKAGE TYPES */
  type context_type is record(
    log_level number,
    trace_level number,
    trace_timing boolean,
    log_modules varchar2(2000),
    is_default boolean);

  /* Initialization procedure
     Made public to allow for any session to reset the PIT.
     As the actual status is persisted in a global context, initializing
     PIT will re-initialize all PIT packages
   */
  procedure initialize;
  
   
  /* CORE */
  /* Logs messages
     %param p_level Log-level. Allows to decide whether PIT should log or not.
     %param p_message_name Name of the message to log
     %param p_affected_id Optional ID of an item a log entry relates to
     %param p_arg_list List of replacement values for the message
     %usage This procedure is called from PIT. It takes the message_name and
            constructs an instance of MESSAGE_TYPE for it. It then calls any
            log procedure of all active output modules and passes the message.
   */
  procedure log(
    p_level in integer,
    p_message_name in varchar2,
    p_affected_id in varchar2,
    p_arg_list in msg_args);
    
    
  /* Logs messages generically
     %param p_message_name Name of the message to log
     %param p_affected_id Optional ID of an item a log entry relates to
     %param p_arg_list List of replacement values for the message
     %param p_log_threshold Threshold that is taken as a comparison to the message
            severity to decide whether a message should be logged
     %param p_log_modules List of output modules to log to. This list is taken
            for this single call only. It does not affected the overall log module
            settings for the active or default context
     %usage This procedure is called from PIT. It takes the message_name and
            constructs an instance of MESSAGE_TYPE for it. It then calls any
            log procedure of all active output modules and passes the message.
            This overloaded version is used to provide a mechanism to log different
            messages to a certain set of log modules only
   */
  procedure log(
    p_message_name in varchar2,
    p_affected_id in varchar2,
    p_arg_list in msg_args,
    p_log_threshold in number,
    p_log_modules in varchar2);
  
  
  /* Traces entering a procedure
     %param p_action Nam of the block that is executed. Normally the procedure
            or function name within a package.
     %param p_module Unit that contains the method that is executed. Either the
            package name or ANONYMOUS, PROCEDURE, FUNCTION or TRIGGER
     %param p_params List of parameters which is passed into tracing. Only varhar2
            is allowed as a parameter value with a maximum of 4000 byte.
     %param p_trace_level Trace level to allow for selective tracing.
     %param p_clinet_info Optional info to be passed to DBMS_APPLICATION_INFO,
            applicable for TRACE_MANDATORY only
     %usage This procedure is called from PIT to trace entering a procedure.
            It will determine timing information and maintain a call stack.
   */
  procedure enter(
    p_action in varchar2,
    p_module in varchar2,
    p_params in msg_params,
    p_trace_level in number,
    p_client_info in varchar2 default null);

  
  /* Traces leaving a procedure
     %param p_trace_level Trace level to allow for selective tracing.
     %usage This procedure is called from PIT to trace leaving a procedure.
            It will determine timing information and maintain a call stack.
   */
  procedure leave(
    p_trace_level in number);  
  
  
  /* Purges the message stack after a given point in time
     %param p_date_before Date, before which the message log is purged 
     %usage This procedure is called from PIT to purge the message stack
            p_date_before determines which entries shall be purged.
   */
  procedure purge(
    p_date_before in date);
  
  
  /* Prints a message to the output modules. Used to pass user information
     to the view layer
     %param p_message_name  Name of the message to log
     %param p_arg_list List of replacement values for the message
     %usage This procedure is called from PIT. It takes the message_name and
            constructs an instance of MESSAGE_TYPE for it. It then calls any
            print procedure of all active output modules and passes the message.
   */
  procedure print(
    p_message_name in varchar2,
    p_arg_list msg_args default null);
  
  
  /* Raises an error
     %param p_message_name  Name of the message to log
     %param p_arg_list List of replacement values for the message
     %usage This procedure is called from PIT. It takes the message_name and
            constructs an instance of MESSAGE_TYPE for it. It then calls raises
            an error with the respective message that can be caught by the exception
            block. Messages with severity error or fatal have an associated error
            called <MESSAGE_NAME>_ERR that can be used to capture the error.
   */
  procedure raise_error(
    p_message_name varchar2,
    p_arg_list in msg_args);
  
  
  /* Returns an instance of type MESSAGE_TYPE.
     %param p_message_name  Name of the message to log
     %param p_arg_list List of replacement values for the message
     %return Instance of the requested message.
     %usage This procedure is called from PIT. It takes the message_name and
            constructs an instance of MESSAGE_TYPE and returns the message instance.
   */
  function get_message(
    p_message_name in varchar2,
    p_affected_id in varchar2,
    p_arg_list msg_args)
    return message_type;
  /* CONTEXT MAINTENANCE */
  /* Function to retrieve the actually valid context
   * %return Instance of context_type-Record that holds the settings for the
   *         actually valid context
   */
   
  
  /* Functon to retrieve the actual context as an instance of context type
   * %return Instance of context_type filled with the actually valid settings
   * %usage is called if an external function wishes to persist the actual
   *        settings and reset them later
   */
  function get_context
    return context_type;
    
    
  /* Procedure to change the settings in the global PIT_CONTEXT
     %param p_log_level New log level.
     %param p_trace_level New trace level
     %param p_trace_timing Flag to switch timing on or off
     %param p_module_list Colon-separated list of output modules used
     %param p_focus Indicates whether changes are made for the active session 
            only (ACTIVE) or as a new default setting (DEFAULT). Defaults to ACTIVE
     $usage This procedure is used when log settings shall be changed dynamically
            Normal usage is to overwrite log settings as defined in the parameters
            for a given session.
   */
  procedure set_context(
    p_log_level in integer,
    p_trace_level in integer,
    p_trace_timing in boolean,
    p_module_list in varchar2);
    
  
  /* Overloaded version that takes an instanvce of CONTEXT_TYPE-record as input parameter
   * %param p_context Instance of CONTEXT_TYPE-record with the actually valid
   *        context settings
   */
  procedure set_context(
    p_context in context_type);
    
  
  /* Overloaded version that expects the name of a named context as defined in the parameters
   * %param p_context_name Name of a context. Reuqires a matching parameter named CONTEXT_<Name>
   *        with predefined debug settings in the format [LOG_LEVEL|TRACE_LEVEL|TRACE_TIMING_FLAG (Y,N)|MODULE_LIST],
   *        fi: CONTEXT_FULL = '70|70|Y|PIT_CONSOLE:PIT_FILE'
   */
  procedure set_context(
    p_context_name in varchar2);
  
  
  /* Procedure to reset log settings to the default settings
     %usage If settings for a session were changed, calling this procedure
            resets these settings to the default settings as defined by the 
            parameters
   */
  procedure reset_active_context;
  
  
  /* Procedure to reset the complete context to default settings
     %usage Use this procedure if all session settings shall be reset to the 
            default settings. Be aware that calling this procedure will reset
            ALL log settings of ALL sessions to default
   */
  procedure reset_context;
  
  
  /* MODULE MAINTENANCE */
  /* Function to retrieve a list of active modules
     %return ARGS-type, List of module names
     %usage Use this function if you require a list of active modules.
   */
  function get_active_modules
   return args
   pipelined;
   
   
  /* Function to retrieve a list of available modules
     %return ARGS-type, List of module names
     %usage Use this function if you require a list of available modules.
            A module is AVAILABLE if it could be initialized succesfully.
   */
  function get_available_modules
   return args
   pipelined;
   
 
end pit_pkg;
/
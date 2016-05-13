create or replace package pit_admin
authid current_user
as 
  /**
    Package to administer PIT. Provides methods to create or maintain messages.
  */
  

  /* Function to retrieve the text for a given language without replacements
   * %param p_message_name Name of the message to retrieve the text for
   * %param p_message_language Oracle language reference
   * %usage This function is used to review the text a given message has in a 
   *        desired language 
   */
  function get_message_text(
    p_message_name in varchar2,
    p_message_language in varchar2 := null)
    return varchar2;
    

  /* Procedure to maintain messages
   * %param p_message_name Name of the respective message. Must be unique for the default language
   * %param p_message_text Message text with replacement anchors in the format #n#, 
   *        where n is an integer that references up to 50 replacement items
   * %param p_severity Reference to a severity as defined in PIT.LEVEL_<level> constants.
   *        Ranges from PIT.LEVEL_FATAL to PIT.LEVEL_VERBOSE or 20..70
   * %param p_message_language Reference to the Oracle supported language names, 
   *        if null, the default language is used (as defined in MESSAGE_LANGUAGES)
   * %param p_error_number Optional reference to an Oracle system error number.
   *        must not be a number of an Oracle predefined error number. If null
   *        and the severity of the message is in 20|30, then an error number
   *        from the range -20999..-20000 is used.
   */
  procedure merge_message(
    p_message_name in varchar2,
    p_message_text in clob,
    p_severity in number,
    p_message_language in varchar2 default null,
    p_error_number in number default null);
    

  /* Procedure to translate a given message
   * %param p_message_name Name of the respective message. Must be unique for the default language
   * %param p_message_text Message text with replacement anchors in the format #n#, 
   *        where n is an integer that references up to 50 replacement items
   * %param p_message_language Reference to the Oracle supported language names
   * %usage Use this procedure as a shortcut for an already existing message, if
   *        the only task is to translate it.
   */
  procedure translate_message(
    p_message_name in varchar2,
    p_message_text in clob,
    p_message_language in varchar2);
    

  /* Procedure to check whether a predefined Oracle error shall be redefined
   * %param p_error_number Error number for which a PIT message shall be created
   * %usage Is called whenever a new message is inserted into table MESSAGE with an Oracle
   *        error number. The function checks whether the Oracle error number is already
   *        a defined error, such as -1 and DUP_VAL_ON_INDEX.
   *        If so, the procedure throws an error.
   *        Limitation: This procedure can only see Exceptions that are defined in 
   *        packages from SYSTEM or SYS and only exceptions from non wrapped sources.
   */
  procedure check_error(
    p_message_name in varchar2,
    p_error_number in number);
    

  /* Function to retrieve an XML file in format XLIFF to translate messages
   * %param p_target_language Oracle supported language name the messages shall be translated to
   * %return XML-instance in format XLIFF to be opened and edited by an XLIFF-Editor
   * %usage Call this function to create an XLIFF-File that can be used to translate all
   *        error messages into a target language at once.
   */
  function get_translation_xml(
    p_target_language in varchar2)
    return XmlType;
    

  /* Procedure to import translated messages into the database
   * %param p_translation_xml XLIFF-instance with the translated messages
   * %usage If provided with a translated XLIFF-Instanve, this procedure creates
   *        the necessary entries in table MESSAGE for the new language.
   */
  procedure translate_messages(
    p_translation_xml in xmltype);
    

  /* Procedure to (re-) create package MSG
   * %param p_directory Optional parameter to define a directory object the creation script shall be written to
   * %usage If called with  no parameter, this procedure creates package MSG based on the actual messages
   *        from table MESSAGE. It automatically maps all custom or oracle errors and creates respective
   *        exception variables for them.
   *        If called with a directory name, the package is not created but written to 
   *        the file system for later creation or deployment purposes.
   */
  procedure create_message_package(
    p_directory varchar2 default null);
  
  
  
  /* Procedure to create a named context
   * %param p_context_name Name of the context. Maximum of 20 byte. Don't use umlauts or special chars
   * %param p_log_level Log level of the named context
   * %param p_trace level Trace level of the named context
   * %param p_trace_timing Flag to indicate whether timing information should be captured
   * %param p_module_list List of output modules to be used for logging
   * %param p_comment Optional comment to explain the usage of the named context
   * %usage Is called to create a named context
   */
  procedure create_named_context(
    p_context_name in varchar2,
    p_log_level in number,
    p_trace_level in number,
    p_trace_timing in boolean,
    p_module_list in varchar2,
    p_comment in varchar2 default null);
  
  
  /* Procedure to create a named context
   * %param p_context_name Name of the context. Maximum of 20 byte. Don't use umlauts or special chars
   * %param p_settings Settings string in the format LOG_LEVEL(10,20..70)|TRACE_LEVEL (10,20..40)|TRACE_TIMING_FLAG (Y,N)|MODULE_LIST (MODULE_1:MODULE_2)
   *        Valid examples are: 
   *        30|10|N|PIT_TABLE:PIT_MAIL, 70|40|Y|PIT_CONSOLE
   *        If you want to express that no logging should be used, use 10|10|N|
   * %param p_comment Optional comment to explain the usage of the named context
   * %usage Is called to create a new named context
   */
  procedure create_named_context(
    p_context_name in varchar2,
    p_settings in varchar2,
    p_comment in varchar2 default null);
    
  
  /* Procedure to remove a named context
   * %param p_context_name Name of the context to remove
   * %usage Is called to remove a named context
   */
  procedure remove_named_context(
    p_context_name in varchar2);
    
    
  /* Procedure to create a context toggle
   * %param p_toggle_name Name of the context toggle. Maximum of 20 byte. Don't use umlauts or special chars
   * %param p_module_list Name of the module to toggle the context for. May be a pipe separated list of modules
   *        Two formats are allowed: Name of a package/method or qualified name of a method in a package (without owner):
   *        Examples: MY_PACKAGE|MY_OTHER_PACKAGE.MY_PROC
   * %param p_context_name Name of the context to switch to. Must be an excisting context
   * %usage Is called to have PIT toggle it's context settings based on entering a module or a list of modules.
   */
  procedure create_context_toggle(
    p_toggle_name in varchar2,
    p_module_list in varchar2,
    p_context_name in varchar2,
    p_comment in varchar2 default null);
    
    
  /* Procedure to remove a context toggle
   * %param p_toggle_name Name of the context toggle to remove
   * %usage Is used to remove a context toggle
   */
  procedure remove_context_toggle(
    p_toggle_name in varchar2);
end pit_admin;
/
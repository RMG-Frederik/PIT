create or replace
package body pit_mail_pkg
as
  g_con utl_smtp.connection;
  g_mail_template clob;
  
  type param_tab is table of varchar2(32767)
    index by varchar2(30);
  g_param_list param_tab;
  
  c_param_group constant varchar2(20) := 'PIT';
  c_fire_threshold constant varchar2(30) := 'PIT_MAIL_FIRE_THRESHOLD';
  c_template constant varchar2(30) := 'PIT_MAIL_TEMPLATE';
  c_host constant varchar2(30) := 'PIT_MAIL_HOST';
  c_from constant varchar2(30) := 'PIT_MAIL_FROM_ADDRESS';
  c_to constant varchar2(30) := 'PIT_MAIL_TO_ADDRESS';
  c_subject constant varchar2(30) := 'PIT_MAIL_SUBJECT';
  
  c_return varchar2(10) := utl_tcp.crlf;
  
  /* HELPER */
  /* Method to send header information for a mail
   * %param p_name Name of the header variable
   * %param p_header Header value
   * %usage Is called by the package to help write formatted header mail information
   */
  procedure send_header(
    p_name in varchar2, 
    p_header in varchar2)
  as
  begin
    utl_smtp.write_data(g_con, p_name || ': ' || p_header || utl_tcp.crlf);
  end send_header;
  
  /* INTERFACE*/
  
  procedure log(
    p_message in message_type)
  as
    l_mail_text varchar2(32767);
  begin
    -- Messagetext vorbereiten
    l_mail_text := g_mail_template;
      
    -- Verbindung herstellen
    g_con := utl_smtp.open_connection(g_param_list(c_host));
    utl_smtp.helo(g_con, g_param_list(c_host));
    utl_smtp.mail(g_con, g_param_list(c_from));
    utl_smtp.rcpt(g_con, g_param_list(c_to));
    
    -- Senden
    utl_smtp.open_data(g_con);
    send_header('From', g_param_list(c_from));
    send_header('To', g_param_list(c_to));
    send_header('Subject', g_param_list(c_subject));
    utl_smtp.write_raw_data(g_con, utl_raw.cast_to_raw(c_return || l_mail_text));
    
    -- Aufraeumen
    utl_smtp.close_data(g_con);
    utl_smtp.quit(g_con);
  exception
    when utl_smtp.transient_error or utl_smtp.permanent_error then
      begin
        utl_smtp.quit(g_con);
      exception
        when utl_smtp.transient_error or utl_smtp.permanent_error then
          null; -- When the SMTP server is down or unavailable, we don't have
                -- a connection to the server. The QUIT call will raise an
                -- exception that we can ignore.
      end;
      pit.error(msg.PIT_MAIL_ERROR, msg_args(to_char(sqlcode), sqlerrm));
  end log;
  
  
  procedure initialize_module(self in out PIT_MAIL)
  as
  begin
    self.fire_threshold := param.get_integer(c_fire_threshold, c_param_group);
    self.status := msg.MODULE_INSTANTIATED;
    -- Copy parameters
    g_mail_template := param.get_string(c_template, c_param_group);
    g_param_list(c_host) := param.get_string(c_host, c_param_group);
    g_param_list(c_from) := param.get_string(c_from, c_param_group);
    g_param_list(c_to) := param.get_string(c_to, c_param_group);
    g_param_list(c_subject) := param.get_string(c_subject, c_param_group);
    g_param_list(c_return) := param.get_string(c_return, c_param_group);
  exception
    when others then
      self.fire_threshold := pit.level_off;
      self.status := msg.MODULE_INITIALIZATION_ERROR;
      self.stack := dbms_utility.format_error_stack;
  end initialize_module;

end pit_mail_pkg;
/
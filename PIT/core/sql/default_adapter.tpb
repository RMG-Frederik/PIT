create or replace type body default_adapter
as
   member procedure get_session_details(
      p_user_name out varchar2,
      p_session_id out varchar2)
   as
   begin
      p_user_name := user;
      p_session_id := sys_context('USERENV', 'CLIENT_IDENTIFIER');
      if p_session_id is null then
         p_session_id := to_char(sys_context('USERENV','SID'));
         dbms_session.set_identifier(p_session_id);
      end if;
   end get_session_details;
   
   constructor function default_adapter(
      self in out nocopy default_adapter)
      return self as result
   as
   begin
      self.environment := 'DEFAULT';
      self.status := 1;
      return;
   end default_adapter;
end;
/

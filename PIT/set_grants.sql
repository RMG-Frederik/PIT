
prompt &h3.Grant SYSTEM privileges
prompt &s1.create session, create procedure, create table, create type to &INSTALL_USER.
grant create session, create procedure, create table, create type to &INSTALL_USER.;

prompt &s1.create session to &REMOTE_USER.
grant create session to &REMOTE_USER.;

prompt &h3.Grant OBJECT privileges
prompt &s1.Select on sys.dba_context
grant select on dba_context to &INSTALL_USER.;

begin
  $IF dbms_db_version.ver_le_11 $THEN
  null;
  $ELSE
  dbms_output.put_line('&s1.INHERIT PRIVILEGES from SYS to &INSTALL_USER. granted');
  execute immediate 'grant inherit privileges on user sys to &INSTALL_USER.';
  $END
end;
/
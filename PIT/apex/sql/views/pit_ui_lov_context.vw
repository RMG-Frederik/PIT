create or replace view pit_ui_lov_context as
select par_id d, par_id r
  from dl_parameter_tab
 where par_pgr_id = 'PIT'
   and par_id like 'CONTEXT%';
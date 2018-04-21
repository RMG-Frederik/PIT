create or replace view pit_ui_admin_pit_toggle as
select rowid row_id,
       par_id, 
       par_pgr_id,
       par_description, 
       substr(par_string_value, 1, instr(par_string_value, '|') - 1) toggle_module_list,
       substr(par_string_value, instr(par_string_value, '|') + 1) toggle_context_name
  from dl_parameter_tab
 where par_pgr_id = 'PIT'
   and par_id like 'TOGGLE%';
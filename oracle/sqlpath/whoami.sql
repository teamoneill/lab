set termout off

column service_name new_value service_name
column session_user new_value session_user
column current_schema new_value current_schema
column db_name new_value db_name
column container_name new_value container_name
column cdb_name new_value cdb_name
column session_edition new_value session_edition
column database_default_edition new_value database_default_edition


select sys_context('USERENV','SERVICE_NAME') as service_name
   , sys_context('USERENV','SESSION_USER') || decode(sys_context('USERENV','IP_ADDRESS'),'TRUE',' (ISDBA)',null) as session_user
   , sys_context('USERENV','CURRENT_SCHEMA') current_schema
   , sys_context('USERENV','CON_NAME') container_name
   , sys_context('USERENV','CDB_NAME') cdb_name
   , sys_context('USERENV','CURRENT_EDITION_NAME') session_edition
   , dp.property_value as database_default_edition
from database_properties dp
where property_name = 'DEFAULT_EDITION';

set termout on

prompt SERVICE NAME...... &service_name
prompt SESSION USER...... &session_user
prompt CURRENT SCHEMA.... &current_schema
prompt CONTAINER NAME.... &container_name
prompt CDB............... &cdb_name
prompt SESSION EDITION... &session_edition
prompt DATABASE DEFAULT.. &database_default_edition
prompt

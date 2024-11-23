/*
   whoami.sql
   
   Example:
      Copy into a client's SQLPATH location
      Execute without pathing
      sql> @whoami

   MIT License

   Copyright (c) 2024 Team O'Neill Projects and Michael O'Neill
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

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

prompt
prompt Oracle session whoami
prompt SERVICE NAME............... &service_name
prompt SESSION USER............... &session_user
prompt CURRENT SCHEMA............. &current_schema
prompt CONTAINER NAME............. &container_name
prompt CDB NAME................... &cdb_name
prompt SESSION EDITION............ &session_edition
prompt DATABASE DEFAULT EDITION... &database_default_edition
prompt

/*
   whoami.sql

   Parameters: none

   Purpose:
      An Oracle session equivalent to Linux whoami. Used by accompanying scripts
      to provide feedback.

      Working with multiple connections, containers, editions and schema can be
      an overwhelming amount of "checking" before executing commands against
      the desired target.
   
   Example:
      sql> @whoami

   MIT License

   Copyright (c) 2024-2025 Team O'Neill Projects and Michael O'Neill
   https://teamoneill.org
   
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

column client new_value client
column service new_value service
column session_user new_value session_user
column current_schema new_value current_schema
column container_name new_value container_name
column cdb_name new_value cdb_name
column session_edition new_value session_edition
column database_default_edition new_value database_default_edition

select
   sys_context('USERENV','OS_USER') || '@'  || sys_context('USERENV','IP_ADDRESS') as client,
   sys_context('USERENV','SERVER_HOST') || '/' || sys_context('USERENV','SERVICE_NAME') as service,
   sys_context('USERENV','SESSION_USER') || decode(sys_context('USERENV','ISDBA'),'TRUE',' (DBA)', '') as session_user,
   sys_context('USERENV','CURRENT_SCHEMA') as current_schema,
   sys_context('USERENV','CON_NAME') as container_name,
   sys_context('USERENV','CDB_NAME') cdb_name,
   sys_context('USERENV','CURRENT_EDITION_NAME') session_edition,
   dp.property_value as database_default_edition
from database_properties dp
where property_name = 'DEFAULT_EDITION';

set termout on

prompt
prompt SERVICE.................... &service
prompt CLIENT..................... &client
prompt SESSION USER............... &session_user
prompt CURRENT SCHEMA............. &current_schema
prompt CONTAINER NAME............. &container_name
prompt CDB NAME................... &cdb_name
prompt SESSION EDITION............ &session_edition
prompt DATABASE DEFAULT EDITION... &database_default_edition
prompt

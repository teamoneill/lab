/*
   enable_validate_constraints.sql

   Parameters: none
   
   Purpose:
      Enables and validates constraints that are both
      * owned by the current schema i.e., sys_context('USERENV','CURRENT_SCHEMA')
      * available to the session user i.e., all_constraints.
   
  Tested: 19c and 23ai servers and clients (should work with any)
   
   Example:
     (optional) sql> @setschema tableOwningSchemaName
      sql> @enable_validate_constraints

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

declare
   v_ddl varchar2(4000);
begin
   for i in (
      select owner, table_name, constraint_name, status, validated
      from all_constraints
      where owner = sys_context('USERENV','CURRENT_SCHEMA')
      and (status != 'ENABLED' or validated = 'NOT VALIDATED')
      order by case constraint_type when 'C' then 1 when 'P' then 2 when 'U' then 3 when 'R' then 4 else 5 end, constraint_name
   ) loop
      v_ddl := 'ALTER TABLE "' || i.owner || '"."' || i.table_name || '"';
      
      if (i.status != 'ENABLED') then
         v_ddl := v_ddl || ' ENABLE';
      end if;
      
      if (i.validated = 'NOT VALIDATED') then
         v_ddl := v_ddl || ' VALIDATE';
      end if;

      execute immediate (v_ddl || ' CONSTRAINT "' || i.constraint_name || '"');
   end loop;
end;
/

set termout on

prompt enable_validate_constraints complete

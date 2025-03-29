/*
   rebuild_unusable_indexes.sql

   Parameters: none
   
   Rebuilds indexes that are both:
      * owned by current schema i.e., sys_context('USERENV','CURRENT_SCHEMA')
      * available to the session user, i.e., all_indexes
   
   Note:
      The owner of the *table* the index is upon is not relevant. Typically, the
      table and index owner are the same, but this is not required.

   Optional: Enable serveroutput for feedback
   
   Example:
      (optional) sql> @setschema indexOwningSchemaName
      sql> @rebuild_unusable_indexes

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
   v_affected integer := 0;
begin
   for i in (
      select owner as index_owner, index_name, null as partition_name, null as subpartition_name
      from all_indexes
      where owner = sys_context('USERENV','CURRENT_SCHEMA')
      and owner = table_owner
      and status = 'UNUSABLE'
      union all
      select index_owner, index_name, partition_name, null as subpartition_name
      from all_ind_partitions p
      join all_indexes i on p.index_owner = i.owner and p.index_name = i.index_name and i.owner = i.table_owner
      where index_owner = sys_context('USERENV','CURRENT_SCHEMA')
      and status = 'UNUSABLE'
      union all
      select index_owner, index_name, partition_name, subpartition_name
      from all_ind_subpartitions s
      join all_indexes i on s.index_owner = i.owner and s.index_name = i.index_name and i.owner = i.table_owner
      where index_owner = sys_context('USERENV','CURRENT_SCHEMA')
      and status = 'UNUSABLE'
   ) loop
   
      v_ddl := 'ALTER INDEX ".' || i.index_owner || '"."' || i.index_name || '" REBUILD ';

      case
         when i.subpartition_name is not null then
            v_ddl := v_ddl || 'SUBPARTIION "' || i.subpartition_name;
         when i.partition_name is not null then
               v_ddl := v_ddl || 'PARTIION "' || i.partition_name;
         else
            null;
      end case;

      begin
         execute immediate (v_ddl || ' ONLINE');
      exception
         when others then
            dbms_output.put_line('FAILED:' || v_ddl );
            dbms_output.put_line(sqlerrm);
      end;
      
      v_count := v_count + 1;
      dbms_output.put_line('INDEXES REBUILT: ' || v_count);
   end loop;
end;
/

set termout off

prompt rebuild_unusable_indexes complete

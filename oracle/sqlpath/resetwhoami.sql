/*
   resetwhoiam.sql

   Parameters: none

   Purpose:
      Undoes any setschema, setedition, setcontainer and returns whoami to defaults. Used by accompanying scripts
      to provide feedback.

      Working with multiple connections, containers, editions and schema can be
      an overwhelming amount of "checking" before executing commands against
      the desired target.
   
   Example:
      sql> @resetwhoami

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

BEGIN
   EXECUTE IMMEDIATE 'alter session set current_schema = ' || sys_context('USERENV', 'SESSION_USER');
END;
/

DECLARE
   database_default_edition database_properties.property_value%TYPE;
BEGIN
   SELECT
      property_value
   INTO database_default_edition
   FROM
      database_properties
   WHERE
      property_name = 'DEFAULT_EDITION';

   EXECUTE IMMEDIATE 'alter session set edition = ' || database_default_edition;
END;
/

DECLARE
   insufficient_privileges EXCEPTION;
   PRAGMA exception_init ( -1031
   , insufficient_privileges );
BEGIN
   EXECUTE IMMEDIATE 'alter session set container = cdb$root';
EXCEPTION
   WHEN insufficient_privileges THEN NULL; -- ok to skip
END;
/

set termout on

@whoami
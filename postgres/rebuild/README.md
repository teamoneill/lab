[Team O'Neill Projects](http://teamoneill.org)
# [Postgres Database Project Rebuild](https://github.com/teamoneill/lab/tree/main/postgres/rebuild)

**Version:** 2025-10-17

**Purpose:** While rapidly developing changes in a branch database, this package completely synchronizes the database with your project's source control sandbox.

The intended purpose of this package is to serve a developer working on an isolated database, dedicated to a branch of the source code. 

**MIT License**

***Copyright (c) 2025 [Michael O'Neill](https://teamoneill.org)***

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

## Dependencies

PostgreSQL psql client (when `--conninfo` parameter is provided). This package has been developed and tested with version 17.4, [YMMV](https://www.urbandictionary.com/define.php?term=ymmv).

## Usage

````
$ rebuild.sh {parameters}
````

Both folder parameters are required to generate the rebuild SQL output.

To automatically execute the SQL output, valid conninfo is required.

Example
````
$ rebuild.sh --source-folder=~/source/repos/myproject/database_src -output-folder=/tmp/top_rebuild --product-owner=thetableowningrole --conninfo=postgresql://dbuser:mypwd@myhost:5432/mybranchdb
````

### Parameters

| <div style="width:250px">Parameter</div> | Meaning |
| -- | :-- |
| `--help`                        | Informational. Displays help and exits. |
| `--version`                     | Informational. Displays version and continues. |
| `--copyright`                   | Informational. Displays copyright and continues. |
| `--license`                     | Informational. Displays license and continues. |
| `--project-folder=`***{path}*** | Generate SQL input. The path to the database project folder. |
| `--output-folder=`***{path}***  | Generate SQL output. The path to the folder where generated files will be created (and overwritten). This does not have to be under your project folder (probably shouldn't be). |
| `--product-owner=`***{role}***  | The role that will own the objects created as part of the rebuild. |
| `--conninfo=`***{uri}***        | Execution of the generated SQL is requested. {uri} is in the form of `postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&param2=value2]`. |

-------------------------------------------------------------------------------

### Input
`--project-folder` 

This should have an expected structure. Review `project-template` folder as additional guidance.

````
{project_name} <---- --project-folder
  |-- setup_tasks               
  |    |-- {any folder structure}/{any filename}.sql  
  |-- database
  |    |-- {any folder structure}/{any filename}.sql                                            
  |-- schemas                  
  |    |-- {schema_name}
  |    |    |-- special
  |    |    |    |-- domains
  |    |    |    |    |-- {any folder structure}/{any filename}.sql  
  |    |    |    |-- types
  |    |    |    |    |-- {any folder structure}/{any filename}.sql
  |    |    |    |-- forward_declarations
  |    |    |    |    |-- {any folder structure}/{any filename}.sql  
  |    |    |-- general
  |    |    |    |-- {any folder structure}/{any filename}.sql              
  |    |-- ... (any number of {schema_name})              
  |-- breakdown_tasks           
  |    |-- {any folder structure}/{any filename}.sql
  |-- instance
````

### Rebuild processing occurs in this order for any *.sql files found:

1. `setup_tasks/` - Any custom administrative scripts to support the rebuild, e.g., logging, notifications
1. `database/` - Database-scope scripting, e.g., creating schemas and maintining their associated privileges. Instance-scope configuration is outside the scope of the rebuild.
1. `schemas/{each_schema_name}/special/` - Folders with special handling (in this order)
    1. `domains/` - Processed before general scripting
    1. `types/` - Processed before general scripting
    1. `forward_declarations/` - All schemas' forward_declarations are processed before any schema's general processing
1. `schemas/{each_schema_name}/general/` - Very freeform and flexible, where most of the source contol body of work lives
1. `breakdown_tasks/` - Any custom administrative scripts to support the rebuild, e.g., unit testing, continuous integration, custom dml, etc.

Note: `instance/` - Is not processed ([yet](https://github.com/teamoneill/lab/issues/6))


### Key Notes:

* Employ folder structure and folder/file naming prefixes to ensure any desired deterministic order of processing.
* Do not include foreign key constraints in the general folder. Use the `special/ref_constraints/`.
* This package ***will not*** implicitly drop any roles (or users) or make any privileges changes (but you can script as you require).
* However, this package ***will*** drop each {schema_name} cascade -- except `public`. If this behavior is not compatible with your database project processes, this package is not for you.
* Even when `schemas/public/` exists, the `public` schema is neither ***implicitly*** created, dropped, nor any objects contained by it dropped. Use of `public` schema is discouraged. `schemas/public/` *.sql files will be executed, however.
* When adding or removing roles and privileges for your database project, use the instance folder to capture this logic. The rebuild process does not consider this folder at this time ([but will soon](https://github.com/teamoneill/lab/issues/6))
* To support error-free processing of intra-schema referencing, all `schemas/{schema_name}/special/forward_declarations/` *.sql files are processed prior to any other schemas' `general/` *.sql files.
* Keep in mind that this package is very much a [GIGO](https://www.urbandictionary.com/define.php?term=gigo) architecture. Especially while you are experimenting, ensure that you are not using this in a vital database.
* While data can easily be included, anything significant is going to slow down the rebuild cycle. Either create conditional logic for large amounts of DML only in certain circumstances or handle in a seperate fashion from rebuild.

-------------------------------------------------------------------------------

## Output

`--output-folder=`*{path}*

### Primary Output

For successful executions:

| <div style="width:250px">File</div> | Meaning |
| -- | -- |
| rebuild.sql | The generated SQL |
| rebuild.log | Log of the generation and execution of rebuild.sql |

There are intermediary files that can help debug unsuccessful executions referenced in STDERR:

| <div style="width:250px">File</div> |  |
| -- | -- |
| `setup_tasks.sql` | Driven by `breakdown_tasks/` | 
| `database_scope.sql` | Driven by implicit drop of all `schemas/{schema}/` and `database/` |
| `special_initial_schema.sql` | Driven by `schemas/{schema}/special/[domains\|types\|forward_declarations]` |
| `general_schema.sql` | Driven by `schemas/{schema}/general/` |
| `special_final_schema.sql` | Driven by `schemas/{schema}/special/ref_constraints/` | 
| `breakdown_tasks.sql` | Driven by `breakdown_tasks/` |


-------------------------------------------------------------------------------

## Recommendations

### Execution is failing but the source is good
Except for the `{project-folder}/schemas/*/general/`, order may matter. Try using file name prefixes to drive the order deterministically.

Instead of
````
{project-folder}/setup_tasks/
  do_something_that_depends_on_first_task.sql
  this_is_the_first_task.sql
````
Try
````
{project-folder}/setup_tasks/
  100_this_is_the_first_task.sql
  200_do_something_that_depends_on_first_task.sql
````

### Executing .../general_schema.sql never succeeds but the source is good

This is important: Every DDL that has an IF NOT EXISTS option, or an OR REPLACE option should be employed in your source code.

For example
````
CREATE TABLE mytable ( ... )
````
Will result in a FATAL ERROR if multiple passes are necessary.

Instead
````
CREATE TABLE IF NOT EXISTS mytable ( ... )
````
Is multipass-compatible

### Executing .../general_schema.sql has too many passes but succeeds

This is the only intermediary file that will be run multiple iterations. Because the primary goal of the postgress/rebuild package is to take the source control as-it-is as much as possible, multiple passes may be necessary to complete the rebuild successfully.

Too much effort into reducing passes should not be expended. Very large projects with many passes will still execute in seconds. Re-thinking, setup/breakdown tasks that are DML heavy that aren't required until the DDL is solid, would be a good example of focus to increase productivity.

Note: because any \*.sql file in any schemas/*/general file structure may be executed multiple times, refrain from any unintended side effect scripting under general. Put such scripts in the setup_tasks or breakdown_tasks folder instead, which only get executed once per rebuild.

#### Examples requiring multiple passes

The rebuild is dependent upon the Linux `find` command, so that determines any process ordering.

#### Inter-schema dependencies

Given
````
{project-folder}/schemas/
  alpha/general/create_anyview_referencing_beta_anytable.sql    <---- Executes first
  betas/general/create_anytable_source.sql                      <---- Second
````
So two passes are required:

**Pass 1:** `create_anyview_referencing_beta_anytable.sql` will fail because the `beta.anytable` object does not ***yet*** exist, then
**Pass 2:** `create_anyview_referencing_beta_anytable.sql` succeeds and `create_anytable_source.sql` does not fail because it has the `CREATE TABLE IF NOT EXISTS anytable (...)` syntax.

Many inter-schema dependencies can be configured for single pass success by using the `{project-folder}/schemas/{schema}/special/forward_declarations` folder.

1. For every schema, the `forward_declarations` scripts are processed before any `{project-folder}/schemas/{schema}/general` scripts, and
1. They are only executed once.

Instead of
````
schemas/
  alpha/general/myview_using_beta_myfunction.sql
  beta/general/myfunction.sql
````
Try
````
schemas/
  alpha/general/myview_using_beta_myfunction.sql
  beta/
    general/myfunction.sql
    special/forward_declarations/myfunction_stub.sql
````
Resulting in the processing order of:
1. `myfunction_stub.sql`
1. `myview_using_beta_myfunction.sql`
1. `myfunction.sql`

#### Table hierarchies (`CREATE TABLE childtable (...) INHERITS parenttable`) within the same schema

Like the inter-schema dependencies example, it is possible the childtable creation script is processed before the partentable creation script. The rebuild will succeed after at least two passes, but you may want to reduce the number of passes.

Instead of
````
{project-folder}/schemas/{yourschema}/general/
  childtable.sql           <---- Executes first
  parenttable.sql          <---- Second
````
Try
````
{project-folder}/schemas/{yourschema}/general/
  parenttable.sql          <---- Executes first
  parenttable/
    childtable.sql         <---- Second
````
As long as the folder name containing the child table is the same as the parent file name (without the prefix) this will succeed in one pass.
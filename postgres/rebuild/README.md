[Team O'Neill Projects](http://teamoneill.org)
# [Postgres Database Project Rebuild](https://github.com/teamoneill/lab/tree/main/postgres/rebuild)

**Version:** 2025-05-26

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
$ rebuild.sh --source-folder=~/source/repos/myproject/database_src -output-folder=/tmp/top_rebuild --conninfo=postgresql://dbuser:mypwd@myhost:5432/mybranchdb
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
| `--conninfo=`***{uri}***        | Execution of the generated SQL is requested. {uri} is in the form of `postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&param2=value2]`. Connect as the product owner of the project|

-------------------------------------------------------------------------------

### Input
`--project-folder` 

This should have an expected structure. Review `project-template` folder as additional guidance. This folder must have three subfolders: setup, schemas, breakdown. The instance folder is for future use and is not currently part of the rebuild.

````
{project_name}    <---- --project-folder
  |-- setup
  |    |-- {any folder structure}/{any filename}.sql                                            
  |-- schemas                  
  |    |-- {any folder structure}/{any filename}.sql  
  |-- breakdown       
  |    |-- {any folder structure}/{any filename}.sql
  |-- instance
````

### Rebuild processing occurs in this order for any *.sql files found:

1. `setup/` - These scripts are executed once, before any `schemas` scripts. Candidates for setup scripts are:
    * dropping your schemas and recreating them (recommended)
    * any other custom administrative scripts to support the rebuild, e.g., logging, notifications
    * any forward declarations if you have circular references
    * while not required, extension, domain, and type declarations could reduce the number of passes for the schemas execution - but explicit ordering must be employed as this script will only be run once - and must succeed
1. `schemas/` - This is your core source for all schema objects. If you have multiple schemas, your scripting should contain schema syntax for the objects.
1. `breakdown/` - Any custom administrative scripts to support the rebuild, e.g., unit testing, continuous integration, custom dml, etc.

-------------------------------------------------------------------------------

## Output

`--output-folder=`*{path}*

### Primary Output

For successful executions:

| <div style="width:250px">File</div> | Meaning |
| -- | -- |
| rebuild.sql | The generated SQL - not it can be quite wordy if many passes are required |
| rebuild.log | Log of the generation and execution of rebuild.sql |


-------------------------------------------------------------------------------

## Recommendations

### setup/breakdown - Execution is failing but the source is good
Try using folder structure and/or file name prefixes to drive the order deterministically.

Instead of
````
{project-folder}/setup/
  do_something_that_depends_on_first_task.sql
  this_is_the_first_task.sql
````
Try
````
{project-folder}/setup/
  100_this_is_the_first_task.sql
  200_do_something_that_depends_on_first_task.sql
````

### Executing schemas never succeeds but the source is good

1. Are you dropping cascade your product's schema(s), and recreating them in the setup folder? It is recommended that you do so for predictable results during a rebuild.
1. Does your product have multiple schemas, but the script source has no schema prefix in create statements? You are going to need to either:
    * introduce schema prefixes into your source code (not always desirable), or
    * use multiple project folders and multiple rebuilds (easy enough to script that)

### Executing schemas has too many passes but succeeds

Because the primary goal of the postgress/rebuild package is to take the source control as-it-is as much as possible, multiple passes may be necessary to complete the rebuild successfully, e.g., creating objects *out of order*.

Too much effort into reducing passes should not be expended. Very large projects with many passes will still execute in seconds. Re-thinking, setup/breakdown scripts that are DML heavy that aren't required until the DDL is solid, would be a good example of focus to decrease rebuild execution time.

***Note:*** *Because any \*.sql file in the schemas folder may be executed multiple times, refrain from any unintended side effect scripting under general. Put such scripts in the setup or breakdown folders instead, which only get executed once per rebuild.*

#### Examples requiring multiple passes

The rebuild is dependent upon the Linux `find` command, so that determines any process ordering.

#### Inter-schema dependencies

Given
````
{project-folder}/schemas/
  create_anyview_referencing_betaschema_anytable.sql    <---- Executes first
  create_betaschema_anytable_source.sql                 <---- Second
````
So two passes are required:

**Pass 1:** `create_anyview_referencing_beta_anytable.sql` will fail because the `beta.anytable` object does not ***yet*** exist, then
**Pass 2:** `create_anyview_referencing_beta_anytable.sql` now succeeds.

***Note:*** *Forward declarations should not be necessary, unless you have circular references that can never be resolved by multiple passes. If forward declarations are necessary, put them in the setup folder.*
````

#### Table hierarchies (`CREATE TABLE childtable (...) INHERITS parenttable`) within the same schema

Like the inter-schema dependencies example, it is possible the child table creation script is processed before the parent table creation script. The rebuild will succeed after at least two passes, but you may want to reduce the number of passes.

Instead of
````
{project-folder}/schemas/
  childtable.sql           <---- Executes first
  parenttable.sql          <---- Second
````
Try
````
{project-folder}/schemas/
  parenttable.sql          <---- Executes first
  parenttable/
    childtable.sql         <---- Second
````
As long as the folder name containing the child table is the same as the parent file name (without the prefix) this will succeed in one pass.
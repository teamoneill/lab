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

`$ rebuild.sh` {parameters}

Both folder parameters are required to generate the rebuild SQL older.

To automatically execute generated rebuild SQL, valid conninfo is required.

### Example:
````
$ rebuild.sh --source-folder=~/source/repos/myproject/database_src -output-folder=/tmp/top_rebuild --product-owner=thetableowningrole --conninfo=postgresql://dbuser:mypwd@myhost:5432/mybranchdb
````

## Parameters

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

## Input
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

1. `setup_tasks` - Any custom administrative scripts to support the rebuild, e.g., logging, notifications
1. `database` - Database-scope scripting, e.g., creating schemas and maintining their associated privileges. Instance-scope configuration is outside the scope of the rebuild.
1. `schemas`/{each_schema_name}/`special` - Folders with special handling (in this order)
    1. `domains` - Processed before general scripting
    1. `types` - Processed before general scripting
    1. `forward_declarations` - All schemas' forward_declarations are processed before any schema's general processing (optional)
1. `schemas`/{each_schema_name}/`general` - Very freeform and flexible, where most of the source contol body of work lives
1. `breakdown_tasks` - Any custom administrative scripts to support the rebuild, e.g., unit testing, continuous integration, custom dml, etc.

`instance` - Is not processed


### Notes:

* Employ folder structure and folder/file naming prefixes to ensure any desired deterministic order of processing. Recommendations:
  * Create a folder structure that mimics your table inheritence structure (makes logical sense and may improve rebuild processing time)
  * Avoid circular references between objects, same or cross-schema. Your only remedy is use of the special forward_declarations folder
  * Do not include foreign key constraints in the general folder. Use the special ref_constraints folder
* This package ***will not*** implicitly drop any roles or users.
* However, this package ***will*** drop {each_schema_name} cascade. If this behavior is not compatible with your database project processes, this package is not for you.
* Even when `schemas/public` folder exists, the `public` schema is neither ***implicitly*** created, dropped, nor any objects contained by it dropped. Use of `public` schema is discouraged. `schemas/public` *.sql files will be executed, however.
* When adding or removing roles for your database project, use the instance folder to capture this logic. The rebuild process does not consider this folder. 
* To support error-free processing of intra-schema referencing, all `schemas`/{schema_name}/`forward_source` *.sql files are processed prior to any other schemas' *.sql files.

* Keep in mind that this package is very much a [GIGO](https://www.urbandictionary.com/define.php?term=gigo) architecture. Especially while you are experimenting, ensure that you are not using this in a vital database.
* While data can easily be included, anything significant is going to slow down the rebuild cycle execution. Either create conditional logic for large amounts of DML only in certain circumstances or handle in a seperate fashion from rebuild.

-------------------------------------------------------------------------------

## Output
`--output-folder`

The rebuild.log file can be helpful for troubleshooting. The various generated *.sql files are not intended for individual manual execution.
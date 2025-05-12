[Team O'Neill Projects](http://teamoneill.org)
# [Postgres Database Project Rebuild](https://github.com/teamoneill/lab/tree/main/postgres/rebuild)

**Version:** (pre-release)

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
$ rebuild.sh --source-folder=~/source/repos/myproject/database_src -output-folder=/tmp/top_rebuild --conninfo=postgresql://dbuser:mypwd@myhost:5432/mybranchdb
````

## Parameters

| <div style="width:250px">Parameter</div> | Meaning |
| -- | :-- |
| `--help`                        | Informational. Displays help and exits. |
| `--version`                     | Informational. Displays version and continues. |
| `--copyright`                   | Informational. Displays copyright and continues. |
| `--license`                     | Informational. Displays license and continues. |
| `--project-folder=`***{path}*** | Generate SQL input. The path to the database project folder. |
| `--output-folder=`***{path}***  | Generate SQL output. The path to the folder where generated files will be created (and overwritten).|
| `--conninfo=`***{uri}***        | Execution of the generated SQL is requested. {uri} is in the form of `postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&param2=value2]`.  If uri value is ommitted, all PG* environment variables must be set. This connection should have sufficient privileges to all roles, schemas and system privileges to execute all the *.sql files of the project|

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
  |    |    |-- forward_source
  |    |    |    |-- {any folder structure}/{any filename}.sql  
  |    |    |-- source
  |    |    |    |-- {any folder structure}/{any filename}.sql              
  |    |-- ... (any number of {schema_name})              
  |-- breakdown_tasks           
  |    |-- {any folder structure}/{any filename}.sql
  |-- output
````

### Implicitly invoked by `build.sql` in this order:
The package will process all *.sql files found under:
1. `setup_tasks` - Any custom administrative scripts to support the rebuild, e.g., logging, notifications
1. `database` - Database-scope scripting, e.g., roles, users, schemas, system privilege grants, etc. Including CREATE SCHEMAs here is almost certainly necessary.
1. `schemas`/{each_schema_name}/`forward_source` - All schemas' forward_source is processed before any schemas' source
1. `schemas`/{each_schema_name}/`source` - Traditional per-object database source files
1. `breakdown_tasks` - Any custom administrative scripts to support the rebuild, e.g., unit testing, continuous integration, etc.

### Notes:
* Employ folder structure and folder/file naming prefixes to ensure any desired deterministic order of processing.
* This package ***will not*** implicitly drop any roles or users.
* However, this package ***will*** drop {each_schema_name} cascade. If this behavior is not compatible with your database project processes, this package is not for you.
* Even when `schemas/public` folder exists, the `public` schema is neither ***implicitly*** created, dropped, nor any objects contained by it dropped. Use of `public` schema is discouraged. `schemas/public` *.sql files will be executed, however.
* When removing roles, users, or schemas from your database project - manually drop them from the database(s) as necessary (or include logic to `setup_tasks`/`database`/`breakdown_tasks` to do so)
* To support error-free processing of intra-schema referencing, all `schemas`/{schema_name}/`forward_source` *.sql files are processed prior to any other schemas' *.sql files.
* Recommended: for schema `forward_source` and `source` *.sql files, omit schema in the definitions. It is not necessary or desirable to include schema in the definitions.
* Keep in mind that this package is very much a [GIGO](https://www.urbandictionary.com/define.php?term=gigo) architecture. Especially while you are experimenting, ensure that you are not using this in a vital database.
* While data can easily be included, anything significant is going to slow down the rebuild cycle execution. Either create conditional logic for large amounts of DML only in certain circumstances or handle in a seperate fashion from rebuild.

-------------------------------------------------------------------------------

## Output
`--output-folder`

| <div style="width:250px">File</div> | Purpose |
| -- | -- |
| `rebuild.sql` | The generated script. When executed, implicitly or explicitly, this script synchronizes the database with project-folder. When `--connect-url` parameter is provided, executed automatically |
| `rebuild.log` | The logging of the execution of `rebuild.sql` (if executed) |
| `rebuild.log.error` | Any execution NOTICEs, WARNINGs, or ERRORs |
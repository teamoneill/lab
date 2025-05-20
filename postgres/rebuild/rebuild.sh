#!/bin/bash

script_start="$(date +%s.%N)"
log_date=`date +%FT%T`

echo "INFO: Script started - $log_date"

display_fatal_error_default_action() {
    echo "ACTION: Display help (rebuild.sh --help) and/or review README.md5"
}
display_fatal_error() {
    echo "FATAL: $1"
}

display_version() {
    echo "Team O'Neill Projects - Postgres Schema Rebuild (2025-10-17)"
}

display_copyright() {
    echo "Copyright (c) 2025 Michael O'Neill - https://teamoneill.org"
}

display_license() {
    echo "
MIT License

Copyright (c) 2025 Michael O'Neill - https://teamoneill.org

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
OUT OF OR IN conninfoION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"
}

display_help() {
    echo "
Purpose:
  This script generates the script file necessary to synchronize a
  database from database project source control sandbox. If the conninfo
  parameter is provided, the generated script is executed as well.

Usage:
  rebuild.sh {parameters}

Parameters:
  --help
      Displays help information and exits.

  --version|--copyright|--license
      Displays corresponding information and continues.

  --project-folder={path}
      Location of database project source code. See README for guidance on structure expected.
      Required for output.

  --output-folder={path}
      Location of generated SQL. Required for output.

  --product-owner={role}
      The role that owns the objects of the rebuild. Required for output.

  --conninfo={uri}
      Execution of generated SQL is requested.
      The executing role must have SET privilege to the product-owner 

See README for more detailed guidance.
"
}

display_horizontal_rule() {
    echo "------------------------------------------------------------"
}

step_label=""
declare -i step=0
display_step_header() {
    step=$step+1
    display_horizontal_rule
    echo "-- Step ($step) - $step_label"
    display_horizontal_rule
}

# baseline state
information_requested="false"
output_requested="false"
execution_requested="false"
project_folder=""
output_folder=""
product_owner=""
conninfo=""

# parameter processing
for i in "$@"; do
    case $i in
        --help)
        display_help
        information_requested="true"
        shift
        ;;
        --version)
        display_version
        information_requested="true"
        shift
        ;;
        --copyright)
        display_copyright
        information_requested="true"
        shift
        ;;
        --license)
        display_license
        information_requested="true"
        shift
        ;;
        --project-folder=*)
        project_folder="${i#*=}"
        output_requested="true"
        shift
        ;;
        --output-folder=*)
        output_folder="${i#*=}"
        output_requested="true"
        shift
        ;;
        --product-owner=*)
        product_owner="${i#*=}"
        output_requested="true"
        shift
        ;;
        --conninfo=*)
        conninfo="${i#*=}"
        output_requested="true"
        execution_requested="true"
        shift
        ;;
        --execute)
        output_requested="true"
        execution_requested="true"
        shift
        ;;
        -*|--*)
        display_fatal_error "Unknown parameter $i"
        display_fatal_error_default_action
        exit 1
        ;;
        *)
        ;;
    esac
done

if [[ "$output_requested" == "false" && "$information_requested" == "true" ]]; then
    exit 0
elif [[ "$output_requested" == "false" && "$information_requested" == "false" ]]; then
    display_fatal_error "Required parameter(s) missing"
    display_fatal_error_default_action
    exit 1
fi

if [ "$output_requested" = "true" ]; then
    # check if required source folder parameter is missing
    if [[ -n "$project_folder" && -n "$output_folder" && -n "$product_owner" ]]; then

        #TODO check that source folder exists and has expected structure
        #TODO check that output folder exists

        echo "INFO: Input - $project_folder"
        echo "INFO: Output - $output_folder"
        echo "INFO: Product Owner - $product_owner"
    else
        display_fatal_error "required parameter(s) for output missing"
        display_fatal_error_default_action
        exit 1
    fi
fi

echo "REQUESTED: Generate rebuild SQL"

# output baseline variables
setup_tasks=$output_folder/setup_tasks.sql
database_scope=$output_folder/database_scope.sql
special_initial_schema=$output_folder/special_initial_schema.sql
general_schema=$output_folder/general_schema.sql
special_final_schema=$output_folder/special_final_schema.sql
breakdown_tasks=$output_folder/breakdown_tasks.sql
rebuild_sql=$output_folder/rebuild.sql
todo=$output_folder/todo.txt
log=$output_folder/rebuild.log

# initialize output files
echo "" > $setup_tasks
echo "" > $database_scope
echo "" > $special_initial_schema
echo "" > $general_schema
echo "" > $special_final_schema
echo "" > $breakdown_tasks
echo "" > $todo
echo "" > $log

step_label="SETUP TASKS"
display_step_header >> $setup_tasks
echo "INFO: Generating $step_label - $setup_tasks"
echo "SET client_min_messages TO ERROR;" >> $setup_tasks
echo "SET ROLE $product_owner;" >>$breakdown_tasks 
for sql_script in $(find $project_folder/setup_tasks/*.sql -type f | sort -n); do
    echo "\\echo $sql_script" >> $setup_tasks
    cat $sql_script >> $setup_tasks
    echo "" >> $setup_tasks
done 2>/dev/null

step_label="DATABASE SCOPE"
display_step_header >> $database_scope
echo "INFO: Generating $step_label - $database_scope"
echo "SET client_min_messages TO ERROR;" >> $database_scope
echo "SET ROLE $product_owner;" >>$breakdown_tasks 
echo "-- explicitly dropping schemas" >> $database_scope
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    schema_lower_case=$( tr '[:upper:]' '[:lower:]' <<<"$(basename $schema)" )
    if [ "$schema_lower_case" == "public" ]; then
        echo "-- intentionally skipping public schema" >> $database_scope
        echo "-- any errors resulting from creating public schema objects must be resolved manually" >>$database_scope
    else
        echo "DROP SCHEMA IF EXISTS $(basename $schema) CASCADE;" >> $database_scope
    fi
done 2>/dev/null
echo "-- processing database folder" >> $database_scope
for sql_script in $(find $project_folder/database -type f -name "*.sql" | sort -n); do
    echo "\\echo $sql_script" >> $database_scope
    cat $sql_script >> $database_scope
    echo "" >> $database_scope
done 2>/dev/null
echo "" >> $database_scope
echo "-- implicit create schemas, in case they aren't explicitly declared in database folder" >> $database_scope
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    schema_lower_case=$( tr '[:upper:]' '[:lower:]' <<<"$(basename $schema)" )
    if [ "$schema_lower_case" == "public" ]; then
        echo "-- intentionally skipping public schema" >> $database_scope
    else
        echo "CREATE SCHEMA IF NOT EXISTS $(basename $schema);" >> $database_scope
    fi
done 2>/dev/null

echo "INFO: SCHEMA SCOPE (SPECIAL INITIAL) - $special_initial_schema"
display_step_header >> $special_initial_schema
echo "-- processing schemas special folders" >> $special_initial_schema
echo "SET client_min_messages TO ERROR;" >> $special_initial_schema
echo "SET ROLE $product_owner;" >> $special_initial_schema
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    echo "SET SEARCH_PATH=$(basename $schema);" >>$special_initial_schema

    # list of folders with DDL that must be run before general schema folder and run only once
    declare -a folder_names=("domains" "types") 
    for folder in "${folder_names[@]}"; do
        step_label="$(basename $schema)/special/$folder"
        display_step_header >> $special_initial_schema
        for sql_script in $(find $schema/special/$folder -type f -name "*.sql" | sort -n); do
            echo "\\echo $sql_script" >> $special_initial_schema
            cat $sql_script >> $special_initial_schema
            echo "" >> $special_initial_schema
        done 2>/dev/null
        echo "" >> $special_initial_schema
    done 2>/dev/null
    step_label="schemas/*/special/forward_declarations"
    display_step_header >> $special_initial_schema
    for sql_script in $(find $project_folder/schemas/*/special/forward_declarations -type f -name "*.sql" | sort -n); do
        echo "\\echo $sql_script" >> $special_initial_schema
        cat $sql_script >> $special_initial_schema
        echo "" >> $special_initial_schema
    done 2>/dev/null
done 2>/dev/null

step_label="SCHEMAS SCOPE (GENERAL MULTIPASS)"
display_step_header >> $general_schema
echo "INFO: Generating $step_label - $general_schema"
echo "-- processing schemas folder" >> $general_schema
echo "SET client_min_messages TO ERROR;" >> $general_schema
echo "SET ROLE $product_owner;" >> $general_schema
echo "SET search_path=sportball;" >>$general_schema
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    echo "set search_path=$(basename $schema);" >>$general_schema

    for sql_script in $(find $schema/general -type f -name "*.sql" | sort -n); do
            echo "\\echo $sql_script" >> $general_schema
            cat $sql_script >> $general_schema
            echo "" >> $general_schema
    done 2>/dev/null
    echo "" >> $general_schema

done 2>/dev/null

echo "INFO: SCHEMA SCOPE (SPECIAL FINAL) - $special_final_schema"
display_step_header >> $special_final_schema
echo "-- processing schemas special folders" >> $special_final_schema
echo "SET client_min_messages TO ERROR;" >> $special_final_schema
echo "SET ROLE $product_owner;" >> $special_final_schema
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    echo "SET SEARCH_PATH=$(basename $schema);" >>$special_final_schema
    # list of folders with DDL that must be run after general schema folder and run only once
    declare -a folder_names=("ref_constraints")
    for folder in "${folder_names[@]}"; do
        step_label="special/$folder"
        display_step_header >> $special_final_schema

        for sql_script in $(find $schema/special/$folder -type f -name "*.sql" | sort -n); do
            echo "\\echo $sql_script" >> $special_final_schema
            cat $sql_script >> $special_final_schema
            echo "" >> $special_final_schema
        done 2>/dev/null
        echo "" >> $special_final_schema
    done 2>/dev/null
done 2>/dev/null

step_label="BREAKDOWN TASKS"
display_step_header >> $breakdown_tasks
echo "INFO: Generating $step_label - $breakdown_tasks"
echo "-- processing breakdown_tasks folder" >> $breakdown_tasks
echo "SET client_min_messages TO ERROR;" >> $breakdown_tasks
echo "SET ROLE $product_owner;" >>$breakdown_tasks 
for sql_script in $(find $project_folder/breakdown_tasks -type f -name "*.sql" | sort -n); do
    echo "\\echo $sql_script" >> $breakdown_tasks
    cat $sql_script >> $breakdown_tasks
    echo "" >> $breakdown_tasks
done 2>/dev/null

step_label="TODO"
display_step_header >> $todo
echo "INFO: Generating $step_label - $todo"
grep -r -e "TODO" $project_folder --exclude-dir $output_folder | sed "s/${project_folder//\//\\/}/.../g" >> $todo

echo "INFO: Generation complete"

if [ "$execution_requested" == "true" ]; then
    echo "REQUESTED: Execute generated SQL"
    
    echo "INFO: Executing $setup_tasks"
    psql $conninfo -v ON_ERROR_STOP=1 --file=$setup_tasks --echo-queries >>$log
    if [ $? -eq 0 ]; then
        cat $setup_tasks >> $rebuild_sql
    else
        echo "FATAL: output $(basename $setup_tasks) script did not succeed"
        echo "ACTION: review ERROR, resolve related source code, and rereun"
        exit 1
    fi

    echo "INFO: Executing $database_scope"
    psql $conninfo -v ON_ERROR_STOP=1 --file=$database_scope --echo-queries >>$log
    if [ $? -eq 0 ]; then
        cat $database_scope >> $rebuild_sql
    else
        echo "FATAL: output $(basename $database_scope) script did not succeed"
        echo "ACTION: review ERROR, resolve related source code, and rereun"
        exit 1
    fi

    echo "INFO: Executing $special_initial_schema"
    psql $conninfo -v ON_ERROR_STOP=1 --file=$special_initial_schema --echo-queries >>$log
    if [ $? -eq 0 ]; then
        cat $special_initial_schema >> $rebuild_sql
    else
        echo "FATAL: output $(basename $special_initial_schema) script did not succeed"
        echo "ACTION: review ERROR, resolve related source code, and rereun"
        exit 1
    fi

    echo "INFO: Executing $general_schema"

    temp_log=$log.tmp
    echo "" > $temp_log
    declare -i passes=0
    declare -i error_count=1000000
    declare -i new_error_count=0
    while [ $error_count -gt 0 ]; do
        passes=$((passes+1));
        psql $conninfo -v ON_ERROR_STOP=0 --file=$general_schema --echo-queries  >$temp_log 2>&1
        new_error_count=`grep "ERROR:" $temp_log | wc -l`
        echo "INFO: pass $passes - $new_error_count ERRORS"
        if [ $new_error_count -eq $error_count ]; then
            echo "(multipass error resolution stopped progressing)"
            # there is no progress being made, time to stop on error and spit out log
            psql $conninfo -v ON_ERROR_STOP=1 --file=$general_schema --echo-queries >$log
            echo "FATAL: schema scope multipass processing cannot resolve this ERROR"
            echo "ACTION: review ERROR, resolve related source code, and rereun"
            rm $temp_log >/dev/null 2>&1
            exit 1
        else
            error_count=`grep "ERROR:" $temp_log | wc -l`
            cat $general_schema >> $rebuild_sql
        fi
    done
    cat $temp_log >> $log
    rm $temp_log >/dev/null 2>&1
    if [ $passes -eq 1 ]; then
        echo "INFO: AMAZING! Only one pass was required to succeed."
    else
        echo "INFO: $passes passes were required to succeed. See README for suggestions to succeed in one pass."
        # TODO maybe make recommendation(s) if passes is greater than one
    fi

    echo "INFO: Executing $special_final_schema"
    psql $conninfo -v ON_ERROR_STOP=1 --file=$special_final_schema --echo-queries >>$log
    if [ $? -eq 0 ]; then
        cat $special_final_schema >> $rebuild_sql
    else
        echo "FATAL: output $(basename $special_final_schema) script did not succeed"
        echo "ACTION: review ERROR, resolve related source code, and rereun"
        exit 1
    fi

    echo "INFO: Executing $breakdown_tasks"
    psql $conninfo -v ON_ERROR_STOP=1 --file=$breakdown_tasks --echo-queries >>$log
    if [ $? -eq 0 ]; then
        cat $breakdown_tasks >> $rebuild_sql
    else
        echo "FATAL: output $(basename $breakdown_tasks) script did not succeed"
        echo "ACTION: review ERROR, resolve related source code, and rereun"
        exit 1
    fi

fi

echo "EXIT: Script completed normally - `date +%FT%T` ($(echo "$(date +%s.%N)-$script_start" | bc) seconds)"
exit 0
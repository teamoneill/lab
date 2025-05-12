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
    echo "Team O'Neill Projects - Rebuild (pre-release)"
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

  --output-folder={path}
      Location of generated SQL.

  --conninfo={uri}
      Execution of generated SQL is requested. 

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
    if [[ -n "$project_folder" && -n "$output_folder" ]]; then

        #TODO check that source folder exists and has expected structure
        #TODO check that output folder exists

        echo "INFO: Input - $project_folder"
        echo "INFO: Output - $output_folder"
    else
        display_fatal_error "folder parameter(s) missing"
        display_fatal_error_default_action
        exit 1
    fi
fi

# output baseline variables
rebuild_sql=$output_folder/rebuild.sql
rebuild_log=$output_folder/rebuild.log
rebuild_error=$rebuild_log.error

# initialize output files
touch $rebuild_sql >/dev/null 2>&1
echo "--$log_date" > $rebuild_sql
touch $rebuild_log >/dev/null 2>&1
echo "$log_date" > $rebuild_log
touch $rebuild_error >/dev/null 2>&1
echo "$log_date" > $rebuild_error

echo "INFO: Generating rebuild SQL - $rebuild_sql"

step_label="SETUP TASKS"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for sql_script in $(find $project_folder/setup_tasks/*.sql -type f | sort -n); do
    echo "-- $(basename $sql_script)" >> $rebuild_sql
    cat $sql_script >> $rebuild_sql
    echo "" >> $rebuild_sql
    echo "" >> $rebuild_sql
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="DROP SCHEMAS"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    schema_lower_case=$( tr '[:upper:]' '[:lower:]' <<<"$(basename $schema)" )
    if [ "$schema_lower_case" == "public" ]; then
        echo "-- intentionally skipping public schema" >> $rebuild_sql
    else
        echo "DROP SCHEMA $(basename $schema) CASCADE;" >> $rebuild_sql
    fi
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="DATABASE SCOPE"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for sql_script in $(find $project_folder/database -type f -name "*.sql" | sort -n); do
    echo "-- $sql_script" >> $rebuild_sql
    cat $sql_script >> $rebuild_sql
    echo "" >> $rebuild_sql
    echo "" >> $rebuild_sql
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="SCHEMAS FORWARD SOURCE"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    for sql_script in $(find $schema/forward_source -type f -name "*.sql" | sort -n); do
        echo "set search_path = \"$(basename $schema)\",\"\$user\";" >> $rebuild_sql
        echo "-- $sql_script" >> $rebuild_sql
        echo "-- $sql_script" >> $rebuild_sql
        cat $sql_script >> $rebuild_sql
        echo "" >> $rebuild_sql
        echo "" >> $rebuild_sql
    done 2>/dev/null
    echo "" >> $rebuild_sql
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="SCHEMAS SOURCE"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for schema in $(find $project_folder/schemas -type d -maxdepth 1 -not -path $project_folder/schemas | sort -n); do
    for sql_script in $(find $schema/source -type f -name "*.sql" | sort -n); do
        echo "set search_path = \"$(basename $schema)\",\"\$user\";" >> $rebuild_sql
        echo "-- $sql_script" >> $rebuild_sql
        cat $sql_script >> $rebuild_sql
        echo "" >> $rebuild_sql
        echo "" >> $rebuild_sql
    done 2>/dev/null
    echo "" >> $rebuild_sql
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="BREAKDOWN TASKS"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
for sql_script in $(find $project_folder/breakdown_tasks -type f -name "*.sql" | sort -n); do
    echo "-- $(basename $sql_script)" >> $rebuild_sql
    cat $sql_script >> $rebuild_sql
    echo "" >> $rebuild_sql
    echo "" >> $rebuild_sql
done 2>/dev/null
echo "" >> $rebuild_sql

step_label="TODO"
display_step_header >> $rebuild_sql
echo "INFO: Appending $step_label"
echo "" >> $rebuild_sql
echo "" >> $rebuild_sql
echo "/*" >> $rebuild_sql
grep -r -e "^--TODO" $project_folder --exclude-dir $output_folder | sed "s/${project_folder//\//\\/}/.../g" >> $rebuild_sql
echo "*/" >> $rebuild_sql

echo "INFO: Generation complete"

if [ "$execution_requested" == "true" ]; then
    echo "INFO: Executing rebuild SQL"
    
    #psql $conninfo --file=$rebuild_sql --log-file=$rebuild_log --output=/dev/null 2>$rebuild_error
    psql $conninfo --file=$rebuild_sql --echo-queries >$rebuild_log 2>$rebuild_error
    
    if [ $? -ne 0 ]; then
        echo "FATAL: psql ON_ERROR_STOP"
        echo "ACTION: resolve ERROR and rerun"
        echo ""
        cat $rebuild_error
        exit 1
    else
        echo "INFO: Execution complete - $rebuild_log"
    fi
fi

if [ "$execution_requested" == "true" ]; then
    touch $rebuild_error >/dev/null 2>&1
    
    if [ `grep "ERROR:" $rebuild_error | wc -l` -gt 0 ]; then
        echo "WARNING: Errors occurred"
        echo "ACTION: Review NOTICEs and resolve ERRORs before rerunning"
        echo ""
        cat $rebuild_error
    else
        echo "INFO: Congratulations! No execution errors!"
    fi
fi

echo "EXIT: Script complete - `date +%FT%T` ($(echo "$(date +%s.%N)-$script_start" | bc) seconds)"
exit 0
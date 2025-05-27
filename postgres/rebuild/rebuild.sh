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
    echo "Team O'Neill Projects - Postgres Schema Rebuild (2025-05-26)"
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
      Must contain setup, breakdown, schemas folders.

  --output-folder={path}
      Location of generated SQL. Required for output.

  --conninfo={uri}
      Execution of generated SQL is requested.
      Execute as the product owner.

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
        display_fatal_error "required parameter(s) for output missing"
        display_fatal_error_default_action
        exit 1
    fi
fi

# output baseline variables
rebuild_sql=$output_folder/rebuild.sql
todo=$output_folder/todo.txt
log=$output_folder/rebuild.log


# initialize output files
echo "" > $rebuild_sql
echo "" > $log
echo "" > $todo

if [ "$execution_requested" == "true" ]; then

    echo -n "INFO: Executing setup folder..."
    for sql_script in $(find $project_folder/setup/*.sql -type f | sort -n); do
        echo "\i $sql_script" >> $rebuild_sql
        psql $conninfo -v ON_ERROR_STOP=0 --file=$sql_script --echo-queries >>$log 2>&1
        if [ $? -ne 0 ]; then
            cat $log
            echo "FATAL: setup_tasks failed"
            echo "ACTION: review rebuild.log and fix setup scripts to succeed"
            exit 1
        fi
    done 2>/dev/null
    echo "(completed successfully)"

    echo -n "INFO: Executing schemas folder..."
    temp_log=$log.tmp
    declare -i passes=0
    declare -i error_count=-1
    declare -i prior_error_count=-1
    final_pass="false"
    while [ $error_count -ne 0 ]; do
        echo "" > $temp_log
        passes=$((passes+1));
        echo -n "."
        for sql_script in $(find $project_folder/schemas -type f -name "*.sql"); do
            echo "\i $sql_script" >> $rebuild_sql
            echo $sql_script >>$temp_log
            psql $conninfo -v ON_ERROR_STOP=0 --file=$sql_script --echo-queries  >>$temp_log 2>&1
        done

        error_count=`grep '^psql:.*ERROR:.*' $temp_log | grep -v 'already exists' | wc -l`
        
        if [ $error_count -eq 0 ]; then
            echo "(completed successfully in $passes passes)"
            cat $temp_log >> $log
            rm $temp_log >/dev/null 2>&1
            break;
        fi

        if [ $final_pass == "true" ]; then
            echo ""
            grep '^psql:.*ERROR:.*' $temp_log | grep -v 'already exists' 
            echo "FATAL: schemas failed during $passes passes with $error_count errors unresolved"
            cat $temp_log >> $log
            rm $temp_log >/dev/null 2>&1
            exit 1;
        fi

        if [ $error_count -eq $prior_error_count ]; then
            final_pass="true"
        fi
        prior_error_count=$error_count
    done

    echo -n "INFO: Executing breakdown folder..."
    for sql_script in $(find $project_folder/breakdown/*.sql -type f | sort -n); do
        echo "\i $sql_script" >> $rebuild_sql
        psql $conninfo -v ON_ERROR_STOP=0 --file=$sql_script --echo-queries >>$log 2>&1
        if [ $? -ne 0 ]; then
            echo ""
            grep '^psql:.*ERROR:.*' $temp_log | grep -v 'already exists' 
            echo "FATAL: breakdown script(s) failed"
            echo "ACTION: review rebuild.log and fix breakdown script(s)"
            exit 1
        fi
    done 2>/dev/null
    echo "(completed successfully)"

fi

echo "EXIT: Script completed normally - `date +%FT%T` ($(echo "$(date +%s.%N)-$script_start" | bc) seconds)"
exit 0
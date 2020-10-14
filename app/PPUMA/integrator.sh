#!/bin/bash

WORKFLOW="$1"
INFILE="$2"
JOB_DIR="$3"
# JOB_ID="$4"
FEATURE_INFO_INFILE="$4"

# Used for error handling
INFILE_BASENAME="$(basename $INFILE)"
LOG_ERROR="$JOB_DIR/log_error.json"

WF_LEN=$(expr ${#WORKFLOW} - 1)


for MOD_I in $(seq 0 $WF_LEN)
do
    MOD_NUM=${WORKFLOW:MOD_I:1}

    if [ $MOD_NUM == '1' ]
    then
        python "$PWD/app/PPUMA/pyModules/Tagger.py" -i "$INFILE" -c "$JOB_DIR/Tagger.ini" -od "$JOB_DIR"
        
        # Handle errors
        STATUS_CODE=$?
        
        if [ $STATUS_CODE -eq 1 ]; then
            echo '{"Module": "Tagger", "StatusCode": 1, "Message": "An error occurred during execution. Please, check the parameters"}' > "$LOG_ERROR"
            exit 1
        
        elif [ $STATUS_CODE -eq 2 ]; then
            echo '{"Module": "Tagger", "StatusCode": 2, "Message": "An error occurred when openning '$INFILE_BASENAME'. Please, check its format"}' > "$LOG_ERROR"
            exit 2

        elif [ $STATUS_CODE -eq 3 ]; then
            echo '{"Module": "Tagger", "StatusCode": 3, "Message": "Column containing compound names was not found in '$INFILE_BASENAME'"}' > "$LOG_ERROR"
            exit 3
        fi

        INFILE="$JOB_DIR/$(cat "$JOB_DIR/Tagger.ini" | awk -F ' = ' '/^OutputName = / {print $2}')"
        
    fi

    if [ $MOD_NUM == '2' ]
    then
        python "$PWD/app/PPUMA/pyModules/Mod.py" -i "$INFILE" -pr "$JOB_DIR/REname.ini"  -od "$JOB_DIR" -re "$JOB_DIR/regex.ini"

        # Handle errors
        STATUS_CODE=$?
        
        if [ $STATUS_CODE -eq 1 ]; then
            echo '{"Module": "REname", "StatusCode": 1, "Message": "An error occurred during execution. Please, check the parameters"}' > "$LOG_ERROR"
            exit 4
        
        elif [ $STATUS_CODE -eq 2 ]; then
            echo '{"Module": "REname", "StatusCode": 2, "Message": "An error occurred when openning '$INFILE_BASENAME'. Please, check its format"}' > "$LOG_ERROR"
            exit 5

        elif [ $STATUS_CODE -eq 3 ]; then
            echo '{"Module": "REname", "StatusCode": 3, "Message": "Column containing compound names was not found in '$INFILE_BASENAME'"}' > "$LOG_ERROR"
            exit 6

        elif [ $STATUS_CODE -eq 4 ]; then
            echo '{"Module": "REname", "StatusCode": 4, "Message": "An error occurred when applying regular expressions. Please, check them"}' > "$LOG_ERROR"
            exit 7
        fi

        INFILE=$JOB_DIR/$(cat $JOB_DIR/REname.ini | awk -F ' = ' '/^OutputName = / {print $2}')
    
    fi

    if [ $MOD_NUM == '3' ]
    then
        python "$PWD/app/PPUMA/pyModules/Table.py" -i "$INFILE" -c "$JOB_DIR/rowMerger.ini" -od "$JOB_DIR"

        # Handle errors
        STATUS_CODE=$?
        
        if [ $STATUS_CODE -eq 1 ]; then
            echo '{"Module": "RowMerger", "StatusCode": 1, "Message": "An error occurred during execution. Please, check the parameters"}' > "$LOG_ERROR"
            exit 8
        
        elif [ $STATUS_CODE -eq 2 ]; then
            echo '{"Module": "RowMerger", "StatusCode": 2, "Message": "An error occurred when openning '$INFILE_BASENAME'. Please, check its format"}' > "$LOG_ERROR"
            exit 9

        elif [ $STATUS_CODE -eq 3 ]; then
            echo '{"Module": "RowMerger", "StatusCode": 3, "Message": "Column containing compound names was not found in '$INFILE_BASENAME'"}' > "$LOG_ERROR"
            exit 10
        fi

        INFILE="$JOB_DIR/$(cat "$JOB_DIR/rowMerger.ini" | awk -F ' = ' '/^OutputName = / {print $2}')"
    fi

    if [ $MOD_NUM == '4' ]
    then
        python "$PWD/app/PPUMA/pyModules/FeatureInfo.py" -id "$INFILE" -c "$JOB_DIR/tableMerger.ini" -if "$FEATURE_INFO_INFILE" -od "$JOB_DIR"

        # Handle errors
        STATUS_CODE=$?
        FEATINFO_BASENAME="$(basename "$FEATURE_INFO_INFILE")"
        
        if [ $STATUS_CODE -eq 1 ]; then
            echo '{"Module": "TableMerger", "StatusCode": 1, "Message": "An error occurred during execution. Please, check the parameters"}' > "$LOG_ERROR"
            exit 11
        
        elif [ $STATUS_CODE -eq 2 ]; then
            echo '{"Module": "TableMerger", "StatusCode": 2, "Message": "An error occurred when openning '$INFILE_BASENAME'. Please, check its format"}' > "$LOG_ERROR"
            exit 12

        elif [ $STATUS_CODE -eq 3 ]; then
            echo '{"Module": "TableMerger", "StatusCode": 3, "Message": "An error occurred when openning '$FEATINFO_BASENAME'. Please, check its format"}' > "$LOG_ERROR"
            exit 13

        elif [ $STATUS_CODE -eq 4 ]; then
            echo '{"Module": "TableMerger", "StatusCode": 4, "Message": "Column containing feature mass was not found in '$INFILE_BASENAME'"}' > "$LOG_ERROR"
            exit 14

        elif [ $STATUS_CODE -eq 5 ]; then
            echo '{"Module": "TableMerger", "StatusCode": 5, "Message": "Column containing feature mass was not found in '$FEATINFO_BASENAME'"}' > "$LOG_ERROR"
            exit 14
        fi

        INFILE="$JOB_DIR/$(cat "$JOB_DIR/tableMerger.ini" | awk -F ' = ' '/^OutputName = / {print $2}')"
    fi

done

# INIT_PATH="$PWD"
# cd "$JOB_DIR"
# zip TurboPutativeResults.zip ./*
# cd "$INIT_PATH"
# mv $JOB_ID.zip $JOB_DIR/TurboPutativeResults.zip
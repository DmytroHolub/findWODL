#!/bin/bash

LEN=3
FILE="word_list_english_uppercase_spell_checked.txt"
FILE2=$(mktemp)

function preparation
{
    if [[ ! -f ${LEN} ]];then
        echo "Creating dict for ${LEN}-lettered words. Please, be patient..."
        if [[ ! -f ${FILE} ]];then
            echo "Prepairing the source dict"
            if [[ ! -f ${FILE}.7z ]];then
                wget --quiet "http://www.aaabbb.de/WordList/${FILE}.7z" 2>&1 >/dev/null
                #TODO: check result and retry?
            fi
            if [[ x$(which p7zip) == "x" ]];then
                echo "Need 7z installed first"
                sudo apt install p7zip
            fi
            p7zip -d ${FILE}.7z 2>&1 >/dev/null
            #TODO: check result and what?

            cat ${FILE} | tr [:upper:] [:lower:] | sort | uniq > ${FILE2}
            mv ${FILE2} ${FILE}
        fi

        #TODO: optimize this for speed
        while read p; do
            if [[ l$(echo ${p} | wc -m) == "l$((${LEN} + 1))" ]];then
                echo "$p" >> ${LEN}
            fi
        done <${FILE}
        echo "Dict for ${LEN}-lettered words created."
    fi
    echo "There are $(cat ${LEN} | wc -l) words in the dict."
}

function iterate
{
    #TODO: add logging of all inputs to let to share not final word
    read -p "Put all your GREY letters together (if any, or empty input): " GREY
    for i in $(seq 1 ${#GREY})
    do
        cat ${FILE2} | grep -v ${GREY:i-1:1} > ${FILE3}
        mv ${FILE3} ${FILE2}
    done
    echo "Now you still have $(cat ${FILE2} | wc -l) words in the dict."

    #TODO: take into account the incorrect positions
    read -p "Put all your YELLOW letters together if any, or empty input): " YELLOW
    for i in $(seq 1 ${#YELLOW})
    do
        cat ${FILE2} | grep ${YELLOW:i-1:1} > ${FILE3}
        mv ${FILE3} ${FILE2}
    done
    echo "Now you still have $(cat ${FILE2} | wc -l) words in the dict."

    read -p "Now put all your GREEN letters if any in format (3e 4r): " GREEN
    key=""
    for i in $(seq 1 ${LEN}); do
        key=${key}"?"
    done
    for green in ${GREEN}; do
        pos=$(echo ${green} | cut -c1-1)
        let=$(echo ${green} | cut -c2-2)
        key=$(echo ${key} | sed s/./${let}/${pos})
    done

    while read line; do
        if [[ $line = *${key} ]]; then
            echo "$line" >> ${FILE3}
        fi
    done < ${FILE2}
    mv ${FILE3} ${FILE2}

    read -p "Now you still have $(cat ${FILE2} | wc -l) words in the dict. Press any key when ready to choose one of them: " -n 1 emptyInput <&1
    less ${FILE2}
}

# Main
if [[ $# == 1 && $1 > 3 && $1 < 8 ]];then
    LEN=$1
else
    read -p "Enter letter count: " LEN
    if [[ ${LEN} < 3 || ${LEN} > 7 ]];then
        echo "Seems wrong input"
        exit 1
    fi
fi

preparation
cp ${LEN} ${FILE2}
FILE3=$(mktemp)

while : ; do
    iterate
done

rm ${FILE2} ${FILE3} 2>&1 >/dev/null

#!/bin/bash

LEN=3
FILE="word_list_english_uppercase_spell_checked.txt"
FILE2=$(mktemp)

function preparation
{
    if [[ ! -f ${LEN} ]];then
        echo "Creating dict for ${LEN}-lettered words. Please, be patient..."
        if [[ ! -f ${FILE} ]];then
            #TODO: add another dictionary(s) to concatenate with. Maybe some crypto related and modern one?
            echo "Prepairing the source dict"
            if [[ ! -f ${FILE}.7z ]];then
                wget --quiet "http://www.aaabbb.de/WordList/${FILE}.7z" 2>&1 >/dev/null
                if [[ $? != 0 ]]; then
                    echo "Possibly connection issue. Try to retry"
                    exit 2 # network issue?
                fi
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
    echo "There are $(cat ${LEN} | wc -l) words in the dict. Let's filter some"
}

function iterate
{
    #TODO: add logging of all inputs to let to share not final word

    read -p "Now put all your GREEN letters, if any, in format \"3e 4r\": " GREEN
    if [[ x${GREEN} != "x" ]]; then
        key=""
        for i in $(seq 1 ${LEN}); do
            key=${key}"?"
        done
        for green in ${GREEN}; do
            pos=$(echo ${green} | cut -c1-1)
            let=$(echo ${green} | cut -c2-2 | tr [:upper:] [:lower:])
            key=$(echo ${key} | sed s/./${let}/${pos})
        done

        while read line; do
            if [[ $line = *${key} ]]; then
                echo "$line" >> ${FILE3}
            fi
        done < ${FILE2}
        mv ${FILE3} ${FILE2}
        if [[ $? != 0 ]]; then
            echo "Sorry, no variants left for your input :-("
            exit 0
        fi
        echo "Now you still have $(cat ${FILE2} | wc -l) words in the dict."
    fi

    read -p "Put all your YELLOW letters, if any, in format \"3e 4r\": " YELLOW
    if [[ x${YELLOW} != "x" ]]; then
        key=""
        for i in $(seq 1 ${LEN}); do
            key=${key}"?"
        done
        for yellow in ${YELLOW}; do
            pos=$(echo ${yellow} | cut -c1-1)
            let=$(echo ${yellow} | cut -c2-2 | tr [:upper:] [:lower:])

            cat ${FILE2} | grep ${let} > ${FILE3}
            mv ${FILE3} ${FILE2}
            if [[ $? != 0 ]]; then
                echo "Sorry, no variants left for your input :-("
                exit 0
            fi

            key=$(echo ${key} | sed s/./${let}/${pos})
        done
        while read line; do
            if [[ $line = *${key} ]]; then
                echo >/dev/null # ignoring match
            else
                echo "$line" >> ${FILE3}
            fi
        done < ${FILE2}
        mv ${FILE3} ${FILE2}
        if [[ $? != 0 ]]; then
            echo "Sorry, no variants left for your input :-("
            exit 0
        else
            echo "Now you still have $(cat ${FILE2} | wc -l) words in the dict."
        fi
    fi

    read -p "Put all your GREY letters together, if any: " GREY
    if [[ x${GREY} != "x" ]]; then
        for i in $(seq 1 ${#GREY}); do
            let=$(echo ${GREY:i-1:1} | tr [:upper:] [:lower:])
            # Some letters could be both Yellow and Grey. Handle this case:
            if [[ x$(echo ${GREEN}${YELLOW} | grep ${let}) == "x" ]]; then
                cat ${FILE2} | grep -v ${let} > ${FILE3}
                mv ${FILE3} ${FILE2}
            else
                echo "Not filtering grey letter ${let} due to it's not only grey"
            fi
        done
    fi

    read -p "Now you still have $(cat ${FILE2} | wc -l) words in the dict. Press any key when ready to choose the best match from them: " -n 1 emptyInput <&1
    less ${FILE2}
}

# Main
if [[ $# == 1 && $1 > 3 && $1 < 9 ]];then
    LEN=$1
else
    read -p "Enter letter count: " LEN
    if [[ ${LEN} < 3 || ${LEN} > 8 ]];then
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


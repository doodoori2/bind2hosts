#!/bin/bash
SCRIPT_NAME=$(basename $0)
OPTION_CNAME_RESOLVE=1
OPTION_ECHO_BIND_LINE=1

function usage()
{
	echo -e "Usage:\t${SCRIPT_NAME} [FILE]..."
	echo -e "\t${SCRIPT_NAME} convert bind9 db file to hosts file\n"
	echo -e "Examples: "
	echo -e "\t${SCRIPT_NAME} db.local"
	echo -e "\t${SCRIPT_NAME} db.*"
	exit
}


function read_db_file()
{
	local _DB_FILE_NAME=$1
	cat ${_DB_FILE_NAME} |
	sed 's/^[ \t]*//' |
	sed 's/[;\*].*//' |
	grep . |
	tr '[:lower:]' '[:upper:]'
}

function dig_query()
{
	local DOMAIN=$1
	local DIG_RESULT=(`dig ${DOMAIN} | sed 's/[;\*].*//' | grep -e "[[:space:]]A[[:space:]]"`)
	echo "${DIG_RESULT[4]}"
}

function echo_line()
{
	IP=$1
	FULL_DOMAIN=$2
	COMMENT=$3
	if [[ "${OPTION_ECHO_BIND_LINE}" ]]
	then
		echo -e "${IP_ADDR} ${FULL_DOMAIN}\t\t#${COMMENT}" | tr '[:upper:]' '[:lower:]'
	else
		echo -e "${IP_ADDR} ${FULL_DOMAIN}" | tr '[:upper:]' '[:lower:]'
	fi
}

function process_a_field()
{
	local LINE=$1
	local PARAM=($LINE)
	local SUB_DOMAIN=${PARAM[0]}
	local IP_ADDR=${PARAM[3]}
	HOSTS_CACHE["${SUB_DOMAIN}"]="${IP_ADDR}"
	echo_line $IP_ADDR "${SUB_DOMAIN}.${DOMAIN}" "${LINE}"
}

function process_cname_field()
{
	local LINE=$1
	local PARAM=($LINE)
	local SUB_DOMAIN=${PARAM[0]}
	local CNAME_DOMAIN=${PARAM[3]}
	local IP_ADDR=${HOSTS_CACHE["${CNAME_DOMAIN}"]}
	if [ "${IP_ADDR}" ]
	then
		echo_line $IP_ADDR "${SUB_DOMAIN}.${DOMAIN}" "${LINE}"
	else # not internal CNAMEs
		if [[ "${OPTION_CNAME_RESOLVE}" ]]
		then
			IP_ADDR=$(dig_query ${CNAME_DOMAIN})
			HOSTS_CACHE[${CNAME_DOMAIN}]="${IP_ADDR}"
			echo_line $IP_ADDR "${SUB_DOMAIN}.${DOMAIN}" "${LINE}"
		fi
	fi
}
function process_bind9_db_file()
{
	declare -A HOSTS_CACHE
	local DB_FILE=$1
	if [ ! -f "${DB_FILE}" ]; then
		echo "ERROR: ${DB_FILE} is not exists. "
		exit
	fi
	local DB_FILE_CONTENT=$(read_db_file ${DB_FILE})
	local SOA_FIELD=(`echo "${DB_FILE_CONTENT}" | grep -e "[[:space:]]SOA[[:space:]]" `)
	local DOMAIN=${SOA_FIELD[3]::-1}

	echo "###### bind2hosts.sh ${DB_FILE} ${DOMAIN} "
	while read LINE
	do
		process_a_field "$LINE"
	done < <(echo "${DB_FILE_CONTENT}" | grep -e "[[:space:]]A[[:space:]]")

	while read LINE
	do
		process_cname_field "$LINE"
	done < <(echo "${DB_FILE_CONTENT}" | grep -e "[[:space:]]CNAME[[:space:]]")
	echo -e "###### bind2hosts.sh ${DB_FILE} ${DOMAIN} \n"
}

function main()
{
	for DB_FILE in $@
	do
		process_bind9_db_file ${DB_FILE}
	done
}

if [ "$#" -eq 0 ]
then
	usage
else
	main $@
fi


#!/bin/bash
#DB_FILES=(samples/db.local)
DB_FILES=(samples/db.*)
DB_FILES=(samples/db.cnames)
OPTION_CNAME_RESOLVE=1
OPTION_ECHO_BIND_LINE=1



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
	local DIG_RESULT=(`dig ${DOMAIN} | sed 's/[;\*].*//' | grep -w "A"`)
	echo "${DIG_RESULT[4]}"
}


function echo_line()
{
	if [[ "${OPTION_ECHO_BIND_LINE}" ]]
	then
		echo "# ${1}"
	else
		echo -e "\n"
	fi
}

function process_a_field()
{
	local LINE=$1
	local PARAM=($LINE)
	local SUB_DOMAIN=${PARAM[0]}
	local IP_ADDR=${PARAM[3]}
	HOSTS_CACHE["${SUB_DOMAIN}"]="${IP_ADDR}"
	echo -ne "${IP_ADDR} ${SUB_DOMAIN}.${DOMAIN}	\t" | tr '[:upper:]' '[:lower:]'
	echo_line "${LINE}"
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
		echo -ne "${IP_ADDR} ${SUB_DOMAIN}.${DOMAIN}	\t" | tr '[:upper:]' '[:lower:]'
	else # not internal CNAMEs
		if [[ "${OPTION_CNAME_RESOLVE}" ]]
		then
			IP_ADDR=$(dig_query ${CNAME_DOMAIN})
			HOSTS_CACHE[${CNAME_DOMAIN}]="${IP_ADDR}"
			echo -ne "${IP_ADDR} ${SUB_DOMAIN}.${DOMAIN}	\t" | tr '[:upper:]' '[:lower:]'
		fi
	fi
	echo_line "${LINE}"

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
	local SOA_FIELD=(`echo "${DB_FILE_CONTENT}" | grep -w SOA `)
	local DOMAIN=${SOA_FIELD[3]::-1}

	echo "###### bind2hosts.sh ${DB_FILE} ${DOMAIN} "
	while read LINE
	do
		process_a_field "$LINE"
	done < <(echo "${DB_FILE_CONTENT}" | grep -w "A")

	while read LINE
	do
		process_cname_field "$LINE"
	done < <(echo "${DB_FILE_CONTENT}" | grep -w "CNAME")
	echo -e "###### bind2hosts.sh ${DB_FILE} ${DOMAIN} \n"
}

function main()
{
	DB_FILES=$1
	for DB_FILE in ${DB_FILES[@]}
	do
		process_bind9_db_file ${DB_FILE}
	done
}

main "$DB_FILES"

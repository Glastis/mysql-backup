#!/usr/bin/env bash

MYSQL_USERNAME=""
MYSQL_PASSWORD=""
MYSQL_DATABASE=""
OUTPATH=""
BACKUP_ALL=""
DB_LIST=""
MYSQL_COMMAND="mysql"
MYSQLDUMP_COMMAND="mysqldump --single-transaction"
MYSQL_TABLES=""

function usage()
{
    echo "./backup.sh"
    echo
    echo -e "\t -u [MYSQL USER]         If needed (eg: you're not root), provide login info to mysql."
    echo -e "\t -p [MYSQL PASSWORD]     If needed (eg: you're not root), provide login info to mysql."
    echo -e "\t -s                      Same as -p but password will be asked in shell. Ignored if -p is used."
    echo -e "\t -d [DATABASES NAMES]    Backup only provided databases, separated by ','. If not used, script will backup all databases."
    echo -e "\t -o [OUT PATH]           Create path if it doesn't exist. If not used, will backup all in current working directory."
    echo -e "\t -a                      Backup all databases without asking for confirmation."
    echo -e "\t -f                      Backup information_schema and performance_schema, ignored by default."
    echo -e "\t -H [MYSQL HOST]         Specify mysql host. Default is localhost."
    echo -e "\t -h                      Display this dialog."
    exit 0
}

while getopts "hfaH:su:p:d:o:" arg; do
    case ${arg} in
        h)
            usage
            ;;
        f)
            MYSQL_TABLES=1
            ;;
        a)
            BACKUP_ALL=1
            ;;
        H)
            MYSQL_HOST=${OPTARG}
            ;;
        u)
            MYSQL_USERNAME=${OPTARG}
            ;;
        p)
            MYSQL_PASSWORD=${OPTARG}
            ;;
        s)
            read -sp 'Mysql password: ' MYSQL_PASSWORD
            ;;
        d)
            MYSQL_DATABASE=${OPTARG}
            ;;
        o)
            OUTPATH=${OPTARG}
            ;;
        ?)
            echo "Bad option, use -h to display usage."
            exit 1
            ;;
    esac
done

function show_options()
{
    echo "MYSQL_USERNAME: \"${MYSQL_USERNAME}\""
    echo "MYSQL_PASSWORD: \"${MYSQL_PASSWORD}\""
    echo "MYSQL_DATABASE: \"${MYSQL_DATABASE}\""
    echo "OUTPATH: \"${OUTPATH}\""
    echo "BACKUP_ALL: \"${BACKUP_ALL}\""
    echo "MYSQL_HOST: \"${MYSQL_HOST}\""
}

function build_mysql_command()
{
    if [[ -n ${MYSQL_USERNAME} ]]; then
        MYSQL_COMMAND="${MYSQL_COMMAND} -u ${MYSQL_USERNAME}"
        MYSQLDUMP_COMMAND="${MYSQLDUMP_COMMAND} -u ${MYSQL_USERNAME}"
    fi
    if [[ -n ${MYSQL_PASSWORD} ]]; then
        MYSQL_COMMAND="${MYSQL_COMMAND} -p${MYSQL_PASSWORD}"
        MYSQLDUMP_COMMAND="${MYSQLDUMP_COMMAND} -p${MYSQL_PASSWORD}"
    fi
    if [[ -n ${MYSQL_HOST} ]]; then
        MYSQL_COMMAND="${MYSQL_COMMAND} -h ${MYSQL_HOST}"
        MYSQLDUMP_COMMAND="${MYSQLDUMP_COMMAND} -h ${MYSQL_HOST}"
    fi
}

function get_all_databases()
{
    DB_LIST="$(echo "SHOW DATABASES;" | ${MYSQL_COMMAND})"
    if [[ ${?} == 1 ]]; then
        echo "Error while connecting to mysql."
        exit
    fi
    DB_LIST="$(echo ${DB_LIST} | cut -d' ' -f2-)"
    if [[ -z ${MYSQL_TABLES} ]]; then
        DB_LIST="$(echo ${DB_LIST} | sed 's/information_schema//g' | sed 's/performance_schema//g')"
    fi
}

function confirm_backup_all()
{
    if [[ -z ${MYSQL_DATABASE} ]] && [[ -z ${BACKUP_ALL} ]]; then
        echo "Found following databases:"
        echo ${DB_LIST} | sed 's/ /\n/g'
        echo "No database selected, backup all? (y/N)"
        read REP
        REP="$(echo ${REP} | awk '{print tolower($0)}')"
        if [[ "${REP}" != "y" ]] && [[ "${REP}" != "yes" ]]; then
            echo "Aborting backup."
            exit
        fi
    fi
}

function mysql_database_to_db_list()
{
    if [[ -n ${MYSQL_DATABASE} ]]; then
        DB_LIST="$(echo ${MYSQL_DATABASE} | sed 's/,/ /g')"
    fi
}

function backup_db_list()
{
    ERR_LIST=""
    if [[ -n ${OUTPATH} ]]; then mkdir -p ${OUTPATH}; fi
    if [[ -n ${OUTPATH} ]]; then OUTPATH="${OUTPATH}/"; fi
    for line in ${DB_LIST}; do
        echo "Backup ${line}..."
        ${MYSQLDUMP_COMMAND} ${line} > "${OUTPATH}${line}.sql"
        if [[ ${?} != 0 ]]; then
            if [[ -z ${ERR_LIST} ]]; then
                ERR_LIST=${line}
            else
                ERR_LIST="${ERR_LIST}\n${line}"
            fi
        fi
    done
    if [[ -n ${ERR_LIST} ]]; then
        echo
        echo "Failed to back up following databases:"
        echo -e ${ERR_LIST}
    fi
}

function main()
{
    build_mysql_command
    get_all_databases
    confirm_backup_all
    mysql_database_to_db_list
    backup_db_list
}

main

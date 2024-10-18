# Mysql simple backup script
 
The default usage is quite simple: `./backup.sh` will dump every database that current user can get access to in separate files.

The option list is here:

    -u [MYSQL USER]         If needed (eg: you're not root), provide login info to mysql.
    -p [MYSQL PASSWORD]     If needed (eg: you're not root), provide login info to mysql.
    -s                      Same as -p but password will be asked in shell. Ignored if -p is used.
    -d [DATABASES NAMES]    Backup only provided databases, separated by ','. If not used, script will backup all databases.
    -o [OUT PATH]           Create path if it doesn't exist. If not used, will backup all in current working directory.
    -a                      Backup all databases without asking for confirmation.
    -f                      Backup information_schema and performance_schema, ignored by default.
    -H [MYSQL HOST]         Specify mysql host. Default is localhost.
    -h                      Display this dialog.

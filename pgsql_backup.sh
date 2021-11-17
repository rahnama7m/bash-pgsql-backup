#! /bin/sh

#################################
#     1. Run file 
#################################
# chmod u+x pgsql_backup.sh
# ./postgrepgsql_backupsql_db_backup.sh


#################################
#     2. Crontab document 
################################# 
# The minimum time for crontab is at least one hour. 
# Otherwise, daily and monthly backup files will be corrupted. (If you had idea for this problem participate in the project!)
# sudo crontab -e 
#    0 * * * * /absoulote/path/to/pgsql_backup.sh
 
#################################
#     3. How its work?
################################# 
# If you set crontab to run each hour: 
#      1. Checking for directories and create nessecary direcotroies if not exist.
#      2. Dump DB in new backup file and put it into hourly directory 
#      3. Checking for hour of day: if hour=23, the last file in hourly directory copy to daily directory
#      4. Checking for day of month: if day=29, the last file in dayily directory copy to monthly directory 
#      5. At each run of file, check for cont of files in each directory and delete extra ones base on `KEEP_*` variables.

#################################
# Start Block: Set this varaibles
################################# 
PG_SERVER_IP=
PG_SERVER_USER=
PS_SERVER_DB=
PG_SERVER_PASS=
PG_SERVER_PORT=
KEEP_HOURLY=48
KEEP_DAILY=60
KEEP_MONTHLY=120
BACKUP_SUFFIX=
PC_USER=
#################################
# End Block: Set this varaibles
################################# 




LOCAL_SERVER_BACKUP_DIR=/home/$PC_USER/DBBackups
LOCAL_SERVER_BACKUP_DIR_HOURLY=$LOCAL_SERVER_BACKUP_DIR/hourly
LOCAL_SERVER_BACKUP_DIR_DAILY=$LOCAL_SERVER_BACKUP_DIR/daily
LOCAL_SERVER_BACKUP_DIR_MONTHLY=$LOCAL_SERVER_BACKUP_DIR/monthly
LOCAL_SERVER_LOG=$LOCAL_SERVER_BACKUP_DIR/backup.log
HOURLY_BACKUP_FILE_NAME="${LOCAL_SERVER_BACKUP_DIR_HOURLY}/${PS_SERVER_DB}-`date +%Y-%m-%d-%H-%M`${BACKUP_SUFFIX}"


check_and_mkdir() {
    # echo "Args are $@"
    for directory_name in $@
        do
            # Create subdirectories and theirs parents if dosen't exists
            mkdir -p ${directory_name}
        done
}

check_and_rm_extra_backup_files () {
    # 1 : Absoult path of backups files directory.
    # 2 : Backup files suffix. 
    # 3 : Amount of backup files that want to be remain.
    
    all_files_count="$(find $1  -type f -name "*$2" | wc -l)"
    tail_amount=$(($3 +  1))
    
    if [ "${all_files_count}" -gt $3 ] 
        then 
            must_delete_files="$(find $1 -type f -name "*$2" -printf '%T@\t%p\0' | sort -zk1,1rn | cut -zf2 | tail -z -n +${tail_amount} | xargs -0 rm -f)"
        fi
    echo "All extra files in $1 has been deleted!" >> $LOCAL_SERVER_LOG 
}

cp_last_backups(){
    # 1 : Absoult path of resource backups files directory.
    # 2 : Backup files suffix. 
    # 3 : Absoult path of destination backups files directory.
    cp -p "`ls -dtr1 "$1"/*"$2" | tail -1`" "$3"
}

create_backup(){
    # 1: Port 
    # 2: database name 
    # 3: user name
    # 4: password
    # 5: absoulote path and file name for backup file
     
    echo "Start backup process" >> $LOCAL_SERVER_LOG 
    pg_dump "host=localhost port=$1 dbname=$2 user=$3 password=$4" | gzip > $5
    echo "Backup process has been complete." >> $LOCAL_SERVER_LOG 
    echo "New file: $5" >> $LOCAL_SERVER_LOG 
}


fireup()
{  
    check_and_mkdir $LOCAL_SERVER_BACKUP_DIR_HOURLY $LOCAL_SERVER_BACKUP_DIR_DAILY $LOCAL_SERVER_BACKUP_DIR_WEEKLY $LOCAL_SERVER_BACKUP_DIR_MONTHLY
    echo "Starting Backup..." >> $LOCAL_SERVER_LOG 
    date +"%y-%m-%d %T" >> $LOCAL_SERVER_LOG
     
    create_backup $PG_SERVER_PORT $PS_SERVER_DB $PG_SERVER_USER $PG_SERVER_PASS $HOURLY_BACKUP_FILE_NAME
    
    currenttime=$(date +%H:%M)
    echo "---Current time is: ${currenttime}" >> $LOCAL_SERVER_LOG 
    case $currenttime in
        (23:*)   
            echo "------COPY HOURLY TO DAILY DIRECTORY"    >> $LOCAL_SERVER_LOG 
            cp_last_backups $LOCAL_SERVER_BACKUP_DIR_HOURLY $BACKUP_SUFFIX $LOCAL_SERVER_BACKUP_DIR_DAILY
            currentdate=$(date +%d)
            echo "------Current day of month is: ${currentdate}" >> $LOCAL_SERVER_LOG 
            case $currentdate in
                (29)       
                    echo "---------COPY DAILY TO MONTHLY DIRECTORY" >> $LOCAL_SERVER_LOG 
                    cp_last_backups $LOCAL_SERVER_BACKUP_DIR_DAILY $BACKUP_SUFFIX $LOCAL_SERVER_BACKUP_DIR_MONTHLY
                ;;
            esac
         ;;
    esac
    
    check_and_rm_extra_backup_files $LOCAL_SERVER_BACKUP_DIR_HOURLY $BACKUP_SUFFIX $KEEP_HOURLY
    check_and_rm_extra_backup_files $LOCAL_SERVER_BACKUP_DIR_DAILY $BACKUP_SUFFIX $KEEP_DAILY
    check_and_rm_extra_backup_files $LOCAL_SERVER_BACKUP_DIR_MONTHLY $BACKUP_SUFFIX $KEEP_MONTHLY

    date +"%y-%m-%d %T" >>  $LOCAL_SERVER_LOG 
    echo "Backup Finished Successfully!" >> $LOCAL_SERVER_LOG 
    echo "#############################" >> $LOCAL_SERVER_LOG 

}

fireup


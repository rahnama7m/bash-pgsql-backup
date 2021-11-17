# pgsql-backup
Automation Backup Project For PostgreSQL Database



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


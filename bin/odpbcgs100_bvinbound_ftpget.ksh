#!/bin/sh
# Name:     odpbcgs100_bvinbound_ftpget .ksh
# Objective: Basic FTP process from lunix/unix machine
#            In order to this shell to work the .netrc file should
#            be setup by the system administrator
# Server to be connected

FTP_SERVER=odsc02
# Directory where the file is going to be get or put
# Remote directory
#FTP_RDIR=RBUY/PBQUALITY/DEV
# Local directory
FTP_LDIR=$XXMER_DATA/inbound
# File name 
FTP_FILE=OD_Status_Excel.csv
# File extension
FILE_EXT=csv
# Type of file (ascii or binary)
FTP_TYPE=binary

fname=`basename $FTP_FILE .$FILE_EXT`
tdate=`date +%Y%m%d_%H%M%S`
# Logfile
logfile=$FTP_LDIR/${fname}_${tdate}".log"
echo "local  file =$FTP_LDIR/$FTP_FILE"
echo "remote file =$FTP_FILE"

# Ftp command
ftp -v -i $FTP_SERVER 1>$logfile 2>&1<<EOF
$FTP_TYPE
get $FTP_FILE $FTP_LDIR/$FTP_FILE
bye
EOF
if [ $? -ne 0 ]
 then
   echo "Fatal error in FTP, check log $logfile"
   exit 1
fi
cat $logfile
fgrep "226 Transfer complete." > /dev/null <$logfile
if [ $? -ne 0 ]
 then
   echo "Fatal error in FTP, check log $logfile"
   exit 1
fi
grep -i -e "error" -e "fail" -e "The system cannot find the file specified." -e "No such file or directory" ${logfile} > /dev/null
if [ $? -eq 0 ]
 then
   echo "Fatal error in FTP, check log $logfile"
   exit 1
fi
echo "FTP Successfully completed."

#!/bin/sh
echo "Executing LFTP in XXLFTPGET File"
echo "user $1"
echo "passwd $2"
echo "port $3"
echo "server $4"
echo "source Location $5"
echo "Destination Location  $6"
echo "Source File $7"
echo "Destination File $8"
echo "-u $user,$passwd -p $server"
echo "-u $1,$2 -p $3 $4"
LFTPPARMS2="-u $1,$2 -p $3 $4"
echo "LFTPPARMS2 $LFTPPARMS2"
echo "Before lftp"
/usr/bin/lftp -u $1,$2 -p $3 $4 <<EOF
lcd  $6
cd $5
mget $7
quit
EOF
echo "After lftp"
#The following commands will be executed in local machine
success=`ls $6/$7 | wc -l`
echo success=$success
if [ $success -ge 1 ]
then
    #If the destination file name is not null then move the file to destination file
	if [ "$8" != "" ]
    then	
	   mv $6/$7 $6/$8
	fi
	echo "LFTP_SUCCESSFUL"
fi
echo "Executiing XXLFTPGET is completed"
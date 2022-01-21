#!/bin/sh
	 echo "Executing LFTP in Process LFTP File"
	 echo "user $1"
	 echo "port $3"
	 echo "server $4"
	 echo "source Location $5"
	 echo "Destination Location  $6"
	 echo "Source File $7"
	 echo "Temp File $8"
	 echo "Before lftp"
success=`/usr/bin/lftp -u $1,$2 -p $3 $4 <<EOF
lcd $5
cd  $6
mput $7 
quit
EOF
`

echo success=$success
if [ $success -ge 1 ]
then
	echo " LFTP transfer completed successfully " > $8 
fi
#!/bin/ksh
# file name

PROJECT=$1
FILENAME=$2

file=$FILENAME
 
# read EBS_Batch_ID and AOPS_Batch_Nbr in a while loop
# set the Internal Field Separator to a pipe symbol
while IFS=\| read BATCH_ID BATCH_NBR
do
	print "EBS Batch ID: $BATCH_ID and AOPS BATCH NBR is $BATCH_NBR"
	/app/IBM/RunDataStageJob.ksh -p $PROJECT -j CRM_EXTRACT_ALL_MAPPINGS_SJOB -v BATCH_NBR=$BATCH_NBR -v BATCH_ID=$BATCH_ID
done <"$file"
rm -f $file


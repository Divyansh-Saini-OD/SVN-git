echo "XPTR Log starts here........................" > /tmp/xx_com_xptr.$$
echo "Arguments:$*" >> /tmp/xx_com_xptr.$$
V_SRC_FILE=$2
V_TITLE=$4
echo "Printer:$1" >> /tmp/xx_com_xptr.$$
echo "Source File:$V_SRC_FILE" >> /tmp/xx_com_xptr.$$
echo "Copies:$3" >> /tmp/xx_com_xptr.$$
echo "Title:$V_TITLE" >> /tmp/xx_com_xptr.$$
V_REQUEST_ID=`echo $V_TITLE | cut -d. -f2 `
echo "Request_id:$V_REQUEST_ID" >> /tmp/xx_com_xptr.$$
V_RESULT=`echo "set echo off
		set heading off
		set feedback off
		set lines 1000
		set trimspool on
		set serveroutput on
		Declare
		x_result        varchar2(1000);
		Begin
			select	'orcl'||decode(lower(fa.product_code),'ce','cm',lower(fa.product_code))||'~'||
				rpad(substr(cp.concurrent_program_name,1,8),8,'0')||'~'||
				cr.logfile_name
			into	x_result
			from fnd_concurrent_requests cr,
				fnd_concurrent_programs cp,
				fnd_application fa
			Where	cr.request_id = $V_REQUEST_ID
			and	cp.concurrent_program_id = cr.concurrent_program_id
			and	cp.application_id = cr.program_application_id
			and	fa.application_id = cr.program_application_id;
			dbms_output.put_line(x_result);
		Exception
		    When others then
			dbms_output.put_line('OERROR~OTHER~'||substr(sqlerrm,1,255));
		End;
/"|sqlplus -s /nolog`
if [ "$?" = 0 ]
then
    if [ "$V_RESULT" = "Not connected" ]
    then
	echo "Could not access the database. XPTR Exiting!!!" >> /tmp/xx_com_xptr.$$
	exit 1;
    else
	echo "Query successful." >> /tmp/xx_com_xptr.$$
    fi
else
    echo "Could not access the database. XPTR Exiting!!!" >> /tmp/xx_com_xptr.$$
    exit 1;
fi
echo "Query Result:$V_RESULT" >> /tmp/xx_com_xptr.$$
V_DIR=`echo $V_RESULT | cut -d~ -f1 `
V_FILE=`echo $V_RESULT | cut -d~ -f2 `
V_LOGFILE=`echo $V_RESULT | cut -d~ -f3 `
if [ "$V_DIR" = "OERROR" ]
then
    echo "Error occurred while querying the database" >> /tmp/xx_com_xptr.$$
    echo "$V_LOGFILE" >> /tmp/xx_com_xptr.$$
    echo "XPTR Exiting!!!" >> /tmp/xx_com_xptr.$$
    exit 1;
fi
echo "Target Directory:/app/xptrrs/orarpt/$V_DIR" >> /tmp/xx_com_xptr.$$
V_EXTN=`basename $V_SRC_FILE | cut -d. -f2 `
V_FILENAME=`echo "$V_FILE.$V_EXTN"`
echo "Target Filename:$V_FILENAME" >> /tmp/xx_com_xptr.$$
echo "Checking for existence of Target Directory....." >> /tmp/xx_com_xptr.$$
if test ! -d /app/xptrrs/orarpt/$V_DIR
then
    echo "Target Directory does not exist! XPTR Exiting!!!" >> /tmp/xx_com_xptr.$$
    echo "XPTR Log ends here." >> /tmp/xx_com_xptr.$$
    cat /tmp/xx_com_xptr.$$ >> $V_LOGFILE
    if [ "$?" = 0 ]
    then
	rm /tmp/xx_com_xptr.$$
    fi
    exit 1;
else
    if test ! -w /app/xptrrs/orarpt/$V_DIR
    then
	echo "Target Directory is not writable! XPTR Exiting!!!" >> /tmp/xx_com_xptr.$$
	echo "XPTR Log ends here." >> /tmp/xx_com_xptr.$$
	cat /tmp/xx_com_xptr.$$ >> $V_LOGFILE
	if [ "$?" = 0 ]
	then
	    rm /tmp/xx_com_xptr.$$
	fi
	exit 1;
    fi
    echo "Target Directory Exists and is Writable!" >> /tmp/xx_com_xptr.$$
fi
echo "Copying file $V_SRC_FILE to /app/xptrrs/orarpt/$V_DIR/$V_FILENAME....." >> /tmp/xx_com_xptr.$$
cp $V_SRC_FILE /app/xptrrs/orarpt/$V_DIR/$V_FILENAME
if [ "$?" = 0 ]
then
    echo "File copied successfully!" >> /tmp/xx_com_xptr.$$
else
    echo "File copy failed!!!" >> /tmp/xx_com_xptr.$$
fi
echo "XPTR Log ends here." >> /tmp/xx_com_xptr.$$
cat /tmp/xx_com_xptr.$$ >> $V_LOGFILE
if [ "$?" = 0 ]
then
    rm /tmp/xx_com_xptr.$$
fi


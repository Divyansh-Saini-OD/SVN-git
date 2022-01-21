#!/bin/ksh
#
#* $Header            OFFICE Depot - Project Simplify
###############################################################################################
#
# Shell Script Name : XXPOREPORTS.sh
#
# Purpose           : Script To Install OD E0407 PO Reports
#
# Change History    :
#
# Version      Date            Name               Description
# ----------   ------------    ---------------    -------------------------
# 1.0          24-Apr-2007     Sarah Justina      Initial Version
################################################################################################

echo "*******************************************************"
echo "Installation of OD E0407 PO Reports"
echo "*******************************************************"

# --------------------------------------------------------------------
#  Setting up the environment
# --------------------------------------------------------------------

#. /app/ebs/atgsidev03/gsidev03appl/APPSORA.env
#. /app/ebs/atgsidev03/gsidev03appl/customGSIDEV03_chileba17d.env

# --------------------------------------------------------------------
#  Setting the variables to be used for the installation
# --------------------------------------------------------------------

HOME_PATH=`pwd`
LOG_FILE=$HOME_PATH/XXPOREPORTS.log
BIN_DIR=$XXPTP_TOP/bin
SQL_DIR=$XXPTP_TOP/sql

echo "Installation of OD E0407 PO Reports" > $LOG_FILE
echo `date` >> $LOG_FILE

# --------------------------------------------------------------------
#  Function to Check the validity of login IDs and password.
# --------------------------------------------------------------------
CHKLOGIN()
{
     if sqlplus -s /nolog <<! >/dev/null 2>&1
          WHENEVER SQLERROR EXIT 1;
          CONNECT $1 ;

          EXIT;
!
    then
        echo OK
    else
        echo NOK
    fi
}

# --------------------------------------------------------------------
#  Prompt for APPS Login Id /Password
# --------------------------------------------------------------------
while [ "$APPSID" = "" -o `CHKLOGIN "$APPSID"` = "NOK" ]
do
    if [ "$APPSID" = "" ];then
        echo ""
	echo "Please enter APPS User: "
        read APPS_USER
        echo "Please enter APPS Password: "
        stty -echo
        read -s APPS_PASSWD
        stty echo
        APPSID=$APPS_USER/$APPS_PASSWD
    else
        echo "APPS password incorrect"
        APPSID=""
    fi
done

#-------------------------------------------------------------------------------------
# Get the database host name, port, sid from the user for uploading the custom region
#-------------------------------------------------------------------------------------
HOST_NAME=""
while [ -z "$HOST_NAME" ];
do
    echo "Please enter Database Host Name : "
    read HOST_NAME
done

DB_PORT=""
while [ -z "$DB_PORT" ];
do
    echo "Please enter Database Port : "
    read DB_PORT
done

DB_SID=""
while [ -z "$DB_SID" ];
do
    echo "Please enter Database SID : "
    read DB_SID
done

# -----------------------------------------------------------------------------
# Move the database object creation files into the $XXPTP_TOP directories
# -----------------------------------------------------------------------------
echo " 1.1 Copying database object creation files"

#Copy the SQL script into sql directory
cp $HOME_PATH/PO_HEADERS_XML.sql           $XXPTP_TOP/sql
cp $HOME_PATH/PO_LINES_XML.sql             $XXPTP_TOP/sql
cp $HOME_PATH/PO_LINE_LOCATIONS_XML.sql    $XXPTP_TOP/sql
cp $HOME_PATH/PO_RELEASE_XML.sql           $XXPTP_TOP/sql
cp $HOME_PATH/XX_PO_SHORT_TEXT_REC.sql     $XXPTP_TOP/sql
cp $HOME_PATH/XX_PO_SHORT_TEXT_TAB.sql     $XXPTP_TOP/sql


echo " 1.2 Copying XSL files"

#Copy the XSL files into bin directory
cp $HOME_PATH/XX_PO_STANDARD.rtf           $XXPTP_TOP/bin
cp $HOME_PATH/XX_PO_BLANKET.rtf            $XXPTP_TOP/bin
cp $HOME_PATH/XX_PO_CONTRACTS.rtf          $XXPTP_TOP/bin
cp $HOME_PATH/XX_PO_REL_BLANKET.rtf        $XXPTP_TOP/bin

# --------------------------------------------------------------------
# Change the permission on the files
# --------------------------------------------------------------------

chmod 775 $XXPTP_TOP/sql/PO_HEADERS_XML.sql
chmod 775 $XXPTP_TOP/sql/PO_LINES_XML.sql
chmod 775 $XXPTP_TOP/sql/PO_LINE_LOCATIONS_XML.sql
chmod 775 $XXPTP_TOP/sql/PO_RELEASE_XML.sql
chmod 775 $XXPTP_TOP/sql/XX_PO_SHORT_TEXT_REC.sql
chmod 775 $XXPTP_TOP/sql/XX_PO_SHORT_TEXT_TAB.sql
chmod 775 $XXPTP_TOP/bin/XX_PO_STANDARD.rtf 
chmod 775 $XXPTP_TOP/bin/XX_PO_BLANKET.rtf
chmod 775 $XXPTP_TOP/bin/XX_PO_CONTRACTS.rtf
chmod 775 $XXPTP_TOP/bin/XX_PO_REL_BLANKET.rtf

# --------------------------------------------------------------------
#  Call script to create custom database objects
# --------------------------------------------------------------------

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/XX_PO_SHORT_TEXT_REC.sql
then
    echo " "
else
    echo "Installation of the custom record type for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/XX_PO_SHORT_TEXT_TAB.sql
then
    echo " "
else
    echo "Installation of the custom table type for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/PO_HEADERS_XML.sql
then
    echo " "
else
    echo "Installation of the view PO_HEADERS_XML for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/PO_LINES_XML.sql
then
    echo " "
else
    echo "Installation of the view PO_LINES_XML for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/PO_LINE_LOCATIONS_XML.sql
then
    echo " "
else
    echo "Installation of the view PO_LINE_LOCATIONS_XML for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

if sqlplus -s $APPS_USER/$APPS_PASSWD @$XXPTP_TOP/sql/PO_RELEASE_XML.sql
then
    echo " "
else
    echo "Installation of the view PO_RELEASE_XML for PO reports is Unsuccessful"  | tee -a $LOG_FILE
    echo "Please check and rerun"
    echo "Aborting......"
    exit 1
fi

# --------------------------------------------------------------------
# Upload RTF files
# --------------------------------------------------------------------

echo " " >> $LOG_FILE
echo "3. Uploading the Template Files into the Database " | tee -a $LOG_FILE

if java oracle.apps.xdo.oa.util.XDOLoader UPLOAD -DB_USERNAME $APPS_USER -DB_PASSWORD $APPS_PASSWD -JDBC_CONNECTION $HOST_NAME:$DB_PORT:$DB_SID -LOB_TYPE TEMPLATE -APPS_SHORT_NAME PO -LOB_CODE XX_STD_PO_RTF -LANGUAGE en -TERRITORY US -XDO_FILE_TYPE RTF -FILE_NAME $XXPTP_TOP/bin/XX_PO_STANDARD.rtf | tee -a $LOG_FILE
then
   echo "Upload of Standard RTF Template File successful." | tee -a $LOG_FILE
else
   echo "Unable to upload Standard RTF Template File " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi

if java oracle.apps.xdo.oa.util.XDOLoader UPLOAD -DB_USERNAME $APPS_USER -DB_PASSWORD $APPS_PASSWD -JDBC_CONNECTION $HOST_NAME:$DB_PORT:$DB_SID -LOB_TYPE TEMPLATE -APPS_SHORT_NAME PO -LOB_CODE XX_BLNK_PA_RTF -LANGUAGE en  -TERRITORY US -XDO_FILE_TYPE RTF -FILE_NAME $XXPTP_TOP/bin/XX_PO_BLANKET.rtf | tee -a $LOG_FILE
then
   echo "Upload of Blanket RTF Template File successful." | tee -a $LOG_FILE
else
   echo "Unable to upload Blanket RTF Template File " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi

if java oracle.apps.xdo.oa.util.XDOLoader UPLOAD -DB_USERNAME $APPS_USER -DB_PASSWORD $APPS_PASSWD -JDBC_CONNECTION $HOST_NAME:$DB_PORT:$DB_SID -LOB_TYPE TEMPLATE -APPS_SHORT_NAME PO -LOB_CODE XX_CONTRACT_PA_RTF -LANGUAGE en -TERRITORY US -XDO_FILE_TYPE RTF -FILE_NAME $XXPTP_TOP/bin/XX_PO_CONTRACTS.rtf | tee -a $LOG_FILE
then
   echo "Upload of Contracts RTF Template File successful." | tee -a $LOG_FILE
else
   echo "Unable to upload Contracts RTF Template File " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi

if java oracle.apps.xdo.oa.util.XDOLoader UPLOAD -DB_USERNAME $APPS_USER -DB_PASSWORD $APPS_PASSWD -JDBC_CONNECTION $HOST_NAME:$DB_PORT:$DB_SID -LOB_TYPE TEMPLATE -APPS_SHORT_NAME PO -LOB_CODE XX_BLNK_REL_RTF -LANGUAGE en -TERRITORY US -XDO_FILE_TYPE RTF -FILE_NAME $XXPTP_TOP/bin/XX_PO_REL_BLANKET.rtf | tee -a $LOG_FILE
then
   echo "Upload of Blanket Release RTF Template File successful." | tee -a $LOG_FILE
else
   echo "Unable to upload Blanket Release RTF Template File " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi


echo "End of installation"
echo "Please view log file for details: "$LOG_FILE
echo "End of installation" >> $LOG_FILE

# --------------------------------------------------------------------
# Unset the variables set for this installation
# --------------------------------------------------------------------
unset HOME_PATH
unset LOG_FILE
unset XXPTP_PASSWD
unset APPS_PASSWD
unset APPS_USER
unset XXPTP_USER
unset SQL_DIR

# --------------------------------------------------------------------
#  End of Script
# --------------------------------------------------------------------


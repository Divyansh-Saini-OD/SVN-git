#!/bin/ksh
#
#* $Header            OFFICE Depot - Project Simplify
################################################################################
#
# Shell Script Name : XXPOCHNGAUD.sh
#
# Purpose           : Script To Install OD E0324 PO Change Audit
#                      
#
# Change History    :
#
# Version           Date            Name               Description
# ----------        ------------    ---------------    ------------------------
# 1.0               28-Mar-2007     Senthil Jayachandran      Initial Version
#
################################################################################

echo "********************************************"
echo "Installation of OD E0324 PO Change Audit"
echo "********************************************"

# --------------------------------------------------------------------
#  Setting up the environment 
# --------------------------------------------------------------------

#. /app/ebs/atgsidev02/gsidev02appl/APPSORA.env
#. /app/ebs/atgsidev02/gsidev02appl/GSIDEV02_chileba06d.env

# --------------------------------------------------------------------
#  Setting the variables to be used for the installation
# --------------------------------------------------------------------
HOME_PATH=`pwd`
LOG_FILE=$XXPTP_TOP/bin/XXPOCHNGAUD.log
BIN_DIR=$XXPTP_TOP/bin
SQL_DIR=$XXPTP_TOP/sql
JAVA_BIN=$XXPTP_JAVA_TOP/personalizations/oracle/apps/pos
APPS_USER="APPS"
XXPTP_USER="XXPTP"
echo "Installation of OD E0324 PO Change Audit" > $LOG_FILE
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
while [ "$APPS_USER/$APPS_PASSWD" = "" -o `CHKLOGIN "$APPS_USER/$APPS_PASSWD"` = "NOK" ]
do
    if [ "$APPS_PASSWD" = "" ];then
            echo "Please enter APPS password: "
            stty -echo
            read -s APPS_PASSWD
            stty echo
    else
        echo "APPS password incorrect"
        APPS_PASSWD=""
    fi
done
# --------------------------------------------------------------------
#  Prompt for Custom Login Id / Password
# --------------------------------------------------------------------
while [ "$XXPTP_USER/$XXPTP_PASSWD" = "" -o `CHKLOGIN "$XXPTP_USER/$XXPTP_PASSWD" "DUAL"` = "NOK" ]
do
    if [ "$XXPTP_PASSWD" = "" ];then
        echo "Please enter Custom Schema password: "
        stty -echo
        read -s XXPTP_PASSWD
        stty echo
    else
        echo "Custom Schema password incorrect"

        XXPTP_PASSWD=""
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
#. /app/ebs/atgsidev02/gsidev02appl/APPSORA.env
#. /app/ebs/atgsidev02/gsidev02appl/GSIDEV02_chileba06d.env
#
# -----------------------------------------------------------------------------
# Move the database object creation files into the $XXPTP_TOP directories
# -----------------------------------------------------------------------------
echo " 1. Moving database object creation files"

mv ODCompareHeaderInfo.xml            $XXPTP_JAVA_TOP/pos/isp/server        
mv ODCompareResult.xml                $XXPTP_JAVA_TOP/pos/isp/server                     
mv ODCompareHeaderInfoRowImpl.java    $XXPTP_JAVA_TOP/pos/isp/server         
mv ODCompareResultRowImpl.java        $XXPTP_JAVA_TOP/pos/isp/server             
mv ODPOTypesVO.xml                    $XXPTP_JAVA_TOP/pos/changeorder/server
mv ODUsersVO.xml                      $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODPosRevisionHistoryVO.xml         $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODUsrPOTypeLovAM.xml               $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODPosRevisionHistoryVORowImpl.java $XXPTP_JAVA_TOP/pos/changeorder/server
mv ODPOTypesVOImpl.java               $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODPOTypesVORowImpl.java            $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODUsersVOImpl.java                 $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODUsersVORowImpl.java              $XXPTP_JAVA_TOP/pos/changeorder/server  
mv ODUsrPOTypeLovAMImpl.java          $XXPTP_JAVA_TOP/pos/changeorder/server  
mv PosViewComparePG.xml               $JAVA_BIN/inquiry/webui/customizations/site/0
mv ODPosRevisionHistoryPG.xml         $XXPTP_TOP/mds/pos/changeorder/webui
mv PORevisionSearch.jpx               $XXPTP_JAVA_TOP

#mv CompareHeaderInfo.xml              $JAVA_BIN/isp/server/customizations/site/0
#mv CompareResult.xml                  $JAVA_BIN/isp/server/customizations/site/0
#mv PosRevisionHistoryVO.xml           $JAVA_BIN/changeorder/server/customizations/site/0
# --------------------------------------------------------------------
# Move the OAF files to the respective directories
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Change the permission on the files
# --------------------------------------------------------------------

#chmod 775 $JAVA_BIN/changeorder/server/customizations/site/0/*
chmod 775 $JAVA_BIN/inquiry/webui/customizations/site/0/*
#chmod 775 $JAVA_BIN/isp/server/customizations/site/0/*
chmod 775 $XXPTP_JAVA_TOP/pos/changeorder/server/*  
chmod 775 $XXPTP_JAVA_TOP/pos/isp/server/*  

chmod 777 $LOG_FILE

# *******************************************************************
# Compile java classes
# *******************************************************************

echo " " >> $LOG_FILE
echo "2. Compiling JAVA files " >> $LOG_FILE
echo "2. Compiling JAVA files in $XXPTP_JAVA_TOP/pos/changeorder/server" 

if javac  $XXPTP_JAVA_TOP/pos/changeorder/server/*.java | tee -a $LOG_FILE
then
   echo " "
   echo "  Java compilation successful."
   echo " "

   chmod 755 $XXPTP_JAVA_TOP/pos/changeorder/server/*.class
   
else
    echo " "
    echo "  Java compilation failed in $XXPTP_JAVA_TOP/pos/changeorder/server."
    echo "  Please correct and re-run."
    echo " "
exit
fi

echo "2. Compiling JAVA files in $XXPTP_JAVA_TOP/pos/isp/server" 

if javac  $XXPTP_JAVA_TOP/pos/isp/server/*.java | tee -a $LOG_FILE
then
   echo " "
   echo "  Java compilation successful."
   echo " "

   chmod 755 $XXPTP_JAVA_TOP/pos/isp/server/*.class
   
else
    echo " "
    echo "  Java compilation failed in $XXPTP_JAVA_TOP/pos/isp/server."
    echo "  Please correct and re-run."
    echo " "
exit
fi

# --------------------------------------------------------------------
# Import JRAD XML files
# --------------------------------------------------------------------

echo " " >> $LOG_FILE
echo "3. Importing the JRAD xml files into Database " | tee -a $LOG_FILE

if java oracle.jrad.tools.xml.importer.XMLImporter $JAVA_BIN/inquiry/webui/customizations/site/0/PosViewComparePG.xml -rootdir $XXPTP_JAVA_TOP/personalizations  -username $APPS_USER -password $APPS_PASSWD -dbconnection  "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=$HOST_NAME)(PORT=$DB_PORT))(CONNECT_DATA=(SID=$DB_SID)))" | tee -a $LOG_FILE
then
   echo "Import of JRAD xml files successful." | tee -a $LOG_FILE
else
   echo "Unable to import JRAD xml files " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi

# --------------------------------------------------------------------
# VO Substitution
# --------------------------------------------------------------------

echo " " >> $LOG_FILE
echo "4. VO Substitution " | tee -a $LOG_FILE


if java oracle.jrad.tools.xml.importer.JPXImporter $XXPTP_JAVA_TOP/PORevisionSearch.jpx -username $APPS_USER -password $APPS_PASSWD -dbconnection  "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=$HOST_NAME)(PORT=$DB_PORT))(CONNECT_DATA=(SID=$DB_SID)))" | tee -a $LOG_FILE
then
   echo "VO Substitution successful." | tee -a $LOG_FILE
else
   echo "VO Substitution UNSUCCESSFUL. " | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
exit 1
fi

# --------------------------------------------------------------------
# Importing Custom Page 
# --------------------------------------------------------------------

echo " " >> $LOG_FILE
echo "5. Importing Custom JRAD Page " | tee -a $LOG_FILE


if java oracle.jrad.tools.xml.importer.XMLImporter $XXPTP_TOP/mds/pos/changeorder/webui/ODPosRevisionHistoryPG.xml -rootdir $XXPTP_TOP/mds -userId 1 -rootPackage /od/oracle/apps/xxptp -username $APPS_USER -password $APPS_PASSWD -dbconnection  "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=$HOST_NAME)(PORT=$DB_PORT))(CONNECT_DATA=(SID=$DB_SID)))" | tee -a $LOG_FILE
then
   echo "Import of Custom JRAD Page successful." | tee -a $LOG_FILE
else
   echo "Import of Custom JRAD Page UNSUCCESSFUL. " | tee -a $LOG_FILE
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


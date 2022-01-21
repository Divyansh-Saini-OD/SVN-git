#--------------------------------------------------------------------------------
#-- Copyright (c) <Project Name> - All rights reserved.
#-- Type: Shell Script
#-- Description: Shell script to install E0316_RestrictPoByPoType elements
#--
#-- Author:        Vikas Raina
#-- Creation Date:  27-Mar-2007
#-- MODIFICATION HISTORY
#--
#-- Author Name        Ver      DD-MON-YYYY     Description
#--Vikas Raina         Draft1a  27-Mar-07       Draft version
#--Vikas Raina         1.0      27-Apr-07       Baseline        
#--------------------------------------------------------------------------------


LOG_FILE=`echo $0 | sed 's/\./\.log/'|sed 's/.log.*/.log/g'`

rm -f $LOG_FILE

XXPTP_TOP_SQL="$XXPTP_TOP/sql"
XXPTP_TOP_BIN="$XXPTP_TOP/bin"

handle_error()
if [ $? = 0 ];
then
  
   echo "Copied file $1" 
  
else
 
   echo "Failed to copy the file $1. For further details please check the log file: "
   exit 2
fi

echo "Copying the various install files to the appropriate folders ..."

echo "Installation Script Run ...: " $0 | tee -a $LOG_FILE

APPSID="$1"

#**********************************************************************************
#  Copy all SQL files to $XXPTP_TOP
# **********************************************************************************

mv XX_PO_RESTRICT_POTYPE_PKG.pks    $XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pks
chmod 755 $XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pks
handle_error XX_PO_RESTRICT_POTYPE_PKG.pks

mv XX_PO_RESTRICT_POTYPE_PKG.pkb    $XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pkb
chmod 755 $XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pkb
handle_error XX_PO_RESTRICT_POTYPE_PKG.pkb

mv XX_PO_ADDVPDPOLICY.sql    $XXPTP_TOP_SQL/XX_PO_ADDVPDPOLICY.sql
chmod 755 $XXPTP_TOP_SQL/XX_PO_ADDVPDPOLICY.sql
handle_error XX_PO_ADDVPDPOLICY.sql

mv XX_PO_CREATECONTEXT.sql    $XXPTP_TOP_SQL/XX_PO_CREATECONTEXT.sql
chmod 755 $XXPTP_TOP_SQL/XX_PO_CREATECONTEXT.sql
handle_error XX_PO_CREATECONTEXT.sql 


# ****************************************************************************
#  Check if APPS Login Id is entered else prompt to get it
# ****************************************************************************

while [ "$APPSID" = ""  ]
do
    if [ "$APPSID" = "" ];then
        echo "Enter APPS Login Userid/Passwd : \c" 
        read APPSID
        echo "Enter APPS Login Userid/Passwd : " $APPSID >> $LOG_FILE
    else
        echo "APPS Login Userid and Password entered may not be CORRECT" | tee -a $LOG_FILE
        APPSID=""
    fi
done

echo "Installaling the Entire Pack " | tee -a $LOG_FILE

#  Call all the scripts for installation of entire package

# ****************************************************************************
# Call SQL Script to create package spec  
# ****************************************************************************

   echo "Creating Package XX_PO_RESTRICT_POTYPE_PKG Specification .... " | tee -a $LOG_FILE

   if sqlplus -s $APPSID @$XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pks | tee -a $LOG_FILE
   then
     echo "Creation of Package XX_PO_RESTRICT_POTYPE_PKG Specification Successful " | tee -a $LOG_FILE
   else 
     echo "Installation of Package XX_PO_RESTRICT_POTYPE_PKG Specification not successful" | tee -a $LOG_FILE
     echo "Aborting..." | tee -a $LOG_FILE
     exit 1
   fi

# ****************************************************************************
# Call SQL Script to create package body
# ****************************************************************************

   echo "Creating Package XX_PO_RESTRICT_POTYPE_PKG body..... " | tee -a $LOG_FILE

   if sqlplus -s $APPSID @$XXPTP_TOP_SQL/XX_PO_RESTRICT_POTYPE_PKG.pkb | tee -a $LOG_FILE
   then
     echo "Creation of Package XX_PO_RESTRICT_POTYPE_PKG body Successful " | tee -a $LOG_FILE
   else 
     echo "Installation of Package XX_PO_RESTRICT_POTYPE_PKG body not successful" | tee -a $LOG_FILE
     echo "Aborting..." | tee -a $LOG_FILE
     exit 1
   fi
   
   
# ****************************************************************************
# Call SQL Script to apply policy
# ****************************************************************************

   echo "Applying VPD policies..... " | tee -a $LOG_FILE

   if sqlplus -s $APPSID @$XXPTP_TOP_SQL/XX_PO_ADDVPDPOLICY.sql | tee -a $LOG_FILE
   then
     echo "Creation of Policy Successful " | tee -a $LOG_FILE
   else 
     echo "Creation of Policy not successful" | tee -a $LOG_FILE
     echo "Aborting..." | tee -a $LOG_FILE
     exit 1
   fi
      
# ****************************************************************************
# Call SQL Script to create context
# ****************************************************************************

 echo "Applying VPD policies..... " | tee -a $LOG_FILE

 if sqlplus -s $APPSID @$XXPTP_TOP_SQL/XX_PO_CREATECONTEXT.sql | tee -a $LOG_FILE
 then
   echo "Creation of Policy Successful " | tee -a $LOG_FILE
 else 
   echo "Creation of Policy not successful" | tee -a $LOG_FILE
   echo "Aborting..." | tee -a $LOG_FILE
   exit 1
fi

# ***********************************************************************************
#  Copy the install scripts to $XXPTP_TOP/bin
# ***********************************************************************************
	
mv XXPORESTRICTPOTYPE.sh  $XXPTP_TOP/bin/XXPORESTRICTPOTYPE.sh
handle_error XXPORESTRICTPOTYPE.sh

echo "Check the log file : " $LOG_FILE

# ****************************************************************************
#  End of Script
# ****************************************************************************
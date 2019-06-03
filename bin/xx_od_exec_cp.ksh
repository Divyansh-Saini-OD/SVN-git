# Name:      xx_od_exec_cp.ksh
# Author:    Antonio Morales
# Objective: Script to execute a Concurrent process in Concurrent Manager
#
# History
#
#---------------------------------------------------------------------
apost=\'

#. ${src_dir}/od_po_common_functions.ksh

#---------------------------------------------------------------------
# Procedure to get defaults from EBS for missed parameters
#---------------------------------------------------------------------
get_ebs_def ()
{
ebs_def=`sqlplus -s <<EOSQL
       ${CONNECTSTRING}
        WHENEVER SQLERROR EXIT 1
        WHENEVER OSERROR  EXIT 2
        set term off
        set echo off
        set head off
        set pages 0
        set lines 200
        set feed off
        SELECT xx_mer_exec_cp_pkg.xx_mer_get_cp_default('${appshname}', $1) FROM dual;
EOSQL`
retcode=$?
if [ $retcode -ne 0 ]; then
     appsMessage "Error in executioni get defaults from EBS"
     exit 1
fi
echo "ebs_def=$ebs_def"
}

#---------------------------------------------
# MAIN -- Call CP based on parameters received
#---------------------------------------------
appsMessage "Started" 1
if [ ${#username} -eq 0 ]
 then
   appsMessage "Error in userid"
   exit 1
fi

appsMessage "Number of positional parameters=$#"
npar=0
par=

while [ "$1" != "" ]; do
    case $1 in
        -app | --app )          shift
                                appname=$1
                                ;;
        -cpn | --cpn )          shift
                                appshname=$1
                                ;;
        * )                     (( ind= $1 * -1));
                                if [ $? -ne 0 ]; then
                                   echo "Error in parameter $1"
                                   exit 1
                                fi
                                shift
                                par[$ind]=",${apost}$1${apost}"
                                if [ $ind -gt $npar ]; then
                                   npar=$ind
                                fi
                                ;;

    esac
    shift
done
retcode=$?
if [ $retcode -ne 0 ]; then
     appsMessage "Error getting parameters"
     exit 1
fi
echo app=$appname
echo cpn=$appshname
appsMessage app=$appname
appsMessage cpn=$appshname
if [ -z $appname ] || [ -z $appshname ]; then
   appsMessage "Missing required parameters"
   exit 1
fi

#-- Get number of parameters from EBS
typeset -i ebs_par
ebs_par=`sqlplus -s <<EOSQL
       ${CONNECTSTRING}
        WHENEVER SQLERROR EXIT 1
        WHENEVER OSERROR  EXIT 2
        set term off
        set echo off
        set head off
        set pages 0
        set lines 10
        set feed off
        SELECT xx_mer_exec_cp_pkg.xx_mer_get_cp_npar('${appshname}')
          FROM dual;
EOSQL`
retcode=$?
if [ $retcode -ne 0 ]; then
     appsMessage "Error getting number of parameters from EBS"
     exit 1
fi
if [ $ebs_par -lt $npar ]; then
   appsMessage "Error in number of parameters, EBS=$ebs_par, command line=$npar"
   exit 1
fi
# Get defaults for missed or not entered parameters
ind=0
while [ $ind -lt $ebs_par ]; do
         (( ind = $ind + 1 ))
         if [ -z "${par[${ind}]}" ]; then
            get_ebs_def $ind
            par[${ind}]=",${apost}${ebs_def}${apost}"
         fi
done
ind1=1
while [ $ind1 -le $ebs_par ] ; do
      echo "Parameter $ind1=${par[${ind1}]}"
      (( ind1 = $ind1 + 1 ))
done

appsMessage "Parameters for CP=[${par[*]}]"

echo $log_file

sqlplus >> ${log_file} <<EOSQL
       ${CONNECTSTRING}
        WHENEVER SQLERROR EXIT 1
        WHENEVER OSERROR  EXIT 2
        set timi on
        set time on
        set echo on
        set term on
        set serverout on size 1000000
        VARIABLE rcode NUMBER

DECLARE
 v_rcode       NUMBER;
 v_module_name VARCHAR2(100):='$PROGRAM_NAME';
 v_event       VARCHAR2(200):='Executing xx_mer_exec_cp_pkg.exec_cp';
 v_user_id     NUMBER;
BEGIN
 v_event:= 'Exec xx_mer_exec_cp_pkg.xx_mer_get_user_id';
 v_user_id:= xx_mer_exec_cp_pkg.xx_mer_get_user_id( '$PROGRAM_NAME'
                                                   ,'$appname'
                                                   ,'$username'
                                                  );
 v_event:= 'Exec xx_mer_exec_cp_pkg.exec_cp';
 v_rcode:= xx_mer_exec_cp_pkg.exec_cp( '$PROGRAM_NAME'
                                      ,'$appname'
                                      ,'$appshname'
                                      ,'$username'
                                      ${par[*]}
                                      );
 :rcode := 0;
EXCEPTION
 WHEN OTHERS THEN
    dbms_output.put_line(v_event || ' ' || sqlerrm);
    xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                        ,v_module_name
                                        ,v_event
                                        ,'E'
                                        ,'1'
                                        ,sqlerrm
                                        ,v_user_id
                                        ,fnd_global.login_id
                                       );
    :rcode := sqlcode * -1;
    dbms_output.put_line(v_event || ' ' || sqlerrm);
END;
/
exit :rcode
EOSQL

retcode=$?
if [ $retcode -ne 0 ]; then
     appsMessage "Error in execution"
     exit 1
fi
cat $log_file
if [ ${retcode} -eq 0 ]
 then
   FindOraErrorAB
   appsMessage "Successfully finished"
 else
   appsMessage "Finished with errors, code=${retcode}"
   exit 1
fi

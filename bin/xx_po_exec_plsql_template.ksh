# Name:      xx_po_exec_plsql_template.ksh
# Author:    Antonio Morales
# Objective: Script to execute a Concurrent process in Concurrent Manager
#            Usage: . xx_od_exec_cp.ksh -app application short name \
#                                       -cpn concurrent program short name \
#                                       -1 parameter 1 \
#                                       -2 parameter 2 \
#                                       ...
#                                       -100 parameter 100
#            -app   Required application short name (XXMER, XXFIN, XXPTP, etc]
#            -cpn   Required Concurrent program short name. (From form Concurrent Programs developer mode)
#            -1 ... -100 Optional parameters, this should follow the same position defined in the concurrent 
#                        Programs parameters. If the parameter has a default in EBS and you do not enter at
#                        execution time, the default will be used.
# History
#
#--------------------------------------------------------------------------------------------------
export CONNECTSTRING=apps/appsp2p
export username=461848 # -- EBS user name (varchar)
export PROGRAM_NAME="`basename $0`"
#--------------------------------------------------------------------------------------------------
# Change if needed
#--------------------------------------------------------------------------------------------------
export DATA_DIR=$XXMER_DATA             # Data Top directory (XXMER_DATA, XXPTP_DATA, etc)
export APP_DIR=$XXMER_TOP               # Application top directory (XXMER_TOP, XXPTP_TOP, etc)
app_name="XXMER"                        # Application Name (XXMER, XXPTP, etc)
conc_pgm_shortname="XX_PO_EXEC_PL_SQL"  # Concurrent program short name
#-------------------------------------------------------------------------------------------------
# Parameters 1 to 100 as needed
#-------------------------------------------------------------------------------------------------
param1="2007/11/08 00:00:01"            # Parameter 1

#--------------------------------------------------------------------------------------------------
# Do not change from the variables bellow
#--------------------------------------------------------------------------------------------------
export data_dir=$DATA_DIR/inbound
export error_dir=$DATA_DIR/outbound
export log_dir=$DATA_DIR/outbound
export log_file=${log_dir}/${PROGRAM_NAME}_`date +%Y%m%d_%H%M%S`.log
export src_dir=$APP_DIR/bin/

. ${src_dir}/od_po_common_functions.ksh   # Do not change

appsMessage ". ${src_dir}/xx_od_exec_cp.ksh -app $app_name -cpn "$conc_pgm_shortname" -1 "$param1""
#--------------------------------------------------------------------------------------------------
# Add or remove parameters as needed (ex.: -1 "param 1" ... -100 "param 100")
#--------------------------------------------------------------------------------------------------
. ${src_dir}/xx_od_exec_cp.ksh -app "$app_name" -cpn "$conc_pgm_shortname" -1 "$param1"
#--------------------------------------------------------------------------------------------------
retcode=$?
if [ $retcode -eq 0 ]
 then
   appsMessage "Successfully finshed"
 else
   appsMessage "Error check logs end code=$retcode"
fi
exit $retcode

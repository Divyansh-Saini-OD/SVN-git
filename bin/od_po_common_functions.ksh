# Name:
# Author: Antonio Morales
# Objective: Common function for od purchasing
#
# History
#
#---------------------------------------------------------------------
#--------------------------------------------------------------------
# Messages
#--------------------------------------------------------------------
appsMessage ()
{
 par2=$2
 if [ ${#par2} != 0 ]
  then
    echo "$PROGRAM_NAME `date`: $1" > ${log_file}
  else
    echo "$PROGRAM_NAME `date`: $1" >> ${log_file}
 fi
# echo "`date`: $1"

}
# Find oracle errors in log
#--------------------------------------------------------------------
FindOraError ()
{
grep -e "ORA\-" -e "SP2\-" -e "Loader\-" ${log_file} > /dev/null
retcodeg=$?
if [ ${retcodeg} -eq 0 ]
 then
  appsMessage "Warning: *** Sqlload Errors found in log ${log_file} ***"
fi
}
# End FindOraError
#---------------------------------------------------------------------
FindOraErrorAB ()
{
grep -e "ORA\-" -e "SP2\-" -e "Loader\-" ${log_file} > /dev/null
retcodega=$?
if [ ${retcodega} -eq 0 ]
 then
  appsMessage "ERROR: *** Errors found in log ${log_file} ***"
  exit 1
fi
}
# End FindOraErrorAB
#---------------------------------------------------------------------
#  Insert error in error log
#---------------------------------------------------------------------
ins_error ()
{
# Parameters: PROGRAM_NAME
#             event
#             severity
#             code
#             code_desc
#             userid
appsMessage " "
appsMessage "*****************"
appsMessage "Inserting errors "
appsMessage "*****************"
appsMessage " "
sqlplus >> ${log_file} <<EOSQL
     ${CONNECTSTRING}
     whenever sqlerror exit 1
     whenever oserror  exit 2
-- Log Errors
DECLARE
BEGIN
    xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                        ,'${PROGRAM_NAME}'
                                        ,'${event}'
                                        ,'${severity}'
                                        ,'${code}'
                                        ,'${code_desc}'
                                        ,${userid}
                                        ,fnd_global.login_id
                                       );

END;
/
EXIT
EOSQL
if [ $? != 0 ]
 then
   appsMessage "Error logging data in log table"
   cat ${log_file}
   exit 1
fi

}

#---------------------------------------------------------------------
sql_ldr ()
{
  rm -f ${error_dir}/$1.bad
  export in_data_file=${data_dir}/$1.dat
  sqlldr control=${src_dir}/$1.ctl data=${in_data_file} bad=${error_dir}/$1.bad log=${data_dir}/$1.log \
         errors=999999999999 silent="(feedback,header) direct=n" <<EOLDR
         $CONNECTSTRING
EOLDR
appsMessage "Sql*Loader code=$?"
cat ${data_dir}/$1.log >>  ${log_file}
cat ${data_dir}/$1.log
rm -f ${data_dir}/$1.log
#---------------------------------------------------------------------
# Insert error in error log
#---------------------------------------------------------------------
if  [ -s ${error_dir}/$1.bad ]
 then
    event="Inserting rows in $1"
    code=2
    code_desc="Bad record in load check ${log_file}"
    severity='W'
    ins_error ${error_dir}/$1.bad
fi
# End sql_ldr
}
#---------------------------------------------------------------------
# Arhcive files
#---------------------------------------------------------------------
archive_in ()
{
 mv -f $1 $XXMER_DATA/archive/inbound/.
 if [ $? != 0 ]
 then
   appsMessage "Error archiving inbound data $1"
   cat ${log_file}
   exit 1
 fi
}
#---------------------------------------------------------------------
# Arhcive outbound files
#---------------------------------------------------------------------
archive_out ()
{
 mv -f $1 $XXMER_DATA/archive/outbound/.
 if [ $? != 0 ]
 then
   appsMessage "Error archiving outbound data $1"
   cat ${log_file}
   exit 1
 fi
}
#---------------------------------------------------------------------
# Move Processed inbound files
#---------------------------------------------------------------------
processed_in ()
{
 mv -f $1 $XXMER_DATA/processed/inbound/.
 if [ $? != 0 ]
 then
   appsMessage "Error moving inbound processed data $1"
   cat ${log_file}
   exit 1
 fi
}
#---------------------------------------------------------------------
# Move Processed outbound files
#---------------------------------------------------------------------
processed_out ()
{
 mv -f $1 $XXMER_DATA/processed/outbound/.
 if [ $? != 0 ]
 then
   appsMessage "Error moving outbound processed data $1"
   cat ${log_file}
   exit 1
 fi
}
#---------------------------------------------------------------------------------------
function f_init_logs
{
   echo `date +%a" "%b" "%d" "%T`" Program: ${base_pgm}${1:+ [$1]}${2:+ $2}${3:+ $3}: \
PID=$$ Started by $user" | tee -a $pgmlogfile $rmslogfile
   return 0
}


function f_normal_display
{
   if [[ "$1" != "" ]]
   then
      message="$1"
   fi

   date_time=`date +%Y%m%d.%H%M%S`
   echo "$date_time $message" >>$pgmlogfile

   if [[ $DEBUG > 1 ]]
   then
      echo "$date_time $message"
   fi

   return 0
}


function f_normal_exit
{
   message=`echo "Script $base_pgm: PID=$$ is done by user $user"| tr '[a-z]' '[A-Z]'`

   date_time=`date +%Y%m%d.%H%M%S`

   echo "$date_time NORMAL EXIT - $message" | tee -a $pgmlogfile $pidstatusfile

   echo `date +%a" "%b" "%d" "%T`" Program: "$base_pgm": PID=$$ Completed by "$user \
     | tee -a $rmslogfile

   rm -f $stdoe* 2>/dev/null  # do a little cleanup

   exit 0
}


function f_error_exit
{
   if [[ "$1" != "" ]]
   then
      message="$1"
   fi

   date_time=`date +%Y%m%d.%H%M%S`

   echo "$date_time $message" >> $pgmlogfile

   echo `date +%a" "%b" "%e" "%T`" Program: ${base_pgm}: PID=$$ \
   aborted - time stamp: $date_time \
   ................... see $pgmlogfile for more info" | tee -a $rmslogfile $pidstatusfile


   if [[ ! -z $stdoe ]]
   then
      rm -f $stdoe* 2>/dev/null  # do a little cleanup
   fi

   # use the exit code in pgmcc if it is set else exit 1
   typeset -i pgmcc

   if [[ $pgmcc -ne 0 ]]
   then
      exit $pgmcc
   fi

   exit 1
}


function f_merge_logs
{
   if [[ -s $1 ]]
   then
      date_time=`date +%Y%m%d.%H%M%S`

      echo "\n$date_time Merging file $1 \
      \n---===>>>Merge Starts<<<===---" >>$pgmlogfile

      cat $1 >>$pgmlogfile  2>/dev/null

      echo "---===>>>Merge of $1 Ends<<<===---\n" >>$pgmlogfile
   fi

   rm -f $1  2>/dev/null

   return 0
}


#---------------------------------------------------------------
#   function to get the number of threads from the restart_start control tables
#   for a RMS program
#   Parameters In: 1 - required: program name
#                  2 - required: num_of_threads variable name
#                  3 - optional external variable: return_on_error
#                      If the function errors and the variable "return_on_error" is null,
#                      then the common f_error_exit function will be called.
#                      If the called function errors and "return_on_error" is not empty
#                      then the function will write a message and return with a return code of 1
#---------------------------------------------------------------
function f_get_num_threads
{
   if [[ ( $# < 2 ) || ($1 = \? ) || ($1 = help) ]]
   then
      message="USAGE: f_get_num_threads  program_name  num_of_threads_variable_name \
             \n...............        where num_of_threads_variable_name name of the variable that holds the value for the number of threads"

      if [[ ($1 = \? ) || ($1 = help) ]]
      then
         f_normal_display "$message"
      else
         f_error_exit "$message"
      fi

      return 1
   fi

   gnt_program_name=$1
   gnt_nt_vname=$2
   gnt_nf=${return_on_error:+1}

   gntstdoeora=$stdoe.$$.f_gnt
   gntsqllst=$stdoe.$$.f_gnt.lst

   rms_runsql "$CRETC/od_get_num_threads $gnt_program_name $gntsqllst" 1>>$gntstdoeora 2>>$gntstdoeora
   pgmcc=$?


   eval $gnt_nt_vname='`cat $gntsqllst`'


   if [[ ! $pgmcc = 0 ]]
   then
      f_merge_logs $gntstdoeora
      f_merge_logs $gntsqllst

      message="ERROR:  SQL ERRORS ENCOUNTERED DURING F_GET_NUM_THREADS."

      if [[ ! -z $gnt_nf ]]
      then
         f_normal_display "$message"
         return 1
      else
         f_error_exit "FATAL $message"
      fi
   fi

   rm -f $gntsqllst $gntstdoeora 2>/dev/null

   return 0
}


#---------------------------------------------------------------
#   function to get the available threads from the restart_start control tables
#   for a RMS program
#   Parameters In: 1 - required: program name
#                  2 - required: ava_thread_variable_name
#                  3 - required: num_of_ava_threads_variable_name
#                  4 - optional external variable: return_on_error
#                      If the function errors and the variable "return_on_error" is null,
#                      then the common f_error_exit function will be called.
#                      If the called function errors and "return_on_error" is not empty
#                      then the function will write a message and return with a return code of 1
#---------------------------------------------------------------
function f_get_ava_threads
{
   if [[ ( $# < 3 ) || ($1 = \? ) || ($1 = help) ]]
   then
      message="USAGE: f_get_ava_threads program_name  ava_threads_variable_name  num_of_ava_threads_variable_name \
             \n...............        where ava_threads_variable_name        is the name of the variable that holds the list of available threads \
             \n...............              num_of_ava_threads_variable_name is the name of the variable that hold count of available threads"

      if [[ ($1 = \? ) || ($1 = help) ]]
      then
         f_normal_display "$message"
      else
         f_error_exit "$message"
      fi

      return 1
   fi

   gat_program_name=$1
   gat_at_vname=$2
   gat_nat_vname=$3
   gat_nf=${return_on_error:+1}

   gatstdoeora=$stdoe.$$.f_gat
   gatsqllst=$stdoe.$$.f_gat.lst


   rms_runsql "$CRETC/od_get_ava_threads $gat_program_name $gatsqllst" 1>>$gatstdoeora 2>>$gatstdoeora
   pgmcc=$?


   eval $gat_at_vname='`cat $gatsqllst`'
   eval $gat_nat_vname='`wc -l <$gatsqllst`'


   if [[ ( ! $pgmcc = 0 ) ]]
   then
      f_merge_logs $gatstdoeora

      message="ERROR:  ERRORS ENCOUNTERED DURING F_GET_AVA_THREADS."

      if [[ ! -z $gat_nf ]]
      then
         f_normal_display "$message"
         return 1
      else
         f_error_exit "FATAL $message"
      fi
   fi

   rm -f $gatsqllst $gatstdoeora 2>/dev/null

   return 0
}


#---------------------------------------------------------------
#   function to get the max number of simulataneous instances for a given program
#   and the sleep time to wait between instance checks for a RMS program
#   Parameters In: 1 - required: program name
#                  2 - required: max_instance_count variable name
#                  3 - required: sleep_time variable name
#                  4 - optional external variable: return_on_error
#                      If the function errors and the variable "return_on_error" is null,
#                      then the common f_error_exit function will be called.
#                      If the called function errors and "return_on_error" is not empty
#                      then the function will write a message and return with a return code of 1
#---------------------------------------------------------------
function f_get_max_instance
{
   if [[ ( $# < 3 ) || ($1 = \? ) || ($1 = help) ]]
   then
      message="USAGE: f_get_max_instance  program_name  max_instance_cnt_variable_name  sleep_variable_name \
             \n...............        where max_instance_cnt_variable_name is the name of the variable to hold the max instance value \
             \n...............              sleep_variable_name            is the name of the variable to hold the sleep time value"

      if [[ ($1 = \? ) || ($1 = help) ]]
      then
         f_normal_display "$message"
      else
         f_error_exit "$message"
      fi

      return 1
   fi

   gmi_program_name=$1
   gmi_ivar_name=$2
   gmi_svar_name=$3
   gmi_nf=${return_on_error:+1}

   stdoegmi=$stdoe.$$.gmi

   gmiparmfile=$CRETC/od_parms_mitctrl.ctl


   if [[ ! -s $gmiparmfile ]]
   then
      f_error_exit "FATAL ERROR:  MITCTRL PARM FILE NOT FOUND: \
                  \n............... FILE=$gmiparmfile"
   fi


   # get parameters from the file
   # find that line that matches the key and print it
   # take the nawk print output and parse via the "read" into the variables

   nawk -v gmikey=$gmi_program_name '{ if ($1 == gmikey) {print ($0);exit;} }'<$gmiparmfile 2>>$stdoegmi | \
         read gmikey \
              gmi_max_instance \
              gmi_sleep
   pgmcc=$?


   eval $gmi_ivar_name=$gmi_max_instance
   eval $gmi_svar_name=$gmi_sleep


   if [[ ( ! $pgmcc = 0 ) || ( -z $gmi_max_instance ) || ( -z $gmi_sleep ) ]]
   then
      message="ERROR: ERRORS ENCOUNTERED DURING F_GET_MAX_INSTANCE."

      f_merge_logs $stdoegmi

      if [[ ! -z $gmi_nf ]]
      then
         f_normal_display "$message"
         return 1
      else
         f_error_exit "FATAL $message"
      fi
   fi

   rm -f $stdoegmi 2>/dev/null

   return 0
}


#---------------------------------------------------------------
#   function to get the commit_max_ctr from the restart_start control table
#   for a RMS program
#   Parameters In: 1 - required: program name
#                  2 - required: commit_max_ctr_variable_name
#                  3 - optional external variable: return_on_error
#                      If the function errors and the variable "return_on_error" is null,
#                      then the common f_error_exit function will be called.
#                      If the called function errors and "return_on_error" is not empty
#                      then the function will write a message and return with a return code of 1
#---------------------------------------------------------------
function f_get_commit_max_ctr
{
   if [[ ( $# < 2 ) || ($1 = \? ) || ($1 = help) ]]
   then
      message="USAGE: f_get_commit_max_ctr  program_name  commit_max_ctr_variable_name \
             \n...............        where commit_max_ctr_variable_name is the name of the variable that holds the commit_max_ctr value"

      if [[ ($1 = \? ) || ($1 = help) ]]
      then
         f_normal_display "$message"
      else
         f_error_exit "$message"
      fi

      return 1
   fi

   gcmc_program_name=$1
   gcmc_cmc_vname=$2
   gcmc_nf=${return_on_error:+1}

   gcmcstdoeora=$stdoe.$$.f_gcmc
   gcmcsqllst=$stdoe.$$.f_gcmc.lst


   rms_runsql "$CRETC/od_get_commit_max_ctr $gcmc_program_name $gcmcsqllst" 1>>$gcmcstdoeora 2>>$gcmcstdoeora
   pgmcc=$?


   eval $gcmc_cmc_vname='`cat $gcmcsqllst`'


   if [[ ( ! $pgmcc = 0 ) ]]
   then
      f_merge_logs $gcmcstdoeora

      message="ERROR:  ERRORS ENCOUNTERED DURING F_GET_COMMIT_MAX_CTR."

      if [[ ! -z $gcmc_nf ]]
      then
         f_normal_display "$message"
         return 1
      else
         f_error_exit "FATAL $message"
      fi
   fi

   rm -f $gcmcsqllst $gcmcstdoeora 2>/dev/null

   return 0
}


#---------------------------------------------------------------
#   function to read a keyword parameter file and set the variables from the file
#   for a RMS program
#   Parameters In: 1 - required: name of the parameter file
#                  2 - required: value of the key to id the lines to process
#                  3 - ... - optional variables: names of variable(s) to verify
#                      that the variable is NOT null after the parm file as been read.
#                      If a listed variable is null, then error exit.
#---------------------------------------------------------------
function f_read_keyword_parm_file
{
   frkpf_parmfile="$1"
   frkpf_parmkey="$2"

   f_normal_display "FRKPF - Reading keyword parameter file: $frkpf_parmfile\
                   \n............... Using key: $frkpf_parmkey"

   # get the line that has the data that we want to use
   # and parse the data into individual variables

   if [[ ! -s "$frkpf_parmfile" ]]
   then
      f_error_exit "FRKPF: FATAL ERROR:  PARM FILE NOT FOUND: \
                  \n............... FILE=$frkpf_parmfile"
   fi

   if [[ -z "$frkpf_parmkey" ]]
   then
      f_error_exit "FRKPF: FATAL ERROR:  PARM KEY IS NULL"
   fi

   # get parameters from the file
   # find that line that matches the key and print it
   # take the nawk print output and parse via the "read" into the variables

   typeset -i frkpf_lc=0

   cat $frkpf_parmfile | \
   while read frkpf_input
   do
      echo "$frkpf_input" | \
      nawk -v key=$frkpf_parmkey '{if ($1 == key)
                                   {
                                      print (NF-1 " " $0)
                                      exit
                                   }
                                  }' | \
      read NF frkpf_key frkpf_parms  2>>$stdoe.frkpf

      # if "parms" is not null then eval then so that they get assigned
      if [[ ! "$frkpf_parms" = "" ]]
      then
         (( frkpf_lc = $frkpf_lc + 1 ))
         if [[ $frkpf_lc -eq 1 ]]
         then
            message="Task FRKPF - Parameters from ini file are:"
         fi

         message="$message \n............... parm $frkpf_lc = $frkpf_parms"

         eval "$frkpf_parms" 2>>$stdoe.frkpf
      fi
   done

   pgmcc=$?

   f_normal_display "$message"

   if [[ (-z $frkpf_parmkey) || ($pgmcc -ne 0)  || (-s $stdoe.frkpf) ]]
   then
      f_merge_logs $stdoe.frkpf
      f_error_exit "TASK FRKPF: FATAL ERROR DURING READ OF KEYWORD PARAMETERS"
   fi


   #----- verify required parameters were found and are not null

   frkpf_message=
   ((frkpf_cnt = 2))

   while [[ $frkpf_cnt -lt ${#*} ]]
   do
      ((frkpf_cnt = $frkpf_cnt + 1))

      eval frkpf_p1="$"$frkpf_cnt   # assign the input parm name to p1
      eval frkpf_p="$"$frkpf_p1     # assign the value of the parameter named in p1 to p

      # test to see if the value is null.  error if it is null.
      if [[ -z $frkpf_p ]]
      then
         frkpf_message="$frkpf_message \n............... $frkpf_p1"
         frkpf_error_ind=1
      fi
   done

   if [[ $frkpf_error_ind = 1 ]]
   then
      f_normal_display "FRKPF - Missing required keyword parameter(s): $frkpf_message"
      f_error_exit     "FRKPF - FATAL ERROR: MISSING REQUIRED KEYWORD PARAMETER(S)"
   fi

   rm -f $stdoe.frkpf 2>/dev/null

   return 0
}


#-----------------------------------------#
#--- set default mask for all routines ---#
#-----------------------------------------#
umask 111
if [[ $ORACLE_SID = rmsprd01 ]]
then
   umask 113
fi


#!/bin/ksh
###########################################################
##
## Script will pick form from current dir
## and copy it to Module TOP and AU TOP
## Will compile form and copy output to Module top.
##
##
###########################################################

CURR_DIR=$(pwd)
MODULE=XXFIN
echo -n "Enter Module(XXFIN): "
read MODULE
echo "Form needs to exist in current directory."
echo -n "Enter Form Name: "
read FORM
if [[ $FORM != *.fmb ]]; then
   echo "Not a fmb."
   exit 1;
fi
echo "Form: " $FORM
if [ ! -s $FORM ]; then
   echo "File not found."
   exit 1
fi
cd /app/ebs/itgsidev03/ebs
. EBSapps.env run > /dev/null
MODULE_TOP=$MODULE"_TOP"
MODULE_TOP=`env|grep $MODULE_TOP|awk -F"=" '{print $2}'`
FORM_OUT=${FORM/fmb/fmx}
echo "Working in RUN env."
echo "module top: " $MODULE_TOP

if [ ! -d ${MODULE_TOP} ];
then
   echo "Invalid Module TOP."
   exit 1
fi
CURR_DATE=`date +%m%d%y%H%M%S`
if [ -s $AU_TOP/forms/US/$FORM ]; then
   mv $AU_TOP/forms/US/$FORM $AU_TOP/forms/US/${FORM}_${CURR_DATE}
else 
   echo "Form not backed up in AU_TOP, as its new one."
fi
if [ -s $MODULE_TOP/forms/US/$FORM_OUT ]; then
   mv $MODULE_TOP/forms/US/$FORM_OUT $MODULE_TOP/forms/US/${FORM_OUT}_${CURR_DATE}
else 
   echo "Form not backed up in ${MODULE}_TOP, as its new one."
fi
cp $CURR_DIR/$FORM $AU_TOP/forms/US
echo -n "\n\nEnter APPS password: "
read APPS_PWD
cd $AU_TOP/forms/US
echo "Compiling Form. Review logfile at /tmp/comp_${FORM}_${CURR_DATE}.log"
frmcmp_batch userid=apps/$APPS_PWD module=$FORM output_file=$MODULE_TOP/forms/US/$FORM_OUT module_type=form batch=no compile_all=special  > /tmp/comp_${FORM}_${CURR_DATE}.log

cd /app/ebs/itgsidev03/ebs
. EBSapps.env patch > /dev/null
echo "Working in PATCH env."
if [ -s $AU_TOP/forms/US/$FORM ]; then
   mv $AU_TOP/forms/US/$FORM $AU_TOP/forms/US/${FORM}_${CURR_DATE}
else
   echo "Form not backed up in AU_TOP, as its new one."
fi
if [ -s $MODULE_TOP/forms/US/$FORM_OUT ]; then
   mv $MODULE_TOP/forms/US/$FORM_OUT $MODULE_TOP/forms/US/${FORM_OUT}_${CURR_DATE}
else
   echo "Form not backed up in ${MODULE}_TOP, as its new one."
fi
cp $CURR_DIR/$FORM $AU_TOP/forms/US
echo $CURR_DIR/$FORM $AU_TOP/forms/US
cd $AU_TOP/forms/US
frmcmp_batch userid=apps/$APPS_PWD module=$FORM output_file=$MODULE_TOP/forms/US/$FORM_OUT module_type=form batch=no compile_all=special  >> /tmp/comp_${FORM}_${CURR_DATE}.log

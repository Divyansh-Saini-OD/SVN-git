#!/bin/sh
# /* $Header: XXODGENSENDEMAIL_SLINK.ksh 1.0 Neeraj $ */
# ===================================================================================================
# Script Name:    XXUTLSENDEMAIL_SLINK.ksh
# Author’s name:   Neeraj Kumar
# Date written:    09-Sep-2017
# PURPOSE: 	      To create soft link for email program XXODGENSENDEMAIL
# HISTORY:
# Date		      Name		           Change
# 09-Sep-2017 	  Neeraj Kumar		   Initial version
# 
# ===================================================================================================
ln -f -s $FND_TOP/bin/fndcpesr XXODGENSENDEMAIL

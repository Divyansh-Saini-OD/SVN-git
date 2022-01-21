/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware, LP                                   A#
 *#W  Address: 410 Edgewater Place suite 260                     X#
 *#A           Wakefield MA 01880    USA                         W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel 781-557-2600 Fax 781-557-2606                 R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM ADP Taxware, LP            A#
 *#W                                                             X#
 *#A       Copyright © 2004 ADP Taxware, LP                      W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *# $Header: $
 *###############################################################
 *   Source File          :- od_twe_ap_custom_install.sql
 *   History              :- OD Customization: New installation  
 *                           file created for OD Customizations.
 *###############################################################
 */
 
SET ECHO OFF;
SPOOL od_twe_ap_custom_install.log;
PROMPT 
PROMPT 
PROMPT 
PROMPT 
PROMPT ************************************************************
PROMPT This script will do the grants and will create all synonyms
PROMPT the values on the [] are default values just press enter
PROMPT ************************************************************
PROMPT 
PROMPT 
PROMPT 

ACCEPT APPSUser CHAR DEFAULT APPS PROMPT 'Please Enter Oracle Apps User Name [APPS] : '
ACCEPT APPSpwd  CHAR DEFAULT APPS PROMPT 'Please Enter Oracle Apps Password  [APPS] : ' HIDE
ACCEPT ORASid   CHAR PROMPT              'Please Enter Oracle SID                   : '


ACCEPT TWEAPUser CHAR DEFAULT twe_ap PROMPT 'Please Enter TWE AP Adapter User Name [twe_ap] : '
ACCEPT TWEAPpwd  CHAR DEFAULT twe_ap PROMPT 'Please Enter TWE AP Adapter Password  [twe_ap] : ' HIDE


PROMPT 
PROMPT 
PROMPT **********************************************************************
PROMPT Connecting to the APPS user and modifying the valuesets.
PROMPT **********************************************************************
PROMPT 
PROMPT 
CONNECT &APPSUser/&APPSpwd@&ORASid;
PROMPT 
PROMPT 
PROMPT
@TWE-ApValueSets.sql
PROMPT 
PROMPT 
PROMPT ****************************************************************************
PROMPT Connecting to the TWE AP Adapter user to compile new packages.
PROMPT ****************************************************************************
PROMPT 
PROMPT 
CONNECT &TWEAPUser/&TWEAPpwd@&ORASid;

PROMPT 
PROMPT 
PROMPT ****************************************************************************
PROMPT Creating all the TWE AP Adapter objects
PROMPT ****************************************************************************
PROMPT 
PROMPT 
@TWE-ApDataElements.sql;
@TWE-ApTax10.wrp;
@TWE-ApAdaptor.wrp;


SPOOL OFF;
exit;
/

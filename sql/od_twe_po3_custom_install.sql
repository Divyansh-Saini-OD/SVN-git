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
 *#A       Copyright © 2005 ADP Taxware, LP                      W#
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
spool od_twe_po_custom_install.log

PROMPT 
PROMPT 
PROMPT 
PROMPT 
PROMPT ************************************************************
PROMPT This script will do the grants and will create all synonyms
PROMPT ************************************************************
PROMPT 
PROMPT 
PROMPT 

ACCEPT APPSUser CHAR DEFAULT APPS PROMPT 'Please Enter Oracle Apps User Name [APPS] : '
ACCEPT APPSpwd  CHAR DEFAULT APPS PROMPT 'Please Enter Oracle Apps Password  [APPS] : ' HIDE
ACCEPT ORASid   CHAR PROMPT              'Please Enter Oracle SID                   : '

ACCEPT TWEAPUser CHAR PROMPT 'Please Enter TWE PO Adapter User Name : '
ACCEPT TWEAPpwd  CHAR PROMPT 'Please Enter TWE PO Adapter Password  : ' HIDE


PROMPT 
PROMPT 
PROMPT **********************************************************************
PROMPT Connecting to the APPS user and generating grants to PO Adapter user
PROMPT **********************************************************************
PROMPT 
PROMPT 
CONNECT &APPSUser/&APPSpwd@&ORASid;

GRANT SELECT ON HR_OPERATING_UNITS TO &TWEAPUser;
GRANT SELECT ON MTL_SYSTEM_ITEMS TO &TWEAPUser;
GRANT SELECT ON MTL_CATEGORIES_B TO &TWEAPUser;

GRANT EXECUTE ON FND_FLEX_KEYVAL TO &TWEAPUser;

PROMPT 
PROMPT 
PROMPT ****************************************************************************
PROMPT Connecting to the TWE PO Adapter user to generate synonyms
PROMPT ****************************************************************************
PROMPT 
PROMPT 
CONNECT &TWEAPUser/&TWEAPpwd@&ORASid;

DROP SYNONYM HR_OPERATING_UNITS; 
DROP SYNONYM MTL_SYSTEM_ITEMS; 
DROP SYNONYM MTL_CATEGORIES_B; 
DROP SYNONYM FND_FLEX_KEYVAL; 

CREATE SYNONYM HR_OPERATING_UNITS FOR &APPSUser..HR_OPERATING_UNITS;
CREATE SYNONYM MTL_SYSTEM_ITEMS FOR &APPSUser..MTL_SYSTEM_ITEMS;
CREATE SYNONYM MTL_CATEGORIES_B FOR &APPSUser..MTL_CATEGORIES_B;
CREATE SYNONYM FND_FLEX_KEYVAL FOR &APPSUser..FND_FLEX_KEYVAL;

PROMPT 
PROMPT 
PROMPT ****************************************************************************
PROMPT Creating all the TWE PO Adapter objects
PROMPT ****************************************************************************
PROMPT 
PROMPT 

@TWE-PODataElements.sql
@TWE-POSetDffData.wrp
@TWE-POTax10.wrp
@TWE-POAdapter.wrp

spool off
exit;
/

/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *# $Header: $  March 31, 2007 
 *###############################################################
 *   Source File          :- twe_ar_install_adapter.sql
 *###############################################################
 */

set feedback on
set echo off
set verify off
spool xx_ar_twe_custom_install.log
PROMPT ***************************************************************************
PROMPT This Install the Oracle packages for Taxware Enterprise (TWE) customization 
PROMPT in Office Depot.
PROMPT ***************************************************************************
column object_name for a30
column object_type for a25
column version for a31

DEF APPSUser="APPS"
DEF APPSpwd="APPS"
DEF TWEARUser="TWE_AR"
DEF TWEARpwd="TWE_AR"

ACCEPT APPSUser CHAR DEFAULT &APPSUser PROMPT 'Please enter APPS user name [&APPSUser]:'
ACCEPT APPSpwd CHAR DEFAULT &APPSpwd PROMPT   'Please enter APPS password  [&APPSpwd]:' HIDE
ACCEPT L_SID CHAR PROMPT    'Please enter DB SID (db name):'
ACCEPT TWEARUser CHAR DEFAULT &TWEARUser PROMPT 'Please enter TWE Adapter user name [&TWEARUser] :'
ACCEPT TWEARpwd CHAR DEFAULT &TWEARpwd PROMPT 'Please enter TWE Adapter password  [&TWEARpwd] :' HIDE

PROMPT *********************************************

PROMPT Creating objects for user &TWEARUser
connect &TWEARUser/&TWEARpwd@&l_sid;

drop table xx_od_twe_ar_inv_gt
/

drop table xx_ar_twe_inv_glb_tmp
/
PROMPT Creating GLOBAL TEMPORARY TABLE xx_ar_twe_inv_glb_tmp
create global temporary table xx_ar_twe_inv_glb_tmp
(
customer_trx_id 		number(15),
created_by			number(15),
creation_date			date
) on commit delete rows
/

PROMPT Adding Grants for &APPSUSER ....

GRANT ALL ON xx_ar_twe_inv_glb_tmp  TO &APPSUSER;

PROMPT *********************************************
PROMPT Grant select rights to &TWEARUser

connect &APPSUser/&APPSpwd@&L_SID;

PROMPT GRANT SELECT on RA_CUSTOMER_TRX to &TWEARUser;
GRANT SELECT on RA_CUSTOMER_TRX to &TWEARUser;

PROMPT GRANT SELECT on RA_CUSTOMER_TRX_PARTIAL_V to &TWEARUser;
GRANT SELECT on RA_CUSTOMER_TRX_PARTIAL_V to &TWEARUser;

PROMPT GRANT SELECT on RA_CUST_TRX_LINE_GL_DIST_V to &TWEARUser;
GRANT SELECT on RA_CUST_TRX_LINE_GL_DIST_V to &TWEARUser;

PROMPT GRANT SELECT on RA_SITE_USES to &TWEARUser;
GRANT SELECT on RA_SITE_USES to &TWEARUser;

PROMPT GRANT SELECT on RA_CUSTOMER_TRX_LINES to &TWEARUser;
GRANT SELECT on RA_CUSTOMER_TRX_LINES to &TWEARUser;

PROMPT GRANT SELECT on MTL_SYSTEM_ITEMS to &TWEARUser;
GRANT SELECT on MTL_SYSTEM_ITEMS to &TWEARUser;

PROMPT GRANT SELECT on MTL_ITEM_CATEGORIES_V to &TWEARUser;
GRANT SELECT on MTL_ITEM_CATEGORIES_V to &TWEARUser;

PROMPT GRANT SELECT on RA_ADDRESSES to &TWEARUser;
GRANT SELECT on RA_ADDRESSES to &TWEARUser;

PROMPT GRANT EXECUTE on FND_FLEX_EXT to &TWEARUser;
GRANT EXECUTE on FND_FLEX_EXT to &TWEARUser;

PROMPT GRANT EXECUTE on FND_FILE to &TWEARUser;
GRANT EXECUTE on FND_FILE to &TWEARUser;

PROMPT GRANT EXECUTE on FND_GLOBAL to &TWEARUser;
GRANT EXECUTE on FND_GLOBAL to &TWEARUser;

PROMPT GRANT EXECUTE on FND_PROFILE to &TWEARUser;
GRANT EXECUTE on FND_PROFILE to &TWEARUser;

PROMPT GRANT EXECUTE on ARP_UTIL_TAX to &TWEARUser;
GRANT EXECUTE on ARP_UTIL_TAX to &TWEARUser;

PROMPT GRANT EXECUTE on ARP_TAX to &TWEARUser;
GRANT EXECUTE on ARP_TAX to &TWEARUser;

PROMPT GRANT EXECUTE on FND_FLEX_KEYVAL to &TWEARUser;
GRANT EXECUTE on FND_FLEX_KEYVAL to &TWEARUser;

PROMPT GRANT SELECT on FND_PROFILE_OPTIONS to &TWEARUser;
GRANT SELECT on FND_PROFILE_OPTIONS to &TWEARUser;

PROMPT GRANT SELECT on FND_PROFILE_OPTION_VALUES to &TWEARUser;
GRANT SELECT on FND_PROFILE_OPTION_VALUES to &TWEARUser;

PROMPT GRANT SELECT on AR_ADDRESSES_V to &TWEARUser;
GRANT SELECT on AR_ADDRESSES_V to &TWEARUser;

PROMPT GRANT SELECT on HR_LOCATIONS_ALL to &TWEARUser;
GRANT SELECT on HR_LOCATIONS_ALL to &TWEARUser;

PROMPT GRANT SELECT on hr_organization_information_v to &TWEARUser;
GRANT SELECT on hr_organization_information_v to &TWEARUser;

PROMPT GRANT SELECT on hr_organization_units_v to &TWEARUser;
GRANT SELECT on hr_organization_units_v to &TWEARUser;

PROMPT GRANT SELECT on oe_order_headers to &TWEARUser;
GRANT SELECT on oe_order_headers to &TWEARUser;

PROMPT GRANT SELECT on per_addresses_v to &TWEARUser;
GRANT SELECT on per_addresses_v to &TWEARUser;

PROMPT GRANT SELECT on ra_salesreps to &TWEARUser;
GRANT SELECT on ra_salesreps to &TWEARUser;

PROMPT GRANT SELECT on ra_cust_trx_line_salesreps_v to &TWEARUser;
GRANT SELECT on ra_cust_trx_line_salesreps_v to &TWEARUser;


/* Custom */
PROMPT GRANT SELECT on oe_order_sources to &TWEARUser;
GRANT SELECT on oe_order_sources to &TWEARUser;

PROMPT GRANT SELECT on oe_order_lines to &TWEARUser;
GRANT SELECT on oe_order_lines to &TWEARUser;

PROMPT GRANT SELECT on RA_CUST_TRX_TYPES to &TWEARUser;
GRANT SELECT on RA_CUST_TRX_TYPES to &TWEARUser;

PROMPT GRANT SELECT on RA_BATCH_SOURCES to &TWEARUser;
GRANT SELECT on RA_BATCH_SOURCES to &TWEARUser;

PROMPT GRANT SELECT on hr_all_organization_units to &TWEARUser;
GRANT SELECT on hr_all_organization_units to &TWEARUser;

PROMPT GRANT SELECT on fnd_lookup_types to &TWEARUser;
GRANT SELECT on fnd_lookup_types to &TWEARUser;

PROMPT GRANT SELECT on fnd_lookup_values to &TWEARUser;
GRANT SELECT on fnd_lookup_values to &TWEARUser;

PROMPT GRANT SELECT on oe_order_types_v to &TWEARUser;
GRANT SELECT on oe_order_types_v to &TWEARUser;


PROMPT *********************************************
PROMPT Creates Synonyms in &&APPSUser

PROMPT DROP SYNONYM  xx_od_twe_ar_inv_gt;
DROP SYNONYM  xx_od_twe_ar_inv_gt
/

PROMPT DROP SYNONYM  xx_ar_twe_inv_glb_tmp;
drop synonym xx_ar_twe_inv_glb_tmp
/

PROMPT CREATE SYNONYM  xx_ar_twe_inv_glb_tmp for &&TWEARUser..xx_ar_twe_inv_glb_tmp;
CREATE SYNONYM  xx_ar_twe_inv_glb_tmp for &&TWEARUser..xx_ar_twe_inv_glb_tmp
/

PROMPT *********************************************
PROMPT Creating GLOBAL TEMPORARY TABLE xx_om_twe_usetax_glb_tmp

drop table xx_ont_twe_usetax_gt
/

drop table xx_om_twe_usetax_glb_tmp
/

create global temporary table xx_om_twe_usetax_glb_tmp
(
acct_type_code       NUMBER(15),                  
tax_code 	varchar2(15),
currency_code   varchar2(15),
created_by	number(15),
creation_date	date,
ccid        number(15),
segment1    VARCHAR2(25),
segment2    VARCHAR2(25),
segment3    VARCHAR2(25),
segment4    VARCHAR2(25),
segment5    VARCHAR2(25),
segment6    VARCHAR2(25),
segment7    VARCHAR2(25),
entered_dr  number,
entered_cr  number
) on commit delete rows
/

PROMPT *****************************************************
PROMPT Creating package XX_OM_USETAXACCRUAL_PKG in &&APPSUser

PROMPT Dropping incorrectly named package od_ont_use_tax_accrual in &&APPSUser
drop package od_ont_use_tax_accrual
/

@XXOMUSETAXACCRUALS.pls
@XXOMUSETAXACCRUALB.pls

PROMPT ********************************
PROMPT Creating PACKAGE SPEC in &TWEARUser
connect &TWEARUser/&TWEARpwd@&l_sid;

PROMPT Dropping incorrectly named package twe_ar_util_pkg_od in &&APPSUser
drop package twe_ar_util_pkg_od
/

@taxpkg_gen_spec.sql
@taxpkg_10_params.sql
@taxpkg_10_spec.sql
@XXARTWEUTILS.sql

PROMPT Creating PACKAGE BODY in &TWEARUser
@taxpkg_gen_body.sql
@taxpkg_10_body.sql
@taxpkg_10_paramb.sql
@XXARTWEUTILB.sql

PROMPT Grant execute permission on &TWEARUser objects to APPS
GRANT EXECUTE on TAXPKG_GEN to &APPSUser;
GRANT EXECUTE on TAXPKG_10 to &APPSUser;
GRANT EXECUTE on TAXPKG_10_PARAM  to &APPSUser;
GRANT EXECUTE on XX_AR_TWE_UTIL_PKG to &APPSUser;

PROMPT *********************************************
PROMPT Recompile ARP_TAX_VIEW_TAXWARE Package Body
connect &APPSUser/&APPSpwd@&L_SID;
ALTER PACKAGE ARP_TAX_VIEW_TAXWARE COMPILE BODY;

PROMPT *********************************************

PROMPT Installation is finished, check for invalid objects

PROMPT Checking for invalid objects in the &TWEARUser Schema
connect &TWEARUser/&TWEARpwd@&l_sid;
SELECT substr(object_name,1,30) Object_Name, object_type
FROM   user_objects
WHERE  status = 'INVALID';


PROMPT *****************__-__*****************
PROMPT Checking Versions in &TWEARUser Schema
SELECT SUBSTR (NAME, 1, 35) Object_Name,
       SUBSTR (text, (INSTR (text, '$Header')), 30) Version
  FROM user_source
 WHERE text LIKE '%$Header%';


PROMPT *********************************************
PROMPT End of script
PROMPT *********************************************
spool off

exit;

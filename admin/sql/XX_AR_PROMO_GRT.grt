{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 Courier New;}{\f1\fswiss\fcharset0 Arial;}}
{\*\generator Msftedit 5.41.15.1507;}\viewkind4\uc1\pard\f0\fs20 /**********************************************************************************\par
 Program Name: XX_AR_PROMO_GRT.grt\par
 Purpose:      Grant on xx_ar_promo_cardtypes to APPS.\par
               Grant on xx_ar_promo_header to APPS.\par
               Grant on xx_ar_promo_detail to APPS.\par
\par
 REVISIONS:\par
-- Version Date        Author                               Description\par
-- ------- ----------- ------------------------------------ ---------------------\par
-- 1.0     05-MAR-2007 Raji Natarajan,Wipro Technologies   Created base version.\par
-- \par
**********************************************************************************/\par
SET SHOW         OFF\par
SET VERIFY       OFF\par
SET ECHO         OFF\par
SET TAB          OFF\par
SET FEEDBACK     ON\par
\par
GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_cardtypes TO APPS;\par
GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_header TO APPS;\par
GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_detail TO APPS;\par
\par
/\par
SHOW ERROR\par
\f1\par
}
 
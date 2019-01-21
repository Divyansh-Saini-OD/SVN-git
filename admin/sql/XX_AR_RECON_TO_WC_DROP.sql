/* =============================================================================
  * Module Type : SQL Script
  * Module Name :  xx_ar_recon_to_wc.sql
  * Description : Drop tables for AR Recon
  * Run Env.    : SQL*Plus
  *
  * History
  * =======
  *
  * Version   Name           Date            Description of Change
  * -------  -------------   -----------     -----------------------------------
  * 1.0      Maheswararao N   03-OCT-2011     Initial Creation. 
  * 1.1      Maheswararao N   21-OCT-2011     Changed as per MD70 update 
  * =============================================================================
  */

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE

DROP TABLE XXFIN.XX_AR_RECON_TRANS_STG;

SHOW ERRORS;

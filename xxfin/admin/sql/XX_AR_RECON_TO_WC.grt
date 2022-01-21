 /* =============================================================================
  * Module Type : SQL Script
  * Module Name :  xx_ar_recon_trans_itm.grt
  * Description : Grant access to apps for this table
  * Run Env.    : SQL*Plus
  *
  * History
  * =======
  *
  * Version   Name           Date            Description of Change
  * -------  -------------   -----------     -----------------------------------
  * 1.0      Maheswararao N   03-OCT-2011     Initial Creation. 
  * =============================================================================
  */
  
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

GRANT ALL ON xxfin.XX_AR_RECON_TRANS_STG TO APPS WITH grant option;

SHOW ERRORS;
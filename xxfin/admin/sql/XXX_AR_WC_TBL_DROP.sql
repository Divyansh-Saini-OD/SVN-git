SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

DROP TABLE XXFIN.XX_AR_TRANS_WC_STG;
DROP TABLE XXFIN.XX_AR_CR_WC_STG;
DROP TABLE XXFIN.XX_AR_ADJ_WC_STG;
DROP TABLE XXFIN.XX_AR_PS_WC_STG; 
DROP TABLE XXFIN.XX_AR_RECAPPL_WC_STG;
DROP TABLE XXFIN.XX_AR_EXT_WC_MASTER_DETAILS;
DROP SEQUENCE XXFIN.XX_AR_EXT_WC_MASTER_S;









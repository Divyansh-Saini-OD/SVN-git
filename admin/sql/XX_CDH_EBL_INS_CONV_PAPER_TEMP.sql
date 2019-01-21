SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_INS_CONV_PAPER_TEMP.sql                          |
-- | Description : SQL to create bulk upload template for  PAPER docs to ePDF  |
-- |               docs conversion.                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author          Remarks            	               |
-- |======= =========== ================ ======================================|
-- |DRAFT 1 09-NOV-2010 Devi Viswanathan Initial draft version                 |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+


INSERT INTO  xxtps.xxtps_template_file_uploads 
VALUES 
(9
,null
,-1
,sysdate
,-1
,sysdate
,'CUST_DOC_CONV'
,'Customer Documents'
,'Template to upload Account details for customer document conversion'
,'''CUST_ACCOUNT_ID'',''ACCOUNT_NUMBER'',''CUSTOMER_NAME'',''AOPS_NUMBER'',''ZIP_CODE'''
,'XX_CDH_EBL_CONV_PAPER_EPDF.LOAD_ACCOUNT_DTLS'
, '''Cust Account Id'',''Account Number'',''Customer Name'',''AOPS Number'',''Zip Code'',''Status'',''Error'''
, '''Cust Account Id'',''Account Number'',''Customer Name'',''AOPS Number'',''Zip Code'',''Status'',''Error'''
,'Cust Account Id *,Account Number *,Customer Name *,AOPS Number *,Zip Code *'
,'The File should contain the following columns in the following order - 
-Cust Account Id *
-Account Number *
-Customer Name *
-AOPS Number *
-Zip Code *');

COMMIT;






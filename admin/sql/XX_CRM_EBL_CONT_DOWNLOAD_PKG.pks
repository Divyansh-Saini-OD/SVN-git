SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CRM_EBL_CONT_DOWNLOAD_PKG
--+======================================================================+
--|      Office Depot -                                                  |
--+======================================================================+
--|Name       : XX_CRM_EBL_CONT_DOWNLOAD_PKG.pks                         |
--|Description: This Package is used for downloading ebill contact       |
--|             for a given cust_account_id and cust_doc_id              |
--|                                                                      |
--|             The download proc will perform the following steps       |
--|                                                                      |
--|             1. Get all eBill contacts for a given cust_account_id and|
--|                cust_doc_id                                           |
--|             2. Write into a file in utl file directory path          |
--|             3. Move the file into OA Fwk Temp directory to download  |
--|                as CSV file                                           |
--|                                                                      |
--| History                                                              |
--| 23-Jul-2012   Sreedhar Mohan  Intial Draft                           |
--+======================================================================+
AS
PROCEDURE DOWNLOAD_EBL_CONTACT (
                                 x_errbuf          OUT      VARCHAR2
                                ,x_retcode         OUT      VARCHAR2
                                ,x_file_upload_id  OUT      VARCHAR2
                                ,p_cust_doc_id     IN       VARCHAR2
                                ,p_cust_account_id IN       VARCHAR2
                                ,p_oaf_temp_dir    IN       VARCHAR2
                                ,p_utl_file_name   IN       VARCHAR2
                               );


END XX_CRM_EBL_CONT_DOWNLOAD_PKG;
/

SHOW ERROR;

create or replace 
PACKAGE  XX_CDH_EBL_COPY_PKG  AUTHID CURRENT_USER
  -- +======================================================================================+
  -- |                  Office Depot - Project Simplify                                     |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
  -- +======================================================================================|
  -- | Name       : XX_CDH_EBL_COPY_PKG                                                     |
  -- | Description: This package is for the Copy functionlity in the Search Page            |
  -- |                                                                                      |
  -- |                                                                                      |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version     Date            Author               Remarks                              |
  -- |=======   ===========   =================     ========================================|
  -- |DRAFT 1A  20-APR-2010    Mangala                   Initial draft version              |
  -- |1.1       07-SEP-2010    Mangala                   Code change to Fix Defect 7588,7635|
  -- |                                                                                      |
  -- |1.2       07-JAN-2016    Suresh N                  Module 4B Release 3 Changes(Defect#36320)|
  -- |1.3       30-MAR-2016    Havish K                  Module 4B Release 4 Changes        |
  -- |======================================================================================|
  -- +======================================================================================+
AS
  -- +==================================================================================+
  -- | Name             : MAIN_PROC                                                     |
  -- | Description      : This procedure will in turn call all the other procedures to  |
  -- |                    perform the COPY functioanlity                                |
  -- |                                                                                  |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE MAIN_PROC(
                     x_cust_document_id OUT NUMBER
                    ,p_cust_account_id  IN  NUMBER
                    ,p_scust_doc_id     IN  NUMBER
                    ,p_dcust_account_id IN  NUMBER
                   );
  -- +==================================================================================+
  -- | Name             : COPY_CUST_DOC                                                 |
  -- | Description      : This procedure will copy the cust doc id values from the      |
  -- |                    EGO table XX_CDH_CUST_ACCT_EXT_B and insert a record into the |
  -- |                    same table                                                    |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_CUST_DOC(
                         x_cust_doc_id   OUT NUMBER
                        ,p_cust_acct_id  IN  NUMBER
                        ,p_cust_doc_id   IN  NUMBER
                        ,p_dcust_acct_id IN  NUMBER
                       );
  -- +==================================================================================+
  -- | Name             : COPY_DOC_EXCEPTION                                            |
  -- | Description      : This procedure will copy the cust doc id values from the      |
  -- |                    EGO table XX_CDH_CUST_ACCT_EXT_B and insert a record into the |
  -- |                    Exception tables XX_CDH_ACCT_SITE_EXT_B and                   |
  -- |                    XX_CDH_ACCT_SITE_EXT_TL.The Exceptions are copied only for    |
  -- |                     Info Docs                                                    |
  -- +==================================================================================+
PROCEDURE COPY_DOC_EXCEPTION(
                             p_scust_doc_id  IN NUMBER
                            ,p_dcust_doc_id  IN NUMBER
                            ,p_scust_acct_id IN NUMBER
                            ,p_dcust_acct_id IN NUMBER
                           );
  -- +==================================================================================+
  -- | Name             : COPY_EBL_MAIN                                                 |
  -- | Description      : This procedure will copy the Ebill main details corresponding |
  -- |                    to Cust doc id and insert into the table XX_CDH_EBL_MAIN      |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_EBILL_MAIN(
                         p_scust_doc_id     IN NUMBER
                        ,p_dcust_doc_id     IN NUMBER
                        ,p_dcust_account_id IN NUMBER
                         );
  -- +==================================================================================+
  -- | Name             : COPY_TRANSMISSION_DTL                                         |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TRANSMISSION_DTL                                  |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_TRANSMISSION_DTL(
                                p_scust_doc_id IN NUMBER,
                                p_dcust_doc_id IN NUMBER
                               );
  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_HEADER                                             |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TEMPL_HEADER                                      |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_TEMPL_HEADER(
                            p_scust_doc_id IN NUMBER,
                            p_dcust_doc_id IN NUMBER
                           );
  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_DETAIL                                             |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TEMPL_DTL                                         |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_TEMPL_DETAIL(
                            p_scust_doc_id IN NUMBER
                            ,p_dcust_doc_id IN NUMBER
                           );
-- Adding for MOD 4B Release 4
  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_TRAILER_TXT                                        |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TEMPL_TRL_TXT                                     |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_TEMPL_TRAILER_TXT(
                                 p_scust_doc_id IN NUMBER
                                ,p_dcust_doc_id IN NUMBER
                                );
-- End of adding MOD 4B Release 4 changes
  -- +==================================================================================+
  -- | Name             : COPY_CONCATENATE_DETAIL                                       |
  -- | Description      : This procedure copies data into the table                     |
  -- |                     XX_CDH_EBL_TEMPL_DTL only for eTXT Documents                 |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_CONCATENATE_DETAIL(
                            p_scust_doc_id IN NUMBER
                            ,p_dcust_doc_id IN NUMBER
                           );
  -- +==================================================================================+
  -- | Name             : COPY_SPLIT_DETAIL                                             |
  -- | Description      : This procedure copies data into the table                     |
  -- |                     XX_CDH_EBL_TEMPL_DTL only for eTXT Documents                 |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_SPLIT_DETAIL(
                            p_scust_doc_id IN NUMBER
                            ,p_dcust_doc_id IN NUMBER
                           );
  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_DETAIL_ETXT                                        |
  -- | Description      : This procedure copies data into the table                     |
  -- |                     XX_CDH_EBL_TEMPL_DTL only for eTXT Documents                 |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_TEMPL_DETAIL_ETXT (   p_scust_doc_id IN NUMBER
                                    ,p_dcust_doc_id IN NUMBER
                                 );
  -- +==================================================================================+
  -- | Name             : COPY_EBL_CONTACTS                                             |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_CONTACTS                                          |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_EBL_CONTACTS(
                             p_scust_doc_id  IN NUMBER
                            ,p_dcust_doc_id  IN NUMBER
                            ,p_scust_acct_id IN NUMBER
                            ,p_dcust_acct_id IN NUMBER
                           );

  -- +==================================================================================+
  -- | Name             : COPY_EBL_FILE_NAME_DTL                                        |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                    XX_CDH_EBL_FILE_NAME_DTL                                      |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_EBL_FILE_NAME_DTL( p_scust_doc_id IN NUMBER
                                 ,p_dcust_doc_id IN NUMBER
                                );


  -- +==================================================================================+
  -- | Name             : COPY_EBL_STD_AGGR_DTL                                         |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                    XX_CDH_EBL_STD_AGGR_DTL                                       |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_EBL_STD_AGGR_DTL(  p_scust_doc_id IN NUMBER
                                 ,p_dcust_doc_id IN NUMBER
                               );

END XX_CDH_EBL_COPY_PKG;
/
SHOW ERRORS;
EXIT;
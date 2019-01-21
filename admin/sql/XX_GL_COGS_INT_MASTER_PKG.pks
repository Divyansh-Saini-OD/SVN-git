SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON
PROMPT Creating PACKAGE Body XX_GL_COGS_INT_MASTER_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_GL_COGS_INT_MASTER_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_COGS_INT_MASTER_PKG                                 |
-- | Description      :  This PKG will be used to COGS interfaces      |
-- |                     data feed with with the Oracle GL             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       06-25/2007  P.Marco          Initial draft version       |
-- |1.1       24-JUNE-08  Raji             Added values for defect 8242|
-- |1.2       10-AUG-08   Srividya         Changes for Defect 9696     |
-- |1.3       16-Mar-2010 Priyanka N       Modified for CR 661         |
-- |                                       RICE I2119                  |
-- +===================================================================+
-- +===================================================================+
-- | Name         :XX_DERIVE_LOB_TEST                                  |
-- | Description  :This Funtion will fetch the LOB values              |
-- |               corresponding to the location from the              |
-- |               translation 'XX_RA_COGS_LOB_VALUES'                 |
-- |                                                                   |
-- | Parameters   :Location                                            |
-- | Returns      :LOB                                                 |
-- +===================================================================+
    FUNCTION XX_DERIVE_LOB_TEST(p_location IN VARCHAR2)
    RETURN NUMBER;
-- +===================================================================+
-- | Name         : PROCESS_JOURNALS_CHILD                             |
-- | Description  : The main controlling procedure for the COGS        |
-- |                interfaces.It inserts data into the                |
-- |                XX_GL_INTERFACE_NA_STG Table                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name,p_debug_flg,p_debug_flg,p_batch_size    |
-- |             p_cust_trx_id_low,p_cust_trx_id_high,p_gl_date_low    |
-- |             p_otc_cycle_run_date,p_otc_cycle_wave_num             |
-- |                                                                   |
-- | Returns : x_return_code, x_return_message                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE PROCESS_JOURNALS_CHILD  (x_return_message          OUT  VARCHAR2
                                      ,x_return_code             OUT  VARCHAR2
                                      ,p_source_name             IN   VARCHAR2
                                      ,p_debug_flg               IN   VARCHAR2
                                      ,p_batch_size              IN   NUMBER
                                      ,p_cust_trx_id_low         IN   NUMBER
                                      ,p_cust_trx_id_high        IN   NUMBER
                                      ,p_gl_date_low             IN   VARCHAR2
                                      ,p_gl_date_high            IN   VARCHAR2
                                      ,p_otc_cycle_run_date      IN   VARCHAR2                   --Added for CR 661
                                      ,p_otc_cycle_wave_num      IN   NUMBER                     --Added for CR 661
                                    );
-- +===================================================================+
-- | Name  : XX_GL_COGS_INT_MASTER_PROC                                |
-- | Description  : The procedure used to for running mulitple threads |
-- |                of COGS program                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name,p_debug_flg,p_batch_size,               |
-- |             p_set_of_books_id ,p_gl_date_low,p_gl_date_high,      |
-- |             p_otc_cycle_run_date,p_otc_cycle_wave_num             |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message, x_return_code                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_GL_COGS_INT_MASTER_PROC(
                                        x_return_message     OUT  VARCHAR2
                                       ,x_return_code        OUT  VARCHAR2
                                       ,p_source_name        IN   VARCHAR2
                                       ,p_debug_flg          IN   VARCHAR2
                                       ,p_batch_size         IN   NUMBER
                                       ,p_set_of_books_id    IN   NUMBER
                                       ,p_gl_date_low        IN   VARCHAR2
                                       ,p_gl_date_high       IN   VARCHAR2
                                       ,p_otc_cycle_run_date IN   VARCHAR2                             --Added for CR 661
                                       ,p_otc_cycle_wave_num IN   NUMBER                               --Added for CR 661
                                       ,p_submit_exception_report IN VARCHAR2                          --Added for Defect 3098 on 27-APR-10
                                       );
-----------------------------------------------------------------------------------------------------
----------------------Commeneted for CR 661 Starts --------------------------------------------------
-----------------------------------------------------------------------------------------------------
/*-- +===================================================================+
-- | Name  :XX_CONCAT_EMAIL_OUTPUT                                     |
-- | Description      :  This local procedure will submit concurrent   |
-- |                     program XXODCOGSM to email the concatenated   |
-- |                     output file.                                  |
-- |                     p_email_lookup is value on tranlation lookup  |
-- |                     Table                                         |
-- |                                                                   |
-- | Parameters : p_request_id, p_email_lookup, p_email_subject        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   x_return_message, x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE XX_CONCAT_EMAIL_OUTPUT (
                                      p_request_id       IN  NUMBER
                                     ,p_email_lookup     IN VARCHAR2
                                     ,p_email_subject    IN VARCHAR2
                                    ) ;
PROCEDURE XX_CONCAT_EMAIL_OUTPUT (p_email_lookup     IN VARCHAR2
                                 ,x_temp_email      OUT VARCHAR2);
   PROCEDURE XX_CONCAT_EMAIL_OUTPUT (p_request_id       IN  NUMBER
                                    ,p_email_lookup     IN VARCHAR2
                                    ,p_email_subject    IN VARCHAR2
                                    );*/
-----------------------------------------------------------------------------------------------------
----------------------Commeneted for CR 661 Ends ----------------------------------------------------
-----------------------------------------------------------------------------------------------------
----------------Procedure Specfications Added for CR 661 Starts -------------------------------------
-- +===================================================================+
-- | Name  :PROCESS_JRNL_LINES                                         |
-- | Description : The main processing procedure.  After records are   |
-- |               inserted in the staging table using the             |
-- |               PROCESS_JOURNALS_CHILD, you can call the            |
-- |               PROCESS_JRNL_LINES process to validate, copy        |
-- |               import the JE lines into HV GL.INTERFACE and        |
-- |               HV CONTROL tables                                   |
-- |                                                                   |
-- | Parameters : p_group_id,p_source_nm,p_err_cnt,p_debug_flag,       |
-- |              p_otc_cycle_run_date,p_otc_cycle_wave_num            |
-- |             ,p_period_name,p_parent_request_id                    |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE  PROCESS_JRNL_LINES (p_group_id             IN       NUMBER
                                  ,p_source_nm            IN       VARCHAR2
                                  ,p_debug_flag           IN       VARCHAR2
                                  ,p_otc_cycle_run_date   IN       VARCHAR2
                                  ,p_otc_cycle_wave_num   IN       NUMBER
                                  ,p_period_name          IN       VARCHAR2
                                  ,p_parent_request_id    IN       NUMBER
                                   );
-- +===================================================================+
-- | Name         :DEBUG_MESSAGE                                       |
-- | Description  :  This local procedure will write debug state-      |
-- |                     ments to the log file if debug_flag is Y      |
-- |                                                                   |
-- | Parameters   :p_message (msg written), p_spaces (# of blank lines)|
-- |                                                                   |
-- +===================================================================+
    PROCEDURE DEBUG_MESSAGE (p_message  IN  VARCHAR2
                            ,p_spaces   IN  NUMBER  DEFAULT 0
                            );
-- +===================================================================+
-- | Name        :LOG_MESSAGE                                          |
-- | Description :  This procedure will be used to write record to the |
-- |                xx_gl_interface_na_log table.                      |
-- |                                                                   |
-- | Parameters  : p_grp_id,p_source_nm,p_status,p_details,p_debug_flag|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE  LOG_MESSAGE (p_grp_id         IN NUMBER   DEFAULT NULL
                           ,p_source_nm       IN VARCHAR2 DEFAULT NULL
                           ,p_status         IN VARCHAR2 DEFAULT NULL
                           ,p_details        IN VARCHAR2 DEFAULT NULL
                           ,p_debug_flag     IN VARCHAR2 DEFAULT NULL
                            );
-- +===================================================================+
-- | Name         :XX_VALIDATE_STG_PROC                                |
-- | Description  :This Procedure will validate the records            |
-- |                     which will be fetch  from the AR tables       |
-- | Parameters   :p_group_id                                         |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_VALIDATE_STG_PROC(p_group_id IN NUMBER);
-- +===================================================================+
-- | Name          :UPDATE_COGS_FLAG                                   |
-- | Description   :This Procedure will update the COGS Generated Flag |
-- |                for valid COGS journal entries                     |
-- |                                                                   |
-- | Parameters    :p_group_id,p_sob_id,p_source_nm                    |
-- |                                                                   |
-- |                                                                   |
-- | Returns       :x_output_msg                                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE UPDATE_COGS_FLAG   (p_group_id   IN NUMBER
                                 ,p_sob_id     IN NUMBER
                                 ,p_source_nm  IN VARCHAR2
                                 ,x_output_msg OUT VARCHAR2
                                 );
-- +===========================================================================+
-- | Name  :       CREATE_OUTPUT                                               |
-- | Description  :This Procedure will Print the Output for the Master         |
-- |               and Child Program                                           |
-- |                                                                           |
-- | Parameters :    p_source_name,p_debug_flag,p_batch_size,                  |
-- |                ,p_set_of_books_id,p_gl_date_low,p_gl_date_high,           |
-- |                ,p_otc_cycle_run_date,p_otc_cycle_wave_num                 |
-- |                ,p_parent_request_id ,p_cust_trx_low,p_cust_trx_high       |
-- +===========================================================================+
    PROCEDURE  CREATE_OUTPUT   (p_source_name             IN   VARCHAR2
                               ,p_debug_flag              IN   VARCHAR2
                               ,p_batch_size              IN   NUMBER
                               ,p_set_of_books_id         IN   NUMBER
                               ,p_gl_date_low             IN   VARCHAR2
                               ,p_gl_date_high            IN   VARCHAR2
                               ,p_otc_cycle_run_date      IN   VARCHAR2
                               ,p_otc_cycle_wave_num      IN   NUMBER
                               ,p_parent_request_id       IN   NUMBER
                               ,p_child_request_id        IN   NUMBER
                               ,p_cust_trx_low            IN   NUMBER
                               ,p_cust_trx_high           IN   NUMBER
                              );
-- +===================================================================+-------Procedure Added as part of Defect #3098 on 27-APR-10
-- | Name  :XX_EXCEPTION_REPORT_PROC                                   |
-- | Description      :  This Procedure will Submit request for the    |
-- |                     Report which will fetch  the  Invalid records |
-- |                     from the staging table                        |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_EXCEPTION_REPORT_PROC;
-- +===================================================================+
-- | Name          : GET_CODE_COMBINATION_ID                           |
-- | Description   : This Function will be used to fetch               |
-- |                 Code_combiantion_Id                               |
-- | Parameters    : Segment1,Segment2,Segment3,Segment4,Segment5      |
-- |                 Segmnet6,Segment7                                 |
-- |                                                                   |
-- | Returns       : Code_Combination_Id                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    FUNCTION GET_CODE_COMBINATION_ID (p_segment1 VARCHAR2
                                     ,p_segment2 VARCHAR2
                                     ,p_segment3 VARCHAR2
                                     ,p_segment4 VARCHAR2
                                     ,p_segment5 VARCHAR2
                                     ,p_segment6 VARCHAR2
                                     ,p_segment7 VARCHAR2
                                     )
   RETURN NUMBER;
-- +===================================================================+
-- | Name          : DERIVE_COMPANY_FROM_LOCATION                      |
-- | Description   : This Function will be used to fetch Company       |
-- |                    ID for a Location    (APPS.FND_FLEX_VALUES     |
-- |                     _VL.flex_value) Segment4                      |
-- | Parameters    : Location (Segment4)                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns       : Company                                           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    FUNCTION DERIVE_COMPANY_FROM_LOCATION(p_location IN VARCHAR2)
    RETURN VARCHAR2;
----------------Procedure Specfications Added for CR 661 Ends -------------------------------------
END XX_GL_COGS_INT_MASTER_PKG;
/
SHO ERR;
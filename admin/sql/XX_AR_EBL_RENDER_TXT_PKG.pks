SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_EBL_RENDER_TXT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_AR_EBL_RENDER_TXT_PKG AS
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : RENDER_TXT_P                                                                |
-- | Description : This Procedure is used for multithreading the etxt data into                |
-- |               batches and to submit the child procedure RENDER_TXT_C                      |
-- |Parameters   : p_billing_dt                                                                |
-- |             , p_debug_flag                                                                |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
-- |                                               (Master Defect#37585)                       |
-- +===========================================================================================+
  PROCEDURE RENDER_TXT_P (
    Errbuf                  OUT NOCOPY VARCHAR2
   ,Retcode                 OUT NOCOPY VARCHAR2
   ,p_billing_dt            IN VARCHAR2
   ,p_debug_flag            IN VARCHAR2
  );
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : RENDER_TXT_C                                                        |
-- | Description : This Procedure is used for framing the dynamic query to fetch data  |
-- |               from the Configuration tables and to write the data into TXT File   |
-- |Parameters   : p_thread_id                                                         |
-- |             , p_thread_count                                                      |
-- |             , p_debug_flag                                                        |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
  PROCEDURE RENDER_TXT_C (
    p_errbuf                OUT NOCOPY VARCHAR2
   ,p_retcode               OUT NOCOPY VARCHAR2
   ,p_thread_id             IN NUMBER
   ,p_thread_count          IN NUMBER
   ,p_debug_flag            IN VARCHAR2
  );
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : GET_FORMATTED_ETXT_COLUMN                                             |
-- | Description : This Function is used for framing the column with start and end       |
-- |               positions with right/left justification based on configuration tables |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_justify                                                             |
-- |             , p_start_position                                                      |
-- |             , p_end_position                                                        |
-- |             , p_fill_txt                                                            |
-- |             , p_column_name                                                         |
-- |             , p_debug_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
-- +=====================================================================================+  
  FUNCTION GET_FORMATTED_ETXT_COLUMN(
    p_cust_doc_id    IN NUMBER
   ,p_alignment      IN VARCHAR2
   ,p_start_position IN NUMBER
   ,p_end_position   IN NUMBER 
   ,p_fill_txt       IN VARCHAR2 
   ,p_prepend_char   IN VARCHAR2
   ,p_append_char    IN VARCHAR2
   ,p_data_type      IN VARCHAR2
   ,p_data_format    IN VARCHAR2
   ,p_column_name    IN VARCHAR2
   ,p_debug_flag     IN VARCHAR2
   ,p_delimiter_char IN VARCHAR2
   ,p_label          IN VARCHAR2 DEFAULT NULL
  )
  RETURN VARCHAR2;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : GET_SORT_COLUMNS                                                      |
-- | Description : This Function is used for framing the sort columns                    |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_record_type                                                         |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
-- +=====================================================================================+  
  FUNCTION GET_SORT_COLUMNS(
    p_cust_doc_id    IN NUMBER
   ,p_record_type    IN VARCHAR2
  )
  RETURN VARCHAR2;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_HDR_SUMMARY_DATA                                           |
-- | Description : This Procedure is used for framing the sql based on                   |
-- |               Header Summary data and write it into TXT file.                       |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
-- +=====================================================================================+  
  PROCEDURE RENDER_TXT_HDR_SUMMARY_DATA(
    p_cust_doc_id     IN  NUMBER
   ,p_file_id         IN  NUMBER
   ,p_org_id          IN  NUMBER
   ,p_output_file     IN  UTL_FILE.FILE_TYPE
   ,p_file_creation_type  IN VARCHAR2
   ,p_delimiter_char      IN VARCHAR2
   ,p_debug_flag      IN  VARCHAR2
   ,p_hdr_error_flag      OUT  VARCHAR2
   ,p_hdr_error_msg       OUT  VARCHAR2
   );
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_DTL_DATA                                                   |
-- | Description : This Procedure is used for framing the sql based on                   |
-- |               Detail(Header/Lines/Dist Lines) data and write it into TXT file.      |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
-- +=====================================================================================+  
  PROCEDURE RENDER_TXT_DTL_DATA( 
    p_cust_doc_id     IN  NUMBER
   ,p_file_id         IN  NUMBER
   ,p_org_id          IN  NUMBER
   ,p_output_file     IN  UTL_FILE.FILE_TYPE
   ,p_file_creation_type  IN VARCHAR2
   ,p_delimiter_char      IN VARCHAR2
   ,p_debug_flag      IN  VARCHAR2
   ,p_dtl_error_flag      OUT  VARCHAR2
   ,p_dtl_error_msg       OUT  VARCHAR2
   ); 
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_TRL_DATA                                                   |
-- | Description : This Procedure is used for framing the sql based on                   |
-- |               Trailer Records data and write it into TXT file.                      |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
-- +=====================================================================================+    
  PROCEDURE RENDER_TXT_TRL_DATA( 
    p_cust_doc_id     IN  NUMBER
   ,p_file_id         IN  NUMBER
   ,p_org_id          IN  NUMBER
   ,p_output_file     IN  UTL_FILE.FILE_TYPE
   ,p_file_creation_type  IN VARCHAR2
   ,p_delimiter_char      IN VARCHAR2
   ,p_debug_flag      IN  VARCHAR2
   ,p_trl_error_flag      OUT  VARCHAR2
   ,p_trl_error_msg       OUT  VARCHAR2
   ); 
   
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_HDR_CNT                                                   |
-- | Description : This Function is used for to get counts in Header                     |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
   
   FUNCTION  RENDER_TXT_HDR_CNT (
      p_cust_doc_id          IN     NUMBER,
      p_file_id              IN     NUMBER,
      p_rownum               IN NUMBER,
      p_org_id               IN     NUMBER,     
      p_file_creation_type   IN     VARCHAR2,
      p_delimiter_char       IN     VARCHAR2,
      p_debug_flag           IN     VARCHAR2,
      p_lbl_flag           IN     VARCHAR2   DEFAULT 'N' )
   RETURN NUMBER;

-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_TRL_CNT                                                   |
-- | Description : This Function is used for to get counts in TRL                     |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
        
FUNCTION  RENDER_TXT_TRL_CNT (
      p_cust_doc_id          IN     NUMBER,
      p_file_id              IN     NUMBER,
      p_rownum               IN NUMBER,
      p_org_id               IN     NUMBER,     
      p_file_creation_type   IN     VARCHAR2,
      p_delimiter_char       IN     VARCHAR2,
      p_debug_flag           IN     VARCHAR2 ,
      p_lbl_flag           IN     VARCHAR2  DEFAULT 'N'
       )
   RETURN NUMBER ;

-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_DTL_CNT                                                   |
-- | Description : This Function is used for to get counts in TRL                     |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+   
    
 FUNCTION RENDER_TXT_DTL_CNT (
      p_cust_doc_id          IN     NUMBER,
      p_file_id              IN     NUMBER,
      p_rownum               IN NUMBER,
      p_org_id               IN     NUMBER,     
      p_file_creation_type   IN     VARCHAR2,
      p_delimiter_char       IN     VARCHAR2,
      p_debug_flag           IN     VARCHAR2,
      p_lbl_flag           IN     VARCHAR2 DEFAULT 'N')
  RETURN NUMBER;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_INV_CNT                                                    |
-- | Description : This Function is used for to get counts in INV                        |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+  
FUNCTION  RENDER_TXT_INV_CNT (
      p_cust_doc_id          IN     NUMBER,
      p_file_id              IN     NUMBER,
      p_rownum               IN     NUMBER,
      p_org_id               IN     NUMBER,     
      p_file_creation_type   IN     VARCHAR2,
      p_delimiter_char       IN     VARCHAR2,
      p_debug_flag           IN     VARCHAR2,
      p_input_type           IN     VARCHAR2 )
   RETURN NUMBER;    
   
END XX_AR_EBL_RENDER_TXT_PKG;
/
SHOW ERRORS;
EXIT;

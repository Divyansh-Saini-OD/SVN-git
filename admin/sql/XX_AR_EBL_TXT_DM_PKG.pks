CREATE OR REPLACE PACKAGE XX_AR_EBL_TXT_DM_PKG
AS
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- +===================================================================================+
   -- | Name        : XX_AR_EBL_TXT_MASTER_PROG                                           |
   -- | Description : This Procedure is used for multithreading the etxt data into        |
   -- |               batches and to submit the child procedure XX_AR_EBL_TXT_CHILD_PROG  |
   -- |               for every batch                                                     |
   -- |Parameters   :  p_debug_flag                                                       |
   -- |               ,p_batch_size                                                       |
   -- |               ,p_thread_cnt                                                       |
   -- |               ,p_doc_type                                                         |
   -- |               ,p_cycle_date                                                       |
   -- |               ,p_delivery_method                                                  |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
   -- |                                               (Master Defect#37585)               |
   -- +===================================================================================+
   PROCEDURE XX_AR_EBL_TXT_MASTER_PROG (x_error_buff           OUT VARCHAR2,
                                        x_ret_code             OUT NUMBER,
                                        p_debug_flag        IN     VARCHAR2,
                                        p_batch_size        IN     NUMBER,
                                        p_thread_cnt        IN     NUMBER,
                                        p_doc_type          IN     VARCHAR2,
                                        p_cycle_date        IN     VARCHAR2,
                                        p_delivery_method   IN     VARCHAR2);

   -- +==================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- +===================================================================================+
   -- | Name        : XX_AR_EBL_TXT_CHILD_PROG                                            |
   -- | Description : This Procedure is used for framing the dynamic query to fetch data  |
   -- |               from the Configuration tables and to poplate the txt stagging tables|
   -- |Parameters   : p_batch_id                                                          |
   -- |             , p_doc_type                                                          |
   -- |             , p_debug_flag                                                        |
   -- |             , p_cycle_date                                                        |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
   -- +===================================================================================+
   PROCEDURE XX_AR_EBL_TXT_CHILD_PROG (x_error_buff      OUT VARCHAR2,
                                       x_ret_code        OUT NUMBER,
                                       p_batch_id     IN     NUMBER,
                                       p_doc_type     IN     VARCHAR2,
                                       p_debug_flag   IN     VARCHAR2,
                                       p_cycle_date   IN     VARCHAR2);

   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : PROCESS_TXT_HDR_SUMMARY_DATA                                                |
   -- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
   -- |               from the header summary table and to poplate the hdr txt stagging table     |
   -- |Parameters   : p_batch_id                                                                  |
   -- |             , p_cust_doc_id                                                               |
   -- |             , p_file_id                                                                   |
   -- |             , p_cycle_date                                                                |
   -- |             , p_org_id                                                                    |
   -- |             , p_debug_flag                                                                |
   -- |             , p_error_flag                                                                |
   -- |                                                                                           |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- |      1.1 15-DEC-2017  Aniket J CG             Changes for Defect #22772                   |
   -- +===========================================================================================+
   PROCEDURE PROCESS_TXT_HDR_SUMMARY_DATA (
      p_batch_id         IN     NUMBER,
      p_cust_doc_id      IN     NUMBER,
      p_file_id          IN     NUMBER,
      p_cycle_date       IN     VARCHAR2,
      p_org_id           IN     NUMBER,
      p_debug_flag       IN     VARCHAR2,
      p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
      p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
      p_hdr_error_flag      OUT VARCHAR2,
      p_hdr_error_msg       OUT VARCHAR2);

   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : PROCESS_TXT_DTL_DATA                                                        |
   -- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
   -- |               from the configuration detail table and to poplate the                      |
   -- |               dtl txt stagging table                                                      |
   -- |Parameters   : p_batch_id                                                                  |
   -- |             , p_cust_doc_id                                                               |
   -- |             , p_file_id                                                                   |
   -- |             , p_cycle_date                                                                |
   -- |             , p_org_id                                                                    |
   -- |             , p_debug_flag                                                                |
   -- |             , p_error_flag                                                                |
   -- |                                                                                           |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- |      1.1 15-DEC-2017  Aniket J CG             Changes for Defect #22772                   |
   -- +===========================================================================================+
   PROCEDURE PROCESS_TXT_DTL_DATA (p_batch_id         IN     NUMBER,
                                   p_cust_doc_id      IN     NUMBER,
                                   p_file_id          IN     NUMBER,
                                   p_cycle_date       IN     VARCHAR2,
                                   p_org_id           IN     NUMBER,
                                   p_debug_flag       IN     VARCHAR2,
                                   p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
                                   p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
                                   p_dtl_error_flag      OUT VARCHAR2,
                                   p_dtl_error_msg       OUT VARCHAR2);

   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : PROCESS_TXT_TRL_DATA                                                        |
   -- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
   -- |               from the configuration trailer table and to poplate the                     |
   -- |               trl txt stagging table                                                      |
   -- |Parameters   : p_batch_id                                                                  |
   -- |             , p_cust_doc_id                                                               |
   -- |             , p_file_id                                                                   |
   -- |             , p_cycle_date                                                                |
   -- |             , p_org_id                                                                    |
   -- |             , p_debug_flag                                                                |
   -- |             , p_error_flag                                                                |
   -- |                                                                                           |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- |      1.1 15-DEC-2017  Aniket J CG             Changes for Defect #22772                      |
   -- +===========================================================================================+
   PROCEDURE PROCESS_TXT_TRL_DATA (p_batch_id         IN     NUMBER,
                                   p_cust_doc_id      IN     NUMBER,
                                   p_file_id          IN     NUMBER,
                                   p_cycle_date       IN     VARCHAR2,
                                   p_org_id           IN     NUMBER,
                                   p_debug_flag       IN     VARCHAR2,
                                   p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
                                   p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
                                   p_trl_error_flag      OUT VARCHAR2,
                                   p_trl_error_msg       OUT VARCHAR2);

   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- +===================================================================================+
   -- | Name        : get_conc_field_names                                                |
   -- | Description : This function is used to build the sql columns with concatenated    |
   -- |               field names as per setup defined in the concatenation tab           |
   -- |Parameters   : cust_doc_id, concatenated_field_id                                  |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
   -- +===================================================================================+
   FUNCTION get_conc_field_names (p_cust_doc_id     IN NUMBER,
                                  p_conc_field_id   IN NUMBER,
                                  p_trx_type        IN VARCHAR2,
                                  p_record_type     IN VARCHAR2,
                                  p_debug_flag      IN VARCHAR2,
                                  p_file_id         IN NUMBER)
      RETURN VARCHAR2;

   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- +===================================================================================+
   -- | Name        : get_split_field_names                                               |
   -- | Description : This function is used to build the sql columns with split           |
   -- |               field names as per setup defined in the split tab                   |
   -- |Parameters   : cust_doc_id, p_base_field_id                                        |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
   -- +===================================================================================+
   FUNCTION get_split_field_names (p_cust_doc_id     IN NUMBER,
                                   p_base_field_id   IN NUMBER,
                                   p_count           IN NUMBER,
                                   p_trx_type        IN VARCHAR2,
                                   p_record_type     IN VARCHAR2,
                                   p_debug_flag      IN VARCHAR2)
      RETURN VARCHAR2;

   -- +===================================================================================+
   -- |                  Office Depot - Enhancement Requirement#2302                      |
   -- |                             CAPGEMINI                                             |
   -- +===================================================================================+
   -- | Name        : GET_DECODE_NDT                                                      |
   -- | Description : This function is used to concatenate the header coumns for which a  |
   -- |               non dt record has to be populated in a way as used in the code      |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 08-FEB-2017  Punit G                 Initial draft version               |
   -- +===================================================================================+
   FUNCTION get_decode_ndt (p_debug_flag IN VARCHAR2)
      RETURN VARCHAR2;

   -- +=============================================================================+
   -- |                         Office Depot - Enhancement Requirement#2302         |
   -- |                                CAPGEMINI                                    |
   -- +=============================================================================+
   -- | Name        : XX_AR_EBL_TXT_CHILD_NON_DT                                    |
   -- | Description : This Procedure is used to insert special columns into the TXT |
   -- |               stagging table in the order that the user selects from CDH    |
   -- |               for a NON-DT record type                                      |
   -- |                                                                             |
   -- | Parameters  :  p_cust_doc_id                                                |
   -- |               ,p_field_id                                                   |
   -- |               ,p_insert                                                     |
   -- |               ,p_select                                                     |
   -- |Change Record:                                                               |
   -- |===============                                                              |
   -- |Version   Date          Author                  Remarks                      |
   -- |=======   ==========   =============           ==============================|
   -- |DRAFT 1.0 08-FEB-2017  Punit G                  Initial draft version        |
   -- |      1.1 05-JUL-2017  Punit G                  Changes for Defect # 39140   |
   -- |      1.2 31-JUL-2017  Punit G                  Changes for Defect # 41307   |
  -- |       1.3 15-DEC-2017  Aniket J CG              Changes for Defect #22772      |
   -- +=============================================================================+
   PROCEDURE XX_AR_EBL_TXT_CHILD_NON_DT (p_cust_doc_id     IN     NUMBER,
                                         p_ebatchid        IN     NUMBER,
                                         p_file_id         IN     NUMBER,
                                         p_insert          IN     VARCHAR2,
                                         p_select          IN     VARCHAR2,
                                         p_seq_nondt       IN     VARCHAR2, -- Added by Punit for Defect #39140 on 05-JUL-2017
										                     p_rownum		   IN     NUMBER,   -- Added by Punit for Defect #41307 on 31-JUL-2017  
                                         p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
                                         p_doc_type        IN     VARCHAR2, --(CONS/IND)
                                         p_debug_flag      IN     VARCHAR2,
                                         p_insert_status      OUT VARCHAR2,
                                         p_cycle_date      IN     DATE);
END XX_AR_EBL_TXT_DM_PKG;
/
SHOW ERRORS;
EXIT;
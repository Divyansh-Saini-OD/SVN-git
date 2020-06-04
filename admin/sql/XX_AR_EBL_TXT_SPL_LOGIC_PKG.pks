create or replace PACKAGE XX_AR_EBL_TXT_SPL_LOGIC_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_total                                                     |
-- | Description : This function is used to get the total invoice amount for the       |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : p_cust_doc_id, p_file_id, p_org_id, p_field_name                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |                                               (Master Defect#37585)               |
-- |      1.1 15-Dec-2017  Aniket J      CG        Requirement# (22772)                |
-- |1.2       27-MAY-2020  Divyansh                Added Finction for JIRA NAIT-129167 |
-- +===================================================================================+
    FUNCTION get_grand_total (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               ,p_fun_combo_whr          IN VARCHAR2      DEFAULT NULL  --Added by Aniket CG #22772 on 15 Dec 2017
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_freight_amt                                               |
-- | Description : This function is used to get the total freight amount for           |
-- |               the given file_id and cust_doc_id                                   |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |      1.1 15-Dec-2017  Aniket J      CG        Requirement# (22772)                   |
-- +===================================================================================+
    FUNCTION get_grand_freight_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               ,p_fun_combo_whr          IN VARCHAR2   DEFAULT NULL  --Added by Aniket CG #22772 on 15 Dec 2017
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_misc_amt                                                  |
-- | Description : This function is used to get the total misslaneous amount for the   |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_misc_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_tax_amt                                                   |
-- | Description : This function is used to get the total tax amount for the           |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_tax_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_grand_gift_card_amt                                             |
-- | Description : This function is used to get the total tax amount for the           |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_grand_gift_card_amt (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_dist_class                                                      |
-- | Description : This function is used to derive the distribution class value        |
-- |               based on cost center                                                |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : p_cust_doc_id, p_file_id, p_org_id, p_field_name                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_dist_class (p_cust_doc_id IN NUMBER
                            ,p_file_id IN NUMBER
                            ,p_org_id  IN NUMBER
                            ,p_field_name IN VARCHAR2
                            )
    RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_current_seq_num                                                 |
-- | Description : This function is used to get the total invoice amount for the       |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : p_cust_doc_id, p_file_id, p_org_id, p_field_name                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_current_seq_num (p_cust_doc_id IN NUMBER
                              ,p_file_id IN NUMBER
                              ,p_org_id  IN NUMBER
                              ,p_field_name IN VARCHAR2
                              )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_total_inv_lines                                                 |
-- | Description : This function is used to get the total tax amount for the           |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_total_inv_lines(p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_quarter_num                                                     |
-- | Description : This function is used to get the Calender year Quarter Number       |
-- |               from the Invoice Bill Date for the given file_id and cust_doc_id    |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_quarter_num (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_requestor_first_name                                            |
-- | Description : This function is used to get the first name of the contact name     |
-- |               for the given file_id and cust_doc_id                               |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_requestor_first_name (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN VARCHAR2;
	-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_total_inv_lines                                                 |
-- | Description : This function is used to get the total invoice lines counts for the |
-- |               given file_id and cust_doc_id                                       |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 03-MAY-2018  Aniket J                Initial draft version #NAIT-36070   |
-- +===================================================================================+
    FUNCTION get_total_rec_count (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               )
    RETURN NUMBER ;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_fee_amount                                                      |
-- | Description : This function is used to get the total fee amount                   |
-- |Parameters   : cust_doc_id, file_id                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- | 1.0      03-APR-2020  Divyansh Saini          Initial draft version #NAIT-129167  |
-- +===================================================================================+
	FUNCTION get_fee_amount (p_cust_doc_id IN NUMBER
                               ,p_file_id IN NUMBER
                               ,p_org_id  IN NUMBER
                               ,p_field_name IN VARCHAR2
                               ) 
    RETURN NUMBER;
 END XX_AR_EBL_TXT_SPL_LOGIC_PKG;
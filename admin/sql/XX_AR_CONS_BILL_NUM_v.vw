SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                            Office Depot                            |
-- +====================================================================+
-- | Name  : XX_AR_CONS_BILL_NUM_V                                      |
-- | Description: Custom view for the Value set to fetch the Cons Bill  |
-- |              in addition to the cut_off_date and site sequence     |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date         Author             Remarks                   |
-- |=======   ==========   =============      ==========================|
-- |1.0       06-JAN-2009  Gokila Tamilselvam Initial version           |
-- |1.1       24-MAY-2010  Gokila Tamilselvam Modified for R 1.4 CR 586.|
-- |1.2       10-JUN-2014  Arun Gannarapu     Modified for 30509 defect |
-- +===================================================================+|
 CREATE OR REPLACE VIEW XX_AR_CONS_BILL_NUM_V AS 
 (
 SELECT  ACI.cons_billing_number                      CBI_NUM
        ,ACI.cons_inv_id                              CBI_ID
        ,(TO_DATE(ACI.attribute1) - 1)                CUT_OFF_DATE
        ,HCSU.orig_system_reference                   SITE_SEQ
        ,'Y'                                          PAYDOC_FLAG
        ,'PAYDOC'                                     DOC_TYPE
        ,ACI.site_use_id                              SITE_USE_ID
        ,ACI.customer_id                              CUST_ID
 FROM    ar_cons_inv        ACI
        ,hz_cust_site_uses  HCSU
 WHERE   ACI.site_use_id = HCSU.site_use_id
 AND     ACI.status      IN ( 'ACCEPTED' , 'FINAL')
 AND     EXISTS ( SELECT 1
                  FROM   ar_cons_inv_trx_all
                  WHERE  cons_inv_id = ACI.cons_inv_id
                  )
 UNION
 SELECT  XACBH.attribute6                             CBI_NUM
        ,TO_NUMBER(XACBH.attribute16)                 CBI_ID
        ,XACBH.bill_from_date                         CUT_OFF_DATE
        ,HCSU.orig_system_reference                   SITE_SEQ
        ,'N'                                          PAYDOC_FLAG
        ,XACBH.attribute8                             DOC_TYPE
        ,TO_NUMBER(XACBH.attribute7)                  SITE_USE_ID
        ,XACBH.customer_id                            CUST_ID
 FROM    xx_ar_cons_bills_history XACBH
        ,hz_cust_site_uses        HCSU
 WHERE   XACBH.attribute8   IN ('PAYDOC_IC','INV_IC')
 AND     XACBH.process_flag = 'Y'
 AND     XACBH.attribute7   = HCSU.site_use_id
 UNION
 SELECT  XAGBLA.c_ext_attr2                           CBI_NUM
        ,XAGBLA.n_ext_attr2                           CBI_ID
        ,XAGBLA.issue_date                            CUT_OFF_DATE
        ,HCSU.orig_system_reference                   SITE_SEQ
        ,'N'                                          PAYDOC_FLAG
        ,XAGBLA.c_ext_attr1                           DOC_TYPE
        ,XAGBLA.billing_site_id                       SITE_USE_ID
        ,XAGBLA.customer_id                           CUST_ID
 FROM    xx_ar_gen_bill_lines_all XAGBLA
        ,hz_cust_site_uses        HCSU
 WHERE   XAGBLA.c_ext_attr1     IN ('PAYDOC_IC','INV_IC')
 AND     XAGBLA.processed_flag  = 'Y'
 AND     XAGBLA.billing_site_id = HCSU.site_use_id
 AND     XAGBLA.n_ext_attr2     IS NOT NULL
 AND     XAGBLA.c_ext_attr2     IS NOT NULL
 --Added for R 1.4 CR 586.
 UNION
 SELECT  XAECHH.consolidated_bill_number              CBI_NUM
        ,XAECHH.cons_inv_id                           CBI_ID
        ,XAECHH.bill_to_date                          CUT_OFF_DATE
        ,HCSU.orig_system_reference                   SITE_SEQ
        ,'N'                                          PAYDOC_FLAG
        ,XAECHH.infocopy_tag                          DOC_TYPE
        ,XAECHH.bill_to_site_use_id                   SITE_USE_ID
        ,XAECHH.cust_account_id                       CUST_ID
 FROM    xx_ar_ebl_cons_hdr_hist  XAECHH
        ,hz_cust_site_uses        HCSU
 WHERE   XAECHH.infocopy_tag            IN ('PAYDOC_IC','INV_IC')
 AND     XAECHH.bill_to_site_use_id     = HCSU.site_use_id
 -- End of changes for R 1.4 CR 586.
 )

/
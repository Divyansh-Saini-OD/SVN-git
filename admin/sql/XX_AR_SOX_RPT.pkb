SET SHOW OFF
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_AR_SOX_RPT

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE BODY XX_AR_SOX_RPT
AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                         Wipro Technology                                      |
-- +===============================================================================+
-- | Name         : XX_AR_SOX_RPT                                                  |
-- | Description  : This package is used to get the Daily Invoices count           |
-- |                and amount for all billing methods (Certegy, EDI,              |
-- |                EBill and Special Handling)                                    |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version  Date         Author                Remarks                            |
-- |=======  ===========  =============         ===================================|
-- | 1       03-MAR-2010  Lincy K               Initial version                    |
-- |                                            Defects 2348 and 1676              |
-- | 1.1     15-APR-2010  Sambasiva Reddy D     Defects 2348 and 1676              |
-- | 1.2     15-JUN-2010  Ranjith Thangasamy    Defect 2811 CR 586                 |
-- | 1.3     27-JUN-2010  Abdul Khan            Defect 11836                       |
-- | 1.4     18-JUN-2015  Shravya Gattu         Defect 34796                       |
-- | 1.5     19-OCT-2015  Vasu Raparla          Removed Schema References for 12.2 |                      
-- | 1.6     29-APR-2016  Suresh Naragam        Changes as part of Mod 4B          |
-- |                                            Release 4 (SIT Defect#2177)        |
-- | 1.7     06-JUL-2018  M Rakesh Reddy		Modified for Defect #44270		   |
-- | 1.8     17-SEP-2018  Sangita Deshmukh      Defect (NAIT-56624) 			   |
-- | 1.9     10-OCT-2019  M Rakesh Reddy        Modified to include SKU 		   |	
-- |											Defect#105482                      |
-- +===============================================================================+

-- +====================================================================+
-- | Name       : XX_AR_SOX_CALC                                        |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_delivery_method, p_print_date, p_requests_id        |
-- |              p_email_address and  p_sender_address                 |
-- |                                                                    |
-- | Returns :   x_errbuf, x_ret_code                                   |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+

PROCEDURE XX_AR_SOX_CALC (x_errbuf              OUT    VARCHAR2
                          ,x_ret_code           OUT    NUMBER
                          ,p_delivery_method    IN     VARCHAR2
                          ,p_print_date         IN     VARCHAR2
                          ,p_email_address      IN     VARCHAR2
                          ,p_sender_address     IN     VARCHAR2)
AS

lc_error_loc          VARCHAR2(2000);
lc_prog_name          fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
lc_child_prog_name1     fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
lc_child_prog_name2    fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
lc_child_prog_name3     fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
lc_child_prog_name4    fnd_concurrent_programs_vl.concurrent_program_name%TYPE;  --added for SKU lines NAIT-105482

ln_invoice_total      NUMBER:=0;
ln_total_amount       NUMBER:=0;

lc_email_subject      VARCHAR2(250);
lc_email_address      VARCHAR2(250);
ln_conc_request_id    NUMBER;
lc_sender_address     VARCHAR2(250);

lv_country            VARCHAR2(10);

ln_org_id             NUMBER;
ln_this_request_id    NUMBER;
ld_print_date         DATE;
lv_conc_prog_name     fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;

ln_first_cbi_id       NUMBER:=0;
ln_first_cbi_pd       NUMBER:=0;
ln_first_inv_id       NUMBER:=0;
ln_first_inv_pd       NUMBER:=0;
ln_inv_id_flg         NUMBER:=0;
ln_inv_pd_flg         NUMBER:=0;
ln_cbi_id_flg         NUMBER:=0;
ln_cbi_pd_flg         NUMBER:=0;
ln_time_delay		  NUMBER:=0; --Added for the defect #44270

TYPE t_reqid IS TABLE OF NUMBER;
ln_req_id  t_reqid;

TYPE t_req_date IS TABLE OF VARCHAR2(30);
lv_req_start  t_req_date;
lv_req_end    t_req_date;

TYPE t_conc_prog IS TABLE OF VARCHAR2(240);
lv_conc_name  t_conc_prog;

TYPE t_threadid IS TABLE OF VARCHAR2(30);
lv_thread_id  t_threadid;

TYPE t_sox_output IS RECORD (
         ou                 VARCHAR2(3)
         ,inv_type          VARCHAR2(5)
         ,doc_type          VARCHAR2(5)
         ,req_id            NUMBER
         ,prog_name         VARCHAR2(100)
         ,start_time        VARCHAR2(25)
         ,end_time          VARCHAR2(25)
         ,total_cust        NUMBER
         ,total_inv         NUMBER
         ,total_amount      NUMBER
       );

TYPE t_sox_op_type IS TABLE OF t_sox_output;

lr_sox_cbi_id_op t_sox_op_type := t_sox_op_type();
lr_sox_cbi_pd_op t_sox_op_type := t_sox_op_type();
lr_sox_inv_id_op t_sox_op_type := t_sox_op_type();
lr_sox_inv_pd_op t_sox_op_type := t_sox_op_type();

CURSOR lcu_cert_inv (p_request_id IN NUMBER, p_org_id IN NUMBER )
   IS
      SELECT 'INV'                                                          inv_type
             ,'PD'                                                          doc_type
             ,COUNT( DISTINCT CERT_IND.bill_to_customer_id)                 tot_cust
             ,COUNT(CERT_IND.paydoc_flag)                                   tot_inv
             ,SUM((SELECT SUM(RCTL.extended_amount )
                   FROM ra_customer_trx_lines_all  RCTL             --Removed apps Schema reference
                   WHERE RCTL.customer_trx_id =CERT_IND.invoice_id
                   )+
                   (SELECT NVL(SUM(DECODE(RCTT.type
                                          ,'CM',  CERT_IND.attribute4
                                          , 'INV',-1*CERT_IND.attribute4
                                         )
                                   )
                               ,0
                              ) 
                   FROM ra_customer_trx_all RCT                             --Removed apps Schema reference
                        ,ra_cust_trx_types_all RCTT                         --Removed apps Schema reference
                   WHERE  RCT.customer_trx_id  = CERT_IND.invoice_id
                   AND    RCT.cust_trx_type_id = RCTT.cust_trx_type_id
                   )
                  )                                                         tot_amount
      FROM
      (SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */  -- Added hint on 15-APR-10, Corrected Hint syntax for Defect 11836
             XAIF.invoice_id
            ,XAIF.attribute4
            ,XAIF.bill_to_customer_id
            ,XAIF.paydoc_flag
       FROM   xx_ar_invoice_freq_history  XAIF                      --Removed apps Schema reference
       WHERE  XAIF.attribute1 = to_char(p_request_id)  -- Added to_char so that index is used -- Defect 11836
       AND    XAIF.org_id               = p_org_id
       AND    XAIF.doc_delivery_method  = 'PRINT'
       AND    XAIF.printed_flag         = 'Y'
       AND    XAIF.paydoc_flag='Y'
       AND    XAIF.billdocs_special_handling IS NULL)CERT_IND
      UNION ALL
      SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */  -- Added hint on 15-APR-10, Corrected Hint syntax for Defect 11836
               'INV'                                                          inv_type 
              ,'ID'                                                         doc_type 
              ,COUNT(distinct XAIF.bill_to_customer_id)                     tot_cust
              ,COUNT(paydoc_flag)                                           tot_inv
              ,0                                                            tot_amount
      FROM   xx_ar_invoice_freq_history  XAIF         --Removed apps Schema reference
      WHERE  XAIF.attribute1 = to_char(p_request_id)  -- Added to_char so that index is used -- Defect 11836
      AND    XAIF.org_id               = p_org_id
      AND    XAIF.doc_delivery_method  = 'PRINT'
      AND    XAIF.printed_flag         = 'Y'
      AND    XAIF.paydoc_flag='N'
      AND    XAIF.billdocs_special_handling IS NULL;

CURSOR lcu_cert_cons (p_thread_id IN VARCHAR2,p_org_id IN NUMBER )
   IS
      SELECT  /*+ INDEX (XACB XX_AR_CONS_BILLS_HISTORY_N7) */  -- Added hint on 15-apr-10
              'CBI'                                                          inv_type   
             ,'PD'                                                          doc_type   
             ,COUNT( DISTINCT XACB.customer_id)                             tot_cust   
             ,COUNT(XACB.paydoc)                                            tot_inv    
             ,NVL(SUM(XACB.attribute14),0)                                  tot_amount  
      FROM     xx_ar_cons_bills_history_all XACB                    --Removed xfin Schema reference
      WHERE    XACB.thread_id= p_thread_id
      AND   XACB.org_id              = p_org_id
      AND   XACB.delivery            = 'PRINT'
      AND   XACB.process_flag        = 'Y'
      AND   XACB.paydoc              = 'Y'
      AND XACB.thread_id > 0 
      UNION ALL          
      SELECT  /*+ INDEX (XACB XX_AR_CONS_BILLS_HISTORY_N7) */  -- Added hint on 15-apr-10
              'CBI'                                                          inv_type  
             ,'ID'                                                          doc_type  
             ,COUNT( DISTINCT XACB.customer_id)                             tot_cust  
             ,COUNT(DISTINCT XACB.cons_inv_id)                              tot_inv   
             ,0                                                             tot_amount
      FROM     xx_ar_cons_bills_history_all XACB              --Removed xxfin Schema reference
      WHERE   XACB.thread_id= p_thread_id
      AND   XACB.org_id              = p_org_id
      AND   XACB.delivery            = 'PRINT'
      AND   XACB.process_flag        = 'Y'
      AND   XACB.paydoc              = 'N'
      AND XACB.thread_id > 0;

CURSOR lcu_ebill (p_request_id IN NUMBER,p_org_id IN NUMBER ) 
   IS
      SELECT 'CBI'                                                          inv_type
             ,'PD'                                                          doc_type   
             ,COUNT( DISTINCT EBILL.customer_id)                            tot_cust   
             ,COUNT(EBILL.cons_inv_id)                                      tot_inv    
             ,SUM((SELECT SUM(extended_amount)                
                   FROM ra_customer_trx_lines_all RCTL,                     --Removed apps Schema reference
                        ar_cons_inv_trx_all       ACIT                      --Removed apps Schema reference
                   WHERE ACIT.cons_inv_id      = EBILL.cons_inv_id
                   AND   RCTL.customer_trx_id  = ACIT.customer_trx_id
                   )-
                  (SELECT   NVL(SUM(OP.payment_amount),0)
                   FROM     oe_payments         OP                      --Removed apps Schema reference
                           ,ra_customer_trx_all RCT                     --Removed apps Schema reference
                           ,ar_cons_inv_trx_all  ACIT                   --Removed apps Schema reference
                   WHERE    OP.header_id        = RCT.attribute14
                   AND      RCT.customer_trx_id = ACIT.customer_trx_id
                   AND      ACIT.cons_inv_id = EBILL.cons_inv_id
                  )
                 +
                  (SELECT   NVL(SUM(ORT.credit_amount),0)
                   FROM     xx_om_return_tenders_all ORT             --Removed apps Schema reference
                           ,ra_customer_trx_all      RCT             --Removed apps Schema reference
                           ,ar_cons_inv_trx_all  ACIT                --Removed apps Schema reference
                   WHERE    ORT.header_id       = RCT.attribute14
                   AND      RCT.customer_trx_id = ACIT.customer_trx_id
                   and      ACIT.cons_inv_id    = EBILL.cons_inv_id
                  )
                 )                                                          tot_amount
      FROM (SELECT  ACI.customer_id
                    ,ACI.cons_inv_id
      FROM  ar_cons_inv_all             ACI                         --Removed apps Schema reference
      WHERE SUBSTR(ACI.attribute4,INSTR(ACI.attribute4,'|')+1) = p_request_id
      AND   ACI.org_id                = p_org_id)EBILL
      UNION ALL
      SELECT 'CBI'                                                          inv_type
             ,'ID'                                                          doc_type  
             ,COUNT(DISTINCT XAGB.customer_id)                              tot_cust  
             ,COUNT(1)                                                      tot_inv   
             ,0                                                             tot_amount
      FROM  xx_ar_gen_bill_temp_all XAGB                              --Removed apps Schema reference
      WHERE  XAGB.request_id           = p_request_id
      AND    XAGB.org_id               = p_org_id;

CURSOR lcu_edi (p_request_id IN NUMBER,p_org_id IN NUMBER ) 
   IS

      SELECT 'INV'                                                          inv_type
             ,'PD'                                                          doc_type
             ,COUNT(DISTINCT EDI.bill_to_customer_id)                       tot_cust
             ,COUNT(EDI.paydoc)                                             tot_inv 
             ,SUM((SELECT SUM(extended_amount)
                   FROM  ra_customer_trx_lines_all         RCTL       --Removed apps Schema reference
                   WHERE RCTL.customer_trx_id = EDI.invoice_id
                  )
                  +
                  (SELECT NVL(SUM(DECODE(RCTT.type
                                 ,'CM',  EDI.attribute4
                                 , 'INV',-1*EDI.attribute4
                                         )
                                  )
                              ,0) amount
                    FROM  ra_customer_trx_all RCT                 --Removed apps Schema reference
                          ,ra_cust_trx_types_all RCTT             --Removed apps Schema reference
                    WHERE  RCT.customer_trx_id  = EDI.invoice_id
                    AND    RCT.cust_trx_type_id = RCTT.cust_trx_type_id
                   )
                  )                                                         tot_amount
      FROM (SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N3) */  -- Added hint on 15-APR-10,Corrected Hint syntax for Defect 11836
                     XAIF.paydoc_flag                           paydoc
                    ,XAIF.bill_to_customer_id                  bill_to_customer_id
                    ,XAIF.invoice_id
                    ,XAIF.attribute4
              FROM    xx_ar_invoice_freq_history   XAIF                  --Removed apps Schema reference
              WHERE   XAIF.request_id           = p_request_id
              AND     XAIF.org_id               = p_org_id
              AND     XAIF.doc_delivery_method  = 'EDI'
              AND   XAIF.paydoc_flag     = 'Y') EDI
      UNION ALL
      SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N3) */  -- Added hint on 15-APR-10,Corrected Hint syntax for Defect 11836
             'INV'                                                          inv_type  
             ,'ID'                                                          doc_type  
             ,COUNT(DISTINCT XAIF.bill_to_customer_id)                      tot_cust  
             ,COUNT(paydoc_flag)                                            tot_inv   
             ,0                                                             tot_amount
      FROM    xx_ar_invoice_freq_history   XAIF                   --Removed apps Schema reference
              WHERE   XAIF.request_id           = p_request_id
              AND     XAIF.org_id               = p_org_id
              AND     XAIF.paydoc_flag          = 'N'
              AND     XAIF.doc_delivery_method  = 'EDI';

CURSOR lcu_spl_inv (p_request_id IN NUMBER, p_org_id IN NUMBER ) 
   IS
      SELECT 'INV'                                                          inv_type  
             ,'PD'                                                          doc_type  
             ,COUNT(DISTINCT SPL_INV.bill_to_customer_id)                   tot_cust  
             ,COUNT(SPL_INV.paydoc_flag)                                    tot_inv   
             ,SUM((SELECT SUM(extended_amount)
                   FROM  ra_customer_trx_lines_all         RCTL             --Removed apps Schema reference
                   WHERE RCTL.customer_trx_id = SPL_INV.invoice_id
                  )
                  +
                  (SELECT NVL(SUM(DECODE(RCTT.type
                                 ,'CM',  SPL_INV.attribute4
                                 , 'INV',-1*SPL_INV.attribute4
                                         )
                                  )
                              ,0) amount
                    FROM  ra_customer_trx_all RCT                        --Removed apps Schema reference
                          ,ra_cust_trx_types_all RCTT                    --Removed apps Schema reference
                    WHERE  RCT.customer_trx_id  = SPL_INV.invoice_id
                    AND    RCT.cust_trx_type_id = RCTT.cust_trx_type_id
                   )
                  )                                                         tot_amount
      FROM (SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */  -- Added hint on 15-APR-10,Corrected Hint Syntax for Defect 11836
                     XAIF.paydoc_flag                           paydoc_flag
                    ,XAIF.bill_to_customer_id                  bill_to_customer_id
                    ,XAIF.invoice_id
                    ,XAIF.attribute4
              FROM    xx_ar_invoice_freq_history   XAIF                 --Removed apps Schema reference
              WHERE   XAIF.attribute1 = to_char(p_request_id)  -- Added to_char so that index is used -- Defect 11836
              AND     XAIF.org_id               = p_org_id
              AND     XAIF.doc_delivery_method  = 'PRINT'
              AND     XAIF.paydoc_flag          = 'Y'
              AND     XAIF.printed_flag         = 'Y'
              AND     XAIF.billdocs_special_handling IS NOT NULL)SPL_INV
      UNION ALL
      SELECT /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */  -- Added hint on 15-APR-10,Corrected Hint Syntax for Defect 11836
              'INV'                                                          inv_type  
             ,'ID'                                                          doc_type  
             ,COUNT(DISTINCT XAIF.bill_to_customer_id)                      tot_cust  
             ,COUNT(XAIF.paydoc_flag)                                       tot_inv   
             ,0                                                             tot_amount
      FROM    xx_ar_invoice_freq_history   XAIF                       --Removed apps Schema reference
      WHERE   XAIF.attribute1 = to_char(p_request_id)  -- Added to_char so that index is used -- Defect 11836
      AND     XAIF.org_id               = p_org_id
      AND     XAIF.doc_delivery_method  = 'PRINT'
      AND     XAIF.paydoc_flag          = 'N'
      AND     XAIF.printed_flag         = 'Y'
      AND     XAIF.billdocs_special_handling IS NOT NULL;

CURSOR lcu_spl_cons (p_request_id IN NUMBER, p_org_id IN NUMBER )
   IS
      SELECT 'CBI'                                                          inv_type
              ,'PD'                                                         doc_type
              ,COUNT ( DISTINCT SPL_CBI.customer_id)                        tot_cust  
              ,COUNT(SPL_CBI.cons_inv_id)                                   tot_inv  
              ,SUM((SELECT SUM(extended_amount)
                    FROM ra_customer_trx_lines_all RCTL,               --Removed apps Schema reference
                         ar_cons_inv_trx_all       ACIT                --Removed apps Schema reference
                    WHERE ACIT.cons_inv_id          = SPL_CBI.cons_inv_id
                    AND   RCTL.customer_trx_id      = ACIT.customer_trx_id
                    )-
                   (SELECT   NVL(SUM(OP.payment_amount),0)
                    FROM     oe_payments         OP                 --Removed apps Schema reference
                            ,ra_customer_trx_all RCT                --Removed apps Schema reference
                            ,ar_cons_inv_trx_all  ACIT              --Removed apps Schema reference
                    WHERE    OP.header_id        = RCT.attribute14
                    AND      RCT.customer_trx_id = ACIT.customer_trx_id
                    AND      ACIT.cons_inv_id = SPL_CBI.cons_inv_id
                   )
                  +
                   (SELECT   NVL(SUM(ORT.credit_amount),0)
                    FROM     xx_om_return_tenders_all ORT             --Removed apps Schema reference
                            ,ra_customer_trx_all      RCT             --Removed apps Schema reference
                            ,ar_cons_inv_trx_all  ACIT                --Removed apps Schema reference
                    WHERE    ORT.header_id       = RCT.attribute14
                    AND      RCT.customer_trx_id = ACIT.customer_trx_id
                    and      ACIT.cons_inv_id    = SPL_CBI.cons_inv_id
                   )
                  )                                                         tot_amount
      FROM  (SELECT ACI.cons_inv_id
                   ,ACI.customer_id
             FROM  ar_cons_inv_all             ACI                     --Removed apps Schema reference
             WHERE   ACI.org_id                = p_org_id
             AND     SUBSTR(ACI.attribute10,INSTR(ACI.attribute10,'|')+1) = to_char(p_request_id)  -- Added to_char so that index is used -- Defect 11836
             )SPL_CBI;

-- Below cursor added for Ebilling Cr 586 Defect 2811           
CURSOR lcu_ePDF_inv (p_request_id IN NUMBER,p_org_id IN NUMBER )
   IS
      SELECT   'INV'                                                        inv_type
              ,'PD'                                                         doc_type
              ,COUNT(distinct HIST.cust_account_id)                         tot_cust
              ,COUNT(HIST.customer_Trx_id)                                  tot_inv
              ,SUM(HIST.original_invoice_amount-total_gift_card_amount)     tot_amount
      FROM   xx_ar_ebl_ind_hdr_hist  HIST                               --Removed apps Schema reference
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id               = p_org_id
      AND    HIST.billdocs_delivery_method  = 'ePDF'
      AND    HIST.document_type='Paydoc'
      UNION ALL
      SELECT   'INV'                                                        inv_type
              ,'ID'                                                         doc_type
              ,COUNT(distinct HIST.cust_account_id)                     tot_cust
              ,COUNT(HIST.document_type)                                    tot_inv
              ,0                                                            tot_amount
      FROM   xx_ar_ebl_ind_hdr_hist  HIST                                 --Removed apps Schema reference
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id               = p_org_id
      AND    HIST.billdocs_delivery_method  = 'ePDF'
      AND    HIST.document_type='Infocopy';

-- Below cursor added for Ebilling Cr 586 defect 2811            
CURSOR lcu_ePDF_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER )
   IS
 SELECT       'CBI'                                                         inv_type
             ,'PD'                                                          doc_type
             ,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust
             ,COUNT(DISTINCT HIST.cons_inv_id)                              tot_inv
             ,SUM(HIST.original_invoice_amount-total_gift_card_amount)     tot_amount
      FROM      xx_ar_ebl_cons_hdr_hist HIST
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id     = p_org_id
      AND    HIST.billdocs_delivery_method  = 'ePDF'
      AND    HIST.document_type='Paydoc'
      UNION ALL
      SELECT  'CBI'                                                          inv_type
             ,'ID'                                                          doc_type
             ,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust
             ,COUNT(DISTINCT HIST.cons_inv_id)                              tot_inv
             ,0                                                              tot_amount
      FROM      xx_ar_ebl_cons_hdr_hist HIST
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id     = p_org_id
      AND    HIST.billdocs_delivery_method  = 'ePDF'
      AND    HIST.document_type='Infocopy';
      
-- Below cursor added for Ebilling Cr 586 defect 2811            

CURSOR lcu_eXLS_eTXT_inv (p_request_id IN NUMBER,p_org_id IN NUMBER,p_delivery_method IN VARCHAR2 )
   IS
      SELECT   'INV'                                                        inv_type
              ,'PD'                                                         doc_type
              ,COUNT(distinct HIST.cust_account_id)                         tot_cust
              ,COUNT(HIST.customer_Trx_id)                                  tot_inv
              ,SUM(HIST.original_invoice_amount-total_gift_card_amount)     tot_amount
      FROM   xx_ar_ebl_ind_hdr_hist  HIST                                  --Removed apps Schema reference
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id               = p_org_id
      AND    HIST.billdocs_delivery_method  = p_delivery_method
      AND    HIST.document_type='Paydoc'
      UNION ALL
      SELECT   'INV'                                                        inv_type
              ,'ID'                                                         doc_type
              ,COUNT(distinct HIST.cust_account_id)                     tot_cust
              ,COUNT(HIST.document_type)                                    tot_inv
              ,0                                                            tot_amount
      FROM   xx_ar_ebl_ind_hdr_hist  HIST                              --Removed apps Schema reference
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id               = p_org_id
      AND    HIST.billdocs_delivery_method  = p_delivery_method
      AND    HIST.document_type='Infocopy';

-- Below cursor added for Ebilling Cr 586 defect 2811            
CURSOR lcu_eXLS_eTXT_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_delivery_method IN VARCHAR2 )
   IS
 SELECT       'CBI'                                                         inv_type
             ,'PD'                                                          doc_type
             ,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust
             ,COUNT(DISTINCT HIST.cons_inv_id)                              tot_inv
             ,SUM(HIST.original_invoice_amount-total_gift_card_amount)     tot_amount
      FROM      xx_ar_ebl_cons_hdr_hist HIST
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id     = p_org_id
      AND    HIST.billdocs_delivery_method  = p_delivery_method
      AND    HIST.document_type='Paydoc'
      UNION ALL
      SELECT  'CBI'                                                          inv_type
             ,'ID'                                                          doc_type
             ,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust
             ,COUNT(DISTINCT HIST.cons_inv_id)                              tot_inv
             ,0                                                              tot_amount
      FROM      xx_ar_ebl_cons_hdr_hist HIST
      WHERE  HIST.request_id = p_request_id
      AND    HIST.org_id     = p_org_id
      AND    HIST.billdocs_delivery_method  = p_delivery_method
      AND    HIST.document_type='Infocopy';
	  
     ----- Below cursor added for OPSTECH  Defect (NAIT-56624)
     ----- Start OPSTECH logic for NAIT-56624
     CURSOR lcu_opstech_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_delivery_method IN VARCHAR2 )
     IS
     SELECT 'CBI' inv_type ,
            'PD' doc_type ,
            COUNT(NVL(XAOB.cust_doc_id,0)) tot_cust ,
            COUNT(NVL(XAOB.cons_inv_id,0)) tot_inv ,
            SUM(NVL(XAOB.total_inv_amt,0)) tot_amount
       FROM XX_AR_OPSTECH_BILL_STG XAOB
      WHERE XAOB.request_id      = p_request_id
        AND XAOB.org_id          = p_org_id
        AND XAOB.processed_flag  = 'S'
        AND XAOB.delivery_method = p_delivery_method;
     -------End OPSTECH logic for NAIT-56624	  
      
lc_qry lcu_cert_inv%ROWTYPE;

ln_rec_inv_id           NUMBER:=1;
ln_rec_inv_pd           NUMBER:=1;
ln_rec_cbi_id           NUMBER:=1;
ln_rec_cbi_pd           NUMBER:=1;

BEGIN

        ld_print_date:= FND_DATE.CANONICAL_TO_DATE(p_print_date);
     -- Printing parameter list
         FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters passed in:');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Delivery Method : '||p_delivery_method);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Report Date     : '||p_print_date);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address   : '||p_email_address);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Sender Address  : '||p_sender_address);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
         -- Printing output report header information
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('AR Billing SOX Report',88,' '));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('--------------------------------',93,' '));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Date             :'||to_char(ld_print_date,'DD-MON-YYYY'));
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Delivery Method :'||p_delivery_method);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('OU',5)
                                           ||RPAD('INV',9)
                                           ||RPAD('DOC',9)
                                           ||RPAD('CONC',24)
                                           ||RPAD('CONC REQ',32)
                                           ||RPAD('REPORT START',26)
                                           ||RPAD('REPORT END',18)
                                           ||RPAD('TOTAL',9)
                                           ||RPAD('TOTAL',10)
                                           ||RPAD('TOTAL',10)
                           );
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     '
                                           ||RPAD('TYPE',9)
                                           ||RPAD('TYPE',8)
                                           ||RPAD('REQ ID',27)
                                           ||RPAD('NAME',34)
                                           ||RPAD('TIME',25)
                                           ||RPAD('TIME',15)
                                           ||RPAD('CUST',10)
                                           ||RPAD('INV',9)
                                           ||RPAD('AMOUNT',10)
                          );                                          
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',2,'-')
                                           ||'  '
                                           ||RPAD('-',6,'-')
                                           ||'   '
                                           ||RPAD('-',6,'-')
                                           ||'  '
                                           ||RPAD('-',7,'-')
                                           ||'  '
                                           ||RPAD('-',(40),'-')
                                           ||'   '
                                           ||RPAD('-',(22),'-')
                                           ||'   '
                                           ||RPAD('-',(22),'-')
                                           ||'  '
                                           ||RPAD('-',(7),'-')
                                           ||'  '
                                           ||RPAD('-',(7),'-')
                                           ||'  '
                                           ||RPAD('-',(11),'-')
                          );                                              
         FND_PROFILE.GET('ORG_ID',ln_org_id);

         lc_error_loc:='Getting the country of the org';
         SELECT default_country
         INTO lv_country
         FROM ar_system_parameters_all
         WHERE org_id=ln_org_id;

         lc_error_loc:='Assigning the request id of the program';
         ln_this_request_id := FND_GLOBAL.CONC_REQUEST_ID;
         lr_sox_cbi_id_op.DELETE;
         lr_sox_cbi_pd_op.DELETE;
         lr_sox_inv_id_op.DELETE;
         lr_sox_inv_pd_op.DELETE;     

        IF (p_delivery_method='Certegy') THEN
                -- Get the exact name of the billing program for certegy
                lc_error_loc:='Getting the name of the billing program for certegy-individual';
                
                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'INV'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for certegy in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for certegy-individual';

                SELECT FCR.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_programs_vl FCP
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument9,1,10)=to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
				AND    FCR.phase_code = 'C'										-- Added by Shravya for Defect# 34796
				AND    FCR.status_code = 'C' 									-- Added by Shravya for Defect# 34796
            /* End  -- Added on 15-APR-10 */
;

                lc_error_loc:='Getting the details for certegy-individual';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_cert_inv(ln_req_id(i),ln_org_id)
                                LOOP
                                        IF(lc_qry.inv_type='INV' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_id_op.EXTEND();
                                                lr_sox_inv_id_op(ln_rec_inv_id).ou          := lv_country;
                                                lr_sox_inv_id_op(ln_rec_inv_id).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).req_id      := ln_req_id(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).start_time  := lv_req_start(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).end_time    := lv_req_end(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_id := ln_rec_inv_id + 1;
                                                ln_inv_id_flg:=1;
                                        ELSIF (lc_qry.inv_type='INV' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_pd_op.EXTEND();
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).ou          := lv_country;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).req_id      := ln_req_id(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).start_time  := lv_req_start(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).end_time    := lv_req_end(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_pd := ln_rec_inv_pd + 1;
                                                ln_inv_pd_flg:=1;
                                        END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                IF (ln_inv_id_flg = 0  OR ln_inv_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                lc_error_loc:= 'Setting to NULL';
                ln_req_id    :=NULL;
                lv_req_start :=NULL;
                lv_req_end   :=NULL;
                lv_conc_name :=NULL;

                -- Get the exact name of the billing program for certegy
                lc_error_loc:='Getting the name of the billing program for certegy-consolidated';
                
                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'CBI'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for certegy in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for certegy-consolidated';
                SELECT FCR.argument1
                       ,fcr.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO lv_thread_id
                     ,ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR     --Removed apps Schema reference
                       ,fnd_concurrent_programs_vl FCP  --Removed apps Schema reference
                       ,fnd_application FA              --Removed apps Schema reference
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument2,1,10)=to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
            /* End  -- Added on 15-APR-10 */
            ;

                lc_error_loc:='Getting the details for certegy-consolidated';
                IF (lv_thread_id.COUNT <> 0) THEN
                        FOR i IN lv_thread_id.FIRST .. lv_thread_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_cert_cons(lv_thread_id(i),ln_org_id)
                                LOOP
                                   IF(lc_qry.inv_type='CBI' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_id_op.EXTEND();
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).ou          := lv_country;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).req_id      := ln_req_id(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).start_time  := lv_req_start(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).end_time    := lv_req_end(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_id := ln_rec_cbi_id + 1;
                                        ln_cbi_id_flg:=1;
                                   ELSIF (lc_qry.inv_type='CBI' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_pd_op.EXTEND();
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou          := lv_country;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id      := ln_req_id(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time  := lv_req_start(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time    := lv_req_end(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_pd := ln_rec_cbi_pd + 1;
                                        ln_cbi_pd_flg:=1;
                                   END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;
                IF (ln_cbi_id_flg = 0  OR ln_cbi_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;

         ELSIF(p_delivery_method='EBill') THEN

                -- Get the exact name of the billing program for EBill
                lc_error_loc:='Getting the name of the billing program for EBill';
                
                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'CBI'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for EBill in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for EBill';
                SELECT FCR.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_programs_vl FCP   
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument2,1,10)= to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
            /* End  -- Added on 15-APR-10 */
              ;
                
                lc_error_loc:='Getting the details for EBill';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_ebill(ln_req_id(i),ln_org_id)
                                LOOP
                                   IF(lc_qry.inv_type='CBI' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_id_op.EXTEND();
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).ou          := lv_country;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).req_id      := ln_req_id(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).start_time  := lv_req_start(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).end_time    := lv_req_end(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_id := ln_rec_cbi_id + 1;
                                        ln_cbi_id_flg:=1;
                                   ELSIF (lc_qry.inv_type='CBI' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_pd_op.EXTEND();
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou          := lv_country;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id      := ln_req_id(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time  := lv_req_start(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time    := lv_req_end(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_pd := ln_rec_cbi_pd + 1;
                                        ln_cbi_pd_flg:=1;
                                   END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;
                IF (ln_cbi_id_flg = 0  OR ln_cbi_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;

         ELSIF(p_delivery_method='EDI') THEN

                -- Get the exact name of the billing program for EDI
                lc_error_loc:='Getting the name of the billing program for EDI';
                
                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'INV'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for EDI in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for EDI';
                SELECT FCR.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_programs_vl FCP   
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument6,1,10)= to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
            /* End  -- Added on 15-APR-10 */
              ;

                lc_error_loc:='Getting the details for EDI';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_edi(ln_req_id(i),ln_org_id)
                                LOOP
                                        IF(lc_qry.inv_type='INV' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_id_op.EXTEND();
                                                lr_sox_inv_id_op(ln_rec_inv_id).ou          := lv_country;
                                                lr_sox_inv_id_op(ln_rec_inv_id).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).req_id      := ln_req_id(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).start_time  := lv_req_start(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).end_time    := lv_req_end(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_id := ln_rec_inv_id + 1;
                                                ln_inv_id_flg:=1;
                                        ELSIF (lc_qry.inv_type='INV' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_pd_op.EXTEND();
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).ou          := lv_country;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).req_id      := ln_req_id(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).start_time  := lv_req_start(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).end_time    := lv_req_end(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_pd := ln_rec_inv_pd + 1;
                                                ln_inv_pd_flg :=1;
                                        END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                IF (ln_inv_id_flg = 0  OR ln_inv_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
         ELSIF (p_delivery_method = 'Special Handling') THEN 
                -- Get the exact name of the billing program for Special Handling - Individual
                lc_error_loc:='Getting the name of the billing program for Special Handling - Individual';
                
                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'INV'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for Special Handling - Individual in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for Special Handling - Individual';
                SELECT FCR.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_programs_vl FCP   
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument9,1,10)= to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
            /* End  -- Added on 15-APR-10 */
            ;

                lc_error_loc:='Getting the details for Special Handling - Individual';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_spl_inv(ln_req_id(i),ln_org_id)
                                LOOP
                                        IF(lc_qry.inv_type='INV' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_id_op.EXTEND();
                                                lr_sox_inv_id_op(ln_rec_inv_id).ou          := lv_country;
                                                lr_sox_inv_id_op(ln_rec_inv_id).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).req_id      := ln_req_id(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).start_time  := lv_req_start(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).end_time    := lv_req_end(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_id := ln_rec_inv_id + 1;
                                                ln_inv_id_flg := 1;
                                        ELSIF (lc_qry.inv_type='INV' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_pd_op.EXTEND();
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).ou          := lv_country;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).req_id      := ln_req_id(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).start_time  := lv_req_start(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).end_time    := lv_req_end(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_pd := ln_rec_inv_pd + 1;
                                                ln_inv_pd_flg := 1;
                                        END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                IF (ln_inv_id_flg = 0  OR ln_inv_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;

                ln_req_id    :=NULL;
                lv_req_start :=NULL;
                lv_req_end   :=NULL;
                lv_conc_name :=NULL;

                -- Get the exact name of the billing program for Special Handling - Consolidated
                lc_error_loc:='Getting the name of the billing program for Special Handling - Consolidated';

                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'CBI'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for Special Handling - Consolidated in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for Special Handling - Consolidated';
                SELECT FCR.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_programs_vl FCP   
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    -- Added on 15-APR-10
                       ,fnd_profile_option_values FLOV             -- Added on 15-APR-10
                WHERE  SUBSTR(FCR.argument1,1,10)= to_char(ld_print_date,'RRRR/MM/DD')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
            /* Start  -- Added on 15-APR-10 */
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796                
            /* End  -- Added on 15-APR-10 */
             ;

                lc_error_loc:='Getting the details for Special Handling - Consolidated';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_spl_cons(ln_req_id(i),ln_org_id)
                                LOOP
                                   IF(lc_qry.inv_type='CBI' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_pd_op.EXTEND();
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou          := lv_country;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id      := ln_req_id(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time  := lv_req_start(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time    := lv_req_end(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_pd := ln_rec_cbi_pd + 1;
                                        ln_cbi_pd_flg :=1;
                                   END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',NULL,ln_cbi_pd_flg);
                        ln_cbi_pd_flg:=1;
                END IF;
                IF (ln_cbi_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',NULL,ln_cbi_pd_flg);
                        ln_cbi_pd_flg:=1;
                END IF;
-- Below ELSIF block Added for Cr 586 Defect 2811
        ELSIF (p_delivery_method = 'ePDF') THEN
                -- Get the exact name of the billing program for certegy
                lc_error_loc:='Getting the name of the billing program for ePDF-individual';

                SELECT XFTV.target_value2
                      ,XFTV.target_value3
                INTO lc_prog_name
                     ,lc_child_prog_name1
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'INV'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for certegy in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';

                SELECT FCR1.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP1.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_requests FCR1
                       ,fnd_concurrent_programs_vl FCP
                       ,fnd_concurrent_programs_vl FCP1
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    
                       ,fnd_profile_option_values FLOV            
                WHERE  FCR.argument5 =to_char(ld_print_date,'YYYY/MM/DD HH24:MI:SS')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCR1.concurrent_program_id = FCP1.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP1.concurrent_program_name = lc_child_prog_name1
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR1.parent_request_id = FCR.request_id
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
                ;


                lc_error_loc:='Getting the details for ePDF-individual';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_ePDF_inv(ln_req_id(i),ln_org_id)
                                LOOP
                                        IF(lc_qry.inv_type='INV' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_id_op.EXTEND();
                                                lr_sox_inv_id_op(ln_rec_inv_id).ou          := lv_country;
                                                lr_sox_inv_id_op(ln_rec_inv_id).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).req_id      := ln_req_id(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).start_time  := lv_req_start(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).end_time    := lv_req_end(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_id := ln_rec_inv_id + 1;
                                                ln_inv_id_flg:=1;
                                        ELSIF (lc_qry.inv_type='INV' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_pd_op.EXTEND();
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).ou          := lv_country;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).req_id      := ln_req_id(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).start_time  := lv_req_start(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).end_time    := lv_req_end(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_pd := ln_rec_inv_pd + 1;
                                                ln_inv_pd_flg:=1;
                                        END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                IF (ln_inv_id_flg = 0  OR ln_inv_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                lc_error_loc:= 'Setting to NULL';
                ln_req_id    :=NULL;
                lv_req_start :=NULL;
                lv_req_end   :=NULL;
                lv_conc_name :=NULL;

                -- Get the exact name of the billing program for ePDF consolidated
                lc_error_loc:='Getting the name of the billing program for ePDF-consolidated';

                SELECT XFTV.target_value2
                      ,XFTV.target_value3
                      ,XFTV.target_value4
                      ,XFTV.target_value5
					  ,XFTV.target_value6 --added for SKU 
                INTO lc_prog_name
                     ,lc_child_prog_name1
                     ,lc_child_prog_name2
                     ,lc_child_prog_name3
					 ,lc_child_prog_name4 --added for SKU
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'CBI'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';
               
                lc_error_loc  := 'Getting the request details of all the billing programs run for ePDF- Consolidated';
                SELECT FCR1.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP1.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_requests FCR1
                       ,fnd_concurrent_programs_vl FCP
                       ,fnd_concurrent_programs_vl FCP1
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    
                       ,fnd_profile_option_values FLOV            
                WHERE  FCR.argument12=to_char(ld_print_date,'YYYY/MM/DD HH24:MI:SS')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCR1.concurrent_program_id = FCP1.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP1.concurrent_program_name IN (lc_child_prog_name1,lc_child_prog_name2,lc_child_prog_name3,lc_child_prog_name4)  --lc_child_prog_name4 added for SKU
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR1.parent_request_id = FCR.request_id
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
                ;
                
                lc_error_loc  := 'Getting the details for ePDF-Consolidated';
                
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_ePDF_cbi(ln_req_id(i),ln_org_id)
                                LOOP
                                   IF(lc_qry.inv_type='CBI' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_id_op.EXTEND();
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).ou          := lv_country;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).req_id      := ln_req_id(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).start_time  := lv_req_start(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).end_time    := lv_req_end(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_id := ln_rec_cbi_id + 1;
                                        ln_cbi_id_flg:=1;
                                   ELSIF (lc_qry.inv_type='CBI' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_pd_op.EXTEND();
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou          := lv_country;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id      := ln_req_id(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time  := lv_req_start(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time    := lv_req_end(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_pd := ln_rec_cbi_pd + 1;
                                        ln_cbi_pd_flg:=1;
                                   END IF;
                                END LOOP;
                        END LOOP;
                ELSE
               lc_error_loc  := 'XX_AR_SOX_PRINT_NULL - ELSE - for ePDF-Consolidated';
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;
                lc_error_loc  := 'XX_AR_SOX_PRINT_NULL - ln_cbi_id_flg = 0 - for ePDF-Consolidated';
                IF (ln_cbi_id_flg = 0  OR ln_cbi_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;
				
              ----- Below logic added for Opstech  Defect (NAIT-56624)
              ---- Start Opstech logic for NAIT-56624
          ELSIF p_delivery_method ='OPSTECH' THEN
			
            SELECT XFTV.target_value2
              INTO lc_prog_name
              FROM xx_fin_translatedefinition XFTD ,
                   xx_fin_translatevalues XFTV
             WHERE XFTD.translate_id   = XFTV.translate_id
               AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
               AND XFTV.source_value2    = p_delivery_method
               AND XFTV.enabled_flag = 'Y'
               AND XFTD.enabled_flag = 'Y';
			   
             SELECT FCR.request_id ,
                    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
                    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
                    FCP.user_concurrent_program_name BULK COLLECT
               INTO ln_req_id ,
                    lv_req_start ,
                    lv_req_end ,
                    lv_conc_name
               FROM fnd_concurrent_requests FCR ,
                    fnd_concurrent_programs_vl FCP ,
                    fnd_application FA ,
                    fnd_profile_options FLO ,
                    fnd_profile_option_values FLOV
              WHERE SUBSTR(FCR.argument2,1,10)  = TO_CHAR(ld_print_date,'RRRR/MM/DD')
				AND FCR.concurrent_program_id   = FCP.concurrent_program_id
				AND FCP.concurrent_program_name = lc_prog_name
				AND FCP.application_id          = FA.application_id
				AND FA.application_short_name   = 'XXFIN'
				AND FLOV.level_value            = fcr.responsibility_id
				AND FLOV.profile_option_id      = FLO.profile_option_id
				AND FLO.profile_option_name     = 'ORG_ID'
				AND FLOV.profile_option_value   = TO_CHAR(ln_org_id)
				AND FCR.phase_code              = 'C'
				AND FCR.status_code             = 'C';
				
              lc_error_loc := 'Getting the details for '||p_delivery_method||' - Consolidated';
              IF (ln_req_id.COUNT <> 0) THEN
                FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                LOOP
                  FOR lc_qry IN lcu_opstech_cbi(ln_req_id(i),ln_org_id,p_delivery_method)
                  LOOP
                    IF (lc_qry.tot_cust <> 0) THEN
                      lr_sox_cbi_pd_op.EXTEND();
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou           := lv_country;
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type     := lc_qry.inv_type;
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type     := lc_qry.doc_type;
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id       := ln_req_id(i);
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name    := lv_conc_name(i);
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time   := lv_req_start(i);
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time     := lv_req_end(i);
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust   := lc_qry.tot_cust;
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv    := lc_qry.tot_inv;
                      lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount := lc_qry.tot_amount;
                      ln_rec_cbi_pd                                := ln_rec_cbi_pd + 1;
                      ln_cbi_pd_flg                                := 1;
                    END IF;
                  END LOOP;
                END LOOP;
              ELSE
			    ln_cbi_id_flg := 1;
                XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                ln_cbi_pd_flg := 1;
              END IF;
              ---End OPSTECH logic for NAIT-56624
			  
        ---- Below ELSIF block added for Ebilling Cr 586 defect 2811
        ELSIF (p_delivery_method in('eXLS','eTXT')) THEN
                -- Get the exact name of the billing program for certegy
                lc_error_loc:='Getting the name of the billing program for '||p_delivery_method||' -individual';

                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'INV'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                -- Get the request id of all the billing programs run for certegy in today's run
                lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';

                SELECT FCR1.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP1.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_requests FCR1
                       ,fnd_concurrent_programs_vl FCP
                       ,fnd_concurrent_programs_vl FCP1
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    
                       ,fnd_profile_option_values FLOV            
                WHERE  FCR.argument1 =to_char(ld_print_date,'YYYY/MM/DD HH24:MI:SS')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCR1.concurrent_program_id = FCP1.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR1.parent_request_id = FCR.request_id
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796
                ;


                lc_error_loc:='Getting the details for '||p_delivery_method||' -individual';
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_eXLS_eTXT_inv(ln_req_id(i),ln_org_id,p_delivery_method)
                                LOOP
                                        IF(lc_qry.inv_type='INV' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_id_op.EXTEND();
                                                lr_sox_inv_id_op(ln_rec_inv_id).ou          := lv_country;
                                                lr_sox_inv_id_op(ln_rec_inv_id).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_id_op(ln_rec_inv_id).req_id      := ln_req_id(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).start_time  := lv_req_start(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).end_time    := lv_req_end(i);
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_id_op(ln_rec_inv_id).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_id := ln_rec_inv_id + 1;
                                                ln_inv_id_flg:=1;
                                        ELSIF (lc_qry.inv_type='INV' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                                lr_sox_inv_pd_op.EXTEND();
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).ou          := lv_country;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).inv_type    := lc_qry.inv_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).doc_type    := lc_qry.doc_type;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).req_id      := ln_req_id(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).prog_name   := lv_conc_name(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).start_time  := lv_req_start(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).end_time    := lv_req_end(i);
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_cust  := lc_qry.tot_cust;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_inv   := lc_qry.tot_inv;
                                                lr_sox_inv_pd_op(ln_rec_inv_pd).total_amount:= lc_qry.tot_amount;
                                                ln_rec_inv_pd := ln_rec_inv_pd + 1;
                                                ln_inv_pd_flg:=1;
                                        END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                IF (ln_inv_id_flg = 0  OR ln_inv_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'INV',ln_inv_id_flg,ln_inv_pd_flg);
                        ln_inv_id_flg:=1;
                        ln_inv_pd_flg:=1;
                END IF;
                lc_error_loc:= 'Setting to NULL';
                ln_req_id    :=NULL;
                lv_req_start :=NULL;
                lv_req_end   :=NULL;
                lv_conc_name :=NULL;

                -- Get the exact name of the billing program for ePDF consolidated
                lc_error_loc:='Getting the name of the billing program for '||p_delivery_method||' -consolidated';

                SELECT XFTV.target_value2
                INTO lc_prog_name
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND    XFTV.source_value2 = p_delivery_method
                AND    XFTV.source_value3 = 'CBI'
                AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';

                SELECT FCR1.request_id
                       ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')
                       ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS')
                       ,FCP1.user_concurrent_program_name
                BULK COLLECT INTO ln_req_id
                     ,lv_req_start
                     ,lv_req_end
                     ,lv_conc_name
                FROM   fnd_concurrent_requests  FCR 
                       ,fnd_concurrent_requests FCR1
                       ,fnd_concurrent_programs_vl FCP
                       ,fnd_concurrent_programs_vl FCP1
                       ,fnd_application FA
                       ,fnd_profile_options FLO                    
                       ,fnd_profile_option_values FLOV            
                WHERE  FCR.argument1=to_char(ld_print_date,'YYYY/MM/DD HH24:MI:SS')
                AND    FCR.concurrent_program_id = FCP.concurrent_program_id
                AND    FCR1.concurrent_program_id = FCP1.concurrent_program_id
                AND    FCP.concurrent_program_name = lc_prog_name
                AND    FCP.application_id = FA.application_id
                AND    FA.application_short_name = 'XXFIN'
                AND    FLOV.level_value = fcr.responsibility_id
                AND    FLOV.profile_option_id = FLO.profile_option_id
                AND    FLO.profile_option_name = 'ORG_ID'
                AND    FLOV.profile_option_value = TO_CHAR(ln_org_id)
                AND    FCR1.parent_request_id = FCR.request_id
                AND    FCR.phase_code = 'C'          -- Added by Shravya for Defect# 34796
                AND    FCR.status_code = 'C'         -- Added by Shravya for Defect# 34796                
                ;
                IF (ln_req_id.COUNT <> 0) THEN
                        FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
                        LOOP
                                FOR lc_qry IN lcu_eXLS_eTXT_cbi(ln_req_id(i),ln_org_id,p_delivery_method)
                                LOOP
                                   IF(lc_qry.inv_type='CBI' AND lc_qry.doc_type='ID' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_id_op.EXTEND();
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).ou          := lv_country;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).req_id      := ln_req_id(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).start_time  := lv_req_start(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).end_time    := lv_req_end(i);
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_id_op(ln_rec_cbi_id).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_id := ln_rec_cbi_id + 1;
                                        ln_cbi_id_flg:=1;
                                   ELSIF (lc_qry.inv_type='CBI' AND lc_qry.doc_type='PD' AND lc_qry.tot_cust <> 0) THEN
                                        lr_sox_cbi_pd_op.EXTEND();
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).ou          := lv_country;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).inv_type    := lc_qry.inv_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).doc_type    := lc_qry.doc_type;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).req_id      := ln_req_id(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).prog_name   := lv_conc_name(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).start_time  := lv_req_start(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).end_time    := lv_req_end(i);
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_cust  := lc_qry.tot_cust;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_inv   := lc_qry.tot_inv;
                                        lr_sox_cbi_pd_op(ln_rec_cbi_pd).total_amount:= lc_qry.tot_amount;
                                        ln_rec_cbi_pd := ln_rec_cbi_pd + 1;
                                        ln_cbi_pd_flg:=1;
                                   END IF;
                                END LOOP;
                        END LOOP;
                ELSE
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;
                IF (ln_cbi_id_flg = 0  OR ln_cbi_pd_flg = 0) THEN
                        XX_AR_SOX_PRINT_NULL(lv_country,lc_prog_name,'CBI',ln_cbi_id_flg,ln_cbi_pd_flg);
                        ln_cbi_id_flg:=1;
                        ln_cbi_pd_flg:=1;
                END IF;

-- End of changes for CR 586
        
        END IF;
-- Printing the actual output section
        IF (lr_sox_inv_id_op.count<>0 ) THEN
                 FOR j_inv_id IN lr_sox_inv_id_op.FIRST .. lr_sox_inv_id_op.LAST
                 LOOP
                        IF(ln_first_inv_id = 0) THEN
                                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lr_sox_inv_id_op(j_inv_id).ou,5)
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).inv_type,10,' ')
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).doc_type,6,' ')
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).req_id,9,' ')
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).prog_name,44,' ')
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).start_time,25,' ')
                                                           ||RPAD(lr_sox_inv_id_op(j_inv_id).end_time,26,' ')
                                                           ||LPAD(lr_sox_inv_id_op(j_inv_id).total_cust,4,' ')
                                                           ||lPAD(lr_sox_inv_id_op(j_inv_id).total_inv,9,' ')
                                                           ||lPAD(lr_sox_inv_id_op(j_inv_id).total_amount,13,' ')
                                                   );
                                 ln_first_inv_id :=1;
                                 ln_invoice_total:=ln_invoice_total+lr_sox_inv_id_op(j_inv_id).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_inv_id_op(j_inv_id).total_amount;
                         ELSE
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(' ',21)
                                                   ||RPAD(lr_sox_inv_id_op(j_inv_id).req_id,9,' ')
                                                   ||RPAD(lr_sox_inv_id_op(j_inv_id).prog_name,44,' ')
                                                   ||RPAD(lr_sox_inv_id_op(j_inv_id).start_time,25,' ')
                                                   ||RPAD(lr_sox_inv_id_op(j_inv_id).end_time,26,' ')
                                                   ||LPAD(lr_sox_inv_id_op(j_inv_id).total_cust,4,' ')
                                                   ||lPAD(lr_sox_inv_id_op(j_inv_id).total_inv,9,' ')
                                                   ||lPAD(lr_sox_inv_id_op(j_inv_id).total_amount,13,' ')
                                                   );
                                 ln_invoice_total:=ln_invoice_total+lr_sox_inv_id_op(j_inv_id).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_inv_id_op(j_inv_id).total_amount;
                         END IF;
                 END LOOP;
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                   ||LPAD(ln_invoice_total,9,' ')
                                                   ||LPAD(ln_total_amount,13,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
        END IF;

        ln_invoice_total:=0;
        ln_total_amount :=0;

        IF (lr_sox_inv_pd_op.count<>0 ) THEN

                 FOR j_inv_pd IN lr_sox_inv_pd_op.FIRST .. lr_sox_inv_pd_op.LAST
                 LOOP
                        IF(ln_first_inv_pd = 0) THEN
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lr_sox_inv_pd_op(j_inv_pd).ou,5)
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).inv_type,10,' ')
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).doc_type,6,' ')
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).req_id,9,' ')
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).prog_name,44,' ')
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).start_time,25,' ')
                                                                  ||RPAD(lr_sox_inv_pd_op(j_inv_pd).end_time,26,' ')
                                                                  ||LPAD(lr_sox_inv_pd_op(j_inv_pd).total_cust,4,' ')
                                                                  ||lPAD(lr_sox_inv_pd_op(j_inv_pd).total_inv,9,' ')
                                                                  ||lPAD(lr_sox_inv_pd_op(j_inv_pd).total_amount,13,' ')
                                                   );
                                 ln_first_inv_pd :=1;
                                 ln_invoice_total:=ln_invoice_total+lr_sox_inv_pd_op(j_inv_pd).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_inv_pd_op(j_inv_pd).total_amount;
                         ELSE
                                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(' ',21)
                                           ||RPAD(lr_sox_inv_pd_op(j_inv_pd).req_id,9,' ')
                                           ||RPAD(lr_sox_inv_pd_op(j_inv_pd).prog_name,44,' ')
                                           ||RPAD(lr_sox_inv_pd_op(j_inv_pd).start_time,25,' ')
                                           ||RPAD(lr_sox_inv_pd_op(j_inv_pd).end_time,26,' ')
                                           ||LPAD(lr_sox_inv_pd_op(j_inv_pd).total_cust,4,' ')
                                           ||lPAD(lr_sox_inv_pd_op(j_inv_pd).total_inv,9,' ')
                                           ||lPAD(lr_sox_inv_pd_op(j_inv_pd).total_amount,13,' ')
                                           );
                                 ln_invoice_total:=ln_invoice_total+lr_sox_inv_pd_op(j_inv_pd).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_inv_pd_op(j_inv_pd).total_amount;
                         END IF;
                 END LOOP;
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                   ||LPAD(ln_invoice_total,9,' ')
                                                   ||LPAD(ln_total_amount,13,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
        END IF;

        ln_invoice_total:=0;
        ln_total_amount :=0;

        IF (lr_sox_cbi_id_op.count<>0 ) THEN
                 FOR j_cbi_id IN lr_sox_cbi_id_op.FIRST .. lr_sox_cbi_id_op.LAST
                 LOOP
                        IF(ln_first_cbi_id = 0) THEN
                                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lr_sox_cbi_id_op(j_cbi_id).ou,5)
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).inv_type,10,' ')
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).doc_type,6,' ')
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).req_id,9,' ')
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).prog_name,44,' ')
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).start_time,25,' ')
                                                           ||RPAD(lr_sox_cbi_id_op(j_cbi_id).end_time,26,' ')
                                                           ||LPAD(lr_sox_cbi_id_op(j_cbi_id).total_cust,4,' ')
                                                           ||lPAD(lr_sox_cbi_id_op(j_cbi_id).total_inv,9,' ')
                                                           ||lPAD(lr_sox_cbi_id_op(j_cbi_id).total_amount,13,' ')
                                                   );
                                 ln_first_cbi_id :=1;
                                 ln_invoice_total:=ln_invoice_total+lr_sox_cbi_id_op(j_cbi_id).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_cbi_id_op(j_cbi_id).total_amount;
                         ELSE
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(' ',21)
                                                   ||RPAD(lr_sox_cbi_id_op(j_cbi_id).req_id,9,' ')
                                                   ||RPAD(lr_sox_cbi_id_op(j_cbi_id).prog_name,44,' ')
                                                   ||RPAD(lr_sox_cbi_id_op(j_cbi_id).start_time,25,' ')
                                                   ||RPAD(lr_sox_cbi_id_op(j_cbi_id).end_time,26,' ')
                                                   ||LPAD(lr_sox_cbi_id_op(j_cbi_id).total_cust,4,' ')
                                                   ||lPAD(lr_sox_cbi_id_op(j_cbi_id).total_inv,9,' ')
                                                   ||lPAD(lr_sox_cbi_id_op(j_cbi_id).total_amount,13,' ')
                                                   );
                                 ln_invoice_total:=ln_invoice_total+lr_sox_cbi_id_op(j_cbi_id).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_cbi_id_op(j_cbi_id).total_amount;
                         END IF;
                 END LOOP;
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                   ||LPAD(ln_invoice_total,9,' ')
                                                   ||LPAD(ln_total_amount,13,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
        END IF;

        ln_invoice_total:=0;
        ln_total_amount :=0;

        IF (lr_sox_cbi_pd_op.count<>0 ) THEN

                 FOR j_cbi_pd IN lr_sox_cbi_pd_op.FIRST .. lr_sox_cbi_pd_op.LAST
                 LOOP
                        IF(ln_first_cbi_pd = 0) THEN
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lr_sox_cbi_pd_op(j_cbi_pd).ou,5)
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).inv_type,10,' ')
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).doc_type,6,' ')
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).req_id,9,' ')
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).prog_name,44,' ')
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).start_time,25,' ')
                                                                  ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).end_time,26,' ')
                                                                  ||LPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_cust,4,' ')
                                                                  ||lPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_inv,9,' ')
                                                                  ||lPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_amount,13,' ')
                                                   );
                                 ln_first_cbi_pd :=1;
                                 ln_invoice_total:=ln_invoice_total+lr_sox_cbi_pd_op(j_cbi_pd).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_cbi_pd_op(j_cbi_pd).total_amount;
                         ELSE
                                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(' ',21)
                                           ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).req_id,9,' ')
                                           ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).prog_name,44,' ')
                                           ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).start_time,25,' ')
                                           ||RPAD(lr_sox_cbi_pd_op(j_cbi_pd).end_time,26,' ')
                                           ||LPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_cust,4,' ')
                                           ||lPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_inv,9,' ')
                                           ||lPAD(lr_sox_cbi_pd_op(j_cbi_pd).total_amount,13,' ')
                                           );
                                 ln_invoice_total:=ln_invoice_total+lr_sox_cbi_pd_op(j_cbi_pd).total_inv;
                                 ln_total_amount :=ln_total_amount +lr_sox_cbi_pd_op(j_cbi_pd).total_amount;
                         END IF;
                 END LOOP;
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                   ||LPAD(ln_invoice_total,9,' ')
                                                   ||LPAD(ln_total_amount,13,' '));
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
        END IF;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('**********END OF REPORT*********',93,' '));

         lc_email_subject  := 'Billing SOX Report Output';
         lc_sender_address := p_sender_address;

          IF p_email_address IS NOT NULL THEN
              lc_email_address  := p_email_address ;
          ELSE
			BEGIN
              SELECT XFTV.target_value1
                INTO lc_email_address
                FROM xx_fin_translatedefinition XFTD ,
                     xx_fin_translatevalues XFTV
              WHERE XFTD.translate_id   = XFTV.translate_id
                AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
                AND XFTV.source_value1    = p_delivery_method
                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND XFTV.enabled_flag = 'Y'
                AND XFTD.enabled_flag = 'Y';
			EXCEPTION
             WHEN OTHERS THEN
			  lc_email_address := NULL;
            END;
          END IF;   
              

         IF lc_email_address IS NOT NULL THEN
		 --Start of changes for defect #44270
			BEGIN
			SELECT XFTV.target_value1/1440
                into ln_time_delay
                FROM   xx_fin_translatedefinition XFTD
                       ,xx_fin_translatevalues XFTV
                WHERE  XFTD.translate_id = XFTV.translate_id
                AND    XFTD.translation_name = 'XX_CHILD_REQ_TIME_DELAY'
				AND    XFTV.source_value1 = 'XXARSOXREP' 
				AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                AND    XFTV.enabled_flag = 'Y'
                AND    XFTD.enabled_flag = 'Y';
			
			EXCEPTION
				WHEN OTHERS THEN
					ln_time_delay :=0;
			END;
		--End of changes for defect #44270
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the emailer program');
                 -- ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXODROEMAILER','',SYSDATE,FALSE 				--Commented for defect #44270
				ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXODROEMAILER','',to_char(SYSDATE+ln_time_delay,'DD-MON-RRRR HH24:MI:SS'),FALSE 	--Added for defect #44270
                                                   ,NULL
                                                   ,lc_email_address,lc_email_subject,'','Y',ln_this_request_id,lc_sender_address,'','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','',''
                                                   ,'','','','','','','','','','') ;
                 COMMIT;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted Emailer program - Request id: '||ln_conc_request_id);
         END IF;
EXCEPTION
  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
        FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
        x_ret_code:=1;
END XX_AR_SOX_CALC;


-- +====================================================================+
-- | Name       : XX_AR_SOX_PRINT_NULL                                  |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_country, p_conc_prog, p_inv_type, p_id_flg and      |
-- |              p_pd_flg                                              |
-- |                                                                    |
-- | Returns :                                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE XX_AR_SOX_PRINT_NULL( p_country      IN VARCHAR2
                               ,p_conc_prog    IN VARCHAR2
                               ,p_inv_type     IN VARCHAR2
                               ,p_id_flg       IN NUMBER
                               ,p_pd_flg       IN NUMBER)
AS
lc_error_loc          VARCHAR2(2000);
lv_conc_prog_name     fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;

BEGIN
                lc_error_loc:='Getting the conc prog name';
                        SELECT user_concurrent_program_name
                        INTO lv_conc_prog_name
                        FROM fnd_concurrent_programs_vl
                        WHERE concurrent_program_name = p_conc_prog;
                lc_error_loc:='Printing null records';
                        IF (p_id_flg =0) THEN
                                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(p_country,5,' ')
                                                                        ||RPAD(p_inv_type,10,' ')
                                                                        ||RPAD('ID',9,' ')
                                                                        ||RPAD('NA',6,' ')
                                                                        ||RPAD(lv_conc_prog_name,53,' ')
                                                                        ||RPAD('NA',25,' ')
                                                                        ||RPAD('NA',17,' ')
                                                                        ||LPAD('0',4,' ')
                                                                        ||LPAD('0',9,' ')
                                                                        ||LPAD('0',13,' ')
                                                  );
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                                   ||LPAD('0',9,' ')
                                                                   ||LPAD('0',13,' '));
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
                        END IF;
                        IF (p_pd_flg = 0) THEN

                                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(p_country,5)
                                                                        ||RPAD(p_inv_type,10,' ')
                                                                        ||RPAD('PD',9,' ')
                                                                        ||RPAD('NA',6,' ')
                                                                        ||RPAD(lv_conc_prog_name,53,' ')
                                                                        ||RPAD('NA',25,' ')
                                                                        ||RPAD('NA',17,' ')
                                                                        ||LPAD('0',4,' ')
                                                                        ||lPAD('0',9,' ')
                                                                        ||lPAD('0',13,' ')
                                                  );
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-----------------------------',151,' '));
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('TOTAL',129,' ')
                                                                   ||LPAD('0',9,' ')
                                                                   ||LPAD('0',13,' '));
                                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',151,'-'));
                        END IF;
EXCEPTION
  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
        FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
END XX_AR_SOX_PRINT_NULL;
END XX_AR_SOX_RPT;
/
SHOW ERRORS;
EXIT;
-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CE_NCC_UPDATE_SCRIPT.pkb                                                 |
-- | Rice Id      :                                                                             | 
-- | Description  : Update all duplicate DEBIT CARD transactions with right order payment id    |  
-- | Purpose      : to clear all OPEN transactions                                              |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   07-FEB-2012   Bapuji Nanapaneni    Initial Version                               |
-- |  1.1      06-JUN-2012   Sita Ram Kumar       Defect #18501                                 |
-- |  1.2      02-JAN-2013   Abdul Khan           QC Defect # 21189                             |
-- |  1.2      29-OCT-2013   Avinash              R12.2 Compliance Changes	                |
-- +============================================================================================+

SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CE_NCC_UPDATE_SCRIPT AS
-- +===================================================================+
-- | Name  : update_ajb998_opid                                        |
-- | Description     : extract transaction where customer ref is > 2   |
-- |                   and update xx_ce_ajb998 table with correct ord  |
-- |                   pay id                                          |
-- | Parameters      : p_recon_date_from   IN -> recon from date       |
-- |                   p_recon_date_to     IN -> recon to date         |
-- |                   p_type              IN -> ORDER/REFUND          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_ajb998_opid ( x_retcode          OUT NOCOPY   NUMBER
                             , x_errbuf           OUT NOCOPY   VARCHAR2
                             , p_recon_date_from   IN          VARCHAR2
                             , p_recon_date_to     IN          VARCHAR2
                             , p_type              IN          VARCHAR2
                             ) IS

/* Variable Declaration */

TYPE DC_DATARECTYP IS RECORD ( customer_receipt_reference   VARCHAR2(100) 
                             , orig_sys_document_ref        VARCHAR2(100) 
                             , order_payment_id             NUMBER
                             , seq_id                       NUMBER
                             );

TYPE DC_DATATABTYP IS TABLE OF DC_DATARECTYP INDEX BY BINARY_INTEGER;
G_DC_DATATABTYP   DC_DATATABTYP;
G_DC_DATARECTYP   DC_DATARECTYP;

i                  BINARY_INTEGER := 0;
j                  BINARY_INTEGER := 0;
ln_ord_count       NUMBER := 0;
ln_processed_count NUMBER  := 0;
ld_recon_date_from DATE := NULL;
ld_recon_date_to   DATE := NULL;

/*Cursor Declaration */

CURSOR c_ref_number( p_date_from IN DATE
                   , p_date_to   IN DATE) IS 
SELECT COUNT(DISTINCT r.order_payment_id) no_of_receipts 
     , xx.receipt_num
  FROM xx_ce_ajb998            xx 
     , xx_ar_order_receipt_dtl r
 WHERE recon_date        BETWEEN p_date_from AND p_date_to
   AND xx.provider_type  IN ('CHECK', 'DEBIT')
   AND xx.receipt_num    = customer_receipt_reference
   AND xx.trx_amount     = payment_amount
  --  AND xx.trx_type       = r.sale_type                             -- Commented as part of Defect #18501 
  AND xx.trx_type        = REPLACE(r.sale_type,'DEPOSIT-SALE','SALE') -- Added for Defect #18501 
   AND (r.payment_amount > 0 AND (p_type = 'ORDER')) 
GROUP BY xx.receipt_num,
         xx.order_payment_id -- Added for QC Defect # 21189
HAVING COUNT(DISTINCT r.order_payment_id) > 1
UNION
SELECT COUNT(DISTINCT r.order_payment_id) no_of_receipts 
     , xx.receipt_num
  FROM xx_ce_ajb998            xx 
     , xx_ar_order_receipt_dtl r
 WHERE recon_date        BETWEEN p_date_from AND p_date_to
   AND xx.provider_type  IN ('CHECK', 'DEBIT')
   AND xx.receipt_num    = customer_receipt_reference
   AND xx.trx_amount     = payment_amount
   AND xx.trx_type       = r.sale_type
   AND (r.payment_amount < 0 AND (p_type = 'REFUND')) 
GROUP BY xx.receipt_num
HAVING COUNT(DISTINCT r.order_payment_id) > 1;

CURSOR c_receipt_num (p_receipt_ref IN VARCHAR2)  IS 
SELECT DISTINCT r.customer_receipt_reference
     , r.orig_sys_document_ref
     , r.order_payment_id
  FROM xx_ce_ajb998 xx
     , xx_ar_order_receipt_dtl r
 WHERE r.customer_receipt_reference = xx.receipt_num
   AND xx.provider_type             IN ('CHECK', 'DEBIT')
   AND xx.receipt_num               = p_receipt_ref
   AND xx.trx_amount                = payment_amount
 --  AND xx.ar_cash_receipt_id        = r.cash_receipt_id --COMMENTED FOR Defect #18501 BY RAM KUMAR
   AND xx.store_num                 = r.store_number
   AND (r.payment_amount            > 0 AND (p_type = 'ORDER')) 
UNION
SELECT DISTINCT r.customer_receipt_reference
     , r.orig_sys_document_ref
     , r.order_payment_id
  FROM xx_ce_ajb998 xx
     , xx_ar_order_receipt_dtl r
 WHERE r.customer_receipt_reference = xx.receipt_num
   AND xx.provider_type             IN ('CHECK', 'DEBIT')
   AND xx.receipt_num               = p_receipt_ref
   AND xx.trx_amount                = payment_amount
   --AND xx.ar_cash_receipt_id        = r.cash_receipt_id --COMMENTED FOR Defect #18501 BY RAM KUMAR
   AND xx.store_num                 = r.store_number
   AND (r.payment_amount            < 0 AND (p_type = 'REFUND')) 
ORDER BY 1, 3;


CURSOR c_seq_id (p_receipt_ref IN VARCHAR2) IS
SELECT DISTINCT receipt_num
     , xx.rowid rownumber
     , sequence_id_998
  FROM xx_ce_ajb998 xx
     , xx_ar_order_receipt_dtl r
 WHERE r.customer_receipt_reference = xx.receipt_num
   AND xx.provider_type             IN ('CHECK', 'DEBIT')
   AND xx.receipt_num               = p_receipt_ref
   AND xx.trx_amount                = payment_amount
   AND xx.ar_cash_receipt_id        = r.cash_receipt_id
   AND xx.store_num                 = r.store_number
   AND (r.payment_amount            > 0 AND (p_type = 'ORDER')) 
UNION
SELECT DISTINCT receipt_num
     , xx.rowid rownumber
     , sequence_id_998
  FROM xx_ce_ajb998 xx
     , xx_ar_order_receipt_dtl r
 WHERE r.customer_receipt_reference = xx.receipt_num
   AND xx.provider_type             IN ('CHECK', 'DEBIT')
   AND xx.receipt_num               = p_receipt_ref
   AND xx.trx_amount                = payment_amount
   AND xx.ar_cash_receipt_id        = r.cash_receipt_id
   AND xx.store_num                 = r.store_number
   AND (r.payment_amount            < 0 AND (p_type = 'REFUND')) 
ORDER BY 1,2;

BEGIN
    ld_recon_date_from := TRUNC(TO_DATE(p_recon_date_from,'YYYY/MM/DD HH24:MI:SS'));
    ld_recon_date_to   := TRUNC(TO_DATE(p_recon_date_to,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Beginning of Program :::');
    FOR r_ref_number IN c_ref_number(ld_recon_date_from,ld_recon_date_to ) LOOP
    
        g_DC_DATARECTYP.customer_receipt_reference := NULL;
        g_DC_DATARECTYP.orig_sys_document_ref      := NULL;
        g_DC_DATARECTYP.order_payment_id           := NULL;
        g_DC_DATARECTYP.seq_id                     := NULL;

        G_DC_DATATABTYP.delete;

        i := 0;   
        j := 0;
       
        FOR r_receipt_num  IN c_receipt_num(r_ref_number.receipt_num)  LOOP

            i := i+1;   

            G_DC_DATATABTYP(i).customer_receipt_reference := r_receipt_num.customer_receipt_reference;
            G_DC_DATATABTYP(i).orig_sys_document_ref      := r_receipt_num.orig_sys_document_ref;
            G_DC_DATATABTYP(i).order_payment_id           := r_receipt_num.order_payment_id;
          --  G_DC_DATATABTYP(i).seq_id                     := NULL;

        END LOOP;

        FOR r_seq_id  IN c_seq_id(r_ref_number.receipt_num) LOOP

            j:=j+1;
            G_DC_DATATABTYP(j).seq_id                     := r_seq_id.sequence_id_998;
        END LOOP;

        FOR j IN 1..G_DC_DATATABTYP.COUNT LOOP
             IF r_ref_number.no_of_receipts = G_DC_DATATABTYP.COUNT THEN
                ln_processed_count := (ln_processed_count +1);
                UPDATE xx_ce_ajb998
                   SET order_payment_id = G_DC_DATATABTYP(j).order_payment_id
                     , last_update_date = SYSDATE
                     , last_updated_by = FND_GLOBAL.USER_ID 
                 WHERE sequence_id_998  = G_DC_DATATABTYP(j).seq_id;
                COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Transaction Successfully updated Customer Reference Number :::'||G_DC_DATATABTYP(j).customer_receipt_reference || ' AND Order Number :::'||G_DC_DATATABTYP(j).orig_sys_document_ref);
            ELSE
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Transaction Failed to updated Customer Reference Number :::'||G_DC_DATATABTYP(j).customer_receipt_reference || ' AND Order Number :::'||G_DC_DATATABTYP(j).orig_sys_document_ref);
            END IF;
            ln_ord_count       := (ln_ord_count+ 1);
            
        END LOOP;

    END lOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Of Rows Extracted          :::'||ln_ord_count );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No of Rows Updated            :::'||ln_processed_count);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No of Rows Failed to Update   :::'||(ln_ord_count-ln_processed_count));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'End of Program :::');
EXCEPTION
WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'NO DATA FOUND FOR RECORD G_DC_DATATABTYP(j).seq_id :::'||G_DC_DATATABTYP(j).customer_receipt_reference);
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS RAISED :::'||SQLERRM);
END update_ajb998_opid;
END XX_CE_NCC_UPDATE_SCRIPT;
/
SHOW ERRORS PACKAGE BODY XX_CE_NCC_UPDATE_SCRIPT;
EXIT;

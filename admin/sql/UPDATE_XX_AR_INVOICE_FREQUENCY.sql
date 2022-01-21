SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_AR_UPDATE_GCAMT.sql                                  |
-- | Description : Script to update the attribute4 in frequency table with |
-- |               gift card amount                                        |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     26-Oct-2009  Tamil Vendhan L   CR 626 (R1.1 Defect # 1451)    |
-- +=======================================================================+

 DECLARE

 CURSOR c_certegy_trans_unsent
 IS
    SELECT  XAIF.invoice_id               INVOICE_ID
           ,XAIF.document_id              DOC_ID
           ,XAIF.customer_document_id     CUST_DOC_ID
           ,RCT.attribute14               HEADER_ID
           ,RCTT.type                     TRX_TYPE
    FROM    apps.xx_ar_invoice_frequency XAIF
           ,apps.ra_customer_trx_all     RCT
           ,apps.ra_cust_trx_types_all   RCTT
    WHERE   XAIF.invoice_id                = RCT.customer_trx_id
    AND     RCT.cust_trx_type_id           = RCTT.cust_trx_type_id
    AND     XAIF.doc_delivery_method       = 'PRINT'
    AND     XAIF.billdocs_special_handling IS NULL
    AND     XAIF.attribute4                IS NULL;

    ln_rowcnt                  NUMBER      := 0;
    ln_tender_amount           NUMBER      := 0;

 BEGIN

    ln_rowcnt := 0;

    FOR lcu_certegy_trans_unsent IN c_certegy_trans_unsent
    LOOP

       IF lcu_certegy_trans_unsent.trx_type = 'INV' THEN

          SELECT  NVL(SUM(OP.payment_amount),0)
          INTO    ln_tender_amount
          FROM    apps.oe_payments OP
          WHERE   OP.header_id        = lcu_certegy_trans_unsent.header_id;

       ELSIF lcu_certegy_trans_unsent.trx_type = 'CM' THEN

          SELECT  NVL(SUM(ORT.credit_amount),0)
          INTO    ln_tender_amount
          FROM   xx_om_return_tenders_all ORT
          WHERE  ORT.header_id             =   lcu_certegy_trans_unsent.header_id;

       END IF;

       INSERT INTO xxfin.xx_ar_invoice_freq_bkp1115
       SELECT *
       FROM   xx_ar_invoice_frequency
       WHERE  invoice_id              = lcu_certegy_trans_unsent.invoice_id
       AND    customer_document_id    = lcu_certegy_trans_unsent.cust_doc_id;

       UPDATE xx_ar_invoice_frequency
       SET    attribute4              = ln_tender_amount
       WHERE  invoice_id              = lcu_certegy_trans_unsent.invoice_id
       AND    customer_document_id    = lcu_certegy_trans_unsent.cust_doc_id;

       ln_rowcnt := ln_rowcnt + 1;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Number of records updated whose Certegy Paydoc has not been sent: ' ||ln_rowcnt);

    COMMIT;


 EXCEPTION
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('Failed to update and insert records');
END;
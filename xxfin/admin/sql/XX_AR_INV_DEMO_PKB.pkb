CREATE OR REPLACE PACKAGE BODY XX_AR_INV_DEMO AS
    FUNCTION COMPUTE_EFFECTIVE_DATE(
                                    p_as_of_date     IN    DATE
                                   )  RETURN DATE IS

    BEGIN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'in the compute function');
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling COMPUTE_EFFECTIVE_DATE   :'||TRUNC(p_as_of_date));
      return p_as_of_date;
    EXCEPTION WHEN OTHERS THEN

        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||lc_error_debug);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
--        FND_FILE.PUT_LINE(FND_FILE.LOG,'Frequency: '||lc_frequency||'Payment Term: '||lc_payment_term||'Extension id: '||p_extension_id);
        RETURN (NULL);
    END;

PROCEDURE SYNCH (x_error_buff         OUT VARCHAR2
                ,x_ret_code           OUT NUMBER
                --,p_as_of_date         IN DATE
		) as
    CURSOR c_inv_cust_doc
    IS
    (
        SELECT
                XCCAE.extension_id
               ,XCCAE.billdocs_doc_id
               ,XCCAE.billdocs_cust_doc_id
               ,XCCAE.billdocs_delivery_meth
               ,XCCAE.billdocs_paydoc_ind
               ,XCCAE.billdocs_combo_type
               ,RCT.customer_trx_id
               ,RCT.creation_date
               ,RCT.trx_number
               ,XCCAE.cust_account_id                  --Added for traceability
               ,XCCAE.billdocs_special_handling        --Added for traceability
               ,XCCAE.billdocs_payment_term            --Added for traceability
        FROM
               ra_customer_trx_all RCT
               ,ra_batch_sources_all RBS
               ,xx_cdh_a_ext_billdocs_v XCCAE
               ,apps.oe_order_headers_all OOH
        WHERE
               RCT.bill_to_customer_id = 121851
               AND RCT.bill_to_customer_id = XCCAE.cust_account_id
               AND XCCAE.billdocs_doc_type = 'Invoice'
               AND RBS.batch_source_id = RCT.batch_source_id
               AND OOH.header_id(+) = DECODE(RCT.attribute_category, 'SALES_ACCT',RCT.attribute14, NULL)
--               AND RBS.name <> p_conv_invoice_source
               AND RCT.complete_flag = 'Y'
               AND RCT.attribute15 IS NULL
    );

    ld_estimated_print_date    DATE;

    BEGIN

        FOR lcu_inv_cust_doc IN c_inv_cust_doc
        LOOP

                ld_estimated_print_date := COMPUTE_EFFECTIVE_DATE(TRUNC(lcu_inv_cust_doc.creation_date));
        end loop;
    EXCEPTION
        WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'when others Error Message: '||SQLERRM);
    END SYNCH;
END XX_AR_INV_DEMO;
/
SHOW ERR
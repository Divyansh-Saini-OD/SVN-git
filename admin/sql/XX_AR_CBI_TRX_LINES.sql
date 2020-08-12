
  CREATE OR REPLACE VIEW "APPS"."XX_AR_CBI_TRX_LINES" ("REQUEST_ID", "CONS_INV_ID", "CUSTOMER_TRX_ID", "LINE_SEQ", "ITEM_CODE", "CUSTOMER_PRODUCT_CODE", "ITEM_DESCRIPTION", "MANUF_CODE", "QTY", "UOM", "UNIT_PRICE", "EXTENDED_PRICE", "ORG_ID", "LINE_COMMENTS", "COST_CENTER_DEPT", "CUST_DEPT_DESCRIPTION", "KIT_SKU", fee_type,fee_line_seq) AS 
  select
"REQUEST_ID","CONS_INV_ID","CUSTOMER_TRX_ID","LINE_SEQ","ITEM_CODE","CUSTOMER_PRODUCT_CODE","ITEM_DESCRIPTION","MANUF_CODE","QTY","UOM","UNIT_PRICE","EXTENDED_PRICE","ORG_ID","LINE_COMMENTS","COST_CENTER_DEPT","CUST_DEPT_DESCRIPTION","KIT_SKU" , fee_type,fee_line_seq
FROM xx_ar_cbi_trx_lines_all
WHERE NVL (org_id,
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                    ' ', NULL,
                                    SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           ),
                 -99
                )
           ) =
          NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                  ' ', NULL,
                                  SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                 )
                         ),
               -99
              );

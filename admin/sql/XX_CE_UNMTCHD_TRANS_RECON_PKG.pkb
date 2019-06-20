CREATE OR REPLACE
PACKAGE BODY XX_CE_UNMTCHD_TRANS_RECON_PKG
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_CE_UNMTCHD_TRANS_RECON_PKG.pks                  |
  -- | Description :  Plsql package for CE Unmatched Transactions Report |
  -- |                                  |
  -- | RICE ID     :                                                     |
  -- |Change Record :                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |1.0       31-Oct-2018 M K Pramod Kumar    Initial version           |
  -- |1.1       14-Jun-2019 M K Pramod Kumar    Code Changes for NEWEGG MPL           |
  -- |                                                     |
  -- +===================================================================+
AS
  gc_max_log_size CONSTANT NUMBER := 2000;
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT TRUE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF (p_force) THEN
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
      -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
/************************************************
* Helper procedure to get translation information
************************************************/
PROCEDURE get_translation_info(
    p_translation_name  IN xx_fin_translatedefinition.translation_name%TYPE,
    px_translation_info IN OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
IS
  lr_translation_info xx_fin_translatevalues%ROWTYPE;
BEGIN
  SELECT vals.*
  INTO lr_translation_info
  FROM xx_fin_translatevalues vals,
    xx_fin_translatedefinition defn
  WHERE 1                           =1
  AND defn.translation_name         = p_translation_name
  AND defn.translate_id             = vals.translate_id
  AND NVL(vals.source_value1, '-X') = NVL(px_translation_info.source_value1, NVL(vals.source_value1, '-X'))
  AND NVL(vals.source_value2, '-X') = NVL(px_translation_info.source_value2, NVL(vals.source_value2, '-X'))
  AND NVL(vals.source_value3, '-X') = NVL(px_translation_info.source_value3, NVL(vals.source_value3, '-X'))
  AND NVL(vals.source_value4, '-X') = NVL(px_translation_info.source_value4, NVL(vals.source_value4, '-X'))
  AND NVL(vals.source_value5, '-X') = NVL(px_translation_info.source_value5, NVL(vals.source_value5, '-X'))
  AND NVL(vals.source_value6, '-X') = NVL(px_translation_info.source_value6, NVL(vals.source_value6, '-X'))
  AND NVL(vals.source_value7, '-X') = NVL(px_translation_info.source_value7, NVL(vals.source_value7, '-X'))
  AND NVL(vals.source_value8, '-X') = NVL(px_translation_info.source_value8, NVL(vals.source_value8, '-X'))
  AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
  AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
  AND vals.enabled_flag = 'Y'
  AND defn.enabled_flag = 'Y';
  px_translation_info  := lr_translation_info;
  logit(p_message => 'RESULT Source_value1: ' || px_translation_info.Source_value1);
EXCEPTION
WHEN OTHERS THEN
  logit('Exception occured in procedure get_translation_info : SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END get_translation_info;
/**********************************************************************************
* Procedure to derive Error Description for Unmatched Transactions.
***********************************************************************************/
PROCEDURE derive_mpl_error_description(
    p_order_id     VARCHAR2,
    p_mpl_name     VARCHAR2,
    p_store_number VARCHAR2,
    x_order_info IN xx_ar_order_receipt_dtl%ROWTYPE,
    p_error_msg OUT nocopy VARCHAR2 )
IS
  /*CURSOR cr_Order_line_details(p_header_id NUMBER)
  IS
    SELECT oola.line_number ,
      oola.ordered_item ,
      oola.ordered_quantity ,
      oola.order_quantity_uom ,
      oola.cancelled_quantity ,
      NVL(wdd.shipped_quantity,0) shipped_quantity,
      oola.tax_code TAX_CODE,
      oola.pricing_quantity,
      oola.unit_selling_price,
      oola.unit_list_price,
      oola.tax_value,
      ((oola.shipped_quantity) * (oola.unit_selling_price)) XX_LINE_TOTAL
    FROM wsh_delivery_details wdd,
      oe_order_lines_all oola
    WHERE 1                 = 1
    AND oola.header_id      =p_header_id
   AND wdd.source_header_id(+)=oola.header_id
    AND wdd.source_line_id(+)  =oola.line_id
    ORDER BY header_id,
      ordered_item; */
	  
	  CURSOR cr_Order_line_details(p_header_id NUMBER)
  IS
  SELECT  
      oola.ordered_item ,
                oola.order_quantity_uom ,
      sum(NVL(oola.ordered_quantity,0))  ordered_quantity,
                sum(NVL(oola.cancelled_quantity,0))  cancelled_quantity,
                sum(NVL(oola.shipped_quantity,0))  shipped_quantity,
                sum(NVL(oola.pricing_quantity,0))  pricing_quantity,
                sum(NVL(oola.tax_value,0))  tax_value,         
      oola.unit_selling_price,     
      sum(((NVL(oola.shipped_quantity,0)) * (NVL(oola.unit_selling_price,0)))) XX_LINE_TOTAL
    FROM  
      oe_order_lines_all oola
    WHERE 1                 = 1
    AND oola.header_id      =p_header_id    
    group by header_id,ordered_item,oola.unit_selling_price,oola.order_quantity_uom 
    order by ordered_item;

  

  CURSOR cr_mpl_order_dtl_details(p_ordered_item oe_order_lines_all.ordered_item%type)
  IS
    SELECT dtl.*
    FROM xx_Ce_mpl_settlement_dtl dtl,
      xx_Ce_mpl_settlement_hdr hdr
    WHERE hdr.order_id            =p_order_id
    AND hdr.transaction_type      =DECODE(x_order_info.sale_type,'SALE','Order','Adjustment')
    AND hdr.marketplace_name      =p_mpl_name
    AND dtl.mpl_header_id         =hdr.mpl_header_id
    AND dtl.merchant_order_item_id=p_ordered_item;
  x_ce_mpl_stlmt_dtl_info xx_ce_mpl_Settlement_dtl%ROWTYPE;
BEGIN
  p_error_msg:='';
  BEGIN
  
    FOR order_line_Rec IN cr_Order_line_details(x_order_info.header_id)
    LOOP
      FOR dtl_Rec IN cr_mpl_order_dtl_details(order_line_Rec.ordered_item)
      LOOP
	  
        IF p_mpl_name            ='EBAY_MPL' THEN
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.unit_price<>order_line_Rec.unit_selling_price THEN
            p_error_msg         :=p_error_msg||'Order and Transaction Unit Price do not matchfor ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.quantity_purchased<> order_line_Rec.shipped_quantity THEN
            p_error_msg         :=p_error_msg||'Order Shipped Quantity do not match to Transaction Quantity Purchased for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.price_type='Principal' AND dtl_Rec.price_amount<>order_line_Rec.XX_LINE_TOTAL THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Principal Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.price_type='Tax' AND dtl_Rec.price_amount<>order_line_Rec.tax_value THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Tax Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
        elsif p_mpl_name         ='WALMART_MPL' THEN
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.unit_price<>order_line_Rec.unit_selling_price THEN
		    if dtl_Rec.unit_price<>0 then 
            p_error_msg         :=p_error_msg||'Order and Transaction Unit Price do not match for ordered item '||order_line_Rec.ordered_item||'.';
            end if;
		  END IF;
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.quantity_purchased<> order_line_Rec.shipped_quantity THEN
            if dtl_Rec.quantity_purchased<>0 then 
			p_error_msg         :=p_error_msg||'Order Shipped Quantity do not match to Transaction Quantity Purchased for ordered item '||order_line_Rec.ordered_item||'.';
            end if;
		 END IF;
          IF dtl_Rec.price_type='Principal' AND dtl_Rec.price_amount<>(order_line_Rec.XX_LINE_TOTAL+order_line_Rec.tax_value) THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Principal Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
        elsif p_mpl_name         ='RAKUTEN_MPL' THEN
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.unit_price<>order_line_Rec.unit_selling_price THEN
            p_error_msg         :=p_error_msg||'Order and Transaction Unit Price do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.unit_price IS NOT NULL AND dtl_Rec.price_type IS NULL AND dtl_Rec.quantity_purchased<> order_line_Rec.shipped_quantity THEN
            p_error_msg         :=p_error_msg||'Order Shipped Quantity do not match to Transaction Quantity Purchased for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.price_type='Principal' AND dtl_Rec.price_amount<>order_line_Rec.XX_LINE_TOTAL THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Principal Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
          IF dtl_Rec.price_type='Tax' AND dtl_Rec.price_amount<>order_line_Rec.tax_value THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Tax Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
		
		 elsif p_mpl_name         ='NEWGG_MPL' THEN
         
          IF dtl_Rec.price_type='Principal' AND dtl_Rec.price_amount<>order_line_Rec.XX_LINE_TOTAL THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Principal Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
		 
          IF dtl_Rec.price_type='Tax' AND dtl_Rec.price_amount<>order_line_Rec.tax_value THEN
            p_error_msg       :=p_error_msg||'Order and Transaction Tax Amount do not match for ordered item '||order_line_Rec.ordered_item||'.';
          END IF;
        END IF;
		
      END LOOP;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    p_error_msg:='Error occured in derive_mpl_error_description:'||sqlerrm;
  END;
END derive_mpl_error_description;
/*********************************************************************
* Function used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
*********************************************************************/
FUNCTION BEFOREREPORT
  RETURN BOOLEAN
IS
BEGIN
  RETURN TRUE;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_CE_UNMTCHD_TRANS_RECON_PKG.BeforeReport:- ' || SQLERRM);
END BEFOREREPORT;
/*********************************************************************
* Main Function to derive the Transaction Details
* Calls Subprocedures to and derive the Error Description for each transaction
*********************************************************************/
FUNCTION XX_CE_UNMATCH_TRANS_DETAILS(
    P_PROVIDER_TYPE     VARCHAR2,
    P_DEPOSIT_FROM_DATE VARCHAR2,
    P_DEPOSIT_TO_DATE   VARCHAR2 )
  RETURN XX_CE_UNMTCHD_TRANS_RECON_PKG.UNMATCH_AJB998_TRANS_TBL PIPELINED
IS
  CURSOR C_UNMATCH_REC
  IS
    SELECT provider_type,
      invoice_num,
      receipt_num,
      bank_rec_id,
      processor_id,
      trx_type,
      TRX_AMOUNT,
      store_num,
      org_id
    FROM xx_ce_ajb998
    WHERE 1=1
    AND recon_date BETWEEN to_Date(P_DEPOSIT_FROM_DATE,'RRRR/MM/DD HH24:MI:SS') AND to_Date(P_DEPOSIT_to_DATE,'RRRR/MM/DD HH24:MI:SS')
      --and processor_id=P_PROVIDER_TYPE
    AND processor_id IN
      (SELECT flv.meaning
      FROM fnd_lookup_values flv
      WHERE lookup_type    ='OD_CREDIT_CARD_PROVIDERS'
      AND flv.meaning      =DECODE(p_provider_type,'ALL',flv.meaning,p_provider_type)
      AND flv.enabled_flag = 'Y'
      AND sysdate BETWEEN NVL (flv.start_date_active, sysdate ) AND NVL (flv.end_date_active, sysdate + 1 )
      )
  AND STATUS_1310='NEW'
  AND status     ='PREPROCESSED';
TYPE UNMATCH_AJB998_TRANS_TYPE
IS
  TABLE OF XX_CE_UNMTCHD_TRANS_RECON_PKG.UNMATCH_AJB998_TRANS_REC INDEX BY PLS_INTEGER;
  L_UNMATCH_DETAIL_REC UNMATCH_AJB998_TRANS_TYPE;
  N NUMBER := 0;
  x_order_info xx_ar_order_receipt_dtl%ROWTYPE;
  p_error_message VARCHAR2(5000);
  lv_error_flag   VARCHAR2(1):='N';
  lv_marketplace_name xx_ce_mpl_Settlement_hdr.marketplace_name%type;
BEGIN

  FOR ajb998_rec IN C_UNMATCH_REC
  LOOP
    lv_error_flag:='N';
    
    BEGIN
      SELECT DECODE(ajb998_rec.provider_type,'EBAY','EBAY_MPL','WALMART','WALMART_MPL','RAKUTEN','RAKUTEN_MPL','NEWEGG','NEWEGG_MPL',ajb998_rec.provider_type)
      INTO lv_marketplace_name
      FROM dual;
    EXCEPTION
    WHEN OTHERS THEN
      lv_marketplace_name:=ajb998_rec.provider_type;
    END;
    BEGIN
	x_order_info:=null;
      SELECT *
      INTO x_order_info
      FROM xx_ar_order_receipt_dtl xordt
      WHERE 1                              =1
      AND xordt.customer_receipt_reference =  NVL(ajb998_rec.invoice_num,'-Z')
      AND xordt.org_id                     = ajb998_rec.org_id
      AND xordt.sale_type                  = ajb998_rec.trx_type
      AND xordt.credit_card_code           =ajb998_rec.provider_type
      --AND xordt.store_number
       -- ||'' = ajb998_rec.store_num
	   ;
    EXCEPTION
    WHEN no_data_found THEN
      p_Error_Message:='Order Information Unavailable in ORDT Table';
      lv_error_flag  :='Y';
    WHEN too_many_rows THEN
      p_Error_Message:='Too many Orders available in ORDT Table for the same Store Number';
      lv_error_flag  :='Y';
    WHEN OTHERS THEN
      lv_error_flag:='Y';
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS')||':Exception Occured to Derive ORDT info-SQLERRM:'||sqlerrm, p_force => True);
    END;

    IF lv_error_flag                 ='N' THEN
      IF NVL(x_order_info.payment_amount,0)<>ajb998_rec.TRX_AMOUNT THEN
        derive_mpl_error_description(ajb998_rec.receipt_num,lv_marketplace_name,ajb998_rec.store_num,x_order_info,p_Error_Message);
        IF p_Error_Message IS NULL THEN
          p_Error_Message  :='Transaction Amount does not match with Payment Amount';
        END IF;
      END IF;
    END IF;
    L_UNMATCH_DETAIL_REC(N).provider_type       := ajb998_rec.provider_type;
    L_UNMATCH_DETAIL_REC(N).invoice_num         := ajb998_rec.invoice_num;
    L_UNMATCH_DETAIL_REC(N).receipt_num         := ajb998_rec.receipt_num ;
    L_UNMATCH_DETAIL_REC(N).bank_rec_id         := ajb998_rec.bank_rec_id ;
    L_UNMATCH_DETAIL_REC(N).processor_id        := ajb998_rec.processor_id ;
    L_UNMATCH_DETAIL_REC(N).trx_type            := ajb998_rec.trx_type ;
    L_UNMATCH_DETAIL_REC(N).order_source        := x_order_info.order_source ;
    L_UNMATCH_DETAIL_REC(N).order_type          := x_order_info.order_type ;
    L_UNMATCH_DETAIL_REC(N).order_number        := x_order_info.order_number ;
    L_UNMATCH_DETAIL_REC(N).store_number        := ajb998_rec.store_num ;
    L_UNMATCH_DETAIL_REC(N).payment_type_code   := x_order_info.payment_type_code ;
    L_UNMATCH_DETAIL_REC(N).credit_card_code    := x_order_info.credit_card_code ;
    L_UNMATCH_DETAIL_REC(N).receipt_number      := x_order_info.receipt_number ;
    L_UNMATCH_DETAIL_REC(N).header_id           := x_order_info.header_id ;
    L_UNMATCH_DETAIL_REC(N).ORDT_payment_amount := NVL(x_order_info.payment_amount,0) ;
    L_UNMATCH_DETAIL_REC(N).AJB998_TRX_AMOUNT   := NVL(ajb998_rec.TRX_AMOUNT,0);
    L_UNMATCH_DETAIL_REC(N).VARIANCE_AMOUNT     := NVL(x_order_info.payment_amount,0)-NVL(ajb998_rec.TRX_AMOUNT,0) ;
    L_UNMATCH_DETAIL_REC(N).ERROR_CODE          := NULL ;
    L_UNMATCH_DETAIL_REC(N).ERROR_DESCRIPTION   := p_Error_Message ;
    N                                           := N+1;
  END LOOP;
  FOR I IN L_UNMATCH_DETAIL_REC.FIRST .. L_UNMATCH_DETAIL_REC.LAST
  LOOP
    PIPE ROW ( L_UNMATCH_DETAIL_REC(I) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Exception caurght '||SQLERRM);
  logit(p_message => 'Unexpected Error Occured:'||sqlerrm, p_force => True);
END XX_CE_UNMATCH_TRANS_DETAILS;
END XX_CE_UNMTCHD_TRANS_RECON_PKG;
/
show errors;
EXIT;
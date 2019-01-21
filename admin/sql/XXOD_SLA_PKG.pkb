create or replace PACKAGE BODY xxod_sla_pkg
AS
  -- +===================================================================+
  -- |                  Office Depot - R12 Upgrade Project               |
  -- |                    Office Depot Organization                      |
  -- +===================================================================+
  -- | Name  : XXOD_SLA_PKG                                              |
  -- | Description :  This PKG will be used to Derive COGS Account and   |
  -- |                 amount values based on interface line id          |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author          Remarks                      |
  -- |=======   ==========  =============   ============================ |
  -- |1.0      19-Sep-2013  Manasa D        E3063 - Initial draft version|
  -- |1.1      27-Nov-2013  Darshini        E3036 - Added the 'ROUND'    |
  -- |                                      function to the COGS amount  |
  -- |                                      derivation for Defect#26631  |
  -- |1.2      15-Jan-2014  Jay Gupta       Added Tax_location Function  |
  -- |                                      Defect#27223                 |
  -- |1.3      16-Oct-2014  Gayathri.K      Defect#31379                 |
  -- |1.4      01-Aug-2017  Sridhar Gajjala Customizing the Write-Off    |
  -- |          Accounting                 								 |
  -- |1.4      10-Nov-2017  Paddy Sanjeevi  Added INV_LOB                |  
  -- |1.5      30-Nov-2017  Havish Kasina   Changed the input parameter  |
  -- |                                      from p_distribution_id to    |
  -- |                                      p_write_off_id               |  
  -- |1.6      23-Jan-2018  Paddy Sanjeevi  Added Dropship Accrual Acct  |    
  -- |1.7      12-Feb-2018  Paddy Sanjeevi  Added for chargeback_acct    |  
  -- +===================================================================+
  -- +==============================================================================+
  -- | Name         :chargeback_acct                                                |
  -- | Description  :This Function return the inventory shrink account for chbk     |
  -- |                                                                              |
  -- | Parameters   :p_invoice_dist_id                                              |
  -- |                                                                              |
  -- +==============================================================================+    
 
  FUNCTION chargeback_acct(p_invoice_dist_id IN NUMBER)
  RETURN VARCHAR2
  IS
  
  v_cnt 		NUMBER:=0;
  v_achbk		NUMBER:=0;
  v_oddbui      NUMBER:=0;
  v_acct  		VARCHAR2(50);
  BEGIN
    SELECT COUNT(1)
	  INTO v_cnt
      FROM po_headers_all po,
           ap_invoices_all ai,
           ap_invoice_lines_all ail,
           ap_invoice_distributions_all d 
     WHERE d.invoice_distribution_id=p_invoice_dist_id
       AND ail.invoice_id=d.invoice_id
       AND ail.line_number=d.invoice_line_number
       AND ail.description like 'QTY%'
       AND ai.invoice_id=ail.invoice_id
       AND ai.attribute12='Y'
       AND ai.invoice_type_lookup_code='DEBIT'
       AND po.po_header_id=nvl(ai.po_header_id,ai.quick_po_header_id)
       AND po.attribute_category IN ('FrontDoor DC','FrontDoor Retail','Replenishment','New Store','Non-Code','Trade')
	   AND EXISTS ( SELECT 'x'
				      FROM ap_holds_all ah,
					       ap_invoice_lines_all ol,
						   ap_invoices_all oh
				     WHERE oh.invoice_num=SUBSTR(ai.invoice_num,1,(LENGTH(ai.invoice_num)-2))
					   AND oh.vendor_id+0=ai.vendor_id
					   AND oh.vendor_site_id+0=ai.vendor_site_id
					   AND ol.invoice_id=oh.invoice_id
					   AND ol.line_number=ail.attribute5
					   AND ah.invoice_id=ol.invoice_id
					   AND ah.line_location_id=ol.po_line_location_id
					   AND ah.hold_lookup_code='QTY REC'
					   AND ah.release_lookup_code IS NOT NULL
			      );
    IF v_cnt=0 THEN
       SELECT COUNT(1)
	     INTO v_achbk
         FROM po_headers_all po,
              ap_invoices_all ai,
              ap_invoice_lines_all ail,
              ap_invoice_distributions_all d 
        WHERE d.invoice_distribution_id=p_invoice_dist_id
          AND ail.invoice_id=d.invoice_id
          AND ail.line_number=d.invoice_line_number
          AND ail.description like 'QTY%'
          AND ai.invoice_id=ail.invoice_id
          AND ai.attribute12='Y'
          AND ai.invoice_type_lookup_code='DEBIT'
          AND po.po_header_id=nvl(ai.po_header_id,ai.quick_po_header_id)
          AND po.attribute_category IN ('FrontDoor DC','FrontDoor Retail','Replenishment','New Store','Non-Code','Trade')
	      AND EXISTS ( SELECT 'x'
			  	         FROM 
					          ap_invoice_lines_all ol,
						      ap_invoices_all oh
				        WHERE oh.invoice_num=SUBSTR(ai.invoice_num,1,(LENGTH(ai.invoice_num)-2))
					      AND oh.vendor_id+0=ai.vendor_id
					      AND oh.vendor_site_id+0=ai.vendor_site_id
					      AND ol.invoice_id=oh.invoice_id
					      AND ol.line_number=ail.attribute5
					      AND NOT EXISTS (SELECT 'x'
									        FROM ap_holds_all
										   WHERE invoice_id=oh.invoice_id
										     AND line_location_id=ol.po_line_location_id
											 AND hold_lookup_code='QTY REC'
 										 )
				          AND NOT EXISTS (SELECT 'x'
										FROM ap_invoices_all
									   WHERE invoice_num like oh.invoice_num||'ODDBUIA%'
									     AND vendor_id=oh.vendor_id
										 AND vendor_site_id=oh.vendor_site_id
									 )										 
   			         );

  	END IF;
    IF v_cnt=0 AND v_achbk=0 THEN
       SELECT COUNT(1)
	     INTO v_oddbui
         FROM po_headers_all po,
              ap_invoices_all ai,
              ap_invoice_lines_all ail,
              ap_invoice_distributions_all d 
        WHERE d.invoice_distribution_id=p_invoice_dist_id
          AND ail.invoice_id=d.invoice_id
          AND ail.line_number=d.invoice_line_number
          AND ail.description like 'QTY%'
          AND ai.invoice_id=ail.invoice_id
          AND ai.attribute12='Y'
          AND ai.invoice_type_lookup_code='DEBIT'
          AND po.po_header_id=nvl(ai.po_header_id,ai.quick_po_header_id)
          AND po.attribute_category IN ('FrontDoor DC','FrontDoor Retail','Replenishment','New Store','Non-Code','Trade')
	      AND EXISTS ( SELECT 'x'
			  	         FROM 
					          ap_invoice_lines_all ol,
						      ap_invoices_all oh
				        WHERE oh.invoice_num=SUBSTR(ai.invoice_num,1,(LENGTH(ai.invoice_num)-2))
					      AND oh.vendor_id+0=ai.vendor_id
					      AND oh.vendor_site_id+0=ai.vendor_site_id
					      AND ol.invoice_id=oh.invoice_id
					      AND ol.line_number=ail.attribute5
					      AND NOT EXISTS (SELECT 'x'
									        FROM ap_holds_all
										   WHERE invoice_id=oh.invoice_id
										     AND line_location_id=ol.po_line_location_id
											 AND hold_lookup_code='QTY REC'
 										 )
				          AND EXISTS (SELECT 'x'
										FROM ap_invoices_all
									   WHERE invoice_num like oh.invoice_num||'ODDBUIA%'
									     AND vendor_id=oh.vendor_id
										 AND vendor_site_id=oh.vendor_site_id
									 )
   			         );

	END IF;
	IF v_cnt<>0 OR v_achbk<>0 THEN   
	   BEGIN
	     SELECT attribute2
		   INTO v_acct
		   FROM mtl_transaction_reasons
		  WHERE reason_name='L';
		  RETURN(v_acct);
	   EXCEPTION
	     WHEN others THEN  
		   RETURN('12210000');
	   END;
	ELSIF v_oddbui<>0 THEN
	  RETURN(NULL);
	ELSE
	  RETURN(NULL);
	END IF;   
  END chargeback_acct;

  -- +===================================================================+
  -- | Name         :INV_LOB                                             |
  -- | Description  :This Procedure derive the LOB for the transaction_id|
  -- | Parameters   :p_transaction_id                                    |
  -- |                                                                   |
  -- +===================================================================+  
  FUNCTION INV_LOB (p_transaction_id IN NUMBER) 
  RETURN VARCHAR2
  AS

  LC_LOB xx_fin_translatevalues.target_value1%TYPE;

  BEGIN
    SELECT target_value1
      INTO lc_lob
      FROM mtl_material_transactions a,
           xx_fin_translatedefinition xtd,
           xx_fin_translatevalues xtv
     WHERE xtd.translation_name = 'OD_INVENTORY_ORG_LOB'
       AND xtd.translate_id     = xtv.translate_id
       AND source_value2        = A.organization_ID
       AND TRANSACTION_ID       = p_transaction_id;
    RETURN LC_LOB;
  EXCEPTION
    WHEN others THEN
      RETURN NULL;
  END;  
    
  -- +===================================================================+
  -- | Name         :COGS                                                |
  -- | Description  :This Procedure derive the COGS Value attribute7     |
  -- |               based on the interface line id  from the AR tables  |
  -- | Parameters   :p_trx_line_id                                       |
  -- |                                                                   |
  -- +===================================================================+
  FUNCTION cogs(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2
  IS
    lc_cogs VARCHAR2 (200) := '';
  BEGIN
    BEGIN
      SELECT attribute7
      INTO lc_cogs
      FROM ra_cust_trx_line_gl_dist_all
      WHERE customer_trx_line_id = p_trx_line_id;
    EXCEPTION
    WHEN OTHERS THEN
      lc_cogs := '';
    END;
    RETURN lc_cogs;
  END;
-- +===================================================================+
-- | Name         :INV                                                 |
-- | Description  :This Procedure derive the INV Value attribute8/10   |
-- |               based on the interface line id  from the AR tables  |
-- | Parameters   :p_trx_line_id                                       |
-- |                                                                   |
-- +===================================================================+
  FUNCTION inv(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2
  IS
    lc_inv VARCHAR2 (200) := '';
  BEGIN
    BEGIN
      SELECT NVL (attribute10, attribute8)
      INTO lc_inv
      FROM ra_cust_trx_line_gl_dist_all
      WHERE customer_trx_line_id = p_trx_line_id;
    EXCEPTION
    WHEN OTHERS THEN
      lc_inv := '';
    END;
    RETURN lc_inv;
  END;
-- +===================================================================+
-- | Name         :COGS_AMOUNT                                         |
-- | Description  :This Procedure derive the Amount for invoice        |
-- |               based on the interface line id  from the AR tables  |
-- | Parameters   :p_trx_line_id                                       |
-- |                                                                   |
-- +===================================================================+
  FUNCTION cogs_amount(
      p_trx_line_id IN NUMBER)
    RETURN NUMBER
  IS
    ln_amt NUMBER;
  BEGIN
    BEGIN
      SELECT ROUND((rctla.quantity_invoiced * rctlgda.attribute9),2) --Added the 'ROUND' function for Defect#26631
      INTO ln_amt
      FROM ra_cust_trx_line_gl_dist_all rctlgda,
        ra_customer_trx_lines_all rctla
      WHERE rctlgda.customer_trx_line_id = rctla.customer_trx_line_id
      AND rctlgda.customer_trx_line_id   = p_trx_line_id;
    EXCEPTION
    WHEN OTHERS THEN
      ln_amt := 0;
    END;
    RETURN ln_amt;
  END;
-- +===================================================================+
-- | Name         :CM_COGS_AMOUNT                                      |
-- | Description  :This Procedure derive the amount for Credit memo    |
-- |               based on the interface line id  from the AR tables  |
-- | Parameters   :p_trx_line_id                                       |
-- |                                                                   |
-- +===================================================================+
  FUNCTION cm_cogs_amount(
      p_trx_line_id IN NUMBER)
    RETURN NUMBER
  IS
    ln_amt                NUMBER;
    lc_qty_invoiced       VARCHAR2(1000);
    lc_qty_credited       VARCHAR2(1000);
    lc_unit_selling_price VARCHAR2(1000);
  BEGIN
    BEGIN
      SELECT ABS(ROUND(DECODE(TO_NUMBER(NVL(TRIM(rctlgda.attribute9),'0')) * rctla.quantity_invoiced , NULL,TO_NUMBER(NVL(TRIM(rctlgda.attribute9),'0')) * rctla.quantity_credited ,TO_NUMBER(NVL(TRIM(rctlgda.attribute9),'0')) * rctla.quantity_invoiced ) ,2 ) ) ,
        rctla.quantity_invoiced,
        rctla.quantity_credited,
        rctla.unit_selling_price
      INTO ln_amt,
        lc_qty_invoiced,
        lc_qty_credited,
        lc_unit_selling_price
      FROM ra_cust_trx_line_gl_dist_all rctlgda,
        ra_customer_trx_lines_all rctla
      WHERE rctlgda.customer_trx_line_id            = rctla.customer_trx_line_id
      AND rctlgda.customer_trx_line_id              = p_trx_line_id;
      IF SIGN(NVL(lc_qty_invoiced,lc_qty_credited)) = '-1' OR SIGN(NVL(lc_unit_selling_price,'0')) = '-1' THEN
        ln_amt                                     := ln_amt* (-1);
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      ln_amt := 0;
    END;
    RETURN ln_amt;
  END;
-- +===================================================================+
-- | Name         :TAX_LOCATION                                        |
-- | Description  :This derives the account of associated 8 series     |
-- | Parameters   :p_trx_line_id                                       |
-- +===================================================================+
--V1.2
  FUNCTION tax_location(
      p_dist_cc_id IN NUMBER)
    RETURN VARCHAR2
  IS
    LC_SEGMENT4 VARCHAR2(6);
  BEGIN
    SELECT ffv.flex_value
    INTO LC_SEGMENT4
    FROM FND_FLEX_VALUES_VL ffv,
      fnd_flex_value_sets ffvs
    WHERE ffv.flex_value_set_id =ffvs.flex_value_set_id
    AND ffvs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
    AND ffv.attribute4          =
      (SELECT ffv.attribute4
      FROM FND_FLEX_VALUES_VL ffv,
        fnd_flex_value_sets ffvs
      WHERE ffv.flex_value=
        (SELECT gcc.segment4
        FROM gl_code_combinations gcc,
          ap_invoice_distributions_all aid
        WHERE gcc.code_combination_id    =aid.dist_code_combination_id
        AND aid.dist_code_combination_id = p_dist_cc_id
        AND rownum                       =1
        )
      AND ffv.flex_value_set_id   =ffvs.flex_value_set_id
      AND ffvs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
      )
    AND ffv.flex_value LIKE '8%';
    RETURN LC_SEGMENT4;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  END tax_location;
-- +===================================================================+
-- | Name         :INV_LOCATION                                  |
-- | Description  :This Procedure derives the location for Invoice?s  |
-- | Inventory Line account based on the interface line id from the AR tables  |
-- | Parameters   :p_trx_line_id                                       |
-- |                                                                   |
-- +===================================================================+
  FUNCTION inv_location(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2
  IS -- Added as part of QC# 31379
    lc_segment4 VARCHAR2(6);
  BEGIN
    SELECT gl.segment4
    INTO lc_segment4
    FROM gl_code_combinations gl,
      mtl_parameters mtl,
      ra_customer_trx_lines_all ral
    WHERE ral.Customer_Trx_Line_Id=p_trx_line_id
    AND mtl.organization_id       =ral.warehouse_id
    AND gl.code_combination_id    =mtl.material_account;
    RETURN lc_segment4;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  END inv_location;
--  +=============================================================================+
-- | Name         :INV_COMPANY                                                    |
-- | Description  :This Function derives the company for Invoice?s                |
-- |               Inventory company segment based on the interface line id       |
-- |                 from the gl table                                            |
-- | Parameters   :p_trx_line_id                                                  |
-- |                                                                              |
-- +==============================================================================+
  FUNCTION inv_company(
      p_trx_line_id IN NUMBER)
    RETURN VARCHAR2
  IS -- Added as part of QC# 31379
    lc_segment1 VARCHAR2(5) := NULL;
    lc_segment4 VARCHAR2(6) := NULL;
  BEGIN
    SELECT gl.segment4
    INTO lc_segment4
    FROM gl_code_combinations gl,
      mtl_parameters mtl,
      ra_customer_trx_lines_all ral
    WHERE ral.Customer_Trx_Line_Id=p_trx_line_id
    AND mtl.organization_id       =ral.warehouse_id
    AND gl.code_combination_id    =mtl.material_account;
    IF lc_segment4               IS NOT NULL THEN
      SELECT ffv.attribute1
      INTO lc_segment1
      FROM fnd_flex_value_sets ffvs ,
        fnd_flex_values ffv
      WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
      AND flex_value_Set_name      = 'OD_GL_GLOBAL_LOCATION'
      AND flex_value               = lc_segment4;
    END IF;
    RETURN lc_segment1;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  END inv_company;
  
  --  +=============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+
  FUNCTION ACCRUAL_WRITEOFF(
  p_write_off_id in number) 
  return varchar2 
  AS
  lc_account VARCHAR2(30);
  begin
   
   SELECT mtr.attribute2
     INTO lc_account
     FROM cst_write_offs cwo,
          mtl_transaction_reasons mtr
    WHERE cwo.write_off_id =p_write_off_id -- Changes done as per Version 1.5
      AND cwo.reason_id = mtr.reason_id;
     return lc_account;

exception
when others then
return null;
  END ACCRUAL_WRITEOFF;
  
  
  --  +=============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF_LOCATION                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+
  
 FUNCTION ACCRUAL_WRITEOFF_LOCATION(
    p_write_off_id IN NUMBER)
  RETURN VARCHAR2
AS
  lc_location VARCHAR2(30);
BEGIN
  
  SELECT mtr.attribute6
  INTO lc_location
  FROM cst_write_offs cwo,
    mtl_transaction_reasons mtr
  WHERE cwo.write_off_id =p_write_off_id  -- Changes done as per Version 1.5
  AND cwo.reason_id            = mtr.reason_id;
  
  RETURN lc_location;
EXCEPTION
WHEN OTHERS THEN
  
  RETURN NULL;
END ACCRUAL_WRITEOFF_LOCATION;

 
  --  +=============================================================================+
  -- | Name         :ACCRUAL_WRITEOFF_LOB                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                process                                                       |
  -- | Parameters   :p_write_off_id                                              |
  -- |                                                                              |
  -- +==============================================================================+

FUNCTION ACCRUAL_WRITEOFF_LOB(
    p_write_off_id IN NUMBER)
  RETURN VARCHAR2
AS
  lc_lOB VARCHAR2(30);
BEGIN
  
  SELECT mtr.attribute7
  INTO lc_lOB
  FROM cst_write_offs cwo,
    mtl_transaction_reasons mtr
  WHERE cwo.write_off_id =p_write_off_id  -- Changes done as per Version 1.5
  AND cwo.reason_id            = mtr.reason_id;
  
  RETURN lc_lOB;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END ACCRUAL_WRITEOFF_LOB;
  
  --  +=============================================================================+
  -- | Name         :CONSIGN_MATERIAL_ACCT                                          |
  -- | Description  :This Function return the custom Account for the Write Off      |
  -- |                Process based on the Transaction Type derived from the        |
  -- |                Transaction Id                                                |
  -- | Parameters   :p_transaction_id                                               |
  -- |                                                                              |
  -- +==============================================================================+  
  FUNCTION CONSIGN_MATERIAL_ACCT(
      p_transaction_id IN NUMBER)
    RETURN VARCHAR2
  AS
    l_transaction_source VARCHAR2(100);
  BEGIN
    BEGIN
      SELECT MMT.TRANSACTION_SOURCE_NAME
      INTO l_transaction_source
      FROM  MTL_MATERIAL_TRANSACTIONS MMT
      WHERE MMT.transaction_id        = p_transaction_id;
    END;
    IF l_transaction_source = 'OD CONSIGNMENT RECEIPTS' THEN
      RETURN '12101000';
    elsif l_transaction_source = 'OD CONSIGNMENT RTV' THEN
      RETURN '12101000';
	elsif l_transaction_source = 'OD CONSIGNMENT SALES' THEN
      RETURN '12101000';
    ELSE
      RETURN '';
    END IF;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error: '||SQLERRM);
    fnd_file.put_line(fnd_file.log,'Error: '||SQLERRM);
  END CONSIGN_MATERIAL_ACCT;
  
  -- +==============================================================================+
  -- | Name         :dropship_accrual_acct                                          |
  -- | Description  :This Function return the accrual account for Dropship Source   |
  -- |                                                                              |
  -- | Parameters   :p_header_id                                                    |
  -- |                                                                              |
  -- +==============================================================================+    
  
FUNCTION DROPSHIP_ACCRUAL_ACCT(p_header_id IN NUMBER)
RETURN VARCHAR2
AS
  lc_ds_accrual_acct VARCHAR2(30);
BEGIN
  
  SELECT attribute_category
    INTO lc_ds_accrual_acct
    FROM Po_headers_all 
   WHERE po_header_id = p_header_id
     AND attribute_category in ('DropShip NonCode-SPL Order', 'DropShip VW');

   RETURN '20103000';

EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END DROPSHIP_ACCRUAL_ACCT; 
  
END;
/
SHOW ERRORS;

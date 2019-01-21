	create or replace
	PACKAGE BODY      XX_AP_INV_BLD_NON_PO_LINES_PKG
	AS
	-- +===============================================================================================+
	-- |                  Office Depot - Project Simplify                                              |
	-- |                       WIPRO Technologies                                                      |
	-- +===============================================================================================+
	-- | Name :  XX_AP_INV_BLD_PO_LINES_PKG                                                            |
	-- | Description :  This package is used to create invoices distribution lines for Non PO related  |
	-- |                invoices.This package is created as part of the fix for defect 3845 and CR #326|
	-- |                                                                                               |
	-- |                                                                                               |
	-- |Change Record:                                                                                 |
	-- |===============                                                                                |
	-- |Version   Date           Author                 Remarks                                        |
	-- |======   ==========     =============           =======================                        |
	-- |1.0       08-JAN-2008   Aravind A.              Initial draft version                          |
	-- |1.1       13-FEB-2008   Aravind A.              Code change for Defect 3845                    |
	-- |1.2       03-MAR-2008   Aravind A.              Fixed defect 4998 and CR 354                   |
	-- |1.3       06-MAR-2008   Aravind A.              Fixed defect 5219                              |
	-- |1.4       18-MAR-2008   Aravind A.              Fixed defect 5000                              |
	-- |1.5       08-MAY-2008   Hemalatha S.            Fixed Defect 6683                              |
	-- |1.6       27-AUG-2008   Aravind A.              Fixed defect 9420                              | 
	-- |1.7       27-SEP-2010   Erika Cupo              Fixed Defect 3128; CR 744 for Retailease       | 
	-- |1.8       05-SEP-2013   Darshini                I0013 - Changed to populate the freight        | 
	-- |                                                description for the prorated lines for Defect 25089|
	-- |1.9       02-Jan-2014   Santosh                 Changes for defect 25144.                      | 
	-- |1.10      17-Jan-2014   Paddy Sanjeevi	        Changes for Defect 25382                       |    
	-- |1.11      12-Feb-2014   Darshini                I0013 - Modified for Defect#27858              |
	-- |1.12      14-Feb-2014   Darshini                I0013 - Modified for Defect#27988              |--Added for Defect# 28591
	-- |1.13      26-Feb-2014   Darshini                I0013 - Modified for Defect#27988, 28294, 28591|
	-- |1.14      04-MAR-2014   Darshini                I0013 - Set prorate flag to 'Y' for FREIGHT    |
	-- |                                                lines for Defect# 28591                        |
	-- |1.15      17-NOV-2015   Harvinder Rakhra        Fixed defect 33354                             |
	-- |                                                Retrofit R12.2                                 |
	-- +===============================================================================================+




	--Global Variables

	   gc_processed_state      CONSTANT ap_invoices_interface.status%TYPE                            DEFAULT 'PROCESSED';

	   gc_item_lookup_code     CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE        DEFAULT 'ITEM';

	   gc_tax_lookup_code      CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE        DEFAULT 'TAX';

	   gc_freight_lookup_code  CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE        DEFAULT 'FREIGHT';

	-- +===================================================================+
	-- | Name        : SET_FREIGHT_PRORATE                                 |
	-- |                                                                   |
	-- | Description : This procedure is used to set the freight prorate   |
	-- |               flag in the lines interface table                   |
	-- |                                                                   |
	-- | Parameters  : p_invoice_id                                        |
	-- |                                                                   |
	-- | Returns     :                                                     |
	-- +===================================================================+

	   PROCEDURE SET_FREIGHT_PRORATE (
									  p_invoice_id IN NUMBER
									 )
	   IS
		  ln_freight_count          NUMBER               DEFAULT 0;
		  lc_error_loc              VARCHAR2(2000)       DEFAULT NULL;
	   BEGIN
		  SELECT COUNT(1)
		  INTO ln_freight_count
			 FROM ap_invoice_lines_interface AILI
			 WHERE AILI.invoice_id = p_invoice_id
				AND UPPER(NVL(AILI.line_type_lookup_code,'X')) = gc_freight_lookup_code;

		  IF (ln_freight_count > 0) THEN
			 lc_error_loc := 'Set Prorate Across Flag for Freight Line';

			 UPDATE ap_invoice_lines_interface AILI
				SET AILI.prorate_across_flag = 'Y'
				WHERE AILI.invoice_id = p_invoice_id
				   AND AILI.line_type_lookup_code =  gc_freight_lookup_code;

			  lc_error_loc := 'Set Line Group Number for Freight and Item Lines';

			  UPDATE ap_invoice_lines_interface AILI
				 SET AILI.line_group_number = p_invoice_id
				 WHERE AILI.invoice_id = p_invoice_id
					AND AILI.line_type_lookup_code IN (gc_item_lookup_code, gc_freight_lookup_code);
		  END IF;

	   EXCEPTION
		  WHEN OTHERS THEN
			 FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
	   END SET_freight_PRORATE;


	-- +===================================================================+
	-- | Name        : XX_AP_CREATE_NON_PO_INV_LINES                       |
	-- |                                                                   |
	-- | Description : This procedure is used to create invoices           |
	-- |               distribution lines for Non PO invoices.             |
	-- |                                                                   |
	-- | Parameters  : p_source                                            |
	-- |                                                                   |
	-- | Returns     :                                                     |
	-- +===================================================================+
							 
	   PROCEDURE XX_AP_CREATE_NON_PO_INV_LINES (
												p_source IN VARCHAR2
											   )
			 
	   IS
		  CURSOR lcu_non_po_invoices
		  IS
			 SELECT AII.invoice_id
				   , AII.invoice_num
				   , AII.last_updated_by
				   , AII.last_update_date
				   , AII.last_update_login
				   , AII.created_by
				   , AII.creation_date
			   FROM ap_invoices_interface AII
			  WHERE AII.source = p_source                        --Fixed defect 4998
				AND AII.po_number IS NULL
				AND NVL(AII.status,'X') <> gc_processed_state;

		  CURSOR lcu_invoice_item_lines (p_invoice_id NUMBER)
		  IS
			 SELECT AII.invoice_id
				   , AILI.invoice_line_id             --Defect 9420
				   , AII.last_updated_by
				   , AII.last_update_date
				   , AII.last_update_login
				   , AII.created_by
				   , AII.creation_date
				   , AILI.line_number
				   , AILI.line_type_lookup_code
				   , AILI.amount
				   , AILI.org_id
				   , AILI.dist_code_concatenated
				   , NULL project_id                  --Fixed defect 5000
				   , NULL task_id                     --Fixed defect 6683
				   , NULL expenditure_type            --Fixed defect 6683
				   , NULL project_accounting_context  --Fixed defect 6683
				   , NULL expenditure_organization_id --Fixed defect 6683
				   , NULL expenditure_item_date       --Fixed defect 6683
			   FROM  ap_invoices_interface AII
					 ,ap_invoice_lines_interface AILI
			  WHERE AII.invoice_id = p_invoice_id
				AND AII.invoice_id = AILI.invoice_id
				AND NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_item_lookup_code
				AND AILI.project_id IS NULL     --Fixed defect 6683
			  UNION ALL                            --Fixed defect 6683
			 SELECT AII.invoice_id
				   , AILI.invoice_line_id          --Defect 9420
				   , AII.last_updated_by
				   , AII.last_update_date
				   , AII.last_update_login
				   , AII.created_by
				   , AII.creation_date
				   , AILI.line_number
				   , AILI.line_type_lookup_code
				   , AILI.amount
				   , AILI.org_id
				   , NULL dist_code_concatenated
				   , AILI.project_id
				   , AILI.task_id
				   , AILI.expenditure_type
				   , AILI.project_accounting_context
				   , AILI.expenditure_organization_id
				   , AILI.expenditure_item_date
			   FROM ap_invoices_interface AII
					 ,ap_invoice_lines_interface AILI
			  WHERE AII.invoice_id = p_invoice_id
				AND AII.invoice_id = AILI.invoice_id
				AND NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_item_lookup_code
				AND AILI.project_id IS NOT NULL;


		  lc_error_loc           VARCHAR2(2000)       DEFAULT NULL;
		  lc_error_msg           VARCHAR2(4000)       DEFAULT NULL;
		  lc_tax_code            ap_invoice_lines_interface.tax_code%TYPE;
		  lc_line_exists_flag    VARCHAR(1)           DEFAULT 'N';
		  lc_reject_code         VARCHAR2(200);

		  lc_rtl_gl_code         varchar2(200); --defect 3128
		  v_ccid                 number; --defect 3128
		  lc_coa_id              gl_sets_of_books_v.chart_of_accounts_id%TYPE; --defect 3128
		  
		  ln_translation_id      xx_fin_translatedefinition.translate_id%TYPE      DEFAULT 0;
		  ln_tax_amount          ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_freight_amount      ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_total_line_amt_tx   ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_total_line_amt_fr   ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_tax_line_id         ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_tax                 ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_freight_line_id     ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_freight             ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_invoice_line_id     ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_tax_lines           NUMBER                                            DEFAULT 0;
		  ln_tax_cum             ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_freight_cum         ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  ln_tax_diff            NUMBER                                            DEFAULT 0;
		  ln_freight_diff        NUMBER                                            DEFAULT 0;
		  ln_tx_diff_line_id     ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_fr_diff_line_id     ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_max_tax             ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;
		  ln_max_freight         ap_invoice_lines_interface.invoice_line_id%TYPE   DEFAULT 0;

		  lr_invoice_item_rec    lcu_invoice_item_lines%ROWTYPE;
		  lr_non_po_invoices_rec  lcu_non_po_invoices%ROWTYPE;

		  --Defect 9420
		  ln_line_number         NUMBER  DEFAULT 1;
		  ln_grp_line_number     NUMBER  DEFAULT 1;
		  ln_tax_count           NUMBER  DEFAULT 0;

		  ln_freight_desc        ap_invoice_lines_interface.description%TYPE;  --Added by Darshini for Defect 25089
		  ln_prorate_flag        varchar2(5) ; -- added by Santosh defect 25144
		  ln_tax_description     VARCHAR2(240);
		  --Added for defect# 27988
		  --ln_tax_amount_util     ap_invoice_lines_interface.amount%TYPE            DEFAULT 0;
		  --lc_tax_code_util       ap_invoice_lines_interface.tax_code%TYPE;
		  ln_max_line_num        NUMBER  DEFAULT 0;
		  ln_tax_line_number     NUMBER  DEFAULT 0;
		  ln_freight_line_number NUMBER  DEFAULT 0;
		  ln_freight_count       NUMBER  DEFAULT 0;
		  ld_last_update_date    DATE;
		  ln_last_updated_by     NUMBER;
		  ln_created_by          NUMBER;
		  ld_creation_date       DATE;
		  --end
	   BEGIN

		  BEGIN
			 lc_error_loc:='Fetching translation id for tax codes translation';

			 SELECT XFTD.translate_id
			   INTO ln_translation_id
			   FROM xx_fin_translatedefinition XFTD
			  WHERE XFTD.translation_name = 'AP_PRORATE_US_TAX_CODES'
				AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active, SYSDATE + 1 )
				AND XFTD.enabled_flag = 'Y';
	   
	   FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_translation_id = '||ln_translation_id);

		  EXCEPTION
			 WHEN NO_DATA_FOUND THEN
				FND_MESSAGE.SET_NAME ('XXFIN', 'XX_AP_0027_NO_TRANSLATION');
				lc_error_msg := FND_MESSAGE.GET;
				FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || lc_error_msg );
			 WHEN OTHERS THEN
				FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
		  END;

		  OPEN lcu_non_po_invoices;
		  LOOP

			 FETCH lcu_non_po_invoices INTO lr_non_po_invoices_rec;
			 EXIT WHEN lcu_non_po_invoices%NOTFOUND;
		  --Added for defect# 27988, 28294, 28591
		  IF p_source <> 'US_OD_RENT' THEN
		  
				BEGIN
				  ln_max_line_num := 0;               --Added for Defect 33354, version 1.15
				  
				  --Commenting Query for Defect 33354, version 1.15
				/*  SELECT  MAX(AILI2.line_number)	
						 ,AILI2.last_update_date
						 ,AILI2.last_updated_by
						 ,AILI2.created_by
						 ,AILI2.creation_date
					INTO  ln_max_line_num
						 ,ld_last_update_date
						 ,ln_last_updated_by
						 ,ln_created_by
						 ,ld_creation_date
					FROM  ap_invoice_lines_interface AILI2
				   WHERE  AILI2.invoice_id = lr_non_po_invoices_rec.invoice_id
					 AND  NVL(UPPER(AILI2.line_type_lookup_code),'X') = gc_item_lookup_code
					 GROUP BY AILI2.LAST_UPDATE_DATE
							 ,AILI2.last_updated_by
							 ,AILI2.CREATED_BY
							 ,AILI2.CREATION_DATE;*/
							 
				  --Added for Defect 33354, version 1.15
				  SELECT  MAX(AILI.line_number)
				  INTO    ln_max_line_num
				  FROM    ap_invoice_lines_interface AILI
				  WHERE   AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
				  AND     NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_item_lookup_code;
					 
				  SELECT AILI.last_update_date
					   , AILI.last_updated_by
					   , AILI.created_by
					   , AILI.creation_date
				  INTO  ld_last_update_date
					  , ln_last_updated_by
					  , ln_created_by
					  , ld_creation_date
				  FROM  ap_invoice_lines_interface AILI
				  WHERE  AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
				  AND  AILI.line_number = ln_max_line_num;
				EXCEPTION
				   WHEN NO_DATA_FOUND THEN
					   FND_FILE.PUT_LINE (
										 FND_FILE.LOG
										 ,'NO_DATA_FOUND: Invoice ITEM Line for US Tax Codes does not exist for Invoice ID : '||lr_non_po_invoices_rec.invoice_id
										);


				   WHEN TOO_MANY_ROWS THEN
					  FND_FILE.PUT_LINE (
										 FND_FILE.LOG
										 ,'TOO_MANY_ROWS Exception: Multiple US ITEM Lines Exist for the invoice ID : '||
										  lr_non_po_invoices_rec.invoice_id
										);
				END;
				SELECT COUNT(1)
				  INTO   ln_tax_count
				  FROM   ap_invoice_lines_interface AILI
				 WHERE   AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
				   AND   NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_tax_lookup_code;
				
			IF (ln_tax_count>0) THEN    			
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calulating the Total tax amount');
				BEGIN
				   SELECT  SUM(AILI1.amount)
						  ,AILI1.tax_code
						  ,AILI1.description
					 INTO  ln_tax_amount
						  ,lc_tax_code
						  ,ln_tax_description
					 FROM  ap_invoice_lines_interface AILI1
					WHERE  AILI1.invoice_id = lr_non_po_invoices_rec.invoice_id
					  AND  NVL(UPPER(AILI1.line_type_lookup_code),'X') = gc_tax_lookup_code
					 GROUP BY AILI1.tax_code
							 ,AILI1.description ;
			  
				EXCEPTION
				   WHEN NO_DATA_FOUND THEN
						FND_FILE.PUT_LINE (
										   FND_FILE.LOG
										   ,'NO_DATA_FOUND: Tax Invoice Line for US Tax Codes does not exist.'
										  );


				   WHEN TOO_MANY_ROWS THEN
						FND_FILE.PUT_LINE (
										   FND_FILE.LOG
										  ,'TOO_MANY_ROWS Exception: Multiple US Tax Lines Exist for the invoice.'
										  );
				END;
				
				ln_tax_line_number := ln_max_line_num +1;
		   
				SELECT ap_invoice_lines_interface_s.NEXTVAL
				  INTO ln_invoice_line_id
				  FROM DUAL;
				  
						   INSERT INTO ap_invoice_lines_interface(
																   invoice_id
																   ,invoice_line_id
																   ,line_type_lookup_code
																   ,description			
																   ,line_number                     
																   ,amount
																   ,tax_code
																   ,org_id
																   ,last_updated_by
																   ,last_update_date
																   ,created_by
																   ,creation_date
																   )
															VALUES(
																   lr_non_po_invoices_rec.invoice_id
																   ,ln_invoice_line_id
																   ,gc_tax_lookup_code
																   ,ln_tax_description  
																   ,ln_tax_line_number                
																   ,ln_tax_amount
																   ,lc_tax_code
																   ,fnd_global.org_id
																   ,ln_last_updated_by
																   ,ld_last_update_date
																   ,ln_created_by
																   ,ld_creation_date
															);
															
			DELETE ap_invoice_lines_interface AILI
			 WHERE AILI.invoice_line_id <> ln_invoice_line_id
			   AND NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_tax_lookup_code
			   AND AILI.invoice_id = lr_non_po_invoices_rec.invoice_id;
			
			END IF;
			SELECT COUNT(1)
			  INTO   ln_freight_count
			  FROM   ap_invoice_lines_interface AILI
			 WHERE   AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
			   AND   NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_freight_lookup_code;
			   
			IF (ln_freight_count>0) THEN  
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calulating the Freight amount');
		  
				BEGIN
				   SELECT  SUM(AILI1.amount)
						  ,AILI1.description
					 INTO  ln_freight_amount
						  ,ln_freight_desc
					 FROM  ap_invoice_lines_interface AILI1
					WHERE  AILI1.invoice_id = lr_non_po_invoices_rec.invoice_id
					  AND  NVL(UPPER(AILI1.line_type_lookup_code),'X') = gc_freight_lookup_code
					 GROUP BY AILI1.tax_code
							 ,AILI1.description ;
			  
				EXCEPTION
				   WHEN NO_DATA_FOUND THEN
						FND_FILE.PUT_LINE (
										   FND_FILE.LOG
										   ,'NO_DATA_FOUND: Tax Invoice Line for US Tax Codes does not exist.'
										  );


				   WHEN TOO_MANY_ROWS THEN
						FND_FILE.PUT_LINE (
										   FND_FILE.LOG
										  ,'TOO_MANY_ROWS Exception: Multiple US Tax Lines Exist for the invoice.'
										  );
				END;
				
				IF(ln_tax_line_number<>0) THEN
				ln_freight_line_number := ln_tax_line_number +1;
				ELSE
				ln_freight_line_number := ln_max_line_num +1;
				END IF;
		   
				SELECT ap_invoice_lines_interface_s.NEXTVAL
				  INTO ln_invoice_line_id
				  FROM DUAL;
				  
						   INSERT INTO ap_invoice_lines_interface(
																   invoice_id
																   ,invoice_line_id
																   ,line_type_lookup_code
																   ,description			
																   ,line_number                     
																   ,amount
																   ,org_id
																   ,last_updated_by
																   ,last_update_date
																   ,created_by
																   ,creation_date
																   ,prorate_across_flag --Added for Defect# 28591
																   )
															VALUES(
																   lr_non_po_invoices_rec.invoice_id
																   ,ln_invoice_line_id
																   ,gc_freight_lookup_code
																   ,ln_freight_desc  
																   ,ln_freight_line_number                
																   ,ln_freight_amount
																   ,fnd_global.org_id
																   ,ln_last_updated_by
																   ,ld_last_update_date
																   ,ln_created_by
																   ,ld_creation_date
																   ,'Y' --Added for Defect# 28591
															);
															
			DELETE ap_invoice_lines_interface AILI
			 WHERE AILI.invoice_line_id <> ln_invoice_line_id
			   AND NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_freight_lookup_code
			   AND AILI.invoice_id = lr_non_po_invoices_rec.invoice_id;
			END IF;
		  ELSE
		  --END changes for Defect# 27988, 28294, 28591
			 ln_line_number     := 1;
			 ln_grp_line_number := 1;

				lc_error_loc := 'Getting Freight amount to be prorated';

				BEGIN
				   SELECT   AILI1.amount
							,AILI1.invoice_line_id
							,SUM(AILI2.amount)
							,AILI1.DESCRIPTION  --Added by Darshini for Defect 25089
				   INTO    ln_freight_amount
						   ,ln_freight_line_id
						   ,ln_total_line_amt_fr
						   ,ln_freight_desc   --Added by Darshini for Defect 25089
					  FROM ap_invoice_lines_interface AILI1
						  ,ap_invoice_lines_interface AILI2
					  WHERE AILI1.invoice_id = lr_non_po_invoices_rec.invoice_id
						 AND AILI2.invoice_id = lr_non_po_invoices_rec.invoice_id
						 AND NVL(UPPER(AILI1.line_type_lookup_code),'X') = gc_freight_lookup_code
						 AND AILI2.invoice_id = AILI1.invoice_id
						 AND NVL(UPPER(AILI2.line_type_lookup_code),'X') = gc_item_lookup_code
					  GROUP BY AILI1.amount
							  , AILI1.invoice_line_id
							  ,AILI1.DESCRIPTION;
				EXCEPTION
				   WHEN NO_DATA_FOUND THEN
					  ln_total_line_amt_fr := 0;
				   WHEN OTHERS THEN
					  ln_total_line_amt_fr := 0;
					  FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
				END;

				lc_error_loc := 'Getting Tax amount to be prorated';

				BEGIN
				   SELECT   AILI1.amount
							,AILI1.tax_code
							,AILI1.invoice_line_id
							,SUM (AILI2.amount)
				   INTO   ln_tax_amount
						  ,lc_tax_code
						  ,ln_tax_line_id
						  ,ln_total_line_amt_tx
					 FROM ap_invoice_lines_interface AILI1
						  ,ap_invoice_lines_interface AILI2
						  ,hr_operating_units HOU
					 WHERE  AILI1.invoice_id = lr_non_po_invoices_rec.invoice_id
						AND AILI2.invoice_id = lr_non_po_invoices_rec.invoice_id
						AND NVL(UPPER(AILI1.line_type_lookup_code),'X') = gc_tax_lookup_code
						AND AILI2.invoice_id = AILI1.invoice_id
						AND NVL(UPPER(AILI2.line_type_lookup_code),'X') = gc_item_lookup_code
						AND HOU.organization_id = AILI1.org_id
						AND (AILI1.tax_code, HOU.NAME) IN (
														 SELECT XFTV.source_value1
																,XFTV.source_value2
															FROM xx_fin_translatevalues XFTV
															WHERE XFTV.translate_id = ln_translation_id
															   AND SYSDATE BETWEEN XFTV.start_date_active
																			  AND NVL(XFTV.end_date_active, SYSDATE + 1)
															   AND XFTV.enabled_flag = 'Y'
														 )
					 GROUP BY AILI1.amount
							  , AILI1.tax_code
							  , AILI1.invoice_line_id;
				EXCEPTION
				   WHEN NO_DATA_FOUND THEN
					  lc_error_loc := 'NO_DATA_FOUND: Tax Invoice Line for US Tax Codes does not exist.';
					  ln_tax_amount := 0;
					  ln_total_line_amt_tx := 0;
					  FND_MESSAGE.CLEAR;
					  FND_MESSAGE.SET_NAME ('XXFIN', 'XX_AP_0025_NO_TAX_LINE');
					  FND_MESSAGE.SET_TOKEN (
											 'INVOICE_NUM'
											 ,lr_non_po_invoices_rec.invoice_num
											);
					  lc_error_msg := FND_MESSAGE.GET;
					  FND_FILE.PUT_LINE (
										 FND_FILE.LOG
										 ,'XX_AP_CREATE_NON_PO_INV_LINES: '|| lc_error_msg
										);
					  --Defect 9420 ## Set prorate_across_flag to NULL 
					  --for Canadian TAX lines if it exists
					  SELECT COUNT(1)
					  INTO   ln_tax_count
					  FROM   ap_invoice_lines_interface AILI
					  WHERE  AILI.invoice_id = lr_non_po_invoices_rec.invoice_id;

					  IF (ln_tax_count > 0) THEN
							UPDATE ap_invoice_lines_interface AILI
							--SET    prorate_across_flag = NULL
							SET    prorate_across_flag = 'N' --Added for Defect# 28446
							WHERE  AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
							AND    NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_tax_lookup_code;
					  END IF;

					  ln_tax_amount := 0;

				   WHEN TOO_MANY_ROWS THEN
					  lc_error_loc := 'TOO_MANY_ROWS Exception: Multiple US Tax Lines Exist for the invoice.';
					  ln_tax_amount := 0;
					  ln_total_line_amt_tx := 0;
					  FND_MESSAGE.CLEAR;
					  FND_MESSAGE.SET_NAME (
											'XXFIN'
											,'XX_AP_0025_MULTIPLE_TAX_LINES'
										   );
					  FND_MESSAGE.SET_TOKEN (
											 'INVOICE_NUM'
											 ,lr_non_po_invoices_rec.invoice_num
											);
					  lc_error_msg := FND_MESSAGE.GET;
					  FND_FILE.PUT_LINE (
										 FND_FILE.LOG
										 ,'XX_AP_CREATE_NON_PO_INV_LINES: '|| lc_error_msg
										);
				END;
			  
				--IF (ln_tax_amount > 0 OR ln_freight_amount > 0) THEN
				IF (ABS(ln_tax_amount) > 0 OR ABS(ln_freight_amount) > 0) THEN --Commented and added for Defect#27858
				   --Fixed defect 5219
				   ln_tax_cum := 0;
				   ln_freight_cum := 0;
				   ln_max_tax := 0;
				   ln_max_freight := 0;
				   ln_tx_diff_line_id := 0;
				   ln_fr_diff_line_id := 0;
	  
				   OPEN lcu_invoice_item_lines (lr_non_po_invoices_rec.invoice_id);
				   LOOP

					  FETCH lcu_invoice_item_lines INTO lr_invoice_item_rec;
					  EXIT WHEN lcu_invoice_item_lines%NOTFOUND;

						 lc_line_exists_flag := 'Y';

						 --Defetc 9420
						 UPDATE ap_invoice_lines_interface AILI
						 SET    line_number = ln_line_number
								,line_group_number = ln_grp_line_number
						 WHERE  AILI.invoice_line_id = lr_invoice_item_rec.invoice_line_id
						 AND    AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
						 AND    NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_item_lookup_code;

						 lc_error_loc := 'Calculating prorated freight amount for each item';

						 --IF (ln_total_line_amt_fr > 0) THEN
						 IF (ABS(ln_total_line_amt_fr) > 0) THEN --Commented and added for Defect#27858
							ln_freight := (lr_invoice_item_rec.amount * ln_freight_amount) / ln_total_line_amt_fr;
							ln_freight := ROUND(ln_freight,2);
						 ELSE
							ln_freight := 0;
						 END IF;

						 lc_error_loc := 'Getting invoice line id from sequence';

						 SELECT ap_invoice_lines_interface_s.NEXTVAL
						 INTO ln_invoice_line_id
						 FROM DUAL;

						FND_FILE.PUT_LINE(FND_FILE.LOG, 'Interface Lines NEXTVAL = '||ln_invoice_line_id);

						 --IF (ln_freight > 0 ) THEN
						 IF (ABS(ln_freight) > 0 ) THEN --Commented and added for Defect#27858
							--Defect 9420
							ln_line_number := ln_line_number +1;
							
							INSERT INTO ap_invoice_lines_interface(
																   invoice_id
																   ,invoice_line_id
																   ,line_type_lookup_code
																   ,line_number             --Defect 9420
																   ,line_group_number       --Defect 9420
																   ,amount
																   ,org_id
																   ,dist_code_concatenated
																   --,project_id
																   --,task_id
																   --,expenditure_type
																   --,project_accounting_context
																   --,expenditure_organization_id
																   --,expenditure_item_date
																   ,last_updated_by
																   ,last_update_date
																   ,created_by
																   ,creation_date
																   ,prorate_across_flag             --Defect 9420
																   ,description  --Added by Darshini for Defect 25089
																   )
															VALUES(
																   lr_non_po_invoices_rec.invoice_id
																   ,ln_invoice_line_id
																   ,gc_freight_lookup_code
																   ,ln_line_number                  --Defect 9420
																   ,ln_grp_line_number              --Defect 9420
																   ,ln_freight
																   ,lr_invoice_item_rec.org_id
																   ,lr_invoice_item_rec.dist_code_concatenated
																   --,lr_invoice_item_rec.project_id                   --Fixed defect 5000
																   --,lr_invoice_item_rec.task_id
																   --,lr_invoice_item_rec.expenditure_type
																   --,lr_invoice_item_rec.project_accounting_context
																   --,lr_invoice_item_rec.expenditure_organization_id
																   --,lr_invoice_item_rec.expenditure_item_date
																   ,lr_invoice_item_rec.last_updated_by
																   ,lr_invoice_item_rec.last_update_date
																   ,lr_invoice_item_rec.created_by
																   ,lr_invoice_item_rec.creation_date
																   ,'Y'                             --Defect 9420
																   ,ln_freight_desc  --Added by Darshini for Defect 25089
																   );
						 END IF;

						 --Fixed defect 5219

						 --IF (ln_max_freight < ln_freight) THEN
						 IF (ABS(ln_max_freight) < ABS(ln_freight)) THEN --Commented and added for Defect#27858
							ln_max_freight := ln_freight;
							ln_fr_diff_line_id := ln_invoice_line_id;
						 END IF;

						 lc_error_loc := 'Calculating prorated tax amount for each item';

						 --IF (ln_total_line_amt_tx > 0) THEN
						 IF (ABS(ln_total_line_amt_tx) > 0) THEN --Commented and added for Defect#27858
							ln_tax := (lr_invoice_item_rec.amount * ln_tax_amount) / ln_total_line_amt_tx;
							ln_tax := ROUND(ln_tax,2);
						 ELSE
							ln_tax := 0;
						 END IF;

						 lc_error_loc := 'Getting invoice line id from sequence';

						 SELECT ap_invoice_lines_interface_s.NEXTVAL
						 INTO ln_invoice_line_id
							FROM DUAL;
							
						FND_FILE.PUT_LINE(FND_FILE.LOG, 'Interface Lines NEXTVAL = '||ln_invoice_line_id);                        
						FND_FILE.PUT_LINE(FND_FILE.LOG, 'Pkg: XX_AP_INV_BLD_NON_PO_LINES; Before TAX > 0 IF code ');                          

						 --IF (ln_tax > 0 ) THEN
						 IF (ABS(ln_tax) > 0 ) THEN --27858 --Commented and added for Defect#27858
							--Defect 9420
							ln_line_number := ln_line_number +1;
				ln_tax_description:=NULL;

				-- Defect 25382

				BEGIN
				  SELECT NVL(b.description,a.description) 
					INTO ln_tax_description
					FROM xx_ap_inv_lines_interface_stg b,
						 xx_ap_inv_interface_stg a 
				   WHERE a.invoice_id=lr_non_po_invoices_rec.invoice_id
								 AND b.invoice_id=a.invoice_id
					 AND b.line_type_lookup_code='TAX' 
					 AND rownum<2;
				EXCEPTION
				  WHEN others THEN
					ln_tax_description:=NULL;
					END; 
				
				-- Defect 25382

						FND_FILE.PUT_LINE(FND_FILE.LOG, 'Pkg: Inside ln_tax > 0 if');     

							
							--added for defect 3128 CR744 Retailease
							IF (p_source = 'US_OD_RENT' AND lr_invoice_item_rec.project_id IS NULL) THEN

							FND_FILE.PUT_LINE(FND_FILE.LOG, 'Pkg: Inside US_OD_RENT if');    
							
							  BEGIN
								 SELECT  item_description
									INTO lc_rtl_gl_code
									FROM xx_ap_inv_lines_interface_stg
								  WHERE invoice_line_id = lr_invoice_item_rec.invoice_line_id;
							  EXCEPTION
								 WHEN NO_DATA_FOUND THEN
									lc_rtl_gl_code := NULL;
								 WHEN OTHERS THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG, 'Tax GL code select failed');
									FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
							  END;
													 
							  FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_rtl_gl_code from item_description = '||lc_rtl_gl_code);                          
							  
							  BEGIN                    
								 SELECT gsb.chart_of_accounts_id
									INTO lc_coa_id
									FROM gl_sets_of_books_v gsb
								   WHERE gsb.set_of_books_id = fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
							  EXCEPTION
								 WHEN NO_DATA_FOUND THEN
									lc_coa_id := NULL;
								 WHEN OTHERS THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG, 'COA select failed');
									FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
							  END;
							  
							  FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_coa_id = '||lc_coa_id);
							 
							  BEGIN
								 SELECT code_combination_id
									 INTO v_ccid
									 FROM gl_code_combinations
								   WHERE chart_of_accounts_id = lc_coa_id
										 AND    segment1 = SUBSTR(lc_rtl_gl_code,1,4)
										 AND    segment2 = SUBSTR(lc_rtl_gl_code,6,5)
										 AND    segment3 = SUBSTR(lc_rtl_gl_code,12,8)
										 AND    segment4 = SUBSTR(lc_rtl_gl_code,21,6)
										 AND    segment5 = SUBSTR(lc_rtl_gl_code,28,4)
										 AND    segment6 = SUBSTR(lc_rtl_gl_code,33,2)
										 AND    segment7 = SUBSTR(lc_rtl_gl_code,36,6);
							  EXCEPTION
								 WHEN NO_DATA_FOUND THEN
									v_ccid := NULL;
								 WHEN OTHERS THEN
									FND_FILE.PUT_LINE(FND_FILE.LOG, 'CCID select failed');
									FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
							  END;
										 
							  FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_ccid = '||v_ccid);
							  FND_FILE.PUT_LINE(FND_FILE.LOG, 'lr_non_po_invoices_rec.invoice_id = '||lr_non_po_invoices_rec.invoice_id);
							  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_invoice_line_id = '||ln_invoice_line_id);
										 
										 --added by Santosh defect 25144
							 
							 If  p_source = 'US_OD_RENT' THEN 
							  ln_prorate_flag:='N';
							 end if;
	-- end here for defect 25144              
							  INSERT INTO ap_invoice_lines_interface(
																   invoice_id
																   ,invoice_line_id
																   ,line_type_lookup_code
									   ,description			--Defect 25382
																   ,line_number                     --Defect 9420
																   ,line_group_number               --Defect 9420
																   ,amount
																   ,tax_code
																   ,org_id
																   ,dist_code_concatenated
																   ,dist_code_combination_id --defect 3128
																   --,project_id
																   --,task_id
																   --,expenditure_type
																   --,project_accounting_context
																   --,expenditure_organization_id
																   --,expenditure_item_date
																   ,last_updated_by
																   ,last_update_date
																   ,created_by
																   ,creation_date
																   ,prorate_across_flag             --Defect 9420
																   )
															VALUES(
																   lr_non_po_invoices_rec.invoice_id
																   ,ln_invoice_line_id
																   ,gc_tax_lookup_code
									   ,ln_tax_description   -- Defect 25382
																   ,ln_line_number                 --Defect 9420
																   ,NULL    --,ln_grp_line_number --Defect 9420 --Replaced with NULL FOR DEFECT 3128 
																   ,ln_tax
																   ,lc_tax_code
																   ,lr_invoice_item_rec.org_id
																   ,lc_rtl_gl_code  --,lr_invoice_item_rec.dist_code_concatenated --replaced with lc_rtl_gl_code for defect 3128
																   ,v_ccid          --defect 3128
																   --,lr_invoice_item_rec.project_id              --Fixed defect 5000
																   --,lr_invoice_item_rec.task_id
																   --,lr_invoice_item_rec.expenditure_type
																   --,lr_invoice_item_rec.project_accounting_context
																   --,lr_invoice_item_rec.expenditure_organization_id
																   --,lr_invoice_item_rec.expenditure_item_date
																   ,lr_invoice_item_rec.last_updated_by
																   ,lr_invoice_item_rec.last_update_date
																   ,lr_invoice_item_rec.created_by
																   ,lr_invoice_item_rec.creation_date
																   ,ln_prorate_flag    --,'Y'                       --Defect 9420 --Replaced with NULL FOR DEFECT 3128
																   );
						 
							ELSE     --NOT 'US_OD_RENT' (Retailease)
								
	--added by Santosh defect 25144
							 
							 If  p_source = 'US_OD_RENT' THEN 
							  ln_prorate_flag:='N';
							 end if;
	-- end here for defect 25144                         

							INSERT INTO ap_invoice_lines_interface(
																   invoice_id
																   ,invoice_line_id
																   ,line_type_lookup_code
									   ,description			--Defect 25382
																   ,line_number                     --Defect 9420
																   ,line_group_number               --Defect 9420
																   ,amount
																   ,tax_code
																   ,org_id
																   ,dist_code_concatenated
																   --,project_id
																   --,task_id
																   --,expenditure_type
																   --,project_accounting_context
																   --,expenditure_organization_id
																   --,expenditure_item_date
																   ,last_updated_by
																   ,last_update_date
																   ,created_by
																   ,creation_date
																   ,prorate_across_flag             --Defect 9420
																   )
															VALUES(
																   lr_non_po_invoices_rec.invoice_id
																   ,ln_invoice_line_id
																   ,gc_tax_lookup_code
									   ,ln_tax_description	       --Defect 25382
																   ,ln_line_number                 --Defect 9420
																   ,ln_grp_line_number             --Defect 9420
																   ,ln_tax
																   ,lc_tax_code
																   ,lr_invoice_item_rec.org_id
																   ,lr_invoice_item_rec.dist_code_concatenated
																   --,lr_invoice_item_rec.project_id              --Fixed defect 5000
																   --,lr_invoice_item_rec.task_id
																   --,lr_invoice_item_rec.expenditure_type
																   --,lr_invoice_item_rec.project_accounting_context
																   --,lr_invoice_item_rec.expenditure_organization_id
																   --,lr_invoice_item_rec.expenditure_item_date
																   ,lr_invoice_item_rec.last_updated_by
																   ,lr_invoice_item_rec.last_update_date
																   ,lr_invoice_item_rec.created_by
																   ,lr_invoice_item_rec.creation_date
																   ,ln_prorate_flag  --25144 replace  'Y'                            --Defect 9420
																   );
																   
							END IF;
							   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Pkg: XX_AP_INV_BLD_NON_PO_LINES; End Retailease IF code ');                          
						 END IF;

						
						 --Fixed defect 5219

						 --IF (ln_max_tax < ln_tax) THEN
						 IF (ABS(ln_max_tax) < ABS(ln_tax)) THEN --Commented and added for Defect#27858
							ln_max_tax := ln_tax;
							ln_tx_diff_line_id := ln_invoice_line_id;
						 END IF;

						 ln_tax_cum := ln_tax_cum + ln_tax;                 --Fixed defect 5219
						 ln_freight_cum := ln_freight_cum + ln_freight;     --Fixed defect 5219

						 --Defect 9420
						 ln_line_number := ln_line_number + 1;
						 ln_grp_line_number := ln_grp_line_number + 1;

				   END LOOP;
				   CLOSE lcu_invoice_item_lines;
				END IF;

				ln_tax_diff := ln_tax_amount - ln_tax_cum;
				ln_freight_diff := ln_freight_amount - ln_freight_cum;

				--Start of fix for defect 5219
				--IF(ln_tax_diff <> 0) THEN
				IF(ABS(ln_tax_diff) <> 0) THEN --Commented and added for Defect#27858
				   UPDATE ap_invoice_lines_interface
					  SET amount = amount + ln_tax_diff
					  WHERE invoice_line_id = ln_tx_diff_line_id
						 AND invoice_id = lr_non_po_invoices_rec.invoice_id;
				END IF;

				--IF(ln_freight_diff <> 0) THEN
				IF(ABS(ln_freight_diff) <> 0) THEN --Commented and added for Defect#27858
				   UPDATE ap_invoice_lines_interface
					  SET amount = amount + ln_freight_diff
					  WHERE invoice_line_id = ln_fr_diff_line_id
						 AND invoice_id = lr_non_po_invoices_rec.invoice_id;
				END IF;

				--End of fix for defect 5219

				IF ( lc_line_exists_flag <> 'Y' ) THEN
				   lc_error_loc := 'No item line exists';

				   SELECT COUNT(1)
				   INTO ln_tax_lines
					  FROM ap_invoice_lines_interface AILI
					  WHERE AILI.invoice_id = lr_non_po_invoices_rec.invoice_id
						 AND NVL(UPPER(AILI.line_type_lookup_code),'X') = gc_tax_lookup_code;

				   IF (ln_tax_lines > 0) THEN
					  FND_MESSAGE.SET_NAME ('XXFIN', 'XX_AP_0054_NON_PO_TAX_ISSUE');
					  lc_reject_code := FND_MESSAGE.GET;
				   ELSE
					  FND_MESSAGE.SET_NAME ('XXFIN', 'XX_AP_0055_NON_PO_ITEM_ISSUE');
					  lc_reject_code := FND_MESSAGE.GET;
				   END IF;

					FND_FILE.PUT_LINE(FND_FILE.LOG, '         '||lr_non_po_invoices_rec.invoice_num ||'          '||lr_non_po_invoices_rec.invoice_id||'          '||lc_reject_code);
					--XX_AP_INV_BUILD_PO_LINES_PKG.xx_ap_reset_invoice_stg (p_group_id,lr_non_po_invoices_rec.invoice_id);
				ELSE

				   BEGIN
					  lc_error_loc := 'Deleting TAX Line from source: '|| ln_tax_line_id;

					  DELETE ap_invoice_lines_interface AILI
						 WHERE AILI.invoice_line_id = ln_tax_line_id;

						FND_FILE.PUT_LINE(FND_FILE.LOG, 'This would delete ln_tax_line_id = '||ln_tax_line_id); 

					  IF (ln_freight_line_id > 0) THEN
						 DELETE ap_invoice_lines_interface AILI
							WHERE AILI.invoice_line_id = ln_freight_line_id;
					  END IF;
				   END;
						FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_rtl_gl_code after delete = '||lc_rtl_gl_code);                          
						FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_ccid after after delete = '||v_ccid);    
				END IF;

				lc_line_exists_flag := 'N';
				ln_tax_cum := 0;
				ln_freight_cum := 0;
				ln_max_tax := 0;
				ln_max_freight := 0;
				ln_tx_diff_line_id := 0;
				ln_fr_diff_line_id := 0;
				ln_tax_line_id := 0;
				ln_freight_line_id := 0;

				--Defect 9420
				ln_line_number := 1;
				ln_grp_line_number := 1;
				ln_prorate_flag := NULL; --added by Santosh defect 25144
		  END IF;
		  END LOOP;
		  CLOSE lcu_non_po_invoices;

		  COMMIT;
	   EXCEPTION
		  WHEN OTHERS THEN
			 FND_MESSAGE.CLEAR;
			 FND_MESSAGE.SET_NAME ('XXFIN', 'XX_AP_0001_ERROR');
			 FND_MESSAGE.SET_TOKEN ('ERR_LOC', lc_error_loc);
			 FND_MESSAGE.SET_TOKEN ('ERR_ORA', SQLERRM);
			 lc_error_msg := FND_MESSAGE.GET;
			 FND_FILE.PUT_LINE (
								FND_FILE.LOG
								,'Other Exception Encountered in XX_AP_CREATE_PO_INV_LINES: '|| lc_error_msg
							   );
			 XX_COM_ERROR_LOG_PUB.LOG_ERROR(
											p_program_type                => 'CONCURRENT PROGRAM'
											,p_program_id                  => fnd_global.conc_program_id
											,p_module_name                 => 'AP'
											,p_error_location              => 'Error at '|| lc_error_loc
											,p_error_message_count         => 1
											,p_error_message_code          => 'E'
											,p_error_message               => lc_error_msg
											,p_error_message_severity      => 'Warning'
											,p_notify_flag                 => 'N'
											,p_object_type                 => 'PO Invoice Line'
											,p_object_id                   => ''
										   );
	   END XX_AP_CREATE_NON_PO_INV_LINES;


	END XX_AP_INV_BLD_NON_PO_LINES_PKG;
	/
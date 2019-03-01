create or replace PACKAGE BODY XX_AP_INVOICE_INTEGRAL_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_INVOICE_INTEGRAL_PKG                                                      |
-- |  RICE ID 	 :                                           			                        |
-- |  Description:                                                                          	|
-- |                                                           				                    |
-- +============================================================================================+
-- | Version     Date         Author              Remarks                                       |
-- | =========   ===========  =============       ==============================================|
-- | 1.0         05/04/2017   Havish Kasina       Initial version                               |
-- | 1.1         09/23/2017   Suresh Ponnambalam  Continue process if file does not exist.      |
-- | 1.2         10/02/2017   Havish Kasina       Added the logic to make the invoice line type |
-- |                                              as MISCELLANEOUS when sku is invalid          |
-- | 1.3         10/04/2017   Havish Kasina       Adding a new PO line if PO Line doesn't exist |
-- |                                              in the PO but we get in the Invoice File      |
-- | 1.4         10/06/2017   Havish Kasina       For Consignment Unabsorbed lines we get the   |
-- |                                              GL String from the Translation                |
-- | 1.5         10/06/2017   Havish Kasina       Added LTRIM to value in the description field |
-- | 1.6         10/10/2017   Havish Kasina       Modified the logic to populate the header desc|
-- | 1.7         10/13/2017   Havish Kasina       Remove all preceding Zero's and any nonalpha/ |
-- |                                              nonnumeric from invoice numbers               |
-- | 1.8         10/13/2017   Havish Kasina       Getting the sign for the SAC Code             |
-- | 1.9         10/24/2017   Havish Kasina       Stopping TDM invoices for the Consignment     |
-- |                                              suppliers if the invoices are coded and       |
-- |                                              approved                                      |
-- | 2.0         10/31/2017   Havish Kasina       For Below lines in the EDI source, To get the |
-- |                                              gl company and gl location from the PO only if|
-- |                                              they are NULL in the Reason Code Translation  |
-- | 2.1         10/31/2017   Havish Kasina       Added the new parameters in the procedure     |
-- |                                              mtl_transaction_int                           |
-- | 2.2         10/31/2017   Havish Kasina       IF SAC Code doesn't exist in the Translation, |
-- |                                              then pass the GL String as NULL and invoice   |
-- |                                              will get fail in the Payables Open Interface  |
-- |                                              for the Invalid Distribution Acct Issue       |
-- | 2.3         11/01/2017   Havish Kasina       All invoices with header and detail (approved |
-- |                                              invoices) should have payment terms of N00.All|
-- |                                              invoices with header only,payment terms should|
-- |                                              be derived from PO terms (Defect 11779)       |
-- | 2.4         11/03/2017   Havish Kasina       Populating the Reason code value in the       |
-- |                                              Attribute11 in the lines staging table        |
-- | 2.5         11/14/2017   Havish Kasina       Creating the new Miscellaneous line if the SKU|
-- |                                              doesn't exist for the respective PO Location  |
-- | 2.6         11/20/2017   Havish Kasina       Added a new procedure which reads data from   |
-- |                                              the PO base tables and update the Invoice     |
-- |                                              interface lines table with PO reference       |
-- |                                              (PO Line Number)                              |
-- | 2.7         11/20/2017   Havish Kasina       Added a new translation XX_AP_TRADE_INV_EMAIL |
-- |                                              to get the email details                      |
-- | 2.8         11/27/2017   Havish Kasina       Added a new logic to create the Freight line  |
-- |                                              for the TDM Unapproved Invoices               |
-- | 2.9         12/11/2017   Havish Kasina       Added the logic to create the Miscellaneous   |
-- |                                              issue for Consignment Sales                   |
-- | 3.0         01/08/2018   Havish Kasina       1.Made change in the EDI source to populate   |
-- |                                                UOM value                                   |
-- |                                              2.Calling the new procedure to identify the   |
-- |                                                missing POs                                 |
-- | 3.1         01/15/2018   Havish Kasina       Added the logic to create the Consignment     |
-- |                                              Invoice even by passing date parameters       |
-- | 3.2         02/27/2018   Havish Kasina       Added the logic to insert the po missing      |
-- |                                              records into xx_po_pom_missed_in_int table    |
-- | 3.3         02/28/2018   Havish Kasina       Added the logic to get the PO Line number for |
-- |                                              EDI invoices for both Regular and Tier Pricing|
-- |                                              Scenarios                                     |
-- | 3.4         04/07/2018   Havish Kasina       Added the lc_stg_uom_code variable to pass the|
-- |                                              uom code to po_lines_interface table          |
-- | 3.5         04/09/2018   Havish Kasina       Added the new field misc_issue_flag in the    |
-- |                                              xx_ap_trade_inv_lines table                   |
-- | 3.6         04/18/2018   Antonio Morales     Change cursor lines_consign_summ_cur to       |
-- |                                              improve performance. Also, load locations     |
-- |                                              table in an table array to do a faster search |
-- |                                              in memory.                                    |
-- | 3.7         04/18/2018   Havish Kasina       Modified the update_interface_lines_dtls proc |
-- |                                              to consider the PO Vendor Payment Method, Pay |
-- |                                              Group                                         |
-- | 3.8         04/20/2018   Antonio Morales     Change cursor lines_consign_summ_cur to       |
-- |                                              process only items with type <> '02'          |
-- | 3.9         05/30/2018   Atul Khard	      Added Exception for failing the request if a  |
-- |                                              corrupt file has been received it will only   |
-- |                                              skip only the bad records (NAIT-48272)        |
-- | 4.0         06/28/2018   Vivek Kumar         NAIT-48272 (Defect#45304) Send email alert    |
-- |                                              when there is corrupt File                    |
-- | 4.1         06/14/2018   Madhan Sanjeevi     Modified for Defect# 45153 - NAIT-40379       |
-- | 4.2         06/18/2018   Madhan Sanjeevi     Modified for Defect# 45221 NAIT-40778         |
-- | 4.3         07/10/2018   Kirubha Samuel      Modified for Defect# 45074 NAIT-42786         |
-- | 4.4         06/28/2018   Antonio Morales     Eliminate the trim of PO Number when EDI      |
-- |                                              invoices are created                          |
-- | 4.5         08/20/2018   Antonio Morales     Changes to support 8/7/6 digits PO in all     |
-- |                                              sources                                       |
-- | 4.6         11/09/2018   Arun DSouza         Changes for PRG RTV Source                    |
-- | 4.7         12/28/2018   Arun DSouza         Changes for PO Mismatch Defect                |
-- | 4.5         08/27/2018   Vivek Kumar         Modified For NAIT - 57153 -Add Vendor Name and|
-- |                                              Vendor Site Number to the Alert for           |
-- |                                              Consignment Supplier Coming in EDI file       |
-- | 4.6         01/24/2019   BIAS                INSTANCE_NAME is replaced with DB_NAME for OCI|
-- |                                              Migration 
-- +============================================================================================+

-- +============================================================================================+
-- |  Name	 : Log Exception                                                                    |
-- |  Description: The log_exception procedure logs all exceptions                              |
-- =============================================================================================|

gc_debug 	                VARCHAR2(2);
gn_request_id               fnd_concurrent_requests.request_id%TYPE;
gn_user_id                  fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	            NUMBER;
gn_batch_id                 NUMBER;
gn_bad_file_rec_count		NUMBER :=0;  -- Added as per changes in Version 3.9
gn_bad_rec_flag				NUMBER :=0;  -- Added as per changes in Version 3.9
gn_count                    NUMBER :=0;   ---Added For NAIT-48272
ln_conc_request_id          NUMBER;       ---Added For NAIT-48272


-- AM 4/18/18
-- Cursor to Store locations to speed up the search process

    CURSOR c_hrl IS
      SELECT attribute1
            ,inventory_organization_id
        FROM hr_locations_all
       WHERE in_organization_flag = 'Y'
         AND inventory_organization_id IS NOT NULL;

    TYPE t_htl IS TABLE OF c_hrl%ROWTYPE INDEX BY PLS_INTEGER;
    thtl t_htl;


PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                        ,p_error_location     IN  VARCHAR2
		                ,p_error_msg          IN  VARCHAR2)
IS
ln_login     NUMBER   :=  FND_GLOBAL.LOGIN_ID;
ln_user_id   NUMBER   :=  FND_GLOBAL.USER_ID;
BEGIN
XX_COM_ERROR_LOG_PUB.log_error(
			     p_return_code             => FND_API.G_RET_STS_ERROR
			    ,p_msg_count               => 1
			    ,p_application_name        => 'XXFIN'
			    ,p_program_type            => 'Custom Messages'
			    ,p_program_name            => p_program_name
			    ,p_attribute15             => p_program_name
			    ,p_program_id              => null
			    ,p_module_name             => 'AP'
			    ,p_error_location          => p_error_location
			    ,p_error_message_code      => null
			    ,p_error_message           => p_error_msg
			    ,p_error_message_severity  => 'MAJOR'
			    ,p_error_status            => 'ACTIVE'
			    ,p_created_by              => ln_user_id
			    ,p_last_updated_by         => ln_user_id
			    ,p_last_update_login       => ln_login
			    );

EXCEPTION
WHEN OTHERS
THEN
    fnd_file.put_line(fnd_file.log, 'Error while writing to the log ...'|| SQLERRM);
END log_exception;

/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    IF (gc_debug = 'Y' OR p_force)
    THEN
        lc_Message := p_message;
        fnd_file.put_line (fnd_file.log, lc_Message);

        IF ( fnd_global.conc_request_id = 0
            OR fnd_global.conc_request_id = -1)
        THEN
            dbms_output.put_line (lc_message);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END print_debug_msg;

/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg (p_message IN VARCHAR2)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    lc_message := p_message;
    fnd_file.put_line (fnd_file.output, lc_message);

    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
    THEN
        dbms_output.put_line (lc_message);
    END IF;
EXCEPTION
WHEN OTHERS
THEN
    NULL;
END print_out_msg;

-- +============================================================================================+
-- |  Name	 : get_inventory_item_id                                                            |
-- |  Description: Procedure to get the inventory Item ID for the respective SKU                |
-- =============================================================================================|
PROCEDURE get_inventory_item_id(p_sku                IN  VARCHAR2
                               ,p_po_number          IN  VARCHAR2
						       ,o_inventory_item_id  OUT NUMBER
							   ,o_po_type            OUT VARCHAR2)
IS
BEGIN

	SELECT msi.inventory_item_id,
	       poh.attribute_category
	  INTO o_inventory_item_id,
	       o_po_type
	  FROM mtl_system_items_b msi,
           po_headers_all poh,
           hr_locations hrl,
           hr_all_organization_units hru
     WHERE msi.segment1 = LTRIM(p_sku,'0')
       AND poh.segment1 = p_po_number
	   AND msi.organization_id = hru.organization_id
       AND poh.ship_to_location_id = hrl.location_id
       AND hrl.location_id = hru.location_id;
EXCEPTION
	WHEN OTHERS
	THEN
	    o_inventory_item_id := NULL;
		o_po_type := NULL;
	    print_debug_msg ('Unable to get the Inventory Item ID for the SKU :'||p_sku||' - '||substr(sqlerrm,1,250),FALSE);
END get_inventory_item_id;

-- +============================================================================================+
-- |  Name	 : get_vendor_sites_kff_id                                                          |
-- |  Description: Procedure to get the frequency code for the respective Vendor Sites KFF ID   |
-- =============================================================================================|
PROCEDURE get_vendor_sites_kff_id(p_vendor_sites_kff_id  IN  NUMBER
						         ,o_frequency_code       OUT VARCHAR2)
IS
BEGIN

    SELECT segment44
	  INTO o_frequency_code
	  FROM xx_po_vendor_sites_kff
	 WHERE vs_kff_id = p_vendor_sites_kff_id;
EXCEPTION
	WHEN OTHERS
	THEN
	    o_frequency_code := NULL;
	    print_debug_msg ('Unable to get the Frequency Code for the KFF ID :'||p_vendor_sites_kff_id||' - '||substr(sqlerrm,1,250),FALSE);
END get_vendor_sites_kff_id;

-- +============================================================================================+
-- |  Name	 : get_po_line_num                                                                  |
-- |  Description: Procedure to get the PO Line Number                                          |
-- =============================================================================================|
PROCEDURE get_po_line_num(p_po_number         IN  VARCHAR2
						 ,p_inventory_item_id IN  NUMBER
						 ,p_sku               IN  VARCHAR2
						 ,p_unit_price        IN  NUMBER
						 ,p_quantity          IN  NUMBER
						 ,p_inv_line_num      IN  NUMBER
						 ,p_invoice_id        IN  NUMBER
						 ,o_po_attr_category  OUT VARCHAR2
						 ,o_po_line_num       OUT NUMBER
						 ,o_uom_code          OUT VARCHAR2)
IS
lc_error_loc            VARCHAR2(100);
lc_error_msg            VARCHAR2(300);
ln_po_header_id         NUMBER;
ln_max_stg_po_line_num  NUMBER;
ln_max_po_line_num      NUMBER;

BEGIN
    fnd_file.put_line(fnd_file.log,'Processing PO Number :'||p_po_number);
	BEGIN
        SELECT po_header_id, attribute_category
	      INTO ln_po_header_id, o_po_attr_category
	      FROM po_headers_all
	     WHERE segment1 = p_po_number;
	EXCEPTION
	WHEN OTHERS
	THEN
	    ln_po_header_id := NULL;
		o_po_attr_category := NULL;
	END;

	IF ln_po_header_id IS NOT NULL
	THEN
        BEGIN
   	         SELECT pla.line_num,
		            pla.unit_meas_lookup_code
	           INTO o_po_line_num,
		            o_uom_code
	           FROM po_lines_all pla
	          WHERE 1 =1
			    AND pla.po_header_id = ln_po_header_id
	            AND pla.item_id = p_inventory_item_id
	            AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
	          ORDER BY pla.line_num;

        EXCEPTION
        WHEN TOO_MANY_ROWS -- If SKU returns more than 1 row
	    THEN
	        BEGIN
		         SELECT pla.line_num,
				        pla.unit_meas_lookup_code
			       INTO o_po_line_num,
		                o_uom_code
	               FROM po_lines_all pla
	              WHERE 1 =1
	                AND pla.item_id = p_inventory_item_id
	                AND pla.unit_price = p_unit_price
	                AND pla.po_header_id = ln_po_header_id
			        AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
			      ORDER BY pla.line_num;
		    EXCEPTION
		    WHEN TOO_MANY_ROWS -- Combination of SKU and price retrun more than 1 row
		    THEN
			    BEGIN
			        SELECT MAX(TO_NUMBER(po_line_number))
				      INTO ln_max_stg_po_line_num
				      FROM xx_ap_trade_inv_lines
--				     WHERE po_number= SUBSTR(p_po_number,1,7)
				     WHERE
             po_number=  substr(p_po_number,1,instr(p_po_number,'-')-1) -- Arun added 12/28/2018
--           po_number= p_po_number  -- version 4.6 Commented by Arun for po match fix in line above
--					 AND location_number = SUBSTR(p_po_number,9,12)
					   AND location_number = SUBSTR(p_po_number,INSTR(p_po_number,'-')+1) -- version 4.6
					   AND sku = p_sku
					   AND cost = p_unit_price;
			    EXCEPTION
			    WHEN OTHERS
				THEN
				    ln_max_stg_po_line_num := NULL;
			    END;
				IF ln_max_stg_po_line_num IS NULL
				THEN
				    BEGIN
				        SELECT a.line_num,
					    	   a.unit_meas_lookup_code
					      INTO o_po_line_num,
					           o_uom_code
                          FROM (SELECT pla.line_num,
				                       pla.unit_meas_lookup_code
	                              FROM po_lines_all pla
	                             WHERE 1 =1
	                               AND pla.item_id = p_inventory_item_id
	                               AND pla.unit_price = p_unit_price
	                               AND pla.po_header_id = ln_po_header_id
			                       AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
					             ORDER BY pla.line_num)a
					     WHERE ROWNUM = 1;
					EXCEPTION
					WHEN OTHERS
					THEN
					    o_po_line_num := NULL;
					    o_uom_code    := NULL;
					END;
				ELSE
				    BEGIN
					    SELECT MAX(pla.line_num)
			              INTO ln_max_po_line_num
	                      FROM po_lines_all pla
	                     WHERE 1 =1
	                       AND pla.item_id = p_inventory_item_id
	                       AND pla.unit_price = p_unit_price
	                       AND pla.po_header_id = ln_po_header_id
			               AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL);

					EXCEPTION
					WHEN OTHERS
					THEN
						ln_max_po_line_num := NULL;
					END;

					-- fnd_file.put_line(fnd_file.log,'Max PO Line Number :'||ln_max_po_line_num);

					IF ln_max_stg_po_line_num <> ln_max_po_line_num
					THEN
					    BEGIN
						    SELECT a.line_num,
						           a.unit_meas_lookup_code
					          INTO o_po_line_num,
					               o_uom_code
                              FROM (SELECT pla.line_num,
				                           pla.unit_meas_lookup_code
	                                  FROM po_lines_all pla
	                                 WHERE 1 =1
	                                   AND pla.item_id = p_inventory_item_id
	                                   AND pla.unit_price = p_unit_price
	                                   AND pla.po_header_id = ln_po_header_id
						    		   AND pla.line_num > ln_max_stg_po_line_num
			                           AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
					                 ORDER BY pla.line_num)a
					         WHERE ROWNUM = 1;
							 -- fnd_file.put_line(fnd_file.log,'6. PO Line Number :'||o_po_line_num);
						EXCEPTION
					    WHEN OTHERS
					    THEN
					        o_po_line_num := NULL;
					        o_uom_code    := NULL;
							--fnd_file.put_line(fnd_file.log,'7. PO Line Number :'||o_po_line_num);
					    END;
					ELSE
					    BEGIN
						    SELECT a.line_num,
						           a.unit_meas_lookup_code
					          INTO o_po_line_num,
					               o_uom_code
                              FROM (SELECT pla.line_num,
				                           pla.unit_meas_lookup_code
	                                  FROM po_lines_all pla
	                                 WHERE 1 =1
	                                   AND pla.item_id = p_inventory_item_id
	                                   AND pla.unit_price = p_unit_price
	                                   AND pla.po_header_id = ln_po_header_id
			                           AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
						    		   AND NOT EXISTS ( SELECT 1
	                                                      FROM xx_ap_trade_inv_lines
						                                 WHERE invoice_id = p_invoice_id
						                                   AND po_line_number = pla.line_num)
					                ORDER BY pla.line_num)a
					         WHERE ROWNUM = 1;
							 --fnd_file.put_line(fnd_file.log,'8. PO Line Number :'||o_po_line_num);
						EXCEPTION
					    WHEN OTHERS
					    THEN
					        o_po_line_num := NULL;
					        o_uom_code    := NULL;
					    END;
					END IF;
				END IF;

			WHEN NO_DATA_FOUND -- Combination of SKU and Price return 0 rows
			THEN
	            BEGIN
			        SELECT MAX(TO_NUMBER(po_line_number))
				      INTO ln_max_stg_po_line_num
				      FROM xx_ap_trade_inv_lines
--				     WHERE po_number= SUBSTR(p_po_number,1,7)
				     WHERE
               po_number=  substr(p_po_number,1,instr(p_po_number,'-')-1) -- Arun added 12/28/2018
--             po_number= p_po_number        -- version 4.6 Commented by Arun and replaced with line above.
--					   AND location_number = SUBSTR(p_po_number,9,12)
					   AND location_number = SUBSTR(p_po_number,INSTR(p_po_number,'-')+1) -- version 4.6
					   AND sku = p_sku
					   AND cost = p_unit_price;
			    EXCEPTION
			    WHEN OTHERS
			    THEN
				    ln_max_stg_po_line_num := NULL;
			    END;

			    IF ln_max_stg_po_line_num IS NULL
			    THEN
			        BEGIN
				        SELECT a.line_num,
				               a.unit_meas_lookup_code
				          INTO o_po_line_num,
				               o_uom_code
                          FROM (SELECT pla.line_num,
				                       pla.unit_meas_lookup_code
	                              FROM po_lines_all pla
	                             WHERE 1 =1
	                               AND pla.item_id = p_inventory_item_id
	                               AND pla.po_header_id = ln_po_header_id
			                       AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
				              ORDER BY pla.line_num)a
				         WHERE ROWNUM = 1;
					    --fnd_file.put_line(fnd_file.log,'9. PO Line Number :'||o_po_line_num);
				    EXCEPTION
				    WHEN OTHERS
				    THEN
				    	o_po_line_num := NULL;
				    	o_uom_code    := NULL;
				    	--fnd_file.put_line(fnd_file.log,'10. PO Line Number :'||o_po_line_num);
				    END;
		        ELSE
				    BEGIN
					    SELECT MAX(pla.line_num)
			              INTO ln_max_po_line_num
	                      FROM po_lines_all pla
	                     WHERE 1 =1
	                       AND pla.item_id = p_inventory_item_id
	                       AND pla.po_header_id = ln_po_header_id
			               AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL);
				    EXCEPTION
				    WHEN OTHERS
				    THEN
				    	ln_max_po_line_num := NULL;
				    END;

				    IF ln_max_stg_po_line_num <> ln_max_po_line_num
				    THEN
				        BEGIN
					        SELECT a.line_num,
					        	   a.unit_meas_lookup_code
					          INTO o_po_line_num,
					               o_uom_code
                              FROM (SELECT pla.line_num,
				                           pla.unit_meas_lookup_code
	                                  FROM po_lines_all pla
	                                 WHERE 1 =1
	                                   AND pla.item_id = p_inventory_item_id
	                                   AND pla.po_header_id = ln_po_header_id
					        		   AND pla.line_num > ln_max_stg_po_line_num
			                           AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
					                 ORDER BY pla.line_num)a
					         WHERE ROWNUM = 1;
						    --fnd_file.put_line(fnd_file.log,'11. PO Line Number :'||o_po_line_num);
					    EXCEPTION
					    WHEN OTHERS
					    THEN
					       o_po_line_num := NULL;
					       o_uom_code    := NULL;
					    END;
				    ELSE
				        BEGIN
					        SELECT a.line_num,
					        	   a.unit_meas_lookup_code
					          INTO o_po_line_num,
					               o_uom_code
                              FROM (SELECT pla.line_num,
				                           pla.unit_meas_lookup_code
	                                  FROM po_lines_all pla
	                                 WHERE 1 =1
	                                   AND pla.item_id = p_inventory_item_id
	                                   AND pla.po_header_id = ln_po_header_id
			                           AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
					        		   AND NOT EXISTS ( SELECT 1
	                                                      FROM xx_ap_trade_inv_lines
					        	                         WHERE invoice_id = p_invoice_id
					        	                           AND po_line_number = pla.line_num)
					                 ORDER BY pla.line_num)a
					         WHERE ROWNUM = 1;
						     --fnd_file.put_line(fnd_file.log,'12. PO Line Number :'||o_po_line_num);
					    EXCEPTION
					    WHEN OTHERS
					    THEN
					        o_po_line_num := NULL;
					        o_uom_code    := NULL;
					    END;
				    END IF;
		        END IF;

			WHEN OTHERS -- Combination of SKU and Price return 0 rows
			THEN
	            o_po_line_num := NULL;
				o_uom_code := NULL;
			END;

		WHEN NO_DATA_FOUND -- SKU retrun 0 rows
		THEN
			o_po_line_num := NULL;
			o_uom_code := NULL;
		WHEN OTHERS
		THEN
	        o_po_line_num := NULL;
			o_uom_code := NULL;
		END;

    ELSE
	    o_po_attr_category := NULL;
	    o_po_line_num := NULL;
		o_uom_code := NULL;
	END IF;

EXCEPTION
WHEN OTHERS
THEN
    o_po_attr_category := NULL;
	o_po_line_num := NULL;
	o_uom_code := NULL;
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('Unable to get the PO Line Number for the PO Number :'||p_po_number||' - '||substr(sqlerrm,1,250),FALSE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.get_po_line_num',
                   lc_error_loc,
		           lc_error_msg);
END get_po_line_num;

-- +============================================================================================+
-- |  Name	 : get_po_line_num_int                                                              |
-- |  Description: Procedure to get the PO Line Number                                          |
-- =============================================================================================|
PROCEDURE get_po_line_num_int(p_header_id         IN  NUMBER
						     ,p_inventory_item_id IN  NUMBER
						     ,p_unit_price        IN  NUMBER
						     ,p_quantity          IN  NUMBER
						     ,p_inv_line_num      IN  NUMBER
						     ,p_invoice_id        IN  NUMBER
						     ,o_po_line_num       OUT NUMBER
						     ,o_uom_code          OUT VARCHAR2)
IS
lc_error_loc VARCHAR2(100);
lc_error_msg VARCHAR2(300);
BEGIN
   	SELECT pla.line_num,
		   pla.unit_meas_lookup_code
	  INTO o_po_line_num,
		   o_uom_code
	  FROM po_lines_all pla
	 WHERE 1 =1
	   AND pla.item_id = p_inventory_item_id
	   AND pla.po_header_id = p_header_id
	   AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
       AND NOT EXISTS ( SELECT 1
	                      FROM ap_invoice_lines_interface
						 WHERE invoice_id = p_invoice_id
						   AND po_line_number = pla.line_num)
	 ORDER BY pla.line_num;

EXCEPTION
    WHEN TOO_MANY_ROWS -- If SKU returns more than 1 row
	THEN
	    BEGIN
		    SELECT pla.line_num,
				   pla.unit_meas_lookup_code
			  INTO o_po_line_num,
		           o_uom_code
	          FROM po_lines_all pla
	         WHERE 1 =1
	           AND pla.item_id = p_inventory_item_id
	           AND pla.po_header_id = p_header_id
	           AND pla.unit_price = p_unit_price
			   AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
			   AND NOT EXISTS ( SELECT 1
	                             FROM ap_invoice_lines_interface
						        WHERE invoice_id = p_invoice_id
						          AND po_line_number = pla.line_num)
			 ORDER BY pla.line_num;
		EXCEPTION
		WHEN TOO_MANY_ROWS -- Combination of SKU and price retrun more than 1 row
		THEN
		    BEGIN
			    SELECT line_num,
					   unit_meas_lookup_code
				  INTO o_po_line_num,
		               o_uom_code
				  FROM
		             (SELECT rownum ln_num,
				             pla.line_num,
			    	         pla.unit_meas_lookup_code
	                    FROM po_lines_all pla
	                   WHERE 1 =1
	                     AND pla.item_id = p_inventory_item_id
	                     AND pla.po_header_id = p_header_id
				         AND pla.unit_price = p_unit_price
			             AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
						 AND NOT EXISTS ( SELECT 1
	                                        FROM ap_invoice_lines_interface
						                   WHERE invoice_id = p_invoice_id
						                     AND po_line_number = pla.line_num)
			           ORDER BY pla.line_num)
				  WHERE ln_num = p_inv_line_num
				 ;
			EXCEPTION
			WHEN NO_DATA_FOUND -- Combination of SKU, Price and Invoice Line Num return 0 rows
			THEN
	            o_po_line_num := NULL;
				o_uom_code := NULL;
			WHEN OTHERS -- Combination of SKU, Price and Invoice Line Num return 0 rows
			THEN
	            o_po_line_num := NULL;
				o_uom_code := NULL;
			END;

		WHEN NO_DATA_FOUND -- Combination of SKU and price retrun 0 rows
		THEN
		    BEGIN
		        SELECT line_num,
					   unit_meas_lookup_code
				  INTO o_po_line_num,
		               o_uom_code
				  FROM
		             (SELECT rownum ln_num,
				             pla.line_num,
			    	         pla.unit_meas_lookup_code
	                    FROM po_lines_all pla
	                   WHERE 1 =1
	                     AND pla.item_id = p_inventory_item_id
	                     AND pla.po_header_id = p_header_id
			             AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
						 AND NOT EXISTS ( SELECT 1
	                                        FROM ap_invoice_lines_interface
						                   WHERE invoice_id = p_invoice_id
						                     AND po_line_number = pla.line_num)
			           ORDER BY pla.line_num)
				  WHERE ln_num = p_inv_line_num
				 ;
			EXCEPTION
			WHEN NO_DATA_FOUND -- Combination of SKU and Invoice Line Num return 0 rows
			THEN
	            o_po_line_num := NULL;
				o_uom_code := NULL;
			WHEN OTHERS -- Combination of SKU and Invoice Line Num return 0 rows
			THEN
	            o_po_line_num := NULL;
				o_uom_code := NULL;
			END;

		WHEN OTHERS
		THEN
	        o_po_line_num := NULL;
			o_uom_code := NULL;
		END;

    WHEN NO_DATA_FOUND -- SKU retrun 0 rows
	THEN
		BEGIN
		    SELECT line_num,
				   unit_meas_lookup_code
			  INTO o_po_line_num,
		           o_uom_code
			  FROM
		          (SELECT rownum ln_num,
				          pla.line_num,
			    	      pla.unit_meas_lookup_code
	                FROM  po_lines_all pla
	               WHERE 1 =1
	                 AND pla.item_id = p_inventory_item_id
	                 AND pla.po_header_id = p_header_id
			         AND (pla.closed_code = 'OPEN' OR pla.closed_code IS NULL)
				     AND NOT EXISTS ( SELECT 1
	                                    FROM ap_invoice_lines_interface
						               WHERE invoice_id = p_invoice_id
						                 AND po_line_number = pla.line_num)
			       ORDER BY pla.line_num)
			 WHERE ln_num = p_inv_line_num;

		EXCEPTION
		WHEN NO_DATA_FOUND -- Combination of SKU and Invoice Line Num return 0 rows
		THEN
	        o_po_line_num := NULL;
		    o_uom_code := NULL;
		WHEN OTHERS -- Combination of SKU and Invoice Line Num return 0 rows
		THEN
	        o_po_line_num := NULL;
		    o_uom_code := NULL;
	    END;
    WHEN OTHERS
    THEN
	    o_po_line_num := NULL;
		o_uom_code := NULL;
        lc_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('Unable to get the PO Line Number for the PO Header ID :'||p_header_id||' - '||substr(sqlerrm,1,250),FALSE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.get_po_line_num_int',
                       lc_error_loc,
		               lc_error_msg);
END get_po_line_num_int;

-- +============================================================================================+
-- |  Name	 : get_po_terms_id                                                                  |
-- |  Description: Procedure to get the PO Terms ID                                             |
-- =============================================================================================|
PROCEDURE get_po_terms_id(p_po_number         IN   VARCHAR2
						 ,o_terms_id          OUT  NUMBER)
IS
lc_error_loc VARCHAR2(100);
lc_error_msg VARCHAR2(300);
BEGIN
   	SELECT pha.terms_id
	  INTO o_terms_id
	  FROM po_headers_all pha
	 WHERE 1 =1
	   AND pha.segment1 = p_po_number;
EXCEPTION
    WHEN OTHERS
    THEN
        o_terms_id := NULL;
        lc_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('Unable to get the PO Terms ID for the PO Number :'||p_po_number||' - '||substr(sqlerrm,1,250),FALSE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.get_po_terms_id',
                       lc_error_loc,
		               lc_error_msg);
END get_po_terms_id;

-- +============================================================================================+
-- |  Name	 : get_supplier_info                                                                |
-- |  Description: Procedure to get the supplier information                                    |
-- =============================================================================================|
PROCEDURE get_supplier_info (p_vendor                  IN   VARCHAR2
						    ,o_terms_id                OUT  NUMBER
							,o_pay_group_lookup_code   OUT  VARCHAR2
                            ,o_pymt_method_lookup_code OUT  VARCHAR2
                            ,o_supp_attr_category      OUT  VARCHAR2
							,o_vendor_sites_kff_id     OUT  NUMBER)
IS
BEGIN

	SELECT c.pay_group_lookup_code,
       	   c.terms_id,
           a.payment_method_code ,
		   c.attribute8,
		   c.attribute12
	  INTO o_pay_group_lookup_code,
	       o_terms_id,
		   o_pymt_method_lookup_code,
		   o_supp_attr_category,
		   o_vendor_sites_kff_id
      FROM iby_ext_party_pmt_mthds a,
	       iby_external_payees_all b,
           ap_supplier_sites_all c,
           ap_suppliers d
     WHERE 1 = 1
	   AND LTRIM(c.vendor_site_code_alt,'0') = LTRIM(p_vendor,'0')
	   AND d.vendor_id = c.vendor_id
       AND c.vendor_site_id = b.supplier_site_id
	   AND a.ext_pmt_party_id = b.ext_payee_id
	   AND a.primary_flag = 'Y'
	   AND c.pay_site_flag = 'Y'
       AND c.attribute8 LIKE 'TR%'
       AND ((c.inactive_date IS NULL) OR (c.inactive_date > SYSDATE));

EXCEPTION
    WHEN TOO_MANY_ROWS
	THEN
	    SELECT c.pay_group_lookup_code,
       	       c.terms_id,
               a.payment_method_code ,
		       c.attribute8,
		       c.attribute12
	      INTO o_pay_group_lookup_code,
	           o_terms_id,
		       o_pymt_method_lookup_code,
		       o_supp_attr_category,
		       o_vendor_sites_kff_id
          FROM iby_ext_party_pmt_mthds a,
	           iby_external_payees_all b,
               ap_supplier_sites_all c,
               ap_suppliers d
         WHERE 1 = 1
	       AND LTRIM(c.vendor_site_code_alt,'0') = LTRIM(p_vendor,'0')
	       AND d.vendor_id = c.vendor_id
           AND c.vendor_site_id = b.supplier_site_id
	       AND a.ext_pmt_party_id = b.ext_payee_id
	       AND a.primary_flag = 'Y'
	       AND c.pay_site_flag = 'Y'
           AND c.attribute8 LIKE 'TR%'
           AND ((c.inactive_date IS NULL) OR (c.inactive_date > SYSDATE))
		   AND ROWNUM = 1;

    WHEN OTHERS
    THEN
	    o_supp_attr_category := NULL;
	    o_terms_id := NULL;
	    o_pay_group_lookup_code := NULL;
	    o_pymt_method_lookup_code := NULL;
		o_vendor_sites_kff_id := NULL;
END get_supplier_info;

-- +============================================================================================+
-- |  Name	 : get_item_details                                                                |
-- |  Description: Procedure to get the supplier information                                    |
-- =============================================================================================|
PROCEDURE get_item_details(p_sku                    IN   VARCHAR2
						  ,p_location               IN   VARCHAR2
						  ,o_inventory_item_id      OUT  NUMBER
                          ,o_organization_id        OUT  NUMBER
                          ,o_uom_code               OUT  VARCHAR2
						  )
IS
BEGIN
	SELECT msi.inventory_item_id,
           msi.organization_id,
           msi.primary_uom_code
	  INTO o_inventory_item_id,
		   o_organization_id,
		   o_uom_code
      FROM
           hr_locations hl,
		   mtl_system_items_b msi
     WHERE msi.segment1 = LTRIM(p_sku,'0')
	   AND hl.inventory_organization_id=msi.organization_id+0
       AND LTRIM(hl.attribute1,'0') = p_location;

EXCEPTION
    WHEN NO_DATA_FOUND
	THEN
	    BEGIN
	        SELECT inventory_item_id,
                   primary_uom_code
              INTO o_inventory_item_id,
                   o_uom_code
		      FROM mtl_system_items_b
             WHERE segment1 = LTRIM(p_sku,'0')
               AND ROWNUM = 1;
		EXCEPTION
		WHEN OTHERS
		THEN
		    o_inventory_item_id := p_sku; -- Passing the location value as inventory item id. So,the record will fail in MTL_TRANSACTIONS_INTERFACE
            o_uom_code := NULL;
		END;
		-- To get the Organization ID
		BEGIN
		     SELECT inventory_organization_id
			   INTO o_organization_id
			   FROM hr_locations
              WHERE LTRIM(attribute1,'0') = LTRIM(p_location,'0')
			    AND in_organization_flag = 'Y'
				AND inventory_organization_id IS NOT NULL;
		EXCEPTION
		WHEN OTHERS
		THEN
		    o_organization_id := p_location; -- Passing the location value as organization id. So,the record will fail in MTL_TRANSACTIONS_INTERFACE
		END;
	WHEN OTHERS
    THEN
        o_inventory_item_id := p_sku;
		o_organization_id   := p_location;
		o_uom_code          := NULL;
END get_item_details;

-- +============================================================================================+
-- |  Name	 : get_po_vendor_site_code                                                          |
-- |  Description: Procedure to get the PO Vendor Site Code                                     |
-- =============================================================================================|
PROCEDURE get_po_vendor_site_code(p_po_number         IN   VARCHAR2
						         ,o_vendor_site_code  OUT  VARCHAR2)
IS
lc_error_loc VARCHAR2(100);
lc_error_msg VARCHAR2(300);
BEGIN

	SELECT assa.vendor_site_code_alt
	  INTO o_vendor_site_code
      FROM po_headers_all poh,
           ap_supplier_sites_all assa
     WHERE poh.vendor_site_id = assa.vendor_site_id
       AND poh.segment1 = p_po_number;

EXCEPTION
    WHEN OTHERS
    THEN
        o_vendor_site_code := NULL;
        lc_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('Unable to get the PO Vendor Site Code for the PO Number :'||p_po_number||' - '||substr(sqlerrm,1,250),FALSE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.get_po_vendor_site_code',
                       lc_error_loc,
		               lc_error_msg);
END get_po_vendor_site_code;

-- +============================================================================================+
-- |  Name	 : get_rtv_gl_string                                                                |
-- |  Description: Procedure to get the GL information                                          |
-- =============================================================================================|
PROCEDURE get_rtv_gl_string  (o_gl_company             OUT  VARCHAR2
						     ,o_gl_cost_center         OUT  VARCHAR2
                             ,o_gl_account             OUT  VARCHAR2
						     ,o_gl_location            OUT  VARCHAR2
						     ,o_gl_inter_company       OUT  VARCHAR2
						     ,o_gl_lob                 OUT  VARCHAR2
						     ,o_gl_future              OUT  VARCHAR2
						     )
IS
BEGIN
    SELECT target_value1
          ,target_value2
		  ,target_value3
		  ,target_value4
		  ,target_value5
		  ,target_value6
		  ,target_value7
	  INTO o_gl_company
	      ,o_gl_cost_center
	      ,o_gl_account
	      ,o_gl_location
	      ,o_gl_inter_company
	      ,o_gl_lob
	      ,o_gl_future
      FROM xx_fin_translatevalues
     WHERE translate_id IN (SELECT translate_id
          			          FROM xx_fin_translatedefinition
          			         WHERE translation_name = 'XX_AP_RTV_CHARGE_ACCT'
          			           AND enabled_flag = 'Y')
       AND source_value1 = 'US_OD_RTV_MERCHANDISING';
EXCEPTION
    WHEN OTHERS
    THEN
       	o_gl_company            := NULL;
	    o_gl_cost_center        := NULL;
	    o_gl_account            := NULL;
	    o_gl_location           := NULL;
	    o_gl_inter_company      := NULL;
	    o_gl_lob                := NULL;
	    o_gl_future             := NULL;
		print_debug_msg ('Unable to get the GL Information for the RTV Source',FALSE);
END get_rtv_gl_string;

-- +============================================================================================+
-- |  Name	 : get_consign_gl_string                                                            |
-- |  Description: Procedure to get the GL information for the Consignment Source               |
-- =============================================================================================|
PROCEDURE get_consign_gl_string (p_vendor_num             IN   VARCHAR2
                                ,p_location_num           IN   VARCHAR2
                                ,p_unabsorb_flag          IN   VARCHAR2
								,o_gl_description         OUT  VARCHAR2
								,o_gl_company             OUT  VARCHAR2
								,o_gl_cost_center         OUT  VARCHAR2
								,o_gl_account             OUT  VARCHAR2
						        ,o_gl_location            OUT  VARCHAR2
								,o_gl_inter_company       OUT  VARCHAR2
								,o_gl_lob                 OUT  VARCHAR2
                                ,o_gl_future              OUT  VARCHAR2
								,o_acct_detail            OUT  VARCHAR2
						        )
IS
BEGIN
    IF  p_unabsorb_flag <> 'Y'
	THEN
	    BEGIN
            SELECT target_value1,
			       SUBSTR(target_value6,1,4),
                   SUBSTR(target_value6,6,5),
                   SUBSTR(target_value6,12,8),
                   SUBSTR(target_value6,21,6),
				   SUBSTR(target_value6,28,4),
				   SUBSTR(target_value6,33,2),
				   SUBSTR(target_value6,36,6),
                   target_value8
              INTO o_gl_description,
                   o_gl_company,
                   o_gl_cost_center,
                   o_gl_account,
                   o_gl_location,
                   o_gl_inter_company,
				   o_gl_lob,
				   o_gl_future,
				   o_acct_detail
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
          			                  FROM xx_fin_translatedefinition
          			                 WHERE translation_name = 'AP_CONSIGN_LIABILITY'
          			                   AND enabled_flag = 'Y')
               AND source_value2 = p_vendor_num
			   AND source_value1 = 'USA';

        EXCEPTION
            WHEN OTHERS
            THEN
               -- print_debug_msg ('Unable to get the GL information for the vendor site :'||p_vendor_num ,FALSE);
                    SELECT target_value1,
			               SUBSTR(target_value6,1,4),
                           SUBSTR(target_value6,6,5),
                           SUBSTR(target_value6,12,8),
                           SUBSTR(target_value6,21,6),
			        	   SUBSTR(target_value6,28,4),
			        	   SUBSTR(target_value6,33,2),
			        	   SUBSTR(target_value6,36,6),
                           target_value8
                      INTO o_gl_description,
                           o_gl_company,
                           o_gl_cost_center,
                           o_gl_account,
                           o_gl_location,
                           o_gl_inter_company,
			        	   o_gl_lob,
			        	   o_gl_future,
			        	   o_acct_detail
                      FROM xx_fin_translatevalues
                     WHERE translate_id IN (SELECT translate_id
          	        		                  FROM xx_fin_translatedefinition
          	        		                 WHERE translation_name = 'AP_CONSIGN_LIABILITY'
          	        		                   AND enabled_flag = 'Y')
                       AND source_value2 = 'DEFAULT'
					   AND source_value1 = 'USA';
        END;
	ELSE
	    BEGIN
            SELECT target_value1,
                   target_value6,
				   NULL
			  INTO o_gl_description,
                   o_gl_account,
				   o_acct_detail
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
          			                  FROM xx_fin_translatedefinition
          			                 WHERE translation_name = 'AP_CONSIGN_UNABSORBED'
          			                   AND enabled_flag = 'Y')
               AND source_value2 = 'DEFAULT'
			   AND source_value1 = 'USA';

            -- To get all the other segments
			SELECT SUBSTR(gcck.concatenated_segments,1,4),
                   SUBSTR(gcck.concatenated_segments,6,5),
                   SUBSTR(gcck.concatenated_segments,21,6),
		           SUBSTR(gcck.concatenated_segments,28,4),
		           SUBSTR(gcck.concatenated_segments,33,2),
		           SUBSTR(gcck.concatenated_segments,36,6)
			  INTO o_gl_company,
			       o_gl_cost_center,
			       o_gl_location,
			       o_gl_inter_company,
			       o_gl_lob,
			       o_gl_future
	          FROM hr_locations hl,
                   mtl_parameters mp,
                   gl_code_combinations_kfv gcck
             WHERE ltrim(hl.attribute1,'0') = LTRIM(p_location_num,'0')
               AND gcck.code_combination_id = mp.material_account
               AND mp.organization_id = hl.inventory_organization_id;

        EXCEPTION
            WHEN OTHERS
            THEN
               print_debug_msg ('Unable to get the GL information for the Unabsorbed line for the Vendor Num :'||p_vendor_num ,FALSE);
               o_gl_description    := NULL;
			   o_gl_account        := NULL;
			   o_acct_detail       := NULL;
			   o_gl_company        := NULL;
			   o_gl_cost_center    := NULL;
			   o_gl_location       := NULL;
			   o_gl_inter_company  := NULL;
			   o_gl_lob            := NULL;
			   o_gl_future		   := NULL;

        END;
	END IF;
EXCEPTION
WHEN OTHERS
THEN
    print_debug_msg ('Unable to get the GL Information for the vendor  :'||p_vendor_num||' - '||substr(sqlerrm,1,250),FALSE);
END get_consign_gl_string;

-- +============================================================================================+
-- |  Name	 : parse_tdm_dci_file                                                               |
-- |  Description: Procedure to parse string and load them into the file                        |
-- =============================================================================================|
PROCEDURE parse_tdm_dci_file(p_string      IN  VARCHAR2
							,p_table       OUT varchar2_table
							,p_error_msg   OUT VARCHAR2
							,p_errcode     OUT VARCHAR2)
IS

   l_string   VARCHAR2(32767) := p_string;
   l_table    varchar2_table;

BEGIN
    l_table(1) := TRIM(SUBSTR(l_string,1,4));      -- AP Company
	l_table(2) := TRIM(SUBSTR(l_string,5,9));      -- AP Vendor
	l_table(3) := TRIM(SUBSTR(l_string,14,20));    -- Invoice Number
	l_table(4) := TRIM(SUBSTR(l_string,34,6));     -- Invoice date
    l_table(6) := TRIM(SUBSTR(l_string,41,3));     -- Line Number
    l_table(5) := TRIM(SUBSTR(l_string,40,1));     -- Record Type

    IF l_table(5) ='H'
	THEN
	    l_table(7) := TRIM(SUBSTR(l_string,44,11));    -- Gross Amount
	    l_table(8) := TRIM(SUBSTR(l_string,55,1));     -- Gross Amount Sign
	    l_table(9) := TRIM(SUBSTR(l_string,56,2));     -- Reason Code
	    l_table(10):= TRIM(SUBSTR(l_string,58,2));     -- Department
 -- Version 4.5 Start
      IF TRIM(SUBSTR(l_string,155,1)) = 'Y' THEN -- voucher_type/Quick Match
         l_table(11):= CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,60,9)),'0')) < 7 THEN LPAD(LTRIM(TRIM(SUBSTR(l_string,60,9)),'0'),7,'0')
                           ELSE LTRIM(TRIM(SUBSTR(l_string,60,9)),'0')
                       END;      -- Default PO
      ELSE
         l_table(11):= TRIM(SUBSTR(l_string,60,9));
      END IF;
	    l_table(12):= TRIM(SUBSTR(l_string,69,1));     -- Pay Code
	    l_table(13):= TRIM(SUBSTR(l_string,70,1));     -- Payment Priority
	    l_table(14):= TRIM(SUBSTR(l_string,71,6));     -- Due Date
	    l_table(15):= TRIM(SUBSTR(l_string,77,32));    -- Check Description
	    l_table(16):= TRIM(SUBSTR(l_string,109,8));    -- User ID Setup
	    l_table(17):= TRIM(SUBSTR(l_string,117,5));    -- Location ID
	    l_table(18):= TRIM(SUBSTR(l_string,122,7));    -- Freight Amount
	    l_table(19):= TRIM(SUBSTR(l_string,129,1));    -- Freight Amount Sign
	    l_table(20):= TRIM(SUBSTR(l_string,130,7));    -- Tax Amount
	    l_table(21):= TRIM(SUBSTR(l_string,137,1));    -- Tax Amount Sign
	    l_table(22):= TRIM(SUBSTR(l_string,138,7));    -- GST Amount
	    l_table(23):= TRIM(SUBSTR(l_string,145,1));    -- GST Amount Sign
	    l_table(24):= TRIM(SUBSTR(l_string,146,9));    -- DCN
	    l_table(25):= TRIM(SUBSTR(l_string,155,1));    -- Quick Match
	    l_table(26):= TRIM(SUBSTR(l_string,156,3));    -- Data Source
	    l_table(27):= TRIM(SUBSTR(l_string,159,1));    -- GST Calc Flag
	    l_table(28):= REPLACE(SUBSTR(l_string,160,10), ' ','');   -- Terms
	    l_table(29):= TRIM(SUBSTR(l_string,170,31));   -- Filler Header

-- Version 4.5 End

		p_table 	:= l_table;

	ELSIF l_table(5) ='D'
	THEN
	    l_table(7) := TRIM(SUBSTR(l_string,44,11));    -- MDSE Amount
		l_table(8) := TRIM(SUBSTR(l_string,55,1));     -- MDSE Amount Sign
		l_table(9) := TRIM(SUBSTR(l_string,56,5));     -- GL Company
		l_table(10):= TRIM(SUBSTR(l_string,61,5));     -- GL Cost Center
		l_table(11):= TRIM(SUBSTR(l_string,66,8));     -- GL Account
		l_table(12):= TRIM(SUBSTR(l_string,74,6));     -- GL Location
		l_table(13):= TRIM(SUBSTR(l_string,80,5));     -- GL Inter Company
		l_table(14):= TRIM(SUBSTR(l_string,85,2));     -- GL Lob
		l_table(15):= TRIM(SUBSTR(l_string,87,20));    -- GL Description
		l_table(16):= TRIM(SUBSTR(l_string,107,3));    -- Detail Data Source
		l_table(17):= TRIM(SUBSTR(l_string,110,5));    -- PAN Number
		l_table(18):= TRIM(SUBSTR(l_string,115,86));   -- Filler Detail
		l_table(19):= 'ITEM';                          -- Line Type
		l_table(20):= TRIM(SUBSTR(l_string,87,20));    -- SKU Description

		p_table 	:= l_table;
	END IF;

EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.parse_tdm_file - record:'||substr(sqlerrm,1,150);
END parse_tdm_dci_file;

-- +============================================================================================+
-- |  Name	 : parse_csi_file                                                                   |
-- |  Description: Procedure to parse string and load them into the file                        |
-- =============================================================================================|
PROCEDURE parse_csi_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2)
IS
    l_string   VARCHAR2(32767) := p_string;
    l_table    varchar2_table;

BEGIN
    l_table(1) := TRIM(SUBSTR(l_string,1,5));      -- Location Number
	l_table(2) := TRIM(SUBSTR(l_string,6,9));      -- Vendor Number
	l_table(3) := TRIM(SUBSTR(l_string,15,8));     -- Sales Date (YYYYMMDD)
	l_table(4) := TRIM(SUBSTR(l_string,23,7));     -- SKU Number
	l_table(5) := TRIM(SUBSTR(l_string,30,1));     -- Cost Sign
    l_table(6) := TRIM(SUBSTR(l_string,31,13));    -- Cost
	l_table(7) := TRIM(SUBSTR(l_string,44,1));     -- Quantity Sign
	l_table(8) := TRIM(SUBSTR(l_string,45,9));     -- Quantity
	l_table(9) := TRIM(SUBSTR(l_string,54,30));    -- Description
	l_table(10):= TRIM(SUBSTR(l_string,84,1));     -- PO cost sign
	l_table(11):= TRIM(SUBSTR(l_string,85,13));    -- PO cost
	l_table(12):= TRIM(SUBSTR(l_string,98,1));     -- Invoice Indicator
	l_table(13):= 'Y';    -- If Regular line, then 'Y' else 'N' (Unabsorbed line)
	l_table(22):= TRIM(SUBSTR(l_string,99,20));    -- Track ID
	l_table(23):= TRIM(SUBSTR(l_string,119,24));    -- Account Number

	p_table 	:= l_table;

EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.parse_csi_file - record:'||substr(sqlerrm,1,150);
END parse_csi_file;

-- +============================================================================================+
-- |  Name	 : parse_drp_file                                                                   |
-- |  Description: Procedure to parse string and load them into the file                        |
-- =============================================================================================|
PROCEDURE parse_drp_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2)
IS

    l_string   VARCHAR2(32767) := p_string;
    l_table    varchar2_table;

BEGIN
    l_table(1) := TRIM(SUBSTR(l_string,1,9));      -- RTN Order Number
	l_table(2) := TRIM(SUBSTR(l_string,11,3));     -- RTN Order Sub
	l_table(3) := TRIM(SUBSTR(l_string,15,9));     -- Orig Order Number
	l_table(4) := TRIM(SUBSTR(l_string,25,3));     -- Orig Number Sub
	l_table(5) := TRIM(SUBSTR(l_string,29,4));     -- Location Number
    l_table(6) := TRIM(SUBSTR(l_string,34,10));    -- Sales Date
	l_table(7) := TRIM(SUBSTR(l_string,45,7));     -- Vendor ID
-- Version 4.5 Start
	l_table(8) := CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,53,8)),'0')) < 7 THEN LPAD(LTRIM(TRIM(SUBSTR(l_string,53,8)),'0'),7,'0')
		               ELSE CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,53,8)),'0')) is not null THEN LTRIM(TRIM(SUBSTR(l_string,53,8)),'0')
                                 ELSE SUBSTR(l_string,53,8)
                            END
                  END;     -- Default PO
	l_table(9) := TRIM(SUBSTR(l_string,62,7));     -- SKU
	l_table(10):= TRIM(SUBSTR(l_string,70,5));     -- Quantity
	l_table(11):= TRIM(SUBSTR(l_string,76,1));     -- Cost sign
	l_table(12):= TRIM(SUBSTR(l_string,77,9));     -- Cost
	l_table(13):= TRIM(SUBSTR(l_string,87,2));     -- RTN Reason CD
	l_table(14):= TRIM(SUBSTR(l_string,90,18));    -- RTN Authz CD
	l_table(15):= TRIM(SUBSTR(l_string,109,2));    -- Brand CD
-- Version 4.5 End

	p_table 	:= l_table;

EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.parse_drp_file - record:'||substr(sqlerrm,1,150);
END parse_drp_file;

-- +============================================================================================+
-- |  Name	 : parse_edi_file                                                                   |
-- |  Description: Procedure to parse string and load them into the file                        |
-- =============================================================================================|
PROCEDURE parse_edi_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_line_table  OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2)
IS

    l_string        VARCHAR2(32767) := p_string;
    l_table         varchar2_table;
    l_line_table    varchar2_table;

BEGIN
    l_table.DELETE();
	l_line_table.DELETE;

    l_table(1) := TRIM(SUBSTR(l_string,1,1));      -- Record Type
    print_debug_msg ('Record Type in Parse function :'||l_table(1) ,FALSE);

    IF l_table(1) = '1'	THEN
       print_debug_msg ('Record Type Test 1:'||l_table(1) ,FALSE);
	     l_table(2) := TRIM(SUBSTR(l_string,2,8));            --  AP Vendor
-- Version 4.5 Start
       l_table(3) := CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')) < 7 THEN LPAD(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0'),7,'0')
		                      ELSE LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')
                     END;     -- Default PO
	     l_table(4) := TRIM(SUBSTR(l_string,19,4));           --  Location
       l_table(5) := TRIM(SUBSTR(l_string,23,22));          --  Invoice Number
       l_table(6) := TRIM(SUBSTR(l_string,45,2));           --  Invoice_YY
       l_table(7) := TRIM(SUBSTR(l_string,47,2));           --  Invoice_MM
       l_table(8) := TRIM(SUBSTR(l_string,49,2));           --  Invoice_DD
       l_table(9) := TRIM(SUBSTR(l_string,51,2));           --  Ship_YY
       l_table(10):= TRIM(SUBSTR(l_string,53,2));           --  Ship_MM
       l_table(11):= TRIM(SUBSTR(l_string,55,2));           --  Ship_DD
       v_inv_num := TRIM(SUBSTR(l_string,23,22)); 	----- NAIT-48272 (Defect#45304)
       v_ven_num := TRIM(SUBSTR(l_string,2,8));    ----- NAIT-48272 (Defect#45304)
       v_po_num  := TRIM(SUBSTR(l_string,10,8));   ----- NAIT-48272 (Defect#45304)
-- Version 4.5 End

		   p_table 	:= l_table;
	  ELSIF l_table(1) = '4' THEN
          print_debug_msg ('Record Type Test 2:'||l_table(1) ,FALSE);
          l_line_table(1) := TRIM(SUBSTR(l_string,1,1));      --  Record Type
	        l_line_table(2) := TRIM(SUBSTR(l_string,2,8));      --  AP Vendor
-- Version 4.5 Start
          l_line_table(3) := CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')) < 7 THEN LPAD(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0'),7,'0')
		                              ELSE LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')
                             END;     -- Default PO
          l_line_table(4) := TRIM(SUBSTR(l_string,19,4));     --  Location
          l_line_table(5) := TRIM(SUBSTR(l_string,23,10));    --  Quantity
          l_line_table(6) := TRIM(SUBSTR(l_string,33,1));     --  Quantity sign
          l_line_table(7) := TRIM(SUBSTR(l_string,34,2));     --  UOM
          l_line_table(8) := TRIM(SUBSTR(l_string,36,15));    --  UPC
          l_line_table(9) := TRIM(SUBSTR(l_string,51,7));     --  SKU
          l_line_table(10):= TRIM(SUBSTR(l_string,58,7));     --  Unit Price
          l_line_table(11):= TRIM(SUBSTR(l_string,65,1));     --  Unit Price Sign
-- Version 4.5 End
          p_table 	    := l_table;
          p_line_table 	:= l_line_table;
    ELSIF l_table(1) = '5' THEN
          print_debug_msg ('Record Type Test 3:'||l_table(1) ,FALSE);
          l_table(1) := TRIM(SUBSTR(l_string,1,1));    -- Record Type
-- Version 4.5 Start
	        l_table(12):= TRIM(SUBSTR(l_string,23,10));  -- Charge Amount
          l_table(13):= TRIM(SUBSTR(l_string,33,1));   -- Charge Sign
          l_table(14):= TRIM(SUBSTR(l_string,34,8));   -- Charge Percentage
          l_table(15):= TRIM(SUBSTR(l_string,42,4));   -- Charge Code
-- Version 4.5 End
          p_table 	:= l_table;
    ELSIF l_table(1) = '6' THEN
          print_debug_msg ('Record Type Test 4:'||l_table(1) ,FALSE);
	        l_line_table(1):=  TRIM(SUBSTR(l_string,1,1));      --  Record Type
          l_line_table(2):=  TRIM(SUBSTR(l_string,2,8));      --  AP Vendor
-- Version 4.5
          l_line_table(3) := CASE WHEN length(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')) < 7 THEN LPAD(LTRIM(TRIM(SUBSTR(l_string,10,8)),'0'),7,'0')
		                              ELSE LTRIM(TRIM(SUBSTR(l_string,10,8)),'0')
                             END;     -- Default PO
          l_line_table(4):=  TRIM(SUBSTR(l_string,19,4));     --  Location
          l_line_table(10):= TRIM(SUBSTR(l_string,24,9));     --  Freight Amount
          l_line_table(11):= TRIM(SUBSTR(l_string,33,1));     --  Freight Amount Sign
          l_line_table(15):= TRIM(SUBSTR(l_string,41,4));     --  SAC Code
-- Version 4.5 End
          p_table 	    := l_table;
          p_line_table 	:= l_line_table;
   ELSIF l_table(1) IN ('0','2') THEN
         p_table 	 := l_table;
         p_errcode   := 0;
         p_error_msg := 'Skipping the Record Types 0 and 2 lines';
	-- changes as per version 3.9 starts here --
   ELSE
          p_table 	 := l_table;
          gn_bad_rec_flag := 1;
          p_error_msg := 'Data Format Issue. Skipping the bad record. Line with String - ' || TRIM(l_string);
 	END IF;
	-- changes as per version 3.9 ends here --

EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.parse_edi_file - record:'||SUBSTR(SQLERRM,1,150);
END parse_edi_file;

-- +============================================================================================+
-- |  Name	 : parse_rtv_file                                                                	|
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse_rtv_file(p_delimstring IN  VARCHAR2
                        ,p_table       OUT varchar2_table
                        ,p_nfields     OUT INTEGER
                        ,p_delim       IN  VARCHAR2 DEFAULT '|'
                        ,p_error_msg   OUT VARCHAR2
                        ,p_retcode     OUT VARCHAR2) IS

    l_string   VARCHAR2(32767) := p_delimstring;
    l_nfields  PLS_INTEGER := 1;
    l_table    varchar2_table;
    l_delimpos PLS_INTEGER := INSTR(p_delimstring, p_delim);
    l_delimlen PLS_INTEGER := LENGTH(p_delim);
BEGIN
    WHILE l_delimpos > 0
    LOOP
        l_table(l_nfields) := TRIM(SUBSTR(l_string,1,l_delimpos-1));
        l_string 	 := SUBSTR(l_string,l_delimpos+l_delimlen);
        l_nfields  := l_nfields+1;
        l_delimpos := INSTR(l_string, p_delim);
    END LOOP;
    l_table(l_nfields) := TRIM(l_string);
    p_table 	:= l_table;
    p_nfields	:= l_nfields;
EXCEPTION
WHEN others THEN
    p_retcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.parse_rtv_file - record:'||substr(sqlerrm,1,150);
END parse_rtv_file;

-- +============================================================================================+
-- |  Name	 : insert_dropship_nonded                                                           |
-- |  Description: Procedure to insert the Dropship Non-Deductible information                  |
-- =============================================================================================|
PROCEDURE insert_dropship_nonded(p_table       IN  varchar2_table
                                ,p_error_msg   OUT VARCHAR2
                                ,p_errcode     OUT VARCHAR2)
IS
    l_table    	        varchar2_table;
BEGIN
    l_table.DELETE;
	l_table := p_table;

	INSERT
	  INTO xx_ap_dropship_non_deductions
	         ( record_id
			  ,return_order_num
			  ,return_order_sub
			  ,orig_order_num
			  ,orig_order_sub
			  ,location_num
			  ,sales_date
			  ,vendor_num
			  ,po_number
			  ,sku
			  ,quantity
			  ,cost
			  ,cost_sign
			  ,retrun_reason_code
			  ,return_auth_code
			  ,brand_code
			  ,record_status
			  ,error_description
			  ,request_id
			  ,creation_date
			  ,created_by
			  ,last_update_date
			  ,last_updated_by
			  ,last_update_login
              )
       VALUES (xx_ap_ds_non_deductions_s.nextval -- record_id
	          ,l_table(1)    -- return_order_num
			  ,l_table(2)    -- return_order_sub
			  ,l_table(3)    -- orig_order_num
			  ,l_table(4)    -- orig_order_sub
			  ,l_table(5)    -- location_num
			  ,TO_DATE(l_table(6),'YYYY-MM-DD')    -- sales_date
			  ,l_table(7)    -- vendor_num
			  ,l_table(8)    -- po_number
			  ,l_table(9)    -- sku
			  ,TO_NUMBER(l_table(10))   -- quantity
			  ,TO_NUMBER(l_table(12))   -- cost
			  ,l_table(11)   -- cost_sign
			  ,l_table(13)   -- retrun_reason_code
			  ,l_table(14)   -- return_auth_code
			  ,l_table(15)   -- brand_code
			  ,'N'		     -- record_status
	          ,''			 -- error_description
	          ,gn_request_id -- request_id
			  ,SYSDATE       -- creation_date
	          ,gn_user_id    -- created_by
	          ,SYSDATE       -- last_update_date
	          ,gn_user_id    -- last_updated_by
	          ,gn_login_id   -- last_update_login
	         );
	   COMMIT;
EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.insert_dropship_nonded '||SUBSTR(SQLERRM,1,150);
    fnd_file.put_line(fnd_file.log,'Error Message :'||p_error_msg);
END insert_dropship_nonded;

-- +============================================================================================+
-- |  Name	 : insert_rtv_header                                                                |
-- |  Description: Procedure to insert data into RTV header staging table                       |
-- =============================================================================================|
PROCEDURE insert_rtv_header(p_table       IN  varchar2_table
                           ,p_source      IN  VARCHAR2
                           ,p_error_msg   OUT VARCHAR2
                           ,p_errcode     OUT VARCHAR2)
IS
    l_table                       varchar2_table ;
	ln_terms_id                   NUMBER;
	lc_pay_group                  VARCHAR2(30);
	lc_payment_method_lookup_code VARCHAR2(30);
	lc_supp_attr_category         VARCHAR2(30);
	lc_vendor_sites_kff_id        NUMBER;
	lc_frequency_code             VARCHAR2(30);

BEGIN
    l_table.DELETE;
	l_table := p_table;
	lc_frequency_code := NULL;

	-- To derive the Supplier Information
    get_supplier_info (p_vendor                  => l_table(52)
					  ,o_terms_id                => ln_terms_id
					  ,o_pay_group_lookup_code   => lc_pay_group
                      ,o_pymt_method_lookup_code => lc_payment_method_lookup_code
                      ,o_supp_attr_category      => lc_supp_attr_category
					  ,o_vendor_sites_kff_id     => lc_vendor_sites_kff_id);

	IF l_table(31) <> '73'
	THEN
	    lc_frequency_code := 'DAILY';
	ELSE
        get_vendor_sites_kff_id(p_vendor_sites_kff_id  => lc_vendor_sites_kff_id
						       ,o_frequency_code       => lc_frequency_code);
	END IF;

	INSERT
     INTO xx_ap_rtv_hdr_attr
   	   ( header_id
	    ,record_type
	    ,rtv_number
        ,voucher_num
	    ,location
	    ,freight_bill_num1
	    ,freight_bill_num2
	    ,freight_bill_num3
	    ,freight_bill_num4
	    ,freight_bill_num5
	    ,freight_bill_num6
	    ,freight_bill_num7
	    ,freight_bill_num8
	    ,freight_bill_num9
	    ,freight_bill_num10
	    ,carrier_name
	    ,company_address
	    ,vendor_address
	    ,return_code
	    ,return_description
	    ,ship_name
	    ,ship_address1
	    ,ship_address2
	    ,ship_address3
	    ,ship_address4
	    ,ship_address5
	    ,location_address1
        ,location_address2
        ,location_address3
        ,location_address4
        ,location_address5
        ,location_address6
        ,group_name
	    ,company_code
	    ,vendor_num
	    ,gross_amt
	    ,quantity
		,terms_id
		,pay_group_lookup_code
		,payment_method_lookup_code
		,supplier_attr_category
		,vendor_sites_kff_id
        ,frequency_code
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login
      ,reason_code)
    VALUES
       ( DECODE(lc_frequency_code,'WEEKLY',NULL,'MONTHLY',NULL,'QUARTERLY',NULL,'DAILY',ap_invoices_interface_s.NEXTVAL,NULL ) -- header_id
	    ,l_table(1)    -- record_type
	    ,l_table(2)    -- rtv_number
	    ,NULL --DECODE(lc_frequency_code,'WEEKLY',NULL,'MONTHLY',NULL,'QUARTERLY',NULL,'DAILY',xx_ap_trade_voucher_num_s.NEXTVAL,NULL ) -- voucher_num
	    ,l_table(4)    -- location
	    ,l_table(8)    -- freight_bill_num1
	    ,l_table(9)    -- freight_bill_num2
	    ,l_table(10)   -- freight_bill_num3
	    ,l_table(11)   -- freight_bill_num4
	    ,l_table(12)   -- freight_bill_num5
	    ,l_table(13)   -- freight_bill_num6
	    ,l_table(14)   -- freight_bill_num7
	    ,l_table(15)   -- freight_bill_num8
	    ,l_table(16)   -- freight_bill_num9
	    ,l_table(17)   -- freight_bill_num10
	    ,l_table(18)   -- Carrier Name
	    ,l_table(19)||' '||l_table(20)||' '||l_table(21)||' '||l_table(22)||' '||l_table(23)||' '||l_table(24) -- Company Address
	    ,l_table(25)||' '||l_table(26)||' '||l_table(27)||' '||l_table(28)||' '||l_table(29)||' '||l_table(30) -- Vendor Address
	    ,l_table(31)   -- return_code
	    ,l_table(32)   -- return_description
	    ,l_table(33)   -- ship_name
	    ,l_table(34)   -- ship_address1
	    ,l_table(35)   -- ship_address2
	    ,l_table(36)   -- ship_address3
	    ,l_table(37)   -- ship_address4
	    ,l_table(38)   -- ship_address5
	    ,l_table(39)   -- location_address1
	    ,l_table(40)   -- location_address2
	    ,l_table(41)   -- location_address3
	    ,l_table(42)   -- location_address4
	    ,l_table(43)   -- location_address5
	    ,l_table(44)   -- location_address6
	    ,l_table(45)   -- group_name
	    ,l_table(46)   -- Company Code
	    ,l_table(52)   -- vendor_num
	    ,NULL          -- gross_amt
	    ,NULL          -- quantity
		,NULL          -- terms_id
		,lc_pay_group  -- pay_group_lookup_code
		,lc_payment_method_lookup_code -- payment_method_lookup_code
		,lc_supp_attr_category    -- supplier_attr_category
		,lc_vendor_sites_kff_id   -- vendor_sites_kff_id
		,DECODE(lc_frequency_code,'WEEKLY','WY','MONTHLY','MY','QUARTERLY','QY','DAILY','DY','WY')  -- frequency_code
	    ,'N'		     -- record_status
	    ,''			   -- error_description
	    ,gn_request_id -- request_id
	    ,gn_user_id    -- created_by
	    ,SYSDATE       -- creation_date
	    ,gn_user_id    -- last_updated_by
	    ,SYSDATE       -- last_update_date
	    ,gn_login_id   -- last_update_login
      ,l_table(6)    -- reason_code
	    );
EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.insert_rtv_header '||SUBSTR(SQLERRM,1,150);
    fnd_file.put_line(fnd_file.log,'Error Message :'||p_error_msg);
END insert_rtv_header;

-- +============================================================================================+
-- |  Name	 : insert_rtv_line                                                               	|
-- |  Description: Procedure to insert line data into RTV line staging table                    |
-- =============================================================================================|
PROCEDURE insert_rtv_line(p_table       IN  varchar2_table
                         ,p_source      IN  VARCHAR2
                         ,p_error_msg   OUT VARCHAR2
                         ,p_errcode     OUT VARCHAR2)
IS
    l_table    	                  varchar2_table;
    lc_qty                        VARCHAR2(20);
    lc_cost                       VARCHAR2(20);
    lc_line_amt                   VARCHAR2(20);
	ln_terms_id                   NUMBER;
	lc_pay_group                  VARCHAR2(30);
	lc_payment_method_lookup_code VARCHAR2(30);
	lc_supp_attr_category         VARCHAR2(30);
	lc_vendor_sites_kff_id        NUMBER;
	lc_frequency_code             VARCHAR2(30);
	lc_location                   VARCHAR2(30);

BEGIN
    l_table.DELETE;
    l_table := p_table;
	lc_frequency_code := NULL;
	lc_location := NULL;

	BEGIN
	   SELECT frequency_code,location
	     INTO lc_frequency_code, lc_location
	     FROM xx_ap_rtv_hdr_attr
	    WHERE rtv_number = l_table(2)
	      AND vendor_num = l_table(19)
		  AND record_status = 'N'
		  ;
	EXCEPTION
	WHEN TOO_MANY_ROWS
	THEN
	    SELECT frequency_code,location
	     INTO lc_frequency_code, lc_location
	     FROM xx_ap_rtv_hdr_attr
	    WHERE rtv_number = l_table(2)
	      AND vendor_num = l_table(19)
		  AND record_status = 'N'
		  AND ROWNUM = 1
		  ;
	WHEN OTHERS
	THEN
	    lc_frequency_code:= 'WY';
		lc_location := NULL;
	END;

    INSERT
      INTO xx_ap_rtv_lines_attr
	   ( line_id
	    ,header_id
	    ,record_type
	    ,rtv_number
	    ,worksheet_num
	    ,rga_number
	    ,sku
	    ,vendor_product_code
	    ,item_description
	    ,serial_num
	    ,qty
	    ,cost
	    ,line_amount
	    ,group_name
	    ,company
	    ,vendor_num
		,location
		,rtv_date
        ,frequency_code
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
        ,last_updated_by
	    ,last_update_date
	    ,last_update_login
		,adjusted_qty
		,adjusted_cost
		,adjusted_line_amount
        )
    VALUES
      ( ap_invoice_lines_interface_s.NEXTVAL -- line_id
	   ,DECODE(lc_frequency_code,'WY',NULL,'MY',NULL,'QY',NULL,'DY',ap_invoices_interface_s.CURRVAL)  -- header_id
       ,l_table(1)     -- record_type
	   ,l_table(2)     -- rtv_number
	   ,l_table(3)     -- worksheet_num
	   ,l_table(4)     -- rga_number
	   ,l_table(5)     -- sku
	   ,l_table(6)     -- vendor_product_code
	   ,l_table(7)     -- item_description
	   ,l_table(14)    -- serial_num
	   ,TO_NUMBER(l_table(8))    -- qty
	   ,TO_NUMBER(l_table(9))    -- cost
	   ,TO_NUMBER(l_table(10))   -- line_amount
	   ,l_table(15)    -- group_name
	   ,l_table(16)    -- company
	   ,l_table(19)    -- vendor_num
	   ,lc_location    -- Location
	   ,TO_DATE(l_table(17),'MMDDYY') -- rtv_date
	   ,lc_frequency_code -- frequency_code
	   ,'N'		       -- record_status
	   ,''			   -- error_description
	   ,gn_request_id  -- request_id
	   ,gn_user_id     -- created_by
	   ,sysdate        -- creation_date
	   ,gn_user_id     -- last_updated_by
	   ,sysdate        -- last_update_date
	   ,gn_login_id    -- last_update_login
	   ,TO_NUMBER(l_table(11)) -- adjusted_qty
	   ,TO_NUMBER(l_table(12)) -- adjusted_cost
	   ,TO_NUMBER(l_table(13)) -- adjusted_line_amount
      );
EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.insert_rtv_line '||SUBSTR(SQLERRM,1,150);
    fnd_file.put_line(fnd_file.log,'Error Message :'||p_error_msg);
END insert_rtv_line;

-- +============================================================================================+
-- |  Name	 : insert_header                                                                	|
-- |  Description: Procedure to insert data into header staging table                           |
-- =============================================================================================|
PROCEDURE insert_header(p_table       IN  varchar2_table
                       ,p_source      IN  VARCHAR2
                       ,p_error_msg   OUT VARCHAR2
                       ,p_errcode     OUT VARCHAR2)
IS
    l_table    	                   varchar2_table ;
    lc_pay_group_lookup_code       VARCHAR2(50);
    lc_payment_method_lookup_code  VARCHAR2(50);
    ln_terms_id                    NUMBER;
    lc_gross_amt                   VARCHAR2(30);
	lc_supp_attr_category          VARCHAR2(30);
	lc_vendor_sites_kff_id	       NUMBER;

BEGIN
    l_table.delete;
    lc_pay_group_lookup_code := NULL;
    ln_terms_id := NULL;
    lc_payment_method_lookup_code := NULL;

    l_table := p_table;
    IF p_source IN ('US_OD_TDM','US_OD_DCI_TRADE')
    THEN
       INSERT
         INTO xx_ap_trade_inv_hdr
   	    (invoice_id
	    ,record_type
	    ,ap_company
	    ,ap_vendor_1
	    ,ap_vendor
	    ,voucher
	    ,invoice_number
	    ,source
	    ,voucher_type
	    ,invoice_date
	    ,gross_amt
	    ,gross_amt_sign
	    ,discount_amt
	    ,discount_amt_sign
	    ,default_po
	    ,location_id
	    ,terms_date
	    ,terms_id
	    ,terms_name
	    ,discount_date
	    ,check_description
	    ,dcn_number
	    ,pay_group
	    ,payment_method_lookup_code
	    ,ap_liab_acct
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login)
       VALUES
        (ap_invoices_interface_s.nextval -- invoice_id
        ,l_table(5) -- record_type
	    ,DECODE(l_table(12),'I','00',null) -- ap_company
	    ,'0'        -- ap_vendor_1
	    ,l_table(2) -- ap_vendor
	    ,NULL --xx_ap_trade_voucher_num_s.nextval -- voucher
	    ,l_table(3) -- invoice_number
	    ,p_source   -- p_source
	    ,DECODE(l_table(25),'Y','1','3') -- voucher_type
	    ,TO_DATE(l_table(4),'MMDDYY')    -- invoice_date
	    ,DECODE(l_table(8), '+',TO_NUMBER(l_table(7))/100,'-', -TO_NUMBER(l_table(7))/100)      -- gross_amt
	    ,l_table(8)  -- gross_amt_sign
	    ,null    -- discount_amt
	    ,null    -- discount_amt_sign
		  ,l_table(11) -- po_number -- Added as per version 4.5
	    ,LTRIM(l_table(17),'0')       -- location_id
	    ,TO_DATE(l_table(4),'MMDDYY') -- terms_date
	    ,NULL           -- ln_terms_id
	    ,REPLACE(l_table(28),' ','') -- terms_name
	    ,null           -- discount_date
	    ,l_table(15)    -- check_description
	    ,l_table(24)    -- dcn_number
	    ,NULL           --  pay_group
	    ,NULL           -- lc_payment_method_lookup_code
        ,NULL           -- ap_liab_acct
	    ,'N'		    -- record_status
	    ,''				-- error_description
	    ,gn_request_id  -- request_id
	    ,gn_user_id
	    ,sysdate
	    ,gn_user_id
	    ,sysdate
	    ,gn_login_id);

    ELSIF p_source IN ('US_OD_CONSIGNMENT_SALES')
    THEN
       INSERT
         INTO xx_ap_trade_inv_hdr
   	    (invoice_id
	    ,record_type
	    ,ap_company
	    ,ap_vendor_1
	    ,ap_vendor
	    ,voucher
	    ,invoice_number
	    ,source
	    ,voucher_type
	    ,invoice_date
	    ,gross_amt
	    ,gross_amt_sign
	    ,discount_amt
	    ,discount_amt_sign
	    ,default_po
	    ,location_id
	    ,terms_date
	    ,terms_id
	    ,terms_name
	    ,discount_date
	    ,check_description
	    ,dcn_number
	    ,pay_group
	    ,payment_method_lookup_code
	    ,ap_liab_acct
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login)
       VALUES
        (TO_NUMBER(l_table(1)) -- invoice_id
        ,'H'                   -- record_type
	    ,'00'                  -- ap_company
	    ,'0'                   -- ap_vendor_1
	    ,l_table(2)            -- ap_vendor
	    ,NULL --TO_NUMBER(l_table(7)) -- voucher
	    ,l_table(3) -- invoice_number
	    ,p_source   -- p_source
	    ,'3' -- voucher_type
	    ,TO_DATE(l_table(4),'MMDDYY') -- invoice_date
	    ,TO_NUMBER(l_table(5)) -- gross_amt
	    ,l_table(6) -- gross_amt_sign
	    ,null -- discount_amt
	    ,null -- discount_amt_sign
	    ,null -- default_po
	    ,null -- location_id
	    ,TO_DATE(l_table(4),'MMDDYY')   -- terms_date
	    ,NULL           -- terms_id
	    ,null           -- Terms Name
	    ,null           -- discount_date
	    ,l_table(8)     -- check_description
	    ,null           -- dcn_number
	    ,NULL           -- lc_pay_group_lookup_code -- pay_group
	    ,NULL           -- lc_payment_method_lookup_code
        ,NULL           -- ap_liab_acct
	    ,'N'		    -- record_status
	    ,''				-- error_description
	    ,gn_request_id  -- request_id
	    ,gn_user_id
	    ,sysdate -- NVL(TO_DATE(l_table(9),'MMDDYY'),sysdate)
	    ,gn_user_id
	    ,sysdate
	    ,gn_login_id);

    ELSIF p_source = 'US_OD_DROPSHIP'
    THEN
		 -- To derive the Supplier Information
         get_supplier_info (p_vendor                  => l_table(2)
						   ,o_terms_id                => ln_terms_id
						   ,o_pay_group_lookup_code   => lc_pay_group_lookup_code
                           ,o_pymt_method_lookup_code => lc_payment_method_lookup_code
                           ,o_supp_attr_category      => lc_supp_attr_category
                           ,o_vendor_sites_kff_id     => lc_vendor_sites_kff_id
							);
       INSERT
        INTO xx_ap_trade_inv_hdr
   	    (invoice_id
	    ,record_type
	    ,ap_company
	    ,ap_vendor_1
	    ,ap_vendor
	    ,voucher
	    ,invoice_number
	    ,source
	    ,voucher_type
	    ,invoice_date
	    ,gross_amt
	    ,gross_amt_sign
	    ,discount_amt
	    ,discount_amt_sign
	    ,default_po
	    ,location_id
	    ,terms_date
	    ,terms_id
	    ,terms_name
	    ,discount_date
	    ,check_description
	    ,dcn_number
	    ,pay_group
	    ,payment_method_lookup_code
	    ,ap_liab_acct
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login)
    VALUES
        (TO_NUMBER(l_table(1)) --invoice_id
        ,'H' -- record_type
	    ,'00' --ap_company
	    ,'0' -- ap_vendor_1
	    ,l_table(2) -- ap_vendor
	    ,NULL  -- voucher
	    ,l_table(3) -- invoice_number
	    ,p_source -- p_source
	    ,'3' -- voucher_type
	    ,TO_DATE(l_table(4),'MMDDYY') -- invoice_date
	    ,TO_NUMBER(l_table(5))
	    ,l_table(6) -- gross_amt_sign
	    ,null -- discount_amt
	    ,null -- discount_amt_sign
	    ,l_table(10) -- default_po
	    ,l_table(9) -- location_id
	    ,TO_DATE(l_table(4),'MMDDYY')  -- terms_date
	    ,10000  -- terms_id
	    ,'00' -- Terms Name
	    ,null  -- discount_date
	    ,l_table(8) -- check_description
	    ,null -- dcn_number
	    ,lc_pay_group_lookup_code -- pay_group
	    ,lc_payment_method_lookup_code
        ,NULL  -- ap_liab_acct
	    ,'N'		    --record_status
	    ,''				--error_description
	    ,gn_request_id
	    ,gn_user_id
	    ,NVL(TO_DATE(l_table(11),'MMDDYY'),sysdate)
	    ,gn_user_id
	    ,sysdate
	    ,gn_login_id);

    ELSIF p_source = 'US_OD_TRADE_EDI'
    THEN
       INSERT
        INTO xx_ap_trade_inv_hdr
   	    (invoice_id
	    ,record_type
	    ,ap_company
	    ,ap_vendor_1
	    ,ap_vendor
	    ,voucher
	    ,invoice_number
	    ,source
	    ,voucher_type
	    ,invoice_date
	    ,gross_amt
	    ,gross_amt_sign
	    ,discount_amt
	    ,discount_amt_sign
	    ,default_po
	    ,location_id
	    ,terms_date
	    ,terms_id
	    ,terms_name
	    ,discount_date
	    ,check_description
	    ,dcn_number
	    ,pay_group
	    ,payment_method_lookup_code
	    ,ap_liab_acct
	    ,record_status
	    ,error_description
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login)
       VALUES
        (TO_NUMBER(l_table(16)) --invoice_id
        ,'H' -- record_type
	    ,NULL --ap_company
	    ,'0' -- ap_vendor_1
	    ,l_table(2) -- ap_vendor
	    ,NULL -- TO_NUMBER(l_table(17)) -- voucher number
	    ,LTRIM(l_table(5),'0') -- invoice_number   /* Added LTRIM to removing the preceeding zeros in the invoice number */
	    ,p_source -- p_source
	    ,'1' -- voucher_type
	    ,TO_DATE(l_table(7)||l_table(8)||l_table(6),'MMDDYY') -- invoice_date
	    ,DECODE(l_table(13),'+',TO_NUMBER(l_table(12))/100,'-',-TO_NUMBER(l_table(12))/100) -- TO_NUMBER(lc_gross_amt) -- gross_amt
	    ,l_table(13) -- gross_amt_sign
	    ,null -- discount_amt
	    ,null -- discount_amt_sign
	    ,l_table(3) -- default_po
	    ,LPAD(LTRIM(l_table(4),'0'),4,'0')  -- location_num
	    ,TO_DATE(l_table(7)||l_table(8)||l_table(6),'MMDDYY') -- terms_date
	    ,NULL -- ln_terms_id  -- terms_id
	    ,null -- Terms Name
	    ,null  -- discount_date
	    ,LTRIM(l_table(3),'0')||' '||LPAD(LTRIM(l_table(4),'0'),4,'0') -- check_description
	    ,'0' -- dcn_number
	    ,NULL -- lc_pay_group_lookup_code -- pay_group
	    ,NULL -- lc_payment_method_lookup_code
        ,NULL  -- ap_liab_acct
	    ,'N'		    --record_status
	    ,''				--error_description
	    ,gn_request_id
	    ,gn_user_id
	    ,sysdate
	    ,gn_user_id
	    ,sysdate
	    ,gn_login_id);

    END IF;

EXCEPTION
WHEN others THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.insert_header '||substr(sqlerrm,1,150);
    fnd_file.put_line(fnd_file.log,'Error Message :'||p_error_msg);
END insert_header;

-- +============================================================================================+
-- |  Name	 : insert_line                                                               	|
-- |  Description: Procedure to insert line data into line staging table                        |
-- =============================================================================================|
PROCEDURE insert_line(p_table       IN varchar2_table
                     ,p_source      IN  VARCHAR2
                     ,p_error_msg   OUT VARCHAR2
                     ,p_errcode     OUT VARCHAR2)
IS
    l_table    	        varchar2_table;
    lc_cost_center       VARCHAR2(30);
    lc_frequency_code    VARCHAR2(30);
    lc_description       VARCHAR2(30);
    lc_location          VARCHAR2(30);
    lc_lob               VARCHAR2(30);
    lc_account           VARCHAR2(30);
    lc_drop_ship_acct    VARCHAR2(30);
    lc_company           VARCHAR2(30);
    lc_location_type     VARCHAR2(30);
    lc_po_type           VARCHAR2(30);
    lc_drop_ship_flag    VARCHAR2(30);
    lc_cost              VARCHAR2(30);
    lc_quantity          VARCHAR2(30);
    lc_cost1             NUMBER;
    lc_quantity1         NUMBER;
    lc_amount            VARCHAR2(30);
    lc_line_amount       NUMBER;
    lc_line_type         VARCHAR2(30);
    ln_po_line_num       NUMBER;
    ln_inventory_item_id NUMBER;
	lc_error_msg         VARCHAR2(250);
    lc_errcode           VARCHAR2(30);
	ln_accrual_acct_id   NUMBER;
	lc_gl_company        VARCHAR2(30);
	lc_gl_cost_center    VARCHAR2(30);
	lc_gl_account        VARCHAR2(30);
	lc_gl_location       VARCHAR2(30);
	lc_gl_inter_company  VARCHAR2(30);
	lc_gl_lob            VARCHAR2(30);
	lc_gl_future         VARCHAR2(30);
    lc_non_deductible_supp  VARCHAR2(30);
	lc_reason_code       VARCHAR2(30);
	ln_ccid              NUMBER;
	ln_accrual_id        NUMBER;
	ln_acct_id           NUMBER;
	lc_gl_string         VARCHAR2(100);
	lc_status            VARCHAR2(30);
	lc_ret_status        VARCHAR2(30);
	lc_receipt_required_flag VARCHAR2(1);
	lc_sac_code_sign     VARCHAR2(10);
	lc_sac_code          VARCHAR2(10);

BEGIN
    l_table.DELETE;
    lc_cost_center        := NULL;
    lc_frequency_code     := NULL;
    lc_description        := NULL;
    lc_location           := NULL;
    lc_lob                := NULL;
    lc_account            := NULL;
    lc_drop_ship_acct     := NULL;
    lc_company            := NULL;
    lc_location_type      := NULL;
    lc_po_type            := NULL;
    lc_drop_ship_flag     := NULL;
    lc_cost               := NULL;
    lc_quantity           := NULL;
    lc_cost1              := NULL;
    lc_quantity1          := NULL;
    lc_amount             := NULL;
    lc_line_amount        := NULL;
    lc_line_type          := NULL;
    ln_po_line_num        := NULL;
    ln_inventory_item_id  := NULL;
	lc_gl_company         := NULL;
	lc_gl_cost_center     := NULL;
	lc_gl_account         := NULL;
	lc_gl_location        := NULL;
	lc_gl_inter_company   := NULL;
	lc_gl_lob             := NULL;
	lc_gl_future          := NULL;
	lc_reason_code        := NULL;
	lc_status             := NULL;
	lc_error_msg          := NULL;
	lc_ret_status         := NULL;
	lc_receipt_required_flag := NULL;
	lc_sac_code_sign      := NULL;
	ln_acct_id            := NULL;
	lc_sac_code           := NULL;

    l_table := p_table;

    IF p_source IN ('US_OD_TDM','US_OD_DCI_TRADE')
    THEN
      INSERT
       INTO xx_ap_trade_inv_lines
	   (invoice_line_id
	   ,invoice_id
	   ,record_type
	   ,ap_company
	   ,ap_vendor_1
	   ,ap_vendor
	   ,voucher
	   ,invoice_number
	   ,line_number
	   ,line_type
	   ,mdse_amount
	   ,mdse_amount_sign
	   ,charge_back
	   ,gl_company
	   ,gl_location
	   ,gl_cost_center
	   ,gl_lob
	   ,gl_account
	   ,gl_inter_company
	   ,gl_future
	   ,line_description
	   ,sku
	   ,cost
	   ,cost_sign
	   ,quantity
	   ,quantity_sign
	   ,source
	   ,invoice_date
	   ,location_number
	   ,frequency_code
	   ,reason_code
	   ,reason_code_desc
	   ,po_number
	   ,po_line_number
	   ,unit_of_measure
       ,sku_description
       ,sac_code
	   ,record_status
	   ,error_description
	   ,request_id
	   ,created_by
	   ,creation_date
	   ,last_updated_by
	   ,last_update_date
	   ,last_update_login
	   )
      VALUES
       (ap_invoice_lines_interface_s.NEXTVAL -- invoice_line_id
	   ,ap_invoices_interface_s.currval    -- invoice_id
       ,l_table(5) -- record_type
	   ,DECODE(l_table(12),'I','00',null)  -- ap_company
	   ,'0' -- ap_vendor_1
	   ,l_table(2) -- ap_vendor
	   ,NULL --xx_ap_trade_voucher_num_s.currval -- voucher
	   ,l_table(3) -- invoice_number
	   ,null -- line_number
	   ,l_table(19)  -- line_type
	   ,DECODE(l_table(8),'+',TO_NUMBER(l_table(7))/100,'-',-TO_NUMBER(l_table(7))/100) -- mdse_amount
	   ,l_table(8) -- mdse_amount_sign
	   ,null  -- charge_back
	   ,l_table(9)  -- gl_company
	   ,l_table(12) -- gl_location
	   ,l_table(10) -- gl_cost_center
	   ,l_table(14) -- gl_lob
	   ,l_table(11) -- gl_account
	   ,NVL(l_table(13),'0000') -- gl_inter_company
	   ,'000000' -- gl_future
	   ,l_table(15) -- line_description
	   ,null        -- sku
	   ,null        -- cost,
	   ,null        -- cost_sign
	   ,null        -- quantity
	   ,null        -- quantity_sign
	   ,p_source    -- source
	   ,null        -- invoice_date
	   ,null        -- location_number
	   ,null        -- frequency_code
	   ,null        -- reason_code
	   ,null        -- reason_code_desc
	   ,null        -- po_number
	   ,null        -- po_line_number
	   ,NULL -- unit_of_measure
       ,l_table(15) -- sku_description
       ,NULL -- sac_code
	   ,'N'		    -- record_status
	   ,''		    -- error_description
	   ,gn_request_id
	   ,gn_user_id
	   ,sysdate
	   ,gn_user_id
	   ,sysdate
	   ,gn_login_id
	   );

    ELSIF p_source = 'US_OD_CONSIGNMENT_SALES'
    THEN
      BEGIN
	    SELECT DECODE(a.attribute4,'WKLY','WE','DLY','DY','WE') -- assumption
          INTO lc_frequency_code
          FROM ap_supplier_sites_all a
         WHERE LTRIM(a.vendor_site_code_alt,'0') = ltrim(l_table(2),'0')
           AND a.pay_site_flag = 'Y'
		   AND a.attribute8 like 'TR%'
           AND NVL(a.inactive_date,sysdate) >= trunc(sysdate);

	  EXCEPTION
	    WHEN OTHERS
	    THEN
		   print_debug_msg ('Unable to fetch the Frequency code for the supplier' ,FALSE);
		   lc_frequency_code := 'WE';
	  END;

      INSERT
       INTO xx_ap_trade_inv_lines
	    (invoice_line_id
	    ,invoice_id
	    ,record_type
	    ,ap_company
	    ,ap_vendor_1
	    ,ap_vendor
	    ,voucher
	    ,invoice_number
	    ,line_number
	    ,line_type
	    ,mdse_amount
	    ,mdse_amount_sign
	    ,charge_back
	    ,gl_company
	    ,gl_location
	    ,gl_cost_center
	    ,gl_lob
	    ,gl_account
	    ,gl_inter_company
	    ,gl_future
	    ,line_description
	    ,sku
	    ,cost
	    ,cost_sign
	    ,quantity
	    ,quantity_sign
	    ,po_cost
	    ,po_cost_sign
	    ,source
	    ,invoice_date
	    ,location_number
	    ,frequency_code
	    ,reason_code
	    ,reason_code_desc
	    ,po_number
		,unit_of_measure
        ,sku_description
        ,sac_code
	    ,record_status
	    ,error_description
	    ,consign_flag
	    ,request_id
	    ,created_by
	    ,creation_date
	    ,last_updated_by
	    ,last_update_date
	    ,last_update_login
		,track_id
		,account_number
		)
       VALUES
        (ap_invoice_lines_interface_s.NEXTVAL -- invoice_line_id
	    ,null     -- ap_invoices_interface_s.currval -- invoice_id
        ,'D'      -- record_type
	    ,'00'     -- ap_company
	    ,'0'      -- ap_vendor_1
	    ,l_table(2) -- ap_vendor
	    ,null    -- xx_ap_trade_voucher_num_s.currval -- voucher
	    ,null    -- invoice_number
	    ,null    -- line_number
	    ,'ITEM'  -- line_type
	    ,TRUNC(TO_NUMBER(l_table(6))/1000,2) * DECODE(l_table(7),'+',TO_NUMBER(l_table(8)),'-',-TO_NUMBER(l_table(8)))  -- mdse_amount
	    ,l_table(5)   -- mdse_amount_sign
	    ,null         -- charge_back
	    ,l_table(19)  -- gl_company
	    ,l_table(15)  -- gl_location
	    ,l_table(16)  -- gl_cost_center
	    ,l_table(17)  -- gl_lob
	    ,l_table(18)  -- gl_account
	    ,l_table(20)  -- gl_inter_company
	    ,l_table(21)  -- gl_future
	    ,l_table(14)  -- line_description
	    ,l_table(4)   -- sku
	    ,l_table(6)/1000   -- cost
	    ,l_table(5)   -- cost_sign
	    ,l_table(8)   -- Quantity
	    ,l_table(7)   -- Quantity_sign
	    ,l_table(11)/1000  -- po_cost
	    ,l_table(10)  -- po_cost_sign
	    ,p_source     -- source
	    ,TO_DATE(l_table(3),'YYYYMMDD')  -- Invoice_Date
	    ,LTRIM(l_table(1),'0')   -- Location_number
	    ,lc_frequency_code -- frequency_code
	    ,null         -- reason_code
	    ,null         -- reason_code_desc
	    ,null         -- po_number
		,NULL         -- unit_of_measure
        ,l_table(9)   -- sku_description
        ,NULL         -- sac_code
	    ,'N'		  -- record_status
	    ,''			  -- error_description
	    ,l_table(13)  -- consign_flag
	    ,gn_request_id
	    ,gn_user_id
	    ,sysdate
	    ,gn_user_id
	    ,sysdate
	    ,gn_login_id
		,l_table(22) -- track_id
		,l_table(23) -- account_number
		);

    ELSIF p_source = 'US_OD_DROPSHIP'
    THEN
	    BEGIN
		   lc_non_deductible_supp := NULL;
	       SELECT source_value1
		     INTO lc_non_deductible_supp
		     FROM  xx_fin_translatevalues
		    WHERE translate_id IN (SELECT translate_id
								     FROM xx_fin_translatedefinition
								    WHERE translation_name = 'XX_AP_DS_NON_DED_SUPP'
								      AND enabled_flag = 'Y')
		    AND source_value1 = LTRIM(l_table(7),'0');

	    EXCEPTION
	       WHEN OTHERS
	       THEN
		      print_debug_msg ('Unable to check whether the supplier :'||l_table(7)||' is Non-Deductible for the Dropship' ,FALSE);
		      lc_non_deductible_supp    := NULL;
	    END;

		IF lc_non_deductible_supp IS NOT NULL
		THEN
		    insert_dropship_nonded(p_table      =>  l_table
                                  ,p_error_msg   =>  lc_error_msg
                                  ,p_errcode     => lc_errcode);

        ELSE
		    BEGIN
	            SELECT target_value1
		          INTO lc_description
		          FROM  xx_fin_translatevalues
		         WHERE translate_id IN (SELECT translate_id
								          FROM xx_fin_translatedefinition
								         WHERE translation_name = 'XX_AP_DS_DEDUCTION_CD'
								           AND enabled_flag = 'Y')
		           AND source_value1 = l_table(13);

	        EXCEPTION
	        WHEN OTHERS
	        THEN
		        print_debug_msg ('Unable to get the Reason code description for the Reason code :'||l_table(13) ,FALSE);
		        lc_description    := NULL;
	        END;

			IF  lc_description IS NOT NULL
			THEN

	            INSERT
		              INTO xx_ap_trade_inv_lines
		                        (invoice_line_id
		                        ,invoice_id
		                        ,record_type
		                        ,ap_company
		                        ,ap_vendor_1
		                        ,ap_vendor
		                        ,voucher
		                        ,invoice_number
		                        ,line_number
		                        ,line_type
		                        ,mdse_amount
		                        ,mdse_amount_sign
		                        ,charge_back
		                        ,gl_company
		                        ,gl_location
		                        ,gl_cost_center
		                        ,gl_lob
		                        ,gl_account
		                        ,gl_inter_company
		                        ,gl_future
		                        ,line_description
		                        ,sku
		                        ,cost
		                        ,cost_sign
		                        ,quantity
		                        ,quantity_sign
		                        ,source
		                        ,invoice_date
		                        ,location_number
		                        ,frequency_code
		                        ,reason_code
		                        ,reason_code_desc
		                        ,po_number
								,unit_of_measure
                                ,sku_description
                                ,sac_code
								,return_order_num
			                    ,return_order_sub
			                    ,orig_order_num
			                    ,orig_order_sub
								,return_auth_code
			                    ,brand_code
		                        ,record_status
		                        ,error_description
		                        ,request_id
		                        ,created_by
		                        ,creation_date
		                        ,last_updated_by
		                        ,last_update_date
		                        ,last_update_login
								)
		              VALUES    (ap_invoice_lines_interface_s.NEXTVAL -- invoice_line_id
		                        ,null -- invoice_id
		                        ,'D'            -- record_type
		                        ,'00'           -- ap_company
		                        ,'0'            -- ap_vendor_1
		                        ,l_table(7)     -- ap_vendor
		                        ,null           -- voucher
		                        ,'DS'||l_table(13)||l_table(8)||l_table(5) -- invoice_number
		                        ,null           -- line_number
		                        ,'ITEM'         -- line_type
		                        ,-TO_NUMBER(l_table(12))   -- mdse_amount
								-- ,(TO_NUMBER(l_table(12))) * TO_NUMBER(l_table(10))   -- mdse_amount
		                        ,'-'      -- mdse_amount_sign
		                        ,null     -- charge_back
		                        ,NULL     -- gl_company
		                        ,NULL     -- gl_location
		                        ,NULL     -- gl_cost_center
		                        ,NULL     -- gl_lob
		                        ,NULL     -- gl_account
		                        ,NULL     -- gl_inter_company
		                        ,NULL     -- gl_future
								,lc_description||' PO'||LTRIM(l_table(8),'0')||'-'||LPAD(LTRIM(l_table(5),'0'),4,'0') -- line_description
		                        --,'ORIG ORDR '||l_table(3)||l_table(4)||'/RTN ORDR '||l_table(1)||l_table(2) -- line_description
		                        ,l_table(9)    -- sku
		                        ,TO_NUMBER(l_table(12))   -- cost
		                        ,l_table(11)   -- cost_sign
		                        ,TO_NUMBER(l_table(10))   -- Quantity
		                        ,l_table(11)   -- Quantity_sign
		                        ,p_source      -- source
		                        ,TO_DATE(l_table(6),'YYYY-MM-DD')       -- Invoice_Date
		                        ,l_table(5)    -- Location_number
		                        ,null          -- frequency_code
		                        ,l_table(13)   -- reason_code
		                        ,lc_description  -- reason_code_desc
		                        ,l_table(8)      -- po_number
								,NULL            -- unit_of_measure
                                ,NULL            -- sku_description
                                ,NULL            -- sac_code
								,l_table(1)      -- return_order_num
			                    ,l_table(2)      -- return_order_sub
			                    ,l_table(3)      -- orig_order_num
			                    ,l_table(4)      -- orig_order_sub
								,l_table(14)     -- return_auth_code
			                    ,l_table(15)     -- brand_code
		                        ,'N'	         -- record_status
		                        ,''			     -- error_description
		                        ,gn_request_id
		                        ,gn_user_id
		                        ,sysdate
		                        ,gn_user_id
		                        ,sysdate
		                        ,gn_login_id
								);

			ELSE
			    insert_dropship_nonded(p_table       =>  l_table
                                      ,p_error_msg   =>  lc_error_msg
                                      ,p_errcode     =>  lc_errcode);

		    END IF; -- lc_description IS NOT NULL
	    END IF; -- lc_non_deductible_supp IS NOT NULL

    ELSIF p_source = 'US_OD_TRADE_EDI'
    THEN

	    IF l_table(1) = '6'
	    THEN
           lc_amount   := TRIM(l_table(10));
	       lc_amount   := TO_NUMBER(lc_amount)/100;
		   lc_line_type := 'FREIGHT';
		   l_table(6) := NULL;
		   l_table(9) := NULL;
		   lc_cost := NULL;
		   lc_quantity := NULL;
		   l_table(11) := NULL;
		   l_table(7):= NULL;

	    ELSIF l_table(1) = '4'
	    THEN
	       lc_cost := TRIM(l_table(10));
	       lc_cost := TO_NUMBER(lc_cost)/1000;
           lc_quantity := TRIM(l_table(5));
	       lc_quantity := TO_NUMBER(lc_quantity)/100;
		   l_table(15) := NULL;

		   IF l_table(6) = '+'
		   THEN
		      lc_amount := TO_NUMBER(lc_quantity) * TO_NUMBER(lc_cost);
		   ELSIF l_table(6) = '-'
		   THEN
		      lc_amount := (-1) * TO_NUMBER(lc_quantity) * TO_NUMBER(lc_cost);
		   END IF;

	       lc_line_type := 'ITEM';
	    END IF;

	    INSERT
		    INTO xx_ap_trade_inv_lines
		    (invoice_line_id
		    ,invoice_id
		    ,record_type
		    ,ap_company
		    ,ap_vendor_1
		    ,ap_vendor
		    ,voucher
		    ,invoice_number
		    ,line_number
		    ,line_type
		    ,mdse_amount
		    ,mdse_amount_sign
		    ,charge_back
		    ,gl_company
		    ,gl_location
		    ,gl_cost_center
		    ,gl_lob
		    ,gl_account
		    ,gl_inter_company
		    ,gl_future
		    ,line_description
		    ,sku
		    ,cost
		    ,cost_sign
		    ,quantity
		    ,quantity_sign
		    ,source
		    ,invoice_date
		    ,location_number
		    ,frequency_code
		    ,reason_code
		    ,reason_code_desc
		    ,po_number
		    ,po_line_number
			,unit_of_measure
            ,sku_description
            ,sac_code
		    ,record_status
		    ,error_description
		    ,request_id
		    ,created_by
		    ,creation_date
		    ,last_updated_by
		    ,last_update_date
		    ,last_update_login)
		   VALUES
		    (ap_invoice_lines_interface_s.NEXTVAL -- invoice_line_id
		    ,TO_NUMBER(l_table(13))    -- invoice_id
		    ,'D'            -- record_type
		    ,NULL           -- ap_company
		    ,'0'            -- ap_vendor_1
		    ,l_table(2)     -- ap_vendor
		    ,NULL -- l_table(14)    -- voucher number
		    ,LTRIM(l_table(12),'0') -- invoice_number  /* Added LTRIM to removing the preceeding zeros in the invoice number */
		    ,null           -- line_number
		    ,lc_line_type -- line_type
		    ,TO_NUMBER(lc_amount)   -- mdse_amount
		    ,l_table(6)     -- mdse_amount_sign
		    ,NULL           -- charge_back
		    ,NULL           -- gl_company
		    ,NULL           -- gl_location
		    ,NULL           -- gl_cost_center
		    ,NULL           -- gl_lob
		    ,NULL           -- gl_account
		    ,NULL           -- gl_inter_company
		    ,NULL           -- gl_future
		    ,NULL           -- line_description
		    ,l_table(9)     -- SKU
		    ,TO_NUMBER(lc_cost)   -- cost
		    ,l_table(11)          -- cost_sign
		    ,TO_NUMBER(lc_quantity)  -- Quantity
		    ,l_table(6)    -- Quantity_sign
		    ,p_source      -- source
		    ,NULL          -- Invoice_Date
		    ,LPAD(LTRIM(l_table(4),'0'),4,'0')   -- Location_number
		    ,NULL          -- frequency_code
		    ,NULL          -- reason_code
		    ,NULL          -- reason_code_desc
		    ,l_table(3)    -- po_number
		    ,NULL          -- PO line Number
			,l_table(7)    -- unit_of_measure
            ,NULL          -- sku_description
            ,l_table(15)   -- sac_code
		    ,'N'		   -- record_status
		    ,''			   -- error_description
		    ,gn_request_id
		    ,gn_user_id
		    ,SYSDATE
		    ,gn_user_id
		    ,SYSDATE
		    ,gn_login_id
           );

    END IF; -- If p_source

EXCEPTION
WHEN OTHERS
THEN
    p_errcode   := '2';
    p_error_msg := 'Error in XX_AP_INVOICE_INTEGRAL_PKG.insert_line '||substr(sqlerrm,1,150);
    fnd_file.put_line(fnd_file.log,'Line error message :'||sqlerrm);
END insert_line;

-- +==========================================================================================================+
-- |  Name	 : load_csi_data                                                                                  |
-- |  Description: This procedure inserts the CSI data into pre-staging tables                                |
-- ===========================================================================================================|
PROCEDURE load_csi_data(p_source         IN   VARCHAR2
                       ,p_frequency_code IN   VARCHAR2
                       ,p_debug          IN   VARCHAR2
					   ,p_from_date      IN   DATE
				       ,p_to_date        IN   DATE
					   ,p_date           IN   DATE
					   ,p_error_msg      OUT  VARCHAR2
                       ,p_errcode        OUT  VARCHAR2)
AS

-- Cursor to get the lines details for the Consignment Source from the Prestaging table
    CURSOR csi_lines_cur(p_from_date IN DATE,
                         p_to_date   IN DATE,
						 p_date      IN DATE
						)
    IS
        SELECT ap_vendor,
	    	   sum(mdse_amount) sum_amount,
	    	   source,
	    	   frequency_code
		  FROM xx_ap_trade_inv_lines
	     WHERE record_status = 'N'
           AND source = p_source
		  AND ((frequency_code = NVL(p_frequency_code,'DY') AND creation_date BETWEEN to_date(to_char(p_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_date)||' 23:59:59','DD-MON-RR HH24:MI:SS'))
		     OR (frequency_code = NVL(p_frequency_code,'WE') AND creation_date BETWEEN to_date(to_char(p_from_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_to_date)||' 23:59:59','DD-MON-RR HH24:MI:SS'))
			  )
	    GROUP BY ap_vendor,
	    	     source,
	    	     frequency_code;

    ld_from_date       DATE;
    ld_to_date         DATE;
    ld_date            DATE;
    ln_invoice_id      NUMBER;
    lc_vendor_site     VARCHAR2(30);
    l_table            varchar2_table;
    ln_count_hdr       NUMBER := 0;
    ln_sequence_number NUMBER := 0;
    lc_error_loc       VARCHAR2(100) := 'XX_AP_INVOICE_INTEGRAL_PKG.load_csi_data';
    lc_error_msg       VARCHAR2(1000);
    lc_errcode         VARCHAR2(100);
    data_exception     EXCEPTION;

BEGIN
    SELECT TRUNC(SYSDATE,'DY')-6 -- TRUNC(SYSDATE,'DY')-7
	  INTO ld_from_date
	  FROM dual;
	-- fnd_file.put_line(fnd_file.log,' ld_from_date :'||ld_from_date);

	SELECT TRUNC(SYSDATE,'DY') -- TRUNC(SYSDATE,'DY')-1
	  INTO ld_to_date
	  FROM dual;
	-- fnd_file.put_line(fnd_file.log,' ld_to_date :'||ld_to_date);

	SELECT TRUNC(SYSDATE)  -- TRUNC(SYSDATE,'DY')+6
	  INTO ld_date
	  FROM dual;
	-- fnd_file.put_line(fnd_file.log,' ld_date :'||ld_date);

	lc_vendor_site := NULL;

	-- fnd_file.put_line(fnd_file.log,' From date :'||p_from_date);
	--fnd_file.put_line(fnd_file.log,' To date :'||p_to_date);
	-- fnd_file.put_line(fnd_file.log,' Date :'||p_date);

	-- For DAILY
	IF p_frequency_code = 'DY'
	THEN
	    IF p_date IS NOT NULL
	    THEN
		    ld_from_date := p_date;
			ld_to_date   := p_date;
		ELSE
		    ld_from_date := ld_date;
			ld_to_date   := ld_date;
		END IF;
	ELSE
		ld_date      := ld_date;
	END IF;

	 -- Creating the header record
	FOR csi_lines IN csi_lines_cur(p_from_date => NVL(p_from_date,ld_from_date),
	                               p_to_date => NVL(p_to_date,ld_to_date),
								   p_date => NVL(p_date,ld_date))
    LOOP
		BEGIN
		    SELECT ap_invoices_interface_s.nextval
		      INTO ln_invoice_id
			  FROM DUAL;

            IF csi_lines.frequency_code = 'DY'
		    THEN
		        l_table(1):= to_char(ln_invoice_id);
		        l_table(2):= csi_lines.ap_vendor;
			    l_table(3):= 'DY'||NVL(to_char(p_date,'MMDDYY'),to_char(sysdate,'MMDDYY'));
			    l_table(4):= NVL(to_char(p_date,'MMDDYY'),to_char(sysdate,'MMDDYY'));
			    l_table(5):= to_char(csi_lines.sum_amount);
			    l_table(6):= NULL; -- csi_lines.mdse_amount_sign;
			    l_table(7):= NULL; -- to_char(ln_voucher_num);
			    l_table(8):= null;
			    l_table(9):= NVL(to_char(p_date,'MMDDYY'),to_char(sysdate,'MMDDYY'));

			    print_debug_msg ('Insert Header',FALSE);
			    insert_header(l_table,p_source,lc_error_msg,lc_errcode);
   	            IF lc_errcode = '2'
			    THEN
	               RAISE data_exception;
	            END IF;
			    ln_count_hdr := ln_count_hdr + 1;

			    UPDATE xx_ap_trade_inv_lines
			       SET invoice_id = ln_invoice_id,
				       voucher = NULL, --ln_voucher_num,
					   invoice_number = 'DY'||NVL(to_char(p_date,'MMDDYY'),to_char(sysdate,'MMDDYY')),
					   last_update_date = sysdate,
					   last_updated_by = gn_user_id
			    WHERE record_status = 'N'
			      AND ap_vendor = csi_lines.ap_vendor
				  AND frequency_code = csi_lines.frequency_code
				  AND source = p_source
				  AND creation_date BETWEEN to_date(to_char(NVL(p_date,ld_date))||' 00:00:00','DD-MON-RR HH24:MI:SS')
				                        AND to_date(to_char(NVL(p_date,ld_date))||' 23:59:59','DD-MON-RR HH24:MI:SS');

		    ELSIF csi_lines.frequency_code = 'WE'
		    THEN
			    lc_vendor_site:= csi_lines.ap_vendor;
			    ln_sequence_number := ln_sequence_number+1;

			    l_table(1):= to_char(ln_invoice_id);
			    l_table(2):= csi_lines.ap_vendor;
			    l_table(3):= 'WE'||NVL(to_char(p_to_date-1,'MMDDYY'),to_char(ld_to_date-1,'MMDDYY'))||to_char(LPAD(ln_sequence_number,4,0));
			    l_table(4):= NVL(to_char(p_to_date-1,'MMDDYY'),to_char(ld_to_date-1,'MMDDYY'));
			    l_table(5):= to_char(csi_lines.sum_amount);
			    l_table(6):= NULL; -- csi_lines.mdse_amount_sign;
			    l_table(7):= NULL; -- to_char(ln_voucher_num);
			    l_table(8):= null;
		        l_table(9):= NULL;

		        print_debug_msg ('Insert Header',FALSE);
			    insert_header(l_table,p_source,lc_error_msg,lc_errcode);
   	            IF lc_errcode = '2'
			    THEN
	               RAISE data_exception;
	            END IF;
			    ln_count_hdr := ln_count_hdr + 1;

			    UPDATE xx_ap_trade_inv_lines
			       SET invoice_id = ln_invoice_id,
				       --voucher = ln_voucher_num,
					   invoice_number = 'WE'||NVL(to_char(p_to_date-1,'MMDDYY'),to_char(ld_to_date-1,'MMDDYY'))||to_char(LPAD(ln_sequence_number,4,0)),
					   last_update_date = sysdate,
					   last_updated_by = gn_user_id
			     WHERE record_status = 'N'
			       AND ap_vendor = csi_lines.ap_vendor
				   AND frequency_code = csi_lines.frequency_code
				   AND source = p_source
				   -- AND TRUNC(creation_date) BETWEEN TRUNC(NVL(p_from_date,ld_from_date)) AND TRUNC(NVL(p_to_date,ld_to_date))
				   AND creation_date BETWEEN to_date(to_char(NVL(p_from_date,ld_from_date))||' 00:00:00','DD-MON-RR HH24:MI:SS')
				                         AND to_date(to_char(NVL(p_to_date,ld_to_date))||' 23:59:59','DD-MON-RR HH24:MI:SS');

		    END IF;
		    COMMIT;
		EXCEPTION
		WHEN OTHERS
		THEN
		    print_debug_msg ('Error Message:'||SQLERRM,FALSE);
		END;
	END LOOP;
EXCEPTION
    WHEN data_exception
    THEN
       ROLLBACK;
        p_errcode   := '2';
        fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
        p_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_csi_data - '||p_error_msg,TRUE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_csi_data',
	                   lc_error_loc,
		               p_error_msg);
    WHEN OTHERS
    THEN
        p_errcode   := '2';
        fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
        p_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_csi_data - '||p_error_msg,TRUE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_csi_data',
	                   lc_error_loc,
		               p_error_msg);
END load_csi_data;

-- +==========================================================================================================+
-- |  Name	 : load_drp_data                                                                                  |
-- |  Description: This procedure inserts the DROPSHIP data into pre-staging tables                           |
-- ===========================================================================================================|
PROCEDURE load_drp_data(p_source         IN   VARCHAR2
                       ,p_date           IN   DATE
                       ,p_debug          IN   VARCHAR2
					   ,p_error_msg      OUT  VARCHAR2
                       ,p_errcode        OUT  VARCHAR2)
AS

   -- Cursor to check whether the PO Number exists or not
   CURSOR drp_po_cur
   IS
     SELECT *
	   FROM xx_ap_trade_inv_lines
	  WHERE record_status IN ('N','E')
        AND source = p_source
		-- AND trunc(creation_date) = NVL(p_date,creation_date)
		AND (p_date IS NULL OR (creation_date BETWEEN to_date(to_char(p_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')))
		;

    -- Cursor to get the lines details for the Dropship Source from the Prestaging table
    CURSOR drp_lines_cur
    IS
        SELECT ap_vendor,
	           invoice_number,
	    	   sum(mdse_amount) sum_amount,
	    	   line_description,
	    	   source,
	    	   location_number,
	    	   po_number,
			   invoice_date,
			   NULL mdse_amount_sign
	      FROM xx_ap_trade_inv_lines a
	     WHERE record_status = 'N'
           AND source = p_source
		   -- AND trunc(creation_date) = NVL(p_date,creation_date)
		   AND (p_date IS NULL OR (creation_date BETWEEN to_date(to_char(p_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')))
	    GROUP BY ap_vendor,
		         invoice_number,
		         po_number,
	    		 location_number,
	    		 line_description,
				 invoice_date,
	    		 source
	    		 ;

	-- Cursor to fetch all the Dropship Invoices which doesn't have NO PO Reference
    CURSOR drp_po_num_cur
    IS
	    SELECT invoice_number,
		       po_number||'-'||LPAD(LTRIM(location_number,'0'),4,'0') po_number  -- version 4.6
	      FROM xx_ap_trade_inv_lines
	     WHERE creation_date = NVL(p_date,creation_date)
	       AND source = 'US_OD_DROPSHIP'
		   AND record_status = 'E';

	ln_invoice_id        NUMBER;
	l_table              varchar2_table;
	ln_count_hdr         NUMBER := 0;
    lc_error_loc         VARCHAR2(100) := 'XX_AP_INVOICE_INTEGRAL_PKG.load_drp_data';
	lc_error_msg         VARCHAR2(1000);
    lc_errcode           VARCHAR2(100);
	data_exception       EXCEPTION;
	ln_accrual_acct_id   NUMBER;
	lc_status            VARCHAR2(1);
	lc_gl_company        VARCHAR2(30);
	lc_gl_cost_center    VARCHAR2(30);
	lc_gl_account        VARCHAR2(30);
	lc_gl_location       VARCHAR2(30);
	lc_gl_inter_company  VARCHAR2(30);
	lc_gl_lob            VARCHAR2(30);
	lc_gl_future         VARCHAR2(30);
    lc_drp_details       VARCHAR2(32767);
	lc_email_from        VARCHAR2(100);
	lc_email_to          VARCHAR2(100);
	lc_email_cc          VARCHAR2(100);
	lc_email_subject     VARCHAR2(100);
	lc_email_body        VARCHAR2(100);
	conn                 utl_smtp.connection;
	lc_ret_status        VARCHAR2(100);

BEGIN
    l_table.delete;
	ln_invoice_id := NULL;

	-- Checking the Dropship PO Exists or NOT
	FOR drp_po IN drp_po_cur
	LOOP
	   BEGIN
	        BEGIN
                SELECT pod.accrual_account_id
				  INTO ln_accrual_acct_id
                  FROM po_headers_all poh,
                       po_lines_all   pol,
	                   po_distributions_all pod
                 WHERE poh.po_header_id = pol.po_header_id
                   AND poh.po_header_id = pod.po_header_id
                   AND pol.po_line_id = pod.po_line_id
                   AND poh.segment1 = drp_po.po_number||'-'||LPAD(LTRIM(drp_po.location_number,'0'),4,'0')  -- version 4.6
                   AND pol.line_num =  1;
			EXCEPTION
				WHEN OTHERS
				THEN
					ln_accrual_acct_id := NULL;
			END;

            IF 	ln_accrual_acct_id IS NOT NULL
            THEN
			    lc_status := 'N';

			    BEGIN
                    SELECT SUBSTR(concatenated_segments,1,4),
                           SUBSTR(concatenated_segments,6,5),
				           SUBSTR(concatenated_segments,12,8),
                           LPAD(LTRIM(drp_po.location_number,'0'),6,'0'),
		                   SUBSTR(concatenated_segments,28,4),
		                   '80',
		                   SUBSTR(concatenated_segments,36,6)
			          INTO lc_gl_company,
			               lc_gl_cost_center,
				           lc_gl_account,
			               lc_gl_location,
			               lc_gl_inter_company,
			               lc_gl_lob,
			               lc_gl_future
			          FROM gl_code_combinations_kfv
                     WHERE code_combination_id = ln_accrual_acct_id;
				EXCEPTION
				    WHEN OTHERS
					THEN
					    lc_gl_company        := NULL;
					    lc_gl_cost_center    := NULL;
					    lc_gl_account        := NULL;
					    lc_gl_location       := NULL;
					    lc_gl_inter_company  := NULL;
					    lc_gl_lob            := NULL;
					    lc_gl_future         := NULL;
				END;

		    ELSE
			    lc_status := 'E'; -- Erroring the record because PO does not exist
			    lc_gl_company        := NULL;
			    lc_gl_cost_center    := NULL;
			    lc_gl_account        := NULL;
			    lc_gl_location       := NULL;
			    lc_gl_inter_company  := NULL;
			    lc_gl_lob            := NULL;
			    lc_gl_future         := NULL;
            END IF;	-- ln_accrual_acct_id IS NOT NULL

			UPDATE xx_ap_trade_inv_lines
			   SET record_status = lc_status
			      ,gl_company = lc_gl_company
			      ,gl_location = lc_gl_location
			      ,gl_cost_center = lc_gl_cost_center
			      ,gl_lob = lc_gl_lob
			      ,gl_account = lc_gl_account
			      ,gl_inter_company = lc_gl_inter_company
	              ,gl_future = lc_gl_future
				  ,last_update_date = sysdate
				  ,last_updated_by = gn_user_id
			 WHERE invoice_line_id = drp_po.invoice_line_id;

	   EXCEPTION
	   WHEN OTHERS
		THEN
		    print_debug_msg ('Error Message:'||SQLERRM,FALSE);
	   END;
	END LOOP;
	COMMIT;

	 -- Creating the header record
	FOR drp_lines IN drp_lines_cur
    LOOP
		BEGIN
		    SELECT ap_invoices_interface_s.nextval
		      INTO ln_invoice_id
			  FROM DUAL;

		    l_table(1) := to_char(ln_invoice_id);
		    l_table(2) := drp_lines.ap_vendor;
			l_table(3) := drp_lines.invoice_number;
			l_table(4) := to_char(drp_lines.invoice_date,'MMDDYY');
			l_table(5) := to_char(drp_lines.sum_amount);
			l_table(6) := drp_lines.mdse_amount_sign;
			l_table(7) := NULL; --to_char(ln_voucher_num);
			l_table(8) := drp_lines.line_description;
			l_table(9) := drp_lines.location_number;
			l_table(10):= drp_lines.po_number;
			l_table(11):= NVL(to_char(p_date,'MMDDYY'),to_char(sysdate,'MMDDYY'));

			print_debug_msg ('Insert Header',FALSE);
			insert_header(l_table,p_source,lc_error_msg,lc_errcode);
   	        IF lc_errcode = '2'
			THEN
	           RAISE data_exception;
	        END IF;
			ln_count_hdr := ln_count_hdr + 1;

			UPDATE xx_ap_trade_inv_lines
			   SET invoice_id = ln_invoice_id,
			       last_update_date = sysdate,
				   last_updated_by = gn_user_id
			 WHERE record_status = 'N'
			   AND invoice_number = drp_lines.invoice_number
			   AND source = p_source;

		    COMMIT;
		EXCEPTION
		WHEN OTHERS
		THEN
		    print_debug_msg ('Error Message:'||SQLERRM,FALSE);
		END;
	END LOOP;

	-- Send an email if the PO Number does not exist

	lc_drp_details  := NULL;
	   FOR drp_details IN drp_po_num_cur
       LOOP
	    BEGIN
		    -- Added as per version 3.7
		    -- Calling the procedure to identify the missed POs and send to POM team
			xx_po_pom_int_pkg.valid_and_mark_missed_po_int(  p_source => 'INVOICE-DROPSHIP DEDUCTIONS'
		   		                                            ,p_source_record_id  => NULL
		   		                                            ,p_po_number    => drp_details.po_number
		   		                                            ,p_po_line_num  => NULL
		   		                                            ,p_result       => lc_ret_status
														  );
	        lc_drp_details := lc_drp_details||chr(10)||'Invoice Number :'||drp_details.invoice_number||' and '||'PO Number is :'||drp_details.po_number||chr(10);
	       EXCEPTION
	    WHEN OTHERS
	    THEN
               lc_drp_details := lc_drp_details||chr(10)||'Invoice Number :'||drp_details.invoice_number||' and '||'PO Number is :'||drp_details.po_number||chr(10);
	    END;
	   END LOOP;

	IF lc_drp_details IS NOT NULL
	THEN

	/* Added as per version 2.7 */
	-- To get the Email details
	    BEGIN
	        lc_email_from    := NULL;
	    	lc_email_to      := NULL;
	        lc_email_cc      := NULL;
	        lc_email_subject := NULL;
	        lc_email_body    := NULL;

	        SELECT target_value1, -- Email From
                   target_value2, -- Email To
                   target_value3, -- Email CC
                   target_value4, -- Email Subject
                   target_value5  -- Email Body
	    	  INTO lc_email_from,
	    	       lc_email_to,
	    		   lc_email_cc,
	    		   lc_email_subject,
	    		   lc_email_body
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
	                                  FROM xx_fin_translatedefinition
	                                 WHERE translation_name = 'XX_AP_TRADE_INV_EMAIL'
	                                   AND enabled_flag = 'Y')
                  AND source_value1 = p_source;
	    EXCEPTION
	    WHEN OTHERS
	    THEN
	        lc_email_from    := NULL;
	    	lc_email_to      := NULL;
	    	lc_email_cc      := NULL;
	    	lc_email_subject := NULL;
	    	lc_email_body    := NULL;
	    END;

        BEGIN
            conn := xx_pa_pb_mail.begin_mail(sender => lc_email_from,
                                             recipients => lc_email_to,
                                             cc_recipients=>lc_email_cc,
                                             subject => lc_email_subject ,
                                             mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

            xx_pa_pb_mail.attach_text( conn => conn,
                                       data => lc_drp_details
                                                );

            xx_pa_pb_mail.end_mail( conn => conn );

            COMMIT;
            print_debug_msg ('Email sent successfully',TRUE);
        EXCEPTION
        WHEN OTHERS
	    THEN
            print_debug_msg ('Error while sending the Email',TRUE);
        END;
	END IF; -- lc_drp_details

EXCEPTION
WHEN data_exception
THEN
    ROLLBACK;
    p_errcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    p_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_drp_data - '||p_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_drp_data',
	               lc_error_loc,
		           p_error_msg);
WHEN OTHERS
THEN
    p_errcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    p_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_drp_data - '||p_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_drp_data',
	               lc_error_loc,
		           p_error_msg);
END load_drp_data;

-- +==========================================================================================================+
-- |  Name	 : load_rtv_data                                                                                  |
-- |  Description: This procedure reads data from the RTV staging tables and inserts into pre-staging tables  |
-- ===========================================================================================================|
PROCEDURE load_rtv_data(p_source         IN   VARCHAR2
                       ,p_frequency_code IN   VARCHAR2
					   ,p_from_date      IN   DATE
				       ,p_to_date        IN   DATE
					   ,p_date           IN   DATE
                       ,p_debug          IN   VARCHAR2
					   ,p_error_msg      OUT  VARCHAR2
                       ,p_errcode        OUT  VARCHAR2)
AS
  -- Cursor to get the RTV Header details
    CURSOR rtv_hdr_dy_details( p_frequency_code  VARCHAR2,
	                           p_date            DATE)
    IS
        SELECT header_id,
		       record_type,
			   rtv_number,
			   voucher_num,
			   location,
			   return_code,
			   vendor_num,
			   invoice_num,
			   pay_group_lookup_code,
			   payment_method_lookup_code,
			   supplier_attr_category,
			   frequency_code,
               record_status,
               error_description
	      FROM xx_ap_rtv_hdr_attr
	     WHERE 1 = 1
	       AND record_status = 'N'
		   AND frequency_code = p_frequency_code
		   AND creation_date BETWEEN to_date(to_char(p_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')
		   ;

	CURSOR rtv_hdr_wy_details( p_weekly          VARCHAR2
	                          ,p_monthly         VARCHAR2
                              ,p_quarterly       VARCHAR2
							  ,p_wy_from_date    DATE
							  ,p_wy_to_date      DATE
							  ,p_my_start_date   DATE
							  ,p_my_end_date     DATE
							  ,p_qy_start_date   DATE
							  ,p_qy_end_date     DATE
							  ,p_frequency_code  VARCHAR2
							 )
    IS
		SELECT NULL header_id,
		       NULL record_type,
			   NULL rtv_number,
			   NULL voucher_num,
			   NULL location,
			   return_code,
			   vendor_num,
			   NULL invoice_num,
			   pay_group_lookup_code,
			   payment_method_lookup_code,
			   supplier_attr_category,
			   frequency_code,
               NULL record_status,
               NULL error_description
	      FROM xx_ap_rtv_hdr_attr
	     WHERE 1 = 1
	       AND record_status = 'N'
		   /*AND  ((frequency_code = 'WY' AND (TRUNC(creation_date) BETWEEN TRUNC(p_wy_from_date) AND TRUNC(p_wy_to_date)) AND p_weekly = 'Y')
				 OR(frequency_code = 'MY' AND (TRUNC(creation_date) BETWEEN TRUNC(p_my_start_date) AND TRUNC(p_my_end_date)) AND p_monthly = 'Y')
				 OR(frequency_code = 'QY' AND (TRUNC(creation_date) BETWEEN TRUNC(p_qy_start_date) AND TRUNC(p_qy_end_date)) AND p_quarterly = 'Y')
			    ) */
		   AND ((frequency_code = 'WY' AND creation_date BETWEEN to_date(to_char(p_wy_from_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_wy_to_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_weekly = 'Y')
		         OR(frequency_code = 'MY' AND creation_date BETWEEN to_date(to_char(p_my_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_my_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_monthly = 'Y')
				 OR(frequency_code = 'QY' AND creation_date BETWEEN to_date(to_char(p_qy_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_qy_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_quarterly = 'Y')
			    )
		GROUP BY vendor_num,
			     return_code,
			     pay_group_lookup_code,
			     payment_method_lookup_code,
			     supplier_attr_category,
			     frequency_code;

	TYPE header IS TABLE OF rtv_hdr_dy_details%ROWTYPE
    INDEX BY PLS_INTEGER;

  -- Cursor to get the RTV Lines Daily Details
    CURSOR rtv_line_dy_details (  p_header_id         NUMBER
	                             ,p_frequency_code    VARCHAR2
							    )
    IS
        SELECT *
	      FROM xx_ap_rtv_lines_attr
	     WHERE record_status = 'N'
		   AND header_id  = p_header_id
		   AND frequency_code = p_frequency_code;

  -- Cursor to get the RTV Lines Weekly Details
	CURSOR rtv_line_wy_details (  p_weekly          VARCHAR2
	                             ,p_monthly         VARCHAR2
                                 ,p_quarterly       VARCHAR2
							     ,p_wy_from_date    DATE
							     ,p_wy_to_date      DATE
							     ,p_my_start_date   DATE
							     ,p_my_end_date     DATE
							     ,p_qy_start_date   DATE
							     ,p_qy_end_date     DATE
							     ,p_vendor_num      VARCHAR2
                                 ,p_frequency_code  VARCHAR2
							    )
    IS
		SELECT *
	      FROM xx_ap_rtv_lines_attr
	     WHERE record_status = 'N'
		   AND vendor_num = p_vendor_num
		   AND ((frequency_code = 'WY' AND creation_date BETWEEN to_date(to_char(p_wy_from_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_wy_to_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_weekly = 'Y')
		         OR(frequency_code = 'MY' AND creation_date BETWEEN to_date(to_char(p_my_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_my_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_monthly = 'Y')
				 OR(frequency_code = 'QY' AND creation_date BETWEEN to_date(to_char(p_qy_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_qy_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND p_quarterly = 'Y')
			    )
		;

	TYPE lines IS TABLE OF rtv_line_dy_details%ROWTYPE
    INDEX BY PLS_INTEGER;

  -- Cursor to get the Header amount for RTV
    CURSOR rtv_hdr_amount( p_header_id  NUMBER)
    IS
        SELECT DECODE(line_amount,0,adjusted_line_amount,line_amount) line_amount
		  FROM
			(SELECT SUM(line_amount) line_amount,
			        SUM(adjusted_line_amount) adjusted_line_amount
	           FROM xx_ap_rtv_lines_attr
	          WHERE header_id = p_header_id) a
		;


	l_rtv_hdr_dy_tab 	          HEADER;
	l_rtv_hdr_wy_tab 	          HEADER;
	l_rtv_lines_dy_tab 	          LINES;
    l_rtv_lines_wy_tab 	          LINES;
    indx                 	      NUMBER;
    l_indx                        NUMBER;
    o_indx			              NUMBER;
    ln_batch_size		          NUMBER := 250;
    lc_error_loc                  VARCHAR2(100) := 'XX_AP_INVOICE_INTEGRAL_PKG.load_rtv_data';
    lc_error_msg                  VARCHAR2(1000);
    lc_errcode                    VARCHAR2(100);
    ln_err_count		          NUMBER;
    ln_error_idx		          NUMBER;
    data_exception                EXCEPTION;
	ln_line_number                NUMBER;
	ln_header_id                  NUMBER;
    ln_total_records_processed    NUMBER;
    ln_success_records            NUMBER;
    ln_failed_records             NUMBER;
	lc_status                     VARCHAR2(10);
	lc_hdr_amount                 VARCHAR2(30);
	lc_retcode                    VARCHAR2(10);
	lc_gl_company                 VARCHAR2(30);
	lc_gl_cost_center             VARCHAR2(30);
	lc_gl_account                 VARCHAR2(30);
	lc_gl_location                VARCHAR2(30);
	lc_gl_inter_company           VARCHAR2(30);
	lc_gl_lob                     VARCHAR2(30);
	lc_gl_future                  VARCHAR2(30);
	ln_inventory_item_id          NUMBER;
	ln_organization_id            NUMBER;
	lc_uom_code                   VARCHAR2(10);
	lc_cc_id                      VARCHAR2(10);
	ld_wy_from_date               DATE;
	ld_wy_to_date                 DATE;
	ld_my_start_date              DATE;
	ld_my_end_date                DATE;
	ld_qy_start_date              DATE;
	ld_qy_end_date                DATE;
	ln_period_year                NUMBER;
	ln_quarter_num                NUMBER;
	lc_weekly                     VARCHAR2(1);
	lc_monthly                    VARCHAR2(1);
	lc_quarterly                  VARCHAR2(1);
	ln_sequence_number            NUMBER;
	lc_description                VARCHAR2(100);
	lc_invoice_number             VARCHAR2(30);
	lc_vendor_num                 VARCHAR2(30);
	lc_freight_bill_num           VARCHAR2(500);
	lc_freight_carrier            VARCHAR2(100);
	ld_date                       DATE;
	ln_rtv_date                   DATE; -- Added for Defect# 45221 NAIT-40778

BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
    ln_total_records_processed:= 0;
	ln_success_records := 0;
	ln_failed_records := 0;
	lc_weekly     := 'N';
	lc_monthly    := 'N';
	lc_quarterly  := 'N';
	ln_header_id  := 0;
	ln_sequence_number := 0;
	lc_vendor_num := '-1';

    print_debug_msg ('Start the loading data into Pre-Staging table for RTV' ,TRUE);

	-- For Daily
	SELECT TRUNC(SYSDATE)  -- TRUNC(SYSDATE,'DY')+6
	  INTO ld_date
	  FROM dual;

	-- For Weekly
	SELECT  TRUNC(SYSDATE,'DY') -- TRUNC(SYSDATE,'DY')-7
	  INTO ld_wy_from_date
	  FROM dual;

	SELECT TRUNC(SYSDATE,'DY')+6  -- TRUNC(SYSDATE,'DY')-1
	  INTO ld_wy_to_date
	  FROM dual;

	-- For MONTHLY
	SELECT start_date, end_date, quarter_start_date, period_year, quarter_num
	  INTO ld_my_start_date, ld_my_end_date, ld_qy_start_date, ln_period_year, ln_quarter_num
	  FROM gl_periods
     WHERE TRUNC(SYSDATE) BETWEEN TRUNC(start_date) AND TRUNC(end_date);

	-- For Quarterly
	SELECT MAX(end_date)
	  INTO ld_qy_end_date
	  FROM gl_periods
	 WHERE quarter_num = ln_quarter_num
	   AND period_year = ln_period_year;

	IF p_frequency_code = 'WY' -- To handle Weekly Invoices
	THEN
	   lc_weekly := 'Y';
	ELSIF p_frequency_code = 'MY' -- To handle Monthly Invoices
	THEN
	   lc_weekly := 'Y';
	   lc_monthly := 'Y';
	ELSIF p_frequency_code = 'QY' -- To handle Quarterly Invoices
	THEN
	   lc_weekly := 'Y';
	   lc_monthly := 'Y';
	   lc_quarterly := 'Y';
	END IF;

	ld_date := NVL(p_date,ld_date);
	ld_wy_from_date := NVL(p_from_date,ld_wy_from_date);
	ld_wy_to_date := NVL(p_to_date,ld_wy_to_date);
	ld_my_start_date := NVL(p_from_date,ld_my_start_date);
	ld_my_end_date := NVL(p_to_date,ld_my_end_date);
	ld_qy_start_date := NVL(p_from_date,ld_qy_start_date);
	ld_qy_end_date := NVL(p_to_date,ld_qy_end_date);

	/* Process the Header details */
	IF p_frequency_code = 'DY'
	THEN
	    OPEN rtv_hdr_dy_details( p_frequency_code  =>  p_frequency_code,
		                         p_date            =>  ld_date);
        LOOP
	        l_rtv_hdr_dy_tab.DELETE;  --- Deleting the data in the Table type
            FETCH rtv_hdr_dy_details BULK COLLECT INTO l_rtv_hdr_dy_tab;
            EXIT WHEN l_rtv_hdr_dy_tab.COUNT = 0;

		    ln_total_records_processed := ln_total_records_processed + l_rtv_hdr_dy_tab.COUNT;
		    FOR indx IN l_rtv_hdr_dy_tab.FIRST..l_rtv_hdr_dy_tab.LAST
            LOOP
		    BEGIN

		     /* Process the Line details */
		        OPEN rtv_line_dy_details( p_header_id      =>  l_rtv_hdr_dy_tab(indx).header_id
				                         ,p_frequency_code =>  l_rtv_hdr_dy_tab(indx).frequency_code
									    );
                LOOP
	                l_rtv_lines_dy_tab.DELETE;  --- Deleting the data in the Table type
                    FETCH rtv_line_dy_details BULK COLLECT INTO l_rtv_lines_dy_tab LIMIT ln_batch_size;
                    EXIT WHEN l_rtv_lines_dy_tab.COUNT = 0;

		            FOR l_indx IN l_rtv_lines_dy_tab.FIRST..l_rtv_lines_dy_tab.LAST
                    LOOP
                    BEGIN
					-- To handle the Return Code = '74' Scenario
                    IF l_rtv_hdr_dy_tab(indx).return_code = '74'
		            THEN
                   	    l_rtv_lines_dy_tab(l_indx).record_status := 'C';
		        	    l_rtv_lines_dy_tab(l_indx).error_description := 'Excluding the record for the Return Code 74' ;
                        CONTINUE;
                    END IF;
                        IF l_rtv_hdr_dy_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
			            THEN
				            get_item_details(p_sku                => l_rtv_lines_dy_tab(l_indx).sku
						                    ,p_location           => LTRIM(l_rtv_lines_dy_tab(l_indx).location,'0')
						                    ,o_inventory_item_id  => ln_inventory_item_id
                                            ,o_organization_id    => ln_organization_id
                                            ,o_uom_code           => lc_uom_code
						                    );

							-- To get the Freight Bill Number and Freight Carrier
							/*
							BEGIN
							    SELECT freight_bill_num1 ||DECODE(freight_bill_num1, NULL,NULL,',')||
                                       freight_bill_num2 ||DECODE(freight_bill_num2, NULL,NULL,',')||
                                       freight_bill_num3 ||DECODE(freight_bill_num3, NULL,NULL,',')||
                                       freight_bill_num4 ||DECODE(freight_bill_num4, NULL,NULL,',')||
                                       freight_bill_num5 ||DECODE(freight_bill_num5, NULL,NULL,',')||
                                       freight_bill_num6 ||DECODE(freight_bill_num6, NULL,NULL,',')||
                                       freight_bill_num7 ||DECODE(freight_bill_num7, NULL,NULL,',')||
                                       freight_bill_num8 ||DECODE(freight_bill_num8, NULL,NULL,',')||
                                       freight_bill_num9 ||DECODE(freight_bill_num9, NULL,NULL,',')||
                                       freight_bill_num10,
                                       carrier_name
                                 INTO  lc_freight_bill_num,
                                       lc_freight_carrier
                                 FROM  xx_ap_rtv_hdr_attr
                                WHERE  rtv_number = l_rtv_lines_dy_tab(l_indx).rtv_number;
							EXCEPTION
							WHEN OTHERS
							THEN
							    lc_freight_bill_num := NULL;
								lc_freight_carrier  := NULL;
							END;
							*/
							BEGIN
							    SELECT freight_bill_num1
                                       || NVL2(freight_bill_num2, NVL2(freight_bill_num1,',',NULL)||freight_bill_num2, NULL)
			                           || NVL2(freight_bill_num3, ','||freight_bill_num3, NULL)
			                           || NVL2(freight_bill_num4, ','||freight_bill_num4, NULL)
                                       || NVL2(freight_bill_num5, ','||freight_bill_num5, NULL)
                                       || NVL2(freight_bill_num6, ','||freight_bill_num6, NULL)
                                       || NVL2(freight_bill_num7, ','||freight_bill_num7, NULL)
                                       || NVL2(freight_bill_num8, ','||freight_bill_num8, NULL)
                                       || NVL2(freight_bill_num9, ','||freight_bill_num9, NULL)
                                       || NVL2(freight_bill_num10, ','||freight_bill_num10, NULL),
                                       carrier_name
                                 INTO  lc_freight_bill_num,
                                       lc_freight_carrier
                                 FROM  xx_ap_rtv_hdr_attr
                                WHERE  rtv_number = l_rtv_lines_dy_tab(l_indx).rtv_number;
							EXCEPTION
							WHEN OTHERS
							THEN
							    lc_freight_bill_num := NULL;
								lc_freight_carrier  := NULL;
							END;

							-- Below code logic added for Defect# 45221 NAIT-40778
							BEGIN
								SELECT l_rtv_lines_dy_tab(l_indx).rtv_date INTO ln_rtv_date
								FROM org_acct_periods WHERE l_rtv_lines_dy_tab(l_indx).rtv_date
								BETWEEN period_start_date AND schedule_close_date
								AND organization_id = ln_organization_id
								AND open_flag = 'Y';
							EXCEPTION
							WHEN OTHERS THEN
							  BEGIN
						        SELECT period_start_date INTO ln_rtv_date
								FROM org_acct_periods WHERE 1 = 1
								AND organization_id = ln_organization_id
								AND open_flag = 'Y'
								AND rownum = 1;
							  EXCEPTION
							  WHEN OTHERS THEN
							     ln_rtv_date := sysdate;
							  END;
							END;


					  -- Calling the mtl_transaction_int procedure
					        xx_po_rcv_int_pkg.mtl_transaction_int(p_errbuf       		       => lc_error_msg
                      	                                         ,p_retcode      		       => lc_retcode
			                                                     ,p_transaction_type_name      => 'Miscellaneous issue'
			                                                     ,p_inventory_item_id	       => ln_inventory_item_id
			                                                     ,p_organization_id		       => ln_organization_id
			                                                     ,p_transaction_qty		       => -TO_NUMBER(l_rtv_lines_dy_tab(l_indx).qty)
			                                                     ,p_transaction_cost	       => TO_NUMBER(l_rtv_lines_dy_tab(l_indx).cost)
			                                                     ,p_transaction_uom_code       => lc_uom_code
			                                                     ,p_transaction_date	       => ln_rtv_date---l_rtv_lines_dy_tab(l_indx).rtv_date -- SYSDATE
																 -- Modified ln_rtv_date for Defect# 45221 NAIT-40778
			                                                     ,p_subinventory_code	       => 'STOCK'
			                                                     ,p_transaction_source	       => 'OD CONSIGNMENT RTV'
																 ,p_vendor_site                => '0'||l_rtv_hdr_dy_tab(indx).vendor_num
																 ,p_original_rtv               => l_rtv_lines_dy_tab(l_indx).rtv_number
																 ,p_rga_number                 => l_rtv_lines_dy_tab(l_indx).rga_number
																 ,p_freight_carrier            => lc_freight_carrier
																 ,p_freight_bill               => lc_freight_bill_num
																 ,p_vendor_prod_code           => l_rtv_lines_dy_tab(l_indx).vendor_product_code
																 ,p_sku                        => l_rtv_lines_dy_tab(l_indx).sku
																 ,p_location                   => LTRIM(l_rtv_lines_dy_tab(l_indx).location,'0')
																 );
						    IF lc_retcode = '2'
						    THEN
						        l_rtv_lines_dy_tab(l_indx).record_status := 'E';
				                l_rtv_lines_dy_tab(l_indx).error_description := 'Unable to insert the record in the mtl_transactions_interface table for the Miscellaneous issue for the Consignment Supplier';
                                CONTINUE;
                            ELSE
                                l_rtv_lines_dy_tab(l_indx).record_status := 'C';
				                l_rtv_lines_dy_tab(l_indx).error_description :=  'Processed the record for the Miscellaneous issue for the Consignment Supplier';
							    CONTINUE;
                            END IF;
				        ELSE
                            -- To derive the Description and Invoice Number
                            IF l_rtv_hdr_dy_tab(indx).return_code <> '73'
		                    THEN
                                lc_invoice_number := 'RTV'||l_rtv_hdr_dy_tab(indx).rtv_number;
				               	lc_description    := 'ST0'||l_rtv_hdr_dy_tab(indx).location||' RGA#'||l_rtv_lines_dy_tab(l_indx).rga_number;
                            END IF;

				            -- To get the GL String
				            get_rtv_gl_string (o_gl_company            => lc_gl_company
						                      ,o_gl_cost_center        => lc_gl_cost_center
                                              ,o_gl_account            => lc_gl_account
						                      ,o_gl_location           => lc_gl_location
						                      ,o_gl_inter_company      => lc_gl_inter_company
						                      ,o_gl_lob                => lc_gl_lob
						                      ,o_gl_future             => lc_gl_future
						                      );
				            INSERT
		                       INTO xx_ap_trade_inv_lines
		                           (invoice_line_id
		                           ,invoice_id
		                           ,record_type
		                           ,ap_company
		                           ,ap_vendor_1
		                           ,ap_vendor
		                           ,voucher
		                           ,invoice_number
		                           ,line_number
		                           ,line_type
		                           ,mdse_amount
		                           ,mdse_amount_sign
		                           ,charge_back
		                           ,gl_company
		                           ,gl_location
		                           ,gl_cost_center
		                           ,gl_lob
		                           ,gl_account
		                           ,gl_inter_company
		                           ,gl_future
		                           ,line_description
		                           ,sku
		                           ,cost
		                           ,cost_sign
		                           ,quantity
		                           ,quantity_sign
		                           ,source
		                           ,invoice_date
		                           ,location_number
		                           ,frequency_code
		                           ,reason_code
		                           ,reason_code_desc
		                           ,po_number
		                           ,po_line_number
		                           ,record_status
		                           ,error_description
		                           ,request_id
		                           ,created_by
		                           ,creation_date
		                           ,last_updated_by
		                           ,last_update_date
		                           ,last_update_login)
		                        VALUES
						           (l_rtv_lines_dy_tab(l_indx).line_id
                                   ,l_rtv_lines_dy_tab(l_indx).header_id
                                   ,l_rtv_lines_dy_tab(l_indx).record_type
		                           ,l_rtv_lines_dy_tab(l_indx).company
		                           ,NULL
		                           ,l_rtv_hdr_dy_tab(indx).vendor_num
		                           ,NULL
		                           ,lc_invoice_number
		                           ,NULL
		                           ,'ITEM'
		                           ,- l_rtv_lines_dy_tab(l_indx).line_amount
		                           ,'-'
		                           ,NULL
		                           ,lc_gl_company
		                           ,lc_gl_location
		                           ,lc_gl_cost_center
		                           ,lc_gl_lob
		                           ,lc_gl_account
		                           ,lc_gl_inter_company
		                           ,lc_gl_future
		                           ,l_rtv_lines_dy_tab(l_indx).item_description
		                           ,l_rtv_lines_dy_tab(l_indx).sku
		                           ,l_rtv_lines_dy_tab(l_indx).cost
		                           ,'-'
		                           ,l_rtv_lines_dy_tab(l_indx).qty
		                           ,'-'
		                           ,'US_OD_RTV_MERCHANDISING'
		                           ,SYSDATE
		                           ,l_rtv_hdr_dy_tab(indx).location
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,'N'
		                           ,NULL
		                           ,gn_request_id
	                               ,gn_user_id
	                               ,ld_date
	                               ,gn_user_id
	                               ,sysdate
	                               ,gn_login_id
						           );

						        l_rtv_lines_dy_tab(l_indx).record_status := 'C';
				                l_rtv_lines_dy_tab(l_indx).error_description := NULL;
								l_rtv_lines_dy_tab(l_indx).invoice_num := lc_invoice_number;

			            END IF; -- l_rtv_hdr_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
			        EXCEPTION
			        WHEN OTHERS
			        THEN
                        lc_error_msg := SUBSTR(sqlerrm,1,100);
                        print_debug_msg ('line_id=['||to_char(l_rtv_lines_dy_tab(l_indx).line_id)||'], RB, '||lc_error_msg,FALSE);
                        l_rtv_lines_dy_tab(l_indx).record_status := 'E';
                        l_rtv_lines_dy_tab(l_indx).error_description :='Unable to insert the record into xx_ap_trade_inv_lines table for the line_id :'||l_rtv_lines_dy_tab(l_indx).line_id||' '||lc_error_msg;
						ROLLBACK;
			        END;
                    END LOOP; --l_rtv_lines_dy_tab

                    BEGIN
	                    print_debug_msg('Starting update of xx_ap_rtv_lines_attr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	            FORALL l_indx IN 1..l_rtv_lines_dy_tab.COUNT
	       	            SAVE EXCEPTIONS

   		                    UPDATE xx_ap_rtv_lines_attr
	       	                   SET record_status = l_rtv_lines_dy_tab(l_indx).record_status
	       	                      ,error_description = l_rtv_lines_dy_tab(l_indx).error_description
								  ,invoice_num = l_rtv_lines_dy_tab(l_indx).invoice_num
	     	                      ,last_update_date  = sysdate
	                              ,last_updated_by   = gn_user_id
	                              ,last_update_login = gn_login_id
	       	                 WHERE line_id  = l_rtv_lines_dy_tab(l_indx).line_id;

			                COMMIT;
	                EXCEPTION
	                WHEN OTHERS
			        THEN
	                    print_debug_msg('Bulk Exception raised',FALSE);
	                    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	                    FOR i IN 1..ln_err_count
	                    LOOP
	                        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                        lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                        print_debug_msg('Invoice_line_id=['||to_char(l_rtv_lines_dy_tab(ln_error_idx).line_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	                    END LOOP; -- bulk_err_loop FOR UPDATE
	                END;
	                print_debug_msg('Ending Update of xx_ap_rtv_lines_attr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

                END LOOP; --rtv_line_dy_details
                COMMIT;
                CLOSE rtv_line_dy_details; -- End of line Details

		        print_debug_msg ('Insert into xx_ap_inv_interface_stg - header_id=['||to_char(l_rtv_hdr_dy_tab(indx).header_id)||']',FALSE);

				-- To handle the Return Code = '74' Scenario
                IF l_rtv_hdr_dy_tab(indx).return_code = '74'
		        THEN
                   	l_rtv_hdr_dy_tab(indx).record_status := 'C';
		        	l_rtv_hdr_dy_tab(indx).error_description := 'Excluding the record for the Return Code 74' ;
                    CONTINUE;
                END IF;

                IF l_rtv_hdr_dy_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
		        THEN
                   	l_rtv_hdr_dy_tab(indx).record_status := 'C';
		        	l_rtv_hdr_dy_tab(indx).error_description := 'Processed the record for the Miscellaneous issue for the Consignment Supplier';
                    CONTINUE;
                END IF;

                -- Inserting the records into the header table
                OPEN  rtv_hdr_amount(l_rtv_hdr_dy_tab(indx).header_id);
                FETCH rtv_hdr_amount INTO lc_hdr_amount;
                CLOSE rtv_hdr_amount;

		        INSERT
                  INTO xx_ap_trade_inv_hdr
                       (invoice_id
	                   ,record_type
	                   ,ap_company
	                   ,ap_vendor_1
	                   ,ap_vendor
	                   ,voucher
	                   ,invoice_number
	                   ,source
	                   ,voucher_type
	                   ,invoice_date
	                   ,gross_amt
	                   ,gross_amt_sign
	                   ,discount_amt
	                   ,discount_amt_sign
	                   ,default_po
	                   ,location_id
	                   ,terms_date
	                   ,terms_id
	                   ,terms_name
	                   ,discount_date
	                   ,check_description
	                   ,dcn_number
	                   ,pay_group
	                   ,payment_method_lookup_code
	                   ,ap_liab_acct
					   ,return_code
					   ,return_code_desc
					   ,frequency_code
	                   ,record_status
	                   ,error_description
	                   ,request_id
	                   ,created_by
	                   ,creation_date
	                   ,last_updated_by
	                   ,last_update_date
	                   ,last_update_login)
                    VALUES
                       (l_rtv_hdr_dy_tab(indx).header_id
			           ,l_rtv_hdr_dy_tab(indx).record_type
	                   ,NULL
	                   ,NULL
	                   ,l_rtv_hdr_dy_tab(indx).vendor_num
	                   ,NULL
	                   ,lc_invoice_number
	                   ,'US_OD_RTV_MERCHANDISING'
	                   ,'3'
	                   ,SYSDATE
	                   ,-TO_NUMBER(lc_hdr_amount)
	                   ,'-'
	                   ,NULL
	                   ,NULL
	                   ,NULL
	                   ,l_rtv_hdr_dy_tab(indx).location
	                   ,NULL
	                   ,NULL
	                   ,'00' -- Terms Name
	                   ,NULL
	                   ,lc_description
	                   ,NULL
	                   ,l_rtv_hdr_dy_tab(indx).pay_group_lookup_code
	                   ,l_rtv_hdr_dy_tab(indx).payment_method_lookup_code
	                   ,NULL
					   ,l_rtv_hdr_dy_tab(indx).return_code
					   ,NULL
					   ,l_rtv_hdr_dy_tab(indx).frequency_code
	                   ,'N'
	                   ,NULL
	                   ,gn_request_id
	                   ,gn_user_id
	                   ,ld_date
	                   ,gn_user_id
	                   ,sysdate
	                   ,gn_login_id);
			        ln_success_records  := ln_success_records + 1;

				    l_rtv_hdr_dy_tab(indx).record_status := 'C';
				    l_rtv_hdr_dy_tab(indx).error_description := NULL;
					l_rtv_hdr_dy_tab(indx).invoice_num := lc_invoice_number;
					l_rtv_hdr_dy_tab(indx).header_id := l_rtv_hdr_dy_tab(indx).header_id;

            EXCEPTION
			WHEN OTHERS
			THEN
			    ROLLBACK;
				ln_failed_records := ln_failed_records +1;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
                print_debug_msg ('Invoice_id=['||to_char(l_rtv_hdr_dy_tab(indx).header_id)||'], RB, '||lc_error_msg,FALSE);
                l_rtv_hdr_dy_tab(indx).record_status := 'E';
                l_rtv_hdr_dy_tab(indx).error_description :='Unable to insert the record into xx_ap_trade_inv_hdr table for the header_id :'||l_rtv_hdr_dy_tab(indx).header_id||' '||lc_error_msg;
			END;
            END LOOP; --l_rtv_hdr_dy_tab

            BEGIN
	            print_debug_msg('Starting update of xx_ap_rtv_hdr_attr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	   FORALL indx IN 1..l_rtv_hdr_dy_tab.COUNT
	       	    SAVE EXCEPTIONS
   		        UPDATE xx_ap_rtv_hdr_attr
	       		   SET record_status = l_rtv_hdr_dy_tab(indx).record_status
	       		      ,error_description = l_rtv_hdr_dy_tab(indx).error_description
					  ,header_id = l_rtv_hdr_dy_tab(indx).header_id
					  ,invoice_num = l_rtv_hdr_dy_tab(indx).invoice_num
	     		      ,last_update_date  = sysdate
	                  ,last_updated_by   = gn_user_id
	                  ,last_update_login = gn_login_id
	       	     WHERE record_status = 'N'
				   AND header_id = l_rtv_hdr_dy_tab(indx).header_id
				        AND frequency_code = 'DY';

				COMMIT;
	        EXCEPTION
	        WHEN OTHERS
			THEN
	            print_debug_msg('Bulk Exception raised',FALSE);
	            ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	            FOR i IN 1..ln_err_count
	            LOOP
	               ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	               lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	               print_debug_msg('Invoice_id=['||to_char(l_rtv_hdr_dy_tab(ln_error_idx).header_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	            END LOOP; -- bulk_err_loop FOR UPDATE
	        END;
	        print_debug_msg('Ending Update of xx_ap_rtv_hdr_attr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

        END LOOP; --rtv_hdr_dy_details
        COMMIT;
        CLOSE rtv_hdr_dy_details;

	ELSE

	    OPEN rtv_hdr_wy_details( p_weekly          =>  lc_weekly
	                            ,p_monthly         =>  lc_monthly
                                ,p_quarterly       =>  lc_quarterly
							    ,p_wy_from_date    =>  ld_wy_from_date
							    ,p_wy_to_date      =>  ld_wy_to_date
							    ,p_my_start_date   =>  ld_my_start_date
							    ,p_my_end_date     =>  ld_my_end_date
							    ,p_qy_start_date   =>  ld_qy_start_date
							    ,p_qy_end_date     =>  ld_qy_end_date
								,p_frequency_code  =>  p_frequency_code
						      );
        LOOP
	        l_rtv_hdr_wy_tab.DELETE;  --- Deleting the data in the Table type
            FETCH rtv_hdr_wy_details BULK COLLECT INTO l_rtv_hdr_wy_tab;
            EXIT WHEN l_rtv_hdr_wy_tab.COUNT = 0;

		    ln_total_records_processed := ln_total_records_processed + l_rtv_hdr_wy_tab.COUNT;
		    FOR indx IN l_rtv_hdr_wy_tab.FIRST..l_rtv_hdr_wy_tab.LAST
            LOOP
		    BEGIN
                IF 	l_rtv_hdr_wy_tab(indx).return_code = '73'
                THEN
                    ln_header_id  := ap_invoices_interface_s.NEXTVAL;
                END IF;

		     /* Process the Line details */
		        OPEN rtv_line_wy_details( p_weekly          =>  lc_weekly
	                                     ,p_monthly         =>  lc_monthly
                                         ,p_quarterly       =>  lc_quarterly
							             ,p_wy_from_date    =>  ld_wy_from_date
							             ,p_wy_to_date      =>  ld_wy_to_date
							             ,p_my_start_date   =>  ld_my_start_date
							             ,p_my_end_date     =>  ld_my_end_date
							             ,p_qy_start_date   =>  ld_qy_start_date
							             ,p_qy_end_date     =>  ld_qy_end_date
									     ,p_vendor_num      =>  l_rtv_hdr_wy_tab(indx).vendor_num
									     ,p_frequency_code  =>  p_frequency_code
									    );
                LOOP
	                l_rtv_lines_wy_tab.DELETE;  --- Deleting the data in the Table type
                    FETCH rtv_line_wy_details BULK COLLECT INTO l_rtv_lines_wy_tab LIMIT ln_batch_size;
                    EXIT WHEN l_rtv_lines_wy_tab.COUNT = 0;

		            FOR l_indx IN l_rtv_lines_wy_tab.FIRST..l_rtv_lines_wy_tab.LAST
                    LOOP
                    BEGIN
					-- To handle the Return Code = '74' Scenario
                    IF l_rtv_hdr_wy_tab(indx).return_code = '74'
		            THEN
                   	    l_rtv_hdr_wy_tab(l_indx).record_status := 'C';
		        	    l_rtv_hdr_wy_tab(l_indx).error_description := 'Excluding the record for the Return Code 74' ;
                        CONTINUE;
                    END IF;

                        IF l_rtv_hdr_wy_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
			            THEN
				            get_item_details(p_sku                => l_rtv_lines_wy_tab(l_indx).sku
						                    ,p_location           => LTRIM(l_rtv_lines_wy_tab(l_indx).location,'0')
						                    ,o_inventory_item_id  => ln_inventory_item_id
                                            ,o_organization_id    => ln_organization_id
                                            ,o_uom_code           => lc_uom_code
						                    );

                            -- To get the Freight Bill Number and Freight Carrier
                            /*
							BEGIN
							    SELECT freight_bill_num1 ||DECODE(freight_bill_num1, NULL,NULL,',')||
                                       freight_bill_num2 ||DECODE(freight_bill_num2, NULL,NULL,',')||
                                       freight_bill_num3 ||DECODE(freight_bill_num3, NULL,NULL,',')||
                                       freight_bill_num4 ||DECODE(freight_bill_num4, NULL,NULL,',')||
                                       freight_bill_num5 ||DECODE(freight_bill_num5, NULL,NULL,',')||
                                       freight_bill_num6 ||DECODE(freight_bill_num6, NULL,NULL,',')||
                                       freight_bill_num7 ||DECODE(freight_bill_num7, NULL,NULL,',')||
                                       freight_bill_num8 ||DECODE(freight_bill_num8, NULL,NULL,',')||
                                       freight_bill_num9 ||DECODE(freight_bill_num9, NULL,NULL,',')||
                                       freight_bill_num10,
                                       carrier_name
                                 INTO  lc_freight_bill_num,
                                       lc_freight_carrier
                                 FROM  xx_ap_rtv_hdr_attr
                                WHERE  rtv_number = l_rtv_lines_wy_tab(l_indx).rtv_number;
							EXCEPTION
							WHEN OTHERS
							THEN
							    lc_freight_bill_num := NULL;
								lc_freight_carrier  := NULL;
							END;
							*/

							BEGIN
							    SELECT freight_bill_num1
                                       || NVL2(freight_bill_num2, NVL2(freight_bill_num1,',',NULL)||freight_bill_num2, NULL)
			                           || NVL2(freight_bill_num3, ','||freight_bill_num3, NULL)
			                           || NVL2(freight_bill_num4, ','||freight_bill_num4, NULL)
                                       || NVL2(freight_bill_num5, ','||freight_bill_num5, NULL)
                                       || NVL2(freight_bill_num6, ','||freight_bill_num6, NULL)
                                       || NVL2(freight_bill_num7, ','||freight_bill_num7, NULL)
                                       || NVL2(freight_bill_num8, ','||freight_bill_num8, NULL)
                                       || NVL2(freight_bill_num9, ','||freight_bill_num9, NULL)
                                       || NVL2(freight_bill_num10, ','||freight_bill_num10, NULL),
                                       carrier_name
                                 INTO  lc_freight_bill_num,
                                       lc_freight_carrier
                                 FROM  xx_ap_rtv_hdr_attr
                                WHERE  rtv_number = l_rtv_lines_wy_tab(l_indx).rtv_number;
							EXCEPTION
							WHEN OTHERS
							THEN
							    lc_freight_bill_num := NULL;
								lc_freight_carrier  := NULL;
							END;

							-- Below code logic added for Defect# 45221 NAIT-40778
							BEGIN
								SELECT l_rtv_lines_wy_tab(l_indx).rtv_date INTO ln_rtv_date
								FROM org_acct_periods WHERE l_rtv_lines_wy_tab(l_indx).rtv_date
								BETWEEN period_start_date AND schedule_close_date
								AND organization_id = ln_organization_id
								AND open_flag = 'Y';
							EXCEPTION
							WHEN OTHERS THEN
							  BEGIN
						        SELECT period_start_date INTO ln_rtv_date
								FROM org_acct_periods WHERE 1 = 1
								AND organization_id = ln_organization_id
								AND open_flag = 'Y'
								AND rownum = 1;
							  EXCEPTION
							  WHEN OTHERS THEN
							     ln_rtv_date := sysdate;
							  END;
							END;

					  -- Calling the mtl_transaction_int procedure

					        xx_po_rcv_int_pkg.mtl_transaction_int(p_errbuf       		       => lc_error_msg
                      	                                         ,p_retcode      		       => lc_retcode
			                                                     ,p_transaction_type_name      => 'Miscellaneous issue'
			                                                     ,p_inventory_item_id	       => ln_inventory_item_id
			                                                     ,p_organization_id		       => ln_organization_id
			                                                     ,p_transaction_qty		       => -TO_NUMBER(l_rtv_lines_wy_tab(l_indx).qty)
			                                                     ,p_transaction_cost	       => TO_NUMBER(l_rtv_lines_wy_tab(l_indx).cost)
			                                                     ,p_transaction_uom_code       => lc_uom_code
			                                                     ,p_transaction_date	       => ln_rtv_date--l_rtv_lines_wy_tab(l_indx).rtv_date -- SYSDATE
																 -- Added ln_rtv_date for Defect# 45221 NAIT-40778
			                                                     ,p_subinventory_code	       => 'STOCK'
			                                                     ,p_transaction_source	       => 'OD CONSIGNMENT RTV'
																 ,p_vendor_site                => '0'||l_rtv_hdr_wy_tab(indx).vendor_num
																 ,p_original_rtv               => l_rtv_lines_wy_tab(l_indx).rtv_number
																 ,p_rga_number                 => l_rtv_lines_wy_tab(l_indx).rga_number
																 ,p_freight_carrier            => lc_freight_carrier
																 ,p_freight_bill               => lc_freight_bill_num
																 ,p_vendor_prod_code           => l_rtv_lines_wy_tab(l_indx).vendor_product_code
																 ,p_sku                        => l_rtv_lines_wy_tab(l_indx).sku
																 ,p_location                   => LTRIM(l_rtv_lines_wy_tab(l_indx).location,'0')
																 );

						    IF lc_retcode = '2'
						    THEN
						        l_rtv_lines_wy_tab(l_indx).record_status := 'E';
				                l_rtv_lines_wy_tab(l_indx).error_description := 'Unable to insert the record in the mtl_transactions_interface table for the Miscellaneous issue for the Consignment Supplier';
                                CONTINUE;
                            ELSE
                                l_rtv_lines_wy_tab(l_indx).record_status := 'C';
				                l_rtv_lines_wy_tab(l_indx).error_description :=  'Processed the record for the Miscellaneous issue for the Consignment Supplier';
							    CONTINUE;
                            END IF;
				        ELSE
                            -- To derive the Description and Invoice Number
                            IF l_rtv_hdr_wy_tab(indx).return_code = '73'
		                    THEN
                                IF lc_vendor_num <> l_rtv_hdr_wy_tab(indx).vendor_num
                                THEN
		            	            ln_sequence_number := ln_sequence_number+1;
									lc_vendor_num := l_rtv_hdr_wy_tab(indx).vendor_num;
		            	        ELSE
		            	            ln_sequence_number := ln_sequence_number;
		            	        END IF;

								IF p_frequency_code = 'QY'
								THEN
				                   lc_invoice_number := 'RTV73'||to_char(NVL(ld_qy_end_date,SYSDATE),'MMDDYY')||to_char(LPAD(ln_sequence_number,6,0));
								ELSIF p_frequency_code = 'MY'
								THEN
								    lc_invoice_number := 'RTV73'||to_char(NVL(ld_my_end_date,SYSDATE),'MMDDYY')||to_char(LPAD(ln_sequence_number,6,0));
								ELSIF p_frequency_code = 'WY'
								THEN
								    lc_invoice_number := 'RTV73'||to_char(NVL(ld_wy_to_date,SYSDATE),'MMDDYY')||to_char(LPAD(ln_sequence_number,6,0));
								END IF;

				               	IF l_rtv_hdr_wy_tab(indx).frequency_code = 'WY'
				               	THEN
				               	    lc_description    := 'WEEKLY DESTROYED MERC SUMMARY';
				               	ELSIF l_rtv_hdr_wy_tab(indx).frequency_code = 'MY'
				               	THEN
				               	    lc_description    := 'MONTHLY DESTROYED MERC SUMMARY';
				               	ELSIF l_rtv_hdr_wy_tab(indx).frequency_code = 'QY'
				               	THEN
				               	    lc_description    := 'QUARTERLY DESTROYED MERC SUMMARY';
				               	END IF;
                            END IF;	-- l_rtv_hdr_wy_tab(indx).return_code = '73'

				            -- To get the GL String
				            get_rtv_gl_string (o_gl_company            => lc_gl_company
						                      ,o_gl_cost_center        => lc_gl_cost_center
                                              ,o_gl_account            => lc_gl_account
						                      ,o_gl_location           => lc_gl_location
						                      ,o_gl_inter_company      => lc_gl_inter_company
						                      ,o_gl_lob                => lc_gl_lob
						                      ,o_gl_future             => lc_gl_future
						                      );
				            INSERT
		                       INTO xx_ap_trade_inv_lines
		                           (invoice_line_id
		                           ,invoice_id
		                           ,record_type
		                           ,ap_company
		                           ,ap_vendor_1
		                           ,ap_vendor
		                           ,voucher
		                           ,invoice_number
		                           ,line_number
		                           ,line_type
		                           ,mdse_amount
		                           ,mdse_amount_sign
		                           ,charge_back
		                           ,gl_company
		                           ,gl_location
		                           ,gl_cost_center
		                           ,gl_lob
		                           ,gl_account
		                           ,gl_inter_company
		                           ,gl_future
		                           ,line_description
		                           ,sku
		                           ,cost
		                           ,cost_sign
		                           ,quantity
		                           ,quantity_sign
		                           ,source
		                           ,invoice_date
		                           ,location_number
		                           ,frequency_code
		                           ,reason_code
		                           ,reason_code_desc
		                           ,po_number
		                           ,po_line_number
		                           ,record_status
		                           ,error_description
		                           ,request_id
		                           ,created_by
		                           ,creation_date
		                           ,last_updated_by
		                           ,last_update_date
		                           ,last_update_login)
		                        VALUES
						           (l_rtv_lines_wy_tab(l_indx).line_id
                                   ,ln_header_id
                                   ,l_rtv_lines_wy_tab(l_indx).record_type
		                           ,l_rtv_lines_wy_tab(l_indx).company
		                           ,NULL
		                           ,l_rtv_hdr_wy_tab(indx).vendor_num
		                           ,NULL
		                           ,lc_invoice_number
		                           ,NULL
		                           ,'ITEM'
		                           ,-l_rtv_lines_wy_tab(l_indx).line_amount
		                           ,'-'
		                           ,NULL
		                           ,lc_gl_company
		                           ,lc_gl_location
		                           ,lc_gl_cost_center
		                           ,lc_gl_lob
		                           ,lc_gl_account
		                           ,lc_gl_inter_company
		                           ,lc_gl_future
		                           ,l_rtv_lines_wy_tab(l_indx).item_description
		                           ,l_rtv_lines_wy_tab(l_indx).sku
		                           ,l_rtv_lines_wy_tab(l_indx).cost
		                           ,'-'
		                           ,l_rtv_lines_wy_tab(l_indx).qty
		                           ,'-'
		                           ,'US_OD_RTV_MERCHANDISING'
		                           ,SYSDATE
		                           ,l_rtv_hdr_wy_tab(indx).location
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,NULL
		                           ,'N'
		                           ,NULL
		                           ,gn_request_id
	                               ,gn_user_id
	                               ,sysdate
	                               ,gn_user_id
	                               ,sysdate
	                               ,gn_login_id
						           );

						        l_rtv_lines_wy_tab(l_indx).record_status := 'C';
				                l_rtv_lines_wy_tab(l_indx).error_description := NULL;
								l_rtv_lines_wy_tab(l_indx).header_id := ln_header_id;
								l_rtv_lines_wy_tab(l_indx).invoice_num := lc_invoice_number;

			            END IF; -- l_rtv_hdr_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
			        EXCEPTION
			        WHEN OTHERS
			        THEN
                        lc_error_msg := SUBSTR(sqlerrm,1,100);
                        print_debug_msg ('line_id=['||to_char(l_rtv_lines_wy_tab(l_indx).line_id)||'], RB, '||lc_error_msg,FALSE);
                        l_rtv_lines_wy_tab(l_indx).record_status := 'E';
                        l_rtv_lines_wy_tab(l_indx).error_description :='Unable to insert the record into xx_ap_rtv_lines_attr table for the line_id :'||l_rtv_lines_wy_tab(l_indx).line_id||' '||lc_error_msg;
						ROLLBACK;
			        END;
                    END LOOP; --l_rtv_lines_wy_tab

                    BEGIN
	                    print_debug_msg('Starting update of xx_ap_rtv_lines_attr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	            FORALL l_indx IN 1..l_rtv_lines_wy_tab.COUNT
	       	            SAVE EXCEPTIONS

   		                    UPDATE xx_ap_rtv_lines_attr
	       	                   SET record_status = l_rtv_lines_wy_tab(l_indx).record_status
	       	                      ,error_description = l_rtv_lines_wy_tab(l_indx).error_description
								  ,header_id = l_rtv_lines_wy_tab(l_indx).header_id
								  ,invoice_num = l_rtv_lines_wy_tab(l_indx).invoice_num
	     	                      ,last_update_date  = sysdate
	                              ,last_updated_by   = gn_user_id
	                              ,last_update_login = gn_login_id
	       	                 WHERE line_id  = l_rtv_lines_wy_tab(l_indx).line_id;

			                COMMIT;
	                EXCEPTION
	                WHEN OTHERS
			        THEN
	                    print_debug_msg('Bulk Exception raised',FALSE);
	                    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	                    FOR i IN 1..ln_err_count
	                    LOOP
	                        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                        lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                        print_debug_msg('Invoice_line_id=['||to_char(l_rtv_lines_wy_tab(ln_error_idx).line_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	                    END LOOP; -- bulk_err_loop FOR UPDATE
	                END;
	                print_debug_msg('Ending Update of xx_ap_rtv_lines_attr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

                END LOOP; --rtv_line_wy_details
                COMMIT;
                CLOSE rtv_line_wy_details; -- End of line Details

		        print_debug_msg ('Insert into xx_ap_inv_interface_stg - header_id=['||to_char(l_rtv_hdr_wy_tab(indx).header_id)||']',FALSE);

				-- To handle the Return Code = '74' Scenario
                IF l_rtv_hdr_wy_tab(indx).return_code = '74'
		        THEN
                   	l_rtv_hdr_wy_tab(indx).record_status := 'C';
		        	l_rtv_hdr_wy_tab(indx).error_description := 'Excluding the record for the Return Code 74' ;
                    CONTINUE;
                END IF;

                IF l_rtv_hdr_wy_tab(indx).supplier_attr_category IN ('TR-CON','TR-OMXCON')
		        THEN
                   	l_rtv_hdr_wy_tab(indx).record_status := 'C';
		        	l_rtv_hdr_wy_tab(indx).error_description := 'Processed the record for the Miscellaneous issue for the Consignment Supplier';
                    CONTINUE;
                END IF;

                -- Inserting the records into the header table
                OPEN  rtv_hdr_amount(ln_header_id);
                FETCH rtv_hdr_amount INTO lc_hdr_amount;
                CLOSE rtv_hdr_amount;

		        INSERT
                  INTO xx_ap_trade_inv_hdr
                       (invoice_id
	                   ,record_type
	                   ,ap_company
	                   ,ap_vendor_1
	                   ,ap_vendor
	                   ,voucher
	                   ,invoice_number
	                   ,source
	                   ,voucher_type
	                   ,invoice_date
	                   ,gross_amt
	                   ,gross_amt_sign
	                   ,discount_amt
	                   ,discount_amt_sign
	                   ,default_po
	                   ,location_id
	                   ,terms_date
	                   ,terms_id
	                   ,terms_name
	                   ,discount_date
	                   ,check_description
	                   ,dcn_number
	                   ,pay_group
	                   ,payment_method_lookup_code
	                   ,ap_liab_acct
					   ,return_code
					   ,return_code_desc
					   ,frequency_code
	                   ,record_status
	                   ,error_description
	                   ,request_id
	                   ,created_by
	                   ,creation_date
	                   ,last_updated_by
	                   ,last_update_date
	                   ,last_update_login)
                    VALUES
                       (ln_header_id
			           ,l_rtv_hdr_wy_tab(indx).record_type
	                   ,NULL
	                   ,NULL
	                   ,l_rtv_hdr_wy_tab(indx).vendor_num
	                   ,NULL
	                   ,lc_invoice_number
	                   ,'US_OD_RTV_MERCHANDISING'
	                   ,'3'
	                   ,SYSDATE
	                   ,-TO_NUMBER(lc_hdr_amount)
	                   ,'-'
	                   ,NULL
	                   ,NULL
	                   ,NULL
	                   ,l_rtv_hdr_wy_tab(indx).location
	                   ,NULL
	                   ,NULL
	                   ,'00' -- Terms Name
	                   ,NULL
	                   ,lc_description
	                   ,NULL
	                   ,l_rtv_hdr_wy_tab(indx).pay_group_lookup_code
	                   ,l_rtv_hdr_wy_tab(indx).payment_method_lookup_code
	                   ,NULL
					   ,l_rtv_hdr_wy_tab(indx).return_code
					   ,NULL
					   ,l_rtv_hdr_wy_tab(indx).frequency_code
	                   ,'N'
	                   ,NULL
	                   ,gn_request_id
	                   ,gn_user_id
	                   ,sysdate
	                   ,gn_user_id
	                   ,sysdate
	                   ,gn_login_id);
			       -- COMMIT;
			        ln_success_records  := ln_success_records + 1;

				    l_rtv_hdr_wy_tab(indx).record_status := 'C';
				    l_rtv_hdr_wy_tab(indx).error_description := NULL;
					l_rtv_hdr_wy_tab(indx).invoice_num := lc_invoice_number;
					l_rtv_hdr_wy_tab(indx).header_id := ln_header_id;

            EXCEPTION
			WHEN OTHERS
			THEN
			    ROLLBACK;
				ln_failed_records := ln_failed_records +1;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
                print_debug_msg ('Invoice_id=['||to_char(l_rtv_hdr_wy_tab(indx).header_id)||'], RB, '||lc_error_msg,FALSE);
                l_rtv_hdr_wy_tab(indx).record_status := 'E';
                l_rtv_hdr_wy_tab(indx).error_description :='Unable to insert the record into xx_ap_rtv_hdr_attr table for the header_id :'||l_rtv_hdr_wy_tab(indx).header_id||' '||lc_error_msg;
			END;
            END LOOP; --l_rtv_hdr_wy_tab

            BEGIN
	            print_debug_msg('Starting update of xx_ap_rtv_hdr_attr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	   FORALL indx IN 1..l_rtv_hdr_wy_tab.COUNT
	       	    SAVE EXCEPTIONS
   		        UPDATE xx_ap_rtv_hdr_attr
	       		   SET record_status = l_rtv_hdr_wy_tab(indx).record_status
	       		      ,error_description = l_rtv_hdr_wy_tab(indx).error_description
					  ,header_id = l_rtv_hdr_wy_tab(indx).header_id
					  ,invoice_num = l_rtv_hdr_wy_tab(indx).invoice_num
	     		      ,last_update_date  = sysdate
	                  ,last_updated_by   = gn_user_id
	                  ,last_update_login = gn_login_id
	       	     WHERE record_status = 'N'
				   AND vendor_num  = l_rtv_hdr_wy_tab(indx).vendor_num
				       /*AND( (frequency_code = 'WY' AND (TRUNC(creation_date) BETWEEN TRUNC(ld_wy_from_date) AND TRUNC(ld_wy_to_date)) AND lc_weekly = 'Y')
				           OR(frequency_code = 'MY' AND (TRUNC(creation_date) BETWEEN TRUNC(ld_my_start_date) AND TRUNC(ld_my_end_date)) AND lc_monthly = 'Y')
				           OR(frequency_code = 'QY' AND (TRUNC(creation_date) BETWEEN TRUNC(ld_qy_start_date) AND TRUNC(ld_qy_end_date)) AND lc_quarterly = 'Y')
			               ) */
				   AND ((frequency_code = 'WY' AND creation_date BETWEEN to_date(to_char(ld_wy_from_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(ld_wy_to_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND lc_weekly = 'Y')
		              OR(frequency_code = 'MY' AND creation_date BETWEEN to_date(to_char(ld_my_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(ld_my_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND lc_monthly = 'Y')
				      OR(frequency_code = 'QY' AND creation_date BETWEEN to_date(to_char(ld_qy_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(ld_qy_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND lc_quarterly = 'Y')
			           )
						   ;

				COMMIT;
	        EXCEPTION
	        WHEN OTHERS
			THEN
	            print_debug_msg('Bulk Exception raised',FALSE);
	            ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	            FOR i IN 1..ln_err_count
	            LOOP
	               ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	               lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	               print_debug_msg('Invoice_id=['||to_char(l_rtv_hdr_wy_tab(ln_error_idx).header_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	            END LOOP; -- bulk_err_loop FOR UPDATE
	        END;
	        print_debug_msg('Ending Update of xx_ap_rtv_hdr_attr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

        END LOOP; --rtv_hdr_wy_details
        COMMIT;
        CLOSE rtv_hdr_wy_details;
	END IF;
	--========================================================================
		-- Updating the OUTPUT FILE
	--========================================================================
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed:: '||ln_total_records_processed);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully:: '||ln_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed:: '||ln_failed_records);

EXCEPTION
WHEN data_exception
THEN
    ROLLBACK;
    p_errcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    p_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_rtv_data - '||p_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_rtv_data',
	                lc_error_loc,
		            p_error_msg);
WHEN OTHERS
THEN
	p_errcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    p_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_rtv_data - '||p_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_rtv_data',
	                lc_error_loc,
		            p_error_msg);
END load_rtv_data;

/* Added as per Version 3.7 */
-- +===================================================================================================+
-- |  Name	 : update_cons_edi_invoices                                                                |
-- |  Description: This procedure is to update the consignment edi invoices to not processed in the    |
-- |               staging table                                                                       |
-- ====================================================================================================|
PROCEDURE update_cons_edi_invoices
AS
  CURSOR C1
  IS
    SELECT a.invoice_id,
           a.invoice_num,
           c.attribute8
      FROM xx_ap_inv_interface_stg a,
           po_headers_all b,
           ap_supplier_sites_all c
     WHERE a.status = 'CONS_REJECTED'
       AND a.source ='US_OD_TRADE_EDI'
       AND a.po_number = b.segment1
       AND b.vendor_site_id = c.vendor_site_id
	   AND c.attribute8 <> 'TR-CON'; -- 111

ln_cnt NUMBER := 0;
BEGIN
  print_debug_msg('Start processing all the Consignment EDI Processed Invoices in the POI',TRUE);

  FOR cons_cur IN C1
  LOOP
	    UPDATE xx_ap_inv_interface_stg
		   SET global_attribute16 = NULL,
		       status = NULL
	     WHERE invoice_id = cons_cur.invoice_id;

		 ln_cnt := ln_cnt + SQL%ROWCOUNT;
  END LOOP;

  print_debug_msg('Number of Consignment EDI Invoices updated :'||ln_cnt,TRUE);

EXCEPTION
  WHEN OTHERS
  THEN
     print_debug_msg('Error Message - Processing all the Consignment EDI Processed Invoices in the POI :'||SQLERRM,TRUE);
END update_cons_edi_invoices;

/* Added as per Version 2.6 */
-- +===================================================================================================+
-- |  Name	 : update_interface_lines_dtls                                                             |
-- |  Description: This procedure reads data from the PO base tables and update the Invoice interface  |
-- |               lines table with PO reference (PO Line Number)                                      |
-- ====================================================================================================|
PROCEDURE update_interface_lines_dtls
AS

CURSOR interface_hdr_details
  IS
     SELECT hdr.invoice_id,
            hdr.invoice_num,
			hdr.po_number,
            pha.attribute_category po_type,
		    pha.po_header_id,
            pha.vendor_site_id,
            hdr.attribute10,
            pha.terms_id,
            hdr.pay_group_lookup_code,
            hdr.payment_method_code,
            hdr.invoice_type_lookup_code,
            hdr.status
       FROM ap_invoices_interface hdr,
	        po_headers_all pha
      WHERE 1 =1
        AND hdr.status = 'REJECTED'
		AND ((hdr.source = 'US_OD_TRADE_EDI') OR (hdr.source = 'US_OD_DROPSHIP' AND hdr.attribute2 = 'Y'))
		AND hdr.po_number = pha.segment1;

CURSOR interface_lines_details(p_invoice_id IN NUMBER)
  IS
     SELECT lines.invoice_line_id,
            lines.line_type_lookup_code,
            lines.inventory_item_id,
			lines.unit_price,
			lines.quantity_invoiced quantity,
			lines.line_number inv_line_number,
			lines.amount,
            stg_lines.reason_code,
            stg_lines.sku,
            stg_lines.sac_code
       FROM ap_invoice_lines_interface lines,
            xx_ap_trade_inv_lines stg_lines
      WHERE 1 =1
        AND lines.invoice_id = p_invoice_id
		AND lines.invoice_line_id = stg_lines.invoice_line_id
	 -- ORDER BY inventory_item_id
	 ;

  TYPE details IS TABLE OF interface_lines_details%ROWTYPE
  INDEX BY PLS_INTEGER;

  l_detail_tab 		               DETAILS;
  indx                 	           NUMBER;
  ln_batch_size		               NUMBER := 250;
  ln_po_line_num                   NUMBER;
  lc_po_attr_category              VARCHAR2(100);
  ln_ccid                          NUMBER;
  ln_accrual_id                    NUMBER;
  ln_acct_id                       NUMBER;
  lc_gl_string                     VARCHAR2(100);
  lc_po_type                       VARCHAR2(100);
  lc_drop_ship_flag                VARCHAR2(30);
  lc_company                       VARCHAR2(100);
  lc_cost_center                   VARCHAR2(100);
  lc_account                       VARCHAR2(100);
  lc_location                      VARCHAR2(100);
  lc_lob                           VARCHAR2(100);
  lc_drop_ship_acct                VARCHAR2(100);
  lc_description                   VARCHAR2(100);
  ln_failed_records                NUMBER;
  lc_error_msg                     VARCHAR2(1000);
  ln_total_records_processed       NUMBER;
  lc_source                        VARCHAR2(50);
  lc_attr2                         VARCHAR2(1);
  ln_po_header_id                  NUMBER;
  lc_po_uom                        VARCHAR2(30);
  -- Added as per version 3.7
  ln_supp_terms_id                 NUMBER;
  lc_pay_group                     VARCHAR2(100);
  lc_payment_method_lookup_code    VARCHAR2(100);
  lc_supp_attr_category            VARCHAR2(100);
  lc_vendor_sites_kff_id	       NUMBER;
  lc_vendor_site_code              VARCHAR2(100);
  lc_attr3                         VARCHAR2(1);
  lc_sac_code_sign                 VARCHAR2(10);

BEGIN
  lc_attr3 := NULL;
  lc_sac_code_sign := NULL;
  print_debug_msg('Start processing all the Rejected Records in the POI',TRUE);

  FOR hdr_details IN interface_hdr_details
  LOOP
    -- Added as per version 3.7
	lc_vendor_site_code           := NULL;
	ln_supp_terms_id              := NULL;
	lc_pay_group                  := NULL;
	lc_payment_method_lookup_code := NULL;
	lc_supp_attr_category         := NULL;
	lc_vendor_sites_kff_id	      := NULL;

    print_debug_msg('Invoice Number :'||hdr_details.invoice_num,TRUE);

	IF hdr_details.po_type LIKE 'DropShip%'
	THEN
		lc_source := 'US_OD_DROPSHIP';
		lc_attr2 := 'Y';
	ELSE
		lc_source := 'US_OD_TRADE_EDI';
		lc_attr2 := NULL;
	END IF;

	-- Added as per version 3.7
	-- To derive the Supplier Site Code
	BEGIN
	     SELECT vendor_site_code_alt
		   INTO lc_vendor_site_code
		   FROM ap_supplier_sites_all
		  WHERE vendor_site_id = hdr_details.vendor_site_id;
	EXCEPTION
	WHEN OTHERS
	THEN
	    lc_vendor_site_code := hdr_details.attribute10;
	END;

	-- To get the Supplier Information
	get_supplier_info (p_vendor                  => lc_vendor_site_code
					  ,o_terms_id                => ln_supp_terms_id
					  ,o_pay_group_lookup_code   => lc_pay_group
                      ,o_pymt_method_lookup_code => lc_payment_method_lookup_code
                      ,o_supp_attr_category      => lc_supp_attr_category
                      ,o_vendor_sites_kff_id     => lc_vendor_sites_kff_id
					   );

    -- To derive the term_id
	IF hdr_details.invoice_type_lookup_code <> 'STANDARD'
	THEN
	    BEGIN
		  SELECT term_id
		    INTO hdr_details.terms_id
            FROM ap_terms_tl
           WHERE name= '00';
		EXCEPTION
		WHEN OTHERS
		THEN
		    hdr_details.terms_id := NULL;
		END;
	ELSE
	     hdr_details.terms_id := NVL(hdr_details.terms_id,ln_supp_terms_id);
	END IF;

	IF lc_supp_attr_category = 'TR-CON'
	THEN
	    hdr_details.status := 'PROCESSED';
	END IF;

	BEGIN
		UPDATE ap_invoices_interface
		   SET source = lc_source,
			   attribute2 = lc_attr2,
			   attribute7 = lc_source,
			   attribute5 = hdr_details.po_type,
			   terms_id   = NVL(hdr_details.terms_id, terms_id),
			   pay_group_lookup_code = NVL(lc_pay_group,pay_group_lookup_code),
			   payment_method_code = NVL(lc_payment_method_lookup_code, payment_method_code),
			   attribute10 = NVL(LPAD(lc_vendor_site_code,10,'0'),attribute10),
			   status = NVL(hdr_details.status,status),
			   last_update_date = sysdate,
			   last_updated_by = gn_user_id
		 WHERE invoice_id = hdr_details.invoice_id;
	EXCEPTION
	WHEN OTHERS
	THEN
		print_debug_msg('Unable to update the Source for the Invoice ID :'||hdr_details.invoice_id,FALSE);
	END;

        OPEN interface_lines_details(hdr_details.invoice_id);
        LOOP
	      l_detail_tab.DELETE;  --- Deleting the data in the Table type
          FETCH interface_lines_details BULK COLLECT INTO l_detail_tab LIMIT ln_batch_size;
          EXIT WHEN l_detail_tab.COUNT = 0;

		  ln_total_records_processed := ln_total_records_processed + l_detail_tab.COUNT;
		  FOR indx IN l_detail_tab.FIRST..l_detail_tab.LAST
          LOOP
            BEGIN
			    lc_attr3 := NULL;
				IF l_detail_tab(indx).line_type_lookup_code = 'ITEM'
				THEN
				    IF l_detail_tab(indx).inventory_item_id IS NULL
				    THEN
				        -- To derive the Inventory Item ID
	                    get_inventory_item_id( p_sku               =>  l_detail_tab(indx).sku
			                                  ,p_po_number         =>  hdr_details.po_number
						                      ,o_inventory_item_id =>  l_detail_tab(indx).inventory_item_id
											  ,o_po_type           =>  lc_po_type);
			    	END IF;

					IF l_detail_tab(indx).inventory_item_id IS NOT NULL
					THEN
					    get_po_line_num_int(p_header_id         =>  hdr_details.po_header_id
					    	               ,p_inventory_item_id =>  l_detail_tab(indx).inventory_item_id
					    	               ,p_unit_price        =>  l_detail_tab(indx).unit_price
					    	               ,p_quantity          =>  l_detail_tab(indx).quantity
					    	               ,p_inv_line_num      =>  l_detail_tab(indx).inv_line_number
					    	               ,p_invoice_id        =>  hdr_details.invoice_id
					    	               ,o_po_line_num       =>  ln_po_line_num
					    	               ,o_uom_code          =>  lc_po_uom);

					    print_debug_msg('PO Line Number :'||ln_po_line_num,FALSE);

					    BEGIN
				            UPDATE ap_invoice_lines_interface
					           SET po_line_number = ln_po_line_num,
					    	       unit_of_meas_lookup_code = lc_po_uom,
					    		   inventory_item_id = l_detail_tab(indx).inventory_item_id,
					               dist_code_concatenated = null,
					    		   last_update_date = sysdate,
					    		   last_updated_by = gn_user_id
					         WHERE invoice_line_id = l_detail_tab(indx).invoice_line_id;
					    EXCEPTION
					    WHEN OTHERS
					    THEN
					    	print_debug_msg('Unable to update the PO Line Num for the Invoice Line ID :'||l_detail_tab(indx).invoice_line_id,FALSE);
					    END;

				    ELSE
				        l_detail_tab(indx).line_type_lookup_code := 'MISCELLANEOUS';
						lc_attr3 := 'Y';
					END IF;
				END IF; -- l_detail_tab(indx).line_type_lookup_code = 'ITEM'

                IF l_detail_tab(indx).line_type_lookup_code <> 'ITEM'
				THEN
				    IF l_detail_tab(indx).line_type_lookup_code = 'MISCELLANEOUS' AND lc_attr3 = 'Y'
                    THEN
                        l_detail_tab(indx).reason_code:= 'DEFAULT1';
		                lc_sac_code_sign := '+';
                    ELSE
                        -- To get the Reason Code for the Below lines
		                BEGIN
		                    SELECT target_value2, target_value3
		                      INTO l_detail_tab(indx).reason_code, lc_sac_code_sign
		                      FROM xx_fin_translatevalues
		                     WHERE translate_id IN (SELECT translate_id
                                                      FROM xx_fin_translatedefinition
		                                         	 WHERE translation_name = 'XX_AP_SAC_REASON_CODES' -- 'XX_AP_SAC_CODE'
		                                         	   AND enabled_flag = 'Y')
                                                       AND target_value1 = l_detail_tab(indx).sac_code;
		                EXCEPTION
		                WHEN OTHERS
		                THEN
		                    l_detail_tab(indx).reason_code:= 'DEFAULT';
		                    lc_sac_code_sign := '+';
		                END;
		            END IF;

					IF lc_sac_code_sign = '+'
					THEN
						l_detail_tab(indx).amount := 1 * l_detail_tab(indx).amount ;
					ELSE
						l_detail_tab(indx).amount := (-1) * l_detail_tab(indx).amount;
					END IF;

				    BEGIN
						ln_ccid := NULL;
				        ln_accrual_id := NULL;
			            lc_gl_string := NULL;
				        ln_acct_id  := NULL;

				        SELECT /*+ cardinality(poh 1) */
						       pod.code_combination_id,
                               pod.accrual_account_id
						  INTO ln_ccid,
                               ln_accrual_id
						  FROM po_lines_all pol,
                               po_distributions_all pod
				         WHERE 1 = 1
                           AND pol.po_line_id = pod.po_line_id
                           AND pol.po_header_id = hdr_details.po_header_id
                           AND pol.line_num = 1;

			        EXCEPTION
				        WHEN NO_DATA_FOUND
				        THEN
				            ln_ccid := NULL;
				            ln_accrual_id := NULL;

				        WHEN OTHERS
                        THEN
				            ln_ccid := NULL;
				            ln_accrual_id := NULL;
                    END;

                    IF hdr_details.po_type LIKE 'DropShip%'
					THEN
					    lc_drop_ship_flag := 'Y';
						ln_acct_id        := ln_accrual_id;
					ELSE
					    lc_drop_ship_flag := 'N';
						ln_acct_id        := ln_ccid;
					END IF;

					-- To get the GL String for the Miscellaneous Lines
					BEGIN

					    SELECT gcck.concatenated_segments
						  INTO lc_gl_string
						  FROM gl_code_combinations_kfv gcck
						 WHERE gcck.code_combination_id = ln_acct_id;
					EXCEPTION
					    WHEN OTHERS
						THEN
				    	     lc_gl_string := NULL;
				    END;

	                -- To get the GL information for the below lines
                    BEGIN
                        SELECT target_value4,
                               target_value5,
                               target_value6,
                               target_value7,
                               target_value8,
		                 	   target_value10,
			        		   target_value2
                          INTO lc_company,
                               lc_cost_center,
                               lc_account,
                               lc_location,
                               lc_lob,
		                 	   lc_drop_ship_acct,
			        		   lc_description
		                  FROM xx_fin_translatevalues
	                     WHERE translate_id IN (SELECT translate_id
		                 						  FROM xx_fin_translatedefinition
		                 					     WHERE translation_name = 'OD_AP_REASON_CD_ACCT_MAP'
		                 						   AND enabled_flag = 'Y')
		                   AND target_value1 = DECODE(l_detail_tab(indx).reason_code,'FR',DECODE(lc_drop_ship_flag,'Y','FS','FR'),l_detail_tab(indx).reason_code);
                    EXCEPTION
	                WHEN OTHERS
	                THEN
	                    lc_company := NULL;
	                    lc_cost_center := NULL;
	                    lc_account := NULL;
	                    lc_location := NULL;
	                    lc_lob := NULL;
		                lc_drop_ship_acct := NULL;
			        	lc_description := NULL;
                    END;

					print_debug_msg('Reason Code is :'||l_detail_tab(indx).reason_code,FALSE);

					-- Updating the Invoice Interface table
					BEGIN

                        UPDATE ap_invoice_lines_interface
					       SET po_line_number = NULL,
						       line_type_lookup_code = l_detail_tab(indx).line_type_lookup_code,
							   attribute3 = lc_attr3,
							   amount = l_detail_tab(indx).amount,
							   quantity_invoiced = NULL,
							   unit_price = NULL,
					           dist_code_concatenated = DECODE(l_detail_tab(indx).reason_code,
					    	                                   'DEFAULT',
					    									   NULL,
					    	                                   NVL(lc_company,SUBSTR(lc_gl_string,1,4)) ||'.'||
                                                               NVL(lc_cost_center,SUBSTR(lc_gl_string,6,5))||'.'||
                                                               NVL(lc_account,SUBSTR(lc_gl_string,12,8))||'.'||
					    	                                   NVL(lc_location,SUBSTR(lc_gl_string,21,6)) ||'.'||
					    	                                   NVL(SUBSTR(lc_gl_string,28,4),'0000') ||'.'||
					    	                                   NVL(lc_lob,SUBSTR(lc_gl_string,33,2))||'.'||
					    	                                   NVL(SUBSTR(lc_gl_string,36,6),'000000')) ,
                               last_update_date = sysdate,
							   last_updated_by = gn_user_id
					     WHERE invoice_line_id = l_detail_tab(indx).invoice_line_id;
					EXCEPTION
					WHEN OTHERS
					THEN
						print_debug_msg('Unable to update the GL String for the Invoice Line ID :'||l_detail_tab(indx).invoice_line_id,FALSE);
					END;

                END IF; -- l_detail_tab(indx).line_type_lookup_code <> 'ITEM'

			EXCEPTION
			  WHEN OTHERS
			  THEN
			    ROLLBACK;
				ln_failed_records := ln_failed_records +1;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
			END;
          END LOOP; -- l_detail_tab
	    END LOOP; --interface_lines_details
        CLOSE interface_lines_details;
	COMMIT;
	END LOOP; -- interface_hdr_details
    print_debug_msg('End of processing all the Rejected Records in the POI',TRUE);
EXCEPTION
   WHEN OTHERS
   THEN
     print_debug_msg('Error Message - Processing all the Rejected Records in the POI :'||SQLERRM,TRUE);
END update_interface_lines_dtls;

-- +===============================================================================================+
-- |  Name	 : load_data_to_staging                                                                |
-- |  Description: This procedure reads data from the pre-staging and inserts into staging tables  |
-- ================================================================================================|

PROCEDURE load_data_to_staging(p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  VARCHAR2
                              ,p_source         IN   VARCHAR2
                              ,p_frequency_code IN   VARCHAR2
                              ,p_debug          IN   VARCHAR2
							  ,p_from_date      IN   VARCHAR2
					          ,p_to_date        IN   VARCHAR2
							  ,p_date           IN   VARCHAR2
							  )
AS

   -- Cursor to select all the header information
    CURSOR header_cur(p_source  VARCHAR2,
	                  p_date  DATE) IS
        SELECT *
	      FROM xx_ap_trade_inv_hdr
	     WHERE record_status = 'N'
           AND source = p_source
		   AND TRUNC(creation_date) =  TRUNC(NVL(p_date,creation_date))
	     ORDER BY invoice_id;

    TYPE header IS TABLE OF header_cur%ROWTYPE
    INDEX BY PLS_INTEGER;

   -- To get the Summary line information for the Consignment
   CURSOR lines_consign_summ_cur(p_invoice_id  NUMBER,
                                 p_frequency_code VARCHAR2,
								 p_source VARCHAR2)

	IS
	    SELECT invoice_id,
	           NULL location_number,
	           NULL invoice_line_id, -- ap_invoice_lines_interface_s.NEXTVAL ,
			   NULL line_type,
			   SUM(mdse_amount) mdse_amount,
			   NULL mdse_amount_sign,
			   NULL line_description,
			   NULL sku,
			   NULL quantity,
			   NULL quantity_sign,
			   NULL cost,
			   NULL cost_sign,
			   NULL po_line_number,
			   NULL gl_company,
			   NULL gl_cost_center,
			   NULL gl_account,
			   NULL gl_location,
			   NULL gl_inter_company,
			   NULL gl_lob,
			   NULL gl_future,
			   NULL reason_code,
			   NULL record_status,
			   NULL error_description,
			   NULL unit_of_measure,
               NULL sku_description,
               NULL sac_code
	      FROM xx_ap_trade_inv_lines
		 WHERE record_status = 'N'
           AND source = p_source
	       AND frequency_code = NVL(p_frequency_code,frequency_code)
	       AND invoice_id = p_invoice_id
		   AND consign_flag = 'Y'
		GROUP BY invoice_id;

	-- To get the unabsorbed lines details for the Consignment
	CURSOR lines_consign_unabsorb_cur(p_invoice_id NUMBER,
                                      p_frequency_code VARCHAR2,
								      p_source VARCHAR2)
	IS
	    SELECT invoice_id,
	           location_number,
	           NULL invoice_line_id,
			   NULL line_type,
			   SUM(mdse_amount) mdse_amount,
			   NULL  mdse_amount_sign,
			   NULL line_description,
			   NULL sku,
			   NULL quantity,
			   NULL quantity_sign,
			   NULL cost,
			   NULL cost_sign,
			   NULL po_line_number,
			   NULL gl_company,
			   NULL gl_cost_center,
			   NULL gl_account,
			   NULL gl_location,
			   NULL gl_inter_company,
			   NULL gl_lob,
			   NULL gl_future,
			   NULL reason_code,
			   NULL record_status,
			   NULL error_description,
			   NULL unit_of_measure,
               NULL sku_description,
               NULL sac_code
	      FROM xx_ap_trade_inv_lines
		 WHERE record_status = 'N'
           AND source = p_source
	       AND frequency_code = NVL(p_frequency_code,frequency_code)
	       AND invoice_id = p_invoice_id
		   AND consign_flag = 'N'
		GROUP BY invoice_id,
		         location_number;

	-- To get the lines details for all sources other than CONSIGNMENT
	CURSOR lines_cur(p_invoice_id NUMBER,
	                 p_source VARCHAR2)
	IS
	    SELECT invoice_id,
	           location_number,
	           invoice_line_id,
			   line_type,
			   mdse_amount,
			   mdse_amount_sign,
			   line_description,
			   sku,
			   quantity,
			   quantity_sign,
			   cost,
			   cost_sign,
			   po_line_number,
			   gl_company,
			   gl_cost_center,
			   gl_account,
			   gl_location,
			   gl_inter_company,
			   gl_lob,
			   gl_future,
			   reason_code,
			   record_status,
			   error_description,
			   unit_of_measure,
               sku_description,
               sac_code
	      FROM xx_ap_trade_inv_lines
		 WHERE record_status = 'N'
           AND source = p_source
		   AND invoice_id = p_invoice_id
           AND (frequency_code IS NULL AND consign_flag IS NULL);

    TYPE lines IS TABLE OF lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;

	-- Cursor to fetch all the Consignment Suppliers Invoice Numbers for TDM and EDI Sources
   /* CURSOR cons_inv_num_cur
    IS
	    SELECT invoice_num
	      FROM xx_ap_inv_interface_stg
	     WHERE request_id = gn_request_id
	       AND source = p_source
		   AND status = 'CONS_REJECTED';*/  ---Commented For NAIT-57153 to print the vendor name and vendor site in the email

	---Added For NAIT-57153 to print the vendor name and vendor site in the email------
	   CURSOR cons_inv_num_cur
    IS
	    SELECT  A.INVOICE_NUM
	           ,D.VENDOR_NAME "SUPPLIER_NAME"
			   ,C.VENDOR_SITE_CODE "SUPPLIER_SITE"
           FROM   XX_AP_INV_INTERFACE_STG A,
                  PO_HEADERS_ALL B,
                  AP_SUPPLIER_SITES_ALL C,
                  AP_SUPPLIERS D
           WHERE  A.REQUEST_ID = GN_REQUEST_ID
	          AND B.VENDOR_SITE_ID = C.VENDOR_SITE_ID
              AND C.VENDOR_ID = D.VENDOR_ID
              AND A.PO_NUMBER = B.SEGMENT1
	          AND A.SOURCE = P_SOURCE
              AND A.STATUS = 'CONS_REJECTED';

	-- Cursor to fetch the Consignment Suppliers Details to create the Miscellaneous Issue
    -- Modified by Antonio Morales 4/18/18 (Performance and skip type '02' items)

	CURSOR get_consign_misc_dtls(p_in_date DATE)
	IS
    SELECT *
      FROM (
      SELECT /*+ index(msi mtl_system_items_b_n1) */
             apl.*,
             msi.inventory_item_id,
             msi.organization_id,
             msi.primary_uom_code,
             msa.od_sku_type_cd
        FROM (SELECT apl.ap_vendor,
                     apl.location_number,
                     apl.sku,
                     SUM(DECODE(apl.quantity_sign,'+',apl.quantity,'-',(-1) * apl.quantity)) quantity,
                     apl.cost,
					 apl.quantity_sign -- added for Defect# 45153 - NAIT-40379
                FROM xx_ap_trade_inv_lines apl
               WHERE 1 =1
                 AND apl.source = 'US_OD_CONSIGNMENT_SALES'
                 AND apl.consign_flag = 'Y'
                -- AND apl.quantity_sign = '+'  --commented for Defect# 45153 - NAIT-40379
                 AND (apl.cost+apl.quantity) <> 0
                 AND apl.misc_issue_flag IS NULL
                 AND apl.record_status = 'N'
                 AND apl.creation_date BETWEEN to_date(to_char(p_in_date)||' 00:00:00','DD-MON-RR HH24:MI:SS')
                                           AND to_date(to_char(p_in_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')
               GROUP BY ap_vendor,
                        location_number,
                        sku,
                        cost,
                        quantity_sign  --- Added for Defect# 45153 - NAIT-40379
             ) apl
             ,(SELECT attribute1
                     ,inventory_organization_id
                 FROM hr_locations_all
                WHERE in_organization_flag = 'Y'
                  AND inventory_organization_id IS NOT NULL) hrl
             ,mtl_system_items_b msi
             ,xx_inv_item_master_attributes msa
       WHERE 1=1
         AND hrl.attribute1(+) = lpad(apl.location_number,6,'0')
         AND hrl.inventory_organization_id(+) IS NOT NULL
         AND msi.segment1(+) = ltrim(apl.sku,'0')
         AND hrl.inventory_organization_id = msi.organization_id(+)
         AND msa.inventory_item_id(+) = msi.inventory_item_id
     )
     WHERE NVL(od_sku_type_cd,'01') <> '02';

    TYPE consign_misc_inv_lines IS TABLE OF get_consign_misc_dtls%ROWTYPE
    INDEX BY PLS_INTEGER;
    l_consign_misc_inv_lines_tab  consign_misc_inv_lines;

 -- Cursor to get the Org ID
	CURSOR org_cur(p_batch_id NUMBER)
	IS
       SELECT distinct org_id
         FROM po_headers_interface
        WHERE batch_id = p_batch_id
          -- AND interface_source_code = 'NA-POINTR'
          AND org_id IS NOT NULL;

    TYPE org IS TABLE OF org_cur%ROWTYPE
    INDEX BY PLS_INTEGER;

    l_org_tab 		              ORG;
	l_header_tab 		          HEADER;
    l_lines_tab 		          LINES;
	l_lines_consign_summ_tab      LINES;
	l_lines_consign_unabosb_tab   LINES;
    indx                 	      NUMBER;
    l_indx                        NUMBER;
    o_indx			              NUMBER;
    ln_batch_size		          NUMBER := 250;
    lc_error_loc                  VARCHAR2(100) := 'XX_AP_INVOICE_INTEGRAL_PKG.load_data_to_staging';
    lc_error_msg                  VARCHAR2(1000);
    lc_errcode                    VARCHAR2(100);
    ln_err_count		          NUMBER;
    ln_error_idx		          NUMBER;
    data_exception                EXCEPTION;
	lc_location                   VARCHAR2(30);
    lc_lob                        VARCHAR2(30);
    lc_oracle_account             VARCHAR2(30);
	lc_drop_ship_acct             VARCHAR2(30);
    lc_company                    VARCHAR2(30);
    lc_cost_center                VARCHAR2(30);
    lc_inter_company              VARCHAR2(30);
    lc_future                     VARCHAR2(30);
    lc_description                VARCHAR2(100);
	ln_ccid                       NUMBER;
	ln_accrual_id                 NUMBER;
	lc_gl_string                  VARCHAR2(100);
	ln_acct_id                    NUMBER;
	lc_po_type                    VARCHAR2(100);
    lc_unabsorb_location          VARCHAR2(30);
    lc_unabsorb_lob               VARCHAR2(30);
    lc_unabsorb_oracle_account    VARCHAR2(30);
    lc_unabsorb_company           VARCHAR2(30);
    lc_unabsorb_cost_center       VARCHAR2(30);
    lc_unabsorb_inter_company     VARCHAR2(30);
    lc_unabsorb_future            VARCHAR2(30);
    lc_unabsorb_description       VARCHAR2(100);
	lc_acct_detail                VARCHAR2(100);
	ln_line_number                NUMBER;
	ln_invoice_id                 NUMBER;
    ln_total_hdr_records_process  NUMBER;
    ln_hdr_success_records        NUMBER;
    ln_hdr_failed_records         NUMBER;
	ln_total_line_records_process NUMBER;
    ln_line_success_records       NUMBER;
    ln_line_failed_records        NUMBER;
	ln_total_records_processed    NUMBER;
	ln_success_records            NUMBER;
	ln_failed_records             NUMBER;
	lc_supp_attr_category         VARCHAR2(50);
	lc_vendor_sites_kff_id        NUMBER;
	lc_status                     VARCHAR2(30);
	lc_gbl_attr16                 VARCHAR2(30);
	lc_cons_vendor_flag           VARCHAR2(1);
	lc_cons_inv_num               VARCHAR2(32767);
    lc_temp_email                 VARCHAR2(2000);
	lc_source                     VARCHAR2(10);
	ln_inventory_item_id          NUMBER;
	ln_supp_terms_id              NUMBER;
	ln_po_terms_id                NUMBER;
	lc_invoice_type_lookup_code   VARCHAR2(30);
	lc_supplier_site_code         VARCHAR2(30);
	lc_drop_ship_flag             VARCHAR2(1);
	lc_reason_code                VARCHAR2(30);
	lc_email_from                 VARCHAR2(100);
	lc_email_to                   VARCHAR2(100);
	lc_email_cc                   VARCHAR2(100);
	lc_email_subject              VARCHAR2(100);
	lc_email_body                 VARCHAR2(100);
    conn utl_smtp.connection;
	ln_max_request_id             NUMBER;
	l_consign_indx                NUMBER;
	ln_organization_id            NUMBER;
  	lc_uom_code                   VARCHAR2(100);
	lc_phase                      VARCHAR2(100);
    lc_rpt_status                 VARCHAR2(100);
    lc_dev_phase                  VARCHAR2(100);
    lc_dev_status                 VARCHAR2(100);
    lc_message                    VARCHAR2(100);
    lb_complete                   BOOLEAN;
    ln_request_id                 NUMBER;
    lb_layout                     BOOLEAN;
	lc_unit_of_measure            VARCHAR2(100);
	lc_uom                        VARCHAR2(100);
	lc_stg_uom_code               VARCHAR2(100);
	ln_po_line_num                NUMBER;
	lc_receipt_required_flag      VARCHAR2(1);
	lc_ret_status                 VARCHAR2(30);
	lc_sac_code_sign              VARCHAR2(10);
	lc_line_type                  VARCHAR2(30);
	ln_amount                     NUMBER;
	lc_attr3                      VARCHAR2(1);
	ln_job_id                     NUMBER;
	ld_from_date                  DATE;
    ld_to_date                    DATE;
	ld_date                       DATE;
	lc_misc_issue_flag            VARCHAR2(1);
    lc_od_sku_type_cd             VARCHAR2(10);
	ln_log1                       VARCHAR2(32767); ---Added For NAIT-57153 to print the vendor name and vendor site in the email

BEGIN
    fnd_file.put_line(fnd_file.log,' Input Parameters ');
	fnd_file.put_line(fnd_file.log,' Source :'||p_source);
	fnd_file.put_line(fnd_file.log,' Frequency Code :'|| p_frequency_code);
	fnd_file.put_line(fnd_file.log,' Debug Flag :'||p_debug);
	fnd_file.put_line(fnd_file.log,' From Date :'||p_from_date);
	fnd_file.put_line(fnd_file.log,' To Date :'|| p_to_date);
	fnd_file.put_line(fnd_file.log,' Date :'||p_date);

    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
    ln_total_hdr_records_process:= 0;
	ln_hdr_success_records := 0;
	ln_hdr_failed_records := 0;
	ln_total_line_records_process := 0;
	ln_line_success_records := 0;
	ln_line_failed_records := 0;
    ln_total_records_processed := 0;
	ln_success_records := 0;
	ln_failed_records := 0;
	lc_cons_vendor_flag := NULL;
    lc_invoice_type_lookup_code := NULL;
	ln_supp_terms_id  := NULL;
	ln_po_terms_id  := NULL;
    lc_supplier_site_code := NULL;
    ln_max_request_id := NULL;
	lc_unit_of_measure := NULL;
	ln_po_line_num := NULL;
	lc_receipt_required_flag := NULL;
	lc_ret_status := NULL;
	lc_sac_code_sign := NULL;
	lc_attr3 := NULL;
	lc_uom := NULL;
	lc_uom_code := NULL;
	lc_stg_uom_code := NULL;
	ln_inventory_item_id := NULL;
	ld_date := NULL;
	ld_from_date := NULL;
	ld_to_date := NULL;
	lc_misc_issue_flag := NULL;

-- AM Change 4/12/18
-- Load locations in a collection to speed up the search process

    OPEN c_hrl;
    FETCH c_hrl
     BULK COLLECT
     INTO thtl;
    CLOSE c_hrl;


	IF p_source = 'US_OD_TRADE_EDI'
	THEN
	   -- To get the Batch ID
	   SELECT XX_PO_POM_INT_BATCH_S.NEXTVAL
	     INTO gn_batch_id
	     FROM DUAL;

	   fnd_file.put_line(fnd_file.log,'Batch ID: '||gn_batch_id);

	   -- Added as per version 3.7
	   -- Calling update_interface_lines_dtls procedure to update the po line reference for the Rejected lines
	   update_interface_lines_dtls;

	   -- Calling update_cons_edi_invoices procedure to update the Consignment EDI Processed Invoices to not processed
	   update_cons_edi_invoices;

	END IF;

	-- To create the Header records from the Lines Details by Vendor for Consignment Sales
	IF p_source = 'US_OD_CONSIGNMENT_SALES'
	THEN
		  -- To pass the date parameters
	    IF p_frequency_code IS NULL
	    THEN
	          -- FROM DATE
	          IF p_from_date IS NOT NULL
              THEN
                -- ld_from_date := FND_DATE.CANONICAL_TO_DATE(p_from_date);
				 SELECT TO_DATE(p_from_date)
				   INTO ld_from_date
				   FROM DUAL;

              ELSE
                 ld_from_date := NULL;
              END IF;
		  	-- TO DATE
		  	IF p_to_date IS NOT NULL
              THEN
                -- ld_to_date := FND_DATE.CANONICAL_TO_DATE(p_to_date);
				SELECT TO_DATE(p_to_date)
				   INTO ld_to_date
				   FROM DUAL;
              ELSE
                 ld_to_date := NULL;
              END IF;
		ELSIF p_frequency_code = 'DY'
		THEN
		    IF p_date IS NOT NULL
			THEN
			   --ld_date := FND_DATE.CANONICAL_TO_DATE(p_date);
			   SELECT TO_DATE(p_date)
				   INTO ld_date
				   FROM DUAL;
			ELSE
			   ld_date := NULL;
			END IF;

	    END IF;

	 -- fnd_file.put_line(fnd_file.log,' Input Parameters ');
	 -- fnd_file.put_line(fnd_file.log,' ld_date :'||ld_date);
	 -- fnd_file.put_line(fnd_file.log,' ld_from_date :'|| ld_from_date);
	 -- fnd_file.put_line(fnd_file.log,' ld_to_date :'||ld_to_date);

      load_csi_data(p_source         => p_source
	               ,p_frequency_code => p_frequency_code
                   ,p_debug          => p_debug
				   ,p_from_date      => ld_from_date
				   ,p_to_date        => ld_to_date
				   ,p_date           => ld_date
				   ,p_error_msg      => lc_error_msg
				   ,p_errcode        => lc_errcode);
    END IF;

	IF p_source <> 'US_OD_CONSIGNMENT_SALES'
	THEN
	    IF p_date IS NOT NULL
        THEN
          -- ld_date := FND_DATE.CANONICAL_TO_DATE(p_date);
		  SELECT TO_DATE(p_date)
				   INTO ld_date
				   FROM DUAL;
		ELSE
		   ld_date := NULL;
		END IF;
	END IF;

	-- To create the Header records from the Lines Details for Dropship
    IF p_source = 'US_OD_DROPSHIP'
    THEN
        load_drp_data(p_source         => p_source
		             ,p_date           => ld_date
                     ,p_debug          => p_debug
				     ,p_error_msg      => lc_error_msg
				     ,p_errcode        => lc_errcode);
	END IF;

	IF p_source = 'US_OD_RTV_MERCHANDISING'
	THEN

	      -- To pass the date parameters
	    IF p_frequency_code <> 'DY'
	    THEN
	          -- FROM DATE
	          IF p_from_date IS NOT NULL
              THEN
                -- ld_from_date := FND_DATE.CANONICAL_TO_DATE(p_from_date);
				 SELECT TO_DATE(p_from_date)
				   INTO ld_from_date
				   FROM DUAL;

              ELSE
                 ld_from_date := NULL;
              END IF;
		  	-- TO DATE
		  	IF p_to_date IS NOT NULL
              THEN
                -- ld_to_date := FND_DATE.CANONICAL_TO_DATE(p_to_date);
				SELECT TO_DATE(p_to_date)
				   INTO ld_to_date
				   FROM DUAL;
              ELSE
                 ld_to_date := NULL;
              END IF;
		ELSE
		    IF p_date IS NOT NULL
			THEN
			   --ld_date := FND_DATE.CANONICAL_TO_DATE(p_date);
			   SELECT TO_DATE(p_date)
				   INTO ld_date
				   FROM DUAL;
			ELSE
			   ld_date := NULL;
			END IF;

	    END IF; -- p_frequency_code <> 'DY'
	    load_rtv_data(p_source         => p_source
		             ,p_frequency_code => p_frequency_code
					 ,p_from_date      => ld_from_date
				     ,p_to_date        => ld_to_date
					 ,p_date           => ld_date
                     ,p_debug          => p_debug
				     ,p_error_msg      => lc_error_msg
				     ,p_errcode        => lc_errcode);
	END IF;

	IF p_source = 'US_OD_CONSIGNMENT_SALES'
	THEN
    -- To create the Miscellaneous Issue for the Consignment Sales details for the respective Consignment Supplier
		IF p_date IS NOT NULL
		THEN
			--ld_date := FND_DATE.CANONICAL_TO_DATE(p_date);
			SELECT TO_DATE(p_date)
			  INTO ld_date
			  FROM DUAL;

		ELSE
			SELECT SYSDATE
			  INTO ld_date
			  FROM DUAL;

		END IF;

		-- print_debug_msg ('ld_date :'||ld_date);

           OPEN get_consign_misc_dtls(ld_date);

           LOOP

           FETCH get_consign_misc_dtls
            BULK COLLECT
            INTO l_consign_misc_inv_lines_tab LIMIT 50000;

           EXIT WHEN l_consign_misc_inv_lines_tab.COUNT = 0;

           FOR l_consign_indx IN 1..l_consign_misc_inv_lines_tab.COUNT
           LOOP
              BEGIN

              lc_od_sku_type_cd := NULL;

              IF l_consign_misc_inv_lines_tab(l_consign_indx).inventory_item_id IS NULL THEN
                 BEGIN
        	        SELECT msi.inventory_item_id,
                           msi.primary_uom_code,
                           msa.od_sku_type_cd
                      INTO ln_inventory_item_id,
                           lc_uom_code,
                           lc_od_sku_type_cd
        		      FROM mtl_system_items_b msi
                          ,xx_inv_item_master_attributes msa
                     WHERE msi.segment1 = LTRIM(l_consign_misc_inv_lines_tab(l_consign_indx).sku,'0')
                       AND msi.inventory_item_id = msa.inventory_item_id
                       AND ROWNUM = 1;
        		 EXCEPTION
        		   WHEN OTHERS THEN
        		    ln_inventory_item_id := l_consign_misc_inv_lines_tab(l_consign_indx).sku;
                                         -- Passing the location value as inventory item id. So,the record will fail in MTL_TRANSACTIONS_INTERFACE
                    lc_uom_code := NULL;
                    lc_od_sku_type_cd := NULL;
        		 END;

                 IF NVL(lc_od_sku_type_cd,'01') <> '02' THEN -- Skip type = '02', type <> '02' and nulls are processed
                    ln_organization_id := NULL;
                    FOR i IN thtl.FIRST .. thtl.LAST
                    LOOP
                        IF LTRIM(thtl(i).attribute1,'0') = LTRIM(l_consign_misc_inv_lines_tab(l_consign_indx).location_number,'0') THEN
                           ln_organization_id := thtl(i).inventory_organization_id;
                           EXIT;
                        END IF;
                    END LOOP;
                    IF ln_organization_id IS NULL THEN
                       ln_organization_id := l_consign_misc_inv_lines_tab(l_consign_indx).location_number;
                                          -- Passing the location value as organization id. So,the record will fail in MTL_TRANSACTIONS_INTERFACE
                    END IF;
                 END IF;
              ELSE
                ln_inventory_item_id := l_consign_misc_inv_lines_tab(l_consign_indx).inventory_item_id;
                ln_organization_id   := l_consign_misc_inv_lines_tab(l_consign_indx).organization_id;
                lc_uom_code          := l_consign_misc_inv_lines_tab(l_consign_indx).primary_uom_code;
                lc_od_sku_type_cd    := l_consign_misc_inv_lines_tab(l_consign_indx).od_sku_type_cd;
              END IF;

              IF NVL(lc_od_sku_type_cd,'01') <> '02' THEN  -- Skip type = '02', type <> '02' and nulls are processed

			     --Before if condition logic added for Defect# 45153 - NAIT-40379
				 --Code change Starts here Defect# 45153 - NAIT-40379
				IF l_consign_misc_inv_lines_tab(l_consign_indx).quantity_sign = '+' THEN
    			 xx_po_rcv_int_pkg.mtl_transaction_int( p_errbuf       		       => lc_error_msg
                         	                           ,p_retcode      		       => lc_errcode
    			                                       ,p_transaction_type_name    => 'Miscellaneous issue'
    			                                       ,p_inventory_item_id	       => ln_inventory_item_id
    			                                       ,p_organization_id		   => ln_organization_id
    			                                       ,p_transaction_qty		   => -TO_NUMBER(l_consign_misc_inv_lines_tab(l_consign_indx).quantity)
    			                                       ,p_transaction_cost	       => TO_NUMBER(l_consign_misc_inv_lines_tab(l_consign_indx).cost)
    			                                       ,p_transaction_uom_code     => lc_uom_code
    			                                       ,p_transaction_date	       => SYSDATE
    			                                       ,p_subinventory_code	       => 'STOCK'
    			                                       ,p_transaction_source	   => 'OD CONSIGNMENT SALES'
    												   ,p_vendor_site              => '0'||l_consign_misc_inv_lines_tab(l_consign_indx).ap_vendor
    												   ,p_original_rtv             => NULL
    												   ,p_rga_number               => NULL
    												   ,p_freight_carrier          => NULL
    												   ,p_freight_bill             => NULL
    												   ,p_vendor_prod_code         => NULL
    												   ,p_sku                      => l_consign_misc_inv_lines_tab(l_consign_indx).sku
    												   ,p_location                 => LTRIM(l_consign_misc_inv_lines_tab(l_consign_indx).location_number,'0')
    												   );
				ELSIF  l_consign_misc_inv_lines_tab(l_consign_indx).quantity_sign = '-' THEN
			   		 xx_po_rcv_int_pkg.mtl_transaction_int( p_errbuf       		       => lc_error_msg
                         	                           ,p_retcode      		       => lc_errcode
    			                                       ,p_transaction_type_name    => 'Miscellaneous receipt'
    			                                       ,p_inventory_item_id	       => ln_inventory_item_id
    			                                       ,p_organization_id		   => ln_organization_id
    			                                       ,p_transaction_qty		   => -TO_NUMBER(l_consign_misc_inv_lines_tab(l_consign_indx).quantity)
    			                                       ,p_transaction_cost	       => TO_NUMBER(l_consign_misc_inv_lines_tab(l_consign_indx).cost)
    			                                       ,p_transaction_uom_code     => lc_uom_code
    			                                       ,p_transaction_date	       => SYSDATE
    			                                       ,p_subinventory_code	       => 'STOCK'
    			                                       ,p_transaction_source	   => 'OD CONSIGNMENT SALES'
    												   ,p_vendor_site              => '0'||l_consign_misc_inv_lines_tab(l_consign_indx).ap_vendor
    												   ,p_original_rtv             => NULL
    												   ,p_rga_number               => NULL
    												   ,p_freight_carrier          => NULL
    												   ,p_freight_bill             => NULL
    												   ,p_vendor_prod_code         => NULL
    												   ,p_sku                      => l_consign_misc_inv_lines_tab(l_consign_indx).sku
    												   ,p_location                 => LTRIM(l_consign_misc_inv_lines_tab(l_consign_indx).location_number,'0')
    												   );
				END IF;
				--Code change Ends here Defect# 45153 - NAIT-40379

    			  IF lc_errcode = '2'
    			  THEN
    			      lc_misc_issue_flag := 'E';

    				  UPDATE xx_ap_trade_inv_lines
    			       SET misc_issue_flag = lc_misc_issue_flag,
    					   last_update_date = sysdate,
    					   last_updated_by = gn_user_id
    			    WHERE misc_issue_flag IS NULL
    			      AND ap_vendor = l_consign_misc_inv_lines_tab(l_consign_indx).ap_vendor
    				  AND sku = l_consign_misc_inv_lines_tab(l_consign_indx).sku
    				  AND location_number = l_consign_misc_inv_lines_tab(l_consign_indx).location_number
    				  AND cost = l_consign_misc_inv_lines_tab(l_consign_indx).cost
    				  AND record_status = 'N'
    				  AND consign_flag = 'Y'
    		          -- AND quantity_sign = '+'  -- Commented for Defect# 45153 - NAIT-40379
    		          AND (cost <> 0 OR quantity <> 0)
    				  AND source = 'US_OD_CONSIGNMENT_SALES'
    				  AND creation_date BETWEEN to_date(to_char(ld_date)||' 00:00:00','DD-MON-RR HH24:MI:SS')
    				                        AND to_date(to_char(ld_date)||' 23:59:59','DD-MON-RR HH24:MI:SS');

    			      print_debug_msg ('Unable to create the Miscellaneous Issue for the Consignment Sales for the Vendor: '||l_consign_misc_inv_lines_tab(l_consign_indx).ap_vendor||
    				                                                                                           ', Location: '||l_consign_misc_inv_lines_tab(l_consign_indx).location_number||
    				                                                                                           ', SKU: '||l_consign_misc_inv_lines_tab(l_consign_indx).sku||
    				                                                                                           ', Quantity: '||l_consign_misc_inv_lines_tab(l_consign_indx).quantity||
    																										   ', Cost: '||l_consign_misc_inv_lines_tab(l_consign_indx).cost

                    				  ,TRUE);
    			      CONTINUE;
    			   ELSE
    			      lc_misc_issue_flag := 'C';
                  END IF;

    			  UPDATE xx_ap_trade_inv_lines
    			       SET misc_issue_flag = lc_misc_issue_flag,
    					   last_update_date = sysdate,
    					   last_updated_by = gn_user_id
    			    WHERE misc_issue_flag IS NULL
    			      AND ap_vendor = l_consign_misc_inv_lines_tab(l_consign_indx).ap_vendor
    				  AND sku = l_consign_misc_inv_lines_tab(l_consign_indx).sku
    				  AND location_number = l_consign_misc_inv_lines_tab(l_consign_indx).location_number
    				  AND cost = l_consign_misc_inv_lines_tab(l_consign_indx).cost
    				  AND record_status = 'N'
    				  AND consign_flag = 'Y'
    		          -- AND quantity_sign = '+'  -- Commented for Defect# 45153 - NAIT-40379
    		          AND (cost <> 0 OR quantity <> 0)
    				  AND source = 'US_OD_CONSIGNMENT_SALES'
    				  AND creation_date BETWEEN to_date(to_char(ld_date)||' 00:00:00','DD-MON-RR HH24:MI:SS')
    				                        AND to_date(to_char(ld_date)||' 23:59:59','DD-MON-RR HH24:MI:SS');
              END IF;

			EXCEPTION
			WHEN OTHERS
			THEN
			   print_debug_msg('Consignment Sales Miscellaneous Issue :'||SQLERRM);
			END;
		END LOOP;
	    COMMIT;

        END LOOP;

        CLOSE get_consign_misc_dtls;

	END IF; -- Added as per Version 2.9

    -- Passing the date parameter to the Header Cursor
	IF p_source = 'US_OD_CONSIGNMENT_SALES'
	THEN
        ld_date := NULL;
    END IF;

	-- To load the Invoice Header and Lines details into Staging table
    print_debug_msg ('Start the loading data into Staging table' ,TRUE);

    OPEN header_cur(p_source,ld_date);
        LOOP
	        l_header_tab.DELETE;  --- Deleting the data in the Table type
            FETCH header_cur BULK COLLECT INTO l_header_tab LIMIT ln_batch_size;
            EXIT WHEN l_header_tab.COUNT = 0;

		    ln_total_hdr_records_process := ln_total_hdr_records_process + l_header_tab.COUNT;
		    FOR indx IN l_header_tab.FIRST..l_header_tab.LAST
            LOOP
                BEGIN
				    lc_supplier_site_code := NULL;

				    -- To get the gross amount sign
					SELECT DECODE(SIGN(l_header_tab(indx).gross_amt),'1','+','-1','-','0','+')
					  INTO l_header_tab(indx).gross_amt_sign
					  FROM DUAL;

					-- To get the Invoice Type Lookup Code
					SELECT DECODE(l_header_tab(indx).gross_amt_sign,'+','STANDARD','-','DEBIT')
					  INTO lc_invoice_type_lookup_code
				      FROM DUAL;

                    IF p_source NOT IN ('US_OD_RTV_MERCHANDISING','US_OD_DROPSHIP')
			        THEN
					   -- To derive the Supplier Site Code
					    get_po_vendor_site_code(p_po_number         => l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0') -- version 4.5
						                       ,o_vendor_site_code  => lc_supplier_site_code);

						IF lc_supplier_site_code IS NULL
						THEN
						   lc_supplier_site_code:= l_header_tab(indx).ap_vendor;
						END IF;

                     -- To derive the Supplier Information
                        get_supplier_info (p_vendor                  => lc_supplier_site_code
						                  ,o_terms_id                => ln_supp_terms_id
							              ,o_pay_group_lookup_code   => l_header_tab(indx).pay_group
                                          ,o_pymt_method_lookup_code => l_header_tab(indx).payment_method_lookup_code
                                          ,o_supp_attr_category      => lc_supp_attr_category
                                          ,o_vendor_sites_kff_id     => lc_vendor_sites_kff_id
										  );

                     -- To derive the PO Terms ID
                        IF 	p_source IN ('US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI')
                        THEN
				            get_po_terms_id(p_po_number   => l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0') -- version 4.5
						                   ,o_terms_id    => ln_po_terms_id
									       );
			            END IF; -- p_source IN ('US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI')
					ELSE
						lc_supplier_site_code:= l_header_tab(indx).ap_vendor;
					END IF; -- p_source NOT IN ('US_OD_RTV_MERCHANDISING','US_OD_DROPSHIP')

					-- To populate the Terms ID
					IF lc_invoice_type_lookup_code <> 'STANDARD'
					THEN
						l_header_tab(indx).terms_name := '00';
					ELSE
					    IF p_source = 'US_OD_DCI_TRADE' AND l_header_tab(indx).voucher_type = '3' -- Added as per version 2.3
                        THEN
                            l_header_tab(indx).terms_name := '00';
                        ELSE
					        IF ln_po_terms_id IS NOT NULL
						     THEN
						         l_header_tab(indx).terms_id := ln_po_terms_id;
						     ELSE
						         l_header_tab(indx).terms_id := ln_supp_terms_id;
                            END IF;
                        END IF;
					END IF;

			        -- To check whether the supplier is Consignment Supplier
                    IF p_source = 'US_OD_TRADE_EDI'
                    THEN
			            lc_status := NULL;
						lc_gbl_attr16 := NULL;
                        IF lc_supp_attr_category = 'TR-CON'
				        THEN
				           lc_cons_vendor_flag := 'Y';
				           lc_status := 'CONS_REJECTED';
						   lc_gbl_attr16 := 'PROCESSED';
				        ELSE
				           lc_status := NULL;
						   lc_gbl_attr16 := NULL;
				        END IF;
					ELSIF p_source = 'US_OD_TDM' AND l_header_tab(indx).voucher_type = '1' -- Added as per version 1.9
					THEN
					    lc_status := NULL;
						lc_gbl_attr16 := NULL;
                        IF lc_supp_attr_category = 'TR-CON'
				        THEN
				           lc_cons_vendor_flag := 'Y';
				           lc_status := 'CONS_REJECTED';
						   lc_gbl_attr16 := 'PROCESSED';
				        ELSE
				           lc_status := NULL;
						   lc_gbl_attr16 := NULL;
				        END IF;
			        END IF;

                    print_debug_msg ('Insert into xx_ap_inv_interface_stg - Invoice_id=['||to_char(l_header_tab(indx).invoice_id)||']',FALSE);

				    INSERT
					    INTO
						  xx_ap_inv_interface_stg( invoice_id ,
													  invoice_num ,
													  invoice_type_lookup_code ,
													  invoice_date ,
													  po_number ,
													  vendor_id ,
													  vendor_num ,
													  vendor_name ,
													  vendor_site_id ,
													  vendor_site_code ,
													  invoice_amount ,
													  invoice_currency_code,
													  exchange_rate,
													  exchange_rate_type,
													  exchange_date,
													  terms_id ,
													  terms_name,
													  description,
													  awt_group_id,
													  awt_group_name ,
													  last_update_date ,
													  last_updated_by ,
													  last_update_login ,
													  creation_date ,
													  created_by ,
													  attribute_category ,
													  attribute1,
													  attribute2,
													  attribute3,
													  attribute4,
													  attribute5,
													  attribute6,
													  attribute7,
													  attribute8,
													  attribute9,
													  attribute10,
													  attribute11,
													  attribute12,
													  attribute13,
													  attribute14,
													  attribute15,
													  global_attribute_category,
													  global_attribute1 ,
													  global_attribute2 ,
													  global_attribute3 ,
													  global_attribute4 ,
													  global_attribute5 ,
													  global_attribute6 ,
													  global_attribute7 ,
													  global_attribute8 ,
													  global_attribute9 ,
													  global_attribute10,
													  global_attribute11,
													  global_attribute12,
													  global_attribute13,
													  global_attribute14,
													  global_attribute15,
													  global_attribute16,
													  global_attribute17,
													  global_attribute18,
													  global_attribute19,
													  global_attribute20,
													  status,
													  source,
													  group_id,
													  request_id ,
													  payment_cross_rate_type,
													  payment_cross_rate_date,
													  payment_cross_rate,
													  payment_currency_code,
													  workflow_flag,
													  doc_category_code,
													  voucher_num,
													  payment_method_lookup_code,
													  pay_group_lookup_code,
													  goods_received_date,
													  invoice_received_date,
													  gl_date,
													  accts_pay_code_combination_id,
													  ussgl_transaction_code,
													  exclusive_payment_flag,
													  org_id,
													  amount_applicable_to_discount,
													  prepay_num,
													  prepay_dist_num ,
													  prepay_apply_amount ,
													  prepay_gl_date,
													  invoice_includes_prepay_flag ,
													  no_xrate_base_amount,
													  vendor_email_address,
													  terms_date,
													  requester_id,
													  ship_to_location ,
													  external_doc_ref,
													  batch_id)
											 VALUES ( l_header_tab(indx).invoice_id,
												     -- l_header_tab(indx).invoice_number ,
													  LTRIM(regexp_replace(l_header_tab(indx).invoice_number , '(*[[:punct:]])', ''),'0'), -- Invoice Number
												      lc_invoice_type_lookup_code ,  -- invoice_type_lookup_code
												      NVL(l_header_tab(indx).invoice_date , SYSDATE), -- invoice_date
													  CASE WHEN l_header_tab(indx).voucher_type <> '1' THEN NULL               -- version 4.6
														     ELSE l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
													  END,  -- po_number
												      null,  -- vendor_id
												      null,  -- vendor_num
												      null,  -- vendor_name
												      null,  -- vendor_site_id
												      null,  -- vendor_site_code
                                                      ROUND(l_header_tab(indx).gross_amt,2),	--invoice_amount
												      null,  -- invoice_currency_code
												      null,  -- exchange_rate
												      null,  -- exchange_rate_type
												      null,  -- exchange_date
												      l_header_tab(indx).terms_id,  -- terms_id
												      l_header_tab(indx).terms_name,  -- terms_name
												      DECODE(p_source,'US_OD_RTV_MERCHANDISING',l_header_tab(indx).check_description,
													                  'US_OD_DROPSHIP',l_header_tab(indx).check_description,
																	  'US_OD_TRADE_EDI',l_header_tab(indx).check_description,
																	  'US_OD_CONSIGNMENT_SALES',NULL,
																	  'US_OD_TDM', l_header_tab(indx).default_po||' '||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0'),  -- version 4.6
																	  'US_OD_DCI_TRADE',l_header_tab(indx).default_po||' '||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')  -- version 4.6
				                                            ), -- description -- Modified as per Version 1.6
												      null,  -- awt_group_id
												      null,  -- awt_group_name
												      sysdate, -- last_update_date
												      gn_user_id, -- last_updated_by
												      gn_login_id, -- last_update_login
												      sysdate, -- creation_date
												      gn_user_id, -- created_by
												      null,  -- attribute_category
												      null,  -- attribute1
												      null,  -- attribute2
												      null,  -- attribute3
												      null,  -- attribute4
												      null,  -- attribute5 -- PO Type
												      null,  -- attribute6
												      p_source,  -- attribute7
												      null,  -- attribute8
												      DECODE(p_source,'US_OD_TDM','0'||l_header_tab(indx).dcn_number
                                                                        ,'US_OD_DCI_TRADE' ||l_header_tab(indx).dcn_number
                                                                        ,null),	 --  DCN Number
												      /*DECODE(p_source,'US_OD_DROPSHIP','000'||l_header_tab(indx).ap_vendor
                                                                        ,DECODE(p_source,'US_OD_TRADE_EDI','00'||l_header_tab(indx).ap_vendor,'0'||l_header_tab(indx).ap_vendor)), --  Vendor Site ID */
                                                      LPAD(lc_supplier_site_code,10,'0'),	 --  Vendor Site Code
												      l_header_tab(indx).default_po, -- Legacy PO Number
												      null,  -- attribute12
													  l_header_tab(indx).voucher_type ,  -- attribute13
													  null,  -- attribute14
													  null, --attribute15, -- Release Number
													  null,  -- global_attribute_category
													  null,  -- global_attribute1
													  null,  -- global_attribute2
													  null,  -- global_attribute3
													  null,  -- global_attribute4
													  null,  -- global_attribute5
													  null,  -- global_attribute6
													  null,  -- global_attribute7
													  null,  -- global_attribute8
													  null,  -- global_attribute9
													  null,  -- global_attribute10
													  null,  -- global_attribute11
													  null,  -- global_attribute12
													  null,  -- global_attribute13
													  null,  -- global_attribute14
													  null,  -- global_attribute15
													  lc_gbl_attr16,  -- global_attribute16  -- 'PROCESSED' or not
													  null,  -- global_attribute17
													  null,  -- global_attribute18
													  null,  -- global_attribute19
													  l_header_tab(indx).gross_amt_sign,  -- global_attribute20
													  lc_status,  -- status
													  l_header_tab(indx).source, -- source
													  DECODE(l_header_tab(indx).source,'US_OD_TDM','TDM-TRADE',null),  --group_id,
													  gn_request_id,  -- request_id
													  null,  -- payment_cross_rate_type,
													  null, -- payment_cross_rate_date
													  null, -- payment_cross_rate,
													  null, -- payment_currency_code
													  null, -- workflow_flag
													  null, -- doc_category_code
													  null, -- l_header_tab(indx).voucher,  -- voucher_num
													  l_header_tab(indx).payment_method_lookup_code,  -- payment_method_lookup_code
													  l_header_tab(indx).pay_group,
													  null, -- goods_received_date
													  null, -- invoice_received_date
													  null, -- gl_date
													  NULL, -- accts_pay_code_combination_id
													  null, -- ussgl_transaction_code
													  null, -- exclusive_payment_flag
													  null, -- org_id
													  null, -- amount_applicable_to_discount
													  null, -- prepay_num
													  null, -- prepay_dist_num
													  null, -- prepay_apply_amount
													  null, -- prepay_gl_date
													  null, -- invoice_includes_prepay_flag
													  null, -- no_xrate_base_amount
													  null, -- vendor_email_address
													  l_header_tab(indx).terms_date, -- terms_date
													  null, -- requester_id
													  null, -- ship_to_location
													  null, -- external_doc_ref
													  null  -- batch_id
													 );
			    ln_hdr_success_records  := ln_hdr_success_records + 1;

				l_header_tab(indx).record_status := 'C';
				l_header_tab(indx).error_description := NULL;

				-- To Fetch the lines records

				ln_line_number := 0;
	            ln_invoice_id  := 0;

			IF p_source <> 'US_OD_CONSIGNMENT_SALES'
			THEN
                OPEN lines_cur(p_invoice_id => l_header_tab(indx).invoice_id,
				               p_source => p_source);
                LOOP
	                l_lines_tab.DELETE;  --- Deleting the data in the Table type
                    FETCH lines_cur BULK COLLECT INTO l_lines_tab LIMIT ln_batch_size;
                    EXIT WHEN l_lines_tab.COUNT = 0;

		            FOR l_indx IN l_lines_tab.FIRST..l_lines_tab.LAST
                    LOOP
                        BEGIN
				--------------------------------------
				/* Start of TDM Source Validations */
				--------------------------------------
							-- To create the Freight Line for the NOT Approved TDM Invoices
							IF p_source = 'US_OD_TDM' AND l_lines_tab(l_indx).line_type = 'FREIGHT'
							THEN
		            	 		BEGIN
                                     SELECT MAX(line_num)+1
									   INTO ln_line_number
                                       FROM po_lines_all pol,
                                            po_headers_all poh
                                      WHERE poh.segment1 = l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0') -- version 4.6
                                        AND pol.po_header_id = poh.po_header_id;
								EXCEPTION
								WHEN OTHERS
								THEN
								    ln_line_number:= NULL;
								END;

		            	    ELSE
							   IF ln_invoice_id = l_lines_tab(l_indx).invoice_id
                               THEN
		            	           ln_line_number := ln_line_number+1;
		            	       ELSE
		            	           ln_line_number := 1;
		            		       ln_invoice_id := l_lines_tab(l_indx).invoice_id;
		            	       END IF;
							END IF;

							-- To get the inventory item id
							IF p_source <> 'US_OD_TRADE_EDI'
							THEN
                                IF l_lines_tab(l_indx).sku IS NOT NULL
							    THEN
							        BEGIN
                                       SELECT inventory_item_id
							    	     INTO ln_inventory_item_id
                                         FROM mtl_system_items_b
                                        WHERE segment1 = LTRIM(l_lines_tab(l_indx).sku,'0')
                                          AND ROWNUM = 1;
							    	EXCEPTION
							    	WHEN OTHERS
							    	THEN
							    	    lc_error_msg := SUBSTR(sqlerrm,1,100);
							    		ln_inventory_item_id := NULL;
							    	END;
							    END IF;
							END IF;

							/* Added as per version 2.8 */
							-- To get the GL String for the Below lines
							IF p_source = 'US_OD_TDM' AND l_lines_tab(l_indx).line_type = 'FREIGHT'
							THEN
							    BEGIN
						            ln_ccid := NULL;
				                    ln_accrual_id := NULL;
			                        lc_gl_string := NULL;
				                    ln_acct_id  := NULL;
				                    lc_po_type  := NULL;

				                    SELECT /*+ cardinality(poh 1) */
						                   pod.code_combination_id,
                                           pod.accrual_account_id,
					                       poh.attribute_category
                                      INTO ln_ccid,
                                           ln_accrual_id,
					                       lc_po_type
                                      FROM po_headers_all poh,
                                           po_lines_all pol,
                                           po_distributions_all pod
				                     WHERE poh.po_header_id = pol.po_header_id
                                       AND poh.po_header_id = pod.po_header_id
                                       AND pol.po_line_id = pod.po_line_id
                                       AND poh.segment1 = l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0') -- version 4.6
                                       AND rownum = 1;

			                    EXCEPTION
				                WHEN NO_DATA_FOUND
				                THEN
				                    ln_ccid := NULL;
				                    ln_accrual_id := NULL;
							        lc_po_type := NULL;

				                WHEN OTHERS
                                THEN
				                    ln_ccid := NULL;
				                    ln_accrual_id := NULL;
				        	        lc_po_type := NULL;
                                END;

                                IF lc_po_type LIKE 'DropShip%'
					            THEN
					               lc_drop_ship_flag := 'Y';
						           ln_acct_id        := ln_accrual_id;
								   lc_reason_code    := 'FS';
					            ELSE
					               lc_drop_ship_flag := 'N';
						           ln_acct_id        := ln_ccid;
								   lc_reason_code    := 'FR';
					            END IF;

					            BEGIN
					                SELECT gcck.concatenated_segments
						              INTO lc_gl_string
						              FROM gl_code_combinations_kfv gcck
						             WHERE gcck.code_combination_id = ln_acct_id;
					            EXCEPTION
					            WHEN OTHERS
						        THEN
				    	            lc_gl_string := NULL;
				                END;

	                            -- To get the GL information for the below lines
                                BEGIN
                                    SELECT target_value4,
                                           target_value5,
                                           target_value6,
                                           target_value7,
                                           target_value8,
			        	            	   target_value2
                                      INTO lc_company,
                                           lc_cost_center,
                                           lc_oracle_account,
                                           lc_location,
                                           lc_lob,
			        	            	   lc_description
		                              FROM xx_fin_translatevalues
	                                 WHERE translate_id IN (SELECT translate_id
		                             						  FROM xx_fin_translatedefinition
		                             					     WHERE translation_name = 'OD_AP_REASON_CD_ACCT_MAP'
		                             						   AND enabled_flag = 'Y')
		                               AND target_value1 = lc_reason_code;
                                EXCEPTION
	                                WHEN OTHERS
	                                THEN
	                                    lc_company := NULL;
	                                    lc_cost_center := NULL;
	                                    lc_oracle_account := NULL;
	                                    lc_location := NULL;
	                                    lc_lob := NULL;
			        	                lc_description := NULL;
                                END;

								l_lines_tab(l_indx).gl_company := NVL(lc_company,SUBSTR(lc_gl_string,1,4));
		            			l_lines_tab(l_indx).gl_cost_center := NVL(lc_cost_center,SUBSTR(lc_gl_string,6,5));
		            			l_lines_tab(l_indx).gl_account := NVL(lc_oracle_account,SUBSTR(lc_gl_string,12,8));
		            			l_lines_tab(l_indx).gl_location := NVL(lc_location,SUBSTR(lc_gl_string,21,6));
		            			l_lines_tab(l_indx).gl_inter_company := NVL(SUBSTR(lc_gl_string,28,4),'0000');
		            			l_lines_tab(l_indx).gl_lob := NVL(lc_lob,SUBSTR(lc_gl_string,33,2));
		            			l_lines_tab(l_indx).gl_future := NVL(SUBSTR(lc_gl_string,36,6),'000000');
								l_lines_tab(l_indx).line_description := lc_description;

                            END IF; -- p_source = 'US_OD_TDM' AND l_lines_tab(l_indx).line_type = 'FREIGHT'
				-------------------------------------
				/* End of TDM Source Validations */
				-------------------------------------

				--------------------------------------
				/* Start of EDI Source Validations */
				--------------------------------------

							-- To get the Unit of Measure for the UOM
							IF p_source = 'US_OD_TRADE_EDI' AND l_lines_tab(l_indx).line_type = 'ITEM'
							THEN
							    BEGIN
								   SELECT unit_of_measure
                                     INTO lc_unit_of_measure
                                     FROM mtl_units_of_measure
                                    WHERE uom_code = l_lines_tab(l_indx).unit_of_measure;
								EXCEPTION
								WHEN OTHERS
								THEN
								    lc_unit_of_measure := NULL;
								END;
							END IF; -- p_source = 'US_OD_TRADE_EDI' AND l_lines_tab(l_indx).line_type = 'ITEM'

							-- Validations for the Source US_OD_TRADE_EDI
							IF p_source = 'US_OD_TRADE_EDI'
							THEN
							    lc_line_type := l_lines_tab(l_indx).line_type;
								lc_attr3 := NULL;
								lc_uom   := NULL;

							    IF l_lines_tab(l_indx).line_type = 'ITEM'
	                            THEN
	                                -- To derive the Inventory Item ID
-- change 4.4
	                                get_inventory_item_id(p_sku               =>  l_lines_tab(l_indx).sku
			                                             ,p_po_number         =>  l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
						                                 ,o_inventory_item_id =>  ln_inventory_item_id
														 ,o_po_type           =>  lc_po_type);

                                    /* Changes done as per Version 1.2 */
			                        IF  ln_inventory_item_id IS NOT NULL
			                        THEN

										IF lc_po_type LIKE 'DropShip%'
	                                    THEN
		                                    lc_drop_ship_flag := 'Y';
					                        lc_receipt_required_flag := 'N';
	                                    ELSE
		                                    lc_drop_ship_flag := 'N';
					                        lc_receipt_required_flag := 'Y';
	                                    END IF;

	                                  -- To derive the Drop ship flag and PO Line Num
-- change 4.4
	                                    get_po_line_num(p_po_number          => l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
			    	                                   ,p_inventory_item_id  => ln_inventory_item_id
													   ,p_sku                => l_lines_tab(l_indx).sku
			    		                               ,p_unit_price         => TO_NUMBER(l_lines_tab(l_indx).cost)
			    		                               ,p_quantity           => TO_NUMBER(l_lines_tab(l_indx).quantity)
													   ,p_inv_line_num       => ln_line_number
													   ,p_invoice_id         => l_header_tab(indx).invoice_id
			    		                               ,o_po_attr_category   => lc_po_type
			    		                               ,o_po_line_num        => ln_po_line_num
													   ,o_uom_code           => lc_uom);

										-- Updating the PO Line number in the Pre-staging table

										BEGIN
										   UPDATE xx_ap_trade_inv_lines
										      SET po_line_number = ln_po_line_num,
											      last_update_date  = sysdate,
	                                              last_updated_by   = gn_user_id,
	                                              last_update_login = gn_login_id
											WHERE invoice_line_id = l_lines_tab(l_indx).invoice_line_id;
										EXCEPTION
										   WHEN OTHERS
										   THEN
										       print_debug_msg ('Unable to update the PO Line Number for the - Invoice_line_id=['||to_char(l_lines_tab(l_indx).invoice_line_id)||']',FALSE);
										END;

										-- Checking if the quantity is zero and pass the quantity as 0.00000000001
					                    IF l_lines_tab(l_indx).quantity = '0'
					                    THEN
					                        l_lines_tab(l_indx).quantity := '0.00000000001';
					                    END IF;

				                        IF ln_po_line_num IS NULL
				                        THEN
										   /*
				                            BEGIN
		                                      SELECT attribute_category
		                                        INTO lc_po_type
		                                        FROM po_headers_all
			                                   WHERE segment1 = LTRIM(l_header_tab(indx).default_po,'0')||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0');
		                                    EXCEPTION
		                                    WHEN OTHERS
		                                    THEN
		                                        lc_po_type := NULL;
		                                    END;

					                        IF lc_po_type LIKE 'DropShip%'
	                                        THEN
		                                        lc_drop_ship_flag := 'Y';
					                            lc_receipt_required_flag := 'N';
	                                        ELSE
		                                        lc_drop_ship_flag := 'N';
					                            lc_receipt_required_flag := 'Y';
	                                        END IF;
										   */

											lc_ret_status := NULL;
											lc_stg_uom_code := l_lines_tab(l_indx).unit_of_measure;
											lc_uom := lc_unit_of_measure;

					                         /* Changes done as per Version 1.3 */
					                        -- Creating the new PO Line if Line does not exist in the PO
				                            xx_po_pom_int_pkg.add_po_line(p_batch_id          => gn_batch_id
-- change 4.4
                                                                         ,p_po_number         => l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
                                                                         ,p_item_id           => ln_inventory_item_id
                                              	                         ,p_quantity          => TO_NUMBER('0.00000000001')
                                              	                         ,p_price             => TO_NUMBER('0.01')
					                        							 ,p_receipt_req_flag  => lc_receipt_required_flag
																		 ,p_uom_code          => lc_stg_uom_code
                                              	                         ,p_line_num          => ln_po_line_num
					                        	                         ,p_return_status     => lc_ret_status
					                        	                         ,p_error_message     => lc_error_msg
					                        							 );

					                        IF  lc_ret_status ='E'
					                        THEN
					                            ln_po_line_num := NULL;
												fnd_file.put_line(fnd_file.log, 'Error while creating the PO line ...'|| lc_error_msg); --Added for #45074
				                            END IF;

                                        END IF; -- ln_po_line_num IS NULL

			                        ELSE -- Creating the MISCELLANEOUS Line with just Line Amount

									    BEGIN
		                                    SELECT attribute_category
		                                      INTO lc_po_type
		                                      FROM po_headers_all
-- change 4.4
			                                 WHERE segment1 = l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0');
		                                EXCEPTION
		                                WHEN OTHERS
		                                THEN
		                                     lc_po_type := NULL;
		                                END;

										IF lc_po_type IS NOT NULL
										THEN
			                                l_lines_tab(l_indx).cost := NULL;
				                            l_lines_tab(l_indx).quantity := NULL;
				                            ln_inventory_item_id := NULL;
				                            l_lines_tab(l_indx).line_type := 'MISCELLANEOUS';
										 ELSE

										    -- Calling the procedure
											xx_po_pom_int_pkg.valid_and_mark_missed_po_int( p_source => 'INVOICE-EDI'
		   		                                                                           ,p_source_record_id  => l_lines_tab(l_indx).invoice_line_id
--	change 4.4
		   		                                                                           ,p_po_number    => l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
		   		                                                                           ,p_po_line_num  => NULL
		   		                                                                           ,p_result       => lc_ret_status
																						   );
										END IF;

			                        END IF; -- ln_inventory_item_id IS NOT NULL

	                            END IF; --  l_lines_tab(l_indx).line_type = 'ITEM'

                                IF l_lines_tab(l_indx).line_type <> 'ITEM'
	                            THEN
                                    l_lines_tab(l_indx).cost := NULL;
				                    l_lines_tab(l_indx).quantity := NULL;
				                    ln_inventory_item_id := NULL;

                                    IF lc_line_type = 'FREIGHT'
                                    THEN
		                        	  -- To get the Reason Code for the Below lines
		                        	    BEGIN
		                        	        SELECT target_value2, target_value3
		                        	          INTO l_lines_tab(l_indx).reason_code, lc_sac_code_sign
		                                      FROM xx_fin_translatevalues
		                                     WHERE translate_id IN (SELECT translate_id
                                                                      FROM xx_fin_translatedefinition
		                                         					 WHERE translation_name = 'XX_AP_SAC_REASON_CODES' -- 'XX_AP_SAC_CODE'
		                                         					   AND enabled_flag = 'Y')
                                                                       AND target_value1 = l_lines_tab(l_indx).sac_code;
		                        	    EXCEPTION
		                        	    WHEN OTHERS
		                        	    THEN
		                        	        l_lines_tab(l_indx).reason_code:= 'DEFAULT';
		                        	    	lc_sac_code_sign := '+';
		                        	    END;
		                        	ELSIF lc_line_type = 'ITEM'
		                        	THEN
		                        	    l_lines_tab(l_indx).reason_code:= 'DEFAULT1';
		                        	    lc_sac_code_sign := '+';
		                        	END IF;

		                        	BEGIN
		                        	    ln_ccid := NULL;
		                        		ln_accrual_id := NULL;
		                        	    lc_gl_string := NULL;
		                        		ln_acct_id  := NULL;
		                        		lc_po_type  := NULL;

		                        		SELECT pod.code_combination_id,
                                               pod.accrual_account_id,
		                        			   poh.attribute_category
                                          INTO ln_ccid,
                                               ln_accrual_id,
		                        			   lc_po_type
                                          FROM po_headers_all poh,
                                               po_lines_all pol,
                                               po_distributions_all pod
		                        		 WHERE poh.po_header_id = pol.po_header_id
                                           AND poh.po_header_id = pod.po_header_id
                                           AND pol.po_line_id = pod.po_line_id
-- change 4.4
                                           AND poh.segment1 = l_header_tab(indx).default_po||'-'||LPAD(LTRIM(l_header_tab(indx).location_id,'0'),4,'0')
                                           AND pol.line_num = 1;
		                        	EXCEPTION
		                        		WHEN NO_DATA_FOUND
		                        		THEN
		                        		    ln_ccid := NULL;
		                        			ln_accrual_id := NULL;
		                        		    lc_po_type := NULL;
		                        			print_debug_msg ('No GL String found :',FALSE);
		                        		WHEN OTHERS
                                        THEN
		                        		    ln_ccid := NULL;
		                        			ln_accrual_id := NULL;
		                        			lc_po_type := NULL;
		                        		    print_debug_msg ('Error Message :'||SUBSTR(SQLERRM,1,255),FALSE);
                                    END;

		                        	IF lc_po_type LIKE 'DropShip%'
	                                THEN
		                                lc_drop_ship_flag := 'Y';
		                        		ln_acct_id        := ln_accrual_id;
	                                ELSE
		                                lc_drop_ship_flag := 'N';
		                        		ln_acct_id        := ln_ccid;
	                                END IF;

		                        	-- To get the GL String for the Miscellaneous Lines
		                        	BEGIN

		                        	    SELECT /*+ INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */
                                               gcck.concatenated_segments
		                        		  INTO lc_gl_string
		                        		  FROM gl_code_combinations_kfv gcck
		                        		 WHERE gcck.code_combination_id = ln_acct_id;
		                        	EXCEPTION
		                        	    WHEN OTHERS
		                        		THEN
		                        		     lc_gl_string := NULL;
		                        	END;

	                                -- To get the GL information for the below lines
                                    BEGIN
                                        SELECT target_value4,
                                               target_value5,
                                               target_value6,
                                               target_value7,
                                               target_value8,
		                                 	   target_value10,
		                        			   target_value2
                                          INTO lc_company,
                                               lc_cost_center,
                                               lc_oracle_account,
                                               lc_location,
                                               lc_lob,
		                                 	   lc_drop_ship_acct,
		                        			   lc_description
		                                  FROM xx_fin_translatevalues
	                                     WHERE translate_id IN (SELECT translate_id
		                                 						  FROM xx_fin_translatedefinition
		                                 					     WHERE translation_name = 'OD_AP_REASON_CD_ACCT_MAP'
		                                 						   AND enabled_flag = 'Y')
		                                   AND target_value1 = DECODE(l_lines_tab(l_indx).reason_code,'FR',DECODE(lc_drop_ship_flag,'Y','FS','FR'),l_lines_tab(l_indx).reason_code);
                                    EXCEPTION
	                                WHEN OTHERS
	                                THEN
	                                    lc_company := NULL;
	                                    lc_cost_center := NULL;
	                                    lc_oracle_account := NULL;
	                                    lc_location := NULL;
	                                    lc_lob := NULL;
		                                lc_drop_ship_acct := NULL;
		                        		lc_description := NULL;
                                    END;

		                        	-- To get the line type for the below lines
		                        	IF l_lines_tab(l_indx).reason_code IN ('FR','FS','FP')
		                        	THEN
		                        	    l_lines_tab(l_indx).line_type := 'FREIGHT';
		                        	ELSE
		                        	    l_lines_tab(l_indx).line_type := 'MISCELLANEOUS';
		                        	END IF;

                                END IF; -- l_lines_tab(l_indx).line_type <> 'ITEM'

								-- To derive the GL Information and Line Amount
								IF l_lines_tab(l_indx).line_type <> 'ITEM' -- AND lc_line_type <> 'ITEM'
								THEN
								    IF lc_sac_code_sign = '+'
									THEN
								        l_lines_tab(l_indx).mdse_amount := 1 * l_lines_tab(l_indx).mdse_amount ;
									ELSE
									    l_lines_tab(l_indx).mdse_amount := (-1) * l_lines_tab(l_indx).mdse_amount;
									END IF; -- lc_sac_code_sign

								   	IF l_lines_tab(l_indx).reason_code <> 'DEFAULT'
									THEN
									    l_lines_tab(l_indx).gl_company := NVL(lc_company,SUBSTR(lc_gl_string,1,4));
		            			        l_lines_tab(l_indx).gl_cost_center := NVL(lc_cost_center,SUBSTR(lc_gl_string,6,5));
		            			        l_lines_tab(l_indx).gl_account := NVL(lc_oracle_account,SUBSTR(lc_gl_string,12,8));
		            			        l_lines_tab(l_indx).gl_location := NVL(lc_location,SUBSTR(lc_gl_string,21,6));
		            			        l_lines_tab(l_indx).gl_inter_company := NVL(SUBSTR(lc_gl_string,28,4),'0000');
		            			        l_lines_tab(l_indx).gl_lob := NVL(lc_lob,SUBSTR(lc_gl_string,33,2));
		            			        l_lines_tab(l_indx).gl_future := NVL(SUBSTR(lc_gl_string,36,6),'000000');
								        l_lines_tab(l_indx).line_description := lc_description;
										l_lines_tab(l_indx).po_line_number   := NULL;

										IF l_lines_tab(l_indx).reason_code = 'FR'
										THEN
										    IF lc_drop_ship_flag = 'Y'
											THEN
											    l_lines_tab(l_indx).reason_code := 'FS';
											ELSE
											    l_lines_tab(l_indx).reason_code := 'FR';
											END IF; -- lc_drop_ship_flag
										ELSIF l_lines_tab(l_indx).reason_code = 'DEFAULT1'
                                        THEN
                                            l_lines_tab(l_indx).reason_code := NULL;
											lc_attr3 := 'Y';
                                        ELSE
										    l_lines_tab(l_indx).reason_code := l_lines_tab(l_indx).reason_code;
										END IF;

									ELSE
									    l_lines_tab(l_indx).gl_company       := NULL;
		            			        l_lines_tab(l_indx).gl_cost_center   := NULL;
		            			        l_lines_tab(l_indx).gl_account       := NULL;
		            			        l_lines_tab(l_indx).gl_location      := NULL;
		            			        l_lines_tab(l_indx).gl_inter_company := NULL;
		            			        l_lines_tab(l_indx).gl_lob           := NULL;
		            			        l_lines_tab(l_indx).gl_future        := NULL;
								        l_lines_tab(l_indx).line_description := NULL;
										l_lines_tab(l_indx).reason_code      := 'DEFAULT';
										l_lines_tab(l_indx).po_line_number   := NULL;
									END IF; -- l_lines_tab(l_indx).reason_code <> 'DEFAULT'
								ELSE
                                    l_lines_tab(l_indx).gl_company       := NULL;
		            			    l_lines_tab(l_indx).gl_cost_center   := NULL;
		            			    l_lines_tab(l_indx).gl_account       := NULL;
		            			    l_lines_tab(l_indx).gl_location      := NULL;
		            			    l_lines_tab(l_indx).gl_inter_company := NULL;
		            			    l_lines_tab(l_indx).gl_lob           := NULL;
		            			    l_lines_tab(l_indx).gl_future        := NULL;
								    l_lines_tab(l_indx).po_line_number   := ln_po_line_num;

                                   /*
                                    IF l_lines_tab(l_indx).cost_sign = '+'
									THEN
								        l_lines_tab(l_indx).mdse_amount := TO_NUMBER(l_lines_tab(l_indx).cost) * TO_NUMBER(l_lines_tab(l_indx).quantity);
									ELSE
									    l_lines_tab(l_indx).mdse_amount := (-1) * TO_NUMBER(l_lines_tab(l_indx).cost) * TO_NUMBER(l_lines_tab(l_indx).quantity);
									END IF;  -- l_lines_tab(l_indx).cost_sign
									*/

									IF lc_drop_ship_flag = 'Y'
									THEN
									    l_lines_tab(l_indx).line_description := NULL;
									ELSE
									    l_lines_tab(l_indx).line_description := 'MERCHANDISE ACCT SYS';
									END IF; -- lc_drop_ship_flag
								END IF;

							END IF; -- p_source = 'US_OD_TRADE_EDI

                            print_debug_msg ('Insert into xx_ap_inv_lines_interface_stg - Invoice_line_id=['||to_char(l_lines_tab(l_indx).invoice_line_id)||']',FALSE);
	                        INSERT
							    INTO xx_ap_inv_lines_interface_stg(
                                                            invoice_id                   ,
		            										invoice_line_id              ,
		            										line_number                  ,
		            										line_type_lookup_code        ,
		            										line_group_number            ,
		            										amount                       ,
		            										accounting_date              ,
		            										description                  ,
		            										amount_includes_tax_flag     ,
		            										prorate_across_flag          ,
		            										tax_code                     ,
		            										final_match_flag             ,
		            										po_header_id                 ,
		            										po_number                    ,
		            										po_line_id                   ,
		            										po_line_number               ,
		            										po_line_location_id          ,
		            										po_shipment_num              ,
		            										po_distribution_id           ,
		            										po_distribution_num          ,
		            										po_unit_of_measure           ,
		            										inventory_item_id            ,
		            										item_description             ,
		            										quantity_invoiced            ,
		            										ship_to_location_code        ,
		            										unit_price                   ,
		            										distribution_set_id          ,
		            										distribution_set_name        ,
		            										dist_code_concatenated       ,
		            										dist_code_combination_id     ,
		            										awt_group_id                 ,
		            										awt_group_name               ,
		            										last_updated_by              ,
		            										last_update_date             ,
		            										last_update_login            ,
		            										created_by                   ,
		            										creation_date                ,
		            										attribute_category           ,
		            										attribute1                   ,
		            										attribute2                   ,
		            										attribute3                   ,
		            										attribute4                   ,
		            										attribute5                   ,
		            										attribute6                   ,
		            										attribute7                   ,
		            										attribute8                   ,
		            										attribute9                   ,
		            										attribute10                  ,
		            										attribute11                  ,
		            										attribute12                  ,
		            										attribute13                  ,
		            										attribute14                  ,
		            										attribute15                  ,
		            										global_attribute_category    ,
		            										global_attribute1            ,
		            										global_attribute2            ,
		            										global_attribute3            ,
		            										global_attribute4            ,
		            										global_attribute5            ,
		            										global_attribute6            ,
		            										global_attribute7            ,
		            										global_attribute8            ,
		            										global_attribute9            ,
		            										global_attribute10           ,
		            										global_attribute11           ,
		            										global_attribute12           ,
		            										global_attribute13           ,
		            										global_attribute14           ,
		            										global_attribute15           ,
		            										global_attribute16           ,
		            										global_attribute17           ,
		            										global_attribute18           ,
		            										global_attribute19           ,
		            										global_attribute20           ,
		            										po_release_id                ,
		            										release_num                  ,
		            										account_segment              ,
		            										balancing_segment            ,
		            										cost_center_segment          ,
		            										project_id                   ,
		            										task_id                      ,
		            										expenditure_type             ,
		            										expenditure_item_date        ,
		            										expenditure_organization_id  ,
		            										project_accounting_context   ,
		            										pa_addition_flag             ,
		            										pa_quantity                  ,
		            										ussgl_transaction_code       ,
		            										stat_amount                  ,
		            										type_1099                    ,
		            										income_tax_region            ,
		            										assets_tracking_flag         ,
		            										price_correction_flag        ,
		            										org_id                       ,
		            										receipt_number               ,
		            										receipt_line_number          ,
		            										match_option                 ,
		            										packing_slip                 ,
		            										rcv_transaction_id           ,
		            										pa_cc_ar_invoice_id          ,
		            										pa_cc_ar_invoice_line_num    ,
		            										reference_1                  ,
		            										reference_2                  ,
		            										pa_cc_processed_code         ,
		            										tax_recovery_rate            ,
		            										tax_recovery_override_flag   ,
		            										tax_recoverable_flag         ,
		            										tax_code_override_flag       ,
		            										tax_code_id                  ,
		            										credit_card_trx_id           ,
		            										award_id                     ,
		            										vendor_item_num              ,
		            										taxable_flag                 ,
		            										price_correct_inv_num        ,
		            										external_doc_line_ref        ,
		            										vendor_num                   ,
		            										invoice_num                  ,
		            										legacy_segment1              ,
		            										legacy_segment2              ,
		            										legacy_segment3              ,
		            										legacy_segment4              ,
		            										legacy_segment5              ,
		            										legacy_segment6              ,
		            										legacy_segment7              ,
		            										legacy_segment8              ,
		            										legacy_segment9              ,
		            										legacy_segment10             ,
		            										reason_code                  ,
		            										oracle_gl_company            ,
		            										oracle_gl_cost_center        ,
		            										oracle_gl_location           ,
		            										oracle_gl_account            ,
		            										oracle_gl_intercompany       ,
		            										oracle_gl_lob                ,
		            										oracle_gl_future1)
                                                    VALUES (l_lines_tab(l_indx).invoice_id, -- invoice_id
		            										NVL(l_lines_tab(l_indx).invoice_line_id,ap_invoice_lines_interface_s.NEXTVAL), -- invoice_line_id
		            										ln_line_number, --line_number
		            										l_lines_tab(l_indx).line_type, -- line_type_lookup_code
		            										NULL, -- line_group_number
		            										ROUND(l_lines_tab(l_indx).mdse_amount,2),	--invoice_amount
		            										NULL, -- accounting_date
		            										l_lines_tab(l_indx).line_description, -- description   -- /* Added as per Version 1.5 */
		            										NULL, -- amount_includes_tax_flag
		            										NULL, -- prorate_across_flag
		            										NULL, -- tax_code
		            										NULL, -- final_match_flag
		            										NULL, -- po_header_id
		            										NULL, -- po_number
		            										NULL, -- po_line_id
		            										l_lines_tab(l_indx).po_line_number, -- po_line_number
		            										NULL, -- po_line_location_id
		            										NULL, -- po_shipment_num
		            										NULL, -- po_distribution_id
		            										NULL, -- po_distribution_num
		            										NULL, -- po_unit_of_measure
		            										ln_inventory_item_id, -- inventory_item_id
		            										NULL, -- item_description
		            										l_lines_tab(l_indx).quantity, -- quantity_invoiced
		            										NULL, -- ship_to_location_code
		            										l_lines_tab(l_indx).cost, -- unit_price
		            										NULL, -- distribution_set_id
		            										NULL, -- distribution_set_name
                                                            DECODE(l_lines_tab(l_indx).po_line_number,
                                                                   NULL,
		            										       SUBSTR(l_lines_tab(l_indx).gl_company,1,4)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_cost_center,1,5)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_account,1,8)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_location,1,6)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_inter_company,1,4)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_lob,1,2)||'.'||
		            										       SUBSTR(l_lines_tab(l_indx).gl_future,1,6),
		            											   NULL
		            										   ), --dist_code_concatenated
		            										NULL, --  dist_code_combination_id
		            										NULL, -- awt_group_id
		            										NULL, -- awt_group_name
		            										gn_user_id, -- last_updated_by
		            										SYSDATE, -- last_update_date
		            										gn_user_id, -- last_update_login
		            										gn_user_id, -- created_by
		            										SYSDATE, -- creation_date
		            										NULL, -- attribute_category
		            										NULL, -- attribute1
		            										NULL, -- attribute2
		            										DECODE(l_lines_tab(l_indx).line_type,'ITEM',NULL,lc_attr3), -- attribute3 -- To identify the Miscellaneous Line with Invalid SKU
		            										DECODE(l_lines_tab(l_indx).line_type,'ITEM',lc_unit_of_measure,NULL), -- attribute4  -- Invoice Unit of Measure
		            										DECODE(l_lines_tab(l_indx).line_type,'ITEM',lc_uom,NULL), -- attribute5  -- PO Unit of Measure
		            										NULL, -- attribute6
		            										NULL, -- attribute7
		            										NULL, -- attribute8
		            										NULL, -- attribute9
		            										NULL, -- attribute10
		            										l_lines_tab(l_indx).reason_code, -- attribute11
		            										NULL, -- attribute12
		            										NULL, -- attribute13
		            										NULL, -- attribute14
		            										NULL, -- attribute15
		            										NULL, -- global_attribute_category
		            										NULL, -- global_attribute1
		            										NULL, -- global_attribute2
		            										NULL, -- global_attribute3
		            										NULL, -- global_attribute4
		            										NULL, -- global_attribute5
		            										NULL, -- global_attribute6
		            										NULL, -- global_attribute7
		            										NULL, -- global_attribute8
		            										NULL, -- global_attribute9
		            										NULL, -- global_attribute10
		            										NULL, -- global_attribute11
		            										NULL, -- global_attribute12
		            										NULL, -- global_attribute13
		            										NULL, -- global_attribute14
		            										NULL, -- global_attribute15
		            										NULL, -- global_attribute16  -- PROCESSED or Not
		            										NULL, -- global_attribute17
		            										NULL, -- global_attribute18
		            										NULL, -- global_attribute19
		            										NULL, -- global_attribute20
		            										NULL, -- po_release_id
		            										NULL, -- release_num,
		            										NULL, -- account_segment
		            										NULL, -- balancing_segment
		            										NULL, -- cost_center_segment
		            										NULL, -- project_id
		            										NULL, -- task_id
		            										NULL, -- expenditure_type   ?
		            										NULL, -- expenditure_item_date
		            										NULL, -- expenditure_organization_id
		            										NULL, -- project_accounting_context
		            										NULL, -- pa_addition_flag
		            										NULL, -- pa_quantity
		            										NULL, -- ussgl_transaction_code
		            										NULL, -- stat_amount
		            										NULL, -- type_1099
		            										NULL, -- income_tax_region
		            										NULL, -- assets_tracking_flag
		            										NULL, -- price_correction_flag
		            										NULL, -- org_id
		            										NULL, -- receipt_number
		            										NULL, -- receipt_line_number
		            										NULL, -- match_option
		            										NULL, -- packing_slip
		            										NULL, -- rcv_transaction_id
		            										NULL, -- pa_cc_ar_invoice_id
		            										NULL, -- pa_cc_ar_invoice_line_num
		            										NULL, -- reference_1
		            										NULL, -- reference_2
		            										NULL, -- pa_cc_processed_code
		            										NULL, -- tax_recovery_rate
		            										NULL, -- tax_recovery_override_flag
		            										NULL, -- tax_recoverable_flag
		            										NULL, -- tax_code_override_flag
		            										NULL, -- tax_code_id
		            										NULL, -- credit_card_trx_id
		            										NULL, -- award_id
		            										NULL, -- vendor_item_num
		            										NULL, -- taxable_flag
		            										NULL, -- price_correct_inv_num
		            										NULL, -- external_doc_line_ref
		            										NULL, -- vendor_num
		            										NULL, -- invoice_num
		            										NULL, -- legacy_segment1
		            										NULL, -- legacy_segment2
		            										NULL, -- legacy_segment3
		            										NULL, -- legacy_segment4
		            										NULL, -- legacy_segment5
		            										NULL, -- legacy_segment6
		            										NULL, -- legacy_segment7
		            										NULL, -- legacy_segment8
		            										NULL, -- legacy_segment9
		            										NULL, -- legacy_segment10
		            										l_lines_tab(l_indx).reason_code, -- reason_code
		            										SUBSTR(l_lines_tab(l_indx).gl_company,1,4), --oracle_gl_company
		            										SUBSTR(l_lines_tab(l_indx).gl_cost_center,1,5), -- oracle_gl_cost_center
		            										SUBSTR(l_lines_tab(l_indx).gl_location,1,6), -- oracle_gl_location
		            										SUBSTR(l_lines_tab(l_indx).gl_account,1,8), -- oracle_gl_account
		            										SUBSTR(l_lines_tab(l_indx).gl_inter_company,1,4), --  oracle_gl_intercompany
		            										SUBSTR(l_lines_tab(l_indx).gl_lob,1,2), -- oracle_gl_lob
		            										SUBSTR(l_lines_tab(l_indx).gl_future,1,6) -- oracle_gl_future1
		            									);

		            		l_lines_tab(l_indx).record_status := 'C';
		            		l_lines_tab(l_indx).error_description := NULL;
                        EXCEPTION
		            	WHEN OTHERS
		            	THEN
		            	    ROLLBACK;
		            		ln_failed_records  := ln_failed_records + 1;
                            lc_error_msg := SUBSTR(sqlerrm,1,100);
                            print_debug_msg ('Invoice_line_id=['||to_char(l_lines_tab(l_indx).invoice_line_id)||'], RB, '||lc_error_msg,FALSE);
                            l_lines_tab(l_indx).record_status := 'E';
                            l_lines_tab(l_indx).error_description :='Unable to insert the record into xx_ap_inv_lines_interface_stg table for the invoice_line_id :'||l_lines_tab(l_indx).invoice_line_id||' '||lc_error_msg;
		                END;
                    END LOOP; --l_lines_tab

                    BEGIN
	                    print_debug_msg('Starting update of xx_ap_trade_inv_lines #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	                   	FORALL l_indx IN 1..l_lines_tab.COUNT
	                   	SAVE EXCEPTIONS
   		                    UPDATE xx_ap_trade_inv_lines
	                   		   SET record_status = l_lines_tab(l_indx).record_status
	                   		      ,error_description = l_lines_tab(l_indx).error_description
	                 		      ,last_update_date  = sysdate
	                              ,last_updated_by   = gn_user_id
	                              ,last_update_login = gn_login_id
	                   	     WHERE invoice_id = l_lines_tab(l_indx).invoice_id;
		            		COMMIT;
	                EXCEPTION
	                WHEN OTHERS
		            THEN
	                    print_debug_msg('Bulk Exception raised',FALSE);
	                    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	                    FOR i IN 1..ln_err_count
	                    LOOP
	                        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                        lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                        print_debug_msg('Invoice_line_id=['||to_char(l_lines_tab(ln_error_idx).invoice_line_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	                    END LOOP; -- bulk_err_loop FOR UPDATE
	                END;
	                print_debug_msg('Ending Update of xx_ap_trade_inv_lines #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

                END LOOP; --lines_cur
                COMMIT;
                CLOSE lines_cur;

			ELSE
			    OPEN lines_consign_summ_cur(p_invoice_id => l_header_tab(indx).invoice_id,
				                            p_frequency_code => p_frequency_code,
											p_source => p_source);
                LOOP
	                l_lines_consign_summ_tab.DELETE;  --- Deleting the data in the Table type
                    FETCH lines_consign_summ_cur BULK COLLECT INTO l_lines_consign_summ_tab LIMIT ln_batch_size;
                    EXIT WHEN l_lines_consign_summ_tab.COUNT = 0;

		            FOR l_indx IN l_lines_consign_summ_tab.FIRST..l_lines_consign_summ_tab.LAST
                    LOOP
                        BEGIN

		            	    IF ln_invoice_id = l_lines_consign_summ_tab(l_indx).invoice_id
                            THEN
		            	        ln_line_number := ln_line_number+1;
		            	    ELSE
		            	        ln_line_number := 1;
		            		    ln_invoice_id := l_lines_consign_summ_tab(l_indx).invoice_id;
		            	    END IF;
							/* Added as per Version 1.4 */
							get_consign_gl_string (p_vendor_num        => l_header_tab(indx).ap_vendor
				                                  ,p_location_num      => NULL
				                                  ,p_unabsorb_flag     => 'N'
									              ,o_gl_description    => lc_description
									              ,o_gl_company        => lc_company
									              ,o_gl_cost_center    => lc_cost_center
									              ,o_gl_account        => lc_oracle_account
							                      ,o_gl_location       => lc_location
									              ,o_gl_inter_company  => lc_inter_company
									              ,o_gl_lob            => lc_lob
				                                  ,o_gl_future         => lc_future
									              ,o_acct_detail       => lc_acct_detail
		        			                      );
							/* End of changes as per Version 1.4 */
                            print_debug_msg ('Insert into xx_ap_inv_lines_interface_stg - Invoice_line_id=['||to_char(l_lines_consign_summ_tab(l_indx).invoice_line_id)||']',FALSE);
	                        INSERT
							    INTO xx_ap_inv_lines_interface_stg(
                                                            invoice_id                   ,
		            										invoice_line_id              ,
		            										line_number                  ,
		            										line_type_lookup_code        ,
		            										line_group_number            ,
		            										amount                       ,
		            										accounting_date              ,
		            										description                  ,
		            										amount_includes_tax_flag     ,
		            										prorate_across_flag          ,
		            										tax_code                     ,
		            										final_match_flag             ,
		            										po_header_id                 ,
		            										po_number                    ,
		            										po_line_id                   ,
		            										po_line_number               ,
		            										po_line_location_id          ,
		            										po_shipment_num              ,
		            										po_distribution_id           ,
		            										po_distribution_num          ,
		            										po_unit_of_measure           ,
		            										inventory_item_id            ,
		            										item_description             ,
		            										quantity_invoiced            ,
		            										ship_to_location_code        ,
		            										unit_price                   ,
		            										distribution_set_id          ,
		            										distribution_set_name        ,
		            										dist_code_concatenated       ,
		            										dist_code_combination_id     ,
		            										awt_group_id                 ,
		            										awt_group_name               ,
		            										last_updated_by              ,
		            										last_update_date             ,
		            										last_update_login            ,
		            										created_by                   ,
		            										creation_date                ,
		            										attribute_category           ,
		            										attribute1                   ,
		            										attribute2                   ,
		            										attribute3                   ,
		            										attribute4                   ,
		            										attribute5                   ,
		            										attribute6                   ,
		            										attribute7                   ,
		            										attribute8                   ,
		            										attribute9                   ,
		            										attribute10                  ,
		            										attribute11                  ,
		            										attribute12                  ,
		            										attribute13                  ,
		            										attribute14                  ,
		            										attribute15                  ,
		            										global_attribute_category    ,
		            										global_attribute1            ,
		            										global_attribute2            ,
		            										global_attribute3            ,
		            										global_attribute4            ,
		            										global_attribute5            ,
		            										global_attribute6            ,
		            										global_attribute7            ,
		            										global_attribute8            ,
		            										global_attribute9            ,
		            										global_attribute10           ,
		            										global_attribute11           ,
		            										global_attribute12           ,
		            										global_attribute13           ,
		            										global_attribute14           ,
		            										global_attribute15           ,
		            										global_attribute16           ,
		            										global_attribute17           ,
		            										global_attribute18           ,
		            										global_attribute19           ,
		            										global_attribute20           ,
		            										po_release_id                ,
		            										release_num                  ,
		            										account_segment              ,
		            										balancing_segment            ,
		            										cost_center_segment          ,
		            										project_id                   ,
		            										task_id                      ,
		            										expenditure_type             ,
		            										expenditure_item_date        ,
		            										expenditure_organization_id  ,
		            										project_accounting_context   ,
		            										pa_addition_flag             ,
		            										pa_quantity                  ,
		            										ussgl_transaction_code       ,
		            										stat_amount                  ,
		            										type_1099                    ,
		            										income_tax_region            ,
		            										assets_tracking_flag         ,
		            										price_correction_flag        ,
		            										org_id                       ,
		            										receipt_number               ,
		            										receipt_line_number          ,
		            										match_option                 ,
		            										packing_slip                 ,
		            										rcv_transaction_id           ,
		            										pa_cc_ar_invoice_id          ,
		            										pa_cc_ar_invoice_line_num    ,
		            										reference_1                  ,
		            										reference_2                  ,
		            										pa_cc_processed_code         ,
		            										tax_recovery_rate            ,
		            										tax_recovery_override_flag   ,
		            										tax_recoverable_flag         ,
		            										tax_code_override_flag       ,
		            										tax_code_id                  ,
		            										credit_card_trx_id           ,
		            										award_id                     ,
		            										vendor_item_num              ,
		            										taxable_flag                 ,
		            										price_correct_inv_num        ,
		            										external_doc_line_ref        ,
		            										vendor_num                   ,
		            										invoice_num                  ,
		            										legacy_segment1              ,
		            										legacy_segment2              ,
		            										legacy_segment3              ,
		            										legacy_segment4              ,
		            										legacy_segment5              ,
		            										legacy_segment6              ,
		            										legacy_segment7              ,
		            										legacy_segment8              ,
		            										legacy_segment9              ,
		            										legacy_segment10             ,
		            										reason_code                  ,
		            										oracle_gl_company            ,
		            										oracle_gl_cost_center        ,
		            										oracle_gl_location           ,
		            										oracle_gl_account            ,
		            										oracle_gl_intercompany       ,
		            										oracle_gl_lob                ,
		            										oracle_gl_future1)
                                                    VALUES (l_lines_consign_summ_tab(l_indx).invoice_id, -- invoice_id
		            										NVL(l_lines_consign_summ_tab(l_indx).invoice_line_id,ap_invoice_lines_interface_s.NEXTVAL), -- invoice_line_id
		            										ln_line_number, --line_number
		            										'ITEM', -- line_type_lookup_code
		            										NULL, -- line_group_number
		            										ROUND(l_lines_consign_summ_tab(l_indx).mdse_amount,2),	--invoice_amount
		            										NULL, -- accounting_date
		            										lc_description, -- description
		            										NULL, -- amount_includes_tax_flag
		            										NULL, -- prorate_across_flag
		            										NULL, -- tax_code
		            										NULL, -- final_match_flag
		            										NULL, -- po_header_id
		            										NULL, -- po_number
		            										NULL, -- po_line_id
		            										NULL, -- po_line_number
		            										NULL, -- po_line_location_id
		            										NULL, -- po_shipment_num
		            										NULL, -- po_distribution_id
		            										NULL, -- po_distribution_num
		            										NULL, -- po_unit_of_measure
		            										NULL, -- inventory_item_id
		            										NULL, -- item_description
		            										NULL, -- quantity_invoiced
		            										NULL, -- ship_to_location_code
		            										NULL, -- unit_price
		            										NULL, -- distribution_set_id
		            										NULL, -- distribution_set_name
		            										(lc_company||'.'||
		            										lc_cost_center||'.'||
		            										lc_oracle_account||'.'||
		            										lc_location||'.'||
		            										lc_inter_company||'.'||
		            										lc_lob||'.'||
		            										lc_future), --dist_code_concatenated
		            										NULL, --  dist_code_combination_id
		            										NULL, -- awt_group_id
		            										NULL, -- awt_group_name
		            										gn_user_id, -- last_updated_by
		            										SYSDATE, -- last_update_date
		            										gn_user_id, -- last_update_login
		            										gn_user_id, -- created_by
		            										SYSDATE, -- creation_date
		            										NULL, -- attribute_category
		            										NULL, -- attribute1
		            										NULL, -- attribute2
		            										NULL, -- attribute3
		            										NULL, -- attribute4
		            										NULL, -- attribute5
		            										NULL, -- attribute6
		            										NULL, -- attribute7
		            										NULL, -- attribute8
		            										NULL, -- attribute9
		            										NULL, -- attribute10
		            										NULL, -- attribute11
		            										NULL, -- attribute12
		            										NULL, -- attribute13
		            										NULL, -- attribute14
		            										NULL, -- attribute15
		            										NULL, -- global_attribute_category
		            										NULL, -- global_attribute1
		            										NULL, -- global_attribute2
		            										NULL, -- global_attribute3
		            										NULL, -- global_attribute4
		            										NULL, -- global_attribute5
		            										NULL, -- global_attribute6
		            										NULL, -- global_attribute7
		            										NULL, -- global_attribute8
		            										NULL, -- global_attribute9
		            										NULL, -- global_attribute10
		            										NULL, -- global_attribute11
		            										NULL, -- global_attribute12
		            										NULL, -- global_attribute13
		            										NULL, -- global_attribute14
		            										NULL, -- global_attribute15
		            										NULL, -- global_attribute16  -- PROCESSED or Not
		            										NULL, -- global_attribute17
		            										NULL, -- global_attribute18
		            										NULL, -- global_attribute19
		            										NULL, -- global_attribute20
		            										NULL, -- po_release_id
		            										NULL, -- release_num,
		            										NULL, -- account_segment
		            										NULL, -- balancing_segment
		            										NULL, -- cost_center_segment
		            										NULL, -- project_id
		            										NULL, -- task_id
		            										NULL, -- expenditure_type   ?
		            										NULL, -- expenditure_item_date
		            										NULL, -- expenditure_organization_id
		            										NULL, -- project_accounting_context
		            										NULL, -- pa_addition_flag
		            										NULL, -- pa_quantity
		            										NULL, -- ussgl_transaction_code
		            										NULL, -- stat_amount
		            										NULL, -- type_1099
		            										NULL, -- income_tax_region
		            										NULL, -- assets_tracking_flag
		            										NULL, -- price_correction_flag
		            										NULL, -- org_id
		            										NULL, -- receipt_number
		            										NULL, -- receipt_line_number
		            										NULL, -- match_option
		            										NULL, -- packing_slip
		            										NULL, -- rcv_transaction_id
		            										NULL, -- pa_cc_ar_invoice_id
		            										NULL, -- pa_cc_ar_invoice_line_num
		            										NULL, -- reference_1
		            										NULL, -- reference_2
		            										NULL, -- pa_cc_processed_code
		            										NULL, -- tax_recovery_rate
		            										NULL, -- tax_recovery_override_flag
		            										NULL, -- tax_recoverable_flag
		            										NULL, -- tax_code_override_flag
		            										NULL, -- tax_code_id
		            										NULL, -- credit_card_trx_id
		            										NULL, -- award_id
		            										NULL, -- vendor_item_num
		            										NULL, -- taxable_flag
		            										NULL, -- price_correct_inv_num
		            										NULL, -- external_doc_line_ref
		            										NULL, -- vendor_num
		            										NULL, -- invoice_num
		            										NULL, -- legacy_segment1
		            										NULL, -- legacy_segment2
		            										NULL, -- legacy_segment3
		            										NULL, -- legacy_segment4
		            										NULL, -- legacy_segment5
		            										NULL, -- legacy_segment6
		            										NULL, -- legacy_segment7
		            										NULL, -- legacy_segment8
		            										NULL, -- legacy_segment9
		            										NULL, -- legacy_segment10
		            										NULL, -- reason_code
		            										lc_company, --oracle_gl_company
		            										lc_cost_center, -- oracle_gl_cost_center
		            										lc_location, -- oracle_gl_location
		            										lc_oracle_account, -- oracle_gl_account
		            										lc_inter_company, --  oracle_gl_intercompany
		            										lc_lob, -- oracle_gl_lob
		            										lc_future -- oracle_gl_future1
		            									);

		            		l_lines_consign_summ_tab(l_indx).record_status := 'C';
		            		l_lines_consign_summ_tab(l_indx).error_description := NULL;
                        EXCEPTION
		            	WHEN OTHERS
		            	THEN
		            	    ROLLBACK;
		            		ln_failed_records  := ln_failed_records + 1;
                            lc_error_msg := SUBSTR(sqlerrm,1,100);
                            print_debug_msg ('Invoice_line_id=['||to_char(l_lines_consign_summ_tab(l_indx).invoice_line_id)||'], RB, '||lc_error_msg,FALSE);
                            l_lines_consign_summ_tab(l_indx).record_status := 'E';
                            l_lines_consign_summ_tab(l_indx).error_description :='Unable to insert the record into xx_ap_inv_lines_interface_stg table for the invoice_line_id :'||l_lines_tab(l_indx).invoice_line_id||' '||lc_error_msg;
		                END;
                    END LOOP; --l_lines_consign_summ_tab

                    BEGIN
	                    print_debug_msg('Starting update of xx_ap_trade_inv_lines #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	                   	FORALL l_indx IN 1..l_lines_consign_summ_tab.COUNT
	                   	SAVE EXCEPTIONS
   		                    UPDATE xx_ap_trade_inv_lines
	                   		   SET record_status = l_lines_consign_summ_tab(l_indx).record_status
	                   		      ,error_description = l_lines_consign_summ_tab(l_indx).error_description
	                 		      ,last_update_date  = sysdate
	                              ,last_updated_by   = gn_user_id
	                              ,last_update_login = gn_login_id
	                   	     WHERE invoice_id = l_lines_consign_summ_tab(l_indx).invoice_id
							   AND consign_flag = 'Y';
		            		COMMIT;
	                EXCEPTION
	                WHEN OTHERS
		            THEN
	                    print_debug_msg('Bulk Exception raised',FALSE);
	                    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	                    FOR i IN 1..ln_err_count
	                    LOOP
	                        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                        lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                        print_debug_msg('Invoice_line_id=['||to_char(l_lines_consign_summ_tab(ln_error_idx).invoice_line_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	                    END LOOP; -- bulk_err_loop FOR UPDATE
	                END;
	                print_debug_msg('Ending Update of xx_ap_trade_inv_lines #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

                END LOOP; --lines_consign_summ_cur
                COMMIT;
                CLOSE lines_consign_summ_cur;

                -- To create the unabsorbed lines

				OPEN lines_consign_unabsorb_cur(p_invoice_id => l_header_tab(indx).invoice_id,
				                                p_frequency_code => p_frequency_code,
											    p_source => p_source);
                LOOP
	                l_lines_consign_unabosb_tab.DELETE;  --- Deleting the data in the Table type
                    FETCH lines_consign_unabsorb_cur BULK COLLECT INTO l_lines_consign_unabosb_tab LIMIT ln_batch_size;
                    EXIT WHEN l_lines_consign_unabosb_tab.COUNT = 0;

		            FOR l_indx IN l_lines_consign_unabosb_tab.FIRST..l_lines_consign_unabosb_tab.LAST
                    LOOP
                        BEGIN

		            	    IF l_lines_consign_unabosb_tab(l_indx).mdse_amount = 0 -- AND l_lines_consign_unabosb_tab(l_indx).line_description = 'UNABSORBED COSTS'
		            	    THEN
							   l_lines_consign_unabosb_tab(l_indx).record_status := 'C';
		            	       CONTINUE;
		            	    END IF;

		            	    IF ln_invoice_id = l_lines_consign_unabosb_tab(l_indx).invoice_id
                            THEN
		            	        ln_line_number := ln_line_number+1;
		            	    ELSE
		            	        ln_line_number := 1;
		            		    ln_invoice_id := l_lines_consign_unabosb_tab(l_indx).invoice_id;
		            	    END IF;

							-- To get the GL string for the Unabsorbed lines
							/* Added as per Version 1.4 */
							get_consign_gl_string (p_vendor_num        => l_header_tab(indx).ap_vendor
				                                  ,p_location_num      => l_lines_consign_unabosb_tab(l_indx).location_number
				                                  ,p_unabsorb_flag     => 'Y'
				        					      ,o_gl_description    => lc_unabsorb_description
				        					      ,o_gl_company        => lc_unabsorb_company
				        					      ,o_gl_cost_center    => lc_unabsorb_cost_center
				        					      ,o_gl_account        => lc_unabsorb_oracle_account
				        			              ,o_gl_location       => lc_unabsorb_location
				        					      ,o_gl_inter_company  => lc_unabsorb_inter_company
				        					      ,o_gl_lob            => lc_unabsorb_lob
				                                  ,o_gl_future         => lc_unabsorb_future
				        					      ,o_acct_detail       => lc_acct_detail
		                			          );
							/* End of changes as per Version 1.4 */

                            print_debug_msg ('Insert into xx_ap_inv_lines_interface_stg - Invoice_line_id=['||to_char(l_lines_consign_unabosb_tab(l_indx).invoice_line_id)||']',FALSE);
	                        INSERT
							    INTO xx_ap_inv_lines_interface_stg(
                                                            invoice_id                   ,
		            										invoice_line_id              ,
		            										line_number                  ,
		            										line_type_lookup_code        ,
		            										line_group_number            ,
		            										amount                       ,
		            										accounting_date              ,
		            										description                  ,
		            										amount_includes_tax_flag     ,
		            										prorate_across_flag          ,
		            										tax_code                     ,
		            										final_match_flag             ,
		            										po_header_id                 ,
		            										po_number                    ,
		            										po_line_id                   ,
		            										po_line_number               ,
		            										po_line_location_id          ,
		            										po_shipment_num              ,
		            										po_distribution_id           ,
		            										po_distribution_num          ,
		            										po_unit_of_measure           ,
		            										inventory_item_id            ,
		            										item_description             ,
		            										quantity_invoiced            ,
		            										ship_to_location_code        ,
		            										unit_price                   ,
		            										distribution_set_id          ,
		            										distribution_set_name        ,
		            										dist_code_concatenated       ,
		            										dist_code_combination_id     ,
		            										awt_group_id                 ,
		            										awt_group_name               ,
		            										last_updated_by              ,
		            										last_update_date             ,
		            										last_update_login            ,
		            										created_by                   ,
		            										creation_date                ,
		            										attribute_category           ,
		            										attribute1                   ,
		            										attribute2                   ,
		            										attribute3                   ,
		            										attribute4                   ,
		            										attribute5                   ,
		            										attribute6                   ,
		            										attribute7                   ,
		            										attribute8                   ,
		            										attribute9                   ,
		            										attribute10                  ,
		            										attribute11                  ,
		            										attribute12                  ,
		            										attribute13                  ,
		            										attribute14                  ,
		            										attribute15                  ,
		            										global_attribute_category    ,
		            										global_attribute1            ,
		            										global_attribute2            ,
		            										global_attribute3            ,
		            										global_attribute4            ,
		            										global_attribute5            ,
		            										global_attribute6            ,
		            										global_attribute7            ,
		            										global_attribute8            ,
		            										global_attribute9            ,
		            										global_attribute10           ,
		            										global_attribute11           ,
		            										global_attribute12           ,
		            										global_attribute13           ,
		            										global_attribute14           ,
		            										global_attribute15           ,
		            										global_attribute16           ,
		            										global_attribute17           ,
		            										global_attribute18           ,
		            										global_attribute19           ,
		            										global_attribute20           ,
		            										po_release_id                ,
		            										release_num                  ,
		            										account_segment              ,
		            										balancing_segment            ,
		            										cost_center_segment          ,
		            										project_id                   ,
		            										task_id                      ,
		            										expenditure_type             ,
		            										expenditure_item_date        ,
		            										expenditure_organization_id  ,
		            										project_accounting_context   ,
		            										pa_addition_flag             ,
		            										pa_quantity                  ,
		            										ussgl_transaction_code       ,
		            										stat_amount                  ,
		            										type_1099                    ,
		            										income_tax_region            ,
		            										assets_tracking_flag         ,
		            										price_correction_flag        ,
		            										org_id                       ,
		            										receipt_number               ,
		            										receipt_line_number          ,
		            										match_option                 ,
		            										packing_slip                 ,
		            										rcv_transaction_id           ,
		            										pa_cc_ar_invoice_id          ,
		            										pa_cc_ar_invoice_line_num    ,
		            										reference_1                  ,
		            										reference_2                  ,
		            										pa_cc_processed_code         ,
		            										tax_recovery_rate            ,
		            										tax_recovery_override_flag   ,
		            										tax_recoverable_flag         ,
		            										tax_code_override_flag       ,
		            										tax_code_id                  ,
		            										credit_card_trx_id           ,
		            										award_id                     ,
		            										vendor_item_num              ,
		            										taxable_flag                 ,
		            										price_correct_inv_num        ,
		            										external_doc_line_ref        ,
		            										vendor_num                   ,
		            										invoice_num                  ,
		            										legacy_segment1              ,
		            										legacy_segment2              ,
		            										legacy_segment3              ,
		            										legacy_segment4              ,
		            										legacy_segment5              ,
		            										legacy_segment6              ,
		            										legacy_segment7              ,
		            										legacy_segment8              ,
		            										legacy_segment9              ,
		            										legacy_segment10             ,
		            										reason_code                  ,
		            										oracle_gl_company            ,
		            										oracle_gl_cost_center        ,
		            										oracle_gl_location           ,
		            										oracle_gl_account            ,
		            										oracle_gl_intercompany       ,
		            										oracle_gl_lob                ,
		            										oracle_gl_future1)
                                                    VALUES (l_lines_consign_unabosb_tab(l_indx).invoice_id, -- invoice_id
		            										NVL(l_lines_consign_unabosb_tab(l_indx).invoice_line_id,ap_invoice_lines_interface_s.NEXTVAL), -- invoice_line_id
		            										ln_line_number, --line_number
		            										'ITEM', -- line_type_lookup_code
		            										NULL, -- line_group_number
		            										ROUND(l_lines_consign_unabosb_tab(l_indx).mdse_amount,2),	--invoice_amount
		            										NULL, -- accounting_date
		            										lc_unabsorb_description, -- description
		            										NULL, -- amount_includes_tax_flag
		            										NULL, -- prorate_across_flag
		            										NULL, -- tax_code
		            										NULL, -- final_match_flag
		            										NULL, -- po_header_id
		            										NULL, -- po_number
		            										NULL, -- po_line_id
		            										NULL, -- po_line_number
		            										NULL, -- po_line_location_id
		            										NULL, -- po_shipment_num
		            										NULL, -- po_distribution_id
		            										NULL, -- po_distribution_num
		            										NULL, -- po_unit_of_measure
		            										NULL, -- inventory_item_id
		            										NULL, -- item_description
		            										NULL, -- quantity_invoiced
		            										NULL, -- ship_to_location_code
		            										NULL, -- unit_price
		            										NULL, -- distribution_set_id
		            										NULL, -- distribution_set_name
		            										lc_unabsorb_company||'.'||
		            										lc_unabsorb_cost_center||'.'||
		            										lc_unabsorb_oracle_account||'.'||
		            										lc_unabsorb_location||'.'||
		            										lc_unabsorb_inter_company||'.'||
		            										lc_unabsorb_lob||'.'||
		            										lc_unabsorb_future, --dist_code_concatenated
		            										NULL, --  dist_code_combination_id
		            										NULL, -- awt_group_id
		            										NULL, -- awt_group_name
		            										gn_user_id, -- last_updated_by
		            										SYSDATE, -- last_update_date
		            										gn_user_id, -- last_update_login
		            										gn_user_id, -- created_by
		            										SYSDATE, -- creation_date
		            										NULL, -- attribute_category
		            										NULL, -- attribute1
		            										NULL, -- attribute2
		            										NULL, -- attribute3
		            										NULL, -- attribute4
		            										NULL, -- attribute5
		            										NULL, -- attribute6
		            										NULL, -- attribute7
		            										NULL, -- attribute8
		            										NULL, -- attribute9
		            										NULL, -- attribute10
		            										NULL, -- attribute11
		            										NULL, -- attribute12
		            										NULL, -- attribute13
		            										NULL, -- attribute14
		            										NULL, -- attribute15
		            										NULL, -- global_attribute_category
		            										NULL, -- global_attribute1
		            										NULL, -- global_attribute2
		            										NULL, -- global_attribute3
		            										NULL, -- global_attribute4
		            										NULL, -- global_attribute5
		            										NULL, -- global_attribute6
		            										NULL, -- global_attribute7
		            										NULL, -- global_attribute8
		            										NULL, -- global_attribute9
		            										NULL, -- global_attribute10
		            										NULL, -- global_attribute11
		            										NULL, -- global_attribute12
		            										NULL, -- global_attribute13
		            										NULL, -- global_attribute14
		            										NULL, -- global_attribute15
		            										NULL, -- global_attribute16  -- PROCESSED or Not
		            										NULL, -- global_attribute17
		            										NULL, -- global_attribute18
		            										NULL, -- global_attribute19
		            										NULL, -- global_attribute20
		            										NULL, -- po_release_id
		            										NULL, -- release_num,
		            										NULL, -- account_segment
		            										NULL, -- balancing_segment
		            										NULL, -- cost_center_segment
		            										NULL, -- project_id
		            										NULL, -- task_id
		            										NULL, -- expenditure_type   ?
		            										NULL, -- expenditure_item_date
		            										NULL, -- expenditure_organization_id
		            										NULL, -- project_accounting_context
		            										NULL, -- pa_addition_flag
		            										NULL, -- pa_quantity
		            										NULL, -- ussgl_transaction_code
		            										NULL, -- stat_amount
		            										NULL, -- type_1099
		            										NULL, -- income_tax_region
		            										NULL, -- assets_tracking_flag
		            										NULL, -- price_correction_flag
		            										NULL, -- org_id
		            										NULL, -- receipt_number
		            										NULL, -- receipt_line_number
		            										NULL, -- match_option
		            										NULL, -- packing_slip
		            										NULL, -- rcv_transaction_id
		            										NULL, -- pa_cc_ar_invoice_id
		            										NULL, -- pa_cc_ar_invoice_line_num
		            										NULL, -- reference_1
		            										NULL, -- reference_2
		            										NULL, -- pa_cc_processed_code
		            										NULL, -- tax_recovery_rate
		            										NULL, -- tax_recovery_override_flag
		            										NULL, -- tax_recoverable_flag
		            										NULL, -- tax_code_override_flag
		            										NULL, -- tax_code_id
		            										NULL, -- credit_card_trx_id
		            										NULL, -- award_id
		            										NULL, -- vendor_item_num
		            										NULL, -- taxable_flag
		            										NULL, -- price_correct_inv_num
		            										NULL, -- external_doc_line_ref
		            										NULL, -- vendor_num
		            										NULL, -- invoice_num
		            										NULL, -- legacy_segment1
		            										NULL, -- legacy_segment2
		            										NULL, -- legacy_segment3
		            										NULL, -- legacy_segment4
		            										NULL, -- legacy_segment5
		            										NULL, -- legacy_segment6
		            										NULL, -- legacy_segment7
		            										NULL, -- legacy_segment8
		            										NULL, -- legacy_segment9
		            										NULL, -- legacy_segment10
		            										NULL, -- reason_code
		            										lc_unabsorb_company, --oracle_gl_company
		            										lc_unabsorb_cost_center, -- oracle_gl_cost_center
		            										lc_unabsorb_location, -- oracle_gl_location
		            										lc_unabsorb_oracle_account, -- oracle_gl_account
		            										lc_unabsorb_inter_company, --  oracle_gl_intercompany
		            										lc_unabsorb_lob, -- oracle_gl_lob
		            										lc_unabsorb_future -- oracle_gl_future1
		            									);

		            		l_lines_consign_unabosb_tab(l_indx).record_status := 'C';
		            		l_lines_consign_unabosb_tab(l_indx).error_description := NULL;
							/*fnd_file.put_line(fnd_file.log,'Record Status :'||l_lines_consign_unabosb_tab(l_indx).record_status
							                                                ||' and Location :'||l_lines_consign_unabosb_tab(l_indx).location_number
																			||' and Invoice Number:'||l_header_tab(indx).invoice_number); */

                        EXCEPTION
		            	WHEN OTHERS
		            	THEN
		            	    ROLLBACK;
		            		ln_failed_records  := ln_failed_records + 1;
                            lc_error_msg := SUBSTR(sqlerrm,1,100);
                            -- print_debug_msg ('Invoice_line_id=['||to_char(l_lines_consign_unabosb_tab(l_indx).invoice_line_id)||'], RB, '||lc_error_msg,FALSE);
							print_debug_msg ('Location Number=['||to_char(l_lines_consign_unabosb_tab(l_indx).location_number)||'], RB, '||lc_error_msg,FALSE);
                            l_lines_consign_unabosb_tab(l_indx).record_status := 'E';
							/*fnd_file.put_line(fnd_file.log,'Record Status :'||l_lines_consign_unabosb_tab(l_indx).record_status
							                                                ||' and Location :'||l_lines_consign_unabosb_tab(l_indx).location_number
																			||' and Invoice Number:'||l_header_tab(indx).invoice_number); */
                            l_lines_consign_unabosb_tab(l_indx).error_description :='Unable to insert the record into xx_ap_inv_lines_interface_stg table for the invoice_id :'
							                                                         ||l_lines_consign_unabosb_tab(l_indx).invoice_id
																					 ||' and Location Number :'||l_lines_consign_unabosb_tab(l_indx).location_number
																					 ||' '||lc_error_msg;
		                END;
                    END LOOP; --l_lines_consign_unabosb_tab

                    BEGIN
	                    print_debug_msg('Starting update of xx_ap_trade_inv_lines #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	                   	FORALL l_indx IN 1..l_lines_consign_unabosb_tab.COUNT
	                   	SAVE EXCEPTIONS
   		                    UPDATE xx_ap_trade_inv_lines
	                   		   SET record_status = l_lines_consign_unabosb_tab(l_indx).record_status
	                   		      ,error_description = l_lines_consign_unabosb_tab(l_indx).error_description
	                 		      ,last_update_date  = sysdate
	                              ,last_updated_by   = gn_user_id
	                              ,last_update_login = gn_login_id
	                   	     WHERE invoice_id = l_lines_consign_unabosb_tab(l_indx).invoice_id
							   AND location_number = l_lines_consign_unabosb_tab(l_indx).location_number
							   AND consign_flag = 'N';
		            		COMMIT;
	                EXCEPTION
	                WHEN OTHERS
		            THEN
	                    print_debug_msg('Bulk Exception raised',FALSE);
	                    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	                    FOR i IN 1..ln_err_count
	                    LOOP
	                        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                        lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                        print_debug_msg('Invoice_id=['||to_char(l_lines_consign_unabosb_tab(ln_error_idx).invoice_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	                    END LOOP; -- bulk_err_loop FOR UPDATE
	                END;
	                print_debug_msg('Ending Update of xx_ap_trade_inv_lines #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

                END LOOP; --lines_consign_unabsorb_cur
                COMMIT;
                CLOSE lines_consign_unabsorb_cur;

			END IF; -- p_source

            EXCEPTION
			WHEN OTHERS
			THEN
			    ln_hdr_failed_records:= ln_hdr_failed_records +1;
			    ROLLBACK;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
                print_debug_msg ('Invoice_id=['||to_char(l_header_tab(indx).invoice_id)||'], RB, '||lc_error_msg,FALSE);
                l_header_tab(indx).record_status := 'E';
                l_header_tab(indx).error_description :='Unable to insert the record into xx_ap_inv_interface_stg table for the invoice_id :'||l_header_tab(indx).invoice_id||' '||lc_error_msg;
			END;
            END LOOP; --l_header_tab

            BEGIN
	            print_debug_msg('Starting update of xx_ap_trade_inv_hdr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	    FORALL indx IN 1..l_header_tab.COUNT
	       	    SAVE EXCEPTIONS
   		        UPDATE xx_ap_trade_inv_hdr
	       		   SET record_status = l_header_tab(indx).record_status
	       		      ,error_description = l_header_tab(indx).error_description
	     		      ,last_update_date  = sysdate
	                  ,last_updated_by   = gn_user_id
	                  ,last_update_login = gn_login_id
	       	     WHERE invoice_id = l_header_tab(indx).invoice_id;
				COMMIT;
	        EXCEPTION
	        WHEN OTHERS
			THEN
	            print_debug_msg('Bulk Exception raised',FALSE);
	            ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	            FOR i IN 1..ln_err_count
	            LOOP
	                ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	                lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	                print_debug_msg('Invoice_id=['||to_char(l_header_tab(ln_error_idx).invoice_id)||'], Error msg=['||lc_error_msg||']',TRUE);
	            END LOOP; -- bulk_err_loop FOR UPDATE
	        END;
	        print_debug_msg('Ending Update of xx_ap_trade_inv_hdr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);

        END LOOP; --header_cur
    COMMIT;
    CLOSE header_cur;

	-- Submitting the Import Standard Purchase Order
    print_debug_msg('Submitting Import Standard Purchase Orders',TRUE);
    OPEN org_cur(gn_batch_id);
    FETCH org_cur BULK COLLECT INTO l_org_tab;
    CLOSE org_cur;

    FOR o_indx IN 1..l_org_tab.COUNT
    LOOP
        print_debug_msg('Submitting Import Standard Purchase Orders for batchid=['||gn_batch_id||'], Org_id=['||l_org_tab(o_indx).org_id||']',TRUE);

        mo_global.set_policy_context('S',l_org_tab(o_indx).org_id);
        mo_global.init ('PO');
        ln_job_id := fnd_request.submit_request(application => 'PO'
	                                           ,program     => 'POXPOPDOI'
	                                           ,sub_request => FALSE
	                                           ,argument1   => ''        		            -- Default Buyer
	                                           ,argument2   => 'STANDARD'  		            -- Doc. Type
	                                           ,argument3   => ''			                -- Doc. Sub Type
	                                           ,argument4   => 'N'         		            -- Create or Update Items
	                                           ,argument5   => ''                           -- Create sourcing Rules flag
	                                           ,argument6   => 'APPROVED' 		            -- Approval Status
	                                           ,argument7   => ''			                -- Release Generation Method
	                                           ,argument8   => gn_batch_id                  -- batch_id
	                                           ,argument9   => l_org_tab(o_indx).org_id  	-- org_id
	                                           );

		IF ln_job_id > 0
		THEN
	        COMMIT;

		    print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
		 -- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
							                               request_id   => ln_job_id,
							                               interval     => 10,
							                               max_wait     => 0,
							                               phase        => lc_phase,
							                               status       => lc_status,
							                               dev_phase    => lc_dev_phase,
							                               dev_status   => lc_dev_status,
							                               message      => lc_message
														  );

	        print_debug_msg('Status :'||lc_status);
			print_debug_msg('dev_phase :'||lc_dev_phase);
			print_debug_msg('dev_status :'||lc_dev_status);
			print_debug_msg('message :'||lc_message);
		END IF;

        IF ln_job_id = 0
		THEN
	      lc_errcode := '2';
	      exit;
	    END IF;

    END LOOP;

	    IF lc_errcode = 2
	THEN
        lc_error_msg := 'Sub-Request Submission- Failed';
        return;
    END IF;

	--========================================================================
		-- Updating the OUTPUT FILE
	--========================================================================
	FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Staging table Details:');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed for Header Table:: '||ln_total_hdr_records_process);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully for Header Table :: '||ln_hdr_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed for Header Table:: '||ln_hdr_failed_records);
	FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));

	-- Sending an email notification if the EDI and TDM sources having Consignment Suppliers

	IF p_source = 'US_OD_TRADE_EDI' AND lc_cons_vendor_flag = 'Y'
	THEN
	    lc_cons_inv_num := NULL;

		---Added For NAIT-57153 to print the vendor name and vendor site in the email------

    ln_log1 := ln_log1 ||CHR(10)|| 'INVOICE NUMBER          SUPPLIER NAME                  SUPPLIER SITE            '|| CHR(10);
    ln_log1 := ln_log1 || '-------------------------------------------------------------------------'|| CHR(10);

	    FOR cons_inv_num IN cons_inv_num_cur
        LOOP
		    BEGIN
			--lc_cons_inv_num := lc_cons_inv_num||chr(10)||cons_inv_num.invoice_num||chr(10);
              ln_log1 := ln_log1||cons_inv_num.invoice_num;
			  ln_log1 := ln_log1||'        '||cons_inv_num.SUPPLIER_NAME;
			  ln_log1 := ln_log1||'              '||cons_inv_num.SUPPLIER_SITE||chr(10);
	        EXCEPTION
		    WHEN OTHERS
		    THEN
            --lc_cons_inv_num := lc_cons_inv_num||chr(10)||cons_inv_num.invoice_num||chr(10);
              ln_log1 := ln_log1||cons_inv_num.invoice_num;
			  ln_log1 := ln_log1||'        '||cons_inv_num.SUPPLIER_NAME;
			  ln_log1 := ln_log1||'              '||cons_inv_num.SUPPLIER_SITE||chr(10);
		    END;
	    END LOOP;

		/* Added as per version 2.7 */
		-- To get the Email details
		BEGIN
		    lc_email_from    := NULL;
			lc_email_to      := NULL;
		    lc_email_cc      := NULL;
		    lc_email_subject := NULL;
		    lc_email_body    := NULL;

		    SELECT target_value1, -- Email From
                   target_value2, -- Email To
                   target_value3, -- Email CC
                   target_value4, -- Email Subject
                   target_value5  -- Email Body
			  INTO lc_email_from,
			       lc_email_to,
				   lc_email_cc,
				   lc_email_subject,
				   lc_email_body
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
		                              FROM xx_fin_translatedefinition
		                             WHERE translation_name = 'XX_AP_TRADE_INV_EMAIL'
		                               AND enabled_flag = 'Y')
               AND source_value1 = p_source;
		EXCEPTION
		WHEN OTHERS
		THEN
		    lc_email_from    := NULL;
			lc_email_to      := NULL;
			lc_email_cc      := NULL;
			lc_email_subject := NULL;
		    lc_email_body    := NULL;
		END;

		-- To send an email
        BEGIN
            conn := xx_pa_pb_mail.begin_mail(sender => lc_email_from,
                                             recipients => lc_email_to,
                                             cc_recipients=> lc_email_cc,
                                             subject => lc_email_subject ,
                                             mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

            xx_pa_pb_mail.attach_text( conn => conn,
                                       data => lc_email_body|| ln_log1
                                             );

            xx_pa_pb_mail.end_mail( conn => conn );

            COMMIT;
            print_debug_msg ('Email sent successfully',TRUE);
        EXCEPTION
        WHEN OTHERS
		THEN
            print_debug_msg ('Error while sending the Email',TRUE);
        END;

	ELSIF p_source = 'US_OD_TDM' AND lc_cons_vendor_flag = 'Y' -- Added as per version 1.9
	THEN
	    lc_cons_inv_num := NULL;
	    FOR cons_inv_num IN cons_inv_num_cur
        LOOP
		    BEGIN
		        lc_cons_inv_num := lc_cons_inv_num||chr(10)||cons_inv_num.invoice_num||chr(10);
	        EXCEPTION
		    WHEN OTHERS
		    THEN
                lc_cons_inv_num := lc_cons_inv_num||chr(10)||cons_inv_num.invoice_num||chr(10);
		    END;
	    END LOOP;

		/* Added as per version 2.7 */
		-- To get the Email details
		BEGIN
		    lc_email_from    := NULL;
			lc_email_to      := NULL;
		    lc_email_cc      := NULL;
		    lc_email_subject := NULL;
		    lc_email_body    := NULL;

		    SELECT target_value1, -- Email From
                   target_value2, -- Email To
                   target_value3, -- Email CC
                   target_value4, -- Email Subject
                   target_value5  -- Email Body
			  INTO lc_email_from,
			       lc_email_to,
				   lc_email_cc,
				   lc_email_subject,
				   lc_email_body
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
		                              FROM xx_fin_translatedefinition
		                             WHERE translation_name = 'XX_AP_TRADE_INV_EMAIL'
		                               AND enabled_flag = 'Y')
               AND source_value1 = p_source;
		EXCEPTION
		WHEN OTHERS
		THEN
		    lc_email_from    := NULL;
			lc_email_to      := NULL;
			lc_email_cc      := NULL;
			lc_email_subject := NULL;
			lc_email_body    := NULL;
		END;

        BEGIN
            conn := xx_pa_pb_mail.begin_mail(sender => lc_email_from,
                                             recipients => lc_email_to,
                                             cc_recipients=>lc_email_cc,
                                             subject => lc_email_subject,
                                             mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

            xx_pa_pb_mail.attach_text( conn => conn,
                                       data => lc_email_body|| lc_cons_inv_num
                                             );

            xx_pa_pb_mail.end_mail( conn => conn );

            COMMIT;
            print_debug_msg ('Email sent successfully',TRUE);
        EXCEPTION
        WHEN OTHERS
		THEN
            print_debug_msg ('Error while sending the Email',TRUE);
        END;
	END IF; -- p_source

EXCEPTION
WHEN data_exception
THEN
    ROLLBACK;
    p_retcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_data_to_staging - '||lc_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_data_to_staging',
	                lc_error_loc,
		            lc_error_msg);
WHEN OTHERS
THEN
	p_retcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg);
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AP_INVOICE_INTEGRAL_PKG.load_data_to_staging - '||lc_error_msg,TRUE);
    log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.load_data_to_staging',
	                lc_error_loc,
		            lc_error_msg);
END load_data_to_staging;

-- +============================================================================================+
-- |  Name	 : load_prestaging                                                                  |
-- |  Description: This procedure reads data from the file and inserts into prestaging tables   |
-- =============================================================================================|
PROCEDURE load_prestaging(p_errbuf         OUT  VARCHAR2
                         ,p_retcode        OUT  VARCHAR2
                         ,p_filepath       IN   VARCHAR2
					     ,p_source         IN   VARCHAR2
                         ,p_file_name 	   IN   VARCHAR2
                         ,p_debug          IN   VARCHAR2)
AS

    CURSOR get_dir_path
    IS
      SELECT directory_path
        FROM all_directories
       WHERE directory_name = p_filepath;

    l_filehandle       UTL_FILE.FILE_TYPE;
    lc_filedir         VARCHAR2(30) := p_filepath;
    lc_filename	       VARCHAR2(200):= p_file_name;
    lc_source          VARCHAR2(40) := p_source;
    lc_dirpath         VARCHAR2(500);
    lb_file_exist      BOOLEAN;
    ln_size            NUMBER;
    ln_block_size      NUMBER;
    lc_newline         VARCHAR2(4000);  -- Input line
    ln_max_linesize    BINARY_INTEGER  := 32767;
    ln_rec_cnt         NUMBER := 0;
    l_table 	       varchar2_table;
    l_hdr_table        varchar2_table;
    l_line_table       varchar2_table;
    lc_error_msg       VARCHAR2(1000) := NULL;
    lc_error_loc	   VARCHAR2(2000) := 'XX_AP_INVOICE_INTEGRAL_PKG.LOAD_STAGING';
    lc_errcode	       VARCHAR2(3)    := NULL;
    lc_rec_type        VARCHAR2(1)    := NULL;
    ln_count_hdr       NUMBER := 0;
    ln_count_lin       NUMBER := 0;
    ln_count_err       NUMBER := 0;
    ln_count_tot       NUMBER := 0;
    ln_conc_file_copy_request_id NUMBER;
    lc_dest_file_name  VARCHAR2(200);
    nofile             EXCEPTION;
	bad_file_exception EXCEPTION; --3.9 Change
    data_exception     EXCEPTION;
    ld_from_date       DATE;
    ld_to_date         DATE;
    ln_invoice_id      NUMBER;
    ln_sequence_number NUMBER := 0;
    lc_vendor_site     VARCHAR2(30);
    lc_description     VARCHAR2(30);
    lc_location        VARCHAR2(30);
    lc_lob             VARCHAR2(30);
    lc_oracle_account  VARCHAR2(30);
    lc_company         VARCHAR2(30);
    lc_acct_detail     VARCHAR2(30);
    lc_cost_center     VARCHAR2(30);
    lc_inter_company   VARCHAR2(30);
    lc_future          VARCHAR2(30);
    l_nfields          NUMBER;
    lc_drp_details     VARCHAR2(32767);
    lc_temp_email      VARCHAR2(100);
    conn               utl_smtp.connection;
    lc_instance_name   VARCHAR2(30);
	ln_job_id          NUMBER;
	lb_complete        BOOLEAN;
    lc_phase           VARCHAR2(100);
    lc_status          VARCHAR2(100);
    lc_dev_phase       VARCHAR2(100);
    lc_dev_status      VARCHAR2(100);
    lc_message         VARCHAR2(100);
	lc_email_from      VARCHAR2(100);
	lc_email_to        VARCHAR2(100);
	lc_email_cc        VARCHAR2(100);
	lc_email_subject   VARCHAR2(100);
	lc_email_body      VARCHAR2(100);
	lc_email_sub       VARCHAR2(200) := 'Alert - Trade EDI File Carriage Return Issue';
	ln_log             VARCHAR2(32767);



BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;

	-- To get the instance Name
	SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),1,8)
      INTO lc_instance_name
      FROM dual;

-- ******************************
-- For Sources: TDM and DCI
-- ******************************
	IF p_source IN ('US_OD_TDM','US_OD_DCI_TRADE')
	THEN
        print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF NOT lb_file_exist THEN
		   RAISE nofile;
		END IF;

		-- Open the TDM File
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);

		print_debug_msg ('File open successfull',TRUE);
		LOOP
		    BEGIN
			    UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			    IF lc_newline IS NULL
			    THEN
				   EXIT;
		        END IF;

		        print_debug_msg ('Processing Line:'||lc_newline,FALSE);

		        --parse the line
		        parse_tdm_dci_file(lc_newline,l_table,lc_error_msg,lc_errcode);
		        IF lc_errcode = '2'
			    THEN
			       RAISE data_exception;
		        END IF;

		        lc_rec_type := l_table(5);

		        IF lc_rec_type = 'H'
			    THEN
			        print_debug_msg ('Insert Header',FALSE);
			        insert_header(l_table,p_source,lc_error_msg,lc_errcode);
   	                IF lc_errcode = '2'
			        THEN
	                    RAISE data_exception;
	                END IF;
			        ln_count_hdr := ln_count_hdr + 1;

					  /* Added as per version 2.8 */
					  -- To create the Freight line for the Not Approved TDM Invoice
					  IF TO_NUMBER(l_table(18)) <> 0 AND p_source = 'US_OD_TDM'
					  THEN
					      l_table(5) := 'D';  -- Record Type
						  l_table(12):= NULL; -- NULL
						  l_table(2) := l_table(2); -- Vendor Number
						  l_table(3) := l_table(3); -- Invoice Number
						  l_table(8) := l_table(19); -- Freight Amount Sign
						  l_table(7) := l_table(18); -- Freight Amount
						  l_table(9) := NULL; -- GL Company
						  l_table(12):= NULL; -- GL Location
						  l_table(10):= NULL; -- GL Cost Center
						  l_table(14):= NULL; -- GL LOB
						  l_table(11):= NULL; -- GL Account
						  l_table(15):= NULL; -- Line Description
						  l_table(13):= NULL; -- GL Inter Company
						  l_table(19):= 'FREIGHT';

			              print_debug_msg ('Insert Line',FALSE);
			              insert_line(l_table,p_source,lc_error_msg,lc_errcode);
   	                      IF lc_errcode = '2'
			              THEN
	                         RAISE data_exception;
	                      END IF;
			              ln_count_lin := ln_count_lin + 1;
					  END IF;

		        ELSIF lc_rec_type = 'D'
			    THEN
			        print_debug_msg ('Insert Line',FALSE);
			        insert_line(l_table,p_source,lc_error_msg,lc_errcode);
   	                IF lc_errcode = '2'
			        THEN
	                    RAISE data_exception;
	                END IF;
			        ln_count_lin := ln_count_lin + 1;

		        ELSE
			        print_debug_msg ('Invalid Record Type',FALSE);
			        lc_errcode := '2';
			        lc_error_msg := 'ERROR - Invalid record type :'||lc_rec_type;
			        RAISE data_exception;
		        END IF;
		        ln_count_tot := ln_count_tot + 1;
		    EXCEPTION
		    WHEN no_data_found
			THEN
			  EXIT;
		    END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	    COMMIT;

-- ******************************
-- For Sources: Consignment
-- ******************************
	ELSIF p_source IN ('US_OD_CONSIGNMENT_SALES')
	THEN
	    print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF lb_file_exist
		THEN

		-- Open the Consignment File
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);

		print_debug_msg ('File open successfull',TRUE);
		LOOP
		    BEGIN
			    UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			    IF lc_newline IS NULL
			    THEN
				    EXIT;
                END IF;

		        print_debug_msg ('Processing Line:'||lc_newline,FALSE);

		        --parse the line
		        parse_csi_file(lc_newline,l_table,lc_error_msg,lc_errcode);
		        IF lc_errcode = '2'
		        THEN
			        RAISE data_exception;
		        END IF;

                lc_description    := NULL;
		        lc_location       := NULL;
		        lc_cost_center    := NULL;
		        lc_lob            := NULL;
		        lc_oracle_account := NULL;
			    lc_acct_detail    := NULL;
				lc_company        := NULL;
				lc_inter_company  := NULL;
				lc_future         := NULL;

				get_consign_gl_string (p_vendor_num        => l_table(2)
				                      ,p_location_num      => l_table(1)
				                      ,p_unabsorb_flag     => 'N'
									  ,o_gl_description    => lc_description
									  ,o_gl_company        => lc_company
									  ,o_gl_cost_center    => lc_cost_center
									  ,o_gl_account        => lc_oracle_account
							          ,o_gl_location       => lc_location
									  ,o_gl_inter_company  => lc_inter_company
									  ,o_gl_lob            => lc_lob
				                      ,o_gl_future         => lc_future
									  ,o_acct_detail       => lc_acct_detail
		        			          );

		        print_debug_msg ('Insert Line',FALSE);

		        l_table(14) := lc_description;
			    l_table(15) := NULL;
			    l_table(16) := NULL;
			    l_table(17) := NULL;
			    l_table(18) := NULL;
				l_table(19) := NULL;
				l_table(20) := NULL;
				l_table(21) := NULL;

			    insert_line(l_table,p_source,lc_error_msg,lc_errcode);

   	            IF lc_errcode = '2'
			    THEN
	               RAISE data_exception;
	            END IF;
			    ln_count_lin := ln_count_lin + 1;

			    IF lc_acct_detail IS NULL
			    THEN
			      -- If PO Cost and Invoice Cost don't match
			        IF (l_table(11)- l_table(6))/1000 <> 0
			        THEN
			            -- l_table(6)  := TRUNC(l_table(11),2)- TRUNC(l_table(6),2); --> Cost
						l_table(6)  :=  (TRUNC((l_table(11)/1000),2)- TRUNC((l_table(6)/1000),2)) * 1000; --> Cost
			            l_table(13) := 'N';  --> Consign Flag
			            l_table(10) := NULL;
			            l_table(11) := NULL;
			            l_table(14) := NULL;
			            l_table(15) := NULL;
			            l_table(16) := NULL;
			            l_table(17) := NULL;
			            l_table(18) := NULL;
						l_table(19) := NULL;
				        l_table(20) := NULL;
				        l_table(21) := NULL;
						l_table(22) := NULL;
						l_table(23) := NULL;

			            print_debug_msg ('Insert Line',FALSE);
			            insert_line(l_table,p_source,lc_error_msg,lc_errcode);

   	                    IF lc_errcode = '2'
			            THEN
	                        RAISE data_exception;
	                    END IF;
			            ln_count_lin := ln_count_lin + 1;

			        END IF; -- (l_table(11)- l_table(6))/1000 > 0
			    END IF;  -- lc_acct_detail IS NULL
		    EXCEPTION
		    WHEN no_data_found
			THEN
			    EXIT;
		    END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	    COMMIT;
	    ELSE
		   print_debug_msg ('No data file found. Continue to stage Consignment data. '||p_source,TRUE);
	    END IF;


-- **********************************
-- For Sources: Dropship Deductions
-- **********************************
	ELSIF p_source = 'US_OD_DROPSHIP'
	THEN
	    print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF NOT lb_file_exist
		THEN
		   RAISE nofile;
		END IF;

		-- Open the Dropship deductions file
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);

		print_debug_msg ('File open successfull',TRUE);
		LOOP
		    BEGIN
			    UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			    IF lc_newline IS NULL
				THEN
				    EXIT;
                END IF;

		        print_debug_msg ('Processing Line:'||lc_newline,FALSE);

		        --parse the line
		        parse_drp_file(lc_newline,l_table,lc_error_msg,lc_errcode);
		        IF lc_errcode = '2'
				THEN
			        RAISE data_exception;
		        END IF;

		        print_debug_msg ('Insert Line',FALSE);
			    insert_line(l_table,p_source,lc_error_msg,lc_errcode);
   	            IF lc_errcode = '2'
			    THEN
	                RAISE data_exception;
	            END IF;
			    ln_count_lin := ln_count_lin + 1;

		    EXCEPTION
		    WHEN no_data_found
			THEN
			    EXIT;
		    END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	    COMMIT;

-- **********************************
-- For Sources: EDI
-- **********************************
	ELSIF p_source = 'US_OD_TRADE_EDI'
	THEN
        print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF NOT lb_file_exist
		THEN
		   RAISE nofile;
		END IF;

		-- Open the EDI File
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);

		print_debug_msg ('File open successfull',TRUE);
		ln_log := ln_log || 'INVOICE NUMBER       VENDOR NUMBER          PO NUMBER                            LINE NUMBER                         ERROR MESSAGE '|| chr(10);
		ln_log := ln_log || '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------' || CHR(10);
		LOOP
		    BEGIN
                lc_rec_type := NULL;
			    UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			    IF lc_newline IS NULL
				THEN
				   EXIT;
		        END IF;

		        print_debug_msg ('Processing Line:'||lc_newline,FALSE);

		        --parse the line
		        parse_edi_file(lc_newline,l_table,l_line_table,lc_error_msg,lc_errcode);

				gn_count := gn_count+1;

		        IF lc_errcode = '2'
				THEN
			        RAISE data_exception;
		        END IF;

			    lc_rec_type := TRIM(l_table(1));

				-- changes as per version 3.9 starts here --

				IF gn_bad_rec_flag = '1' -- AND (lc_rec_type <> '1' OR lc_rec_type is null)
				THEN
					IF lc_rec_type = '1'
					THEN
						lc_rec_type := '1';
					ELSIF lc_rec_type IN ('2','4','5','6')  --Added For NAIT-48272
					THEN
					print_debug_msg ('line_number' || '    ' || gn_count || ' ' || lc_error_msg,TRUE);  --Added For NAIT-48272
					ln_log := ln_log || v_inv_num || '                     ' || v_ven_num || '                     ' || v_po_num ||'                             ' || gn_count   || '           ' || lc_newline  || chr(10);  --Added For NAIT-48272

					lc_rec_type := '9';

				    ELSIF lc_rec_type = '0'
					THEN
					lc_rec_type := '9';
					ELSE
						lc_rec_type := '9';

						print_debug_msg ('line_number'  || gn_count || '      ' || lc_error_msg,TRUE); --Added For NAIT-48272 -- Added to skip the bad record insert until next Header Record is received
					    ln_log := ln_log || v_inv_num || '                     ' || v_ven_num || '                     ' || v_po_num ||'                             ' || gn_count   || '           ' || lc_error_msg  || chr(10);  --Added For NAIT-48272

					END IF;
				END IF;

				IF gn_bad_rec_flag ='0' and lc_rec_type <> '9'
				THEN

					IF lc_rec_type = '1'
					THEN
						print_debug_msg ('Insert Main Header Type 1',FALSE);
						l_hdr_table.DELETE;
						SELECT ap_invoices_interface_s.nextval
						INTO ln_invoice_id
						FROM DUAL;
						/*
						SELECT xx_ap_trade_voucher_num_s.nextval
						INTO ln_voucher_num
						FROM DUAL; */

						l_hdr_table := l_table;

					ELSIF  lc_rec_type = '4'
					THEN
						print_debug_msg ('Insert Line',FALSE);
						l_line_table(12) := l_hdr_table(5);           -- Invoice Number
						l_line_table(13) := to_char(ln_invoice_id);   -- Invoice ID
						l_line_table(14) := NULL; -- to_char(ln_voucher_num);  -- Voucher Number
						insert_line(l_line_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
							RAISE data_exception;
						END IF;
						ln_count_lin := ln_count_lin + 1;

					ELSIF  lc_rec_type = '6'
					THEN
						print_debug_msg ('Insert Freight Line',FALSE);
						l_line_table(12) := l_hdr_table(5);            -- Invoice Number
						l_line_table(13) := to_char(ln_invoice_id);    -- Invoice ID
						l_line_table(14) := NULL; -- to_char(ln_voucher_num);   -- Voucher Number
						insert_line(l_line_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
						RAISE data_exception;
						END IF;
						ln_count_lin := ln_count_lin + 1;

					ELSIF lc_rec_type = '5'
					THEN
						print_debug_msg ('Insert Header',FALSE);
						l_hdr_table(12):= l_table(12);    -- Charge Amount
						l_hdr_table(13):= l_table(13);    -- Charge Sign
						l_hdr_table(14):= l_table(14);    -- Charge Percentage
						l_hdr_table(15):= l_table(15);    -- Charge Code
						l_hdr_table(16):= ln_invoice_id;  -- Invoice ID
						l_hdr_table(17):= NULL; -- ln_voucher_num; -- Voucher Number

						insert_header(l_hdr_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
						RAISE data_exception;
						END IF;
						ln_count_hdr := ln_count_hdr + 1;
					END IF;	-- lc_rec_type

				END IF; --gn_bad_rec_flag

				IF gn_bad_rec_flag ='1' and lc_rec_type = '1'
				THEN

					gn_bad_file_rec_count := gn_bad_file_rec_count + gn_bad_rec_flag;
					gn_bad_rec_flag := 0;
					-- changes as per version 3.9 ends here --

					IF lc_rec_type = '1'
					THEN
						print_debug_msg ('Insert Main Header Type 1',FALSE);
						l_hdr_table.DELETE;
						SELECT ap_invoices_interface_s.nextval
						INTO ln_invoice_id
						FROM DUAL;
						/*
						SELECT xx_ap_trade_voucher_num_s.nextval
						INTO ln_voucher_num
						FROM DUAL; */

						l_hdr_table := l_table;

					ELSIF  lc_rec_type = '4'
					THEN
						print_debug_msg ('Insert Line',FALSE);
						l_line_table(12) := l_hdr_table(5);           -- Invoice Number
						l_line_table(13) := to_char(ln_invoice_id);   -- Invoice ID
						l_line_table(14) := NULL; -- to_char(ln_voucher_num);  -- Voucher Number
						insert_line(l_line_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
							RAISE data_exception;
						END IF;
						ln_count_lin := ln_count_lin + 1;

					ELSIF  lc_rec_type = '6'
					THEN
						print_debug_msg ('Insert Freight Line',FALSE);
						l_line_table(12) := l_hdr_table(5);            -- Invoice Number
						l_line_table(13) := to_char(ln_invoice_id);    -- Invoice ID
						l_line_table(14) := NULL; -- to_char(ln_voucher_num);   -- Voucher Number
						insert_line(l_line_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
						RAISE data_exception;
						END IF;
						ln_count_lin := ln_count_lin + 1;

					ELSIF lc_rec_type = '5'
					THEN
						print_debug_msg ('Insert Header',FALSE);
						l_hdr_table(12):= l_table(12);    -- Charge Amount
						l_hdr_table(13):= l_table(13);    -- Charge Sign
						l_hdr_table(14):= l_table(14);    -- Charge Percentage
						l_hdr_table(15):= l_table(15);    -- Charge Code
						l_hdr_table(16):= ln_invoice_id;  -- Invoice ID
						l_hdr_table(17):= NULL; -- ln_voucher_num; -- Voucher Number

						insert_header(l_hdr_table,p_source,lc_error_msg,lc_errcode);
						IF lc_errcode = '2'
						THEN
						RAISE data_exception;
						END IF;
						ln_count_hdr := ln_count_hdr + 1;
					END IF;	-- lc_rec_type

				END IF; --gn_bad_rec_flag

		        ln_count_tot := ln_count_tot + 1;

		    EXCEPTION
		    WHEN no_data_found
		    THEN
			    EXIT;
		    END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	    COMMIT;
		-- changes as per version 3.9 starts here --
		IF gn_bad_file_rec_count <> 0
		THEN
			print_debug_msg ('Raising bad_file_exception',FALSE);
			RAISE bad_file_exception;

		END IF;

		-- changes as per version 3.9 ends here --
-- **********************************
-- For Sources: RTV
-- **********************************
	ELSIF p_source = 'US_OD_RTV_MERCHANDISING'
	THEN
	    print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath||' for Source: '||p_source,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF lb_file_exist
		THEN

		-- Open the RTV File
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);

		print_debug_msg ('File open successfull',TRUE);
		LOOP
		    BEGIN
			    UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			    IF lc_newline IS NULL
			    THEN
				    EXIT;
		        END IF;

		        print_debug_msg ('Processing Line:'||lc_newline,FALSE);

		        --parse the line
		        parse_rtv_file(lc_newline,l_table,l_nfields,'|',lc_error_msg,lc_errcode);
		        IF lc_errcode = '2'
				THEN
			        RAISE data_exception;
		        END IF;

		        lc_rec_type := l_table(1);

		        IF lc_rec_type = 'H'
				THEN
			        print_debug_msg ('Insert Header',FALSE);
			        insert_rtv_header(l_table,p_source,lc_error_msg,lc_errcode);
   	                IF lc_errcode = '2'
			        THEN
	                    RAISE data_exception;
	                END IF;
			        ln_count_hdr := ln_count_hdr + 1;

		        ELSIF lc_rec_type = 'D'
				THEN
			        print_debug_msg ('Insert Line',FALSE);
			        insert_rtv_line(l_table,p_source,lc_error_msg,lc_errcode);
   	                IF lc_errcode = '2'
			        THEN
	                   RAISE data_exception;
	                END IF;
			        ln_count_lin := ln_count_lin + 1;

		        ELSE
			        print_debug_msg ('Invalid Record Type',TRUE);
			        lc_errcode := '2';
			        lc_error_msg := 'ERROR - Invalid record type :'||lc_rec_type;
			        RAISE data_exception;
		        END IF;
		        ln_count_tot := ln_count_tot + 1;
		    EXCEPTION
		    WHEN no_data_found
			THEN
			   EXIT;
		    END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	    COMMIT;

		ELSE
		 -- No file
		 print_debug_msg('No data file to process. Continue to stage RTV ',TRUE);
	    END IF; -- if File Exist

	END IF; -- if p_source

    /*print_debug_msg(to_char(ln_count_tot)||' records successfully loaded into the Header Table',FALSE); */

    print_out_msg('================================================ ');
    print_out_msg('No. of header records loaded in the Prestaging table:'||to_char(ln_count_hdr));
    print_out_msg('No. of line records loaded in the Prestaging table :'||to_char(ln_count_lin));
    print_out_msg(' ');
    dbms_lock.sleep(5);

    IF lb_file_exist
	THEN
        lc_phase       := NULL;
        lc_status      := NULL;
        lc_dev_phase   := NULL;
        lc_dev_status  := NULL;
	    lc_message     := NULL;

        OPEN get_dir_path;
        FETCH get_dir_path INTO lc_dirpath;
        CLOSE get_dir_path;

		print_debug_msg('Calling the Common File Copy to copy the source file to AP Folder',TRUE);
        lc_dest_file_name := '/app/ebs/ebsfinance/'||lc_instance_name||'/apinvoice/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)||'_'
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';

        ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
          					                                       'XXCOMFILCOPY',
          					   		                               '',
          							                               '',
          							                               FALSE,
          							                               lc_dirpath||'/'||lc_filename,   --Source File Name
          							                               lc_dest_file_name,              --Dest File Name
          							                               '',
          							                               '',
          							                               'N'   --Deleting the Source File
	    						                                  );

	    IF ln_conc_file_copy_request_id > 0
		THEN
	        COMMIT;

		    print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
		 -- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
							                               request_id   => ln_conc_file_copy_request_id,
							                               interval     => 10,
							                               max_wait     => 0,
							                               phase        => lc_phase,
							                               status       => lc_status,
							                               dev_phase    => lc_dev_phase,
							                               dev_status   => lc_dev_status,
							                               message      => lc_message
														  );

	        print_debug_msg('Status :'||lc_status);
			print_debug_msg('dev_phase :'||lc_dev_phase);
			print_debug_msg('dev_status :'||lc_dev_status);
			print_debug_msg('message :'||lc_message);
		END IF;

		print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);
		lc_dest_file_name:= NULL;
		ln_conc_file_copy_request_id := NULL;

        lc_dest_file_name := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)||'_'
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';

        ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
          					                                       'XXCOMFILCOPY',
          					   		                               '',
          							                               '',
          							                               FALSE,
          							                               lc_dirpath||'/'||lc_filename,   --Source File Name
          							                               lc_dest_file_name,              --Dest File Name
          							                               '',
          							                               '',
          							                               'Y'   --Deleting the Source File
	    						                                  );
    END IF;

    COMMIT;

EXCEPTION
    WHEN nofile
	THEN
        print_debug_msg ('ERROR - File not exists',TRUE);
        p_retcode := 2;
    WHEN data_exception
	THEN
        ROLLBACK;
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg('Error at line:'||lc_newline,TRUE);
        p_errbuf  := lc_error_msg;
        p_retcode := lc_errcode;
	-- changes as per version 3.9 starts here --
	WHEN bad_file_exception
	THEN
        ROLLBACK;
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg('Bad File Issue'||lc_error_msg,TRUE);
        p_errbuf  := lc_error_msg;
		/*print_debug_msg(to_char(ln_count_tot)||' records successfully loaded into the Header Table',FALSE); */

    print_out_msg('================================================ ');
    print_out_msg('No. of header records loaded in the Prestaging table:'||to_char(ln_count_hdr));
    print_out_msg('No. of line records loaded in the Prestaging table :'||to_char(ln_count_lin));
    print_out_msg(' ');
    dbms_lock.sleep(5);

    IF lb_file_exist
	THEN
        lc_phase       := NULL;
        lc_status      := NULL;
        lc_dev_phase   := NULL;
        lc_dev_status  := NULL;
	    lc_message     := NULL;

        OPEN get_dir_path;
        FETCH get_dir_path INTO lc_dirpath;
        CLOSE get_dir_path;

		print_debug_msg('Calling the Common File Copy to copy the source file to AP Folder',TRUE);
        lc_dest_file_name := '/app/ebs/ebsfinance/'||lc_instance_name||'/apinvoice/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)||'_'
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';

        ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
          					                                       'XXCOMFILCOPY',
          					   		                               '',
          							                               '',
          							                               FALSE,
          							                               lc_dirpath||'/'||lc_filename,   --Source File Name
          							                               lc_dest_file_name,              --Dest File Name
          							                               '',
          							                               '',
          							                               'N'   --Deleting the Source File
	    						                                  );

	    IF ln_conc_file_copy_request_id > 0
		THEN
	        COMMIT;

		    print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
		 -- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
							                               request_id   => ln_conc_file_copy_request_id,
							                               interval     => 10,
							                               max_wait     => 0,
							                               phase        => lc_phase,
							                               status       => lc_status,
							                               dev_phase    => lc_dev_phase,
							                               dev_status   => lc_dev_status,
							                               message      => lc_message
														  );

	        print_debug_msg('Status :'||lc_status);
			print_debug_msg('dev_phase :'||lc_dev_phase);
			print_debug_msg('dev_status :'||lc_dev_status);
			print_debug_msg('message :'||lc_message);
		END IF;

		print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);
		lc_dest_file_name:= NULL;
		ln_conc_file_copy_request_id := NULL;

        lc_dest_file_name := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)||'_'
                                                   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';

        ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
          					                                       'XXCOMFILCOPY',
          					   		                               '',
          							                               '',
          							                               FALSE,
          							                               lc_dirpath||'/'||lc_filename,   --Source File Name
          							                               lc_dest_file_name,              --Dest File Name
          							                               '',
          							                               '',
          							                               'Y'   --Deleting the Source File
	    						                                  );
    END IF;

    COMMIT;
       --- p_retcode := 2;	---Commented For NAIT-48272

	-- changes as per version 3.9 ends here --
	--Changes as per version 4.0 Starts here - NAIT-48272(Defect#45304)
	BEGIN
         SELECT SYS_CONTEXT ('USERENV', 'DB_NAME')
           INTO lc_instance_name
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_instance_name := NULL;
            print_debug_msg (   'No data found while getting the Instance Name : '
                    || lc_instance_name
                   );
         WHEN OTHERS
         THEN
            lc_instance_name := NULL;
            print_debug_msg (   'Exception while getting the Instance Name : '
                    || lc_instance_name
                   );
      END;


     BEGIN
	        lc_email_from    := NULL;
          lc_email_to      := NULL;
           lc_email_cc      := NULL;
	       -- lc_email_subject := NULL;
	        lc_email_body    := NULL;

	        SELECT target_value1, -- Email From
                   target_value2, -- Email To
                  target_value3, -- Email CC
                 --  target_value4, -- Email Subject
                   target_value5  -- Email Body
	    	  INTO lc_email_from,
	    	       lc_email_to,
	    		  lc_email_cc,
	    		   --lc_email_subject,
	    		   lc_email_body
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id
	                                  FROM xx_fin_translatedefinition
	                                 WHERE translation_name = 'XX_AP_TRADE_INV_EMAIL'
	                                   AND enabled_flag = 'Y')
                  AND source_value1 = 'TRADE_EDI_BAD_DATA';
	    EXCEPTION
	    WHEN OTHERS
	    THEN
	        lc_email_from    := NULL;
	    	lc_email_to      := NULL;
	      lc_email_cc      := NULL;
	    	---lc_email_subject := NULL;
	    	lc_email_body    := NULL;
	    END;

	      lc_email_subject := lc_instance_name || ' ' || lc_email_sub;

		IF gn_bad_file_rec_count<>0

     THEN

        BEGIN
            conn := xx_pa_pb_mail.begin_mail(sender => lc_email_from,
                                             recipients => lc_email_to,
                                            cc_recipients=>lc_email_cc,
                                             subject => lc_email_subject,
                                             mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

            xx_pa_pb_mail.attach_text( conn => conn,
                                       data => ln_log
                                                );

            xx_pa_pb_mail.end_mail( conn => conn );

            COMMIT;

            print_debug_msg ('Email sent successfully',TRUE);
        EXCEPTION
        WHEN OTHERS
	    THEN
            print_debug_msg ('Error while sending the Email',TRUE);
        END;
		END IF;

	--Changes as per version 4.0 ends here - NAIT-48272(Defect#45304)

    WHEN UTL_FILE.INVALID_OPERATION
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Invalid Operation',TRUE);
        p_retcode:=2;
    WHEN UTL_FILE.INVALID_FILEHANDLE
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Invalid File Handle',TRUE);
        p_retcode := 2;
    WHEN UTL_FILE.READ_ERROR
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Read Error',TRUE);
        p_retcode := 2;
    WHEN UTL_FILE.INVALID_PATH
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Invalid Path',TRUE);
        p_retcode := 2;
    WHEN UTL_FILE.INVALID_MODE
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Invalid Mode',TRUE);
        p_retcode := 2;
    WHEN UTL_FILE.INTERNAL_ERROR
	THEN
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - Internal Error',TRUE);
        p_retcode := 2;
    WHEN OTHERS
	THEN
        ROLLBACK;
        UTL_FILE.FCLOSE(l_filehandle);
        print_debug_msg ('ERROR - '||substr(sqlerrm,1,250),TRUE);
        p_retcode := 2;
END load_prestaging;

END XX_AP_INVOICE_INTEGRAL_PKG;
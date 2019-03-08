create or replace 
PACKAGE BODY      XX_AR_REPRINT_SUMMBILL AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_REPRINT_SUMMBILL.pkb                                          |
---|                                                                                                        |
---|    Description             :       This package used for Paper Bills(re-prints and special handling)   |
-- |                                    to generate PDF outputs.                                            |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                |
---|    1.1             07-MAR-2008       Balaguru Seshadri  Sorting Logic -Defect 2971                     |
---|    1.1             09-MAR-2008       Balaguru Seshadri  Cursor G_TRX_LINES /G_INFODOC_LINES modified   |
---|    1.1             09-MAR-2008       Sai Bala           Cursor G_TRX_LINES /G_INFODOC_LINES modified   |
---|                                                         to account for single Tiered Discount line     |
---|                                                         as well as Miscellaneous Credit memo           |
---|    1.2             24-JUL-2008       Sarat Uppalapati   Defect 9165                                    |
---|    1.2             29-JUL-2008       Sarat Uppalapati   Defect 9165 (Undo the changes)                 |
---|    1.2             29-JUL-2008       Sarat Uppalapati   Defect 9046                                    |
---|    1.3             29-JUL-2008       Sarat Uppalapati   Added Conditional logic for Defect 9046        |
---|    1.4             07-AUG-2008       Sarat Uppalapati   Defect 9555                                    |
---|    1.5             13-AUG-2008       Sarat Uppalapati   Added parameter p_reprint to the function      |
---|                                                         p_spec_handling_flag for defect 9555           |
---|    1.6             02-DEC-2008       Sambasiva Reddy    Changed for the Defect # 12223                 |
-- |    1.7             08-JAN-2009       Ranjith Prabu      Changes for defect 11993                       |
-- |    1.8             03-APR-2009       Gokila Tamilselvam Changed the view to base table                 |
-- |    1.9             28-MAR-2009       Gokila Tamilselvam Defect# 15063.                                 |
-- |    2.0             18-NOV-2009       Tamil Vendhan L    Modified for R1.2 Defect 1143 (CR 621)         |
-- |    2.1             16-DEC-2009       Gokila Tamilselvam Modified for R1.2 Defect# 1210 CR# 466.        |
-- |    2.2             28-JAN-2010       Lincy K            Modified get_bill_from_date function for       |
-- |                                                         R1.2 Defect# 4136                              |
-- |    2.3             02-FEB-2010       Lincy K            Updated get_bill_from_date function for        |
-- |                                                         R1.2 Defect# 4136                              |
-- |    2.4             04-MAR-2010       Tamil Vendhan L    Modified for R1.3 CR 738 Defect 2766           |
-- |    2.5             08-APR-2010       Lincy K            Updating attribute15 for defect 4760 and       |
-- |                                                         updating WHO columns for defect 4761           |
-- |    2.6             19-MAY-2010       Gokila Tamilselvam Modified for R 1.4 CR 586.                     |
-- |    2.6             24-JUN-2010       Ganga Devi R       Modified 'get_cbi_amount_due' function to get  |
-- |                                                         the FLO Code as same as the total invoice      |
-- |                                                         amount for defect#5074                         |
-- |    2.7             16-JAN-2014       Aradhna Sharma     Added status as FINAL for defect#27208 for R12 |
-- |    2.8             02-FEB-2014       Deepak V           QC Defect 31838 Performance fix                |
-- |    2.9             10-AUG-2015       Shaik Ghouse       QC Defect 35282 SUMM ONE Detail Issues         |
-- |    3.0             19-OCT-2015       Vasu Raparla       Removed Schema References for R12.2            |
-- |    3.1             26-JAN-2016       Havish Kasina      Changed the data type length from 40 Bytes to  |
-- |                                                         80 Bytes as per Defect 1994 (MOD4B Release 3   |
-- |                                                         Changes)                                       |
-- |    4.1             06-MAR-2019	      Sravan Reddy       Added functions get_cons_msg_bcc,              | 
-- |                                                         get_paydoc_flag, get_pod_msg as part of        |  	
-- |                                                         NAIT-80452                                     |
---+========================================================================================================+

-- Added for defect 31838
 TYPE ln_rec_rprn_rows IS RECORD
(	REQUEST_ID NUMBER,
	CONS_INV_ID NUMBER,
	LINE_TYPE VARCHAR2(20 BYTE),
	LINE_SEQ NUMBER,
	SF_TEXT VARCHAR2(240 BYTE),
	SFDATA1 VARCHAR2(80 BYTE), -- Changed the data type length from 40 Bytes to 80 Bytes as per Defect 1994 (MOD4B Release 3 Changes)
	SFDATA2 VARCHAR2(80 BYTE), -- Changed the data type length from 40 Bytes to 80 Bytes as per Defect 1994 (MOD4B Release 3 Changes)
	SFDATA3 VARCHAR2(80 BYTE), -- Changed the data type length from 40 Bytes to 80 Bytes as per Defect 1994 (MOD4B Release 3 Changes)
	SFDATA4 VARCHAR2(80 BYTE), -- Changed the data type length from 40 Bytes to 80 Bytes as per Defect 1994 (MOD4B Release 3 Changes)
	SFDATA5 VARCHAR2(80 BYTE), -- Changed the data type length from 40 Bytes to 80 Bytes as per Defect 1994 (MOD4B Release 3 Changes)
	SUBTOTAL NUMBER,
	DELIVERY NUMBER,
	DISCOUNTS NUMBER,
	TAX NUMBER,
	TOTAL NUMBER,
	PAGE_BREAK VARCHAR2(1 BYTE),
	ATTRIBUTE1 VARCHAR2(80 BYTE),
	ATTRIBUTE2 VARCHAR2(80 BYTE),
	ATTRIBUTE3 VARCHAR2(80 BYTE),
	ATTRIBUTE4 VARCHAR2(80 BYTE),
	ATTRIBUTE5 VARCHAR2(80 BYTE),
	ATTRIBUTE6 VARCHAR2(80 BYTE),
	ATTRIBUTE7 VARCHAR2(80 BYTE),
	ATTRIBUTE8 VARCHAR2(80 BYTE),
	ATTRIBUTE9 VARCHAR2(80 BYTE),
	ATTRIBUTE10 VARCHAR2(80 BYTE),
	ORG_ID NUMBER
   );

   TYPE ln_table_rprn_rows IS TABLE OF ln_rec_rprn_rows INDEX BY BINARY_INTEGER;
   ln_tab_rprn_rows ln_table_rprn_rows;
   lntrx NUMBER := -1;

   G_PKB_VERSION NUMBER(2,1)  :='2.6';

PROCEDURE insert_rprn_rows_tbl
                (
                  p_reqs_id      IN NUMBER
                 ,p_cons_id      IN NUMBER
                 ,p_line_type    IN VARCHAR2
                 ,p_line_seq     IN NUMBER
                 ,p_sf_text      IN VARCHAR2
                 ,p_pg_brk       IN VARCHAR2
                 ,p_ordnum_attr1 IN VARCHAR2
                 ,p_ord_dt_attr2 IN VARCHAR2
                 ,p_subtotal     IN VARCHAR2
                 ,p_delivery     IN VARCHAR2
                 ,p_discounts    IN VARCHAR2
                 ,p_tax          IN VARCHAR2
                 ,p_total        IN VARCHAR2
                 ,p_sf_data1     IN VARCHAR2
                 ,p_sf_data2     IN VARCHAR2
                 ,p_sf_data3     IN VARCHAR2
                 ,p_sf_data4     IN VARCHAR2
                 ,p_sf_data5     IN VARCHAR2
                 ,p_invoice_id   IN NUMBER
                ) AS
BEGIN
        -- Added for Defect 31838
        lntrx := lntrx + 1;
		ln_tab_rprn_rows(lntrx).request_id:= p_reqs_id;
		ln_tab_rprn_rows(lntrx).cons_inv_id:= p_cons_id;
		ln_tab_rprn_rows(lntrx).line_type:= p_line_type;
		ln_tab_rprn_rows(lntrx).line_seq:= p_line_seq;
		ln_tab_rprn_rows(lntrx).sf_text:= p_sf_text;
		ln_tab_rprn_rows(lntrx).page_break:= p_pg_brk;
		ln_tab_rprn_rows(lntrx).attribute1:= p_ordnum_attr1;
		ln_tab_rprn_rows(lntrx).attribute2:= p_ord_dt_attr2;
		ln_tab_rprn_rows(lntrx).subtotal:= p_subtotal;
		ln_tab_rprn_rows(lntrx).delivery:= p_delivery;
		ln_tab_rprn_rows(lntrx).discounts:= p_discounts;
		ln_tab_rprn_rows(lntrx).tax:= p_tax;
		ln_tab_rprn_rows(lntrx).total:= p_total;
		ln_tab_rprn_rows(lntrx).sfdata1:= p_sf_data1;
		ln_tab_rprn_rows(lntrx).sfdata2:= p_sf_data2;
		ln_tab_rprn_rows(lntrx).sfdata3:= p_sf_data3;
		ln_tab_rprn_rows(lntrx).sfdata4:= p_sf_data4;
		ln_tab_rprn_rows(lntrx).sfdata5:= p_sf_data5;
		ln_tab_rprn_rows(lntrx).attribute3:= p_invoice_id;

		/* Commented for defect 31838
         INSERT INTO xx_ar_cbi_rprn_rows
          (
            request_id
           ,cons_inv_id
           ,line_type
           ,line_seq
           ,sf_text
           ,page_break
           ,attribute1
           ,attribute2
           ,subtotal
           ,delivery
           ,discounts
           ,tax
           ,total
           ,sfdata1
           ,sfdata2
           ,sfdata3
           ,sfdata4
           ,sfdata5
           ,attribute3 --Copy Invoice ID..
          )
         VALUES
          (
            p_reqs_id
           ,p_cons_id
           ,p_line_type
           ,p_line_seq
           ,p_sf_text
           ,p_pg_brk
           ,p_ordnum_attr1
           ,p_ord_dt_attr2
           ,p_subtotal
           ,p_delivery
           ,p_discounts
           ,p_tax
           ,p_total
           ,p_sf_data1
           ,p_sf_data2
           ,p_sf_data3
           ,p_sf_data4
           ,p_sf_data5
           ,p_invoice_id
          );
		  */
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_rprn_rows.when others');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END insert_rprn_rows_tbl;



FUNCTION Run_DETAIL (p_template IN VARCHAR2) RETURN BOOLEAN IS
BEGIN
 IF p_template !='DETAIL' THEN
  RETURN FALSE;
 END IF;
   RETURN TRUE;
END Run_DETAIL;

FUNCTION Run_SUMMARIZE (p_template IN VARCHAR2) RETURN BOOLEAN IS
BEGIN
 IF p_template !='SUMMARIZE' THEN
  RETURN FALSE;
 END IF;
   RETURN TRUE;
END Run_SUMMARIZE;

FUNCTION Run_ONE (p_template IN VARCHAR2) RETURN BOOLEAN IS
BEGIN
 IF p_template !='ONE' THEN
  RETURN FALSE;
 END IF;
   RETURN TRUE;
END Run_ONE;

FUNCTION get_bill_from_date( p_customer_id IN NUMBER
                            ,p_site_id     IN NUMBER
                            ,p_consinv_id  IN NUMBER
                            ,infocopy_tag  IN VARCHAR2
                            ,p_spec_handling_flag     IN VARCHAR2 -- Defect 9555
                           ) RETURN DATE AS
 bill_from_dt DATE :=TO_DATE(NULL);
 ln_cbi_id    NUMBER :=0;
 ln_cust_docid NUMBER; -- added for defect 4136
BEGIN
 IF infocopy_tag !='INV_IC' THEN

   -- Commented the below IF condition as part of R1.2 Defect# 1210 CR# 466. Both for Paydoc and paydoc_ic consinv_id is going to be same.
   /*IF infocopy_tag ='PAYDOC' THEN
    ln_cbi_id :=p_consinv_id;
   ELSE
    ln_cbi_id :=SUBSTR(p_consinv_id ,1 ,LENGTH(p_consinv_id)-1);
   END IF;
   */

   ln_cbi_id :=p_consinv_id;
   -- End of changes for R1.2 Defect# 1210 CR# 466.

  -- Added IF then Else for p_spec_handling_flag for the defect 9555  on 13-AUG-08
  -- By Sarat Uppalapati
  IF UPPER(p_spec_handling_flag) IN ('YES','Y') THEN -- if for reprints

    BEGIN
    --Defect 9046 changed this query as cons_inv_id does not appear to be truly sequential
    --by Sarat Uppalapati on 29-JUL-08
          --SELECT MAX(CUT_OFF_DATE)  -- Commented for Defect# 15063.
          SELECT MAX(TO_DATE(attribute1)) --Added for Defect# 15063. The logic of the attribute1 column is handled in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN
          INTO   bill_from_dt
          FROM ar_cons_inv  -- Removed apps schema References
          WHERE customer_id = p_customer_id
          AND site_use_id = p_site_id
        ---  AND status = 'ACCEPTED' -- Defect 9046
	    AND status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
          AND cons_inv_id != ln_cbi_id;
          --AND cons_inv_id != p_consinv_id;
    --     SELECT TRUNC(cut_off_date) --Per defect 9046, remove the issue date and changed it to cut off date.
    --     INTO   bill_from_dt
    --     FROM   ar_cons_inv
    --     WHERE  cons_inv_id = (
    --                  SELECT MAX(cons_inv_id)-1
    --                  FROM   ar_cons_inv
    --                  WHERE  customer_id =p_customer_id
    --                    AND  site_use_id =p_site_id
    --                    AND  status = 'ACCEPTED' -- Defect 9046
    --                 );
    -- RETURN bill_from_dt;

        -- Added IF then else end if logic, to get minimum transaction_date for defect 9046
          IF bill_from_dt IS NULL THEN
          BEGIN
           SELECT MIN(TRUNC(TRANSACTION_DATE))
           INTO   bill_from_dt
           FROM  ar_cons_inv_trx acit
                 ,ar_cons_inv aci -- Defect 9046
           WHERE acit.cons_inv_id      =ln_cbi_id
             AND acit.cons_inv_id = aci.cons_inv_id
             ----AND aci.status = 'ACCEPTED'-- Defect 9046
	      AND aci.status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
             AND acit.transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
             RETURN bill_from_dt;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            RETURN TO_DATE(NULL);
           WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'3-Error in get bill from date ,infocopy tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'3-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
          END;
          ELSE
                  RETURN bill_from_dt;
          END IF;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
          BEGIN
           SELECT MIN(TRUNC(TRANSACTION_DATE))
           INTO   bill_from_dt
           FROM  ar_cons_inv_trx acit
                 ,ar_cons_inv aci -- Defect 9046
           WHERE acit.cons_inv_id      =ln_cbi_id
             AND acit.cons_inv_id = aci.cons_inv_id
            --- AND aci.status = 'ACCEPTED'-- Defect 9046
	      AND aci.status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
             AND acit.transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
             RETURN bill_from_dt;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            RETURN TO_DATE(NULL);
           WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'1-Error in get bill from date ,infocopy tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'1-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
          END;
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'2-Error in get bill from date ,infocopy tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'2-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
    END;
  ELSE
    --fnd_file.put_line(fnd_file.log ,'Special Handling Flag -'||p_spec_handling_flag||to_char(sysdate,'DD-MON-YYYY HH24:MI'));

  -- Added logic for getting the original bill from date for Reprints, Defect 9555
  -- By Sarat Uppalapati on 14-AUG-08
      --SELECT MAX(CUT_OFF_DATE)  -- Commented for Defect# 15063.
      SELECT MAX(TO_DATE(attribute1)) --Added for Defect# 15063. The logic of the attribute1 column is handled in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN
      INTO bill_from_dt
      FROM ar_cons_inv           -- Removed apps schema References
     WHERE customer_id = p_customer_id
       AND site_use_id = p_site_id
      ----- AND status = 'ACCEPTED'
        AND status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
       AND cons_inv_id != ln_cbi_id
       -- The below condition is commented for the Defect#15063.
       /*AND (cut_off_date) < ( SELECT (MAX(CUT_OFF_DATE))
                              FROM apps.ar_cons_inv
                             WHERE customer_id = p_customer_id
                               AND site_use_id = p_site_id
                               AND status = 'ACCEPTED'
                               AND cons_inv_id = ln_cbi_id);*/
        --Added for Defect# 15063. The logic of the attribute1 column is handled in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN
        AND TO_DATE(attribute1) < ( SELECT MAX(TO_DATE(attribute1))
                                    FROM ar_cons_inv   -- Removed apps schema References
                                    WHERE customer_id  = p_customer_id
                                    AND site_use_id    = p_site_id
                                   --- AND status         = 'ACCEPTED'
				    AND status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
                                    AND cons_inv_id = ln_cbi_id);
      IF bill_from_dt IS NULL THEN
           BEGIN
           SELECT MIN(TRUNC(TRANSACTION_DATE))
           INTO   bill_from_dt
           FROM  ar_cons_inv_trx acit
                 ,ar_cons_inv aci
           WHERE acit.cons_inv_id      =ln_cbi_id
             AND acit.cons_inv_id = aci.cons_inv_id
            ---- AND aci.status = 'ACCEPTED'
	      AND aci.status IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
             AND acit.transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
             RETURN bill_from_dt;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            RETURN TO_DATE(NULL);
           WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'3-Error in get bill from date ,paydoc tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'3-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
          END;
      ELSE
          RETURN bill_from_dt;
      END IF;
  END IF;    -- End for reprints
 ELSE
-- Start of changes for  defect 4136
 BEGIN

   SELECT DISTINCT cust_doc_id
   INTO   ln_cust_docid
   FROM   xx_ar_cons_bills_history od_summbills
   WHERE  od_summbills.customer_id = p_customer_id
   AND    od_summbills.attribute7  = p_site_id
   AND    od_summbills.attribute8  = 'INV_IC'
   AND    od_summbills.cons_inv_id = p_consinv_id;

 EXCEPTION
 WHEN NO_DATA_FOUND THEN

    -- Added the below block as part of R1.4 CR# 586.
    BEGIN

       SELECT n_ext_attr1
       INTO   ln_cust_docid
       FROM   xx_ar_gen_bill_temp
       WHERE  customer_id     = p_customer_id
       AND    billing_site_id = p_site_id
       AND    cons_inv_id     = p_consinv_id
       AND    c_ext_attr1     = 'INV_IC';

    EXCEPTION
    WHEN NO_DATA_FOUND THEN

       BEGIN

          SELECT DISTINCT cust_doc_id
          INTO   ln_cust_docid
          FROM   xx_ar_ebl_cons_hdr_hist
          WHERE  cust_account_id        = p_customer_id
          AND    bill_to_site_use_id    = p_site_id
          AND    cons_inv_id            = p_consinv_id
          AND    infocopy_tag           = 'INV_IC';

       EXCEPTION
       WHEN NO_DATA_FOUND THEN

          ln_cust_docid := NULL;
          fnd_file.put_line(fnd_file.log ,'Cust Doc ID is NULL Since we are trying to reprint INV_IC scenario as a Paydoc');

       END;

    END;

END;
-- End of changes for Defect# 4136

 IF UPPER(p_spec_handling_flag) IN ('YES','Y') THEN -- if for reprints
  --fnd_file.put_line(fnd_file.log ,'Special Handling Flag -'||p_spec_handling_flag||to_char(sysdate,'DD-MON-YYYY HH24:MI'));

    BEGIN
    --Defect 9046 changed this query as cons_inv_id does not appear to be truly sequential
    --by Sarat Uppalapati on 29-JUL-08
        SELECT MAX(TRUNC(od_summbills.bill_from_date))
          INTO bill_from_dt
          FROM xx_ar_cons_bills_history od_summbills
         WHERE od_summbills.customer_id =p_customer_id
           AND od_summbills.attribute7  =p_site_id
           AND od_summbills.attribute8  ='INV_IC'
           AND od_summbills.cust_doc_id =ln_cust_docid -- added for defect 4136
           AND od_summbills.cons_inv_id != p_consinv_id;
          -- RETURN bill_from_dt; -- Defect 9555

    --     SELECT MAX(TRUNC(od_summbills.bill_from_date))
    --     INTO   bill_from_dt
    --     FROM   xx_ar_cons_bills_history od_summbills
    --     WHERE  od_summbills.cons_inv_id = (
    --                  SELECT MAX(cons_inv_id)-1
    --                  FROM   xx_ar_cons_bills_history
    --                  WHERE  customer_id =p_customer_id
    --                    AND  attribute7  =p_site_id
    --                    AND  attribute8  ='INV_IC');
          IF bill_from_dt IS NULL THEN
          BEGIN
           SELECT MIN(TRUNC(ract.trx_date))
           INTO   bill_from_dt
           FROM  ra_customer_trx ract,xx_ar_cons_bills_history od_summbills
           WHERE od_summbills.cons_inv_id =p_consinv_id
             AND od_summbills.attribute8 ='INV_IC'
             AND ract.complete_flag = 'Y' -- Defect 9046
             AND od_summbills.customer_id =p_customer_id
             AND od_summbills.attribute7  =p_site_id
             AND od_summbills.attribute1  =ract.customer_trx_id;
             RETURN bill_from_dt;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            RETURN TO_DATE(NULL);
           WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'3-Error in get bill from date ,infocopy tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'3-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
          END;
          ELSE
                  RETURN bill_from_dt;
          END IF;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
          BEGIN
           SELECT MIN(TRUNC(ract.trx_date))
           INTO   bill_from_dt
           FROM  ra_customer_trx ract,xx_ar_cons_bills_history od_summbills
           WHERE od_summbills.cons_inv_id =p_consinv_id
             AND od_summbills.attribute8 ='INV_IC'
             AND ract.complete_flag = 'Y' -- Defect 9046
             AND od_summbills.customer_id =p_customer_id
             AND od_summbills.attribute7  =p_site_id
             AND od_summbills.attribute1  =ract.customer_trx_id;
             RETURN bill_from_dt;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            RETURN TO_DATE(NULL);
           WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log ,'1-Error in get bill from date ,infocopy tag :'||infocopy_tag);
            fnd_file.put_line(fnd_file.log ,'1-get_bill_from_date -'||SQLERRM);
            RETURN TO_DATE(NULL);
          END;
         WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log ,'2-Error in get bill from date ,infocopy tag :'||infocopy_tag);
      fnd_file.put_line(fnd_file.log ,'2-get_bill_from_date -'||SQLERRM);
      RETURN TO_DATE(NULL);
        END;
  ELSE
  --fnd_file.put_line(fnd_file.log ,'Special Handling Flag -'||p_spec_handling_flag||to_char(sysdate,'DD-MON-YYYY HH24:MI'));

  -- Added logic for getting the original bill from date for Reprints, Defect 9555
  -- By Sarat Uppalapati on 14-AUG-08

        --SELECT MAX(TRUNC(od_summbills.bill_from_date))
        SELECT MAX(TRUNC(od_summbills.bill_from_date)) + 1  -- Added as part of Defect# 4136
          INTO bill_from_dt
          FROM xx_ar_cons_bills_history od_summbills
         WHERE od_summbills.customer_id =p_customer_id
           AND od_summbills.attribute7  =p_site_id
           AND od_summbills.attribute8  ='INV_IC'
           AND od_summbills.cons_inv_id != p_consinv_id
           AND od_summbills.cust_doc_id =ln_cust_docid -- added for defect 4136
           AND od_summbills.bill_from_date <
                                  ( SELECT MAX(TRUNC(od_summbills.bill_from_date))
                                      FROM xx_ar_cons_bills_history od_summbills
                                     WHERE od_summbills.customer_id =p_customer_id
                                       AND od_summbills.attribute7  =p_site_id
                                       AND od_summbills.attribute8  ='INV_IC'
                                       AND od_summbills.cons_inv_id = p_consinv_id);
          IF bill_from_dt IS NULL THEN
             BEGIN
              SELECT MIN(TRUNC(ract.trx_date))
                INTO   bill_from_dt
                FROM  ra_customer_trx ract,xx_ar_cons_bills_history od_summbills
                WHERE od_summbills.cons_inv_id =p_consinv_id
                  AND od_summbills.attribute8 ='INV_IC'
                  AND ract.complete_flag = 'Y'
                  AND od_summbills.customer_id =p_customer_id
                  AND od_summbills.attribute7  =p_site_id
                  AND od_summbills.attribute1  =ract.customer_trx_id;

                -- Added the below exception part for Defect# 1210 CR# 466. To get the bill from date for EBILL customers.

                IF bill_from_dt IS NULL THEN

                   SELECT (MAX (TRUNC(issue_date)) + 1)
                   INTO   bill_from_dt
                   FROM   xx_ar_gen_bill_temp
                   WHERE  customer_id     = p_customer_id
                   AND    billing_site_id = p_site_id
                   AND    cons_inv_id    != p_consinv_id
                   AND    c_ext_attr1     = 'INV_IC'
                   AND    issue_date      < (SELECT MAX (TRUNC(issue_date))
                                             FROM   xx_ar_gen_bill_temp
                                             WHERE  customer_id     = p_customer_id
                                             AND    billing_site_id = p_site_id
                                             AND    cons_inv_id     = p_consinv_id
                                             AND    c_ext_attr1     = 'INV_IC'
                                             );

                   IF bill_from_dt IS NULL THEN

                      SELECT MIN(TRUNC(RCT.trx_date))
                      INTO   bill_from_dt
                      FROM   ra_customer_trx            RCT
                            ,xx_ar_gen_bill_lines_all   XAGBLA
                      WHERE  XAGBLA.n_ext_attr2         = p_consinv_id
                      AND    XAGBLA.c_ext_attr1         = 'INV_IC'
                      AND    RCT.complete_flag          = 'Y'
                      AND    XAGBLA.customer_id         = p_customer_id
                      AND    XAGBLA.billing_site_id     = p_site_id
                      AND    XAGBLA.customer_trx_id     = RCT.customer_trx_id;

                         -- Added as part of R1.4 CR# 586.
                         IF bill_from_dt IS NULL THEN

                            SELECT MAX(bill_to_date) + 1
                            INTO   bill_from_dt
                            FROM   xx_ar_ebl_cons_hdr_hist   XAECHH
                            WHERE  XAECHH.cons_inv_id         != p_consinv_id
                            AND    XAECHH.cust_account_id     = p_customer_id
                            AND    XAECHH.bill_to_site_use_id = p_site_id
                            AND    XAECHH.infocopy_tag        = 'INV_IC'
                            AND    XAECHH.bill_to_date        < ( SELECT MAX(bill_to_date)
                                                                  FROM   xx_ar_ebl_cons_hdr_hist
                                                                  WHERE  cons_inv_id         = p_consinv_id
                                                                  AND    cust_account_id     = p_customer_id
                                                                  AND    bill_to_site_use_id = p_site_id
                                                                  AND    infocopy_tag        = 'INV_IC'
                                                                 );

                            IF bill_from_dt IS NULL THEN

                               SELECT MIN(TRUNC(RCT.trx_date))
                               INTO   bill_from_dt
                               FROM   ra_customer_trx            RCT
                                     ,xx_ar_ebl_cons_hdr_hist    XAECHH
                               WHERE  XAECHH.cons_inv_id         = p_consinv_id
                               AND    XAECHH.infocopy_tag        = 'INV_IC'
                               AND    XAECHH.cust_account_id     = p_customer_id
                               AND    XAECHH.customer_trx_id     = RCT.customer_trx_id;

                            END IF;

                         END IF;
                         -- End of changes of R1.4 CR# 586.

                   END IF;

                END IF;
                -- End of R1.2 Defect# 1210 CR# 466.

                  RETURN bill_from_dt;
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                 RETURN TO_DATE(NULL);
                WHEN OTHERS THEN
                 fnd_file.put_line(fnd_file.log ,'3-Error in get bill from date ,infocopy tag :'||infocopy_tag);
                 fnd_file.put_line(fnd_file.log ,'3-get_bill_from_date -'||SQLERRM);
                 RETURN TO_DATE(NULL);
             END;
          ELSE
             RETURN bill_from_dt;
          END IF;

           RETURN bill_from_dt;

  END IF;
 END IF;
 commit;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'3-Error in get bill from date...');
  fnd_file.put_line(fnd_file.log ,'3-get_bill_from_date -'||SQLERRM);
  RETURN TO_DATE(NULL);
END get_bill_from_date;

FUNCTION beforereport RETURN BOOLEAN
IS

-- ===================================
-- Cursor Declaration...
-- ===================================
--Commented for the Defect 13576, 13577 and 13578. Base table is used instead of view

/*
CURSOR g_pay_cust IS
select  hzlo.province                    bill_to_province
       ,hzca.account_number              billing_id
       ,aci.cons_inv_id                  cbi_id
       ,aci.cons_billing_number          cbi_number
       ,apps.xx_ar_cbi_paydoc_ministmnt
        (aci.cons_inv_id ,'TOTAL')       cbi_amount_due
     -- Start for Defect # 12223
       ,xcdm.document_id                  document_id
        ,xcdm.doc_sort_order              sort_order
        ,substr(xcdm.doc_sort_order ,1 ,instr(xcdm.doc_sort_order ,xcdm.total_through_field_id))||'1' total_by
        ,substr(xcdm.doc_sort_order ,1 ,instr(xcdm.doc_sort_order ,xcdm.page_break_through_id))||'1' page_break
        ,xcdm.doc_detail_level      template
     -- End for Defect # 12223
 from   ar_cons_inv              aci
       ,hz_cust_accounts         hzca
       ,hz_cust_acct_sites       hzas
       ,hz_cust_site_uses        hzsu
       ,hz_party_sites           hzps
       ,hz_locations             hzlo
       ,ra_terms                 term
       ,xx_cdh_a_ext_billdocs_v xceb      --Added for Defect # 12223
       ,xx_cdh_mbs_document_master xcdm   --Added for Defect # 12223
 where  1 =1
   and  aci.customer_id        = NVL(P_CUST_ACCOUNT_ID,aci.customer_id)  --commented for the Defect # 12223
   and  aci.cons_billing_number BETWEEN NVL(P_SUMM_BILL_NUM, aci.cons_billing_number) AND NVL(P_SUMM_BILL_NUM_TO, aci.cons_billing_number)
   and  aci.status             ='ACCEPTED'
   -- Start for the Defect # 12223
   AND aci.customer_id             =xceb.cust_account_id
   AND xceb.billdocs_doc_id        =xcdm.document_id
   AND xceb.billdocs_doc_type      ='Consolidated Bill'
 --  AND xceb.billdocs_delivery_meth ='PRINT'   -- commented for defect 11993
   AND (xceb.billdocs_delivery_meth ='PRINT'   OR  P_SPEC_HANDLING_FLAG<>'Y')   -- added for defect 11993
   AND xceb.billdocs_paydoc_ind    ='Y'
   AND xcdm.doc_detail_level       = NVL(P_DOC_DETAIL,xcdm.doc_detail_level)
 --  AND XCDM.document_id = NVL(P_MBS_DOCUMENT_ID,XCDM.document_id)      commented for defect 11993
   AND (DECODE(P_SPEC_HANDLING_FLAG,'Y',aci.attribute2,NULL) IS NULL
        AND DECODE(P_SPEC_HANDLING_FLAG,'Y',aci.attribute4,NULL) IS NULL
        AND DECODE(P_SPEC_HANDLING_FLAG,'Y',aci.attribute10,NULL) IS NULL
       )
   AND DECODE(P_SPEC_HANDLING_FLAG,'Y',xceb.billdocs_special_handling,1) IS NOT NULL
   AND DECODE(P_SPEC_HANDLING_FLAG,'Y',XX_AR_INV_FREQ_PKG.compute_effective_date
      --    ( XCEB.billdocs_payment_term, TRUNC(ACI.cut_off_date)),'01-JAN-00') <= NVL(p_as_of_date1,'01-JAN-00') --- commented for defect 11993
        ( XCEB.billdocs_payment_term, TRUNC(ACI.cut_off_date-1)),'01-JAN-00') <= NVL(p_as_of_date1,'01-JAN-00')  -- added for defect 11993
   AND  EXISTS
            (
              SELECT 1
              FROM   ar_cons_inv_trx_lines
              WHERE  cons_inv_id =aci.cons_inv_id
            )
   -- End for the Defect # 12223
   and  hzca.cust_account_id   =aci.customer_id
   and  hzas.cust_account_id   =aci.customer_id
   and  hzsu.cust_acct_site_id =hzas.cust_acct_site_id
   and  hzsu.site_use_id       =aci.site_use_id
   and  hzps.party_site_id     =hzas.party_site_id
   and  hzlo.location_id       =hzps.location_id
   and  term.term_id           =aci.term_id
   ORDER BY aci.cons_billing_number; --Added for Defect # 12223
   */

   --End of Change for the Defect 13576, 13577 and 13578.

--Added for the Defect 13576, 13577 and 13578. Base table is used instead of view
CURSOR g_pay_cust ( p_attr_group_id NUMBER
                   ,p_bill_from     VARCHAR2  -- Added this for R1.2 Defect# 1210 CR# 466.
                   ,p_bill_to       VARCHAR2  -- Added this for R1.2 Defect# 1210 CR# 466.
                   ,p_virtual_bill  NUMBER    -- Added this for R1.2 Defect# 1210 CR# 466.
                   ,p_site_use_id   NUMBER    -- Added this for R1.2 Defect# 1210 CR# 466.
                   )
IS
   SELECT  HZLO.province                    bill_to_province
          ,HZCA.account_number              billing_id
          ,ACI.cons_inv_id                  cbi_id
          ,ACI.cons_billing_number          cbi_number
          ,xx_ar_cbi_paydoc_ministmnt  -- Removed apps schema References
                 (ACI.cons_inv_id ,'TOTAL')  cbi_amount_due
-- Commented for R1.3 CR 738 Defect 2766
/*          ,XCDM.document_id                  document_id
          ,XCDM.doc_sort_order              sort_order
          ,SUBSTR(XCDM.doc_sort_order ,1 ,instr(XCDM.doc_sort_order ,XCDM.total_through_field_id))||'1' total_by
          ,substr(XCDM.doc_sort_order ,1 ,instr(XCDM.doc_sort_order ,XCDM.page_break_through_id))||'1'  page_break
          ,xcdm.doc_detail_level      template*/
          -- The below columns are added for R1.2 Defect# 1210 CR# 466.
-- Added for R1.3 CR 738 Defect 2766
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',XCDM.document_id
                  ,NULL
                  )                          document_id
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',XCDM.doc_sort_order
                  ,NULL
                  )                          sort_order
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',SUBSTR(XCDM.doc_sort_order ,1 ,instr(XCDM.doc_sort_order ,XCDM.total_through_field_id))||'1'
                  ,NULL
                  )                          total_by
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',substr(XCDM.doc_sort_order ,1 ,instr(XCDM.doc_sort_order ,XCDM.page_break_through_id))||'1'
                  ,NULL
                  )                          page_break
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',xcdm.doc_detail_level
                  ,NULL
                  )                          template
-- End of changes for R1.3 CR 738 Defect 2766
          ,DECODE( P_INFOCOPY_FLAG
                  ,'Y','PAYDOC_IC'
                  ,'PAYDOC'
                  )                         DOC_TYPE
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',TO_NUMBER(NULL)
                  ,ACI.site_use_id
                  )                         SITE_USE_ID
          ,DECODE( P_SPEC_HANDLING_FLAG
                  ,'Y',TO_NUMBER(NULL)
                  ,ACI.cons_inv_id
                  )                         CBI_ID1
           --End for R1.2 Defect# 1210 CR# 466.
            ,'N'                              EBILL_IND   -- Added as part of R1.4 CR# 586
   FROM    ar_cons_inv                      ACI
          ,hz_cust_accounts                 HZCA
          ,hz_cust_acct_sites               HZAS
          ,hz_cust_site_uses                HZSU
          ,hz_party_sites                   HZPS
          ,hz_locations                     HZLO
          ,ra_terms                         TERM
          ,xx_cdh_cust_acct_ext_b     XCCAE
          ,xx_cdh_mbs_document_master       XCDM
   WHERE  1 =1
   AND    ACI.customer_id              = NVL(P_CUST_ACCOUNT_ID,ACI.customer_id)
   --AND    aci.cons_billing_number      BETWEEN NVL(P_SUMM_BILL_NUM, ACI.cons_billing_number) AND NVL(P_SUMM_BILL_NUM_TO, ACI.cons_billing_number)
                                                                -- Commented for R1.2 Defect# 1210 CR# 466.
   AND    aci.cons_billing_number      BETWEEN NVL(p_bill_from, ACI.cons_billing_number) AND NVL(p_bill_to, ACI.cons_billing_number)
                                                                -- Added for R1.2 Defect# 1210 CR# 466.
  ---- AND    ACI.status                   = 'ACCEPTED'
   AND    ACI.status                    IN ( 'ACCEPTED' ,'FINAL') ---Changed by Aradhna on 16-Jan-2014 for defect#27208
   AND    ACI.customer_id              = XCCAE.cust_account_id
   AND    XCCAE.attr_group_id          = p_attr_group_id
   AND    XCCAE.n_ext_attr1            = XCDM.document_id
   AND    XCCAE.c_ext_attr1            = 'Consolidated Bill'
   AND    (XCCAE.c_ext_attr3           = 'PRINT'   OR  P_SPEC_HANDLING_FLAG <> 'Y')
   AND    XCCAE.c_ext_attr2            ='Y'
   AND    XCDM.doc_detail_level        = NVL(P_DOC_DETAIL,XCDM.doc_detail_level)
   AND    (DECODE(P_SPEC_HANDLING_FLAG,'Y',ACI.attribute2,NULL) IS NULL
          AND DECODE(P_SPEC_HANDLING_FLAG,'Y',ACI.attribute4,NULL) IS NULL
          AND DECODE(P_SPEC_HANDLING_FLAG,'Y',ACI.attribute10,NULL) IS NULL
          AND DECODE(P_SPEC_HANDLING_FLAG,'Y',ACI.attribute15,NULL) IS NULL   --Added as part of R1.4 CR# 586
          )
   AND    DECODE(P_SPEC_HANDLING_FLAG,'Y',XCCAE.c_ext_attr4 ,1) IS NOT NULL
   -- The below condition is commented for Defect# 15063.
   /*AND    DECODE(P_SPEC_HANDLING_FLAG,'Y',XX_AR_INV_FREQ_PKG.compute_effective_date
          ( XCCAE.c_ext_attr14, TRUNC(ACI.cut_off_date-1)),'01-JAN-00') <= NVL(p_as_of_date1,'01-JAN-00')*/
   --Added for Defect# 15063. The logic of the attribute1 column is handled in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN
   AND    DECODE(P_SPEC_HANDLING_FLAG,'Y',XX_AR_INV_FREQ_PKG.compute_effective_date
          ( XCCAE.c_ext_attr14, TO_DATE(ACI.attribute1)-1),'01-JAN-00') <= NVL(p_as_of_date1,'01-JAN-00')
   AND    EXISTS
             (
               SELECT 1
               FROM   ar_cons_inv_trx_lines
               WHERE  cons_inv_id = ACI.cons_inv_id
             )
   AND    HZCA.cust_account_id         = ACI.customer_id
   AND    HZAS.cust_account_id         = ACI.customer_id
   AND    HZSU.cust_acct_site_id       = HZAS.cust_acct_site_id
   AND    HZSU.site_use_id             = ACI.site_use_id
   AND    HZPS.party_site_id           = HZAS.party_site_id
   AND    HZLO.location_id             = HZPS.location_id
   AND    TERM.term_id                 = ACI.term_id
   --ORDER BY ACI.cons_billing_number;  -- Commented for R1.2 Defect# 1210 CR# 466.
--End of Change for the Defect 13576, 13577 and 13578.
   -- Added for R1.2 Defect# 1210 CR# 466.
   AND    (P_VIRTUAL_BILL_FLAG         IS NULL OR P_VIRTUAL_BILL_FLAG = 'N')
   AND    (P_CUST_DOC_ID               IS NULL  OR (P_INFOCOPY_FLAG = 'N' AND P_CUST_DOC_ID IS NOT NULL))
   AND    (P_MULTIPLE_BILL             IS NULL
           OR ACI.cons_inv_id          IN (SELECT column_value
                                           FROM TABLE(CAST(xx_ar_reprint_summbill.lt_cons_bill AS xx_ar_reprint_cons_bill_t))
                                           )
          )
   AND    ((TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS'))                 IS NULL OR (TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS')) <= (TO_DATE(ACI.attribute1)-1))
   AND    ((TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))                   IS NULL OR (TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))   >= (TO_DATE(ACI.attribute1)-1))
   -- end of change for R1.2 Defect# 1210 CR# 466.
   -- Added the below conditions for R1.3 CR 738 Defect 2766
   AND    DECODE(P_SPEC_HANDLING_FLAG,'Y',P_AS_OF_DATE1,XCCAE.d_ext_attr1)                >= XCCAE.d_ext_attr1
   AND    (XCCAE.d_ext_attr2                                                              IS NULL
           OR
           DECODE(P_SPEC_HANDLING_FLAG,'Y',P_AS_OF_DATE1,XCCAE.d_ext_attr2)               <= XCCAE.d_ext_attr2)
-- End of changes for R1.3 CR 738 Defect 2766
   -- Added the below union query for R1.2 Defect# 1210 CR# 466 to get the data for INV_IC scenario both from certegy and Ebill.
   UNION
   SELECT    HL.province                      BILL_TO_PROVINCE
            ,XACBH.attribute9                 BILLING_ID
            ,XACBH.cons_inv_id                CBI_ID
            ,XACBH.attribute6                 CBI_NUMBER
            ,NULL                             CBI_AMOUNT_DUE
            ,NULL                             DOCUMENT_ID
            ,NULL                             SORT_ORDER
            ,NULL                             TOTAL_BY
            ,NULL                             PAGE_BREAK
            ,NULL                             TEMPLATE
            ,XACBH.attribute8                 DOC_TYPE
            ,DECODE( P_CUST_DOC_ID
                    ,NULL,RCT.bill_to_site_use_id
                    ,TO_NUMBER(XACBH.attribute7)
                    )                         SITE_USE_ID
            ,TO_NUMBER(XACBH.attribute16)     CBI_ID1
            ,'N'                              EBILL_IND   -- Added as part of R1.4 CR# 586
   FROM     xx_ar_cons_bills_history          XACBH
           ,xx_ar_cbi_trx_history             XACTH
           ,ra_customer_trx                   RCT
           ,hz_cust_acct_sites                HCAS
           ,hz_cust_site_uses                 HCSU
           ,hz_party_sites                    HPS
           ,hz_locations                      HL
   WHERE    XACBH.customer_id            = NVL(P_CUST_ACCOUNT_ID,XACBH.customer_id)
   AND      XACBH.cons_inv_id            = NVL(p_virtual_bill,XACBH.cons_inv_id)
   AND      XACBH.attribute6             = NVL(p_bill_from,XACBH.attribute6)
   AND      XACBH.attribute8             IN ('PAYDOC_IC','INV_IC')
   AND      XACTH.cons_inv_id            = XACBH.cons_inv_id
   AND      XACTH.attribute1             = XACBH.attribute8
   AND      XACBH.thread_id              = XACTH.request_id
   AND      XACTH.inv_type               NOT IN ('SOFTHDR_TOTALS' ,'BILLTO_TOTALS' ,'GRAND_TOTAL')
   AND      XACTH.customer_trx_id        = RCT.customer_trx_id
   AND      RCT.bill_to_site_use_id      = HCSU.site_use_id
   AND      HCSU.cust_acct_site_id       = HCAS.cust_acct_site_id
   AND      HPS.party_site_id            = HCAS.party_site_id
   AND      HL.location_id               = HPS.location_id
   AND      XACBH.paydoc                != 'Y'
   AND      NVL(XACBH.process_flag,'N')  = 'Y'
   AND      P_INFOCOPY_FLAG              = 'Y'
   AND      ((P_VIRTUAL_BILL_FLAG        = 'N'   AND XACBH.cust_doc_id          = P_CUST_DOC_ID)
             OR (P_VIRTUAL_BILL_FLAG     = 'Y'   AND XACBH.cust_doc_id          = NVL(P_CUST_DOC_ID,XACBH.cust_doc_id))
             )
   AND      (P_MULTIPLE_BILL             IS NULL
             OR XACBH.attribute16        IN (SELECT column_value
                                             FROM TABLE(CAST(xx_ar_reprint_summbill.lt_cons_bill AS xx_ar_reprint_cons_bill_t))
                                             )
            )
   AND      ((TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS'))                  IS NULL OR (TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS')) <= TRUNC(XACBH.bill_from_date))
   AND      ((TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))                    IS NULL OR (TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))   >= TRUNC(XACBH.bill_from_date))
   AND      (P_CUST_DOC_ID                IS NULL OR XACBH.attribute7  = NVL(p_site_use_id,XACBH.attribute7))
   UNION
   SELECT    HL.province                      BILL_TO_PROVINCE
            ,HCA.account_number               BILLING_ID
            ,XAGBLA.n_ext_attr2               CBI_ID
            ,XAGBLA.c_ext_attr2               CBI_NUMBER
            ,NULL                             CBI_AMOUNT_DUE
            ,NULL                             DOCUMENT_ID
            ,NULL                             SORT_ORDER
            ,NULL                             TOTAL_BY
            ,NULL                             PAGE_BREAK
            ,NULL                             TEMPLATE
            ,XAGBLA.c_ext_attr1               DOC_TYPE
            ,DECODE( P_CUST_DOC_ID
                    ,NULL,RCT.bill_to_site_use_id
                    ,XAGBLA.billing_site_id
                    )                         SITE_USE_ID
            ,XAGBLA.n_ext_attr2               CBI_ID1
            ,'N'                              EBILL_IND -- Added as part of R1.4 CR# 586
   FROM      xx_ar_gen_bill_lines_all         XAGBLA
            ,ra_customer_trx                  RCT
            ,hz_cust_accounts                 HCA
            ,hz_cust_acct_sites               HCAS
            ,hz_cust_site_uses                HCSU
            ,hz_party_sites                   HPS
            ,hz_locations                     HL
   WHERE    XAGBLA.customer_id              = NVL(P_CUST_ACCOUNT_ID,XAGBLA.customer_id)
   AND      XAGBLA.n_ext_attr2              = NVL(p_virtual_bill,XAGBLA.n_ext_attr2)
   AND      XAGBLA.c_ext_attr2              = NVL(p_bill_from,XAGBLA.c_ext_attr2)
   AND      RCT.customer_trx_id             = XAGBLA.customer_trx_id
   AND      HCA.cust_account_id             = XAGBLA.customer_id
   AND      HCAS.cust_account_id            = XAGBLA.customer_id
   AND      RCT.bill_to_site_use_id         = HCSU.site_use_id
   AND      HCSU.cust_acct_site_id          = HCAS.cust_acct_site_id
   AND      HPS.party_site_id               = HCAS.party_site_id
   AND      HL.location_id                  = HPS.location_id
   AND      XAGBLA.c_ext_attr1              IN ('PAYDOC_IC','INV_IC')
   AND      NVL(XAGBLA.processed_flag,'N')  = 'Y'
   AND      P_INFOCOPY_FLAG                 = 'Y'
   AND      ((P_VIRTUAL_BILL_FLAG           = 'N'   AND XAGBLA.n_ext_attr1          = P_CUST_DOC_ID)
             OR (P_VIRTUAL_BILL_FLAG        = 'Y'   AND XAGBLA.n_ext_attr1          = NVL(P_CUST_DOC_ID,XAGBLA.n_ext_attr1))
             )
   AND      (P_MULTIPLE_BILL                IS NULL
             OR XAGBLA.n_ext_attr2          IN (SELECT column_value
                                                FROM TABLE(CAST(xx_ar_reprint_summbill.lt_cons_bill AS xx_ar_reprint_cons_bill_t))
                                                )
            )
   AND      ((TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS'))                  IS NULL OR (TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS')) <= TRUNC(XAGBLA.issue_date))
   AND      ((TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))                    IS NULL OR (TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'))   >= TRUNC(XAGBLA.issue_date))
   AND      (P_CUST_DOC_ID                IS NULL OR XAGBLA.billing_site_id = NVL(p_site_use_id,XAGBLA.billing_site_id))
   -- Added the below UNION query to get the Infocopies of consolidated bill through EBill delivery methods as part of R1.4 CR# 586
   UNION
   SELECT   XAECHH.bill_to_state                      BILL_TO_PROVINCE
           ,XAECHH.oracle_account_number              BILLING_ID
           ,XAECHH.cons_inv_id                        CBI_ID
           ,XAECHH.consolidated_bill_number           CBI_NUMBER
           ,NULL                                      CBI_AMOUNT_DUE
           ,NULL                                      DOCUMENT_ID
           ,NULL                                      SORT_ORDER
           ,NULL                                      TOTAL_BY
           ,NULL                                      PAGE_BREAK
           ,NULL                                      TEMPLATE
           ,XAECHH.infocopy_tag                       DOC_TYPE
           ,DECODE( P_CUST_DOC_ID
                   ,NULL,RCT.bill_to_site_use_id
                   ,XAECHH.bill_to_site_use_id
                   )                                 SITE_USE_ID
           ,XAECHH.cons_inv_id                       CBI_ID1
           ,'Y'                                      EBILL_IND
   FROM     xx_ar_ebl_cons_hdr_hist     XAECHH
           ,ra_customer_trx_all         RCT
   WHERE    RCT.customer_trx_id                           = XAECHH.customer_trx_id
   AND      XAECHH.cust_account_id                        = NVL(P_CUST_ACCOUNT_ID,XAECHH.cust_account_id)
   AND      XAECHH.cons_inv_id                            = NVL(p_virtual_bill,XAECHH.cons_inv_id)
   AND      XAECHH.consolidated_bill_number               = NVL(p_bill_from,XAECHH.consolidated_bill_number)
   AND      XAECHH.infocopy_tag                           IN ('PAYDOC_IC','INV_IC')
   AND      P_INFOCOPY_FLAG                               = 'Y'
   AND      ((P_VIRTUAL_BILL_FLAG                         = 'N'   AND XAECHH.cust_doc_id          = P_CUST_DOC_ID)
             OR (P_VIRTUAL_BILL_FLAG                      = 'Y'   AND XAECHH.cust_doc_id          = NVL(P_CUST_DOC_ID,XAECHH.cust_doc_id))
             )
   AND      (P_MULTIPLE_BILL                              IS NULL
             OR XAECHH.cons_inv_id                        IN (SELECT column_value
                                                          FROM TABLE(CAST(xx_ar_reprint_summbill.lt_cons_bill AS xx_ar_reprint_cons_bill_t))
                                                          )
            )
   AND      (P_CUST_DOC_ID                               IS NULL OR XAECHH.bill_to_site_use_id = NVL(p_site_use_id,XAECHH.bill_to_site_use_id))
   AND       XAECHH.bill_from_date                       >= NVL(TO_DATE(P_DATE_FROM,'DD/MM/YYYY HH24:MI:SS'),XAECHH.bill_from_date)
   AND       XAECHH.bill_to_date                         <= NVL(TO_DATE(P_DATE_TO,'DD/MM/YYYY HH24:MI:SS'),XAECHH.bill_to_date)
   -- End of changes for R1.4 CR# 586.
   ORDER BY cbi_number;
   -- End for R1.2 Defect# 1210 CR# 466.

CURSOR get_softheader_totals(cbi_id IN NUMBER ,trx_id IN NUMBER ) IS
SELECT sumz.insert_seq
      ,'TOTAL FOR '||sumz.inv_source_name             summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                         total_orders
      ,NVL(sumz.tax_code ,'N')                         pg_break
      ,sumz.subtotal_amount  summarize_subtotal
      ,sumz.delivery_charges summarize_delivery
      ,sumz.promo_and_disc   summarize_discounts
      ,sumz.tax_amount       summarize_tax
      ,( sumz.subtotal_amount +
         sumz.delivery_charges +
         sumz.promo_and_disc +
         sumz.tax_amount
       )                    summarize_total
	 --  ,b.trx_id-- Commented for defect 31838 Perf
 ,sumz.customer_trx_id-- Added for defect 31838
FROM  xx_ar_cbi_rprn_trx sumz
/*, -- Commented for defect 31838 Perf
      (select to_number(attribute3) trx_id
	   from xx_ar_cbi_rprn_rows b
	   where request_id  = P_REQUEST_ID
	     and cons_inv_id = cbi_id
	  )b -- Added for defect 31838
*/ -- Commented for defect 31838 Perf
WHERE sumz.request_id      =P_REQUEST_ID
  AND sumz.cons_inv_id     =cbi_id
--  AND sumz.customer_trx_id = b.trx_id -- Commented for 31838 Perf
--  AND attribute1      ='PAYDOC'
  AND sumz.inv_type ='SOFTHDR_TOTALS'
UNION ALL
SELECT sumz.insert_seq
      ,'TOTAL FOR '||sumz.inv_source_name  summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                         total_orders
      ,NVL(sumz.tax_code ,'N')                         pg_break
      ,sumz.subtotal_amount  summarize_subtotal
      ,sumz.delivery_charges summarize_delivery
      ,sumz.promo_and_disc   summarize_discounts
      ,sumz.tax_amount       summarize_tax
      ,( sumz.subtotal_amount +
         sumz.delivery_charges +
         sumz.promo_and_disc +
         sumz.tax_amount
       )                    summarize_total
	 --  ,b.trx_id-- Commented for defect 31838 Perf
 ,sumz.customer_trx_id-- Added for defect 31838
FROM  xx_ar_cbi_rprn_trx sumz
/*, -- Commented for defect 31838 Perf
      (select to_number(attribute3) trx_id
	   from xx_ar_cbi_rprn_rows b
	   where request_id  = P_REQUEST_ID
	     and cons_inv_id = cbi_id
	  )b -- Added for defect 31838
*/ -- Commented for defect 31838 Perf
WHERE sumz.request_id      =P_REQUEST_ID
  AND sumz.cons_inv_id     =cbi_id
 -- AND sumz.customer_trx_id =b.trx_id -- Commented for defect 31838 Perf
--  AND attribute1      ='PAYDOC'
  AND sumz.inv_type ='BILLTO_TOTALS'
UNION ALL
SELECT sumz.insert_seq                                  insert_seq
      ,'GRAND TOTAL :'                                  summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                          total_orders
      ,NVL(sumz.tax_code ,'N')                          pg_break
      ,TO_NUMBER(NULL)                                  summarize_subtotal
      ,TO_NUMBER(NULL)                                  summarize_delivery
      ,TO_NUMBER(NULL)                                  summarize_discounts
      ,TO_NUMBER(NULL)                                  summarize_tax
      ,sumz.subtotal_amount                             summarize_total
	 --  ,b.trx_id-- Commented for defect 31838 Perf
 ,sumz.customer_trx_id-- Added for defect 31838
FROM  xx_ar_cbi_rprn_trx sumz
/*, -- Commented for defect 31838 Perf
      (select to_number(attribute3) trx_id
	   from xx_ar_cbi_rprn_rows b
	   where request_id  = P_REQUEST_ID
	     and cons_inv_id = cbi_id
	  )b -- Added for defect 31838
*/ -- Commented for defect 31838 Perf
WHERE sumz.request_id      =P_REQUEST_ID
  AND sumz.cons_inv_id     =cbi_id
 -- AND sumz.customer_trx_id =b.trx_id -- Commented for defect 31838 Perf
--  AND attribute1      ='PAYDOC'
  AND sumz.inv_type ='GRAND_TOTAL'
ORDER BY insert_seq;

CURSOR get_softheader_ONE_totals (cbi_id IN NUMBER) IS
SELECT sumz.insert_seq
      ,'TOTAL FOR '||sumz.inv_source_name             summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                         total_orders
      ,NVL(sumz.tax_code ,'N')                         pg_break
      ,sumz.subtotal_amount  summarize_subtotal
      ,sumz.delivery_charges summarize_delivery
      ,sumz.promo_and_disc   summarize_discounts
      ,sumz.tax_amount       summarize_tax
      ,( sumz.subtotal_amount +
         sumz.delivery_charges +
         sumz.promo_and_disc +
         sumz.tax_amount
       )                    summarize_total
FROM  xx_ar_cbi_rprn_trx sumz
WHERE request_id      =P_REQUEST_ID
  AND cons_inv_id     =cbi_id
  AND inv_type ='SOFTHDR_TOTALS'
UNION ALL
SELECT sumz.insert_seq
      ,'TOTAL FOR '||sumz.inv_source_name     summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                         total_orders
      ,NVL(sumz.tax_code ,'N')                         pg_break
      ,sumz.subtotal_amount  summarize_subtotal
      ,sumz.delivery_charges summarize_delivery
      ,sumz.promo_and_disc   summarize_discounts
      ,sumz.tax_amount       summarize_tax
      ,( sumz.subtotal_amount +
         sumz.delivery_charges +
         sumz.promo_and_disc +
         sumz.tax_amount
       )                    summarize_total
FROM  xx_ar_cbi_rprn_trx sumz
WHERE request_id      =P_REQUEST_ID
  AND cons_inv_id     =cbi_id
  AND inv_type ='BILLTO_TOTALS'
UNION ALL
SELECT sumz.insert_seq                                  insert_seq
      ,'GRAND TOTAL:'                                   summarize_text
      ,DECODE( sumz.order_header_id
              ,1
              ,TO_CHAR(sumz.order_header_id)||' ORDER'
              ,TO_CHAR(sumz.order_header_id)||' ORDERS'
             )                                          total_orders
      ,NVL(sumz.tax_code ,'N')                          pg_break
      ,TO_NUMBER(NULL)                                  summarize_subtotal
      ,TO_NUMBER(NULL)                                  summarize_delivery
      ,TO_NUMBER(NULL)                                  summarize_discounts
      ,TO_NUMBER(NULL)                                  summarize_tax
      ,sumz.subtotal_amount                             summarize_total
FROM  xx_ar_cbi_rprn_trx sumz
WHERE request_id      =P_REQUEST_ID
  AND cons_inv_id     =cbi_id
  AND inv_type ='GRAND_TOTAL'
ORDER BY insert_seq;

-- ===================================
-- Local variables.
-- ===================================
lc_sort_by     VARCHAR2(12);
lc_total_by    VARCHAR2(12);
lc_page_by     VARCHAR2(12);
lc_template    VARCHAR2(20);
lb_insert_once BOOLEAN :=TRUE;
lc_line_type   VARCHAR2(20);
lc_error_location VARCHAR2(2000);  -- added for defect 11993
lc_debug          VARCHAR2(1000);  -- added for defect 11993
ln_attr_group_id  NUMBER;

-- Added for R1.2 Defect# 1210 CR# 466.
lc_err_buff              VARCHAR2(4000);
ln_err_code              NUMBER;
ln_site_use_id           hz_cust_site_uses.site_use_id%type;
ln_virtual_bill          NUMBER;
ln_position              NUMBER;
lc_cons_bill             ar_cons_inv.cons_billing_number%type;
lc_cons_bill_to          ar_cons_inv.cons_billing_number%type;
ln_count                 NUMBER := 1;
ln_prev_site_use_id      hz_cust_site_uses.site_use_id%type;
ln_cons_inv_id           NUMBER;
ln_cbi_id                NUMBER;
-- End of change for R1.2 Defect# 1210 CR# 466.

ln_prev_cons_inv_id      NUMBER;  -- Added as part of R1.4 CR# 586.

/*
  Main -BeforeReport Trigger....
*/
BEGIN
 -- =============================
 -- get template details
 -- =============================
  fnd_file.put_line(fnd_file.log ,'Customer Account id: '||P_CUST_ACCOUNT_ID);
  fnd_file.put_line(fnd_file.log ,'MBS document id'||P_MBS_DOCUMENT_ID);
  fnd_file.put_line(fnd_file.log ,'Request ID:' ||P_REQUEST_ID);
  fnd_file.put_line(fnd_file.log ,'Customer Doc Detail Level: ' ||P_DOC_DETAIL);   --Added for Defect # 12223
  fnd_file.put_line(fnd_file.log ,'As of Date:' ||P_AS_OF_DATE1);                  --Added for Defect # 12223
  fnd_file.put_line(fnd_file.log ,'Global Conc Request ID : '||FND_GLOBAL.CONC_REQUEST_ID);  -- by samba
    SELECT attr_group_id
    INTO   ln_attr_group_id
    FROM   ego_attr_groups_v
    WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
    AND    attr_group_name = 'BILLDOCS' ;

IF P_SPEC_HANDLING_FLAG <>'Y' THEN
-- Uncommenting the below block  ranjith
-- Commented for Defect # 12223
/* */ fnd_file.put_line(fnd_file.log ,'Enter reprint fetch template details, Block-1');
lc_error_location := 'Enter reprint fetch template details, Block-1';
lc_debug := 'Document ID '|| p_mbs_document_id;
 BEGIN
  SELECT
         mbs_doc_master.doc_sort_order sort_order
        ,substr(mbs_doc_master.doc_sort_order ,1 ,instr(mbs_doc_master.doc_sort_order ,mbs_doc_master.total_through_field_id))||'1' total_by
        ,substr(mbs_doc_master.doc_sort_order ,1 ,instr(mbs_doc_master.doc_sort_order ,mbs_doc_master.page_break_through_id))||'1' page_break
        ,TRIM(mbs_doc_master.doc_detail_level)
  INTO  lc_sort_by
       ,lc_total_by
       ,lc_page_by
       ,lc_template
  FROM   xx_cdh_mbs_document_master mbs_doc_master
  WHERE document_id =p_mbs_document_id;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20000, 'Error in fetching template, sort ,total and page break details');
  WHEN OTHERS THEN
   RAISE_APPLICATION_ERROR(-20000, 'Error in fetching template, sort ,total and page break details');
 END;
  fnd_file.put_line(fnd_file.log ,'Exit reprint fetch template details, Block-1');

  fnd_file.put_line(fnd_file.log ,'Enter Reprint Pay Doc Block-2');
/**/
END IF;

-- Added the below IF conditions for R1.2 Defect# 1210 CR# 466.
 IF P_MULTIPLE_BILL IS NOT NULL THEN
    GET_IND_BILL_NUM( lc_err_buff
                     ,ln_err_code
                     ,P_MULTIPLE_BILL
                     ,P_VIRTUAL_BILL_FLAG
                    );
 END IF;

 IF P_VIRTUAL_BILL_FLAG = 'Y' THEN

    ln_position      := INSTR(P_VIRTUAL_BILL_NUM,'-');
    ln_virtual_bill  := SUBSTR(P_VIRTUAL_BILL_NUM,1,ln_position-1);
    ln_site_use_id   := SUBSTR(P_VIRTUAL_BILL_NUM,ln_position+1);

 ELSIF P_VIRTUAL_BILL_FLAG = 'N' THEN
    ln_position      := INSTR(P_SUMM_BILL_NUM,'-');
    lc_cons_bill     := SUBSTR(P_SUMM_BILL_NUM,1,ln_position-1);
    lc_cons_bill_to  := lc_cons_bill;
    ln_site_use_id   := SUBSTR(P_SUMM_BILL_NUM,ln_position+1);

 ELSE

    lc_cons_bill    := P_SUMM_BILL_NUM;
    lc_cons_bill_to := P_SUMM_BILL_NUM_TO;

 END IF;

 fnd_file.put_line(fnd_file.log ,'Cons Bill From :'||lc_cons_bill);
 fnd_file.put_line(fnd_file.log ,'Cons Bill To :'||lc_cons_bill_to);
 fnd_file.put_line(fnd_file.log ,'Virtual Bill To :'||ln_virtual_bill);

 ln_count := 0;
 -- End of changes for R1.2 Defect# 1210 CR# 466.
  BEGIN
    FOR rec IN g_pay_cust ( ln_attr_group_id
                           ,lc_cons_bill     -- Added for R1.2 Defect# 1210 CR# 466.
                           ,lc_cons_bill_to  -- Added for R1.2 Defect# 1210 CR# 466.
                           ,ln_virtual_bill  -- Added for R1.2 Defect# 1210 CR# 466.
                           ,ln_site_use_id   -- Added for R1.2 Defect# 1210 CR# 466.
                           )
     LOOP
      fnd_file.put_line(fnd_file.log ,'CBI ID:'||   rec.cbi_id);

      -- added for defect 11993

        IF P_SPEC_HANDLING_FLAG ='Y' THEN
        lc_sort_by  := rec.sort_order;
        lc_total_by := rec.total_by;
        lc_page_by  := rec.page_break;
        lc_template := rec.template;
        END IF;

        -- Added the below logic for R1.2 Defect# 1210 CR# 466.
        lc_error_location := 'To get the Virtual Bills appended with sequence number in order to to get the direct and indirect individual transactions';
        lc_debug := '';

        IF (rec.doc_type = 'INV_IC' AND P_CUST_DOC_ID IS NULL) OR (rec.doc_type = 'PAYDOC_IC' AND rec.ebill_ind = 'Y') THEN -- Added the OR condition as part of CR# 486.

           IF ln_count = 0 THEN
              ln_prev_site_use_id := rec.site_use_id;
              ln_prev_cons_inv_id := rec.cbi_id;         -- Added as part of R1.4 CR# 586.
              ln_count            := 1;
           END IF;

           IF (ln_prev_site_use_id = rec.site_use_id) AND (ln_prev_cons_inv_id = rec.cbi_id) THEN -- Added the AND condition as part of R1.4 CR# 586.

              ln_cons_inv_id := rec.cbi_id||ln_count;

           ELSE
/* -- Commented as part of R1.4 CR# 586.
                 ln_count            := 1;
                 ln_prev_site_use_id := rec.site_use_id;
                 ln_cons_inv_id      := rec.cbi_id||ln_count;
*/
              -- Added the below IF condition as part of R1.4 CR# 586.
              IF (ln_prev_cons_inv_id = rec.cbi_id) THEN

                 ln_prev_site_use_id := rec.site_use_id;
                 ln_prev_cons_inv_id := rec.cbi_id;
                 ln_cons_inv_id      := rec.cbi_id||ln_count;

              ELSE

                 ln_count            := 1;
                 ln_prev_site_use_id := rec.site_use_id;
                 ln_prev_cons_inv_id := rec.cbi_id;
                 ln_cons_inv_id      := rec.cbi_id||ln_count;

              END IF;

              -- End of changes for R1.4 CR# 586.

           END IF;

           ln_count  := ln_count + 1;
           ln_cbi_id := ln_cons_inv_id;

        ELSE

           ln_cons_inv_id := rec.cbi_id1;
           ln_cbi_id      := rec.cbi_id;

        END IF;

        -- End of changes for R1.2 Defect# 1210 CR# 466.
     -- ===========================================================
     -- Call to the routine xx_ar_cbi_calc_subtotals.get_invoices
     -- will insert all invoices for the corresponding consolidated
     -- bill with the customer specific sort applied.
     -- ===========================================================
      lc_error_location := 'Call to the routine xx_ar_cbi_calc_subtotals.get_invoices';
      lc_debug := '';

       xx_ar_cbi_rprn_subtotals.get_invoices
         (
       P_REQUEST_ID
      ,rec.cbi_id
      ,rec.cbi_amount_due
      ,rec.bill_to_province
-- Commented for Defect # 12223
/*    ,lc_sort_by
      ,lc_total_by
      ,lc_page_by
      ,lc_template */
-- added for defect 11993
       ,lc_sort_by
       ,lc_total_by
       ,lc_page_by
       ,lc_template
-- Start for Defect # 12223
/*  commented by ranjith
   ,rec.sort_order
      ,rec.total_by
      ,rec.page_break
      ,rec.template
-- End for Defect # 12223
      */
      --,'PAYDOC'          -- Commented for R1.2 Defect# 1210 CR# 466.
      ,rec.doc_type        -- Added for R1.2 Defect# 1210 CR# 466.
      ,rec.cbi_number
      ,rec.site_use_id       -- Added for R1.2 Defect# 1210 CR# 466. This is used to get the bill to address and bill from date for reprint.
      ,P_VIRTUAL_BILL_FLAG   -- Added for R1.2 Defect# 1210 CR# 466.
      ,P_CUST_DOC_ID         -- Added for R1.2 Defect# 1210 CR# 466.
      ,ln_cons_inv_id        -- Added for R1.2 Defect# 1210 CR# 466.
      ,rec.ebill_ind         -- Added for R1.4 CR# 586.
     );

              -- ===========================================
              -- Generate sub totals for DETAIL Template
              -- ===========================================
       lc_error_location := 'Generate sub totals for DETAIL Template';
       lc_debug := '';
     BEGIN
          IF lc_template ='DETAIL' THEN
            IF lc_total_by <>'B1' THEN
           xx_ar_cbi_rprn_subtotals.generate_DETAIL_subtotals
           (
             (LENGTH(REPLACE(lc_total_by, 'B1' ,''))/2)  -- pn_number_of_soft_headers IN NUMBER
            ,rec.billing_id                              -- p_billing_id              IN VARCHAR2
            --,rec.cbi_id                                  -- p_cons_id                 IN NUMBER  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
            ,P_REQUEST_ID                                -- p_reqs_id                 IN NUMBER
            ,lc_total_by                                 -- p_total_by                IN VARCHAR2
            ,lc_page_by                                  -- p_page_by                 IN VARCHAR2
            --,'PAYDOC'                                  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,rec.doc_type                                -- Added for R1.2 Defect# 1210 CR# 466.
            ,rec.bill_to_province
           );
            ELSE
           xx_ar_cbi_rprn_subtotals.generate_DETAIL_subtotals
           (
             (LENGTH(lc_total_by)/2)                     -- pn_number_of_soft_headers IN NUMBER
            ,rec.billing_id                              -- p_billing_id              IN VARCHAR2
            --,rec.cbi_id                                  -- p_cons_id                 IN NUMBER  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
            ,P_REQUEST_ID                                -- p_reqs_id                 IN NUMBER
            ,lc_total_by                                 -- p_total_by                IN VARCHAR2
            ,lc_page_by                                  -- p_page_by                 IN VARCHAR2
            --,'PAYDOC'                                  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,rec.doc_type                                -- Added for R1.2 Defect# 1210 CR# 466.
            ,rec.bill_to_province
           );
            END IF;
          ELSE
              -- =================================================
              -- Generate sub totals for SUMMARIZE and ONE
              -- templates. The buckets are a little different
              -- from the DETAIL procedure. So we modified
              -- and made appropriate changes to it.
              -- =================================================
         lc_error_location := 'Generate sub totals for SUMMARIZE and ONE Templates';
         lc_debug := '';


            IF lc_total_by <>'B1' THEN
           xx_ar_cbi_rprn_subtotals.generate_SUMM_ONE_subtotals
           (
             (LENGTH(REPLACE(lc_total_by, 'B1' ,''))/2)  -- pn_number_of_soft_headers IN NUMBER
            ,rec.billing_id                              -- p_billing_id              IN VARCHAR2
            --,rec.cbi_id                                  -- p_cons_id                 IN NUMBER  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
            ,P_REQUEST_ID                                -- p_reqs_id                 IN NUMBER
            ,lc_total_by                                 -- p_total_by                IN VARCHAR2
            ,lc_page_by                                  -- p_page_by                 IN VARCHAR2
            --,'PAYDOC'                                  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,rec.doc_type                                -- Added for for R1.2 Defect# 1210 CR# 466.
            ,rec.bill_to_province
           );
            ELSE
           xx_ar_cbi_rprn_subtotals.generate_SUMM_ONE_subtotals
           (
             (LENGTH(lc_total_by)/2)                     -- pn_number_of_soft_headers IN NUMBER
            ,rec.billing_id                              -- p_billing_id              IN VARCHAR2
            --,rec.cbi_id                                  -- p_cons_id                 IN NUMBER  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
            ,P_REQUEST_ID                                -- p_reqs_id                 IN NUMBER
            ,lc_total_by                                 -- p_total_by                IN VARCHAR2
            ,lc_page_by                                  -- p_page_by                 IN VARCHAR2
            --,'PAYDOC'                                  -- Commented for R1.2 Defect# 1210 CR# 466.
            ,rec.doc_type                                -- Added for R1.2 Defect# 1210 CR# 466.
            ,rec.bill_to_province
           );
            END IF;
          END IF;
     EXCEPTION
      WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.log ,lc_template||' ,BeforeReport Reprint Paydoc subtotals:' || SUBSTR (SQLERRM, 1, 2000));
     END;
     -- =========================================================================================
     -- Insert rows into xx_ar_cbi_rprn_rows for each invoice , spc info ,tiered discount and
     -- soft headers /bill to level totals if any and grand total.
     -- We will use these inserted rows and print them as single record with in the templates
     -- SUMMARIZE and ONE.
     -- =========================================================================================

  IF lc_template ='SUMMARIZE' THEN
          FOR inv_rec IN
                   (SELECT
                    customer_trx_id trx_id
                   ,inv_number      invoice_num
                   ,TO_CHAR(order_date ,'DD-MON-YY') order_date
                   ,sfdata1
                   ,sfdata2
                   ,sfdata3
                   ,sfdata4
                   ,sfdata5
                   ,NVL(subtotal_amount ,0)      subtotal
                   ,NVL(delivery_charges ,0)     delivery
                   ,NVL(promo_and_disc ,0)  discounts
                   ,NVL(tax_amount ,0)           tax
                   ,(NVL(subtotal_amount ,0) +
                                     NVL(delivery_charges ,0) +
                                     NVL(promo_and_disc ,0) +
                                     NVL(tax_amount ,0)
                         )                            order_total
                   ,insert_seq
                   FROM  xx_ar_cbi_rprn_trx
                   WHERE 1 =1
                     AND xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID')
                     AND request_id  =P_REQUEST_ID
                     --AND cons_inv_id =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
                     AND cons_inv_id = ln_cbi_id   -- Added for R1.2 Defect# 1210 CR# 466.
                     --AND attribute1  ='PAYDOC'    -- Commented for R1.2 Defect# 1210 CR# 466.
                     AND attribute1 = rec.doc_type  -- Added for R1.2 Defect# 1210 CR# 466.
                     AND inv_type NOT IN ('SOFTHDR_TOTALS' ,'BILLTO_TOTALS' ,'GRAND_TOTAL')
                   UNION
                   SELECT
                       customer_trx_id trx_id
                      ,inv_number      invoice_num
                      ,TO_CHAR(order_date ,'DD-MON-YY') order_date
                      ,sfdata1
                      ,sfdata2
                      ,sfdata3
                      ,sfdata4
                      ,sfdata5
                      ,NVL(subtotal_amount ,0)      subtotal
                      ,NVL(delivery_charges ,0)     delivery
                      ,NVL(promo_and_disc ,0)  discounts
                      ,(NVL(cad_county_tax_amount ,0) +
                       NVL(cad_state_tax_amount, 0) )  tax
                      ,(NVL(subtotal_amount ,0) +
                                        NVL(delivery_charges ,0) +
                                        NVL(promo_and_disc ,0)   +
                                        NVL(cad_county_tax_amount ,0) +
                                        NVL(cad_state_tax_amount, 0)
                            )                            order_total
                      ,insert_seq
                      FROM  xx_ar_cbi_rprn_trx
                      WHERE 1 =1
                        AND  xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID')
                        AND request_id  =P_REQUEST_ID
                        --AND cons_inv_id =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
                     AND cons_inv_id = ln_cbi_id   -- Added for R1.2 Defect# 1210 CR# 466.
                        --AND attribute1  ='PAYDOC'     -- Commented for R1.2 Defect# 1210 CR# 466.
                        AND attribute1 = rec.doc_type   -- Added for R1.2 Defect# 1210 CR# 466.
                     AND inv_type NOT IN ('SOFTHDR_TOTALS' ,'BILLTO_TOTALS' ,'GRAND_TOTAL')
                 ORDER BY insert_seq)
          LOOP
         lc_error_location := 'Insert rows into xx_ar_cbi_rprn_rows';
         lc_debug := '';

            --xx_ar_cbi_rprn_subtotals.insert_rprn_rows Commented for 31838
			--Added for defect 31838
			insert_rprn_rows_tbl
             (
               P_REQUEST_ID
              --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
              ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
              ,'TRX_REC'
              ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
              ,NULL
              ,'N'                                                                   --Page break.
              ,RPAD(inv_rec.invoice_num ,15 ,' ')       --attribute1
              ,RPAD(inv_rec.order_date ,9 ,' ')                          --attribute2
              ,inv_rec.subtotal
              ,inv_rec.delivery
              ,inv_rec.discounts
              ,inv_rec.tax
              ,inv_rec.order_total
              ,inv_rec.sfdata1
              ,inv_rec.sfdata2
              ,inv_rec.sfdata3
              ,inv_rec.sfdata4
              ,inv_rec.sfdata5
              ,inv_rec.trx_id
              );
              --,RPAD(TRIM(TO_CHAR(inv_rec.subtotal ,'9G990D99PR')) ,10 ,' ')
              --,RPAD(TRIM(TO_CHAR(inv_rec.delivery ,'990D99PR')) ,8 ,' ')
              --,RPAD(TRIM(TO_CHAR(inv_rec.discounts ,'990D99PR')) ,8 ,' ')
              --,RPAD(TRIM(TO_CHAR(inv_rec.tax ,'990D99PR')) ,8 ,' ')
              --,RPAD(TRIM(TO_CHAR(inv_rec.order_total ,'99G990D99PR')) ,11 ,' ')
              --);

             --fnd_file.put_line(fnd_file.log 'STEP 3 --Insert SPC row...');
         /* Commented for 31838
		 lc_error_location := 'Insert SPC CARD info';
         lc_debug := '';
                 FOR spc_rec IN (SELECT item_description spc_card_details
                     FROM   xx_ar_cbi_rprn_trx_lines a
                     WHERE a.request_id      =P_REQUEST_ID
                       --AND a.cons_inv_id     =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
                       AND a.cons_inv_id     = ln_cbi_id    -- Added for R1.2 Defect# 1210 CR# 466.
                       AND a.customer_trx_id =inv_rec.trx_id
                       AND a.item_code       ='SPC_CARD_INFO')

                 LOOP
                    --xx_ar_cbi_rprn_subtotals.insert_rprn_rows
					insert_rprn_rows_tbl
                     (
                       P_REQUEST_ID
                      --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
                      ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
                      ,'SPC_REC'
                      ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
                      , RPAD(' ' ,8 ,' ')
                      ||RPAD('Note: ' ,6 ,' ')
                      ||spc_rec.spc_card_details
                      ||RPAD(' ' ,8 ,' ')
                     ,'N' -- page break not required for spc card info record.
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,inv_rec.trx_id
                     );
                 END LOOP;
         lc_error_location := 'Insert TD info';
         lc_debug := '';
             --fnd_file.put_line(fnd_file.log 'STEP 4 --Insert Tiered Discount row...');

                 FOR td_rec IN (SELECT extended_price td_value
                     FROM   xx_ar_cbi_rprn_trx_lines a
                     WHERE a.request_id      =P_REQUEST_ID
                       --AND a.cons_inv_id     =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
                       AND a.cons_inv_id     = ln_cbi_id    -- Added for R1.2 Defect# 1210 CR# 466.
                       AND a.customer_trx_id =inv_rec.trx_id
                       AND a.item_code       ='TD')

                 LOOP
                    --xx_ar_cbi_rprn_subtotals.insert_rprn_rows
					insert_rprn_rows_tbl
                     (
                       P_REQUEST_ID
                      --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
                      ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
                      ,'TD_REC'
                      ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
                      ,RPAD(' ' ,8 ,' ')
                       ||'Note: A Tiered discount of '
--                       ||RPAD(NVL(TO_CHAR(td_rec.td_value ,'9G999D99PR') ,' ') ,11 ,' ')   -- Commented for R1.2 Defect 1143 (CR 621)
                       ||RPAD(NVL(TO_CHAR(td_rec.td_value ,'9G999D99') ,' ') ,11 ,' ')     -- Added for R1.2 Defect 1143 (CR 621)
                       ||' has been applied to your order.'
                       ||RPAD(' ' ,8 ,' ')
                     ,'N' -- page break not required for tiered discount info record.
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,NULL
                     ,inv_rec.trx_id
                     );
                 END LOOP;
             --fnd_file.put_line(fnd_file.log 'STEP 5 --Insert Sub total records...');

         lc_error_location := 'Insert Sub total records';
         lc_debug := '';
                 FOR subtotal_records IN get_softheader_totals(ln_cbi_id,inv_rec.trx_id) -- Commented rec.cbi_id and added ln_cbi_id for R1.2 Defect# 1210 CR# 466.
                  LOOP
                      IF TRIM(subtotal_records.summarize_text) LIKE 'GRAND TOTAL%' THEN
                        lc_line_type :='GRAND_TOTAL';
                      ELSIF TRIM(subtotal_records.summarize_text) LIKE 'TOTAL FOR BILL%' THEN
                        lc_line_type :='BILL_TO_TOTAL';
                      ELSE
                        lc_line_type :='SOFTHDR_TOTAL';
                      END IF;
                    --xx_ar_cbi_rprn_subtotals.insert_rprn_rows
					insert_rprn_rows_tbl
                     (
                       P_REQUEST_ID
                       --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
                      ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
                      ,lc_line_type
                      ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
                      ,subtotal_records.summarize_text                  --sf text
                      ,subtotal_records.pg_break                        --page break may exist
                      ,RPAD(subtotal_records.total_orders ,27 ,' ')     --attribute1
                      ,NULL                                             --attribute2
                      ,NVL(subtotal_records.summarize_subtotal ,0)
                      ,NVL(subtotal_records.summarize_delivery ,0)
                      ,NVL(subtotal_records.summarize_discounts ,0)
                      ,NVL(subtotal_records.summarize_tax ,0)
                      ,NVL(subtotal_records.summarize_total ,0)
                      ,NULL
                      ,NULL
                      ,NULL
                      ,NULL
                      ,NULL
                      ,inv_rec.trx_id
                     );
                      --,RPAD(NVL(TO_CHAR(subtotal_records.summarize_subtotal ,'9G990D99PR') ,' ') ,11 ,' ')
                      --,RPAD(NVL(TO_CHAR(subtotal_records.summarize_delivery ,'9990D99PR') ,' ') ,9 ,' ')
                      --,RPAD(NVL(TO_CHAR(subtotal_records.summarize_discounts ,'990D99PR') ,' ') ,9 ,' ')
                      --,RPAD(NVL(TO_CHAR(subtotal_records.summarize_tax ,'990D99PR') ,' ') ,9 ,' ')
                      --,RPAD(NVL(TO_CHAR(subtotal_records.summarize_total ,'990D99PR') ,' ') ,12 ,' ')
                      --);

                  END LOOP;
			*/
          END LOOP; --STEP 2 --Insert Invoices...


--Added for Defect 31838
		BEGIN
		    -- Writing the above data into the table
			FORALL i in 0 .. ln_tab_rprn_rows.COUNT-1
			INSERT INTO xx_ar_cbi_rprn_rows VALUES ln_tab_rprn_rows(i);

			Commit;
			ln_tab_rprn_rows.DELETE;
			lntrx := -1;

			lc_error_location := 'Insert SPC CARD info';
			lc_debug := '';

			 FOR spc_rec IN (SELECT a.item_description spc_card_details, b.trx_id
				 FROM   xx_ar_cbi_rprn_trx_lines a,
				       (select to_number(attribute3) trx_id
					    from xx_ar_cbi_rprn_rows b
					    where request_id  = P_REQUEST_ID
						  and cons_inv_id = ln_cbi_id
					   )b
				 WHERE a.request_id      =P_REQUEST_ID
				   --AND a.cons_inv_id     =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
				   AND a.cons_inv_id     = ln_cbi_id    -- Added for R1.2 Defect# 1210 CR# 466.
				   AND a.customer_trx_id = b.trx_id
				   AND a.item_code       ='SPC_CARD_INFO')

			 LOOP
				--xx_ar_cbi_rprn_subtotals.insert_rprn_rows
				insert_rprn_rows_tbl
				 (
				   P_REQUEST_ID
				  --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
				  ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
				  ,'SPC_REC'
				  ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
				  , RPAD(' ' ,8 ,' ')
				  ||RPAD('Note: ' ,6 ,' ')
				  ||spc_rec.spc_card_details
				  ||RPAD(' ' ,8 ,' ')
				 ,'N' -- page break not required for spc card info record.
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,spc_rec.trx_id
				 );
			 END LOOP;
	         lc_error_location := 'Insert TD info';
	         lc_debug := '';
		 --fnd_file.put_line(fnd_file.log 'STEP 4 --Insert Tiered Discount row...');

			 FOR td_rec IN (SELECT extended_price td_value, b.trx_id
				 FROM   xx_ar_cbi_rprn_trx_lines a,
				        (select to_number(attribute3) trx_id
					     from xx_ar_cbi_rprn_rows b
					     where request_id  = P_REQUEST_ID
						   and cons_inv_id = ln_cbi_id
					    )b
				 WHERE a.request_id      =P_REQUEST_ID
				   --AND a.cons_inv_id     =rec.cbi_id  -- Commented for R1.2 Defect# 1210 CR# 466.
				   AND a.cons_inv_id     = ln_cbi_id    -- Added for R1.2 Defect# 1210 CR# 466.
				   AND a.customer_trx_id = b.trx_id
				   AND a.item_code       ='TD')

			 LOOP
				--xx_ar_cbi_rprn_subtotals.insert_rprn_rows
				insert_rprn_rows_tbl
				 (
				   P_REQUEST_ID
				  --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
				  ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
				  ,'TD_REC'
				  ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
				  ,RPAD(' ' ,8 ,' ')
				   ||'Note: A Tiered discount of '
--                       ||RPAD(NVL(TO_CHAR(td_rec.td_value ,'9G999D99PR') ,' ') ,11 ,' ')   -- Commented for R1.2 Defect 1143 (CR 621)
				   ||RPAD(NVL(TO_CHAR(td_rec.td_value ,'9G999D99') ,' ') ,11 ,' ')     -- Added for R1.2 Defect 1143 (CR 621)
				   ||' has been applied to your order.'
				   ||RPAD(' ' ,8 ,' ')
				 ,'N' -- page break not required for tiered discount info record.
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,NULL
				 ,td_rec.trx_id
				 );
			 END LOOP;
		 --fnd_file.put_line(fnd_file.log 'STEP 5 --Insert Sub total records...');
			 lc_error_location := 'Insert Sub total records';
			 lc_debug := '';
			 FOR subtotal_records IN get_softheader_totals(ln_cbi_id,0) -- Commented rec.cbi_id and added ln_cbi_id for R1.2 Defect# 1210 CR# 466.
			  LOOP
				  IF TRIM(subtotal_records.summarize_text) LIKE 'GRAND TOTAL%' THEN
					lc_line_type :='GRAND_TOTAL';
				  ELSIF TRIM(subtotal_records.summarize_text) LIKE 'TOTAL FOR BILL%' THEN
					lc_line_type :='BILL_TO_TOTAL';
				  ELSE
					lc_line_type :='SOFTHDR_TOTAL';
				  END IF;
				--xx_ar_cbi_rprn_subtotals.insert_rprn_rows
				insert_rprn_rows_tbl
				 (
				   P_REQUEST_ID
				   --,rec.cbi_id                               -- Commented for R1.2 Defect# 1210 CR# 466.
				  ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
				  ,lc_line_type
				  ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
				  ,subtotal_records.summarize_text                  --sf text
				  ,subtotal_records.pg_break                        --page break may exist
				  ,RPAD(subtotal_records.total_orders ,27 ,' ')     --attribute1
				  ,NULL                                             --attribute2
				  ,NVL(subtotal_records.summarize_subtotal ,0)
				  ,NVL(subtotal_records.summarize_delivery ,0)
				  ,NVL(subtotal_records.summarize_discounts ,0)
				  ,NVL(subtotal_records.summarize_tax ,0)
				  ,NVL(subtotal_records.summarize_total ,0)
				  ,NULL
				  ,NULL
				  ,NULL
				  ,NULL
				  ,Null
				  ,subtotal_records.customer_trx_id
				 );
			END LOOP;

			FORALL i in 0 .. ln_tab_rprn_rows.COUNT-1
			INSERT INTO xx_ar_cbi_rprn_rows VALUES ln_tab_rprn_rows(i);
			Commit;

		EXCEPTION
		WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'Errorw hile loading data. ' || SQLERRM);
			ROLLBACK;
		END;
		--End of addition for Defect 31838
  ELSIF lc_template ='ONE' THEN
         lc_error_location := 'Insert Sub total records - ONE';
         lc_debug := '';

                FOR subtotal_records IN get_softheader_ONE_totals (/*rec.cbi_id*/ln_cbi_id) --Commented rec.cbi_id and added ln_cbi_id for R1.2 Defect# 1210 CR# 466.
                 LOOP
                        IF TRIM(subtotal_records.summarize_text) LIKE 'GRAND TOTAL%' THEN
                          lc_line_type :='GRAND_TOTAL';
                        ELSIF TRIM(subtotal_records.summarize_text) LIKE 'TOTAL FOR BILL%' THEN
                          lc_line_type :='BILL_TO_TOTAL';
                        ELSE
                          lc_line_type :='SOFTHDR_TOTAL';
                        END IF;
                      --xx_ar_cbi_rprn_subtotals.insert_rprn_rows
					  insert_rprn_rows_tbl
                       (
                         P_REQUEST_ID
                        --,rec.cbi_id                                -- Commented for R1.2 Defect# 1210 CR# 466.
                        ,ln_cbi_id                                   -- Added for R1.2 Defect# 1210 CR# 466.
                        ,lc_line_type
                        ,xx_ar_cbi_rprn_subtotals.get_rprn_seq()
                        ,RPAD(' ' ,20 ,' ')||RPAD(subtotal_records.summarize_text ,50 ,' ')   --sf text
                        ,subtotal_records.pg_break                        --page break may exist
                        ,RPAD(subtotal_records.total_orders ,27 ,' ')     --attribute1
                        ,NULL                                             --attribute2
                        ,NVL(subtotal_records.summarize_subtotal ,0)
                        ,NVL(subtotal_records.summarize_delivery ,0)
                        ,NVL(subtotal_records.summarize_discounts ,0)
                        ,NVL(subtotal_records.summarize_tax ,0)
                        ,NVL(subtotal_records.summarize_total ,0)
                        ,NULL
                        ,NULL
                        ,NULL
                        ,NULL
                        ,NULL
                        ,NULL
                       );
                 END LOOP;

 -- Added for defect 35282 (fix for 31838)				
				FORALL i in 0 .. ln_tab_rprn_rows.COUNT-1
				INSERT INTO xx_ar_cbi_rprn_rows VALUES ln_tab_rprn_rows(i);
				Commit;

  ELSIF lc_template ='DETAIL' THEN
      NULL;
  ELSE
       NULL;
  END IF;
    END LOOP; --g_pay_cust CURSOR
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log ,'BeforeReport Paydoc :' || SUBSTR (SQLERRM, 1, 2000));
  END;
  fnd_file.put_line(fnd_file.log ,'Exit Reprint Pay Doc Block-2');
 COMMIT;

 RETURN TRUE;  --OUTER RETURN STATEMENT FOR THE FUNCTION beforereport trigger...

EXCEPTION
 WHEN OTHERS
 THEN
  fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

    fnd_file.put_line(fnd_file.log ,'BeforeReport :' || SUBSTR (SQLERRM, 1, 2000));
    ROLLBACK;
    RETURN FALSE;
END beforereport;
/*
  End Main -BeforeReport Trigger....
*/

FUNCTION xx_fin_check_digit (p_account_number VARCHAR2,
                                               p_invoice_number VARCHAR2,
                                               p_amount         VARCHAR2) RETURN VARCHAR2 IS
  v_account_number       VARCHAR2(8) := LPAD(REPLACE(p_account_number,' ','0'),8,'0');
  v_account_number_cd    NUMBER;
  v_invoice_number       VARCHAR2(12) := LPAD(REPLACE(p_invoice_number,' ','0'),12,'0');
  v_invoice_number_cd    NUMBER;
  v_amount               VARCHAR2(11) := LPAD(REPLACE(REPLACE(p_amount,' ','0'),'-','0'),11,'0');
  v_amount_cd            NUMBER;
  v_value_out            VARCHAR2(50);
  v_final_cd             NUMBER;

  FUNCTION f_check_digit (v_string VARCHAR2) RETURN NUMBER IS
    v_sum     NUMBER := 0;
    v_weight  NUMBER;
    v_product NUMBER;
  BEGIN
    FOR i in 1..length(v_string) LOOP
      /* Set the weight based on the character space */
      If mod(i,2) = 0 Then
        v_weight := 2;
      Else
        v_weight := 1;
      End If;

      /* Calculate the weighted procduct */
      v_product := SUBSTR(v_string, i, 1) * v_weight;

      /* Add the digit or digits to the sum */
      IF LENGTH(v_product) = 1 THEN
        v_sum := v_sum + v_product;
      ELSE
        v_sum := v_sum + SUBSTR(v_product,1,1) + SUBSTR(v_product,2);
      END IF;
    END LOOP;

    /* Check digit is 10-the mod10 of the sum */
    IF (MOD(v_sum,10) = 0) THEN   -- defect 7629
      v_sum := 0;
    ELSE
      v_sum := 10-MOD(v_sum,10);
    END IF;

    RETURN v_sum;
  END;

BEGIN
  /* Calculate the account check digit */
  v_account_number_cd := f_check_digit(v_account_number);

  /* Calculate the invoice check digit */
  v_invoice_number_cd := f_check_digit(v_invoice_number);

  /* Set the amount check digit */
  IF p_amount > 0 THEN
    v_amount_cd := 1;
  ELSE
    v_amount_cd := 0;
  END IF;

  /* Calculate the final check digit */
  v_final_cd := f_check_digit(v_account_number||v_account_number_cd||v_invoice_number||v_invoice_number_cd||v_amount||v_amount_cd);

  /* Build and return the out value */
  v_value_out := v_account_number||v_account_number_cd||' '||v_invoice_number||v_invoice_number_cd||' '||v_amount||' '||v_amount_cd||' '||v_final_cd;
  RETURN v_value_out;
END xx_fin_check_digit;

FUNCTION get_cbi_amount_due
             (
               p_cbi_id IN           NUMBER
              ,p_ministmnt_line_type VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,TAX and TOTAL...
             ) RETURN NUMBER AS
 ln_ext_amt_plus_delvy NUMBER :=0;
 ln_promo_and_disc     NUMBER :=0;
 ln_tax_amount     NUMBER :=0;
 ln_total_amount   NUMBER :=0;
 lc_return_amount      NUMBER :=0;
 lc_error_location VARCHAR2(2000);  -- added for defect 11993
 lc_debug          VARCHAR2(1000);  -- added for defect 11993

BEGIN
-- added for defect 11993
  lc_error_location := 'Getting EXTAMT_PLUS_DELVY';
  lc_debug := '';
 IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN
   BEGIN
/*   SELECT SUM(extamt) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN
--      (
--         SELECT RACTL.CUSTOMER_TRX_LINE_ID
--         FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--               ,OE_PRICE_ADJUSTMENTS OEPA
--         WHERE  1 = 1
--         AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--         AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--      )
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )
    UNION ALL
    SELECT SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID =p_cbi_id
            )
      AND (ractl.interface_line_attribute11 IS NULL OR ractl.interface_line_attribute11 =0)
    );
  */
  -- Added for Defect # 10750 perf

    SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
    INTO    ln_ext_amt_plus_delvy
    FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
          ,RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
      AND CONSINV_LINES.customer_trx_line_id = ractl.customer_trx_line_id
      AND RACTL.LINE_TYPE = 'LINE'
    --AND RACTL.DESCRIPTION != 'Tiered Discount'  ; --Commented for defect#5074 (V 2.6) on 24-Jun-2010
      AND    RACTL.interface_line_attribute11 = '0'; --Added for defect#5074 (V 2.6) on 24-Jun-2010


      lc_return_amount :=ln_ext_amt_plus_delvy;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY');
     RETURN 0;
   END;
-- added for defect 11993
  lc_error_location := 'Getting TAX';
  lc_debug := '';
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN
     /*
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                );
     */
        SELECT SUM (nvl(tax_original ,0))
        INTO   ln_tax_amount
        FROM ar_cons_inv_trx
        WHERE cons_inv_id =p_cbi_id
          AND transaction_type IN
                       (
                         'INVOICE'
                        ,'CREDIT_MEMO'
                        --,'ADJUSTMENT'
                       );
      lc_return_amount :=ln_tax_amount;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX');
     RETURN 0;
   END;
-- added for defect 11993
  lc_error_location := 'Getting DISCOUNT';
  lc_debug := '';
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN
 /*       SELECT SUM(nvl(DISCOUNT.AMOUNT ,0))
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(RACTL.EXTENDED_AMOUNT) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND to_number(RACTL.INTERFACE_LINE_ATTRIBUTE11)   =OEPA.PRICE_ADJUSTMENT_ID
          AND RACTL.CUSTOMER_TRX_LINE_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
                )
        UNION ALL
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )
        ) DISCOUNT;
 */

   ---Added for perf defect # 10750
        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_lines_all acit
              ,RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND acit.cons_inv_id = p_cbi_id
          AND acit.customer_trx_line_id = ractl.customer_trx_line_id
          AND RACTL.LINE_TYPE = 'LINE'
    --AND RACTL.DESCRIPTION != 'Tiered Discount'  ; --Commented for defect#5074 (V2.6) on 24-Jun-2010
      AND    RACTL.interface_line_attribute11 = '0';--Added for defect#5074 (V2.6) on 24-Jun-2010

 lc_return_amount :=ln_promo_and_disc;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS');
     RETURN 0;
   END;
 -- added for defect 11993
  lc_error_location := 'Getting TOTAL';
  lc_debug := '';

 ELSIF p_ministmnt_line_type ='TOTAL' THEN
   BEGIN
/*   SELECT NVL(SUM(extamt) ,0) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT) ,0) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN
--      (
--         SELECT RACTL.CUSTOMER_TRX_LINE_ID
--         FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--               ,OE_PRICE_ADJUSTMENTS OEPA
--         WHERE  1 = 1
--         AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--         AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--      )
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )
    UNION ALL
    SELECT SUM(RACTL.EXTENDED_AMOUNT) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID =p_cbi_id
            )
      AND (ractl.interface_line_attribute11 IS NULL OR ractl.interface_line_attribute11 =0)
    );
  */
  -- Added for Defect # 10750 perf

    SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
    INTO    ln_ext_amt_plus_delvy
    FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
          ,RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
      AND CONSINV_LINES.customer_trx_line_id = ractl.customer_trx_line_id
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'  ;

  lc_return_amount :=lc_return_amount + ln_ext_amt_plus_delvy;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY');
     lc_return_amount :=lc_return_amount+0;
   END;
   BEGIN
    /*
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                );
    */
        SELECT NVL(SUM (tax_original) ,0)
        INTO   ln_tax_amount
        FROM ar_cons_inv_trx
        WHERE cons_inv_id =p_cbi_id
          AND transaction_type IN
                       (
                         'INVOICE'
                        ,'CREDIT_MEMO'
                        --,'ADJUSTMENT'
                       );
      lc_return_amount :=lc_return_amount + ln_tax_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX');
     lc_return_amount :=lc_return_amount+0;
   END;
   BEGIN
/*        SELECT NVL(SUM(DISCOUNT.AMOUNT) ,0)
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(RACTL.EXTENDED_AMOUNT) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND to_number(RACTL.INTERFACE_LINE_ATTRIBUTE11)   =OEPA.PRICE_ADJUSTMENT_ID
          AND RACTL.CUSTOMER_TRX_LINE_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
                )
        UNION ALL
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )
        ) DISCOUNT;
  */
     ---Added for perf defect # 10750
        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_lines_all acit
              ,RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND acit.cons_inv_id = p_cbi_id
          AND acit.customer_trx_line_id = ractl.customer_trx_line_id
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 =OEPA.PRICE_ADJUSTMENT_ID;


  lc_return_amount :=lc_return_amount + ln_promo_and_disc;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS');
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;
   END;
          /*
       BEGIN
        SELECT SUM(amount_original)
        INTO   ln_total_amount
        FROM   ar_cons_inv_trx
        WHERE  cons_inv_id =p_cbi_id
          AND  transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
          lc_return_amount :=ln_total_amount;
          RETURN lc_return_amount;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
         RETURN 0;
        WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_get_paydoc_ministmnt in formula TOTAL');
         RETURN 0;
       END;
          */
 ELSE
      RETURN(0);
 END IF;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
     fnd_file.put_line(fnd_file.log, 'NODATA @ xx_ar_cbi_paydoc_ministmnt...'||SQLERRM);
      RETURN(0);
 WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
   fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt...'||SQLERRM);
      RETURN(0);
END get_cbi_amount_due;

FUNCTION afterreport RETURN BOOLEAN
IS
 -- Start for Defect # 12223
   TYPE cons_tab IS TABLE OF ar_cons_inv_all.cons_inv_id%TYPE;
      t_cons_tab cons_tab;
   CURSOR c_cons_ids(p_req NUMBER) IS
     SELECT XACR.cons_inv_id
     FROM   fnd_concurrent_requests  FCR
           ,xx_ar_cbi_rprn_trx       XACR
     WHERE  FCR.request_id=p_req
     AND   FCR.parent_request_id = XACR.request_id
     GROUP BY XACR.cons_inv_id;

   ld_print_date            VARCHAR2(40)        DEFAULT TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS');
   ln_request_id            NUMBER;
   lc_error_location VARCHAR2(2000);  -- added for defect 11993
   lc_debug          VARCHAR2(1000);  -- added for defect 11993
   lc_who           CONSTANT fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');
   ld_when          CONSTANT DATE                                              := SYSDATE;
 -- End for Defect # 12223
BEGIN
 -- NULL;  Commented for Defect # 12223
 -- Start for Defect # 12223
      ln_request_id := FND_GLOBAL.CONC_REQUEST_ID;
 -- added for defect 11993
  lc_error_location := 'Getting Cons. Inovice ID for the request ID';
  lc_debug := 'request ID' || to_char(ln_request_id);

      OPEN c_cons_ids(ln_request_id);
      FETCH c_cons_ids BULK COLLECT INTO t_cons_tab;
      CLOSE c_cons_ids;
      IF t_cons_tab.count > 0 THEN
        FOR i IN t_cons_tab.FIRST .. t_cons_tab.LAST
           LOOP
             fnd_file.put_line(fnd_file.log,'Updation and Deletion for Billing ID...'|| t_cons_tab(i) );

           IF (P_SPEC_HANDLING_FLAG = 'Y') THEN

             UPDATE ar_cons_inv
             SET attribute10     = ld_print_date || '|' ||P_REQUEST_ID
                 ,attribute15    = 'Y'  --added for defect 4760
                 ,last_update_date  = SYSDATE  -- added for defect 4761
                 ,last_updated_by   = FND_GLOBAL.USER_ID  -- added for defect 4761
                 ,last_update_login = FND_GLOBAL.USER_ID  -- added for defect 4761
             WHERE cons_inv_id = t_cons_tab(i);

          END IF;
               --- Pushing the records into history before flusing the tables
               --  below two inserts part of defect# 11993
 -- added for defect 11993
  lc_error_location := 'Deleting record from xx_ar_cbi_rprn_rows and xx_ar_cbi_rprn_rows';
  lc_debug := 'Cons bill ID: ' || to_char(t_cons_tab(i));
--Start of Defect# 11993.

              INSERT INTO XX_AR_CBI_RPRN_TRX_HISTORY
              SELECT
                      REQUEST_ID
                     ,CONS_INV_ID
                     ,CUSTOMER_TRX_ID
                     ,ORDER_HEADER_ID
                     ,INV_NUMBER
                     ,INV_TYPE
                     ,INV_SOURCE_ID
                     ,INV_SOURCE_NAME
                     ,ORDER_DATE
                     ,SHIP_DATE
                     ,SFHDR1
                     ,SFDATA1
                     ,SFHDR2
                     ,SFDATA2
                     ,SFHDR3
                     ,SFDATA3
                     ,SFHDR4
                     ,SFDATA4
                     ,SFHDR5
                     ,SFDATA5
                     ,SFHDR6
                     ,SFDATA6
                     ,SUBTOTAL_AMOUNT
                     ,DELIVERY_CHARGES
                     ,PROMO_AND_DISC
                     ,TAX_CODE
                     ,TAX_AMOUNT
                     ,CAD_COUNTY_TAX_CODE
                     ,CAD_COUNTY_TAX_AMOUNT
                     ,CAD_STATE_TAX_CODE
                     ,CAD_STATE_TAX_AMOUNT
                     ,INSERT_SEQ
                     ,ATTRIBUTE1
                     ,ATTRIBUTE2
                     ,ATTRIBUTE3
                     ,ATTRIBUTE4
                     ,ATTRIBUTE5
                     ,ATTRIBUTE6
                     ,ATTRIBUTE7
                     ,ATTRIBUTE8
                     ,ATTRIBUTE9
                     ,ATTRIBUTE10
                     ,ATTRIBUTE11
                     ,ATTRIBUTE12
                     ,ATTRIBUTE13
                     ,ATTRIBUTE14
                     ,ATTRIBUTE15
                     ,ORG_ID
                     ,ld_when
                     ,lc_who
                     ,ld_when
                     ,lc_who
              FROM   xx_ar_cbi_rprn_trx
              WHERE  cons_inv_id = t_cons_tab(i)
              AND    request_id  =P_REQUEST_ID;

              INSERT INTO XX_AR_CBI_RPRN_ROWS_HISTORY
              SELECT
                     REQUEST_ID
                    ,CONS_INV_ID
                    ,LINE_TYPE
                    ,LINE_SEQ
                    ,SF_TEXT
                    ,SFDATA1
                    ,SFDATA2
                    ,SFDATA3
                    ,SFDATA4
                    ,SFDATA5
                    ,SUBTOTAL
                    ,DELIVERY
                    ,DISCOUNTS
                    ,TAX
                    ,TOTAL
                    ,PAGE_BREAK
                    ,ATTRIBUTE1
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,ATTRIBUTE10
                    ,ORG_ID
                    ,ld_when
                    ,lc_who
                    ,ld_when
                    ,lc_who
               FROM xx_ar_cbi_rprn_rows
               WHERE  cons_inv_id = t_cons_tab(i)
               AND    request_id  =P_REQUEST_ID;

               --End of Defect# 11993.


              DELETE xx_ar_cbi_rprn_trx
              WHERE  cons_inv_id = t_cons_tab(i)
              AND    request_id  =P_REQUEST_ID;


             DELETE xx_ar_cbi_rprn_rows
             WHERE  cons_inv_id = t_cons_tab(i)
             AND    request_id  =P_REQUEST_ID;

           END LOOP;

        COMMIT;
      END IF;


 -- End for Defect # 12223
 RETURN TRUE;
EXCEPTION
 WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
   fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

  fnd_file.put_line(fnd_file.log,'WHEN OTHERS...After Report Trigger...');
  ROLLBACK;
  RETURN FALSE;
END afterreport;

FUNCTION XX_RETURN_ADDRESS return VARCHAR2
IS
lc_address1       VARCHAR2(40);
lc_address2       VARCHAR2(40);
lc_address3       VARCHAR2(40);
lc_address4       VARCHAR2(40);
lc_city           VARCHAR2(40);
lc_state          VARCHAR2(40);
lc_postal_code    VARCHAR2(40);
lc_province       VARCHAR2(40);
lc_country        VARCHAR2(10);

lc_description fnd_territories_vl.territory_short_name%TYPE;
lc_postal         VARCHAR2(25);
lc_state_pr       VARCHAR2(25);
lc_address        VARCHAR2(1000);
   lc_error_location VARCHAR2(2000);  -- added for defect 11993
   lc_debug          VARCHAR2(1000);  -- added for defect 11993

begin
 -- added for defect 11993
  lc_error_location := 'Getting RETURN ADDRESS';
  lc_debug := '';


select return_address_line1 return_address_line1
      ,return_address_line2 return_address_line2
      ,return_city          return_city
      ,return_state         return_state
      ,return_postal_code   return_postal_code
into   lc_address1
       ,lc_address2
       ,lc_city
       ,lc_state
       ,lc_postal_code
from   xx_ar_sys_info;          -- Removed apps schema References
    IF (LENGTH(lc_postal_code) <= 5)
         THEN
        lc_postal := lc_postal_code;
    ELSE
        lc_postal := SUBSTR(lc_postal_code,1,5)||'-'||SUBSTR(REPLACE(lc_postal_code ,'-'),6);
    END IF;


IF (lc_address1 IS NOT NULL)
 THEN
   lc_address :=lc_address1;
END IF;

IF (lc_address2 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address2;
END IF;
return (lc_address||chr(10)
        ||lc_city||' '||lc_state||'  '||lc_postal||chr(10)
       );
EXCEPTION
WHEN NO_DATA_FOUND THEN

DBMS_OUTPUT.PUT_LINE(SQLERRM);
 RETURN NULL;
WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
   fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

DBMS_OUTPUT.PUT_LINE(SQLERRM);
 RETURN NULL;
END XX_RETURN_ADDRESS;

FUNCTION XX_BILL_TO_ADDRESS (p_site_use_id IN NUMBER) return VARCHAR2
IS
lc_address1       VARCHAR2(40);
lc_address2       VARCHAR2(40);
lc_address3       VARCHAR2(40);
lc_address4       VARCHAR2(40);
lc_city           VARCHAR2(40);
lc_state          VARCHAR2(40);
lc_postal_code    VARCHAR2(40);
lc_province       VARCHAR2(40);
lc_country        VARCHAR2(10);

lc_description fnd_territories_vl.territory_short_name%TYPE;
lc_postal         VARCHAR2(25);
lc_state_pr       VARCHAR2(25);
lc_address        VARCHAR2(1000);
lc_error_location VARCHAR2(2000);  -- added for defect 11993
lc_debug          VARCHAR2(1000);  -- added for defect 11993

begin

 -- added for defect 11993
  lc_error_location := 'Getting BILL TO ADDRESS';
  lc_debug := '';

select
     substr(hzlo.address1 ,1 ,40)  bill_to_address_line1
      ,substr(hzlo.address2 ,1 ,40)  bill_to_address_line2
      ,substr(hzlo.address3 ,1 ,40)  bill_to_address_line3
      ,substr(hzlo.address4 ,1 ,40)  bill_to_address_line4
      ,substr(hzlo.city ,1 ,40)      bill_to_city
      ,hzlo.state                    bill_to_state
      ,REPLACE(hzlo.postal_code ,'-' ,'') bill_to_postal_code
      ,hzlo.province                 bill_to_province
      ,hzlo.country                  bill_to_country
into   lc_address1
       ,lc_address2
       ,lc_address3
       ,lc_address4
       ,lc_city
       ,lc_state
       ,lc_postal_code
       ,lc_province
       ,lc_country
from    hz_cust_site_uses     hzsu
        ,hz_cust_acct_sites   hzas
        ,hz_party_sites       hzps
        ,hz_locations         hzlo
where   hzsu.site_use_id             =p_site_use_id
and     hzsu.cust_acct_site_id       =hzas.cust_acct_site_id
and     hzps.party_site_id           =hzas.party_site_id
and     hzlo.location_id             =hzps.location_id;

    IF (lc_country = 'CA')
         THEN
        SELECT UPPER(territory_short_name)
              INTO lc_description
              FROM fnd_territories_vl
             WHERE territory_code = lc_country;

        IF lc_description IS NULL THEN
                    lc_description := lc_country;
                END IF;
    ELSE
       lc_description := '';
    END IF;

    IF (lc_country = 'CA')
         THEN
        lc_state_pr := lc_province;
        ELSIF (lc_country = 'US')
           THEN
            lc_state_pr := lc_state;
    END IF;

    IF (LENGTH(lc_postal_code) <= 5)
         THEN
        lc_postal := lc_postal_code;
    ELSE
        lc_postal := SUBSTR(lc_postal_code,1,5)||'-'||SUBSTR(REPLACE(lc_postal_code ,'-'),6);
    END IF;


IF (lc_address1 IS NOT NULL)
 THEN
   lc_address :=lc_address1;
END IF;

IF (lc_address2 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address2;
END IF;

IF (lc_address3 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address3;
END IF;

IF (lc_address4 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address4;
END IF;
return (lc_address||chr(10)
        ||lc_city||' '||lc_state_pr||'  '||lc_postal||chr(10) -- Defect 9165
        ||lc_description
       );
EXCEPTION
WHEN NO_DATA_FOUND THEN
 RETURN NULL;
WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
   fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

 RETURN NULL;
END XX_BILL_TO_ADDRESS;

FUNCTION XX_REMIT_TO_ADDRESS (p_site_use_id IN NUMBER) return VARCHAR2
IS
lc_address1       VARCHAR2(40);
lc_address2       VARCHAR2(40);
lc_address3       VARCHAR2(40);
lc_address4       VARCHAR2(40);
lc_city           VARCHAR2(40);
lc_state          VARCHAR2(40);
lc_postal_code    VARCHAR2(40);
lc_province       VARCHAR2(40);
lc_country        VARCHAR2(10);

lc_description fnd_territories_vl.territory_short_name%TYPE;
lc_postal         VARCHAR2(25);
lc_state_pr       VARCHAR2(25);
lc_address        VARCHAR2(1000);
lc_error_location VARCHAR2(2000);  -- added for defect 11993
lc_debug          VARCHAR2(1000);  -- added for defect 11993

begin

  lc_error_location := 'Getting REMIT TO ADDRESS';
  lc_debug := '';

select substr(rhzlo.address1 ,1 ,40) remit_to_address_line1
      ,substr(rhzlo.address2 ,1 ,40) remit_to_address_line2
      ,substr(rhzlo.address3 ,1 ,40) remit_to_address_line3
      ,substr(rhzlo.address4 ,1 ,40) remit_to_address_line4
      ,substr(rhzlo.city ,1 ,40)     remit_to_city
      ,rhzlo.state                   remit_to_state
      ,rhzlo.postal_code              remit_to_postal_code
      ,rhzlo.country                 remit_to_country
into   lc_address1
       ,lc_address2
       ,lc_address3
       ,lc_address4
       ,lc_city
       ,lc_state
       ,lc_postal_code
       ,lc_country
from   hz_cust_acct_sites   rhzca
       ,hz_party_sites       rhzps
       ,hz_locations         rhzlo
where rhzca.cust_acct_site_id      =xx_ar_print_summbill.get_remitaddressid(p_site_use_id)
    and rhzps.party_site_id        =rhzca.party_site_id
    and rhzlo.location_id          =rhzps.location_id;

    IF (lc_country = 'CA')
         THEN
        SELECT UPPER(territory_short_name)
              INTO lc_description
              FROM fnd_territories_vl
             WHERE territory_code = lc_country;

        IF lc_description IS NULL THEN
                    lc_description := lc_country;
                END IF;
    ELSE
       lc_description := '';
    END IF;

    IF (lc_country = 'CA')
         THEN
        lc_state_pr := lc_province;
        ELSIF (lc_country = 'US')
           THEN
            lc_state_pr := lc_state;
    END IF;

    IF (LENGTH(lc_postal_code) <= 5)
         THEN
        lc_postal := lc_postal_code;
    ELSE
        lc_postal := SUBSTR(lc_postal_code,1,5)||'-'||SUBSTR(REPLACE(lc_postal_code ,'-'),6);
    END IF;


IF (lc_address1 IS NOT NULL)
 THEN
   lc_address :=lc_address1;
END IF;

IF (lc_address2 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address2;
END IF;

IF (lc_address3 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address3;
END IF;

IF (lc_address4 IS NOT NULL)
 THEN
   lc_address := lc_address||chr(10)||lc_address4;
END IF;
RETURN (lc_address||chr(10)
        ||lc_city||' '||lc_state_pr||'  '||lc_postal||chr(10) -- Defect 9165
        ||lc_description
       );
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE(SQLERRM);
 RETURN NULL;
WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
   fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

DBMS_OUTPUT.PUT_LINE(SQLERRM);
 RETURN NULL;
END XX_REMIT_TO_ADDRESS;

-- Added the below procedure GET_IND_BILL_NUM for R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name        : GET_IND_BILL_NUM                                    |
-- | Description : To get the individual transactions separately from  |
-- |               the Multiple transactions parameter separated by    |
-- |               commas.                                             |
-- | Parameters  : p_multiple_bills                                    |
-- |               p_virtual_bill_flag                                 |
-- |                                                                   |
-- | Returns     : x_error_buff,x_ret_code                             |
-- +===================================================================+
 PROCEDURE GET_IND_BILL_NUM ( x_error_buff        OUT VARCHAR2
                             ,x_ret_code          OUT NUMBER
                             ,p_multi_trans_num   IN  VARCHAR2
                             ,p_virtual_bill_flag IN  VARCHAR2
                             )
 AS

 lc_multi_trans_num VARCHAR2(240) := p_multi_trans_num;
 ln_loop            NUMBER;
 ln_instr_len       NUMBER;
 lc_value           VARCHAR2(150);
 ln_cons_inv_id     ar_cons_inv_all.cons_inv_id%type;

 BEGIN

    SELECT LENGTH(lc_multi_trans_num) - LENGTH(TRANSLATE(lc_multi_trans_num,CHR(0)||',',CHR(0)))
    INTO   ln_loop
    FROM   dual;

    ln_loop := ln_loop + 1;

    FOR i IN 1..ln_loop
    LOOP

       SELECT INSTR(lc_multi_trans_num,',')
       INTO   ln_instr_len
       FROM   dual;

       SELECT  SUBSTR(lc_multi_trans_num,1,ln_instr_len-1)
              ,SUBSTR(lc_multi_trans_num,ln_instr_len+1)
       INTO    lc_value
              ,lc_multi_trans_num
       FROM  dual;

       IF lc_value IS NULL THEN
          lc_value := lc_multi_trans_num;
       END IF;

       IF p_virtual_bill_flag = 'N' THEN

          SELECT cons_inv_id
          INTO   ln_cons_inv_id
          FROM   ar_cons_inv
          WHERE  cons_billing_number = lc_value;

       ELSE

          ln_cons_inv_id := lc_value;

       END IF;

       xx_ar_reprint_summbill.lt_cons_bill.EXTEND;
       xx_ar_reprint_summbill.lt_cons_bill(i) := ln_cons_inv_id;

    END LOOP;

 END GET_IND_BILL_NUM;

 -- Added the below function GET_BILL_TO_DATE for R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name        : GET_BILL_TO_DATE                                    |
-- | Description : To get the bill to date for reprinting the bills.   |
-- |               commas.                                             |
-- | Parameters  : p_customer_id                                       |
-- |              ,p_site_id                                           |
-- |              ,p_consinv_id                                        |
-- |              ,p_infocopy_tag                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns     : x_error_buff,x_ret_code                             |
-- +===================================================================+
 FUNCTION GET_BILL_TO_DATE( p_customer_id  IN NUMBER
                           ,p_consinv_id   IN NUMBER
                           ,infocopy_tag   IN VARCHAR2
                           )
 RETURN DATE AS

 ld_bill_to_date   DATE;

 BEGIN

    IF infocopy_tag != 'INV_IC' THEN

       SELECT  TO_DATE(ACI.attribute1) - 1
       INTO    ld_bill_to_date
       FROM    ar_cons_inv ACI
       WHERE   ACI.cons_inv_id = p_consinv_id
       AND     ACI.customer_id = p_customer_id;

    ELSE

       SELECT MAX(bill_from_date)
       INTO   ld_bill_to_date
       FROM   xx_ar_cons_bills_history  XACBH
       WHERE  XACBH.cons_inv_id   = p_consinv_id
       AND    XACBH.customer_id   = p_customer_id
       AND    XACBH.attribute8    = 'INV_IC';

       IF ld_bill_to_date IS NULL THEN

          SELECT MAX(issue_date)
          INTO   ld_bill_to_date
          FROM   xx_ar_gen_bill_lines_all   XAGT
          WHERE  XAGT.n_ext_attr2    = p_consinv_id
          AND    XAGT.customer_id    = p_customer_id
          AND    XAGT.c_ext_attr1    = 'INV_IC';

          -- Added as part of R1.4 CR# 586

          IF ld_bill_to_date IS NULL THEN

             SELECT DISTINCT bill_to_date
             INTO   ld_bill_to_date
             FROM   xx_ar_ebl_cons_hdr_hist   XAECHH
             WHERE  XAECHH.cons_inv_id       = p_consinv_id
             AND    XAECHH.cust_account_id   = p_customer_id
             AND    XAECHH.infocopy_tag      = 'INV_IC';

          END IF;

          -- End of changes of R1.4 CR# 584.

       END IF;

    END IF;

    RETURN ld_bill_to_date;

 EXCEPTION
    WHEN OTHERS THEN
       RETURN NULL;

 END GET_BILL_TO_DATE;
 -- Added below function GET_CONS_MSG_BCC as part of NAIT# 80452
 --+=============================================================================================+
  ---|    Name : GET_CONS_MSG_BCC                                                                 |
  ---|    Description   : This function will perform the following                                |
  ---|                                                                                            |
  ---|                  1. If customer is "Bill complete customer" and document type is           |
  -- |                     "Consolidated" and it is Paydoc then blurb message to be displayed in  |
  ---|                      respective child programs of "OD: AR Reprint Summary Bills".          |                 
  ---|                                                                                            |
  ---|    Parameters : Cust_doc_Id, Cust_account_id, Consolidated_billing_number                  |
  --+=============================================================================================+	 
FUNCTION GET_CONS_MSG_BCC 
	     ( p_custdoc_id      IN NUMBER		  
		  ,p_cust_account_id IN NUMBER
		  ,p_billing_number  IN VARCHAR2
	     ) 
 RETURN VARCHAR2 AS 
		lc_cons_msg_bcc   VARCHAR2(2000) := TO_CHAR(NULL);
		ln_delivery_method xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE;
		lc_error_location VARCHAR2(2000);
		ln_attr_group_id  NUMBER;
		ln_custdoc_id     NUMBER;		
		
BEGIN
	  SELECT attr_group_id
		INTO ln_attr_group_id
		FROM ego_attr_groups_v
	   WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
		 AND attr_group_name = 'BILLDOCS';
		 
		 fnd_file.put_line(fnd_file.log , 'p_cust_doc_id is '||p_custdoc_id||' p_cust_account_id is '||p_cust_account_id
		 ||' p_billing_number is '||p_billing_number ); 
	
 IF P_CUSTDOC_ID IS NOT NULL THEN	
	lc_error_location:='  Custdoc Id is not null ';
	    
	SELECT c_ext_attr3 --delivery_method,				
	  INTO ln_delivery_method
	  FROM xx_cdh_cust_acct_ext_b   
	 WHERE attr_group_id = ln_attr_group_id   
	   AND c_ext_attr1   = 'Consolidated Bill' --Document_Type
	   AND c_ext_attr2   = 'Y'                 --paydoc_ind
	   AND c_ext_attr16  = 'COMPLETE' 
       AND c_ext_attr3   = 'ePDF'       
	   AND n_ext_attr2   = p_custdoc_id 	   
	   AND TRUNC(SYSDATE) BETWEEN d_ext_attr1 AND NVL(d_ext_attr2,TRUNC(SYSDATE))
	   AND ROWNUM        = 1; 		   
	
		IF  ln_delivery_method='ePDF' THEN		
			lc_error_location:=' Custdoc_id is not null and Cust_account_id is not null and delivery_method is ePDF ';
			lc_cons_msg_bcc := xx_ar_ebl_common_util_pkg.get_cons_msg_bcc(p_custdoc_id,p_cust_account_id,p_billing_number);
		ELSE
			lc_cons_msg_bcc:='X';		
		END IF;	
	    RETURN(lc_cons_msg_bcc);	
 ELSE
	 lc_error_location:=' Getting Custdoc Id and delivery method ';
    IF p_cust_account_id IS NOT NULL 
    THEN  
        SELECT n_ext_attr2 --p_cust_doc_id
		      ,c_ext_attr3 --delivery_method,				
          INTO ln_custdoc_id
		      ,ln_delivery_method
          FROM xx_cdh_cust_acct_ext_b   
         WHERE 1 = 1 
           AND attr_group_id = ln_attr_group_id 
           AND c_ext_attr1   = 'Consolidated Bill' --Document_Type
           AND c_ext_attr2   = 'Y' --paydoc_ind
           AND c_ext_attr16  = 'COMPLETE'
		   AND c_ext_attr3   = 'ePDF'
           AND cust_account_id = p_cust_account_id            
           AND TRUNC(SYSDATE) BETWEEN d_ext_attr1 AND NVL(d_ext_attr2,TRUNC(SYSDATE))
		   AND ROWNUM        = 1;
		fnd_file.put_line(fnd_file.log , 'p_cust_doc_id is '||ln_custdoc_id||' delivery_method is '||ln_delivery_method);   
		
		IF ln_custdoc_id IS NOT NULL AND ln_delivery_method='ePDF' THEN		
		lc_error_location:=' Getting Bill complete message for ePDF delivery Method ';
		lc_cons_msg_bcc:=xx_ar_ebl_common_util_pkg.get_cons_msg_bcc(ln_custdoc_id,p_cust_account_id,p_billing_number);
		ELSE
		lc_cons_msg_bcc:='X';		
		END IF;
	  RETURN(lc_cons_msg_bcc);
	ELSE 
      lc_cons_msg_bcc:='X';
	  RETURN(lc_cons_msg_bcc);
    END IF; 
	
 END IF;	
 EXCEPTION		
	WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
	lc_cons_msg_bcc:='X';
	RETURN(lc_cons_msg_bcc);     
 END GET_CONS_MSG_BCC;
 
 --+=============================================================================================+
  ---|    Name : GET_PAYDOC_FLAG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	  
  
FUNCTION get_paydoc_flag (p_cust_doc_id IN NUMBER,p_cust_account_id IN NUMBER)     
RETURN VARCHAR2 
IS 
ln_pay_doc       NUMBER      	:=  0;
lc_paydoc_flag   VARCHAR2(1) 	:= 'N';
ln_custdoc_id    NUMBER	 		:=  0;
ln_attr_group_id NUMBER;
BEGIN 
  SELECT attr_group_id
	INTO ln_attr_group_id
	FROM ego_attr_groups_v
   WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
	 AND attr_group_name = 'BILLDOCS'; 
	 
	IF p_cust_doc_id IS NOT NULL THEN
      SELECT COUNT(1)
		INTO ln_pay_doc
		FROM xx_cdh_cust_acct_ext_b b
	   WHERE b.n_ext_attr2   = p_cust_doc_id
		 AND b.attr_group_id = ln_attr_group_id                      
		 AND b.c_ext_attr1   ='Consolidated Bill'
		 AND b.c_ext_attr2   = 'Y' 
		 AND b.c_ext_attr16  = 'COMPLETE'
		 AND b.c_ext_attr3   = 'ePDF'
		 AND ROWNUM          = 1
		 AND TRUNC(SYSDATE) BETWEEN B.D_EXT_ATTR1 AND NVL(B.D_EXT_ATTR2,TRUNC(SYSDATE));
		
		IF ln_pay_doc = 1 THEN 
		lc_paydoc_flag := 'Y'; 
		ELSE 
        lc_paydoc_flag := 'N'; 
		END IF;
		
		RETURN(lc_paydoc_flag);
	ELSE
			SELECT COUNT(1)
			  INTO ln_pay_doc
			  FROM xx_cdh_cust_acct_ext_b   
			 WHERE 1 = 1 
			   AND attr_group_id = ln_attr_group_id 
			   AND c_ext_attr1   = 'Consolidated Bill' --Document_Type
			   AND c_ext_attr2   = 'Y' --paydoc_ind
			   AND c_ext_attr16  = 'COMPLETE'
			   AND cust_account_id = p_cust_account_id 
			   AND c_ext_attr3   = 'ePDF'			
			   AND TRUNC(SYSDATE) BETWEEN d_ext_attr1 AND NVL(d_ext_attr2,TRUNC(SYSDATE))
			   AND ROWNUM        = 1;
		   
			IF ln_pay_doc = 1 THEN 
			lc_paydoc_flag := 'Y'; 
			ELSE 
			lc_paydoc_flag := 'N'; 
			END IF;

			RETURN(lc_paydoc_flag);
	
	END IF;	
EXCEPTION WHEN OTHERS THEN 
Fnd_File.Put_Line(Fnd_File.Log,'Error while returning l_pod_blurb_msg in get_paydoc_flag : '||SQLERRM);
	lc_paydoc_flag := 'N'; 
	RETURN(lc_paydoc_flag);
END get_paydoc_flag; 

--+=============================================================================================+
  ---|    Name : GET_POD_MSG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
  
  
  FUNCTION get_pod_msg (p_cust_account_id IN NUMBER , p_customer_trx_id IN NUMBER , p_cust_doc_id IN NUMBER )   
    RETURN VARCHAR2 
    As	
    lc_pod_blurb_msg VARCHAR2(1000):= NULL;
    ln_pod_cnt       NUMBER :=0; 
	ln_pod_tab_cnt   NUMBER :=0; 
	ln_pay_doc       NUMBER :=0; 
	ln_attr_group_id  NUMBER;
	Begin	
      
	 ln_pod_cnt      := 0;	
	 ln_pod_tab_cnt	 := 0;
	 ln_pay_doc      := 0; 
	 
	    SELECT attr_group_id
		  INTO ln_attr_group_id
		  FROM ego_attr_groups_v
	     WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
		   AND attr_group_name = 'BILLDOCS';
		
		SELECT COUNT(1) 
		  INTO ln_pod_cnt
		  FROM hz_customer_profiles HCP
		 WHERE HCP.cust_account_id = p_cust_account_id	
		   AND HCP.site_use_id        IS NULL
		   AND Hcp.Status              = 'A'
		   AND HCP.attribute6         IN ('Y','P');
		   
		   
		SELECT COUNT(1)
		  INTO ln_pod_tab_cnt
		  FROM Xx_Ar_Ebl_Pod_Dtl
		 WHERE Customer_Trx_Id = p_customer_trx_id
		   AND( Pod_Image        IS NOT NULL
		    OR Delivery_Date     IS NOT NULL		
		    OR consignee         IS NOT NULL); 	   
		
	IF p_cust_doc_id IS NOT NULL THEN
		SELECT COUNT(1)
		  INTO ln_pay_doc
		  FROM xx_cdh_cust_acct_ext_b
		 WHERE n_ext_attr2  = p_cust_doc_id
		   AND c_ext_attr2  = 'Y' 
		   AND c_ext_attr16 = 'COMPLETE'
		   AND c_ext_attr3  = 'ePDF';
	ELSE 
		SELECT COUNT(1)
		  INTO ln_pay_doc
		  FROM xx_cdh_cust_acct_ext_b   
		 WHERE attr_group_id = ln_attr_group_id 
		   AND c_ext_attr1   = 'Consolidated Bill' --Document_Type
		   AND c_ext_attr2   = 'Y' --paydoc_ind
		   AND c_ext_attr16  = 'COMPLETE'
		   AND c_ext_attr3   = 'ePDF'
		   AND cust_account_id = p_cust_account_id            
		   AND TRUNC(SYSDATE) BETWEEN d_ext_attr1 AND NVL(d_ext_attr2,TRUNC(SYSDATE))
		   AND ROWNUM = 1;
		   
	END IF;	
	
    IF ln_pod_cnt >= 1 AND ln_pod_tab_cnt = 0 AND ln_pay_doc = 1 THEN 
	    lc_pod_blurb_msg:= 'Delivery Details Not Available.';
    ELSE 
     lc_pod_blurb_msg := NULL;
    END IF;    

	RETURN(lc_pod_blurb_msg);		   
   
	EXCEPTION	
	WHEN OTHERS	THEN
	Fnd_File.Put_Line(Fnd_File.Log,'Error while returning l_pod_blurb_msg in GET_POD_MSG : '||Sqlerrm);
	lc_pod_blurb_msg := NULL;
	RETURN(lc_pod_blurb_msg);
  
  END get_pod_msg;

END XX_AR_REPRINT_SUMMBILL;

/
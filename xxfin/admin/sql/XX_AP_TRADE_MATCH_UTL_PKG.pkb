CREATE OR REPLACE PACKAGE BODY  XX_AP_TRADE_MATCH_UTL_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_TRADE_MATCH_UTL_PKG.pkb                            |
-- | Description :  AP Trade Match Util Package                              |
-- | RICE ID   :  E3522_OD Trade Match Foundation                            |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       30-MAY-2017 Paddy Sanjeevi     Initial version                 |
-- |1.1       07-DEC-2017 Paddy Sanjeevi     Modified for NAIT20608          |
-- |1.1       12-Dec-2017 Paddy Sanjeevi     Added xx_qty_hold_amt function  |
-- |1.2       27-Dec-2017 Paddy Sanjeevi     Modified xx_qty_hold_amt        |
-- |1.3       05-JUN-2018 Priyam Parmar      Code modified for NAIT-37732    |
-- |1.4       19-JUN-2018 Madhan Sanjeevi    Code Modified for NAIT-41529    |
-- |1.5       20-JUN-2018 Vivek Kumar        Added For NAIT-40533            |
-- +=========================================================================+
AS
-- +======================================================================+
-- | Name        :  xx_get_vendor_assistant                               |
-- | Description :  This function returns vendor assistant name           |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_code                                                |
-- |                                                                      |
-- | Returns     :  vendor assistant name                                 |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_get_vendor_assistant(p_code in varchar2) Return varchar2
is
v_name varchar2(100);
begin
   select tv.target_value2
    into v_name
  from  
      xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
where td.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS' 
  AND tv.TRANSLATE_ID  = td.TRANSLATE_ID
  AND tv.enabled_flag='Y'
  AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)  
  AND tv.target_value1=p_code;
  return(v_name);
exception 
 when others then
   return(v_name);
end xx_get_vendor_assistant ;
-- +====================================================================================+
-- | Name        :  xx_ap_release_hold                                                    |
-- | Description :  Procedure used to release holds                                       |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id,p_qty_rel_code,p_price_rel_code                          |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_ap_release_hold(p_invoice_id IN NUMBER, p_qty_rel_code IN VARCHAR2, p_price_rel_code IN VARCHAR2)
IS  
  CURSOR c_qty_hold IS
  SELECT invoice_id,
         line_location_id,
         hold_lookup_code
    FROM ap_holds_all
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code IN ('MAX QTY ORD','QTY ORD','QTY REC','AMT ORD','MAX AMT REC','MAX AMT ORD','AMT REC')
     AND release_lookup_code IS NULL;

  CURSOR c_price_hold IS
  SELECT invoice_id,
         line_location_id,
         hold_lookup_code
    FROM ap_holds_all
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code IN ('OD MAX PRICE','OD Favorable','PRICE','LINE VARIANCE','DIST VARIANCE')
     AND release_lookup_code IS NULL;
     
BEGIN
  
  IF p_qty_rel_code IS NOT NULL THEN

  FOR cur IN c_qty_hold LOOP
  
    UPDATE ap_holds_all
       SET release_lookup_code = p_qty_rel_code,
           release_reason = (SELECT description
                               FROM ap_lookup_codes
                              WHERE lookup_type = 'HOLD CODE'
                                AND lookup_code = p_qty_rel_code),
           last_updated_by = FND_GLOBAL.user_id,
           last_update_date = SYSDATE,
           last_update_login = FND_GLOBAL.login_id,
           status_flag='R'           
     WHERE invoice_id = p_invoice_id
       AND line_location_id=cur.line_location_id
       AND release_lookup_code IS NULL
       AND hold_lookup_code = cur.hold_lookup_code;
  
  END LOOP;
  COMMIT;

  END IF; 
  
  IF p_price_rel_code IS NOT NULL THEN
  
  FOR cur IN c_price_hold LOOP
  
    UPDATE ap_holds_all
       SET release_lookup_code = p_price_rel_code,
           release_reason = (SELECT description
                               FROM ap_lookup_codes
                              WHERE lookup_type = 'HOLD CODE'
                                AND lookup_code = p_price_rel_code),
           last_updated_by = FND_GLOBAL.user_id,
           last_update_date = SYSDATE,
           last_update_login = FND_GLOBAL.login_id,
           status_flag='R'
     WHERE invoice_id = p_invoice_id
       AND line_location_id=cur.line_location_id
       AND release_lookup_code IS NULL
       AND hold_lookup_code = cur.hold_lookup_code;
  
  END LOOP;
  COMMIT;
  
  END IF;
END xx_ap_release_hold;
-- +====================================================================================+
-- | Name        :  xx_ap_freight_invoice                                                 |
-- | Description :  Function used to find type FREIGHT                                    |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id                                                          |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION xx_ap_freight_invoice(p_invoice_id NUMBER) RETURN VARCHAR2 
IS
ln_freight 	NUMBER:=0;
v_freight VARCHAR2(1);
BEGIN
 SELECT COUNT(1)
   INTO ln_freight
   FROM ap_holds_all
  WHERE invoice_id=p_invoice_id
    AND hold_lookup_code like 'OD Max Freight%'
	AND release_lookup_code IS NULL;
 IF ln_freight<>0 THEN
    v_freight:='Y';
 ELSE
    v_freight:='N';
 END IF;
 RETURN v_freight;
EXCEPTION
 WHEN others THEN
   v_freight:='N';
   return(v_Freight);
END xx_ap_freight_invoice;
-- +====================================================================================+
-- | Name        :  xx_primary_vendor_name                                                |
-- | Description :  Function used to find primary vendor                                  |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_vend_site_id                                                        |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION xx_primary_vendor_name(p_vend_site_id IN NUMBER) RETURN VARCHAR2
IS
v_vendor_name VARCHAR2(240);
BEGIN
  SELECT vendor_name
    INTO v_vendor_name
    FROM ap_suppliers sup,
         ap_supplier_sites_all site
   WHERE (    site.attribute9 = LPAD(p_vend_site_id,10,'0')
          OR (site.vendor_site_id = p_vend_site_id AND site.attribute9 IS NULL)
         )         
     AND sup.vendor_id=site.vendor_id
     AND rownum<2;
     RETURN v_vendor_name;
EXCEPTION 
  WHEN others THEN 
    v_vendor_name:=NULL;
    RETURN v_vendor_name;    
END xx_primary_vendor_name;
-- +====================================================================================+
-- | Name        :  xx_ap_update_due_date                                                 |
-- | Description :  Procedure used to update due date                                     |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id,p_terms_date,p_terms_id                                  |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_ap_update_due_date(p_invoice_id IN NUMBER, p_terms_date IN date,p_terms_id IN number)
IS
  l_due_date           DATE;
  l_disc_due_date      DATE;
  v_pay_type           VARCHAR2(1):=NULL;
BEGIN

  BEGIN
   SELECT DECODE(SIGN(instr(name,'/')),0,'N',1,'D') 
     INTO v_pay_type
     FROM ap_terms
    WHERE term_id=p_terms_id;
  EXCEPTION 
    WHEN others THEN 
      v_pay_type:=NULL;
  END;
   
    fnd_file.put_line(fnd_file.log, 'Get Term Id ...'|| p_terms_id);  ---ADDED FOR NAIT-40533
	fnd_file.put_line(fnd_file.log, 'Get Terms Date ...'|| p_terms_date);  --ADDED FOR NAIT-40533
   
  BEGIN
     SELECT NVL(fixed_date,
           (DECODE(ap_terms_lines.due_days,
                   NULL,TO_DATE(TO_CHAR(LEAST(NVL(ap_terms_lines.due_day_of_month,32),
                                              TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(P_Terms_Date,
                                                                          NVL(ap_terms_lines.due_months_forward,0) +
                                                                          DECODE(ap_terms.due_cutoff_day, NULL, 0,
                                                                                 DECODE(GREATEST(NVL(ap_terms.due_cutoff_day, 32),
                                                                                        TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))),
                                                                                        TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))
                                                                                 , 1, 0)))), 'DD')))) || '-' ||
                                   TO_CHAR(ADD_MONTHS(P_Terms_Date,
                 NVL(ap_terms_lines.due_months_forward,0) +
                   DECODE(ap_terms.due_cutoff_day, NULL, 0,
               DECODE(GREATEST(NVL(ap_terms.due_cutoff_day, 32),
                 TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))),
                 TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD')), 1, 0))),
            'MON-RR'),'DD-MON-RR'),  /*bugfix:5647464 */
            trunc(P_Terms_Date) /*bug 8522014*/ + NVL(ap_terms_lines.due_days,0))))
        ,DECODE(ap_terms_lines.discount_days,
            NULL,
        DECODE(ap_terms_lines.discount_day_of_month, NULL, NULL,
                  TO_DATE(TO_CHAR(LEAST(NVL(ap_terms_lines.discount_day_of_month,32),
                  TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS
                  (P_Terms_Date, NVL(ap_terms_lines.discount_months_forward,0) +
                   DECODE(ap_terms.due_cutoff_day, NULL, 0,
                    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
                     TO_NUMBER(TO_CHAR(LAST_DAY(P_Terms_Date), 'DD'))),
                     TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))),
                     TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))
                     , 1, 0)))), 'DD')))) || '-' ||
                     TO_CHAR(ADD_MONTHS(P_Terms_Date,
                     NVL(ap_terms_lines.discount_months_forward,0) +
                    DECODE(ap_terms.due_cutoff_day, NULL, 0,
                    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
                     TO_NUMBER(TO_CHAR(LAST_DAY(P_Terms_Date),'DD'))),
                     TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD'))),
                     TO_NUMBER(TO_CHAR(P_Terms_Date, 'DD')), 1, 0))),
        'MON-RR'),'DD-MON-RR')
              ),
                P_Terms_Date + NVL(ap_terms_lines.discount_days,0)
          )     
      INTO l_due_date,l_disc_due_date
      FROM ap_terms,
           ap_terms_lines
     WHERE ap_terms.term_id = P_Terms_Id
      AND  ap_terms.term_id = ap_terms_lines.term_id
      AND  ap_terms_lines.sequence_num = 1;
	  
	 fnd_file.put_line(fnd_file.log, 'Discount Date ...'|| l_disc_due_date);  --ADDED FOR NAIT-40533
	 fnd_file.put_line(fnd_file.log, 'Due Date ...'|| l_due_date);  --ADDED FOR NAIT-40533
	 
  EXCEPTION
    WHEN others THEN
     l_due_date:=NULL;
     l_disc_due_date:=NULL;  
	 
	 fnd_file.put_line(fnd_file.log, 'Going in the exception while assigning due Date as NULL'); --- ADDED FOR NAIT-40533
	
  END;

  UPDATE ap_invoices_all  
     SET terms_id=p_terms_id
   WHERE invoice_id=p_invoice_id;     
  
  UPDATE ap_payment_schedules_all 
     SET due_date=l_due_date,
         discount_date=DECODE(v_pay_type,'D',l_disc_due_date,'N',NULL)
   WHERE invoice_id=p_invoice_id;
   
  COMMIT;
  
EXCEPTION
 WHEN others THEN
  dbms_output.put_line('Error :'|| SQLERRM);
END xx_ap_update_due_date;         
-- +====================================================================================+
-- | Name        :  xx_ap_update_pay_method                                               |
-- | Description :  Procedure used to update pay method                                   |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id,p_pay_method                                             |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+

PROCEDURE xx_ap_update_pay_method(p_invoice_id IN NUMBER, p_pay_method IN VARCHAR2)
IS
 BEGIN
   UPDATE ap_invoices_all 
     SET payment_method_code=p_pay_method
   WHERE invoice_id=p_invoice_id;
   --NAIT-41529 Code Modification Starts Here
   UPDATE ap_payment_schedules_all  
     SET payment_method_code=p_pay_method
   WHERE invoice_id=p_invoice_id;
   
   IF p_pay_method = 'EFT'
   THEN
   
   BEGIN
       UPDATE AP_PAYMENT_SCHEDULES_ALL  aps
       SET EXTERNAL_BANK_ACCOUNT_ID = (SELECT IEBA.EXT_BANK_ACCOUNT_ID
                                     FROM iby_ext_bank_accounts ieba,
                                          iby_external_payees_all iepa,
                                          iby_pmt_instr_uses_all ipiua,
                                          ap_suppliers apss,
                                          ap_supplier_sites_all assa,
                                          hz_parties hp1,
                                          ap_invoices_all aia,
                                          AP_PAYMENT_SCHEDULES_all apsa
                                    WHERE ipiua.instrument_id    =ieba.ext_bank_account_id
                                    AND   assa.VENDOR_SITE_ID    =iepa.SUPPLIER_SITE_ID
                                    AND ipiua.ext_pmt_party_id   =iepa.ext_payee_id
                                    AND assa.VENDOR_ID           =APSS.VENDOR_ID
                                    AND IPIUA.INSTRUMENT_TYPE    ='BANKACCOUNT'
                                    AND IPIUA.PAYMENT_FLOW       ='DISBURSEMENTS'
                                    AND ieba.branch_id               =hp1.party_id
                                    AND aia.vendor_id                =apss.vendor_id
                                    AND apss.vendor_id                =assa.vendor_id
                                    AND assa.vendor_site_id          =aia.vendor_site_id 
                                    AND apsa.invoice_id              =aia.invoice_id
                                    AND aia.invoice_id               = aps.invoice_id
                                    AND sysdate between NVL(ipiua.start_date,sysdate) AND  NVL(ipiua.end_Date,sysdate))
                                    ,aps.LAST_UPDATED_BY = -1
                                    ,aps.LAST_UPDATE_DATE =SYSDATE
                                   WHERE aps.INVOICE_ID = p_invoice_id
                                   AND APS.EXTERNAL_BANK_ACCOUNT_ID IS NULL;
            EXCEPTION
                WHEN others THEN
                      dbms_output.put_line('Error :'|| SQLERRM); 
            END;
		ELSIF p_pay_method = 'CHECK' THEN
		    UPDATE ap_payment_schedules_all  
            SET EXTERNAL_BANK_ACCOUNT_ID = NULL
            WHERE invoice_id=p_invoice_id;
        END IF;
--NAIT-41529 Code Modification Ends Here                                       
COMMIT;

EXCEPTION
  WHEN others THEN
   dbms_output.put_line('Error :'|| SQLERRM);  
END xx_ap_update_pay_method;
-- +====================================================================================+
-- | Name        :  xx_ap_update_pay_group                                                |
-- | Description :  Procedure used to update pay group                                    |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id,p_pay_group                                             |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_ap_update_pay_group(p_invoice_id IN NUMBER, p_pay_group IN VARCHAR2)
IS
BEGIN
  UPDATE ap_invoices_all 
     SET pay_group_lookup_code=p_pay_group
   WHERE invoice_id=p_invoice_id;
  COMMIT;   
EXCEPTION
  WHEN others THEN
   dbms_output.put_line('Error :'|| SQLERRM);    
END xx_ap_update_pay_group;
-- +====================================================================================+
-- | Name        :  xx_ap_update_pay_due_date                                             |
-- | Description :  Procedure used to update pay due date                                 |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id,p_due_date                                               |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_ap_update_pay_due_date(p_invoice_id IN NUMBER, p_due_date IN date)
IS
BEGIN
  UPDATE ap_payment_schedules_all 
     SET due_date=p_due_date
   WHERE invoice_id=p_invoice_id;
  COMMIT;   
EXCEPTION
  WHEN others THEN
   dbms_output.put_line('Error :'|| SQLERRM);    
END xx_ap_update_pay_due_date;
-- +====================================================================================+
-- | Name        :  xx_upd_invoice_released                                               |
-- | Description :  Procedure used to mass update invoices release holds                  |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  invoice_in                                                            |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
procedure xx_upd_invoice_released(invoice_in IN XX_AP_TR_INV_ARRAY)  
IS
BEGIN
  FOR i IN 1..invoice_in.count
  LOOP
    UPDATE ap_invoices_all
    SET validation_request_id=NULL
	 ----------Code added to populate DFF release date  NAIT-37732 
    ,attribute4=to_char(sysdate,'DD-MON-YYYY')
    WHERE invoice_num      =invoice_in(i);

  END LOOP;

EXCEPTION
WHEN OTHERS THEN
  null;
END;
-- +====================================================================================+
-- | Name        :  xx_upd_vendorassistant                                                |
-- | Description :  Procedure used to update vendor assistants                            |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  invoice_in                                                            |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
procedure xx_upd_vendorassistant(site_id IN XX_AP_TR_INV_ARRAY)
  
IS
BEGIN
 dbms_output.put_line('starting');
 dbms_output.put_line(' site id'|| site_id.count);
  FOR i IN 3..site_id.count
  LOOP
    dbms_output.put_line(' site id' || site_id(i));
    UPDATE ap_supplier_sites_all
    SET attribute6=site_id(2)
    WHERE vendor_site_code      =site_id(i) and attribute6=site_id(1);
  END LOOP;

EXCEPTION
WHEN OTHERS THEN
  null;
END;
-- +====================================================================================+
-- | Name        :  xx_upd_paymentterms                                                   |
-- | Description :  Procedure used to update payment terms                                |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  invoice_in                                                            |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_upd_paymentterms(invoice_in XX_AP_TR_INV_ARRAY) IS

   CURSOR cur_payment_term_date(p_invoice_id in varchar2) IS
    SELECT terms_date 
      FROM ap_invoices_all where invoice_id=p_invoice_id;
    p_term_date date;
BEGIN

   IF invoice_in(1)<>'NA' then
       FOR i in 5..invoice_in.count LOOP
           OPEN  cur_payment_term_date(invoice_in(i));
           FETCH  cur_payment_term_date into p_term_date;
           CLOSE  cur_payment_term_date;
           xx_ap_update_due_date(invoice_in(i),p_term_date,invoice_in(1));
       END LOOP;
   END IF;

   IF invoice_in(2)<>'NA' THEN
      FOR i in 5..invoice_in.count LOOP
          xx_ap_update_pay_due_date(invoice_in(i),to_date(invoice_in(2),'YYYY-MM-DD'));
   END LOOP;
   END IF;

   IF invoice_in(3) <> 'NA' THEN
      FOR i in 5..invoice_in.count LOOP
          xx_ap_update_pay_method(invoice_in(i),invoice_in(3));
      END LOOP;
   END IF;

   IF invoice_in(4)<>'NA' THEN
      FOR i in 5..invoice_in.count LOOP
          xx_ap_update_pay_group(invoice_in(i),invoice_in(4));
      END LOOP;
    END IF;
END;

-- +====================================================================================+
-- | Name        :  xx_upd_mass_releasehold                                               |
-- | Description :  Procedure used to update mass release holds                           |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  invoice_in                                                            |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE xx_upd_mass_releasehold(invoice_in IN XX_AP_TR_INV_ARRAY)

IS
 invoice_num VARCHAR2(500);
 qtyhold VARCHAR2(500);
 pricehold VARCHAR2(500);
 secondpart VARCHAR2(1000);
 i NUMBER;
BEGIN
  i :=1;
  WHILE i <= invoice_in.count
  LOOP
  
        IF invoice_in(i+1) = 'NA' THEN
           qtyhold:=NULL;
        ELSE
           qtyhold:=invoice_in(i+1);
        END IF;
        IF invoice_in(i+2) ='NA' THEN
           pricehold:=NULL;
        ELSE
           pricehold:=invoice_in(i+2);
        END IF;
        dbms_output.put_line('invoice num'||invoice_in(i)||'qty hold reason'||qtyhold||'price hold reason'||pricehold);
        BEGIN
             xx_ap_release_hold(invoice_in(i),qtyhold,pricehold);
        EXCEPTION
        WHEN OTHERS THEN
             dbms_output.put_line('Exception invoice_num');
        END;
    i:=i+3;
  END LOOP;

EXCEPTION
WHEN OTHERS THEN
  NULL;
END xx_upd_mass_releasehold;

-- +======================================================================================+
-- | Name        :  xxod_tdmatch_price                                                    |
-- | Description :  Function to get the price hold amount for the invoice                 |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id                                                          |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- +======================================================================================+
FUNCTION xxod_tdmatch_price(p_invoice_id in NUMBER) 
RETURN NUMBER 
IS

CURSOR C1 
IS
SELECT l.invoice_id,
	   l.inventory_item_id,
	   l.po_line_id,
	   l.po_header_id,
	   l.quantity_invoiced,
	   l.unit_price inv_price,
	   pol.unit_price po_price
  FROM po_lines_all pol,
	   ap_invoice_lines_all	l
 WHERE l.invoice_id=p_invoice_id
   AND line_type_lookup_code='ITEM'
   AND pol.po_line_id=l.po_line_id
   AND EXISTS (SELECT 'x'
                 FROM ap_holds_all h
                WHERE h.invoice_id = l.invoice_id
                  AND h.line_location_id = l.po_line_location_id
                  AND h.hold_lookup_code like 'PRICE%'                
                  AND h.release_lookup_code IS NULL
	 	      ); 

ln_available_qty 		NUMBER;   			  
ln_price_hold_amount 	NUMBER:= 0;			  

BEGIN
  FOR cur IN C1 LOOP
    ln_available_qty:=XX_AP_TR_UI_ACTION_PKG.get_unbilled_qty(cur.po_header_id,cur.po_line_id,cur.inventory_item_id,cur.invoice_id);
	IF ln_available_qty>cur.quantity_invoiced THEN
	   ln_available_qty:=cur.quantity_invoiced;
	END IF;
    ln_price_hold_amount:=ln_price_hold_amount+ROUND(((cur.inv_price-cur.po_price)*ln_available_qty),2);
  END LOOP;
  RETURN ln_price_hold_amount;
EXCEPTION
  WHEN others then 
    RETURN 0;
END xxod_tdmatch_price;

-- +======================================================================================+
-- | Name        :  xx_price_hold_amt                                                     |
-- | Description :  Function to get the price hold amount for the invoice line            |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id, p_line_number                                           |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- +======================================================================================+
FUNCTION xx_price_hold_amt(p_invoice_id in number,p_line_number IN NUMBER)
RETURN NUMBER 
IS

CURSOR C1 
IS
SELECT l.invoice_id,
	   l.inventory_item_id,
	   l.po_line_id,
	   l.po_header_id,
	   l.quantity_invoiced,
	   l.unit_price inv_price,
	   pol.unit_price po_price
  FROM po_lines_all pol,
	   ap_invoice_lines_all	l
 WHERE l.invoice_id=p_invoice_id
   AND l.line_number=p_line_number
   AND l.line_type_lookup_code='ITEM'   
   AND pol.po_line_id=l.po_line_id
   AND EXISTS (SELECT 'x'
                 FROM ap_holds_all h
                WHERE h.invoice_id = l.invoice_id
                  AND h.line_location_id = l.po_line_location_id
                  AND h.hold_lookup_code like 'PRICE%'                
                  AND h.release_lookup_code IS NULL
	 	      ); 

ln_available_qty 		NUMBER;   			  
ln_price_hold_amount 	NUMBER:= 0;			  

BEGIN
  FOR cur IN C1 LOOP
    ln_available_qty:=XX_AP_TR_UI_ACTION_PKG.get_unbilled_qty(cur.po_header_id,cur.po_line_id,cur.inventory_item_id,cur.invoice_id);
	IF ln_available_qty>cur.quantity_invoiced THEN
	   ln_available_qty:=cur.quantity_invoiced;
	END IF;
    ln_price_hold_amount:=ROUND(((cur.inv_price-cur.po_price)*ln_available_qty),2);
  END LOOP;
  RETURN ln_price_hold_amount;
EXCEPTION
  WHEN others then 
    RETURN 0;
END xx_price_hold_amt;

-- +======================================================================================+
-- | Name        :  xxod_tdmatch_quantity                                                 |
-- | Description :  Function to get qty hold amount for the invoice                       |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id                                                          |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION xxod_tdmatch_quantity(p_invoice_id in number) 
RETURN NUMBER 
IS
CURSOR C1 
IS
SELECT l.invoice_id,
	   l.inventory_item_id,
	   l.po_line_id,
	   l.po_header_id,
	   l.quantity_invoiced,
	   l.unit_price
  FROM ap_invoice_lines_all	l
 WHERE l.invoice_id=p_invoice_id
   AND l.line_type_lookup_code='ITEM'   
   AND EXISTS (SELECT 'x'
                 FROM ap_holds_all h
                WHERE h.invoice_id = l.invoice_id
                  AND h.line_location_id = l.po_line_location_id
                  AND h.hold_lookup_code like 'QTY%'                
                  AND h.release_lookup_code IS NULL
	 	      ); 
   
ln_available_qty 	NUMBER;   
ln_qty_hold_amount 	NUMBER:= 0;

BEGIN
  FOR cur IN C1 LOOP
    ln_available_qty:=XX_AP_TR_UI_ACTION_PKG.get_unbilled_qty(cur.po_header_id,cur.po_line_id,cur.inventory_item_id,cur.invoice_id);
    ln_qty_hold_amount:=ln_qty_hold_amount+ROUND(((cur.quantity_invoiced-ln_available_qty)*cur.unit_price),2);
  END LOOP;
  RETURN ln_qty_hold_amount;
EXCEPTION
  WHEN others then 
    RETURN 0;
END xxod_tdmatch_quantity; 

-- +======================================================================================+
-- | Name        :  xx_qty_hold_amt                                                       |
-- | Description :  Function to get the qty hold amount for the invoice line              |
-- |                                                                                      |
-- | Parameters  :  p_invoice_id, p_line_number                                           |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- +======================================================================================+
 
FUNCTION xx_qty_hold_amt(p_invoice_id in number,p_line_number IN NUMBER)
RETURN NUMBER 
IS

CURSOR C1 
IS
SELECT l.invoice_id,
	   l.inventory_item_id,
	   l.po_line_id,
	   l.po_header_id,
	   l.quantity_invoiced,
	   l.unit_price
  FROM ap_invoice_lines_all	l
 WHERE l.invoice_id=p_invoice_id
   AND l.line_number=p_line_number
   AND l.line_type_lookup_code='ITEM'   
   AND EXISTS (SELECT 'x'
                 FROM ap_holds_all h
                WHERE h.invoice_id = l.invoice_id
                  AND h.line_location_id = l.po_line_location_id
                  AND h.hold_lookup_code like 'QTY%'                
                  AND h.release_lookup_code IS NULL
	 	      ); 
   
ln_available_qty 	NUMBER;   
ln_qty_hold_amount 	NUMBER:= 0;
BEGIN
  FOR cur IN C1 LOOP
    ln_available_qty:=XX_AP_TR_UI_ACTION_PKG.get_unbilled_qty(cur.po_header_id,cur.po_line_id,cur.inventory_item_id,cur.invoice_id);
    ln_qty_hold_amount:=ROUND(((cur.quantity_invoiced-ln_available_qty)*cur.unit_price),2);
  END LOOP;
  RETURN ln_qty_hold_amount;
EXCEPTION
  WHEN others then 
    RETURN 0;
END xx_qty_hold_amt;

END;
/
SHOW ERRORS;
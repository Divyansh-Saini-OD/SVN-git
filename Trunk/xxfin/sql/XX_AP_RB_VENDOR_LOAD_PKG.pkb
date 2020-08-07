SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_AP_RB_VENDOR_LOAD_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_AP_RB_VENDOR_LOAD_PKG                                        |
-- | Description      : This Program will load vendors to iface table from   |
-- |                    stagging table                                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    14-FEB-2012   Bapuji Nanapaneni Initial code                  |
-- +=========================================================================+

PROCEDURE send_error_rpt (p_request_id IN NUMBER,
			  p_email      IN VARCHAR2)
IS

  conn 			utl_smtp.connection;
  p_text		varchar2(2000);
  p_file_name		varchar2(100);
  r 			NUMBER := 0 ;
  v_cnt	 		NUMBER:=0;

  CURSOR C1 IS
  SELECT vendor_name,
	   customer_num,
	   site_address1,
	   site_address2,
	   site_address3,
	   site_city,
	   site_state,
	   site_zip,
	   error_message
   FROM xxfin.XX_AP_RB_VENDOR_STG 
  WHERE request_id=p_request_id
    AND error_flag='Y'
  ORDER by 1;


BEGIN

  SELECT COUNT(1)
    INTO v_cnt
   FROM xxfin.XX_AP_RB_VENDOR_STG 
  WHERE request_id=p_request_id
    AND error_flag='Y';

  IF v_cnt>0 THEN
 
     p_file_name:=TO_CHAR(p_request_id)||'RB_Vendor_int.xls';
     xx_gen_xl_xml.create_excel('XXMER_OUTBOUND',p_file_name) ;

     xx_gen_xl_xml.create_worksheet( 'sheet1');
     xx_gen_xl_xml.create_style( 'sgs1','Courier','green',12,TRUE,p_backcolor => 'LightGray');
     xx_gen_xl_xml.create_style( 'sgs2' , 'Courier', 'blue',10,NULL  );

     -- increase width OF colum b that IS no 2

     xx_gen_xl_xml.set_column_width( 1, 100, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 2, 100, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 3, 150, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 4, 150, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 5, 150, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 6,  80, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 7,  80, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 8,  50, 'sheet1' );
     xx_gen_xl_xml.set_column_width( 9, 500, 'sheet1' );

     xx_gen_xl_xml.set_row_height( 1, 30 ,'sheet1' );

     -- writing the headers
     r := r+1 ;
     xx_gen_xl_xml.write_cell_char( r,1, 'sheet1', 'Vendor Name' ,'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,2, 'sheet1', 'Customer Number' ,'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,3, 'sheet1', 'Site Address1', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,4, 'sheet1', 'Site Address2', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,5, 'sheet1', 'Site Address3', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,6, 'sheet1', 'Site City', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,7, 'sheet1', 'Site State', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,8, 'sheet1', 'Site ZIP', 'sgs1' );
     xx_gen_xl_xml.write_cell_char( r,9, 'sheet1', 'Error Message', 'sgs1' ); 

     FOR CUR IN C1 LOOP 
    
        r := r+1 ;

        xx_gen_xl_xml.write_cell_char( r,1, 'sheet1' , cur.vendor_name, 'sgs2'  );
        xx_gen_xl_xml.write_cell_char( r,2, 'sheet1' , cur.customer_num, 'sgs2' );
        xx_gen_xl_xml.write_cell_char( r,3, 'sheet1' , cur.site_address1, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,4, 'sheet1' , cur.site_address2, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,5, 'sheet1' , cur.site_address3, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,6, 'sheet1' , cur.site_city, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,7, 'sheet1' , cur.site_state, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,8, 'sheet1' , cur.site_zip, 'sgs2');
        xx_gen_xl_xml.write_cell_char( r,9, 'sheet1' , cur.error_message, 'sgs2');

     END LOOP ;
 
     xx_gen_xl_xml.close_file ;


      p_text:='      OD: AP Rebate Customers As Suppliers Load to Iface      '||chr(10);
      p_text:=p_text||chr(10);
      p_text:=p_text||'Run Date     :'||to_char(sysdate,'dd-mon-rr hh24:mi:ss')||chr(10);
      p_text:=p_text||chr(10);
      p_text:=p_text||'Program Name :OD: AP Rebate Customers As Suppliers Load to Iface'||chr(10);
      p_text:=p_text||'Request ID   :'||to_char(p_request_id)||chr(10);
      p_text:=p_text||chr(10);
      p_text:=p_text||'Please see the attachment for the details';

      conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'Finance@officedepot.com',
	  	        recipients => p_email,
			  cc_recipients=>NULL,
		        subject => 'OD: AP Rebate Customers As Suppliers Load to Iface',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

      xx_pa_pb_mail.xx_attach_excel(conn,p_file_name);
      xx_pa_pb_mail.end_attachment(conn => conn);
      xx_pa_pb_mail.attach_text(conn => conn,
  		                      data => p_text,
		                      mime_type => 'multipart/html');
      xx_pa_pb_mail.end_mail( conn => conn );

  END IF;

END send_error_rpt;

PROCEDURE LOAD_VENDORS( x_retcode          OUT NOCOPY NUMBER
                      , x_errbuf           OUT NOCOPY VARCHAR2
                      , p_email            IN         VARCHAR2
                      ) IS

CURSOR c_vendor IS
SELECT UPPER(TRIM(vendor_name))   vendor_name
     , TRIM(customer_num)         customer_num
     , UPPER(TRIM(site_address1)) site_address1
     , UPPER(TRIM(site_address2)) site_address2
     , UPPER(TRIM(site_address3)) site_address3
     , UPPER(TRIM(site_city))     site_city
     , UPPER(TRIM(site_state))    site_state
     , REPLACE(UPPER(TRIM(site_zip)),'-',' ')      site_zip
     , rowid                      row_id
  FROM xx_ap_rb_vendor_stg
 WHERE NVL(process_flag,'N') != 'Y';


 CURSOR c1 IS
 SELECT site_zip,rowid prowid
   FROM xx_ap_rb_vendor_stg
  WHERE NVL(process_flag,'N') != 'Y';

/*Local Variables Declaration */
lc_org_code               xx_fin_translatevalues.target_value1%TYPE;
lc_supplier_type          xx_fin_translatevalues.target_value2%TYPE;
lc_one_time               xx_fin_translatevalues.target_value3%TYPE;
lc_invoice_match_option   xx_fin_translatevalues.target_value4%TYPE;
lc_payment_term           xx_fin_translatevalues.target_value5%TYPE;
lc_terms_basis_date       xx_fin_translatevalues.target_value6%TYPE;
lc_payment_method         xx_fin_translatevalues.target_value7%TYPE;
lc_ship_to_location       xx_fin_translatevalues.target_value8%TYPE;
lc_bill_to_location       xx_fin_translatevalues.target_value9%TYPE;
lc_pay_group              xx_fin_translatevalues.target_value10%TYPE;
lc_invoice_curr           xx_fin_translatevalues.target_value11%TYPE;
lc_payment_curr           xx_fin_translatevalues.target_value12%TYPE;
lc_pay_date_basics        xx_fin_translatevalues.target_value13%TYPE;
lc_site_category          xx_fin_translatevalues.target_value14%TYPE;
lc_site_prefix            xx_fin_translatevalues.target_value15%TYPE;
lc_purchase_site          xx_fin_translatevalues.target_value16%TYPE;
lc_pay_site               xx_fin_translatevalues.target_value17%TYPE;
lc_futher                 xx_fin_translatevalues.target_value18%TYPE;
lc_response_to_queue      xx_fin_translatevalues.target_value19%TYPE;
lc_curr_request           xx_fin_translatevalues.target_value20%TYPE;
ln_vendor_interface_id    ap_suppliers_int.vendor_interface_id%TYPE;
lc_sitecode               ap_supplier_sites_int.vendor_site_code%TYPE;
ln_sent_count             NUMBER := 0;
ln_supp_count             NUMBER := 0;
ln_supp_site_count        NUMBER := 0;
ln_vendor_count           NUMBER := 0;
ln_vendor_iface_count     NUMBER := 0;
ln_v_site_count           NUMBER := 0;
ln_v_site_iface_count     NUMBER := 0;
lc_error_message          VARCHAR2(2000);
ln_ship_location_id       NUMBER;
ln_bill_location_id       NUMBER;
lc_asci_validation        VARCHAR2(4000);
ln_request_id             NUMBER := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
lc_insp_flag              VARCHAR2(1);
lc_rcpt_flag              VARCHAR2(1);
lc_ascii 		  VARCHAR2(10);

BEGIN

    DBMS_OUTPUT.PUT_LINE('BEGINNING OF PROGRAM');
    FND_FILE.PUT_LINE(fnd_file.output,'BEGINNING OF PROGRAM');
    FND_FILE.PUT_LINE(fnd_file.output,'PROGRAM NAME   : '|| 'OD: AP Rebate Customers As Suppliers Load to Iface');
    FND_FILE.PUT_LINE(fnd_file.output,'REQUEST ID     : '|| ln_request_id);
    FND_FILE.PUT_LINE(fnd_file.output,'DATE SUBMITTED : '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));


    BEGIN
      FOR cur IN c1 LOOP
        lc_ascii :=null;
        lc_ascii:=ascii(substr(cur.site_zip,LENGTH(cur.site_zip),(LENGTH(cur.site_zip)-1)));
        IF lc_ascii=13 THEN
           UPDATE xx_ap_rb_vendor_stg
              SET site_zip=SUBSTR(site_zip,1,LENGTH(site_zip)-1)
            WHERE rowid=cur.prowid;
        END IF;
      END LOOP;
    END;
    COMMIT;

    SELECT xftv.target_value1
     , xftv.target_value2
     , xftv.target_value3
     , xftv.target_value4
     , xftv.target_value5
     , xftv.target_value6
     , xftv.target_value7
     , xftv.target_value8
     , xftv.target_value9
     , xftv.target_value10
     , xftv.target_value11
     , xftv.target_value12
     , xftv.target_value13
     , xftv.target_value14
     , xftv.target_value15
     , xftv.target_value16
     , xftv.target_value17
     , xftv.target_value18
     , xftv.target_value19
     , xftv.target_value20
  INTO lc_org_code
     , lc_supplier_type
     , lc_one_time
     , lc_invoice_match_option
     , lc_payment_term
     , lc_terms_basis_date
     , lc_payment_method
     , lc_ship_to_location
     , lc_bill_to_location
     , lc_pay_group
     , lc_invoice_curr
     , lc_payment_curr
     , lc_pay_date_basics
     , lc_site_category
     , lc_site_prefix
     , lc_purchase_site
     , lc_pay_site
     , lc_futher
     , lc_response_to_queue
     , lc_curr_request
  FROM xx_fin_translatedefinition xftd
     , xx_fin_translatevalues xftv
 WHERE XFTD.translate_id = xftv.translate_id
   AND XFTD.TRANSLATION_NAME = 'XX_SUPPLIER_INTERFACE'
   AND SUBSTR(XFTV.source_value1,1,5) LIKE 'US_OD%'
   AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
   AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
   AND XFTV.ENABLED_FLAG = 'Y'
   AND XFTD.enabled_flag = 'Y';

    ln_v_site_count       := 0;
    ln_v_site_iface_count := 0;
    --lc_error_flag         := NULL;
    --lc_error_message      := NULL;
   BEGIN
     SELECT location_id
       INTO ln_ship_location_id
       FROM hr_locations
      WHERE location_code = lc_ship_to_location;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       ln_ship_location_id := NULL;
       FND_FILE.PUT_LINE(fnd_file.log,'NO DATA FOUND RAISED WHILE DERIVING SHIP_LOCATION_ID FROM TRANSLATE : '|| 	lc_ship_to_location);
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(fnd_file.log,'WHEN OTHERS RAISED WHILE DERIVING SHIP_LOCATION_ID  FROM TRANSLATE : '||SQLERRM);    
   END;

   BEGIN
     SELECT location_id
       INTO ln_bill_location_id
       FROM hr_locations
      WHERE location_code = lc_bill_to_location;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       ln_bill_location_id := NULL;
       FND_FILE.PUT_LINE(fnd_file.log,'NO DATA FOUND RAISED WHILE DERIVING BILL_LOCATION_ID  FROM TRANSLATE : '|| 	lc_bill_to_location);
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(fnd_file.log,'WHEN OTHERS RAISED WHILE DERIVING BILL_LOCATION_ID  FROM TRANSLATE : '||SQLERRM);
   END;

   FOR r_vendor IN c_vendor LOOP

     ln_sent_count := ln_sent_count + 1;
     lc_error_message := NULL;

     dbms_output.put_line('Vendor_name :::'|| r_vendor.vendor_name);
     dbms_output.put_line('lc_org_code :::'|| lc_org_code);

     SELECT ap.ap_suppliers_int_s.NEXTVAL 
       INTO ln_vendor_interface_id 
       FROM DUAL;

     SELECT SUBSTR(TRIM(lc_site_prefix),1,2) || LPAD (xx_ar_refund_sitecode_s.NEXTVAL, 13, '0') 
       INTO lc_sitecode 
       FROM DUAL;

     SELECT COUNT(*) 
       INTO ln_vendor_count  
       FROM po_vendors 
      WHERE (vendor_name = r_vendor.vendor_name OR customer_num = r_vendor.customer_num);

     SELECT COUNT(*) 
       INTO ln_vendor_iface_count 
       FROM ap_suppliers_int 
      WHERE (vendor_name = r_vendor.vendor_name OR customer_num = r_vendor.customer_num);

       /* Validation of columns from stg table */
       
      IF r_vendor.vendor_name IS NULL OR LENGTH(r_vendor.vendor_name) >= 31 THEN
         lc_error_message := ' Vendor Name IS NULL OR EXCEED 30 CHAR : '|| r_vendor.vendor_name;
      ELSE
         lc_asci_validation :=  find_special_chars(r_vendor.vendor_name);
         IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
            lc_error_message := 'Vendor Name has special characters : '|| r_vendor.vendor_name;
         END IF; 
      END IF; 

      IF lc_supplier_type = 'CUSTOMER' THEN  
         lc_insp_flag  := 'N';
         lc_rcpt_flag   := 'N';
         IF r_vendor.customer_num IS NULL THEN
            lc_error_message := lc_error_message||', Customer Number IS NULL : '||r_vendor.customer_num;
         ELSE
            lc_asci_validation := find_special_chars(r_vendor.customer_num);
            IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
               lc_error_message :=lc_error_message||', Customer Number has special characters : '|| r_vendor.customer_num;
            END IF;
         END IF;
      END IF;

      IF r_vendor.site_address1 IS NULL OR LENGTH(r_vendor.site_address1) >= 39  THEN
         lc_error_message := lc_error_message||', SHIP ADDRESS1 IS NULL : '|| r_vendor.site_address1;
      ELSE
         lc_asci_validation := find_special_chars(r_vendor.site_address1);
         IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
            lc_error_message :=lc_error_message||', SHIP ADDRESS1 has special characters : '|| r_vendor.site_address1;    
         END IF;
      END IF;

      IF LENGTH(r_vendor.site_address2) >= 39 THEN
         lc_error_message := lc_error_message||', SHIP ADDRESS2 LENGTH EXCEEDS 38 CHAR : '||r_vendor.site_address2;
      ELSE
         lc_asci_validation := find_special_chars(r_vendor.site_address2);
         IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
            lc_error_message := lc_error_message||', SHIP ADDRESS2 has special characters : '|| r_vendor.site_address2;
         END IF;
      END IF; 

      IF r_vendor.site_city IS NULL OR LENGTH(r_vendor.site_city) >= 23 THEN
         lc_error_message := lc_error_message||' ,SHIP CITY IS NULL OR LENGTH EXCEEDS 22 CHAR : '|| r_vendor.site_city;
      ELSE
         lc_asci_validation := find_special_chars(r_vendor.site_city);
         IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
            lc_error_message := lc_error_message||' ,SHIP CITY  has special characters : '|| r_vendor.site_city;                     END IF;
      END IF;
   
      IF r_vendor.site_state IS NULL OR LENGTH(r_vendor.site_state) >= 3 THEN
         lc_error_message := lc_error_message||' ,SHIP STATE IS NULL OR LENGHT EXCEEDS 2 CHAR : '|| r_vendor.site_state;
      ELSE
         lc_asci_validation := find_special_chars(r_vendor.site_state);
         IF lc_asci_validation = 'JUNK_CHARS_EXIST' THEN
            lc_error_message := lc_error_message||' ,SHIP STATE has special characters : '||r_vendor.site_state;
         END IF;
      END IF;

      IF r_vendor.site_zip IS NULL OR LENGTH(r_vendor.site_zip) >= 11 THEN
         lc_error_message := lc_error_message||' ,SHIP ZIP CODE IS NULL OR EXCEEDS 10 CHAR : '|| r_vendor.site_zip;
      ELSE
         IF LENGTH(TRIM(r_vendor.site_zip)) >= 6 THEN
            r_vendor.site_zip := SUBSTR(r_vendor.site_zip,1,5) 			    				||'-'||SUBSTR(r_vendor.site_zip,INSTR((r_vendor.site_zip),' ',1)+1);
         END IF;
      END IF;

      IF ln_vendor_count > 0 OR ln_vendor_iface_count > 0 THEN
         IF ln_vendor_count > 0 THEN
            FND_FILE.PUT_LINE(fnd_file.log,'Vendor already exists in PO VENDORS TABLE : '||r_vendor.vendor_name);
            lc_error_message := lc_error_message||', Vendor already exists in PO VENDORS TABLE : '||r_vendor.vendor_name;
         ELSE
           FND_FILE.PUT_LINE(fnd_file.log,'Vendor already exists in PO VENDORS IFACE TABLE : '||r_vendor.vendor_name);
	   lc_error_message := lc_error_message||', Vendor already exists in PO VENDORS IFACE TABLE : 			    	   '||r_vendor.vendor_name;
         END IF;
      END IF;

      IF lc_error_message IS  NULL THEN

          BEGIN

            INSERT 
	      INTO ap_suppliers_int( vendor_interface_id
                                        , vendor_name
                                        , customer_num
                                        , vendor_type_lookup_code
                                        , one_time_flag
                                        , terms_name
                                        , pay_date_basis_lookup_code
                                        , ship_to_location_id
                                        , bill_to_location_id
                                        , pay_group_lookup_code
                                        , start_date_active
                                        , end_date_active
                                        , status
                                        , terms_date_basis
                                        , invoice_currency_code
                                        , payment_currency_code
                                        , last_update_date 
                                        , last_updated_by
                                        , creation_date
                                        , created_by
                                        , last_update_login
                                        , receipt_required_flag
                                        , inspection_required_flag
                                        ) 
  	    VALUES
                                        ( ln_vendor_interface_id
                                        , r_vendor.vendor_name
                                        , r_vendor.customer_num
                                        , lc_supplier_type
                                        , lc_one_time
                                        , lc_payment_term
                                        , lc_pay_date_basics
                                        , ln_ship_location_id
                                        , ln_bill_location_id
                                        , lc_pay_group
                                        , SYSDATE
                                        , NULL
                                        , 'NEW'
                                        , lc_terms_basis_date
                                        , lc_invoice_curr
                                        , lc_payment_curr
                                        , SYSDATE
                                        , fnd_global.user_id
                                        , SYSDATE
                                        , fnd_global.user_id
                                        , fnd_global.conc_login_id
                                       , lc_rcpt_flag
                                       , lc_insp_flag
                                       );
            ln_supp_count := (ln_supp_count + SQL%ROWCOUNT);
          EXCEPTION
            WHEN OTHERS THEN
              dbms_output.put_line('WHEN OTHERS RAISED WHILE INSERTING INTO SUPPLIER_INT:::'||SQLERRM);
              FND_FILE.PUT_LINE(fnd_file.log,'WHEN OTHERS RAISED WHILE INSERTING INTO SUPPLIER_INT:::'||SQLERRM);
              lc_error_message :=lc_error_message||', WHEN OTHERS RAISED WHILE INSERTING INTO SUPPLIER_INT:::'||SQLERRM;
              GOTO END_OF_LOOP;
          END;
      END IF;   -- End of IF lc_error_message IS  NULL THEN

      IF lc_error_message IS NULL THEN 
   
         SELECT COUNT(*) 
           INTO ln_v_site_count
           FROM po_vendor_sites_all s
              , po_vendors          p
          WHERE p.vendor_name          = r_vendor.vendor_name
            AND p.customer_num         = r_vendor.customer_num 
            AND p.vendor_id            = s.vendor_id
            AND SUBSTR(s.vendor_site_code,1,2) = SUBSTR(TRIM(lc_site_prefix),1,2)  
            AND address_line1          = r_vendor.site_address1 
            AND NVL(address_line2,-1)  = NVL(r_vendor.site_address2,-1)
            AND NVL(address_line3,-1)  = NVL(r_vendor.site_address3,-1)
            AND city                   = r_vendor.site_city 
            AND state                  = r_vendor.site_state
            AND zip                    = r_vendor.site_zip;
            
         SELECT COUNT(*)
           INTO ln_v_site_iface_count
           FROM ap_supplier_sites_int
          WHERE  SUBSTR(vendor_site_code,1,2) = SUBSTR(TRIM(lc_site_prefix),1,2)
            AND address_line1          = r_vendor.site_address1
            AND NVL(address_line2,-1)  = NVL(r_vendor.site_address2,-1)
            AND NVL(address_line3,-1)  = NVL(r_vendor.site_address3,-1)
            AND city                   = r_vendor.site_city
            AND state                  = r_vendor.site_state
            AND zip                    = r_vendor.site_zip;

         IF ln_v_site_count > 0 OR ln_v_site_iface_count > 0 THEN 
            IF ln_v_site_count > 0 THEN
               FND_FILE.PUT_LINE(fnd_file.log,'Supplier Site already Exists for vendor : '|| r_vendor.vendor_name);
               lc_error_message :=lc_error_message||', Supplier Site already Exists for vendor : '|| r_vendor.vendor_name;
            ELSE
               FND_FILE.PUT_LINE(fnd_file.log,'Supplier Site already Exists in Iface for vendor : '|| 			r_vendor.vendor_name); 
               lc_error_message := lc_error_message||', Supplier Site already Exists in Iface for vendor : '|| 				     	 r_vendor.vendor_name;
            END IF;
         ELSE
	   BEGIN
             INSERT 
	       INTO ap_supplier_sites_int( vendor_interface_id
                                             , vendor_site_code
                                             , address_line1
                                             , address_line2
                                             , address_line3
                                             , city
                                             , state
                                             , province
                                             , country
                                             , zip
                                             , terms_name
                                             , purchasing_site_flag
                                             , pay_site_flag
                                             , org_id
                                             , status
                                             , terms_date_basis
                                             , pay_date_basis_lookup_code
                                             , pay_group_lookup_code
                                             , payment_method_lookup_code
                                             , ship_to_location_id
                                             , bill_to_location_id
                                             , attribute8
                                             , last_update_date
                                             , last_updated_by
                                             , creation_date
                                             , created_by
                                             , last_update_login
                                             ) 
	     VALUES
                                             ( ln_vendor_interface_id
                                             , lc_sitecode
                                             , r_vendor.site_address1
                                             , r_vendor.site_address2
                                             , r_vendor.site_address3
                                             , r_vendor.site_city
                                             , r_vendor.site_state
                                             , NULL
                                             , 'US'
                                             , r_vendor.site_zip
                                             , lc_payment_term
                                             , lc_purchase_site
                                             , lc_pay_site
                                             , 404
                                             , 'NEW'
                                             , lc_terms_basis_date
                                             , lc_pay_date_basics
                                             , lc_pay_group
                                             , lc_payment_method
                                             , ln_ship_location_id
                                             , ln_bill_location_id
                                             , lc_site_category 
                                             , SYSDATE
                                             , fnd_global.user_id
                                             , SYSDATE
                                             , fnd_global.user_id 
                                             , fnd_global.conc_login_id
                                             );
             ln_supp_site_count := (ln_supp_site_count + SQL%ROWCOUNT);
           EXCEPTION
             WHEN OTHERS THEN
               dbms_output.put_line('WHEN OTHERS RAISED WHILE INSERTING INTO SUPPLIER_SITE_INT:::'||SQLERRM);
               FND_FILE.PUT_LINE(fnd_file.log,'WHEN OTHERS RAISED WHILE INSERTING INTO SUPPLIER_SITE_INT:::'||SQLERRM);
               lc_error_message := lc_error_message||', WHEN OTHERS RAISED WHILE INSERTING INTO 								SUPPLIER_SITE_INT:::'||SQLERRM;
               GOTO END_OF_LOOP;
           END;
         END IF;   --  IF ln_v_site_count > 0 OR ln_v_site_iface_count > 0 THEN 
      END IF;  -- IF lc_error_message IS NULL THEN 

      <<END_OF_LOOP>> 

        IF lc_error_message IS NOT NULL THEN
           UPDATE xx_ap_rb_vendor_stg
              SET error_flag       = 'Y'
                , error_message    = lc_error_message
	        , process_flag     = 'Y'
		, request_id	   =ln_request_id
                , last_updated_by  = fnd_global.user_id
                , last_update_date = SYSDATE 
             WHERE rowid            = r_vendor.row_id;
            FND_FILE.PUT_LINE(fnd_file.log,'Supplier : '|| r_vendor.vendor_name ||' marked for error with error message : 		'||lc_error_message);
        ELSE
            UPDATE xx_ap_rb_vendor_stg
               SET process_flag     = 'Y'
                 , last_updated_by  = fnd_global.user_id
 	      	 , request_id	   =ln_request_id
                 , last_update_date = SYSDATE 
             WHERE rowid            =  r_vendor.row_id;
        END IF;
        COMMIT;       
    END LOOP;

    send_error_rpt(ln_request_id,p_email);
    
    DBMS_OUTPUT.PUT_LINE('RECEIVED COUNT      :::'||ln_sent_count); 
    DBMS_OUTPUT.PUT_LINE('successful SUPPLEIR COUNT      :::'||ln_supp_count);
    DBMS_OUTPUT.PUT_LINE('successful SUPPLIER SITE COUNT :::'||ln_supp_site_count);
    DBMS_OUTPUT.PUT_LINE('Failed SUPPLEIR COUNT          :::'|| (ln_sent_count-ln_supp_count));
    DBMS_OUTPUT.PUT_LINE('Failed SUPPLEIR SITE COUNT     :::'|| (ln_sent_count-ln_supp_site_count));
    DBMS_OUTPUT.PUT_LINE('END OF PROGRAM');
    FND_FILE.PUT_LINE(fnd_file.output,'RECEIVED COUNT                 :::'||ln_sent_count);
    FND_FILE.PUT_LINE(fnd_file.output,'successful SUPPLEIR COUNT      :::'||ln_supp_count);
    FND_FILE.PUT_LINE(fnd_file.output,'successful SUPPLIER SITE COUNT :::'||ln_supp_site_count);
    FND_FILE.PUT_LINE(fnd_file.output,'Failed SUPPLEIR COUNT          :::'|| (ln_sent_count-ln_supp_count));
    FND_FILE.PUT_LINE(fnd_file.output, 'Failed SUPPLEIR SITE COUNT    :::'|| (ln_sent_count-ln_supp_site_count));
    FND_FILE.PUT_LINE(fnd_file.output,'END OF PROGRAM');
EXCEPTION
     WHEN OTHERS THEN
         dbms_output.put_line('WHEN OTHERS RAISED :::'||SQLERRM);
END LOAD_VENDORS;

-- +=====================================================================+
-- | Name  : FIND_SPECIAL_CHARS                                          |
-- | Description  : This function will be called to validate any ascii   |
-- |                charaters passes to the IN parameter                 |
-- |                                                                     |
-- | Parameters :  p_string  IN  -> pass a string of char                |
-- |               p_string OUT  -> will pass the same string if no ascii|
-- |                                char found else orig string          |
-- +=====================================================================+
 
FUNCTION find_special_chars(p_string IN VARCHAR2) RETURN VARCHAR2 IS
  v_string         VARCHAR2(4000);
  v_char           VARCHAR2(1);
  v_out_string     VARCHAR2(4000) := NULL;

BEGIN
  v_string := LTRIM(RTRIM(p_string));
  BEGIN
    SELECT LENGTH(TRIM(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' '))) 
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN 'JUNK_CHARS_EXIST';
  ELSE
     RETURN v_string;
  END IF;

/*
    IF p_string IS NOT NULL THEN
        FOR i IN 1..LENGTH(v_string) LOOP
            v_char := SUBSTR(v_string, i, 1);
            IF (ASCII(SUBSTR(v_char,1,1)) <= 31) OR (ASCII(SUBSTR(v_char,1,1)) IN (33,34,35,36,37,38,42,47,58,59,60,61,62,63,64,91,92,93,94,95,96)) OR (ASCII(SUBSTR(v_char,1,1)) >= 123) THEN
                v_out_string := v_out_string||v_char;
            END IF;
        END LOOP;
    END IF;
    IF v_out_string IS NOT NULL THEN
        RETURN 'JUNK_CHARS_EXIST';
    ELSE
        RETURN v_string;
    END IF;
*/


END find_special_chars;
END XX_AP_RB_VENDOR_LOAD_PKG;
/
SHOW ERRORS PACKAGE BODY XX_AP_RB_VENDOR_LOAD_PKG;
--EXIT;

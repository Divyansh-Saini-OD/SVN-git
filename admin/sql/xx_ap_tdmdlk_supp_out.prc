create or replace
PROCEDURE xx_ap_tdmdlk_supp_out(errbuf OUT VARCHAR2,   retcode OUT VARCHAR2
                               ,p_extract_date IN DATE) AS
--) AS
/******************************************************************************
   NAME:       xx_ap_tdmdlk_supp_out
   PURPOSE:    This procedure will read the Supplier base tables for any changes and write
               it to outputfile for TDM and Datalink.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        3/10/2007   Sandeep Pandhare Created this procedure.
   2.0        9/10/2007   Sandeep Pandhare Change the select to include only Paysites.
   3.0        1/10/2007   Sandeep Pandhare Modify the LOG to remove Site ID.   
   4.0        5/05/2008   Sandeep Pandhare Defect 6453 - Archiving    
   5.0        5/25/2008   Sandeep Pandhare Defect 7379 - Replace Country code in output file
   6.0        9/11/1008   Sandeep Pandhare Defect 10891 - Remove timestamp on the filename
   6.1        9/29/1008   Sandeep Pandhare Defect 11563 - Add new filename for full load
   6.2        6/24/2013   Aradhna Sharma   Made changes for R12 Retrofit
   6.3        10/3/2013   Aradhna Sharma   Made changes for R12 Retrofit defect#25680
   6.7        20-May-14   Paddy Sanjeevi   Defect 30102
******************************************************************************/


 /* Define constants */ c_file_path constant VARCHAR2(15) := 'XXFIN_OUTBOUND';
c_separator constant VARCHAR2(1) := '|';
c_blank constant VARCHAR2(1) := ' ';
c_when constant DATE := sysdate;
c_who constant fnd_user.user_id%TYPE := fnd_load_util.owner_id('INTERFACE');
c_fileext constant VARCHAR2(10) := '.txt';
/* Define variables */

 v_outfilename VARCHAR2(60);
v_extract_dt date := NULL;
v_timestamp VARCHAR2(30) := to_char(c_when, 'DDMONYY_HHMISS');
fileid utl_file.file_type;
v_name VARCHAR2(100);
v_vendor_number VARCHAR2(30);
v_vendor_site_id NUMBER;
v_vendor_type VARCHAR2(64);
v_default_pay_site_id VARCHAR2(1);
v_country_cd VARCHAR2(10);
v_inactive_date DATE;
v_inactive_flag VARCHAR2(1);
v_terms_id NUMBER;
v_org_name VARCHAR2(10);
v_reccnt NUMBER := 0;

 -----#6.2 Removed for R12 Retrofit by Aradhna Sharma on 6/24/2013. 
/*
v_vendor_site_code po_vendor_sites_all.vendor_site_code%TYPE;
v_category_att8 po_vendor_sites_all.attribute8%TYPE;
v_type_att9 po_vendor_sites_all.attribute9%TYPE;
v_address_line1 po_vendor_sites_all.address_line1%TYPE;
v_address_line2 po_vendor_sites_all.address_line2%TYPE;
v_address_line3 po_vendor_sites_all.address_line3%TYPE;
v_city po_vendor_sites_all.city%TYPE;
v_state po_vendor_sites_all.state%TYPE;
v_zip po_vendor_sites_all.zip%TYPE;
v_country po_vendor_sites_all.country%TYPE;
v_payment_method_lookup_code po_vendor_sites_all.payment_method_lookup_code%TYPE;
v_payment_currency_code po_vendor_sites_all.payment_currency_code%TYPE;
v_hold_all_payments_flag po_vendor_sites_all.hold_all_payments_flag%TYPE;
v_org_id po_vendor_sites_all.org_id%TYPE;
v_globalvendor_id po_vendor_sites_all.attribute9%TYPE;
*/

 -----#6.2 Added for R12 Retrofit by Aradhna Sharma on 6/24/2013. 
v_vendor_site_code ap_supplier_sites_all.vendor_site_code%TYPE;
v_category_att8 ap_supplier_sites_all.attribute8%TYPE;
v_type_att9 ap_supplier_sites_all.attribute9%TYPE;
v_address_line1 ap_supplier_sites_all.address_line1%TYPE;
v_address_line2 ap_supplier_sites_all.address_line2%TYPE;
v_address_line3 ap_supplier_sites_all.address_line3%TYPE;
v_city ap_supplier_sites_all.city%TYPE;
v_state ap_supplier_sites_all.state%TYPE;
v_zip ap_supplier_sites_all.zip%TYPE;
v_country ap_supplier_sites_all.country%TYPE;
v_payment_method_lookup_code ap_supplier_sites_all.payment_method_lookup_code%TYPE;
v_payment_currency_code ap_supplier_sites_all.payment_currency_code%TYPE;
v_hold_all_payments_flag ap_supplier_sites_all.hold_all_payments_flag%TYPE;
v_org_id ap_supplier_sites_all.org_id%TYPE;
v_globalvendor_id ap_supplier_sites_all.attribute9%TYPE;


-- variables for file copy
ln_req_id    	NUMBER;
lc_sourcepath varchar2(1000);
lc_destpath 	varchar2(1000);
lb_result      boolean;
lc_phase      varchar2(1000);
lc_status     varchar2(1000);
lc_dev_phase  varchar2(1000);
lc_dev_status varchar2(1000);
lc_message    varchar2(1000);
lc_err_status varchar2(10);
lc_err_mesg   varchar2(1000);
lc_err_flag   VARCHAR2(10) := 'N';

CURSOR suppldtl_cur IS
SELECT v.vendor_name,
  v.segment1,
  s.vendor_site_id,
  s.vendor_site_code,
  s.attribute8,
  s.attribute9,
  s.primary_pay_site_flag,
  s.address_line1,
  s.address_line2,
  s.address_line3,
  s.city,
  s.state,
  s.zip,
  s.country,
  s.inactive_date,
  s.terms_id,
-----  s.payment_method_lookup_code,    -----Commented for R12 retrofit defect #25680 by Aradhna fro defect #25680 on 3-oct-2013
  nvl(s.payment_method_lookup_code,v.payment_method_lookup_code),    ------Added for R12 retrofit defect #25680 by Aradhna on 3-oct-2013
  s.payment_currency_code,
  s.hold_all_payments_flag,
  decode(s.org_id, 404, 'US', 403, 'CA','US')

FROM/* po_vendors v,
  po_vendor_sites_all s  */      -----#6.2 Removed for R12 Retrofit by Aradhna Sharma on 6/24/2013. 
  ap_suppliers v,
  ap_supplier_sites_all s     ------#6.2 Added for R12 Retrofit by Aradhna Sharma on 6/24/2013. 
WHERE v.vendor_id = s.vendor_id
 AND  (s.attribute8 LIKE 'TR%' OR s.attribute8 LIKE 'EX%')
 AND s.org_id in (xx_fin_country_defaults_pkg.f_org_id('CA'),xx_fin_country_defaults_pkg.f_org_id('US'))
 AND s.pay_site_flag = 'Y'    -- 2.0 change
 AND s.attribute8  NOT LIKE '%OMX%'   -- Defect 30102
 AND (trunc(s.last_update_date) = v_extract_dt OR v_extract_dt IS NULL);

BEGIN

---+===============================================================================================
---|  Select the directory path for XXFIN_OUTBOUND directory
---+===============================================================================================

      BEGIN

          SELECT directory_path
          INTO   lc_sourcepath
          FROM   dba_directories
          WHERE  directory_name = c_file_path ;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
              lc_err_status := 'Y' ;
              lc_err_mesg := 'DBA Directory : '||c_file_path||': Not Defined';
              FND_FILE.PUT_LINE(fnd_file.log,'Error : '|| lc_err_mesg);
              lc_err_flag := 'Y' ;
      END;

-- Defect 10891
--  v_outfilename := 'TDMsupplout_'|| v_timestamp || c_fileext;
  v_outfilename := 'TDMsupplout'|| c_fileext;
-- end  

  if p_extract_date is NULL then
    v_extract_dt := NULL;
    v_outfilename := 'TDMsupploutW'|| c_fileext;   -- Defect 11563
    FND_FILE.PUT_LINE(fnd_file.log,'Full Load Filename : '|| v_outfilename);
  else
    v_extract_dt := p_extract_date;
  end if;

  -- Add code for File open
  fnd_file.PUT_LINE(fnd_file.LOG,   'Opening the ' || v_outfilename || ' output file......');
  fnd_file.PUT_LINE(fnd_file.LOG,   '                                                    ');
  fnd_file.PUT_LINE(fnd_file.LOG,    'Global Vendor id' || c_separator || 'Supplier Number' || c_separator ||  'Name' || c_separator ||  'Category' || c_separator ||  'Primary Pay Site' || c_separator || 'AddressLine1' || c_separator || 'AddressLine2' || c_separator || 'AddressLine3' || c_separator || 'City' || c_separator || 'State' || c_separator || 'Zip' || c_separator || 'Country' || c_separator || 'Inactive' || c_separator || 'Payment Terms' || c_separator || 'Payment Method' || c_separator || 'Currency' || c_separator || 'Holds' || c_separator);
  fnd_file.PUT_LINE(fnd_file.LOG,   '                                                    ');

  fileid := utl_file.fopen(c_file_path,   v_outfilename,   'W');
  
-- Write the Header Line
  utl_file.PUT_LINE(fileid,    'Global Vendor id' || c_separator || 'Supplier Number' || c_separator || 'Name' || c_separator ||   'Category' || c_separator ||  'Primary Pay Site' || c_separator || 'AddressLine1' || c_separator || 'AddressLine2' || c_separator || 'AddressLine3' || c_separator || 'City' || c_separator || 'State' || c_separator || 'Zip' || c_separator || 'Country' || c_separator || 'Inactive' || c_separator || 'Payment Terms' || c_separator || 'Payment Method' || c_separator || 'Currency' || c_separator || 'Holds' );

  OPEN suppldtl_cur;

  LOOP
    FETCH suppldtl_cur
    INTO v_name,
      v_vendor_number,
      v_vendor_site_id,
      v_vendor_site_code,
      v_category_att8,
      v_type_att9,
      v_default_pay_site_id,
      v_address_line1,
      v_address_line2,
      v_address_line3,
      v_city,
      v_state,
      v_zip,
      v_country_cd,
      v_inactive_date,
      v_terms_id,
      v_payment_method_lookup_code,
      v_payment_currency_code,
      v_hold_all_payments_flag,
      v_org_name;

    EXIT  WHEN NOT suppldtl_cur % FOUND;

  v_inactive_flag := 'N';
  v_globalvendor_id := APPS.xx_po_global_vendor_pkg.F_GET_OUTBOUND(v_vendor_site_id);
  IF v_inactive_date <= c_when THEN
--    DBMS_OUTPUT.PUT_LINE('Vendor is Inactive');
    v_inactive_flag := 'Y';
  END IF;

/* Retreieve Country lookup value
v_country := null;
select  territory_short_name
into v_country
from fnd_territories_tl
where territory_code = v_country_cd;
*/

  v_reccnt := v_reccnt + 1;
  fnd_file.PUT_LINE(fnd_file.LOG, v_globalvendor_id || c_separator || v_vendor_number || c_separator || v_name || c_separator ||   v_category_att8 || c_separator ||  v_default_pay_site_id || c_separator || v_address_line1 || c_separator || v_address_line2 || c_separator || v_address_line3 || c_separator || v_city || c_separator || v_state || c_separator || v_zip || c_separator || v_org_name || c_separator || v_inactive_flag || c_separator || v_terms_id || c_separator || v_payment_method_lookup_code || c_separator || v_payment_currency_code || c_separator || v_hold_all_payments_flag );
--  utl_file.PUT_LINE(fileid,    v_globalvendor_id || c_separator || v_vendor_number || c_separator || v_name || c_separator ||  v_category_att8 || c_separator ||  v_default_pay_site_id || c_separator || v_address_line1 || c_separator || v_address_line2 || c_separator || v_address_line3 || c_separator || v_city || c_separator || v_state || c_separator || v_zip || c_separator || v_country_cd || c_separator || v_inactive_flag || c_separator || v_terms_id || c_separator || v_payment_method_lookup_code || c_separator || v_payment_currency_code || c_separator || v_hold_all_payments_flag );
  utl_file.PUT_LINE(fileid,    v_globalvendor_id || c_separator || v_vendor_number || c_separator || v_name || c_separator ||  v_category_att8 || c_separator ||  v_default_pay_site_id || c_separator || v_address_line1 || c_separator || v_address_line2 || c_separator || v_address_line3 || c_separator || v_city || c_separator || v_state || c_separator || v_zip || c_separator || v_org_name || c_separator || v_inactive_flag || c_separator || v_terms_id || c_separator || v_payment_method_lookup_code || c_separator || v_payment_currency_code || c_separator || v_hold_all_payments_flag );


END LOOP;

-- write trailer record
utl_file.PUT_LINE(fileid, '3' || c_separator || v_outfilename  || c_separator || to_char(c_when, 'DD-MON-YYYY') || c_separator || to_char(c_when, 'HH:MM:SS') || c_separator || v_reccnt );

    utl_file.fclose(fileid);
    CLOSE suppldtl_cur;

---+============================================================================================================
---|  Submit the Request to copy the TDM file from XXFIN_OUTBOUND directory to XXFIN_DATA/ftp/out
---+============================================================================================================

-- Defect 6453
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
			        	  ,'XXCOMFILCOPY'
					  ,''
				          ,''
					   ,FALSE
                                           ,lc_sourcepath ||'/'||v_outfilename
                                           ,'$XXFIN_DATA/ftp/out/tdm/'||v_outfilename
                                           ,'','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','','');
   COMMIT;

IF ln_req_id > 0 THEN

    lb_result:=apps.fnd_concurrent.wait_for_request(
              ln_req_id,
              10,
              0,
              lc_phase      ,
              lc_status     ,
              lc_dev_phase  ,
              lc_dev_status ,
              lc_message    );


END IF ;


IF trim(lc_status) = 'Error' THEN

   lc_err_status := 'Y' ;
   lc_err_mesg := 'File Copy of the TDM Supplier File Failed : '||v_outfilename||
                   ': Please check the Log file for Request ID : '||ln_req_id;
   FND_FILE.PUT_LINE(fnd_file.log,'Error : ' || lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM) ;

END IF ;


    fnd_file.PUT_LINE(fnd_file.LOG, '3' || c_separator || v_outfilename  || c_separator || to_char(c_when, 'DD-MON-YYYY') || c_separator || to_char(c_when, 'HH:MM:SS') || c_separator || v_reccnt );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   'Program Name: Office Depot TDM/DATALINK Supplier Outbound                                     Date: '||SYSDATE);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   '                                                                                                    ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   '                                                                                                        ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   'Number of lines in the File: ' || v_reccnt);

END;




/
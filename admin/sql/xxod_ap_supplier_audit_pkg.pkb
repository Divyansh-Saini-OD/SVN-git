create or replace PACKAGE BODY      XXOD_AP_SUPPLIER_AUDIT_PKG AS
gc_no_site_change   CONSTANT  VARCHAR2(200) DEFAULT 'No Site Change';
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- |                    IT Convergence/Office Depot                                      |
-- +===================================================================                  |
-- | Name             :  xxod_ap_supplier_audit_pkg                                      |
-- | Description      :  This Package is used by Financial Reports                       |
-- |                                                                                     |
-- | Change Record:                                                                      |
-- | ===============                                                                     |
-- | Version   Date         Author           Remarks                                     |
-- | =======   ==========   =============    ============================                |
-- | DRAFT 1A  31-AUG-2007  Kantharaja       Initial draft version                       |
-- | V1.1      13-JAN-08    Aravind A.       Fixed defect 4345                           |
-- | V1.2      01-JULY-2013 Sravanthi Surya  Modified Table names as part of R12 Upgrade |
-- | V1.3      03-JULY-2014 Avinash Baddam   Changes for defect 30042 			         |	
-- | V1.4      22-JAN-2020 Bhargavi Ankolekar Added for jira NAIT-103952                 |
-- | V1.5      03-JULY-2014 Rahul Y          Changes for JIRA # 133497 			         |
-- +=====================================================================================+


PROCEDURE PROCESS_VENDORS(p_begin_date DATE,p_end_date DATE)
IS

CURSOR lcu_changed_vendors
IS
SELECT PV.vendor_id
       ,PV.vendor_name
       ,PV.segment1   vendor_num
FROM    --- po_vendors pv
       -- Changed Table Name on 7/1/2013 by Sravanthi Surya as part of R12 Upgrade 
       ap_suppliers PV
WHERE PV.last_update_date BETWEEN p_begin_date AND p_end_date;

CURSOR lcu_vendor_aud(p_vendor_id NUMBER)
IS
SELECT * FROM
(SELECT  vendor_name Vendor_name_Current
         ,lag(vendor_name,1,null)  over (order by version_timestamp) Vendor_Name_Prev ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
         ,num_1099 num_1099_Current
         ,lag(num_1099,1,null)  over (order by version_timestamp) num_1099_Prev ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
         ,vat_registration_num vat_registration_num_Current
         ,lag(vat_registration_num,1,null)  over (order by version_timestamp) vat_registration_num_Prev ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
         ,type_1099 type_1099_Current
         ,lag(type_1099,1,null)  over (order by version_timestamp) type_1099_Prev ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
         ,employee_id employee_id_Current
         ,lag(employee_id,1,null)  over (order by version_timestamp) employee_id_Prev ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
      ,last_updated_by
      ,last_update_date
      ,1 order_by_col
FROM xx_po_vendors_all_aud va
WHERE va.vendor_id = p_vendor_id
) where last_update_date
  BETWEEN p_begin_date AND p_end_date
  ORDER BY last_update_date;

-------Adding this cursor for ap_suppliers additional column audit jira NAIT-103952.Added by Bhargavi Ankolekar.
----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
CURSOR lcu_vendor_add_aud(p_vendor_id NUMBER)
IS
SELECT * FROM
(SELECT  TAX_REPORTING_NAME   TAX_REPORTING_NAME_cur
         ,lag(TAX_REPORTING_NAME,1,null)  over (order by version_timestamp) TAX_REPORTING_NAME_prev
         ,TAX_VERIFICATION_DATE   TAX_VERIFICATION_DATE_cur
         ,lag(TAX_VERIFICATION_DATE ,1,null)  over (order by version_timestamp) TAX_VERIFICATION_DATE_prev
         ,ORGANIZATION_TYPE_LOOKUP_CODE  ORG_TYPE_LOOKUP_CODE_cur
         ,lag(ORGANIZATION_TYPE_LOOKUP_CODE,1,null)  over (order by version_timestamp) ORG_TYPE_LOOKUP_CODE_prev
		 ,INDIVIDUAL_1099  INDIVIDUAL_1099_cur
         ,lag(INDIVIDUAL_1099,1,null)  over (order by version_timestamp) INDIVIDUAL_1099_prev
		 ----- End of changes for jira #133497
      ,last_updated_by
      ,last_update_date
      ,1 order_by_col
FROM XX_PO_VENDOR_ADD_AUD_V1 va
WHERE va.vendor_id = p_vendor_id
) where last_update_date
  BETWEEN p_begin_date AND p_end_date
  ORDER BY last_update_date;


lr_vendor_rec        lcu_changed_vendors%ROWTYPE;
lr_vendor_aud_rec    lcu_vendor_aud%ROWTYPE;
lr_vendor_add_aud_rec lcu_vendor_add_aud%ROWTYPE;

BEGIN



FOR lr_vendor_rec IN lcu_changed_vendors
LOOP
FOR lr_vendor_aud_rec IN lcu_vendor_aud(lr_vendor_rec.vendor_id)
LOOP

IF (NVL(lr_vendor_aud_rec.vendor_name_Current,'X') <> NVL(lr_vendor_aud_rec.vendor_name_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'VENDOR NAME'
                            ,lr_vendor_aud_rec.vendor_name_prev
                            ,lr_vendor_aud_rec.vendor_name_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.num_1099_Current,'X') <> NVL(lr_vendor_aud_rec.num_1099_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'TIN NUMBER'
                            ,lr_vendor_aud_rec.num_1099_prev
                            ,lr_vendor_aud_rec.num_1099_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.vat_registration_num_Current,'X') <> NVL(lr_vendor_aud_rec.vat_registration_num_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'TAX REGISTRATION NUMBER'
                            ,lr_vendor_aud_rec.vat_registration_num_prev
                            ,lr_vendor_aud_rec.vat_registration_num_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.type_1099_Current,'X') <> NVL(lr_vendor_aud_rec.type_1099_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'INCOME TAX REPORTING TYPE'
                            ,lr_vendor_aud_rec.type_1099_prev
                            ,lr_vendor_aud_rec.type_1099_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.employee_id_Current,0) <> NVL(lr_vendor_aud_rec.employee_id_prev,0)) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'EMPLOYEE NUMBER'
                            ,lr_vendor_aud_rec.employee_id_prev
                            ,lr_vendor_aud_rec.employee_id_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

END LOOP;
END LOOP;

-------Adding this loop for ap_supplier additonal column audit jira NAIT-103952.Added by Bhargavi Ankolekar.
FOR lr_vendor_rec IN lcu_changed_vendors
LOOP
FOR lr_vendor_add_aud_rec IN lcu_vendor_add_aud(lr_vendor_rec.vendor_id)
LOOP

IF (NVL(lr_vendor_add_aud_rec.TAX_REPORTING_NAME_cur,'X') <> NVL(lr_vendor_add_aud_rec.TAX_REPORTING_NAME_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_add_aud_rec.last_updated_by
                            ,lr_vendor_add_aud_rec.last_update_date
                            ,'TAX_REPORTING_NAME'
                            ,lr_vendor_add_aud_rec.TAX_REPORTING_NAME_prev
                            ,lr_vendor_add_aud_rec.TAX_REPORTING_NAME_cur
                               ,'AUDIT'
                            ,lr_vendor_add_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_add_aud_rec.TAX_VERIFICATION_DATE_cur,NULL) <> NVL(lr_vendor_add_aud_rec.TAX_VERIFICATION_DATE_prev,NULL)) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_add_aud_rec.last_updated_by
                            ,lr_vendor_add_aud_rec.last_update_date
                            ,'TAX_VERIFICATION_DATE'
                            ,lr_vendor_add_aud_rec.TAX_VERIFICATION_DATE_prev
                            ,lr_vendor_add_aud_rec.TAX_VERIFICATION_DATE_cur
                               ,'AUDIT'
                            ,lr_vendor_add_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_add_aud_rec.ORG_TYPE_LOOKUP_CODE_cur,'X') <> NVL(lr_vendor_add_aud_rec.ORG_TYPE_LOOKUP_CODE_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_add_aud_rec.last_updated_by
                            ,lr_vendor_add_aud_rec.last_update_date
                            ,'ORGANIZATION_TYPE_LOOKUP_CODE'
                            ,lr_vendor_add_aud_rec.ORG_TYPE_LOOKUP_CODE_prev
                            ,lr_vendor_add_aud_rec.ORG_TYPE_LOOKUP_CODE_cur
                               ,'AUDIT'
                            ,lr_vendor_add_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_add_aud_rec.INDIVIDUAL_1099_cur,'X') <> NVL(lr_vendor_add_aud_rec.INDIVIDUAL_1099_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                              flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,gc_no_site_change
                            ,NULL
                            ,lr_vendor_add_aud_rec.last_updated_by
                            ,lr_vendor_add_aud_rec.last_update_date
                            ,'INDIVIDUAL_1099'
                            ,lr_vendor_add_aud_rec.INDIVIDUAL_1099_prev
                            ,lr_vendor_add_aud_rec.INDIVIDUAL_1099_cur
                               ,'AUDIT'
                            ,lr_vendor_add_aud_rec.order_by_col);
END IF;

END LOOP;

END LOOP;
------ loop for jira NAIT-103952 ends here.Added by Bhargavi Ankolekar.


END PROCESS_VENDORS;

PROCEDURE PROCESS_VENDOR_SITES(p_begin_date DATE,p_end_date DATE)
IS

CURSOR lcu_changed_vendor_sites
IS
SELECT PVSA.vendor_site_id
       ,PVSA.vendor_site_code
       ,PV.segment1   vendor_num
       ,PV.vendor_name
       ,PVSA.attribute9 legacy_num
FROM   -- Changed Table Name on 7/1/2013 by Sravanthi Surya as part of R12 Upgrade 		
		       -- po_vendors pv		
		       -- ,po_vendor_sites_all PVSA
          ap_suppliers PV,
      ap_supplier_sites_all PVSA
WHERE PV.vendor_id = PVSA.vendor_id
--AND PVSA.org_id = FND_PROFILE.VALUE('ORG_ID') -- Commented by Ganesan for defect 4878 to show the data irrespective of the operating unit
AND PVSA.last_update_date BETWEEN p_begin_date AND p_end_date
UNION  --For defect 30042
SELECT PVSA.vendor_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
     FROM iby_external_payees_all iepa,
          iby_ext_party_pmt_mthds ieppm,
          ap_suppliers pv,
          ap_supplier_sites_all pvsa
    WHERE iepa.ext_payee_id = ieppm.ext_pmt_party_id
      AND( (ieppm.inactive_date IS NULL)or (ieppm.inactive_date > sysdate))
      AND ieppm.primary_flag = 'Y'
      AND iepa.supplier_site_id = pvsa.vendor_site_id
      AND pvsa.vendor_id = pv.vendor_id
      AND ieppm.last_update_date BETWEEN p_begin_date AND p_end_date;
	 
-------Adding below CURSOR for  column audit of XX_PO_VENDOR_SITES_KFF requested for jira NAIT-103952.Added by Bhargavi Ankolekar.	  

CURSOR lcu_po_vend_site_kff is 
select PVSA.vendor_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
		 ,pvsa.attribute10
		 ,pvsa.attribute11
		 ,pvsa.attribute12
from ap_supplier_sites_all PVSA,
ap_suppliers PV,
XX_PO_VENDOR_SITES_KFF xpvsk
where  PV.vendor_id=PVSA.vendor_id
and PVSA.attribute10=xpvsk.VS_KFF_ID
AND xpvsk.last_update_date BETWEEN p_begin_date AND p_end_date;

-------Adding below CURSOR for column audit of XX_PO_VEND_SITES_KFF_AUD requested for jira NAIT-103952.Added by Bhargavi Ankolekar.	  
CURSOR lcu_po_vdsite_aud_kff(p_attribute10 number, p_attribute11 number , p_attribute12 number)is 
SELECT * FROM (
select pvs.SEGMENT1   SEGMENT1_cur
         ,lag(pvs.SEGMENT1,1,null)  over (order by last_update_date) SEGMENT1_prev
         ,pvs.SEGMENT2   SEGMENT2_cur
         ,lag(pvs.SEGMENT2 ,1,null)  over (order by last_update_date) SEGMENT2_prev
        ,pvs.SEGMENT3  SEGMENT3_cur
         ,lag(pvs.SEGMENT3,1,null)  over (order by last_update_date) SEGMENT3_prev
		 ,pvs.SEGMENT4 SEGMENT4_cur
         ,lag(pvs.SEGMENT4,1,null)  over (order by last_update_date) SEGMENT4_prev
		 ,pvs.SEGMENT5  SEGMENT5_cur
         ,lag(pvs.SEGMENT5,1,null)  over (order by last_update_date) SEGMENT5_prev
		 ,pvs.SEGMENT11  SEGMENT11_cur
         ,lag(pvs.SEGMENT11,1,null)  over (order by last_update_date) SEGMENT11_prev
		 ,pvs.SEGMENT13  SEGMENT13_cur
         ,lag(pvs.SEGMENT13,1,null)  over (order by last_update_date) SEGMENT13_prev
		 ,pvs.SEGMENT14  SEGMENT14_cur
         ,lag(pvs.SEGMENT14,1,null)  over (order by last_update_date) SEGMENT14_prev
		 ,pvs.SEGMENT15  SEGMENT15_cur
         ,lag(pvs.SEGMENT15,1,null)  over (order by last_update_date) SEGMENT15_prev
		 ,pvs.SEGMENT16  SEGMENT16_cur
         ,lag(pvs.SEGMENT16,1,null)  over (order by last_update_date) SEGMENT16_prev
		 ,pvs.SEGMENT17  SEGMENT17_cur
         ,lag(pvs.SEGMENT17,1,null)  over (order by last_update_date) SEGMENT17_prev
		 ,pvs.SEGMENT37  SEGMENT37_cur
         ,lag(pvs.SEGMENT37,1,null)  over (order by last_update_date) SEGMENT37_prev
		 ,pvs.SEGMENT40  SEGMENT40_cur
         ,lag(pvs.SEGMENT40,1,null)  over (order by last_update_date) SEGMENT40_prev
		 ,pvs.SEGMENT42  SEGMENT42_cur
         ,lag(pvs.SEGMENT42,1,null)  over (order by last_update_date) SEGMENT42_prev
		 ,pvs.SEGMENT43  SEGMENT43_cur
         ,lag(pvs.SEGMENT43,1,null)  over (order by last_update_date) SEGMENT43_prev
		 ,pvs.SEGMENT44  SEGMENT44_cur
         ,lag(pvs.SEGMENT44,1,null)  over (order by last_update_date) SEGMENT44_prev
		 ,pvs.SEGMENT47  SEGMENT47_cur
         ,lag(pvs.SEGMENT47,1,null)  over (order by last_update_date) SEGMENT47_prev
		 ,pvs.SEGMENT50  SEGMENT50_cur
         ,lag(pvs.SEGMENT50,1,null)  over (order by last_update_date) SEGMENT50_prev
		 ,pvs.SEGMENT51  SEGMENT51_cur
         ,lag(pvs.SEGMENT51,1,null)  over (order by last_update_date) SEGMENT51_prev
		 ,pvs.SEGMENT52  SEGMENT52_cur
         ,lag(pvs.SEGMENT52,1,null)  over (order by last_update_date) SEGMENT52_prev
		 ,pvs.SEGMENT53  SEGMENT53_cur
         ,lag(pvs.SEGMENT53,1,null)  over (order by last_update_date) SEGMENT53_prev
		 ,pvs.SEGMENT54  SEGMENT54_cur
         ,lag(pvs.SEGMENT54,1,null)  over (order by last_update_date) SEGMENT54_prev
		 ,pvs.SEGMENT55  SEGMENT55_cur
         ,lag(pvs.SEGMENT55,1,null)  over (order by last_update_date) SEGMENT55_prev
		 ,pvs.SEGMENT58  SEGMENT58_cur
         ,lag(pvs.SEGMENT58,1,null)  over (order by last_update_date) SEGMENT58_prev
		 ,pvs.SEGMENT60  SEGMENT60_cur
         ,lag(pvs.SEGMENT60,1,null)  over (order by last_update_date) SEGMENT60_prev 
,last_updated_by
      ,last_update_date
      ,1 order_by_col
from XX_PO_VEND_SITES_KFF_AUD_V1 pvs
WHERE pvs.VS_KFF_ID in (p_attribute10 , p_attribute11, p_attribute12))
WHERE last_update_date BETWEEN p_begin_date AND p_end_date
ORDER BY last_update_date;

------Adding below cursor for xx ap custom tolerance as per the request for jira NAIT-103952.This is added by Bhargavi Ankolekar.

CURSOR lcu_xxap_cust_tol_aud
IS
select PVSA.vendor_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
         ,xact.SUPPLIER_SITE_ID
from ap_supplier_sites_all PVSA,
ap_suppliers PV,
xx_ap_custom_tolerances xact
where  PV.vendor_id=PVSA.vendor_id
and xact.SUPPLIER_SITE_ID=PVSA.VENDOR_SITE_ID
and xact.supplier_id=pv.vendor_id
AND xact.last_update_date BETWEEN p_begin_date AND p_end_date;

------Adding below cursor for xx ap custom tolerance of new trigger table created  as per the request for jira NAIT-103952.This is added by Bhargavi Ankolekar.

CURSOR LCU_XXAP_CUST_TOL_AUD_COMP(p1_supplier_site_id NUMBER)
IS
SELECT * FROM
(SELECT  
FAVOURABLE_PRICE_PCT FAVOURABLE_PRICE_PCT_Cur
	  ,lag(FAVOURABLE_PRICE_PCT,1,null)  over (order by last_update_date) FAVOURABLE_PRICE_PCT_Prev
	  ,MAX_PRICE_AMT MAX_PRICE_AMT_Cur
	  ,lag(MAX_PRICE_AMT,1,null)  over (order by last_update_date) MAX_PRICE_AMT_Prev
	  ,MIN_CHARGEBACK_AMT   MIN_CHARGEBACK_AMT_cur
         ,lag(MIN_CHARGEBACK_AMT,1,null)  over (order by last_update_date) MIN_CHARGEBACK_AMT_prev
         ,MAX_FREIGHT_AMT   MAX_FREIGHT_AM_cur
         ,lag(MAX_FREIGHT_AMT ,1,null)  over (order by last_update_date) MAX_FREIGHT_AMT_prev
         ,DIST_VAR_NEG_AMT  DIST_VAR_NEG_AMT_cur
         ,lag(DIST_VAR_NEG_AMT,1,null)  over (order by last_update_date) DIST_VAR_NEG_AMT_prev
		 ,DIST_VAR_POS_AMT  DIST_VAR_POS_AMT_cur
         ,lag(DIST_VAR_POS_AMT,1,null)  over (order by last_update_date) DIST_VAR_POS_AMT_prev
	    ,last_updated_by
      ,last_update_date
      ,2 order_by_col
FROM XX_AP_CUST_TOLERANCE_AUD_V1 xpc
WHERE xpc.supplier_site_id = p1_supplier_site_id
) where last_update_date
  BETWEEN p_begin_date AND p_end_date
  ORDER BY last_update_date;

-------------------Cursor added for the additional column audit from the supplier sites all table as for jira NAIT-103952.Added by Bhargavi Ankolekar.
CURSOR lcu_vend_sites_add_aud
IS
select PVSA.vendor_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
from ap_supplier_sites_all PVSA,
ap_suppliers PV
where  PV.vendor_id=PVSA.vendor_id
AND PVSA.last_update_date BETWEEN p_begin_date AND p_end_date;

-------------------Cursor added for the additional column audit at the new trigger table created from the supplier sites all table as for jira NAIT-103952.Added by Bhargavi Ankolekar.
----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
CURSOR lcu_vd_sites_add_aud(p1_vendor_site_id NUMBER)
IS
SELECT * FROM
(SELECT  ATTRIBUTE4   ATTRIBUTE4_cur
         ,lag(ATTRIBUTE4,1,null)  over (order by version_timestamp) ATTRIBUTE4_prev
         ,ATTRIBUTE5   ATTRIBUTE5_cur
         ,lag(ATTRIBUTE5 ,1,null)  over (order by version_timestamp) ATTRIBUTE5_prev
         ,ATTRIBUTE8  ATTRIBUTE8_cur
         ,lag(ATTRIBUTE8,1,null)  over (order by version_timestamp) ATTRIBUTE8_prev
		 ,ORG_ID  ORG_ID_cur
         ,lag(ORG_ID,1,null)  over (order by version_timestamp) ORG_ID_prev
		 ,TELEX  TELEX_cur
         ,lag(TELEX,1,null)  over (order by version_timestamp) TELEX_prev
		 ,VENDOR_SITE_CODE_ALT  VENDOR_SITE_CODE_ALT_cur
         ,lag(VENDOR_SITE_CODE_ALT,1,null)  over (order by version_timestamp) VENDOR_SITE_CODE_ALT_prev
		  ,LANGUAGE  LANGUAGE_cur
         ,lag(LANGUAGE,1,null)  over (order by version_timestamp) LANGUAGE_prev
		------- End of changes for jira #133497
      ,last_updated_by
      ,last_update_date
      ,1 order_by_col
FROM XX_PO_VDSITES_ADD_AUD_V1 va
WHERE va.vendor_site_id = p1_vendor_site_id
) where last_update_date
  BETWEEN p_begin_date AND p_end_date
  ORDER BY last_update_date;


------Adding below CURSOR for additional column audit requested for jira NAIT-103952.Added by Bhargavi Ankolekar.
cursor lcu_vdsite_iby_col_aud is 
SELECT iepa.supplier_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
     FROM iby_external_payees_all iepa,
          ap_suppliers pv,
          ap_supplier_sites_all pvsa
    WHERE iepa.supplier_site_id = pvsa.vendor_site_id
      AND pvsa.vendor_id = pv.vendor_id
      AND iepa.last_update_date BETWEEN p_begin_date AND p_end_date;
	  
-------Adding below CURSOR for additional column audit requested for jira NAIT-103952.Added by Bhargavi Ankolekar.
CURSOR lcu_vdsite_add_col_aud(p_supplier_site_id NUMBER) is
SELECT * FROM (
SELECT
PAYMENT_FORMAT_CODE PAYMENT_FORMAT_CODE_CURRENT
	  ,lag(PAYMENT_FORMAT_CODE,1,null)  over (order by last_update_date) PAYMENT_FORMAT_CODE_PREV
	  ,PAYMENT_REASON_CODE PAYMENT_REASON_CODE_Current
	  ,lag(PAYMENT_REASON_CODE,1,null)  over (order by last_update_date) PAYMENT_REASON_CODE_Prev
      ,PAYMENT_REASON_COMMENTS PAYMENT_REASON_COMMENTS_Curr
      ,lag(PAYMENT_REASON_COMMENTS,1,null)  over (order by last_update_date) PAYMENT_REASON_COMMENTS_Prev
	  ,REMIT_ADVICE_DELIVERY_METHOD REMIT_ADVICE_DELIVERY_METHOD_C
      ,lag(REMIT_ADVICE_DELIVERY_METHOD,1,null)  over (order by last_update_date) REMIT_ADVICE_DELIVERY_METHOD_P
	  ,REMIT_ADVICE_EMAIL REMIT_ADVICE_EMAIL_Current
	  ,lag(REMIT_ADVICE_EMAIL,1,null)  over (order by last_update_date) REMIT_ADVICE_EMAIL_Prev
	  ,REMIT_ADVICE_FAX REMIT_ADVICE_FAX_Current
	  ,lag(REMIT_ADVICE_FAX,1,null)  over (order by last_update_date) REMIT_ADVICE_FAX_Prev
,last_updated_by
      ,last_update_date
      ,2 order_by_col
FROM XX_IBY_EXT_PAYEES_ALL_AUD_V1 va
WHERE va.SUPPLIER_SITE_ID = p_supplier_site_id)
WHERE last_update_date BETWEEN p_begin_date AND p_end_date
ORDER BY last_update_date;


CURSOR lcu_vendor_sites_aud(p_vendor_site_id NUMBER)
IS
----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
SELECT * FROM (
SELECT vendor_site_code vendor_site_code_Current
       ,lag(vendor_site_code,1,null)  over (order by version_timestamp) vendor_site_code_Prev
      ,decode(NVL(purchasing_site_flag,'N'),'Y','PUR ') || decode(NVL(pay_site_flag,'N'),'Y','PAY') site_uses_flag_Current -- Added By Ganesan for defect 4878
      ,decode(NVL(lag(purchasing_site_flag,1,null)  over (order by version_timestamp),'N'),'Y','PUR ') || decode(NVL(lag(pay_site_flag,1,null)  over (order by version_timestamp),'N'),'Y','PAY') site_uses_flag_prev  -- Added By Ganesan for defect 4878
      ,accts_pay_code_combination_id code_combination_id_Current
       ,lag(accts_pay_code_combination_id,1,null)  over (order by version_timestamp) code_combination_id_Prev
      ,area_code||'-'||phone area_Current
       ,lag(area_code||'-'||phone,1,null)  over (order by version_timestamp) area_Prev
      ,address_line1 address_line1_Current
       ,lag(address_line1,1,null)  over (order by version_timestamp) address_line1_Prev
      ,address_line2 address_line2_Current
       ,lag(address_line2,1,null)  over (order by version_timestamp) address_line2_Prev
      ,address_line3 address_line3_Current
       ,lag(address_line3,1,null)  over (order by version_timestamp) address_line3_Prev
      ,city city_Current
       ,lag(city,1,null)  over (order by version_timestamp) city_Prev
      ,state state_Current
       ,lag(state,1,null)  over (order by version_timestamp) state_Prev
      ,province province_Current
       ,lag(province,1,null)  over (order by version_timestamp) province_Prev
      ,zip zip_Current
       ,lag(zip,1,null)  over (order by version_timestamp) zip_Prev
      ,inactive_date inactive_date_Current
       ,lag(inactive_date,1,null)  over (order by version_timestamp) inactive_date_Prev
      ,match_option match_option_Current
       ,lag(match_option,1,null)  over (order by version_timestamp) match_option_Prev
      ,hold_all_payments_flag hold_all_payments_flag_Current
       ,lag(hold_all_payments_flag,1,null)  over (order by version_timestamp) hold_all_payments_flag_Prev
      ,terms_id terms_id_Current
       ,lag(terms_id,1,null)  over (order by version_timestamp) terms_id_Prev
      ,pay_group_lookup_code pay_group_lookup_code_Current
       ,lag(pay_group_lookup_code,1,null)  over (order by version_timestamp) pay_group_lookup_code_Prev
      ,payment_priority payment_priority_Current
       ,lag(payment_priority,1,null)  over (order by version_timestamp) payment_priority_Prev
      ,terms_date_basis terms_date_basis_Current
       ,lag(terms_date_basis,1,null)  over (order by version_timestamp) terms_date_basis_Prev
      ,payment_currency_code payment_currency_code_Current
       ,lag(payment_currency_code,1,null)  over (order by version_timestamp) payment_currency_code_Prev
      ,pay_date_basis_lookup_code pay_date_basis_code_Current
       ,lag(pay_date_basis_lookup_code,1,null)  over (order by version_timestamp) pay_date_basis_code_Prev
      ,payment_method_lookup_code payment_method_code_Current
       ,lag(payment_method_lookup_code,1,null)  over (order by version_timestamp) payment_method_code_Prev
      ,bank_account_name bank_account_name_Current
       ,lag(bank_account_name,1,null)  over (order by version_timestamp) bank_account_name_Prev
      ,bank_account_num bank_account_num_Current
       ,lag(bank_account_num,1,null)  over (order by version_timestamp) bank_account_num_Prev
      ,tax_reporting_site_flag tax_reporting_site_Current
       ,lag(tax_reporting_site_flag,1,null)  over (order by version_timestamp) tax_reporting_site_Prev
      ,always_take_disc_flag always_take_disc_flag_Current
       ,lag(always_take_disc_flag,1,null)  over (order by version_timestamp) always_take_disc_flag_Prev
      ,create_debit_memo_flag create_debit_memo_flag_Current
       ,lag(create_debit_memo_flag,1,null)  over (order by version_timestamp) create_debit_memo_flag_Prev
      ,attribute9 attribute9_Current
       ,lag(attribute9,1,null)  over (order by version_timestamp) attribute9_Prev
      ,email_address email_address_Current                                                    -- Added by Ganesan for the defect 4878
      ,lag(email_address,1,null)  over (order by version_timestamp) email_address_Prev         -- Added by Ganesan for the defect 4878
	  ----- End of changes for jira #133497
      ,last_updated_by
      ,last_update_date
      ,2 order_by_col
FROM xx_po_vendor_sites_all_aud va
WHERE va.vendor_site_id = p_vendor_site_id)
WHERE last_update_date BETWEEN p_begin_date AND p_end_date
ORDER BY last_update_date;

-------Adding below CURSOR for ap_tolerance template column audit as requested for jira NAIT-103952.Added by Bhargavi Ankolekar.

CURSOR lcu_ap_tolerance_temp_aud
IS
select PVSA.vendor_site_id
         ,PVSA.vendor_site_code
         ,PV.segment1   vendor_num
         ,PV.vendor_name
         ,PVSA.attribute9 legacy_num
         ,att.tolerance_id
from ap_supplier_sites_all PVSA,
ap_suppliers PV,
ap_tolerance_templates att
where  PV.vendor_id=PVSA.vendor_id
and att.tolerance_id= pvsa.tolerance_id
AND PVSA.last_update_date BETWEEN p_begin_date AND p_end_date;

-------Adding below CURSOR for ap_tolerance template new trigger table created as requested for jira NAIT-103952.Added by Bhargavi Ankolekar.
CURSOR lcu_ap_tol_template_aud(p_tolerance_id NUMBER) is
SELECT * FROM (
SELECT
TOLERANCE_NAME TOLERANCE_NAME_CURRENT
	  ,lag(TOLERANCE_NAME,1,null)  over (order by version_timestamp) TOLERANCE_NAME_PREV -- ----- Changing the last_update_date to version_timestamp for the jira 133497 by Rahul Y
,last_updated_by
      ,last_update_date
      ,2 order_by_col
FROM XX_AP_TOLERANCE_TEMP_AUD_V1 xata
WHERE  xata.TOLERANCE_ID= p_tolerance_id)
WHERE last_update_date BETWEEN p_begin_date AND p_end_date
ORDER BY last_update_date;


lr_vendor_rec        lcu_changed_vendor_sites%ROWTYPE;
lr_vendor_aud_rec    lcu_vendor_sites_aud%ROWTYPE;
lcu_vend_sites_add_aud_rec lcu_vend_sites_add_aud%ROWTYPE;
lcu_vd_sites_add_aud_rec lcu_vd_sites_add_aud%ROWTYPE;
lcu_vdsite_iby_col_rec lcu_vdsite_iby_col_aud%ROWTYPE;
lcu_vdsite_add_colpay lcu_vdsite_add_col_aud%ROWTYPE;
lcu_po_vdsite_kff_rec lcu_po_vend_site_kff%rowtype;
lcu_po_vdsite_aud_kff_rec lcu_po_vdsite_aud_kff%rowtype;

lcu_xxap_cust_tol_aud_rec lcu_xxap_cust_tol_aud%rowtype;
lcu_xxap_cust_tol_aud_comp_rec lcu_xxap_cust_tol_aud_comp%rowtype;
lcu_ap_tol_temp_aud_rec lcu_ap_tolerance_temp_aud%ROWTYPE;
lcu_ap_tol_template_aud_rec lcu_ap_tol_template_aud%ROWTYPE;


lc_terms_name_pre             ap_terms.name%TYPE;
lc_terms_name_cur             ap_terms.name%TYPE;

lc_liability_acct_num_pre gl_code_combinations.segment3%TYPE;
lc_liability_acct_num_cur gl_code_combinations.segment3%TYPE;

BEGIN
--------for loop added for ap tolerance column audit for jira NAIT-103952.Added by Bhargavi Ankolekar.
FOR lcu_ap_tol_temp_aud_rec IN lcu_ap_tolerance_temp_aud
LOOP
FOR lcu_ap_tol_template_aud_rec IN lcu_ap_tol_template_aud(lcu_ap_tol_temp_aud_rec.tolerance_id)
LOOP

IF (NVL(lcu_ap_tol_template_aud_rec.TOLERANCE_NAME_CURRENT,'X') <> NVL(lcu_ap_tol_template_aud_rec.TOLERANCE_NAME_PREV,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_ap_tol_temp_aud_rec.vendor_num
                            ,lcu_ap_tol_temp_aud_rec.vendor_name
                            ,lcu_ap_tol_temp_aud_rec.vendor_site_code
                            ,lcu_ap_tol_temp_aud_rec.legacy_num
                            ,lcu_ap_tol_template_aud_rec.last_updated_by
                            ,lcu_ap_tol_template_aud_rec.last_update_date
                            ,'TOLERANCE_NAME'
                            ,lcu_ap_tol_template_aud_rec.TOLERANCE_NAME_PREV
                            ,lcu_ap_tol_template_aud_rec.TOLERANCE_NAME_CURRENT
                               ,'AUDIT'
                            ,lcu_ap_tol_template_aud_rec.order_by_col);					

END IF;

end loop;
end loop;
-----------for loop ends here.Added for ap tolerance column audit for jira NAIT-103952.Added by Bhargavi Ankolekar.

--------for loop added for ap custom tolerance column audit for jira NAIT-103952.Added by Bhargavi Ankolekar.

FOR lcu_xxap_cust_tol_aud_rec IN lcu_xxap_cust_tol_aud
LOOP
FOR lcu_xxap_cust_tol_aud_comp_rec IN lcu_xxap_cust_tol_aud_comp(lcu_xxap_cust_tol_aud_rec.supplier_site_id)
LOOP

IF (NVL(lcu_xxap_cust_tol_aud_comp_rec.FAVOURABLE_PRICE_PCT_Cur,'0') <> NVL(lcu_xxap_cust_tol_aud_comp_rec.FAVOURABLE_PRICE_PCT_Prev,'0')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_xxap_cust_tol_aud_rec.vendor_num
                            ,lcu_xxap_cust_tol_aud_rec.vendor_name
                            ,lcu_xxap_cust_tol_aud_rec.vendor_site_code
                            ,lcu_xxap_cust_tol_aud_rec.legacy_num
                            ,lcu_xxap_cust_tol_aud_comp_rec.last_updated_by
                            ,lcu_xxap_cust_tol_aud_comp_rec.last_update_date
                            ,'FAVOURABLE_PRICE_PCT'
                            ,lcu_xxap_cust_tol_aud_comp_rec.FAVOURABLE_PRICE_PCT_Prev
                            ,lcu_xxap_cust_tol_aud_comp_rec.FAVOURABLE_PRICE_PCT_Cur
                               ,'AUDIT'
                            ,lcu_xxap_cust_tol_aud_comp_rec.order_by_col);					

END IF;

IF (NVL(lcu_xxap_cust_tol_aud_comp_rec.MAX_PRICE_AMT_Cur,'0') <> NVL(lcu_xxap_cust_tol_aud_comp_rec.MAX_PRICE_AMT_Prev,'0')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_xxap_cust_tol_aud_rec.vendor_num
                            ,lcu_xxap_cust_tol_aud_rec.vendor_name
                            ,lcu_xxap_cust_tol_aud_rec.vendor_site_code
                            ,lcu_xxap_cust_tol_aud_rec.legacy_num
                            ,lcu_xxap_cust_tol_aud_comp_rec.last_updated_by
                            ,lcu_xxap_cust_tol_aud_comp_rec.last_update_date
                            ,'MAX_PRICE_AMT'
                            ,lcu_xxap_cust_tol_aud_comp_rec.MAX_PRICE_AMT_Prev
                            ,lcu_xxap_cust_tol_aud_comp_rec.MAX_PRICE_AMT_Cur
                               ,'AUDIT'
                            ,lcu_xxap_cust_tol_aud_comp_rec.order_by_col);					

END IF;

end loop;
end loop;
-----------for loop ends here.Added for ap custom tolerance column audit for jira NAIT-103952.Added by Bhargavi Ankolekar.

-------Adding for loop for vendor kff column audit.This is added for jira NAIT-103952.Added by Bhargavi Ankolekar.

FOR lcu_po_vdsite_kff_rec IN lcu_po_vend_site_kff
LOOP
FOR lcu_po_vdsite_aud_kff_rec IN lcu_po_vdsite_aud_kff(lcu_po_vdsite_kff_rec.attribute10 , null, null)
LOOP
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT1_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT1_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Lead Time'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT1_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT1_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT2_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT2_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Back Order Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT2_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT2_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;


if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT3_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT3_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Deliver Policy'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT3_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT3_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT4_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT4_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Mini Prepaid Code'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT4_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT4_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;


if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT5_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT5_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Vendor Min Amount'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT5_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT5_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT11_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT11_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'EFT Settle Days'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT11_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT11_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT13_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT13_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Master Vendor ID'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT13_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT13_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT14_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT14_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'PI Pack Year'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT14_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT14_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT15_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT15_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'OD Date Signed'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT15_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT15_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT16_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT16_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Vendor Date Signed'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT16_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT16_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT17_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT17_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Dedut from Invoice Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT17_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT17_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

end loop;

FOR lcu_po_vdsite_aud_kff_rec IN lcu_po_vdsite_aud_kff(null,null,lcu_po_vdsite_kff_rec.attribute12)
loop
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT60_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT60_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'OD Vendor Sign Title'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT60_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT60_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT40_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT40_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'RTV option'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT40_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT40_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;


if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT42_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT42_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Permanent RGA'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT42_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT42_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT43_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT43_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Destroy Allow Amount'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT43_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT43_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT44_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT44_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Payment Frequency'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT44_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT44_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT47_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT47_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Damage/Destroy Limit'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT47_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT47_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT50_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT50_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'RGA Marked Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT50_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT50_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT51_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT51_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Remove Price Sticker Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT51_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT51_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT52_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT52_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Contact Supplier for RGA'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT52_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT52_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT53_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT53_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Destroy Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT53_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT53_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT54_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT54_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Serial # Required Flag'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT54_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT54_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT55_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT55_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'Obsolute Item'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT55_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT55_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT58_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT58_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'RTV Related Site'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT58_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT58_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;
end loop;

FOR lcu_po_vdsite_aud_kff_rec IN lcu_po_vdsite_aud_kff(null, lcu_po_vdsite_kff_rec.attribute11, null)
loop
if (NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT37_cur,'X') <> NVL(lcu_po_vdsite_aud_kff_rec.SEGMENT37_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_po_vdsite_kff_rec.vendor_num
                            ,lcu_po_vdsite_kff_rec.vendor_name
                            ,lcu_po_vdsite_kff_rec.vendor_site_code
                            ,lcu_po_vdsite_kff_rec.legacy_num
                            ,lcu_po_vdsite_aud_kff_rec.last_updated_by
                            ,lcu_po_vdsite_aud_kff_rec.last_update_date
                            ,'EDI Distribution code'
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT37_prev
                            ,lcu_po_vdsite_aud_kff_rec.SEGMENT37_cur
                               ,'AUDIT'
                            ,lcu_po_vdsite_aud_kff_rec.order_by_col);					

END IF;

end loop;
end loop;


-------for loop for vendor kff column audit ends here.This is added for jira NAIT-103952.Added by Bhargavi Ankolekar.



-------Adding for loop for iby external payees column audit.This is added for jira NAIT-103952.Added by Bhargavi Ankolekar.

FOR lcu_vdsite_iby_col_rec IN lcu_vdsite_iby_col_aud
LOOP
FOR lcu_vdsite_add_colpay IN lcu_vdsite_add_col_aud(lcu_vdsite_iby_col_rec.supplier_site_id)
LOOP

IF (NVL(lcu_vdsite_add_colpay.PAYMENT_FORMAT_CODE_CURRENT,'X') <> NVL(lcu_vdsite_add_colpay.PAYMENT_FORMAT_CODE_PREV,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'PAYMENT_FORMAT_CODE'
                            ,lcu_vdsite_add_colpay.PAYMENT_FORMAT_CODE_PREV
                            ,lcu_vdsite_add_colpay.PAYMENT_FORMAT_CODE_CURRENT
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;

IF (NVL(lcu_vdsite_add_colpay.PAYMENT_REASON_CODE_CURRENT,'X') <> NVL(lcu_vdsite_add_colpay.PAYMENT_REASON_CODE_PREV,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'PAYMENT_REASON_CODE'
                            ,lcu_vdsite_add_colpay.PAYMENT_REASON_CODE_PREV
                            ,lcu_vdsite_add_colpay.PAYMENT_REASON_CODE_CURRENT
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;

IF (NVL(lcu_vdsite_add_colpay.PAYMENT_REASON_COMMENTS_CURR,'X') <> NVL(lcu_vdsite_add_colpay.PAYMENT_REASON_COMMENTS_PREV,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'PAYMENT_REASON_COMMENTS'
                            ,lcu_vdsite_add_colpay.PAYMENT_REASON_COMMENTS_PREV
                            ,lcu_vdsite_add_colpay.PAYMENT_REASON_COMMENTS_CURR
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;

IF (NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_DELIVERY_METHOD_C,'X') <> NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_DELIVERY_METHOD_P,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'REMIT_ADVICE_DELIVERY_METHOD'
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_DELIVERY_METHOD_P
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_DELIVERY_METHOD_C
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;

IF (NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_EMAIL_Current,'X') <> NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_EMAIL_Prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'REMIT_ADVICE_EMAIL'
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_EMAIL_Prev
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_EMAIL_Current
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;

IF (NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_FAX_Current,'X') <> NVL(lcu_vdsite_add_colpay.REMIT_ADVICE_FAX_Prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vdsite_iby_col_rec.vendor_num
                            ,lcu_vdsite_iby_col_rec.vendor_name
                            ,lcu_vdsite_iby_col_rec.vendor_site_code
                            ,lcu_vdsite_iby_col_rec.legacy_num
                            ,lcu_vdsite_add_colpay.last_updated_by
                            ,lcu_vdsite_add_colpay.last_update_date
                            ,'REMIT_ADVICE_FAX'
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_FAX_Prev
                            ,lcu_vdsite_add_colpay.REMIT_ADVICE_FAX_Current
                               ,'AUDIT'
                            ,lcu_vdsite_add_colpay.order_by_col);					

END IF;
end loop;
end loop;
-------loop ends here.This is for jira NAIT-103952.Added by Bhargavi Ankolekar.


-------Adding loop as requested for jira NAIT-103952.Added by Bhargavi Ankolekar.
FOR lcu_vend_sites_add_aud_rec IN lcu_vend_sites_add_aud
LOOP
FOR lcu_vd_sites_add_aud_rec IN lcu_vd_sites_add_aud(lcu_vend_sites_add_aud_rec.vendor_site_id)
LOOP

IF (NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE4_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE4_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'Consignment Frequency'
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE4_prev
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE4_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE5_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE5_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'DUNS#'
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE5_prev
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE5_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE8_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.ATTRIBUTE8_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'Site category'
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE8_prev
                            ,lcu_vd_sites_add_aud_rec.ATTRIBUTE8_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.ORG_ID_cur,0) <> NVL(lcu_vd_sites_add_aud_rec.ORG_ID_prev,0)) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'Operating Unit'
                            ,lcu_vd_sites_add_aud_rec.ORG_ID_prev
                            ,lcu_vd_sites_add_aud_rec.ORG_ID_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.TELEX_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.TELEX_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'TELEX'
                            ,lcu_vd_sites_add_aud_rec.TELEX_prev
                            ,lcu_vd_sites_add_aud_rec.TELEX_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.VENDOR_SITE_CODE_ALT_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.VENDOR_SITE_CODE_ALT_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'VENDOR_SITE_CODE_ALT'
                            ,lcu_vd_sites_add_aud_rec.VENDOR_SITE_CODE_ALT_prev
                            ,lcu_vd_sites_add_aud_rec.VENDOR_SITE_CODE_ALT_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

IF (NVL(lcu_vd_sites_add_aud_rec.LANGUAGE_cur,'X') <> NVL(lcu_vd_sites_add_aud_rec.LANGUAGE_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lcu_vend_sites_add_aud_rec.vendor_num
                            ,lcu_vend_sites_add_aud_rec.vendor_name
                            ,lcu_vend_sites_add_aud_rec.vendor_site_code
                            ,lcu_vend_sites_add_aud_rec.legacy_num
                            ,lcu_vd_sites_add_aud_rec.last_updated_by
                            ,lcu_vd_sites_add_aud_rec.last_update_date
                            ,'LANGUAGE'
                            ,lcu_vd_sites_add_aud_rec.LANGUAGE_prev
                            ,lcu_vd_sites_add_aud_rec.LANGUAGE_cur
                               ,'AUDIT'
                            ,lcu_vd_sites_add_aud_rec.order_by_col);
END IF;

END LOOP;
END LOOP;

------ loop for jira NAIT-103952 ends here.Added by Bhargavi Ankolekar.

FOR lr_vendor_rec IN lcu_changed_vendor_sites
LOOP
FOR lr_vendor_aud_rec IN lcu_vendor_sites_aud(lr_vendor_rec.vendor_site_id)
LOOP

IF (NVL(lr_vendor_aud_rec.vendor_site_code_Current,'X') <> NVL(lr_vendor_aud_rec.vendor_site_code_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'SITE NAME'
                            ,lr_vendor_aud_rec.vendor_site_code_prev
                            ,lr_vendor_aud_rec.vendor_site_code_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;
/*
   Added by Ganesan for the Defect 4878 for showing the changes in Pay/Purchasing Flags properly.
*/

IF (NVL(lr_vendor_aud_rec.site_uses_flag_Current,'X') <> NVL(lr_vendor_aud_rec.site_uses_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'SITE USES'
                            ,lr_vendor_aud_rec.site_uses_flag_prev
                            ,lr_vendor_aud_rec.site_uses_flag_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

/*IF (NVL(lr_vendor_aud_rec.pay_site_flag_Current,'X') <> NVL(lr_vendor_aud_rec.pay_site_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'SITE USES '
                            ,lr_vendor_aud_rec.pay_site_flag_prev
                            ,lr_vendor_aud_rec.pay_site_flag_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;*/

IF (NVL(lr_vendor_aud_rec.code_combination_id_Current,0) <> NVL(lr_vendor_aud_rec.code_combination_id_prev,0)) THEN

lc_liability_acct_num_pre := GET_LIABILITY_ACCT_NUM(lr_vendor_aud_rec.code_combination_id_prev);

lc_liability_acct_num_cur := GET_LIABILITY_ACCT_NUM(lr_vendor_aud_rec.code_combination_id_current);

IF (lc_liability_acct_num_pre <> lc_liability_acct_num_cur) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'LIABILITY ACCOUNT NUMBER'
                            ,lc_liability_acct_num_pre
                            ,lc_liability_acct_num_cur
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;
END IF;

/*IF (NVL(lr_vendor_aud_rec.purchasing_site_flag_Current,'X') <> NVL(lr_vendor_aud_rec.purchasing_site_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'SITE USES '
                            ,lr_vendor_aud_rec.purchasing_site_flag_prev
                            ,lr_vendor_aud_rec.purchasing_site_flag_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;*/

IF (NVL(lr_vendor_aud_rec.area_Current,'X') <> NVL(lr_vendor_aud_rec.area_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'AREA CODE'
                            ,lr_vendor_aud_rec.area_prev
                            ,lr_vendor_aud_rec.area_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.email_address_Current,'X') <> NVL(lr_vendor_aud_rec.email_address_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'EMAIL ADDRESS'
                            ,lr_vendor_aud_rec.email_address_prev
                            ,lr_vendor_aud_rec.email_address_Current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.address_line1_Current,'X') <> NVL(lr_vendor_aud_rec.address_line1_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'ADDRESS_LINE1'
                            ,lr_vendor_aud_rec.address_line1_prev
                            ,lr_vendor_aud_rec.address_line1_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.address_line2_Current,'X') <> NVL(lr_vendor_aud_rec.address_line2_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'ADDRESS_LINE2'
                            ,lr_vendor_aud_rec.address_line2_prev
                            ,lr_vendor_aud_rec.address_line2_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.address_line3_Current,'X') <> NVL(lr_vendor_aud_rec.address_line3_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'ADDRESS_LINE3'
                            ,lr_vendor_aud_rec.address_line3_prev
                            ,lr_vendor_aud_rec.address_line3_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.city_Current,'X') <> NVL(lr_vendor_aud_rec.city_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'CITY'
                            ,lr_vendor_aud_rec.city_prev
                            ,lr_vendor_aud_rec.city_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.state_Current,'X') <> NVL(lr_vendor_aud_rec.state_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'STATE'
                            ,lr_vendor_aud_rec.state_prev
                            ,lr_vendor_aud_rec.state_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.province_Current,'X') <> NVL(lr_vendor_aud_rec.province_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PROVINCE'
                            ,lr_vendor_aud_rec.province_prev
                            ,lr_vendor_aud_rec.province_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.zip_Current,'X') <> NVL(lr_vendor_aud_rec.zip_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'POSTAL'
                            ,lr_vendor_aud_rec.zip_prev
                            ,lr_vendor_aud_rec.zip_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.inactive_date_Current,'01-JAN-1900') <> NVL(lr_vendor_aud_rec.inactive_date_prev,'01-JAN-1900')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'INACTIVE DATE'
                            ,lr_vendor_aud_rec.inactive_date_prev
                            ,lr_vendor_aud_rec.inactive_date_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.match_option_Current,'X') <> NVL(lr_vendor_aud_rec.match_option_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'INVOICE MATCH OPTION'
                            ,lr_vendor_aud_rec.match_option_prev
                            ,lr_vendor_aud_rec.match_option_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.hold_all_payments_flag_Current,'X') <> NVL(lr_vendor_aud_rec.hold_all_payments_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAYMENT HOLD'
                            ,lr_vendor_aud_rec.hold_all_payments_flag_prev
                            ,lr_vendor_aud_rec.hold_all_payments_flag_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.terms_id_Current,0) <> NVL(lr_vendor_aud_rec.terms_id_prev,0)) THEN

lc_terms_name_pre := GET_TERMS_NAME(lr_vendor_aud_rec.terms_id_prev);
lc_terms_name_cur := GET_TERMS_NAME(lr_vendor_aud_rec.terms_id_current);

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAYMENT TERMS'
                            ,lc_terms_name_pre                    -- Added by Ganesan for defect# 4878
                            ,lc_terms_name_cur                    -- Added by Ganesan for defect# 4878
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.pay_group_lookup_code_Current,'X') <> NVL(lr_vendor_aud_rec.pay_group_lookup_code_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAYMENT GROUP'
                            ,lr_vendor_aud_rec.pay_group_lookup_code_prev
                            ,lr_vendor_aud_rec.pay_group_lookup_code_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.payment_priority_Current,0) <> NVL(lr_vendor_aud_rec.payment_priority_prev,0)) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAYMENT PRIORITY'
                            ,lr_vendor_aud_rec.payment_priority_prev
                            ,lr_vendor_aud_rec.payment_priority_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.terms_date_basis_Current,'X') <> NVL(lr_vendor_aud_rec.terms_date_basis_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'TERMS DATE  BASIS'
                            ,lr_vendor_aud_rec.terms_date_basis_prev
                            ,lr_vendor_aud_rec.terms_date_basis_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.payment_currency_code_Current,'X') <> NVL(lr_vendor_aud_rec.payment_currency_code_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'CURRENCY'
                            ,lr_vendor_aud_rec.payment_currency_code_prev
                            ,lr_vendor_aud_rec.payment_currency_code_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.pay_date_basis_code_Current,'X') <> NVL(lr_vendor_aud_rec.pay_date_basis_code_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAY DATE  BASIS'
                            ,lr_vendor_aud_rec.pay_date_basis_code_prev
                            ,lr_vendor_aud_rec.pay_date_basis_code_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.payment_method_code_Current,'X') <> NVL(lr_vendor_aud_rec.payment_method_code_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'PAYMENT METHOD'
                            ,lr_vendor_aud_rec.payment_method_code_prev
                            ,lr_vendor_aud_rec.payment_method_code_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.bank_account_name_Current,'X') <> NVL(lr_vendor_aud_rec.bank_account_name_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'BANK'
                            ,lr_vendor_aud_rec.bank_account_name_prev
                            ,lr_vendor_aud_rec.bank_account_name_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.bank_account_num_Current,'X') <> NVL(lr_vendor_aud_rec.bank_account_num_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'ACCOUNT NUMBER'
                            ,lr_vendor_aud_rec.bank_account_num_prev
                            ,lr_vendor_aud_rec.bank_account_num_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.tax_reporting_site_Current,'X') <> NVL(lr_vendor_aud_rec.tax_reporting_site_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'INCOME TAX REPORTING SITE FLAG'
                            ,lr_vendor_aud_rec.tax_reporting_site_prev
                            ,lr_vendor_aud_rec.tax_reporting_site_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.always_take_disc_flag_Current,'X') <> NVL(lr_vendor_aud_rec.always_take_disc_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'ALWAYS TAKE DISCOUNT FLAG'
                            ,lr_vendor_aud_rec.always_take_disc_flag_prev
                            ,lr_vendor_aud_rec.always_take_disc_flag_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.create_debit_memo_flag_Current,'X') <> NVL(lr_vendor_aud_rec.create_debit_memo_flag_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'CREATE DEBIT MEMO FLAG'
                            ,lr_vendor_aud_rec.create_debit_memo_flag_prev
                            ,lr_vendor_aud_rec.create_debit_memo_flag_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

IF (NVL(lr_vendor_aud_rec.attribute9_Current,'X') <> NVL(lr_vendor_aud_rec.attribute9_prev,'X')) THEN

INSERT INTO xx_ap_supplier_temp(supplier_number,
                           supplier_name,
                           site_id_num,
                           legacy_num,
                           changed_by,
                           date_changed,
                           changed_field,
                           changed_from,
                           changed_to,
                                 flag,
                           order_by_col)
             VALUES       ( lr_vendor_rec.vendor_num
                            ,lr_vendor_rec.vendor_name
                            ,lr_vendor_rec.vendor_site_code
                            ,lr_vendor_rec.legacy_num
                            ,lr_vendor_aud_rec.last_updated_by
                            --,rec_main.last_update_date
                            ,lr_vendor_aud_rec.last_update_date
                            ,'LEGACY VENDOR NUMBER'
                            ,lr_vendor_aud_rec.attribute9_prev
                            ,lr_vendor_aud_rec.attribute9_current
                               ,'AUDIT'
                            ,lr_vendor_aud_rec.order_by_col);
END IF;

END LOOP;
END LOOP;

END PROCESS_VENDOR_SITES;

PROCEDURE ap_flash_back(p_begin_date DATE
            ,p_end_date DATE) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot                             |
-- +===================================================================+
-- | Name             :  ap_flash_back                                     |
-- | Description      :  This Procedure is used to Populate the        |
-- |                     vendor, vendor sites and audit details        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 31-AUG-2007 Kantharaja       Initial draft version       |
-- |V1.1      13-JAN-08   Aravind A.       Fixed defect 4345           |
-- |V1.2      23-JUL-08   Senthil Kumar    Handled exception per       |
-- |                                       standard                    |
-- |V1.3      20-MAY-2014 Avinash Baddam   Fix for defect 30042	       |
-- +===================================================================+

CURSOR   lcu_SS IS
SELECT   VSA.vendor_site_code
         ,VA.segment1
     ,VSA.vendor_id
     ,SUBSTR(VA.vendor_name,1,30) vendor_name----Changed by Kantharja for 2560
     ,VSA.purchasing_site_flag
     ,VSA.pay_site_flag
    ,VSA.vendor_site_id
     ,VSA.attribute9
     ,VSA.area_code||'-'||VSA.phone  area_code-----Changed by Kantharja for 2560
    --,VSA.phone-----Changed by Kantharja for 2560
     ,VSA.address_line1
     ,VSA.address_line2
     ,VSA.address_line3
     ,VSA.city
     ,VSA.state
     ,VSA.zip
     ,VSA.province
     ,VSA.inactive_date
     ,VSA.payment_priority
     ,GLA.segment3
     ,VSA.hold_all_payments_flag
     ,APT.name  terms_id-----Changed by Kantharja for 2560
     ,VSA.pay_group_lookup_code
     ,VSA.terms_date_basis
     ,VSA.payment_currency_code
     ,VSA.pay_date_basis_lookup_code
     ,VSA.payment_method_lookup_code
     ,VSA.bank_account_name-----Changed by Kantharja for 2560
     ,VSA.bank_account_num-----Changed by Kantharja for 2560
     ,VSA.create_debit_memo_flag
     ,vsa.created_by created_by
FROM     -- Changed Table Name on 7/1/2013 by Sravanthi Surya as part of R12 Upgrade 
         -- po_vendor_sites_all               VSA
         --- po_vendors pv
          ap_supplier_sites_all VSA
         ,ap_suppliers                     VA
         ,gl_code_combinations           GLA
         ,ap_terms                        APT
WHERE    VSA.accts_pay_code_combination_id = gla.code_combination_id
AND      VSA.vendor_id = VA.vendor_id
AND      APT.term_id=VSA.terms_id-----added by Kantharja
AND      VSA.creation_date BETWEEN p_begin_date AND p_end_date -----Changed by Kantharja for 2560
--AND      VSA.creation_date = VSA.last_update_date              -----Changed by Kantharja for 2560
--AND      VSA.org_id = FND_PROFILE.VALUE('ORG_ID')              -- Commented by Ganesan for defect 4878 to show the data irrespective of the operating unit
ORDER BY VSA.vendor_site_code
         ,VA.segment1     DESC;
         
         
l_payment_method_code VARCHAR2(30);

CURSOR pay_method_cur(l_vendor_site_id NUMBER) IS
   SELECT ieppm.payment_method_code
     FROM iby_external_payees_all iepa,
          iby_ext_party_pmt_mthds ieppm
    WHERE iepa.ext_payee_id = ieppm.ext_pmt_party_id
      AND( (ieppm.inactive_date IS NULL)or (ieppm.inactive_date > sysdate))
      AND ieppm.primary_flag = 'Y'
      AND iepa.supplier_site_id= l_vendor_site_id;
      
CURSOR default_pay_method_cur IS
   SELECT payment_method_code 
     FROM  iby_payment_rules 
    WHERE application_id = 200;
    
       BEGIN

       PROCESS_VENDORS(p_begin_date,p_end_date);

       PROCESS_VENDOR_SITES(p_begin_date,p_end_date);

---------INSERT STATEMENT FOR VENDOR SITES
FOR rec_SS IN lcu_SS
LOOP
--- SITE USE
                   INSERT INTO xx_ap_supplier_temp (
                        SUPPLIER_NUMBER
                        ,SITE_ID_NUM
                        ,SITE_ID                      ---- Added by Ganesan for including the Site_ID
                        ,legacy_num
                        ,CHANGED_BY
                        ,CHANGED_FIELD
                        ,CHANGED_FROM
                        ,FLAG)
                    VALUES(
                           rec_SS.segment1
                        ,rec_SS.vendor_site_code
                           ,rec_SS.vendor_site_id
                          ,rec_SS.vendor_name
                           ,rec_SS.created_by
                           ,'Site Use'
                             ,DECODE(NVL(rec_SS.purchasing_site_flag,'N'), 'Y', 'PUR ')||DECODE(NVL(rec_SS.pay_site_flag,'N'), 'Y', 'PAY')  -- Changed by Ganesan from 'PURCHASING to PUR', and handling NULL Values.
                           ,'SS');
--- SITE ID-----Changed by Kantharja
                 /*  INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
                rec_SS.vendor_site_code
            ,rec_SS.segment1
                ,rec_SS.vendor_name
            ,rec_SS.created_by
            ,'Site ID'
            ,rec_SS.vendor_site_id
            ,'SS');*/
--- LEGACY VENDOR#-----Changed by Kantharja
                   /*INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID
                        ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
                rec_SS.vendor_site_code
            ,rec_SS.segment1
                ,rec_SS.vendor_name
            ,rec_SS.created_by
            ,'Legacy Vendor #'
            ,rec_SS.attribute9
            ,'SS');*/
--- VOICE/AREA CODE
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
         ,SITE_ID  ---- Added by Ganesan for including the Site_ID
            ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Voice/Area Code'
            ,rec_SS.area_code
            ,'SS');
--- CREATE DEBIT MEMO
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
                ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Create Debit Memo'
            ,rec_SS.create_debit_memo_flag
            ,'SS');
            
            
--- PAYMENT METHOD

          --For defect 30042
          l_payment_method_code := null;
          OPEN pay_method_cur(rec_SS.vendor_site_id);
          FETCH pay_method_cur INTO l_payment_method_code;
          CLOSE pay_method_cur;
          
          IF l_payment_method_code IS NULL THEN
             OPEN default_pay_method_cur;
             FETCH default_pay_method_cur INTO l_payment_method_code;
             CLOSE default_pay_method_cur;
          END IF;

            INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
            VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
            ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
            ,rec_SS.created_by
            ,'Payment Method'
            ,l_payment_method_code
            ,'SS');
--- PAY DATE BASIS
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Pay Date Basis'
            ,rec_SS.pay_date_basis_lookup_code
            ,'SS');
--- CURRENCY
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Currency'
            ,rec_SS.payment_currency_code
            ,'SS');
--- TERMS DATE BASIS
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Terms Date Basis'
            ,rec_SS.terms_date_basis
            ,'SS');
--- PAYMENT PRIORITY
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Payment Priority'
            ,rec_SS.payment_priority
            ,'SS');
--- PAYMENT GROUP
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Payment Group'
            ,rec_SS.pay_group_lookup_code
            ,'SS');
--- PAYMENT TERMS
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Payment Terms'
            ,rec_SS.terms_id
                        --,rec_SS.terms-----Changed by Kantharja
            ,'SS');
--- HOLD ALL PAYMENTS
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID  ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Hold All Payments'
            ,rec_SS.hold_all_payments_flag
            ,'SS');
--- LIABILITY ACCOUNT NUMBER
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Liability Account #'
            ,rec_SS.segment3
            ,'SS');
--- INACTIVE DATE
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Inactive Date'
            ,rec_SS.inactive_date
            ,'SS');
--- POSTAL
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Postal'
            ,rec_SS.zip
            ,'SS');
--- PROVINCE
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Province'
            ,rec_SS.province
            ,'SS');
--- STATE
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'State'
            ,rec_SS.state
            ,'SS');
--- CITY
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'City'
            ,rec_SS.city
            ,'SS');
--- ADDRESS LINE 3
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Address Line 3'
            ,rec_SS.address_line3
            ,'SS');
--- ADDRESS LINE 2
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Address Line 2'
            ,rec_SS.address_line2
            ,'SS');
--- BANK-----Changed by Kantharja
                  /* INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
                rec_SS.vendor_site_code
            ,rec_SS.segment1
                ,rec_SS.vendor_name
            ,rec_SS.created_by
            ,'Bank'
            ,rec_SS.bank_account_name
            ,'SS');
--- ACCOUNT NUMBER-----Changed by Kantharja
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
                rec_SS.vendor_site_code
            ,rec_SS.segment1
                ,rec_SS.vendor_name
            ,rec_SS.created_by
            ,'Account Number'
            ,rec_SS.bank_account_num
            ,'SS');*/
---- ADDRESS LINE 1
                   INSERT INTO xx_ap_supplier_temp (
            SUPPLIER_NUMBER
            ,SITE_ID_NUM
            ,SITE_ID   ---- Added by Ganesan for including the Site_ID
         ,legacy_num
            ,CHANGED_BY
            ,CHANGED_FIELD
            ,CHANGED_FROM
            ,FLAG)
                    VALUES(
            rec_SS.segment1
            ,rec_SS.vendor_site_code
           ,rec_SS.vendor_site_id
            ,rec_SS.vendor_name
         ,rec_SS.created_by
            ,'Address Line 1'
            ,rec_SS.address_line1
            ,'SS');
END LOOP;
END ap_flash_back;
/*
   Functions added by Ganesan for the defect 2239
*/
FUNCTION GET_TERMS_NAME(P_TERMS_ID NUMBER)
RETURN VARCHAR2 IS
lc_term_name ap_terms.name%TYPE;
BEGIN
IF(p_terms_id IS NOT NULL) THEN
 BEGIN
   SELECT name
   INTO lc_term_name
      FROM ap_terms
      WHERE term_id = p_terms_id;
RETURN lc_term_name;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the Term name');
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||SQLERRM);
  END;
ELSE
RETURN NULL;
END IF;
END;

FUNCTION GET_LIABILITY_ACCT_NUM(P_CC_ID NUMBER)
RETURN VARCHAR2 IS
lc_liability_acct_num  gl_code_combinations.segment3%TYPE;
BEGIN
IF (p_cc_id IS NOT NULL) THEN
 BEGIN
   SELECT segment3
   INTO lc_liability_acct_num
      FROM gl_code_combinations
      WHERE code_combination_id = p_cc_id;
RETURN lc_liability_acct_num;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the Liability Account Number');
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||SQLERRM);
  END;
ELSE
RETURN NULL;
END IF;
END;

-- Changed the Function Definition for showing the Data in Order for defect 4878.
  FUNCTION VENDOR_SEQ(P_TRANSLATION_NAME IN VARCHAR2,P_SRC_VALUE IN VARCHAR2) RETURN VARCHAR2
  IS
    X_TARGET_VALUE1        VARCHAR2(2000);
    X_TARGET_VALUE2        VARCHAR2(2000);
    X_TARGET_VALUE3        VARCHAR2(2000);
    X_TARGET_VALUE4        VARCHAR2(2000);
    X_TARGET_VALUE5        VARCHAR2(2000);
    X_TARGET_VALUE6        VARCHAR2(2000);
    X_TARGET_VALUE7        VARCHAR2(2000);
    X_TARGET_VALUE8        VARCHAR2(2000);
    X_TARGET_VALUE9        VARCHAR2(2000);
    X_TARGET_VALUE10       VARCHAR2(2000);
    X_TARGET_VALUE11       VARCHAR2(2000);
    X_TARGET_VALUE12       VARCHAR2(2000);
    X_TARGET_VALUE13       VARCHAR2(2000);
    X_TARGET_VALUE14       VARCHAR2(2000);
    X_TARGET_VALUE15       VARCHAR2(2000);
    X_TARGET_VALUE16       VARCHAR2(2000);
    X_TARGET_VALUE17       VARCHAR2(2000);
    X_TARGET_VALUE18       VARCHAR2(2000);
    X_TARGET_VALUE19       VARCHAR2(2000);
    X_TARGET_VALUE20       VARCHAR2(2000);
    X_ERROR_MESSAGE        VARCHAR2(2000);
   begin
    xx_fin_translate_pkg.XX_FIN_TRANSLATEVALUE_PROC(P_TRANSLATION_NAME =>   P_TRANSLATION_NAME
                                                    ,P_SOURCE_VALUE1   =>   P_SRC_VALUE--'ADDRESS_LINE2'
                                                    ,  X_TARGET_VALUE1 =>   X_TARGET_VALUE1
                                                     , X_TARGET_VALUE2 =>   X_TARGET_VALUE2
                                                     , X_TARGET_VALUE3 =>   X_TARGET_VALUE3
                                                     , X_TARGET_VALUE4 =>   X_TARGET_VALUE4
                                                     , X_TARGET_VALUE5 =>   X_TARGET_VALUE5
                                                     , X_TARGET_VALUE6 =>   X_TARGET_VALUE6
                                                     , X_TARGET_VALUE7 =>   X_TARGET_VALUE7
                                                     , X_TARGET_VALUE8 =>   X_TARGET_VALUE8
                                                     , X_TARGET_VALUE9 =>   X_TARGET_VALUE9
                                                     , X_TARGET_VALUE10=>   X_TARGET_VALUE10
                                                     , X_TARGET_VALUE11 =>  X_TARGET_VALUE11
                                                     , X_TARGET_VALUE12 =>  X_TARGET_VALUE12
                                                     , X_TARGET_VALUE13 =>  X_TARGET_VALUE13
                                                     , X_TARGET_VALUE14 =>  X_TARGET_VALUE14
                                                     , X_TARGET_VALUE15 =>  X_TARGET_VALUE15
                                                     , X_TARGET_VALUE16 =>  X_TARGET_VALUE16
                                                     , X_TARGET_VALUE17 =>  X_TARGET_VALUE17
                                                     , X_TARGET_VALUE18 =>  X_TARGET_VALUE18
                                                     , X_TARGET_VALUE19 =>  X_TARGET_VALUE19
                                                     ,X_TARGET_VALUE20  =>  X_TARGET_VALUE20
                                                     , X_ERROR_MESSAGE  =>  X_ERROR_MESSAGE );
   RETURN X_TARGET_VALUE1;

   --dbms_output.put_line(X_TARGET_VALUE1);
   --dbms_output.put_line(X_TARGET_VALUE2);
   END VENDOR_SEQ;

END xxod_ap_supplier_audit_pkg;
/
show errors;
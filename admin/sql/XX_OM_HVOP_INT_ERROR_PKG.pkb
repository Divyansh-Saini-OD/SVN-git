create or replace 
PACKAGE BODY XX_OM_HVOP_INT_ERROR_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                |
-- +============================================================================+
-- | Name  : XXOMHVOPINTERRORPKG.PKB                                            |
-- | Description      : Package Body                          		        |
-- |                                                                            |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version    Date          Author           Remarks                           |
-- |=======    ==========    =============    ========================          |
-- |DRAFT 1A   06-JAN-2009   Bala          Initial draft version                |
-- |1.1        20-APR-2015   Sai Kiran     Changes made as part of Defect# 34203|
-- |1.2        18-OCT-2015   Sai Kiran     Changes made as part of Defect# 36145|
-- |1.3        09-11-2015    Shubhashree   R12.2 Compliance changes             |
-- |1.4        27-APR-2016   Surendra Oruganti Changes made to display          |
-- |                                      every WAVE defect# 37784              |
-- |1.5       11-MAY-2016 Surendra Oruganti  Changes made to add date           |
-- |                              parameter to schedule job through ESP         |
-- |1.6       07-NOV-2016   Poonam Gupta    Changes made for                    |
-- |                                        Enhancement Defect#39138            |
-- |1.7       30-NOV-2016   Rakesh Polepalli  Changes made for QC#40149         |
-- |1.8       25-AUG-2017   Venkata Battu     Changes Made for Defect#62632     |
-- |1.9       29-SEP-2017   Suresh Naragam    Changes for the defect#43330      |
-- |2.0       10-OCT-2017   Venkata Battu     Changes for the Defect# 43418     |
-- |2.1       18-DEC-2017   Venkata Battu     Changes for the Defect# 43920     |
-- |2.2       28-MAR-2018   Suresh Naragam    Changes for the Defect# 44426     |
-- +============================================================================+
Procedure hvop_int_error_count( retcode OUT  NUMBER
                               ,errbuf OUT VARCHAR2
                               ,p_date VARCHAR2     -- Added as per Ver 1.5
                               --,l_email_list VARCHAR2
                               ) --commented as part of36145
                                IS
ln_om_count Number :=0;
ln_cdh_count Number:=0;
ln_fin_count Number:=0 ;
ln_merch_count Number:=0;
ln_gtss_count Number:=0;
ln_other_count Number:=0;
ln_overall_count NUMBER:=0; -- Added for Defect#39138
ln_om_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_cdh_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_fin_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_merch_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_gtss_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_other_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
ln_overall_amount xx_om_headers_attr_iface_all.order_total%type :=0 ; -- Added for Defect#39138
lc_message VARCHAR2(50);
ln_ord_amount xx_om_headers_attr_iface_all.order_total%type :=0 ;
lc_error_category fnd_lookup_values_vl.attribute6%type;
lc_mail_status VARCHAR2(1);
lc_error_message varchar2(1000);
p_status varchar2(10);
ln_lookup_exist Number;
lc_message_create varchar2(200);
lc_msg_body clob;
crlf  VARCHAR2(10) := chr(13) || chr(10);
LO_CDH CMN_ERROR_TBL_TYPE;
lo_merch cmn_error_tbl_type;
lo_om cmn_error_tbl_type;
lo_fin cmn_error_tbl_type;
lo_other cmn_error_tbl_type;
lo_overall cmn_error_tbl_type; -- Added for Defect#39138
ln_cdh number;
ln_merch number;
ln_om Number;
ln_fin Number;
LN_OTHER NUMBER;
ln_overall NUMBER; -- Added for Defect#39138
p_email_list varchar2(1000);
--  added as per ver 1.4
ln_org_id   Number:= TO_NUMBER(fnd_profile.VALUE('ORG_ID'));
l_sas_order_amt       Number :=0;
l_ebs_order_amt       Number :=0;
l_ebs_order_err_amt   Number :=0;
l_sas_order_cnt       Number :=0;
l_ebs_order_cnt       Number :=0;
l_ebs_order_err_cnt   Number :=0;
l_ebs_order_pay_amt   Number :=0;
l_ebs_order_pay_cnt   Number :=0;
l_sas_order_pay_amt   Number :=0;
l_sas_order_pay_cnt   Number :=0;
l_sas_dep_amt	      Number :=0;
l_sas_dep_cnt         Number :=0;
l_ebs_dep_ordt_cnt    Number :=0;
l_ebs_dep_ordt_amt    Number :=0;
l_ebs_dep_err_amt     Number :=0;
l_ebs_dep_err_cnt     Number :=0;
l_ebs_oe_pay_amt      Number :=0;
l_ebs_total_pay_amt   Number :=0;
l_ebs_oe_pay_cnt      Number :=0;
l_ebs_total_pay_cnt   Number :=0;
l_ebs_oe_pay_err_amt  Number :=0;
l_ebs_oe_pay_err_cnt  Number :=0;
l_ebs_ordt_pay_amt    Number :=0;
l_ebs_ordt_pay_cnt    Number :=0;
l_ebs_dep_cnt         Number :=0;
l_ebs_dep_amt         Number :=0;
l_ebs_order_pay_count   Number :=0;
l_ebs_order_pay_amount  Number :=0;
l_ebs_ord_err_pay_count Number :=0;
l_ebs_ord_err_pay_amount Number :=0;
l_sas_pay_amount        Number :=0;
l_sas_pay_count         Number :=0;
l_pay_miss_ordt_cre_amt Number :=0;
l_pay_miss_ordt_cre_cnt Number :=0;
l_pay_miss_ordt_dbt_amt Number :=0;
l_pay_miss_ordt_dbt_cnt Number :=0;
l_pay_total_cnt         Number :=0;
l_pay_total_amt         Number :=0;
l_iface_pay_total_amt   Number :=0;
l_ebs_ret_pay_amt        Number :=0;
l_ebs_ret_pay_cnt        Number :=0;
l_ebs_ret_pay_err_amt    Number :=0;
L_EBS_RET_PAY_ERR_CNT	 NUMBER :=0;
L_EBS_ORDER_ERR_TOTAL_CNT NUMBER := 0; -- Added for Defect#39138
L_EBS_ORDER_ERR_TOTAL_AMT NUMBER := 0; -- Added for Defect#39138
l_ebs_err_pay_total_amt number := 0; -- Added for Defect#39138
l_ebs_err_pay_total_cnt number := 0; -- Added for Defect#39138
l_sysdate          DATE := fnd_conc_date.string_to_date (p_date);
-- Ended as per Ver 1.4
-- Added for Defect#39138 for "$" Sign and Comma Format - Start
ln_om_count_ch 					VARCHAR2(25);
ln_om_amount_ch 	 			VARCHAR2(25);
ln_merch_count_ch	 			VARCHAR2(25);
ln_merch_amount_ch  			VARCHAR2(25);
ln_fin_count_ch					VARCHAR2(25);
ln_fin_amount_ch 				VARCHAR2(25);
ln_cdh_count_ch					VARCHAR2(25);
ln_cdh_amount_ch				VARCHAR2(25);
ln_gtss_count_ch				VARCHAR2(25);
ln_gtss_amount_ch				VARCHAR2(25);
ln_other_count_ch				VARCHAR2(25);
ln_other_amount_ch				VARCHAR2(25);
ln_overall_count_ch				VARCHAR2(25);
ln_overall_amount_ch 			VARCHAR2(25);
l_sas_order_cnt_ch    			VARCHAR2(25);
l_sas_order_amt_ch				VARCHAR2(25);
l_sas_pay_amount_ch				VARCHAR2(25);
l_sas_pay_count_ch				VARCHAR2(25);
l_ebs_order_err_cnt_ch			VARCHAR2(25);
l_ebs_order_err_amt_ch			VARCHAR2(25);
l_ebs_ord_err_pay_count_ch		VARCHAR2(25);
l_ebs_ord_err_pay_amount_ch 	VARCHAR2(25);
l_ebs_order_cnt_ch				VARCHAR2(25);
l_ebs_order_amt_ch				VARCHAR2(25);
l_ebs_total_pay_amt_ch			VARCHAR2(25);
l_ebs_total_pay_cnt_ch			VARCHAR2(25);
l_ebs_ordt_pay_cnt_ch			VARCHAR2(25);
l_ebs_ordt_pay_amt_ch 			VARCHAR2(25);
l_pay_miss_ordt_cre_amt_ch		VARCHAR2(25);
l_pay_miss_ordt_cre_cnt_ch		VARCHAR2(25);
l_pay_miss_ordt_dbt_amt_ch		VARCHAR2(25);
l_pay_miss_ordt_dbt_cnt_ch		VARCHAR2(25);
l_pay_total_cnt_ch				VARCHAR2(25);
l_pay_total_amt_ch  			VARCHAR2(25);
--
l_ebs_order_err_total_cnt_ch VARCHAR2(25);
l_ebs_order_err_total_amt_ch VARCHAR2(25);
l_ebs_err_pay_total_amt_ch VARCHAR2(25);
l_ebs_err_pay_total_cnt_ch VARCHAR2(25);
-- Added for Defect#39138 for "$" Sign and Comma Format - End
--
-- Added for Defect#42632  for Entered ordered count and total value
        ln_ord_enter_cnt               NUMBER := 0;
        ln_ord_enter_tot               NUMBER := 0;
        ln_ord_enter_tot_ch            VARCHAR2(25);
        ln_ord_enter_hld_cnt           NUMBER := 0;
        ln_ord_enter_hld_tot           NUMBER := 0;
        ln_ord_enter_hld_tot_ch        VARCHAR2(25);
-- -- Added for Defect#43920   		
        ln_iso_cnt              number :=0;  
        ln_iso_amount           number :=0; 
        ln_iso_amount_ch        VARCHAR2(25);		
CURSOR error_record_cur IS
SELECT orig_sys_document_ref,message_text,ABS(order_total) order_total  -- ABS () added for defect#43418
            FROM    
                (SELECT 
                h.orig_sys_document_ref
              --,oep.message_text message_text
                ,
                (
                    SELECT
                        opm.message_text
                    FROM
                        oe_processing_msgs_vl opm
                    WHERE
                            opm.original_sys_document_ref = h.orig_sys_document_ref
                        AND
                            message_text != 'This Customer''s PO Number is referenced by another order'
                        AND
                            message_text != 'Order has been booked.'
                        AND
                            ROWNUM <= 1
                ) message_text,
                xh.order_total
            FROM
                oe_headers_iface_all h,
                xx_om_sacct_file_history fh,
                xx_om_headers_attr_iface_all xh,
                oe_processing_msgs_vl oep
            WHERE
                    xh.imp_file_name = fh.file_name
                AND
                    h.order_source_id = xh.order_source_id
                AND
                    h.orig_sys_document_ref = xh.orig_sys_document_ref
                AND
                    h.orig_sys_document_ref = oep.original_sys_document_ref
                AND
                    h.order_source_id = oep.order_source_id
--and nvl(h.error_flag,'N') = 'Y'
                AND
                    fh.file_type != 'DEPOSIT'
                AND
                    message_text != 'This Customer''s PO Number is referenced by another order'
                AND
                    message_text != 'Order has been booked.'
                AND
                    substr(message_text,1,8) NOT IN (
                        '10000033','10000027','10000014','10000009'
                    )) GROUP BY orig_sys_document_ref,message_text,order_total ;
CURSOR error_catg_cur is
select
 fv.lookup_code
,fv.meaning
,fv.description
,fv.attribute6
from
fnd_lookup_values_vl fv
where fv.lookup_type = 'XX_OM_HVOP_ERROR_CATEGORY'
and Enabled_flag = 'Y';
--
-- Added as per Ver 1.4
CURSOR pay_ordt (p_org_id NUMBER,p_date date)IS
/*SELECT
op.payment_type_code
,SUM(NVL(op.payment_amount,0))  pay_amt
,COUNT(op.header_id)        cnt
FROM     xx_om_sacct_file_history  fs
        ,xx_om_header_attributes_all   h
        ,oe_payments op
WHERE  fs.file_type = 'ORDER'
  AND fs.org_id = p_org_id
  AND fs.process_date = p_date
  AND h.imp_file_name(+) = fs.file_name
  AND op.header_id = h.header_id
  AND NOT EXISTS (SELECT 1
                    FROM xx_ar_order_receipt_dtl ordt
                   WHERE ordt.header_id = op.header_id)
GROUP BY op.payment_type_code,FS.PROCESS_DATE*/
--Modified for QC# 40149
SELECT
op.payment_type_code
,SUM(NVL(OP.PAYMENT_AMOUNT,0))  PAY_AMT
,COUNT(op.header_id)        cnt
FROM xx_om_sacct_file_history fs ,
  xx_om_header_attributes_all h,
  oe_payments op,
  oe_order_headers_all ooh
WHERE fs.file_type     = 'ORDER'
  AND FS.ORG_ID          = p_org_id
  AND fs.process_date    = p_date
  AND H.IMP_FILE_NAME(+) = FS.FILE_NAME
  AND OP.HEADER_ID       = H.HEADER_ID
  AND OOH.HEADER_ID      = OP.HEADER_ID
  AND NOT EXISTS (SELECT 1
				from XX_AR_ORDER_RECEIPT_DTL ORDT
				WHERE (ORDT.CASH_RECEIPT_ID = OP.ATTRIBUTE15 OR ORDT.ORIG_SYS_DOCUMENT_REF = OOH.ORIG_SYS_DOCUMENT_REF))
GROUP BY op.payment_type_code,FS.PROCESS_DATE
UNION
SELECT a.payment_type_code
,SUM(NVL(a.prepaid_amount,0)) pay_amt
,COUNT(b.orig_sys_document_ref) cnt
FROM  xx_om_legacy_deposits a
     ,xx_om_legacy_dep_dtls B
     ,xx_om_sacct_file_history fs
WHERE fs.file_type = 'DEPOSIT'
  AND fs.org_id = p_org_id
  AND fs.process_date = p_date
  AND a.i1025_status <> 'NEW'
  AND a.TRANSACTION_NUMBER =B.TRANSACTION_NUMBER
  AND a.imp_file_name=fs.file_name
  AND NOT EXISTS (SELECT 1
                    FROM xx_ar_order_receipt_dtl ordt
                   WHERE ordt.cash_receipt_id = a.cash_receipt_id)
GROUP BY a.payment_type_code,FS.PROCESS_DATE;
--
BEGIN
-- Added as per Ver 1.4
--SELECT trunc(sysdate) INTO l_sysdate FROM dual;  -- Commented as per Ver 1.5
FND_FILE.put_line(FND_FILE.log,'Current Date :'||l_sysdate);
For error_cur_rec in error_record_cur loop

-- Checking the Merchandising errors
If substr(error_cur_rec.message_text,1,4) = '1000' then
    If --substr(error_cur_rec.message_text,1,8) = '10000015' OR   --Commented on 29-sep-2017 for the defect#43330
	   substr(error_cur_rec.message_text,1,8) = '10000017'
       OR substr(error_cur_rec.message_text,1,8) = '10000018'  then

   -- Check point whether the order has been already counted or not
       ln_merch := lo_merch.COUNT;
        IF ln_merch > 0 THEN
          FOR ln_merch in 1..lo_merch.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_merch(ln_merch).order_number then
               EXIT;
             ELSE
                lo_merch(ln_merch).order_number := error_cur_rec.orig_sys_document_ref;
                ln_merch_count := ln_merch_count + 1;
                ln_merch_amount := ln_merch_amount + TO_NUMBER(error_cur_rec.order_total);
               END IF;
           END LOOP;
         ELSE
           ln_merch_count := ln_merch_count + 1;
           ln_merch_amount := ln_merch_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_merch:= lo_merch.count + 1;
           lo_merch(ln_merch).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;
    
  -- Checking the Finance errors
   elsif substr(error_cur_rec.message_text,1,8) = '10000007'
       OR substr(error_cur_rec.message_text,1,8) = '10000024' THEN
   -- Check point whether the order has been already counted or not
        ln_fin := lo_fin.COUNT;
        IF ln_fin > 0 THEN
          FOR ln_fin in 1..lo_fin.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_fin(ln_fin).order_number THEN
              EXIT;
              ELSE
               lo_fin(ln_fin).order_number := error_cur_rec.orig_sys_document_ref;
                ln_fin_count := ln_fin_count + 1;
                ln_fin_amount := ln_fin_amount + error_cur_rec.order_total;
               END IF;
          END LOOP;
        ELSE
           ln_fin_count := ln_fin_count + 1;
           ln_fin_amount := ln_fin_amount + error_cur_rec.order_total;
           ln_fin:= lo_fin.count + 1;
           lo_fin(ln_fin).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;
   
    -- Checking the CDH errors
  elsif substr(error_cur_rec.message_text,1,8) =     '10000010'
       OR substr(error_cur_rec.message_text,1,8) = '10000012'
	   OR substr(error_cur_rec.message_text,1,8) = '10000015'  --Added on 29-sep-2017 for the defect#43330
       OR substr(error_cur_rec.message_text,1,8) = '10000016'
       OR substr(error_cur_rec.message_text,1,8) = '10000021'
       OR substr(error_cur_rec.message_text,1,8) = '10000022'
       OR substr(error_cur_rec.message_text,1,8) = '10000028'
       OR substr(error_cur_rec.message_text,1,8) = '10000031'  THEN

     -- Check point whether the order has been already counted or not
        ln_cdh := lo_cdh.COUNT;
        IF ln_cdh > 0 THEN
          FOR ln_cdh in 1..lo_cdh.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_cdh(ln_cdh).order_number THEN
              EXIT;
              ELSE
               lo_cdh(ln_cdh).order_number := error_cur_rec.orig_sys_document_ref;
                ln_cdh_count := ln_cdh_count + 1;
                ln_cdh_amount := ln_cdh_amount + error_cur_rec.order_total;
               END IF;
          END LOOP;
         ELSE
           ln_cdh_count := ln_cdh_count + 1;
           ln_cdh_amount := ln_cdh_amount + error_cur_rec.order_total;
           ln_cdh:= lo_cdh.count + 1;
           lo_cdh(ln_cdh).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;
  

  -- Checking of Order Management Errors
    elsif substr(error_cur_rec.message_text,1,8) = '10000030'
       OR substr(error_cur_rec.message_text,1,8) = '10000000'
       OR substr(error_cur_rec.message_text,1,8) = '10000019'
       OR substr(error_cur_rec.message_text,1,8) = '10000026'
       OR substr(error_cur_rec.message_text,1,8) = '10000003'
       OR substr(error_cur_rec.message_text,1,8) = '10000020'
       OR substr(error_cur_rec.message_text,1,8) = '10000035'
       OR substr(error_cur_rec.message_text,1,8) = '10000013'
       OR substr(error_cur_rec.message_text,1,8) = '10000002'
       OR substr(error_cur_rec.message_text,1,8) = '10000034'
       OR substr(error_cur_rec.message_text,1,8) = '10000008'
       OR substr(error_cur_rec.message_text,1,8) = '10000011'
       OR substr(error_cur_rec.message_text,1,8) = '10000029'
       OR substr(error_cur_rec.message_text,1,8) = '10000032'
       OR substr(error_cur_rec.message_text,1,8) = '10000001'
       OR substr(error_cur_rec.message_text,1,8) = '10000006'
       OR substr(error_cur_rec.message_text,1,8) = '10000004'
       OR substr(error_cur_rec.message_text,1,8) = '10000005'
       OR substr(error_cur_rec.message_text,1,8) = '10000023'
       OR substr(error_cur_rec.message_text,1,8) = '10000036'  -- added for the defect#43418  
       THEN
       -- Check point whether the order has been already counted or not
        ln_om := lo_om.COUNT;
        IF ln_om > 0 THEN
          FOR ln_om in 1..lo_om.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_om(ln_om).order_number THEN
              EXIT;
              ELSE
               lo_om(ln_om).order_number := error_cur_rec.orig_sys_document_ref;
                ln_om_count := ln_om_count + 1;
                ln_om_amount := ln_om_amount + error_cur_rec.order_total;
               END IF;
          END LOOP;
       ELSE
           ln_om_count := ln_om_count + 1;
           ln_om_amount := ln_om_amount + error_cur_rec.order_total;
           ln_om:= lo_om.count + 1;
           lo_om(ln_om).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;
    ELSE 
           ln_other_count := ln_other_count + 1;
           ln_other_amount := ln_other_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_other:= lo_other.count + 1;
           lo_other(ln_other).order_number := error_cur_rec.orig_sys_document_ref;
    End if;
 ELSE IF substr(error_cur_rec.message_text,1,4) = 'ORA-' THEN
      if substr(error_cur_rec.message_text,1,9) = 'ORA-14403' then
       ln_gtss_count := ln_gtss_count + 1;
       ln_gtss_amount := ln_om_amount + error_cur_rec.order_total;
      else if substr(error_cur_rec.message_text,1,9) = 'ORA-03233' then
      ln_gtss_count := ln_gtss_count + 1;
       ln_gtss_amount := ln_om_amount + error_cur_rec.order_total;
     else
      ln_om_count := ln_om_count + 1;
      ln_om_amount := ln_om_amount + error_cur_rec.order_total;
     End if;
    End if;
ELSE IF substr(error_cur_rec.message_text,1,4) != '1000'
     AND substr(error_cur_rec.message_text,1,4) != 'ORA-' THEN
         if substr(error_cur_rec.message_text,1,31) = 'Validation failed for the field' Then
         ln_lookup_exist := 0;
      -- Checking the lookup value exists
          For error_catg_rec in error_catg_cur loop
             if substr(error_cur_rec.message_text,instr(error_cur_rec.message_text,'-')+1) = substr(error_catg_rec.meaning,instr(error_catg_rec.meaning,'-')+1) then
              ln_lookup_exist := 1;
              lc_error_category := error_catg_rec.attribute6;
              End if;
          End loop;
  -- If the Lookup value exists
           if ln_lookup_exist = 1 then
            if lc_error_category = 'CDH' then
              ln_cdh := lo_cdh.COUNT;
                IF ln_cdh > 0 THEN
                  FOR ln_cdh in 1..lo_cdh.count LOOP
                  IF error_cur_rec.orig_sys_document_ref = lo_cdh(ln_cdh).order_number THEN
                      EXIT;
                  ELSE
                      lo_cdh(ln_cdh).order_number := error_cur_rec.orig_sys_document_ref;
                      ln_cdh_count := ln_cdh_count + 1;
                      ln_cdh_amount := ln_cdh_amount + error_cur_rec.order_total;
                  END IF;
                 END LOOP;
                ELSE
                    ln_cdh_count := ln_cdh_count + 1;
                    ln_cdh_amount := ln_cdh_amount + error_cur_rec.order_total;
                    ln_cdh:= lo_cdh.count + 1;
                    lo_cdh(ln_cdh).order_number := error_cur_rec.orig_sys_document_ref;
                END IF;
            end if;
              if lc_error_category = 'ORDER MANAGEMENT' then
                 ln_om := lo_om.COUNT;
                 IF ln_om > 0 THEN
                    FOR ln_om in 1..lo_om.count LOOP
                      IF error_cur_rec.orig_sys_document_ref = lo_om(ln_om).order_number THEN
                        EXIT;
                      ELSE
                          lo_om(ln_om).order_number := error_cur_rec.orig_sys_document_ref;
                          ln_om_count := ln_om_count + 1;
                          ln_om_amount := ln_om_amount + error_cur_rec.order_total;
                      END IF;
                      END LOOP;

                  ELSE
                        ln_om_count := ln_om_count + 1;
                        ln_om_amount := ln_om_amount + error_cur_rec.order_total;
                        ln_om:= lo_om.count + 1;
                        lo_om(ln_om).order_number := error_cur_rec.orig_sys_document_ref;
                  END IF;
               end if;
              if lc_error_category = 'FINANACE' then
                 ln_fin := lo_fin.COUNT;
        IF ln_fin > 0 THEN
          FOR ln_fin in 1..lo_fin.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_fin(ln_fin).order_number THEN
              EXIT;
              ELSE
               lo_fin(ln_fin).order_number := error_cur_rec.orig_sys_document_ref;
                ln_fin_count := ln_fin_count + 1;
                ln_fin_amount := ln_fin_amount + error_cur_rec.order_total;
               END IF;
          END LOOP;

       ELSE
           ln_fin_count := ln_fin_count + 1;
           ln_fin_amount := ln_fin_amount + error_cur_rec.order_total;
           ln_fin:= lo_fin.count + 1;
           lo_fin(ln_fin).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;
          end if;
              if lc_error_category = 'ITEM' then
                     IF ln_merch > 0 THEN
          FOR ln_merch in 1..lo_merch.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_merch(ln_merch).order_number then

              EXIT;
              ELSE
                lo_merch(ln_merch).order_number := error_cur_rec.orig_sys_document_ref;
                ln_merch_count := ln_merch_count + 1;
                ln_merch_amount := ln_merch_amount + TO_NUMBER(error_cur_rec.order_total);
               END IF;
           END LOOP;

       ELSE
           ln_merch_count := ln_merch_count + 1;
           ln_merch_amount := ln_merch_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_merch:= lo_merch.count + 1;
           lo_merch(ln_merch).order_number := error_cur_rec.orig_sys_document_ref;
       END IF;

              end if;
          Else
             IF ln_other > 0 THEN
          FOR ln_other in 1..lo_other.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_other(ln_other).order_number then

              EXIT;
              ELSE
                lo_other(ln_other).order_number := error_cur_rec.orig_sys_document_ref;
                ln_other_count := ln_other_count + 1;
                ln_other_amount := ln_other_amount + TO_NUMBER(error_cur_rec.order_total);
               END IF;
           END LOOP;

         ELSE
           ln_other_count := ln_other_count + 1;
           ln_other_amount := ln_other_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_other:= lo_other.count + 1;
           lo_other(ln_other).order_number := error_cur_rec.orig_sys_document_ref;
        END IF;

           FND_FILE.put_line(FND_FILE.log,'Message Needs to be created***:' || substr(error_cur_rec.message_text,1,1900));
          End if;

        ELSE
           IF ln_other > 0 THEN
          FOR ln_other in 1..lo_other.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_other(ln_other).order_number then
               EXIT;
              ELSE
                lo_other(ln_other).order_number := error_cur_rec.orig_sys_document_ref;
                ln_other_count := ln_other_count + 1;
                ln_other_amount := ln_other_amount + TO_NUMBER(error_cur_rec.order_total);
               END IF;
           END LOOP;

       ELSE
           ln_other_count := ln_other_count + 1;
           ln_other_amount := ln_other_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_other:= lo_other.count + 1;
           lo_other(ln_other).order_number := error_cur_rec.orig_sys_document_ref;
        END IF;
      end if ;
   End if;
  End if;
 End if;
End loop;
-- added for Defect#42632 to get Entered Orders Without Holds
-- modified the select query for defect#43418
        BEGIN
             SELECT COUNT(booked_count) booked_count
                     ,SUM(order_total) order_total
               INTO  ln_ord_enter_cnt,ln_ord_enter_tot
               FROM (
                     SELECT ooha.order_number booked_count,
                            ABS(xh.order_total) order_total
                       FROM  xx_om_headers_attr_iface_all xh,
                             oe_order_headers_all ooha
                      WHERE  xh.order_source_id = ooha.order_source_id
                        AND  xh.orig_sys_document_ref = ooha.orig_sys_document_ref
                        AND  ooha.flow_status_code = 'ENTERED'
                        AND  ooha.open_flag = 'Y'
                        AND NOT EXISTS ( SELECT 1 
                                           FROM oe_order_holds_all hold
                                          WHERE hold.header_id = ooha.header_id)
                      UNION
                      SELECT  ooha.order_number booked_count,
                              ABS(xh.order_total)  order_total
                        FROM  xx_om_headers_attr_iface_all xh,
                              oe_order_headers_all ooha,
                              oe_order_holds_all hold
                       WHERE  xh.order_source_id = ooha.order_source_id
                         AND  xh.orig_sys_document_ref = ooha.orig_sys_document_ref
                         AND  ooha.flow_status_code  = 'ENTERED'
						 AND  ooha.open_flag = 'Y'
                         AND  hold.header_id         = ooha.header_id
                         AND  hold.released_flag     = 'Y'
                         AND                  0      = (SELECT COUNT(1)
                                                          FROM oe_order_holds_all hold
                                                         WHERE hold.header_id  = ooha.header_id
                                                           AND  hold.released_flag = 'N'
                                                       )
                    );
        END;

  -- added for Defect#42632 to get Entered Orders with hold
  -- Modified the select logic for defect#43418
        BEGIN
             SELECT COUNT(booked_count) booked_count
                     ,SUM(order_total) order_total
               INTO ln_ord_enter_hld_cnt,ln_ord_enter_hld_tot
               FROM (       
                     SELECT ooha.order_number booked_count,
                            ABS(xh.order_total)  order_total
                       FROM  xx_om_headers_attr_iface_all xh,
                             oe_order_headers_all ooha,
                             oe_order_holds_all hold
                      WHERE  xh.order_source_id = ooha.order_source_id
                        AND  xh.orig_sys_document_ref = ooha.orig_sys_document_ref
                        AND  ooha.flow_status_code  = 'ENTERED'
						AND  ooha.open_flag = 'Y'
                        AND  hold.header_id         = ooha.header_id
                        AND  hold.released_flag     = 'N'
                        GROUP BY ooha.order_number,xh.order_total
                    );
        END;
    --  Added internal orders for Defect# 43920
      
        BEGIN
		      -- Internal orders error records count
		     SELECT COUNT(DISTINCT ohi.orig_sys_document_ref)
			   INTO ln_iso_cnt    
               FROM oe_headers_iface_all ohi
              WHERE ohi.error_flag ='Y'
                AND  ohi.order_source_id =10;
			    
				-- internal orders total amount 
              SELECT SUM(oli.ordered_quantity * oli.unit_selling_price)
                INTO ln_iso_amount  			  
                FROM  oe_lines_iface_all oli
               WHERE EXISTS (select 1 
			                   from oe_headers_iface_all ohi
                              where ohi.error_flag ='Y'
                                and  ohi.order_source_id =10
                                and ohi.orig_sys_document_ref = oli.orig_sys_document_ref
							);
        END;							


        -- Changes done for the defect#44426	
/*ln_overall_count := nvl(ln_merch_count,0) + nvl(ln_fin_count,0) + nvl(ln_cdh_count,0) + nvl(ln_om_count,0) + nvl(ln_gtss_count,0) + nvl(ln_other_count
,0) + nvl(ln_ord_enter_cnt,0) + nvl(ln_ord_enter_hld_cnt,0) + nvl(ln_iso_cnt,0);

        ln_overall_amount := nvl(ln_merch_amount,0) + nvl(ln_fin_amount,0) + nvl(ln_cdh_amount,0) + nvl(ln_om_amount,0) + nvl(ln_gtss_amount,0) + nvl
(ln_other_amount,0) + nvl(ln_ord_enter_tot,0) + nvl(ln_ord_enter_hld_tot,0) + nvl(ln_iso_amount,0);*/

         SELECT count(h.orig_sys_document_ref),
                sum(XH.ORDER_TOTAL)
         INTO ln_overall_count,
              ln_overall_amount
         FROM OE_HEADERS_IFACE_ALL H,
              XX_OM_SACCT_FILE_HISTORY FH,
              xx_om_headers_attr_iface_all xh
         WHERE xh.imp_file_name      = fh.file_name
         AND h.order_source_id       = xh.order_source_id
         AND h.orig_sys_document_ref = xh.orig_sys_document_ref
         AND fh.file_type           != 'DEPOSIT'
		 AND not EXISTS (SELECT 'X' 
		                 FROM oe_processing_msgs_vl 
                         WHERE original_sys_document_ref = h.orig_sys_document_ref 
                         AND order_source_id = h.order_source_id
                         AND message_text = 'This Customer''s PO Number is referenced by another order' 
                         AND message_text = 'Order has been booked.'
                         AND substr(message_text,1,8) IN ('10000033','10000027','10000014','10000009'));

-- Added for Defect#39138 - Start - For Total Pending
/* -----------------------------------------------------------------------------------------------
-- There are orders which belong to two tracks simultaneously. The below piece of code will		--
-- count all the orders with errors only once. Similarly, the total error amount for the orders --
-- with error will also be counted only once per order in the final calculation. Hence, Total	--
-- count and total amount will always be less than the actual sum of all tracks	in Total Pending--
----------------------------------------------------------------------------------------------- */
/*For error_cur_rec in error_record_cur loop

If substr(error_cur_rec.message_text,1,4) = '1000' then
	IF  substr(error_cur_rec.message_text,1,8) = '10000015'
		OR substr(error_cur_rec.message_text,1,8) = '10000017'
		OR substr(error_cur_rec.message_text,1,8) = '10000018' -- merch errors
	OR substr(error_cur_rec.message_text,1,8) = '10000007'
		OR substr(error_cur_rec.message_text,1,8) = '10000024' -- fin errors
	OR substr(error_cur_rec.message_text,1,8) =     '10000010'
       OR substr(error_cur_rec.message_text,1,8) = '10000012'
       OR substr(error_cur_rec.message_text,1,8) = '10000016'
       OR substr(error_cur_rec.message_text,1,8) = '10000021'
       OR substr(error_cur_rec.message_text,1,8) = '10000022'
       OR substr(error_cur_rec.message_text,1,8) = '10000028'
       OR substr(error_cur_rec.message_text,1,8) = '10000031'  -- CDH errors
	OR substr(error_cur_rec.message_text,1,8) = '10000030'
       OR substr(error_cur_rec.message_text,1,8) = '10000000'
       OR substr(error_cur_rec.message_text,1,8) = '10000019'
       OR substr(error_cur_rec.message_text,1,8) = '10000026'
       OR substr(error_cur_rec.message_text,1,8) = '10000003'
       OR substr(error_cur_rec.message_text,1,8) = '10000020'
       OR substr(error_cur_rec.message_text,1,8) = '10000035'
       OR substr(error_cur_rec.message_text,1,8) = '10000013'
       OR substr(error_cur_rec.message_text,1,8) = '10000002'
       OR substr(error_cur_rec.message_text,1,8) = '10000034'
       OR substr(error_cur_rec.message_text,1,8) = '10000008'
       OR substr(error_cur_rec.message_text,1,8) = '10000011'
       OR substr(error_cur_rec.message_text,1,8) = '10000029'
       OR substr(error_cur_rec.message_text,1,8) = '10000032'
       OR substr(error_cur_rec.message_text,1,8) = '10000001'
       OR substr(error_cur_rec.message_text,1,8) = '10000006'
       OR substr(error_cur_rec.message_text,1,8) = '10000004'
       OR substr(error_cur_rec.message_text,1,8) = '10000005'
       OR substr(error_cur_rec.message_text,1,8) = '10000023' -- OM errors
	THEN
		ln_overall := lo_overall.COUNT;
		IF ln_overall > 0 THEN
		FOR ln_overall in 1..lo_overall.count LOOP
             IF error_cur_rec.orig_sys_document_ref = lo_overall(ln_overall).order_number then
               EXIT;
             ELSE
                lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
                ln_overall_count := ln_overall_count + 1;
                ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
               END IF;
           END LOOP;
		ELSE
		ln_overall_count := ln_overall_count + 1;
           ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
           ln_overall:= lo_overall.count + 1;
           lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
		END IF;
	END IF;
ELSIF substr(error_cur_rec.message_text,1,4) = 'ORA-' THEN
		ln_overall_count := ln_overall_count + 1;
		ln_overall_amount := ln_overall_amount + error_cur_rec.order_total;
ELSIF((substr(error_cur_rec.message_text,1,4) != '1000') AND (substr(error_cur_rec.message_text,1,4) != 'ORA-')) THEN
	IF substr(error_cur_rec.message_text,1,31) = 'Validation failed for the field' Then
				 ln_lookup_exist := 0;
			  -- Checking the lookup value exists
		For error_catg_rec in error_catg_cur loop
			if substr(error_cur_rec.message_text,instr(error_cur_rec.message_text,'-')+1) = substr(error_catg_rec.meaning,instr(error_catg_rec.meaning,'-')+1) then
			ln_lookup_exist := 1;
			lc_error_category := error_catg_rec.attribute6;
			End if;
		End loop;
		IF ln_lookup_exist = 1 then
			IF lc_error_category = 'CDH'
			OR lc_error_category = 'ORDER MANAGEMENT'
			OR lc_error_category = 'FINANACE'
			OR lc_error_category = 'ITEM'
			THEN
				ln_overall := lo_overall.COUNT;
				IF ln_overall > 0 THEN
					FOR ln_overall in 1..lo_overall.count LOOP
						IF error_cur_rec.orig_sys_document_ref = lo_overall(ln_overall).order_number THEN
							EXIT;
						ELSE
							lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
							ln_overall_count := ln_overall_count + 1;
							ln_overall_amount := ln_overall_amount + error_cur_rec.order_total;
						END IF;
					END LOOP;
				ELSE
					ln_overall_count := ln_overall_count + 1;
					ln_overall_amount := ln_overall_amount + error_cur_rec.order_total;
					ln_overall:= lo_overall.count + 1;
					lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
				END IF;
			ELSIF ln_overall > 0 THEN
				FOR ln_overall in 1..lo_overall.count LOOP
					IF error_cur_rec.orig_sys_document_ref = lo_overall(ln_overall).order_number then
						EXIT;
					ELSE
						lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
						ln_overall_count := ln_overall_count + 1;
						ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
					END IF;
				END LOOP;
			ELSE
				ln_overall_count := ln_overall_count + 1;
				ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
				ln_overall:= lo_overall.count + 1;
				lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
			END IF;
		ELSE
			IF ln_overall > 0 THEN
				FOR ln_overall in 1..lo_overall.count LOOP
					IF error_cur_rec.orig_sys_document_ref = lo_overall(ln_overall).order_number then
						EXIT;
					ELSE
						lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;
						ln_overall_count := ln_overall_count + 1;
						ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
				  END IF;
				END LOOP;
			END IF;
		END IF;
	END IF;
ELSE
	ln_overall_count := ln_overall_count + 1;
    ln_overall_amount := ln_overall_amount + TO_NUMBER(error_cur_rec.order_total);
    LN_OVERALL:= LO_OVERALL.COUNT + 1;
    lo_overall(ln_overall).order_number := error_cur_rec.orig_sys_document_ref;

END IF;

End loop;
-- Added for Defect#39138 - End - For Total Pending
--
-- Added as per Ver 1.4
*/
-- Query to fetch Orders details
BEGIN
SELECT
     SUM(NVL(ot.total_sas_order_amt,0))
    ,SUM(NVL(ot.total_ebs_order_amt,0))
    ,SUM(NVL(eo.total_ebs_order_err_amt,0))
    ,SUM(NVL(ot.total_sas_order_cnt,0))
    ,SUM(NVL(ot.total_ebs_order_cnt,0))
    ,SUM(NVL(eo.total_ebs_order_err_cnt,0))
	,SUM(NVL(ot.total_sas_order_pay_amt,0))
	,SUM(NVL(ot.total_sas_order_pay_cnt,0))
INTO   l_sas_order_amt,l_ebs_order_amt,l_ebs_order_err_amt,l_sas_order_cnt,l_ebs_order_cnt,l_ebs_order_err_cnt,
       l_sas_order_pay_amt,l_sas_order_pay_cnt
FROM
   (SELECT
         fs.process_date
        ,fs.file_name
        ,(fs.legacy_header_amount + fs.cash_back_amount) total_sas_order_amt
        ,SUM(h.order_total)      total_ebs_order_amt
        ,fs.legacy_header_count  total_sas_order_cnt
		,fs.legacy_payment_amount total_sas_order_pay_amt
		,fs.legacy_payment_count  total_sas_order_pay_cnt
        ,COUNT(h.imp_file_name)  total_ebs_order_cnt
    FROM
     	xx_om_sacct_file_history  fs
        ,xx_om_header_attributes_all   h
    WHERE   fs.file_type = 'ORDER'
      AND fs.org_id = ln_org_id
      AND fs.process_date = l_sysdate
      AND h.imp_file_name(+) = fs.file_name
    GROUP BY
         fs.process_date
        ,fs.file_name
        ,(fs.legacy_header_amount + fs.cash_back_amount)
        ,fs.legacy_header_count
		,fs.legacy_payment_amount
		,fs.legacy_payment_count)  ot
   , (SELECT
         fs.file_name
        ,SUM(ih.order_total)     total_ebs_order_err_amt
        ,COUNT(ih.imp_file_name) total_ebs_order_err_cnt
    FROM
         xx_om_sacct_file_history      fs
        ,xx_om_headers_attr_iface_all  ih
        ,oe_headers_iface_all          oh
    WHERE   fs.file_type = 'ORDER'
      AND fs.org_id = ln_org_id
      AND fs.process_date = l_sysdate
      AND ih.imp_file_name = fs.file_name
      AND ih.ORIG_SYS_DOCUMENT_REF = oh.ORIG_SYS_DOCUMENT_REF
      AND ih.order_source_id = oh.order_source_id
    GROUP BY
        fs.file_name) eo
WHERE
    ot.file_name = eo.file_name(+)
GROUP BY
     ot.process_date;
EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the order counts:'||SQLERRM);
END;

-- To fetch deposits information
BEGIN
SELECT
     SUM(dt.total_dep_amt_sas)
    ,SUM(dt.total_dep_sas)
    ,SUM(NVL(dt.total_number_order_deposit,0)) total_number_order_deposit
    ,SUM(NVL(dt.total_amount_order_deposit,0)) total_amount_order_deposit
    ,SUM(NVL(ed.total_amount_error,0)) total_amount_error
    ,SUM(NVL(ed.total_number_error,0)) total_number_error
INTO l_sas_dep_amt,l_sas_dep_cnt,l_ebs_dep_cnt,l_ebs_dep_amt,l_ebs_dep_err_amt,l_ebs_dep_err_cnt
FROM
    (SELECT
     fs.process_date
     ,fs.file_name
     ,fs.legacy_payment_amount total_dep_amt_sas
     ,NVL(fs.legacy_payment_count,0)      total_dep_sas
     ,SUM(NVL(d1.prepaid_amount,0))  total_amount_order_deposit
     ,COUNT(d1.TRANSACTION_NUMBER)  total_number_order_deposit
    FROM
         xx_om_sacct_file_history  fs
        ,xx_om_legacy_deposits d1
    WHERE fs.file_type = 'DEPOSIT'
      AND fs.org_id = ln_org_id
      AND fs.process_date =l_sysdate
      AND d1.imp_file_name(+) = fs.file_name
      AND d1.error_flag(+) = 'N'
 GROUP BY
         fs.process_date
		,fs.file_name
	    ,fs.legacy_payment_amount
        ,fs.legacy_payment_count
    ) dt
   ,(SELECT
     fs.file_name
    ,SUM(NVL(d2.prepaid_amount,0))    total_amount_error
	,COUNT(d2.TRANSACTION_NUMBER)   total_number_error
    FROM
         xx_om_sacct_file_history  fs
        ,xx_om_legacy_deposits d2
    WHERE   fs.file_type = 'DEPOSIT'
      AND fs.process_date =l_sysdate
      AND fs.org_id = ln_org_id
      AND d2.imp_file_name = fs.file_name
      AND NVL(d2.error_flag,'Y') = 'Y'
    GROUP BY
        fs.process_date
        ,fs.file_name
     ) ed
WHERE
        dt.file_name = ed.file_name(+)
GROUP BY dt.process_date;
EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the deposit counts:'||SQLERRM);
END;

--Query to fetch return tenders information
BEGIN
SELECT
SUM(NVL(op.credit_amount,0))   total_ret_payment_amount
,COUNT(op.header_id)        total_ret_payment_count
INTO l_ebs_ret_pay_amt
    ,l_ebs_ret_pay_cnt
FROM     xx_om_sacct_file_history  fs
        ,xx_om_header_attributes_all   h
        ,xx_om_return_tenders_all op
WHERE  fs.file_type = 'ORDER'
  AND fs.org_id = ln_org_id
  AND fs.process_date = l_sysdate
  AND h.imp_file_name(+) = fs.file_name
  AND op.header_id = h.header_id
GROUP BY fs.process_date;
 EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the return tender counts:'||SQLERRM);
END;


BEGIN
SELECT
SUM(NVL(op.credit_amount,0))        total_ret_err_payment_amt
,COUNT(op.orig_sys_document_ref)      total_ret_err_payment_cnt
INTO  l_ebs_ret_pay_err_amt
    ,l_ebs_ret_pay_err_cnt
FROM     xx_om_sacct_file_history  fs
        ,xx_om_headers_attr_iface_all   h
	,oe_headers_iface_all oh
        ,xx_om_ret_tenders_iface_all op
WHERE  fs.file_type = 'ORDER'
  AND fs.org_id = ln_org_id
  AND fs.process_date = l_sysdate
  AND h.imp_file_name(+) = fs.file_name
  AND h.orig_sys_document_ref=oh.orig_sys_document_ref
  AND oh.org_id = fs.org_id
  AND op.orig_sys_document_ref=oh.orig_sys_document_ref
GROUP BY fs.process_date;
 EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the return tender iface counts:'||SQLERRM);
END;

-- Query to fetch orders payment information
BEGIN
SELECT
 SUM(NVL(ot.total_payment_amount,0))
 ,SUM(NVL(ot.total_payment_count,0))
 ,SUM(NVL(ed.total_err_payment_amt,0))
 ,SUM(NVL(ed.total_err_payment_cnt,0))
INTO l_ebs_oe_pay_amt
    ,l_ebs_oe_pay_cnt
    ,l_ebs_oe_pay_err_amt
    ,l_ebs_oe_pay_err_cnt
FROM
(SELECT
fs.process_date
,fs.file_name
,SUM(NVL(op.payment_amount,0))   total_payment_amount
,COUNT(op.header_id)        total_payment_count
FROM     xx_om_sacct_file_history  fs
        ,xx_om_header_attributes_all   h
        ,oe_order_headers_all oh
        ,oe_payments op
WHERE  fs.file_type = 'ORDER'
  AND fs.org_id = ln_org_id
  AND fs.process_date = l_sysdate
  AND h.imp_file_name(+) = fs.file_name
  and oh.header_id  = h.header_id
  AND op.header_id = oh.header_id
  AND NOT EXISTS ( SELECT 1
                     FROM XX_OM_LEGACY_DEP_DTLS ld,XX_OM_LEGACY_DEPOSITS ld2
                    WHERE ld.orig_sys_document_ref = oh.orig_sys_document_ref
                      AND ld.transaction_number=ld2.transaction_number)
GROUP BY fs.process_date,fs.file_name) ot
,(SELECT
fs.file_name
,SUM(NVL(op.payment_amount,0))        total_err_payment_amt
,COUNT(op.orig_sys_document_ref)      total_err_payment_cnt
FROM     xx_om_sacct_file_history  fs
        ,xx_om_headers_attr_iface_all   h
	    ,oe_headers_iface_all oh
        ,oe_payments_iface_all op
WHERE  fs.file_type = 'ORDER'
  AND fs.org_id = ln_org_id
  AND fs.process_date = l_sysdate
  AND h.imp_file_name(+) = fs.file_name
  AND h.ORIG_SYS_DOCUMENT_REF=oh.ORIG_SYS_DOCUMENT_REF
  AND oh.org_id = fs.org_id
  AND op.request_id=fs.request_id
  AND oh.orig_sys_document_ref|| '-BYPASS' = op.orig_sys_document_ref
  AND oh.order_source_id = op.order_source_id
  AND NOT EXISTS ( SELECT 1
                     FROM XX_OM_LEGACY_DEP_DTLS ld,XX_OM_LEGACY_DEPOSITS ld2
                    WHERE ld.orig_sys_document_ref = oh.orig_sys_document_ref
                      AND ld.transaction_number=ld2.transaction_number)
GROUP BY fs.process_date,fs.file_name)  ed
WHERE
        ot.file_name = ed.file_name(+)
GROUP BY
     ot.process_date;
EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the payment counts:'||SQLERRM);
END;

--To fetch data from ordt table
BEGIN
SELECT SUM(ordt.payment_amount)
      ,COUNT(ordt.order_payment_id)
INTO l_ebs_ordt_pay_amt,l_ebs_ordt_pay_cnt
FROM xx_ar_order_receipt_dtl ordt
,xx_om_sacct_file_history fs
WHERE    fs.org_id = ln_org_id
  AND fs.process_date = l_sysdate
  AND ordt.imp_file_name = fs.file_name
GROUP BY FS.process_date  ;
EXCEPTION
WHEN Others THEN
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the deposit counts:'||SQLERRM);
END;


FOR pay_ordt_rec IN pay_ordt(ln_org_id,l_sysdate) LOOP
BEGIN
 IF pay_ordt_rec.payment_type_code = 'CREDIT_CARD' THEN
  l_pay_miss_ordt_cre_amt := l_pay_miss_ordt_cre_amt + pay_ordt_rec.pay_amt;
  l_pay_miss_ordt_cre_cnt := l_pay_miss_ordt_cre_cnt + pay_ordt_rec.cnt;
ELSE
    l_pay_miss_ordt_dbt_amt := l_pay_miss_ordt_dbt_amt + pay_ordt_rec.pay_amt;
    l_pay_miss_ordt_dbt_cnt := l_pay_miss_ordt_dbt_cnt + pay_ordt_rec.cnt;
END IF;
END;
END LOOP;

l_pay_total_cnt  := l_pay_miss_ordt_cre_cnt+l_pay_miss_ordt_dbt_cnt;
l_pay_total_amt  := l_pay_miss_ordt_cre_amt+l_pay_miss_ordt_dbt_amt;
l_ebs_ord_err_pay_count := l_ebs_oe_pay_err_cnt  + l_ebs_dep_err_cnt + l_ebs_ret_pay_err_cnt;
l_ebs_ord_err_pay_amount :=l_ebs_oe_pay_err_amt+l_ebs_dep_err_amt - l_ebs_ret_pay_err_amt;
l_sas_pay_amount := l_sas_order_pay_amt + l_sas_dep_amt;
l_sas_pay_count := l_sas_order_pay_cnt+  l_sas_dep_cnt;
l_ebs_total_pay_amt := l_ebs_oe_pay_amt + l_ebs_dep_amt - l_ebs_ret_pay_amt;
l_ebs_total_pay_cnt :=  l_ebs_oe_pay_cnt + l_ebs_dep_cnt + l_ebs_ret_pay_cnt;
-- Added for Defect#39138
L_EBS_ORDER_ERR_TOTAL_CNT := (NVL(L_EBS_ORDER_ERR_CNT,0)+NVL(L_EBS_ORDER_CNT,0));
L_EBS_ORDER_ERR_TOTAL_AMT := (NVL(L_EBS_ORDER_ERR_AMT,0)+NVL(L_EBS_ORDER_AMT,0));
L_EBS_ERR_PAY_TOTAL_AMT := (NVL(L_EBS_ORD_ERR_PAY_AMOUNT ,0)+NVL(L_EBS_TOTAL_PAY_AMT,0));
l_ebs_err_pay_total_cnt := (nvl(l_ebs_ord_err_pay_count,0)+nvl(l_ebs_total_pay_cnt,0));


-- End as per ver 1.4

--CH ID START Defect# 36145
P_Email_List := Null;
begin
SELECT target_value9 into p_email_list
    FROM xx_fin_translatedefinition def,
      xx_fin_translatevalues val
    Where Def.Translate_Id   =Val.Translate_Id
    And Def.Translation_Name = 'XX_OM_INV_NOTIFICATION';
Exception
When Others Then
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the email list:' || p_email_list);
end;
FND_FILE.put_line(FND_FILE.log,'Recipients :' || p_email_list); -- Added for Defect#39138


-- Added logic to show the distinct orders as per interface data
ln_overall_count := nvl(ln_overall_count,0) + nvl(ln_ord_enter_hld_cnt,0) + nvl(ln_ord_enter_cnt,0) - nvl(ln_iso_cnt,0);
ln_overall_amount := nvl(ln_overall_amount,0.0) + nvl(ln_ord_enter_hld_tot,0.0) + nvl(ln_ord_enter_tot,0.0) - nvl(ln_iso_amount,0.0);

-- Added for Defect#39138 for "$" sign and comma format - Start
ln_om_amount_ch := to_char (round(ln_om_amount,2) , '$999,999,999.99');
ln_merch_amount_ch := to_char (round(ln_merch_amount,2) , '$999,999,999.99');
ln_fin_amount_ch := to_char (round(ln_fin_amount,2) , '$999,999,999.99');
ln_cdh_amount_ch := to_char (round(ln_cdh_amount,2) , '$999,999,999.99');
ln_gtss_amount_ch := to_char (round(ln_gtss_amount,2) , '$999,999,999.99');
ln_other_amount_ch := to_char (round(ln_other_amount,2) , '$999,999,999.99');
ln_overall_amount_ch := to_char (round(ln_overall_amount,2) , '$9,999,999,999.99');
l_pay_miss_ordt_cre_amt_ch := to_char (round(l_pay_miss_ordt_cre_amt,2) , '$9,999,999,999.99');
l_pay_miss_ordt_dbt_amt_ch := to_char (round(l_pay_miss_ordt_dbt_amt,2) , '$9,999,999,999.99');
l_pay_total_amt_ch := to_char (round(l_pay_total_amt,2) , '$9,999,999,999.99');
l_sas_order_amt_ch := to_char (round(l_sas_order_amt,2) , '$9,999,999,999.99');
l_sas_pay_amount_ch := to_char (round(l_sas_pay_amount,2) , '$9,999,999,999.99');
L_EBS_ORDER_ERR_AMT_CH := TO_CHAR (ROUND(L_EBS_ORDER_ERR_AMT,2) , '$9,999,999,999.99');
l_ebs_ordt_pay_amt_ch := to_char (l_ebs_ordt_pay_amt, '$999,999,999,999.99');
l_ebs_ord_err_pay_amount_ch := to_char (round(l_ebs_ord_err_pay_amount,2) , '$9,999,999,999.99');
l_ebs_order_amt_ch := to_char (round(l_ebs_order_amt,2) , '$9,999,999,999.99');
l_ebs_total_pay_amt_ch := to_char (round(l_ebs_total_pay_amt,2) , '$9,999,999,999.99');
--
l_ebs_order_err_total_cnt_ch := to_char(l_ebs_order_err_total_cnt,'999,999,999,999');
l_ebs_order_err_total_amt_ch := to_char(l_ebs_order_err_total_amt, '$999,999,999,999.99');
l_ebs_err_pay_total_amt_ch := to_char (l_ebs_err_pay_total_amt, '$999,999,999,999.99');
l_ebs_err_pay_total_cnt_ch := to_char (l_ebs_err_pay_total_cnt, '999,999,999,999');

-- Added for Defect#39138 for Comma Format - Start
ln_om_count_ch:= to_char (ln_om_count, '999,999,999,999');
ln_merch_count_ch := to_char (ln_merch_count, '999,999,999,999');
ln_fin_count_ch := to_char (ln_fin_count, '999,999,999,999');
ln_cdh_count_ch := to_char (ln_cdh_count, '999,999,999,999');
ln_gtss_count_ch := to_char (ln_gtss_count, '999,999,999,999');
ln_other_count_ch := to_char (ln_other_count, '999,999,999,999');
ln_overall_count_ch := to_char (ln_overall_count, '999,999,999,999');
l_sas_order_cnt_ch := to_char (l_sas_order_cnt, '999,999,999,999');
L_SAS_PAY_COUNT_CH := TO_CHAR (L_SAS_PAY_COUNT, '999,999,999,999');
l_ebs_order_err_cnt_ch := to_char (l_ebs_order_err_cnt, '999,999,999,999');
l_ebs_ord_err_pay_count_ch := to_char (l_ebs_ord_err_pay_count, '999,999,999,999');
l_ebs_order_cnt_ch := to_char (l_ebs_order_cnt, '999,999,999,999');
l_ebs_total_pay_cnt_ch := to_char (l_ebs_total_pay_cnt, '999,999,999,999');
l_ebs_ordt_pay_cnt_ch := to_char (l_ebs_ordt_pay_cnt, '999,999,999,999');
l_pay_miss_ordt_cre_cnt_ch := to_char (l_pay_miss_ordt_cre_cnt, '999,999,999,999');
l_pay_miss_ordt_dbt_cnt_ch := to_char (l_pay_miss_ordt_dbt_cnt, '999,999,999,999');
l_pay_total_cnt_ch := to_char (l_pay_total_cnt, '999,999,999,999');
-- Added for Defect#39138 for "$" Sign and Comma Format - Ends
--
-- CH ID END Defect# 36145
--
-- Added for Defect# 42632 
        ln_ord_enter_tot_ch := TO_CHAR(ln_ord_enter_tot,'$999,999,999,999.99');
        ln_ord_enter_hld_tot_ch := TO_CHAR(ln_ord_enter_hld_tot,'$999,999,999,999.99');
-- Added for the Defect# 43920 
        ln_iso_amount_ch    := TO_CHAR(ln_iso_amount,'$999,999,999,999.99');    		
-- Modified for Defect#39138 for "$" Sign and Comma Format - Start
/*------------------------------------------------------------------------------------------------------------
-- All the parameters passed in hvop_int_error_mail_msg except p_email_list and p_status have been replaced --
-- with new parameterswhich stores the number converted to varchar with "$" Sign and Comma Format			--
------------------------------------------------------------------------------------------------------------*/
-- Added to log
    fnd_file.put_line(fnd_file.log, 'ln_om_count_ch               '||ln_om_count_ch );
	fnd_file.put_line(fnd_file.log, 'ln_om_amount_ch               '||ln_om_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_merch_count_ch             '||ln_merch_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_merch_amount_ch            '||ln_merch_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_fin_count_ch               '||ln_fin_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_fin_amount_ch              '||ln_fin_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_cdh_count_ch               '||ln_cdh_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_cdh_amount_ch              '||ln_cdh_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_gtss_count_ch              '||ln_gtss_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_gtss_amount_ch             '||ln_gtss_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_other_count_ch             '||ln_other_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_other_amount_ch            '||ln_other_amount_ch );
    fnd_file.put_line(fnd_file.log, 'ln_overall_count_ch           '||ln_overall_count_ch );
    fnd_file.put_line(fnd_file.log, 'ln_overall_amount_ch          '||ln_overall_amount_ch );
    fnd_file.put_line(fnd_file.log, 'l_sas_order_cnt_ch            '||l_sas_order_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_sas_order_amt_ch            '||l_sas_order_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_sas_pay_amount_ch           '||l_sas_pay_amount_ch );
    fnd_file.put_line(fnd_file.log, 'l_sas_pay_count_ch            '||l_sas_pay_count_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_err_cnt_ch        '||l_ebs_order_err_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_err_amt_ch        '||l_ebs_order_err_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_ord_err_pay_count_ch    '||l_ebs_ord_err_pay_count_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_ord_err_pay_amount_ch   '||l_ebs_ord_err_pay_amount_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_cnt_ch            '||l_ebs_order_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_amt_ch            '||l_ebs_order_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_total_pay_amt_ch        '||l_ebs_total_pay_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_total_pay_cnt_ch        '||l_ebs_total_pay_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_ordt_pay_cnt_ch         '||l_ebs_ordt_pay_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_ordt_pay_amt_ch         '||l_ebs_ordt_pay_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_miss_ordt_cre_amt_ch    '||l_pay_miss_ordt_cre_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_miss_ordt_cre_cnt_ch    '||l_pay_miss_ordt_cre_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_miss_ordt_dbt_amt_ch    '||l_pay_miss_ordt_dbt_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_miss_ordt_dbt_cnt_ch    '||l_pay_miss_ordt_dbt_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_total_cnt_ch            '||l_pay_total_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_pay_total_amt_ch            '||l_pay_total_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_err_total_cnt_ch  '||l_ebs_order_err_total_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_order_err_total_amt_ch  '||l_ebs_order_err_total_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_err_pay_total_amt_ch    '||l_ebs_err_pay_total_amt_ch );
    fnd_file.put_line(fnd_file.log, 'l_ebs_err_pay_total_cnt_ch    '||l_ebs_err_pay_total_cnt_ch );
    fnd_file.put_line(fnd_file.log, 'ln_ord_enter_cnt              '||ln_ord_enter_cnt );
    fnd_file.put_line(fnd_file.log, 'ln_ord_enter_tot_ch           '||ln_ord_enter_tot_ch );
    fnd_file.put_line(fnd_file.log, 'ln_ord_enter_hld_cnt          '||ln_ord_enter_hld_cnt );
    fnd_file.put_line(fnd_file.log, 'ln_ord_enter_hld_tot_ch       '||ln_ord_enter_hld_tot_ch );
    fnd_file.put_line(fnd_file.log, 'ln_iso_cnt                    '||ln_iso_cnt );
    fnd_file.put_line(fnd_file.log, 'ln_iso_amount_ch              '||ln_iso_amount_ch );
	
	fnd_file.put_line(fnd_file.log, '***********  HVOP Errors (Pending Sales) In Dollars By Each Track  ***********' || crlf ||
  'Date: '   || to_char(sysdate, 'DD-MON-YYYY HH:MM:SS AM') || crlf || crlf ||

   crlf ||
   'CDH Track' || crlf ||
   'Number of Orders: '|| nvl(ln_cdh_count_ch,0) || crlf ||
   'Total pending sales :$'||  nvl(ln_cdh_amount_ch,0.0)|| crlf || crlf ||
   'ORDER MANAGEMENT Track' || crlf ||
   'Number of Orders: ' || nvl(ln_om_count_ch,0) || crlf ||	-- Message body
   'Total pending sales :$'||  nvl(ln_om_amount_ch,0.0)|| crlf ||crlf||
   'MERCHANDISING Track' || crlf ||
   'Number of Orders:' || nvl(ln_merch_count_ch,0) || crlf ||
   'Total pending sales :$'||  nvl(ln_merch_amount_ch,0.0)|| crlf ||crlf ||
   'FINANCE Track' || crlf ||
   'Number of Orders:' || nvl(ln_fin_count_ch,0) || crlf ||
   'Total pending sales :$'||  nvl(ln_fin_amount_ch,0.0)|| crlf ||crlf ||
   'GTSS Track:' || crlf ||
   'Number of Orders:' || nvl(ln_gtss_count_ch,0) || crlf ||
   'Total pending sales :$'|| nvl(ln_gtss_amount_ch,0.0)|| crlf || crlf ||
   'OTHERS (Pending OM Research)' || crlf ||
   'Number of Orders:' || nvl(ln_other_count_ch,0) || crlf ||
   'Total pending sales  :$'|| nvl(ln_other_amount_ch,0.0)|| crlf ||crlf ||
   'ENTERED ORDERS without Holds' || crlf ||
   'Orders Count:' || nvl(ln_ord_enter_hld_cnt,0) || crlf ||
   'Orders Sales  :$'|| nvl(ln_ord_enter_hld_tot_ch,'$0.0')|| crlf ||crlf ||
   'ENTERED ORDERS with Holds' || crlf ||
   'Orders Count:' || nvl(ln_ord_enter_cnt,0) || crlf ||
   'Orders Sales  :$'|| nvl(ln_ord_enter_tot_ch,'$0.0')|| crlf ||crlf ||
   'Internal Orders:' || crlf ||
   'Internal Orders Count:' || nvl(ln_iso_cnt,0) || crlf ||
   'Internal Orders sales  :$'|| nvl(ln_iso_amount_ch,'$0.0')|| crlf ||crlf ||
   'Pending Orders:' || crlf ||
   'Total Pending Orders:' || nvl(ln_overall_count_ch,0) || crlf ||
   'Total pending Orders sales  :$'|| nvl(ln_overall_amount_ch,'$0.0')|| crlf ||crlf ||
   
   'Note: OM will research errors in others category. They  will be adjusted into' || crlf ||
         'appropriate track.' ||crlf); 
		 
hvop_int_error_mail_msg(ln_om_count_ch,
                              ln_om_amount_ch
                              ,ln_merch_count_ch
                              ,ln_merch_amount_ch
                              ,ln_fin_count_ch
                              ,ln_fin_amount_ch
                              ,ln_cdh_count_ch
                              ,ln_cdh_amount_ch
                              ,ln_gtss_count_ch
                              ,ln_gtss_amount_ch
                              ,ln_other_count_ch
                              ,ln_other_amount_ch
							  ,ln_overall_count_ch 		-- Added for Defect#39138
							  ,ln_overall_amount_ch    	-- Added for Defect#39138
						      ,l_sas_order_cnt_ch      -- Added as per Ver 1.4
						      ,l_sas_order_amt_ch
						      ,l_sas_pay_amount_ch
						      ,l_sas_pay_count_ch
			                  ,l_ebs_order_err_cnt_ch
			                  ,l_ebs_order_err_amt_ch
			                  ,l_ebs_ord_err_pay_count_ch
			                  ,l_ebs_ord_err_pay_amount_ch
			                  ,l_ebs_order_cnt_ch
			                  ,l_ebs_order_amt_ch
			                  ,l_ebs_total_pay_amt_ch
			                  ,l_ebs_total_pay_cnt_ch
			                  ,l_ebs_ordt_pay_cnt_ch
			                  ,l_ebs_ordt_pay_amt_ch
			                  ,l_pay_miss_ordt_cre_amt_ch
			                  ,l_pay_miss_ordt_cre_cnt_ch
			                  ,l_pay_miss_ordt_dbt_amt_ch
			                  ,l_pay_miss_ordt_dbt_cnt_ch
			                  ,l_pay_total_cnt_ch
			                  ,l_pay_total_amt_ch
				              ,l_ebs_order_err_total_cnt_ch 			-- Added for Defect#39138
				              ,l_ebs_order_err_total_amt_ch 			-- Added for Defect#39138
				              ,l_ebs_err_pay_total_amt_ch 				-- Added for Defect#39138
				              ,l_ebs_err_pay_total_cnt_ch 				-- Added for Defect#39138, Modified for Defect#39138 for "$" Sign and Comma Format - Ends
                              ,ln_ord_enter_cnt
                              ,ln_ord_enter_tot_ch
                              ,ln_ord_enter_hld_cnt
                              ,ln_ord_enter_hld_tot_ch
							  ,ln_iso_cnt 
							  ,ln_iso_amount_ch
                              ,p_email_list
                              ,p_status);

                retcode := 0;
                errbuf := 'Y';
Exception

        When No_data_found then
          lc_error_message := 'No Data found';
          p_status := 'N';
          when Others then
          lc_error_message := 'Unknown Error occured';
          p_status := 'N';


End hvop_int_error_count;

-- Modified for Defect#39138 for "$" Sign and Comma Format - Start
/*-----------------------------------------------------------------------------------------------------
-- Changed the datatype of parameters from number to varchar2 for "$" sign and with commas by Poonam --
-----------------------------------------------------------------------------------------------------*/
PROCEDURE HVOP_INT_ERROR_MAIL_MSG(P_OMCOUNT                         IN VARCHAR2
                                        ,p_omamount                 IN VARCHAR2
                                        ,P_MERCHCOUNT               IN VARCHAR2
                                        ,p_merchamount              IN VARCHAR2
                                        ,P_FINCOUNT                 IN VARCHAR2
                                        ,p_finamount                IN VARCHAR2
                                        ,P_CDHCOUNT                 IN VARCHAR2
                                        ,p_cdhamount                IN VARCHAR2
                                        ,P_GTSSCOUNT                IN VARCHAR2
                                        ,p_gtssamount               IN VARCHAR2
                                        ,P_OTHERCOUNT               IN VARCHAR2
                                        ,p_OtherAmount              In VARCHAR2
										,p_overallcount             IN VARCHAR2 		-- Added for Defect#39138
										,p_overallamount            IN VARCHAR2 		-- Added for Defect#39138
					                    ,p_sas_order_cnt            IN VARCHAR2    -- Added as per Ver 1.4
					                    ,p_sas_order_amt            IN VARCHAR2
					                    ,p_sas_pay_amount           IN VARCHAR2
					                    ,P_SAS_PAY_COUNT            IN VARCHAR2
					                    ,p_ebs_order_err_cnt        IN VARCHAR2
					                    ,p_ebs_order_err_amt        IN VARCHAR2
					                    ,p_ebs_ord_err_pay_count    IN VARCHAR2
					                    ,p_ebs_ord_err_pay_amount   IN VARCHAR2
					                    ,p_ebs_order_cnt            IN VARCHAR2
					                    ,p_ebs_order_amt            IN VARCHAR2
					                    ,p_ebs_total_pay_amt        IN VARCHAR2
					                    ,p_ebs_total_pay_cnt        IN VARCHAR2
					                    ,p_ebs_pay_cnt              IN VARCHAR2
					                    ,p_ebs_pay_amt              IN VARCHAR2
					                    ,p_pay_miss_ordt_cre_amt    IN VARCHAR2
			                            ,p_pay_miss_ordt_cre_cnt    IN VARCHAR2
			                            ,p_pay_miss_ordt_dbt_amt    IN VARCHAR2
			                            ,p_pay_miss_ordt_dbt_cnt    IN VARCHAR2
			                            ,p_pay_total_cnt            IN VARCHAR2
                                        ,p_pay_total_amt            IN VARCHAR2
										,p_ebs_order_err_total_cnt_ch IN VARCHAR2 	--Added for Defect#39138
										,p_ebs_order_err_total_amt_ch In VARCHAR2	--Added for Defect#39138
										,p_ebs_err_pay_total_amt_ch   IN VARCHAR2		--Added for Defect#39138
										,p_ebs_err_pay_total_cnt_ch   IN VARCHAR2		--Added for Defect#39138, Modified for Defect#39138 for "$" Sign and Comma Format - End
                                        ,p_ord_enter_cnt                IN VARCHAR2    --Added for Defect#42632  
                                        ,p_ord_enter_tot_ch             IN VARCHAR2    --Added for Defect#42632  
                                        ,p_ord_enter_hld_cnt            IN VARCHAR2    --Added for Defect#42632 
                                        ,p_ord_enter_hld_tot_ch         IN VARCHAR2    --Added for Defect#42632
										,p_iso_cnt                      IN VARCHAR2            --Added for Defect#43920 
										,p_iso_amount_ch                IN VARCHAR2           --Added for Defect#43920 
                                        ,p_email_list                   IN Varchar2
                                        ,x_mail_sent_status out VARCHAR2) IS
lc_mail_from varchar2(100):='noreply@officedepot.com';
lc_mail_recipient VARCHAR2(1000);
--lc_mail_subject VARCHAR2(1000) := 'HVOP Pending Sales' ;
--CH ID#34203 Start
--lc_mail_host VARCHAR2(100):= 'USCHMSX83.na.odcorp.net';
lc_mail_host VARCHAR2(100):= fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');

--CH ID#34203 End
LC_MAIL_CONN UTL_SMTP.CONNECTION;

crlf  VARCHAR2(10) := chr(13) || chr(10);
slen number :=1;
v_addr Varchar2(1000);
lc_instance varchar2(100);
lc_msg_body CLOB;
lc_mail_subject     VARCHAR2(2000);
-- -- Added as per Ver 1.4
lc_mail_body_det1        VARCHAR2(5000):=NULL;
lc_mail_body_det2       VARCHAR2(5000):=NULL;
lc_mail_header1      VARCHAR2(1000);
lc_mail_body_det3       VARCHAR2(5000):=NULL;
lc_mail_body_det4       VARCHAR2(5000):=NULL;
lc_mail_body_det5       VARCHAR2(5000):=NULL;
lc_mail_body_det6       VARCHAR2(5000):=NULL;
lc_mail_header2         VARCHAR2(1000);
lc_mail_body1        VARCHAR2(5000):=NULL;
lc_mail_body2       VARCHAR2(5000):=NULL;
lc_mail_header      VARCHAR2(1000);
lc_mail_body3       VARCHAR2(5000):=NULL;
lc_mail_body4       VARCHAR2(5000):=NULL;
lc_mail_body5       VARCHAR2(5000):=NULL;
lc_mail_body6       VARCHAR2(5000):=NULL;
lc_mail_body7       VARCHAR2(5000):=NULL; 	--Added by for Defect#39138
lc_mail_body8       VARCHAR2(5000) := NULL; 	--Added by for Defect#42632 
lc_mail_body9       VARCHAR2(5000) := NULL; 	--Added by for Defect#42632 
lc_mail_body10       VARCHAR2(5000) := NULL; 	--Added by for Defect#43920

Begin
LC_MAIL_CONN := UTL_SMTP.OPEN_CONNECTION(LC_MAIL_HOST,25);

FND_FILE.put_line(FND_FILE.log,'Preparing to Send Mail');  -- Added for Defect#39138

--lc_mail_recipient := 'bala.edupuganti@officedepot.com,bapuji.nanapaneni@officedepot.com';
--lc_mail_recipient := 'om_hvop@officedepot.com,bala.edupuganti@officedepot.com';
lc_mail_recipient := P_email_list;

FND_FILE.put_line(FND_FILE.log,'Mail Recipients Set:' ||lc_mail_recipient );  -- Added for Defect#39138

utl_smtp.helo(lc_mail_conn, lc_mail_host);
utl_smtp.mail(lc_mail_conn, lc_mail_from);
--utl_smtp.rcpt(lc_mail_conn,lc_mail_recipient);

if (instr(lc_mail_recipient,',') = 0) then
V_ADDR:= LC_MAIL_RECIPIENT;
utl_smtp.rcpt(lc_mail_conn,v_addr);
else
lc_mail_recipient := replace(lc_mail_recipient,' ','_') || ',';
while (instr(lc_mail_recipient,',',slen)> 0) loop
v_addr := substr(lc_mail_recipient,slen,instr(substr(lc_mail_recipient,slen),',')-1);
--lc_mail_recipient := substr(lc_mail_recipient,slen,instr(substr(lc_mail_recipient,slen),',')-1);
SLEN := SLEN + INSTR(SUBSTR(LC_MAIL_RECIPIENT,SLEN),',');
utl_smtp.rcpt(lc_mail_conn,v_addr);

end loop;
end if;
select instance_name into lc_instance from v$instance;
lc_mail_subject := 'HVOP ERROR (Pending Sales) IN - ' || lc_instance;
--
-- Modified for Defect#39138 - Start
/*----------------------------------------------------------------------------------------------------------------------------
-- Modified all below lines for formatting round to 2 decimal digits, added '$' sign in amounts, and formatting with commas --
-- in all numbers  -- Corrected 'CHD Track' to 'CDH Track', 'Total' to 'OM Total'  -- Added new line for Total Pending		--
----------------------------------------------------------------------------------------------------------------------------*/
--Added right justification per defect# 40149
--lc_mail_header1 := '<TABLE border="1"><TR align="left"><TH><B>  </B></TH><TH><B>SAS</B></TH><TH><B>OM Interface</B></TH><TH><B>OM</B></TH><TH><B>ORDT</B></TH></TR>';						-- Commented for Defect#39138
lc_mail_header1 := '<TABLE border="1"><TR align="center"><TH><B>  </B></TH><TH><B>SAS</B></TH><TH><B>OM Interface</B></TH><TH><B>OM</B></TH><TH><B>OM Total</B></TH><TH><B>ORDT</B></TH></TR>';  -- Modified for Defect#39138
--lc_mail_body_det1 :=lc_mail_body_det1||'<TR><TD>'||'Order Count'||'</TD><TD>'||nvl(p_sas_order_cnt,0)||'</TD><TD>'||nvl(p_ebs_order_err_cnt,0)||'</TD><TD>'||nvl(p_ebs_order_cnt,0)||'</TD><TD>'||'N/A'||'</TD></TR>';																																-- Commented for Defect#39138
lc_mail_body_det1 :=lc_mail_body_det1||'<TR><TD align="left">'||'Order Count'||'</TD><TD align="right">'||nvl(p_sas_order_cnt,0)||'</TD><TD align="right">'||nvl(p_ebs_order_err_cnt,0)||'</TD><TD align="right">'||nvl(p_ebs_order_cnt,0)||'</TD><TD align="right">'||nvl(p_ebs_order_err_total_cnt_ch,0)||'</TD><TD align="right">'||'N/A'||'</TD></TR>'; 																				-- Added for Defect#39138
--lc_mail_body_det2 :=lc_mail_body_det2||'<TR><TD>'||'Order $'||'</TD><TD>'||nvl(p_sas_order_amt,0)||'</TD><TD>'||nvl(p_ebs_order_err_amt,0)||'</TD><TD>'||nvl(p_ebs_order_amt,0)||'</TD><TD>'||'N/A'||'</TD></TR>';																																	-- Commented by Leelakrishna
--lc_mail_body_det2 :=lc_mail_body_det2||'<TR><TD>'||'Order $'||'</TD><TD>'||'$'||round(nvl(p_sas_order_amt,0),2)||'</TD><TD>'||'$'||round(nvl(p_ebs_order_err_amt,0),2)||'</TD><TD>'||'$'||round(nvl(p_ebs_order_amt,0),2)||'</TD><TD>'||'$'||round((nvl(p_ebs_order_err_amt,0)+nvl(p_ebs_order_amt,0)),2)||'</TD><TD>'||'N/A'||'</TD></TR>';  		-- Commented for Defect#39138																--Added by Leelakrishna
lc_mail_body_det2 :=lc_mail_body_det2||'<TR><TD align="left">'||'Order'||'</TD><TD align="right">'||nvl(p_sas_order_amt,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_order_err_amt,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_order_amt,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_order_err_total_amt_ch,'$0.0')||'</TD><TD align="right" >'||'N/A'||'</TD></TR>';																	-- Added for Defect#39138																--Added by Leelakrishna
--lc_mail_body_det3 :=lc_mail_body_det3||'<TR><TD>'||'Payment Count'||'</TD><TD>'||nvl(p_sas_pay_count,0)||'</TD><TD>'||nvl(p_ebs_ord_err_pay_count,0)||'</TD><TD>'||nvl(p_ebs_total_pay_cnt,0)||'</TD><TD>'||nvl(p_ebs_pay_cnt,0)||'</TD></TR>';																										-- Commented for Defect#39138
lc_mail_body_det3 :=lc_mail_body_det3||'<TR><TD align="left">'||'Payment Count'||'</TD><TD align="right">'||nvl(p_sas_pay_count,0)||'</TD><TD align="right">'||nvl(p_ebs_ord_err_pay_count,0)||'</TD><TD align="right">'||nvl(p_ebs_total_pay_cnt,0)||'</TD><TD align="right">'||(nvl(p_ebs_err_pay_total_cnt_ch,0))||'</TD><TD align="right">'||nvl(p_ebs_pay_cnt,0)||'</TD></TR>';														-- Added for Defect#39138
--lc_mail_body_det4 :=lc_mail_body_det4||'<TR><TD>'||'Payment $'||'</TD><TD>'||nvl(p_sas_pay_amount,0)||'</TD><TD>'||nvl(p_ebs_ord_err_pay_amount ,0)||'</TD><TD>'||nvl(p_ebs_total_pay_amt,0)||'</TD><TD>'||nvl(p_ebs_pay_amt,0)||'</TD></TR>';																										-- Commented for Defect#39138
lc_mail_body_det4 :=lc_mail_body_det4||'<TR><TD align="left">'||'Payment'||'</TD><TD align="right">'||nvl(p_sas_pay_amount,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_ord_err_pay_amount ,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_total_pay_amt,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_err_pay_total_amt_ch,'$0.0')||'</TD><TD align="right">'||nvl(p_ebs_pay_amt,'$0.0')||'</TD></TR>';									-- Added for Defect#39138
lc_mail_header2 := '<TABLE border="1"><TR align="center"><TH><B>  </B></TH><TH><B>Credit Card</B></TH><TH><B>NON-CC</B></TH><TH><B>Total</B></TH></TR>';
LC_MAIL_BODY_DET5 :=LC_MAIL_BODY_DET5||'<TR><TD align="left">'||'Receipt Count'||'</TD><TD align="right">'||NVL(P_PAY_MISS_ORDT_CRE_CNT,0)||'</TD><TD align="right">'||NVL(P_PAY_MISS_ORDT_DBT_CNT ,0)||'</TD><TD align="right">'||NVL(P_PAY_TOTAL_CNT,0)||'</TD></TR>';
lc_mail_body_det6 :=lc_mail_body_det6||'<TR><TD align="left">'||'Receipt Total'||'</TD><TD align="right">'||nvl(p_pay_miss_ordt_cre_amt,'$0.0')||'</TD><TD align="right">'||nvl(p_pay_miss_ordt_dbt_amt ,'$0.0')||'</TD><TD align="right">'||nvl(p_pay_total_amt,'$0.0')||'</TD></TR>';																														-- Modified for Defect#39138
lc_mail_header := '<TABLE border="1"><TR align="center"><TH><B>TRACK</B></TH><TH><B>Total Orders Pending</B></TH><TH><B>Total Pending Sales*</B></TH></TR>'; 																			    																												-- Added for Defect#39138
--lc_mail_body1 :=lc_mail_body1||'<TR><TD>'||'CHD Track'||'</TD><TD>'||nvl(p_cdhcount,0)||'</TD><TD>'||nvl(p_cdhamount,0)||'</TD></TR>'; 																																																				-- Commented for Defect#39138
LC_MAIL_BODY1 :=LC_MAIL_BODY1||'<TR><TD>'||'CDH Track'||'</TD><TD align="right">'||NVL(P_CDHCOUNT,0)||'</TD><TD align="right">'||NVL(P_CDHAMOUNT,'$0.0')||'</TD></TR>';  																																																			-- Added for Defect#39138
LC_MAIL_BODY2 :=LC_MAIL_BODY2||'<TR><TD>'||'ORDER MANAGMENT Track'||'</TD><TD align="right">'||NVL(P_OMCOUNT,0)||'</TD><TD align="right">'||NVL(P_OMAMOUNT,'$0.0')||'</TD></TR>';																																																	-- Added for Defect#39138
LC_MAIL_BODY3 :=LC_MAIL_BODY3||'<TR><TD>'||'MERCHANDISING Track'||'</TD><TD align="right">'||NVL(P_MERCHCOUNT,0)||'</TD><TD align="right">'||NVL(P_MERCHAMOUNT,'$0.0')||'</TD></TR>';																																																-- Added for Defect#39138
LC_MAIL_BODY4 :=LC_MAIL_BODY4||'<TR><TD>'||'FINANCE Track'||'</TD><TD align="right">'||NVL(P_FINCOUNT,0)||'</TD><TD align="right">'||NVL(P_FINAMOUNT,'$0.0')||'</TD></TR>';																																																			-- Added for Defect#39138
lc_mail_body5 :=lc_mail_body5||'<TR><TD>'||'GTSS Track'||'</TD><TD align="right">'||nvl(p_gtsscount,0)||'</TD><TD align="right">'||nvl(p_gtssamount,'$0.0')||'</TD></TR>';																																																			-- Added for Defect#39138
lc_mail_body6 :=lc_mail_body6||'<TR><TD>'||'OTHERS (Pending OM Research)'||'</TD><TD align="right">'||nvl(p_othercount,0)||'</TD><TD align="right">'||nvl(p_otheramount,0.0)||'</TD></TR>';
--lc_mail_body6 :=lc_mail_body7||'<TR><TD>'||'Total Pending'||'</TD><TD>'||nvl(p_othercount,0)||'</TD><TD>'||nvl(p_otheramount,0.0)||'</TD></TR>';  																																																	-- Added by Leelakrishna  -- Commented for Defect#39138
lc_mail_body7 :=lc_mail_body7||'<TR><TD>'||'Total Pending'||'</TD><TD align="right">'||nvl(p_overallcount,0)||'</TD><TD align="right">'||nvl(p_overallamount,'$0.0')||'</TD></TR>';  																																																-- Added for Defect#39138
lc_mail_body8 := lc_mail_body8
         || '<TR><TD>'
         || 'ENTERED ORDERS without Holds'
         || '</TD><TD align="right">'
         || nvl(p_ord_enter_cnt,0)
         || '</TD><TD align="right">'
         || nvl(p_ord_enter_tot_ch,'$0.0')
         || '</TD></TR>';

        lc_mail_body9 := lc_mail_body9
         || '<TR><TD>'
         || 'ENTERED ORDERS with Holds'
         || '</TD><TD align="right">'
         || nvl(p_ord_enter_hld_cnt,0)
         || '</TD><TD align="right">'
         || nvl(p_ord_enter_hld_tot_ch,'$0.0')
         || '</TD></TR>';
		 lc_mail_body10 := lc_mail_body10
         || '<TR><TD>'
         || 'Internal Orders'
         || '</TD><TD align="right">'
         || nvl(p_iso_cnt,0)
         || '</TD><TD align="right">'
         || nvl(p_iso_amount_ch,'$0.0')
         || '</TD></TR>';
--
FND_FILE.put_line(FND_FILE.log,'Data prepared before sending to server');  -- Added for Defect#39138
-- Modified for Defect#39138 - End
UTL_SMTP.DATA
         (lc_mail_conn,
             'From:'
          || lc_mail_from
          || UTL_TCP.crlf
          || 'To: '
          || v_addr
          || UTL_TCP.crlf
          || 'Subject: '
          || lc_mail_subject
          || UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
	  ||utl_tcp.CRLF
	  ||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR>Hi All,<BR><BR>'
          || crlf
          || crlf
          || crlf
          ||'***********  Order And Receipt Summary  ***********:<BR><BR>'
          ||crlf
          ||crlf
          ||lc_mail_header1
          ||lc_mail_body_det1
          ||lc_mail_body_det2
          ||lc_mail_body_det3
          ||lc_mail_body_det4
          ||'</TABLE><BR>'
          || crlf
          || crlf
          || crlf
          ||'***********  Payments Missing IN ORDT  ***********:<BR><BR>'
          ||crlf
          ||crlf
          ||lc_mail_header2
	      ||lc_mail_body_det5
          ||lc_mail_body_det6
          ||'</TABLE><BR>'
          ||crlf
          ||crlf
          ||crlf
          || '***********  HVOP Errors (Pending Sales) In Dollars By Each Track  ***********:<BR><BR>'
          || crlf
          || ' Note: Totals are calculated based on absolute amounts* '
          || crlf
	  || crlf
	  ||lc_mail_header
          || lc_mail_body1
          || lc_mail_body2
	  || lc_mail_body3
	  || lc_mail_body4
	  || lc_mail_body5
	  || lc_mail_body6
          || lc_mail_body8  -- Added for Defect#42632 
          || lc_mail_body9  -- Added for Defect#42632
		  || lc_mail_body10 -- Added for Defect#43920
	  || lc_mail_body7 -- Added for Defect#39138
	  ||'</TABLE><BR>'
          || crlf
    		|| crlf
            || '<BR>------------------------------------------------------------------------------------------------------------------<BR>'
		    || crlf
	        || 'Note: OM will research errors in others category. They  will be adjusted into appropriate track.'
	        || crlf
			|| 'As the same order could be in mulitple buckets, the Sum of Total Order Pending is not the SUM of each error BUCKET.'
			|| crlf
            || 'Total Pending Order is the sum of Distinct Orders in OE INTERFACE (excluding Internal Orders) plus Total Orders WITH and WITHOUT HOLDS.'
			|| crlf
            || '<BR>------------------------------------------------------------------------------------------------------------------<BR><BR><BR>'
            || crlf||'</BODY></HTML>'
         );

/* commented as per Ver 1.4
utl_smtp.data(lc_mail_conn,'From:'||  lc_mail_from || utl_tcp.crlf ||
                           'To: ' || v_addr || utl_tcp.crlf ||
                           'Subject: ' || lc_mail_subject ||
                            utl_tcp.crlf ||
 '***********  HVOP Errors (Pending Sales) In Dollars By Each Track  ***********' || crlf ||
  'Date: '   || to_char(sysdate, 'DD-MON-YYYY HH:MM:SS AM') || crlf || crlf ||

   crlf ||
   'CDH Track' || crlf ||
   'Number of Orders: '|| nvl(p_cdhcount,0) || crlf ||
   'Total pending sales :$'||  nvl(p_cdhamount,0.0)|| crlf || crlf ||
   'ORDER MANAGEMENT Track' || crlf ||
   'Number of Orders: ' || nvl(p_omcount,0) || crlf ||	-- Message body
   'Total pending sales :$'||  nvl(p_omamount,0.0)|| crlf ||crlf||
   'MERCHANDISING Track' || crlf ||
   'Number of Orders:' || nvl(p_merchcount,0) || crlf ||
   'Total pending sales :$'||  nvl(p_merchamount,0.0)|| crlf ||crlf ||
   'FINANCE Track' || crlf ||
   'Number of Orders:' || nvl(p_fincount,0) || crlf ||
   'Total pending sales :$'||  nvl(p_finamount,0.0)|| crlf ||crlf ||
   'GTSS Track:' || crlf ||
   'Number of Orders:' || nvl(p_gtsscount,0) || crlf ||
   'Total pending sales :$'|| nvl(p_gtssamount,0.0)|| crlf || crlf ||
   'OTHERS (Pending OM Research)' || crlf ||
   'Number of Orders:' || nvl(p_othercount,0) || crlf ||
   'Total pending sales  :$'|| nvl(p_otheramount,0.0)|| crlf ||crlf ||
   'Note: OM will research errors in others category. They  will be adjusted into' || crlf ||
         'appropriate track.' ||crlf

 );*/

FND_FILE.put_line(FND_FILE.log,'Data Sent to Mail Server');  -- Added for Defect#39138
utl_smtp.Quit(lc_mail_conn);
X_MAIL_SENT_STATUS := 'Y';
FND_FILE.PUT_LINE(FND_FILE.LOG,'Mail Sent Successfully');  -- Added for Defect#39138

EXCEPTION
 WHEN utl_smtp.Transient_Error OR utl_smtp.Permanent_Error then
   RAISE_APPLICATION_ERROR(-20000, 'Unable to send mail: '||SQLERRM);

END HVOP_INT_ERROR_MAIL_MSG;
END;
/
EXIT;
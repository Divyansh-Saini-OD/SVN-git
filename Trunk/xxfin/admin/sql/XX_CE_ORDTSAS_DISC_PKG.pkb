create or replace 
PACKAGE BODY xx_ce_ordtsas_disc_pkg AS

-- +=====================================================================================================+
-- |                                Office Depot - Project Simplify                                      |
-- |                                     Oracle AMS Support                                              |
-- +=====================================================================================================+
-- |  Name:  XX_CE_ORDTSAS_DISC_PKG (RICE ID : R1392)                                                    |
-- |                                                                                                     |
-- |  Description: This package will be used by following concurrent programs (reports):                 |
-- |                1. OD: CE Order Receipt Detail Discrepancy Report - Excel (XXCEORDTSASDISC_EXCEL)    |
-- |                2. OD: CE Order Receipt Detail Discrepancy Report - Child (XXCEORDTSASDISC_CHILD)    |
-- |                3. OD: CE Order Receipt Detail Discrepancy Summary Report (XXCEORDTSASDISC_SUMMARY)  |
-- |                4. OD: CE Order Receipt Detail Discrepancy Detail Report  (XXCEORDTSASDISC)          |
-- |                                                                                                     |
-- |    FUNCTION before_report_det    Before report trigger for XML Publisher detail report              |
-- |    FUNCTION after_report_det     After report trigger for XML Publisher details report              |
-- |    FUNCTION before_report_sum    Before report trigger for XML Publisher summary report             |
-- |    FUNCTION after_report_sum     After report trigger for XML Publisher summary report              |
-- |    PROCEDURE submit_child_prog   Procedure to submit child request to prepare master data for report|
-- |    PROCEDURE submit_wrapper_prog Procedure to submit wrapper program which will main submit report  |
-- |                                                                                                     |
-- |  Local Procedures:                                                                                  |
-- |    PROCEDURE init_detail_params        Procedure to initialize report parameters                    |
-- |    PROCEDURE generated_pos_data        Procedure to POS data for detail report                      |
-- |    PROCEDURE generated_aops_data       Procedure to AOPS data for detail report                     |
-- |    PROCEDURE generated_spay_data       Procedure to Single Pay data for detail report               |
-- |    PROCEDURE generated_pos_data_sum    Procedure to POS data for summary report                     |
-- |    PROCEDURE generated_aops_data_sum   Procedure to AOPS data for summary report                    |
-- |    PROCEDURE generated_spay_data_sum   Procedure to Single Pay data for summary report              |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  ===================  ======================================================|
-- | 1.0         14-Nov-2013  Abdul Khan           Initial version - QC Defect # 25401                   |
-- | 1.1         16-Oct-2015  Suresh Ponnamabalam  Defect 36151. Removed schema prefix.                  |
-- | 1.2         30-Nov-2016  Avinash Baddam       R12.2 GSCC change									 |
-- | 1.3         14-Mar-2017  Leelakrishna.G       Defect#40824						 |					 |
-- +=====================================================================================================+


    -- Global variables
    gn_org_id            NUMBER  := 0;
    gn_min_hdr_id        NUMBER  := 0;
    gn_max_hdr_id        NUMBER  := 0;
    --gc_where_sas_itm     VARCHAR2(4000);
    --gc_where_ordt_itm    VARCHAR2(4000);
    gc_where_itm         VARCHAR2(4000);
    gc_where_sas         VARCHAR2(4000);
    gc_where_ordt        VARCHAR2(4000);

    -- Populating xx_ce_sas_itm table in threads
    C_SAS_ORDT_ITM_SQL CONSTANT VARCHAR2(32000):=
        'INSERT INTO xx_ce_ordt_sas_itm
         SELECT TRUNC(oehl.actual_shipment_date) receipt_date,
                SUBSTR(hrou.name, 1, 6) store_number,
                flv.meaning tender_type,
                xxoep.payment_amount total_amount,
                oeh.order_source_id,
                oeh.ship_from_org_id,
                oeh.sold_to_org_id,
                xxha.created_by_store_id,
                oeh.header_id,
                xxoep.cash_receipt_id,
                oeh.org_id,
                (SELECT NVL(single_pay_ind, ''N'') FROM xx_om_legacy_dep_dtls WHERE SUBSTR(orig_sys_document_ref, 1, 9) = SUBSTR(oeh.orig_sys_document_ref, 1, 9)
                    AND LENGTH(orig_sys_document_ref) <= 12 AND ROWNUM < 2
                  UNION
                 SELECT NVL(single_pay_ind, ''N'') FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = oeh.orig_sys_document_ref AND ROWNUM < 2
                  UNION
                 SELECT NVL(single_pay_ind, ''N'') FROM xx_ar_order_receipt_dtl WHERE cash_receipt_id = xxoep.cash_receipt_id AND ROWNUM < 2) single_pay_ind,
                oeh.order_number,
                oeh.orig_sys_document_ref,
                SUBSTR(oeh.orig_sys_document_ref, 1, 9) orig_sys_doc_ref_sub,
                xxoep.credit_card_code,
                xxoep.payment_number,
                xxoep.orig_sys_payment_ref,
                SYSDATE creation_date,
                :1 created_by,
                :2 parent_req_id,
                :3 child_req_id,
                :4 thread_number
           FROM xx_om_header_attributes_all xxha,
                oe_order_headers_all oeh,
                oe_order_lines_all oehl,
                fnd_lookup_values flv,
                hr_all_organization_units hrou,
                (SELECT oep.header_id, oep.payment_number, oep.payment_type_code, oep.attribute11 credit_card_code, oep.credit_card_number,
                        oep.payment_amount, TO_NUMBER(attribute15) cash_receipt_id, oep.orig_sys_payment_ref
                   FROM oe_payments oep
                  UNION
                 SELECT xxrt.header_id, xxrt.payment_number, xxrt.payment_type_code, xxrt.od_payment_type credit_card_code, xxrt.credit_card_number,
                        xxrt.credit_amount * -1 payment_amount, xxrt.cash_receipt_id, xxrt.orig_sys_payment_ref
                   FROM xx_om_return_tenders_all xxrt) xxoep
          WHERE oeh.header_id = xxha.header_id
            AND xxha.order_total <> 0
            AND xxoep.header_id = oeh.header_id
            AND flv.lookup_type = ''OD_PAYMENT_TYPES''
            AND flv.enabled_flag = ''Y''
            AND flv.lookup_code = xxoep.credit_card_code
            AND oehl.header_id = oeh.header_id
            AND hrou.organization_id = oeh.ship_from_org_id
            AND oehl.rowid IN (SELECT MAX(rowid) FROM oe_order_lines_all WHERE header_id = oeh.header_id)
            AND NOT EXISTS (SELECT 1 FROM hz_customer_profiles WHERE cust_account_id = oeh.sold_to_org_id AND NVL(attribute3, ''N'') = ''Y'')
            $lc_where_itm$
            AND oeh.header_id BETWEEN :5 AND :6';

    -- Populating xx_ce_ordt_itm table in threads
    /*C_ORDT_ITM_SQL CONSTANT VARCHAR2(32000):=
        'INSERT INTO xx_ce_ordt_itm
         SELECT TRUNC(xxordt.receipt_date) receipt_date,
                xxordt.store_number,
                flv.meaning tender_type,
                xxordt.payment_amount total_amount,
                oeh.order_source_id,
                oeh.ship_from_org_id,
                oeh.sold_to_org_id,
                xxha.created_by_store_id,
                oeh.header_id,
                oeh.org_id,
                NVL(xxordt.single_pay_ind, ''N'') single_pay_ind,
                oeh.order_number,
                oeh.orig_sys_document_ref,
                SUBSTR(oeh.orig_sys_document_ref, 1, 9) orig_sys_doc_ref_sub,
                SYSDATE creation_date,
                :1 created_by,
                :2 parent_req_id,
                :3 child_req_id,
                :4 thread_number
           FROM xx_om_header_attributes_all xxha,
                oe_order_headers_all oeh,
                fnd_lookup_values flv,
                xx_ar_order_receipt_dtl xxordt,
                (SELECT oep.header_id, oep.payment_number, oep.payment_type_code, oep.attribute11 credit_card_code, oep.credit_card_number,
                        oep.payment_amount, TO_NUMBER(attribute15) cash_receipt_id
                   FROM oe_payments oep
                  UNION
                 SELECT xxrt.header_id, NULL payment_number, xxrt.payment_type_code, xxrt.od_payment_type credit_card_code, xxrt.credit_card_number,
                        xxrt.credit_amount * -1 payment_amount, xxrt.cash_receipt_id
                   FROM xx_om_return_tenders_all xxrt) xxoep
          WHERE oeh.header_id = xxha.header_id
            AND xxha.order_total <> 0
            AND xxoep.header_id = oeh.header_id
            AND flv.lookup_type = ''OD_PAYMENT_TYPES''
            AND flv.enabled_flag = ''Y''
            AND flv.lookup_code = xxoep.credit_card_code
            AND xxordt.od_payment_type = xxoep.credit_card_code
            AND xxordt.payment_number = xxoep.payment_number
            AND xxordt.header_id = oeh.header_id
            AND acra.cash_receipt_id = xxordt.cash_receipt_id
            $lc_where_ordt_itm$
            AND oeh.header_id BETWEEN :5 AND :6';*/


    -- Queries for OD: CE Order Receipt Detail Discrepancy Summary Report - Start
    -- POS SAS Summary Query
	-----------------------------1---------------------------------
	--Commented for the Defect#40824
    /*
	C_POS_SAS_SUM_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_pos_sas_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id = 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';
	*/
		 
	--Added for the Defect#40824	 
	C_POS_SAS_SUM_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_pos_sas_itm AS
		insert into xxfin.xx_ce_pos_sas_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id = 1025 /*Order Source = POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';

    -----------------------------2---------------------------------
	-- POS ORDT Summary Query
	--Commented for the Defect#40824
	/*
    C_POS_ORDT_SUM_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_pos_ordt_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM(xxordt.payment_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm,
                xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id = 1025
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND xxordt.payment_number = NVL(xxitm.payment_number, xxordt.payment_number)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';
	*/
		 
	--Added for the Defect#40824	 
	C_POS_ORDT_SUM_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_pos_ordt_itm AS
		insert into xxfin.xx_ce_pos_ordt_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM(xxordt.payment_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm,
                xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id = 1025 /*Order Source = POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND xxordt.payment_number = NVL(xxitm.payment_number, xxordt.payment_number)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';

    -----------------------------3---------------------------------
	-- AOPS SAS Summary Query
	--Commented for the Defect#40824
	/*
    C_AOPS_SAS_SUM_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_aops_sas_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';
	*/
	
--Added for the Defect#40824	
	C_AOPS_SAS_SUM_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_aops_sas_itm AS
		insert into xxfin.xx_ce_aops_sas_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.tender_type';

	-----------------------------4---------------------------------	 
    -- AOPS ORDT Summary Query
	--Commented for the Defect#40824
    /*
	C_AOPS_ORDT_SUM_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_aops_ordt_itm AS
         SELECT aops_ordt.receipt_date, aops_ordt.tender_type, SUM (aops_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id <> 1025
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
          WHERE xxitm.order_source_id <> 1025 
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.rowid = (SELECT MAX(rowid) FROM xx_om_legacy_dep_dtls WHERE transaction_number = xoldd.transaction_number)
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, (-1 * arra.amount_applied) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, ar_receivable_applications_all arra
          WHERE xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N'' --AND xxitm.tender_type = ''PAYPAL''
            AND xxitm.total_amount < 0
            AND arra.cash_receipt_id = xxitm.cash_receipt_id
            AND arra.attribute7 = xxitm.orig_sys_document_ref
            AND arra.display = ''Y''
            AND arra.status = ''ACTIVITY''
            $lc_where_ordt$) aops_ordt
         GROUP BY aops_ordt.receipt_date, aops_ordt.tender_type';
	*/
		 
	--Added for the Defect#40824
	C_AOPS_ORDT_SUM_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_aops_ordt_itm AS
		insert into xxfin.xx_ce_aops_ordt_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT aops_ordt.receipt_date, aops_ordt.tender_type, SUM (aops_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.rowid = (SELECT MAX(rowid) FROM xx_om_legacy_dep_dtls WHERE transaction_number = xoldd.transaction_number)
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.tender_type, (-1 * arra.amount_applied) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, ar_receivable_applications_all arra
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N'' --AND xxitm.tender_type = ''PAYPAL''
            AND xxitm.total_amount < 0
            AND arra.cash_receipt_id = xxitm.cash_receipt_id
            AND arra.attribute7 = xxitm.orig_sys_document_ref
            AND arra.display = ''Y''
            AND arra.status = ''ACTIVITY''
            $lc_where_ordt$) aops_ordt
         GROUP BY aops_ordt.receipt_date, aops_ordt.tender_type';

    -----------------------------5---------------------------------
	-- Single Pay SAS Summary Query
	--Commented for the Defect#40824
	/*
    C_SPAY_SAS_SUM_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_spay_sas_itm AS
         SELECT spay_ordt.receipt_date, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xxitm.total_amount total_amount, xxitm.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xoldd.order_total total_amount, xoldd.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.tender_type';
	*/
		
	--Added for the Defect#40824
	C_SPAY_SAS_SUM_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_spay_sas_itm AS
		insert into xxfin.xx_ce_spay_sas_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT spay_ordt.receipt_date, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xxitm.total_amount total_amount, xxitm.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xoldd.order_total total_amount, xoldd.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.tender_type';

    -----------------------------6---------------------------------
	-- Single Pay ORDT Summary Query
	--Commented for the Defect#40824
	/*
    C_SPAY_ORDT_SUM_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_spay_ordt_itm AS
         SELECT spay_ordt.receipt_date, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.tender_type';
	*/
    -- Queries for OD: CE Order Receipt Detail Discrepancy Summary Report - End
	
	--Added for the Defect#40824
	C_SPAY_ORDT_SUM_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_spay_ordt_itm AS
		insert into xxfin.xx_ce_spay_ordt_itm (RECEIPT_DATE,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT spay_ordt.receipt_date, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.tender_type';


	-----------------------------7---------------------------------
    -- Queries for OD: CE Order Receipt Detail Discrepancy Detail Report - Start
    -- POS SAS Detail Query
	--Commented for the Defect#40824
    /*
	C_POS_SAS_DET_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_pos_sas_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id = 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';
	*/
	--Added for the Defect#40824
	C_POS_SAS_DET_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_pos_sas_itm AS
		insert into xxfin.xx_ce_pos_sas_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id = 1025 /*Order Source = POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';

    -----------------------------8---------------------------------
	-- POS ORDT Detail Query
	--Commented for the Defect#40824
	/*
    C_POS_ORDT_DET_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_pos_ordt_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM(xxordt.payment_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm,
                xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id = 1025
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND xxordt.payment_number = NVL(xxitm.payment_number, xxordt.payment_number)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';
	*/
	
	--Added for the Defect#40824	
	C_POS_ORDT_DET_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_pos_ordt_itm AS
		insert into xxfin.xx_ce_pos_ordt_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM(xxordt.payment_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm,
                xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id = 1025 /*Order Source = POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND xxordt.payment_number = NVL(xxitm.payment_number, xxordt.payment_number)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';

    -----------------------------9---------------------------------
	-- AOPS SAS Detail Query
	--Commented for the Defect#40824
    /*
	C_AOPS_SAS_DET_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_aops_sas_itm AS
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';
	*/
		 
	--Added for the Defect#40824	 
	C_AOPS_SAS_DET_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_aops_sas_itm8 AS
		insert into xxfin.xx_ce_aops_sas_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT TRUNC(xxitm.receipt_date) receipt_date,
                xxitm.store_number,
                xxitm.tender_type,
                SUM (xxitm.total_amount) total_amount
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_sas$
         GROUP BY TRUNC(xxitm.receipt_date), xxitm.store_number, xxitm.tender_type';

    -----------------------------10---------------------------------
	-- AOPS ORDT Detail Query
	--Commented for the Defect#40824
	/*
    C_AOPS_ORDT_DET_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_aops_ordt_itm AS
         SELECT aops_ordt.receipt_date, aops_ordt.store_number, aops_ordt.tender_type, SUM (aops_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id <> 1025 
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
          WHERE xxitm.order_source_id <> 1025 
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.rowid = (SELECT MAX(rowid) FROM xx_om_legacy_dep_dtls WHERE transaction_number = xoldd.transaction_number)
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, (-1 * arra.amount_applied) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, ar_receivable_applications_all arra
          WHERE xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N'' --AND xxitm.tender_type = ''PAYPAL''
            AND xxitm.total_amount < 0
            AND arra.cash_receipt_id = xxitm.cash_receipt_id
            AND arra.attribute7 = xxitm.orig_sys_document_ref
            AND arra.display = ''Y''
            AND arra.status = ''ACTIVITY''
            $lc_where_ordt$) aops_ordt
         GROUP BY aops_ordt.receipt_date, aops_ordt.store_number, aops_ordt.tender_type';
	*/
		
	--Added for the Defect#40824	
	C_AOPS_ORDT_DET_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_aops_ordt_itm8 AS
		insert into xxfin.xx_ce_aops_ordt_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT aops_ordt.receipt_date, aops_ordt.store_number, aops_ordt.tender_type, SUM (aops_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N''
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.rowid = (SELECT MAX(rowid) FROM xx_om_legacy_dep_dtls WHERE transaction_number = xoldd.transaction_number)
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, (-1 * arra.amount_applied) total_amount, xxitm.header_id, NVL(xxitm.orig_sys_payment_ref, 0) orig_sys_payment_ref
           FROM xx_ce_ordt_sas_itm xxitm, ar_receivable_applications_all arra
          WHERE xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''N'' --AND xxitm.tender_type = ''PAYPAL''
            AND xxitm.total_amount < 0
            AND arra.cash_receipt_id = xxitm.cash_receipt_id
            AND arra.attribute7 = xxitm.orig_sys_document_ref
            AND arra.display = ''Y''
            AND arra.status = ''ACTIVITY''
            $lc_where_ordt$) aops_ordt
         GROUP BY aops_ordt.receipt_date, aops_ordt.store_number, aops_ordt.tender_type';

    -----------------------------11---------------------------------
	-- Single Pay SAS Detail Query
	--Commented for the Defect#40824
	/*
    C_SPAY_SAS_DET_SQL  CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_spay_sas_itm AS
         SELECT spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xxitm.total_amount total_amount, xxitm.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xoldd.order_total total_amount, xoldd.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type';
	*/
	
	--Added for the Defect#40824	
	C_SPAY_SAS_DET_SQL1  CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_spay_sas_itm8 AS
		insert into xxfin.xx_ce_spay_sas_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xxitm.total_amount total_amount, xxitm.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, xoldd.order_total total_amount, xoldd.orig_sys_document_ref
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_sas$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type';

    -----------------------------12---------------------------------
	-- Single Pay ORDT Detail Query
	--Commented for the Defect#40824
	/*
    C_SPAY_ORDT_DET_SQL CONSTANT VARCHAR2(32000):=
        'CREATE TABLE xxfin.xx_ce_spay_ordt_itm AS
         SELECT spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type';
	*/
		 
	--Added for the Defect#40824
	C_SPAY_ORDT_DET_SQL1 CONSTANT VARCHAR2(32000):=
        '
		--CREATE TABLE xxfin.xx_ce_spay_ordt_itm AS
		insert into xxfin.xx_ce_spay_ordt_itm (RECEIPT_DATE,STORE_NUMBER,TENDER_TYPE,TOTAL_AMOUNT)
         SELECT spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type, SUM (spay_ordt.total_amount) total_amount
           FROM
         (SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_ar_order_receipt_dtl xxordt
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xxordt.header_id = xxitm.header_id
            AND xxordt.od_payment_type = xxitm.credit_card_code
            AND NVL(xxordt.orig_sys_payment_ref, 0) = NVL(xxitm.orig_sys_payment_ref, NVL(xxordt.orig_sys_payment_ref, 0))
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$
          UNION
         SELECT TRUNC(xxitm.receipt_date) receipt_date, xxitm.store_number, xxitm.tender_type, DECODE(xxordt.payment_amount, 0, xxitm.total_amount, xxordt.payment_amount) total_amount, xxitm.header_id
           FROM xx_ce_ordt_sas_itm xxitm, xx_om_legacy_dep_dtls xoldd, xx_ar_order_receipt_dtl xxordt, xx_om_legacy_deposits xold
          WHERE 1 = 1 --AND xxitm.order_source_id <> 1025 /*Order Source <> POS*/
            AND xoldd.orig_sys_document_ref = xxitm.orig_sys_document_ref
            AND xold.transaction_number = xoldd.transaction_number
            AND xold.cash_receipt_id = xxordt.cash_receipt_id
            AND xoldd.transaction_number IN (SELECT transaction_number FROM xx_om_legacy_dep_dtls WHERE orig_sys_document_ref = xxitm.orig_sys_document_ref)
            AND NVL(xxitm.single_pay_ind, ''N'') = ''Y''
            $lc_where_ordt$) spay_ordt
         GROUP BY spay_ordt.receipt_date, spay_ordt.store_number, spay_ordt.tender_type';
    -- Queries for OD: CE Order Receipt Detail Discrepancy Detail Report - End


    -- Initialize detail report parameters
    PROCEDURE init_detail_params ( p_receipt_date_from     IN VARCHAR2,
                                   p_receipt_date_to       IN VARCHAR2,
                                   p_tender_type           IN VARCHAR2,
                                   p_store_number_from     IN VARCHAR2,
                                   p_store_number_to       IN VARCHAR2,
                                   p_min_header_id         IN NUMBER,
                                   p_max_header_id         IN NUMBER,
                                   p_org_id                IN NUMBER,
                                   p_status               OUT VARCHAR2
                                 )
    IS

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE init_detail_params');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Receipt Date From : ' || p_receipt_date_from);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Receipt Date To   : ' || p_receipt_date_to);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Tender Type       : ' || p_tender_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Store Number From : ' || p_store_number_from);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Store Number To   : ' || p_store_number_to);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Minimum Header ID : ' || p_min_header_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Maximum Header ID : ' || p_max_header_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Org ID            : ' || p_org_id);

        -- Considering that p_receipt_date_from and p_receipt_date_to always going to be NOT NULL
        -- Condition 1 - Only p_receipt_date_from and p_receipt_date_to parameters are passed
        IF (p_receipt_date_from IS NOT NULL AND p_receipt_date_to IS NOT NULL AND p_tender_type IS NULL AND p_store_number_from IS NULL AND p_store_number_to IS NULL) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 1');
            gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                 AND oeh.org_id = '||p_org_id||' ';

            gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1 ';

            gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1 ';

        -- Condition 2 - All parameters are passed
        ELSIF (p_tender_type IS NOT NULL AND p_store_number_from IS NOT NULL AND p_store_number_to IS NOT NULL) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 2');
            gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                 AND flv.meaning = '''||p_tender_type||'''
                                 AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_from||''' AND '''||p_store_number_to||'''
                                 AND oeh.org_id = '||p_org_id||' ';

            gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

            gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

        -- Condition 3 - p_receipt_date_from, p_receipt_date_to and p_tender_type parameters are passed
        ELSIF (p_tender_type IS NOT NULL AND p_store_number_from IS NULL AND p_store_number_to IS NULL) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 3');
            gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                 AND flv.meaning = '''||p_tender_type||'''
                                 AND oeh.org_id = '||p_org_id||' ';

            gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

            gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

        -- Condition 4 - p_receipt_date_from, p_receipt_date_to, p_store_number_from and p_store_number_to parameters are passed
        ELSIF (p_store_number_from IS NOT NULL AND p_store_number_to IS NOT NULL AND p_tender_type IS NULL) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 4');
            gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                 AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_from||''' AND '''||p_store_number_to||'''
                                 AND oeh.org_id = '||p_org_id||' ';

            gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

            gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                 AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

        -- Condition 5 - p_store_number_from or p_store_number_to parameters not passed
        ELSE

            -- Condition 5a - p_store_number_to not passed as parameter
            IF p_store_number_from IS NOT NULL AND p_store_number_to IS NULL THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 5a');
                IF p_tender_type IS NOT NULL THEN

                    gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                         AND flv.meaning = '''||p_tender_type||'''
                                         AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_from||''' AND '''||p_store_number_from||'''
                                         AND oeh.org_id = '||p_org_id||' ';

                    gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                    gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                ELSE

                    gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                         AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_from||''' AND '''||p_store_number_from||'''
                                         AND oeh.org_id = '||p_org_id||' ';

                    gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                    gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                END IF;

            -- Condition 5b - p_store_number_from not passed as parameter
            ELSIF p_store_number_from IS NULL AND p_store_number_to IS NOT NULL THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 5b');
                IF p_tender_type IS NOT NULL THEN

                    gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                         AND flv.meaning = '''||p_tender_type||'''
                                         AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_to||''' AND '''||p_store_number_to||'''
                                         AND oeh.org_id = '||p_org_id||' ';

                    gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                    gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                ELSE

                    gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                         AND SUBSTR(hrou.name, 1, 6) BETWEEN '''||p_store_number_to||''' AND '''||p_store_number_to||'''
                                         AND oeh.org_id = '||p_org_id||' ';

                    gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                    gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                         AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1';

                END IF;

            -- Condition 5c - Default - p_receipt_date_from and p_receipt_date_to parameters are passed
            ELSE

                FND_FILE.PUT_LINE(FND_FILE.LOG,'  Parameters derived based on Condition 5c');
                gc_where_itm    :=  'AND oehl.actual_shipment_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                     AND oehl.actual_shipment_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1
                                     AND oeh.org_id = '||p_org_id||' ';

                gc_where_sas    :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                     AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1 ';

                gc_where_ordt   :=  'AND xxitm.receipt_date >= TO_DATE('''||p_receipt_date_from||''', ''yyyy/mm/dd hh24:mi:ss'')
                                     AND xxitm.receipt_date < TO_DATE('''||p_receipt_date_to||''', ''yyyy/mm/dd hh24:mi:ss'') + 1 ';

            END IF;

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  GC_WHERE_ITM  : ' || gc_where_itm);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  GC_WHERE_SAS  : ' || gc_where_sas);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  GC_WHERE_ORDT : ' || gc_where_ordt);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE init_detail_params');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE init_detail_params : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE init_detail_params');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END init_detail_params;


    -- Logic for OD: CE Order Receipt Detail Discrepancy Summary Report - Start
    -- Generate POS data for report output
    PROCEDURE generated_pos_data_sum ( p_where_sas      IN VARCHAR2,
                                       p_where_ordt     IN VARCHAR2,
                                       p_status        OUT VARCHAR2
                                     )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
	lc_tbl_check_sas1    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
	lc_tbl_check_ordt1   VARCHAR2(30)    := NULL;
    lc_tbl_query_sas    VARCHAR2(4000)  := NULL;
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;
    lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;
	lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_pos_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_pos_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_POS_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_pos_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_pos_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_pos_sas_itm');						--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_pos_sas_itm';											--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_pos_sas_itm');	--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_pos_sas_itm';											--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_pos_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_POS_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_pos_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_pos_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_pos_ordt_itm');						--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_pos_ordt_itm';											--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_pos_ordt_itm');	--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_pos_ordt_itm';										--Added for the Defect#40824
        END IF;
		
		
        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(C_POS_SAS_SUM_SQL, '$lc_where_sas$', p_where_sas);			--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(C_POS_SAS_SUM_SQL1, '$lc_where_sas$', p_where_sas);			--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_POS_ORDT_SUM_SQL, '$lc_where_ordt$', p_where_ordt);		--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_POS_ORDT_SUM_SQL1, '$lc_where_ordt$', p_where_ordt);		--Added for the Defect#40824
		
		
        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating table xxfin.xx_ce_pos_sas_itm');						--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS   : ' || lc_tbl_query_sas);					--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_pos_sas_itm');		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1   : ' || lc_tbl_query_sas1);					--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_sas;		--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_sas1;		--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_pos_sas_itm_n1 on xxfin.xx_ce_pos_sas_itm table');		--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_pos_sas_itm_n1 ON xxfin.xx_ce_pos_sas_itm (receipt_date, tender_type)';	--Commented for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating table xxfin.xx_ce_pos_ordt_itm');							--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT  : ' || lc_tbl_query_ordt);						--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_pos_ordt_itm');		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1  : ' || lc_tbl_query_ordt1);						--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_ordt;		--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_ordt1;		--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_pos_ordt_itm_n1 on xxfin.xx_ce_pos_ordt_itm table');		--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_pos_ordt_itm_n1 ON xxfin.xx_ce_pos_ordt_itm (receipt_date, tender_type)';		--Commented for the Defect#40824

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating POS report data');
        p_pos_sql_summary   :=
            'SELECT TO_CHAR(pos.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    pos.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                      WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_pos_ordt_itm
                      WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                       WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_pos_ordt_itm
                       WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, tender_type FROM xx_ce_pos_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_pos_ordt_itm
                    ) pos
              WHERE 1 = 1
             ORDER BY 1, 2';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_POS_SQL_SUMMARY  : ' || p_pos_sql_summary);

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Calculating POS total discrepancy');
        p_pos_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                       WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_pos_ordt_itm
                       WHERE receipt_date = pos.receipt_date AND tender_type = pos.tender_type), 0)
                    )) POS_TOTAL_DISC
               FROM (SELECT receipt_date, tender_type FROM xx_ce_pos_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_pos_ordt_itm
                    ) pos
              WHERE 1 = 1';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_POS_TOTAL_DISC   : ' || p_pos_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_pos_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_pos_data_sum : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_pos_data_sum');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_pos_data_sum;


    -- Generate AOPS data for report output
    PROCEDURE generated_aops_data_sum ( p_where_sas      IN VARCHAR2,
                                        p_where_ordt     IN VARCHAR2,
                                        p_status        OUT VARCHAR2
                                      )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
    --lc_tbl_query_sas    VARCHAR2(4000)  := NULL;				--Commented for the Defect#40824
    --lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;				--Commented for the Defect#40824
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;				--Added for the Defect#40824
    lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;				--Added for the Defect#40824

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_aops_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_aops_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_AOPS_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_aops_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_aops_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_aops_sas_itm');						--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_aops_sas_itm';											--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_aops_sas_itm');	--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_aops_sas_itm';										--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_aops_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_AOPS_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_aops_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_aops_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_aops_ordt_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_aops_ordt_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_aops_ordt_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_aops_ordt_itm';											--Added for the Defect#40824
        END IF;
		

        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(C_AOPS_SAS_SUM_SQL, '$lc_where_sas$', p_where_sas);			--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(C_AOPS_SAS_SUM_SQL1, '$lc_where_sas$', p_where_sas);			--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_AOPS_ORDT_SUM_SQL, '$lc_where_ordt$', p_where_ordt);		--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_AOPS_ORDT_SUM_SQL1, '$lc_where_ordt$', p_where_ordt);		--Added for the Defect#40824
		
		
        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating table xxfin.xx_ce_aops_sas_itm');						--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  LC_TBL_QUERY_SAS    : ' || lc_tbl_query_sas);					--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_aops_sas_itm');	--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG, '  LC_TBL_QUERY_SAS1    : ' || lc_tbl_query_sas1);					--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_sas;			--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_sas1;			--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_aops_sas_itm_n1 on xxfin.xx_ce_aops_sas_itm table');		--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_aops_sas_itm_n1 ON xxfin.xx_ce_aops_sas_itm (receipt_date, tender_type)';		--Commented for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating table xxfin.xx_ce_aops_ordt_itm');						--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  LC_TBL_QUERY_ORDT   : ' || lc_tbl_query_ordt);						--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_aops_ordt_itm');		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG, '  LC_TBL_QUERY_ORDT1   : ' || lc_tbl_query_ordt1);						--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_ordt;			--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_ordt1;			--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_aops_ordt_itm_n1 on xxfin.xx_ce_aops_ordt_itm table');			--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_aops_ordt_itm_n1 ON xxfin.xx_ce_aops_ordt_itm (receipt_date, tender_type)';		--Commented for the Defect#40824

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating AOPS report data');
        p_aops_sql_summary   :=
            'SELECT TO_CHAR(aops.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    aops.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                      WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_aops_ordt_itm
                      WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                       WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0) -
                     NVL((SELECT total_amount FROM xx_ce_aops_ordt_itm
                       WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, tender_type FROM xx_ce_aops_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_aops_ordt_itm
                    ) aops
              WHERE 1 = 1
             ORDER BY 1, 2';
        FND_FILE.PUT_LINE(FND_FILE.LOG, '  P_AOPS_SQL_SUMMARY  : ' || p_aops_sql_summary);

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Calculating AOPS total discrepancy');
        p_aops_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                       WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_aops_ordt_itm
                       WHERE receipt_date = aops.receipt_date AND tender_type = aops.tender_type), 0)
                    )) AOPS_TOTAL_DISC
               FROM (SELECT receipt_date, tender_type FROM xx_ce_aops_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_aops_ordt_itm
                    ) aops
              WHERE 1 = 1';
        FND_FILE.PUT_LINE(FND_FILE.LOG, '  P_AOPS_TOTAL_DISC   : ' || p_aops_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_aops_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_aops_data_sum : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_aops_data_sum');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_aops_data_sum;


    -- Generate Single Pay data for report output
    PROCEDURE generated_spay_data_sum ( p_where_sas      IN VARCHAR2,
                                        p_where_ordt     IN VARCHAR2,
                                        p_status        OUT VARCHAR2
                                      )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
    --lc_tbl_query_sas    VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
    --lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;		--Added for the Defect#40824
    lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;		--Added for the Defect#40824

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_spay_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_spay_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_SPAY_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_spay_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_spay_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_spay_sas_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_spay_sas_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '   Truncating the data from the table xxfin.xx_ce_spay_sas_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_spay_sas_itm';											--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_spay_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_SPAY_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_spay_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '  xx_ce_spay_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Droping table xxfin.xx_ce_spay_ordt_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_spay_ordt_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE(FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_spay_ordt_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_spay_ordt_itm';											--Added for the Defect#40824
        END IF;

		
        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(C_SPAY_SAS_SUM_SQL, '$lc_where_sas$', p_where_sas);			--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(C_SPAY_SAS_SUM_SQL1, '$lc_where_sas$', p_where_sas);			--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_SPAY_ORDT_SUM_SQL, '$lc_where_ordt$', p_where_ordt);		--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_SPAY_ORDT_SUM_SQL1, '$lc_where_ordt$', p_where_ordt);		--Added for the Defect#40824
		
		--FND_FILE.PUT_LINE(FND_FILE.LOG,'  Creating table xxfin.xx_ce_spay_sas_itm');						--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS    : ' || lc_tbl_query_sas);					--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  Inserting the data into the table xxfin.xx_ce_spay_sas_itm');		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1    : ' || lc_tbl_query_sas1);					--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_sas;		--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_sas1;		--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_spay_sas_itm_n1 on xxfin.xx_ce_spay_sas_itm table');			--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_spay_sas_itm_n1 ON xxfin.xx_ce_spay_sas_itm (receipt_date, tender_type)';			--Commented for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating table xxfin.xx_ce_spay_ordt_itm');					--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT   : ' || lc_tbl_query_ordt);					--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_spay_ordt_itm');	--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1   : ' || lc_tbl_query_ordt1);					--Added for the Defect#40824
        --EXECUTE IMMEDIATE lc_tbl_query_ordt;		--Commented for the Defect#40824
		EXECUTE IMMEDIATE lc_tbl_query_ordt1;		--Added for the Defect#40824
		
		commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating index xxfin.xx_ce_spay_ordt_itm_n1 on xxfin.xx_ce_spay_ordt_itm table');			--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_spay_ordt_itm_n1 ON xxfin.xx_ce_spay_ordt_itm (receipt_date, tender_type)';		--Commented for the Defect#40824

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Creating SPAY report data');
        p_spay_sql_summary   :=
            'SELECT TO_CHAR(spay.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    spay.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                      WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_spay_ordt_itm
                      WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                       WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0) -
                     NVL((SELECT total_amount FROM xx_ce_spay_ordt_itm
                       WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, tender_type FROM xx_ce_spay_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_spay_ordt_itm
                    ) spay
              WHERE 1 = 1
             ORDER BY 1, 2';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_SPAY_SQL_SUMMARY  : ' || p_spay_sql_summary);

        FND_FILE.PUT_LINE(FND_FILE.LOG, '  Calculating AOPS total discrepancy');
        p_spay_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                       WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_spay_ordt_itm
                       WHERE receipt_date = spay.receipt_date AND tender_type = spay.tender_type), 0)
                    )) SPAY_TOTAL_DISC
               FROM (SELECT receipt_date, tender_type FROM xx_ce_spay_sas_itm
                      UNION
                     SELECT receipt_date, tender_type FROM xx_ce_spay_ordt_itm
                    ) spay
              WHERE 1 = 1';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_SPAY_TOTAL_DISC   : ' || p_spay_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_spay_data_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_spay_data_sum : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_spay_data_sum');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_spay_data_sum;


    -- Before Report Trigger logic
    -- OD: CE Order Receipt Detail Discrepancy Summary Report (XXCEORDTSASDISC_SUMMARY)
    FUNCTION before_report_sum
    RETURN BOOLEAN IS

        ln_org_id       NUMBER;
        ln_min_hdr_id   NUMBER;
        ln_max_hdr_id   NUMBER;
        lc_where_sas    VARCHAR2(4000);
        lc_where_ordt   VARCHAR2(4000);

        lc_init_status  VARCHAR2(15);
        lc_pos_status   VARCHAR2(15);
        lc_aops_status  VARCHAR2(15);
        lc_spay_status  VARCHAR2(15);

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of FUNCTION before_report_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetched value of Org ID : ' || gn_org_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Min Header Id - ' || gn_min_hdr_id || ' Max Header Id - ' || gn_max_hdr_id);

        -- Initializing report parameters
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE init_detail_params');
        init_detail_params ( p_receipt_date_from    => p_receipt_date_from,
                             p_receipt_date_to      => p_receipt_date_to,
                             p_tender_type          => p_tender_type,
                             p_store_number_from    => p_store_number_from,
                             p_store_number_to      => p_store_number_to,
                             p_min_header_id        => gn_min_hdr_id,
                             p_max_header_id        => gn_max_hdr_id,
                             p_org_id               => gn_org_id,
                             p_status               => lc_init_status
                            );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure init_detail_params return status : ' || lc_init_status);

        -- Generating POS data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_pos_data_sum');
        generated_pos_data_sum ( p_where_sas      =>    gc_where_sas,
                                 p_where_ordt     =>    gc_where_ordt,
                                 p_status         =>    lc_pos_status
                               );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_pos_data_sum return status : ' || lc_pos_status);

        -- Generating AOPS data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_aops_data_sum');
        generated_aops_data_sum ( p_where_sas      =>    gc_where_sas,
                                  p_where_ordt     =>    gc_where_ordt,
                                  p_status         =>    lc_aops_status
                                );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_aops_data_sum return status : ' || lc_aops_status);

        -- Generating Single Pay data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_spay_data_sum');
        generated_spay_data_sum ( p_where_sas      =>    gc_where_sas,
                                  p_where_ordt     =>    gc_where_ordt,
                                  p_status         =>    lc_spay_status
                                );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_spay_data_sum return status : ' || lc_spay_status);

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION before_report_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        RETURN (TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at FUNCTION before_report_sum : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION before_report_sum');
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            RETURN (FALSE);

    END before_report_sum;


    -- After Report Trigger logic
    -- OD: CE Order Receipt Detail Discrepancy Summary Report (XXCEORDTSASDISC_SUMMARY)
    FUNCTION after_report_sum
    RETURN BOOLEAN IS

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of FUNCTION after_report_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'No logic is written in after_report_sum function');

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION after_report_sum');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        RETURN (TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at FUNCTION after_report_sum : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION after_report_sum');
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            RETURN (FALSE);

    END after_report_sum;
    -- Logic for OD: CE Order Receipt Detail Discrepancy Summary Report - End


    -- Logic for OD: CE Order Receipt Detail Discrepancy Detail Report - Start
    -- Generate POS data for report output
    PROCEDURE generated_pos_data ( p_where_sas      IN VARCHAR2,
                                   p_where_ordt     IN VARCHAR2,
                                   p_status        OUT VARCHAR2
                                 )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
    --lc_tbl_query_sas    VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
    --lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
	
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;		--Added for the Defect#40824
    lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;		--Added for the Defect#40824
	
    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_pos_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_pos_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_POS_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_pos_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_pos_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_pos_sas_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_pos_sas_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_pos_sas_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_pos_sas_itm';												--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_pos_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_POS_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_pos_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_pos_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_pos_ordt_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_pos_ordt_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_pos_ordt_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_pos_ordt_itm';											--Added for the Defect#40824
        END IF;
		
		EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_pos_sas_itm';
		

        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(REPLACE(C_POS_SAS_DET_SQL, '$lc_where_sas$', p_where_sas), 'acra.receipt_date', 'oeh.ordered_date');	--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(REPLACE(C_POS_SAS_DET_SQL1, '$lc_where_sas$', p_where_sas), 'acra.receipt_date', 'oeh.ordered_date');	--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_POS_ORDT_DET_SQL, '$lc_where_ordt$', p_where_ordt);				--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_POS_ORDT_DET_SQL1, '$lc_where_ordt$', p_where_ordt);				--Added for the Defect#40824
		
		

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_pos_sas_itm');						--Commented for the Defect#40824
		--FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS    : ' || lc_tbl_query_sas);						--Added for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_pos_sas_itm');	--Added for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1    : ' || lc_tbl_query_sas1);					--Added for the Defect#40824
        
            --EXECUTE IMMEDIATE lc_tbl_query_sas;					--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_sas1;					--Added for the Defect#40824
			
			commit;													--Added for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_pos_sas_itm_n1 on xxfin.xx_ce_pos_sas_itm table');					   --Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_pos_sas_itm_n1 ON xxfin.xx_ce_pos_sas_itm (receipt_date, store_number, tender_type)';	   --Commented for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_pos_ordt_itm');					--Commented for the Defect#40824
		--FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT    : ' || lc_tbl_query_ordt);						--Added for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_pos_ordt_itm');	--Added for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1    : ' || lc_tbl_query_ordt1);						--Added for the Defect#40824
            --EXECUTE IMMEDIATE lc_tbl_query_ordt;			--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_ordt1;			--Added for the Defect#40824
			
			commit;													--Added for the Defect#40824			

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_pos_ordt_itm_n1 on xxfin.xx_ce_pos_ordt_itm table');					--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_pos_ordt_itm_n1 ON xxfin.xx_ce_pos_ordt_itm (receipt_date, store_number, tender_type)';	--Commented for the Defect#40824

        p_pos_sql_detail   :=
            'SELECT TO_CHAR(pos.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    pos.store_number,
                    pos.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                      WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_pos_ordt_itm
                      WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                       WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_pos_ordt_itm
                       WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_pos_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_pos_ordt_itm
                    ) pos
              WHERE 1 = 1
             ORDER BY 1, 2, 3';

        p_pos_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_pos_sas_itm
                       WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_pos_ordt_itm
                       WHERE receipt_date = pos.receipt_date AND store_number = pos.store_number AND tender_type = pos.tender_type), 0)
                    )) POS_TOTAL_DISC
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_pos_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_pos_ordt_itm
                    ) pos
              WHERE 1 = 1';
			  
		--FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS  : ' || lc_tbl_query_sas);		--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT : ' || lc_tbl_query_ordt);		--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1  : ' || lc_tbl_query_sas1);		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1 : ' || lc_tbl_query_ordt1);		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_POS_SQL_DETAIL  : ' || p_pos_sql_detail);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_POS_TOTAL_DISC  : ' || p_pos_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_pos_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_pos_data : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_pos_data');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_pos_data;


    -- Generate AOPS data for report output
    PROCEDURE generated_aops_data ( p_where_sas      IN VARCHAR2,
                                    p_where_ordt     IN VARCHAR2,
                                    p_status        OUT VARCHAR2
                                  )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
    --lc_tbl_query_sas    VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
    --lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
	
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;		--Added for the Defect#40824
    lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;		--Added for the Defect#40824

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_aops_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_aops_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_AOPS_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_aops_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_aops_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_aops_sas_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_aops_sas_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_aops_sas_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_aops_sas_itm';											--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_aops_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_AOPS_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_aops_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_aops_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_aops_ordt_itm');						--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_aops_ordt_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_aops_ordt_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_aops_ordt_itm';											--Added for the Defect#40824
        END IF;
		

        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(C_AOPS_SAS_DET_SQL, '$lc_where_sas$', p_where_sas);			--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(C_AOPS_SAS_DET_SQL1, '$lc_where_sas$', p_where_sas);			--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_AOPS_ORDT_DET_SQL, '$lc_where_ordt$', p_where_ordt);		--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_AOPS_ORDT_DET_SQL1, '$lc_where_ordt$', p_where_ordt);		--Added for the Defect#40824

		
        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_aops_sas_itm');					--Commented for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_aops_sas_itm');	--Added for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1    : ' || lc_tbl_query_sas1);					--Added for the Defect#40824
            --EXECUTE IMMEDIATE lc_tbl_query_sas;		--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_sas1;		--Added for the Defect#40824
			
			commit;			--Added for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_aops_sas_itm_n1 on xxfin.xx_ce_aops_sas_itm table');					--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_aops_sas_itm_n1 ON xxfin.xx_ce_aops_sas_itm (receipt_date, store_number, tender_type)';	--Commented for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_aops_ordt_itm');					--Commented for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_aops_ordt_itm');	--Added for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1    : ' || lc_tbl_query_ordt1);					--Added for the Defect#40824
            --EXECUTE IMMEDIATE lc_tbl_query_ordt;	--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_ordt1;	--Added for the Defect#40824
			
			commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_aops_ordt_itm_n1 on xxfin.xx_ce_aops_ordt_itm table');					--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_aops_ordt_itm_n1 ON xxfin.xx_ce_aops_ordt_itm (receipt_date, store_number, tender_type)'; --Commented for the Defect#40824

        p_aops_sql_detail   :=
            'SELECT TO_CHAR(aops.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    aops.store_number,
                    aops.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                      WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_aops_ordt_itm
                      WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                       WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0) -
                     NVL((SELECT total_amount FROM xx_ce_aops_ordt_itm
                       WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_aops_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_aops_ordt_itm
                    ) aops
              WHERE 1 = 1
             ORDER BY 1, 2, 3';

        p_aops_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_aops_sas_itm
                       WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_aops_ordt_itm
                       WHERE receipt_date = aops.receipt_date AND store_number = aops.store_number AND tender_type = aops.tender_type), 0)
                    )) AOPS_TOTAL_DISC
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_aops_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_aops_ordt_itm
                    ) aops
              WHERE 1 = 1';

        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS   : ' || lc_tbl_query_sas);	--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT  : ' || lc_tbl_query_ordt);	--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1   : ' || lc_tbl_query_sas1);		--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1  : ' || lc_tbl_query_ordt1);	--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_AOPS_SQL_DETAIL  : ' || p_aops_sql_detail);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_AOPS_TOTAL_DISC  : ' || p_aops_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_aops_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_aops_data : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_aops_data');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_aops_data;


    -- Generate Single Pay data for report output
    PROCEDURE generated_spay_data ( p_where_sas      IN VARCHAR2,
                                    p_where_ordt     IN VARCHAR2,
                                    p_status        OUT VARCHAR2
                                  )
    IS

    lc_tbl_check_sas    VARCHAR2(30)    := NULL;
    lc_tbl_check_ordt   VARCHAR2(30)    := NULL;
    --lc_tbl_query_sas    VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
    --lc_tbl_query_ordt   VARCHAR2(4000)  := NULL;		--Commented for the Defect#40824
	
	lc_tbl_query_sas1    VARCHAR2(4000)  := NULL;		--Added for the Defect#40824
    lc_tbl_query_ordt1   VARCHAR2(4000)  := NULL;		--Added for the Defect#40824

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Start of PROCEDURE generated_spay_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_spay_sas_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_sas
              FROM dba_tables
             WHERE table_name = 'XX_CE_SPAY_SAS_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_spay_sas_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_sas := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_spay_sas_itm table does not exist');
        END;

        IF lc_tbl_check_sas IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_spay_sas_itm');							--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_spay_sas_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_spay_sas_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_spay_sas_itm';											--Added for the Defect#40824
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  Checking for xx_ce_spay_ordt_itm table');
        BEGIN

            SELECT table_name
              INTO lc_tbl_check_ordt
              FROM dba_tables
             WHERE table_name = 'XX_CE_SPAY_ORDT_ITM'
               AND OWNER = 'XXFIN';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_spay_ordt_itm table does not exist');

            WHEN OTHERS THEN
                lc_tbl_check_ordt := NULL;
                FND_FILE.PUT_LINE (FND_FILE.LOG, '  xx_ce_spay_ordt_itm table does not exist');
        END;

        IF lc_tbl_check_ordt IS NOT NULL THEN
            --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Droping table xxfin.xx_ce_spay_ordt_itm');						--Commented for the Defect#40824
            --EXECUTE IMMEDIATE 'DROP TABLE xxfin.xx_ce_spay_ordt_itm';												--Commented for the Defect#40824
			FND_FILE.PUT_LINE (FND_FILE.LOG, '  Truncating the data from the table xxfin.xx_ce_spay_ordt_itm');		--Added for the Defect#40824
			EXECUTE IMMEDIATE 'truncate table xxfin.xx_ce_spay_ordt_itm';											--Added for the Defect#40824
        END IF;	
		
		
        -- Appendibg where clause to main query
        --lc_tbl_query_sas  := REPLACE(C_SPAY_SAS_DET_SQL, '$lc_where_sas$', p_where_sas);				--Commented for the Defect#40824
		lc_tbl_query_sas1  := REPLACE(C_SPAY_SAS_DET_SQL1, '$lc_where_sas$', p_where_sas);				--Added for the Defect#40824
        --lc_tbl_query_ordt := REPLACE(C_SPAY_ORDT_DET_SQL, '$lc_where_ordt$', p_where_ordt);			--Commented for the Defect#40824
		lc_tbl_query_ordt1 := REPLACE(C_SPAY_ORDT_DET_SQL1, '$lc_where_ordt$', p_where_ordt);			--Added for the Defect#40824
		
		
		
        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_spay_sas_itm');						--Commented for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_spay_sas_itm');		--Added for the Defect#40824		
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1    : ' || lc_tbl_query_sas1);	
            --EXECUTE IMMEDIATE lc_tbl_query_sas;		--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_sas1;		--Added for the Defect#40824
			
			commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_spay_sas_itm_n1 on xxfin.xx_ce_spay_sas_itm table');						--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_spay_sas_itm_n1 ON xxfin.xx_ce_spay_sas_itm (receipt_date, store_number, tender_type)';		--Commented for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating table xxfin.xx_ce_spay_ordt_itm');						--Commented for the Defect#40824
		FND_FILE.PUT_LINE (FND_FILE.LOG, '  Inserting the data into the table xxfin.xx_ce_spay_ordt_itm');		--Added for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1    : ' || lc_tbl_query_ordt1);	
            --EXECUTE IMMEDIATE lc_tbl_query_ordt;		--Commented for the Defect#40824
			EXECUTE IMMEDIATE lc_tbl_query_ordt1;		--Added for the Defect#40824
			
			commit;		--Added for the Defect#40824

        --FND_FILE.PUT_LINE (FND_FILE.LOG, '  Creating index xxfin.xx_ce_spay_ordt_itm_n1 on xxfin.xx_ce_spay_ordt_itm table');						--Commented for the Defect#40824
        --EXECUTE IMMEDIATE 'CREATE INDEX xxfin.xx_ce_spay_ordt_itm_n1 ON xxfin.xx_ce_spay_ordt_itm (receipt_date, store_number, tender_type)';		--Commented for the Defect#40824

        p_spay_sql_detail   :=
            'SELECT TO_CHAR(spay.receipt_date, ''DD-MON-YYYY'') RECEIPT_DATE,
                    spay.store_number,
                    spay.tender_type,
                    NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                      WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0) SAS_TOTAL,
                    NVL((SELECT total_amount FROM xx_ce_spay_ordt_itm
                      WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0) ORDT_TOTAL,
                    (NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                       WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0) -
                     NVL((SELECT total_amount FROM xx_ce_spay_ordt_itm
                       WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0)
                    ) DISCREPANCY
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_spay_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_spay_ordt_itm
                    ) spay
              WHERE 1 = 1
             ORDER BY 1, 2, 3';

        p_spay_total_disc   :=
            'SELECT SUM((NVL((SELECT total_amount FROM xx_ce_spay_sas_itm
                       WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0) -
                     NVL ((SELECT total_amount FROM xx_ce_spay_ordt_itm
                       WHERE receipt_date = spay.receipt_date AND store_number = spay.store_number AND tender_type = spay.tender_type), 0)
                    )) SPAY_TOTAL_DISC
               FROM (SELECT receipt_date, store_number, tender_type FROM xx_ce_spay_sas_itm
                      UNION
                     SELECT receipt_date, store_number, tender_type FROM xx_ce_spay_ordt_itm
                    ) spay
              WHERE 1 = 1';

		--FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS   : ' || lc_tbl_query_sas);		--Commented for the Defect#40824
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT  : ' || lc_tbl_query_ordt);		--Commented for the Defect#40824
		FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_SAS1   : ' || lc_tbl_query_sas1);			--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  LC_TBL_QUERY_ORDT1  : ' || lc_tbl_query_ordt1);			--Added for the Defect#40824
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_SPAY_SQL_DETAIL  : ' || p_spay_sql_detail);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  P_SPAY_TOTAL_DISC  : ' || p_spay_total_disc);

        p_status    :=  'SUCCESS';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_spay_data');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    EXCEPTION
        WHEN OTHERS THEN
            p_status    :=  'FAILURE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error at PROCEDURE generated_spay_data : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  End of PROCEDURE generated_spay_data');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');

    END generated_spay_data;


    -- Before Report Trigger logic
    -- OD: CE Order Receipt Detail Discrepancy Detail Report (XXCEORDTSASDISC)
    FUNCTION before_report_det
    RETURN BOOLEAN IS

        ln_org_id       NUMBER;
        ln_min_hdr_id   NUMBER;
        ln_max_hdr_id   NUMBER;
        lc_where_sas    VARCHAR2(4000);
        lc_where_ordt   VARCHAR2(4000);

        lc_init_status  VARCHAR2(15);
        lc_pos_status   VARCHAR2(15);
        lc_aops_status  VARCHAR2(15);
        lc_spay_status  VARCHAR2(15);

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of FUNCTION before_report_det');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetched value of Org ID : ' || gn_org_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Min Header Id - ' || gn_min_hdr_id || ' Max Header Id - ' || gn_max_hdr_id);

        -- Initializing report parameters
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE init_detail_params');
        init_detail_params ( p_receipt_date_from    => p_receipt_date_from,
                             p_receipt_date_to      => p_receipt_date_to,
                             p_tender_type          => p_tender_type,
                             p_store_number_from    => p_store_number_from,
                             p_store_number_to      => p_store_number_to,
                             p_min_header_id        => gn_min_hdr_id,
                             p_max_header_id        => gn_max_hdr_id,
                             p_org_id               => gn_org_id,
                             p_status               => lc_init_status
                            );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure init_detail_params return status : ' || lc_init_status);

        -- Generating POS data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_pos_data');
        generated_pos_data ( p_where_sas      =>    gc_where_sas,
                             p_where_ordt     =>    gc_where_ordt,
                             p_status         =>    lc_pos_status
                           );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_pos_data return status : ' || lc_pos_status);

        -- Generating AOPS data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_aops_data');
        generated_aops_data ( p_where_sas      =>    gc_where_sas,
                              p_where_ordt     =>    gc_where_ordt,
                              p_status         =>    lc_aops_status
                            );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_aops_data return status : ' || lc_aops_status);

        -- Generating Single Pay data
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE generated_spay_data');
        generated_spay_data ( p_where_sas      =>    gc_where_sas,
                              p_where_ordt     =>    gc_where_ordt,
                              p_status         =>    lc_spay_status
                            );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure generated_spay_data return status : ' || lc_spay_status);

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION before_report_det');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        RETURN (TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at FUNCTION before_report_det : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION before_report_det');
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            RETURN (FALSE);

    END before_report_det;


    -- After Report Trigger logic
    -- OD: CE Order Receipt Detail Discrepancy Detail Report (XXCEORDTSASDISC)
    FUNCTION after_report_det
    RETURN BOOLEAN IS

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of FUNCTION after_report_det');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'No logic is written in after_report_det function');

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION after_report_det');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        RETURN (TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at FUNCTION after_report_det : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'End of FUNCTION after_report_det');
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            RETURN (FALSE);

    END after_report_det;
    -- Logic for OD: CE Order Receipt Detail Discrepancy Detail Report - End


    -- Submit child request to prepare master data for report
    -- OD: CE Order Receipt Detail Discrepancy Report - Child (XXCEORDTSASDISC_CHILD)
    PROCEDURE submit_child_prog   ( x_err_buff      OUT NOCOPY VARCHAR2,
                                    x_ret_code      OUT NOCOPY VARCHAR2,
                                    p_receipt_date_from     IN VARCHAR2,
                                    p_receipt_date_to       IN VARCHAR2,
                                    p_tender_type           IN VARCHAR2,
                                    p_store_number_from     IN VARCHAR2,
                                    p_store_number_to       IN VARCHAR2,
                                    p_min_header_id         IN NUMBER,
                                    p_max_header_id         IN NUMBER,
                                    p_thread_number         IN NUMBER,
                                    p_sas_ordt              IN VARCHAR2
                                  )
    IS

    ln_processed_rec     NUMBER(15)     := 0;
    ln_created_by        NUMBER(15)     := 0;
    ln_parent_id         NUMBER(15)     := 0;
    ln_child_id          NUMBER(15)     := 0;
    lc_itm_tbl_query     VARCHAR2(4000) := NULL;
    lc_init_status       VARCHAR2(15)   := NULL;

    BEGIN

        gn_org_id       := FND_GLOBAL.org_id;
        ln_created_by   := FND_GLOBAL.user_id;
        ln_child_id     := FND_GLOBAL.conc_request_id;

        SELECT parent_request_id
          INTO ln_parent_id
          FROM fnd_concurrent_requests
         WHERE request_id = ln_child_id;

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Program Parameters');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date From : ' || p_receipt_date_from);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date To   : ' || p_receipt_date_to);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Tender Type       : ' || p_tender_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Store Number From : ' || p_store_number_from);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Store Number To   : ' || p_store_number_to);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Minimum Header ID : ' || p_min_header_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Maximum Header ID : ' || p_max_header_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Thread Number     : ' || p_thread_number);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'SAS or ORDT       : ' || p_sas_ordt);
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name       : OD: CE Order Receipt Detail Discrepancy Report - Child');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Date       : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID        : ' || ln_child_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Parent Request ID : ' || ln_parent_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Program Parameters');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Receipt Date From : ' || p_receipt_date_from);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Receipt Date To   : ' || p_receipt_date_to);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Tender Type       : ' || p_tender_type);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Store Number From : ' || p_store_number_from);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Store Number To   : ' || p_store_number_to);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Minimum Header ID : ' || p_min_header_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Maximum Header ID : ' || p_max_header_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Thread Number     : ' || p_thread_number);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SAS or ORDT       : ' || p_sas_ordt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

        BEGIN

            -- Initializing report parameters
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling PROCEDURE init_detail_params');
            init_detail_params ( p_receipt_date_from    => p_receipt_date_from,
                                 p_receipt_date_to      => p_receipt_date_to,
                                 p_tender_type          => p_tender_type,
                                 p_store_number_from    => p_store_number_from,
                                 p_store_number_to      => p_store_number_to,
                                 p_min_header_id        => p_min_header_id,
                                 p_max_header_id        => p_max_header_id,
                                 p_org_id               => gn_org_id,
                                 p_status               => lc_init_status
                                );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure init_detail_params return status : ' || lc_init_status);

            lc_itm_tbl_query := REPLACE(C_SAS_ORDT_ITM_SQL, '$lc_where_itm$', gc_where_itm);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'LC_ITM_TBL_QUERY  : ' || lc_itm_tbl_query);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inserting data into xxfin.xx_ce_ordt_sas_itm table');
            EXECUTE IMMEDIATE lc_itm_tbl_query USING ln_created_by, ln_parent_id, ln_child_id, p_thread_number, p_min_header_id, p_max_header_id;

            ln_processed_rec := SQL%ROWCOUNT;

            COMMIT;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records inserted in xxfin.xx_ce_ordt_sas_itm table : ' || ln_processed_rec);

        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting data in xxfin.xx_ce_ordt_sas_itm table : ' || SQLERRM);
                FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        END;

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at PROCEDURE submit_child_prog : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

    END submit_child_prog;


    -- Submit wrapper program for generating excel output
    -- OD: CE Order Receipt Detail Discrepancy Report - Excel (XXCEORDTSASDISC_EXCEL)
    PROCEDURE submit_wrapper_prog ( x_err_buff      OUT NOCOPY VARCHAR2,
                                    X_Ret_Code      Out Nocopy Varchar2,
                                    P_Report_Mode           In Varchar2,
                                    P_Receipt_Date_From     In Varchar2,
                                     p_receipt_date_to       IN VARCHAR2,
                                   p_tender_type           IN VARCHAR2,
                                   P_Store_Number_From     In Varchar2,
                                    P_Store_Number_To       In Varchar2,
                                    p_thread_count          IN NUMBER
                                  )
    IS

    CURSOR c_split_headers (p_thread_count      IN NUMBER,
                            p_min_header_id     IN NUMBER,
                            p_max_header_id     IN NUMBER
                           )
    IS
    SELECT MIN(header_id) min_header_id,
           MAX(header_id) max_header_id,
           thread_number
      FROM (SELECT header_id, NTILE(p_thread_count) OVER (ORDER BY header_id) AS thread_number
              FROM (SELECT /*+ PARALLEL(oeh,8) */ oeh.header_id
                      FROM oe_order_headers_all oeh
                     WHERE oeh.header_id BETWEEN p_min_header_id and p_max_header_id)
           )
    GROUP BY thread_number
    ORDER BY thread_number;

    ln_request_id        NUMBER(15);
    lc_status_code       VARCHAR2(10);
    lc_phase             VARCHAR2(50);
    lc_status            VARCHAR2(50);
    lc_devphase          VARCHAR2(50);
    lc_devstatus         VARCHAR2(50);
    lc_message           VARCHAR2(50);
    lb_layout            BOOLEAN;
    lb_req_status        BOOLEAN;
    lb_print_option      BOOLEAN;

    ln_thread_count      NUMBER;
    ln_date_range        NUMBER;

    lc_init_status       VARCHAR2(15);
    lc_child_status      VARCHAR2(50) := 'RUNNING';
    lc_req_data          VARCHAR2(10) := NULL;
    ln_counter           NUMBER := 0;
    ln_err_temp          NUMBER := 0;
    ln_war_temp          NUMBER := 0;
    ln_nor_temp          NUMBER := 0;

    BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Report Parameters');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Report Mode       : ' || p_report_mode);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date From : ' || p_receipt_date_from);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date To   : ' || p_receipt_date_to);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Tender Type       : ' || p_tender_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Store Number From : ' || p_store_number_from);
        Fnd_File.Put_Line(Fnd_File.Log,'Store Number To   : ' || P_Store_Number_To);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Thread Count      : ' || p_thread_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

        lc_req_data := FND_CONC_GLOBAL.request_data;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'FND_CONC_GLOBAL.request_data : ' || lc_req_data);

        IF (lc_req_data IS NOT NULL) THEN
            BEGIN
                FOR ln_counter IN (SELECT status_code FROM fnd_concurrent_requests
                                    WHERE parent_request_id = FND_PROFILE.value('CONC_REQUEST_ID') -- FND_GLOBAL.conc_request_id
                                      AND status_code IN ('E','G','C'))
                LOOP
                    IF ln_counter.status_code = 'E' THEN
                        ln_err_temp := 1;
                        lc_child_status := 'COMPLETED';
                    ELSIF ln_counter.status_code = 'G' THEN
                        ln_war_temp := 1;
                        lc_child_status := 'COMPLETED';
                    ELSIF ln_counter.status_code = 'C' THEN
                        ln_nor_temp := 1;
                        lc_child_status := 'COMPLETED';
                    END IF;
                END LOOP;

            END;

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Request Status : ' || lc_child_status);
        IF lc_child_status <> 'COMPLETED' THEN

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name       : OD: CE Order Receipt Detail Discrepancy Report - Excel');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Date       : ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID        : ' || FND_PROFILE.value('CONC_REQUEST_ID'));
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Parameters');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Mode       : ' || p_report_mode);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Receipt Date From : ' || p_receipt_date_from);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Receipt Date To   : ' || p_receipt_date_to);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Tender Type       : ' || p_tender_type);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Store Number From : ' || p_store_number_from);
            Fnd_File.Put_Line(Fnd_File.Output,'Store Number To   : ' || P_Store_Number_To);
   --         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Thread Count      : ' || p_thread_count);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

            gn_org_id   :=  FND_PROFILE.value('ORG_ID');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetched value of Org ID : ' || gn_org_id);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching Min and Max Header Id');
            SELECT /*+ PARALLEL(xxordt,8) full(xxordt) */ MIN(xxordt.header_id), MAX(xxordt.header_id)
              INTO gn_min_hdr_id, gn_max_hdr_id
              FROM xx_ar_order_receipt_dtl xxordt
             WHERE xxordt.receipt_date + 0 >= TO_DATE(p_receipt_date_from, 'yyyy/mm/dd hh24:mi:ss')
               AND xxordt.receipt_date + 0 < TO_DATE(p_receipt_date_to, 'yyyy/mm/dd hh24:mi:ss') + 1
               AND xxordt.store_number BETWEEN NVL(p_store_number_from, '000001') AND NVL(p_store_number_to, '999999')
               AND xxordt.org_id = gn_org_id;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Min Header Id - ' || gn_min_hdr_id || '   Max Header Id - ' || gn_max_hdr_id);

            BEGIN

                IF gn_min_hdr_id IS NOT NULL AND gn_max_hdr_id IS NOT NULL THEN

                    SELECT ROUND( ( (TO_DATE(p_receipt_date_to, 'yyyy/mm/dd hh24:mi:ss') + 1) - (TO_DATE(p_receipt_date_from, 'yyyy/mm/dd hh24:mi:ss')) ) / 2 , 0)
                      INTO ln_date_range
                      FROM dual;

                    IF ln_date_range < p_thread_count THEN
                        ln_thread_count := p_thread_count;
                    ELSIF ln_date_range > 20 THEN
                        ln_thread_count := 20;
                    ELSE
                        ln_thread_count := ln_date_range;
                    END IF;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Derived Thread Count - ' || ln_thread_count);

                    -- Truncate xxfin.xx_ce_ordt_sas_itm table
                    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxfin.xx_ce_ordt_sas_itm';

                    -- Submitting Child Request in Loop
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Submiting child request in loop based on the value of Derived Thread Count');
                    FOR i IN c_split_headers (p_thread_count      => ln_thread_count,
                                              p_min_header_id     => gn_min_hdr_id,
                                              p_max_header_id     => gn_max_hdr_id
                                             )
                    LOOP

                        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting child thread number - ' || LPAD(i.thread_number, 2, 0) || '   MinHeaderId - ' || i.min_header_id || '   MaxHeaderId - ' || i.max_header_id);
                        BEGIN

                            ln_request_id := FND_REQUEST.submit_request( 'XXFIN',                   -- Program Application
                                                                         'XXCEORDTSASDISC_CHILD',   -- Program Short Name
                                                                         NULL,                      -- Description
                                                                         NULL,                      -- Start Date
                                                                         TRUE,                      -- Is Sub Request
                                                                         p_receipt_date_from,
                                                                         p_receipt_date_to,
                                                                         p_tender_type,
                                                                         p_store_number_from,
                                                                         p_store_number_to,
                                                                         i.min_header_id,
                                                                         i.max_header_id,
                                                                         i.thread_number,
                                                                         'SAS'
                                                                       );

                            IF ln_request_id <> 0 THEN

                                FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted request id ' ||ln_request_id|| '  - OD: CE Order Receipt Detail Discrepancy Report - Child');

                            ELSE
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: CE Order Receipt Detail Discrepancy Report - Child did not get submitted');

                            END IF;

                        EXCEPTION
                            WHEN OTHERS THEN
                                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error while submitting generate report data program : ' || SQLERRM);

                        END;

                    END LOOP;

                    FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => '-99');
                    COMMIT;

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while submitting OD: CE Order Receipt Detail Discrepancy Report - Child : ' || SQLERRM);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
            END;

        END IF;

        -- Submit Summary or Detail report after completion of Child requests
        IF lc_child_status = 'COMPLETED' THEN

            -- Submitting Summary Report
            IF p_report_mode = 'Summary' THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'Submiting OD: CE Order Receipt Detail Discrepancy Summary Report');

                BEGIN

                    lb_print_option := FND_REQUEST.set_print_options( printer  => 'XPTR',
                                                                      copies   => 1
                                                                    );

                    lb_layout := FND_REQUEST.add_layout( 'XXFIN',
                                                         'XXCEORDTSASDISC_SUMMARY',
                                                         'en',
                                                         'US',
                                                         'EXCEL'
                                                       );

                    ln_request_id := FND_REQUEST.submit_request( 'XXFIN',
                                                                 'XXCEORDTSASDISC_SUMMARY',
                                                                 NULL,
                                                                 NULL,
                                                                 FALSE,
                                                                 p_receipt_date_from,
                                                                 p_receipt_date_to,
                                                                 p_tender_type,
                                                                 p_store_number_from,
                                                                 p_store_number_to
                                                               );

                    COMMIT;

                    lb_req_status := FND_CONCURRENT.wait_for_request( request_id  => ln_request_id,
                                                                      interval    => '2',
                                                                      max_wait    => '',
                                                                      phase       => lc_phase,
                                                                      status      => lc_status,
                                                                      dev_phase   => lc_devphase,
                                                                      dev_status  => lc_devstatus,
                                                                      message     => lc_message
                                                                     );

                    IF ln_request_id <> 0 THEN

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted request id ' ||ln_request_id|| ' - OD: CE Order Receipt Detail Discrepancy Summary Report');
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submitted request id ' ||ln_request_id|| ' - OD: CE Order Receipt Detail Discrepancy Summary Report');
                            IF lc_devstatus ='E' THEN

                              x_err_buff := 'Program Completed In Error';
                              x_ret_code := 2;

                            ELSIF lc_devstatus ='G' THEN

                                x_err_buff := 'Program Completed In Warning';
                                x_ret_code := 1;

                            ELSE
                                x_err_buff := 'Program Completed Normal';
                                x_ret_code := 0;

                            END IF;

                    ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: CE Order Receipt Detail Discrepancy Summary Report did not get submitted');

                    END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error while submitting Summary report : ' || SQLERRM);

                END;

            -- Submitting Detail Report
            ELSIF p_report_mode = 'Detail' THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'Submiting OD: CE Order Receipt Detail Discrepancy Detail Report');

                BEGIN

                    lb_print_option := FND_REQUEST.set_print_options( printer  => 'XPTR',
                                                                      copies   => 1
                                                                    );

                    lb_layout := FND_REQUEST.add_layout( 'XXFIN',
                                                         'XXCEORDTSASDISC',
                                                         'en',
                                                         'US',
                                                         'EXCEL'
                                                       );

                    ln_request_id := FND_REQUEST.submit_request( 'XXFIN',
                                                                 'XXCEORDTSASDISC',
                                                                 NULL,
                                                                 NULL,
                                                                 FALSE,
                                                                 p_receipt_date_from,
                                                                 p_receipt_date_to,
                                                                 p_tender_type,
                                                                 p_store_number_from,
                                                                 p_store_number_to
                                                               );

                    COMMIT;

                    lb_req_status := FND_CONCURRENT.wait_for_request( request_id  => ln_request_id,
                                                                      interval    => '2',
                                                                      max_wait    => '',
                                                                      phase       => lc_phase,
                                                                      status      => lc_status,
                                                                      dev_phase   => lc_devphase,
                                                                      dev_status  => lc_devstatus,
                                                                      message     => lc_message
                                                                     );

                    IF ln_request_id <> 0 THEN

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted request id ' ||ln_request_id|| ' - OD: CE Order Receipt Detail Discrepancy Detail Report');
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submitted request id ' ||ln_request_id|| ' - OD: CE Order Receipt Detail Discrepancy Detail Report');
                            IF lc_devstatus ='E' THEN

                              x_err_buff := 'Program Completed In Error';
                              x_ret_code := 2;

                            ELSIF lc_devstatus ='G' THEN

                                x_err_buff := 'Program Completed In Warning';
                                x_ret_code := 1;

                            ELSE
                                x_err_buff := 'Program Completed Normal';
                                x_ret_code := 0;

                            END IF;

                    ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: CE Order Receipt Detail Discrepancy Detail Report did not get submitted');

                    END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error while submitting Detail report : ' || SQLERRM);

                END;

            -- Default
            ELSE

                FND_FILE.PUT_LINE(FND_FILE.LOG,'Please select Report Mode as Summary or Detail');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Please select Report Mode as Summary or Detail');

            END IF;

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at PROCEDURE submit_wrapper_prog : ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

    END submit_wrapper_prog;


END xx_ce_ordtsas_disc_pkg;
/
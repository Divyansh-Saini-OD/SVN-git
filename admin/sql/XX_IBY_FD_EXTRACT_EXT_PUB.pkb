create or replace PACKAGE BODY iby_fd_extract_ext_pub
AS
/* $Header: ibyfdxeb.pls 120.2 2006/09/20 18:52:12 frzhang noship $ */

  --Added for defect# 28958 and 28983
  ln_isa_seq_num           NUMBER := 0;  
  ln_st_cntrl_num          NUMBER := 1; 
   --
  -- This API is called once only for the payment instruction.
  -- Implementor should construct the extract extension elements
  -- at the payment instruction level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  -- Below is an example implementation:
/*
  FUNCTION Get_Ins_Ext_Agg(p_payment_instruction_id IN NUMBER)
  RETURN XMLTYPE
  IS
    l_ins_ext_agg XMLTYPE;

    CURSOR l_ins_ext_csr (p_payment_instruction_id IN NUMBER) IS
    SELECT XMLConcat(
             XMLElement("Extend",
               XMLElement("Name", ext_table.attr_name1),
               XMLElement("Value", ext_table.attr_value1)),
             XMLElement("Extend",
               XMLElement("Name", ext_table.attr_name2),
               XMLElement("Value", ext_table.attr_value2))
           )
      FROM your_pay_instruction_lvl_table ext_table
     WHERE ext_table.payment_instruction_id = p_payment_instruction_id;

  BEGIN

    OPEN l_ins_ext_csr (p_payment_instruction_id);
    FETCH l_ins_ext_csr INTO l_ins_ext_agg;
    CLOSE l_ins_ext_csr;

    RETURN l_ins_ext_agg;

  END Get_Ins_Ext_Agg;
*/

   -- --------------------------------------------------------------
-- Modified for R12 Upgrade.
-- Added by For Adding the OD required values for payment format
-- --------------------------------------------------------------
   FUNCTION getdefaultvalues
      RETURN XMLTYPE
   IS
      l_ins_ext_agg   XMLTYPE;

-- ----------------------------------------------------------------
-- Added For R12 Upgrade
-- Below cursor will get the data for setting Program variables
-- which will be used for compasrion
-- ----------------------------------------------------------------
      CURSOR l_ins_ext_csr
      IS
         SELECT XMLCONCAT
                   (XMLELEMENT
                       ("ExtendGlobal",
                        XMLELEMENT ("AmexVendorName", val.source_value1),
                        -- Vendor Name for the Amex Payments
                        XMLELEMENT ("ChildGarnishVendType", val.source_value2),
                        -- Vendor Type for the Child Garnish Payments
                        XMLELEMENT ("EDISenderId", val.source_value3),
                        -- EDI Sender Id
                        XMLELEMENT ("TestIndicator", val.source_value4),
                        -- Test Indicator
                        XMLELEMENT ("EdiQualifier",
                                    DECODE (val.source_value4,
                                            'P', '01',
                                            'ZZ'
                                           )
                                   ),                      -- gc_edi_qualifier
                        XMLELEMENT ("EDIGSSenderID", val.source_value5),
                        -- EDI GS Sender ID (705 GS Record)
                        XMLELEMENT ("FileIDMode", val.source_value6),
                        -- File ID Modifier Temporary workaround default 'A'
                        XMLELEMENT ("EDIDunsId", val.source_value7)
                       -- EDI Duns Id*
                       )
                   )
           FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
          WHERE def.translate_id = val.translate_id
            AND def.translation_name = 'OD_AP_NACHA_DETAILS'
            AND SYSDATE BETWEEN def.start_date_active
                            AND NVL (def.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN val.start_date_active
                            AND NVL (val.end_date_active, SYSDATE + 1)
            AND def.enabled_flag = 'Y'
            AND val.enabled_flag = 'Y';
   BEGIN
      OPEN l_ins_ext_csr;

      FETCH l_ins_ext_csr
       INTO l_ins_ext_agg;

      CLOSE l_ins_ext_csr;

      RETURN l_ins_ext_agg;
   END getdefaultvalues;

--- -------------------------------------------------------------
   FUNCTION get_ins_ext_agg (p_payment_instruction_id IN NUMBER)
      RETURN XMLTYPE
   IS
      l_ins_ext_agg   XMLTYPE;

-- ----------------------------------------------------------------
-- Added For R12 Upgrade
-- Below cursor will get the data for setting Program variables
-- which will be used for compasrion
-- ----------------------------------------------------------------
      CURSOR l_ins_ext_csr
      IS
         SELECT XMLCONCAT
                   (XMLELEMENT
                       ("ExtendGlobal",
                        XMLELEMENT ("AmexVendorName", val.source_value1),
                        -- Vendor Name for the Amex Payments
                        XMLELEMENT ("ChildGarnishVendType", val.source_value2),
                        -- Vendor Type for the Child Garnish Payments
                        XMLELEMENT ("EDISenderId", val.source_value3),
                        -- EDI Sender Id
                        XMLELEMENT ("TestIndicator", val.source_value4),
                        -- Test Indicator
                        XMLELEMENT ("EdiQualifier",
                                    DECODE (val.source_value4,
                                            'P', '01',
                                            'ZZ'
                                           )
                                   ),                      -- gc_edi_qualifier
                        XMLELEMENT ("EDIGSSenderID", val.source_value5),
                        -- EDI GS Sender ID (705 GS Record)
                        XMLELEMENT ("FileIDMode", val.source_value6),
                        -- File ID Modifier Temporary workaround default 'A'
                        XMLELEMENT ("EDIDunsId", val.source_value7)
                       -- EDI Duns Id*
                       )
                   )
           FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
          WHERE def.translate_id = val.translate_id
            AND def.translation_name = 'OD_AP_NACHA_DETAILS'
            AND SYSDATE BETWEEN def.start_date_active
                            AND NVL (def.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN val.start_date_active
                            AND NVL (val.end_date_active, SYSDATE + 1)
            AND def.enabled_flag = 'Y'
            AND val.enabled_flag = 'Y';
   BEGIN
      /*OPEN l_ins_ext_csr ;
      FETCH l_ins_ext_csr INTO l_ins_ext_agg;
      CLOSE L_INS_EXT_CSR;
       */
      l_ins_ext_agg := getdefaultvalues;
      RETURN l_ins_ext_agg;
   END get_ins_ext_agg;

   --
   -- This API is called once per payment.
   -- Implementor should construct the extract extension elements
   -- at the payment level as a SQLX XML Aggregate
   -- and return the aggregate.
   --
   FUNCTION get_pmt_ext_agg (p_payment_id IN NUMBER)
      RETURN XMLTYPE
   IS
      l_ins_ext_agg            XMLTYPE;
      lc_amex_vendor_name      xx_fin_translatevalues.source_value1%TYPE;
      lc_garnish_vendor_type   xx_fin_translatevalues.source_value2%TYPE;
      lc_edi_sender_id         xx_fin_translatevalues.source_value3%TYPE;
      lc_test_indicator        xx_fin_translatevalues.source_value4%TYPE;
      lc_edi_qualifier         xx_fin_translatevalues.source_value4%TYPE;
      ln_gs_edi_sender_id      xx_fin_translatevalues.source_value5%TYPE;
      lc_file_id_modifier      xx_fin_translatevalues.source_value6%TYPE;
      ln_edi_duns_id           xx_fin_translatevalues.source_value7%TYPE;
      lc_vendor_type_lk_code   ap_suppliers.vendor_type_lookup_code%TYPE;
      lc_vendor_name           ap_suppliers.vendor_name%TYPE;
      ln_vendor_id             ap_suppliers.vendor_id%TYPE;
      ln_vendor_site_id        ap_supplier_sites_all.vendor_site_id%TYPE;
      ln_addenda_rec_cnt       NUMBER;
      --lc_addenda               VARCHAR2 (4000); -- Commented 09122013
      lc_addenda               CLOB; -- Added 09122013
      lc_payment_type          VARCHAR2 (100);
      lc_site_category         ap_supplier_sites_all.attribute8%TYPE;
      -- added for check prinitng
      lc_curr_symbol           fnd_currencies_vl.symbol%TYPE;
      -- added for check prinitng
      lc_signature             xx_fin_translatevalues.source_value8%TYPE;
      -- added for check prinitng
      lc_trans_per_page        xx_fin_translatevalues.source_value8%TYPE;
      -- Added for check printing contains count of transactions perpage.
      lc_settle_date           VARCHAR2 (15);
      -- varible to capture the settle_date
      ld_payment_date          DATE;    -- varible to capture the settle_date
   BEGIN
-- ---------------------------
-- Get Defaults
-- ---------------------------
     BEGIN
      SELECT val.source_value1            -- Vendor Name for the Amex Payments
                              ,
             val.source_value2   -- Vendor Type for the Child Garnish Payments
        /*, VAL.SOURCE_VALUE3                            -- EDI Sender Id
        , VAL.SOURCE_VALUE4                            -- Test Indicator
        , DECODE (VAL.SOURCE_VALUE4, 'P', '01', 'ZZ')  -- gc_edi_qualifier
        , VAL.SOURCE_VALUE5                            -- EDI GS Sender ID (705 GS Record)
        , VAL.SOURCE_VALUE6                            -- File ID Modifier Temporary workaround default 'A'
        , VAL.SOURCE_VALUE7                            -- EDI Duns Id*/
      INTO   lc_amex_vendor_name,
             lc_garnish_vendor_type
        FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
       WHERE def.translate_id = val.translate_id
         AND def.translation_name = 'OD_AP_NACHA_DETAILS'
         AND SYSDATE BETWEEN def.start_date_active
                         AND NVL (def.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN val.start_date_active
                         AND NVL (val.end_date_active, SYSDATE + 1)
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';
     EXCEPTION
	   WHEN OTHERS THEN
           lc_amex_vendor_name  :=  '';
           lc_garnish_vendor_type :=  '';
	 END;
-- ---------------------------
-- Payment Vendor Details
-- ---------------------------
     BEGIN
      SELECT aps.vendor_id, aps.vendor_name, aps.vendor_type_lookup_code,
             asa.vendor_site_id, asa.attribute8,       -- Added for Checkprint
             ipa.payment_date                        -- added for payment date
        INTO ln_vendor_id, lc_vendor_name, lc_vendor_type_lk_code,
             ln_vendor_site_id, lc_site_category,
             ld_payment_date
        FROM ap_suppliers aps, iby_payments_all ipa,
             ap_supplier_sites_all asa
       WHERE ipa.payment_id = p_payment_id
         AND ipa.payee_party_id = aps.party_id
         AND asa.vendor_id = aps.vendor_id
         AND asa.vendor_site_id = ipa.supplier_site_id;
     EXCEPTION
	   WHEN OTHERS THEN
          ln_vendor_id:='';
		  lc_vendor_name:='';
		  lc_vendor_type_lk_code:='';
		  ln_vendor_site_id:='';
		  lc_site_category:='';
		  ld_payment_date:='';
	 END;	 
----------------------------------------------
-- get payment currency symbol for check printing
------------------------------------------------
     BEGIN
      SELECT fcv.symbol
        INTO lc_curr_symbol
        FROM iby_payments_all ipa, fnd_currencies_vl fcv
       WHERE ipa.payment_id = p_payment_id
         AND fcv.currency_code = ipa.payment_currency_code;
     EXCEPTION
	   WHEN OTHERS THEN
         lc_curr_symbol:='';
	 END;	 
------------------------------------------------
-- get the image for signature on check
------------------------------------------------
     BEGIN
      SELECT val.source_value8                                    -- Signature
            ,val.source_value4                       --  Transactions per page
        INTO lc_signature
            ,lc_trans_per_page
        FROM iby_payments_all ipa,
             xx_fin_translatedefinition def,
             xx_fin_translatevalues val
       WHERE ipa.payment_id = p_payment_id
         AND def.translate_id = val.translate_id
         AND def.translation_name = 'AP_CHECK_PRINT_BANK_DTLS'
         AND val.source_value1 = ipa.int_bank_account_name
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';
    EXCEPTION 
	  WHEN OTHERS THEN
	    lc_signature:='';
		lc_trans_per_page := 37;
	END;
	
    /* Commented 23DEC -- 
	-- -------------------------------------------------
    -- Get the number of lines defined in remittance stub
    -- --------------------------------------------------
     BEGIN
       SELECT ced.number_of_lines_per_remit_stub
         INTO lc_trans_per_page
         FROM ce_payment_documents ced
            , iby_pay_service_requests ipsr
            , iby_payments_all ipa
        WHERE ipa.payment_id = p_payment_id
          AND ipsr.payment_service_request_id = ipa.payment_service_request_id
          AND ced.payment_document_id = ipsr.payment_document_id;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         lc_trans_per_page := NULL;
     END;
	 */
	 --Added for defect# 28958 and 28983
      ln_isa_seq_num := ln_isa_seq_num + 1;
      ln_st_cntrl_num := ln_st_cntrl_num + 1; 
-- -------------------------------------------------
-- Call payment_details function to get the details
----------------------------------------------------
      IF lc_vendor_type_lk_code = lc_garnish_vendor_type
      THEN
         lc_payment_type := 'GARNSH';
         lc_addenda :=
            xx_ap_nachaboa_eft_pkg.payment_details (ln_vendor_id,
                                                    ln_vendor_site_id,
                                                    lc_garnish_vendor_type,
                                                    lc_payment_type,
                                                    p_payment_id,
                                                    1,
													ln_isa_seq_num, --Added for defect# 28958 and 28983
													ln_st_cntrl_num, --Added for defect# 28958 and 28983
                                                    ln_addenda_rec_cnt
                                                   );
      ELSIF lc_vendor_name = lc_amex_vendor_name
      THEN
         lc_payment_type := 'AMEX';
         lc_addenda :=
            xx_ap_nachaboa_eft_pkg.payment_details (ln_vendor_id,
                                                    ln_vendor_site_id,
                                                    lc_garnish_vendor_type,
                                                    lc_payment_type,
                                                    p_payment_id,
                                                    1,
													ln_isa_seq_num, --Added for defect# 28958 and 28983
													ln_st_cntrl_num, --Added for defect# 28958 and 28983
                                                    ln_addenda_rec_cnt
                                                   );
      ELSIF lc_vendor_name = 'JP MORGAN CHASE'
      THEN
         lc_payment_type := 'JP MORGAN';
         lc_addenda :=
            xx_ap_nachaboa_eft_pkg.payment_details (ln_vendor_id,
                                                    ln_vendor_site_id,
                                                    lc_garnish_vendor_type,
                                                    lc_payment_type,
                                                    p_payment_id,
                                                    1,
													ln_isa_seq_num,  --Added for defect# 28958 and 28983
													ln_st_cntrl_num, --Added for defect# 28958 and 28983
                                                    ln_addenda_rec_cnt
                                                   );
      ELSE
         lc_payment_type := 'VENDOR';
         lc_addenda :=
            xx_ap_nachaboa_eft_pkg.payment_details (ln_vendor_id,
                                                    ln_vendor_site_id,
                                                    lc_garnish_vendor_type,
                                                    lc_payment_type,
                                                    p_payment_id,
                                                    1,
													ln_isa_seq_num, --Added for defect# 28958 and 28983
													ln_st_cntrl_num, --Added for defect# 28958 and 28983
                                                    ln_addenda_rec_cnt
                                                   );
      END IF;

-- -----------------------------------------
-- Create the XML output for the record
-- -----------------------------------------
      lc_settle_date :=
         xx_ap_nachaboa_eft_pkg.settle_date (ln_vendor_id,
                                             ln_vendor_site_id,
                                             NVL (ld_payment_date, SYSDATE)
                                            );

-- -----------------------------------------
-- Create the XML output for the record
-- -----------------------------------------
      SELECT XMLCONCAT (XMLELEMENT ("ExtendPayment",
                                    XMLELEMENT ("SignImage", lc_signature),
                                    XMLELEMENT ("TransCountPerPage",
                                                lc_trans_per_page
                                               ),
                                    XMLELEMENT ("PayCurrCode", lc_curr_symbol),
                                    XMLELEMENT ("VenID", ln_vendor_id),
                                    XMLELEMENT ("VenName", lc_vendor_name),
                                    XMLELEMENT ("SettlementDate",
                                                lc_settle_date
                                               ),
                                    -- added for settlement Date
                                    XMLELEMENT ("VenSiteCategory",
                                                lc_site_category
                                               ),
                                    XMLELEMENT ("VendorType",
                                                lc_vendor_type_lk_code
                                               ),
                                    XMLELEMENT ("AddendaRec", lc_addenda),
                                    XMLELEMENT ("AddendaRecCount",
                                                ln_addenda_rec_cnt
                                               )
                                   )
                       )
        INTO l_ins_ext_agg
        FROM DUAL;

      RETURN l_ins_ext_agg;
   END get_pmt_ext_agg;

   --
   -- This API is called once per document payable.
   -- Implementor should construct the extract extension elements
   -- at the document level as a SQLX XML Aggregate
   -- and return the aggregate.
   --
   FUNCTION get_doc_ext_agg (p_document_payable_id IN NUMBER)
      RETURN XMLTYPE
   IS
      l_ins_ext_agg    XMLTYPE;
      lc_voucher_num   ap_invoices_all.voucher_num%TYPE;
      lc_checknumber   ap_checks_all.check_number%TYPE;
   BEGIN
-- ----------------------------------------
-- Added for checkprint to get the voucher number
-- and the check number
-- ----------------------------------------
     BEGIN
      SELECT aia.voucher_num, ipa.paper_document_number
        INTO lc_voucher_num, lc_checknumber           -- added for check print
        FROM iby_docs_payable_all idp,
             ap_invoices_all aia,
             iby_payments_all ipa
       WHERE idp.document_payable_id = p_document_payable_id
         AND ipa.payment_id = idp.payment_id
         AND aia.invoice_id = idp.calling_app_doc_unique_ref2
         AND aia.invoice_num = idp.calling_app_doc_ref_number
         AND ipa.payment_method_code = 'CHECK';
     EXCEPTION
	   WHEN NO_DATA_FOUND THEN
	     lc_voucher_num:='';
		 lc_checknumber:='';
	 END;
      SELECT XMLCONCAT (XMLELEMENT ("ExtendPayDoc",
                                    XMLELEMENT ("InvVoucherNum",
                                                lc_voucher_num
                                               ),
                                    XMLELEMENT ("ActualCheckNum",
                                                lc_checknumber
                                               )
                                   )
                       )
        INTO l_ins_ext_agg
        FROM DUAL;

      RETURN l_ins_ext_agg;
   END get_doc_ext_agg;

   --
   -- This API is called once per document payable line.
   -- Implementor should construct the extract extension elements
   -- at the doc line level as a SQLX XML Aggregate
   -- and return the aggregate.
   --
   -- Parameters:
   --   p_document_payable_id: primary key of IBY iby_docs_payable_all table
   --   p_line_number: calling app doc line number. For AP this is
   --   ap_invoice_lines_all.line_number.
   --
   -- The combination of p_document_payable_id and p_line_number
   -- can uniquely locate a document line.
   -- For example if the calling product of a doc is AP
   -- p_document_payable_id can locate
   -- iby_docs_payable_all/ap_documents_payable.calling_app_doc_unique_ref2,
   -- which is ap_invoice_all.invoice_id. The combination of invoice_id and
   -- p_line_number will uniquely identify the doc line.
   --
   FUNCTION get_docline_ext_agg (
      p_document_payable_id   IN   NUMBER,
      p_line_number           IN   NUMBER
   )
      RETURN XMLTYPE
   IS
   BEGIN
      RETURN NULL;
   END get_docline_ext_agg;

   --
   -- This API is called once only for the payment process request.
   -- Implementor should construct the extract extension elements
   -- at the payment request level as a SQLX XML Aggregate
   -- and return the aggregate.
   --
   FUNCTION get_ppr_ext_agg (p_payment_service_request_id IN NUMBER)
      RETURN XMLTYPE
   IS
   BEGIN
      RETURN NULL;
   END get_ppr_ext_agg;
END iby_fd_extract_ext_pub;
/
SHOW ERRORS;
CREATE OR REPLACE PACKAGE BODY XX_CDH_ACCT_CREATION_INTF_PKG
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                       WIPRO Technologies                          |
   -- +===================================================================+
   -- | Name       :  XX_CDH_ACCT_CREATION_INTF_PKG                       |
   -- | Rice ID    :  E0806_SalesCustomerAccountCreation                  |
   -- | Description:  This package contains procedure to extract customer |
   -- |               account setup request details, find the             |
   -- |               corresponding Bill To Address, Ship To Address and  |
   -- |               Sales Rep details and load them into Interface table|
   -- |                                                                   |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date        Author           Remarks                     |
   -- |=======   ==========  =============    ============================|
   -- |1.a      14-SEP-2007  Rizwan           Initial draft version       |
   -- |1.b      04-OCT-2007  Rizwan           Implemented logic to update |
   -- |                                       request status.             |
   -- |1.0      09-NOV-2007  Rizwan           Modified code to use CRM    |
   -- |                                       specific Error Log API.     |
   -- |1.1      10-DEC-2007  Rizwan           Modified code to use contact|
   -- |                                       details for CDH.            |
   -- |1.2      18-JAN-2007  Rizwan           Modified code to remove     |
   -- |                                       country code.               |
   -- |1.3      19-FEB-2007  Rizwan           Modified code to fix contact|
   -- |1.4      07-MAR-2007  Rizwan           Remove Phone Extension.     |
   -- |                                       Replace ' | ' from all the  |
   -- |                                       fields.                     |
   -- |                                       Pass Party ID and Site ID   |
   -- |                                       instead of Party Number and |
   -- |                                       Site number.                |
   -- |1.5      03-MAY-2007  Rizwan           Translate SFA to AOPS       |
   -- |                                       country code.               |
   -- |1.6      25-JUN-2007  Rizwan           Translate SFA to AOPS       |
   -- |                                       using translation table.    |
   -- |1.7      15-JUL-2007  Rizwan           Modified Sales Rep Info     |
   -- |                                       Derivation.                 |
   -- |1.8      29-AUG-2008  Sreekanth        Modified the BSD BDM rep    |
   -- |                                       assignment. New rule: Check |
   -- |                                       for any BSD assignments, but|
   -- |                                       in the order, BSD BDM to ide|
   -- |                                       ntifying site,then to any si|
   -- |                                       te, then any BSD to identify|
   -- |                                       site and then any BSD assnd |
   -- |1.9      09-APR-2010  Sreedhar         Added tin_number and up_    |
   -- |                                       program_codes.              |
   -- |2.0      18-MAY-2016  Shubashree       Defect#37898 removed schema |
   -- |                                       references for GSCC compliance |
   -- +===================================================================+
AS
  
  FUNCTION GET_CONCATENATED_UP_PROG_CODES( p_contract_template_id NUMBER)
  RETURN VARCHAR2 IS 

  lc_err_desc               xx_com_error_log.error_message%TYPE DEFAULT ' ';
  lc_application_name       xx_com_error_log.application_name%TYPE  := 'XXCRM';
  lc_program_type           xx_com_error_log.program_type%TYPE      := 'E0806_SalesCustomerAccountCreation';
  lc_program_name           xx_com_error_log.program_name%TYPE      := 'XX_CDH_ACCT_CREATION_INTF_PKG';
  lc_module_name            xx_com_error_log.module_name%TYPE       := 'SFA';
  lc_error_location         xx_com_error_log.error_location%TYPE    := 'GET_REQUEST';
  lc_token                  VARCHAR2(4000);
  lc_error_message_code     VARCHAR2(100);  

  
  l_up_prog_codes   VARCHAR2(2000);
  l_tot_prog_codes  NUMBER;
  l_prog_codes_count NUMBER;
  l_temp             varchar2(2000);
  
  cursor c1
  is
  select count(1)
  from   fnd_flex_value_sets vs,
         fnd_flex_values_vl vv
  where  vs.flex_value_set_id = vv.flex_value_set_id 
  and    vs.flex_value_set_name = 'XX_CRM_UNIV_PRICE_PROG_CODES'
  and    vv.enabled_flag='Y' 
  and    vv.end_date_active is null;
  
  cursor c2 ( p_contract_template_id NUMBER)
  is
  select program_code,
         discount_rate,
         exclude_univ_pricing
  from   XX_CDH_CONTRACT_PROG_CODES
  where  contract_template_id = p_contract_template_id;
  
  begin
  
    l_tot_prog_codes := 0;
    l_up_prog_codes := null;

    open c1;
    fetch c1 into l_tot_prog_codes;
    close c1;
    
    l_up_prog_codes := '';
    l_prog_codes_count := 0;
       
    for i in c2 (p_contract_template_id)
    loop
      l_prog_codes_count := l_prog_codes_count + 1;
      l_up_prog_codes := l_up_prog_codes         || '|' || 
                         i.program_code         || '|' || 
                         i.discount_rate        || '|' || 
                         i.exclude_univ_pricing;
    end loop;

    l_temp:= null;    
    for j in 1..(l_tot_prog_codes - l_prog_codes_count)
    loop
      l_temp := l_temp || '|' || '|' || '|';
    end loop;
    
    l_up_prog_codes := l_up_prog_codes || l_temp;
    
    l_up_prog_codes := substr(l_up_prog_codes, 2,length(l_up_prog_codes));
    
    return l_up_prog_codes;
    
  exception
    when others then
      null;
  end GET_CONCATENATED_UP_PROG_CODES;
  

   -- +===================================================================+
   -- | Name             : GET_REQUEST                                    |     
   -- | Description      : This procedure extract customer account setup  |
   -- |                    request details, find the corresponding        |
   -- |                    Bill To Address, Ship To Address and Sales Rep |
   -- |                    details and load them into Interface table     |
   -- |                                                                   |
   -- | Parameters :      x_batch_id                                      |
   -- |                   x_status                                        |
   -- |                   x_message                                       |
   -- +===================================================================+

  PROCEDURE get_request(x_batch_id OUT NUMBER
                       ,x_status   OUT VARCHAR
                       ,x_message  OUT VARCHAR) IS

    ----------------------------------------------------------------------
    ---                Variable Declaration                            ---
    ----------------------------------------------------------------------
    ln_batch_id               NUMBER;
    lc_phone_number           VARCHAR2(100);
    ln_phone_contact_point_id hz_contact_points.contact_point_id%TYPE;
    lc_fax_number             VARCHAR2(100);
    ln_fax_contact_point_id   hz_contact_points.contact_point_id%TYPE;
    ln_contact_name           hz_parties.person_first_name%TYPE;
    ln_person_party_id        hz_parties.party_id%TYPE;
    ln_subject_id             hz_relationships.subject_id%TYPE;
    ln_resource_id            xx_tm_nam_terr_curr_assign_v.resource_id%TYPE;
    ln_resource_role_id       xx_tm_nam_terr_curr_assign_v.resource_role_id%TYPE;
    ln_resource_group_id      xx_tm_nam_terr_curr_assign_v.group_id%TYPE;
    lc_legacy_rep_id          jtf_rs_role_relations.attribute15%TYPE;
    lc_rep_name               jtf_rs_resource_extns.source_name%TYPE;
    lc_rep_phone              jtf_rs_resource_extns.source_phone%TYPE;
    lc_rep_email              jtf_rs_resource_extns.source_email%TYPE;
    lc_dsm_rep_id             jtf_rs_role_relations.attribute15%TYPE;
    lc_dsm_rep_name           jtf_rs_resource_extns.source_name%TYPE;
    lc_err_desc               xx_com_error_log.error_message%TYPE DEFAULT ' ';
    lc_application_name       xx_com_error_log.application_name%TYPE  := 'XXCRM';
    lc_program_type           xx_com_error_log.program_type%TYPE      := 'E0806_SalesCustomerAccountCreation';
    lc_program_name           xx_com_error_log.program_name%TYPE      := 'XX_CDH_ACCT_CREATION_INTF_PKG';
    lc_module_name            xx_com_error_log.module_name%TYPE       := 'SFA';
    lc_error_location         xx_com_error_log.error_location%TYPE    := 'GET_REQUEST';
    lc_token                  VARCHAR2(4000);
    lc_error_message_code     VARCHAR2(100);  
    gc_acct_status_lookup     fnd_lookup_values.lookup_type%TYPE:= 'XX_CDH_BPELPROCESS_REQ_STATUS';
    ln_bsd_rep_found          NUMBER;
    l_up_prog_codes           VARCHAR2(2000);
    
    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    -- Cursor extracts all the customer setup request records from      --
    -- xx_cdh_account_setup_req which are in "Submitted"                --
    -- or "BPEL Trasmission Failed" status                              --
    -- Get Bill to Address based on the Bill to number, It is mandatory --
    -- that Bill to information defined                                 --
    -- Get Ship to Address based on the Ship to number, outer joined    --
    --                                                                  --
    ----------------------------------------------------------------------
    CURSOR c_req_dtls IS
      SELECT HZP.party_id
            , HZP.party_number
            , HZP.party_name
            , HZPS.party_site_id
            , HZPS.addr_line1
            , HZPS.addr_line2
            , HZPS.city
            , HZPS.state
            , HZPS.postal_code
            , HZP.attribute24
            , HZPS.country ora_country
	    ,(SELECT source_value2 
               FROM xx_fin_translatevalues
              WHERE translate_id =
                                  (SELECT translate_id
                                     FROM xx_fin_translatedefinition
                                    WHERE translation_name = 'XXOD_CDH_CONV_COUNTRY')
                AND source_value1 = 'A0' 
                AND source_value3 = 'Y' 
                AND TRUNC(sysdate) BETWEEN nvl(start_date_active, sysdate) AND nvl(end_date_active, sysdate)
                AND target_value1 = HZPS.country
		AND ROWNUM <2) aops_country
            , HZP.duns_number_c
            , hzss.addr_line1 alt_addr1
            , HZSS.addr_line2 alt_addr2
            , HZSS.city alt_city
            , HZSS.state alt_state
            , HZSS.postal_code alt_zip
            , HZSS.country ora_alt_country
	    ,(SELECT source_value2 
               FROM xx_fin_translatevalues
              WHERE translate_id =
                                  (SELECT translate_id
                                     FROM xx_fin_translatedefinition
                                    WHERE translation_name = 'XXOD_CDH_CONV_COUNTRY')
                AND source_value1 = 'A0' 
                AND source_value3 = 'Y' 
                AND TRUNC(sysdate) BETWEEN nvl(start_date_active, sysdate) AND nvl(end_date_active, sysdate)
                AND target_value1 = HZSS.country
		AND ROWNUM <2) aops_alt_country
            , XCASR.request_id
            , XCASR.delivery_document_type
            , XCASR.print_invoice
            , XCASR.display_back_order
            , XCASR.rename_packing_list
            , XCASR.display_purchase_order
            , XCASR.display_prices
            , XCASR.display_payment_method
            , XCASR.payment_method
            , XCASR.parent_id
            , XCASR.afax
            , XCASR.substitutions
            , XCASR.po_validated
            , XCASR.release_validated
            , XCASR.department_validated
            , XCASR.desktop_validated
            , XCASR.po_header
            , XCASR.release_header
            , XCASR.department_header
            , XCASR.desktop_header
            , trim(XCASR.price_plan) || trim(XCASR.attribute2) price_plan
            , XCASR.gp_floor_percentage
            , XCASR.xref
            , XCASR.off_contract_code
            , XCASR.off_contract_percentage
            , XCASR.off_wholesale_code
            , XCASR.wholesale_percentage
            , XCASR.tax_exempt
            , XCASR.comments
            , XCASR.status
            , XCASR.status_transition_date
            , XCASR.bill_to_site_id bill_to_site_id --This has been changed from Site number to Site ID
            , XCASR.ship_to_site_id ship_to_site_id --This has been changed from Site number to Site ID
            , XCASR.fax_order
            , XCASR.back_orders
            , XCASR.ap_contact
            , XCASR.attribute14
            , XCASR.attribute15
            , XCASR.tin_number
            , XCASR.contract_template_id
      FROM xx_cdh_account_setup_req XCASR,
           (SELECT BPS.party_id
                   , BPS.party_site_id
                   , BPS.party_site_number
                   , HL.address1 addr_line1
                   , address2 || ' '|| address3 || ' ' || address4 addr_line2
                   , city, postal_code
                   , state
                   , province
                   , county
		   , country
             FROM hz_locations HL
                 , hz_party_sites BPS
            WHERE HL.location_id = BPS.location_id)  HZPS,
          (SELECT SPS.party_site_id
                  , SPS.party_site_number
                  , HL.address1 addr_line1
		  , address2 || ' ' || address3 || ' ' || address4 addr_line2
                  , city
                  , postal_code
                  , state
                  , province
                  , county
		  , country
            FROM hz_locations HL
                , hz_party_sites SPS
            WHERE HL.location_id = SPS.location_id)  HZSS,
           hz_parties HZP
      WHERE HZPS.party_id = HZP.party_id
        AND XCASR.bill_to_site_id = HZPS.party_site_id
        AND XCASR.ship_to_site_id = HZSS.party_site_id(+)
        AND XCASR.status IN (SELECT FLV.meaning
                               FROM fnd_lookup_values FLV
                              WHERE FLV.lookup_type = gc_acct_status_lookup
                                AND FLV.enabled_flag = 'Y'
                                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(FLV.start_date_active,SYSDATE)) AND TRUNC(NVL(FLV.end_date_active,SYSDATE)));

  BEGIN

    ----------------------------------------------------------------------
    ---                      SEQUENCE                                  ---
    -- Generate Batch ID.                                                 --
    --                                                                  --
    ----------------------------------------------------------------------

    -- Abort the program if Batch ID can not be generated.

    FND_MESSAGE.SET_NAME ('XXCRM', 'XX_CRM_ACCT_001_BATCHID_ERROR');
    lc_err_desc            := FND_MESSAGE.GET;
    lc_error_message_code  := 'XX_CRM_ACCT_001_BATCHID_ERROR';
         
    SELECT xxcrm.xx_cdh_acct_setup_req_intf_s.NEXTVAL
      INTO ln_batch_id
      FROM dual;

    FOR c_req_dtls_rec IN c_req_dtls
    LOOP

       -----------------------------------------------------------------------
       ---                      INSERTION                                  ---
       -- Insert records into interface table xx_cdh_account_setup_req_intf --
       --                                                                   --
       -----------------------------------------------------------------------

      FND_MESSAGE.SET_NAME ('XXCRM', 'XX_CRM_ACCT_008_LOAD_INTF_TAB');
      lc_err_desc           := FND_MESSAGE.GET;
      lc_error_message_code := 'XX_CRM_ACCT_008_LOAD_INTF_TAB';

      l_up_prog_codes := get_concatenated_up_prog_codes(c_req_dtls_rec.contract_template_id);

      INSERT INTO XX_CDH_ACCOUNT_SETUP_REQ_INTF
          (request_id
         , batch_id
         , c_internid
         , r_rep_id
         , r_name
         , r_phone
         , r_dsm_id
         , d_name
         , c_name
         , c_addr1
         , c_addr2
         , c_city
         , c_state
         , c_zip
         , c_phone
         , c_rev_band
         , c_country
         , c_duns_id
         , c_id
         , c_source
         , c_fax
         , c_alt_addr1
         , c_alt_addr2
         , c_alt_city
         , c_alt_state
         , c_alt_zip
         , c_alt_country
         , c_csc_loc_code
         , a_deldoc_type
         , a_print_inv
         , a_disp_backords
         , a_ren_pack_list
         , a_disp_purchord
         , a_disp_pymt_method
         , a_disp_prices
         , a_pymt_method
         , a_credit_card
         , a_parent_id
         , a_child
         , a_ocafax
         , a_ocsubst
         , a_ocfaxord
         , a_ocbackord
         , a_deflt_po
         , a_deflt_dept
         , a_deflt_release
         , a_deflt_dsktop
         , a_price_plan
         , a_gpfloor_percent
         , a_xref
         , a_up_off_contract
         , a_off_cntrct_percent
         , a_up_off_wholesale
         , a_wholesale_percent
         , a_acctspay_cntct
         , a_spc
         , a_tax_exempt
         , a_addlshipto
         , a_internet
         , a_edi
         , a_ren_po
         , a_ren_release
         , a_ren_dept
         , a_ren_dsktp
         , a_needs_approval
         , a_approved_by
         , a_add_shiptos
         , c_original_id
         , ship_to_party_org_num
         , bill_to_site_number
         , ship_to_site_number
         , ap_contact_num
         , phone_id
         , fax_id
         , comments
         , status
         , status_transition_date
         , sales_rep_email
         , employer_id
         , contact_id
         , customer_segmentation_code
         , customer_loyalty_code
         , up_prog_codes)
      VALUES(c_req_dtls_rec.request_id
           , ln_batch_id
           , c_req_dtls_rec.party_id -- this has been chnaged from Party Number to Party ID
           , NULL
           , NULL
           , NULL
           , NULL
           , NULL
           , replace(c_req_dtls_rec.party_name,'|','')
           , replace(c_req_dtls_rec.addr_line1,'|','')
           , replace(c_req_dtls_rec.addr_line2,'|','')
           , replace(c_req_dtls_rec.city,'|','')
           , replace(c_req_dtls_rec.state,'|','')
           , replace(c_req_dtls_rec.postal_code,'|','')
           , NULL
           , replace(c_req_dtls_rec.attribute24,'|','')
           , replace(c_req_dtls_rec.aops_country,'|','')
           , replace(c_req_dtls_rec.duns_number_c,'|','')
           , c_req_dtls_rec.party_id -- this has been chnaged from Party Number to Party ID
           , NULL
           , NULL
           , replace(c_req_dtls_rec.alt_addr1,'|','')
           , replace(c_req_dtls_rec.alt_addr2,'|','')
           , replace(c_req_dtls_rec.alt_city,'|','')
           , replace(c_req_dtls_rec.alt_state,'|','')
           , replace(c_req_dtls_rec.alt_zip,'|','')
           , replace(c_req_dtls_rec.aops_alt_country,'|','')
           , NULL
           , replace(c_req_dtls_rec.delivery_document_type,'|','')
           , replace(c_req_dtls_rec.print_invoice,'|','')
           , replace(c_req_dtls_rec.display_back_order,'|','')
           , replace(c_req_dtls_rec.rename_packing_list,'|','')
           , replace(c_req_dtls_rec.display_purchase_order,'|','')
           , replace(c_req_dtls_rec.display_payment_method,'|','')
           , replace(c_req_dtls_rec.display_prices,'|','')
           , replace(c_req_dtls_rec.payment_method,'|','')
           , NULL
           , replace(c_req_dtls_rec.parent_id,'|','')
           , NULL
           , replace(c_req_dtls_rec.afax,'|','')
           , replace(c_req_dtls_rec.substitutions,'|','')
           , replace(c_req_dtls_rec.fax_order,'|','')
           , replace(c_req_dtls_rec.back_orders,'|','')
           , replace(c_req_dtls_rec.po_validated,'|','')
           , replace(c_req_dtls_rec.department_validated,'|','')
           , replace(c_req_dtls_rec.release_validated,'|','')
           , replace(c_req_dtls_rec.desktop_validated,'|','')
           , replace(c_req_dtls_rec.price_plan,'|','')
           , replace(c_req_dtls_rec.gp_floor_percentage,'|','')
           , replace(c_req_dtls_rec.xref,'|','')
           , replace(c_req_dtls_rec.off_contract_code,'|','')
           , replace(c_req_dtls_rec.off_contract_percentage,'|','')
           , replace(c_req_dtls_rec.off_wholesale_code,'|','')
           , replace(c_req_dtls_rec.wholesale_percentage,'|','')
           , NULL
           , NULL
           , replace(c_req_dtls_rec.tax_exempt,'|','')
           , NULL
           , NULL
           , NULL
           , replace(c_req_dtls_rec.po_header,'|','')
           , replace(c_req_dtls_rec.release_header,'|','')
           , replace(c_req_dtls_rec.department_header,'|','')
           , replace(c_req_dtls_rec.desktop_header,'|','')
           , NULL
           , NULL
           , NULL
           , NULL
           , c_req_dtls_rec.party_id -- this has been chnaged from Party Number to Party ID
           , c_req_dtls_rec.bill_to_site_id -- this has been changed from Site Number to Site ID
           , decode(c_req_dtls_rec.ship_to_site_id
	           ,c_req_dtls_rec.bill_to_site_id
		   ,NULL
		   ,c_req_dtls_rec.ship_to_site_id) -- this has been changed from Site Number to Site ID
           , NULL
           , NULL
           , NULL
           , replace(c_req_dtls_rec.comments,'|','')
           , replace(c_req_dtls_rec.status,'|','')
           , replace(c_req_dtls_rec.status_transition_date,'|','')
           , NULL
           , replace(c_req_dtls_rec.tin_number,'|','')
	   , replace(c_req_dtls_rec.ap_contact,'|','')
           , replace((select lookup_code from fnd_lookup_values where lookup_type='Customer Segmentation' and enabled_flag='Y' and TRUNC(sysdate) BETWEEN TRUNC(nvl(start_date_active, sysdate)) AND TRUNC(nvl(end_date_active, sysdate )) and meaning = c_req_dtls_rec.attribute14),'|','')
           , replace((select lookup_code from fnd_lookup_values where lookup_type='Customer Loyalty' and enabled_flag='Y' and TRUNC(sysdate) BETWEEN TRUNC(nvl(start_date_active, sysdate)) AND TRUNC(nvl(end_date_active, sysdate )) and  meaning = c_req_dtls_rec.attribute15),'|','')           
           , l_up_prog_codes);
       -----------------------------------------------------------------------
       ---                      PHONE DETAILS                              ---
       -- Get Phone details associated with the Party                       --
       -- Update to the interface table                                     --
       -----------------------------------------------------------------------

      BEGIN
  
         SELECT phone_number
               ,contact_point_id
	       ,subject_id
           INTO lc_phone_number
               ,ln_phone_contact_point_id
	       ,ln_subject_id
	   FROM
               (SELECT HCP.contact_point_id
                     , HCP.owner_table_id
                     , HCP.phone_area_code || HCP.phone_number phone_number
                     , HCP.primary_flag
		     , HR.subject_id
               FROM  hz_org_contacts        HOC
                   , hz_relationships       HR
                   , hz_contact_points      HCP
              WHERE 
                    HOC.party_relationship_id = HR.relationship_id
                AND HR.party_id               = HCP.owner_table_id
                AND HCP.owner_table_name      = 'HZ_PARTIES' 
                AND HCP.contact_point_type    = 'PHONE'
                AND HCP.phone_line_type       = 'GEN'
                AND HCP.status                = 'A'
                AND HR.subject_type           = 'PERSON'
		AND HOC.org_contact_id        = c_req_dtls_rec.ap_contact 
           ORDER BY primary_flag DESC)
          WHERE rownum < 2;

         UPDATE xx_cdh_account_setup_req_intf
            SET phone_number = replace(lc_phone_number,'|','')
              , c_phone      = replace(lc_phone_number,'|','')
              , phone_id     = ln_phone_contact_point_id
         WHERE request_id = c_req_dtls_rec.request_id
           AND c_internid = c_req_dtls_rec.party_id;
      
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_002_PHONE_ERROR');
          lc_token       := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;
          
          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_002_PHONE_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);
      WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_002_PHONE_ERROR');
          lc_token   := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;

          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_002_PHONE_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);
      END;

       -----------------------------------------------------------------------
       ---                      PERSON DETAILS                             ---
       -- To fetch contact person name and person party ID                  --
       -- Update to the interface table                                     --
       -----------------------------------------------------------------------

      BEGIN    
	SELECT person_first_name||' '||person_last_name
	        ,party_id
           INTO ln_contact_name
	       ,ln_person_party_id
           FROM hz_parties 
          WHERE party_id = ln_subject_id;

         UPDATE xx_cdh_account_setup_req_intf
            SET a_acctspay_cntct = replace(ln_contact_name,'|','')
	      , ap_contact_num   = ln_person_party_id
         WHERE request_id = c_req_dtls_rec.request_id
           AND c_internid = c_req_dtls_rec.party_id;
     
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_010_PERSON_ERROR');
          lc_token       := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_010_PERSON_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);
      WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_010_PERSON_ERROR');
          lc_token   := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_010_PERSON_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);
      END;

       -----------------------------------------------------------------------
       ---                      FAX DETAILS                                ---
       -- Get Fax details associated with the Party                         --
       -- Update to the interface table                                     --
       -----------------------------------------------------------------------
   
      BEGIN
         SELECT phone_number
               ,contact_point_id
           INTO lc_fax_number
               ,ln_fax_contact_point_id
           FROM
               (SELECT HCP.contact_point_id
              , HCP.owner_table_id
              , HCP.phone_area_code || HCP.phone_number phone_number
              , HCP.primary_flag
               FROM  hz_org_contacts        HOC
                   , hz_relationships       HR
                   , hz_contact_points      HCP
              WHERE 
                    HOC.party_relationship_id = HR.relationship_id
                AND HR.party_id               = HCP.owner_table_id
                AND HCP.owner_table_name      = 'HZ_PARTIES' 
                AND HCP.contact_point_type    = 'PHONE'
                AND HCP.phone_line_type       = 'FAX'
                AND HCP.status                = 'A'
                AND HR.subject_type           = 'PERSON'
		AND HOC.org_contact_id        = c_req_dtls_rec.ap_contact 
           ORDER BY primary_flag DESC)
          WHERE rownum < 2;
         UPDATE xx_cdh_account_setup_req_intf
            SET c_fax      = replace(lc_fax_number,'|','')
              , fax_id     = ln_fax_contact_point_id
         WHERE request_id = c_req_dtls_rec.request_id
           AND c_internid = c_req_dtls_rec.party_id;
      
      EXCEPTION
	WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_003_FAX_ERROR');
          lc_token       := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_003_FAX_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);

      WHEN TOO_MANY_ROWS THEN
FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_003_FAX_ERROR');
          lc_token   := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;

          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_003_FAX_ERROR'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);
      END;

       -----------------------------------------------------------------------
       ---                  ORACLE SALES REP ID                            ---
       -- Get oracle sales rep id associated to the party site              --
       -- Sales rep must belongs to 'BSD' division and 'BDM' account        --
       -----------------------------------------------------------------------

      BEGIN
      ln_bsd_rep_found := 0;

      BEGIN
    -- Check if BSD BDM is assigned to any of the party sites
     SELECT resource_id
           ,resource_role_id
           ,group_id
      INTO ln_resource_id
           ,ln_resource_role_id
           ,ln_resource_group_id
      FROM
          (SELECT /*+ parallel(hps 4) */
                  hps.party_site_id,
                  terr.resource_id,
                  terr.resource_role_id,
                  terr.group_id,
                  legrep.legacy_rep_id
           FROM    hz_party_sites hps
                 ,( SELECT /*+ ordered */
                           terr.named_acct_terr_id  ,
                           terr_ent.entity_type     ,
                           terr_ent.entity_id       ,
                           terr_rsc.resource_id     ,
                           terr_rsc.resource_role_id,
                           terr_rsc.GROUP_ID        ,
                           terr_ent.full_access_flag
                    FROM    xx_tm_nam_terr_rsc_dtls     terr_rsc,
                           xx_tm_nam_terr_defn           terr        ,
                           xx_tm_nam_terr_entity_dtls  terr_ent
                    WHERE   terr.named_acct_terr_id       = terr_rsc.named_acct_terr_id
                      AND   terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id
                      AND   terr_ent.named_acct_terr_id = terr.named_acct_terr_id
                      AND   SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE     - 1) AND NVL (terr.end_date_active, SYSDATE + 1)
                      AND   SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1)
                      AND   SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1)
                      AND   NVL (terr.status, 'A')     = 'A'
                      AND   NVL (terr_ent.status, 'A') = 'A'
                      AND   NVL (terr_rsc.status, 'A') = 'A')         terr,
                 (SELECT    mr.resource_id, 
                            mr.role_id,
                            mr.group_id,
                            jrrr.attribute15 legacy_rep_id
                     FROM   jtf_rs_group_mbr_role_vl mr,
                            jtf_rs_role_relations jrrr,
                            jtf_rs_role_details_vl JTR
                     WHERE    
                            jrrr.role_resource_id= mr.group_member_id
                        AND jrrr.role_id = jtr.role_id
                        AND JTR.attribute15 = 'BSD'
                        AND JTR.attribute14 = 'BDM'
                        AND jrrr.attribute15 is not null) legrep
        WHERE hps.party_id = c_req_dtls_rec.party_id
          AND terr.entity_type     ='PARTY_SITE'
          AND terr.entity_id =  hps.party_site_id
          AND legrep.resource_id = terr.resource_id
          AND legrep.group_id = terr.group_id
          AND legrep.role_id = terr.resource_role_id
        ORDER BY HPS.identifying_address_flag DESC)
      WHERE rownum < 2;
      EXCEPTION WHEN OTHERS THEN
      ln_resource_id       := NULL;
      ln_resource_role_id  := NULL;
      ln_resource_group_id := NULL;
      END;
  IF ln_resource_id IS NULL THEN
       -- Check if any BSD is assigned to the any party sites of the party, identifying takes precedence
      BEGIN
    -- Check if any BSD Rep is assigned to any of the party sites
     SELECT resource_id
           ,resource_role_id
           ,group_id
      INTO ln_resource_id
           ,ln_resource_role_id
           ,ln_resource_group_id
      FROM
          (SELECT /*+ parallel(hps 4) */
                  hps.party_site_id,
                  terr.resource_id,
                  terr.resource_role_id,
                  terr.group_id,
                  legrep.legacy_rep_id
           FROM    hz_party_sites hps
                 ,( SELECT /*+ ordered */
                           terr.named_acct_terr_id  ,
                           terr_ent.entity_type     ,
                           terr_ent.entity_id       ,
                           terr_rsc.resource_id     ,
                           terr_rsc.resource_role_id,
                           terr_rsc.GROUP_ID        ,
                           terr_ent.full_access_flag
                    FROM    xx_tm_nam_terr_rsc_dtls     terr_rsc,
                           xx_tm_nam_terr_defn           terr        ,
                           xx_tm_nam_terr_entity_dtls  terr_ent
                    WHERE   terr.named_acct_terr_id       = terr_rsc.named_acct_terr_id
                      AND   terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id
                      AND   terr_ent.named_acct_terr_id = terr.named_acct_terr_id
                      AND   SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE     - 1) AND NVL (terr.end_date_active, SYSDATE + 1)
                      AND   SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1)
                      AND   SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1)
                      AND   NVL (terr.status, 'A')     = 'A'
                      AND   NVL (terr_ent.status, 'A') = 'A'
                      AND   NVL (terr_rsc.status, 'A') = 'A')         terr,
                 (SELECT    mr.resource_id, 
                            mr.role_id,
                            mr.group_id,
                            jrrr.attribute15 legacy_rep_id
                     FROM   jtf_rs_group_mbr_role_vl mr,
                            jtf_rs_role_relations jrrr,
                            jtf_rs_role_details_vl JTR
                     WHERE    
                            jrrr.role_resource_id= mr.group_member_id
                        AND jrrr.role_id = jtr.role_id
                        AND JTR.attribute15 = 'BSD'
                        AND jrrr.attribute15 is not null) legrep
        WHERE hps.party_id = c_req_dtls_rec.party_id
          AND terr.entity_type     ='PARTY_SITE'
          AND terr.entity_id =  hps.party_site_id
          AND legrep.resource_id = terr.resource_id
          AND legrep.group_id = terr.group_id
          AND legrep.role_id = terr.resource_role_id
        ORDER BY HPS.identifying_address_flag DESC)
      WHERE rownum < 2;
      EXCEPTION WHEN OTHERS THEN
      ln_resource_id       := NULL;
      ln_resource_role_id  := NULL;
      ln_resource_group_id := NULL;
      END;
 END IF;  

	  -----------------------------------------------------------------------
          ---                  LEGACY SALES REP                               ---
          -- Get legacy sales id from oracle sales rep id                      --
          -- Get sales rep's other details like name, phone and email          --
          -----------------------------------------------------------------------
          --Changes: Modified Legacy Rep Info derivation logic. JUL 15, 2008.
	  SELECT get_legacy_rep_id(ln_resource_id
	                          ,ln_resource_role_id
                                  ,ln_resource_group_id) leg_rep_id
                , nvl(JRRE.source_name, 'NULL') rep_name
                , JRRE.source_phone rep_phone
                , JRRE.source_email rep_email
            INTO lc_legacy_rep_id
                ,lc_rep_name
                ,lc_rep_phone
                ,lc_rep_email
            FROM jtf_rs_resource_extns JRRE
            WHERE JRRE.resource_id = ln_resource_id
              AND TRUNC(sysdate) BETWEEN TRUNC(nvl(JRRE.start_date_active,sysdate)) AND TRUNC(nvl(JRRE.end_date_active,sysdate));

          -----------------------------------------------------------------------
	  ---                  LEGACY DSM ID                                  ---
	  -- Get legacy DSM id                                                 --
	  -----------------------------------------------------------------------
          --Changes: Modified Legacy DSM Info derivation logic. JUL 15, 2008.
	  BEGIN
	     SELECT get_legacy_rep_id(JRGMR.resource_id
		  		     ,JRGMR.role_id
				     ,ln_resource_group_id) leg_rep_id
		     , nvl(JRRE.source_name, 'NULL') dsm_name
		INTO lc_dsm_rep_id
		    ,lc_dsm_rep_name
		FROM jtf_rs_group_mbr_role_vl JRGMR
		   , jtf_rs_roles_vl JRRV
		   , jtf_rs_resource_extns JRRE
		   , jtf_rs_groups_vl JRGV
		WHERE JRGMR.resource_id = JRRE.resource_id
		  AND JRGMR.role_id = JRRV.role_id
		  AND JRGV.group_id = JRGMR.group_id
		  AND nvl(JRGMR.manager_flag, 'N') = 'Y'
		  AND JRRV.role_type_code = 'SALES'
		  AND TRUNC(sysdate) BETWEEN TRUNC(nvl(JRGMR.start_date_active, sysdate)) AND TRUNC(nvl(JRGMR.end_date_active, sysdate ))
		  AND TRUNC(sysdate) BETWEEN TRUNC(nvl(JRRE.start_date_active, sysdate )) AND TRUNC(nvl(JRRE.end_date_active, sysdate ))
		  AND JRGV.group_id = ln_resource_group_id;
          EXCEPTION
	  WHEN OTHERS THEN
lc_dsm_rep_id := NULL;
               lc_dsm_rep_name := NULL;
          END;

	  -----------------------------------------------------------------------
          ---                          UPDATE                                 ---
          -- Update legacy sales rep details and DSM details to the intf table --
          -----------------------------------------------------------------------
         UPDATE xx_cdh_account_setup_req_intf
            SET r_rep_id        = replace(lc_legacy_rep_id,'|','')
              , r_name          = replace(lc_rep_name,'|','')
              , r_phone         = replace(lc_rep_phone,'|','')
              , sales_rep_email = replace(lc_rep_email,'|','')
              , d_name          = replace( lc_dsm_rep_name,'|','')
              , r_dsm_id        = replace(lc_dsm_rep_id,'|','')
          WHERE request_id = c_req_dtls_rec.request_id
            AND c_internid = c_req_dtls_rec.party_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_004_LGCY_SALES_REP');
          lc_token       := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;

          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_004_LGCY_SALES_REP'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);


      WHEN TOO_MANY_ROWS THEN
FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_ACCT_004_LGCY_SALES_REP');
          lc_token       := c_req_dtls_rec.request_id;
          FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
          lc_err_desc    := FND_MESSAGE.GET;

          XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_004_LGCY_SALES_REP'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MEDIUM'
			);

     END;
      Commit;
    
    END LOOP;
    Commit;

          -----------------------------------------------------------------------
          ---                          UPDATE                                 ---
          -- Update request status as "BPEL Transmission Initiated"            --
          -----------------------------------------------------------------------

    FND_MESSAGE.SET_NAME ('XXCRM', 'XX_CRM_ACCT_009_UPD_INITSTATUS');
    lc_err_desc            := FND_MESSAGE.GET;
    lc_error_message_code  := 'XX_CRM_ACCT_009_UPD_INITSTATUS';

    UPDATE xx_cdh_account_setup_req XCASR
       SET status = 'BPEL Transmission Initiated'
     WHERE EXISTS (SELECT request_id
                     FROM xx_cdh_account_setup_req_intf XCASRI
                    WHERE XCASRI.batch_id   = ln_batch_id
        AND XCASRI.request_id = XCASR.request_id);
    Commit;
 
    x_batch_id := ln_batch_id;
    x_status  := 'Success';
    x_message := 'Procedure completed successfully';
  
  EXCEPTION
  WHEN OTHERS THEN
     x_status    := 'Error';
     x_message   := SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000);
     lc_err_desc := SUBSTR(lc_err_desc,1,4000);
     XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  lc_error_message_code
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MAJOR'
			);


  END get_request;

-- +===================================================================+
-- | Name             : DELETE INTERFACE TABLE                         |
-- | Description      : This procedure deletes records from the        |
-- |                    interface table corresponding to the input     |
-- |                    batch id                                       |
-- |                                                                   |
-- | Parameters :      p_batch_id                                      |
-- |                   x_status                                        |
-- |                   x_message                                       |
-- +===================================================================+

  PROCEDURE Delete_Intf_Table (p_batch_id  IN  NUMBER
                              ,x_status    OUT VARCHAR
                              ,x_message   OUT VARCHAR)
  IS
  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------
  lc_err_desc               xx_com_error_log.error_message%TYPE DEFAULT ' ';
  lc_application_name       xx_com_error_log.application_name%TYPE  := 'XXCRM';
  lc_program_type           xx_com_error_log.program_type%TYPE      := 'E0806_SalesCustomerAccountCreation';
  lc_program_name           xx_com_error_log.program_name%TYPE      := 'XX_CDH_ACCT_CREATION_INTF_PKG';
  lc_module_name            xx_com_error_log.module_name%TYPE       := 'SFA';
  lc_error_location         xx_com_error_log.error_location%TYPE    := 'DELETE_INTF_TABLE';
   

  BEGIN
    
    DELETE xx_cdh_account_setup_req_intf
     WHERE batch_id = p_batch_id;
    
    COMMIT;
    x_status  := 'Success';
    x_message := 'Procedure completed successfully';
  
  EXCEPTION
  WHEN OTHERS THEN

     FND_MESSAGE.SET_NAME ('XXCRM', 'XX_CRM_ACCT_005_DEL_INTF_TABLE');
     lc_err_desc    := FND_MESSAGE.GET;
     XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_005_DEL_INTF_TABLE'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MAJOR'
			);     
     x_status  := 'Error';
     x_message :=  lc_err_desc;

  END;  


   -- +===================================================================+
   -- | Name             : GET_LEGACY_REP_ID                              |
   -- | Description      : This function get legacy sales representive ID |
   -- |                                                                   |
   -- | Parameters :      P_Sales_Rep_ID                                  |
   -- |                   P_Group_ID                                      |
   -- |                                                                   |
   -- | Returns    :      lc_legacy_rep_id                                |
   -- |                                                                   |
   -- +===================================================================+

  FUNCTION get_legacy_rep_id(p_sales_rep_id IN NUMBER
                            ,p_role_id      IN NUMBER         
			    ,p_group_id     IN NUMBER) 
  RETURN VARCHAR2 IS lc_legacy_rep_id VARCHAR2(100);

  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------
  lc_err_desc               xx_com_error_log.error_message%TYPE DEFAULT ' ';
  lc_application_name       xx_com_error_log.application_name%TYPE  := 'XXCRM';
  lc_program_type           xx_com_error_log.program_type%TYPE      := 'E0806_SalesCustomerAccountCreation';
  lc_program_name           xx_com_error_log.program_name%TYPE      := 'XX_CDH_ACCT_CREATION_INTF_PKG';
  lc_module_name            xx_com_error_log.module_name%TYPE       := 'SFA';
  lc_error_location         xx_com_error_log.error_location%TYPE    := 'GET_LEGACY_REP_ID';
  lc_token                  VARCHAR2(4000);
  
  BEGIN
  
         -----------------------------------------------------------------------
    ---                  LEGACY SALES REP AND DSM ID                    ---
    -- Get legacy sales rep id and DSM id from oracle resource id        --
    -----------------------------------------------------------------------
          
    SELECT JRRR.attribute15 legacy_rep_id
      INTO lc_legacy_rep_id   
      FROM jtf_rs_role_relations JRRR
         , jtf_rs_group_members_vl JTGM
     WHERE JRRR.role_resource_type = 'RS_GROUP_MEMBER'
       AND JRRR.role_resource_id = JTGM.group_member_id
       AND JTGM.group_id = p_group_id
       AND nvl(JTGM.delete_flag, 'N') = 'N'
       AND nvl(JRRR.delete_flag, 'N') = 'N'
       AND TRUNC(sysdate) BETWEEN TRUNC(nvl(JRRR.start_date_active, sysdate )) AND TRUNC(nvl(JRRR.end_date_active, sysdate ))
       AND JTGM.resource_id = p_sales_rep_id 
       AND JRRR.role_id = p_role_id  --Considering Role in addition to resource and grp id, JUL 15 2008.
       AND JRRR.attribute15 IS NOT NULL 
       AND rownum < 2;

    RETURN lc_legacy_rep_id;

    EXCEPTION
  WHEN OTHERS THEN
     lc_legacy_rep_id := NULL;
     FND_MESSAGE.SET_NAME ('XXCRM', 'XX_CRM_ACCT_006_LGCY_REP_ID');
     lc_token      := p_sales_rep_id;
     FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
     lc_err_desc    := FND_MESSAGE.GET;
     XX_COM_ERROR_LOG_PUB.log_error_crm
			( p_application_name        =>  lc_application_name
			, p_program_type            =>  lc_program_type
			, p_program_name            =>  lc_program_name
			, p_module_name             =>  lc_module_name
			, p_error_location          =>  lc_error_location
			, p_error_message_code      =>  'XX_CRM_ACCT_006_LGCY_REP_ID'
			, p_error_message           =>  SUBSTR(lc_err_desc||'=>'||SQLERRM,1,4000)
			, p_error_message_severity  =>  'MAJOR'
			);  
     RETURN lc_legacy_rep_id;			
  END;

END XX_CDH_ACCT_CREATION_INTF_PKG;

/

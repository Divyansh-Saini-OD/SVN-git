SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT 'Creating Procedure XX_AR_DUNNING_PROC'

CREATE OR REPLACE PROCEDURE XX_AR_DUNNING_PROC
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- | Name :      XX_AR_DUNNING_PROC                                                     |
-- | Description : Sending dunning letters to the customer                              |
-- |               those who have not paid their balance amount.                        |
-- |               It will send the letters in the Office Depot format                  |
-- |               to the customers.                                                    |
-- |                                                                                    |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       12-APR-2007  Vijayabaskaran        Initial version                        |
-- |1.1       18-DEC-2007  Subbarao Bangaru      Update added                           |
-- |1.2       10-JUL-2008  Anitha Devarajulu     Change the tables to                   |
-- |                                             base tables for Defect 8700            |
-- |1.3       12-JUL-2008  Ram Nathan            Added table                            |
-- |                                             hr_operating_units for                 |
-- |                                             defect 8889                            |
-- |1.4       12-JUL-2008  Ram Nathan            Added translation table                |
-- |                                             for defect 8756                        |
-- |1.5       26-JUL-2008  Ram Nathan            Added GROUP BY clause                  |
-- |                                             for defect 9183                        |
-- |1.6       31-JUL-2008  Subbarao Bangaru      Changed query for cust_fax             |
-- |                                             to get fax no as always we             |
-- |                                             have only contact with fax             |
-- |                                             and DUNNING Role                       |
-- |1.7       08-AUG-2008  Ram Nathan            Modified query to exclude              |
-- |                                             0$ amounts for defect 9673             |
-- |1.8       14-Aug-08    Hari Mukkoti          Modified query to elemenate            |
-- |                                             full dispute for Defect 8891           |
-- |1.9       25-Aug-08    Anitha Devarajulu     Modified for Defect 9605               |
-- |2.0       04-Sep-08    Rama Krishna K        Addressed defect 8891                  |
-- |2.1       08-Sep-08    Hari Mukkoti          Fetching Singile Record                |
-- |                                             based on Dunning and                   |
-- |                                             Primary key flag Y                     |
-- |                                             for Defect 10716                       |
-- |2.2       27-Aug-08    Anitha Devarajulu     Modified for Defect 2114               |
-- |2.3       18-Nov-09    Usha Ramachandran     Modified for Defect 2807               |
-- |2.4       01-Nov-10    Jude Felix Antony     Modified the query for checking        |
-- |                                             whether the individual invoice         |
-- |                                             is not in consolidate 6955             |
-- |2.5       23-Nov-15    Vasu Raparla          Removed Schema Refererences for R12.2  |
-- +====================================================================================+
    IS
        CURSOR c_od_xml_temp IS
            SELECT *
            FROM xdo_templates_vl
            WHERE template_code
            IN ('ODIEXDNL1','ODIEXDNL2','ODIEXDNL3','ODIEXDNL4','ODIEXDNL5',
                'ODIEXDNL_FAX1','ODIEXDNL_FAX2','ODIEXDNL_FAX3','ODIEXDNL_FAX4','ODIEXDNL_FAX5' );

    ln_query_id    NUMBER;
    lc_statement   CLOB;
    ln_count       NUMBER := 0;
    ln_found       NUMBER := 0;
    ln_update      NUMBER := 0;
    lc_query_id_up iex_query_temp_xref.QUERY_ID%TYPE;

    BEGIN

       FND_CLIENT_INFO.SET_ORG_CONTEXT(fnd_profile.value('ORG_ID'));

    lc_statement := 'SELECT'
        ||' RAC.customer_name first_name'
        ||', ACPV.cons_inv_flag cons_inv_flag'
    --    ||', ACPV.site_use_id billto_site' -- Commented for Defect 2114
        ||', HPS.party_site_number ||'' / ''||HCSUA.location billto_site'-- Defect 2114
        ||', RS.source_first_name || '' '' || RS.source_last_name collector_name'
        ||', RS.source_job_title collector_title'
        ||', RS.source_phone collector_phone'
        ||', RS.source_email collector_email'
        ||', RAC.customer_number customer_number'
        ||', SUBSTR(RAC.orig_system_reference,1,8) legacy_cust_number'
        ||', (SELECT source_value1'
        ||'   FROM   xx_fin_translatedefinition XXTD'
        ||'        , xx_fin_translatevalues XXTV'
        ||'   WHERE   XXTD.translate_id=XXTV.translate_id'
        ||'   AND     XXTD.translation_name=''XX_AR_DUNNING_COLL_CON'') dept_name' -- Defect 8756
        ||', (SELECT source_value2'
        ||'   FROM   xx_fin_translatedefinition XXTD'
        ||'        , xx_fin_translatevalues XXTV'
        ||'   WHERE   XXTD.translate_id=XXTV.translate_id'
        ||'   AND     XXTD.translation_name=''XX_AR_DUNNING_COLL_CON'') phone_number' -- Defect 8756
        ||', (SELECT source_value3'
        ||'   FROM   xx_fin_translatedefinition XXTD'
        ||'        , xx_fin_translatevalues XXTV'
        ||'   WHERE   XXTD.translate_id=XXTV.translate_id'
        ||'   AND     XXTD.translation_name=''XX_AR_DUNNING_COLL_CON'') fax_number' -- Defect 8756
        ||'  ,( SELECT HCP.phone_country_code||HCP.phone_area_code||HCP.Phone_number ' -- Added for the Defect 8684
        ||' FROM   hz_cust_site_uses_all HCSU '
        ||'       ,hz_cust_acct_sites_all HCAS '
        ||'       ,hz_cust_account_roles  HCAR '
        ||'       ,hz_contact_points HCP '
        ||'       ,hz_role_responsibility HRR '
        ||' WHERE  HCSU.site_use_id = :CUSTOMER_SITE_USE_ID '
        ||' AND    HCAS.cust_acct_site_id=HCSU.cust_acct_site_id ' 
        ||' AND    HCSU.cust_acct_site_id = HCAR.cust_acct_site_id '
        ||' AND    HCP.owner_table_id = HCAR.party_id '
        ||' AND    HCAR.cust_account_role_id   = HRR.cust_account_role_id '
        ||' AND    HCSU.site_use_code = ''BILL_TO'''
        ||' AND    HCAS.status = ''A'''
        ||' AND    HCP.status  = ''A'''
        ||' AND    HCAR.current_role_State = ''A'''
        ||' AND    HCP.phone_line_type = ''FAX'''
        ||' AND    HCP.contact_point_purpose = ''DUNNING''' 
        ||' AND    HRR.primary_flag = ''Y'''
        ||' AND    HRR.responsibility_type = ''DUN'''
        ||' AND    HCSU.site_use_id  = :CUSTOMER_SITE_USE_ID) cust_fax ' --Defect 10716
   /*   ||', (SELECT AP.country_code||RP.area_code||RP.phone_number' -- Commented for the Defect 8684
        ||'   FROM   ra_phones RP'
        ||'         ,ar_phones_v AP'
        ||'         ,hz_cust_site_uses_all HCSU' -- Defect 8700
        ||'   WHERE  RP.address_id = HCSU.cust_acct_site_id'
        ||'   AND    RP.phone_id = AP.phone_id'
        ||'   AND    HCSU.site_use_code = ''BILL_TO'''
        ||'   AND    RP.phone_type = ''FAX'''
        ||'   AND    RP.status = ''A'''
        ||'   AND    RP.contact_id IN (SELECT contact_id FROM ar_contacts_v WHERE contact_party_id = PER.party_id)'
        ||'   AND    HCSU.site_use_id  = :CUSTOMER_SITE_USE_ID) cust_fax' */
        ||', (SELECT'
        ||' TO_CHAR(MAX(ISWT.execute_end),''MM-DD-YYYY'')'
        ||' FROM'
        ||' iex_strategy_work_items ISWT'
        ||' , iex_strategies IEXS'
        ||' WHERE'
        ||' IEXS.cust_account_id = :ACCOUNT_ID'
        ||' AND IEXS.status_code = ''OPEN'''
        ||' AND IEXS.strategy_template_id = ISWT.strategy_temp_id'
        ||' AND IEXS.strategy_id = ISWT.strategy_id'
        ||' AND ISWT.status_code = ''COMPLETE'''
        ||' ) dunning_date '
        ||', CURSOR'
        ||' (SELECT'
        ||' CT.trx_number invoice_number'
        ||', CT.interface_header_attribute1 aops_order_number'
        ||', to_char(AR.due_date, ''MM-DD-YYYY'') due_date'
        ||', AR.amount_due_remaining amount_due_remaining'
        ||', CT.purchase_order purchase_order'
        ||', to_char(CT.trx_date, ''MM-DD-YYYY'') trx_date'
        ||', D.cust_account_id account_id'
        ||', HROU.name ou_name'  -- Defect 8889
        ||', (SELECT'
        ||' SUM(aps.amount_due_remaining)'
        ||' FROM'
        ||' iex_delinquencies_all DD' -- Defect 8700
        ||', ar_payment_schedules_all APS' -- Defect 8700
        ||', ra_customer_trx_all ct' --Defect 8891
        ||', hr_operating_units hrou' --Defect 8891
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND ct.org_id = hrou.organization_id'  --Defect 8891
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.status = ''DELINQUENT''' --Defect 8891
        ||' AND aps.customer_trx_id = ct.customer_trx_id' --Defect 8891
        ||' AND ct.org_id = hrou.organization_id' --Defect 8891
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
--Start of changed for Defect 6955
--      ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_remaining'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID'
        ||' AND NOT EXISTS (SELECT 1'
        ||' FROM AR_CONS_INV_TRX_ALL ACITA '
        ||' WHERE ACITA.CUSTOMER_TRX_ID = CT.customer_trx_id)) total_amount_due_remaining'
--End of changed for Defect 6955
        ||', (SELECT'
        ||' SUM(APS.amount_due_original)'
        ||' FROM'
        ||' iex_delinquencies_all DD' -- Defect 8700
        ||', ar_payment_schedules_all APS' -- Defect 8700
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_original'
        ||' FROM'
        ||' iex_delinquencies_all D' -- Defect 8700
        ||', ar_payment_schedules_all AR' -- Defect 8700
        ||', ra_customer_trx_all CT' -- Defect 8700
        ||',hr_operating_units HROU' -- Defect 8889
        ||' WHERE'
        ||' D.party_cust_id = ORG.party_id'
        ||' AND D.cust_account_id = :ACCOUNT_ID'
        ||' AND D.payment_schedule_id = AR.payment_schedule_id'
        ||' AND CT.org_id=HROU.organization_id' -- Defect 8889
        ||' AND D.status = ''DELINQUENT'''
        ||' AND AR.customer_trx_id = CT.customer_trx_id'
        ||' AND D.customer_site_use_id = :CUSTOMER_SITE_USE_ID'
--Start of changed for Defect 6955
        ||' AND NOT EXISTS (SELECT 1'
        ||' FROM AR_CONS_INV_TRX_ALL ACITA '
        ||' WHERE ACITA.CUSTOMER_TRX_ID = CT.customer_trx_id)'
--End of changed for Defect 6955
        ||' AND AR.amount_due_remaining <> 0' -- Defect 9673
        ||' ORDER BY'                                  --Added for Defect 2807
        ||' trx_date'
        ||',invoice_number'
        ||' ) AS payment_history'
        || ' , CURSOR'
        ||' (SELECT'
        ||' ACI.cons_billing_number cons_billing_number'
        ||', SUM(AR.amount_due_remaining) amount_due_remaining'
      --||', to_char(AR.due_date, ''MM-DD-YYYY'') due_date'
      --||', CT.purchase_order purchase_order' --Defect 9183
      --||', to_char(CT.trx_date, ''MM-DD-YYYY'') trx_date'
        ||', to_char(ACI.due_date, ''MM-DD-YYYY'') due_date'  -- Defect 9605
        ||', to_char(ACI.issue_date, ''MM-DD-YYYY'') trx_date'  -- Defect 9605
        ||', HROU.name ou_name'  -- Defect 8889
        ||' , (SELECT'
        ||' SUM(APS.amount_due_remaining)'
        ||' FROM'
        ||' iex_delinquencies_all DD' -- Defect 8700
        ||' ,ar_payment_schedules_all APS' -- Defect 8700
        ||' ,ar_cons_inv_all AC' -- Defect 8700
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND AC.cons_inv_id = APS.cons_inv_id'
        ||' AND dd.status = ''DELINQUENT''' -- Defect 8891
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) tot_cons'
        ||', (SELECT'
        ||' SUM(APS.amount_due_original)'
        ||' FROM'
        ||' iex_delinquencies_all DD' -- Defect 8700
        ||', ar_payment_schedules_all APS' -- Defect 8700
        ||', ar_cons_inv_all AC' -- Defect 8700
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND AC.cons_inv_id(+) = APS.cons_inv_id'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_original'
        ||' FROM'
        ||' iex_delinquencies_all D' -- Defect 8700
        ||', ar_payment_schedules_all AR' -- Defect 8700
        ||', ra_customer_trx_all CT' -- Defect 8700
        ||', ar_cons_inv_all ACI' -- Defect 8700
        ||', hr_operating_units HROU' -- Defect 8889
        ||' WHERE'
        ||' D.party_cust_id = ORG.party_id'
        ||' AND D.cust_account_id = :ACCOUNT_ID'
        ||' AND D.payment_schedule_id = AR.payment_schedule_id'
        ||' AND CT.org_id=HROU.organization_id' -- Defect 8889
        ||' AND D.status = ''DELINQUENT'''
        ||' AND AR.customer_trx_id = CT.customer_trx_id'
        ||' AND ACI.cons_inv_id = AR.cons_inv_id'
        ||' AND D.customer_site_use_id = :CUSTOMER_SITE_USE_ID'
        ||' AND AR.amount_due_remaining <> 0' -- Defect 9673
        ||' GROUP BY'      --Defect 9183
        ||' ACI.cons_billing_number'
    --  ||', to_char(AR.due_date, ''MM-DD-YYYY'')'
    --  ||', CT.purchase_order' ---- Defect 9183
    --  ||', to_char(CT.trx_date, ''MM-DD-YYYY'')'
        ||', to_char(ACI.due_date, ''MM-DD-YYYY'')'  -- Defect 9605
        ||', to_char(ACI.issue_date, ''MM-DD-YYYY'')' -- Defect 9605
        ||', HROU.name'
        ||' ORDER BY'                                  --Added for Defect 2807
        ||' trx_date'
        ||',cons_billing_number'
        ||' ) AS consolidate_history'
        ||' FROM'
        ||' hz_locations LOC'
        ||', hz_parties ORG'
        ||', hz_parties PER'
        ||', jtf_rs_resource_extns RS'
        ||', ra_customers RAC'
        ||', ar_customer_profiles_v ACPV'
        ||', hz_party_sites HPS' -- defect 2114
        ||', hz_cust_site_uses_all HCSUA' -- defect 2114
        ||', hz_Cust_Acct_Sites_All HCASA' -- defect 2114
        ||' WHERE'
        ||' LOC.location_id = :LOCATION_ID'
        ||' AND ORG.party_id= :PARTY_ID'
        ||' AND PER.party_id = nvl(:CONTACT_ID, ORG.party_id)'
        ||' AND RS.RESOURCE_ID = :RESOURCE_ID'
        ||' AND ACPV.CUSTOMER_ID = RAC.CUSTOMER_ID'
        ||' AND ORG.PARTY_ID = RAC.PARTY_ID'
        ||' AND ACPV.site_use_id = :CUSTOMER_SITE_USE_ID'
        ||' AND ACPV.site_use_id = HCSUA.site_use_id' -- Defect 2114
        ||' AND HCSUA.cust_acct_site_id = HCASA.cust_acct_site_id' -- Defect 2114
        ||' AND HCASA.party_site_id = HPS.party_site_id';
        


       FOR lcu_od_xml_temp IN c_od_xml_temp  LOOP


       SELECT count(1)
       INTO   ln_found
       FROM   iex_query_temp_xref
       WHERE  template_id = lcu_od_xml_temp.template_id;

       IF (ln_found = 0) THEN -- There are no records found

            SELECT MAX(query_id)+1
            INTO     ln_query_id
            FROM   iex_xml_queries;

            INSERT INTO iex_xml_queries
            (query_id
            ,additional_query
            ,description
            ,start_date
            ,end_date
            ,enabled_flag
            ,object_type
            ,query_level
            ,created_by
            ,creation_date
            ,last_update_date
            ,last_updated_by
            ,last_update_login
            ,object_version_number)
            VALUES
            (ln_query_id
            ,lc_statement
            ,lcu_od_xml_temp.description
            ,SYSDATE
            ,NULL
            ,'Y'
            ,'DUNN'
            ,'BILL_TO'
            ,-1
            ,SYSDATE
            ,SYSDATE
            ,-1
            ,-1
            ,1);

            INSERT INTO iex_query_temp_xref
            (query_temp_id
            ,query_id
            ,template_id
            ,created_by
            ,creation_date
            ,last_update_date
            ,last_updated_by
            ,last_update_login
            ,object_version_number)
            VALUES
            (ln_query_id
            ,ln_query_id
            ,lcu_od_xml_temp.template_id
            ,-1
            ,SYSDATE
            ,SYSDATE
            ,-1
            ,-1
            ,1);

          ln_count := ln_count + 1;


       ELSE -- Update the Records

            SELECT query_id
            INTO   lc_query_id_up
            from iex_query_temp_xref
            where template_id = lcu_od_xml_temp.template_id;


            DBMS_OUTPUT.PUT_LINE('Number of Records Updated in iex_query_temp_xref - '
                                    ||SQL%ROWCOUNT);

            UPDATE iex_xml_queries
            SET    additional_query = lc_statement
                  ,last_update_date = SYSDATE
            WHERE  query_id = lc_query_id_up;

            DBMS_OUTPUT.PUT_LINE('Number of Records Updated in iex_xml_queries - '
                                    ||SQL%ROWCOUNT);

          ln_update := ln_update + 1;

       END IF;

       END LOOP;

      COMMIT;

    DBMS_OUTPUT.PUT_LINE('Number of Records Inserted - '||ln_count);
    DBMS_OUTPUT.PUT_LINE('Number of Records Updated - '||ln_update);

    EXCEPTION
       WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('Error in Procedure - ' || SQLERRM);

END XX_AR_DUNNING_PROC;

/
show error

EXEC XX_AR_DUNNING_PROC;
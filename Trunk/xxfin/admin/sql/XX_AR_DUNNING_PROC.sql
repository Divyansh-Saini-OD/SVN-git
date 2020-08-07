SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT 'Creating Procedure XX_AR_DUNNING_PROC'

CREATE OR REPLACE PROCEDURE XX_AR_DUNNING_PROC
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      XX_AR_DUNNING_PROC                                    |
-- | Description : Sending dunning letters to the customer             |
-- |               those who have not paid their balance amount.       |
-- |               It will send the letters in the Office Depot format |
-- |               to the customers.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       12-APR-2007  Vijayabaskaran        Initial version       |
-- |                                                                   |
-- +===================================================================+
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
        ||', ACPV.site_use_id billto_site'
        ||', RS.source_first_name || '' '' || RS.source_last_name collector_name'
        ||', RS.source_job_title collector_title'
        ||', RS.source_phone collector_phone'
        ||', RS.source_email collector_email'
        ||', RAC.customer_number customer_number'
        ||', SUBSTR(RAC.orig_system_reference,1,8) legacy_cust_number'
        ||', (SELECT AP.country_code||RP.area_code||RP.phone_number'
        ||'   FROM   ra_phones RP'
        ||'         ,ar_phones_v AP'
        ||'         ,hz_cust_site_uses HCSU'
        ||'   WHERE  RP.address_id = HCSU.cust_acct_site_id'
        ||'   AND    RP.phone_id = AP.phone_id'
        ||'   AND    HCSU.site_use_code = ''BILL_TO'''
        ||'   AND    RP.phone_type = ''FAX'''
        ||'   AND    RP.status = ''A'''
        ||'   AND    RP.contact_id IN (SELECT contact_id FROM ar_contacts_v WHERE contact_party_id = PER.party_id)'
        ||'   AND    HCSU.site_use_id  = :CUSTOMER_SITE_USE_ID) cust_fax'
        ||', (SELECT'
        ||' TO_CHAR(MAX(ISWT.execute_end),''DD MON YYYY'')'
        ||' FROM'
        ||' iex_strategy_work_items ISWT'
        ||' , iex_strategies IEXS'
        ||' WHERE'
        ||' IEXS.cust_account_id = :ACCOUNT_ID'
        ||' AND IEXS.status_code = ''OPEN'''
        ||' AND IEXS.strategy_template_id = ISWT.strategy_temp_id'
        ||' AND IEXS.strategy_id = ISWT.strategy_id'
        ||' AND ISWT.status_code = ''COMPLETE'''
        ||' ) dunning_date'
        ||' ,(SELECT'
        ||' meaning'
        ||' FROM'
        ||' ar_lookups'
        ||' WHERE lookup_type  = ''ARDUNNING_FAX'''
        ||' AND lookup_code  = ''DUNNINGFAX'''
        ||' ) collector_fax'
        ||', CURSOR'
        ||' (SELECT'
        ||' CT.trx_number invoice_number'
        ||', CT.interface_header_attribute1 aops_order_number'
        ||', to_char(AR.due_date, ''MM-DD-YYYY'') due_date'
        ||', AR.amount_due_remaining amount_due_remaining'
        ||', CT.purchase_order purchase_order'
        ||', to_char(CT.trx_date, ''MM-DD-YYYY'') trx_date'
        ||', D.cust_account_id account_id'
        ||', (SELECT'
        ||' SUM(aps.amount_due_remaining)'
        ||' FROM'
        ||' iex_delinquencies DD'
        ||', ar_payment_schedules APS'
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_remaining'
        ||', (SELECT'
        ||' SUM(APS.amount_due_original)'
        ||' FROM'
        ||' iex_delinquencies DD'
        ||', ar_payment_schedules APS'
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_original'
        ||' FROM'
        ||' iex_delinquencies D'
        ||', ar_payment_schedules AR'
        ||', ra_customer_trx CT'
        ||' WHERE'
        ||' D.party_cust_id = ORG.party_id'
        ||' AND D.cust_account_id = :ACCOUNT_ID'
        ||' AND D.payment_schedule_id = AR.payment_schedule_id'
        ||' AND D.status = ''DELINQUENT'''
        ||' AND AR.customer_trx_id = CT.customer_trx_id'
        ||' AND D.customer_site_use_id = :CUSTOMER_SITE_USE_ID'
        ||' ) AS payment_history'
        || ' , CURSOR'
        ||' (SELECT'
        ||' ACI.cons_billing_number cons_billing_number'
        ||', to_char(AR.due_date, ''MM-DD-YYYY'') due_date'
        ||', AR.amount_due_remaining amount_due_remaining'
        ||', CT.purchase_order purchase_order'
        ||', to_char(CT.trx_date, ''MM-DD-YYYY'') trx_date'
        ||' , (SELECT'
        ||' SUM(APS.amount_due_remaining)'
        ||' FROM'
        ||' iex_delinquencies DD'
        ||' ,ar_payment_schedules APS'
        ||' ,ar_cons_inv AC'
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND AC.cons_inv_id = APS.cons_inv_id'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_remaining'
        ||', (SELECT'
        ||' SUM(APS.amount_due_original)'
        ||' FROM'
        ||' iex_delinquencies DD'
        ||', ar_payment_schedules APS'
        ||', ar_cons_inv AC'
        ||' WHERE'
        ||' DD.payment_schedule_id = APS.payment_schedule_id'
        ||' AND DD.party_cust_id = ORG.party_id'
        ||' AND DD.cust_account_id = :ACCOUNT_ID'
        ||' AND AC.cons_inv_id = APS.cons_inv_id'
        ||' AND DD.customer_site_use_id = :CUSTOMER_SITE_USE_ID) total_amount_due_original'
        ||' FROM'
        ||' iex_delinquencies D'
        ||', ar_payment_schedules AR'
        ||', ra_customer_trx CT'
        ||', ar_cons_inv ACI'
        ||' WHERE'
        ||' D.party_cust_id = ORG.party_id'
        ||' AND D.cust_account_id = :ACCOUNT_ID'
        ||' AND D.payment_schedule_id = AR.payment_schedule_id'
        ||' AND D.status = ''DELINQUENT'''
        ||' AND AR.customer_trx_id = CT.customer_trx_id'
        ||' AND ACI.cons_inv_id = AR.cons_inv_id'
        ||' AND D.customer_site_use_id = :CUSTOMER_SITE_USE_ID'
        ||' ) AS consolidate_history'
        ||' FROM'
        ||' hz_locations LOC'
        ||', hz_parties ORG'
        ||', hz_parties PER'
        ||', jtf_rs_resource_extns RS'
        ||', ra_customers RAC'
        ||', ar_customer_profiles_v ACPV'
        ||' WHERE'
        ||' LOC.location_id = :LOCATION_ID'
        ||' AND ORG.party_id= :PARTY_ID'
        ||' AND PER.party_id = nvl(:CONTACT_ID, ORG.party_id)'
        ||' AND RS.RESOURCE_ID = :RESOURCE_ID'
        ||' AND ACPV.CUSTOMER_ID = RAC.CUSTOMER_ID'
        ||' AND ORG.PARTY_ID = RAC.PARTY_ID'
        ||' AND ACPV.site_use_id = :CUSTOMER_SITE_USE_ID' ;


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


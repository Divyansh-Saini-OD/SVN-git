CREATE OR REPLACE PACKAGE BODY xx_ar_truncate_wfitems_pkg AS
FUNCTION dunning_check(p_site_use_id IN NUMBER
                       ,p_category_type IN VARCHAR2)
-- +===================================================================+
-- |         Office Depot - Project Simplify                           |
-- |         Wirpo / Office Depot                                      |
-- +===================================================================+
-- | Name  :DUNNING_CHECK                                              |
-- | Description      :  This Funtion will check if dunning set up is  |
-- |                     properly set                                  |
-- |                                                                   |
-- | Parameters :p_site_use_id(customer site use id)                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns : check flag                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 16-Jun-09   Ganesan JV       Initial draft version       |
-- +===================================================================+
RETURN NUMBER
AS
ln_return NUMBER DEFAULT 0;
BEGIN
   SELECT 1
   INTO ln_return
   FROM   apps.hz_cust_site_uses_all HCSU
         ,apps.hz_cust_acct_sites_all HCAS
         ,apps.hz_cust_account_roles  HCAR
         ,apps.hz_contact_points HCP
         ,apps.hz_role_responsibility HRR
   WHERE  1=1
   and    HCSU.site_use_id = p_site_use_id
   AND    HCAS.cust_acct_site_id=HCSU.cust_acct_site_id
   AND    HCSU.cust_acct_site_id = HCAR.cust_acct_site_id
   AND    HCP.owner_table_id = HCAR.party_id
   AND    HCAR.cust_account_role_id   = HRR.cust_account_role_id
   AND    HCSU.site_use_code ='BILL_TO'
   AND    HCAS.status ='A'
   AND    HCP.status  ='A'
   AND    HCAR.current_role_State ='A'
   AND    HCP.contact_point_type = DECODE(p_category_type,'FAX','PHONE','EMAIL','EMAIL')--IN ('EMAIL','PHONE')
   AND    NVL(HCP.phone_line_type,'EMAIL')  IN ('FAX','EMAIL')
   AND    HCP.contact_point_purpose IN ('DUNNING','COLLECTIONS')
   AND    HRR.primary_flag ='Y'
   AND    HCP.primary_flag = 'Y'
   AND    HRR.responsibility_type ='DUN'
   AND    HCSU.site_use_id = p_site_use_id;
--   AND    ROWNUM  < 2;

	RETURN ln_return;
EXCEPTION 
   WHEN NO_DATA_FOUND THEN
      ln_return := 0;
	   RETURN ln_return;
   WHEN TOO_MANY_ROWS THEN
	   ln_return := 1;    -- There can be multiple faxes or email mentioned for a particular contact, eventhough the Front end form is not allowing now. There can be converted data present.
		RETURN ln_return;
   WHEN OTHERS THEN
      ln_return := 0;
	   RETURN ln_return;
END dunning_check;

PROCEDURE truncate_wfitems
AS
-- +===================================================================+
-- |         Office Depot - Project Simplify                           |
-- |         Wirpo / Office Depot                                      |
-- +===================================================================+
-- | Name  :DUNNING_CHECK                                              |
-- | Description      :  This Procedure will delete records which donot|
-- |                     have dunning setup properly done from wf_items|
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 16-Jun-09   Ganesan JV       Initial draft version       |
-- +===================================================================+
 TYPE wf_missing_dun_type IS TABLE OF wf_items%ROWTYPE INDEX BY PLS_INTEGER;
 lt_wf_missing_dun wf_missing_dun_type;

-- Cursor for fetching errored out records
CURSOR lcu_main
IS
 SELECT --dunning_check(IES.customer_site_use_id) DUNNING_CHECK
        WFI.item_type
        ,WFI.item_key
        ,WFI.root_activity
        ,WFI.root_activity_version
        ,WFI.owner_role
        ,WFI.parent_item_type
        ,WFI.parent_item_key
        ,WFI.parent_context
        ,WFI.begin_date
        ,WFI.end_date
        ,WFI.user_key
        ,WFI.ha_migration_flag
        ,WFI.security_group_id
  FROM  iex_strategy_work_items ISWI
       ,iex_stry_temp_work_items_vl ISTWL
       ,apps.wf_items WFI
       ,iex_strategies IES
  WHERE  ISWI.work_item_template_id = ISTWL.work_item_temp_id
    AND  ISWI.work_item_id = WFI.item_key
    AND  ISWI.strategy_id = ies.strategy_id
    AND  WFI.item_type='IEXSTFFM'
    AND  ISWI.status_code = 'INERROR_CHECK_NOTIFY'
	 AND  dunning_check(IES.customer_site_use_id,ISTWL.category_type) = 0; -- Simply like NOT EXISTS, Function Call will indicate some setup miss.

BEGIN
-- errored records
   OPEN lcu_main;
	LOOP
	  FETCH lcu_main
	  BULK COLLECT INTO lt_wf_missing_dun LIMIT 50000;

	  FORALL i IN lt_wf_missing_dun.FIRST..lt_wf_missing_dun.LAST
	    INSERT INTO xx_ar_wf_items
		 VALUES lt_wf_missing_dun(i);

	  FOR j IN lt_wf_missing_dun.FIRST..lt_wf_missing_dun.LAST
	  LOOP
	    DELETE wf_items WFI
		 WHERE WFI.item_key = lt_wf_missing_dun(j).item_key
		   AND  WFI.item_type='IEXSTFFM';
	  END LOOP;

	  EXIT WHEN lcu_main%NOTFOUND;
	END LOOP;
	CLOSE lcu_main;
	COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error Message: '|| SQLCODE || ' :' || SQLERRM);
	 ROLLBACK;
END truncate_wfitems;
END xx_ar_truncate_wfitems_pkg;
/
SHO ERR
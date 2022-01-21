SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE BODY XX_AR_SUBSC_ITEM_REV_REC_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_SUBSC_ITEM_REV_REC_PKG                                                            |
  -- |                                                                                            |
  -- |  Description: This package body is for identifying Subscription Items are eligible 
  --                 for REV REc and insert into XX_AR_SUBSCRIPTION_ITEMS              |
  -- |                                                                                |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         08/Apr/2020   M K Pramod Kumar     Initial version                              |
  -- | 1.1         11/May/2020   M K Pramod Kumar     Added code to derive Cogs,Consignment,Inventory Account|
  -- | 1.2         14/Jul/2020   M K Pramod Kumar     Code Changes to handle if OD_Billing_frequency or OD_CONTRACT_LENGTH is null in rms table |
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_AR_SUBSC_ITEM_REV_REC_PKG';
  gc_translate_id      number;
  gc_max_log_size number:=500;
  
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;

/************************************************
* Helper Function to check if Transaction type and Transaction is Duplicate
************************************************/
FUNCTION CHECK_REV_REC_ITEM(
    p_item   VARCHAR2)
  RETURN VARCHAR2
IS
  lv_is_rev_rec_flag VARCHAR2(1):='N';
  lv_proc_name varchar2(100):='CHECK_REV_REC_ITEM';
BEGIN

  select IS_REV_REC_ELIGIBLE into lv_is_rev_rec_flag from xx_ar_subscription_items
  where item=p_item;  
  RETURN lv_is_rev_rec_flag;
  
Exception 
when others then 
lv_is_rev_rec_flag:='E';
logit('Exception occured in Pacakge-'||gc_package_name||'.'||lv_proc_name||'. SQLCODE'||sqlcode||'.SQLERRM'||sqlerrm );
END CHECK_REV_REC_ITEM;


/**********************************************************************
* Main Procedure to check if Subscription items are Rev Rec Items or not
***********************************************************************/
PROCEDURE MAIN_ITEM_REV_REC_PROCESS(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_ITEM_REV_REC_PROCESS';

  cursor cr_rms_items is select rms.* ,decode(OD_Billing_frequency,'M',1,'A',12,'Q',3,OD_Billing_frequency) no_of_periods 
  From xx_rms_mv_ssb rms
  where OD_Billing_frequency is not null and OD_CONTRACT_LENGTH is not null ;
  
  lc_item_type mtl_system_items_b.item_type%type;
lc_dept mtl_categories_b.segment3%type;
lc_translation_id number;
lc_rev_account varchar2(30):=null;
lc_cogs_account varchar2(30):=null;
lc_cons_account varchar2(30):=null;
lc_inv_account varchar2(30):=null;

lc_master_organization_id number;
lv_inventory_item_id number;
lv_organization_id   number;
lv_IS_REV_REC_ELIGIBLE varchar2(1):='N';
lv_item_count number:=0;
lv_rev_rec_derive_text varchar2(100):=null;

BEGIN
  
    SELECT translate_id
                    INTO lc_translation_id
                    FROM xx_fin_translatedefinition
                   WHERE translation_name = 'SALES ACCOUNTING MATRIX'
                     AND enabled_flag = 'Y'
                     AND (start_date_active <= SYSDATE
                     AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
					 
	SELECT master_organization_id
              INTO lc_master_organization_id
              FROM mtl_parameters
             WHERE organization_id = master_organization_id;			 
					 
	for rec in cr_rms_items loop
	
	lc_item_type:=null;
    lc_dept:=null;
    lc_rev_account:=null;
	lc_cogs_account :=null;
	lc_cons_account :=null;
	lc_inv_account  :=null;
	lv_inventory_item_id:=null;
	lv_organization_id:=null;
	lv_rev_rec_derive_text:=null;
	Begin
		SELECT MSIB.item_type,inventory_item_id,organization_id
                    INTO lc_item_type,lv_inventory_item_id,lv_organization_id
                    FROM mtl_system_items_b MSIB
                   WHERE MSIB.segment1 = rec.item
                     AND MSIB.organization_id   = lc_master_organization_id;
	Exception 
	when others then 
	lc_item_type:=null;
	logit('Error while getting item type for item-'||rec.item||'.SQLERRM'||sqlerrm);	
	end;
	
	
	Begin
		SELECT MC.segment3
                    INTO lc_dept
                    FROM  mtl_system_items_b msi
                         ,mtl_item_categories MIC
                         ,mtl_categories_b    MC
						 ,mtl_category_sets MCS						
                   WHERE msi.segment1=rec.item
                   AND msi.organization_id=lc_master_organization_id
                   AND MCS.category_set_name = 'Inventory'	
				   AND MIC.category_set_id   = MCS.category_set_id
                   AND MIC.category_id       = MC.category_id
                   AND MIC.inventory_item_id = msi.inventory_item_id
                   AND MIC.organization_id   = lc_master_organization_id;
	Exception 
	when others then 
	lc_dept:=null;
	logit('Error while getting item Dept for item-'||rec.item||'.SQLERRM'||sqlerrm);	
	end;
	
	
	if lc_item_type IS NOT NULL AND lc_dept IS NOT NULL THEN
	
	    BEGIN
            SELECT target_value1
                  ,target_value2
                  ,target_value3
                  ,target_value4
              INTO lc_rev_account
                  ,lc_cogs_account
                  ,lc_inv_account
                  ,lc_cons_account
              FROM xx_fin_translatevalues
             WHERE translate_id = lc_translation_id
               AND (source_value1 IS NULL )
               AND (source_value2 = lc_item_type)
               AND (source_value3 = lc_dept)
               AND enabled_flag   = 'Y'
               AND (start_date_active <= SYSDATE
               AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
			   lv_rev_rec_derive_text:='Derive Rev Rec Account from Item Type and Item DEPT';
        EXCEPTION
           WHEN OTHERS THEN
		  
		   
		   select decode(lv_rev_rec_derive_text,null,null,lv_rev_rec_derive_text) into lv_rev_rec_derive_text from dual;
              --NULL; -- To Proceed Further
        END;
		
		
		IF lc_rev_account IS NULL THEN
		-- Getting Sales Account For  DEPT Alone
                BEGIN
                   SELECT target_value1
                  ,target_value2
                  ,target_value3
                  ,target_value4
                INTO lc_rev_account
                  ,lc_cogs_account
                  ,lc_inv_account
                  ,lc_cons_account
                     FROM xx_fin_translatevalues
                    WHERE translate_id = lc_translation_id
                      AND (source_value1 IS NULL )
                      AND (source_value2 IS NULL )
                      AND (source_value3 = lc_dept)
                      AND enabled_flag   = 'Y'
                      AND (start_date_active <= SYSDATE
                      AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
					  lv_rev_rec_derive_text:='Derive Rev Rec Account from Item DEPT';
                EXCEPTION
                   WHEN OTHERS THEN
				    --lv_rev_rec_derive_text:=null;
					select decode(lv_rev_rec_derive_text,null,null,lv_rev_rec_derive_text) into lv_rev_rec_derive_text from dual;
                     -- NULL; -- To Proceed Further
                END;
        END IF;
		
		
		IF lc_rev_account IS NULL THEN
		-- Getting Sales Account For  Item Type Alone
                BEGIN
                   SELECT target_value1
                  ,target_value2
                  ,target_value3
                  ,target_value4
                INTO lc_rev_account
                  ,lc_cogs_account
                  ,lc_inv_account
                  ,lc_cons_account                       
                    FROM xx_fin_translatevalues
                   WHERE translate_id = lc_translation_id
                     AND (source_value1 IS NULL )
                     AND (source_value2 = lc_item_type)
                     AND (source_value3 IS NULL )
                     AND enabled_flag   = 'Y'
                     AND (start_date_active <= SYSDATE
                     AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
					 lv_rev_rec_derive_text:='Derive Rev Rec Account from Item Type';
                EXCEPTION
                   WHEN OTHERS THEN
				   --lv_rev_rec_derive_text:=null;
				   select decode(lv_rev_rec_derive_text,null,null,lv_rev_rec_derive_text) into lv_rev_rec_derive_text from dual;
                     -- NULL; -- To Proceed Further
                END;
        END IF;
		
		if lc_rev_account is null then
		-- Getting Sales Account For  Item Source=DEFAULT 
				BEGIN
                    SELECT target_value1
                  ,target_value2
                  ,target_value3
                  ,target_value4
                   INTO lc_rev_account
                  ,lc_cogs_account
                  ,lc_inv_account
                  ,lc_cons_account                    
                     FROM xx_fin_translatevalues
                    WHERE translate_id = lc_translation_id
                      AND (source_value1 = 'DEFAULT')
                      AND (source_value2 IS NULL )
                      AND (source_value3 IS NULL )
                      AND enabled_flag   = 'Y'
                      AND (start_date_active <= SYSDATE
                      AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
					  lv_rev_rec_derive_text:='Derive Rev Rec Account from DEFAULT Item source';
                EXCEPTION
                   WHEN OTHERS THEN
				   --lv_rev_rec_derive_text:=null;
				   select decode(lv_rev_rec_derive_text,null,null,lv_rev_rec_derive_text) into lv_rev_rec_derive_text from dual;
                     -- NULL; -- To Proceed Further
                END;
		
		
		end if;
	
	end if;
	
	BEGIN
	-- If the Item is found, Then Derive the REV Account and Overwrite it.
       SELECT target_value1
                  ,target_value2
                  ,target_value3
                  ,target_value4
                INTO lc_rev_account
                  ,lc_cogs_account
                  ,lc_inv_account
                  ,lc_cons_account                   
              FROM xx_fin_translatevalues
             WHERE translate_id = lc_translation_id
               AND (source_value1 IS NULL)
               AND (source_value2 IS NULL)
               AND (source_value3 IS NULL)
               AND (source_value4 = rec.item)
               AND enabled_flag   = 'Y'
               AND (start_date_active <= SYSDATE
               AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
			   lv_rev_rec_derive_text:='Derive Rev Rec Account from Item and Overwirte Rev Rec Account';
    EXCEPTION
        WHEN OTHERS THEN
		--lv_rev_rec_derive_text:=null;
		select decode(lv_rev_rec_derive_text,null,null,lv_rev_rec_derive_text) into lv_rev_rec_derive_text from dual;
    --NULL; -- To Proceed Further
    END;
	
	--lv_IS_REV_REC_ELIGIBLE:=decode(NVL(lc_rev_account,'-1'), '41101000', 'Y', 'N');
    select decode(NVL(lc_rev_account,'-1'), '41101000', 'Y', 'N') into lv_IS_REV_REC_ELIGIBLE from dual;
	
	logit('Processing Item-'||rec.item||'      .Item Type-'||lc_item_type||'         .Item Dept-'||lc_dept ||'      .Attribute5-'||lv_rev_rec_derive_text||'                    .Revenu Account-'||lc_rev_account  );
	select count(1) into lv_item_count from xx_ar_subscription_items where item=rec.item;
	 
	
				  
	 if lv_item_count>0 then 
		Update xx_ar_subscription_items 
		set Is_Rev_Rec_Eligible=lv_IS_REV_REC_ELIGIBLE,
			NUMBER_OF_PERIODS=rec.no_of_periods,
			item_revenue_account=lc_rev_account,
			ITEM_COGS_ACCOUNT=lc_cogs_account,
			ITEM_INVENTORY_ACCOUNT=lc_inv_account,
			ITEM_CONSIGNMENT_ACCOUNT=lc_cons_account,
			item_type =lc_item_type,
			item_department=lc_dept,
			ATTRIBUTE5=lv_rev_rec_derive_text,
		    last_update_date=sysdate,
			last_update_by=fnd_global.user_id,
			request_id=fnd_global.conc_request_id
			where item=rec.item;
			
	 else
	 
	 insert into xx_ar_subscription_items
	 (
	 
	 ITEM                   ,
	 COST                   ,
	 OD_BILLING_FREQUENCY   ,
	 OD_CONTRACT_LENGTH     ,
	 NUMBER_OF_PERIODS      ,
	 IS_REV_REC_ELIGIBLE    ,
	 item_revenue_account   ,
	 ITEM_COGS_ACCOUNT       , 
	 ITEM_INVENTORY_ACCOUNT  , 
	 ITEM_CONSIGNMENT_ACCOUNT, 	 
	 ITEM_TYPE              ,
	 ITEM_DEPARTMENT        , 
	 ATTRIBUTE5             ,
	 INVENTORY_ITEM_ID      ,
	 ORGANIZATION_id		, 
	 CREATION_DATE 			,
	 CREATED_BY    			,
	 REQUEST_ID             ,
	 LAST_UPDATE_DATE       ,
	 LAST_UPDATE_BY )
	values	 
	 (rec.ITEM                   ,
	  rec.COST                   ,
	  rec.OD_BILLING_FREQUENCY   ,
	  rec.OD_CONTRACT_LENGTH     ,
	  rec.no_of_periods          ,
	  lv_IS_REV_REC_ELIGIBLE      ,
	  lc_rev_account              ,
	  lc_cogs_account             ,
	  lc_inv_account              ,
	  lc_cons_account             ,
	  lc_item_type                ,
	  lc_dept                     ,
	  lv_rev_rec_derive_text      ,
	  lv_inventory_item_id        ,
	  lv_organization_id          ,
	  sysdate                     ,
	  fnd_global.user_id          ,
	  fnd_global.conc_request_id  ,
	  sysdate                     ,
	  fnd_global.user_id);
	 end if;
	
	end loop;
	commit;
 
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM);
  retcode := 2;
  errbuff := 'Error encountered. Please check logs';
END MAIN_ITEM_REV_REC_PROCESS;
END XX_AR_SUBSC_ITEM_REV_REC_PKG;
/
show errors;
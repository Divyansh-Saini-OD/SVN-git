create or replace PACKAGE Body Xxoe_Data_Load_Pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Optimize                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  XX_OE_DATA_LOAD_PKG                                                          |
  -- |  RICE ID   :                                              |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  ---| Rice 1272
  -- | 1.0      28-Apr-2021      Shreyas Thorat            Initial draft version  |
  -- +============================================================================================+

    PROCEDURE get_pay_method(
        p_payment_instrument  IN             VARCHAR2,
        p_payment_type_code   IN OUT NOCOPY  VARCHAR2,
        p_credit_card_code    IN OUT NOCOPY  VARCHAR2)
    IS
-- +===================================================================+
-- | Name  : Get_Pay_Method                                            |
-- | Description      : This Procedure is called to get pay method     |
-- |                    code and credit_card_code                      |
-- |                                                                   |
-- | Parameters:        p_payment_instrument IN pass pay instrument    |
-- |                    p_payment_type_code OUT Return payment_code    |
-- |                    p_credit_card_code  OUT Return credit_card_code|
-- +===================================================================+
    BEGIN
		SELECT attribute6 CC_CODE
			   ,attribute7 PAY_TYPE
		INTO   p_credit_card_code
			  ,p_payment_type_code	   
		FROM fnd_lookup_values 
		WHERE lookup_type = 'OD_PAYMENT_TYPES'
		AND lookup_code = p_payment_instrument
		AND enabled_flag = 'Y'
		AND NVL(end_date_active,SYSDATE+1)>SYSDATE;
    EXCEPTION
        WHEN OTHERS
        THEN
            p_payment_type_code := NULL;
            p_credit_card_code := NULL;
    END get_pay_method;

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
  lc_message VARCHAR2(32000);
BEGIN
  lc_message                    := p_message;
  IF (fnd_global.conc_request_id > 0) THEN
    fnd_file.put_line(fnd_file.LOG, lc_message);
  ELSE
    DBMS_OUTPUT.put_line(lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;

FUNCTION payment_term( p_sold_to_org_id  IN  NUMBER , p_immediate_pay_term IN NUMBER)
        RETURN NUMBER
    IS
-- +===================================================================+
-- | Name  : payment_term                                              |
-- | Description     : To derive payment_term_id by passing            |
-- |                   customer_id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : payment_term_id                                  |
-- +===================================================================+
        ln_payment_term_id  NUMBER;
    BEGIN
        SELECT standard_terms
        INTO   ln_payment_term_id
        FROM   hz_customer_profiles
        WHERE  cust_account_id = p_sold_to_org_id AND site_use_id IS NULL;

        RETURN ln_payment_term_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN p_immediate_pay_term;
    END payment_term;


PROCEDURE get_def_shipto(
        p_cust_account_id  IN             NUMBER,
        x_ship_to_org_id   OUT NOCOPY     NUMBER)
    IS
-- +===================================================================+
-- | Name  : Get_Def_Shipto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Ship_to address for POS Orders                 |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_ship_to_org_id   OUT -> get bill_to_org_id    |
-- +===================================================================+
    BEGIN
        SELECT site_use.site_use_id
        INTO   x_ship_to_org_id
        FROM   hz_cust_site_uses_all site_use,
               hz_cust_acct_sites_all addr
        WHERE  addr.cust_account_id = p_cust_account_id
        AND    addr.cust_acct_site_id = site_use.cust_acct_site_id
        AND    site_use.site_use_code = 'SHIP_TO'
        AND    site_use.org_id = FND_PROFILE.VALUE('ORG_ID')
        AND    site_use.primary_flag = 'Y'
        AND    site_use.status = 'A';
    EXCEPTION
        WHEN OTHERS
        THEN
            x_ship_to_org_id := NULL;
    END;

    PROCEDURE get_def_billto(
        p_cust_account_id  IN             NUMBER,
        x_bill_to_org_id   OUT NOCOPY     NUMBER)
    IS
-- +===================================================================+
-- | Name  : Get_Def_Billto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Bill_to address for POS Orders                 |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_bill_to_org_id   OUT -> get bill_to_org_id    |
-- +===================================================================+
    BEGIN
        SELECT site_use.site_use_id
        INTO   x_bill_to_org_id
        FROM   hz_cust_accounts_all acct,
               hz_cust_site_uses_all site_use,
               hz_cust_acct_sites_all addr
        WHERE  acct.cust_account_id = p_cust_account_id
        AND    acct.cust_account_id = addr.cust_account_id
        AND    addr.cust_acct_site_id = site_use.cust_acct_site_id
        AND    site_use.site_use_code = 'BILL_TO'
        AND    site_use.org_id = FND_PROFILE.VALUE('ORG_ID')
        AND    site_use.primary_flag = 'Y'
        AND    site_use.status = 'A'
        AND    addr.bill_to_flag = 'P'                                                                    -- 16-Mar-2009
        AND    addr.status = 'A';                                                                         -- 16-Mar-2009
    EXCEPTION
        WHEN OTHERS
        THEN
            x_bill_to_org_id := NULL;
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS IN Get_Def_Billto ::'
                              || SUBSTR(SQLERRM,
                                        1,
                                        200));
    END get_def_billto;


    PROCEDURE get_def_soldtocontact(
        p_cust_account_id  IN             NUMBER,
        x_sold_to_contact_id   OUT NOCOPY     NUMBER)
    IS
-- +===================================================================+
-- | Name  : Get_Def_Billto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Bill_to address for POS Orders                 |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_bill_to_org_id   OUT -> get bill_to_org_id    |
-- +===================================================================+
    BEGIN
        SELECT hcar.CUST_ACCOUNT_ROLE_ID 
		INTO x_sold_to_contact_id
		FROM hz_cust_accounts_all hca, HZ_CUST_ACCOUNT_ROLES hcar , HZ_RELATIONSHIPS hr
		where 1=1 
		and hr.subject_id = hca.party_id 
		and hr.PARTY_ID = hcar.party_id
		and hcar.ROLE_TYPE = 'CONTACT'
		and hcar.primary_flag = 'Y'
		and hca.cust_account_id = p_cust_account_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_sold_to_contact_id := NULL;
            Logit('WHEN OTHERS IN Get_Def_Billto ::'
                              || SUBSTR(SQLERRM,
                                        1,
                                        200));
    END get_def_soldtocontact;


-- +===================================================================+
-- | Name  : get_customer_details                                            |
-- | Description      : This Procedure is called to derive Ship_to     |
-- |                    Address                                        |
-- |                                                                   |
-- | Parameters     : p_orig_sys_ship_ref IN -> pass orig_ship_ref     |
-- |                  p_orig_system      IN -> pass ordered date      |
-- |                  SOLD_TO_ORG_ID   OUT -> get SOLD_TO_ORG_ID       |
-- +===================================================================+
    PROCEDURE get_customer_details(
        p_orig_sys_ship_ref      IN             VARCHAR2,
		p_orig_system			IN             VARCHAR2,
		SOLD_TO_ORG_ID         IN OUT NOCOPY  NUMBER
		)
    IS
    BEGIN
        SELECT owner_table_id
        INTO   SOLD_TO_ORG_ID
        FROM   hz_orig_sys_references
        WHERE  orig_system = p_orig_system
        AND    orig_system_reference = p_orig_sys_ship_ref
        AND    owner_table_name = 'HZ_CUST_ACCOUNTS'
        AND    status = 'A';
       
    EXCEPTION
        WHEN OTHERS
        THEN
		   SOLD_TO_ORG_ID := NULL;
            Logit('In Others for Derive ShipTo');
            Logit(   'Error :' || SUBSTR(SQLERRM, 1, 80));
    END get_customer_details;



FUNCTION get_ship_method( p_ship_method  IN  VARCHAR2)
        RETURN VARCHAR2
	IS
-- +===================================================================+
-- | Name  : get_ship_method                                           |
-- | Description     : To derive ship_method_code by passing           |
-- |                   delivery code                                   |
-- |                                                                   |
-- | Parameters     : p_ship_method  IN -> pass delivery code          |
-- |                                                                   |
-- | Return         : ship_method_code                                 |
-- +===================================================================+
    ship_method VARCHAR2(30);
	BEGIN
        
		SELECT attribute6 
		INTO   ship_method
		FROM   fnd_lookup_values lkp
		WHERE  1=1
		AND    lkp.lookup_code = p_ship_method
		AND    lkp.lookup_type = 'OD_CSAS_SHIP_METHODS'
		AND    view_application_id = 222;

        RETURN ship_method;
    EXCEPTION
        WHEN OTHERS
        THEN
            logit( 'Not able to get the ship method '|| SUBSTR(SQLERRM,1,90));
            RETURN NULL;
    END get_ship_method;


    FUNCTION get_order_source(
         p_order_source    IN  VARCHAR2
		--,p_app_id          IN  VARCHAR2
		)
		RETURN VARCHAR2
    IS
-- +===================================================================+
-- | Name  : get_order_source                                              |
-- | Description     : To derive order_source_id by passing order      |
-- |                   source                                          |
-- |                                                                   |
-- | Parameters     : p_order_source  IN -> pass order source          |
-- |                                                                   |
-- | Return         : order_source                                  |
-- +===================================================================+
    ret_order_source_id NUMBER	;
	BEGIN
	/*    IF p_app_id IS NOT NULL
		THEN
		 BEGIN
		    SELECT attribute6
            INTO   g_order_source(p_order_source)
            FROM   fnd_lookup_values
            WHERE  lookup_type = 'OD_CSAS_ORDER_SOURCE' 
			  AND  lookup_code = '0'||UPPER(p_order_source)
			  AND  attribute7  = p_app_id;

	     EXCEPTION
         WHEN NO_DATA_FOUND
         THEN 
            BEGIN
			  SELECT   attribute6
                INTO   g_order_source(p_order_source)
                FROM   fnd_lookup_values
               WHERE  lookup_type = 'OD_CSAS_ORDER_SOURCE' AND lookup_code = UPPER(p_order_source);
			EXCEPTION
            WHEN OTHERS
            THEN
			   RETURN NULL;
            END;  			
         END;
        END IF;
        */
		BEGIN
		  SELECT   attribute6
			INTO   ret_order_source_id
			FROM   fnd_lookup_values
		   WHERE  lookup_type = 'OD_CSAS_ORDER_SOURCE' AND lookup_code = UPPER(p_order_source)
		   AND view_application_id = 222;
		EXCEPTION
		WHEN OTHERS
		THEN
		   RETURN NULL;
		END;  			
		RETURN ret_order_source_id;
    EXCEPTION
        WHEN OTHERS
        THEN
		    RETURN NULL;
    END get_order_source;


-- +===================================================================+
-- | Name  : get_salesrep_for_legacyrep                                                 |
-- | Description     : To derive salesrep_id by passing salesrep       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters     : p_sales_rep  IN -> pass salesrep                 |
-- |                                                                   |
-- | Return         : sales_rep_id                                     |
-- +===================================================================+

    FUNCTION get_salesrep_for_legacyrep(
        p_org_id      IN  NUMBER,
        p_sales_rep   IN  VARCHAR2,
        p_as_of_date  IN  DATE DEFAULT SYSDATE
		,p_SALESREP_ID IN NUMBER)
        RETURN NUMBER
    IS

        CURSOR lcu_get_salesrep(
            p_salesrep  VARCHAR2,
            p_orgid     NUMBER)
        IS
            SELECT DISTINCT jrs1.salesrep_id spid1,
                            jrs1.start_date_active start_dt1,
                            jrs1.end_date_active end_dt1,
                            jrs2.salesrep_id spid2,
                            jrs2.start_date_active start_dt2,
                            jrs2.end_date_active end_dt2,
                            jrs3.salesrep_id spid3,
                            jrs3.start_date_active start_dt3,
                            jrs3.end_date_active end_dt3,
                            jrs4.salesrep_id spid4,
                            jrs4.start_date_active start_dt4,
                            jrs4.end_date_active end_dt4,
                            jrs5.salesrep_id spid5,
                            jrs5.start_date_active start_dt5,
                            jrs5.end_date_active end_dt5,
                            jrs6.salesrep_id spid6,
                            jrs6.start_date_active start_dt6,
                            jrs6.end_date_active end_dt6
            FROM            jtf_rs_salesreps jrs1,
                            jtf_rs_resource_extns_vl jrr1,
                            jtf_rs_group_mbr_role_vl jrg,
                            jtf_rs_role_relations jrr,
                            jtf_rs_salesreps jrs2,
                            jtf_rs_resource_extns_vl jrr2,
                            jtf_rs_salesreps jrs3,
                            jtf_rs_resource_extns_vl jrr3,
                            jtf_rs_salesreps jrs4,
                            jtf_rs_resource_extns_vl jrr4,
                            jtf_rs_salesreps jrs5,
                            jtf_rs_resource_extns_vl jrr5,
                            jtf_rs_salesreps jrs6,
                            jtf_rs_resource_extns_vl jrr6
            WHERE           jrr.attribute15 = p_salesrep
            AND             jrr.role_resource_type = 'RS_GROUP_MEMBER'
            -- AND p_as_of_date BETWEEN jrr.start_date_active and NVL(jrr.end_date_active,(p_as_of_date+1))
            AND             jrr.role_relate_id = jrg.role_relate_id
            AND             jrg.resource_id = jrs1.resource_id
            AND             jrs1.org_id(+) = p_orgid
            AND             jrr1.resource_id = jrs1.resource_id
            AND             jrr2.source_id(+) = jrr1.source_mgr_id
            AND             jrs2.org_id(+) = p_orgid
            AND             jrs2.resource_id(+) = jrr2.resource_id
            AND             jrr3.source_id(+) = jrr2.source_mgr_id
            AND             jrs3.org_id(+) = p_orgid
            AND             jrs3.resource_id(+) = jrr3.resource_id
            AND             jrr4.source_id(+) = jrr3.source_mgr_id
            AND             jrs4.org_id(+) = p_orgid
            AND             jrs4.resource_id(+) = jrr4.resource_id
            AND             jrr5.source_id(+) = jrr4.source_mgr_id
            AND             jrs5.org_id(+) = p_orgid
            AND             jrs5.resource_id(+) = jrr5.resource_id
            AND             jrr6.source_id(+) = jrr5.source_mgr_id
            AND             jrs6.org_id(+) = p_orgid
            AND             jrs6.resource_id(+) = jrr6.resource_id;

        ln_salesrep_id           NUMBER;
        l_hierarchy_rec          lcu_get_salesrep%ROWTYPE;
    BEGIN
        
            -- Get the active salesrep associated with the legacy rep as of the passed date
            OPEN lcu_get_salesrep(p_sales_rep,p_org_id);
            FETCH lcu_get_salesrep
            INTO  l_hierarchy_rec;
            CLOSE lcu_get_salesrep;

            IF p_as_of_date BETWEEN l_hierarchy_rec.start_dt1 AND NVL(l_hierarchy_rec.end_dt1, p_as_of_date + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid1;

            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt2 AND NVL(l_hierarchy_rec.end_dt2, p_as_of_date + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid2;

            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt3 AND NVL(l_hierarchy_rec.end_dt3, p_as_of_date + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid3;

            ELSE
                ln_salesrep_id := p_SALESREP_ID;
				
            END IF;

            RETURN ln_salesrep_id;
        
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_salesrep_for_legacyrep;

-- +===================================================================+
-- | Name  : Load_Org_Details                                          |
-- | Description : Local procedure to load org details                 |
-- |                                                                   |
-- | Parameters  : p_org_no  IN -> pass inv/store location no          |
-- |                                                                   |
-- | Return      : None                                                |
-- +===================================================================+
    FUNCTION load_org_details( p_org_no  IN  VARCHAR2)
    RETURN NUMBER 
	IS
	ret_org_id NUMBER ;
    BEGIN
        SELECT organization_id
		      --,attribute5,org.NAME,org.TYPE
        INTO   ret_org_id
        FROM   hr_all_organization_units org
        WHERE  attribute1 = p_org_no;
		RETURN ret_org_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            Logit(   'Error in loading Org Details: ' || SQLERRM);
			RETURN NULL;
    END load_org_details;


/* ===========================================================================*
|  PUBLIC PROCEDURE xxom_load_data                                    |
|                                                                            |
|  DESCRIPTION                                                               |
|  This procedure is used to load data into xxom interface table.            |
|                                                                            |
|  This procedure will be called directly by Concurrent Program              |
|                                                                            |
* ===========================================================================*/
PROCEDURE xxom_load_data ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 ) 
IS
cursor cur_data
  IS 
  SELECT Order_Number ,
    Sub_Order_Number ,
    Process_Flag ,
    Status ,
    Sequence_Num,
    Json_Ord_Data
  FROM Xxom_Import_Int
  WHERE Process_Flag = 'I'
  AND status         = 'New'
  AND Sequence_Num BETWEEN P_START_ID AND P_END_ID;
  
  L_Header_Id NUMBER;
  lc_order    NUMBER;
  lc_seq_num  NUMBER;
  lc_level    VARCHAR2(50);
  
  TYPE cur_data_tab IS TABLE OF cur_data%ROWTYPE INDEX BY PLS_INTEGER;
  cur_lob_data cur_data_tab;
  null_cur_lob_data cur_data_tab;
  
  TYPE tt_header_int IS TABLE OF Xxom_Order_Headers_Int%ROWTYPE ;--INDEX BY PLS_INTEGER;
  l_header_int tt_header_int := tt_header_int();
  l_header_int_temp tt_header_int := tt_header_int();
  empty_header_int tt_header_int := tt_header_int();
  
  TYPE tt_line_int IS TABLE OF XXOM_ORDER_LINES_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_line_int tt_line_int := tt_line_int();
  l_line_int_temp tt_line_int := tt_line_int();
  empty_line_int tt_line_int := tt_line_int();
  
  TYPE tt_tender_int IS TABLE OF XXOM_ORDER_TENDERS_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_tender_int tt_tender_int := tt_tender_int();
  l_tender_int_temp tt_tender_int := tt_tender_int();
  empty_tender_int tt_tender_int := tt_tender_int();
  
  TYPE tt_adjustment_int IS TABLE OF XXOM_ORDER_ADJUSTMENTS_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_adjustment_int tt_adjustment_int := tt_adjustment_int();
  l_adjustment_int_temp tt_adjustment_int := tt_adjustment_int();
  empty_adjustment_int tt_adjustment_int := tt_adjustment_int();
  
  error_forall   EXCEPTION;
  PRAGMA EXCEPTION_INIT (error_forall, -24381);
  error_counter NUMBER;
  
  l_limit NUMBER := 100;
  
  L_SQL_STMT VARCHAR2(32767);
  L_TASK_NAME VARCHAR2(1000);
  
  L_CHUNK_SIZE VARCHAR2(100);
  L_PARALLEL_LEVEL VARCHAR2(100);
  
BEGIN 
    BEGIN 
		SELECT
		XFTV.TARGET_VALUE1
		INTO l_limit
		FROM XX_FIN_TRANSLATEDEFINITION XFTD ,
		XX_FIN_TRANSLATEVALUES XFTV
		WHERE XFTD.TRANSLATION_NAME ='XX_AR_CSAS_INTEGRETION'
		AND XFTD.TRANSLATE_ID =XFTV.TRANSLATE_ID
		AND XFTD.ENABLED_FLAG ='Y'
		AND SOURCE_VALUE1 IN ('XXOM_LIMIT')
		AND XFTV.SOURCE_VALUE2 = FND_PROFILE.VALUE('ORG_ID')
		AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
	EXCEPTION 
	WHEN OTHERS THEN
		l_limit := 500;
	END;
	
	OPEN cur_data;
	LOOP 
	FETCH cur_data BULK COLLECT INTO cur_lob_data LIMIT l_limit;
    EXIT WHEN cur_lob_data.COUNT = 0;
	
	FOR i IN 1 .. cur_lob_data.COUNT
    LOOP
	BEGIN
		lc_order   := cur_lob_data(i).Order_Number;
		lc_seq_num := cur_lob_data(i).Sequence_Num;
		lc_level   := 'Order Header';
		
		l_header_int_temp := empty_header_int;
		l_line_int_temp := empty_line_int;
		l_adjustment_int_temp := empty_adjustment_int ;
		l_tender_int_temp := empty_tender_int ;
	
		/* header */
				
		SELECT Salesperson ,
        Shipping_Shiptoid ,
        Shipping_Shiptoname ,
        Shipping_Addressseq ,
        Shipping_City ,
        Shipping_Cost ,
        Shipping_Country ,
        Shipping_County ,
        Shipping_Line1 ,
        Shipping_Line2 ,
        Shiptolastupdatedate ,
        State ,
        Zip ,
        Accountid ,
        Actioncode ,
        Accertsyn ,
        Botaxpercent ,
        Bototal ,
        Ccalias ,
        Siteid ,
        Wname ,
        Alternateshipper ,
        Billcompleteflag ,
        Billing_Billtoname ,
        Billing_Addressseq ,
        Billing_Billtolastupdatedate ,
        Billing_City ,
        Billing_Country ,
        Billing_County ,
        Billing_Line1 ,
        Billing_Line2 ,
        Billing_State ,
        Billing_Zip ,
        Businessunit ,
        Cancelreason ,
        DECODE(NVL(COMMISIONFLAG,'N'),'Y','Y','N') Commisionflag ,
        Costcentersplitflag ,
        Createbyid ,
        Custcustomertype ,
        Custponumber ,
        Customertaxexmptid ,
        Customertype ,
        Deliverymethod ,
        Depositamount ,
        Depositamountiflag ,
        Deptdescription ,
		DECODE(NVL(Dropshipflag,'N'),'Y','Y','N') Dropshipflag,
        Extordnumber ,
        Freighttaxamt ,
        Freighttaxpercent ,
        Geolocation ,
        Giftflag ,
        Invlocid ,
        Invloctimezone ,
        Isdropship ,
        Iswholesale ,
        Kitoverrideflag ,
        Kittype ,
        Locationtype ,
        Loyaltyid ,
        Ordercategory ,
        Ordercomment1 ,
        Ordercomment2 ,
        Ordercomment3 ,
        Ordercreatetime ,
        Ordercurrency ,
        Orderdate ,
        Orderdatetimestamp ,
        Orderdelcode ,
        Orderdeloverridecode ,
        Orderdepartment ,
        Orderdesktop ,
        Orderendtime ,
        Ordergsttax ,
        Orderlobid ,
        Orderlastupdatedate ,
        Ordernumber ,
        Orderpsttax ,
        Orderrelease ,
        Ordersource ,
        Orderstatus ,
        Orderstatusdescription ,
        Ordersubtotal ,
        Ordertotal ,
        Ordertype ,
        Ordertype2 ,
        Ordertypedescription ,
        Orderustax ,
        Orderwebstatusdescription ,
        Ordersubnumber ,
        Originallocationid ,
        Originalordernumber ,
        Originalordersubnumber ,
        Originalsaledate ,
        Parentorder ,
        Pickupordeliverydate ,
        Pricecode ,
        Promiseddate ,
        Relatedorderscount_Long ,
        Returnactioncode ,
        Returncategorycode ,
        Returnreasoncode ,
        Routenumber ,
        Sectornumber ,
        Saledate ,
        Salelocid ,
        Saleschannel ,
        Salespersonloc ,
        Shipdate ,
        Soldto_Contactemailaddr ,
        Soldto_Contactfirstname ,
        Soldto_Contactlastname ,
        Soldto_Contactphone ,
		Soldto_Contactphoneext ,
		--Soldto_contactName ,
        Soldto_Soldtocontact ,
        Spcacctnumber ,
        Splitorderflag ,
        Store_City ,
        Store_Country ,
        Store_Description ,
        Store_Line1 ,
        Store_Line2 ,
        Store_Phone ,
        Store_Receiptnumber ,
        Store_State ,
        Storenumber ,
        Store_Zipcode ,
        Taxpercent ,
        Taxableflag ,
        Totaladjustmentamount ,
        Totalsaleamount ,
        Totaltax ,
        Updatedby ,
        Clientip ,
        Lastuserid ,
        Originaluserid ,
        Xxom_Header_Data_Seq.Nextval ,
        'New'
		,''
		,Soldto_contactName
		,orig_cust_name
		BULK COLLECT INTO 
		l_header_int_temp
      FROM Dual,
        Json_Table (cur_lob_data(i).Json_Ord_Data, '$.orderHeader[*]' Columns ( Salesperson VARCHAR2(30) Path '$.SalesPerson' ,
        --Shipping
        Shipping_Shiptoid VARCHAR2(30) Path '$.Shipping.ShipToID', Shipping_Shiptoname VARCHAR2(240) Path '$.Shipping.ShipToName', Shipping_Addressseq VARCHAR2(50) Path '$.Shipping.addressSeq', Shipping_City VARCHAR2(60) Path '$.Shipping.city', Shipping_Cost VARCHAR2(30) Path '$.Shipping.cost', Shipping_Country VARCHAR2(60) Path '$.Shipping.country', Shipping_County VARCHAR2(60) Path '$.Shipping.county', Shipping_Line1 VARCHAR2(240) Path '$.Shipping.line1', Shipping_Line2 VARCHAR2(240) Path '$.Shipping.line2', Shiptolastupdatedate VARCHAR2(30) Path '$.Shipping.shipToLastUpdateDate', State VARCHAR2(60) Path '$.Shipping.state', Zip VARCHAR2(60) Path '$.Shipping.zip',
        /*
        NESTED PATH '$.Shipping'
        COLUMNS (ShipToID VARCHAR2(30) PATH '$.ShipToID',
        ShipToName VARCHAR2(50) PATH '$.ShipToName',
        addressseq VARCHAR2(50) PATH '$.addressseq',
        city VARCHAR2(30) PATH '$.city',
        cost VARCHAR2(30) PATH '$.cost',
        country VARCHAR2(30) PATH '$.country',
        county VARCHAR2(30) PATH '$.county',
        line1 VARCHAR2(50) PATH '$.line1',
        line2 VARCHAR2(50) PATH '$.line2',
        shipToLastUpdateDate VARCHAR2(30) PATH '$.shipToLastUpdateDate',
        state VARCHAR2(30) PATH '$.state',
        zip VARCHAR2(30) PATH '$.zip')  , -- Need to Check
        */
        Accountid VARCHAR2(240) Path '$.accountId' , Actioncode VARCHAR2(50) Path '$.actionCode' , Accertsyn VARCHAR2(150) Path '$.addValues.AccertSyn' , Botaxpercent VARCHAR2(150) Path '$.addValues.BOTaxPercent' , Bototal VARCHAR2(150) Path '$.addValues.BOTotal' , Ccalias VARCHAR2(150) Path '$.addValues.CCALIAS' ,
        --COF_COF_RECUR VARCHAR2(150) PATH '$.addValues.COF-COF-RECUR' ,
        --Mobile_App_Id VARCHAR2(150) PATH '$.addValues.Mobile-App-Id' ,
        Siteid VARCHAR2(150) Path '$.addValues.SITEID' ,
        --SOURCE_APP VARCHAR2(150) PATH '$.addValues.SOURCE-APP' ,
        Wname VARCHAR2(150) Path '$.addValues.WNAME' , Alternateshipper VARCHAR2(240) Path '$.alternateShipper' , Billcompleteflag VARCHAR2(1) Path '$.billCompleteFlag' ,
        --billing
        Billing_Billtoname VARCHAR2(240) Path '$.billing.BillToName', Billing_Addressseq VARCHAR2(100) Path '$.billing.addressseq', Billing_Billtolastupdatedate VARCHAR2(30) Path '$.billing.billToLastUpdateDate', Billing_City VARCHAR2(30) Path '$.billing.city', Billing_Country VARCHAR2(30) Path '$.billing.country', Billing_County VARCHAR2(30) Path '$.billing.county', Billing_Line1 VARCHAR2(50) Path '$.billing.line1', Billing_Line2 VARCHAR2(50) Path '$.billing.line2', Billing_State VARCHAR2(30) Path '$.billing.state', Billing_Zip VARCHAR2(30) Path '$.billing.zip',
        /*
        NESTED PATH '$.billing'
        COLUMNS (BillToName VARCHAR2(50) PATH '$.BillToName',
        addressseq VARCHAR2(100) PATH '$.addressseq',
        billToLastUpdateDate VARCHAR2(30) PATH '$.billToLastUpdateDate',
        city VARCHAR2(30) PATH '$.city',
        country VARCHAR2(30) PATH '$.country',
        county VARCHAR2(30) PATH '$.county',
        line1 VARCHAR2(50) PATH '$.line1',
        line2 VARCHAR2(50) PATH '$.line2',
        state VARCHAR2(30) PATH '$.state',
        zip VARCHAR2(30) PATH '$.zip')  , -- Need to Check
        */
        Businessunit                                 VARCHAR2(10) Path '$.businessUnit' , Cancelreason VARCHAR2(30) Path '$.cancelReason' , Commisionflag VARCHAR2(1) Path '$.commisionFlag' , Costcentersplitflag VARCHAR2(1) Path '$.costCenterSplitFlag' , Createbyid VARCHAR2(30) Path '$.createById' , Custcustomertype VARCHAR2(1) Path '$.custCustomerType' , Custponumber VARCHAR2(50) Path '$.custPONumber' , Customertaxexmptid VARCHAR2(30) Path '$.customerTaxExmptId' , Customertype VARCHAR2(1) Path '$.customerType' , Deliverymethod VARCHAR2(30) Path '$.deliveryMethod' , Depositamount NUMBER Path '$.depositAmount' , Depositamountiflag VARCHAR2(1) Path '$.depositAmountIFlag' , Deptdescription VARCHAR2(30) Path '$.deptDescription' , Dropshipflag VARCHAR2(1) Path '$.dropShipFlag' , Extordnumber VARCHAR2(100) Path '$.extOrdNumber' , Freighttaxamt NUMBER Path '$.freightTaxAmt' , Freighttaxpercent NUMBER Path '$.freightTaxPercent' , Geolocation VARCHAR2(30) Path '$.geoLocation' , Giftflag VARCHAR2(1) Path '$.giftFlag' ,
        Invlocid                                     NUMBER Path '$.invLocId' , Invloctimezone VARCHAR2(5) Path '$.invLocTimeZone' , Isdropship VARCHAR2(5) Path '$.isDropShip' , Iswholesale VARCHAR2(5) Path '$.isWholeSale' , Kitoverrideflag VARCHAR2(1) Path '$.kitOverrideFlag' , Kittype VARCHAR2(20) Path '$.kitType' , Locationtype VARCHAR2(10) Path '$.locationType' , Loyaltyid NUMBER Path '$.loyaltyId' , Ordercategory VARCHAR2(1) Path '$.orderCategory' , Ordercomment1 VARCHAR2(200) Path '$.orderComment1' , Ordercomment2 VARCHAR2(200) Path '$.orderComment2' , Ordercomment3 VARCHAR2(200) Path '$.orderComment3' , Ordercreatetime NUMBER Path '$.orderCreateTime' , Ordercurrency VARCHAR2(3) Path '$.orderCurrency' , Orderdate VARCHAR2(15) Path '$.orderDate' , Orderdatetimestamp VARCHAR2(40) Path '$.orderDateTimestamp' , Orderdelcode VARCHAR2(1) Path '$.orderDelCode' , Orderdeloverridecode VARCHAR2(15) Path '$.orderDelOverrideCode' , Orderdepartment VARCHAR2(50) Path '$.orderDepartment' , Orderdesktop VARCHAR2(50) Path
        '$.orderDesktop' , Orderendtime              NUMBER Path '$.orderEndTime' , Ordergsttax NUMBER Path '$.orderGSTTax' , Orderlobid VARCHAR2(10) Path '$.orderLOBId' , Orderlastupdatedate VARCHAR2(15) Path '$.orderLastUpdateDate' , Ordernumber VARCHAR2(30) Path '$.orderNumber' , Orderpsttax NUMBER Path '$.orderPSTTax' , Orderrelease VARCHAR2(240) Path '$.orderRelease' , Ordersource VARCHAR2(25) Path '$.orderSource' , Orderstatus VARCHAR2(25) Path '$.orderStatus' , Orderstatusdescription VARCHAR2(150) Path '$.orderStatusDescription' , Ordersubtotal NUMBER Path '$.orderSubTotal' , Ordertotal NUMBER Path '$.orderTotal' , Ordertype VARCHAR2(20) Path '$.orderType' , Ordertype2 VARCHAR2(15) Path '$.orderType2' , Ordertypedescription VARCHAR2(40) Path '$.orderTypeDescription' , Orderustax NUMBER Path '$.orderUSTax' , Orderwebstatusdescription VARCHAR2(30) Path '$.orderWebStatusDescription' , Ordersubnumber VARCHAR2(30) Path '$.ordersubNumber' , Originallocationid VARCHAR2(1) Path
        '$.originalLocationId' , Originalordernumber VARCHAR2(30) Path '$.originalOrderNumber' , Originalordersubnumber VARCHAR2(30) Path '$.originalOrderSubNumber' , Originalsaledate VARCHAR2(30) Path '$.originalSaleDate' , Parentorder VARCHAR2(30) Path '$.parentOrder' , Pickupordeliverydate VARCHAR2(20) Path '$.pickupOrDeliveryDate' , Pricecode VARCHAR2(10) Path '$.priceCode' , Promiseddate VARCHAR2(15) Path '$.promisedDate' , Relatedorderscount_Long VARCHAR2(10) Path '$.relatedOrdersCount_long' , Returnactioncode VARCHAR2(10) Path '$.returnActionCode' , Returncategorycode VARCHAR2(15) Path '$.returnCategoryCode' , Returnreasoncode VARCHAR2(50) Path '$.returnReasonCode' ,
        --route
        Routenumber VARCHAR2(30) Path '$.route.routeNumber', Sectornumber VARCHAR2(30) Path '$.route.sectorNumber',
        /*
        NESTED PATH '$.route'
        COLUMNS (routeNumber VARCHAR2(30) PATH '$.routeNumber',
        sectorNumber VARCHAR2(30) PATH '$.sectorNumber')  , -- Need to Check
        */
        Saledate VARCHAR2(30) Path '$.saleDate' , Salelocid VARCHAR2(30) Path '$.saleLocId' , Saleschannel VARCHAR2(30) Path '$.salesChannel' , Salespersonloc VARCHAR2(20) Path '$.salesPersonLoc' , Shipdate VARCHAR2(30) Path '$.shipDate' ,
        --soldTo Group
        Soldto_Contactemailaddr VARCHAR2(240) Path '$.soldTo.contactEmailAddr', Soldto_Contactfirstname VARCHAR2(240) Path '$.soldTo.contactFirstName', Soldto_Contactlastname VARCHAR2(240) Path '$.soldTo.contactLastName', Soldto_contactName VARCHAR2(240) Path '$.soldTo.contactName', Soldto_Contactphone VARCHAR2(240) Path '$.soldTo.contactPhone', Soldto_Contactphoneext VARCHAR2(240) Path '$.soldTo.contactPhoneExt', Soldto_Soldtocontact VARCHAR2(30) Path '$.soldTo.soldToContact' ,
        /*
        NESTED PATH '$.soldTo'
        COLUMNS (contactEmailAddr VARCHAR2(30) PATH '$.contactEmailAddr',
        contactFirstName VARCHAR2(30) PATH '$.contactFirstName',
        contactLastName VARCHAR2(30) PATH '$.contactLastName',
        contactPhone VARCHAR2(30) PATH '$.contactPhone',
        contactPhoneExt VARCHAR2(30) PATH '$.contactPhoneExt',
        soldToContact VARCHAR2(30) PATH '$.soldToContact')  , -- Need to Check
        */
        -----
        Spcacctnumber VARCHAR2(30) Path '$.spcAcctNumber' , Splitorderflag VARCHAR2(1) Path '$.splitOrderFlag' ,
        --Store Group
        Store_City VARCHAR2(30) Path '$.store.city', Store_Country VARCHAR2(30) Path '$.store.country', Store_Description VARCHAR2(30) Path '$.store.description', Store_Line1 VARCHAR2(30) Path '$.store.line1', Store_Line2 VARCHAR2(30) Path '$.store.line2', Store_Phone VARCHAR2(30) Path '$.store.phone', Store_Receiptnumber VARCHAR2(30) Path '$.store.receiptNumber', Store_State VARCHAR2(30) Path '$.store.state', Storenumber VARCHAR2(30) Path '$.store.storeNumber', Store_Zipcode VARCHAR2(30) Path '$.store.zipCode' , -- Need to Check
        Taxpercent NUMBER Path '$.taxPercent' , Taxableflag VARCHAR2(1) Path '$.taxableFlag' , Totaladjustmentamount NUMBER Path '$.totalAdjustmentAmount' , Totalsaleamount NUMBER Path '$.totalSaleAmount' , Totaltax NUMBER Path '$.totalTax' , Updatedby VARCHAR2(30) Path '$.updatedBy' ,Clientip VARCHAR2(30) Path '$.webOrderInf.clientIP' ,Lastuserid VARCHAR2(30) Path '$.webOrderInf.lastUserId' ,Originaluserid VARCHAR2(30) Path '$.webOrderInf.originalUserId'
        ,orig_cust_name VARCHAR2(360) Path '$.orig_cust_name'
		/*
        NESTED PATH '$.webOrderInf'
        COLUMNS (clientIP VARCHAR2(30) PATH '$.clientIP',
        lastUserId VARCHAR2(30) PATH '$.lastUserId',
        originalUserId VARCHAR2(30) PATH '$.originalUserId')   -- Need to Check
        */
        )) ;
		
		
		/**/
		
		/* Line*/
		SELECT Xxom_Header_Data_Seq.Currval INTO L_Header_Id FROM Dual;
		lc_level := 'Order Line';
		
		
		SELECT Avgcost ,
        Backorderquantity ,
        Bundleid ,
        Configurationid ,
        Campaigncode ,
        Contractcode ,
        Coretype ,
        Costcentercode ,
        Costcenterdescription ,
        Customerproductcode ,
        Department ,
        Division ,
        Enteredproductcode ,
        Extendedprice ,
        Gsaflag ,
        Itemdescription ,
        Itemsource ,
        Itemtype ,
        Kitdept ,
        Kitquantity ,
        Kitseq ,
        Kitsku ,
        Kitvpc ,
        Linecomments ,
        Linenumber ,
        Carrier ,
        Trackingid ,
        Listprice ,
        Omxsku ,
        Originalitemprice ,
        Pocost ,
        Polinenum ,
        Price ,
        Priceoverridecode ,
        Pricetype ,
        Quantity ,
        Shipquantity ,
        Sku ,
        Taxamt ,
        Taxpercent ,
        Unit ,
        Upc ,
        Vendorid ,
        Vendorproductcode ,
        Vendorshipperaccount ,
        Wholesalerproductnumber ,
        L_Header_Id ,
        Xxom_Line_Data_Seq.Nextval ,
        'New'
		,''
      BULK COLLECT INTO 
	  l_line_int_temp
	  FROM Dual,
        Json_Table (cur_lob_data(i).Json_Ord_Data, '$.orderLines[*]' Columns ( Avgcost NUMBER Path '$.avgCost' , Backorderquantity NUMBER Path '$.backorderQuantity' , Bundleid VARCHAR2(30) Path '$.bundleId' , Campaigncode VARCHAR2(30) Path '$.campaignCode' , Configurationid VARCHAR2(30) Path '$.configurationId' , Contractcode VARCHAR2(30) Path '$.contractCode' , Coretype VARCHAR2(30) Path '$.coreType' , Costcentercode VARCHAR2(3) Path '$.costCenterCode' , Costcenterdescription VARCHAR2(50) Path '$.costCenterDescription' , Customerproductcode VARCHAR2(30) Path '$.customerProductCode' , Department VARCHAR2(30) Path '$.department' , Division VARCHAR2(30) Path '$.division' , Enteredproductcode VARCHAR2(30) Path '$.enteredProductCode' , Extendedprice NUMBER Path '$.extendedPrice' , Gsaflag NUMBER Path '$.gsaFlag' , Itemdescription VARCHAR2(50) Path '$.itemDescription' , Itemsource VARCHAR2(30) Path '$.itemSource' , Itemtype VARCHAR2(30) Path '$.itemType' , Kitdept VARCHAR2(30) Path '$.kitDept' ,
        Kitquantity                                                      NUMBER Path '$.kitQuantity' , Kitseq VARCHAR2(50) Path '$.kitSeq' , Kitsku VARCHAR2(50) Path '$.kitSku' , Kitvpc VARCHAR2(50) Path '$.kitVPC' , Linecomments VARCHAR2(50) Path '$.lineComments' , Linenumber NUMBER Path '$.lineNumber' ,
        --lineTrackingNumbers
        Carrier VARCHAR2(50) Path '$.lineTrackingNumbers.carrier' , Trackingid VARCHAR2(50) Path '$.lineTrackingNumbers.trackingId' , Listprice NUMBER Path '$.listPrice' , Omxsku VARCHAR2(30) Path '$.omxSku' , Originalitemprice NUMBER Path '$.originalItemPrice' , Pocost NUMBER Path '$.poCost' , Polinenum NUMBER Path '$.poLineNum' , Price NUMBER Path '$.price' , Priceoverridecode VARCHAR2(30) Path '$.priceOverrideCode' , Pricetype VARCHAR2(30) Path '$.priceType' , Quantity NUMBER Path '$.quantity' , Shipquantity NUMBER Path '$.shipQuantity' , Sku VARCHAR2(30) Path '$.sku' , Taxamt NUMBER Path '$.taxAmt' , Taxpercent NUMBER Path '$.taxPercent' , Unit VARCHAR2(30) Path '$.unit' , Upc VARCHAR2(30) Path '$.upc' , Vendorid VARCHAR2(30) Path '$.vendorID' , Vendorproductcode VARCHAR2(30) Path '$.vendorProductCode' , Vendorshipperaccount VARCHAR2(30) Path '$.vendorShipperAccount' , Wholesalerproductnumber VARCHAR2(30) Path '$.wholesalerProductNumber' ));
		
		
		/**/
		
		/*Adjustment*/
		
		lc_level := 'Order Adjustment';
		
		SELECT Acctingcouponamount ,
        Adjustmentcode ,
        Adjustmentseqnum ,
        Couponid ,
        Displaycouponamount ,
        Employeeid ,
        Linenum ,
        Xxom_Adjustment_Data_Seq.Nextval ,
        L_Header_Id ,
        '',
        'New'
		,''
		BULK COLLECT INTO
		l_adjustment_int_temp	  
		FROM Dual,
        Json_Table (cur_lob_data(i).Json_Ord_Data, '$.orderAdjustments[*]' Columns (Acctingcouponamount NUMBER Path '$.acctingCouponAmount', Adjustmentcode VARCHAR2(10) Path '$.adjustmentCode', Adjustmentseqnum NUMBER Path '$.adjustmentSeqNum', Couponid NUMBER Path '$.couponId', Displaycouponamount NUMBER Path '$.displayCouponAmount', Employeeid NUMBER Path '$.employeeId', Linenum NUMBER Path '$.lineNum')) ;
      
		
		/**/
		
		/*Tender*/
		
		lc_level := 'Order Tender';
		
		SELECT Accountnumber ,
        Acctencryptionkey ,
        Addrverificationcode ,
        Amount ,
        Authentrymode ,
        Authps2000 ,
        Cardnumber ,
        Ccauthcode ,
        Ccauthdate ,
        Ccencryptionkey ,
        Ccmanualauth ,
        Ccrespcode ,
        Cctype ,
        Clrtexttokenflag ,
        Credentialonfile ,
        Desencryptionkey ,
        Expirydate ,
        Method ,
        Paysubtype ,
        L_Header_Id ,
        Xxom_Tender_Data_Seq.Nextval ,
        'New',
		'',
        payment_ref ,
        credit_card_holder_name
        BULK COLLECT INTO 
		l_tender_int_temp
		FROM Dual,
        Json_Table (cur_lob_data(i).Json_Ord_Data, '$.orderTenders[*]' Columns ( Accountnumber VARCHAR2(30) Path '$.accountNumber' , Acctencryptionkey VARCHAR2(100) Path '$.acctEncryptionKey' , Addrverificationcode VARCHAR2(30) Path '$.addrVerificationCode' , Amount NUMBER Path '$.amount' , Authentrymode VARCHAR2(30) Path '$.authEntryMode' , Authps2000 VARCHAR2(30) Path '$.authPS2000' , Cardnumber VARCHAR2(30) Path '$.cardNumber' , Ccauthcode VARCHAR2(30) Path '$.ccAuthCode' , Ccauthdate VARCHAR2(30) Path '$.ccAuthDate' , Ccencryptionkey VARCHAR2(100) Path '$.ccEncryptionKey' , Ccmanualauth VARCHAR2(30) Path '$.ccManualAuth' , Ccrespcode VARCHAR2(30) Path '$.ccRespCode' , Cctype VARCHAR2(30) Path '$.ccType' , Clrtexttokenflag VARCHAR2(1) Path '$.clrTextTokenFlag' , Credentialonfile VARCHAR2(100) Path '$.credentialOnFile' , Desencryptionkey VARCHAR2(100) Path '$.desEncryptionKey' , Expirydate VARCHAR2(30) Path '$.expiryDate' , Method VARCHAR2(30) Path '$.method' , Paysubtype VARCHAR2(30) Path
        '$.paySubType' , payment_ref                                             VARCHAR2(20) Path '$.payment_ref' , credit_card_holder_name VARCHAR2(240) Path '$.credit_card_holder_name' ));
 
		/**/
    
    
	
	l_header_int := l_header_int Multiset Union ALL l_header_int_temp;
	l_line_int := l_line_int Multiset Union ALL  l_line_int_temp;
	l_adjustment_int := l_adjustment_int Multiset Union ALL  l_adjustment_int_temp;
	l_tender_int := l_tender_int Multiset Union ALL  l_tender_int_temp;
	
	EXCEPTION
    WHEN OTHERS THEN
      logit ('Error in Xxoe_Populate_Columns while getting '|| lc_level ||' data of '||lc_order||' into xxom int tables. Error Code:'||SQLCODE);
      logit ('Error Message: '||SQLERRM);
      
	  UPDATE Xxom_Import_Int
      SET Process_Flag    = 'E',
        Status            = 'Error',
        error_description = 'Error while getting '
        ||lc_level
        || ' data'
      WHERE Order_Number = lc_order
      AND Sequence_Num   = lc_seq_num
      AND Process_Flag   = 'P'
      AND status         = 'New';
      
    END;
	END LOOP;
	
	END LOOP;
	CLOSE cur_data;



	BEGIN

		FORALL header IN l_header_int.FIRST .. l_header_int.LAST SAVE EXCEPTIONS
        INSERT INTO Xxom_Order_Headers_Int VALUES l_header_int(header);

		EXCEPTION
		WHEN error_forall THEN
			error_counter := SQL%BULK_EXCEPTIONS.COUNT;

			IF error_counter > 0 THEN
				logit('Total Number of errors while inserting data in Table Xxom_Order_Headers_Int is : ' || error_counter);

				FOR err IN 1 .. error_counter LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
				
/*
				UPDATE Xxom_Import_Int
				SET Process_Flag = 'E',
					Status = 'Error',
					error_description = 'Error While inserting data in table Xxom_Order_Headers_Int '
				WHERE order_number = l_header_int(SQL%BULK_EXCEPTIONS(err).error_index).order_number
				and Process_Flag = 'I'
				AND status       = 'New';
	*/			
				END LOOP;

			END IF;
	END;

	BEGIN

		FORALL line IN l_line_int.FIRST .. l_line_int.LAST SAVE EXCEPTIONS
        INSERT INTO XXOM_ORDER_LINES_INT VALUES l_line_int(line);

	END;
	
	BEGIN

		FORALL tender IN l_tender_int.FIRST .. l_tender_int.LAST SAVE EXCEPTIONS
        INSERT INTO XXOM_ORDER_TENDERS_INT VALUES l_tender_int(tender);

	END;
	
	BEGIN

		FORALL adj IN l_adjustment_int.FIRST .. l_adjustment_int.LAST SAVE EXCEPTIONS
        INSERT INTO XXOM_ORDER_ADJUSTMENTS_INT VALUES l_adjustment_int(adj);

	END;

  UPDATE Xxom_Import_Int
  SET Process_Flag   = 'P',
    status           = 'Processed'
  WHERE Process_Flag = 'I'
  AND status         = 'New'
  AND Sequence_Num BETWEEN P_START_ID AND P_END_ID;
  
  COMMIT;
	
END xxom_load_data;
/* ===========================================================================*
|  PUBLIC PROCEDURE Xxoe_Populate_Columns                                    |
|                                                                            |
|  DESCRIPTION                                                               |
|  This procedure is used to load data into xxom interface table.            |
|  After this it will cal validation procedure to load data in xxoe tables   |
|                                                                            |
|  This procedure will be called directly by Concurrent Program              |
|                                                                            |
* ===========================================================================*/
PROCEDURE Xxoe_Populate_Columns(
    Errbuf OUT VARCHAR2,
    Retcode OUT VARCHAR2)
IS
  L_Header_Id NUMBER;
  lc_order    NUMBER;
  lc_seq_num  NUMBER;
  lc_level    VARCHAR2(50);
  
  cursor cur_data
  IS 
  SELECT Order_Number ,
    Sub_Order_Number ,
    Process_Flag ,
    Status ,
    Sequence_Num,
    Json_Ord_Data
  FROM Xxom_Import_Int
  WHERE Process_Flag = 'I'
  AND status         = 'New';
  
  TYPE cur_data_tab IS TABLE OF cur_data%ROWTYPE INDEX BY PLS_INTEGER;
  cur_lob_data cur_data_tab;
  null_cur_lob_data cur_data_tab;
  
  TYPE tt_header_int IS TABLE OF Xxom_Order_Headers_Int%ROWTYPE ;--INDEX BY PLS_INTEGER;
  l_header_int tt_header_int := tt_header_int();
  l_header_int_temp tt_header_int := tt_header_int();
  empty_header_int tt_header_int := tt_header_int();
  
  TYPE tt_line_int IS TABLE OF XXOM_ORDER_LINES_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_line_int tt_line_int := tt_line_int();
  l_line_int_temp tt_line_int := tt_line_int();
  empty_line_int tt_line_int := tt_line_int();
  
  TYPE tt_tender_int IS TABLE OF XXOM_ORDER_TENDERS_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_tender_int tt_tender_int := tt_tender_int();
  l_tender_int_temp tt_tender_int := tt_tender_int();
  empty_tender_int tt_tender_int := tt_tender_int();
  
  TYPE tt_adjustment_int IS TABLE OF XXOM_ORDER_ADJUSTMENTS_INT%ROWTYPE;-- INDEX BY PLS_INTEGER;
  l_adjustment_int tt_adjustment_int := tt_adjustment_int();
  l_adjustment_int_temp tt_adjustment_int := tt_adjustment_int();
  empty_adjustment_int tt_adjustment_int := tt_adjustment_int();
  
  error_forall   EXCEPTION;
  PRAGMA EXCEPTION_INIT (error_forall, -24381);
  error_counter NUMBER;
  
  l_xxom_limit NUMBER := 100;
  
  L_SQL_STMT VARCHAR2(32767);
  L_TASK_NAME VARCHAR2(1000);
  
  L_XXOM_CHUNK_SIZE VARCHAR2(100);
  L_XXOM_PARALLEL_LEVEL VARCHAR2(100);
  
  l_xxoe_limit NUMBER := 100;
  L_XXOE_CHUNK_SIZE VARCHAR2(100);
  L_XXOE_PARALLEL_LEVEL VARCHAR2(100);
  
  l_org_id NUMBER := FND_PROFILE.VALUE('ORG_ID');

BEGIN
    
	BEGIN 
		SELECT 
		"'XXOM_LIMIT'" AS XXOM_LIMIT,
		"'XXOM_CHUNK_SIZE'" AS XXOM_CHUNK_SIZE,
		"'XXOM_PARALLEL_LEVEL'" AS XXOM_PARALLEL_LEVEL,
		"'XXOE_LIMIT'" AS XXOE_LIMIT,
		"'XXOE_CHUNK_SIZE'" AS XXOE_CHUNK_SIZE,
		"'XXOE_PARALLEL_LEVEL'" AS XXOE_PARALLEL_LEVEL
		INTO l_xxom_limit,L_XXOM_CHUNK_SIZE,L_XXOM_PARALLEL_LEVEL,
		     l_xxoe_limit,L_XXOE_CHUNK_SIZE,L_XXOE_PARALLEL_LEVEL
		FROM
		(SELECT XFTV.SOURCE_VALUE1,
		XFTV.TARGET_VALUE1
		FROM XX_FIN_TRANSLATEDEFINITION XFTD ,
		XX_FIN_TRANSLATEVALUES XFTV
		WHERE XFTD.TRANSLATION_NAME ='XX_AR_CSAS_INTEGRETION'
		AND XFTD.TRANSLATE_ID =XFTV.TRANSLATE_ID
		AND XFTD.ENABLED_FLAG ='Y'
		AND SOURCE_VALUE1 IN ('XXOM_LIMIT','XXOM_CHUNK_SIZE','XXOM_PARALLEL_LEVEL','XXOE_LIMIT','XXOE_CHUNK_SIZE','XXOE_PARALLEL_LEVEL')
		AND XFTV.SOURCE_VALUE2 = l_org_id
		AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
		) PIVOT (MAX(TARGET_VALUE1) FOR SOURCE_VALUE1 IN ('XXOM_LIMIT','XXOM_CHUNK_SIZE','XXOM_PARALLEL_LEVEL','XXOE_LIMIT','XXOE_CHUNK_SIZE','XXOE_PARALLEL_LEVEL')) ;
	EXCEPTION 
	WHEN OTHERS THEN 
		l_xxom_limit			:= 1000;
		L_XXOM_CHUNK_SIZE		:= 1000;
		L_XXOM_PARALLEL_LEVEL	:= 50;
		l_xxoe_limit			:= 500;
		L_XXOE_CHUNK_SIZE		:= 500;
		L_XXOE_PARALLEL_LEVEL	:= 50;
	
	END;
	
	
	-- Call XXOM Table Insert Logic Parallel
	
	BEGIN
		SELECT DBMS_PARALLEL_EXECUTE.generate_task_name
		INTO L_TASK_NAME
		FROM   dual;
	EXCEPTION WHEN OTHERS THEN
	   logit('Erroring while generating task name for XXOM Table Insert - '||SQLERRM);
	END;
	
	BEGIN
		DBMS_PARALLEL_EXECUTE.create_task (task_name => L_TASK_NAME);	
	EXCEPTION WHEN OTHERS THEN
	  logit('Erroring while creating Task for XXOM Table Insert - '||SQLERRM);	 
	END;
	
	logit('---------------------------------------------------------');
	logit('--------------'||'Task Name-'||L_TASK_NAME||'--------------');
	logit('---------------------------------------------------------');
  
	BEGIN
	/* Creation of Chunk by Number Column*/
	DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(
												task_name => L_TASK_NAME,
												sql_stmt  => 'select start_id , end_id from (  
							with rws as (
							SELECT Sequence_Num , ROW_NUMBER() OVER (ORDER BY Sequence_Num) rn
							FROM Xxom_Import_Int
							WHERE status = ''New''
							), grps as ( select r.*,  ceil ( rn / '||L_XXOM_CHUNK_SIZE||' ) grp  from   rws r )
											select grp , min(Sequence_Num) start_id ,max(Sequence_Num) end_id
											  from   grps
											  group  by grp
											  )
											  order by 1',
												by_rowid => FALSE   ); 
	EXCEPTION WHEN OTHERS THEN
		logit('Erroring while creating Chunk for XXOM Table Insert - '||SQLERRM);
	END;

	BEGIN
	logit('Before Executing XXOM Table Insert Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS'));

	l_sql_stmt := 'begin
		Xxoe_Data_Load_Pkg.xxom_load_data(:start_id,:end_id);
		end;				
		';		
	DBMS_PARALLEL_EXECUTE.run_task( task_name      => L_TASK_NAME,
							sql_stmt       => l_sql_stmt,
							language_flag  => DBMS_SQL.NATIVE,
							parallel_level => L_XXOM_PARALLEL_LEVEL);

	logit('After Executing XXOM Table Insert Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS'));						 
	COMMIT;
	EXCEPTION WHEN OTHERS THEN
		logit('Erroring while executing Task for XXOM Table Insert - '||SQLERRM);	
	END;

  
 
  
  
	-- Call Validation Logic Parallel
	BEGIN
		SELECT DBMS_PARALLEL_EXECUTE.generate_task_name
		INTO L_TASK_NAME
		FROM   dual;
	EXCEPTION WHEN OTHERS THEN
	   logit('Erroring while generating task name for XXOE Table Insert - '||SQLERRM);
	END;
	
	BEGIN
		DBMS_PARALLEL_EXECUTE.create_task (task_name => L_TASK_NAME);	
	EXCEPTION WHEN OTHERS THEN
	  logit('Erroring while creating Task '||SQLERRM);	 
	END;
	
	logit('---------------------------------------------------------');
	logit('--------------'||'Task Name-'||L_TASK_NAME||'--------------');
	logit('---------------------------------------------------------');
  
	BEGIN
	/* Creation of Chunk by Number Column*/
	DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL(
												task_name => L_TASK_NAME,
												sql_stmt  => 'select start_id , end_id from (  
												with rws as (
												SELECT header_id , ROW_NUMBER() OVER (ORDER BY header_id) rn
												FROM Xxom_Order_Headers_Int
												WHERE status = ''New''
												), grps as ( select r.*,  ceil ( rn / '||L_XXOE_CHUNK_SIZE||' ) grp  from   rws r )
																select grp , min(header_id) start_id ,max(header_id) end_id
																  from   grps
																  group  by grp
																  )
																  order by 1',
												by_rowid => FALSE   ); 
	EXCEPTION WHEN OTHERS THEN
		logit('Erroring while creating Chunk for XXOE Table Insert - '||SQLERRM);
	END;

	BEGIN
	logit('Before Executing DBMS Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS'));

	l_sql_stmt := 'begin
		Xxoe_Data_Load_Pkg.Xxoe_Validate_Data(:start_id,:end_id);
		end;				
		';		
	
	DBMS_PARALLEL_EXECUTE.run_task( task_name      => L_TASK_NAME,
							sql_stmt       => l_sql_stmt,
							language_flag  => DBMS_SQL.NATIVE,
							parallel_level => L_XXOE_PARALLEL_LEVEL);
	logit('After Executing DBMS Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS'));						 
	--COMMIT;
	EXCEPTION WHEN OTHERS THEN
		logit('Erroring while executing Task for XXOE Table Insert - '||SQLERRM);	
	END;
  
  
  --Xxoe_Validate_Data;
  
EXCEPTION
WHEN OTHERS THEN
  logit ('Error in Proc Xxoe_Populate_Columns Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
END Xxoe_Populate_Columns;
/* ===========================================================================*
|  PUBLIC PROCEDURE Xxoe_Data_Load_Prc                                       |
|                                                                            |
|  DESCRIPTION                                                               |
|  This procedure is used to split json file order wise and load             |
|  each order payload into interface table                                   |
|                                                                            |
|  This procedure will be called directly by Concurrent Program              |
|                                                                            |
* ===========================================================================*/
PROCEDURE Xxoe_Data_Load_Prc(
    Errbuf OUT VARCHAR2,
    Retcode OUT VARCHAR2)
IS
  L_Bfile Bfile;
  L_Clob CLOB;
  Buf Raw(32767 );
  Vc      VARCHAR2(32767 );
  Maxsize INTEGER := 32767 ; -- a char can take up to 4 bytes,
  -- so this is the maximum safe length in chars
  Amt      INTEGER       :=1;
  Amtvc    INTEGER       :=1;
  V_Offset INTEGER       := 1;
  Dir_Name VARCHAR2(150) := 'NEW_SAS_ORD_DIR'; --/app/ebs/ctgsiprjdevgb/xxfin/inbound/hvop
  --arcihve folder need to create
  --/app/ebs/ctgsiprjdevgb/xxfin/archive/hvop
  File_Name        VARCHAR2(150) ;--:= P_File ;--'test_data_3_lines.json';
  L_Ord_Number     VARCHAR2(30);
  L_Sub_Ord_Number VARCHAR2(30);
  L_Ord_Total  NUMBER :=0;
  L_Tax_Total  NUMBER :=0;
  TYPE import_int_tt IS TABLE OF Xxom_Import_Int%ROWTYPE INDEX BY PLS_INTEGER;
  import_int_data_tt import_int_tt;
  null_import_int_data_tt import_int_tt;
  counter NUMBER := 0;
  error_forall   EXCEPTION;
  PRAGMA EXCEPTION_INIT (error_forall, -24381);
  error_counter NUMBER;

  lv_clob clob;
  ln_length number := 0;
  json_data clob;
  SEQ_NUM NUMBER ;
BEGIN
  BEGIN
    SELECT XFTV.TARGET_VALUE3
    INTO Dir_Name
    FROM XX_FIN_TRANSLATEDEFINITION XFTD,
      XX_FIN_TRANSLATEVALUES XFTV
    WHERE XFTD.TRANSLATION_NAME ='XXOM_CSAS_FILE_PROCESS'
    AND XFTV.SOURCE_VALUE1      ='FILE'
    AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
    AND XFTD.ENABLED_FLAG       ='Y'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
  EXCEPTION
  WHEN OTHERS THEN
    Dir_Name := NULL;
    logit ('Error while getting Database Directory from Translation XXOM_CSAS_FILE_PROCESS '||SQLCODE);
  END;
  IF Dir_Name IS NOT NULL THEN
    FOR i IN
    (SELECT FILE_ID ,
      FILE_NAME
    FROM XXOM_CSAS_FILE_NAMES_HIST
    WHERE Status     = 'New'
    AND PROCESS_FLAG = 'N'
    ORDER BY FILE_ID
    )
    LOOP
      File_Name := i.FILE_NAME;
      Buf       := NULL;
      Vc        := NULL;
      Maxsize   := 32767 ; -- a char can take up to 4 bytes,
      -- so this is the maximum safe length in chars
      Amt                             :=1;
      Amtvc                           :=1;
      V_Offset                        := 1;
      L_Clob                          := NULL;
      L_Bfile                         := NULL;
      L_Bfile                         := Bfilename(Dir_Name, File_Name);
	  import_int_data_tt := null_import_int_data_tt;
	  counter := 0;
	  error_counter := 0;

	  DELETE FROM Xxom_Imp_Cache_Int;
	  COMMIT;


      IF (Dbms_Lob.Fileexists(L_Bfile) = 1) THEN
        Dbms_Output.Put_Line('File Exists');
        INSERT
        INTO Xxom_Imp_Cache_Int T VALUES
          (
            Empty_Clob() ,
            Sysdate ,
            FND_GLOBAL.user_id ,
            FND_GLOBAL.user_id ,
            Sysdate
          )
          RETURN Ord_Json_Data
        INTO L_Clob;
        L_Bfile := Bfilename(Dir_Name, File_Name);
        Amt     := Dbms_Lob.Getlength( L_Bfile );
        Dbms_Lob.Fileopen( L_Bfile, Dbms_Lob.File_Readonly );
        WHILE Amt > 0
        LOOP
          IF Amt > Maxsize THEN
            Amt := Maxsize;
          END IF;
          Dbms_Lob.Read( L_Bfile,Amt, V_Offset, Buf );
          Vc    := Utl_Raw.Cast_To_Varchar2(Buf);
          Amtvc := LENGTH(Vc);
          Dbms_Lob.Writeappend( L_Clob, Amtvc, Vc );
          V_Offset := V_Offset                      + Amt;
          Amt      := Dbms_Lob.Getlength( L_Bfile ) - V_Offset + 1;
        END LOOP;
        Dbms_Lob.Fileclose( L_Bfile );
        COMMIT;
        --select count(sequence_num) from xx_om_order_payload;

		lv_clob := NULL;
		json_data := NULL;

		BEGIN

		SELECT Ord_Json_Data into lv_clob FROM Xxom_Imp_Cache_Int;

		ln_length := length(lv_clob);
		WHILE (ln_length >0)
		LOOP
		json_data:= SUBSTR(lv_clob,1,INSTR(lv_clob,chr(10)));
		lv_clob := SUBSTR(lv_clob,INSTR(lv_clob,chr(10))+1);
		ln_length := length(lv_clob);

		BEGIN
            SELECT Ordernumber,
              Ordersubnumber,
			  ordertotal,
			  TotalTax
            INTO L_Ord_Number ,
              L_Sub_Ord_Number ,
			  L_Ord_Total,
			  L_Tax_Total
            FROM Dual ,
              Json_Table (json_data,'$.orderHeader[*]' Columns ( Ordernumber VARCHAR2(30) Path '$.orderNumber'
			                       , Ordersubnumber VARCHAR2(30) Path '$.ordersubNumber'
								   , Ordertotal NUMBER Path '$.orderTotal'
								   , Totaltax NUMBER Path '$.totalTax') );
          EXCEPTION
          WHEN OTHERS THEN
            logit ('Error in Proc Xxoe_Data_Load_Prc while getting order and sub_order_num. Error Code:'||SQLCODE);
            logit ('Error Message: '||SQLERRM);
            L_Ord_Number     :='';
            L_Sub_Ord_Number := '';
			L_Ord_Total :=0;
			L_Tax_Total :=0;
          END;
          counter := counter+1;

		  SELECT Xx_Om_Json_Data_Seq.Nextval INTO SEQ_NUM FROM DUAL;

			import_int_data_tt(counter).Request_Id 			:=  fnd_global.conc_request_id;
			import_int_data_tt(counter).Sequence_Num 		:=  SEQ_NUM;
			import_int_data_tt(counter).Order_Number 		:=  L_Ord_Number;
			import_int_data_tt(counter).Sub_Order_Number 	:=  L_Sub_Ord_Number;
			import_int_data_tt(counter).Json_Ord_Data 		:=  json_data;
			import_int_data_tt(counter).file_name			:=  file_name;
			import_int_data_tt(counter).Creation_Date 		:=  Sysdate;
			import_int_data_tt(counter).Created_By 			:=  FND_GLOBAL.user_id;
			import_int_data_tt(counter).Last_Updated_By 	:=  FND_GLOBAL.user_id;
			import_int_data_tt(counter).Last_Update_Date 	:=  Sysdate;
			import_int_data_tt(counter).OrderTotal 	:=  L_Ord_Total;
			import_int_data_tt(counter).TotalTax 	:=  L_Tax_Total;

		  IF L_Ord_Number IS NOT NULL AND L_Sub_Ord_Number IS NOT NULL THEN

            import_int_data_tt(counter).Process_Flag 		:=  'I' ;
            import_int_data_tt(counter).Status 				:=  'New';
			import_int_data_tt(counter).error_description	:=  '';

		  ELSE

            import_int_data_tt(counter).Process_Flag 		:=  'E' ;
            import_int_data_tt(counter).Status 				:=  'Error';
			import_int_data_tt(counter).error_description	:=  'Order Number/Sub Order Number is null';
		  END IF;
		END LOOP;
		END;

		BEGIN

		FORALL data_counter IN import_int_data_tt.FIRST .. import_int_data_tt.LAST SAVE EXCEPTIONS
        INSERT INTO Xxom_Import_Int VALUES import_int_data_tt(data_counter);

		EXCEPTION
		WHEN error_forall THEN
			error_counter := SQL%BULK_EXCEPTIONS.COUNT;

			IF error_counter > 0 THEN
				logit('Total Number of errors while inserting data in Table XXOM_IMPORT_INT is : ' || error_counter);

				FOR err IN 1 .. error_counter LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
				END LOOP;

				UPDATE Xxom_Import_Int
				SET Process_Flag = 'E',
					Status = 'Error',
					error_description = 'Error While inserting data in table Xxom_Import_Int from file, Please Check Log of Request ID :'||fnd_global.conc_request_id
				WHERE file_name = file_name;

			END IF;
		END;

        UPDATE XXOM_CSAS_FILE_NAMES_HIST
        SET process_flag = 'Y'
        WHERE file_id    = i.file_id;

        COMMIT;
        --xxoe_populate_columns;
      ELSE
        --Dbms_Output.Put_Line('File does not exist');
        logit (i.file_name || ' does not exist in DBA Directory '|| Dir_Name);
      END IF;
    END LOOP;
  ELSE
    Retcode := 2;
    Errbuf  := 'DBA Directory is mandetory setup. Please provide valid DBA Directory name in translation XXOM_CSAS_FILE_PROCESS.';
    logit ('Error in Proc Xxoe_Data_Load_Prc Error Code:'||SQLCODE);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  Retcode := 2;
  Errbuf  := 'Unhandled Exception in Procedeur Xxoe_Data_Load_Prc';
  logit ('Error in Proc Xxoe_Data_Load_Prc Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
END Xxoe_Data_Load_Prc;
/* ===========================================================================*
|  PUBLIC PROCEDURE Xxoe_Validate_Data                                       |
|                                                                            |
|  DESCRIPTION                                                               |
|  This procedure is used to validated and load data into xxoe tables        |
|  each order payload into interface table                                   |
|                                                                            |
|  This procedure will be called from  Xxoe_Populate_Columns proc            |
|                                                                            |
* ===========================================================================*/
PROCEDURE Xxoe_Validate_Data ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 ) 
IS
  L_Header_Id         NUMBER;
  lc_int_order_number VARCHAR2(50) ;
  lc_sub_order_number VARCHAR2(50) ;
  lc_level            VARCHAR2(50);
  lc_int_header_id    NUMBER;
  
  lv_im_pay_term_id NUMBER;
  lv_deposit_term_id NUMBER; 
  
  TYPE import_header_tt IS TABLE OF Xx_Oe_Order_Headers_All%ROWTYPE INDEX BY PLS_INTEGER;
  header_data_tt import_header_tt;
  null_header_data_tt import_header_tt;
  
  header_count NUMBER :=0;
  
  TYPE import_header_attr_tt IS TABLE OF Xx_Oe_Header_Attributes_All%ROWTYPE INDEX BY PLS_INTEGER;
  header_attr_data_tt import_header_attr_tt;
  null_head_attr_data_tt import_header_tt;
  
  head_attr_count NUMBER := 0;
  
  
  TYPE import_line_tt IS TABLE OF XX_OE_ORDER_LINES_ALL%ROWTYPE INDEX BY PLS_INTEGER;
  line_data_tt import_line_tt;
  null_line_data_tt import_line_tt;
  
  line_count NUMBER :=0;
  line_id_seq NUMBER := 0;
  
  TYPE import_line_attr_tt IS TABLE OF XX_OE_LINE_ATTRIBUTES_ALL%ROWTYPE INDEX BY PLS_INTEGER;
  line_attr_data_tt import_line_attr_tt;
  null_line_attr_data_tt import_line_attr_tt;
  
  line_attr_count NUMBER := 0;
  
  
  TYPE import_price_adj_tt IS TABLE OF XX_OE_PRICE_ADJUSTMENTS%ROWTYPE INDEX BY PLS_INTEGER;
  price_adj_data_tt import_price_adj_tt;
  null_price_adj_data_tt import_price_adj_tt;
  
  adj_count NUMBER :=0;
  
  l_tax boolean := FALSE;
  
  TYPE import_payment_tt IS TABLE OF XX_OE_PAYMENTS%ROWTYPE INDEX BY PLS_INTEGER;
  payment_data_tt import_payment_tt;
  null_payment_attr_data_tt import_payment_tt;
  
  payment_count NUMBER := 0;
  
  type ERROR_REC is record 
      (header_id  NUMBER, 
      line_id  NUMBER, 
      order_number Xx_Oe_Order_Headers_All.Order_number%TYPE,
	  error VARCHAR2(100)
	  );
   
   TYPE ERROR_REC_TAB IS TABLE OF ERROR_REC INDEX BY BINARY_INTEGER;
   
   err_rec_tab ERROR_REC_TAB;
   err_count NUMBER :=1;
   
  error_forall   EXCEPTION;
  PRAGMA EXCEPTION_INIT (error_forall, -24381);
  
  -- Custom System Values
	l_PRICE_LIST_ID NUMBER := 0;
	l_ORDER_TYPE_ID NUMBER := 0;
	l_LINE_TYPE_ID NUMBER := 0;
	l_LIST_HEADER_ID NUMBER := 0;
	l_SALESREP_ID NUMBER := 0;
	l_LIMIT NUMBER := 100;
	
	l_org_id NUMBER := FND_PROFILE.VALUE('ORG_ID');
	l_immediate_pay_term NUMBER := 0;
	
	xxom_lookup_obj xxom_lookup_obj_tab := xxom_lookup_obj_tab();
	xxom_org_obj xxom_org_object_table := xxom_org_object_table();
	xxom_payterm xxom_pay_term_obj_table := xxom_pay_term_obj_table();

  
BEGIN

	SELECT xxom_pay_term_obj (lookup_code , attribute6  ,attribute7 )
	BULK COLLECT INTO xxom_payterm
		--INTO   p_credit_card_code
		--	  ,p_payment_type_code	   
		FROM fnd_lookup_values 
		WHERE lookup_type = 'OD_PAYMENT_TYPES'
		--AND lookup_code = p_payment_instrument
		AND enabled_flag = 'Y'
		AND NVL(end_date_active,SYSDATE+1)>SYSDATE;
    


	SELECT xxom_org_object(organization_id , attribute1)
	BULK COLLECT INTO  xxom_org_obj
	FROM   hr_all_organization_units ;
	 
	SELECT XXOM_LOOKUP_OBJECT(lookup_type,lookup_code,attribute6 	)
	BULK COLLECT INTO  xxom_lookup_obj
		FROM   fnd_lookup_values 
		WHERE  1=1
		AND    lookup_type in ( 'OD_CSAS_SHIP_METHODS' ,'OD_CSAS_ORDER_SOURCE')
		AND    view_application_id = 222
    and enabled_flag = 'Y'
    and NVL(END_DATE_ACTIVE,SYSDATE+1)>SYSDATE;
    

	BEGIN
		SELECT term_id
		INTO   lv_im_pay_term_id
		FROM   ra_terms_vl
		WHERE  NAME = 'IMMEDIATE';
	EXCEPTION
		WHEN OTHERS
		THEN
			lv_im_pay_term_id := NULL;
			logit('IMMEDIATE payment term not found in RA_TERMS_VL');
	END;

-- Get Term_id for deposits 
	BEGIN
		SELECT term_id
		INTO   lv_deposit_term_id
		FROM   ra_terms_vl
		WHERE  NAME = 'SA_DEPOSIT';
	EXCEPTION
		WHEN OTHERS
		THEN
			lv_deposit_term_id := NULL;
	END;
	
-- Get Term_id for immediate 

	select term_id INTO l_immediate_pay_term from RA_TERMS where name = 'IMMEDIATE' and NVL(end_date_active,SYSDATE+1)>SYSDATE	;
	
	
	FOR cust_value in (SELECT XFTV.SOURCE_VALUE1 , XFTV.TARGET_VALUE1
						FROM XX_FIN_TRANSLATEDEFINITION XFTD , XX_FIN_TRANSLATEVALUES XFTV
						WHERE XFTD.TRANSLATION_NAME ='XX_AR_CSAS_INTEGRETION'
						AND XFTD.TRANSLATE_ID       =XFTV.TRANSLATE_ID
						AND XFTD.ENABLED_FLAG       ='Y'
						AND XFTV.SOURCE_VALUE2 = l_org_id
						AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)) 
	LOOP
	BEGIN

		IF cust_value.SOURCE_VALUE1 = 'PRICE_LIST_ID'
		THEN
			l_PRICE_LIST_ID := cust_value.TARGET_VALUE1;	
		ELSIF cust_value.SOURCE_VALUE1 = 'ORDER_TYPE_ID'
		THEN
			l_ORDER_TYPE_ID := cust_value.TARGET_VALUE1;
		ELSIF cust_value.SOURCE_VALUE1 = 'LINE_TYPE_ID'
		THEN
			l_LINE_TYPE_ID := cust_value.TARGET_VALUE1;
		ELSIF cust_value.SOURCE_VALUE1 = 'LIST_HEADER_ID'
		THEN
			l_LIST_HEADER_ID := cust_value.TARGET_VALUE1;
		ELSIF cust_value.SOURCE_VALUE1 = 'SALESREP_ID'
		THEN
			l_SALESREP_ID := cust_value.TARGET_VALUE1;
		ELSIF cust_value.SOURCE_VALUE1 = 'LIMIT'
		THEN
			l_LIMIT := cust_value.TARGET_VALUE1;
		END IF;
	EXCEPTION	
	WHEN OTHERS THEN
		logit ('Exception in Proc Xxoe_Validate_Data. While getting System Variables from translation XX_AR_CSAS_INTEGRETION, Error Code:'||SQLCODE);
	END;	
	END LOOP;
	
	

  FOR I  IN
  (SELECT *
  FROM Xxom_Order_Headers_Int
  WHERE Status = 'New'
  AND HEADER_ID BETWEEN P_START_ID AND P_END_ID
  ORDER BY Header_Id
  )
  LOOP
    lc_int_order_number := I.Ordernumber ;
    lc_sub_order_number := I.Ordersubnumber;
    lc_int_header_id    := I.Header_Id;
    BEGIN
      SELECT Xx_Oe_Ord_Header_Seq.Nextval INTO L_Header_Id FROM Dual;
      lc_level := 'Order Header';
	  header_count := header_count+1;
	  
	  l_tax := TRUE;
	  
	  header_data_tt(header_count).Header_Id 				:= L_Header_Id ;
      header_data_tt(header_count).Order_Type_Id 			:= l_ORDER_TYPE_ID;
      header_data_tt(header_count).Order_Number 			:= I.Ordernumber || I.Ordersubnumber;
      header_data_tt(header_count).ORIG_SYS_DOCUMENT_REF 	:= I.Ordernumber || I.Ordersubnumber;
      header_data_tt(header_count).Version_Number 		:= 1;
      header_data_tt(header_count).Order_Category_Code 	:= 'MIXED';
      header_data_tt(header_count).Open_Flag 				:= 'Y';
      header_data_tt(header_count).Booked_Flag 			:= 'Y';
      header_data_tt(header_count).Creation_Date 			:= SYSDATE;
      header_data_tt(header_count).Created_By 			:= FND_GLOBAL.user_id;
      header_data_tt(header_count).Last_Updated_By 		:= FND_GLOBAL.user_id;
      header_data_tt(header_count).Last_Update_Date 		:= SYSDATE;
      --header_data_tt(header_count).Order_Source_Id 		:= NULL;
      header_data_tt(header_count).Ordered_Date 			:= TO_DATE(i.ORDERDATE,'RRRR-MM-DD');
      header_data_tt(header_count).PRICING_DATE			:= TO_DATE(i.ORDERDATE,'RRRR-MM-DD');
      header_data_tt(header_count).Tax_Exempt_Number 		:= I.Customertaxexmptid;
      header_data_tt(header_count).Transactional_Curr_Code:= I.Ordercurrency;
      header_data_tt(header_count).Cust_Po_Number 		:= I.Custponumber;
      --header_data_tt(header_count).Ship_From_Org_Id 		:= I.Invlocid;
      --header_data_tt(header_count).Salesrep_Id 			:= NULL; 
      header_data_tt(header_count).Sales_Channel_Code 	:= I.Saleschannel;
      header_data_tt(header_count).Drop_Ship_Flag 		:= I.Dropshipflag ;--DECODE(NVL(I.Dropshipflag,'N'),'Y','Y','N');
      header_data_tt(header_count).FREIGHT_CARRIER_CODE	:= I.DELIVERYMETHOD;
      header_data_tt(header_count).ORG_ID					:= l_org_id;
      header_data_tt(header_count).REQUEST_ID				:= FND_GLOBAL.CONC_REQUEST_ID;
      header_data_tt(header_count).REQUEST_DATE			:= SYSDATE;
	  /*New Mapping*/
	  header_data_tt(header_count).FLOW_STATUS_CODE		:= 'CLOSED';
	  header_data_tt(header_count).PRICING_DATE			:= SYSDATE;
	  --header_data_tt(header_count).SHIPPING_METHOD_CODE 	:= get_ship_method(I.DELIVERYMETHOD);
	  --header_data_tt(header_count).ORDER_SOURCE_ID 		:= get_order_source(I.orderSource);
	  --header_data_tt(header_count).ORDER_TYPE_ID			:= get_order_type(I.orderType);
	  header_data_tt(header_count).Salesrep_Id 			:= get_salesrep_for_legacyrep ( l_org_id, I.Salesperson , SYSDATE , l_SALESREP_ID) ;
	  --header_data_tt(header_count).Ship_From_Org_Id 		:= load_org_details(I.Invlocid);
	  header_data_tt(header_count).sold_from_org_id		:= l_org_id;
	  
	  BEGIN
	  
	   SELECT organization_id
        INTO   header_data_tt(header_count).Ship_From_Org_Id 
        FROM   table(cast(xxom_org_obj as xxom_org_object_table)) 
        WHERE  attribute1 = I.Invlocid;
	  
	  EXCEPTION 
	  WHEN OTHERS THEN 
		header_data_tt(header_count).Ship_From_Org_Id  := '';
	  END ;
	  
	  BEGIN 
		select attribute6
		INTO header_data_tt(header_count).SHIPPING_METHOD_CODE 
		from table(cast(xxom_lookup_obj as xxom_lookup_obj_tab))
		WHERE lookup_code = I.DELIVERYMETHOD
		and lookup_type = 'OD_CSAS_SHIP_METHODS';
		
	  EXCEPTION 
	  WHEN OTHERS THEN 
		header_data_tt(header_count).SHIPPING_METHOD_CODE  := '';
	  END;
	  
	   BEGIN 
		select attribute6
		INTO header_data_tt(header_count).ORDER_SOURCE_ID 
		from table(cast(xxom_lookup_obj as xxom_lookup_obj_tab))
		WHERE lookup_code = I.orderSource
		and lookup_type = 'OD_CSAS_ORDER_SOURCE';
	   EXCEPTION 
	  WHEN OTHERS THEN 
		header_data_tt(header_count).ORDER_SOURCE_ID  := '';
	  END;
	  
	  
	  get_customer_details (I.accountId ||'-00001-A0' , 'A0',header_data_tt(header_count).SOLD_TO_ORG_ID);
	  	  
	  	  
	  IF header_data_tt(header_count).SOLD_TO_ORG_ID IS NOT NULL THEN 
		get_def_shipto(header_data_tt(header_count).SOLD_TO_ORG_ID , header_data_tt(header_count).SHIP_TO_ORG_ID);
		
		get_def_billto(header_data_tt(header_count).SOLD_TO_ORG_ID , header_data_tt(header_count).INVOICE_TO_ORG_ID);
		
		get_def_soldtocontact(header_data_tt(header_count).SOLD_TO_ORG_ID , header_data_tt(header_count).SOLD_TO_CONTACT_ID);
		
	  END IF;
	  
	    IF NVL(I.depositAmount,0) > 0
		THEN
			header_data_tt(header_count).payment_term_id := lv_deposit_term_id;
		ELSE
			-- Get the payment term from Customer Account setup
			header_data_tt(header_count).payment_term_id := payment_term(header_data_tt(header_count).SOLD_TO_ORG_ID, l_immediate_pay_term );
		END IF;

	  
	  IF I.Customertaxexmptid IS NOT NULL THEN 
		header_data_tt(header_count).TAX_EXEMPT_REASON_CODE := 'EXEMPT';
        header_data_tt(header_count).TAX_EXEMPT_FLAG := 'E';
      ELSE
        header_data_tt(header_count).TAX_EXEMPT_REASON_CODE := NULL;
        header_data_tt(header_count).TAX_EXEMPT_FLAG := 'S';
      END IF;

	  
	  lc_level := 'Order Header Attribute';
      
	  
	  head_attr_count := head_attr_count +1;
	  
		header_attr_data_tt(head_attr_count).Header_Id 			:= L_Header_Id ;
		header_attr_data_tt(head_attr_count).canada_pst_tax		:= I.ORDERPSTTAX;
		header_attr_data_tt(head_attr_count).Release_Number 	:= I.Orderrelease ;
		header_attr_data_tt(head_attr_count).CUST_DEPT_NO		:= I.ORDERDEPARTMENT;
		header_attr_data_tt(head_attr_count).DESKTOP_LOC_ADDR	:= I.orderDesktop;
		header_attr_data_tt(head_attr_count).Gift_Flag 			:= I.Giftflag ;
		header_attr_data_tt(head_attr_count).Alt_Delv_Address  	:= I.Alternateshipper ;
		header_attr_data_tt(head_attr_count).COMMISIONABLE_IND 	:= I.COMMISIONFLAG;
		--header_attr_data_tt(head_attr_count).--Created_By_Store_Id :=--I.Salelocid ;
		--header_attr_data_tt(head_attr_count).--Paid_At_Store_Id :=--I.Salelocid ;
		header_attr_data_tt(head_attr_count).Spc_Card_Number  	:= I.Spcacctnumber ;
		header_attr_data_tt(head_attr_count).LOYALTY_ID			:= I.LOYALTYID;
		header_attr_data_tt(head_attr_count).Created_By_Id		:= I.Createbyid ;
		header_attr_data_tt(head_attr_count).Delivery_Method	:= I.Deliverymethod ;
		header_attr_data_tt(head_attr_count).DELIVERY_CODE		:= I.OrderDelcode;
		header_attr_data_tt(head_attr_count).Cust_Pref_Email	:= I.Soldto_Contactemailaddr ;
		--header_attr_data_tt(head_attr_count).Cust_Pref_Phone	:= I.Soldto_Contactphone ;
		--header_attr_data_tt(head_attr_count).Cust_Contact_Name	:= I.Soldto_contactName ;
		--header_attr_data_tt(head_attr_count).ORIG_CUST_NAME		:= I.Soldto_contactName  ;
		header_attr_data_tt(head_attr_count).Od_Order_Type		:= I.Ordertype ;
		header_attr_data_tt(head_attr_count).Ship_To_Name		:= I.Shipping_Shiptoname ;
		header_attr_data_tt(head_attr_count).Bill_To_Name 		:= I.orig_cust_name;--I.Billing_Billtoname ;
		header_attr_data_tt(head_attr_count).Ship_To_Sequence 	:= I.Shipping_Addressseq ;
		header_attr_data_tt(head_attr_count).Ship_To_Address1	:= I.Shipping_Line1 ;
		header_attr_data_tt(head_attr_count).Ship_To_Address2 	:= I.Shipping_Line2 ;
		header_attr_data_tt(head_attr_count).Ship_To_City 		:= I.Shipping_City ;
		header_attr_data_tt(head_attr_count).Ship_To_State		:= I.State ;
		header_attr_data_tt(head_attr_count).Ship_To_Country	:= I.Shipping_Country ;
		header_attr_data_tt(head_attr_count).ship_to_county		:= I.Shipping_County;
		header_attr_data_tt(head_attr_count).Ship_To_Zip		:= I.Zip ;
		header_attr_data_tt(head_attr_count).Tax_Rate 			:= I.Taxpercent ;
		header_attr_data_tt(head_attr_count).Order_Action_Code 	:= I.Actioncode ;
		--header_attr_data_tt(head_attr_count).Order_Start_Time 	:= to_date(i.ORDERDATE || ' '||SUBSTR(LPAD(i.ORDERCREATETIME,8,0),1,6) , 'RRRR-MM-DD hh24miss') ;
		--header_attr_data_tt(head_attr_count).Order_End_Time 	:= to_date(i.ORDERDATE|| ' '||SUBSTR(LPAD(i.ORDERENDTIME,8,0),1,6) , 'RRRR-MM-DD hh24miss') ;
		header_attr_data_tt(head_attr_count).Order_Taxable_Cd  	:= I.Taxableflag ;
		header_attr_data_tt(head_attr_count).ACTION_CODE		:= I.ACTIONCODE;
		header_attr_data_tt(head_attr_count).Override_Delivery_Chg_Cd 	:= I.Orderdeloverridecode ;
		header_attr_data_tt(head_attr_count).Ship_To_Geocode 			:= I.Geolocation ;
		header_attr_data_tt(head_attr_count).Cust_Dept_Description 		:= I.Deptdescription ;
		header_attr_data_tt(head_attr_count).Aops_Geo_Code 				:= I.Geolocation ;
		header_attr_data_tt(head_attr_count).External_Transaction_Number:= I.Extordnumber ;
		header_attr_data_tt(head_attr_count).Freight_Tax_Rate 			:= I.Freighttaxpercent ;
		header_attr_data_tt(head_attr_count).Freight_Tax_Amount 		:= I.Freighttaxamt ;
		header_attr_data_tt(head_attr_count).order_total				:= I.Ordertotal;
		header_attr_data_tt(head_attr_count).Creation_Date 				:= Sysdate ;
		header_attr_data_tt(head_attr_count).Created_By 				:= FND_GLOBAL.user_id ;
		header_attr_data_tt(head_attr_count).Last_Update_Date 			:= Sysdate ;
		header_attr_data_tt(head_attr_count).Last_Updated_By			:= FND_GLOBAL.user_id;
		
		header_attr_data_tt(head_attr_count).COST_CENTER_DEPT 	:= I.ORDERDEPARTMENT;
		header_attr_data_tt(head_attr_count).DESK_DEL_ADDR		:= I.orderDesktop;
		header_attr_data_tt(head_attr_count).Cust_Contact_Name	:= I.Soldto_contactName ;
		header_attr_data_tt(head_attr_count).Cust_Pref_Phone	:= I.Soldto_Contactphone ;
		header_attr_data_tt(head_attr_count).Cust_Pref_Phextn 	:= I.Soldto_Contactphoneext ;
		header_attr_data_tt(head_attr_count).order_start_time	:=	to_date(i.ORDERDATE|| ' '||'120000' , 'RRRR-MM-DD hh24miss') ;
		header_attr_data_tt(head_attr_count).order_end_time		:= to_date(i.ORDERDATE|| ' '||'120000' , 'RRRR-MM-DD hh24miss') ;
		header_attr_data_tt(head_attr_count).ORIG_CUST_NAME 	:=  I.orig_cust_name ;-- I.Soldto_contactName ;
		/*
		BEGIN
				SELECT party_name
				INTO   header_attr_data_tt(head_attr_count).ORIG_CUST_NAME 
				FROM   hz_cust_accounts hca,
					   hz_parties hp
				WHERE  hca.cust_account_id = header_data_tt(header_count).SOLD_TO_ORG_ID AND hca.party_id = hp.party_id;
			EXCEPTION
				WHEN OTHERS
				THEN
					header_attr_data_tt(head_attr_count).ORIG_CUST_NAME := NULL;
			 END;
		*/
	  FOR Line IN  (SELECT xol.* , 
						(xol.Price + (NVL(
						(SELECT SUM(xoadj.acctingCouponAmount)
						FROM Xxom_Order_Adjustments_Int xoadj
						WHERE xoadj.Header_Id = xol.Header_Id
						AND xoadj.LINENUM     = xol.Linenumber
						),0)/decode(xol.Quantity,0,1,xol.Quantity)) ) Unit_Selling_Price,
						xoa.ACCTINGCOUPONAMOUNT adj_ACCTINGCOUPONAMOUNT, 
						xoa.ADJUSTMENTCODE adj_ADJUSTMENTCODE, 
						xoa.ADJUSTMENTSEQNUM adj_ADJUSTMENTSEQNUM , 
						xoa.COUPONID adj_COUPONID, 
						xoa.DISPLAYCOUPONAMOUNT adj_DISPLAYCOUPONAMOUNT,  
						xoa.EMPLOYEEID adj_EMPLOYEEID, 
						xoa.LINENUM adj_LINENUM
						, (xoa.displayCouponAmount)/decode(xol.Quantity,0,1,xol.Quantity) Adjusted_Amount
						 FROM Xxom_Order_Lines_Int  xol , Xxom_Order_Adjustments_Int xoa
						  WHERE xol.Header_Id = xoa.Header_Id (+)
						  AND xol.Header_Id = I.Header_Id
						  and xol.Linenumber = xoa.LINENUM (+)
						  AND xol.status      = 'New' 
						  ORDER BY xol.Linenumber)
	  LOOP
	  
		lc_level := 'Order Line';
		line_count := line_count +1;
		line_id_seq := Xx_Oe_Ord_Line_Seq.Nextval;
				
		line_data_tt(line_count).Line_Id 	:=	line_id_seq	;
		line_data_tt(line_count).Header_Id 	:=	L_Header_Id	;
		line_data_tt(line_count).Line_Type_Id 	:=	l_Line_Type_Id	;
		line_data_tt(line_count).Line_Number 	:=	Line.Linenumber	;
		line_data_tt(line_count).ORIG_SYS_DOCUMENT_REF	:=	I.Ordernumber|| I.Ordersubnumber	;
		line_data_tt(line_count).ORIG_SYS_LINE_REF	:=	Line.Linenumber	;
		--line_data_tt(line_count).Inventory_Item_Id 	:=	1	;
		line_data_tt(line_count).Shipment_Number 	:=	Line.Linenumber	;
		line_data_tt(line_count).Creation_Date 	:=	Sysdate 	;
		line_data_tt(line_count).Created_By 	:=	FND_GLOBAL.user_id	;
		line_data_tt(line_count).Last_Update_Date 	:=	Sysdate	;
		line_data_tt(line_count).Last_Updated_By 	:=	FND_GLOBAL.user_id	;
		line_data_tt(line_count).Line_Category_Code 	:=	'ORDER';--NVL(Line.Itemtype,'N')	;
		line_data_tt(line_count).Open_Flag 	:=	'N'	;
		line_data_tt(line_count).Booked_Flag 	:=	'N' 	;
		line_data_tt(line_count).User_Item_Description 	:=	Line.Sku 	;
		--line_data_tt(line_count).Ordered_Item 	:=	Line.Sku 	;
		line_data_tt(line_count).Order_Quantity_Uom 	:=	Line.Unit 	;
		line_data_tt(line_count).INVOICED_QUANTITY	:=	Line.Shipquantity	;
		line_data_tt(line_count).Shipped_Quantity 	:=	Line.Shipquantity 	;
		line_data_tt(line_count).Ordered_Quantity 	:=	Line.Quantity 	;
		line_data_tt(line_count).Cust_Po_Number 	:=	Line.Polinenum 	;
		line_data_tt(line_count).Unit_Selling_Price :=	Line.Unit_Selling_Price	;
		line_data_tt(line_count).Unit_List_Price 	:=	Line.Price 	;
		line_data_tt(line_count).Tax_Value 	:=	I.Totaltax 	;
		line_data_tt(line_count).SCHEDULE_SHIP_DATE 	:=	TO_DATE(I.PICKUPORDELIVERYDATE,'YYYY-MM-DD') 	;
		line_data_tt(line_count).PRICING_QUANTITY 	:=	line.shipquantity 	;
		line_data_tt(line_count).PRICING_QUANTITY_UOM 	:=	Line.unit 	;
		line_data_tt(line_count).FULFILLED_QUANTITY 	:=	Line.shipquantity 	;
		line_data_tt(line_count).ACTUAL_SHIPMENT_DATE 	:=	TO_DATE(I.SALEDATE,'YYYY-MM-DD') 	;
		line_data_tt(line_count).ORG_ID	:=	l_org_id	;
		line_data_tt(line_count).REQUEST_ID 	:=	fnd_global.conc_request_id 	;
		line_data_tt(line_count).REQUEST_DATE	:=	SYSDATE	;
		line_data_tt(line_count).DROP_SHIP_FLAG	:=	I.Dropshipflag 	;
		
		line_data_tt(line_count).PRICE_LIST_ID		:= l_PRICE_LIST_ID;
		line_data_tt(line_count).Ordered_Item 		:= Line.enteredProductCode 	;
		line_data_tt(line_count).SHIP_FROM_ORG_ID 	:= header_data_tt(header_count).Ship_From_Org_Id;
		line_data_tt(line_count).SHIP_TO_ORG_ID  	:= header_data_tt(header_count).SHIP_TO_ORG_ID;
		line_data_tt(line_count).INVOICE_TO_ORG_ID  := header_data_tt(header_count).INVOICE_TO_ORG_ID;
		line_data_tt(line_count).SOLD_TO_ORG_ID 	:= header_data_tt(header_count).SOLD_TO_ORG_ID;
		line_data_tt(line_count).ITEM_TYPE_CODE 	:= 'STANDARD';
		line_data_tt(line_count).PAYMENT_TERM_ID 	:=  header_data_tt(header_count).payment_term_id;
		
		line_data_tt(line_count).SCHEDULE_ARRIVAL_DATE := line_data_tt(line_count).SCHEDULE_SHIP_DATE;
		line_data_tt(line_count).SALESREP_ID := header_data_tt(header_count).Salesrep_Id;

		line_data_tt(line_count).SOURCE_TYPE_CODE := 'INTERNAL';
		line_data_tt(line_count).ITEM_IDENTIFIER_TYPE := 'INT';
		line_data_tt(line_count).ORDER_SOURCE_ID := header_data_tt(header_count).ORDER_SOURCE_ID;


		line_data_tt(line_count).Cust_Po_Number := I.Custponumber;
		line_data_tt(line_count).PRICING_DATE  := SYSDATE;
		BEGIN 
			 SELECT inventory_item_id
             INTO  line_data_tt(line_count).Inventory_Item_Id
             FROM mtl_system_items_b
             WHERE segment1 = TRIM(Line.Sku)
			 AND ROWNUM = 1;
			 
		EXCEPTION 
		WHEN OTHERS THEN		
			line_data_tt(line_count).Inventory_Item_Id := -1;
		END;
		
		lc_level := 'Order Line Attribute';
		line_attr_count := line_attr_count +1;
		
		line_attr_data_tt (line_attr_count).Line_Id 			:=	line_id_seq	;
		line_attr_data_tt (line_attr_count).Creation_Date 		:=	Sysdate 	;
		line_attr_data_tt (line_attr_count).Created_By 			:=	FND_GLOBAL.user_id 	;
		line_attr_data_tt (line_attr_count).Last_Update_Date 	:=	Sysdate 	;
		line_attr_data_tt (line_attr_count).Last_Updated_By 	:=	FND_GLOBAL.user_id 	;
		line_attr_data_tt (line_attr_count).Cost_Center_Dept 	:=	Line.Costcentercode 	;
		line_attr_data_tt (line_attr_count).Config_Code 		:=	Line.Configurationid 	;
		line_attr_data_tt (line_attr_count).Vendor_Product_Code :=	Line.Vendorproductcode 	;
		line_attr_data_tt (line_attr_count).Contract_Details 	:=	Line.Contractcode 	;
		line_attr_data_tt (line_attr_count).taxable_flag		:=	I.TAXABLEFLAG	;
		line_attr_data_tt (line_attr_count).COMMISIONABLE_IND	:=	I.COMMISIONFLAG	;
		line_attr_data_tt (line_attr_count).Line_Comments 		:=	Line.Linecomments 	;
		line_attr_data_tt (line_attr_count).Backordered_Qty 	:=	Line.Backorderquantity 	;
		line_attr_data_tt (line_attr_count).Sku_Dept 			:=	Line.Department 	;
		line_attr_data_tt (line_attr_count).Item_Source 		:=	Line.Itemsource 	;
		line_attr_data_tt (line_attr_count).Average_Cost 		:=	Line.Avgcost 	;
		line_attr_data_tt (line_attr_count).Po_Cost 			:=	Line.Pocost 	;
		line_attr_data_tt (line_attr_count).Sku_List_Price 		:=	Line.listprice	;
		line_attr_data_tt (line_attr_count).UNIT_ORIG_SELLING_PRICE	:=	Line.Originalitemprice 	;
		line_attr_data_tt (line_attr_count).Wholesaler_Item 	:=	Line.Wholesalerproductnumber 	;
		line_attr_data_tt (line_attr_count).Gsa_Flag 			:=	Line.Gsaflag 	;
		line_attr_data_tt (line_attr_count).Price_Change_Reason_Cd 	:=	Line.Priceoverridecode 	;
		line_attr_data_tt (line_attr_count).CAMPAIGN_CD			:=	Line.campaignCode	;
		line_attr_data_tt (line_attr_count).Cust_Dept_Description 	:=	Line.Costcenterdescription 	;
		line_attr_data_tt (line_attr_count).Upc_Code 			:=	Line.Upc 	;
		line_attr_data_tt (line_attr_count).Price_Type 			:=	Line.Pricetype 	;
		line_attr_data_tt (line_attr_count).Kit_Sku 			:=	Line.Kitsku 	;
		line_attr_data_tt (line_attr_count).Kit_Qty 			:=	Line.Kitquantity 	;
		line_attr_data_tt (line_attr_count).Kit_Vend_Product_Code 	:=	Line.Kitvpc 	;
		line_attr_data_tt (line_attr_count).Kit_Sku_Dept 		:=	Line.Kitdept 	;
		line_attr_data_tt (line_attr_count).Kit_Seqnum			:=	Line.Kitseq	;
		line_attr_data_tt (line_attr_count).item_Description	:=	Line.ITEMDESCRIPTION	;
		
		line_attr_data_tt (line_attr_count).Release_Num 		:= I.Orderrelease ;
		line_attr_data_tt (line_attr_count).DESKTOP_DEL_ADDR 	:= I.orderDesktop;
		
		
		
		lc_level         := 'Order Price Adjustment';
		
		IF line.ADJ_LINENUM IS NOT NULL THEN 
			lc_level         := 'Order Price Adjustment';
			adj_count := adj_count +1;
			
			price_adj_data_tt(adj_count).Price_Adjustment_Id 	:=	Xx_Oe_Ord_adjustment_Seq.Nextval;
			price_adj_data_tt(adj_count).Creation_Date 			:=	Sysdate 	;
			price_adj_data_tt(adj_count).Created_By 			:=	FND_GLOBAL.user_id 	;
			price_adj_data_tt(adj_count).Last_Update_Date 		:=	Sysdate 	;
			price_adj_data_tt(adj_count).Last_Updated_By 		:=	FND_GLOBAL.user_id 	;
			price_adj_data_tt(adj_count).Header_Id 				:=	L_Header_Id 	;
			price_adj_data_tt(adj_count).Automatic_Flag 		:=	'N' 	;
			price_adj_data_tt(adj_count).Line_Id 				:=	line_id_seq	;
			price_adj_data_tt(adj_count).Adjusted_Amount 		:=	Line.Adjusted_Amount 	;
			price_adj_data_tt(adj_count).ATTRIBUTE8 			:=	Line.adj_adjustmentCode 	;
			price_adj_data_tt(adj_count).ATTRIBUTE6 			:=	Line.adj_COUPONID 	;
			price_adj_data_tt(adj_count).ATTRIBUTE10 			:=	Line.adj_displaycouponamount 	;
			price_adj_data_tt(adj_count).OPERAND 				:=	Line.adj_displaycouponamount 	;
			price_adj_data_tt(adj_count).ARITHMETIC_OPERATOR 	:=	'LUMPSUM' 	;
			price_adj_data_tt(adj_count).LIST_LINE_TYPE_CODE 	:=	'DIS' 	;
			price_adj_data_tt(adj_count).REQUEST_ID				:=	fnd_global.conc_request_id	;
			
			price_adj_data_tt(adj_count).LIST_HEADER_ID := l_LIST_HEADER_ID;
			
			
			BEGIN 
				SELECT list_line_id
                INTO   price_adj_data_tt(adj_count).LIST_LINE_ID
                FROM   qp_list_lines
                WHERE  list_header_id = l_LIST_HEADER_ID AND ROWNUM = 1;
			EXCEPTION  
			WHEN OTHERS THEN 
				price_adj_data_tt(adj_count).LIST_LINE_ID := -1;
			END;
			
			
		END IF;
		
		IF NVL(I.Totaltax,0) >0 AND l_tax THEN
        lc_level          := 'Order Price Adjustment Tax';
		l_tax := FALSE;

            price_adj_data_tt(adj_count).PRICE_ADJUSTMENT_ID 	:= Xx_Oe_Ord_adjustment_Seq.Nextval;
            price_adj_data_tt(adj_count).CREATION_DATE 		 	:= SYSDATE;
            price_adj_data_tt(adj_count).CREATED_BY 			:= FND_GLOBAL.user_id;
            price_adj_data_tt(adj_count).LAST_UPDATE_DATE		:= Sysdate;
            price_adj_data_tt(adj_count).LAST_UPDATED_BY 		:= FND_GLOBAL.user_id;
            price_adj_data_tt(adj_count).HEADER_ID 				:= L_Header_Id;
            price_adj_data_tt(adj_count).AUTOMATIC_FLAG 		:= 'Y';
            price_adj_data_tt(adj_count).LINE_ID 				:= line_id_seq;
            price_adj_data_tt(adj_count).LIST_LINE_TYPE_CODE 	:= 'TAX';
            price_adj_data_tt(adj_count).ARITHMETIC_OPERATOR 	:= 'AMT';
            price_adj_data_tt(adj_count).TAX_CODE 				:= 'Location';
            price_adj_data_tt(adj_count).ADJUSTED_AMOUNT 		:= I.Totaltax ;
            price_adj_data_tt(adj_count).REQUEST_ID 			:= fnd_global.conc_request_id;

           
      END IF;
		
	  END LOOP;
	  
	  FOR payment IN  (SELECT Xx_Oe_Ord_Payment_Seq.Nextval Payment_Trx_Id,
							xot.Clrtexttokenflag ,
							xot.Ccmanualauth ,
							xot.Authps2000 ,
							xot.Cctype ,
							xot.Ccauthcode ,
							xot.Method ,
							xot.Ccencryptionkey ,
							--SUBSTR (xot.credit_card_holder_name ,1,80) credit_card_holder_name,
							SUBSTR(I.orig_cust_name,1,80) credit_card_holder_name,
							DECODE(NVL(xot.EXPIRYDATE,'00/00'),'00/00',NULL, TO_DATE('01/'||xot.EXPIRYDATE,'dd/mm/rr')) EXPIRYDATE,
							xot.Accountnumber ,
							xot.Amount ,
							xot.payment_ref 
							FROM Xxom_Order_Tenders_Int xot
							WHERE xot.Header_Id = I.Header_Id
							AND xot.status      = 'New')
		LOOP
	  
			lc_level := 'Order Payment';
			payment_count := payment_count +1 ;
			
			payment_data_tt(payment_count).Payment_Trx_Id 				:=	payment.Payment_Trx_Id 	;
			payment_data_tt(payment_count).Header_Id 					:=	L_Header_Id 	;
			payment_data_tt(payment_count).Creation_Date 				:=	Sysdate	;
			payment_data_tt(payment_count).Created_By 					:=	FND_GLOBAL.user_id	;
			payment_data_tt(payment_count).Last_Update_Date 			:=	Sysdate	;
			payment_data_tt(payment_count).Last_Updated_By 			:=	FND_GLOBAL.user_id 	;
			payment_data_tt(payment_count).Attribute3 					:=	payment.Clrtexttokenflag 	;
			payment_data_tt(payment_count).Attribute6 					:=	payment.Ccmanualauth 	;
			payment_data_tt(payment_count).Attribute8 					:=	payment.Authps2000 	;
			payment_data_tt(payment_count).Attribute11 				:=	payment.Cctype 	;
			payment_data_tt(payment_count).Attribute13 				:=	payment.Ccauthcode 	;
			--payment_data_tt(payment_count).Payment_Type_Code 			:=	payment.Method 	;
			--payment_data_tt(payment_count).Credit_Card_Code 			:=	payment.Cctype 	;
			payment_data_tt(payment_count).Credit_Card_Number 			:=	payment.Ccencryptionkey 	;
			payment_data_tt(payment_count).Credit_Card_Holder_Name 	:=	payment.credit_card_holder_name ;
			payment_data_tt(payment_count).CREDIT_CARD_EXPIRATION_DATE :=	payment.EXPIRYDATE;
			payment_data_tt(payment_count).Check_Number 				:=	payment.Accountnumber 	;
			payment_data_tt(payment_count).Payment_Amount 				:=	payment.Amount 	;
			payment_data_tt(payment_count).PREPAID_AMOUNT 				:=	payment.Amount 	;
			payment_data_tt(payment_count).CREDIT_CARD_APPROVAL_CODE 	:=	payment.Ccauthcode 	;
			payment_data_tt(payment_count).REQUEST_ID 					:=	fnd_global.conc_request_id 	;
			payment_data_tt(payment_count).PAYMENT_NUMBER 				:=	payment.payment_ref 	;
			payment_data_tt(payment_count).ORIG_SYS_PAYMENT_REF  		:=	payment.payment_ref 	;
			payment_data_tt(payment_count).CONTEXT  					:=	'SALES_ACCT_HVOP' 	;
			payment_data_tt(payment_count).PAYMENT_LEVEL_CODE 			:=  'ORDER';
			payment_data_tt(payment_count).PAYMENT_COLLECTION_EVENT 	:=  'PREPAY';
			payment_data_tt(payment_count).Attribute4 					:=	payment.ccEncryptionKey 	;
			payment_data_tt(payment_count).Attribute9 					:=	'0' 	;
	  
	        /*
			get_pay_method(p_payment_instrument      => payment.Cctype ,
                           p_payment_type_code       => payment_data_tt(payment_count).Payment_Type_Code,
                           p_credit_card_code        => payment_data_tt(payment_count).Credit_Card_Code);
						   			   
	        */
		
			BEGIN
				--lookup_code VARCHAR2(240), attribute6 VARCHAR2(240) ,attribute7
				--NULL;
				
				SELECT attribute6 , attribute7
				INTO   payment_data_tt(payment_count).Payment_Type_Code	,	
					   payment_data_tt(payment_count).Credit_Card_Code				
				FROM   table(cast(xxom_payterm as xxom_pay_term_obj_table)) 
				WHERE  lookup_code = payment.Cctype;
				

			EXCEPTION 
			WHEN OTHERS THEN 
				payment_data_tt(payment_count).Payment_Type_Code := '';	
				payment_data_tt(payment_count).Credit_Card_Code  := '';
			END ;
	  
			--payment_data_tt(payment_count).Credit_Card_Holder_Name := header_attr_data_tt(head_attr_count).ORIG_CUST_NAME;
	  
	  
	  END LOOP;
	  
     
    EXCEPTION
    WHEN OTHERS THEN
      --lc_level := 'Order Price Adjustment Tax';
      logit ('Error in Proc Xxoe_Validate_Data while getting '|| lc_level ||' data of '||lc_int_order_number||' into xxom int tables. Error Code:'||SQLCODE);
      logit ('Error Message: '||SQLERRM);
	  
	  err_rec_tab(err_count).header_id :=  L_Header_Id;
	  err_rec_tab(err_count).order_number := I.Ordernumber ;
	  --err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
	  err_count := err_count+1;
	  
	  /*
      DELETE FROM Xx_Oe_Payments WHERE header_id = L_Header_Id;
      DELETE FROM Xx_Oe_Price_Adjustments WHERE header_id = L_Header_Id;
      DELETE
      FROM Xx_Oe_Line_Attributes_All xolattr
      WHERE EXISTS
        (SELECT 1
        FROM Xx_Oe_Order_Lines_All xoline
        WHERE xoline.Header_Id = L_Header_Id
        AND xoline.line_id     = xolattr.line_Id
        );
      DELETE FROM Xx_Oe_Order_Lines_All WHERE Header_Id = L_Header_Id;
      DELETE FROM Xx_Oe_Header_Attributes_All WHERE header_id = L_Header_Id;
      DELETE FROM Xx_Oe_Order_Headers_All WHERE header_id = L_Header_Id;
      UPDATE Xxom_Order_Headers_Int
      SET status          = 'Error' ,
        error_description = 'Error in Proc Xxoe_Validate_Data while inserting '
        || lc_level
        ||' data'
      WHERE Ordernumber = lc_int_order_number
      AND Header_Id     = lc_int_header_id;
      UPDATE Xxom_Order_Lines_Int
      SET status          = 'Error' ,
        error_description = 'Error in Proc Xxoe_Validate_Data while inserting '
        || lc_level
        ||' data'
      WHERE header_id = lc_int_header_id;
      UPDATE Xxom_Order_Adjustments_Int
      SET status          = 'Error' ,
        error_description = 'Error in Proc Xxoe_Validate_Data while inserting '
        || lc_level
        ||' data'
      WHERE header_id = lc_int_header_id;
      UPDATE Xxom_Order_Tenders_Int
      SET status          = 'Error' ,
        error_description = 'Error in Proc Xxoe_Validate_Data while inserting '
        || lc_level
        ||' data'
      WHERE header_id = lc_int_header_id;
      UPDATE Xxom_Import_Int
      SET Process_Flag    = 'E',
        Status            = 'Error',
        error_description = 'Error while inserting '
        ||lc_level
        || ' data in xxoe table'
      WHERE Order_Number   = lc_int_order_number
      AND Sub_Order_Number = lc_sub_order_number;
    */
	END;
  END LOOP;
  
   BEGIN 

		  FORALL header_data IN header_data_tt.FIRST .. header_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO Xx_Oe_Order_Headers_All VALUES header_data_tt(header_data);
		  
	EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table Xx_Oe_Order_Headers_All is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;	  
		  
	BEGIN	  
		  FORALL header_attr_data IN header_attr_data_tt.FIRST .. header_attr_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO Xx_Oe_Header_Attributes_All VALUES header_attr_data_tt(header_attr_data);
		EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table Xx_Oe_Header_Attributes_All is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  header_attr_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;	  
		
		BEGIN
		  FORALL line_data IN line_data_tt.FIRST .. line_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO XX_OE_ORDER_LINES_ALL VALUES line_data_tt(line_data);
		EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table XX_OE_ORDER_LINES_ALL is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  line_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					--err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					err_rec_tab(err_count).line_id :=  line_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).line_id;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;	  
		
		BEGIN
		  FORALL line_attr_data IN line_attr_data_tt.FIRST .. line_attr_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO XX_OE_LINE_ATTRIBUTES_ALL VALUES line_attr_data_tt(line_attr_data);
		EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table XX_OE_LINE_ATTRIBUTES_ALL is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  line_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					--err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					err_rec_tab(err_count).line_id :=  line_attr_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).line_id;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;  
		  
		BEGIN  
		  FORALL price_adj_data IN price_adj_data_tt.FIRST .. price_adj_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO XX_OE_PRICE_ADJUSTMENTS VALUES price_adj_data_tt(price_adj_data);
		EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table XX_OE_PRICE_ADJUSTMENTS is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  price_adj_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					--err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					--err_rec_tab(err_count).line_id :=  line_attr_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).line_id;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;    
		  
		BEGIN  
		  FORALL payment_data IN payment_data_tt.FIRST .. payment_data_tt.LAST SAVE EXCEPTIONS
		  INSERT INTO XX_OE_PAYMENTS VALUES payment_data_tt(payment_data);
		EXCEPTION
		WHEN error_forall THEN

			IF SQL%BULK_EXCEPTIONS.COUNT > 0 THEN
				logit('Total Number of errors while inserting data in Table XX_OE_PAYMENTS is : ' || SQL%BULK_EXCEPTIONS.COUNT);

				FOR err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
					logit('Error No: ' || err || ' File Row Number : ' || SQL%BULK_EXCEPTIONS(err).error_index ||' Error Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE));
					err_rec_tab(err_count).header_id :=  payment_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Header_Id;
					--err_rec_tab(err_count).order_number := header_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).Order_number ;
					--err_rec_tab(err_count).line_id :=  line_attr_data_tt(SQL%BULK_EXCEPTIONS(err).error_index).line_id;
					err_rec_tab(err_count).error := SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(err).ERROR_CODE),1,100);
					--err_rec_tab(err_count).sub_order_number := I.Ordersubnumber;
					err_count := err_count+1;
				END LOOP;
			END IF;
		END;
	  
	  
	  BEGIN 
	  
	  FORALL header_data IN header_data_tt.FIRST..header_data_tt.LAST 
	  UPDATE Xxom_Order_Headers_Int
	  SET status = 'Processed'
	  WHERE Ordernumber || Ordersubnumber = header_data_tt(header_data).Order_number
	  AND status = 'New';
	  
	  FORALL header_data IN header_data_tt.FIRST..header_data_tt.LAST
	  UPDATE XXOM_ORDER_LINES_INT xol
	  SET status = 'Processed'
	  WHERE status = 'New'
	  AND  EXISTS (
	  SELECT 1 FROM Xxom_Order_Headers_Int xoh
	  WHERE xoh.Ordernumber || xoh.Ordersubnumber = header_data_tt(header_data).Order_number
	  AND status = 'Processed'
	  AND xoh.header_id = xol.header_id
	  );
	  
	  FORALL header_data IN header_data_tt.FIRST..header_data_tt.LAST
	  UPDATE XXOM_ORDER_ADJUSTMENTS_INT xoa
	  SET status = 'Processed'
	  WHERE status = 'New'
	  AND  EXISTS (
	  SELECT 1 FROM Xxom_Order_Headers_Int xoh
	  WHERE xoh.Ordernumber || xoh.Ordersubnumber = header_data_tt(header_data).Order_number
	  AND status = 'Processed'
	  AND xoh.header_id = xoa.header_id
	  );
	  
	  FORALL header_data IN header_data_tt.FIRST..header_data_tt.LAST
	  UPDATE XXOM_ORDER_TENDERS_INT xot
	  SET status = 'Processed'
	  WHERE status = 'New'
	  AND  EXISTS (
	  SELECT 1 FROM Xxom_Order_Headers_Int xoh
	  WHERE xoh.Ordernumber || xoh.Ordersubnumber = header_data_tt(header_data).Order_number
	  AND status = 'Processed'
	  AND xoh.header_id = xot.header_id
	  );
	  
	  END;
	  
	  /*
	  UPDATE Xxom_Order_Headers_Int
      SET status        = 'Processed'
      WHERE Ordernumber = lc_int_order_number
      AND Header_Id     = lc_int_header_id;
      UPDATE Xxom_Order_Lines_Int
      SET status      = 'Processed'
      WHERE header_id = lc_int_header_id;
      UPDATE Xxom_Order_Adjustments_Int
      SET status      = 'Processed'
      WHERE header_id = lc_int_header_id;
      UPDATE Xxom_Order_Tenders_Int
      SET status      = 'Processed'
      WHERE header_id = lc_int_header_id;
      logit ('Order '||lc_int_order_number||' processed');
  */
  
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST 
	DELETE FROM XX_OE_PAYMENTS WHERE header_id = err_rec_tab(err_data).header_id;
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST 
	DELETE FROM XX_OE_PRICE_ADJUSTMENTS WHERE header_id = err_rec_tab(err_data).header_id;
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	DELETE FROM XX_OE_LINE_ATTRIBUTES_ALL
	WHERE LINE_ID IN (SELECT LINE_ID FROM XX_OE_ORDER_LINES_ALL WHERE header_id = err_rec_tab(err_data).header_id  );
	
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST 
	DELETE FROM XX_OE_ORDER_LINES_ALL WHERE header_id = err_rec_tab(err_data).header_id;
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST 
	DELETE FROM Xx_Oe_Header_Attributes_All WHERE header_id = err_rec_tab(err_data).header_id; 
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	UPDATE Xxom_Import_Int xii
      SET Process_Flag    = 'E',
        Status            = 'Error',
        error_description = 'Error while inserting XXOE Table, Error :'||err_rec_tab(err_data).error
      WHERE 1=1 
	  AND EXISTS 
	  (SELECT 1 FROM Xx_Oe_Order_Headers_All xooa WHERE xooa.ORDER_NUMBER = xii.order_Number   || xii.Sub_Order_Number 
	   AND xooa.header_id = err_rec_tab(err_data).header_id) ;
	
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	UPDATE  Xxom_Order_Headers_Int xohi
	SET status = 'Error' , error_description = err_rec_tab(err_data).error
	WHERE status = 'Processed'
	AND EXISTS (SELECT 1 FROM Xx_Oe_Order_Headers_All xooa WHERE xooa.ORDER_NUMBER = xohi.Ordernumber || xohi.Ordersubnumber
	AND xooa.header_id = err_rec_tab(err_data).header_id);
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	UPDATE Xxom_Order_Lines_Int xoli
	SET status = 'Error' , error_description = 'Error While Inserting Data in XXOE Table'
	WHERE EXISTS (
	SELECT 1 FROM Xxom_Order_Headers_Int xohi
	WHERE xohi.header_id = xoli.header_id
	AND xohi.status = 'Error'
	AND EXISTS (SELECT 1 FROM Xx_Oe_Order_Headers_All xooa WHERE xooa.ORDER_NUMBER = xohi.Ordernumber || xohi.Ordersubnumber
	AND xooa.header_id = err_rec_tab(err_data).header_id)
	)
	AND xoli.status = 'Processed';
	
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	UPDATE Xxom_Order_Adjustments_Int xoai
	SET status = 'Error' , error_description = 'Error While Inserting Data in XXOE Table'
	WHERE EXISTS (
	SELECT 1 FROM Xxom_Order_Headers_Int xohi
	WHERE xohi.header_id = xoai.header_id
	AND xohi.status = 'Error'
	AND EXISTS (SELECT 1 FROM Xx_Oe_Order_Headers_All xooa WHERE xooa.ORDER_NUMBER = xohi.Ordernumber || xohi.Ordersubnumber
	AND xooa.header_id = err_rec_tab(err_data).header_id)
	)
	AND xoai.status = 'Processed';
	
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST
	UPDATE Xxom_Order_Tenders_Int xoti
	SET status = 'Error' , error_description = 'Error While Inserting Data in XXOE Table'
	WHERE EXISTS (
	SELECT 1 FROM Xxom_Order_Headers_Int xohi
	WHERE xohi.header_id = xoti.header_id
	AND xohi.status = 'Error'
	AND EXISTS (SELECT 1 FROM Xx_Oe_Order_Headers_All xooa WHERE xooa.ORDER_NUMBER = xohi.Ordernumber || xohi.Ordersubnumber
	AND xooa.header_id = err_rec_tab(err_data).header_id)
	)
	AND xoti.status = 'Processed';
		
	FORALL err_data IN err_rec_tab.FIRST..err_rec_tab.LAST 
	DELETE FROM Xx_Oe_Order_Headers_All WHERE header_id = err_rec_tab(err_data).header_id; 
	  
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  logit ('Exception in Proc Xxoe_Validate_Data. Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
END Xxoe_Validate_Data;


--PROCEDURE XXOE_PROCESS_DATA ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 ) ;


END Xxoe_Data_Load_Pkg;
/
SHOW ERRORS;
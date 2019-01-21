CREATE OR REPLACE PACKAGE BODY xx_crm_aopstocdhcountry_pkg AS

   /*****************************************************************************
      NAME:       XX_CRM_AOPSTOCDHCOUNTRY_PKG
      PURPOSE:     To retrieve CDH country code and Org_ID for the given AOPS country code.
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        7/12/2007    Kathirvel P        1. Created this package body.
                                                 as per requirements
      1.1        8/9/2007     Kathirvel P        1. Included the procedure  
                                                 xx_crm_aopstocdhcountry_proc to support 
                                                 two aops country code as it is for BPEL.  
      1.2        11/14/2007   Kathirvel P        Changed the code to get the country code and 
                                                 name from xx_fin_translatedefinition and 
                                                 xx_fin_translatevalues           
      1.3        12/28/2007   Kathirvel.P        Created procedure xx_crm_cdhtoaops_org_proc
                                                 to get cdh Org_id and country code for the 
                                                 given account site address       
      1.4        05/07/2008   Kathirvel .P       Included the parameter x_context_country 
                                                 for setting the apps context in the BPEL process
                                                 based on the given input
      1.5        05/16/2008   Kathirvel .P       Included the x_error_message if the Acct Site
                                                 doesnt exist for the AOPS customer ID
      1.6        06/18/2008   Kathirvel .P       Included STATUS condition in cursor l_acct_org_cur 
      1.7        07/16/2008   Kathirvel .P       Changes made for RETAIL customers.
      1.8        05/27/2009   Kalyan             Modified xx_crm_get_cdhcountry_proc to select
                                                 target country and country to determine org_id.
      1.9        06/19/2009   Kalyan             Modified l_cust_acct_cur to ignore status of
                                                 hz_cust_accounts.
   *******************************************************************************/ 
PROCEDURE xx_crm_get_cdhcountry_proc(
  p_orig_system_ref IN VARCHAR2,   
  p_aops_country_code IN VARCHAR2,   
  x_target_country OUT NOCOPY VARCHAR2,   
  x_target_org_id OUT NOCOPY NUMBER,  
  x_return_status OUT NOCOPY VARCHAR2,   
  x_error_message OUT NOCOPY VARCHAR2) IS
  

  lv_target_country VARCHAR2(200);
  lv_target_country2 VARCHAR2(200);
  lv_error          VARCHAR2(200);
  ln_org_id         NUMBER;

  BEGIN
    x_return_status := 'S';
 
    BEGIN

       -- modified 05/27/2009
       SELECT b.target_value1, b.target_value2
       INTO   lv_target_country  , lv_target_country2
        FROM   xx_fin_translatedefinition a,
              xx_fin_translatevalues b
       WHERE  a.translate_id = b.translate_id
       AND    a.translation_name = 'XXOD_CDH_CONV_COUNTRY'
       AND    b.source_value1    = p_orig_system_ref
       AND    b.source_value2    = p_aops_country_code
       AND    TRUNC(sysdate) BETWEEN NVL(b.start_date_active, sysdate) AND   NVL(b.end_date_active,   sysdate);

       x_target_country := lv_target_country;
    EXCEPTION
        WHEN no_data_found THEN
             x_return_status := 'E';
             lv_error := 'No Target Country exists for the Source Country Code ' || p_aops_country_code;
    END;


    BEGIN

  SELECT c.organization_id
        INTO   ln_org_id 
        FROM   xx_fin_translatedefinition a,
               xx_fin_translatevalues b,
               hr_organization_units_v c
        WHERE  a.translate_id     = b.translate_id
        AND    a.translation_name = 'OD_COUNTRY_DEFAULTS'
        -- modified 05/27/2009
        AND    b.source_value1    = lv_target_country2
        --AND    b.source_value1    = lv_target_country
        AND    TRUNC(sysdate) BETWEEN NVL(b.start_date_active, sysdate) AND   NVL(b.end_date_active,   sysdate)
        AND    c.name             = b.target_value2;

        x_target_org_id := ln_org_id;
    EXCEPTION
       WHEN no_data_found THEN
            x_return_status := 'E';
            x_error_message := lv_error || '  No Organization exists for the country ' || lv_target_country;
    END;

  EXCEPTION
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := lv_error || SUBSTR(sqlerrm,   1,   200);
  END xx_crm_get_cdhcountry_proc;
  
PROCEDURE xx_crm_aopstocdhcountry_proc(
  p_orig_system_ref 	 IN VARCHAR2,   
  p_aops_cust_id  	 IN VARCHAR2,   
  p_aops_country_code1   IN VARCHAR2,   
  p_aops_country_code2   IN VARCHAR2,  
  p_bpel_process_name    IN VARCHAR2,
  px_customer_type       IN OUT NOCOPY VARCHAR2,
  x_target_country1      OUT NOCOPY VARCHAR2,   
  x_target_country2      OUT NOCOPY VARCHAR2,   
  x_target_org_id1       OUT NOCOPY NUMBER,   
  x_target_org_id2       OUT NOCOPY NUMBER,   
  x_comm_context_country OUT NOCOPY VARCHAR2, 
  x_target_add_org_id    OUT NOCOPY NUMBER,
  x_null_address_element OUT NOCOPY VARCHAR2,
  x_return_status        OUT NOCOPY VARCHAR2,   
  x_error_message        OUT NOCOPY VARCHAR2) IS

  lv_target_country1 VARCHAR2(200);
  ln_org_id1         NUMBER;
  lv_target_country2 VARCHAR2(200);
  ln_org_id2         NUMBER;
  ln_context_country VARCHAR2(25);
  l_exist_org_id     NUMBER;
  l_return_status    VARCHAR2(1);
  l_error_message    VARCHAR2(2000);
  l_customer_type    VARCHAR2(50);
  FUNCTIONAL_ERROR   EXCEPTION;


  CURSOR  l_cust_acct_cur IS
  select  attribute18
  from    hz_cust_accounts
  where   orig_system_reference = p_aops_cust_id||'-00001-A0';
  --modified 06/19/2009

    CURSOR l_acct_org_cur IS
    select cas.org_id
    from   hz_orig_sys_references osr, hz_cust_acct_sites_all cas
    where  osr.orig_system_reference = p_aops_cust_id||'-00001-A0'
    and    osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
    and    osr.orig_system      = p_orig_system_ref
    and    osr.owner_table_id   = cas.cust_acct_site_id                          
    and    osr.status = 'A';  


  CURSOR l_country_for_prg_cur (l_existing_org_id NUMBER) is
  SELECT b.source_value1
  FROM   xx_fin_translatedefinition a,
         xx_fin_translatevalues b,
         hr_organization_units_v c
  WHERE  a.translate_id     = b.translate_id
  AND    a.translation_name = 'OD_COUNTRY_DEFAULTS'
  AND    TRUNC(sysdate) BETWEEN NVL(b.start_date_active, sysdate) AND   NVL(b.end_date_active,   sysdate)
  AND    c.name             = b.target_value2
  AND    c.organization_id  = l_existing_org_id;

BEGIN

    x_return_status := 'S';

    --The following is required to null out any values that need to be updated with no value.
    --esp. A location in Canada is updated to USA country and does not require the provience
    -- field.
    --Also, this assignment is done here to save the number of trips to the database.
    SELECT chr(0) INTO x_null_address_element FROM DUAL;

    IF px_customer_type IS NULL
    THEN 
    	  OPEN  l_cust_acct_cur ;
        FETCH l_cust_acct_cur INTO l_customer_type;
        CLOSE l_cust_acct_cur ; 
        px_customer_type   :=  l_customer_type;
    ELSE
        IF px_customer_type = 'R'
        THEN
            l_customer_type   := 'DIRECT';
        ELSE
            l_customer_type   := px_customer_type;
        END IF;
    END IF;

    IF p_aops_cust_id IS NULL
    THEN
        l_error_message := 'Customer ID can not be Empty.Please provide AOPS Customer ID';
        RAISE FUNCTIONAL_ERROR;
    ELSE
    	 OPEN  l_acct_org_cur;
    	 FETCH l_acct_org_cur INTO l_exist_org_id;
    	 CLOSE l_acct_org_cur;
    END IF;


    IF l_exist_org_id IS NOT NULL
    THEN
         OPEN  l_country_for_prg_cur(l_exist_org_id) ;
    	   FETCH l_country_for_prg_cur INTO ln_context_country;
    	   CLOSE l_country_for_prg_cur ;  
    END IF;

    IF p_aops_country_code1 IS NOT NULL
    THEN
             xx_crm_get_cdhcountry_proc (
      		p_orig_system_ref   =>  p_orig_system_ref,
      		p_aops_country_code =>  p_aops_country_code1 ,
      		x_target_country    =>  lv_target_country1,
      		x_target_org_id     =>  ln_org_id1,
      		x_return_status     =>  l_return_status,
      		x_error_message     =>  l_error_message
   		                  );

            IF l_return_status <> 'S' 
            THEN
                RAISE FUNCTIONAL_ERROR;
            END IF;
    END IF;      

    IF p_aops_country_code2 IS NOT NULL
    THEN
             xx_crm_get_cdhcountry_proc (
      		p_orig_system_ref   =>  p_orig_system_ref,
      		p_aops_country_code =>  p_aops_country_code2 ,
      		x_target_country    =>  lv_target_country2,
      		x_target_org_id     =>  ln_org_id2,
      		x_return_status     =>  l_return_status,
      		x_error_message     =>  l_error_message
   		                  );

            IF l_return_status <> 'S' 
            THEN
                RAISE FUNCTIONAL_ERROR;
            END IF;
    END IF;   

    IF l_customer_type = 'DIRECT' 
    THEN

        IF (lv_target_country1 = 'CA' or lv_target_country2 = 'CA') and 
            p_bpel_process_name IN ('CreateAccountProcess','SaveAddressProcess') 
        THEN

             x_target_country1     := lv_target_country1;
             x_target_add_org_id   := ln_org_id1; 
 
                 xx_crm_get_cdhcountry_proc (
      		p_orig_system_ref   =>  p_orig_system_ref,
      		p_aops_country_code =>  'USA',
      		x_target_country    =>  lv_target_country1,
      		x_target_org_id     =>  ln_org_id1,
      		x_return_status     =>  l_return_status,
      		x_error_message     =>  l_error_message
   		                  );

            	IF l_return_status <> 'S' 
            	THEN
                		RAISE FUNCTIONAL_ERROR;
            	END IF;
             ln_context_country    := lv_target_country1;
             x_target_org_id1      := ln_org_id1;   
        	 x_comm_context_country:= lv_target_country1;


    	  ELSE
            IF lv_target_country1 IS NOT NULL
            THEN
            	ln_context_country    := lv_target_country1;
           	      x_target_country1     := lv_target_country1;
            	x_target_org_id1      := ln_org_id1; 
            	x_target_add_org_id   := NULL;  
            ELSE
            	x_target_org_id1      := l_exist_org_id; 
            	x_target_add_org_id   := NULL;  
            END IF;
  
    	  END IF;

    	  IF ln_context_country IS NULL
    	  THEN
         	IF l_exist_org_id IS NULL 
         	THEN
                l_error_message := 'No Acct Site Exists for the OSR '||p_aops_cust_id||'-00001-A0';
         	ELSE
                l_error_message := 'Please verify the Finance Transalate for the Org '||l_exist_org_id;
         	END IF;
            RAISE FUNCTIONAL_ERROR;
        END IF;

        x_target_country2     := lv_target_country2;
        x_target_org_id2      := ln_org_id2;
        x_comm_context_country:= ln_context_country;
    ELSE

   		IF ln_context_country IS NULL and p_aops_country_code2 IS NOT NULL
    		THEN
 
         		ln_context_country := lv_target_country2;
			l_exist_org_id     := ln_org_id2;

    		END IF;

    		IF ln_context_country IS NULL and p_aops_country_code1 IS NOT NULL
    		THEN
         		ln_context_country := lv_target_country1;
         		l_exist_org_id     := ln_org_id1;

    		END IF;
    
    		IF ln_context_country IS NULL
    		THEN

         		IF l_exist_org_id IS NULL 
         		THEN
             		l_error_message := 'No Acct Site Exists for the OSR '||p_aops_cust_id||'-00001-A0';
         		ELSE
            		l_error_message := 'Please verify the Finance Transalate for the Org '||l_exist_org_id;
         		END IF;
                  RAISE FUNCTIONAL_ERROR;
    		ELSE
         		x_target_country1     := lv_target_country1;
         		x_target_country2     := lv_target_country2;
                  x_target_org_id1      := l_exist_org_id;   
                  x_target_org_id2      := l_exist_org_id;   
         		x_comm_context_country:= ln_context_country;
    		END IF;
   END IF;

  EXCEPTION
   WHEN FUNCTIONAL_ERROR 
   THEN
      x_return_status := 'E';
      x_error_message := l_error_message; 
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := x_error_message || SUBSTR(sqlerrm,   1,   200);
    CLOSE l_cust_acct_cur;
    CLOSE l_country_for_prg_cur;
    CLOSE l_acct_org_cur;
  END xx_crm_aopstocdhcountry_proc;

END xx_crm_aopstocdhcountry_pkg;
/
CREATE OR REPLACE PACKAGE BODY XX_CDH_CUST_ACHID

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_CUST_ACHID                                           |
-- | Description :                                                             |
-- | This package helps us to get the list of Accounts with ACH_ID's. Used in  |
-- | Program: OD: CDH Customer ACHID List.                                     |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-MAR-2010 Srini         Initial draft version                   |
-- |1.1      12-NOV-2015 Havish K      Removed the Schema References as per    |
-- |                                   R12.2 Retrofit Changes                  |
-- +===========================================================================+

AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : LIST_ACHID_CUSTOMERS                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to get the list of Accounts with ACH_ID's.              |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
   PROCEDURE LIST_ACHID_CUSTOMERS
   (
      x_errbuf            OUT VARCHAR2
     ,x_retcode           OUT NUMBER
   ) IS

      /*
      -- Cursor to get customer details for all Accounts which are having ACH_ID's.
      */
      CURSOR lcu_cust_ach_dtls
      IS
          select /*+ index(hzc, HZ_CUST_ACCOUNTS_U1)*/ 
                EGO.ACH_ID                              ACH_ID
              , replace(EGO.ACH_COMMENTS, '
', '')                                                  ACH_COMMENTS
              , hzc.account_name                        ACCOUNT_NAME
              , substr(hzc.orig_system_reference, 1, 8) AOPS_NUMBER
              , hzc.account_number                      ACCOUNT_NUMBER
              , hzc.cust_account_id                     CUST_ACCOUNT_ID
          from   HZ_CUST_ACCOUNTS hzc,
           (SELECT  C_EXT_ATTR1 ACH_ID
                  , C_EXT_ATTR2 ACH_COMMENTS
                  , CUST_ACCOUNT_ID
             FROM   XX_CDH_CUST_ACCT_EXT_B
             Where  ATTR_GROUP_ID = (
                               SELECT attr_group_id
                               FROM   ego_attr_groups_v v
                               WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                               AND    attr_group_name   = 'ACH_ID')
            and  C_EXT_ATTR1 is not null) EGO
          where EGo.cust_account_id = hzc.cust_account_id
          order by hzc.account_name;
          
      lc_error_message   VARCHAR2(4000);
      lr_cust_ach_dtls   lcu_cust_ach_dtls%rowtype;
     
   BEGIN
     
      -- To Display Report Header.
      fnd_file.put_line (fnd_file.output, 'Report: ACH Sending Id Details');
      
      -- To Display Date and Time report executed.
      fnd_file.put_line (fnd_file.output, 'Report Date and Time: ' || to_char(sysdate, 'DD-Mon-YYYY HH24:MI'));
      
      --  Printing the Header Details.
      fnd_file.put_line (fnd_file.output, 'Customer Name|Sending ID (ACH ID)|Oracle Customer Number|AOPS Number|ACH Comments|Cust_Account_ID');
      
      OPEN lcu_cust_ach_dtls;
      LOOP
         FETCH lcu_cust_ach_dtls INTO lr_cust_ach_dtls;
         EXIT WHEN lcu_cust_ach_dtls%notfound;
       
         BEGIN

            if length(trim(lr_cust_ach_dtls.ACH_ID)) > 0 then
               fnd_file.put_line (fnd_file.output, 
                      lr_cust_ach_dtls.ACCOUNT_NAME   || '|' || lr_cust_ach_dtls.ACH_ID      || '|' || 
                      lr_cust_ach_dtls.ACCOUNT_NUMBER || '|' || lr_cust_ach_dtls.AOPS_NUMBER || '|' || 
                      lr_cust_ach_dtls.ACH_COMMENTS   || '|' || lr_cust_ach_dtls.CUST_ACCOUNT_ID);
            End if;

         EXCEPTION
            WHEN OTHERS THEN
               x_retcode          := 2;
               fnd_file.put_line (fnd_file.log,
                                   'Unexpected Error in package XX_CDH_CUST_ACHID.LIST_ACHID_CUSTOMERS.'
                                || 'Error while getting date for Cust Account Number: ' 
                                || lr_cust_ach_dtls.ACCOUNT_NUMBER);
         END;
        
      END LOOP;
      CLOSE lcu_cust_ach_dtls;

   EXCEPTION
      WHEN OTHERS THEN

         lc_error_message := 
               'Unexpected Error in package XX_CDH_CUST_ACHID.LIST_ACHID_CUSTOMERS'
            || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);
            
         fnd_file.put_line (fnd_file.log, lc_error_message);
         x_errbuf := lc_error_message;
         x_retcode := 2;

   END LIST_ACHID_CUSTOMERS;



-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_RESP_ACCESS                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to make sure that the Responsibility have access to     |
-- | update each attribute group. This procedure is called from ATTRGROUP page.|
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
   PROCEDURE VALIDATE_RESP_ACCESS
   (
       P_ATTRIBUTE_GROUP  IN  VARCHAR2
     , P_MESSAGE          OUT VARCHAR2
     , P_STATUS           OUT VARCHAR2
   ) IS
   
      ln_att_group_access   VARCHAR2(5);
      ln_resp_name          VARCHAR2(50);
      
   BEGIN

      ln_resp_name := fnd_global.RESP_NAME;

      /*
      -- To get the Access details for each Attribute Group and Responsibility combination,
      -- which is setup in FINTRANS table.
      -- If the setup is not defined in FINTRANS for the above combination then below query 
      -- will return as TRUE. means the Resp is having access.
      */
      BEGIN

         SELECT val.source_value3
         INTO   ln_att_group_access
         FROM   XX_FIN_TRANSLATEDEFINITION def,
                XX_FIN_TRANSLATEVALUES val
         WHERE  def.translate_id=val.translate_id
         AND    def.translation_name = 'XX_CDH_ATTR_GROUP_ACCESS'
         AND    val.enabled_flag='Y'
         AND    val.source_value1 = p_attribute_group -- ATTRIBUTE_GROUP
         AND    val.source_value2 = ln_resp_name -- RESPONSIBILITY
         AND    sysdate between val.start_date_active AND NVL(val.end_date_active, SYSDATE+1);

      EXCEPTION 
         WHEN NO_DATA_FOUND THEN

            Begin
               SELECT val.source_value3
	       INTO   ln_att_group_access
	       FROM   XX_FIN_TRANSLATEDEFINITION def,
	              XX_FIN_TRANSLATEVALUES val
	       WHERE  def.translate_id=val.translate_id
	       AND    def.translation_name = 'XX_CDH_ATTR_GROUP_ACCESS'
	       AND    val.enabled_flag='Y'
	       AND    val.source_value1 = p_attribute_group -- ATTRIBUTE_GROUP
	       AND    val.source_value2 is null
               AND    sysdate between val.start_date_active AND NVL(val.end_date_active, SYSDATE+1);

           EXCEPTION 
	       WHEN NO_DATA_FOUND THEN
                  ln_att_group_access := 'TRUE';

            END;
      END;
      
      IF ln_att_group_access = 'FALSE' THEN 
         P_STATUS  := 'E';
         P_MESSAGE := 'XXOD_ACH_001'; -- FND_MESSAGE.GET_STRING('XXCRM', 'XXOD_ACH_001');
      
      ELSE
         P_STATUS  := 'S';
         P_MESSAGE := '';
      
      END IF;
   
   EXCEPTION
      WHEN OTHERS THEN

         P_MESSAGE := 'XXOD_ACH_000'; --  FND_MESSAGE.GET_STRING('XXCRM', 'XXOD_ACH_000') -- 
              -- || 'Unexpected Error in package XX_CDH_CUST_ACHID.LIST_ACHID_CUSTOMERS'
              -- || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);
            
         P_STATUS  := 'E';

  
   END VALIDATE_RESP_ACCESS;



-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_ACH_ID                                             |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to make sure that ACH_ID is valid (No Duplicate values).|
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
   PROCEDURE VALIDATE_ACH_ID
   (
       P_CUST_ACCOUNT_ID  IN  NUMBER
     , P_ACH_ID           IN  VARCHAR2
     , P_MESSAGE          OUT VARCHAR2
     , P_STATUS           OUT VARCHAR2
   ) IS
   
      ln_ach_count    NUMBER;
      
   BEGIN

      /*
      -- To get the count of existing ACH_ID's, for doing duplicate validation.
      */
     IF P_ACH_ID IS NULL or LENGTH(TRIM(P_ACH_ID)) = 0 THEN
        ln_ach_count := 0;
        
     ELSE
        SELECT   /*+index(ego, XX_CDH_CUST_ACCT_EXT_B_N3)*/ 
                count(C_EXT_ATTR1)
         into   ln_ach_count   
         FROM   XX_CDH_CUST_ACCT_EXT_B ego
         Where  ATTR_GROUP_ID = (
                   SELECT attr_group_id
                   FROM   ego_attr_groups_v v
                   WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
                   AND    attr_group_name   = 'ACH_ID')
         AND  CUST_ACCOUNT_ID <> P_CUST_ACCOUNT_ID
         AND  C_EXT_ATTR1 = P_ACH_ID;
     
     END IF;

      IF ln_ach_count > 0 THEN 
         P_STATUS  := 'E';
         P_MESSAGE := 'XXOD_ACH_002'; -- FND_MESSAGE.GET_STRING('XXCRM', 'XXOD_ACH_002');
      
      ELSE
         P_STATUS  := 'S';
         P_MESSAGE := '';
      
      END IF;
            
   EXCEPTION
      WHEN OTHERS THEN


         P_MESSAGE :=  'XXOD_ACH_000'; -- FND_MESSAGE.GET_STRING('XXCRM', 'XXOD_ACH_000') -- 
              -- || 'Unexpected Error in package XX_CDH_CUST_ACHID.LIST_ACHID_CUSTOMERS'
              -- || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);
            
         P_STATUS  := 'E';
  
   END VALIDATE_ACH_ID;
  

END XX_CDH_CUST_ACHID;
/
  
SHOW ERRORS;

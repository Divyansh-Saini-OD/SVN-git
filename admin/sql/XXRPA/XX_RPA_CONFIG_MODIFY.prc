CREATE OR REPLACE PROCEDURE XX_RPA_CONFIG_MODIFY_PRC (P_MODE            IN  VARCHAR2  -- Mandatory Parameter (Update - U, Insert - I)
                                                    , P_CUSTOMER_NAME   IN  VARCHAR2  -- Mandatory Parameter
                                                    , P_CUSTOMER_NUMBER IN  VARCHAR2  -- Mandatory Parameter
                                                    , P_CUSTOMER_DOC_ID IN  VARCHAR2  -- Mandatory Parameter (For Update Put value)
                                                    , P_MBS_DOC_ID      IN OUT  VARCHAR2  -- Optional/ As Requires (10000, 10001)
                                                    , P_PAY_DOC         IN OUT  VARCHAR2  -- Optional/ As Requires (Y or N)
                                                    , P_DELIVERY_METHOD IN OUT  VARCHAR2  -- Optional/ As Requires (ePDF,eXLS,EDI,Print)
                                                    , P_PAYMNET_TERM    IN OUT  VARCHAR2  -- Optional/ As Requires
                                                    , P_DIRECT_DOCUMENT IN OUT  VARCHAR2  -- Optional/ As Requires (Y or N)
                                                    , P_ERROR_FLAG      OUT VARCHAR2  -- For Error Flag 'E'
                                                    , P_ERROR_MSG       OUT VARCHAR2  -- For Eror Messages
                                                    ) 
AS
  
  /* Mandatory Parameters for Insert */
  P_REQUEST_DATE    xx_cdh_cust_acct_ext_b.D_EXT_ATTR9%TYPE := SYSDATE;
  P_INVOICE_TYPE    xx_cdh_cust_acct_ext_b.C_EXT_ATTR1%TYPE := 'Invoice';
  
  /* Variables Assigned */
  l_attr_group_id   ego_attr_groups_v.attr_group_id%TYPE := NULL;
  l_cust_acct_id    hz_cust_accounts.cust_account_id%TYPE := NULL;
  l_extension_id    xx_cdh_cust_acct_ext_b.extension_id%TYPE := NULL;
  l_mbs_doc_id      xx_cdh_cust_acct_ext_b.N_EXT_ATTR1%TYPE := NULL;
  l_pay_doc         xx_cdh_cust_acct_ext_b.C_EXT_ATTR2%TYPE := NULL;
  l_delivery_mthd   xx_cdh_cust_acct_ext_b.C_EXT_ATTR3%TYPE := NULL;
  l_payment_term    xx_cdh_cust_acct_ext_b.C_EXT_ATTR14%TYPE := NULL;
  l_direct_document xx_cdh_cust_acct_ext_b.C_EXT_ATTR7%TYPE := NULL;

BEGIN
  DBMS_OUTPUT.PUT_LINE ('*****START*****');
  DBMS_OUTPUT.PUT_LINE ('MODE: ' || P_MODE);
  P_ERROR_FLAG := 'Y';

  IF P_MODE = 'U'
  THEN    
   BEGIN
      SELECT  XCEB.EXTENSION_ID,
              XCEB.CUST_ACCOUNT_ID,
              XCEB.ATTR_GROUP_ID,
              XCEB.N_EXT_ATTR1,
              XCEB.C_EXT_ATTR2,
              XCEB.C_EXT_ATTR3,
              XCEB.C_EXT_ATTR14,
              XCEB.C_EXT_ATTR7
      INTO l_extension_id,
           l_cust_acct_id,
           l_attr_group_id,
           l_mbs_doc_id,
           l_pay_doc,
           l_delivery_mthd,
           l_payment_term,
           l_direct_document
      FROM hz_cust_accounts_all HCA
         , xx_cdh_cust_acct_ext_b XCEB
         , ego_attr_groups_v EAG
      WHERE XCEB.attr_group_id = EAG.attr_group_id
        AND EAG.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
        AND EAG.attr_group_name = 'BILLDOCS'
        AND HCA.cust_account_id = XCEB.cust_account_id
        --AND SUBSTR(HCA.orig_system_reference,1,8) = '18108847'
        AND HCA.account_name = P_CUSTOMER_NAME
        AND HCA.account_number = P_CUSTOMER_NUMBER
        AND XCEB.N_EXT_ATTR2 = P_CUSTOMER_DOC_ID;
        
   EXCEPTION
   WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ('DOC DETAILS NOT EXIST OR FAILED DUE TO '|| SQLERRM);
   P_ERROR_FLAG := 'E';
   P_ERROR_MSG  := ('DOC DETAILS NOT EXIST OR FAILED DUE TO '|| SQLERRM);
   END;
   
   IF P_ERROR_FLAG = 'Y'
   THEN
   
    IF P_MBS_DOC_ID IS NULL
    THEN
    P_MBS_DOC_ID := l_mbs_doc_id;
    END IF;
    
    IF P_PAY_DOC IS NULL
    THEN
    P_PAY_DOC := l_pay_doc;
    END IF;
    
    IF P_DELIVERY_METHOD IS NULL
    THEN
    P_DELIVERY_METHOD := l_delivery_mthd;
    END IF;
    
    IF P_PAYMNET_TERM IS NULL
    THEN
    P_PAYMNET_TERM := l_payment_term;
    END IF;
    
    IF P_DIRECT_DOCUMENT IS NULL
    THEN
    P_DIRECT_DOCUMENT := l_direct_document;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE ('***** UPDATE START*****');
    
      UPDATE XX_CDH_CUST_ACCT_EXT_B 
      SET C_EXT_ATTR2 = P_PAY_DOC,
          C_EXT_ATTR3 = P_DELIVERY_METHOD,
          C_EXT_ATTR7 = P_DIRECT_DOCUMENT,
          C_EXT_ATTR14 = P_PAYMNET_TERM,
          N_EXT_ATTR1 = P_MBS_DOC_ID,
          LAST_UPDATE_DATE = SYSDATE,
          LAST_UPDATED_BY = fnd_global.user_id
      WHERE EXTENSION_ID = l_extension_id
      AND CUST_ACCOUNT_ID = l_cust_acct_id
      AND ATTR_GROUP_ID = l_attr_group_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE ('*****END UPDATE*****');
   END IF;
   
  ELSIF P_MODE = 'I'
  THEN
    DBMS_OUTPUT.PUT_LINE ('P_MODE: ' || P_MODE);
    BEGIN
      SELECT  HCA.cust_account_id
      INTO l_cust_acct_id
      FROM hz_cust_accounts_all HCA
      WHERE 1=1
      AND HCA.status = 'A'
        --AND SUBSTR(HCA.orig_system_reference,1,8) = '18108847'
      AND HCA.account_name = P_CUSTOMER_NAME
      AND HCA.account_number =  P_CUSTOMER_NUMBER;
    
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE ('CUST_ACCOUNT_ID NOT EXISTS OR FAILED DUE TO '|| SQLERRM);
    P_ERROR_FLAG := 'E';
    P_ERROR_MSG  := ('CUST_ACCOUNT_ID NOT EXISTS OR FAILED DUE TO '|| SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE ('CUST_ACCOUNT_ID: '|| l_cust_acct_id);
  
    BEGIN
      SELECT  EAG.attr_group_id
      INTO l_attr_group_id
      FROM ego_attr_groups_v EAG
      WHERE EAG.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
        AND EAG.attr_group_name = 'BILLDOCS';
     
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE ('ATTR_GROUP_ID NOT EXISTS OR FAILED DUE TO '|| SQLERRM);
    P_ERROR_FLAG := 'E';
    P_ERROR_MSG  := ('ATTR_GROUP_ID NOT EXISTS OR FAILED DUE TO '|| SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE ('ATTR_GROUP_ID: ' || l_attr_group_id);
    
    IF P_ERROR_FLAG = 'Y'
    THEN
      DBMS_OUTPUT.PUT_LINE ('*****START INSERT*****');
      
      INSERT INTO XX_CDH_CUST_ACCT_EXT_B 
                  (EXTENSION_ID,
                   CUST_ACCOUNT_ID,
                   ATTR_GROUP_ID,
                   N_EXT_ATTR1,
                   C_EXT_ATTR2,
                   C_EXT_ATTR3,
                   C_EXT_ATTR14,
                   C_EXT_ATTR7,
                   D_EXT_ATTR9,
                   C_EXT_ATTR1,
                   N_EXT_ATTR2,
                   C_EXT_ATTR16,
                   CREATED_BY,
                   CREATION_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_DATE,
                   LAST_UPDATE_LOGIN
                  )
        VALUES (ego_extfwk_s.nextval,
                l_cust_acct_id,
                l_attr_group_id,
                P_MBS_DOC_ID,
                P_PAY_DOC,
                P_DELIVERY_METHOD,
                P_PAYMNET_TERM,
                P_DIRECT_DOCUMENT,
                P_REQUEST_DATE,
                P_INVOICE_TYPE,
                XX_CDH_CUST_DOC_ID_S.NEXTVAL,
                'COMPLETE',
                fnd_global.user_id,
                SYSDATE,
                fnd_global.user_id,
                SYSDATE,
                -1
                );
       COMMIT; 
      DBMS_OUTPUT.PUT_LINE ('*****INSERT END*****');
    END IF;  
  END IF;
  DBMS_OUTPUT.PUT_LINE ('*****END*****');
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE ('MAIN EXCEPTION: PROCESS FALIED DUE TO ' || SQLERRM);
P_ERROR_FLAG := 'E';
P_ERROR_MSG  := ('MAIN EXCEPTION: PROCESS FALIED DUE TO ' || SQLERRM);
END;
/
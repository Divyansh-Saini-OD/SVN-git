SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_AR_GET_CUSTOMER_ID_TYPE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : xx_ar_get_customer_id_type                                          |
-- | Description : To get customer_id                                                  |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       29-Mar-2010  Usha R               Initial Version                        |
-- +===================================================================================+


CREATE OR REPLACE FUNCTION XX_AR_Get_Customer_ID_Type(x_CUSTOMER_ID IN NUMBER)
  RETURN NUMBER 
  IS
     ln_Customer_ID_Type_Exists NUMBER(1);
BEGIN
  BEGIN
    SELECT 1
    INTO ln_Customer_ID_Type_Exists
    FROM HZ_CUST_ACCOUNTS HZA
    WHERE CUST_ACCOUNT_ID = x_CUSTOMER_ID
    AND CUSTOMER_TYPE = 'I'
    AND ROWNUM = 1;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_Customer_ID_Type_Exists:=0;
        RETURN ln_Customer_ID_Type_Exists;
  END;
  RETURN ln_Customer_ID_Type_Exists;
END XX_AR_Get_Customer_ID_Type;
/
SHOW ERR
CREATE OR REPLACE PROCEDURE Usage_Load_Dummy AS

/*---------------------------------------------------------------------------
-- Procedure Usage_Load
-- Created First Draft January, 2008
-- This procedure reads data from a staging table that resides in the 
-- EBS database and pushes data to the usage database, which is seperate from EBS,
-- This is done via  database link.
--
--
------------------------------------------------------------------------------
*/

BEGIN

DECLARE

v_count	     NUMBER := 0;
v_cust_po_nbr_desc   VARCHAR2(150);
v_cust_release_nbr_desc  VARCHAR2(150);
v_cust_dept_desc      VARCHAR2(150);
v_desktop_loc_desc    VARCHAR2(150);
v_order_id NUMBER;
v_customer_id NUMBER;
v_sql_msg  VARCHAR2(2000);

data_exception	EXCEPTION;
v_error_message VARCHAR2(2000);
v_sqlcode    VARCHAR2(20);

CURSOR cur1(v_customer_id NUMBER, v_order_id NUMBER) IS
SELECT * FROM OD_EXT_USAGE_RPT
WHERE ROWNUM < 500;

CURSOR cur_label(v_customer_id NUMBER) IS
SELECT cust_po_nbr_label, cust_release_nbr_label,desktop_loc_label,cust_dept_label
FROM USAGE_LABELS
WHERE customer_id = v_customer_id;

CURSOR cust_id IS
SELECT DISTINCT customer_id
FROM OD_EXT_USAGE_RPT
WHERE ROWNUM < 10;

CURSOR order_id(v_customer_id NUMBER) IS
SELECT DISTINCT order_id
FROM OD_EXT_USAGE_RPT;



BEGIN

--Cursor Check of Exception Messaging
--Cursor Main Insert of New Records

FOR main_cust_id IN cust_id LOOP
BEGIN

v_customer_id := TO_NUMBER(main_cust_id.customer_id + 1);


FOR main_order_id IN order_id(main_cust_id.customer_id) LOOP
BEGIN

v_order_id := TO_NUMBER(main_order_id.order_id + 1);

FOR main_cur IN cur1(main_cust_id.customer_id, main_order_id.order_id) LOOP
v_error_message := NULL;
BEGIN

--get labels
v_cust_po_nbr_desc := NULL;
v_cust_release_nbr_desc := NULL;
v_cust_dept_desc   := NULL;
v_desktop_loc_desc := NULL;

OPEN cur_label(main_cur.customer_id);
FETCH cur_label INTO v_cust_po_nbr_desc, v_cust_release_nbr_desc, v_desktop_loc_desc, v_cust_dept_desc;
CLOSE cur_label;



--dbms_output.put_line(main_cur.order_id);

--transform values






INSERT INTO OD_EXT_USAGE_RPT_TEST(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,  
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  OD_SKU,
  CUST_RELEASE_NUMBER,
  DESKTOP_LOCATOR,
  CUST_RELEASE_NUMBER_DESC,
  DESKTOP_LOCATOR_DESC,
  CUST_PO_NUMBER_DESC,
  SOURCE_SYSTEM_NAME)
  VALUES(
  v_order_id,
  main_cur.ORDER_LINE_NUMBER,
  main_cur.FULLFILLMENT_ID,
  v_customer_id,
  main_cur.ACCOUNT_NUMBER,
  main_cur.CUSTOMER_NAME,
  main_cur.CUSTOMER_DEPT,
  main_cur.CUSTOMER_DEPT_DESC,
  main_cur.PARENT_NAME,
  main_cur.PARENT_ID,
  main_cur.PRODUCT_CODE,
  main_cur.RETAIL_PRICE,
  main_cur.PRODUCT_DESC,
  main_cur.WHOLESALE_PRODUCT_CODE,
  main_cur.CUSTOMER_PRODUCT_CODE,
  main_cur.EDI_SELL_CODE,
  main_cur.QUANTITY_SHIPPED,
  main_cur.QUANTITY,
  main_cur.CUSTOMER_CURRENCY,
  main_cur.EXTENDED_PRICE,
  main_cur.RECONCILED_DATE,
  main_cur.SHIP_TO_CONTACT_NAME,
  main_cur.SHIP_TO_CUSTOMER_ID,
  main_cur.SHIP_TO_CUSTOMER_NAME,
  main_cur.SHIP_TO_ADDRESS_LINE1,
  main_cur.SHIP_TO_ADDRESS_LINE2,
  main_cur.SHIP_TO_CITY,
  main_cur.SHIP_TO_STATE,
  main_cur.SHIP_TO_ZIP,
  main_cur.COUNTRY_CODE,
  main_cur.BILL_TO_CUSTOMER_ID,
  main_cur.BILL_TO_CUSTOMER_NAME,
  main_cur.BILL_TO_ADDRESS_LINE1,  
  main_cur.BILL_TO_ADDRESS_LINE2,
  main_cur.BILL_TO_CITY,
  main_cur.BILL_TO_STATE,
  main_cur.BILL_TO_ZIP,
  main_cur.ORDER_CREATE_DATE,
  main_cur.DELIVERY_DATE,
  main_cur.ORDER_COMPLETED_DATE,
  main_cur.UNIT_OF_MEASURE,
  main_cur.CUST_PO_NUMBER,
  main_cur.ITEM_DEPT_DESC,
  main_cur.ORDER_NUMBER,
  main_cur.SUB_ORDER,
  main_cur.ORDER_NUMBER_FULLFILLMENT,
  main_cur.SHIP_TO_ID,
  main_cur.SHIP_TO_KEY,
  main_cur.OD_SKU,
  main_cur.CUST_RELEASE_NUMBER,
  main_cur.DESKTOP_LOCATOR,
  main_cur.CUST_RELEASE_NUMBER_DESC,
  main_cur.DESKTOP_LOCATOR_DESC,
  main_cur.CUST_PO_NUMBER_DESC,
  main_cur.SOURCE_SYSTEM_NAME);

--v_count := v_count + 1;


EXCEPTION

WHEN OTHERS THEN

v_sqlcode := SQLCODE;
v_sql_msg := SQLERRM;

INSERT INTO OD_EXT_USAGE_ERR_TEST(
  ORDER_ID,
  ORDER_LINE_NUMBER,
  FULLFILLMENT_ID,
  CUSTOMER_ID,
  ACCOUNT_NUMBER,
  CUSTOMER_NAME,
  CUSTOMER_DEPT,
  CUSTOMER_DEPT_DESC,
  PARENT_NAME,
  PARENT_ID,
  PRODUCT_CODE,
  RETAIL_PRICE,
  PRODUCT_DESC,
  WHOLESALE_PRODUCT_CODE,
  CUSTOMER_PRODUCT_CODE,
  EDI_SELL_CODE,
  QUANTITY_SHIPPED,
  QUANTITY,
  CUSTOMER_CURRENCY,
  EXTENDED_PRICE,
  RECONCILED_DATE,
  SHIP_TO_CONTACT_NAME,
  SHIP_TO_CUSTOMER_ID,
  SHIP_TO_CUSTOMER_NAME,
  SHIP_TO_ADDRESS_LINE1,
  SHIP_TO_ADDRESS_LINE2,
  SHIP_TO_CITY,
  SHIP_TO_STATE,
  SHIP_TO_ZIP,
  COUNTRY_CODE,
  BILL_TO_CUSTOMER_ID,
  BILL_TO_CUSTOMER_NAME,
  BILL_TO_ADDRESS_LINE1,  
  BILL_TO_ADDRESS_LINE2,
  BILL_TO_CITY,
  BILL_TO_STATE,
  BILL_TO_ZIP,
  ORDER_CREATE_DATE,
  DELIVERY_DATE,
  ORDER_COMPLETED_DATE,
  UNIT_OF_MEASURE,
  CUST_PO_NUMBER,
  ITEM_DEPT_DESC,
  ORDER_NUMBER,
  SUB_ORDER,
  ORDER_NUMBER_FULLFILLMENT,
  SHIP_TO_ID,
  SHIP_TO_KEY,
  OD_SKU,
  SOURCE_SYSTEM_NAME,
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  v_order_id,
  main_cur.ORDER_LINE_NUMBER,
  main_cur.FULLFILLMENT_ID,
  v_customer_id,
  main_cur.ACCOUNT_NUMBER,
  main_cur.CUSTOMER_NAME,
  main_cur.CUSTOMER_DEPT,
  main_cur.CUSTOMER_DEPT_DESC,
  main_cur.PARENT_NAME,
  main_cur.PARENT_ID,
  main_cur.PRODUCT_CODE,
  main_cur.RETAIL_PRICE,
  main_cur.PRODUCT_DESC,
  main_cur.WHOLESALE_PRODUCT_CODE,
  main_cur.CUSTOMER_PRODUCT_CODE,
  main_cur.EDI_SELL_CODE,
  main_cur.QUANTITY_SHIPPED,
  main_cur.QUANTITY,
  main_cur.CUSTOMER_CURRENCY,
  main_cur.EXTENDED_PRICE,
  main_cur.RECONCILED_DATE,
  main_cur.SHIP_TO_CONTACT_NAME,
  main_cur.SHIP_TO_CUSTOMER_ID,
  main_cur.SHIP_TO_CUSTOMER_NAME,
  main_cur.SHIP_TO_ADDRESS_LINE1,
  main_cur.SHIP_TO_ADDRESS_LINE2,
  main_cur.SHIP_TO_CITY,
  main_cur.SHIP_TO_STATE,
  main_cur.SHIP_TO_ZIP,
  main_cur.COUNTRY_CODE,
  main_cur.BILL_TO_CUSTOMER_ID,
  main_cur.BILL_TO_CUSTOMER_NAME,
  main_cur.BILL_TO_ADDRESS_LINE1,  
  main_cur.BILL_TO_ADDRESS_LINE2,
  main_cur.BILL_TO_CITY,
  main_cur.BILL_TO_STATE,
  main_cur.BILL_TO_ZIP,
  main_cur.ORDER_CREATE_DATE,
  main_cur.DELIVERY_DATE,
  main_cur.ORDER_COMPLETED_DATE,
  main_cur.UNIT_OF_MEASURE,
  main_cur.CUST_PO_NUMBER,
  main_cur.ITEM_DEPT_DESC,
  main_cur.ORDER_NUMBER,
  main_cur.SUB_ORDER,
  main_cur.ORDER_NUMBER_FULLFILLMENT,
  main_cur.SHIP_TO_ID,
  main_cur.SHIP_TO_KEY,
  main_cur.OD_SKU,
  main_cur.SOURCE_SYSTEM_NAME,
  v_sqlcode,
  v_sql_msg);

END;
END LOOP;

END;
END LOOP;

END;
END LOOP;

COMMIT;


END;

END Usage_Load_Dummy;
/

		

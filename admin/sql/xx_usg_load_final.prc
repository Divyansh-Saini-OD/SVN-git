CREATE OR REPLACE PROCEDURE USAGE_LOAD(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) AS

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

data_exception	EXCEPTION;
v_error_message VARCHAR2(2000);
v_sqlcode    VARCHAR2(20);

CURSOR cur1 IS
SELECT * FROM usage_stage
order by reconciled_date;

CURSOR cur_acct IS
SELECT DISTINCT customer_id 
from usage_stage;

CURSOR cur_po(v_account_num NUMBER) IS
SELECT DISTINCT customer_po_number
FROM usage_stage
WHERE customer_id = v_account_num
and customer_po_number IS NOT NULL;

CURSOR cur_cc(v_account_num NUMBER) IS
SELECT distinct cust_dept_key
FROM usage_stage
WHERE customer_id = v_account_num
and cust_dept_key IS NOT NULL;

CURSOR cur_st(v_account_num NUMBER) IS
SELECT distinct aops_sequence_id
FROM usage_stage
WHERE customer_id = v_account_num
and aops_sequence_id IS NOT NULL;

CURSOR cur_label(v_customer_id NUMBER) IS
SELECT cust_po_nbr_label, cust_release_nbr_label,desktop_loc_label,cust_dept_label
FROM usage_labels@USAGE_LINK
WHERE customer_id = v_customer_id;



BEGIN

--Cursor Check of Exception Messaging
--Cursor Main Insert of New Records

FOR main_cur IN cur1 LOOP
v_error_message := NULL;
BEGIN

dbms_output.put_line(main_cur.order_id);

--Check for critical missing data
IF main_cur.aops_sequence_id IS NULL THEN
v_error_message := 'Missing Customer Ship To ID';
RAISE data_exception;
ELSIF main_cur.aops_sequence_id = '00000' THEN
v_error_message := 'Invalid Customer Ship To ID';
RAISE data_exception;
END IF;

--get labels
v_cust_po_nbr_desc := NULL;
v_cust_release_nbr_desc := NULL;
v_cust_dept_desc   := NULL;
v_desktop_loc_desc := NULL;

OPEN cur_label(main_cur.customer_id);
FETCH cur_label INTO v_cust_po_nbr_desc, v_cust_release_nbr_desc, v_desktop_loc_desc, v_cust_dept_desc;
CLOSE cur_label;


INSERT INTO od_ext_usage_rpt@USAGE_LINK(
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
  to_number(main_cur.order_id),
  to_number(main_cur.order_line_number),
  to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(v_cust_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  to_number(main_cur.parent_id),
  ltrim(rtrim(main_cur.product_code_sku)),
  to_number(main_cur.sku_retail_price),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  to_number(main_cur.quantity_shipped),
  to_number(main_cur.quantity_ordered),
  ltrim(rtrim(main_cur.customer_currency)),
  to_number(main_cur.extended_price),
  to_date(main_cur.reconciled_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  main_cur.aops_sequence_id,
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),  
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  to_date(main_cur.order_create_date,'MMDDYYYY'),
  to_date(main_cur.delivery_date,'MMDDYYYY'),
  to_date(main_cur.order_completed_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  to_number(main_cur.order_number),
  to_number(main_cur.sub_order),
  to_number(main_cur.order_number)||'-00'||to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.od_sku,
  main_cur.cust_release_nbr,
  main_cur.desktop_loc,
  v_cust_release_nbr_desc,
  v_desktop_loc_desc,
  v_cust_po_nbr_desc,
  'TRD');

v_count := v_count + 1;

--Check for other exceptions
IF main_cur.cust_addr_line_1 IS NULL THEN
v_error_message := 'Missing Customer Address Line 1';
RAISE data_exception;
END IF;

IF main_cur.cust_city IS NULL THEN
v_error_message := 'Missing Customer Ship To City';
RAISE data_exception;
END IF;

IF main_cur.cust_state IS NULL THEN
v_error_message := 'Missing Customer Ship To State';
RAISE data_exception;
END IF;

IF main_cur.ship_to_zip IS NULL THEN
v_error_message := 'Missing Customer Ship To Zip';
RAISE data_exception;
END IF;

IF main_cur.order_number IS NULL THEN
v_error_message := 'Missing Customer Order Number';
RAISE data_exception;
END IF;

IF main_cur.bill_to_address_line_1 IS NULL THEN
v_error_message := 'Missing Bill To Address Line 1';
RAISE data_exception;
END IF;

IF main_cur.bill_to_city IS NULL THEN
v_error_message := 'Missing Bill To City';
RAISE data_exception;
END IF;

IF main_cur.bill_to_state IS NULL THEN
v_error_message := 'Missing Bill To State';
RAISE data_exception;
END IF;

IF main_cur.bill_to_zip IS NULL THEN
v_error_message := 'Missing Bill To Zip';
RAISE data_exception;
END IF;

EXCEPTION

WHEN data_exception THEN

v_sqlcode := '99999';

INSERT INTO od_ext_usage_err@USAGE_LINK(
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
  to_number(main_cur.order_id),
  to_number(main_cur.order_line_number),
  to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.customer_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  to_number(main_cur.parent_id),
  ltrim(rtrim(main_cur.product_code_sku)),
  to_number(main_cur.sku_retail_price),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  to_number(main_cur.quantity_shipped),
  to_number(main_cur.quantity_ordered),
  ltrim(rtrim(main_cur.customer_currency)),
  to_number(main_cur.extended_price),
  to_date(main_cur.reconciled_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),  
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  to_date(main_cur.order_create_date,'MMDDYYYY'),
  to_date(main_cur.delivery_date,'MMDDYYYY'),
  to_date(main_cur.order_completed_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  to_number(main_cur.order_number),
  to_number(main_cur.sub_order),
  to_number(main_cur.order_number)||'-00'||to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.od_sku,
  'ERR',
  v_sqlcode,
  v_error_message);


WHEN DUP_VAL_ON_INDEX THEN

UPDATE od_ext_usage_rpt@USAGE_LINK SET
  
  CUSTOMER_ID = ltrim(rtrim(main_cur.customer_id)),
  ACCOUNT_NUMBER = ltrim(rtrim(main_cur.account_number_aops)),
  CUSTOMER_NAME = ltrim(rtrim(main_cur.customer_name)),
  CUSTOMER_DEPT = ltrim(rtrim(main_cur.cust_dept_key)),
  CUSTOMER_DEPT_DESC = ltrim(rtrim(main_cur.customer_dept_desc)),
  PARENT_NAME = ltrim(rtrim(main_cur.parent_name)),
  PARENT_ID = to_number(main_cur.parent_id),
  PRODUCT_CODE = ltrim(rtrim(main_cur.product_code_sku)),
  RETAIL_PRICE = to_number(main_cur.sku_retail_price),
  PRODUCT_DESC = ltrim(rtrim(main_cur.product_desc_sku)),
  WHOLESALE_PRODUCT_CODE = ltrim(rtrim(main_cur.wholesale_product_cd)),
  CUSTOMER_PRODUCT_CODE = ltrim(rtrim(main_cur.cust_product_cd)),
  EDI_SELL_CODE = ltrim(rtrim(main_cur.edi_sell_code)),
  QUANTITY_SHIPPED = to_number(main_cur.quantity_shipped),
  QUANTITY = to_number(main_cur.quantity_ordered),
  CUSTOMER_CURRENCY = ltrim(rtrim(main_cur.customer_currency)),
  EXTENDED_PRICE = to_number(main_cur.extended_price),
  RECONCILED_DATE = to_date(main_cur.reconciled_date,'MMDDYYYY'),
  SHIP_TO_CONTACT_NAME = ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  SHIP_TO_CUSTOMER_ID = ltrim(rtrim(main_cur.aops_sequence_id)),
  SHIP_TO_CUSTOMER_NAME = ltrim(rtrim(main_cur.ship_to_customer_name)),
  SHIP_TO_ADDRESS_LINE1 = ltrim(rtrim(main_cur.cust_addr_line_1)),
  SHIP_TO_ADDRESS_LINE2 = ltrim(rtrim(main_cur.cust_addr_line_2)),
  SHIP_TO_CITY = ltrim(rtrim(main_cur.cust_city)),
  SHIP_TO_STATE = ltrim(rtrim(main_cur.cust_state)),
  SHIP_TO_ZIP = ltrim(rtrim(main_cur.ship_to_zip)),
  COUNTRY_CODE = ltrim(rtrim(main_cur.cust_country_cd)),
  BILL_TO_CUSTOMER_ID = ltrim(rtrim(main_cur.customer_id)),
  BILL_TO_CUSTOMER_NAME = ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  BILL_TO_ADDRESS_LINE1 = ltrim(rtrim(main_cur.bill_to_address_line_1)),  
  BILL_TO_ADDRESS_LINE2 = ltrim(rtrim(main_cur.bill_to_address_line_2)),
  BILL_TO_CITY = ltrim(rtrim(main_cur.bill_to_city)),
  BILL_TO_STATE = ltrim(rtrim(main_cur.bill_to_state)),
  BILL_TO_ZIP =  ltrim(rtrim(main_cur.bill_to_zip)),
  ORDER_CREATE_DATE = to_date(main_cur.order_create_date,'MMDDYYYY'),
  DELIVERY_DATE = to_date(main_cur.delivery_date,'MMDDYYYY'),
  ORDER_COMPLETED_DATE = to_date(main_cur.order_completed_date,'MMDDYYYY'),
  UNIT_OF_MEASURE = ltrim(rtrim(main_cur.edi_sell_code)),
  CUST_PO_NUMBER = ltrim(rtrim(main_cur.customer_po_number)),
  ITEM_DEPT_DESC = ltrim(rtrim(main_cur.item_dept_desc)),
  ORDER_NUMBER = to_number(main_cur.order_number),
  SUB_ORDER = to_number(main_cur.sub_order),
  ORDER_NUMBER_FULLFILLMENT = to_number(main_cur.order_number)||'-00'||to_number(main_cur.fullfillment_id),
  SHIP_TO_ID = ltrim(rtrim(main_cur.customer_ship_to_id)),
  SHIP_TO_KEY = main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  CUST_RELEASE_NUMBER = main_cur.cust_release_nbr,
  DESKTOP_LOCATOR = main_cur.desktop_loc,
  SOURCE_SYSTEM_NAME = 'UPD'
where ORDER_ID = to_number(main_cur.order_id)
AND ORDER_LINE_NUMBER = to_number(main_cur.order_line_number)
AND FULLFILLMENT_ID = to_number(main_cur.fullfillment_id);


WHEN OTHERS THEN
dbms_output.put_line(SQLCODE||', '||SQLERRM);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Updating Duplicate Values');
FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

p_retcode := SQLCODE;
P_errbuf := v_error_message;


INSERT INTO od_ext_usage_err@USAGE_LINK(
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
  to_number(main_cur.order_id),
  to_number(main_cur.order_line_number),
  to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.account_number_aops)),
  ltrim(rtrim(main_cur.customer_name)),
  ltrim(rtrim(main_cur.cust_dept_key)),
  ltrim(rtrim(main_cur.customer_dept_desc)),
  ltrim(rtrim(main_cur.parent_name)),
  to_number(main_cur.parent_id),
  ltrim(rtrim(main_cur.product_code_sku)),
  to_number(main_cur.sku_retail_price),
  ltrim(rtrim(main_cur.product_desc_sku)),
  ltrim(rtrim(main_cur.wholesale_product_cd)),
  ltrim(rtrim(main_cur.cust_product_cd)),
  ltrim(rtrim(main_cur.edi_sell_code)),
  to_number(main_cur.quantity_shipped),
  to_number(main_cur.quantity_ordered),
  ltrim(rtrim(main_cur.customer_currency)),
  to_number(main_cur.extended_price),
  to_date(main_cur.reconciled_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.customer_ship_to_contact_name)),
  ltrim(rtrim(main_cur.aops_sequence_id)),
  ltrim(rtrim(main_cur.ship_to_customer_name)),
  ltrim(rtrim(main_cur.cust_addr_line_1)),
  ltrim(rtrim(main_cur.cust_addr_line_2)),
  ltrim(rtrim(main_cur.cust_city)),
  ltrim(rtrim(main_cur.cust_state)),
  ltrim(rtrim(main_cur.ship_to_zip)),
  ltrim(rtrim(main_cur.cust_country_cd)),
  ltrim(rtrim(main_cur.customer_id)),
  ltrim(rtrim(main_cur.customer_bill_to_business_name)),
  ltrim(rtrim(main_cur.bill_to_address_line_1)),  
  ltrim(rtrim(main_cur.bill_to_address_line_2)),
  ltrim(rtrim(main_cur.bill_to_city)),
  ltrim(rtrim(main_cur.bill_to_state)),
  ltrim(rtrim(main_cur.bill_to_zip)),
  to_date(main_cur.order_create_date,'MMDDYYYY'),
  to_date(main_cur.delivery_date,'MMDDYYYY'),
  to_date(main_cur.order_completed_date,'MMDDYYYY'),
  ltrim(rtrim(main_cur.edi_sell_code)),
  ltrim(rtrim(main_cur.customer_po_number)),
  ltrim(rtrim(main_cur.item_dept_desc)),
  to_number(main_cur.order_number),
  to_number(main_cur.sub_order),
  to_number(main_cur.order_number)||'-00'||to_number(main_cur.fullfillment_id),
  ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.aops_sequence_id||'-'||ltrim(rtrim(main_cur.customer_ship_to_id)),
  main_cur.od_sku,
  'ERR',
  v_sqlcode,
  v_error_message);
END;



END LOOP;



BEGIN 
FOR main_cur_acct IN cur_acct LOOP

  BEGIN
  FOR main_cur_po IN cur_po(main_cur_acct.customer_id) LOOP
   BEGIN

  IF ltrim(rtrim(main_cur_po.customer_po_number)) IS NOT NULL THEN
  INSERT INTO USAGE_LOV@USAGE_LINK(
   account_number, lov_type, lov_description)
   VALUES(
   main_cur_acct.customer_id,'PO',ltrim(rtrim(main_cur_po.customer_po_number)));
  ELSE
   INSERT INTO USAGE_LOV@USAGE_LINK(
   account_number, lov_type, lov_description)
   VALUES(
   main_cur_acct.customer_id,'PO','0');
  END IF;

  EXCEPTION

   WHEN DUP_VAL_ON_INDEX THEN
   NULL;
    END;
  END LOOP;
  END;


 
  BEGIN
  FOR main_cur_cc IN cur_cc(main_cur_acct.customer_id) LOOP
   BEGIN
 
  IF ltrim(rtrim(main_cur_cc.cust_dept_key)) IS NOT NULL THEN
  INSERT INTO USAGE_LOV@USAGE_LINK(
   account_number, lov_type, lov_description)
   VALUES(
   main_cur_acct.customer_id,'CC',ltrim(rtrim(main_cur_cc.cust_dept_key)));
  ELSE
   INSERT INTO USAGE_LOV@USAGE_LINK(
   account_number, lov_type, lov_description)
   VALUES(
   main_cur_acct.customer_id,'CC','0');
  END IF;

  EXCEPTION

   WHEN DUP_VAL_ON_INDEX THEN
   NULL;
  END;
  END LOOP;
  END;


  BEGIN
  FOR main_cur_st IN cur_st(main_cur_acct.customer_id) LOOP
   BEGIN

  IF ltrim(rtrim(main_cur_st.aops_sequence_id)) IS NOT NULL THEN
  INSERT INTO USAGE_LOV@USAGE_LINK(
   account_number, lov_type, lov_description)
   VALUES(
   main_cur_acct.customer_id,'ST',ltrim(rtrim(main_cur_st.aops_sequence_id)));
  END IF;

  EXCEPTION

   WHEN DUP_VAL_ON_INDEX THEN
   NULL;
  END;
  END LOOP;
  END;



END LOOP;

COMMIT;
END;


EXCEPTION

WHEN OTHERS THEN
dbms_output.put_line(SQLCODE||', '||SQLERRM);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Program Processing - Please check the od_ext_usage_err table');
 FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||', '||SQLERRM);

v_sqlcode := SQLCODE;
v_error_message := SQLERRM;

p_retcode := SQLCODE;
p_errbuf := SQLERRM;


INSERT INTO od_ext_usage_err@USAGE_LINK(
  SQL_CODE,
  SQL_ERR_MSG)
  VALUES(
  v_sqlcode,
  v_error_message);  



END;
END usage_load;
/

		

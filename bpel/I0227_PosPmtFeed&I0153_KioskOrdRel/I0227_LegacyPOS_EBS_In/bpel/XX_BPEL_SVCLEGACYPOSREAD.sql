-- Declare the SQL type for the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG_X AS OBJECT (
      ORDER_NUMBER NUMBER,
      HEADER_ID NUMBER,
      TRANSACTION_TYPE VARCHAR2(20),
      POS_TRANSACTION_NUM VARCHAR2(240)
);
/
show errors
-- Declare the SQL type for the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG_10 AS OBJECT (
      ORDER_NUMBER NUMBER,
      SKU_NUMBER VARCHAR2(240),
      INVENTORY_ITEM_ID NUMBER,
      LINE_ID NUMBER,
      LINE_NUMBER NUMBER,
      UOM_CODE VARCHAR2(50),
      WAREHOUSE_CODE VARCHAR2(240),
      SHIP_FROM_ORG_ID NUMBER,
      SALESREP_NAME VARCHAR2(240),
      SALESREP_ID NUMBER,
      TAX_AMT NUMBER,
      SELLING_PRICE NUMBER,
      SHIPPED_QUANTITY NUMBER,
      SERIAL_NUMBER NUMBER,
      LINE_STATUS VARCHAR2(20),
      TAX_CODE VARCHAR2(240)
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG_7 AS TABLE OF XX_OM_LEG_POS_SHIP_CONF_PKG_10; 
/
show errors
-- Declare the SQL type for the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG11 AS OBJECT (
      ORDER_NUMBER NUMBER,
      LINE_NUMBER NUMBER,
      PAYMENT_METHOD VARCHAR2(30),
      PAYMENT_INSTRUMENT VARCHAR2(30),
      PAYMENT_DETAILS VARCHAR2(50),
      EXPIRATION_DATE DATE,
      PAYMENT_AMOUNT NUMBER,
      ACCT_HOLDER_NAME VARCHAR2(240),
      ACCOUNT_NUMBER NUMBER,
      ROUTING_NUMBER NUMBER,
      AUTHORIZATION_CODE VARCHAR2(20)
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG_8 AS TABLE OF XX_OM_LEG_POS_SHIP_CONF_PKG11; 
/
show errors
-- Declare the SQL type for the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG12 AS OBJECT (
      LINE_NUMBER NUMBER,
      ERROR_MESSAGE VARCHAR2(2000)
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_LEG_POS_SHIP_CONF_PKG_9 AS TABLE OF XX_OM_LEG_POS_SHIP_CONF_PKG12; 
/
show errors
-- Declare package containing conversion functions between SQL and PL/SQL types
CREATE OR REPLACE PACKAGE XX_BPEL_SVCLEGACYPOSREAD AS
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE
	FUNCTION PL_TO_SQL8(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_X;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_X)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE
	FUNCTION PL_TO_SQL9(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_10;
	FUNCTION SQL_TO_PL11(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_10)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL
	FUNCTION PL_TO_SQL10(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_7;
	FUNCTION SQL_TO_PL8(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_7)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE
	FUNCTION PL_TO_SQL11(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG11;
	FUNCTION SQL_TO_PL12(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG11)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL
	FUNCTION PL_TO_SQL12(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_8;
	FUNCTION SQL_TO_PL9(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_8)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE
	FUNCTION PL_TO_SQL13(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG12;
	FUNCTION SQL_TO_PL13(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG12)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE;
	-- Declare the conversion functions the PL/SQL type XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_9;
	FUNCTION SQL_TO_PL10(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_9)
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL;
   PROCEDURE XX_OM_LEG_POS_SHIP_CONF_PKG$O (P_ORDER_NUMBER IN OUT NUMBER,P_ORDER_HEADER_REC XX_OM_LEG_POS_SHIP_CONF_PKG_X,P_ORDER_LINES_TBL XX_OM_LEG_POS_SHIP_CONF_PKG_7,P_ORDER_PAYMENTS_TBL XX_OM_LEG_POS_SHIP_CONF_PKG_8,X_ORDER_LINES_TBL_OUT OUT XX_OM_LEG_POS_SHIP_CONF_PKG_9,X_STATUS OUT VARCHAR2,X_TRANSACTION_DATE OUT VARCHAR2,X_MESSAGE OUT VARCHAR2);
END XX_BPEL_SVCLEGACYPOSREAD;
/
show errors
CREATE OR REPLACE PACKAGE BODY XX_BPEL_SVCLEGACYPOSREAD IS
	FUNCTION PL_TO_SQL8(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_X IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_X; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG_X(NULL, NULL, NULL, NULL);
		aSqlItem.ORDER_NUMBER := aPlsqlItem.ORDER_NUMBER;
		aSqlItem.HEADER_ID := aPlsqlItem.HEADER_ID;
		aSqlItem.TRANSACTION_TYPE := aPlsqlItem.TRANSACTION_TYPE;
		aSqlItem.POS_TRANSACTION_NUM := aPlsqlItem.POS_TRANSACTION_NUM;
		RETURN aSqlItem;
	END PL_TO_SQL8;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_X) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE; 
	BEGIN 
		aPlsqlItem.ORDER_NUMBER := aSqlItem.ORDER_NUMBER;
		aPlsqlItem.HEADER_ID := aSqlItem.HEADER_ID;
		aPlsqlItem.TRANSACTION_TYPE := aSqlItem.TRANSACTION_TYPE;
		aPlsqlItem.POS_TRANSACTION_NUM := aSqlItem.POS_TRANSACTION_NUM;
		RETURN aPlsqlItem;
	END SQL_TO_PL7;
	FUNCTION PL_TO_SQL9(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_10 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_10; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG_10(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.ORDER_NUMBER := aPlsqlItem.ORDER_NUMBER;
		aSqlItem.SKU_NUMBER := aPlsqlItem.SKU_NUMBER;
		aSqlItem.INVENTORY_ITEM_ID := aPlsqlItem.INVENTORY_ITEM_ID;
		aSqlItem.LINE_ID := aPlsqlItem.LINE_ID;
		aSqlItem.LINE_NUMBER := aPlsqlItem.LINE_NUMBER;
		aSqlItem.UOM_CODE := aPlsqlItem.UOM_CODE;
		aSqlItem.WAREHOUSE_CODE := aPlsqlItem.WAREHOUSE_CODE;
		aSqlItem.SHIP_FROM_ORG_ID := aPlsqlItem.SHIP_FROM_ORG_ID;
		aSqlItem.SALESREP_NAME := aPlsqlItem.SALESREP_NAME;
		aSqlItem.SALESREP_ID := aPlsqlItem.SALESREP_ID;
		aSqlItem.TAX_AMT := aPlsqlItem.TAX_AMT;
		aSqlItem.SELLING_PRICE := aPlsqlItem.SELLING_PRICE;
		aSqlItem.SHIPPED_QUANTITY := aPlsqlItem.SHIPPED_QUANTITY;
		aSqlItem.SERIAL_NUMBER := aPlsqlItem.SERIAL_NUMBER;
		aSqlItem.LINE_STATUS := aPlsqlItem.LINE_STATUS;
		aSqlItem.TAX_CODE := aPlsqlItem.TAX_CODE;
		RETURN aSqlItem;
	END PL_TO_SQL9;
	FUNCTION SQL_TO_PL11(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_10) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_REC_TYPE; 
	BEGIN 
		aPlsqlItem.ORDER_NUMBER := aSqlItem.ORDER_NUMBER;
		aPlsqlItem.SKU_NUMBER := aSqlItem.SKU_NUMBER;
		aPlsqlItem.INVENTORY_ITEM_ID := aSqlItem.INVENTORY_ITEM_ID;
		aPlsqlItem.LINE_ID := aSqlItem.LINE_ID;
		aPlsqlItem.LINE_NUMBER := aSqlItem.LINE_NUMBER;
		aPlsqlItem.UOM_CODE := aSqlItem.UOM_CODE;
		aPlsqlItem.WAREHOUSE_CODE := aSqlItem.WAREHOUSE_CODE;
		aPlsqlItem.SHIP_FROM_ORG_ID := aSqlItem.SHIP_FROM_ORG_ID;
		aPlsqlItem.SALESREP_NAME := aSqlItem.SALESREP_NAME;
		aPlsqlItem.SALESREP_ID := aSqlItem.SALESREP_ID;
		aPlsqlItem.TAX_AMT := aSqlItem.TAX_AMT;
		aPlsqlItem.SELLING_PRICE := aSqlItem.SELLING_PRICE;
		aPlsqlItem.SHIPPED_QUANTITY := aSqlItem.SHIPPED_QUANTITY;
		aPlsqlItem.SERIAL_NUMBER := aSqlItem.SERIAL_NUMBER;
		aPlsqlItem.LINE_STATUS := aSqlItem.LINE_STATUS;
		aPlsqlItem.TAX_CODE := aSqlItem.TAX_CODE;
		RETURN aPlsqlItem;
	END SQL_TO_PL11;
	FUNCTION PL_TO_SQL10(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_7 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_7; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG_7();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL9(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL10;
	FUNCTION SQL_TO_PL8(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_7) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL11(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL8;
	FUNCTION PL_TO_SQL11(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG11 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG11; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG11(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.ORDER_NUMBER := aPlsqlItem.ORDER_NUMBER;
		aSqlItem.LINE_NUMBER := aPlsqlItem.LINE_NUMBER;
		aSqlItem.PAYMENT_METHOD := aPlsqlItem.PAYMENT_METHOD;
		aSqlItem.PAYMENT_INSTRUMENT := aPlsqlItem.PAYMENT_INSTRUMENT;
		aSqlItem.PAYMENT_DETAILS := aPlsqlItem.PAYMENT_DETAILS;
		aSqlItem.EXPIRATION_DATE := aPlsqlItem.EXPIRATION_DATE;
		aSqlItem.PAYMENT_AMOUNT := aPlsqlItem.PAYMENT_AMOUNT;
		aSqlItem.ACCT_HOLDER_NAME := aPlsqlItem.ACCT_HOLDER_NAME;
		aSqlItem.ACCOUNT_NUMBER := aPlsqlItem.ACCOUNT_NUMBER;
		aSqlItem.ROUTING_NUMBER := aPlsqlItem.ROUTING_NUMBER;
		aSqlItem.AUTHORIZATION_CODE := aPlsqlItem.AUTHORIZATION_CODE;
		RETURN aSqlItem;
	END PL_TO_SQL11;
	FUNCTION SQL_TO_PL12(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG11) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORD_PAYMENTS_REC_TYPE; 
	BEGIN 
		aPlsqlItem.ORDER_NUMBER := aSqlItem.ORDER_NUMBER;
		aPlsqlItem.LINE_NUMBER := aSqlItem.LINE_NUMBER;
		aPlsqlItem.PAYMENT_METHOD := aSqlItem.PAYMENT_METHOD;
		aPlsqlItem.PAYMENT_INSTRUMENT := aSqlItem.PAYMENT_INSTRUMENT;
		aPlsqlItem.PAYMENT_DETAILS := aSqlItem.PAYMENT_DETAILS;
		aPlsqlItem.EXPIRATION_DATE := aSqlItem.EXPIRATION_DATE;
		aPlsqlItem.PAYMENT_AMOUNT := aSqlItem.PAYMENT_AMOUNT;
		aPlsqlItem.ACCT_HOLDER_NAME := aSqlItem.ACCT_HOLDER_NAME;
		aPlsqlItem.ACCOUNT_NUMBER := aSqlItem.ACCOUNT_NUMBER;
		aPlsqlItem.ROUTING_NUMBER := aSqlItem.ROUTING_NUMBER;
		aPlsqlItem.AUTHORIZATION_CODE := aSqlItem.AUTHORIZATION_CODE;
		RETURN aPlsqlItem;
	END SQL_TO_PL12;
	FUNCTION PL_TO_SQL12(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_8 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_8; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG_8();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL11(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL12;
	FUNCTION SQL_TO_PL9(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_8) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL12(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL9;
	FUNCTION PL_TO_SQL13(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG12 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG12; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG12(NULL, NULL);
		aSqlItem.LINE_NUMBER := aPlsqlItem.LINE_NUMBER;
		aSqlItem.ERROR_MESSAGE := aPlsqlItem.ERROR_MESSAGE;
		RETURN aSqlItem;
	END PL_TO_SQL13;
	FUNCTION SQL_TO_PL13(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG12) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_LINES_REC_TYPE; 
	BEGIN 
		aPlsqlItem.LINE_NUMBER := aSqlItem.LINE_NUMBER;
		aPlsqlItem.ERROR_MESSAGE := aSqlItem.ERROR_MESSAGE;
		RETURN aPlsqlItem;
	END SQL_TO_PL13;
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL)
 	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG_9 IS 
	aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_9; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_LEG_POS_SHIP_CONF_PKG_9();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL13(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL7;
	FUNCTION SQL_TO_PL10(aSqlItem XX_OM_LEG_POS_SHIP_CONF_PKG_9) 
	RETURN XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL IS 
	aPlsqlItem XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL13(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL10;

   PROCEDURE XX_OM_LEG_POS_SHIP_CONF_PKG$O (P_ORDER_NUMBER IN OUT NUMBER,P_ORDER_HEADER_REC XX_OM_LEG_POS_SHIP_CONF_PKG_X,P_ORDER_LINES_TBL XX_OM_LEG_POS_SHIP_CONF_PKG_7,P_ORDER_PAYMENTS_TBL XX_OM_LEG_POS_SHIP_CONF_PKG_8,X_ORDER_LINES_TBL_OUT OUT XX_OM_LEG_POS_SHIP_CONF_PKG_9,X_STATUS OUT VARCHAR2,X_TRANSACTION_DATE OUT VARCHAR2,X_MESSAGE OUT VARCHAR2) IS
      P_ORDER_HEADER_REC_ APPS.XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_HDR_REC_TYPE;
      P_ORDER_LINES_TBL_ APPS.XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_LINES_TBL;
      P_ORDER_PAYMENTS_TBL_ APPS.XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ORDER_PAYMENTS_TBL;
      X_ORDER_LINES_TBL_OUT_ APPS.XX_OM_LEG_POS_SHIP_CONF_PKG.XX_OM_ACK_ORD_LINES_TBL;
   BEGIN
      P_ORDER_HEADER_REC_ := XX_BPEL_SVCLEGACYPOSREAD.SQL_TO_PL7(P_ORDER_HEADER_REC);
      P_ORDER_LINES_TBL_ := XX_BPEL_SVCLEGACYPOSREAD.SQL_TO_PL8(P_ORDER_LINES_TBL);
      P_ORDER_PAYMENTS_TBL_ := XX_BPEL_SVCLEGACYPOSREAD.SQL_TO_PL9(P_ORDER_PAYMENTS_TBL);
      APPS.XX_OM_LEG_POS_SHIP_CONF_PKG.OD_POS_SHIP_CONFIRM_PROC(P_ORDER_NUMBER,P_ORDER_HEADER_REC_,P_ORDER_LINES_TBL_,P_ORDER_PAYMENTS_TBL_,X_ORDER_LINES_TBL_OUT_,X_STATUS,X_TRANSACTION_DATE,X_MESSAGE);
      X_ORDER_LINES_TBL_OUT := XX_BPEL_SVCLEGACYPOSREAD.PL_TO_SQL7(X_ORDER_LINES_TBL_OUT_);
   END XX_OM_LEG_POS_SHIP_CONF_PKG$O;

END XX_BPEL_SVCLEGACYPOSREAD;
/
show errors
exit

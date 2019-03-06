-- Declare the SQL type for the PL/SQL type XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T
CREATE OR REPLACE TYPE XX_OM_CARTON_GETSHPMT_PKG_XX6 AS OBJECT (
      DELIVERY_ID NUMBER,
      DELIVERY_NUMBER VARCHAR2(100),
      WHSE VARCHAR2(100),
      DELIVERY_LINE_NUMBER NUMBER,
      SKU VARCHAR2(200),
      CTN_TYPE VARCHAR2(200),
      SEASON VARCHAR2(200),
      SEASON_YR NUMBER,
      STYLE VARCHAR2(200),
      STYLE_SFX VARCHAR2(200),
      COLOR VARCHAR2(200),
      COLOR_SFX VARCHAR2(200),
      SEC_DIM NUMBER,
      QUAL VARCHAR2(200),
      SIZE_DESC VARCHAR2(200),
      SKU_QTY NUMBER,
      WHOLESALE_SKU_FLAG VARCHAR2(200),
      SPL_INSTR_CODE_1 VARCHAR2(200),
      SPL_INSTR_CODE_2 VARCHAR2(200),
      SPL_INSTR_CODE_3 VARCHAR2(200),
      SPL_INSTR_CODE_4 VARCHAR2(200),
      SPL_INSTR_CODE_5 VARCHAR2(200),
      SPL_INSTR_CODE_6 VARCHAR2(200),
      SPL_INSTR_CODE_7 VARCHAR2(200),
      SPL_INSTR_CODE_8 VARCHAR2(200),
      SPL_INSTR_CODE_9 VARCHAR2(200),
      SPL_INSTR_CODE_10 VARCHAR2(200),
      HOST_INPUT_ID NUMBER,
      RETURN_TYPE VARCHAR2(200)
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_CARTON_GETSHPMT_PKG_XX_ AS TABLE OF XX_OM_CARTON_GETSHPMT_PKG_XX6; 
/
show errors
-- Declare package containing conversion functions between SQL and PL/SQL types
CREATE OR REPLACE PACKAGE BPEL_SHIPMENTUNITDETAILS AS
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T)
 	RETURN XX_OM_CARTON_GETSHPMT_PKG_XX6;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX6)
	RETURN XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL
	FUNCTION PL_TO_SQL6(aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL)
 	RETURN XX_OM_CARTON_GETSHPMT_PKG_XX_;
	FUNCTION SQL_TO_PL6(aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX_)
	RETURN XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL;
   PROCEDURE XX_OM_CARTON_GETSHPMT_PKG$GET (P_DELIVERY_ID NUMBER,X_GETSHIPMENTUNIT_TBL OUT XX_OM_CARTON_GETSHPMT_PKG_XX_);
END BPEL_SHIPMENTUNITDETAILS;
/
show errors
CREATE OR REPLACE PACKAGE BODY BPEL_SHIPMENTUNITDETAILS IS
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T)
 	RETURN XX_OM_CARTON_GETSHPMT_PKG_XX6 IS 
	aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX6; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_CARTON_GETSHPMT_PKG_XX6(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.DELIVERY_ID := aPlsqlItem.DELIVERY_ID;
		aSqlItem.DELIVERY_NUMBER := aPlsqlItem.DELIVERY_NUMBER;
		aSqlItem.WHSE := aPlsqlItem.WHSE;
		aSqlItem.DELIVERY_LINE_NUMBER := aPlsqlItem.DELIVERY_LINE_NUMBER;
		aSqlItem.SKU := aPlsqlItem.SKU;
		aSqlItem.CTN_TYPE := aPlsqlItem.CTN_TYPE;
		aSqlItem.SEASON := aPlsqlItem.SEASON;
		aSqlItem.SEASON_YR := aPlsqlItem.SEASON_YR;
		aSqlItem.STYLE := aPlsqlItem.STYLE;
		aSqlItem.STYLE_SFX := aPlsqlItem.STYLE_SFX;
		aSqlItem.COLOR := aPlsqlItem.COLOR;
		aSqlItem.COLOR_SFX := aPlsqlItem.COLOR_SFX;
		aSqlItem.SEC_DIM := aPlsqlItem.SEC_DIM;
		aSqlItem.QUAL := aPlsqlItem.QUAL;
		aSqlItem.SIZE_DESC := aPlsqlItem.SIZE_DESC;
		aSqlItem.SKU_QTY := aPlsqlItem.SKU_QTY;
		aSqlItem.WHOLESALE_SKU_FLAG := aPlsqlItem.WHOLESALE_SKU_FLAG;
		aSqlItem.SPL_INSTR_CODE_1 := aPlsqlItem.SPL_INSTR_CODE_1;
		aSqlItem.SPL_INSTR_CODE_2 := aPlsqlItem.SPL_INSTR_CODE_2;
		aSqlItem.SPL_INSTR_CODE_3 := aPlsqlItem.SPL_INSTR_CODE_3;
		aSqlItem.SPL_INSTR_CODE_4 := aPlsqlItem.SPL_INSTR_CODE_4;
		aSqlItem.SPL_INSTR_CODE_5 := aPlsqlItem.SPL_INSTR_CODE_5;
		aSqlItem.SPL_INSTR_CODE_6 := aPlsqlItem.SPL_INSTR_CODE_6;
		aSqlItem.SPL_INSTR_CODE_7 := aPlsqlItem.SPL_INSTR_CODE_7;
		aSqlItem.SPL_INSTR_CODE_8 := aPlsqlItem.SPL_INSTR_CODE_8;
		aSqlItem.SPL_INSTR_CODE_9 := aPlsqlItem.SPL_INSTR_CODE_9;
		aSqlItem.SPL_INSTR_CODE_10 := aPlsqlItem.SPL_INSTR_CODE_10;
		aSqlItem.HOST_INPUT_ID := aPlsqlItem.HOST_INPUT_ID;
		aSqlItem.RETURN_TYPE := aPlsqlItem.RETURN_TYPE;
		RETURN aSqlItem;
	END PL_TO_SQL7;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX6) 
	RETURN XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T IS 
	aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_T; 
	BEGIN 
		aPlsqlItem.DELIVERY_ID := aSqlItem.DELIVERY_ID;
		aPlsqlItem.DELIVERY_NUMBER := aSqlItem.DELIVERY_NUMBER;
		aPlsqlItem.WHSE := aSqlItem.WHSE;
		aPlsqlItem.DELIVERY_LINE_NUMBER := aSqlItem.DELIVERY_LINE_NUMBER;
		aPlsqlItem.SKU := aSqlItem.SKU;
		aPlsqlItem.CTN_TYPE := aSqlItem.CTN_TYPE;
		aPlsqlItem.SEASON := aSqlItem.SEASON;
		aPlsqlItem.SEASON_YR := aSqlItem.SEASON_YR;
		aPlsqlItem.STYLE := aSqlItem.STYLE;
		aPlsqlItem.STYLE_SFX := aSqlItem.STYLE_SFX;
		aPlsqlItem.COLOR := aSqlItem.COLOR;
		aPlsqlItem.COLOR_SFX := aSqlItem.COLOR_SFX;
		aPlsqlItem.SEC_DIM := aSqlItem.SEC_DIM;
		aPlsqlItem.QUAL := aSqlItem.QUAL;
		aPlsqlItem.SIZE_DESC := aSqlItem.SIZE_DESC;
		aPlsqlItem.SKU_QTY := aSqlItem.SKU_QTY;
		aPlsqlItem.WHOLESALE_SKU_FLAG := aSqlItem.WHOLESALE_SKU_FLAG;
		aPlsqlItem.SPL_INSTR_CODE_1 := aSqlItem.SPL_INSTR_CODE_1;
		aPlsqlItem.SPL_INSTR_CODE_2 := aSqlItem.SPL_INSTR_CODE_2;
		aPlsqlItem.SPL_INSTR_CODE_3 := aSqlItem.SPL_INSTR_CODE_3;
		aPlsqlItem.SPL_INSTR_CODE_4 := aSqlItem.SPL_INSTR_CODE_4;
		aPlsqlItem.SPL_INSTR_CODE_5 := aSqlItem.SPL_INSTR_CODE_5;
		aPlsqlItem.SPL_INSTR_CODE_6 := aSqlItem.SPL_INSTR_CODE_6;
		aPlsqlItem.SPL_INSTR_CODE_7 := aSqlItem.SPL_INSTR_CODE_7;
		aPlsqlItem.SPL_INSTR_CODE_8 := aSqlItem.SPL_INSTR_CODE_8;
		aPlsqlItem.SPL_INSTR_CODE_9 := aSqlItem.SPL_INSTR_CODE_9;
		aPlsqlItem.SPL_INSTR_CODE_10 := aSqlItem.SPL_INSTR_CODE_10;
		aPlsqlItem.HOST_INPUT_ID := aSqlItem.HOST_INPUT_ID;
		aPlsqlItem.RETURN_TYPE := aSqlItem.RETURN_TYPE;
		RETURN aPlsqlItem;
	END SQL_TO_PL7;
	FUNCTION PL_TO_SQL6(aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL)
 	RETURN XX_OM_CARTON_GETSHPMT_PKG_XX_ IS 
	aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX_; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_CARTON_GETSHPMT_PKG_XX_();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL7(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL6;
	FUNCTION SQL_TO_PL6(aSqlItem XX_OM_CARTON_GETSHPMT_PKG_XX_) 
	RETURN XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL IS 
	aPlsqlItem XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL7(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL6;

   PROCEDURE XX_OM_CARTON_GETSHPMT_PKG$GET (P_DELIVERY_ID NUMBER,X_GETSHIPMENTUNIT_TBL OUT XX_OM_CARTON_GETSHPMT_PKG_XX_) IS
      X_GETSHIPMENTUNIT_TBL_ APPS.XX_OM_CARTON_GETSHPMT_PKG.XX_OM_GETSHIPMENTUNIT_TBL;
   BEGIN
      APPS.XX_OM_CARTON_GETSHPMT_PKG.GETSHIPMENTUNIT_TO_WMOS(P_DELIVERY_ID,X_GETSHIPMENTUNIT_TBL_);
      X_GETSHIPMENTUNIT_TBL := BPEL_SHIPMENTUNITDETAILS.PL_TO_SQL6(X_GETSHIPMENTUNIT_TBL_);
   END XX_OM_CARTON_GETSHPMT_PKG$GET;

END BPEL_SHIPMENTUNITDETAILS;
/
show errors
exit

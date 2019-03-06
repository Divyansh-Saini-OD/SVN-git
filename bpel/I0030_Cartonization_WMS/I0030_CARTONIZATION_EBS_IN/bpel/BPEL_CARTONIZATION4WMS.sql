-- Declare the SQL type for the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T
CREATE OR REPLACE TYPE XX_OM_CARTONIZATION_WMS_PKG_6 AS OBJECT (
      CONTAINER_ID NUMBER,
      DELIVERY_NUMBER NUMBER,
      DELIVERY_DETAIL_ID NUMBER,
      CONTAINERLINENUM NUMBER,
      INVENTORY_ITEM_ID NUMBER,
      REQUESTED_QUANTITY NUMBER,
      SPL_INSTR_CODE_1 VARCHAR2(2000),
      SPL_INSTR_CODE_2 VARCHAR2(2000),
      SPL_INSTR_CODE_3 VARCHAR2(2000),
      SPL_INSTR_CODE_4 VARCHAR2(2000),
      SPL_INSTR_CODE_5 VARCHAR2(2000),
      SPL_INSTR_CODE_6 VARCHAR2(2000),
      SPL_INSTR_CODE_7 VARCHAR2(2000),
      SPL_INSTR_CODE_8 VARCHAR2(2000),
      SPL_INSTR_CODE_9 VARCHAR2(2000),
      SPL_INSTR_CODE_10 VARCHAR2(2000),
      SEASON VARCHAR2(200),
      SEASON_YR VARCHAR2(200),
      STYLE VARCHAR2(200),
      STYLESFX VARCHAR2(200),
      COLOR VARCHAR2(200),
      COLORSFX VARCHAR2(200),
      SECDIM VARCHAR2(200),
      QUAL VARCHAR2(200),
      SIZEDESC VARCHAR2(200),
      PROCSTATCODE NUMBER,
      PROCDATETIME DATE
);
/
show errors
CREATE OR REPLACE TYPE XXOMCARTONIZATIONWMSPKG4_XX_O AS TABLE OF XX_OM_CARTONIZATION_WMS_PKG_6; 
/
show errors
-- Declare the SQL type for the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T
CREATE OR REPLACE TYPE XX_OM_CARTONIZATION_WMS_PKG_4 AS OBJECT (
      CONTAINER_ID NUMBER,
      DELIVERY_ID NUMBER,
      GROSS_WEIGHT NUMBER,
      VOLUME NUMBER,
      LENGTH NUMBER,
      WIDTH NUMBER,
      HEIGHT NUMBER,
      CARTON_TYPE VARCHAR2(200),
      CARTON_SIZE VARCHAR2(200),
      POSTMASTER NUMBER,
      SPL_INSTR_CODE_1 VARCHAR2(2000),
      SPL_INSTR_CODE_2 VARCHAR2(2000),
      SPL_INSTR_CODE_3 VARCHAR2(2000),
      SPL_INSTR_CODE_4 VARCHAR2(2000),
      SPL_INSTR_CODE_5 VARCHAR2(2000),
      SPL_INSTR_CODE_6 VARCHAR2(2000),
      SPL_INSTR_CODE_7 VARCHAR2(2000),
      SPL_INSTR_CODE_8 VARCHAR2(2000),
      SPL_INSTR_CODE_9 VARCHAR2(2000),
      SPL_INSTR_CODE_10 VARCHAR2(2000),
      PROCSTATCODE NUMBER,
      PROCDATETIME DATE,
      LT_SHOWSHIPUNIT_THIRDLVL_TBL APPS.XXOMCARTONIZATIONWMSPKG4_XX_O
);
/
show errors
CREATE OR REPLACE TYPE XXOMCARTONIZATIONWMSPKG2_XX_O AS TABLE OF XX_OM_CARTONIZATION_WMS_PKG_4; 
/
show errors
-- Declare the SQL type for the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T
CREATE OR REPLACE TYPE XX_OM_CARTONIZATION_WMS_PKG_2 AS OBJECT (
      DELIVERY_ID NUMBER,
      NUMBER_OF_LPN NUMBER,
      GROSS_WEIGHT NUMBER,
      VOLUME NUMBER,
      SPL_INSTR_CODE_1 VARCHAR2(2000),
      SPL_INSTR_CODE_2 VARCHAR2(2000),
      SPL_INSTR_CODE_3 VARCHAR2(2000),
      SPL_INSTR_CODE_4 VARCHAR2(2000),
      SPL_INSTR_CODE_5 VARCHAR2(2000),
      SPL_INSTR_CODE_6 VARCHAR2(2000),
      SPL_INSTR_CODE_7 VARCHAR2(2000),
      SPL_INSTR_CODE_8 VARCHAR2(2000),
      SPL_INSTR_CODE_9 VARCHAR2(2000),
      SPL_INSTR_CODE_10 VARCHAR2(2000),
      PROCSTATCODE NUMBER,
      PROCDATETIME DATE,
      LT_SHOWSHIPUNIT_SECLVL_TBL APPS.XXOMCARTONIZATIONWMSPKG2_XX_O
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_CARTONIZATION_WMS_PKG_X AS TABLE OF XX_OM_CARTONIZATION_WMS_PKG_2; 
/
show errors
-- Declare package containing conversion functions between SQL and PL/SQL types
CREATE OR REPLACE PACKAGE BPEL_CARTONIZATION4WMS AS
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T
	FUNCTION PL_TO_SQL2(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_6;
	FUNCTION SQL_TO_PL3(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_6)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL
	FUNCTION PL_TO_SQL3(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL)
 	RETURN XXOMCARTONIZATIONWMSPKG4_XX_O;
	FUNCTION SQL_TO_PL4(aSqlItem XXOMCARTONIZATIONWMSPKG4_XX_O)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T
	FUNCTION PL_TO_SQL4(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_4;
	FUNCTION SQL_TO_PL5(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_4)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL
	FUNCTION PL_TO_SQL5(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL)
 	RETURN XXOMCARTONIZATIONWMSPKG2_XX_O;
	FUNCTION SQL_TO_PL6(aSqlItem XXOMCARTONIZATIONWMSPKG2_XX_O)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T
	FUNCTION PL_TO_SQL6(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_2;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_2)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T;
	-- Declare the conversion functions the PL/SQL type XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_X;
	FUNCTION SQL_TO_PL2(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_X)
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL;
   PROCEDURE XX_OM_CARTONIZATION_WMS_PKG$P (P_SHOWSHIPUNIT_FIRSTLVL_TBL XX_OM_CARTONIZATION_WMS_PKG_X,X_STATUS OUT VARCHAR2,X_ERRCODE OUT NUMBER);
END BPEL_CARTONIZATION4WMS;
/
show errors
CREATE OR REPLACE PACKAGE BODY BPEL_CARTONIZATION4WMS IS
	FUNCTION PL_TO_SQL2(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_6 IS 
	aSqlItem XX_OM_CARTONIZATION_WMS_PKG_6; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_CARTONIZATION_WMS_PKG_6(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.CONTAINER_ID := aPlsqlItem.CONTAINER_ID;
		aSqlItem.DELIVERY_NUMBER := aPlsqlItem.DELIVERY_NUMBER;
		aSqlItem.DELIVERY_DETAIL_ID := aPlsqlItem.DELIVERY_DETAIL_ID;
		aSqlItem.CONTAINERLINENUM := aPlsqlItem.CONTAINERLINENUM;
		aSqlItem.INVENTORY_ITEM_ID := aPlsqlItem.INVENTORY_ITEM_ID;
		aSqlItem.REQUESTED_QUANTITY := aPlsqlItem.REQUESTED_QUANTITY;
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
		aSqlItem.SEASON := aPlsqlItem.SEASON;
		aSqlItem.SEASON_YR := aPlsqlItem.SEASON_YR;
		aSqlItem.STYLE := aPlsqlItem.STYLE;
		aSqlItem.STYLESFX := aPlsqlItem.STYLESFX;
		aSqlItem.COLOR := aPlsqlItem.COLOR;
		aSqlItem.COLORSFX := aPlsqlItem.COLORSFX;
		aSqlItem.SECDIM := aPlsqlItem.SECDIM;
		aSqlItem.QUAL := aPlsqlItem.QUAL;
		aSqlItem.SIZEDESC := aPlsqlItem.SIZEDESC;
		aSqlItem.PROCSTATCODE := aPlsqlItem.PROCSTATCODE;
		aSqlItem.PROCDATETIME := aPlsqlItem.PROCDATETIME;
		RETURN aSqlItem;
	END PL_TO_SQL2;
	FUNCTION SQL_TO_PL3(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_6) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_THIRDLVL_T; 
	BEGIN 
		aPlsqlItem.CONTAINER_ID := aSqlItem.CONTAINER_ID;
		aPlsqlItem.DELIVERY_NUMBER := aSqlItem.DELIVERY_NUMBER;
		aPlsqlItem.DELIVERY_DETAIL_ID := aSqlItem.DELIVERY_DETAIL_ID;
		aPlsqlItem.CONTAINERLINENUM := aSqlItem.CONTAINERLINENUM;
		aPlsqlItem.INVENTORY_ITEM_ID := aSqlItem.INVENTORY_ITEM_ID;
		aPlsqlItem.REQUESTED_QUANTITY := aSqlItem.REQUESTED_QUANTITY;
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
		aPlsqlItem.SEASON := aSqlItem.SEASON;
		aPlsqlItem.SEASON_YR := aSqlItem.SEASON_YR;
		aPlsqlItem.STYLE := aSqlItem.STYLE;
		aPlsqlItem.STYLESFX := aSqlItem.STYLESFX;
		aPlsqlItem.COLOR := aSqlItem.COLOR;
		aPlsqlItem.COLORSFX := aSqlItem.COLORSFX;
		aPlsqlItem.SECDIM := aSqlItem.SECDIM;
		aPlsqlItem.QUAL := aSqlItem.QUAL;
		aPlsqlItem.SIZEDESC := aSqlItem.SIZEDESC;
		aPlsqlItem.PROCSTATCODE := aSqlItem.PROCSTATCODE;
		aPlsqlItem.PROCDATETIME := aSqlItem.PROCDATETIME;
		RETURN aPlsqlItem;
	END SQL_TO_PL3;
	FUNCTION PL_TO_SQL3(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL)
 	RETURN XXOMCARTONIZATIONWMSPKG4_XX_O IS 
	aSqlItem XXOMCARTONIZATIONWMSPKG4_XX_O; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XXOMCARTONIZATIONWMSPKG4_XX_O();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL2(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL3;
	FUNCTION SQL_TO_PL4(aSqlItem XXOMCARTONIZATIONWMSPKG4_XX_O) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_THIRDLVL_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL3(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL4;
	FUNCTION PL_TO_SQL4(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_4 IS 
	aSqlItem XX_OM_CARTONIZATION_WMS_PKG_4; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_CARTONIZATION_WMS_PKG_4(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.CONTAINER_ID := aPlsqlItem.CONTAINER_ID;
		aSqlItem.DELIVERY_ID := aPlsqlItem.DELIVERY_ID;
		aSqlItem.GROSS_WEIGHT := aPlsqlItem.GROSS_WEIGHT;
		aSqlItem.VOLUME := aPlsqlItem.VOLUME;
		aSqlItem.LENGTH := aPlsqlItem.LENGTH;
		aSqlItem.WIDTH := aPlsqlItem.WIDTH;
		aSqlItem.HEIGHT := aPlsqlItem.HEIGHT;
		aSqlItem.CARTON_TYPE := aPlsqlItem.CARTON_TYPE;
		aSqlItem.CARTON_SIZE := aPlsqlItem.CARTON_SIZE;
		aSqlItem.POSTMASTER := aPlsqlItem.POSTMASTER;
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
		aSqlItem.PROCSTATCODE := aPlsqlItem.PROCSTATCODE;
		aSqlItem.PROCDATETIME := aPlsqlItem.PROCDATETIME;
		aSqlItem.LT_SHOWSHIPUNIT_THIRDLVL_TBL := PL_TO_SQL3(aPlsqlItem.LT_SHOWSHIPUNIT_THIRDLVL_TBL);
		RETURN aSqlItem;
	END PL_TO_SQL4;
	FUNCTION SQL_TO_PL5(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_4) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_T; 
	BEGIN 
		aPlsqlItem.CONTAINER_ID := aSqlItem.CONTAINER_ID;
		aPlsqlItem.DELIVERY_ID := aSqlItem.DELIVERY_ID;
		aPlsqlItem.GROSS_WEIGHT := aSqlItem.GROSS_WEIGHT;
		aPlsqlItem.VOLUME := aSqlItem.VOLUME;
		aPlsqlItem.LENGTH := aSqlItem.LENGTH;
		aPlsqlItem.WIDTH := aSqlItem.WIDTH;
		aPlsqlItem.HEIGHT := aSqlItem.HEIGHT;
		aPlsqlItem.CARTON_TYPE := aSqlItem.CARTON_TYPE;
		aPlsqlItem.CARTON_SIZE := aSqlItem.CARTON_SIZE;
		aPlsqlItem.POSTMASTER := aSqlItem.POSTMASTER;
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
		aPlsqlItem.PROCSTATCODE := aSqlItem.PROCSTATCODE;
		aPlsqlItem.PROCDATETIME := aSqlItem.PROCDATETIME;
		aPlsqlItem.LT_SHOWSHIPUNIT_THIRDLVL_TBL := SQL_TO_PL4(aSqlItem.LT_SHOWSHIPUNIT_THIRDLVL_TBL);
		RETURN aPlsqlItem;
	END SQL_TO_PL5;
	FUNCTION PL_TO_SQL5(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL)
 	RETURN XXOMCARTONIZATIONWMSPKG2_XX_O IS 
	aSqlItem XXOMCARTONIZATIONWMSPKG2_XX_O; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XXOMCARTONIZATIONWMSPKG2_XX_O();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL4(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL5;
	FUNCTION SQL_TO_PL6(aSqlItem XXOMCARTONIZATIONWMSPKG2_XX_O) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_SECLVL_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL5(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL6;
	FUNCTION PL_TO_SQL6(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_2 IS 
	aSqlItem XX_OM_CARTONIZATION_WMS_PKG_2; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_CARTONIZATION_WMS_PKG_2(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.DELIVERY_ID := aPlsqlItem.DELIVERY_ID;
		aSqlItem.NUMBER_OF_LPN := aPlsqlItem.NUMBER_OF_LPN;
		aSqlItem.GROSS_WEIGHT := aPlsqlItem.GROSS_WEIGHT;
		aSqlItem.VOLUME := aPlsqlItem.VOLUME;
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
		aSqlItem.PROCSTATCODE := aPlsqlItem.PROCSTATCODE;
		aSqlItem.PROCDATETIME := aPlsqlItem.PROCDATETIME;
		aSqlItem.LT_SHOWSHIPUNIT_SECLVL_TBL := PL_TO_SQL5(aPlsqlItem.LT_SHOWSHIPUNIT_SECLVL_TBL);
		RETURN aSqlItem;
	END PL_TO_SQL6;
	FUNCTION SQL_TO_PL7(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_2) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIPUNIT_FIRSTLVL_T; 
	BEGIN 
		aPlsqlItem.DELIVERY_ID := aSqlItem.DELIVERY_ID;
		aPlsqlItem.NUMBER_OF_LPN := aSqlItem.NUMBER_OF_LPN;
		aPlsqlItem.GROSS_WEIGHT := aSqlItem.GROSS_WEIGHT;
		aPlsqlItem.VOLUME := aSqlItem.VOLUME;
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
		aPlsqlItem.PROCSTATCODE := aSqlItem.PROCSTATCODE;
		aPlsqlItem.PROCDATETIME := aSqlItem.PROCDATETIME;
		aPlsqlItem.LT_SHOWSHIPUNIT_SECLVL_TBL := SQL_TO_PL6(aSqlItem.LT_SHOWSHIPUNIT_SECLVL_TBL);
		RETURN aPlsqlItem;
	END SQL_TO_PL7;
	FUNCTION PL_TO_SQL7(aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL)
 	RETURN XX_OM_CARTONIZATION_WMS_PKG_X IS 
	aSqlItem XX_OM_CARTONIZATION_WMS_PKG_X; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_CARTONIZATION_WMS_PKG_X();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL6(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL7;
	FUNCTION SQL_TO_PL2(aSqlItem XX_OM_CARTONIZATION_WMS_PKG_X) 
	RETURN XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL IS 
	aPlsqlItem XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL7(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL2;

   PROCEDURE XX_OM_CARTONIZATION_WMS_PKG$P (P_SHOWSHIPUNIT_FIRSTLVL_TBL XX_OM_CARTONIZATION_WMS_PKG_X,X_STATUS OUT VARCHAR2,X_ERRCODE OUT NUMBER) IS
      P_SHOWSHIPUNIT_FIRSTLVL_TBL_ APPS.XX_OM_CARTONIZATION_WMS_PKG.XX_OM_SHOWSHIP_FIRSTLVL_TBL;
   BEGIN
      P_SHOWSHIPUNIT_FIRSTLVL_TBL_ := BPEL_CARTONIZATION4WMS.SQL_TO_PL2(P_SHOWSHIPUNIT_FIRSTLVL_TBL);
      APPS.XX_OM_CARTONIZATION_WMS_PKG.PROCESS_CARTONIZATION_WMS(P_SHOWSHIPUNIT_FIRSTLVL_TBL_,X_STATUS,X_ERRCODE);
   END XX_OM_CARTONIZATION_WMS_PKG$P;

END BPEL_CARTONIZATION4WMS;
/
show errors
exit

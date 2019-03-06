-- Declare the SQL type for the PL/SQL type XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE
CREATE OR REPLACE TYPE XX_OM_ROADNET_TO_EBS_PKG_XX_9 AS OBJECT (
      REGIONID VARCHAR2(240),
      DELIVERY_NUMBER VARCHAR2(30),
      DELIVERY_DATE DATE,
      ROUTE_NUMBER VARCHAR2(240),
      STOP_NUMBER VARCHAR2(240),
      USER_FIELD3 VARCHAR2(10)
);
/
show errors
CREATE OR REPLACE TYPE XX_OM_ROADNET_TO_EBS_PKG_XX_8 AS TABLE OF XX_OM_ROADNET_TO_EBS_PKG_XX_9; 
/
show errors
-- Declare package containing conversion functions between SQL and PL/SQL types
CREATE OR REPLACE PACKAGE BPEL_ROADNET_DATEBASE AS
	-- Declare the conversion functions the PL/SQL type XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE
	FUNCTION PL_TO_SQL8(aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE)
 	RETURN XX_OM_ROADNET_TO_EBS_PKG_XX_9;
	FUNCTION SQL_TO_PL9(aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_9)
	RETURN XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE;
	-- Declare the conversion functions the PL/SQL type XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL
	FUNCTION PL_TO_SQL9(aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL)
 	RETURN XX_OM_ROADNET_TO_EBS_PKG_XX_8;
	FUNCTION SQL_TO_PL8(aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_8)
	RETURN XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL;
   PROCEDURE XX_OM_ROADNET_TO_EBS_PKG$IMPO (P_DELIVERY_TBL XX_OM_ROADNET_TO_EBS_PKG_XX_8);
END BPEL_ROADNET_DATEBASE;
/
show errors
CREATE OR REPLACE PACKAGE BODY BPEL_ROADNET_DATEBASE IS
	FUNCTION PL_TO_SQL8(aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE)
 	RETURN XX_OM_ROADNET_TO_EBS_PKG_XX_9 IS 
	aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_9; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_OM_ROADNET_TO_EBS_PKG_XX_9(NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.REGIONID := aPlsqlItem.REGIONID;
		aSqlItem.DELIVERY_NUMBER := aPlsqlItem.DELIVERY_NUMBER;
		aSqlItem.DELIVERY_DATE := aPlsqlItem.DELIVERY_DATE;
		aSqlItem.ROUTE_NUMBER := aPlsqlItem.ROUTE_NUMBER;
		aSqlItem.STOP_NUMBER := aPlsqlItem.STOP_NUMBER;
		aSqlItem.USER_FIELD3 := aPlsqlItem.USER_FIELD3;
		RETURN aSqlItem;
	END PL_TO_SQL8;
	FUNCTION SQL_TO_PL9(aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_9) 
	RETURN XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE IS 
	aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_REC_TYPE; 
	BEGIN 
		aPlsqlItem.REGIONID := aSqlItem.REGIONID;
		aPlsqlItem.DELIVERY_NUMBER := aSqlItem.DELIVERY_NUMBER;
		aPlsqlItem.DELIVERY_DATE := aSqlItem.DELIVERY_DATE;
		aPlsqlItem.ROUTE_NUMBER := aSqlItem.ROUTE_NUMBER;
		aPlsqlItem.STOP_NUMBER := aSqlItem.STOP_NUMBER;
		aPlsqlItem.USER_FIELD3 := aSqlItem.USER_FIELD3;
		RETURN aPlsqlItem;
	END SQL_TO_PL9;
	FUNCTION PL_TO_SQL9(aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL)
 	RETURN XX_OM_ROADNET_TO_EBS_PKG_XX_8 IS 
	aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_8; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_OM_ROADNET_TO_EBS_PKG_XX_8();
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL8(aPlsqlItem(I));
		END LOOP; 
		RETURN aSqlItem;
	END PL_TO_SQL9;
	FUNCTION SQL_TO_PL8(aSqlItem XX_OM_ROADNET_TO_EBS_PKG_XX_8) 
	RETURN XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL IS 
	aPlsqlItem XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL; 
	BEGIN 
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL9(aSqlItem(I));
		END LOOP; 
		RETURN aPlsqlItem;
	END SQL_TO_PL8;

   PROCEDURE XX_OM_ROADNET_TO_EBS_PKG$IMPO (P_DELIVERY_TBL XX_OM_ROADNET_TO_EBS_PKG_XX_8) IS
      P_DELIVERY_TBL_ APPS.XX_OM_ROADNET_TO_EBS_PKG.XX_OM_DELIVERY_TBL;
   BEGIN
      P_DELIVERY_TBL_ := BPEL_ROADNET_DATEBASE.SQL_TO_PL8(P_DELIVERY_TBL);
      APPS.XX_OM_ROADNET_TO_EBS_PKG.IMPORT_ROUTE(P_DELIVERY_TBL_);
   END XX_OM_ROADNET_TO_EBS_PKG$IMPO;

END BPEL_ROADNET_DATEBASE;
/
show errors
exit

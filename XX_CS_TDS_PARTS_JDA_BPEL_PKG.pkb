create or replace PACKAGE BODY XX_CS_TDS_PARTS_JDA_BPEL_PKG IS
	FUNCTION PL_TO_SQL1(aPlsqlItem XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_ORDER_ITEMS_REC)
 	RETURN XX_CS_TDS_PARTS_X1327042X1X3 IS 
	aSqlItem XX_CS_TDS_PARTS_X1327042X1X3; 
	BEGIN 
		-- initialize the object
		aSqlItem := XX_CS_TDS_PARTS_X1327042X1X3(NULL, NULL, NULL, NULL, NULL, NULL);
		aSqlItem.RMS_SKU := aPlsqlItem.RMS_SKU;
		aSqlItem.ITEM_DESCRIPTION := aPlsqlItem.ITEM_DESCRIPTION;
		aSqlItem.QUANTITY := aPlsqlItem.QUANTITY;
		aSqlItem.PURCHASE_PRICE := aPlsqlItem.PURCHASE_PRICE;
		aSqlItem.SELLING_PRICE := aPlsqlItem.SELLING_PRICE;
		aSqlItem.UOM := aPlsqlItem.UOM;
		RETURN aSqlItem;
	END PL_TO_SQL1;
	FUNCTION SQL_TO_PL1(aSqlItem XX_CS_TDS_PARTS_X1327042X1X3) 
	RETURN XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_ORDER_ITEMS_REC IS 
	aPlsqlItem XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_ORDER_ITEMS_REC; 
	BEGIN 
		aPlsqlItem.RMS_SKU := aSqlItem.RMS_SKU;
		aPlsqlItem.ITEM_DESCRIPTION := aSqlItem.ITEM_DESCRIPTION;
		aPlsqlItem.QUANTITY := aSqlItem.QUANTITY;
		aPlsqlItem.PURCHASE_PRICE := aSqlItem.PURCHASE_PRICE;
		aPlsqlItem.SELLING_PRICE := aSqlItem.SELLING_PRICE;
		aPlsqlItem.UOM := aSqlItem.UOM;
		RETURN aPlsqlItem;
	END SQL_TO_PL1;
	FUNCTION PL_TO_SQL0(aPlsqlItem XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_PARTS_ORDER_TBL)
 	RETURN XX_CS_TDS_PARTS_X1327042X1X2 IS 
	aSqlItem XX_CS_TDS_PARTS_X1327042X1X2; 
	BEGIN 
		-- initialize the table 
		aSqlItem := XX_CS_TDS_PARTS_X1327042X1X2();
		IF aPlsqlItem IS NOT NULL THEN
		aSqlItem.EXTEND(aPlsqlItem.COUNT);
		IF aPlsqlItem.COUNT>0 THEN
		FOR I IN aPlsqlItem.FIRST..aPlsqlItem.LAST LOOP
			aSqlItem(I + 1 - aPlsqlItem.FIRST) := PL_TO_SQL1(aPlsqlItem(I));
		END LOOP; 
		END IF; 
		END IF; 
		RETURN aSqlItem;
	END PL_TO_SQL0;
	FUNCTION SQL_TO_PL0(aSqlItem XX_CS_TDS_PARTS_X1327042X1X2) 
	RETURN XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_PARTS_ORDER_TBL IS 
	aPlsqlItem XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_PARTS_ORDER_TBL; 
	BEGIN 
		aPlsqlItem := XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_PARTS_ORDER_TBL();
		aPlsqlItem.EXTEND(aSqlItem.COUNT);
		IF aSqlItem.COUNT>0 THEN
		FOR I IN 1..aSqlItem.COUNT LOOP
			aPlsqlItem(I) := SQL_TO_PL1(aSqlItem(I));
		END LOOP; 
		END IF;
		RETURN aPlsqlItem;
	END SQL_TO_PL0;

   PROCEDURE xx_cs_tds_parts_jda_pkg$main_ (P_SR_NUMBER VARCHAR2,
	P_PARTS_TBL OUT APPS.XX_CS_TDS_PARTS_X1327042X1X2,
	X_RETURN_STATUS OUT VARCHAR2,
	X_RETURN_MESSAGE OUT VARCHAR2
	) IS
 P_PARTS_TBL_ APPS.XX_CS_TDS_PARTS_JDA_PKG.XX_CS_TDS_PARTS_ORDER_TBL;
   BEGIN
      APPS.XX_CS_TDS_PARTS_JDA_PKG.MAIN_PROC(P_SR_NUMBER,
	P_PARTS_TBL_,
	X_RETURN_STATUS,
	X_RETURN_MESSAGE
	);
 P_PARTS_TBL := XX_CS_TDS_PARTS_JDA_BPEL_PKG.PL_TO_SQL0(P_PARTS_TBL_);
   END xx_cs_tds_parts_jda_pkg$main_;

END XX_CS_TDS_PARTS_JDA_BPEL_PKG;
/
-- +========================================================================+
-- |                                Office Depot                            |
-- +========================================================================+
-- | Name        : NAIT_62039_XX_FIN_TRANSLATE_VALUES_Update                |
-- | Description : Update script for XX_CDH_EBILLING_FIELDS                 |
-- |Change History:                                                         |
-- |---------------                                                         |
-- | DEFECT ID :                                                            |
-- |Version  Date        Author             Remarks                         |
-- |-------  ----------- -----------------  --------------------------------|
-- | 1.0     27-SEP-2018 Rafi CG          Updating TargetValue22 as 'N'     |
-- |                                      to disable split and TargetValue21|
-- |                                      as'N' to disable 'Concatenate' for| 
-- |                                      the fields of Lines type for the  |
-- |                                      defect NAIT 62039                 |
-- +=======================================================================+

-- update script to disable split	
 UPDATE xx_fin_translatevalues xftv
    SET xftv.target_value22='N'
  WHERE xftv.target_value20='Lines'
    AND xftv.source_value2 IN
	('Item Description'
	,'Line Level Comment'
	,'Line CC'
	,'Line CC Desc'
	,'KIT SKU Desc'
	)
    AND xftv.translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
        );
		
		
-- update script to disable concatenate		
  UPDATE xx_fin_translatevalues xftv
    SET xftv.target_value21='N'
  WHERE xftv.target_value20='Lines'
    AND xftv.source_value2 IN 
	('PO Line Number'
	,'U/M'
	,'Qty Ordered'
	,'Qty Shipped'
    ,'Qty Back Ordered'
    ,'Line Level Comment'
    ,'Electronic Detail Sequence #'
    ,'Total Invoice Amt'
    ,'GSA Comments'
	,'Line CC'
	,'Line CC Desc'
	,'KIT SKU'
	,'KIT SKU Desc'
)
    AND xftv.translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
        );
		
COMMIT;
Show Errors;

-- +========================================================================+
-- |                                Office Depot                            |
-- +========================================================================+
-- | Name        : UPDATE_NAIT_81241_XX_FIN_TRANS_VALUES.sql                |
-- | Description : Update script for XX_CDH_EBILLING_FIELDS                |
-- |Change History:                                                         |
-- |---------------                                                         |
-- | DEFECT ID :                                                            |
-- |Version  Date        Author             Remarks                         |
-- |-------  ----------- -----------------  --------------------------------|
-- | 1.0     30-JAN-2019 Thilak CG          Updating TargetValue2 for       |
-- |                                        consolidated_bill_number        |
-- +=======================================================================+

UPDATE XX_FIN_TRANSLATEVALUES 
   SET target_value2 = '#' 
 WHERE source_value2 = 'Consolidated Bill Number' 
   AND translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
        );
		
COMMIT;
Show Errors;

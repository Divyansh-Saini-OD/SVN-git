-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Insert_xx_fin_translatevalues_skutax                                        |
-- | Description : This Script is used to insert the Total_Invoice_amt                         |
-- |               field into translations values                                              |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 28-AUG-2018  Capgemini               Defect# NAIT-58403                          |
-- +===========================================================================================+
--deleting wrong values inserted in SIT02.

DELETE FROM XXCRM.XX_CDH_MBS_DOCUMENT_MASTER
WHERE DOC_DETAIL_LEVEL = 'DETAILSKU';

COMMIT;
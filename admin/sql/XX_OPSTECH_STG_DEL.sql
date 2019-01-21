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

UPDATE AR_CONS_INV_ALL
SET attribute4 = null , attribute15 = null 
WHERE cons_inv_id IN (8016306,
8016354,
8016900,
8016822,
8016925,
8016472);

COMMIT;

/






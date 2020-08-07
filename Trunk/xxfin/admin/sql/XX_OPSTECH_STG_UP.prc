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

DROP DIRECTORY XXFIN_OPSTECH;

CREATE directory XXFIN_OPSTECH as '/app/ebs/ctgsisit02/xxfin/outbound/XX_OPSTECH';

COMMIT;

/






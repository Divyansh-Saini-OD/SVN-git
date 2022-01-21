-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     WIPRO Technologies                                |
-- +=======================================================================+
-- | Name        : UPDATE_XX_CE_AJB99x.sql                                 |
-- | Description : Script to update the attribute1 in AJB99x table with    |
-- |               "FEE_RECON_YES"                                         |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     03-AUG-2010  Rani Asaithambi   Created for the Defect 6138    |
-- +=======================================================================+

  ALTER session ENABLE PARALLEL dml;

  UPDATE /*+ parallel(xca6, 8) use_hash(xca6)*/ apps.xx_ce_ajb996 xca6 
  SET xca6.attribute1='FEE_RECON_YES'
  WHERE EXISTS (SELECT /*+ full(xc9i)  parallel(xc9i, 8) */ 1 
                FROM apps.xx_ce_999_interface xc9i
                WHERE xc9i.expenses_complete ='Y'
                AND xc9i.bank_rec_id  = xca6.bank_rec_id
                AND xc9i.processor_id =xca6.processor_id);

  UPDATE /*+ parallel(xca8, 8) use_hash(xca8)*/ apps.xx_ce_ajb998 xca8
  SET xca8.attribute1='FEE_RECON_YES'
  WHERE EXISTS (SELECT /*+ full(xc9i)  parallel(xc9i, 8) */ 1 
                FROM apps.xx_ce_999_interface xc9i
                WHERE xc9i.expenses_complete ='Y'
                AND xc9i.bank_rec_id  = xca8.bank_rec_id
                AND xc9i.processor_id =xca8.processor_id);

  UPDATE /*+ parallel(xca9, 8) use_hash(xca9)*/ apps.xx_ce_ajb999 xca9 
  SET xca9.attribute1='FEE_RECON_YES'
  WHERE EXISTS (SELECT /*+ full(xc9i)  parallel(xc9i, 8) */ 1 
                FROM apps.xx_ce_999_interface xc9i
                WHERE xc9i.expenses_complete ='Y'
                AND xc9i.bank_rec_id  = xca9.bank_rec_id
                AND xc9i.processor_id =xca9.processor_id);

/
COMMIT;
/
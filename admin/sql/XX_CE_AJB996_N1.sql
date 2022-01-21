-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB996                                   |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date          Author         Remarks                              |
-- |=======   ===========   =============  =====================================|
-- |1.0       20-JAN-2010   Vinaykumar S   Defect 2610                          |
-- |                                                                            |
-- +============================================================================+

  SET SHOW         OFF
  SET VERIFY       OFF
  SET ECHO         OFF
  SET TAB          OFF
  SET FEEDBACK     ON

   UPDATE xx_ce_ajb996 xca6 SET xca6.status_1310 = 'NEW' 
   WHERE  1 = 1
    AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR')
    AND EXISTS (
                 SELECT 1
                 FROM xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
                 WHERE xftv.translate_id = xftd.translate_id
                 AND xftd.translation_name = 'OD_CE_AJB_CHBK_CODES'
                 AND NVL (xftv.enabled_flag, 'N') = 'Y'
                 AND NVL (xca6.sdate, SYSDATE) BETWEEN xftv.start_date_active
                                                 AND NVL (xftv.end_date_active
                                                        , SYSDATE + 1
                                                         )
                 AND ((xca6.processor_id = xftv.source_value1
                       AND (xftv.target_value1 IS NULL
                            OR xca6.chbk_action_code = xftv.target_value1
                           )
                       AND (xftv.target_value2 IS NULL
                            OR xca6.chbk_alpha_code = xftv.target_value2
                           )
                       AND (xftv.target_value3 IS NULL
                            OR xca6.chbk_numeric_code = xftv.target_value3
                           )
                      )
                ))
    AND  NOT EXISTS (
                      SELECT bank_rec_id
                      FROM xx_ce_999_interface
                      WHERE bank_rec_id = xca6.bank_rec_id
                      AND processor_id = xca6.processor_id
                     );




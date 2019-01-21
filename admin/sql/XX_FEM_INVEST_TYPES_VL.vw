-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Office Depot                             |
-- +===================================================================+
-- | Name       : XX_FEM_INVEST_TYPES_VL.vw                            |
-- | Description: This script was created to fix the delivered invalid |
-- |              view FEM_INVEST_TYPES_TL.                            |
-- |                                                                   |
-- |              This invalid object is resolved in patch Patch 640240|
-- |              , but it is a rollup patch (FEM.D.1 Rollup #4).  The |
-- |              definition for this view was extracted out from the  |
-- |              patch via file patch/115/odf/fem_xdm.odf             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ===========  =============    ===========================|
-- |1.0       12-JAN-2008  R. Aldridge      Original                   |
-- +===================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF

CREATE OR REPLACE VIEW FEM_INVEST_TYPES_VL (row_id
                                           ,invest_type_code
                                           ,enabled_flag
                                           ,personal_flag
                                           ,read_only_flag
                                           ,creation_date
                                           ,created_by
                                           ,last_updated_by
                                           ,last_update_date
                                           ,last_update_login
                                           ,object_version_number
                                           ,invest_type_name
                                           ,description
                                           )
AS
SELECT b.ROWID row_id
      ,b.investor_type_code
      ,b.enabled_flag
      ,b.personal_flag
      ,b.read_only_flag
      ,b.creation_date
      ,b.created_by
      ,b.last_updated_by
      ,b.last_update_date
      ,b.last_update_login
      ,b.object_version_number
      ,t.investor_type_name
      ,t.description
  FROM fem_invest_types_tl t, fem_invest_types_b b
 WHERE b.investor_type_code = t.investor_type_code
   AND t.LANGUAGE = USERENV ('LANG')
/
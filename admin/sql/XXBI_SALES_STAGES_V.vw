SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                                                                                   |
-- +===========================================================================================+
-- | Name        : xxbi_sales_stages_v                                                         |
-- | Description : View to select stage filter in dashboard in the Order                       |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2011/05/16    Sreeranjini K      Initial draft version  	                       |
-- |   2     2012/03/20    Satish Siliveri      defect 17596  	                               |
-- +===========================================================================================+



/*
Defect 17596
*/

CREATE OR REPLACE VIEW xxbi_sales_stages_v
AS
  SELECT sales_stage_id id ,
    CASE NAME
      WHEN 'Appointment Secured'
      THEN 'a._Appointment Secured'
      WHEN 'Initial Approach'
      THEN 'b._Initial Approach'
      WHEN 'Presentation'
      THEN 'c._Presentation'
      WHEN 'Negotiate '
        ||'&'
        ||' Finalize'
      THEN 'd._'
        ||'Negotiate '
        ||'&'
        ||' Finalize'
      WHEN 'Execute'
      THEN 'e._Execute'
      WHEN 'Closed'
      THEN 'f._Closed'
      ELSE NAME
    END AS VALUE
  FROM apps.as_sales_stages_all_vl
  WHERE enabled_flag = 'Y'
  ORDER BY sales_stage_id;



SHOW ERRORS;

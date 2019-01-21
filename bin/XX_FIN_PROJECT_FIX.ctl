-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : XX_FIN_PROJECT_FIX.ctl                              |
-- | Description : To load the project fix to a temp table             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       18-DEC-2007  Radhika Raman,       Initial version        |
-- |                       Wipro Technologies                          |
-- +===================================================================+

LOAD DATA
INTO TABLE XX_FIN_PROJECT_FIX APPEND
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
     po_number  
    ,project_name
    ,task_name        
    ,exp_type  
    ,exp_org
    ,exp_item_date
    ,project_id
    ,task_id
    ,exp_org_id
    ,seg1
    ,seg2
    ,seg3
    ,seg4
    ,seg5
    ,seg6
    ,seg7    "REPLACE(TRIM(:seg7),CHR(13),'')"
)

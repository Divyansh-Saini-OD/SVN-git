-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      PO Auto Requisition Load (SQL *Loader Control file)   |
-- | Description : To Load the Requisitions from the file in XXFIN_DATA|
-- |                path to the staging table XX_PO_REQUISITIONS_STG   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author             Remarks                 |
-- |=======   ==========   =============       ======================= |
-- |1.0       21-MAR-2007  Gowri Shankar       Initial version         |
-- |1.1       28-AUG-2007  Arul Justin Raj     Added Source_organiztion|
-- |                                           column for Defect 1643  |
-- |1.2       14-NOV-2007  Arul Justin Raj     Modifed based on the new|
-- |                                           template for CR # 267   |
-- |1.3       25-JUL-2008  Radhika Raman       Modified the value for  |
-- |                                           request_id for          |
-- |                                           defect 9178             |
-- |                                                                   |
-- +===================================================================+
LOAD DATA
APPEND
INTO TABLE xx_po_requisitions_stg
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
     requisition_type              "TRIM(:requisition_type)"
    ,preparer_emp_nbr              "TRIM(:preparer_emp_nbr)"
    ,req_description               "TRIM(:req_description)"
    ,req_line_number               "TRIM(:req_line_number)"
    ,line_type                     "TRIM(:line_type)"
    ,item                          "TRIM(:item)"
    ,category                      "TRIM(:category)"
    ,item_description              "TRIM(:item_description)"
    ,unit_of_measure               "TRIM(:unit_of_measure)"
    ,price                         "TRIM(:price)"
    ,need_by_date                  "TO_DATE(TRIM(:need_by_date),'MM/DD/YYYY HH24:MI')"
    ,quantity                      "TRIM(:quantity)"
    ,organization                  "TRIM(:organization)"
    ,source_organization           "TRIM(:source_organization)"
    ,location                      "TRIM(:location)"
    ,req_line_number_dist          "TRIM(:req_line_number_dist)"
    ,distribution_quantity         "TRIM(:distribution_quantity)"
    ,charge_account_segment1       "TRIM(:charge_account_segment1)"
    ,charge_account_segment2       "TRIM(:charge_account_segment2)"
    ,charge_account_segment3       "TRIM(:charge_account_segment3)"
    ,charge_account_segment4       "TRIM(:charge_account_segment4)"
    ,charge_account_segment5       "TRIM(:charge_account_segment5)"
    ,charge_account_segment6       "TRIM(:charge_account_segment6)"
    ,charge_account_segment7       "REPLACE(TRIM(:charge_account_segment7),CHR(13),'')"
    ,project                       "TRIM(:project)"
    ,task                          "TRIM(:task)"
    ,expenditure_type              "TRIM(:expenditure_type)"
    ,expenditure_org               "TRIM(:expenditure_org)"
    ,expenditure_item_date         "TO_DATE(REPLACE(TRIM(:expenditure_item_date),CHR(13),''),'MM/DD/YYYY HH24:MI')"
    ,request_id                    CONSTANT 1234
    ,interface_source_code         CONSTANT 'XLS'
    ,destination_type_code         CONSTANT 'EXPENSE'
)

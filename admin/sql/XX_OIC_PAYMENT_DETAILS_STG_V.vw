SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name             : XX_OIC_PAYMENT_DETAILS_STG_V.vw                |
-- | Rice ID          : I0607_IncentiveAndBonusToPayroll               |
-- | Description      : This scipt creates view                        |
-- |                    XX_OIC_PAYMENT_DETAILS_STG_V                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   23-SEP-2007 Rizwan A         Initial Version             |
-- |                                                                   |
-- +===================================================================+

-- ---------------------------------------------------------------------
--      Create view XX_OIC_PAYMENT_DETAILS_STG_V    --
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW xx_oic_payment_details_stg_v AS
SELECT 
 request_id
,payrun_name
,sales_rep_employee_id
,payment_amount
,period
,payment_date
,operating_unit
FROM xx_oic_payment_details_stg
GROUP BY 
 request_id
,payrun_name
,sales_rep_employee_id
,payment_amount
,period
,payment_date
,operating_unit;

SHOW ERROR;
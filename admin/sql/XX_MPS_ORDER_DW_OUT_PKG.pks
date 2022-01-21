create or replace
PACKAGE XX_MPS_ORDER_DW_OUT_PKG
AS
-- +====================================================================+
-- |                  Office Depot                                      | 
-- +====================================================================+
-- |        Name : XX_MPS_ORDER_DW_OUT_PKG                              |
-- | Description : Defect# 20726 - Generate a file for MPS order and    |
-- |               Order Lines for DW                                   |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version    Date          Author           Remarks                   |
-- |=======    ==========    =============    ==========================|
-- |1.0        18-Oct-2012   Deepti S         Defect# 20726             |
-- +====================================================================+
PROCEDURE main(
    p_errbuf OUT VARCHAR2 
   ,p_retcode OUT NUMBER
   ,p_days number);
END;
/
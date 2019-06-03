create or replace
PACKAGE XX_MASTER_CARD_TRAN_VALID_PKG
AS
-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XX_MASTER_CARD_TRAN_VALID_PKG.pks                                            |
-- | Description  : This package is used for the execution of Java Concurrent Program            |
-- |                for Master Card Transactions                                                                            |
-- |Type        Name                       Description                                           |
-- |=========   ===========                ===================================================   |
-- |FUNCTION   CALL_MAIN                    This function will run the Java concurrent Program   |
-- |                                        'APXMCCDF3'  and would return the request ID to BPEL |
-- |                                        process.                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  20-JAN-2012  Deepti S             Initial draft version                            |
-- +=============================================================================================+
FUNCTION CALL_MAIN( p_card_pgm_name      IN VARCHAR2
                    ,p_data_file   IN VARCHAR2
                    ,x_return_message IN OUT VARCHAR2 
                   ) RETURN NUMBER;
 END XX_Master_Card_Tran_Valid_PKG;
/

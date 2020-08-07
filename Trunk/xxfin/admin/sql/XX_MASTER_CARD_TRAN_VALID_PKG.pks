create or replace
PACKAGE XX_MASTER_CARD_TRAN_VALID_PKG
AS
-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XX_MASTER_CARD_TRAN_VALID_PKG.pks                                            |
-- | Description  : This package is used for the execution of Java Concurrent Program            |
-- |                for Master Card Transactions                                                 |
-- |Type        Name                       Description                                           |
-- |=========   ===========                ===================================================   |
-- |FUNCTION   CALL_MAIN                   For calling the iexpense inbound process              |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  20-JAN-2012  Deepti S             Initial draft version                            |
-- +=============================================================================================+
 
   -- This is to call from BPEL
   PROCEDURE CALL_MAIN(p_data_file IN VARCHAR2);

   -- This will be invoked from CP
   PROCEDURE MAIN(errbuff     OUT      VARCHAR2,
                  retcode     OUT      VARCHAR2,
                  p_data_file IN VARCHAR2);


END XX_Master_Card_Tran_Valid_PKG;
/
show err;

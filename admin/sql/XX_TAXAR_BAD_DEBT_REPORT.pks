create or replace PACKAGE XX_TAXAR_BAD_DEBT_REPORT AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        XX_TAXAR_BAD_DEBT_REPORT                            |
-- | Description : Procedure to extract the bad debts written off      |
-- |               and insert the corresponding SAdjustment Numbers    |
-- |               to Custom Batch Audit Table                         |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   02-AUG-08     SHESHI ODETI       Initial version         |
--                                                                     |
-- |V1.0      17-Jan-2014   Veronica M        Modified for Defect 27634|
-- +===================================================================+

-- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : Procedure to Submit the main BAD_DEBT_CREDITCARD    |
-- |               procedure                                           |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: TAX AR Bad Debt Process                             |
-- | Parameters :    p_od_calendar_month                               |   
-- |                 p_od_chargeback_type1                             | 
-- |                 p_od_chargeback_type2                             | 
-- |                 p_od_chargeback_type3                             |  
-- |                 p_od_chargeback_type4                             |  
-- |                 p_od_chargeback_type5                             |  
-- |                 p_od_chargeback_type6                             |  
-- |                 p_od_chargeback_type7                             |  
-- |                 p_od_chargeback_type8                             |  
-- |                 p_od_chargeback_type9                             | 
-- |                 p_od_chargeback_type10                            | 
-- |                 p_error                                           |  
-- | Returns :                                                         |
-- |        return code , error msg                                    |
-- +===================================================================+
  PROCEDURE SUBMIT_REQUEST (
                              x_error_buff           OUT  NOCOPY    VARCHAR2
			     ,x_ret_code             OUT  NOCOPY    NUMBER
			     ,p_od_calendar_month    IN             VARCHAR2  
			     ,p_od_chargeback_type1  IN             VARCHAR2
			     ,p_od_chargeback_type2  IN             VARCHAR2
			     ,p_od_chargeback_type3  IN             VARCHAR2
			     ,p_od_chargeback_type4  IN             VARCHAR2
                             ,p_od_chargeback_type5  IN             VARCHAR2
                             ,p_od_chargeback_type6  IN             VARCHAR2
                             ,p_od_chargeback_type7  IN             VARCHAR2
                             ,p_od_chargeback_type8  IN             VARCHAR2
                             ,p_od_chargeback_type9  IN             VARCHAR2
                             ,p_od_chargeback_type10 IN             VARCHAR2
			   )  ;

/*
-- +===================================================================+
-- | Name : BAD_DEBT_VALUES                                            |
-- | Description : Procedure to derive values for ship to ship from    |
-- |               and other values previously got from taxware tables.|
-- |                                                                   |
-- | Parameters :    p_trx_number                                      |   
-- |                                                                   |  
-- +===================================================================+

   PROCEDURE BAD_DEBT_VALUES( p_trx_number IN VARCHAR2);

*/

--This procedure has been removed from package specification because it is being called within another procedure and its reference here is not necessary.
  FUNCTION is_legacy_batch_source ( 
    p_ar_batch_source in varchar2 ) return number;   --Function from package XX_AR_TWE_UTIL_PKG added for defect 27634 
END XX_TAXAR_BAD_DEBT_REPORT;
/

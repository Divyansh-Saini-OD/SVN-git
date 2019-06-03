/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA PROJECT - XX_PA_QUEUE REGISTER |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_QUEUE_REGISTER                                |
-- | Description:  CREATE AQ REGISTRATION WITH CALL BACK PROC          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      03-Apr-2008  Ian Bassaragh    AQ REGISTRATION             |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
BEGIN
    dbms_aq.register(sys.aq$_reg_info_list(
        sys.aq$_reg_info('XX_PA_QUEUE:RECIPIENT',
                          DBMS_AQ.NAMESPACE_AQ,
                         'plsql://XX_PA_QUEUE_CALL_BACK',
                          HEXTORAW('FF')) ) ,
      1);
END;
/


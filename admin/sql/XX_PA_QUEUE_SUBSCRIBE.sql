/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA PROJECT - XX_PA_QUEUE SUBSCRIBE|
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_QUEUE_SUBSCRIBE                               |
-- | Description:  CREATE AQ SUBSCRIPTION                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      03-Apr-2008  Ian Bassaragh    AQ SUBSCRIPTION             |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
BEGIN
    dbms_aqadm.add_subscriber( 
    queue_name => 'XX_PA_QUEUE',
    subscriber =>  sys.aq$_agent('recipient', null, null));
END;
/


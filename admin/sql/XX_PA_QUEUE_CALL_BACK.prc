/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA PROJECT - CALL BACK PROCEDURE  |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_QUEUE_CALL_BACK                               |
-- | Description:  PL/SQL call back procedure to dequeue the AQ message|
-- |               from XX_PA_PROJ_ERP_EXT_T1 trigger which will then  |
-- |               insert SKU ID attribute rows into PA PROJECTS       |
-- |               PA_PROJECTS_ERP_EXT_B TABLE                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      03-Apr-2008  Ian Bassaragh    Created This call back proc |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
CREATE OR REPLACE PROCEDURE XX_PA_QUEUE_CALL_BACK( context raw,
                                      reginfo sys.aq$_reg_info,
                                      descr sys.aq$_descriptor,
                                      payload raw,
                                      payloadl number)
AS
  dequeue_options    dbms_aq.dequeue_options_t;
  message_properties dbms_aq.message_properties_t;
  message_handle     raw(16);
  message            XX_PA_MESSAGE_TYPE;
  iarg1              VARCHAR2(64);
  iarg2              VARCHAR2(64);
  iarg3              VARCHAR2(64);
  retcode            VARCHAR2(64);
  errbuff            VARCHAR2(64);
  v_request_id       NUMBER;
BEGIN
  dequeue_options.msgid         := descr.msg_id;
  dequeue_options.consumer_name := descr.consumer_name;
  DBMS_AQ.DEQUEUE(
    queue_name         => descr.queue_name,
    dequeue_options    => dequeue_options,
    message_properties => message_properties,
    payload            => message,
    msgid              => message_handle);

 iarg1 := TO_CHAR(message.PRJ_ID);
 iarg2 := TO_CHAR(message.SKU_NUM);
 iarg3 := TO_CHAR(message.UPDT_BY);
 
 XX_PA_CREATE_ITEMID_PKG.XXOD_CREATE_ITEMID(retcode,errbuff,iarg1,iarg2,iarg3);
 commit;
 

END;
/

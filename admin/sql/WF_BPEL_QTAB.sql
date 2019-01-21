SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name    :          CREATE_WF_BPEL_QTAB.tbl                        |
-- | Rice ID :          E0806_SalesCustomerAccountCreation             |
-- | Description      : This scipt creates a table for queue           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   14-SEP-2007 Rizwan A         Initial Version             |
-- +===================================================================+

BEGIN
DBMS_AQADM.DROP_QUEUE_TABLE 
(queue_table       => 'WF_BPEL_QTAB');

DBMS_AQADM.CREATE_QUEUE_TABLE
(queue_table         => 'WF_BPEL_QTAB'
,queue_payload_type  => 'WF_EVENT_T'
,multiple_consumers  => TRUE);
END;

SHOW ERRORS;

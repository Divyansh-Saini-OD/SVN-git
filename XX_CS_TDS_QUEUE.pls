SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  	  : XX_CS_AOPS_QTAB                                    |
-- | Description  : create AQ		                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 07-MAY-08  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


/****************** 
Create Queue Table 
******************/

EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE (queue_table=> 'XX_CS_AOPS_QTAB', queue_payload_type => 'sys.XMLTYPE'); 

/

/****************** 
Create Queue 
******************/ 

EXECUTE DBMS_AQADM.CREATE_QUEUE (queue_name => 'xx_cs_aops_queue', queue_table => 'XX_CS_AOPS_QTAB'); 

/

EXECUTE DBMS_AQADM.START_QUEUE (queue_name => 'xx_cs_aops_queue'); 
/
GRANT SELECT ON XX_CS_AOPS_QTAB TO PUBLIC;
/
exit;
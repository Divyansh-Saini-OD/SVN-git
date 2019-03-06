SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  	  : XX_CS_XML_QTAB                                     |
-- | Description  : create AQ		                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 03-APR-08  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


/****************** 
Create Queue Table 
****************** /
EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE (queue_table=> 'XX_CS_XML_QTAB', queue_payload_type => 'sys.XMLTYPE'); 

/
/****************** 
Create Queue 
******************/ 

EXECUTE DBMS_AQADM.CREATE_QUEUE (queue_name => 'xx_cs_xml_queue', queue_table => 'XX_CS_XML_QTAB'); 

/

EXECUTE DBMS_AQADM.START_QUEUE (queue_name => 'xx_cs_xml_queue'); 
/
exit;

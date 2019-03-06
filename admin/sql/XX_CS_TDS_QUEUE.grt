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
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



GRANT EXECUTE ON XX_CS_AOPS_QTAB TO AQADMIN;

/
exit;
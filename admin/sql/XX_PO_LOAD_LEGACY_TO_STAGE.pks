CREATE OR REPLACE PACKAGE APPS.XX_PO_LOAD_LEGACY_TO_STAGE
-- +==================================================================================+
-- |                      Office Depot - Project Simplify                             |
-- |                                                                                  |
-- +==================================================================================+
-- | Name  :       XX_PO_LOAD_LEGACY_TO_STAGE.pks                                     |
-- | Description:  This package load the FTP file from legacy POM and loads the data  |
-- |               to the pre-processor stage table.                                  |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date           Author                        Remarks                    |
-- |=======   =============  ================    =====================================|
-- |1.0       01-JAN-2008    Victor Costa        Baselined.                           |
-- +==================================================================================+
AS

PROCEDURE XX_PO_LEGACY_ROQS(x_error_buff	OUT	VARCHAR2
                           ,x_ret_code	    OUT	VARCHAR2);

FUNCTION XX_PROCESS_LINES   (l_seq         IN  NUMBER
                            ,l_next_seq    IN  NUMBER
							,l_error_buff OUT VARCHAR2)
RETURN NUMBER;

PROCEDURE XX_PROCESS_ALLOCATIONS (l_ret_code   OUT  NUMBER
                                 ,l_seq         IN  NUMBER
                                 ,l_next_seq    IN  NUMBER
				    		     ,l_error_buff OUT VARCHAR2);

END XX_PO_LOAD_LEGACY_TO_STAGE; 
/


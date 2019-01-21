CREATE OR REPLACE PACKAGE XX_BPEL_INVOKE_ESP_PKG 
AS
-- ------------------------------------------------------------------------
-- $Id$
-- ------------------------------------------------------------------------

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_BPEL_INVOKE_ESP_PKG                                                             |
-- | Description : Manage Information about ESP Jobs to invoke                                        |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       21-June-2008 Cecilia Macean    Initial draft version.      			 	                    |
-- |                                                                                                    |
-- +====================================================================================================+
*/

PROCEDURE get_esp_job_info ( p_process_domain       IN          VARCHAR2,
                             p_process_name         IN          VARCHAR2,
                             p_file_pattern         IN          VARCHAR2,
                             x_job_name             OUT         VARCHAR2,
                             x_esp_application      OUT         VARCHAR2,
                             x_esp_verb             OUT         VARCHAR2
                            );
                            
END XX_BPEL_INVOKE_ESP_PKG;

/

SHOW ERRORS;
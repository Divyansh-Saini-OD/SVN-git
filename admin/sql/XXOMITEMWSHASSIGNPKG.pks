create or replace 
PACKAGE xx_om_item_wsh_Assign_pkg AUTHID CURRENT_USER
-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_ITEM_WSG_ASSIGN                                       |
-- | Rice ID     : Item Warehouse Assignment                                   |
-- | Description : Procedure to call RMS to insert the Item and Location to fix|
-- |               the Item errors from HVOP				       |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 09-OCT-2008  Bala E		 Initial draft version         |
-- | v4.0    24-APR-2018  Faiyaz Ahmad  removing dblink and calling webservices 									       |
-- |                                                                           |
-- +===========================================================================+
AS

PROCEDURE invoke_rms_items_webserv (
p_content     IN CLOB);

PROCEDURE exec_item_rms_wsh_assign(
                                    retcode OUT NOCOPY  NUMBER
                                  , errbuf OUT NOCOPY VARCHAR2
                                  , p_sch_flag IN VARCHAR2
			          , p_request_id IN NUMBER
			                            , p_process_Date IN VARCHAR2
                             );
END xx_om_item_wsh_Assign_pkg;
/
SHOW ERRORS;


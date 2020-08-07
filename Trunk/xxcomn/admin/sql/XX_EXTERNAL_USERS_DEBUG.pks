create or replace PACKAGE XX_EXTERNAL_USERS_DEBUG
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PVT                                                             |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.      			 	                    |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.          		        |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant and commented code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  PROCEDURE print_debug_status;

  PROCEDURE enable_debug;

  PROCEDURE disable_debug;

  PROCEDURE log_debug_message ( p_debug_level    IN    NUMBER
                              , p_message        IN    VARCHAR2
                              );

  PROCEDURE truncate_debug_table ( x_errbuf            OUT    VARCHAR2
                                 , x_retcode           OUT    VARCHAR2
                                 );

END XX_EXTERNAL_USERS_DEBUG;

/

SHOW ERRORS;

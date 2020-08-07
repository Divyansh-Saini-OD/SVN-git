CREATE OR REPLACE PACKAGE BODY XX_EXTERNAL_USERS_DEBUG
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PVT                                                                |
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
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.         			 	                    |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.            		        |
-- |          31-Dec-2007 Yusuf Ali          Incorporated granular API for creating contact at account  |
-- |					                               site level and creating role for web user.                 |
-- |          02-Jan-2008 Yusuf Ali	         Removed call to create_role_resp procedure from            |
-- |					                               save_ext_user procedure.                                   |
-- |          07-Jan-2008 Yusuf Ali	         Created cursor to retrieve party id and cust account role  |
-- |			                Kathirvel Perumal  id from cust account roles table in create_role_resp       |
-- |						                             procedure and create equi-join query to get org id from    |
-- |						                             cust acct sites all table in save_ext_usr procedure.	      |
-- |	        07-Jan-2008 Yusuf Ali          Created cursor for fetching responsibility id and created  |
-- |                                         log_debug procedure to messages.                           |
-- |          08-Jan-2008 Narayan Bh.	       Modified cursors to accept ln_acct_role_id parameter for   |
-- |                      Yusuf Ali	         l_get_responsibility_id_cur, l_get_party_id_cur to accept  |
-- |                      Alok Sahay         OSR, and both cursors to select object version to pass     |
-- |                                         into appropriate granular API call, changed query in       |
-- |                                         save_ext_user to obtain org id for instance where          |
-- |                                         cust_acct_site_id IS NOT NULL.				                      |
-- |	        08-Jan-2008 Narayan Bh	       Created new query in create_role_resp to take              |
-- |					                               ln_bill_to_site_use_id to get cust_acct_site_id from 	    |
-- |  					                             hz_cust_site_uses_all.			                                |
-- |          09-Jan-2008 Alok Sahay 	       Removed permission flag variable (not being used) for 	    |
-- | 					                               condition where permission flag is S/M in create role resp |
-- |					                               procedure							                                    |
-- |          09-Jan-2008 Yusuf Ali          Created/moved get_site_use_id to beginning of   		        |
-- | 			                Alok Sahay	       create_role_resp procedure.                                |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant Variables and Code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |1.3       11-Dec-15   Manikant Kasu      Removed schema alias as part of GSCC R12.2.2 Retrofit      |
-- +====================================================================================================+
*/

  g_debug_type     VARCHAR2(10)    := 'FND';
  g_debug_level    NUMBER          := 3;
  g_debug_count    NUMBER          := 0;
  g_debug          BOOLEAN         := FALSE;

  g_pkg_name       CONSTANT VARCHAR2(30) := 'XX_EXTERNAL_USERS_DEBUG';
  g_module         CONSTANT VARCHAR2(30) := 'CRM';
  g_session_id     NUMBER;

  g_request_id     fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();

  -- ==========================================================================
  --  PROCEDURE NAME:   print_debug_status
  --  DESCRIPTION:      Print the Debug Status.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE print_debug_status
  IS
  BEGIN
       DBMS_OUTPUT.PUT_LINE('g_debug_type     : ' || g_debug_type   );
       DBMS_OUTPUT.PUT_LINE('g_debug_level    : ' || g_debug_level  );
       DBMS_OUTPUT.PUT_LINE('g_debug_count    : ' || g_debug_count  );
       IF g_debug
       THEN
           DBMS_OUTPUT.PUT_LINE('g_debug          : true'        );
       ELSE
           DBMS_OUTPUT.PUT_LINE('g_debug          : false'        );
       END IF; -- g_debug

       DBMS_OUTPUT.PUT_LINE('g_pkg_name       : ' || g_pkg_name     );
       DBMS_OUTPUT.PUT_LINE('g_module         : ' || g_module       );
       DBMS_OUTPUT.PUT_LINE('g_session_id     : ' || g_session_id   );
       DBMS_OUTPUT.PUT_LINE('g_request_id     : ' || g_request_id   );

       XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Test Debugging at Log Level 0' );
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, 'Test Debugging at Log Level 1' );
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(2, 'Test Debugging at Log Level 2' );
       XX_EXTERNAL_USERS_DEBUG.log_debug_message(3, 'Test Debugging at Log Level 3' );

  END print_debug_status;


  -- ==========================================================================
  --  PROCEDURE NAME:   enable_debug
  --  DESCRIPTION:      Turn on debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE enable_debug
  IS
  BEGIN
    g_debug_count    := g_debug_count + 1;
    g_request_id     := fnd_global.conc_request_id();

    IF g_debug_count >= 1
    THEN
      IF fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG') = 'Y'
      THEN
         g_debug       := TRUE;
         g_debug_type  := 'XXCOM';
         g_debug_level := NVL(fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG_LEVEL'),3);
      ELSIF fnd_profile.value('HZ_API_FILE_DEBUG_ON') = 'Y' OR
         fnd_profile.value('HZ_API_DBMS_DEBUG_ON') = 'Y'
      THEN
         hz_utility_v2pub.enable_debug;
         g_debug       := TRUE;
         g_debug_type  := 'HZ';
         g_debug_level := NVL(fnd_profile.value('XXOD_EXTERNAL_USERS_SYNC_DEBUG_LEVEL'),3);
      ELSE
         g_debug       := FALSE;
         g_debug_type  := NULL;
         g_debug_level := 0;
      END IF;
    END IF; -- g_debug_count >= 1
    g_debug := TRUE;
  END enable_debug;

  -- ==========================================================================
  --  PROCEDURE NAME:   disable_debug
  --  DESCRIPTION:      Turn Off debug mode.
  --  PARAMETERS:       None
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE disable_debug
  IS
  BEGIN

    IF g_debug THEN
      g_debug_count := g_debug_count - 1;

      IF g_debug_count = 0 THEN
        hz_utility_v2pub.disable_debug;
        g_debug := FALSE;
      END IF;
    END IF;

  END disable_debug;

  -- ===========================================================================
  --  PROCEDURE NAME:   log_debug_message
  --  DESCRIPTION:      This procedure parses and prints debugging messages.
  --  PARAMETERS:       p_debug_level            IN   NUMBER
  --                    p_message                IN   VARCHAR2
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE log_debug_message ( p_debug_level    IN    NUMBER
                              , p_message        IN    VARCHAR2
                              )
  IS
     PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

     IF g_session_id IS NULL
     THEN
         SELECT SYS_CONTEXT('USERENV','SESSIONID') sessionid
         INTO   g_session_id
         FROM   DUAL;
     END IF; -- g_session_id IS NULL

--     INSERT INTO XXCOMN.XX_COMN_DEBUG (SESSION_ID, TIME, MESSAGE)
--            VALUES (g_session_id, SYSTIMESTAMP, p_message);

     IF g_debug = TRUE AND g_debug_level >= p_debug_level
     THEN
        IF NVL(g_request_id,-1) <> -1
        THEN
            IF fnd_file.log IS NOT NULL
            THEN
               fnd_file.put_line (fnd_file.log, p_message);
            END IF; -- fnd_file.log IS NOT NULL
        ELSIF g_debug_type  = 'HZ'
        THEN
           hz_utility_v2pub.debug(p_message);
        ELSE
           -- Call XX_COMN_DEBUG
           INSERT INTO XX_COMN_DEBUG (SESSION_ID, TIME, MESSAGE)
                  VALUES (g_session_id, SYSTIMESTAMP, p_message);
        END IF; -- NVL(g_request_id,0) <> 0
     END IF; -- g_debug = TRUE AND g_debug_level >= p_debug_level

     COMMIT;
  EXCEPTION
     WHEN OTHERS THEN
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.log_debug_message');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);

  END log_debug_message;


  -- ==========================================================================
  --  PROCEDURE NAME:   print_debug_status
  --  DESCRIPTION:      Print the Debug Status.
  --  PARAMETERS:       x_errbuf        Error Message
  --                    x_retcode       Reyurn Code
  --  NOTES:            None.
  -- ===========================================================================
  PROCEDURE truncate_debug_table ( x_errbuf            OUT    VARCHAR2
                                 , x_retcode           OUT    VARCHAR2
                                 )
  IS
  BEGIN

       EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCOMN.XX_COMN_DEBUG';
       x_retcode := 0;
       x_errbuf  := 'Truncated debug table';

  END truncate_debug_table;

END XX_EXTERNAL_USERS_DEBUG;
/

SHOW ERRORS;
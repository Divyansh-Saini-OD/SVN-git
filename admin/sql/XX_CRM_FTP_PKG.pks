SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_FTP_PKG AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                                                                               |
-- +===============================================================================+
-- | Name  : XX_CRM_FTP_PKG.pks                                                    |
-- | Description: This package will ftp files                                      |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date        Author               Remarks                             |
-- |=======  ===========  =============        ====================================|
-- |1.0      06-JAN-2010  Bapuji Nanapaneni    Initial draft version               |
-- |                                                                               |
-- +===============================================================================+
/*Global Variables Declaration */
g_binary        BOOLEAN := TRUE;
g_convert_crlf  BOOLEAN := TRUE;
g_debug         BOOLEAN := TRUE;


TYPE t_string_table IS TABLE OF VARCHAR2(32767);

g_reply         t_string_table := t_string_table();
-- +===================================================================+
-- | Name  : Login                                                     |
-- | Description      : This Function will vaildate log in Credentials |
-- |                                                                   |
-- | Parameters      : p_host    IN -> pass host name                  |
-- |                   P_port    IN -> pass port name                  |
-- |                   P_user    IN -> pass user name                  |
-- |                   p_pass    IN -> pass password                   |
-- |                   p_timeout IN -> pass timeout intervel           |
-- |                   UTL_TCP.connection  OUT Return FTP connection   |
-- +===================================================================+
FUNCTION login (p_host    IN  VARCHAR2,
                p_port    IN  VARCHAR2,
                p_user    IN  VARCHAR2,
                p_pass    IN  VARCHAR2,
                p_timeout IN  NUMBER := NULL) 
  RETURN UTL_TCP.connection;

-- +===================================================================+
-- | Name  : Logout                                                    |
-- | Description      : This Procedure will vaildate logout Credentials|
-- |                                                                   |
-- | Parameters      : p_conn    IN/OUT -> pass TCP Connection         |
-- |                   P_reply   IN     -> pass Reply                  |
-- +===================================================================+                       
PROCEDURE logout (p_conn   IN OUT NOCOPY  UTL_TCP.connection,
                  p_reply  IN             BOOLEAN := TRUE);

-- +===================================================================+
-- | Name  : put                                                       |
-- | Description      :This procedure put the file in the specified dir|
-- |                                                                   |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_from_dir  IN     -> pass from dir name        |
-- |                   p_from_file IN     -> pass file from path       |
-- |                   p_to_file   IN     -> pass file name            |
-- +===================================================================+                 
PROCEDURE put (p_conn       IN OUT NOCOPY  UTL_TCP.connection,
               p_from_dir   IN             VARCHAR2,
               p_from_file  IN             VARCHAR2,
               p_to_file    IN             VARCHAR2);
                       
-- +===================================================================+
-- | Name  : put_remote_binary_data                                    |
-- | Description      :This procedure put binary data in specified dir |
-- |                                                                   |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_file      IN     -> pass from file name       |
-- |                   p_data      IN     -> pass data                 |
-- +===================================================================+
PROCEDURE put_remote_binary_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                  p_file  IN             VARCHAR2,
				  p_data  IN             BLOB);

-- +===================================================================+
-- | Name  : put_remote_ascii_data                                     |
-- | Description      :This procedure put ascii data in specified dir  |
-- |                                                                   |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_file      IN     -> pass from file name       |
-- |                   p_data      IN     -> pass data                 |
-- +===================================================================+
PROCEDURE put_remote_ascii_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                 p_file  IN             VARCHAR2,
                                 p_data  IN             CLOB);

-- +===================================================================+
-- | Name  : get_local_ascii_data                                      |
-- | Description      :This Function puts ascii data in specified dir  |
-- |                                                                   |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_file      IN     -> pass from file name       |
-- |                   p_data      OUT    -> Return Ascii data         |
-- +===================================================================+
FUNCTION get_local_ascii_data (p_dir   IN  VARCHAR2,
                               p_file  IN  VARCHAR2)
  RETURN CLOB;

-- +===================================================================+
-- | Name  : get_local_binary_data                                      |
-- | Description      :This Function puts Binary data in specified dir  |
-- |                                                                    |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection        |
-- |                   p_file      IN     -> pass from file name        |
-- |                   p_data      OUT    -> Return Binary data         |
-- +===================================================================+  
FUNCTION get_local_binary_data (p_dir   IN  VARCHAR2,
                                p_file  IN  VARCHAR2)
  RETURN BLOB;

-- +===================================================================+
-- | Name  : get_reply                                                 |
-- | Description      :This Procdure gets reply from server            |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- +===================================================================+  
PROCEDURE get_reply (p_conn  IN OUT NOCOPY  UTL_TCP.connection);

-- +===================================================================+
-- | Name  : get_passive                                               |
-- | Description      :This Function gets passive connection to server |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   UTL_TCP.connection OUT Return connection        |
-- +===================================================================+
FUNCTION get_passive (p_conn  IN OUT NOCOPY  UTL_TCP.connection) 
  RETURN UTL_TCP.connection;
  
-- +===================================================================+
-- | Name  : send_command                                              |
-- | Description      :This Procedure sends command to server          |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_command   IN pass command                     |
-- |                   p_reply     IN pass reply                       |
-- +===================================================================+
PROCEDURE send_command (p_conn     IN OUT NOCOPY  UTL_TCP.connection,
                        p_command  IN             VARCHAR2,
                        p_reply    IN             BOOLEAN := TRUE);


-- +===================================================================+
-- | Name  : Transfer_File                                             |
-- | Description      :This procedure transfer file from one server to |
-- |                   another server                                  |
-- | Parameters      : x_retcode OUT return retcode                    |
-- |                   x_errbuff OUT return errbuff                    |
-- |                   P_from_directory IN pass from dir name          |
-- |                   p_from_file_name IN pass file name              |
-- |                   p_file_to_name   IN pass file to name           |
-- +===================================================================+
PROCEDURE Transfer_File( x_retcode          OUT NOCOPY VARCHAR2
                       , x_errbuff          OUT NOCOPY VARCHAR2 
                       , P_from_directory    IN VARCHAR2
                       , p_from_file_name    IN VARCHAR2
                       , p_file_to_name      IN VARCHAR2
                       );
END XX_CRM_FTP_PKG;
/
SHOW ERRORS PACKAGE XX_CRM_FTP_PKG;
EXIT;

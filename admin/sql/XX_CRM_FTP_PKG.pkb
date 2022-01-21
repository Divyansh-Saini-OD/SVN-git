SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_FTP_PKG AS
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- |                                                                                  |
-- +==================================================================================+
-- | Name  : XX_CRM_FTP_PKG.pks                                                       |
-- | Description: This package will ftp files                                         |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date        Author               Remarks                                |
-- |=======  ===========  =============        =======================================|
-- |1.0      06-JAN-2010  Bapuji Nanapaneni    Initial draft version                  |
-- |1.1      08-JUN-2016  Havish Kasina        Removed the hardcoded user name and    |
-- |                                           password and to use new FTP account    |
-- |                                           ODPFTP instead of PRODFTP(Defect 38081)|                                                                 
-- +==================================================================================+

PROCEDURE debug (p_text  IN  VARCHAR2);

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
                       ) IS
                       
l_conn  UTL_TCP.connection;
lc_translation_name      xx_fin_translatedefinition.translation_name%TYPE := 'OD_FTP_PROCESSES';  -- Added for Defect 38081
lc_process_name          VARCHAR2(30)  := 'OD_CRM_FTP_PROCESS';     -- Added for Defect 38081
lr_config_details_rec    xx_fin_translatevalues%ROWTYPE  := NULL;   -- Added for Defect 38081
BEGIN
  -- Adding changes for the Defect 38081 
   lr_config_details_rec := NULL;

   SELECT *
     INTO lr_config_details_rec
	 FROM xx_fin_translatevalues
	WHERE 1 = 1
	  AND translate_id = (SELECT translate_id
	                        FROM xx_fin_translatedefinition
						   WHERE translation_name = lc_translation_name)
	  AND source_value1 = lc_process_name;
  
DBMS_OUTPUT.PUT_LINE('BEGIN');
	l_conn := login(lr_config_details_rec.target_value1,lr_config_details_rec.target_value4,lr_config_details_rec.target_value2,lr_config_details_rec.target_value3);
 -- End of adding changes for the Defect 38081
          put( p_conn      => l_conn
             , p_from_dir  => P_from_directory
             , p_from_file => p_from_file_name
             , p_to_file   => p_file_to_name);
          
             logout( p_conn   =>  l_conn
                   , p_reply  => TRUE);  

EXCEPTION
   WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log ,'Exception at Transfer_File procedure');				   

END Transfer_File;    

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
               p_to_file    IN             VARCHAR2) AS
-- --------------------------------------------------------------------------
BEGIN
  IF g_binary THEN
    put_remote_binary_data(p_conn => p_conn,
                           p_file => p_to_file,
                           p_data => get_local_binary_data(p_from_dir, p_from_file));
  ELSE
    put_remote_ascii_data(p_conn => p_conn,
                          p_file => p_to_file,
                          p_data => get_local_ascii_data(p_from_dir, p_from_file));
  END IF;
  get_reply(p_conn);
END;

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
                                  p_data  IN             BLOB) IS
-- --------------------------------------------------------------------------
  l_conn      UTL_TCP.connection;
  l_result    PLS_INTEGER;
  l_buffer    RAW(32767);
  l_amount    BINARY_INTEGER := 32767;
  l_pos       INTEGER := 1;
  l_blob_len  INTEGER;
BEGIN
  l_conn := get_passive(p_conn);
  send_command(p_conn, 'STOR ' || p_file, TRUE);
  
  l_blob_len := DBMS_LOB.getlength(p_data);

  WHILE l_pos <= l_blob_len LOOP
    DBMS_LOB.READ (p_data, l_amount, l_pos, l_buffer);
    l_result := UTL_TCP.write_raw(l_conn, l_buffer, l_amount);
    UTL_TCP.flush(l_conn);
    l_pos := l_pos + l_amount;
  END LOOP;

  UTL_TCP.close_connection(l_conn);
  -- The following line allows some people to make multiple calls from one connection.
  -- It causes the operation to hang for me, hence it is commented out by default.
  -- get_reply(p_conn);

EXCEPTION
  WHEN OTHERS THEN
    UTL_TCP.close_connection(l_conn);
    RAISE;
END;

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
                                 p_data  IN             CLOB) IS
-- --------------------------------------------------------------------------
  l_conn      UTL_TCP.connection;
  l_result    PLS_INTEGER;
  l_buffer    VARCHAR2(32767);
  l_amount    BINARY_INTEGER := 32767;
  l_pos       INTEGER := 1;
  l_clob_len  INTEGER;
BEGIN
  l_conn := get_passive(p_conn);
  send_command(p_conn, 'STOR ' || p_file, TRUE);
  
  l_clob_len := DBMS_LOB.getlength(p_data);

  WHILE l_pos <= l_clob_len LOOP
    DBMS_LOB.READ (p_data, l_amount, l_pos, l_buffer);
    IF g_convert_crlf THEN
      l_buffer := REPLACE(l_buffer, CHR(13), NULL);
    END IF;
    l_result := UTL_TCP.write_text(l_conn, l_buffer, LENGTH(l_buffer));
    UTL_TCP.flush(l_conn);
    l_pos := l_pos + l_amount;
  END LOOP;

  UTL_TCP.close_connection(l_conn);
  -- The following line allows some people to make multiple calls from one connection.
  -- It causes the operation to hang for me, hence it is commented out by default.
  -- get_reply(p_conn);

EXCEPTION
  WHEN OTHERS THEN
    UTL_TCP.close_connection(l_conn);
    RAISE;
END;

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
  RETURN CLOB IS
-- --------------------------------------------------------------------------
  l_bfile   BFILE;
  l_data    CLOB;
BEGIN
  DBMS_LOB.createtemporary (lob_loc => l_data,
                            cache   => TRUE,
                            dur     => DBMS_LOB.call);
   
  l_bfile := BFILENAME(p_dir, p_file);
  DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);

  IF DBMS_LOB.getlength(l_bfile) > 0 THEN
    DBMS_LOB.loadfromfile(l_data, l_bfile, DBMS_LOB.getlength(l_bfile));
  END IF; 

  DBMS_LOB.fileclose(l_bfile);

  RETURN l_data;
END;

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
  RETURN BLOB IS
-- --------------------------------------------------------------------------
  l_bfile   BFILE;
  l_data    BLOB;
BEGIN
  DBMS_LOB.createtemporary (lob_loc => l_data,
                            cache   => TRUE,
                            dur     => DBMS_LOB.call);
   
  l_bfile := BFILENAME(p_dir, p_file);
  DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
  IF DBMS_LOB.getlength(l_bfile) > 0 THEN
    DBMS_LOB.loadfromfile(l_data, l_bfile, DBMS_LOB.getlength(l_bfile));
  END IF; 
  DBMS_LOB.fileclose(l_bfile);

  RETURN l_data;
END;

-- +===================================================================+
-- | Name  : get_reply                                                 |
-- | Description      :This Procdure gets reply from server            |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- +===================================================================+
PROCEDURE get_reply (p_conn  IN OUT NOCOPY  UTL_TCP.connection) IS
-- --------------------------------------------------------------------------
  l_reply_code  VARCHAR2(3) := NULL;
BEGIN
  LOOP
    g_reply.extend;
    g_reply(g_reply.last) := UTL_TCP.get_line(p_conn, TRUE);
    debug(g_reply(g_reply.last));
    IF l_reply_code IS NULL THEN
      l_reply_code := SUBSTR(g_reply(g_reply.last), 1, 3);
    END IF;
    IF SUBSTR(l_reply_code, 1, 1) IN ('4', '5') THEN
      RAISE_APPLICATION_ERROR(-20000, g_reply(g_reply.last));
    ELSIF (SUBSTR(g_reply(g_reply.last), 1, 3) = l_reply_code AND
           SUBSTR(g_reply(g_reply.last), 4, 1) = ' ') THEN
      EXIT;
    END IF;
  END LOOP;
EXCEPTION
  WHEN UTL_TCP.END_OF_INPUT THEN
    NULL;
END;

PROCEDURE debug (p_text  IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
BEGIN
  IF g_debug THEN
    DBMS_OUTPUT.put_line(SUBSTR(p_text, 1, 255));
    FND_FILE.put_line(FND_FILE.OUTPUT,SUBSTR(p_text, 1, 255));
  END IF;
END;

-- +===================================================================+
-- | Name  : get_passive                                               |
-- | Description      :This Function gets passive connection to server |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   UTL_TCP.connection OUT Return connection        |
-- +===================================================================+
FUNCTION get_passive (p_conn  IN OUT NOCOPY  UTL_TCP.connection) 
  RETURN UTL_TCP.connection IS
-- --------------------------------------------------------------------------
  l_conn    UTL_TCP.connection;
  l_reply   VARCHAR2(32767);
  l_host    VARCHAR(100);
  l_port1   NUMBER(10);
  l_port2   NUMBER(10);
BEGIN
  send_command(p_conn, 'PASV');
  l_reply := g_reply(g_reply.last);
  
  l_reply := REPLACE(SUBSTR(l_reply, INSTR(l_reply, '(') + 1, (INSTR(l_reply, ')')) - (INSTR(l_reply, '('))-1), ',', '.');
  l_host  := SUBSTR(l_reply, 1, INSTR(l_reply, '.', 1, 4)-1);

  l_port1 := TO_NUMBER(SUBSTR(l_reply, INSTR(l_reply, '.', 1, 4)+1, (INSTR(l_reply, '.', 1, 5)-1) - (INSTR(l_reply, '.', 1, 4))));
  l_port2 := TO_NUMBER(SUBSTR(l_reply, INSTR(l_reply, '.', 1, 5)+1));
  
  l_conn := utl_tcp.open_connection(l_host, 256 * l_port1 + l_port2);
  return l_conn;
END;

-- +===================================================================+
-- | Name  : send_command                                              |
-- | Description      :This Procedure sends command to server          |
-- | Parameters      : p_conn      IN/OUT -> pass TCP Connection       |
-- |                   p_command   IN pass command                     |
-- |                   p_reply     IN pass reply                       |
-- +===================================================================+
PROCEDURE send_command (p_conn     IN OUT NOCOPY  UTL_TCP.connection,
                        p_command  IN             VARCHAR2,
                        p_reply    IN             BOOLEAN := TRUE) IS
-- --------------------------------------------------------------------------
  l_result  PLS_INTEGER;
BEGIN
  l_result := UTL_TCP.write_line(p_conn, p_command);
  -- If you get ORA-29260 after the PASV call, replace the above line with the following line.
  -- l_result := UTL_TCP.write_text(p_conn, p_command || utl_tcp.crlf, length(p_command || utl_tcp.crlf));
  
  IF p_reply THEN
    get_reply(p_conn);
  END IF;
END;

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
  RETURN UTL_TCP.connection IS
-- --------------------------------------------------------------------------
  l_conn  UTL_TCP.connection;
BEGIN
  g_reply.delete;
  
  l_conn := UTL_TCP.open_connection(p_host, p_port, tx_timeout => p_timeout);
  get_reply (l_conn);
  send_command(l_conn, 'USER ' || p_user);
  send_command(l_conn, 'PASS ' || p_pass);
  RETURN l_conn;
END;

-- +===================================================================+
-- | Name  : Logout                                                    |
-- | Description      : This Procedure will vaildate logout Credentials|
-- |                                                                   |
-- | Parameters      : p_conn    IN/OUT -> pass TCP Connection         |
-- |                   P_reply   IN     -> pass Reply                  |
-- +===================================================================+
PROCEDURE logout(p_conn   IN OUT NOCOPY  UTL_TCP.connection,
                 p_reply  IN             BOOLEAN := TRUE) AS
-- --------------------------------------------------------------------------
BEGIN
  send_command(p_conn, 'QUIT', p_reply);
  UTL_TCP.close_connection(p_conn);
END;
END XX_CRM_FTP_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CRM_FTP_PKG;
EXIT;


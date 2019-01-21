CREATE OR REPLACE PACKAGE BODY xx_cn_util_pkg
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                 Oracle NAIO Consulting Organization                            |
-- +================================================================================+
-- | Name       : XX_CN_UTIL_PKG                                                    |
-- |                                                                                |
-- | Description:  Allow messages (both for reporting and debugging) to be written  |
-- |to a database table or to a stack(plsql table) by PL/SQL programs executed      |
-- |on the server. Messages can be retrieved and used in an on-line report          |
-- |or log file.                                                                    |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 24-SEP-2007 Sarah Maria Justina        Initial draft version           |
-- |1.0      12-Oct-2007 Sarah Maria Justina        Baselined after Testing         |
-- |1.1      29-Oct-2007 Sarah Maria Justina        Changed logic of                | 
-- |                                                xx_cn_get_division              |
-- |1.2      07-NOV-2007 Hema Chikkanna             Modified the log_error procedure|
-- |                                                as per onsite Requirement       |
-- |1.3      12-NOV-2007 Hema Chikkanna             Excluded g_process_audit_id     |
-- |                                                variables.                      |
-- |1.4      13-NOV-2007 Sarah Maria Justina        Changed Log_error specification |
-- +================================================================================+

-- +================================================================================+

   /*------------------------------ DATA TYPES ---------------------------------*/
   TYPE message_table_type IS TABLE OF VARCHAR2 (255)
      INDEX BY BINARY_INTEGER;

   TYPE code_table_type IS TABLE OF VARCHAR2 (12)
      INDEX BY BINARY_INTEGER;

   TYPE date_table_type IS TABLE OF DATE
      INDEX BY BINARY_INTEGER;

/*---------------------------- PRIVATE VARIABLES ----------------------------*/

   -- Text is indented in 3 character increments
   g_indent0                VARCHAR2 (14)           := '';
   g_indent1                VARCHAR2 (14)           := '  ';
   g_indent2                VARCHAR2 (14)           := '    ';
   g_indent3                VARCHAR2 (14)           := '      ';
   g_indent4                VARCHAR2 (14)           := '        ';
   g_indent5                VARCHAR2 (14)           := '          ';
   g_msg_stack              message_table_type;              -- Message Stack
   g_msg_stack_empty        message_table_type;
   
   -- Empty Stack for clearing memory
   g_msg_type_stack         code_table_type;
                                           -- Message Type Stack in sync with
   -- message stack
   g_msg_type_stack_empty   code_table_type;              -- Emtpy Type Stack
   g_msg_date_stack         date_table_type;
                                           -- Message Date Stack in sync with
   -- message stack
   g_msg_date_stack_empty   date_table_type;              -- Emtpy Date Stack
   g_msg_count              NUMBER                  := 0;
   -- Num of Messages on stack
   g_msg_ptr                NUMBER                  := 1;
                                                    -- Points to next Message
   -- on stack to retreive.
   g_user_id                NUMBER                  := fnd_global.user_id;
   g_conc_request_id        NUMBER                  := 0;
   g_batch_id               NUMBER             NULL;

   g_cn_debug               VARCHAR2 (1);
   g_module_name   CONSTANT VARCHAR2 (50)           := 'CN';
   g_notify        CONSTANT VARCHAR2 (1)            := 'Y';
   g_error_status  CONSTANT VARCHAR2 (10)           := 'ACTIVE';
   g_major         CONSTANT VARCHAR2 (15)           := 'MAJOR';
   g_minor         CONSTANT VARCHAR2 (15)           := 'MINOR';
   g_user_id       CONSTANT VARCHAR2 (60)           := fnd_global.user_id ();

/*---------------------------- PRIVATE ROUTINES ------------------------------*/

  -- +===========================================================================+
  -- | NAME                                                                      |
  -- |    SET_MESSAGE                                                            |
  -- |                                                                           |
  -- | PURPOSE                                                                   |
  -- |   Cover for set_name and set_token                                        |
  -- | NOTES                                                                     |
  -- |   Whenever either the fornm or batch program encounters validation        |
  -- |   problems we push the corresponding  message onto the stack.             |
  -- |   At the the end of batch processing we will dump these messages into a   |
  -- |   table, we never interrupt the processing to issue messages.             |
  -- |   If validation fails during form processing we must either raise         |
  -- |   an error thus halting processing or raise a warning.                    |
  -- |   These forms messages are handled by fnd_set_message but we also         |
  -- |   write the messages to the stack so that if no application_error is      |
  -- |   raised we have the option of pushing them back into a form window       |
  -- |   at the end of the comit cycle.                                          |
  -- +===========================================================================+
   PROCEDURE set_message (
                           appl_short_name   IN   VARCHAR2,
                           message_name      IN   VARCHAR2,
                           token_name1       IN   VARCHAR2,
                           token_value1      IN   VARCHAR2,
                           token_name2       IN   VARCHAR2,
                           token_value2      IN   VARCHAR2,
                           token_name3       IN   VARCHAR2,
                           token_value3      IN   VARCHAR2,
                           token_name4       IN   VARCHAR2,
                           token_value4      IN   VARCHAR2,
                           translate         IN   BOOLEAN
                         )
   IS
   BEGIN
      -- Always set the passed message in case we want to fail processing
      -- and issue the message in the form.
      fnd_message.set_name (appl_short_name, message_name);

      -- protecting unused tokens prevents display of an "=" character in the
      -- message
      IF token_name1 IS NOT NULL
      THEN
         FND_MESSAGE.set_token (token_name1, token_value1);
      END IF;

      IF token_name2 IS NOT NULL
      THEN
         FND_MESSAGE.set_token (token_name2, token_value2);
      END IF;

      IF token_name3 IS NOT NULL
      THEN
         FND_MESSAGE.set_token (token_name3, token_value3);
      END IF;

      IF token_name4 IS NOT NULL
      THEN
         FND_MESSAGE.set_token (token_name4, token_value4);
      END IF;
      
   END set_message;
   
   
-- +========================================================================+
-- | Name        :  INS_AUDIT_LINE                                          |
-- |                                                                        |
-- | Description :  This procedure inserts records into table               |
-- |                xx_cn_process_audit_lines for auditing purpose.         |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_message_text IN VARCHAR2                              |
-- |                p_message_type IN VARCHAR2                              |
-- |                                                                        |
-- +========================================================================+
     
   PROCEDURE ins_audit_line ( p_message_text IN VARCHAR2
                             ,p_message_type IN VARCHAR2
                            )
   IS
   BEGIN
      INSERT INTO xx_cn_process_audit_lines
                  ( process_audit_id
                   ,process_audit_line_id
                   ,message_text
                   ,message_type_code
                  )
           VALUES ( g_process_audit_id
                   ,xx_cn_process_audit_lines_s.NEXTVAL
                   ,SUBSTRB (p_message_text, 1, 239)
                   ,p_message_type
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         rollback_errormsg_commit ('cn_message.insert_audit_line');
         
         RAISE;
   END ins_audit_line;
   
-- +========================================================================+
-- | Name        :  PUSH                                                    |
-- |                                                                        |
-- | Description :  This pushes the messages to the stack                   |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_message_text IN VARCHAR2                              |
-- |                p_message_type IN VARCHAR2                              |
-- |                                                                        |
-- +========================================================================+
    
   PROCEDURE push ( p_message_text IN VARCHAR2
                   ,p_message_type IN VARCHAR2)
   IS
   BEGIN
      IF (g_msg_count > 1000)
      THEN
         FLUSH;
      END IF;

      g_msg_count := g_msg_count + 1;
      g_msg_stack (g_msg_count) := SUBSTRB (p_message_text, 1, 254);
      g_msg_type_stack (g_msg_count) := p_message_type;
      g_msg_date_stack (g_msg_count) := SYSDATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         FLUSH;
         g_msg_count := g_msg_count + 1;
         g_msg_stack (g_msg_count) := p_message_text;
         g_msg_type_stack (g_msg_count) := p_message_type;
         g_msg_date_stack (g_msg_count) := SYSDATE;
   END push;
   
   
-- +========================================================================+
-- | Name        :  INS_AUDIT_BATCH                                         |
-- |                                                                        |
-- | Description :  This procedure inserts records into table               |
-- |                xx_cn_process_audits for auditing purpose.              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_parent_proc_audit_id   IN NUMBER,                     |
-- |                x_process_audit_id       IN OUT NOCOPY NUMBER,          |
-- |                p_request_id             IN NUMBER,                     |
-- |                p_process_type           IN VARCHAR2,                   |
-- |                p_description            IN VARCHAR2                    |
-- |                                                                        |
-- +========================================================================+
     
   PROCEDURE ins_audit_batch (
                               p_parent_proc_audit_id   IN NUMBER,
                               x_process_audit_id       IN OUT NOCOPY NUMBER,
                               p_request_id             IN NUMBER,
                               p_process_type           IN VARCHAR2,
                               p_description            IN VARCHAR2
                             )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      SELECT xx_cn_process_audits_s.NEXTVAL
        INTO g_process_audit_id
        FROM SYS.DUAL;

      x_process_audit_id := g_process_audit_id;

      INSERT INTO xx_cn_process_audits
                  (process_audit_id,
                   parent_process_audit_id,
                   concurrent_request_id, process_type, timestamp_start,
                   description,org_id
                  )
           VALUES (x_process_audit_id,
                   NVL (p_parent_proc_audit_id, x_process_audit_id),
                   p_request_id, p_process_type, SYSDATE,
                   p_description,fnd_global.org_id
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         rollback_errormsg_commit ('cn_message.insert_audit_batch');
         RAISE;
   END ins_audit_batch;

   /*---------------------------- PUBLIC ROUTINES ------------------------------*/

-- +========================================================================+
-- | Name        :  DEBUG                                                   |
-- |                                                                        |
-- | Description :  Writes a debug message to the stack only if profile     |
-- |                CN_DEBUG = 'Y'                                          |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                message_text IN VARCHAR2                                |
-- |                                                                        |
-- |                                                                        |
-- |                                                                        |
-- |                                                                        |
-- +========================================================================+
  
   PROCEDURE debug (message_text IN VARCHAR2)
   IS
      PROFILE   NUMBER;
   BEGIN
      IF g_cn_debug = 'Y'
      THEN
      
         push (p_message_text => MESSAGE_TEXT, p_message_type => 'DEBUG');
         
      END IF;
      
   END debug;

   
-- +========================================================================+
-- | Name        :  WRITE                                                   |
-- |                                                                        |
-- | Description :  Writes a message to the output buffer regardless        |
-- |                the value for profile option AS_DEBUG.                  |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_message_text IN VARCHAR2                              |
-- |                p_message_type IN VARCHAR2                              |
-- |                                                                        |
-- +========================================================================+
     
   PROCEDURE write ( p_message_text IN VARCHAR2
                    ,p_message_type IN VARCHAR2
                   )
   IS
      PROFILE   NUMBER;
      
   BEGIN
   
      push (p_message_text      => p_message_text,
            p_message_type      => p_message_type
           );
           
   END write;

-- +========================================================================+
-- | Name        :  SET_NAME                                                |
-- |                                                                        |
-- | Description :  Puts an "encoded" message name on the stack, marked     |
-- |                for translation.                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                appl_short_name   IN  VARCHAR2                          |
-- |                message_name      IN VARCHAR2                           |
-- |                indent            IN NUMBER                             |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE set_name (
                        appl_short_name   IN  VARCHAR2,
                        message_name      IN VARCHAR2,
                        indent            IN NUMBER
                      )
   IS
      indent_value   NUMBER (2);
      
   BEGIN
      g_msg_count := g_msg_count + 1;
      g_msg_stack (g_msg_count) := appl_short_name || ' ' || message_name;
      g_msg_type_stack (g_msg_count) := 'TRANSLATE';
      g_msg_date_stack (g_msg_count) := SYSDATE;

      IF indent IS NOT NULL
      THEN
         IF indent = 0
         THEN
            indent_value := g_indent0;
         ELSIF indent = 1
         THEN
            indent_value := g_indent1;
         ELSIF indent = 2
         THEN
            indent_value := g_indent2;
         ELSIF indent = 3
         THEN
            indent_value := g_indent3;
         ELSIF indent = 4
         THEN
            indent_value := g_indent4;
         ELSIF indent = 5
         THEN
            indent_value := g_indent5;
         END IF;

         set_token ('INDENT', indent_value, FALSE);
      END IF;
      
   END set_name;

  
  
-- +========================================================================+
-- | Name        :  SET_TOKEN                                               |
-- |                                                                        |
-- | Description :  Append Token Information to the current message on the  |
-- |                stack. The current message must be of type 'TRANSLATE'  |
-- |                for this to work properly when the message is translated| 
-- |                on the client,although no serious errors will occur.    |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                token_name    IN   VARCHAR2                             |
-- |                token_value   IN   VARCHAR2                             |
-- |                translate     IN   BOOLEAN                              |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE set_token (
                        token_name    IN   VARCHAR2,
                        token_value   IN   VARCHAR2,
                        translate     IN   BOOLEAN
                       )
   IS
      trans_label   VARCHAR2 (5);
   BEGIN
      IF TRANSLATE
      THEN
         trans_label := 'TRUE';
      ELSE
         trans_label := 'FALSE';
      END IF;

      g_msg_stack (g_msg_count) :=
            g_msg_stack (g_msg_count)
         || ' '
         || token_name
         || ' \"'
         || token_value
         || '\" '
         || trans_label;
         
   END set_token;

-- +========================================================================+
-- | Name        :  FLUSH                                                   |
-- |                                                                        |
-- | Description :  Flush all messages (debug and translatable) off the     |
-- |                stack(FIFO) into the table                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE flush
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      TYPE numlist IS TABLE OF NUMBER (15)
         INDEX BY BINARY_INTEGER;

      seq_key   numlist;
      counter   NUMBER  := 1;
   BEGIN
      -- Build sequence collection
      FOR i IN 1 .. g_msg_count
      LOOP
         SELECT xx_cn_process_audit_lines_s.NEXTVAL
           INTO seq_key (i)
           FROM DUAL;
      END LOOP;

      FORALL i IN 1 .. g_msg_count
         INSERT INTO xx_cn_process_audit_lines
                     (process_audit_id, process_audit_line_id,
                      MESSAGE_TEXT,
                      message_type_code, creation_date,org_id
                     )
              VALUES (g_process_audit_id, seq_key (i),
                      SUBSTRB (g_msg_stack (i), 1, 239),
                      g_msg_type_stack (i), g_msg_date_stack (i),
                 fnd_global.org_id
                     );
      COMMIT;
      CLEAR;   -- We've flushed the messages into the table so clear the stack
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         DEBUG ('cn_message.insert_audit_line : ' || SQLCODE || SQLERRM);
         COMMIT;
   END FLUSH;

-- +========================================================================+
-- | Name        :  END_BATCH                                               |
-- |                                                                        |
-- | Description :  To end the given process audit batch                    |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_process_audit_id IN NUMBER                            |
-- |                                                                        |
-- +========================================================================+
  
   PROCEDURE end_batch (p_process_audit_id IN NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      FLUSH;
     
      UPDATE xx_cn_process_audits
         SET timestamp_end = SYSDATE
       WHERE process_audit_id = p_process_audit_id;
      
      COMMIT;
      
   END end_batch;

  
  
-- +========================================================================+
-- | Name        :  SET_ERROR                                               |
-- |                                                                        |
-- | Description :  To set the error message type                           |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                routine IN VARCHAR2                                     |
-- |                context IN VARCHAR2                                     |
-- |                                                                        |
-- +========================================================================+
   
   PROCEDURE set_error ( routine IN VARCHAR2
                        ,context IN VARCHAR2
                       )
   IS
      delimiter1   VARCHAR2 (3);
      delimiter2   VARCHAR2 (3);
   BEGIN
      IF routine IS NOT NULL
      THEN
         delimiter1 := ' : ';
      END IF;

      IF CONTEXT IS NOT NULL
      THEN
         delimiter2 := ' : ';
      END IF;

      push (p_message_text      =>    routine
                                   || delimiter1
                                   || CONTEXT
                                   || delimiter2
                                   || SQLCODE
                                   || SQLERRM,
            p_message_type      => 'ERROR'
           );
   END set_error;

-- +========================================================================+
-- | Name        :  CLEAR                                                   |
-- |                                                                        |
-- | Description :  Frees memory used the the Message Stacks and resets the |
-- |                the Message Stack counter and pointer variables.        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                                                                        |
-- +========================================================================+

   PROCEDURE clear
   IS
   BEGIN
      g_msg_stack := g_msg_stack_empty;
      
      g_msg_type_stack := g_msg_type_stack_empty;
      
      g_msg_date_stack := g_msg_date_stack_empty;
      
      g_msg_count := 0;
      
      g_msg_ptr := 1;
      
   END clear;

-- +========================================================================+
-- | Name        :  PURGE                                                   |
-- |                                                                        |
-- | Description :  Delete the contents of cn_messages by batch_id or by    |
-- |                creation date.                                          |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_process_audit_id IN NUMBER                            |
-- |                p_creation_date    IN DATE                              |   
-- |                                                                        |   
-- |                                                                        |   
-- +========================================================================+   
     
   PROCEDURE purge ( p_process_audit_id IN NUMBER
                    ,p_creation_date    IN DATE
                   )
   IS
   BEGIN
      IF p_process_audit_id IS NOT NULL
      THEN
      
         DELETE FROM xx_cn_process_audit_lines
               WHERE process_audit_id = p_process_audit_id;

         DELETE FROM xx_cn_process_audits
               WHERE process_audit_id = p_process_audit_id;
               
      ELSIF p_creation_date IS NOT NULL
      THEN
      
         DELETE FROM xx_cn_process_audit_lines
               WHERE creation_date <= p_creation_date;

         DELETE FROM xx_cn_process_audits
               WHERE creation_date <= p_creation_date;
               
      END IF;
      
   END purge;


-- +========================================================================+
-- | Name        :  BEGIN_BATCH                                             |
-- |                                                                        |
-- | Description :  Prepare the stacks and insert the batch record.         | 
-- |                Retrive the batch id to be passe                        | 
-- |                                                                        | 
-- | Parameters  :                                                          | 
-- |                p_parent_proc_audit_id   IN NUMBER,                     | 
-- |                x_process_audit_id       IN OUT NOCOPY NUMBER,          | 
-- |                p_request_id             IN NUMBER,                     | 
-- |                p_process_type           IN VARCHAR2,                   | 
-- |                p_description            IN VARCHAR2                    | 
-- |                                                                        | 
-- +========================================================================+ 
   
   PROCEDURE begin_batch (
                           p_parent_proc_audit_id   IN NUMBER,
                           x_process_audit_id       IN OUT NOCOPY NUMBER,
                           p_request_id             IN NUMBER,
                           p_process_type           IN VARCHAR2,
                           p_description            IN VARCHAR2
                        )
   IS
   BEGIN
   
      CLEAR;
      
      g_cn_debug := fnd_profile.VALUE ('CN_DEBUG');
      
      ins_audit_batch ( p_parent_proc_audit_id,
                        x_process_audit_id,
                        p_request_id,
                        p_process_type,
                        p_description
                      );
                      
   END begin_batch;
   
   
   
-- +========================================================================+
-- | Name        :  ROLLBACK_ERRORMSG_COMMIT                                |
-- |                                                                        |
-- | Description :  To roll back the error message table                    |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_error_context                                         |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE rollback_errormsg_commit (p_error_context VARCHAR2)
   IS
      delimiter   VARCHAR2 (3) := ' : ';
   BEGIN
   
      ROLLBACK;
      
      DEBUG (p_error_context || delimiter || SQLCODE || SQLERRM);
      
      FLUSH;
   
   END rollback_errormsg_commit;

-- +========================================================================+
-- | Name        :  UPDATE_BATCH                                            |
-- |                                                                        |
-- | Description :  This procedure to update the process audit batch table  |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_process_audit_id                                      |
-- |                p_execution_code                                        |
-- |                p_error_message                                         |
-- |                                                                        |
-- |                                                                        |
-- +========================================================================+

   PROCEDURE update_batch (
                             p_process_audit_id   cn_process_audits.process_audit_id%TYPE,
                             p_execution_code     cn_process_audits.execution_code%TYPE,
                             p_error_message      cn_process_audits.error_message%TYPE
                          )
   IS PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
   
      UPDATE xx_cn_process_audits XCPA
         SET XCPA.timestamp_end     = SYSDATE,
             XCPA.execution_code    = p_execution_code,
             XCPA.error_message     = p_error_message
       WHERE XCPA.process_audit_id  = p_process_audit_id;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
      
      COMMIT;
   
   END update_batch;

-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_prog_name IN VARCHAR2                                 |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE log_error (
                         p_prog_name   IN   VARCHAR2,
                         p_prog_type   IN   VARCHAR2,
                         p_prog_id     IN   NUMBER,
                         p_exception   IN   VARCHAR2,
                         p_message     IN   VARCHAR2,
                         p_code        IN   NUMBER,
                         p_err_code    IN   VARCHAR2
                       )
   IS
   
   lc_severity   VARCHAR2 (15) := NULL;
      
   BEGIN
      IF p_code = -1
      THEN
         lc_severity := g_major;
         
      ELSIF p_code = 1
      THEN
         lc_severity := g_minor;
         
      END IF;

      xx_com_error_log_pub.log_error (p_program_type                => p_prog_type,
                                      p_program_name                => p_prog_name,
                                      p_program_id                  => p_prog_id, 
                                      p_module_name                 => g_module_name,
                                      p_error_location              => p_exception,
                                      p_error_message_code          => p_err_code,
                                      p_error_message               => p_message,
                                      p_error_message_severity      => lc_severity,
                                      p_notify_flag                 => g_notify,
                                      p_error_status                => g_error_status
                                     );
   END log_error;

-- +===================================================================+
-- | Name        :  DISPLAY_LOG                                        |
-- | Description :  This procedure is invoked to print in the log file |
-- | Parameters  :  p_message IN VARCHAR2                              |
-- |                p_optional IN NUMBER                               |
-- +===================================================================+
 
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   
   BEGIN
   
      FND_FILE.put_line (FND_FILE.LOG, p_message);
      
   END display_log;

-- +====================================================================+
-- | Name        :  DISPLAY_OUT                                         |
-- | Description :  This procedure is invoked to print in the Output    |
-- |                file                                                |
-- | Parameters  :  p_message IN VARCHAR2                               |
-- +====================================================================+

   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   
   BEGIN
   
      FND_FILE.put_line (FND_FILE.output, p_message);
      
   END display_out;     
   
   
   
-- +========================================================================+
-- | Name        :  XX_CN_GET_DIVISION                                      |
-- |                                                                        |
-- | Description : This procedure is to derive the division and revenue     |
-- |               class id based on class,department,private brand flag,   |
-- |               order source and collection source.                      | 
-- |                                                                        |
-- | Parameters  : p_dept_code        IN VARCHAR2                           |
-- |               p_class_code       IN VARCHAR2                           | 
-- |               p_order_source     IN VARCHAR2                           |
-- |               p_collect_source   IN VARCHAR2                           |
-- |               p_private_brand    IN VARCHAR2                           |
-- |               x_division         OUT NOCOPY VARCHAR2                   |
-- |               x_rev_class_id     OUT NOCOPY NUMBER                     |
-- |                                                                        |
-- +========================================================================+


   PROCEDURE xx_cn_get_division (
                                 p_dept_code        IN VARCHAR2,
                                 p_class_code       IN VARCHAR2,
                                 p_order_source     IN VARCHAR2,
                                 p_collect_source   IN VARCHAR2,
                                 p_private_brand    IN VARCHAR2,
                                 x_division         OUT NOCOPY VARCHAR2,
                                 x_rev_class_id     OUT NOCOPY NUMBER
                                )
   IS
   ln_count             NUMBER;
   lc_dept_code         xx_cn_rev_class.department%TYPE;
   lc_class_code        xx_cn_rev_class.class%TYPE;
   lc_order_source      xx_cn_rev_class.order_source%TYPE;
   lc_collect_source    xx_cn_rev_class.collection_source%TYPE;
   BEGIN
      SELECT COUNT(1) 
        INTO ln_count
        FROM xx_cn_rev_class
       WHERE department = p_dept_code;
      
      IF(ln_count=0)
      THEN
        lc_dept_code := 'Any';
      ELSE
        lc_dept_code := p_dept_code;
      END IF;
      
      SELECT COUNT(1) 
        INTO ln_count
        FROM xx_cn_rev_class
       WHERE class = p_class_code;
      
      IF(ln_count=0)
      THEN
        lc_class_code := 'Any';
      ELSE 
        lc_class_code := p_class_code;
      END IF;
      
      SELECT COUNT(1) 
        INTO ln_count
        FROM xx_cn_rev_class
       WHERE order_source = p_order_source;
      
      IF(ln_count=0)
      THEN
        lc_order_source := 'Any';
      ELSE
        lc_order_source := p_order_source;
      END IF;
      
      SELECT COUNT(1) 
        INTO ln_count
        FROM xx_cn_rev_class
       WHERE collection_source = p_collect_source;
      
      IF(ln_count=0)
      THEN
        lc_collect_source := 'Any';
      ELSE
        lc_collect_source := p_collect_source;
      END IF; 
   
      SELECT  XCRC.division
             ,XCRC.revenue_class_id
        INTO  x_division
             ,x_rev_class_id
        FROM  xx_cn_rev_class  XCRC
       WHERE  XCRC.department = lc_dept_code
         AND  XCRC.class      = lc_class_code
         AND  XCRC.order_source = lc_order_source
         AND  XCRC.collection_source = lc_collect_source
         AND  XCRC.private_brand_flag = p_private_brand;
         
         
   EXCEPTION
   
      WHEN OTHERS THEN
         x_division     := null;
         x_rev_class_id := null;
   END;
   
END xx_cn_util_pkg;
/

SHOW ERRORS

EXIT;
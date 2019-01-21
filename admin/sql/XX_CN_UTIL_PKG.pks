CREATE OR REPLACE PACKAGE xx_cn_util_pkg AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                 Oracle NAIO/Consulting Organization                            |
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
-- |1.0      07-NOV-2007 Hema Chikkanna             Modified the log_error procedure|
-- |                                                as per onsite Requirement       |
-- |1.1      12-NOV-2007 Hema Chikkanna             Included g_process_audit_id     |
-- |                                                variables for error logging.    |
-- |1.2      13-NOV-2007 Sarah Maria Justina        Changed Log_error specification |
-- +================================================================================+
   g_process_audit_id       NUMBER;
   -------------------------------------------------------------------------------------
   -- Name
   --   set_messages     
   --
   -- Purpose
   --   Cover routine combining set_name and set_token
   --
   -- Notes
   --   Should be able to make set_name/token private leaving this one visible
   -------------------------------------------------------------------------------------
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
      TRANSLATE         IN   BOOLEAN
   );

   -------------------------------------------------------------------------------------
   -- Name
   --   Flush
   --
   -- Purpose
   --   Flush all session messages off the stack and into the table cn_messages
   -------------------------------------------------------------------------------------
   
   PROCEDURE FLUSH;
   
   
   -------------------------------------------------------------------------------------
   -- Name
   --   ins_audit_batch
   --
   -- Purpose
   --   Insert record into xx_cn_process_audits table
   -------------------------------------------------------------------------------------
   PROCEDURE ins_audit_batch (
      p_parent_proc_audit_id                   NUMBER,
      x_process_audit_id       IN OUT NOCOPY   NUMBER,
      p_request_id                             NUMBER,
      p_process_type                           VARCHAR2,
      p_description                            VARCHAR2
   );
   
   ------------------------------------------------------------------------------------- 
   --
   -- NAME
   --   Debug
   --
   -- PURPOSE
   --   Writes a non-translated message to the output buffer only when
   --   the value for profile option AS_DEBUG = 'Y' or is NULL.
   --
   -------------------------------------------------------------------------------------
   PROCEDURE DEBUG (MESSAGE_TEXT IN VARCHAR2);

   -------------------------------------------------------------------------------------
   --
   -- NAME
   --   write
   --
   -- PURPOSE
   --   Writes a message to the output buffer regardless
   --   the value for profile option AS_DEBUG
   --
   -------------------------------------------------------------------------------------
   PROCEDURE WRITE (p_message_text IN VARCHAR2, p_message_type IN VARCHAR2);

   
   -------------------------------------------------------------------------------------
   -- Name
   --   Set_Name
   --
   -- Purpose
   --   Puts a Message Dictionary message on the message stack.
   --   (Same syntax as FND_MESSAGE.Set_Name)
   -------------------------------------------------------------------------------------
   PROCEDURE set_name (
      appl_short_name   VARCHAR2 DEFAULT 'CN',
      message_name      VARCHAR2,
      indent            NUMBER DEFAULT NULL
   );

   -------------------------------------------------------------------------------------
   -- Name
   --   Set_Token
   --
   -- Purpose
   --   Sets the token of the current message on the message stack.
   --   (Same syntax as FND_MESSAGE.Set_Token
   -------------------------------------------------------------------------------------
   PROCEDURE set_token (
      token_name    VARCHAR2,
      token_value   VARCHAR2,
      TRANSLATE     BOOLEAN DEFAULT FALSE
   );

   -------------------------------------------------------------------------------------
   -- Name
   --   Set_Error
   --
   -- Purpose
   --   Writes the error message of the most recently encountered
   --   Oracle Error to the output buffer.
   --
   -- Arguments
   --   Routine     The name of the routine where the Oracle Error
   --         occured. (Optional)
   --   Context     Any context information relating to the error
   --         (e.g. Customer_Id) (Optional)
   -------------------------------------------------------------------------------------
   PROCEDURE set_error (
      routine   VARCHAR2 DEFAULT NULL,
      CONTEXT   VARCHAR2 DEFAULT NULL
   );

   -------------------------------------------------------------------------------------
   -- NAME
   --   Clear
   --
   -- PURPOSE
   --   Clears the message stack and frees memory used by it.
   -------------------------------------------------------------------------------------
   PROCEDURE CLEAR;

   -------------------------------------------------------------------------------------
   -- NAME
   --   Purge
   --
   -- PURPOSE
   --   Delete messages for a given bacth id or forward from a particular date
   -------------------------------------------------------------------------------------
   PROCEDURE PURGE (p_process_audit_id NUMBER, p_creation_date DATE);
   
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   begin_batch
   --
   -- PURPOSE
   --   To begin a new process batch
   -------------------------------------------------------------------------------------

   PROCEDURE begin_batch (
                           p_parent_proc_audit_id                   NUMBER,
                           x_process_audit_id       IN OUT NOCOPY   NUMBER,
                           p_request_id                             NUMBER,
                           p_process_type                           VARCHAR2,
                           p_description                            VARCHAR2
                        );


   -------------------------------------------------------------------------------------
   -- NAME
   --   end_batch
   --
   -- PURPOSE
   --   To end a process batch
   -------------------------------------------------------------------------------------
   PROCEDURE end_batch (p_process_audit_id NUMBER);
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   rollback_errormsg_commit
   --
   -- PURPOSE
   --   To undo the changes to error messages commit
   -------------------------------------------------------------------------------------
   PROCEDURE rollback_errormsg_commit (p_error_context VARCHAR2);
   
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   update_batch
   --
   -- PURPOSE
   --   To update the process audit batch
   -------------------------------------------------------------------------------------

   PROCEDURE update_batch (
                            p_process_audit_id   cn_process_audits.process_audit_id%TYPE,
                            p_execution_code     cn_process_audits.execution_code%TYPE,
                            p_error_message      cn_process_audits.error_message%TYPE
                          );
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   log_error
   --
   -- PURPOSE
   --   To log the errro into xx_comm_error_log table
   -------------------------------------------------------------------------------------
   PROCEDURE log_error (
                         p_prog_name     IN   VARCHAR2,
                         p_prog_type     IN   VARCHAR2,
                         p_prog_id       IN   NUMBER,
                         p_exception     IN   VARCHAR2,
                         p_message       IN   VARCHAR2,
                         p_code          IN   NUMBER,
                         p_err_code      IN   VARCHAR2
                       );
                       
   -------------------------------------------------------------------------------------                    
   -- NAME
   --   display_log
   --
   -- PURPOSE
   --   To display the message in concurrent log file
   -------------------------------------------------------------------------------------

   PROCEDURE display_log (p_message IN VARCHAR2);
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   display_out
   --
   -- PURPOSE
   --   To display the message in concurrent output file
   -------------------------------------------------------------------------------------
   PROCEDURE display_out (p_message IN VARCHAR2);
   
   -------------------------------------------------------------------------------------
   -- NAME
   --   xx_cn_get_division
   --
   -- PURPOSE
   --   To derive the division and revenue class id based on class,department
   --   private brand flag,order source and collection source.
   -------------------------------------------------------------------------------------
   PROCEDURE xx_cn_get_division (
                                 p_dept_code        IN VARCHAR2,
                                 p_class_code       IN VARCHAR2,
                                 p_order_source     IN VARCHAR2,
                                 p_collect_source   IN VARCHAR2,
                                 p_private_brand    IN VARCHAR2,
                                 x_division         OUT NOCOPY VARCHAR2,
                                 x_rev_class_id     OUT NOCOPY NUMBER
                                );
END xx_cn_util_pkg;
/

SHOW ERRORS

EXIT;

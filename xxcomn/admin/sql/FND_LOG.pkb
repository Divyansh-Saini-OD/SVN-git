create or replace package body FND_LOG as
/* $Header: AFUTLOGB.pls 120.5.12010000.3 2010/03/17 17:29:22 pferguso ship $ */
   /* Documentation for this package is at */
   /* http://www-apps.us.oracle.com/logging/ */

   /*
   ** EXCEPTIONS
   */
   bad_parameter EXCEPTION;
   PRAGMA EXCEPTION_INIT(bad_parameter, -06501); -- program error

   /*
   ** PACKAGE VARIABLES
   */
/* Removing these from pkg body as they already exist in spec. 10.1.0.4 throws
   error in case of duplicate definition

   LEVEL_UNEXPECTED CONSTANT NUMBER  := 6;
   LEVEL_ERROR      CONSTANT NUMBER  := 5;
   LEVEL_EXCEPTION  CONSTANT NUMBER  := 4;
   LEVEL_EVENT      CONSTANT NUMBER  := 3;
   LEVEL_PROCEDURE  CONSTANT NUMBER  := 2;
   LEVEL_STATEMENT  CONSTANT NUMBER  := 1;
*/
   /* Message buffer */
   internal_messages VARCHAR2(10000);

   /*
   ** PRIVATE PROCEDURES
   */

   /* Set the contents of the message buffer */
   procedure INTERNAL_MESSAGE(msg VARCHAR2) IS
   begin
      internal_messages := internal_messages || msg || fnd_global.newline;
   end;

   /* Set error message and raise exception for unexpected sql errors */

   procedure GENERIC_ERROR(routine in varchar2,
                           errcode in number,
                           errmsg in varchar2) is
   begin
       fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
       fnd_message.set_token('ROUTINE', routine);
       fnd_message.set_token('ERRNO', errcode);
       fnd_message.set_token('REASON', errmsg);
       app_exception.raise_exception;
   end;



   FUNCTION STR_UNCHKED_INT_WITH_CONTEXT(
                    LOG_LEVEL       IN NUMBER,
                    MODULE          IN VARCHAR2,
                    MESSAGE_TEXT    IN VARCHAR2,
                    ENCODED         IN VARCHAR2 DEFAULT 'N',
                    NODE            IN VARCHAR2 DEFAULT NULL,
                    NODE_IP_ADDRESS IN VARCHAR2 DEFAULT NULL,
                    PROCESS_ID      IN VARCHAR2 DEFAULT NULL,
                    JVM_ID          IN VARCHAR2 DEFAULT NULL,
                    THREAD_ID       IN VARCHAR2 DEFAULT NULL,
                    AUDSID          IN NUMBER   DEFAULT NULL,
                    DB_INSTANCE     IN NUMBER   DEFAULT NULL) RETURN NUMBER is

   CALL_STACK   VARCHAR2(4000) := NULL;
   ERR_STACK    VARCHAR2(4000) := NULL;
   l_seq        NUMBER;

   begin

      if (LOG_LEVEL >= FND_LOG.LEVEL_EXCEPTION) THEN
           CALL_STACK := DBMS_UTILITY.FORMAT_CALL_STACK;
           ERR_STACK := DBMS_UTILITY.FORMAT_ERROR_STACK;
      end if;

      l_seq := FND_LOG_REPOSITORY.STR_UNCHKED_INT_WITH_CONTEXT(
                      LOG_LEVEL       => LOG_LEVEL,
                      MODULE          => MODULE,
                      MESSAGE_TEXT    => MESSAGE_TEXT,
                      ENCODED         => ENCODED,
                      NODE            => NODE,
                      NODE_IP_ADDRESS => NODE_IP_ADDRESS,
                      PROCESS_ID      => PROCESS_ID,
                      JVM_ID          => JVM_ID,
                      THREAD_ID       => THREAD_ID,
                      AUDSID          => AUDSID,
                      DB_INSTANCE     => DB_INSTANCE,
                      CALL_STACK      => CALL_STACK,
                      ERR_STACK       => ERR_STACK);

      return l_seq;

   end;



   /*
   ** PUBLIC PROCEDURES
   */

   /*
   ** FND_LOG.INIT_TRANSACTION
   **
   ** Description:
   ** Initializes a log transaction.  A log transaction
   ** corresponds to an instance or invocation of a single
   ** component.  (e.g. A concurrent request, service process,
   ** open form, ICX function)
   **
   ** This routine should be called only after
   ** FND_GLOBAL.INITIALIZE, since some of the context information
   ** is retrieved from FND_GLOBAL.
   **
   ** Arguments:
   **   CONC_REQUEST_ID       - Concurrent request id
   **   FORM_ID               - Form id
   **   FORM_APPLICATION_ID   - Form application id
   **   CONCURRENT_PROCESS_ID - Service process id
   **   CONCURRENT_QUEUE_ID   - Service queue id
   **   QUEUE_APPLICATION_ID  - Service queue application id
   **   SOA_INSTANCE_ID       - SOA instance id
   **
   ** Use only the arguments that apply to the caller.
   ** Any argument that does not apply should be passed as NULL
   ** i.e. when calling from a form, pass in FORM_ID and FORM_APPLICATION_ID
   ** and leave all other parameters NULL.
   **
   ** Returns:
   **   ID of the log transaction context
   **
   */
   FUNCTION INIT_TRANSACTION (CONC_REQUEST_ID             IN NUMBER DEFAULT NULL,
                              FORM_ID                     IN NUMBER DEFAULT NULL,
                              FORM_APPLICATION_ID         IN NUMBER DEFAULT NULL,
                              CONCURRENT_PROCESS_ID       IN NUMBER DEFAULT NULL,
                              CONCURRENT_QUEUE_ID         IN NUMBER DEFAULT NULL,
                              QUEUE_APPLICATION_ID        IN NUMBER DEFAULT NULL,
			                        SOA_INSTANCE_ID             IN NUMBER DEFAULT NULL)
                                                          return NUMBER is

   l_transaction_context_id   number;
   -- new variable
   lc_soa_fnd_debug_level     fnd_profile_option_values.profile_option_value%type;

   begin
 
     ---------------------------------------------------
     -- SOA ADAPTER DECOUPLING - START -- Defect # 35946
     ---------------------------------------------------
     IF SOA_INSTANCE_ID IS NOT NULL THEN
        
        BEGIN
           lc_soa_fnd_debug_level := NULL;
           
           -- Retrieve OD: SOA FND Debug profile option value (new custom profile option)
           FND_PROFILE.GET('XX_SOA_FND_DEBUG', lc_soa_fnd_debug_level); 
        
           -- Validate Custom Profile and Set FND Debug
           IF lc_soa_fnd_debug_level IS NULL THEN
           xx_com_error_log_pub.log_error( p_module_name           => 'FND',
                                           p_program_name          => 'FND_LOG',                                                  
                                           p_error_location        => 'INIT_TRANSACTION',
                                           p_error_message         => 'Custom profile option does not exist',
                                           p_error_status          => 'LOG',
                                           p_creation_date         => sysdate,
                                           p_last_update_date      => sysdate);
           ELSE   
              -- Set FND Debug profile option value to same value as OD: SOA FND Debug
              FND_PROFILE.PUT('AFLOG_LEVEL', lc_soa_fnd_debug_level);  -- change to FND Debug level SITE value
           END IF;          
    
        EXCEPTION
           WHEN OTHERS THEN
              xx_com_error_log_pub.log_error( p_module_name           => 'FND',
                                              p_program_name          => 'FND_LOG',
                                              p_error_location        => 'INIT_TRANSACTION',
                                              p_error_message         => 'Exception in WHEN OTHERS : Unable to decouple SOA adapter logging',
                                              p_error_status          => 'EXCEPTION',
                                              p_creation_date         => sysdate,
                                              p_last_update_date      => sysdate);
        END;   
    
     END IF;
     ---------------------------------------------------
     -- SOA ADAPTER DECOUPLING - END   -- Defect # 35946
     ---------------------------------------------------
     
     l_transaction_context_id :=
               FND_LOG_REPOSITORY.INIT_TRANS_INT_WITH_CONTEXT(
                                     CONC_REQUEST_ID       => CONC_REQUEST_ID,
                                     FORM_ID               => FORM_ID,
                                     FORM_APPLICATION_ID   => FORM_APPLICATION_ID,
	                                   CONCURRENT_PROCESS_ID => CONCURRENT_PROCESS_ID,
                                     CONCURRENT_QUEUE_ID   => CONCURRENT_QUEUE_ID,
                                     QUEUE_APPLICATION_ID  => QUEUE_APPLICATION_ID,
                                     SOA_INSTANCE_ID       => SOA_INSTANCE_ID);
       return l_transaction_context_id;

   exception
       when others then
           generic_error('FND_LOG.INIT_TRANSACTION', SQLCODE, SQLERRM);
           return -1;


   end INIT_TRANSACTION;

   /*
   ** FND_LOG.SET_TRANSACTION
   ** Description:
   **     Sets the log transaction ID for the current DB connection.
   **     This routine should be used whenever the database connection
   **     changes within the context of a transaction.  For example, this
   **     routine will be used for successive hits within the same ICX
   **     transaction or when a concurrent process reconnects to the database.
   **
   ** Arguments:
   **     Log_Transaction
   **
   */
   PROCEDURE SET_TRANSACTION (TRANS_CONTEXT_ID IN NUMBER) is
   dummy number;

   begin

     select count(*)
       into dummy
       from FND_LOG_TRANSACTION_CONTEXT
      where TRANSACTION_CONTEXT_ID = TRANS_CONTEXT_ID;

     if (dummy = 1) then
       FND_LOG.G_TRANSACTION_CONTEXT_ID := TRANS_CONTEXT_ID;
     else
       internal_message('bad TRANSACTION_CONTEXT_ID: '|| TRANS_CONTEXT_ID);
       internal_message('TRANSACTION_CONTEXT_ID not found in table FND_LOG_TRANSACTION_CONTEXT');
       raise bad_parameter;
     end if;

   end SET_TRANSACTION;

   /*
   **  Writes the message to the log file for the spec'd level and module
   **  if logging is enabled for this level and module
   */
   PROCEDURE STRING(LOG_LEVEL IN NUMBER,
                    MODULE    IN VARCHAR2,
                    MESSAGE   IN VARCHAR2) is

   l_seq   number;
   l_message varchar2(4000);

   begin
      /* Short circuit if logging not turned on at this level */
      if (LOG_LEVEL < G_CURRENT_RUNTIME_LEVEL) then
         return;
      end if;

      if FND_LOG_REPOSITORY.CHECK_ACCESS_INTERNAL (MODULE, LOG_LEVEL) then
	 l_message := substrb(MESSAGE,1,4000); --6313496
         l_seq := STR_UNCHKED_INT_WITH_CONTEXT(
                               LOG_LEVEL       => LOG_LEVEL,
                               MODULE          => MODULE,
                               MESSAGE_TEXT    => l_message);
      end if;

      exception
         when others then
	    NULL; /* supress the exception */
   end;

   /*
   **  Writes the message with context information to the log file for
   **  the spec'd level and module if logging is enabled for this level
   **  and module
   */
   PROCEDURE STRING_WITH_CONTEXT(LOG_LEVEL  IN NUMBER,
                      MODULE           IN VARCHAR2,
                      MESSAGE          IN VARCHAR2,
                      ENCODED          IN VARCHAR2 DEFAULT NULL,
                      NODE             IN VARCHAR2 DEFAULT NULL,
                      NODE_IP_ADDRESS  IN VARCHAR2 DEFAULT NULL,
                      PROCESS_ID       IN VARCHAR2 DEFAULT NULL,
                      JVM_ID           IN VARCHAR2 DEFAULT NULL,
                      THREAD_ID        IN VARCHAR2 DEFAULT NULL,
                      AUDSID          IN NUMBER   DEFAULT NULL,
                      DB_INSTANCE     IN NUMBER   DEFAULT NULL) is

   l_seq   number;
   l_message varchar2(4000);

   begin
      /* Short circuit if logging not turned on at this level */
      if (LOG_LEVEL < G_CURRENT_RUNTIME_LEVEL) then
         return;
      end if;

      if FND_LOG_REPOSITORY.CHECK_ACCESS_INTERNAL (MODULE, LOG_LEVEL) then

         l_message:=substrb(MESSAGE,1,4000); --6313496

         l_seq := STR_UNCHKED_INT_WITH_CONTEXT(
                      LOG_LEVEL       => LOG_LEVEL,
                      MODULE          => MODULE,
                      MESSAGE_TEXT    => l_message,
                      ENCODED         => ENCODED,
                      NODE            => NODE,
                      NODE_IP_ADDRESS => NODE_IP_ADDRESS,
                      PROCESS_ID      => PROCESS_ID,
                      JVM_ID          => JVM_ID,
                      THREAD_ID       => THREAD_ID,
                      AUDSID          => AUDSID,
                      DB_INSTANCE     => DB_INSTANCE);
      end if;
   end;

   /*
   ** Internal (private) API that handles all the logic
   */
   FUNCTION MESSAGE_INTERNAL(LOG_LEVEL   IN NUMBER,
                             MODULE      IN VARCHAR2,
                             POP_MESSAGE IN BOOLEAN DEFAULT NULL,
		                         AUTO_LOG    IN VARCHAR2) RETURN NUMBER is
   msg_buf varchar2(32000);
   l_sequence number := -1;
   begin
      /* Short circuit if logging not turned on at this level */
      if (LOG_LEVEL < G_CURRENT_RUNTIME_LEVEL) then
         return l_sequence;
      end if;

      if FND_LOG_REPOSITORY.CHECK_ACCESS_INTERNAL (MODULE, LOG_LEVEL) then
         msg_buf := FND_MESSAGE.GET_ENCODED(AUTO_LOG);
         l_sequence := STR_UNCHKED_INT_WITH_CONTEXT(
                      LOG_LEVEL       => LOG_LEVEL,
                      MODULE          => MODULE,
                      MESSAGE_TEXT    => msg_buf,
                      ENCODED         => 'Y');

	 /* No change in Message Stack if this PROCEDURE is called for Auto-Log = 'Y' */
         if( (AUTO_LOG <> 'Y') and
             ((pop_message = FALSE) OR (pop_message is NULL)) )then
                 FND_MESSAGE.SET_ENCODED(msg_buf);
         end if;
      end if;

      return l_sequence;

      exception
         when others then
            /* supress the exception */
            return l_sequence;
   end;

   /*
   **  Writes a message to the log file if this level and module is enabled
   **  This requires that the message was set previously with
   **  FND_MESSAGE.SET_NAME, SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.  If POP_MESSAGE isn't passed, the
   **  message will not be popped off the stack, so it must be displayed
   **  or explicitly cleared later on.
   */
   PROCEDURE MESSAGE(LOG_LEVEL   IN NUMBER,
                     MODULE      IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL,
                     AUTO_LOG    IN VARCHAR2)
   is
   l_sequence number;
   begin
      l_sequence := MESSAGE_INTERNAL(LOG_LEVEL, MODULE, POP_MESSAGE, AUTO_LOG);
   end;

   PROCEDURE MESSAGE(LOG_LEVEL   IN NUMBER,
                     MODULE IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL)
   is
   begin
      /* Message is already being logged, so AUTO_LOG = 'N' */
      MESSAGE(LOG_LEVEL, MODULE, POP_MESSAGE, 'N');
   end;

   /*
   **  Writes a message to the log file if this level and module is enabled
   **  The message gets set previously with FND_MESSAGE.SET_NAME,
   **  SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.
   **  Code Sample:
   **  if( FND_LOG.LEVEL_UNEXPECTED >=
   **     FND_LOG.G_CURRENT_RUNTIME_LEVEL) then
   **    FND_MESSAGE.SET_NAME(...);    -- Set message
   **    FND_MESSAGE.SET_TOKEN(...);   -- Set token in message
   **    ATTACHMENT_ID := FND_LOG.MESSAGE_WITH_ATTACHMENT(FND_LOG.LEVEL_UNEXPECTED,...,TRUE);
   **    if ( ATTACHMENT_ID <> -1 ) then
   **	   -- For ASCII data use WRITE
   **      FND_LOG_ATTACHMENT.WRITE(ATTACHMENT_ID, ...);
   **	   -- For Non-ASCII data use WRITE_RAW
   **      FND_LOG_ATTACHMENT.WRITE_RAW(ATTACHMENT_ID, ...);
   **      FND_LOG_ATTACHMENT.CLOSE(ATTACHMENT_ID);
   **    end if;
   **  end if;
   */
   FUNCTION MESSAGE_WITH_ATTACHMENT(LOG_LEVEL   IN NUMBER,
                     MODULE      IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL,
                     P_CHARSET IN VARCHAR2 DEFAULT 'ascii',
                     P_MIMETYPE IN VARCHAR2 DEFAULT 'text/html',
                     P_ENCODING IN VARCHAR2 DEFAULT NULL,
                     P_LANG IN VARCHAR2 DEFAULT NULL,
                     P_FILE_EXTN IN VARCHAR2 DEFAULT 'txt',
                     P_DESC IN VARCHAR2 DEFAULT NULL) RETURN NUMBER is
   l_sequence number := -1;
   begin
     l_sequence := MESSAGE_INTERNAL(LOG_LEVEL, MODULE, POP_MESSAGE, 'N');
     if ( l_sequence > 0 ) then
       FND_LOG_REPOSITORY.INSERT_BLOB(l_sequence, P_CHARSET, P_MIMETYPE,
			P_ENCODING, P_LANG, P_FILE_EXTN, P_DESC);
     end if;
     return l_sequence;
   end;

   /*
   **  Writes a message with context to the log file if this level and
   **  module is enabled.  This requires that the message was set
   **  previously with FND_MESSAGE.SET_NAME, SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.  If POP_MESSAGE isn't passed, the
   **  message will not be popped off the stack, so it must be displayed
   **  or explicitly cleared later on.
   */
   PROCEDURE MESSAGE_WITH_CONTEXT(LOG_LEVEL IN NUMBER,
                      MODULE           IN VARCHAR2,
                      POP_MESSAGE      IN BOOLEAN DEFAULT NULL, --Default FALSE
                      NODE             IN VARCHAR2 DEFAULT NULL,
                      NODE_IP_ADDRESS  IN VARCHAR2 DEFAULT NULL,
                      PROCESS_ID       IN VARCHAR2 DEFAULT NULL,
                      JVM_ID           IN VARCHAR2 DEFAULT NULL,
                      THREAD_ID        IN VARCHAR2 DEFAULT NULL,
                      AUDSID          IN NUMBER   DEFAULT NULL,
                      DB_INSTANCE     IN NUMBER   DEFAULT NULL) is
   msg_buf varchar2(32000);
   l_seq   number;
   begin
      /* Short circuit if logging not turned on at this level */
      if (LOG_LEVEL < G_CURRENT_RUNTIME_LEVEL) then
         return;
      end if;

      if FND_LOG_REPOSITORY.CHECK_ACCESS_INTERNAL (MODULE, LOG_LEVEL) then
         msg_buf := FND_MESSAGE.GET_ENCODED;

         l_seq := STR_UNCHKED_INT_WITH_CONTEXT(
                      LOG_LEVEL       => LOG_LEVEL,
                      MODULE          => MODULE,
                      MESSAGE_TEXT    => msg_buf,
                      ENCODED         => 'Y',
                      NODE            => NODE,
                      NODE_IP_ADDRESS => NODE_IP_ADDRESS,
                      PROCESS_ID      => PROCESS_ID,
                      JVM_ID          => JVM_ID,
                      THREAD_ID       => THREAD_ID,
                      AUDSID          => AUDSID,
                      DB_INSTANCE     => DB_INSTANCE);
         if((pop_message = FALSE) OR (pop_message is NULL))then
            FND_MESSAGE.SET_ENCODED(msg_buf);
         end if;

      end if;
   end;


   /*
   ** FND_LOG.WORK_METRIC
   ** Description:
   **     Writes a metric value out to the FND tables in an
   **     autonomous transaction.  Posting to the Business Event
   **     system is deferred until WORK_METRICS_EVENT is called.
   **
   ** Arguments:
   **     Module       - Module name (See FND_LOG standards.)
   **     Metric_code  - Internal name of metric.
   **     Metric_value - Value for metric (string, number, or date)
   **
   */

   procedure WORK_METRIC (MODULE       IN VARCHAR2,
                     METRIC_CODE  IN VARCHAR2,
                     METRIC_VALUE IN VARCHAR2) is

   begin
     FND_LOG_REPOSITORY.METRIC_INTERNAL_WITH_CONTEXT(
                                       MODULE              => MODULE,
                                       METRIC_CODE         => METRIC_CODE,
                                       METRIC_VALUE_STRING => METRIC_VALUE);
   end WORK_METRIC;

   procedure WORK_METRIC (MODULE       IN VARCHAR2,
                     METRIC_CODE  IN VARCHAR2,
                     METRIC_VALUE IN NUMBER) is

   begin
     FND_LOG_REPOSITORY.METRIC_INTERNAL_WITH_CONTEXT(
                                       MODULE              => MODULE,
                                       METRIC_CODE         => METRIC_CODE,
                                       METRIC_VALUE_NUMBER => METRIC_VALUE);
   end WORK_METRIC;

   procedure WORK_METRIC (MODULE       IN VARCHAR2,
                     METRIC_CODE  IN VARCHAR2,
                     METRIC_VALUE IN DATE) is

   begin
     FND_LOG_REPOSITORY.METRIC_INTERNAL_WITH_CONTEXT(
                                       MODULE              => MODULE,
                                       METRIC_CODE         => METRIC_CODE,
                                       METRIC_VALUE_DATE   => METRIC_VALUE);
   end WORK_METRIC;

   /*
   ** FND_LOG.WORK_METRICS_EVENT
   ** Description:
   **     Posts the pending metrics for the current component
   **     session to the Business Event system and updates the pending
   **     metrics with the event key. The metrics will be bundled in an
   **     XML message included in the event.  The event will be named:
   **     "oracle.apps.fnd.system.metrics"
   **
   ** Arguments:
   **     CONTEXT_ID    ID of the context to post the metrics event for.
   **                   Use NULL for the current context.
   */

   PROCEDURE WORK_METRICS_EVENT(CONTEXT_ID IN NUMBER DEFAULT NULL) IS
   begin

      FND_LOG_REPOSITORY.METRICS_EVENT_INT_WITH_CONTEXT(CONTEXT_ID);

   end WORK_METRICS_EVENT;

   /*
   ** FND_LOG.GET_TEXT
   **
   ** Description:
   ** Retrieves the fully translated message text, given a log sequence ID
   **
   ** Arguments:
   **      log_sequence_id   - FND_LOG message identifier.
   **      lang              - Language code for translation (optional).
   **
   ** Returns:
   **      If an encoded message, the full translated text of the message.
   **      If message not encoded, the text of the message as logged.
   **      Returns NULL if the message cannot be found.
   */
   FUNCTION GET_TEXT(LOG_SEQUENCE_ID IN NUMBER,
                     LANG            IN VARCHAR2 DEFAULT NULL
                     ) RETURN  VARCHAR2 is
       --6434437, the tok_val variable was too small
       --I also went ahead and modified msg_text and msg just in case
       --the underlying columns are changed in the future.

       msg_text           fnd_log_messages.message_text%type;
       msg                fnd_new_messages.message_text%type;
       tok_val            fnd_log_messages.message_text%type;


       encoded            varchar2(1);
       msg_app_short_name varchar2(50);
       msg_name           varchar2(30);
       tok_nam            varchar2(30);
       tok_type           varchar2(1);
       srch               varchar2(2000);
       pos                number;
       nextpos            number;
       data_size          number;

   begin


      begin
        select MESSAGE_TEXT, DECODE(ENCODED, 'Y', 'Y', 'N')
          into msg_text, encoded
          from FND_LOG_MESSAGES
         where LOG_SEQUENCE = LOG_SEQUENCE_ID;

        if (encoded = 'N') then
           return msg_text;
        end if;

      exception
        when no_data_found then
          msg_text := '';
          return msg_text;
      end;


      if (LANG is not NULL) then
         begin
           FND_GLOBAL.SET_NLS_CONTEXT(p_nls_language => LANG);
         exception
           when others then
        /*--------------------------------------------------------------+
         | If LANG parameter is bad, set a message then continue in the |
         | language of the current database session.                    |
         +--------------------------------------------------------------*/
            FND_MESSAGE.SET_NAME ('FND', 'SQL-Generic error');
            FND_MESSAGE.SET_TOKEN ('ERRNO', sqlcode, FALSE);
            FND_MESSAGE.SET_TOKEN ('REASON', sqlerrm, FALSE);
            FND_MESSAGE.SET_TOKEN ('ROUTINE', 'FND_LOG.GET_TEXT', FALSE);
         end;
      end if;

      begin
          FND_MESSAGE.PARSE_ENCODED(msg_text,
                                  msg_app_short_name,
                                  msg_name);
          /* GET_STRING with Auto-Log = 'N' */
          msg := FND_MESSAGE.GET_STRING(msg_app_short_name,
                                      msg_name, 'N');
      exception
        when others then
        /*--------------------------------------------------------------+
         | If it this is not really an encoded message, then            |
         | FND_MESSAGE.PARSE_ENCODED may have tried to put entire       |
         | msg_text in msg_app_short_name.                              |
         +--------------------------------------------------------------*/
           return msg_text;
      end;

      /*--------------------------------------------------------------+
      | It seems to be an authentic encoded message.                  |
      +---------------------------------------------------------------*/

        /* Get rid of msg_app_short_name, msg_name     */
        pos := INSTRB(msg_text, chr(0), 1, 2) + 1;
        msg_text := SUBSTRB(msg_text, pos);

        /* Start the same routine from FND_MESSAGE.GET */
        pos := 1;
        data_size := LENGTH(msg_text);
        while pos < data_size loop
            tok_type := SUBSTR(msg_text, pos, 1);
            pos := pos + 2;
            nextpos := INSTR(msg_text, chr(0), pos);
            if (nextpos = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
            tok_nam := SUBSTR(msg_text, pos, nextpos - pos);
            pos := nextpos + 1;
            nextpos := INSTR(msg_text, chr(0), pos);
            if (nextpos = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
            tok_val := SUBSTR(msg_text, pos, nextpos - pos);
            pos := nextpos + 1;

            if (tok_type = 'Y') then  /* translated token */
                /* GET_STRING with Auto-Log = 'N' */
                tok_val := FND_MESSAGE.GET_STRING(msg_app_short_name, tok_val, 'N');
            elsif (tok_type = 'S') then  /* SQL query token */
                tok_val := FND_MESSAGE.FETCH_SQL_TOKEN(tok_val);
            end if;
            srch := '&' || tok_nam;
            if (INSTR(msg, srch) <> 0) then
                msg := SUBSTRB(REPLACE(msg, srch, tok_val),1,2000);
            else
                /* try the uppercased version of the token name in case */
                /* the caller is (wrongly) passing a mixed case token name */
                /* Because begin July 99 all tokens in msg text should be */
                /* uppercase. */
                srch := '&' || UPPER(tok_nam);
                if (INSTR(msg, srch) <> 0) then
                   msg := SUBSTRB(REPLACE(msg, srch, tok_val),1,2000);
                else
                   msg :=SUBSTRB(msg||' ('||tok_nam||'='||tok_val||')',1,2000);
              end if;
            end if;
        end loop;
        /* double ampersands don't have anything to do with tokens, they */
        /* represent access keys.  So we translate them to single ampersands*/
        /* so that the access key code will recognize them. */
        msg := SUBSTRB(REPLACE(msg, '&&', '&'),1,2000);
        return msg;
    end GET_TEXT;

   /*
   ** Tests whether logging is enabled for this level and module, to
   ** avoid the performance penalty of building long debug message
   ** strings unnecessarily.
   */
   FUNCTION TEST(LOG_LEVEL IN NUMBER,
                 MODULE    IN VARCHAR2) RETURN BOOLEAN is
   begin
      if ( LOG_LEVEL < G_CURRENT_RUNTIME_LEVEL ) then
         return FALSE;
      end if;
      return FND_LOG_REPOSITORY.CHECK_ACCESS_INTERNAL (MODULE, LOG_LEVEL);
   end;


    /**
     * Procedure to enable PL/SQL Buffered Logging (for Batch Mode).
     * Caller is responsible for calling RESET_BUFFERED_MODE to flush
     * messages at end. Only messages with log_level < 4 are bufferable.
     * All error messages (log_level >= 4) are logged immediately.
     *
     * Internally reads AFLOG_BUFFER_MODE Profile and if !=0
     * buffers messages in PL/SQL Collection for Bulk-Inserting.
     */
    PROCEDURE SET_BUFFERED_MODE is
    begin
	FND_LOG_REPOSITORY.SET_BUFFERED_MODE;
    end SET_BUFFERED_MODE;

    /**
     * Flushes any buffered messages, and switches back to the
     * default synchronous (non-buffered) logging.
     */
    PROCEDURE RESET_BUFFERED_MODE is
    begin
        FND_LOG_REPOSITORY.RESET_BUFFERED_MODE;
    end RESET_BUFFERED_MODE;

    /**
     * API for raising a proxy alert on behalf of the given
     * concurrent request. The transaction context for the alert is set to
     * that of the given request ID. The current transaction context is also
     * captured as a parent context.
     *
     * This API does the following:
     * 1) Sets a child context for the given request ID
     * 2) Raises the proxy alert by calling fnd_log.message in the normal
     *    fashion
     * 3) Clears the child context.
     */
    PROCEDURE PROXY_ALERT_FOR_CONC_REQ(
	MODULE IN VARCHAR2,
	POP_MESSAGE IN BOOLEAN DEFAULT NULL,
	REQUEST_ID IN NUMBER) is
    BEGIN
	if (fnd_log.level_unexpected >= fnd_log.g_current_runtime_level) then
		fnd_log_repository.set_child_context_for_conc_req(REQUEST_ID);
		fnd_log.message(
		  log_level => fnd_log.level_unexpected,
		  module => MODULE,
		  pop_message => POP_MESSAGE);
		fnd_log_repository.clear_child_context;
        end if;
    END PROXY_ALERT_FOR_CONC_REQ;

end FND_LOG;
/
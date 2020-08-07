create or replace package FND_LOG AUTHID CURRENT_USER as
/* $Header: AFUTLOGS.pls 120.2.12010000.2 2010/03/12 18:31:55 pferguso ship $ */
   /* Documentation for this package is at */
   /* http://www-apps.us.oracle.com/atg/plans/r115/aflog.txt */

   LEVEL_UNEXPECTED CONSTANT NUMBER  := 6;
   LEVEL_ERROR      CONSTANT NUMBER  := 5;
   LEVEL_EXCEPTION  CONSTANT NUMBER  := 4;
   LEVEL_EVENT      CONSTANT NUMBER  := 3;
   LEVEL_PROCEDURE  CONSTANT NUMBER  := 2;
   LEVEL_STATEMENT  CONSTANT NUMBER  := 1;

   /* Context ID of the log transaction */
   G_TRANSACTION_CONTEXT_ID NUMBER;

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
                                                          return NUMBER;


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
   PROCEDURE SET_TRANSACTION (TRANS_CONTEXT_ID IN NUMBER);

   /*
   **  Writes the message to the log file for the spec'd level and module
   **  if logging is enabled for this level and module
   */
   PROCEDURE STRING(LOG_LEVEL IN NUMBER,
                    MODULE    IN VARCHAR2,
                    MESSAGE   IN VARCHAR2);

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
                      DB_INSTANCE     IN NUMBER   DEFAULT NULL);

   /*
   **  Writes a message to the log file if this level and module is enabled
   **  The message gets set previously with FND_MESSAGE.SET_NAME,
   **  SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.
   **  Example usage:
   **  FND_MESSAGE.SET_NAME(...);    -- Set message
   **  FND_MESSAGE.SET_TOKEN(...);   -- Set token in message
   **  FND_LOG.MESSAGE(..., FALSE);  -- Log message
   **  FND_MESSAGE.ERROR;            -- Display message
   */
   PROCEDURE MESSAGE(LOG_LEVEL   IN NUMBER,
                     MODULE      IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL);

   /*
   **  Writes a message to the log file if this level and module is enabled
   **  The message gets set previously with FND_MESSAGE.SET_NAME,
   **  SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.
   **  Example usage:
   **  FND_MESSAGE.SET_NAME(...);    -- Set message
   **  FND_MESSAGE.SET_TOKEN(...);   -- Set token in message
   **  ATTACHMENT_ID := FND_LOG.MESSAGE_WITH_ATTACHMENT(..., FALSE);  -- Log message
   **  -- For ASCII data use WRITE
   **  FND_LOG_ATTACHMENT.WRITE(ATTACHMENT_ID, ...);
   **  -- For Non-ASCII data use WRITE_RAW
   **  FND_LOG_ATTACHMENT.WRITE_RAW(ATTACHMENT_ID, ...);
   **  FND_LOG_ATTACHMENT.CLOSE();
   */
   FUNCTION MESSAGE_WITH_ATTACHMENT(LOG_LEVEL   IN NUMBER,
                     MODULE      IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL,
                     P_CHARSET IN VARCHAR2 DEFAULT 'ascii',
                     P_MIMETYPE IN VARCHAR2 DEFAULT 'text/html',
                     P_ENCODING IN VARCHAR2 DEFAULT NULL,
                     P_LANG IN VARCHAR2 DEFAULT NULL,
                     P_FILE_EXTN IN VARCHAR2 DEFAULT 'txt',
                     P_DESC IN VARCHAR2 DEFAULT NULL) RETURN NUMBER;

   /*
   **  Writes a message to the log file if this level and module is enabled
   **  The message gets set previously with FND_MESSAGE.SET_NAME,
   **  SET_TOKEN, etc.
   **  The message is popped off the message dictionary stack, if POP_MESSAGE
   **  is TRUE.  Pass FALSE for POP_MESSAGE if the message will also be
   **  displayed to the user later.
   **  Example usage:
   **  FND_MESSAGE.SET_NAME(...);    -- Set message
   **  FND_MESSAGE.SET_TOKEN(...);   -- Set token in message
   **  FND_LOG.MESSAGE(..., FALSE);  -- Log message
   **  FND_MESSAGE.ERROR;            -- Display message
   */
   PROCEDURE MESSAGE(LOG_LEVEL   IN NUMBER,
                     MODULE      IN VARCHAR2,
                     POP_MESSAGE IN BOOLEAN DEFAULT NULL,
		                 AUTO_LOG    IN VARCHAR2);

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
                      DB_INSTANCE     IN NUMBER   DEFAULT NULL);

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
                     METRIC_VALUE IN VARCHAR2);

   procedure WORK_METRIC (MODULE       IN VARCHAR2,
                     METRIC_CODE  IN VARCHAR2,
                     METRIC_VALUE IN NUMBER);

   procedure WORK_METRIC (MODULE       IN VARCHAR2,
                     METRIC_CODE  IN VARCHAR2,
                     METRIC_VALUE IN DATE);

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

   PROCEDURE WORK_METRICS_EVENT(CONTEXT_ID IN NUMBER DEFAULT NULL);

   /*
   ** Tests whether logging is enabled for this level and module, to
   ** avoid the performance penalty of building long debug message
   ** strings unnecessarily.
   */
   FUNCTION TEST(LOG_LEVEL IN NUMBER,
                 MODULE    IN VARCHAR2) RETURN BOOLEAN;


   /* This global allows callers to avoid a function call if a log message */
   /* is not for the current level.  It is automatically populated by */
   /* the FND_LOG_REPOSITORY package.
   /* Here is an example of how to achieve maximum performance with */
   /* this, assuming that you want to log a message at EXCEPTION level */
   /*  */
   /* if((FND_LOG.LEVEL_EXCEPTION >= FND_LOG.G_CURRENT_RUNTIME_LEVEL)) then*/
   /*   if(FND_LOG.TEST(FND_LOG.LEVEL_EXCEPTION */
   /*           'fnd.form.ABCDEFGH.PACKAGEA.FUNCTIONB.firstlabel')) then*/
   /*      dbg_msg := create_lengthy_debug_message(...);*/
   /*      FND_LOG.STRING(FND_LOG.LEVEL_EXCEPTION, */
   /*           'fnd.form.ABCDEFGH.PACKAGEA.FUNCTIONB.firstlabel', dbg_msg);*/
   /*   end if; */
   /* end if;*/
   G_CURRENT_RUNTIME_LEVEL NUMBER := 6;

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
                     ) RETURN  VARCHAR2;

    /**
     * Procedure to enable PL/SQL Buffered Logging (for Batch Mode).
     * Caller is responsible for calling RESET_BUFFERED_MODE to flush
     * messages at end. Only messages with log_level < 4 are bufferable.
     * All error messages (log_level >= 4) are logged immediately.
     *
     * Internally reads AFLOG_BUFFER_MODE Profile and if !=0
     * buffers messages in PL/SQL Collection for Bulk-Inserting.
     */
    PROCEDURE SET_BUFFERED_MODE;

    /**
     * Flushes any buffered messages, and switches back to the
     * default synchronous (non-buffered) logging.
     */
    PROCEDURE RESET_BUFFERED_MODE;

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
	REQUEST_ID IN NUMBER);

end FND_LOG;
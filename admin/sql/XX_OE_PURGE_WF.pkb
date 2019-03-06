create or replace PACKAGE BODY xx_oe_purge_wf 
AS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name         : xx_oe_purge_wf                                         |
-- |                                                                       |
-- | RICE#        :                                                        |
-- |                                                                       |
-- | Description  :                                                        |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- |1.0        09-SEP-15    Havish K       Initial Version                 |
-- +=======================================================================+

  g_purge_count              NUMBER             := 0;
  g_commit_frequency         NUMBER             := 500;
  g_age                      NUMBER             := 0;
  gc_debug                   VARCHAR2(1);
  gc_req_data                VARCHAR2(240)      := NULL;
  gn_parent_request_id       NUMBER(15)         := FND_GLOBAL.CONC_REQUEST_ID;
  gn_parent_cp_id            NUMBER;
  gn_child_cp_id             NUMBER;
  gc_child_prog_name         fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  gc_error_loc               VARCHAR2(4000)     := NULL;
  gc_conc_short_name         VARCHAR2(50)       := 'XX_OE_PUR_WF_CHILD';
  
  -- +====================================================================+
  -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
  -- |                                                                    |
  -- | Description: This procedure is used to print the time to the log   |
  -- |                                                                    |
  -- | Parameters : none                                                  |
  -- |                                                                    |
  -- | Returns    : none                                                  |
  -- +====================================================================+
  PROCEDURE print_time_stamp_to_logfile
  IS
  BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'*** Current system time is '||
                            TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||' ***'||chr(10));
  END print_time_stamp_to_logfile;
   
  -- +===================================================================+
  -- | PROCEDURE  : LOCATION_AND_LOG                                     |
  -- |                                                                   |
  -- | DESCRIPTION: Performs the following actions based on parameters   |
  -- |              1. Sets gc_error_location                            |
  -- |              2. Writes to log file if debug is on                 |
  -- |                                                                   |
  -- | PARAMETERS : p_debug_msg                                          |
  -- |                                                                   |
  -- | RETURNS    : None                                                 |
  -- +===================================================================+
  PROCEDURE location_and_log (p_debug           IN  VARCHAR2,
                              p_debug_msg       IN  VARCHAR2
                              )
  IS
  BEGIN
      gc_error_loc := p_debug_msg;   -- set error location

      IF gc_debug = 'Y' THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, gc_error_loc);
      END IF;

  END LOCATION_AND_LOG;
   
  -- +====================================================================+
  -- | Name       : PURGE_ORPHAN_ERRORS                                   |
  -- |                                                                    |
  -- | Description: This procedure is created to purge the orphan         |
  -- |              error flows                                           |
  -- |                                                                    |
  -- | Parameters : p_item_key                                            |
  -- |                                                                    |
  -- | Returns    : none                                                  |
  -- +====================================================================+
  
  /*----------------------------------------------------------------------------------
  Procedure:   Purge_Orphan_Errors
  Description: This procedure is created to purge the orphan error flows. That is, the
  error flowswhose parent information is missing, or the parent is no longer
  in error. This API will come into picture, only if item type passed is
  OMERROR or ALL and the attempt_to_close parameter is yes. This API will
  abort and immediately purge all such error flows.
  -------------------------------------------------------------------------------------*/
  PROCEDURE purge_orphan_errors(
                                   p_item_key IN VARCHAR2 DEFAULT NULL 
                               )
  IS
    -- Local Variable Declaration
    l_errors_tbl wf_tbl_type;
    
    CURSOR errors
    IS
        SELECT e.item_type,
               e.item_key
          FROM wf_items e
         WHERE ((e.item_type      =  'WFERROR'
           AND e.parent_item_type IN ('OEOH','OEOL','OENH','OEBH'))
            OR e.item_type         = 'OMERROR')
           AND e.end_date         IS NULL
           AND NOT EXISTS (SELECT 1
                             FROM wf_item_activity_statuses s
                            WHERE s.item_type       = e.parent_item_type
                              AND s.item_key        = e.parent_item_key
                              AND s.activity_status = 'ERROR'
                          )
        ;
        
    CURSOR specific_error(c_item_key VARCHAR2)
    IS
        SELECT e.item_type,
               e.item_key
         FROM wf_items e
        WHERE e.item_type = 'OMERROR'
          AND e.end_date  IS NULL
          AND e.item_key  = c_item_key
          AND NOT EXISTS (SELECT 1
                            FROM wf_item_activity_statuses s
                           WHERE s.item_type     = e.parent_item_type
                             AND s.item_key        = e.parent_item_key
                             AND s.activity_status = 'ERROR'
                         )
        ;
        
    /*came up with the above cursor, to honour the attempt to close parameter, when
    item type is passed as 'OMERROR' and a specific error key is passed*/
    
  BEGIN
      
         location_and_log(gc_debug,'Entering the procedure oe_purge_wf.purge_orphan_errors'||chr(10));
     
     IF p_item_key IS NULL 
     THEN
             location_and_log(gc_debug,'Item key is not passed. Fetching all the orphan error flows.');
             
         OPEN errors;
         LOOP
           FETCH errors BULK COLLECT INTO l_errors_tbl LIMIT g_commit_frequency;
            -- EXIT WHEN errors%NOTFOUND ;
           IF l_errors_tbl.COUNT > 0 
           THEN
                FOR i IN l_errors_tbl.FIRST .. l_errors_tbl.LAST
                LOOP
                
                  BEGIN
                    location_and_log(gc_debug,'Setting the error parent to null and aborting the flow.');
                    WF_ITEM.Set_Item_Parent(l_errors_tbl(i).ITEM_TYPE,l_errors_tbl(i).ITEM_KEY,NULL,NULL,NULL);
                    wf_engine.abortprocess(itemtype =>l_errors_tbl(i).ITEM_TYPE, itemkey=>l_errors_tbl(i).item_key);
                  EXCEPTION
                  WHEN OTHERS 
                  THEN
                     UPDATE wf_items
                        SET end_date   = SYSDATE
                      WHERE item_type=l_errors_tbl(i).ITEM_TYPE
                        AND item_key   =l_errors_tbl(i).item_key;
                  END;
                
                  location_and_log(gc_debug,'Purging the error flow for item_type and item_key'||l_errors_tbl(i).ITEM_TYPE||'and'||l_errors_tbl(i).ITEM_KEY);
                
                  wf_purge.items(itemtype => l_errors_tbl(i).ITEM_TYPE, itemkey => l_errors_tbl(i).ITEM_KEY, docommit => FALSE, force=>TRUE);
                  g_purge_count:=g_purge_count+1;
                END LOOP ;
           END IF ;
           
           l_errors_tbl.DELETE ;
           EXIT WHEN errors%NOTFOUND ;
         END LOOP ;
         CLOSE errors;
         
     ELSE

           location_and_log( gc_debug,'Item key is passed. Fetching the specific error flow for key:'||p_item_key);
        
        OPEN specific_error(p_item_key);
        LOOP
           FETCH specific_error BULK COLLECT INTO l_errors_tbl LIMIT g_commit_frequency;
           -- EXIT WHEN errors%NOTFOUND ;
             IF l_errors_tbl.COUNT > 0 
             THEN
               FOR i IN l_errors_tbl.FIRST .. l_errors_tbl.LAST
               LOOP
                   BEGIN

                      location_and_log(gc_debug, 'Setting the error parent to null and aborting the flow for the specific key');
                      
                      WF_ITEM.Set_Item_Parent(l_errors_tbl(i).ITEM_TYPE,l_errors_tbl(i).ITEM_KEY,NULL,NULL,NULL);
                      wf_engine.abortprocess(itemtype =>l_errors_tbl(i).ITEM_TYPE, itemkey=>l_errors_tbl(i).item_key);
                   EXCEPTION
                   WHEN OTHERS
                   THEN
                      UPDATE wf_items
                      SET end_date   = SYSDATE
                      WHERE item_type=l_errors_tbl(i).ITEM_TYPE
                      AND item_key   =l_errors_tbl(i).item_key;
                   END;
               
                   location_and_log(gc_debug, 'Purging the error flow for item_type and item_key'||l_errors_tbl(i).ITEM_TYPE||'and'||l_errors_tbl(i).ITEM_KEY);
                   
                   wf_purge.items(itemtype => l_errors_tbl(i).ITEM_TYPE, itemkey => l_errors_tbl(i).ITEM_KEY, docommit => FALSE, force=>TRUE);
                   g_purge_count:=g_purge_count+1;
               END LOOP ;
             END IF ;
             
             l_errors_tbl.DELETE ;
           EXIT WHEN specific_error%NOTFOUND ;
        END LOOP ;
        CLOSE specific_error;
     END IF ;
     
     location_and_log(gc_debug, 'Exiting oe_purge_wf.purge_orphan_errors');
     
  EXCEPTION
  WHEN OTHERS 
  THEN 
     location_and_log(gc_debug, 'In others exception of oe_purge_wf.purge_orphan_errors :'||SQLERRM);
     l_errors_tbl.DELETE ;    
    IF errors%isopen 
    THEN
      CLOSE errors;
    END IF;    
    IF specific_error%isopen 
    THEN
      CLOSE specific_error;
    END IF;
    
  END purge_orphan_errors;
  
  -- +====================================================================+
  -- | Name       : attempt_to_close                                      |
  -- |                                                                    |
  -- | Description: This procedure is created for order headers only      |
  -- |                                                                    |
  -- | Parameters : p_item_key                                            |
  -- |                                                                    |
  -- | Returns    : none                                                  |
  -- +====================================================================+
  
  /*----------------------------------------------------------------------------------
  Procedure:   Attempt_To_Close
  Description: This procedure is created for order headers only. It comes into picture
  only if the item type passed in 'OEOH' or 'ALL', and the attempt_to_close
  parameter is 'yes'. This API will first abort and purge all the error
  flows associated with the order header. It will then retry the close_wait_
  for_l activity for the headers.
  -------------------------------------------------------------------------------------*/
  PROCEDURE attempt_to_close(p_item_key IN VARCHAR2 DEFAULT NULL )
  IS
    -- Local Variables Declaration
    l_wf_details_tbl          wf_details_tbl_type;
    l_error_tbl               wf_tbl_type;
    l_result                  VARCHAR2(30);
    
    CURSOR to_close
    IS
      SELECT P.INSTANCE_LABEL,
             WAS.ITEM_KEY,
             H.ORDER_NUMBER,
             H.ORG_ID
        FROM WF_ITEM_ACTIVITY_STATUSES WAS,
             WF_PROCESS_ACTIVITIES P,
             OE_ORDER_HEADERS_ALL H
       WHERE TO_NUMBER(WAS.ITEM_KEY) = H.HEADER_ID
         AND WAS.PROCESS_ACTIVITY      = P.INSTANCE_ID
         AND P.ACTIVITY_ITEM_TYPE      = 'OEOH'
         AND P.ACTIVITY_NAME           = 'CLOSE_WAIT_FOR_L'
         AND WAS.ACTIVITY_STATUS       = 'NOTIFIED'
         AND WAS.ITEM_TYPE             = 'OEOH'
         AND NOT EXISTS (SELECT 1
                           FROM OE_ORDER_LINES_ALL
                          WHERE HEADER_ID = H.HEADER_ID
                            AND OPEN_FLAG   = 'Y'
                        )
         ;
                        
    CURSOR close_specific(c_item_key VARCHAR2 )
    IS
      SELECT P.INSTANCE_LABEL,
             WAS.ITEM_KEY,
             H.ORDER_NUMBER,
             H.ORG_ID
        FROM WF_ITEM_ACTIVITY_STATUSES WAS,
             WF_PROCESS_ACTIVITIES P,
             OE_ORDER_HEADERS_ALL H
       WHERE TO_NUMBER(WAS.ITEM_KEY)   =  H.HEADER_ID
         AND WAS.PROCESS_ACTIVITY      =  P.INSTANCE_ID
         AND P.ACTIVITY_ITEM_TYPE      =  'OEOH'
         AND P.ACTIVITY_NAME           =  'CLOSE_WAIT_FOR_L'
         AND WAS.ACTIVITY_STATUS       =  'NOTIFIED'
         AND WAS.item_key              =  c_item_key
         AND WAS.ITEM_TYPE             = 'OEOH'
         AND NOT EXISTS (SELECT 1
                           FROM OE_ORDER_LINES_ALL
                          WHERE HEADER_ID = H.HEADER_ID
                            AND OPEN_FLAG   = 'Y'
                        )
         ;
    CURSOR ERRORS (c_header_id NUMBER)
    IS
      SELECT I.ITEM_TYPE,
             I.ITEM_KEY
        FROM WF_ITEMS I
       WHERE I.ITEM_TYPE         IN ('OMERROR','WFERROR')
         AND I.PARENT_ITEM_TYPE  =  'OEOH'
         AND I.PARENT_ITEM_KEY   =  TO_CHAR(c_header_id)
         AND I.END_DATE          IS NULL FOR UPDATE NOWAIT;
  BEGIN
  
      location_and_log(gc_debug,'Entering oe_purge_wf.attempt_to_close' ) ;
    
    IF p_item_key IS NOT NULL
    THEN

            location_and_log(gc_debug,'Header id is passed. Fetching the specific header.' ) ;
        
        OPEN close_specific(p_item_key);
        LOOP
           FETCH close_specific BULK COLLECT
            INTO l_wf_details_tbl LIMIT g_commit_frequency;
            --EXIT WHEN to_close%NOTFOUND ;
           IF l_wf_details_tbl.COUNT > 0 
           THEN
               FOR i IN l_wf_details_tbl.FIRST .. l_wf_details_tbl.LAST
               LOOP
                  BEGIN
                        location_and_log(gc_debug,'Fetching the error flows associated with the header:'||p_item_key ) ;

                      OPEN ERRORS(To_Number(l_wf_details_tbl(i).item_key));
                      LOOP
                        FETCH ERRORS BULK COLLECT INTO l_error_tbl LIMIT g_commit_frequency;
                        --EXIT WHEN ERRORS%NOTFOUND ;
                        IF l_error_tbl.COUNT>0 
                        THEN
                           FOR j IN l_error_tbl.FIRST .. l_error_tbl.LAST
                           LOOP
                           
                             BEGIN
                                location_and_log(gc_debug,'Clearing the parent info from the error and aborting the error flow.' ) ;
                              
                              WF_ITEM.Set_Item_Parent(l_error_tbl(j).ITEM_TYPE,l_error_tbl(j).ITEM_KEY,NULL,NULL,NULL);
                              WF_ENGINE.ABORTPROCESS(ITEMTYPE =>l_error_tbl(j).ITEM_TYPE, ITEMKEY=>l_error_tbl(j).ITEM_KEY);
                             EXCEPTION
                             WHEN OTHERS 
                             THEN
                                UPDATE wf_items
                                   SET end_date   = SYSDATE
                                 WHERE item_type  = l_error_tbl(j).item_type
                                   AND item_key   = l_error_tbl(j).item_key;
                             END;
                            
                                location_and_log(gc_debug,'Purging the error item_type and error item_key'||l_error_tbl(j).ITEM_TYPE||'and'||l_error_tbl(j).ITEM_KEY ) ;
                             
                             WF_PURGE.ITEMS(ITEMTYPE =>l_error_tbl(j).ITEM_TYPE, ITEMKEY=>l_error_tbl(j).ITEM_KEY, DOCOMMIT=>FALSE, FORCE=>TRUE);
                             g_purge_count:=g_purge_count+1;
                             
                           END LOOP; --looping in the error table
                           l_error_tbl.DELETE ;
                        END IF;
                        
                        EXIT WHEN errors%NOTFOUND ;
                      END LOOP ; --error cursor
                      CLOSE errors;
                      
                       location_and_log(gc_debug,'Done with the error flows. Setting the context.' ) ;
                      
                      BEGIN
                        OE_Standard_WF.OEOH_SELECTOR (p_itemtype => 'OEOH' ,p_itemkey => l_wf_details_tbl(i).item_key ,p_actid => 12345 ,p_funcmode => 'SET_CTX' ,p_result => l_result );
                      EXCEPTION
                      WHEN NO_DATA_FOUND 
                      THEN
                        FND_CLIENT_INFO.SET_ORG_CONTEXT(l_wf_details_tbl(i).org_id);
                        FND_PROFILE.PUT('ORG_ID', TO_CHAR(l_wf_details_tbl(i).org_id));
                      END;
                
                        location_and_log(gc_debug,'Retrying the close_wait_for_l activity' ) ;
                        
                      WF_ENGINE.HANDLEERROR('OEOH', l_wf_details_tbl(i).item_key, l_wf_details_tbl(i).INSTANCE_LABEL, 'RETRY',NULL);
                  EXCEPTION
                  WHEN OTHERS 
                  THEN
                      NULL;
                  END;
               END LOOP ; --specific cusror
           l_wf_details_tbl.DELETE ;
           END IF;
           EXIT WHEN close_specific%NOTFOUND ;
        END LOOP ;
        CLOSE close_specific;
        
    ELSE
       location_and_log(gc_debug,'Header id is not passed. Fetching all the stuck headers.') ;
      
      OPEN to_close;
      LOOP
        FETCH to_close BULK COLLECT INTO l_wf_details_tbl LIMIT g_commit_frequency;
        --EXIT WHEN to_close%NOTFOUND ;
        IF l_wf_details_tbl.COUNT >0 
        THEN
           FOR i IN l_wf_details_tbl.FIRST .. l_wf_details_tbl.LAST
           LOOP
                location_and_log(gc_debug,'Getting the error flows associated with the specific headers.' ) ;
  
              BEGIN
                OPEN errors(To_Number(l_wf_details_tbl(i).item_key));
                LOOP
                  FETCH errors BULK COLLECT INTO l_error_tbl LIMIT g_commit_frequency;
                  --EXIT WHEN ERRORS%NOTFOUND ;
                     IF l_error_tbl.COUNT>0 
                     THEN
                        FOR j IN l_error_tbl.FIRST .. l_error_tbl.LAST
                        LOOP
                           BEGIN
                                location_and_log(gc_debug,'Removing the parent reference and aborting the error flow' ) ;
                              WF_ITEM.Set_Item_Parent(l_error_tbl(j).ITEM_TYPE,l_error_tbl(j).ITEM_KEY,NULL,NULL,NULL);
                              WF_ENGINE.ABORTPROCESS(ITEMTYPE =>l_error_tbl(j).ITEM_TYPE, ITEMKEY=>l_error_tbl(j).ITEM_KEY);
                           EXCEPTION
                           WHEN OTHERS 
                           THEN
                              UPDATE wf_items
                              SET end_date   = SYSDATE
                              WHERE item_type=l_error_tbl(j).item_type
                              AND item_key   =l_error_tbl(j).item_key;
                           END;
                        
                           location_and_log(gc_debug,'Purging the error item type and error item key'||l_error_tbl(j).ITEM_TYPE||'and'||l_error_tbl(j).ITEM_KEY) ;
                           
                           WF_PURGE.ITEMS(ITEMTYPE =>l_error_tbl(j).ITEM_TYPE, ITEMKEY=>l_error_tbl(j).ITEM_KEY, DOCOMMIT=>FALSE, FORCE=>TRUE);
                           g_purge_count:=g_purge_count+1;
                        END LOOP; --error table count
                        l_error_tbl.DELETE ;
                     END IF;
                  EXIT WHEN errors%NOTFOUND ;
                END LOOP ; --error cursor fetch.
                CLOSE errors;
                
                BEGIN
                    location_and_log(gc_debug,'Done with error flows. Setting the context for the header') ;
                   OE_Standard_WF.OEOH_SELECTOR (p_itemtype => 'OEOH' ,p_itemkey => l_wf_details_tbl(i).item_key ,p_actid => 12345 ,p_funcmode => 'SET_CTX' ,p_result => l_result );
                EXCEPTION
                WHEN NO_DATA_FOUND 
                THEN
                   FND_CLIENT_INFO.SET_ORG_CONTEXT(l_wf_details_tbl(i).org_id);
                   FND_PROFILE.PUT('ORG_ID', TO_CHAR(l_wf_details_tbl(i).org_id));
                END;
                
                 location_and_log(gc_debug,'Retrying close_wait_for_l activity for the header') ;
                WF_ENGINE.HANDLEERROR('OEOH', l_wf_details_tbl(i).item_key, l_wf_details_tbl(i).INSTANCE_LABEL, 'RETRY',NULL);
                
              EXCEPTION
              WHEN OTHERS 
              THEN
                 NULL;
              END;
           END LOOP ; --to close cursor fetch
           l_wf_details_tbl.DELETE ;
        END IF;
        EXIT WHEN to_close%NOTFOUND ;
      END LOOP ;
      CLOSE to_close;
    END IF ; --item key check
    
      location_and_log( gc_debug,'Exiting oe_purge_wf.attempt_to_close' ) ;
    
  EXCEPTION
  WHEN OTHERS 
  THEN
    l_wf_details_tbl.DELETE ;
    l_error_tbl.DELETE ;
    IF to_close%ISOPEN 
    THEN
      CLOSE to_close;
    END IF ;
    IF errors%ISOPEN 
    THEN
      CLOSE errors;
    END IF ;
    IF close_specific%isopen 
    THEN
      CLOSE close_specific;
    END IF ;

      location_and_log(gc_debug, SQLERRM ) ;
    
  END attempt_to_close ;
  
  -- +======================================================================+
  -- | Name       : purge_item_type                                         |
  -- |                                                                      |
  -- | Description: This procedure is created to purge the closed workflows |
  -- |              of a specific item type.                                |
  -- | Parameters : p_item_key                                              |
  -- |                                                                      |
  -- | Returns    : none                                                    |
  -- +======================================================================+

  PROCEDURE purge_item_type( p_item_type  IN VARCHAR2,
                             p_thread_num IN NUMBER,
                             p_threads    IN NUMBER )
  IS
    -- Local Variable Declaration
    l_purge_tbl wf_tbl_type;
             
    CURSOR to_purge
    IS 
      SELECT    WF.item_type
	             ,WF.item_key
        FROM  (SELECT WI.item_type
                     ,WI.item_key
                     ,(MOD(CEIL((DENSE_RANK() OVER (PARTITION BY WI.item_type ORDER BY WI.item_key))), p_threads) + 1) AS THREAD_NUM
                 FROM wf_items WI
                WHERE item_type = p_item_type
                  AND end_date <= (SYSDATE - g_age)
              ) WF
       WHERE  1 = 1
         AND WF.thread_num = p_thread_num ; 
         
  BEGIN

       location_and_log( gc_debug,'Entering oe_purge_wf.purge_item_type:'||p_item_type) ;
       FND_FILE.PUT_LINE (FND_FILE.LOG, '');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Entering oe_purge_wf.purge_item_type');
       FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Item Type              : ' || p_item_type);
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Number of Threads      : ' || p_threads);
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread Number          : ' || p_thread_num);
       FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
       FND_FILE.PUT_LINE (FND_FILE.LOG, '');
       
      OPEN to_purge ;
      LOOP
        FETCH to_purge BULK COLLECT INTO l_purge_tbl limit g_commit_frequency;
        --EXIT WHEN to_purge%NOTFOUND ;
          IF l_purge_tbl.COUNT > 0 
          THEN
            FOR i IN l_purge_tbl.first .. l_purge_tbl.last
            LOOP
                location_and_log(gc_debug, l_purge_tbl(i).item_key);
                BEGIN

                   location_and_log(gc_debug, 'Before purging the item_key:'||l_purge_tbl(i).item_key ) ;
                  WF_PURGE.ITEMS(ITEMTYPE =>l_purge_tbl(i).item_type, ITEMKEY=>l_purge_tbl(i).item_key, DOCOMMIT=>FALSE, FORCE=>TRUE);
                  g_purge_count:=g_purge_count+1;
                EXCEPTION
                WHEN OTHERS 
                THEN
                    NULL;
                END ;
            END LOOP ;
          END IF ;
          COMMIT ;
        l_purge_tbl.DELETE ;
        EXIT WHEN to_purge%NOTFOUND ;
      END LOOP ;
      CLOSE to_purge ;

      location_and_log(gc_debug, 'Exiting oe_purge_wf.purge_item_type') ;
  EXCEPTION
  WHEN OTHERS 
  THEN
    location_and_log(gc_debug,sqlerrm);
    l_purge_tbl.DELETE ;
    IF to_purge%isopen 
    THEN
      CLOSE to_purge;
    END IF ;
  END purge_item_type;
  
  -- +========================================================================+
  -- | Name       : master_purge_om_flows                                      |
  -- |                                                                        |
  -- | Description: This is the main API of the package, which will be called |
  -- |              from the concurrent "Purge Order management Workflow"     |
  -- |              concurrent program.                                       |
  -- | Parameters : p_item_type                                               |
  -- |              p_item_key                                                |
  -- |              p_age                                                     |
  -- |              p_attempt_to_close                                        |
  -- |              p_commit_frequency                                        |
  -- |              p_threads                                                 |
  -- | Returns    : errbuf                                                    |
  -- |              retcode                                                   |
  -- +========================================================================+

  PROCEDURE master_purge_om_flows
    (
      errbuf                      OUT NOCOPY  VARCHAR2 ,
      retcode                     OUT NOCOPY NUMBER ,
      p_item_type                 IN VARCHAR2  ,
      p_item_key                  IN VARCHAR2  ,
      p_age                       IN NUMBER  ,
      p_attempt_to_close          IN VARCHAR2 ,
      p_commit_frequency          IN NUMBER  ,
      p_threads                   IN NUMBER ,
      p_debug_flag                IN VARCHAR2)
  IS
  
      ln_thread_cnt                 NUMBER := 0;
      EX_PROGRAM_INFO               EXCEPTION;
      EX_REQUEST_NOT_SUBMITTED      EXCEPTION;
      EX_NO_SUB_REQUESTS            EXCEPTION;
      ln_conc_req_id                NUMBER;
      ln_req_id                     req_id;
      ln_idx                        NUMBER := 1;
      ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
      ln_success_cnt                NUMBER := 0;
      ln_error_cnt                  NUMBER := 0;
      ln_retcode                    NUMBER := 0;
  BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      gc_debug := p_debug_flag;
      gc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

    IF gc_req_data IS NULL 
    THEN
            location_and_log(gc_debug,'Initialize Processing.'||chr(10));
         -------------------------------------------------
         -- Print Parameter Names and Values to Log File
         -------------------------------------------------

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Item Type              : ' || p_item_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Item Key               : ' || p_item_key);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Age                    : ' || p_age);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Attempt to Close       : ' || p_attempt_to_close);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Commit Frequency       : ' || p_commit_frequency);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Number of Threads      : ' || p_threads);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || p_debug_flag);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : ' || gn_parent_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');

      print_time_stamp_to_logfile;
      
      --========================================================================
         -- Retrieve and Print Program Information to Log File
         --========================================================================
         location_and_log (gc_debug,'Retrieve Program IDs for Master and Child.' || CHR (10));

         BEGIN
            location_and_log (gc_debug,'Retrieve Program ID for Master');

            SELECT concurrent_program_id
              INTO gn_parent_cp_id
              FROM fnd_concurrent_requests fcr
             WHERE fcr.request_id = gn_parent_request_id;

            location_and_log (gc_debug,'     Retrieve Program Info for Child');

            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO gn_child_cp_id
                  ,gc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = gc_conc_short_name;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '***************************** PROGRAM INFORMATION ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Program ID      : ' || gn_parent_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program ID       : ' || gn_child_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program Name     : ' || gc_child_prog_name);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE EX_PROGRAM_INFO;
         END;  -- print program information

         print_time_stamp_to_logfile;
         
            location_and_log (gc_debug,'Processing for Purge Order Management Workflow' || CHR (10));

                  -------------------------------------
                  -- Derive Child Thread Ranges - FULL
                  -------------------------------------
                  location_and_log (gc_debug,'     FULL - Before the Loop');

                  LOOP

                    location_and_log(gc_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;

                     ---------------------------------------------------------
                     -- Submit Child Requests - FULL
                     ---------------------------------------------------------

                     location_and_log (gc_debug,'     FULL - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => gc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_item_type
                                                   ,argument2        => p_item_key
                                                   ,argument3        => p_age 
                                                   ,argument4        => p_attempt_to_close 
                                                   ,argument5        => p_commit_frequency
                                                   ,argument6        => p_threads
                                                   ,argument7        => ln_thread_cnt
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug,'     Child Program is not submitted');
                        retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;  
                      ELSE
                        COMMIT;
                        location_and_log (gc_debug,'     Able to submit the Child Program');
                     END IF;
                     EXIT WHEN (ln_thread_cnt = p_threads); 
                  END LOOP;
                  
                   location_and_log ( gc_debug,'     FULL - After the Loop');
                   location_and_log(gc_debug,'     Pausing MASTER Program......'||chr(10));
                   FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                                   request_data => 'CHILD_REQUESTS');
              
      
      ELSE
                  
         location_and_log(gc_debug,'     Restarting after CHILD_REQUESTS Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests 
         --========================================================================
         BEGIN
            location_and_log (gc_debug,'Post-processing for Child Requests' || CHR (10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_parent_request_id);

            location_and_log(gc_debug,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 
            THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  location_and_log(gc_debug,'     ltab_child_requests(i).request_id : '||ltab_child_requests(i).request_id);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_phase  : '||ltab_child_requests(i).dev_phase);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_status : '||ltab_child_requests(i).dev_status);

                  IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                     ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                  THEN
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_success_cnt := ln_success_cnt + 1;
                     retcode      := 0;
                  ELSE
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_error_cnt := ln_error_cnt + 1;
                     retcode    := 2;
                  END IF;

                  SELECT GREATEST (retcode, ln_retcode)
                    INTO ln_retcode
                    FROM DUAL;

               END LOOP; -- Checking Child Requests 
               
              ELSE
                 RAISE EX_NO_SUB_REQUESTS;
              END IF; -- retrieve child requests

            location_and_log (gc_debug,'     Captured Return Code for Master and Control Table Status');
            retcode := ln_retcode;

         END;  -- post processing for child requests

         print_time_stamp_to_logfile;
                                                  
    END IF;    
         
    EXCEPTION
     WHEN EX_PROGRAM_INFO 
     THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_PROGRAM_INFO at: ' || gc_error_loc);
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unable to get the Parent and Child Concurrent Names ');
          print_time_stamp_to_logfile;
          retcode := 2;
         
     WHEN EX_REQUEST_NOT_SUBMITTED 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_REQUEST_NOT_SUBMITTED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Unable to submit child request.');
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Rollback completed.');
         print_time_stamp_to_logfile;
         retcode := 2;
         
     WHEN EX_NO_SUB_REQUESTS 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_SUB_REQUESTS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         retcode := 2;
         
     WHEN NO_DATA_FOUND 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         retcode := 2;

     WHEN OTHERS 
     THEN
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         retcode := 2;
  
  END master_purge_om_flows;
  
  -- +========================================================================+
  -- | Name       : child_purge_om_flows                                      |
  -- |                                                                        |
  -- | Description: This is the main API of the package, which will be called |
  -- |              from the concurrent "Purge Order management Workflow"     |
  -- |              concurrent program.                                       |
  -- | Parameters : p_item_type                                               |
  -- |              p_item_key                                                |
  -- |              p_age                                                     |
  -- |              p_attempt_to_close                                        |
  -- |              p_commit_frequency                                        |
  -- |              p_threads                                                 |
  -- |              p_thread_num                                              |
  -- | Returns    : errbuf                                                    |
  -- |              retcode                                                   |
  -- +========================================================================+

  PROCEDURE child_purge_om_flows
    (
      errbuf                      OUT NOCOPY  VARCHAR2 ,
      retcode                     OUT NOCOPY NUMBER ,
      p_item_type                 IN VARCHAR2  ,
      p_item_key                  IN VARCHAR2  ,
      p_age                       IN NUMBER  ,
      p_attempt_to_close          IN VARCHAR2 ,
      p_commit_frequency          IN NUMBER  ,
      p_threads                   IN NUMBER  ,
      p_thread_num                IN NUMBER)
  IS
    -- Local Variables Declaration
    l_purge_tbl   wf_tbl_type;
    l_end_date    DATE ;
    l_item_type   VARCHAR2(30);
          
    CURSOR purge_all
    IS 
      SELECT    WF.item_type
	           ,WF.item_key
        FROM  (SELECT WI.item_type
                     ,WI.item_key
                     ,(MOD(CEIL((DENSE_RANK() OVER (PARTITION BY WI.item_type ORDER BY WI.item_key))), p_threads) + 1) AS THREAD_NUM
                 FROM wf_items WI
                WHERE item_type IN ('OEOH','OEOL','OMERROR')
                  AND end_date <= (SYSDATE - g_age)
              ) WF
       WHERE  1 = 1
         AND WF.thread_num = p_thread_num ; 
         
  BEGIN
      FND_FILE.PUT_LINE (FND_FILE.LOG, '');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Entering xx_oe_purge_wf.child_purge_om_flows');
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Item type passed is:'||p_item_type);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Item key passed is:'||p_item_key);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Attempt to close passed is:'||p_attempt_to_close);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Elapsed days After closure passed is:'||p_age);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Commit frequency passed is:'||p_commit_frequency);
      FND_FILE.PUT_LINE(FND_FILE.LOG,  'Number of Threads are:'||p_threads);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Thread Number is:'||p_thread_num);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    l_item_type  := p_item_type;
    
    IF l_item_type='ALL' 
    THEN
      l_item_type:= NULL ;
    END IF ;
    
    g_commit_frequency:=NVL(p_commit_frequency,500);
    g_age             :=NVL(p_age,0);
    Retcode           := 0;
    Errbuf            := '';
    IF l_item_type IS NOT NULL 
    THEN
        IF p_item_key IS NOT NULL 
        THEN
          BEGIN
            SELECT end_date
            INTO l_end_date
            FROM wf_items
            WHERE item_type=l_item_type
            AND item_key   =p_item_key;
          EXCEPTION
          WHEN no_data_found
          THEN
              NULL ;
          WHEN others
          THEN
              NULL ;
          END ;
          
             IF l_end_date IS NOT NULL AND l_end_date <= (SYSDATE-g_age)
             THEN
              /*Added the AND condition, just to ensure that a workflow will not get purged,
              if its age is small, even though it is end dated and both item type and item key
              are passed.*/

                  location_and_log(gc_debug, 'end date is not null');
                  
                WF_PURGE.ITEMS(ITEMTYPE =>l_item_type, ITEMKEY=>p_item_key, DOCOMMIT=>FALSE, FORCE=>TRUE);
                g_purge_count:=g_purge_count+1;
             ELSIF  l_end_date IS NULL 
             THEN
  
                IF p_attempt_to_close='Y'
                THEN
  
                       location_and_log( gc_debug,'Before calling attempt to close');
                       
                   IF l_item_type = 'OEOH'
                   THEN
                       attempt_to_close(p_item_key);
  
                   ELSIF l_item_type='OMERROR' 
                   THEN
                       purge_orphan_errors(p_item_key);
                   END IF ;
                   COMMIT;
  
                    BEGIN
                      SELECT end_date
                      INTO l_end_date
                      FROM wf_items
                      WHERE item_type=l_item_type
                      AND item_key   =p_item_key;
                    EXCEPTION
                    WHEN no_data_found 
                    THEN
                      NULL;
                    WHEN others 
                    THEN
                      NULL;
                    END ;
  
                    IF l_end_date IS NOT NULL 
                    THEN

                          location_and_log(gc_debug, 'Before Purging');
                          
                        WF_PURGE.ITEMS(ITEMTYPE =>l_item_type, ITEMKEY=>p_item_key, DOCOMMIT=>FALSE, FORCE=>TRUE);
                        g_purge_count:=g_purge_count+1;
                    END IF ;
                END IF ;
             END IF ;
        ELSIF l_item_type ='OEOH' 
        THEN
             IF p_attempt_to_close='Y' 
             THEN

                  location_and_log(gc_debug, 'Before calling attempt to close');
                attempt_to_close;
                COMMIT;
             END IF ;

                location_and_log( gc_debug,'Before purging');
             purge_item_type(l_item_type,p_thread_num,p_threads);
        ELSIF l_item_type      ='OMERROR' 
        THEN
             IF p_attempt_to_close='Y' 
             THEN

                   location_and_log( gc_debug,'Before calling Purge orphan errors');
                purge_orphan_errors;
                COMMIT ;
             END IF;

                location_and_log( gc_debug,'Before calling purge item type');
             purge_item_type(l_item_type,p_thread_num,p_threads);
        ELSE

             location_and_log( gc_debug,'item type passed is neither OMERROR nor OEOH');
             purge_item_type(l_item_type,p_thread_num,p_threads);
        END IF ;                     --end item key is not null
    ELSIF l_item_type IS NULL 
    THEN --item type is null

           location_and_log( gc_debug,'item type passed is all item types');
        
        IF p_item_key IS NOT NULL
        THEN
            fnd_file.put_line(FND_FILE.OUTPUT,'Item type cannot be null when item key is not null. ' ) ;

                location_and_log( gc_debug,'Item type cannot be null when item key is not null. ' ) ;
       ELSE
            IF p_attempt_to_close='Y' 
            THEN
               attempt_to_close;
               purge_orphan_errors;
               COMMIT ;
             END IF ;
             OPEN purge_all;
             LOOP
               FETCH purge_all BULK COLLECT INTO l_purge_tbl LIMIT p_commit_frequency;
               --EXIT WHEN purge_all%NOTFOUND ;
                  IF l_purge_tbl.COUNT>0
                  THEN
                     FOR i IN l_purge_tbl.FIRST .. l_purge_tbl.LAST
                     LOOP
                       BEGIN
                            location_and_log(gc_debug, 'Before purging for item_type and item_key'||l_purge_tbl(i).item_type||','||l_purge_tbl(i).item_key );
                          WF_PURGE.ITEMS(ITEMTYPE =>l_purge_tbl(i).item_type, ITEMKEY=>l_purge_tbl(i).item_key, DOCOMMIT=>FALSE, FORCE=>TRUE);
                          g_purge_count:=g_purge_count+1;
                       EXCEPTION
                       WHEN OTHERS 
                       THEN
                          NULL;
                       END ;
                     END LOOP ;
                     COMMIT ;
                     l_purge_tbl.DELETE ;
                  END IF;
               EXIT WHEN purge_all%NOTFOUND ;
             END LOOP ;
             CLOSE purge_all;
        END IF;
    END IF;
    errbuf  := '';
    retcode := 0;
    fnd_file.put_line(FND_FILE.LOG,'Number of workflow items attempted to purge is:'|| g_purge_count);
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
     NULL;
  WHEN OTHERS 
  THEN
    g_age             :=0;
    g_commit_frequency:=500;
    location_and_log('Y',sqlerrm);
    retcode := 2;
    errbuf  := sqlerrm;
    l_purge_tbl.DELETE ;
    IF purge_all%isopen 
    THEN
      CLOSE purge_all;
    END IF ;
  END child_purge_om_flows;
END xx_oe_purge_wf;
/
show errors;
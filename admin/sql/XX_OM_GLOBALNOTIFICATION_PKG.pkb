SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_globalnotification_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : xx_om_globalnotification_pkg                                |
-- | Rice ID     : E0270_GlobalNotification                                    |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 10-Jul-2007  Pankaj Kapse           Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS
    -- +===================================================================+
    -- | Name        : Write_Exception                                     |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :  Error_Code                                          |
    -- |               Error_Description                                   |
    -- |               Entity_Reference                                    |
    -- |               Entity_Reference_Id                                 |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                            )
    IS

     lc_errbuf    VARCHAR2(4000);
     lc_retcode   VARCHAR2(4000);

    BEGIN                               -- Procedure Block

     ge_exception.p_error_code        := p_error_code;
     ge_exception.p_error_description := p_error_description;
     ge_exception.p_entity_ref        := p_entity_reference;
     ge_exception.p_entity_ref_id     := p_entity_ref_id;

     xx_om_global_exception_pkg.Insert_Exception(
                                                  ge_exception
                                                 ,lc_errbuf
                                                 ,lc_retcode
                                                );

    END Write_Exception;   -- End Procedure Block

    -- +===================================================================+
    -- | Name        : Process_Bussiness_Event                             |
    -- | Description : This procedure is used in concurrent program which  |
    -- |               is used to select the lastest and deffered mode     |
    -- |               custom bussiness event and processed it.            |
    -- |                                                                   |
    -- | Parameters :  p_mode                                              |
    -- |               p_cause                                             |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Process_Bussiness_Event(
                                       errbuf   OUT VARCHAR2
                                      ,retcode  OUT PLS_INTEGER
                                     )
    IS

       ln_order_header_id PLS_INTEGER;
       lc_cause           VARCHAR2(1000);
       lc_item_key        VARCHAR2(1000);
       
       lc_itemkey_prefix  VARCHAR2(50):= 'XX_OM_GLOBALNOTIFY-'; 

       lc_errbuf          VARCHAR2(4000);
       lc_err_code        VARCHAR2(1000);

       CURSOR lcu_process_deferred_order IS
       SELECT *
       FROM   xx_om_globalnotify;
    BEGIN
      --
      --Deriving Item Key from sequence
      --
      BEGIN
         SELECT xx_om_globalnotify_itemkey_s.NEXTVAL
         INTO   lc_item_key
         FROM   dual;            
      END;    

       FOR lr_process_deferred_order IN lcu_process_deferred_order
       LOOP

          ln_order_header_id := lr_process_deferred_order.order_header_id;
          lc_cause           := lr_process_deferred_order.cause;

          Wf_engine.Createprocess(
                                  itemtype =>'XXOMGNTF'
                                 ,itemkey => lc_itemkey_prefix||lc_item_key
                                 ,process => 'XX_OM_SEND_NOTIFICATION'
                                );

          Wf_engine.SetItemAttrNumber(
                                      itemtype => 'XXOMGNTF'
                                     ,itemkey  => lc_itemkey_prefix||lc_item_key
                                     ,aname    => 'XX_OM_HEADER_ID'
                                     ,avalue   => ln_order_header_id
                                     );

          Wf_engine.SetItemAttrText(
                                    itemtype => 'XXOMGNTF'
                                   ,itemkey  => lc_itemkey_prefix||lc_item_key
                                   ,aname    => 'XX_OM_CAUSE'
                                   ,avalue   => lc_cause
                                   );

          Wf_engine.Startprocess(
                                itemtype =>'XXOMGNTF',
                                itemkey => lc_itemkey_prefix||lc_item_key
                               );
       END LOOP;

       BEGIN
          
          DELETE
          FROM xx_om_globalnotify;  
          
          COMMIT;
          
       EXCEPTION
       WHEN OTHERS THEN
          retcode := 2;  
          FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

          FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

          lc_errbuf   := FND_MESSAGE.GET;
          lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR';

          -- -------------------------------------
          -- Call the Write_Exception procedure to
          -- insert into Global Exception Table
          -- -------------------------------------

          Write_Exception (
                            p_error_code        => lc_err_code
                           ,p_error_description => lc_errbuf
                           ,p_entity_reference  => 'Order Header Id'
                           ,p_entity_ref_id     => gn_header_id
                        );
       END;
    EXCEPTION
    WHEN OTHERS THEN

       ROLLBACK;

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception (
                         p_error_code        => lc_err_code
                        ,p_error_description => lc_errbuf
                        ,p_entity_reference  => 'Order Header Id'
                        ,p_entity_ref_id     => gn_header_id
                     );

    END Process_Bussiness_Event;

    -- +===================================================================+
    -- | Name        : To_Raise_Bussiness_Event                            |
    -- | Description : Procedure is used to raise the custom  bussiness    |
    -- |               event.                                              |
    -- |                                                                   |
    -- | Parameters :  p_mode                                              |
    -- |               p_cause                                             |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE To_Raise_Bussiness_Event(
                                       p_mode             IN  VARCHAR2
                                      ,p_cause            IN  VARCHAR2
                                      ,p_order_header_id  IN  PLS_INTEGER
                                      )
    IS
       lt_parameter_list wf_parameter_list_t := wf_parameter_list_t();
       lc_event_key      VARCHAR2(1000):= NULL;       

       lc_errbuf         VARCHAR2(4000);
       lc_err_code       VARCHAR2(1000);

    BEGIN

       --
       -- Assign to the global variable
       --
       gn_header_id := p_order_header_id;
       
       --
       --Deriving Event Key from sequence
       --
       BEGIN
          SELECT xx_om_globalnotify_itemkey_s.NEXTVAL
          INTO   lc_event_key
          FROM   dual;            
       END;  

       --
       --Deleting values from parameter list
       --         
       IF lt_parameter_list.COUNT > 0 THEN
              lt_parameter_list.DELETE;
       END IF;       
       --
       -- Adding parameter to the parameter list
       --
       wf_event.addparametertolist('Mode'
                                   ,P_Mode
                                   ,lt_parameter_list
                                  );

       wf_event.addparametertolist('Cause'
                                   ,P_cause
                                   ,lt_parameter_list
                                  );

       wf_event.addparametertolist('Order_header_id'
                                   ,P_order_header_id
                                   ,lt_parameter_list
                                  );
       --
       -- Raise custom business event
       --
       WF_EVENT.RAISE(p_event_name  => 'oracle.apps.ont.order.gnotify.send'
                     ,p_event_key   => lc_event_key
                     ,p_parameters  => lt_parameter_list
                     );
       COMMIT;

    EXCEPTION
    WHEN OTHERS THEN

       ROLLBACK;

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR-1';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception(
                       p_error_code        => lc_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'Order Header Id'
                      ,p_entity_ref_id     => gn_header_id
                      );

   END To_Raise_Bussiness_Event;

END xx_om_globalnotification_pkg;
/
SHOW ERRORS;

EXIT;
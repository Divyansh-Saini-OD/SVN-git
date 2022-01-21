SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_WFL_CREATEPO_NON_TRADE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE BODY XX_WFL_CREATEPO_NON_TRADE
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name    :  PO TYPE-NON-TRADE                                        |
-- | Rice Id :  E1330                                                    |
-- | Description :   This Package facilitates in populating the PO type  |
-- |                 value in PO Headers which is needed for             |
-- |                 merchandising team to restrict the users from       |
-- |                 viewing the PO's                                    |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       18-JUL-2007   Chaitanya Nath.G      Initial version        |
-- |                       Wipro Technologies                            |
-- +=====================================================================+

-- +==========================================================================+
-- | Name        :   UPDATE_PO_TYPE_NON_TRADE                                 |
-- | Description :   This procedure facilitates in populating the PO type     |
-- |                 value in PO Headers which is needed for                  |
-- |                 merchandising team to restrict the users from            |
-- |                 viewing the PO's                                         |
-- |Parameters   :   p_itemtype, p_itemkey, p_actid, p_funcmode               |
-- |                                                                          |
-- | Returns     :   x_resultout                                              |
-- +==========================================================================+
    PROCEDURE UPDATE_PO_NON_TRADE (
                                  p_itemtype    IN         VARCHAR2
                                 ,p_itemkey     IN         VARCHAR2
                                 ,p_actid       IN         NUMBER
                                 ,p_funcmode    IN         VARCHAR2
                                 ,x_resultout   OUT NOCOPY VARCHAR2
                                 )
    AS
        ln_po_header_id           po_headers.po_header_id%TYPE;
        lc_apps_source_code       po_requisition_headers_all.apps_source_code%TYPE;
        lc_po_type                fnd_lookup_values.meaning%TYPE;
        lc_help_email             fnd_lookup_values.meaning%TYPE;
        lc_loc_err_msg            VARCHAR2(2000);
        lc_buyer_message          VARCHAR2(2000);
        lc_help_desk_det_message  VARCHAR2(2000);
        lc_error_loc              VARCHAR2(2000);
        lc_error_debug            VARCHAR2(2000);
        lc_po_type_notexists_flag VARCHAR2(1) := 'N';


    BEGIN

        IF ( p_funcmode = 'RUN') THEN

            --To get the PO Header ID
            ln_po_header_id := WF_ENGINE.GETITEMATTRNUMBER ( itemtype => p_itemtype
                                                            ,itemkey  => p_itemkey
                                                            ,aname    => 'AUTOCREATED_DOC_ID');

            --Getting the Email Address of OD Help Desk
            BEGIN
               lc_error_loc   := 'To get the email adress of OD HELP DESK from XX_IPO_PO_TYPE lookup';
               lc_error_debug := 'Lookup Type : XX_IPO_PO_TYPE--lookup_code : OD HELP DESK';
           
                SELECT meaning
                INTO   lc_help_email
                FROM   fnd_lookup_values
                WHERE  lookup_type = 'XX_IPO_PO_TYPE'
                AND    lookup_code = 'OD HELP DESK'
                AND    enabled_flag='Y'
                AND    SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1);

                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0072_BUYER');
                FND_MESSAGE.SET_TOKEN('EMAIL_ID',lc_help_email);
                lc_buyer_message :=  FND_MESSAGE.GET;

            EXCEPTION
            WHEN NO_DATA_FOUND THEN 

                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0069_NO_OD_HELP_DESK');
                lc_buyer_message :=  FND_MESSAGE.GET;
            
                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0066_ERROR');
                FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_loc_err_msg :=  FND_MESSAGE.GET;

                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'WORKFLOW PACKAGE'
                                     ,p_program_name            => 'XX_WFL_CREATEPO_NON_TRADE.UPDATE_PO_NON_TRADE'
                                     ,p_module_name             => 'PO'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_code      => 'XX_PO_0066_ERROR'
                                     ,p_error_message           => lc_loc_err_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Extension - PO TYPE'
                                     ,p_object_id               => 'E1330'); 

            END;
                
            WF_ENGINE.SETITEMATTRTEXT (
                                    itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'OD_HELP_DESK_EMAIL_ID'
                                   ,avalue   => lc_help_email
                                 );

            WF_ENGINE.SETITEMATTRTEXT (
                                    itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'BUYER_MSG'
                                   ,avalue   => lc_buyer_message
                                  );

            -- TO get the records with apps source code = POR
            BEGIN
               lc_error_loc   := 'Getting the records with apps source code as POR';
               lc_error_debug := 'apps_source_code : POR';

                SELECT     COUNT(1)
                INTO       lc_apps_source_code
                FROM       po_requisition_headers_all PRH
                           ,po_requisition_lines_all PRL
                           ,po_req_distributions_all PRD 
                           ,po_distributions_all PD
                           ,po_headers_all PHA
                WHERE      PHA.po_header_id = ln_po_header_id
                AND        PHA.po_header_id = PD.po_header_id 
                AND        PD.req_distribution_id = PRD.distribution_id
                AND        PRL.requisition_line_id = PRD.requisition_line_id
                AND        PRH.requisition_header_id = PRL.requisition_header_id
                AND        PRH.apps_source_code = 'POR';

            EXCEPTION
            WHEN NO_DATA_FOUND THEN

                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0073_NO_ROWS_POR');
                FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                lc_loc_err_msg :=  FND_MESSAGE.GET;
                
                XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'WORKFLOW PACKAGE'
                                     ,p_program_name            => 'XX_WFL_CREATEPO_NON_TRADE.UPDATE_PO_NON_TRADE'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'PO'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_code      => 'XX_PO_0073_NO_ROWS_POR'
                                     ,p_error_message           => lc_loc_err_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Extension - PO TYPE'
                                     ,p_object_id               => 'E1330');

            END;


            IF (lc_apps_source_code > 0 ) THEN
               --If the Requisition is from iProcurement
                BEGIN

                    lc_error_loc   := ' Getting the PO type  from XX_IPO_PO_TYPE lookup';
                    lc_error_debug := 'Lookup Type : XX_IPO_PO_TYPE--lookup_code : NON-TRADE'; 

                    SELECT   meaning
                    INTO     lc_po_type
                    FROM     fnd_lookup_values 
                    WHERE    lookup_type = 'XX_IPO_PO_TYPE'
                    AND      lookup_code = 'NON-TRADE'
                    AND      enabled_flag='Y'
                    AND      SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1);


                EXCEPTION
                WHEN NO_DATA_FOUND THEN 

                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0066_ERROR');
                    FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
                    FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
                    FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                    lc_loc_err_msg :=  FND_MESSAGE.GET;
                    lc_po_type_notexists_flag := 'Y';

                    FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0074_LOOKUP_NOT_SET');
                    lc_help_desk_det_message :=FND_MESSAGE.GET;


                    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'WORKFLOW PACKAGE'
                                     ,p_program_name            => 'XX_WFL_CREATEPO_NON_TRADE.UPDATE_PO_NON_TRADE'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'PO'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_code      => 'XX_PO_0066_ERROR'
                                     ,p_error_message           => lc_loc_err_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Extension - PO TYPE'
                                     ,p_object_id               => 'E1330');

                    
                END;

                WF_ENGINE.SETITEMATTRTEXT (
                                       itemtype => p_itemtype
                                      ,itemkey  => p_itemkey
                                      ,aname    => 'AUTO_APPROVE_DOC'
                                      ,avalue   => 'Y'
                                       );

                BEGIN

                    lc_error_loc   := ' Updating the base tables';
                    lc_error_debug := ''; 

                    IF (lc_po_type_notexists_flag = 'N') THEN

                        lc_error_loc := 'Updating the PO_HEADERS'; 
                        UPDATE  po_headers
                        SET     attribute_category = lc_po_type
                        WHERE   po_header_id = ln_po_header_id;


                        lc_error_loc := 'Updating the PO_LINES';
                        UPDATE po_lines
                        SET    attribute_category = lc_po_type
                        WHERE  po_header_id = ln_po_header_id;

                        lc_error_loc := 'Updating the PO_LINE_LOCATIONS';
                        UPDATE po_line_locations
                        SET    attribute_category = lc_po_type
                        WHERE  po_header_id = ln_po_header_id;

                        x_resultout :='ACTION_SUCCEEDED';

                    ELSE

                        lc_error_loc   := 'Setting Buyer Notif Message and Body';
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0070_ERROR_NOTIFY_SUB');
                        lc_loc_err_msg :=  FND_MESSAGE.GET;

                        WF_ENGINE.SETITEMATTRTEXT (
                                               itemtype => p_itemtype
                                              ,itemkey  => p_itemkey
                                              ,aname    => 'UPDATE_FAIL_MSG_SUB'
                                              ,avalue   => lc_loc_err_msg
                                               );



                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0071_ERROR_NOTIFY_BODY');
                        lc_loc_err_msg :=  FND_MESSAGE.GET;

                        WF_ENGINE.SETITEMATTRTEXT (
                                               itemtype => p_itemtype
                                              ,itemkey  => p_itemkey
                                              ,aname    => 'UPDATE_FAIL_MSG_BODY'
                                              ,avalue   => lc_loc_err_msg
                                               );

                        x_resultout :='ACTION_FAILED';

                    END IF;

                EXCEPTION
                WHEN OTHERS THEN

                        x_resultout :='ACTION_FAILED';
                        lc_help_desk_det_message := lc_help_desk_det_message||chr(10)||'Error Loc: '||lc_help_desk_det_message;
                        lc_help_desk_det_message := lc_help_desk_det_message||chr(10)||'Error Message: '||SQLERRM;
                        
                        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0066_ERROR');
                        FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);                        
                        FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
                        lc_loc_err_msg :=  FND_MESSAGE.GET;

                        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'WORKFLOW PACKAGE'
                                     ,p_program_name            => 'XX_WFL_CREATEPO_NON_TRADE.UPDATE_PO_NON_TRADE'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'PO'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_code      => 'XX_PO_0066_ERROR'
                                     ,p_error_message           => lc_loc_err_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Extension - PO TYPE'
                                     ,p_object_id               => 'E1330');
                                     
                        
                END;

                    WF_ENGINE.SETITEMATTRTEXT (
                                       itemtype => p_itemtype
                                      ,itemkey  => p_itemkey
                                      ,aname    => 'ODHELPDESKDETMSG'
                                      ,avalue   => lc_help_desk_det_message
                                       );

            ELSE

                --If the Requisition is not from iProcurement
                x_resultout :='ACTION_SUCCEEDED';

            END IF;

        END IF;

        
   END UPDATE_PO_NON_TRADE;
 -- +==========================================================================+
-- | Name        :   CHECK_HELP_DESK_EMAIL_ID                                 |
-- | Description :   This procedure checks if the OD Help Desk E-mail exists  |
-- |                 are not and updates the adhoc user                       |
-- |                                                                          |
-- |Parameters   :   p_itemtype, p_itemkey, p_actid, p_funcmode               |
-- |                                                                          |
-- | Returns     :   x_resultout                                              |
-- +==========================================================================+

    PROCEDURE CHECK_HELP_DESK_EMAIL_ID (
                                  p_itemtype    IN         VARCHAR2
                                 ,p_itemkey     IN         VARCHAR2
                                 ,p_actid       IN         NUMBER
                                 ,p_funcmode    IN         VARCHAR2
                                 ,x_resultout   OUT NOCOPY VARCHAR2
                                 )
    AS
        lc_email_address    wf_local_roles.email_address%TYPE;
    BEGIN

        IF ( p_funcmode = 'RUN') THEN

            lc_email_address := WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype
                                                           ,itemkey  => p_itemkey
                                                           ,aname    => 'OD_HELP_DESK_EMAIL_ID');

            IF (lc_email_address IS NOT NULL) THEN

                --Updating the E-mail address for the AdhocUser ODHELPDESK

                WF_DIRECTORY.SETADHOCUSERATTR( user_name       =>   'ODHELPDESK'      --Adhoc UserName
                                              ,email_address  =>   lc_email_address);

                x_resultout :='ACTION_SUCCEEDED';

            ELSE

                x_resultout := 'ACTION_FAILED';

            END IF;

        END IF;

    END CHECK_HELP_DESK_EMAIL_ID;

END XX_WFL_CREATEPO_NON_TRADE;
/
SHOW ERR
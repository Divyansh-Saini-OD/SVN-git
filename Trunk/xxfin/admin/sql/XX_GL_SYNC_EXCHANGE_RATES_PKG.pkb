SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_GL_SYNC_EXCHANGE_RATES_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_GL_SYNC_EXCHANGE_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name             :  XX_GL_SYNC_EXCHANGE_RATES_PKG                 |
-- | Description      :  Invoke the BPEL process to sync the currency  |
-- |                     exchange rates from Teradata                  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft    10-NOV-2009  Aravind A         Initial Version            |
-- |                                        for defect 3314            |
-- |1.1      12-JUL-2010  Sundaram S        Added for defect 4981      |
-- |1.2      17-Nov-2015  Avinash Baddam    R12.2 Compliance Changes   |
-- +===================================================================|

  PROCEDURE INVOKE_BPEL_PROCESS(
                                 x_ret_code         OUT     NUMBER
                                ,x_err_buff         OUT     VARCHAR2
                                ,p_req_system       IN      VARCHAR2     DEFAULT  'EBS'
                                ,p_start_date       IN      VARCHAR2     DEFAULT  NULL
                                ,p_end_date         IN      VARCHAR2
                                ,p_timeout          IN      PLS_INTEGER  DEFAULT  180
                               )
  IS
     lc_method            XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_namespace         XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_soap_action       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_url          XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_debug_mode        XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_process_name      XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_domain_name       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input1       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input2       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input3       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lr_req_typ           XX_FIN_BPEL_SOAP_API_PKG.request_rec_type   DEFAULT   NULL;
     lr_resp_typ          XX_FIN_BPEL_SOAP_API_PKG.response_rec_type  DEFAULT   NULL;
     lc_loc               VARCHAR2(3);
     lc_start_date        VARCHAR2(11);
     lc_end_date          VARCHAR2(11);

     PROCEDURE PUT_LOG_LINE(
                  p_buffer   IN   VARCHAR2
                 )
     IS
     BEGIN
        IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,p_buffer);
          -- else print to DBMS_OUTPUT
        ELSE
          DBMS_OUTPUT.PUT_LINE(p_buffer);
        END IF;
     END PUT_LOG_LINE;


  BEGIN

      lc_loc := '1';
      put_log_line(CHR(13)||CHR(13));
      put_log_line('-------------------- Invoking BPEL Process to Sync Currency Exchange rates from Teradata --------------------');
      put_log_line('p_req_system           : '||p_req_system);
      put_log_line('p_start_date           : '||p_start_date);
      put_log_line('p_end_date             : '||p_end_date);
      
      lc_start_date := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(p_start_date),'YYYY-MM-DD');
      lc_end_date   := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(p_end_date),'YYYY-MM-DD');

      put_log_line('Converted DATE parameters');
      put_log_line('lc_start_date           : '||lc_start_date);
      put_log_line('lc_end_date             : '||lc_end_date);

      lc_loc := '2';
      FOR lcu_bpel_param IN (SELECT   XFTV.source_value1
                                     ,XFTV.target_value1
                                     ,XFTV.target_value2
                             FROM     xx_fin_translatedefinition XFTD
                                     ,xx_fin_translatevalues XFTV
                             WHERE   XFTD.translate_id = XFTV.translate_id
                             AND     XFTD.translation_name = 'GL_SYNC_RATES_BPEL_SETUP'
                             AND     XFTV.target_value1 IN ('BPEL_INVOKE','BPEL_INPUT')
                             AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                             AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                             AND     XFTV.enabled_flag = 'Y'
                             AND     XFTD.enabled_flag = 'Y')
      LOOP
         IF (lcu_bpel_param.target_value1 = 'BPEL_INVOKE') THEN
            IF (lcu_bpel_param.source_value1 = 'METHOD') THEN 
                lc_method := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'NAMESPACE') THEN
                lc_namespace  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'SOAP_ACTION') THEN 
                lc_soap_action := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'URL') THEN
                lc_bpel_url    := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DEBUG_MODE') THEN
                lc_debug_mode  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'PROCESS_NAME') THEN
                lc_process_name := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DOMAIN_NAME') THEN
                lc_domain_name := lcu_bpel_param.target_value2;
            END IF;
         ELSIF (lcu_bpel_param.target_value1 = 'BPEL_INPUT') THEN
            IF (lcu_bpel_param.source_value1 = 'BPEL_INPUT1') THEN 
                lc_bpel_input1 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT2') THEN 
                lc_bpel_input2 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT3') THEN 
                lc_bpel_input3 := lcu_bpel_param.target_value2;
            END IF;
         END IF;
      END LOOP;

      lc_loc := '3';

      put_log_line('BPEL Parameters derived from GL_SYNC_RATES_BPEL_SETUP Translation');
      put_log_line('TIMEOUT           : '||p_timeout);
      put_log_line('METHOD            : '||lc_method);
      put_log_line('NAMESPACE         : '||lc_namespace);
      put_log_line('SOAP_ACTION       : '||lc_soap_action);
      put_log_line('URL               : '||lc_bpel_url);
      put_log_line('DEBUG_MODE        : '||lc_debug_mode);
      put_log_line('PROCESS_NAME      : '||lc_process_name);
      put_log_line('DOMAIN_NAME       : '||lc_domain_name);
      put_log_line('BPEL_INPUT1       : '||lc_bpel_input1);
      put_log_line('BPEL_INPUT2       : '||lc_bpel_input2);
      put_log_line('BPEL_INPUT3       : '||lc_bpel_input3);


      lc_loc := '4';
      lr_req_typ := XX_FIN_BPEL_SOAP_API_PKG.new_request(
                                                        lc_method
                                                        ,lc_namespace
                                                        );

      lc_loc := '5';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input1
                                            ,'xsd:string'
                                            ,p_req_system
                                            );

      lc_loc := '6';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input2
                                            ,'xsd:string'
                                            ,lc_start_date
                                            );

      lc_loc := '7';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input3
                                            ,'xsd:string'
                                            ,lc_end_date
                                            );

      put_log_line('BPEL Process Request/Response'||CHR(13));

      lc_loc := '8';
/*      lr_resp_typ := XX_FIN_BPEL_SOAP_API_PKG.invoke(
                                                     lr_req_typ
                                                    ,lc_bpel_url
                                                    ,lc_soap_action
                                                    ,p_timeout
                                                    );*/ -- Commented for defect 4981

-- Added for defect 4981 to invoke asynchronous process
--Start

      XX_FIN_BPEL_SOAP_API_PKG.invoke_asynch(
                                            lr_req_typ
                                            ,lc_bpel_url
                                            ,lc_soap_action
                                           );

--End

  EXCEPTION
     WHEN OTHERS THEN
        put_log_line('Error occured at '||lc_loc||' due to '||CHR(13)||SQLERRM);
  END INVOKE_BPEL_PROCESS;

END XX_GL_SYNC_EXCHANGE_RATES_PKG;

/

SHOW ERROR
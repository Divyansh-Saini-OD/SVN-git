SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_FIN_BPEL_SOAP_API_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_FIN_BPEL_SOAP_API_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name             :  XX_FIN_BPEL_SOAP_API_PKG                      |
-- | Description      :  Common API for BPEL invocations from PL/SQL   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft    10-NOV-2009  Aravind A         Initial Version            |
-- |1.0      29-DEC-2009  Aravind A         Fixed defect 3314          |
-- |1.1      12-JUL-2010  Sundaram S        Added for defect 4981      |
-- |                                                                   |
-- +===================================================================|

TYPE request_rec_type 
IS RECORD(
          method              VARCHAR2(256)
         ,namespace           VARCHAR2(256)
         ,msg_body            VARCHAR2(32767)
         ,envelope_tag        VARCHAR2(256)
         );

TYPE response_rec_type 
IS RECORD(
          resp_doc            XMLTYPE
         ,envelope_tag        VARCHAR2(256)
         );

PROCEDURE set_proxy_auth(
                         p_username  IN  VARCHAR2
                        ,p_password  IN  VARCHAR2
                        ,p_debug     IN  VARCHAR2   DEFAULT 'N'
                        );

FUNCTION new_request(
                     p_method        IN  VARCHAR2
                    ,p_namespace     IN  VARCHAR2
                    ,p_envelope_tag  IN  VARCHAR2   DEFAULT 'SOAP-ENV'
                    ,p_debug         IN  VARCHAR2   DEFAULT 'N'
                    )
RETURN request_rec_type;

PROCEDURE add_parameter(
                        p_request  IN OUT NOCOPY  request_rec_type
                       ,p_name     IN             VARCHAR2
                       ,p_type     IN             VARCHAR2
                       ,p_value    IN             VARCHAR2
                       ,p_debug    IN             VARCHAR2   DEFAULT 'N'
                       );

FUNCTION invoke(
                p_request  IN OUT NOCOPY  request_rec_type
               ,p_url      IN             VARCHAR2
               ,p_action   IN             VARCHAR2
               ,p_debug    IN             VARCHAR2     DEFAULT 'N'
               ,p_timeout  IN             PLS_INTEGER  DEFAULT 180   --Fixed defect 3314
               )
RETURN response_rec_type;

PROCEDURE invoke_asynch(
                p_request  IN OUT NOCOPY  request_rec_type
               ,p_url      IN             VARCHAR2
               ,p_action   IN             VARCHAR2
               ,p_debug    IN             VARCHAR2     DEFAULT 'N'
               ); -- Added for defect 4981

FUNCTION get_return_value(
                          p_response   IN OUT NOCOPY  response_rec_type
                         ,p_name       IN             VARCHAR2
                         ,p_namespace  IN             VARCHAR2
                         ,p_debug      IN             VARCHAR2   DEFAULT 'N'
                         )
RETURN VARCHAR2;

END XX_FIN_BPEL_SOAP_API_PKG;

/

SHOW ERROR
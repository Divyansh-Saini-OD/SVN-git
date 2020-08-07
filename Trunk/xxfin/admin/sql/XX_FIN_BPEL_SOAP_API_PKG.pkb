  SET SHOW OFF  
  SET VERIFY OFF   
  SET ECHO OFF   
  SET TAB OFF   
  SET FEEDBACK OFF   
  SET TERM ON   
     
  PROMPT Creating PACKAGE BODY XX_FIN_BPEL_SOAP_API_PKG   
     
  PROMPT Program exits IF the creation IS NOT SUCCESSFUL   
     
  WHENEVER SQLERROR CONTINUE   
     
  CREATE OR REPLACE PACKAGE BODY XX_FIN_BPEL_SOAP_API_PKG 
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
-- |1.1      12-JUL-2010  Sundaram S        Added for Defect 4981      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================|

gc_proxy_username     VARCHAR2(256)   DEFAULT NULL;
gc_proxy_password     VARCHAR2(256)   DEFAULT NULL;

PROCEDURE set_proxy_auth(
                         p_username  IN  VARCHAR2
                        ,p_password  IN  VARCHAR2
                        ,p_debug     IN  VARCHAR2   DEFAULT 'N'
                        )
AS
BEGIN
   gc_proxy_username := p_username;
   gc_proxy_password := p_password;
END set_proxy_auth;

FUNCTION new_request(
                     p_method        IN  VARCHAR2
                    ,p_namespace     IN  VARCHAR2
                    ,p_envelope_tag  IN  VARCHAR2   DEFAULT 'SOAP-ENV'
                    ,p_debug         IN  VARCHAR2   DEFAULT 'N'
                    )
RETURN request_rec_type
AS
lr_request_typ   request_rec_type;
BEGIN

   lr_request_typ.method        :=  p_method;
   lr_request_typ.namespace     :=  p_namespace;
   lr_request_typ.envelope_tag  :=  p_envelope_tag;

   RETURN  lr_request_typ;
END new_request;

PROCEDURE add_parameter(
                        p_request  IN OUT NOCOPY  request_rec_type
                       ,p_name     IN             VARCHAR2
                       ,p_type     IN             VARCHAR2
                       ,p_value    IN             VARCHAR2
                       ,p_debug    IN             VARCHAR2   DEFAULT 'N'
                       )
AS
BEGIN
FND_FILE.put_line(FND_FILE.LOG,'Addparameter');

p_request.msg_body  := p_request.msg_body||'<'||p_name||' xsi:type="'||p_type||'">'||p_value||'</'||p_name||'>';

FND_FILE.put_line(FND_FILE.LOG,p_request.msg_body);
END add_parameter;


PROCEDURE generate_envelope(p_request  IN OUT NOCOPY  request_rec_type
                           ,p_env      IN OUT NOCOPY  VARCHAR2)
AS

BEGIN
FND_FILE.put_line(FND_FILE.LOG,'Into generate envelop');
  p_env := '<'||p_request.envelope_tag||':Envelope xmlns:'||p_request.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/" ' ||
               'xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">' ||
             '<'||p_request.envelope_tag||':Body>' ||
               '<'||p_request.method||' '||p_request.namespace||' '||p_request.envelope_tag||':encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' ||
                   p_request.msg_body ||
               '</'||p_request.method||'>' ||
             '</'||p_request.envelope_tag||':Body>' ||
           '</'||p_request.envelope_tag||':Envelope>';
FND_FILE.put_line(FND_FILE.LOG,'exit');
END generate_envelope;


PROCEDURE show_envelope(p_env  IN  VARCHAR2)
AS
   i      PLS_INTEGER;
   l_len  PLS_INTEGER;
BEGIN
   i := 1; l_len := LENGTH(p_env);
   WHILE (i <= l_len) LOOP
     IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
       FND_FILE.put_line(FND_FILE.LOG,NVL(SUBSTR(p_env, i, 60),' '));
       -- else print to DBMS_OUTPUT
     ELSE
       DBMS_OUTPUT.put_line(SUBSTR(p_env, i, 60));
     END IF;
     i := i + 60;
   END LOOP;
END show_envelope;


PROCEDURE check_fault(p_response IN OUT NOCOPY  response_rec_type)
AS
   lt_fault_node_typ       XMLTYPE;
   lc_fault_code           VARCHAR2(256);
   lc_fault_string         VARCHAR2(32767);
BEGIN
   lt_fault_node_typ := p_response.resp_doc.extract('/'||p_response.envelope_tag||':Fault',
                                           'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/');
   IF (lt_fault_node_typ IS NOT NULL) THEN
      lc_fault_code   := lt_fault_node_typ.extract('/'||p_response.envelope_tag||':Fault/faultcode/child::text()',
                                            'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
      lc_fault_string := lt_fault_node_typ.extract('/'||p_response.envelope_tag||':Fault/faultstring/child::text()',
                                            'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
      RAISE_APPLICATION_ERROR(-20000, lc_fault_code || ' - ' || lc_fault_string);
   END IF;
END check_fault;


FUNCTION invoke(
                p_request  IN OUT NOCOPY  request_rec_type
               ,p_url      IN             VARCHAR2
               ,p_action   IN             VARCHAR2
               ,p_debug    IN             VARCHAR2     DEFAULT 'N'
               ,p_timeout  IN             PLS_INTEGER  DEFAULT 180   --Fixed defect 3314
               )
RETURN response_rec_type
AS
   lc_envelope          VARCHAR2(32767);
   lr_http_request      UTL_HTTP.req;
   lr_http_response     UTL_HTTP.resp;
   lr_response_typ      response_rec_type;
   lc_loc               VARCHAR2(100) := '0';
BEGIN
   lc_loc := '1';
   generate_envelope(
                     p_request
                    ,lc_envelope
                    );
   lc_loc := '2';
   lr_http_request := UTL_HTTP.begin_request(
                                             p_url
                                            ,'POST','HTTP/1.0'
                                            );
   lc_loc := '3';
   IF gc_proxy_username IS NOT NULL THEN
      lc_loc := '4';
      UTL_HTTP.set_authentication(
                                  r         => lr_http_request
                                 ,username  => gc_proxy_username
                                 ,password  => gc_proxy_password
                                 ,scheme    => 'Basic'
                                 ,for_proxy => TRUE
                                 );
      lc_loc := '5';
   END IF;
   lc_loc := '6';
   UTL_HTTP.set_header(lr_http_request, 'Content-Type', 'text/xml');
   lc_loc := '7';
   UTL_HTTP.set_header(lr_http_request, 'Content-Length', LENGTH(lc_envelope));
   lc_loc := '8';
   UTL_HTTP.set_header(lr_http_request, 'SOAPAction', p_action);
   UTL_HTTP.set_transfer_timeout(lr_http_request,p_timeout);   --Fixed defect 3314
   lc_loc := '9';
   show_envelope(lc_envelope);
   UTL_HTTP.write_text(lr_http_request, lc_envelope);
   lc_loc := '10';
   lr_http_response := UTL_HTTP.get_response(lr_http_request);
   lc_loc := '11';
   UTL_HTTP.read_text(lr_http_response, lc_envelope);
   lc_loc := '12';
   UTL_HTTP.end_response(lr_http_response);
   lc_loc := '13';
   show_envelope(lc_envelope);
   lc_loc := '14';
   lr_response_typ.resp_doc := XMLTYPE.createxml(lc_envelope);
   lc_loc := '15';
   lr_response_typ.envelope_tag := p_request.envelope_tag;
   lc_loc := '16';
   lr_response_typ.resp_doc := lr_response_typ.resp_doc.extract('/'||lr_response_typ.envelope_tag||':Envelope/'||lr_response_typ.envelope_tag||':Body/child::node()',
                                           'xmlns:'||lr_response_typ.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/"');
   lc_loc := '17';
   check_fault(lr_response_typ);
   lc_loc := '18';
   RETURN lr_response_typ;
EXCEPTION
   WHEN OTHERS THEN
      IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
        FND_FILE.put_line(FND_FILE.LOG,'Error at '|| lc_loc ||' due to '||SQLERRM);
        -- else print to DBMS_OUTPUT
      ELSE
        DBMS_OUTPUT.put_line('Error at '|| lc_loc ||' due to '||SQLERRM);
      END IF;
END invoke;

--Procedure added to invoke asynchronous process for defect 4981
--Start

PROCEDURE invoke_asynch(
                p_request  IN OUT NOCOPY  request_rec_type
               ,p_url      IN             VARCHAR2
               ,p_action   IN             VARCHAR2
               ,p_debug    IN             VARCHAR2     DEFAULT 'N'
               )
AS
   lc_envelope          VARCHAR2(32767);
   lr_http_request      UTL_HTTP.req;
   lr_http_response     UTL_HTTP.resp;
   lr_response_typ      response_rec_type;
   lc_loc               VARCHAR2(100) := '0';
BEGIN
   lc_loc := '1';
   generate_envelope(
                     p_request
                    ,lc_envelope
                    );
   lc_loc := '2';
   lr_http_request := UTL_HTTP.begin_request(
                                             p_url
                                            ,'POST','HTTP/1.1'
                                            );
   lc_loc := '3';
   IF gc_proxy_username IS NOT NULL THEN
      lc_loc := '4';
      UTL_HTTP.set_authentication(
                                  r         => lr_http_request
                                 ,username  => gc_proxy_username
                                 ,password  => gc_proxy_password
                                 ,scheme    => 'Basic'
                                 ,for_proxy => TRUE
                                 );
      lc_loc := '5';
   END IF;
   lc_loc := '6';
   UTL_HTTP.set_header(lr_http_request, 'Content-Type', 'text/xml');
   lc_loc := '7';
   UTL_HTTP.set_header(lr_http_request, 'Content-Length', LENGTH(lc_envelope));
   lc_loc := '8';
   UTL_HTTP.set_header(lr_http_request, 'SOAPAction', p_action);
   UTL_HTTP.set_transfer_timeout(lr_http_request,240); 
   lc_loc := '9';
   show_envelope(lc_envelope);
   UTL_HTTP.write_text(lr_http_request, lc_envelope);
   lc_loc := '10';
   lr_http_response := UTL_HTTP.get_response(lr_http_request);


EXCEPTION
   WHEN UTL_HTTP.TRANSFER_TIMEOUT THEN
      NULL;
   WHEN OTHERS THEN
      IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
        FND_FILE.put_line(FND_FILE.LOG,'Error at '|| lc_loc ||' due to '||SQLERRM);
        -- else print to DBMS_OUTPUT
      ELSE
        DBMS_OUTPUT.put_line('Error at '|| lc_loc ||' due to '||SQLERRM);
      END IF;
END invoke_asynch;

-- End 
-- For defect 4981

FUNCTION get_return_value(
                          p_response   IN OUT NOCOPY  response_rec_type
                         ,p_name       IN             VARCHAR2
                         ,p_namespace  IN             VARCHAR2
                         ,p_debug      IN             VARCHAR2   DEFAULT 'N'
                         )
RETURN VARCHAR2
AS
BEGIN
   IF p_response.resp_doc.extract('//'||p_name||'/child::text()',p_namespace) IS NOT NULL THEN
      RETURN p_response.resp_doc.extract('//'||p_name||'/child::text()',p_namespace).getstringval();
   ELSE
      RETURN NULL;
   END IF;
END get_return_value;

END XX_FIN_BPEL_SOAP_API_PKG;
/

SHOW ERROR

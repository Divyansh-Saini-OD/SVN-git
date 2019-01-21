SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CRM_SOAP_API 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CRM_SOAP_API.pks                                |
-- | Description :  SOAP Message calls generic package                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  29-Sep-2009 Indra Varada       Initial draft version     |
-- +===================================================================+

AS

g_proxy_username  VARCHAR2(50) := NULL;
g_proxy_password  VARCHAR2(50) := NULL;


-- ---------------------------------------------------------------------
PROCEDURE set_proxy_authentication(p_username  IN  VARCHAR2,
                                   p_password  IN  VARCHAR2) AS
-- ---------------------------------------------------------------------
BEGIN
  g_proxy_username := p_username;
  g_proxy_password := p_password;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
FUNCTION new_request(p_method        IN  VARCHAR2,
                     p_namespace     IN  VARCHAR2,
                     p_envelope_tag  IN  VARCHAR2 DEFAULT 'SOAP-ENV')
  RETURN t_request AS
-- ---------------------------------------------------------------------
  l_request  t_request;
BEGIN
  l_request.method       := p_method;
  l_request.namespace    := p_namespace;
  l_request.envelope_tag := p_envelope_tag;
  RETURN l_request;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE add_parameter(p_request    IN OUT NOCOPY  t_request,
                        p_name   IN             VARCHAR2,
                        p_type   IN             VARCHAR2,
                        p_value  IN             VARCHAR2) AS
-- ---------------------------------------------------------------------
BEGIN
  p_request.body := p_request.body||'<'||p_name||' xsi:type="'||p_type||'">'||p_value||'</'||p_name||'>';
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE generate_envelope(p_request  IN OUT NOCOPY  t_request,
		                        p_env      IN OUT NOCOPY  VARCHAR2) AS
-- ---------------------------------------------------------------------
BEGIN
  p_env := '<'||p_request.envelope_tag||':Envelope xmlns:'||p_request.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/" ' ||
               'xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">' ||
             '<'||p_request.envelope_tag||':Body>' ||
               '<'||p_request.method||' '||p_request.namespace||' '||p_request.envelope_tag||':encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' ||
                   p_request.body ||
               '</'||p_request.method||'>' ||
             '</'||p_request.envelope_tag||':Body>' ||
           '</'||p_request.envelope_tag||':Envelope>';
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE show_envelope(p_env  IN  VARCHAR2) AS
-- ---------------------------------------------------------------------
  i      PLS_INTEGER;
  l_len  PLS_INTEGER;
BEGIN
  i := 1; l_len := LENGTH(p_env);
  WHILE (i <= l_len) LOOP
    DBMS_OUTPUT.put_line(SUBSTR(p_env, i, 60));
    i := i + 60;
  END LOOP;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE check_fault(p_response IN OUT NOCOPY  t_response) AS
-- ---------------------------------------------------------------------
  l_fault_node    XMLTYPE;
  l_fault_code    VARCHAR2(256);
  l_fault_string  VARCHAR2(32767);
BEGIN
  l_fault_node := p_response.doc.extract('/'||p_response.envelope_tag||':Fault',
                                         'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/');
  IF (l_fault_node IS NOT NULL) THEN
    l_fault_code   := l_fault_node.extract('/'||p_response.envelope_tag||':Fault/faultcode/child::text()',
                                           'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
    l_fault_string := l_fault_node.extract('/'||p_response.envelope_tag||':Fault/faultstring/child::text()',
                                           'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
    RAISE_APPLICATION_ERROR(-20000, l_fault_code || ' - ' || l_fault_string);
  END IF;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
FUNCTION invoke(p_request IN OUT NOCOPY  t_request,
                p_url     IN             VARCHAR2,
                p_action  IN             VARCHAR2)
  RETURN t_response AS
-- ---------------------------------------------------------------------
  l_envelope       VARCHAR2(32767);
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_response       t_response;
BEGIN
  generate_envelope(p_request, l_envelope);
  --show_envelope(l_envelope);
  l_http_request := UTL_HTTP.begin_request(p_url, 'POST','HTTP/1.0');
  IF g_proxy_username IS NOT NULL THEN
    UTL_HTTP.set_authentication(r         => l_http_request,
                                username  => g_proxy_username,
                                password  => g_proxy_password,
                                scheme    => 'Basic',
                                for_proxy => TRUE);                               
  END IF;
  UTL_HTTP.set_header(l_http_request, 'Content-Type', 'text/xml');
  UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_envelope));
  UTL_HTTP.set_header(l_http_request, 'SOAPAction', p_action);
  UTL_HTTP.write_text(l_http_request, l_envelope);
  l_http_response := UTL_HTTP.get_response(l_http_request);
  UTL_HTTP.read_text(l_http_response, l_envelope);
  UTL_HTTP.end_response(l_http_response);
  show_envelope(l_envelope);
  l_response.doc := XMLTYPE.createxml(l_envelope);
  l_response.envelope_tag := p_request.envelope_tag;
  l_response.doc := l_response.doc.extract('/'||l_response.envelope_tag||':Envelope/'||l_response.envelope_tag||':Body/child::node()',
                                           'xmlns:'||l_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/"');
  -- show_envelope(l_response.doc.getstringval());
  check_fault(l_response);
  RETURN l_response;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
FUNCTION get_return_value(p_response   IN OUT NOCOPY  t_response,
                          p_name       IN             VARCHAR2,
                          p_namespace  IN             VARCHAR2)
  RETURN VARCHAR2 AS
-- ---------------------------------------------------------------------
BEGIN
  IF p_response.doc.extract('//'||p_name||'/child::text()',p_namespace) IS NOT NULL THEN
   RETURN p_response.doc.extract('//'||p_name||'/child::text()',p_namespace).getstringval();
  ELSE
   RETURN NULL;
  END IF;
END;
-- ---------------------------------------------------------------------

END XX_CRM_SOAP_API;
/
SHOW ERRORS;

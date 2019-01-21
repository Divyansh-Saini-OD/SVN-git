SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CRM_SOAP_API

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

TYPE t_request IS RECORD (
  method        VARCHAR2(256),
  namespace     VARCHAR2(256),
  body          VARCHAR2(32767),
  envelope_tag  VARCHAR2(30)
);

TYPE t_response IS RECORD
(
  doc           XMLTYPE,
  envelope_tag  VARCHAR2(30)
);

PROCEDURE set_proxy_authentication(p_username  IN  VARCHAR2,
                                   p_password  IN  VARCHAR2);

FUNCTION new_request(p_method        IN  VARCHAR2,
                     p_namespace     IN  VARCHAR2,
                     p_envelope_tag  IN  VARCHAR2 DEFAULT 'SOAP-ENV')
  RETURN t_request;


PROCEDURE add_parameter(p_request  IN OUT NOCOPY  t_request,
                        p_name     IN             VARCHAR2,
                        p_type     IN             VARCHAR2,
                        p_value    IN             VARCHAR2);

FUNCTION invoke(p_request  IN OUT NOCOPY  t_request,
                p_url      IN             VARCHAR2,
                p_action   IN             VARCHAR2)
  RETURN t_response;

FUNCTION get_return_value(p_response   IN OUT NOCOPY  t_response,
                          p_name       IN             VARCHAR2,
                          p_namespace  IN             VARCHAR2)
RETURN VARCHAR2;

END XX_CRM_SOAP_API;
/
SHOW ERRORS;

SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_bpel_utility_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_OM_BPEL_UTILITY_PKG                                     |
-- | Rice ID     : I0215_OrdtoPOS                                             |
-- | Description : Custom Package containing utility procedures and functions |
-- |               to invoke a BPEL process from PL/SQL.                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |DRAFT 1A 30-May-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      30-May-2007 Vidhya Valantina T     Baselined after testing       |
-- |                                                                          |
-- +==========================================================================+

AS                                      -- Package Block

    -- +===================================================================+
    -- | Name        : Create_New_Request                                  |
    -- | Description : Function to create a new SOAP RPC request           |
    -- |                                                                   |
    -- | Parameters  : Method                                              |
    -- |               Namespace                                           |
    -- |                                                                   |
    -- | Returns     : SOAP RPC Request                                    |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION Create_New_Request(
        p_method    IN VARCHAR2
       ,p_namespace IN VARCHAR2
    ) RETURN soap_request_rec_type
    AS

        lr_req soap_request_rec_type;

    BEGIN

        lr_req.method    := p_method;
        lr_req.namespace := p_namespace;

        RETURN lr_req;

    END Create_New_Request;

    -- +===================================================================+
    -- | Name        : Add_Parameter                                       |
    -- | Description : Function to add parameter to a SOAP RPC request     |
    -- |                                                                   |
    -- | Parameters  : SOAP RPC Request                                    |
    -- |               Name                                                |
    -- |               Type                                                |
    -- |               Value                                               |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Add_Parameter(
        p_req_rec IN OUT NOCOPY soap_request_rec_type
       ,p_name    IN            VARCHAR2
       ,p_type    IN            VARCHAR2
       ,p_value   IN            VARCHAR2
    )
    AS

    BEGIN

        p_req_rec.body :=        p_req_rec.body ||
                         '<'  || p_name         ||' xsi:type="'||p_type|| '">'
                              || p_value        ||
                         '</' || p_name         || '>';

    END Add_Parameter;

    -- +===================================================================+
    -- | Name        : Generate_Envelope                                   |
    -- | Description : Function to generate a SOAP Envelope                |
    -- |                                                                   |
    -- | Parameters  : SOAP RPC Request                                    |
    -- |               Env                                                 |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Generate_Envelope(
        p_req_rec IN OUT NOCOPY soap_request_rec_type
       ,p_env     IN OUT NOCOPY VARCHAR2
    )
    AS

    BEGIN

        p_env := '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema"> <SOAP-ENV:Body '
                                    || p_req_rec.namespace
                           || '> <' || p_req_rec.method
                           || '> '  || p_req_rec.body
                           || ' </' || p_req_rec.method
                           || '> </SOAP-ENV:Body> </SOAP-ENV:Envelope>';

    END Generate_Envelope;

    -- +===================================================================+
    -- | Name        : Show_Envelope                                       |
    -- | Description : Function to construct a SOAP Envelope               |
    -- |                                                                   |
    -- | Parameters  : Env                                                 |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Show_Envelope(
        p_env IN VARCHAR2
    )
    AS

        ln_indx   PLS_INTEGER;
        ln_len    PLS_INTEGER;

    BEGIN

        ln_indx := 1;
        ln_len  := LENGTH(p_env);

        WHILE (ln_indx <= ln_len)
        LOOP

            Dbms_Output.Put_Line(SUBSTR(p_env, ln_indx, 60));

            ln_indx := ln_indx + 60;

        END LOOP;

    END Show_Envelope;

    -- +===================================================================+
    -- | Name        : Check_Fault                                         |
    -- | Description : Function to check fault in a SOAP RPC Response      |
    -- |                                                                   |
    -- | Parameters  : SOAP RPC Response                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Check_Fault(
        p_resp_rec IN OUT NOCOPY soap_response_rec_type
    )
    AS

        lc_fault_code   VARCHAR2(256);
        lc_fault_string VARCHAR2(32767);

        lx_fault_node   XMLTYPE;

    BEGIN

      lx_fault_node := p_resp_rec.doc.extract( '/soap:Fault'
                  ,'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/');

      IF ( lx_fault_node IS NOT NULL ) THEN

        lc_fault_code   := lx_fault_node.extract(
                        '/soap:Fault/faultcode/child::text()'
                       ,'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/'
                       ).getstringval();
        lc_fault_string := lx_fault_node.extract(
                        '/soap:Fault/faultstring/child::text()'
                       ,'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/'
                       ).getstringval();

        Raise_Application_Error(-20000,lc_fault_code||' - '||lc_fault_string);

      END IF;

    END Check_Fault;

    -- +===================================================================+
    -- | Name        : Invoke                                              |
    -- | Description : Function to invoke a BPEL Process using SOAP        |
    -- |                                                                   |
    -- | Parameters  : SOAP RPC Request                                    |
    -- |               Url                                                 |
    -- |               Action                                              |
    -- |                                                                   |
    -- | Returns     : SOAP RPC Response                                   |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION Invoke(
        p_req_rec  IN OUT NOCOPY soap_request_rec_type
       ,p_url      IN            VARCHAR2
       ,p_action   IN            VARCHAR2
    ) RETURN soap_response_rec_type
    AS

        lc_env       VARCHAR2(32767);

        lr_resp      soap_response_rec_type;

        http_req     UTL_HTTP.Req;
        http_resp    UTL_HTTP.Resp;

    BEGIN

      --
      -- Generate the SOAP Envelope
      --

      Generate_Envelope( p_req_rec => p_req_rec
                        ,p_env     => lc_env );

      --
      -- Print the SOAP Envelope
      --

      -- Show_Envelope( lc_env );

      --
      -- Creating a HTTP Request
      --

      http_req := UTL_HTTP.Begin_Request(  p_url
                                         ,'POST'
                                         ,'HTTP/1.0' );

      UTL_HTTP.Set_Header( http_req , 'Content-Type'  , 'text/xml' );
      UTL_HTTP.Set_Header( http_req , 'Content-Length', LENGTH(lc_env) );
      UTL_HTTP.Set_Header( http_req , 'SOAPAction'    , p_action );
      UTL_HTTP.Write_Text( http_req , lc_env );

      --
      -- Getting a HTTP Response
      --

      http_resp := UTL_HTTP.Get_Response( http_req );

      UTL_HTTP.Read_Text( http_resp , lc_env );
      UTL_HTTP.End_Response( http_resp );

      --
      -- Creating the SOAP RPC Response
      --

      lr_resp.doc := XMLTYPE.CreateXML( lc_env );

      lr_resp.doc := lr_resp.doc.extract(
                    '/soap:Envelope/soap:Body/child::node()'
                   ,'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"' );

      --
      -- Print the SOAP Envelope
      --

      -- Show_Envelope( lr_resp.doc.getstringval() );

      --
      -- Check the SOAP Response
      --

      Check_Fault( lr_resp );

      RETURN lr_resp;

    END Invoke;

    -- +===================================================================+
    -- | Name        : Get_Return_Value                                    |
    -- | Description : Function to get the return value from a BPEL Process|
    -- |                                                                   |
    -- | Parameters  : SOAP RPC Response                                   |
    -- |               Url                                                 |
    -- |               Action                                              |
    -- |                                                                   |
    -- | Returns     : String                                              |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION Get_Return_Value(
        p_resp_rec  IN OUT NOCOPY soap_response_rec_type
       ,p_name      IN            VARCHAR2
       ,p_namespace IN            VARCHAR2
    ) RETURN VARCHAR2
    AS

    BEGIN

        RETURN p_resp_rec.doc.extract('//'||p_name||'/child::text()'
                                     ,p_namespace).getstringval();

    END Get_Return_Value;


    -- +===================================================================+
    -- | Name        : Bpel_Process_Caller                                 |
    -- | Description : Function to invoke the BPEL Process from PL/SQL     |
    -- |                                                                   |
    -- | Parameters  : Bpel_Name        - Exact name of the BPEL Process   |
    -- |               Target_Namespace - Obtained from <bpel>.wsdl File   |
    -- |               Param_Names      - Input Parameters List for BPEL   |
    -- |               Param_Values     - Input Parameter Values           |
    -- |               Bpel_Url         - Exact URL of the BPEL Process    |
    -- |               Action           - Operation that needs to be invoked
    -- |               Bpel_Output      - Output of the BPEL process       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Bpel_Process_Caller(
        p_bpel_name        IN         VARCHAR2
       ,p_target_namespace IN         VARCHAR2
       ,p_param_names      IN         xx_om_bpel_paramlist_t
       ,p_param_values     IN         xx_om_bpel_paramlist_t
       ,p_bpel_url         IN         VARCHAR2
       ,p_action           IN         VARCHAR2
       ,p_bpel_output      OUT NOCOPY VARCHAR2
    )
    AS
        ln_indx     PLS_INTEGER;

        lr_req      xx_om_bpel_utility_pkg.soap_request_rec_type;
        lr_resp     xx_om_bpel_utility_pkg.soap_response_rec_type;

    BEGIN

        lr_req        := Create_New_Request (
                             p_method    => 'tns0:'|| p_bpel_name || 'ProcessRequest'
                            ,p_namespace => 'xmlns:tns0="'||p_target_namespace||'"' );

        Dbms_Output.Put_Line('Raised a SOAP RPC Request');

        FOR ln_indx IN p_param_names.FIRST .. p_param_names.LAST
        LOOP

            Add_Parameter(  p_req_rec => lr_req
                           ,p_name    => 'tns0:'||p_param_names(ln_indx)
                           ,p_type    => 'xsd:string'
                           ,p_value   => p_param_values(ln_indx) );

        END LOOP;

        lr_resp       := Invoke( p_req_rec => lr_req
                                ,p_url     => p_bpel_url
                                ,p_action  => p_action);

        p_bpel_output := Get_Return_Value( p_resp_rec  => lr_resp
                                          ,p_name      => 'result'
                                          ,p_namespace => 'xmlns="'||p_target_namespace||'"' );

    END Bpel_Process_Caller;

END xx_om_bpel_utility_pkg;             -- End Package Block
/

SHOW ERRORS;
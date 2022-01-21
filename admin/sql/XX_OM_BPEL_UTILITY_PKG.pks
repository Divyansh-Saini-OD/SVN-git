SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_bpel_utility_pkg AUTHID CURRENT_USER

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

-- -----------------
-- Type Declarations
-- -----------------

  --
  -- Database Type to represent a SOAP RPC request
  --

  TYPE soap_request_rec_type IS RECORD(
       method     VARCHAR2(256)
      ,namespace  VARCHAR2(256)
      ,body       VARCHAR2(32767)
  );

  --
  -- Database Type to represent a SOAP RPC response
  --

  TYPE soap_response_rec_type IS RECORD (
       doc        XMLTYPE
  );

-- ---------------------
-- Function Declarations
-- ---------------------

  --
  -- Function to create a new SOAP RPC request
  --

    FUNCTION Create_New_Request(
        p_method    IN VARCHAR2
       ,p_namespace IN VARCHAR2
    ) RETURN soap_request_rec_type;

  --
  -- Function to make the SOAP RPC call
  --

    FUNCTION Invoke(
        p_req_rec  IN OUT NOCOPY soap_request_rec_type
       ,p_url      IN            VARCHAR2
       ,p_action   IN            VARCHAR2
    ) RETURN soap_response_rec_type;

  --
  -- Function to retrieve the simple return
  -- value of the SOAP RPC call
  --

    FUNCTION Get_Return_Value(
        p_resp_rec  IN OUT NOCOPY soap_response_rec_type
       ,p_name      IN            VARCHAR2
       ,p_namespace IN            VARCHAR2
    ) RETURN VARCHAR2;

  --
  -- Procedure to add parameter to the SOAP RPC request
  --

    PROCEDURE Add_Parameter(
        p_req_rec IN OUT NOCOPY soap_request_rec_type
       ,p_name    IN            VARCHAR2
       ,p_type    IN            VARCHAR2
       ,p_value   IN            VARCHAR2
    );

  --
  -- Procedure to call a BPEL Process using SOAP Envelope
  --

    PROCEDURE Bpel_Process_Caller(
        p_bpel_name        IN         VARCHAR2
       ,p_target_namespace IN         VARCHAR2
       ,p_param_names      IN         xx_om_bpel_paramlist_t
       ,p_param_values     IN         xx_om_bpel_paramlist_t
       ,p_bpel_url         IN         VARCHAR2
       ,p_action           IN         VARCHAR2
       ,p_bpel_output      OUT NOCOPY VARCHAR2
    );

END xx_om_bpel_utility_pkg;             -- End Package Block
/

SHOW ERRORS;
CREATE OR REPLACE PACKAGE APPS.XX_XDO_REQUESTS_API_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUESTS_API_PKG                                                            | 
-- |  Description:  This package is an API that to creates and processes requests in the        | 
-- |                XDO Request tables.                                                         |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         19-Jun-2007  B.Looman         Initial version                                  | 
-- | 2.0         06-Apr-2017  Havish Kasina    Added a new procedure process_irec_request       |
-- +============================================================================================+ 
 
 
GT_PROCESS_STATUS_PENDING           CONSTANT VARCHAR2(20)     := 'PENDING';     -- default for req, doc, dest
GT_PROCESS_STATUS_PROCESSING        CONSTANT VARCHAR2(20)     := 'PROCESSING';  -- used on req, doc, dest
GT_PROCESS_STATUS_GENERATED         CONSTANT VARCHAR2(20)     := 'GENERATED';   -- used on doc
GT_PROCESS_STATUS_ATTACHED          CONSTANT VARCHAR2(20)     := 'ATTACHED';    -- used on doc
GT_PROCESS_STATUS_SENDING           CONSTANT VARCHAR2(20)     := 'SENDING';     -- used on dest
GT_PROCESS_STATUS_SENT              CONSTANT VARCHAR2(20)     := 'SENT';        -- used on dest
GT_PROCESS_STATUS_COMPLETED         CONSTANT VARCHAR2(20)     := 'COMPLETED';   -- used on req, doc, dest
GT_PROCESS_STATUS_ARCHIVED          CONSTANT VARCHAR2(20)     := 'ARCHIVED';    -- used on req, doc, dest


TYPE GT_XDO_REQUESTS_TAB IS TABLE OF XX_XDO_REQUESTS%ROWTYPE
  INDEX BY BINARY_INTEGER;
  
TYPE GT_XDO_REQUEST_DOCS_TAB IS TABLE OF XX_XDO_REQUEST_DOCS%ROWTYPE
  INDEX BY BINARY_INTEGER;
  
TYPE GT_XDO_REQ_DATA_PARAM_TAB IS TABLE OF XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE
  INDEX BY BINARY_INTEGER;
  
TYPE GT_XDO_REQUEST_DESTS_TAB IS TABLE OF XX_XDO_REQUEST_DESTS%ROWTYPE
  INDEX BY BINARY_INTEGER;
  
G_MISS_XDO_REQUESTS_TAB           GT_XDO_REQUESTS_TAB;
G_MISS_REQUEST_DOCS_TAB           GT_XDO_REQUEST_DOCS_TAB;
G_MISS_REQ_DATA_PARAM_TAB         GT_XDO_REQ_DATA_PARAM_TAB;
G_MISS_REQUEST_DESTS_TAB          GT_XDO_REQUEST_DESTS_TAB;


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_STATUS                                                               | 
-- |  Description: This procedure updates the process_status for the given XDO request.         | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id, process_status                                               | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_status
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_STATUS_NOW                                                           | 
-- |  Description: This procedure updates the process_status for the given XDO request using    |
-- |                 an autonomous transaction to update the record immediately.                | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id, process_status                                               | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_status_now
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_STATUS_ALL                                                           | 
-- |  Description: This procedure updates the process_status for the given XDO request and      |
-- |                 child records (documents and destinations).                                | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id, process_status                                               | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_status_all
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_DOC_STATUS                                                           |
-- |  Description: This procedure updates the process_status for the given XDO request doc.     | 
-- |                                                                                            | 
-- |  Parameters:  xdo_document_id, process_status                                              | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_doc_status
( p_xdo_document_id        IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_DOC_STATUS_NOW                                                       |
-- |  Description: This procedure updates the process_status for the given XDO request doc      |
-- |                 using an autonomous transaction to update the record immediately.          | 
-- |                                                                                            | 
-- |  Parameters:  xdo_document_id, process_status                                              | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_doc_status_now
( p_xdo_document_id        IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_DEST_STATUS                                                          |
-- |  Description: This procedure updates the process_status for the given XDO request dest.    | 
-- |                                                                                            | 
-- |  Parameters:  xdo_destination_id, process_status                                           | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_dest_status
( p_xdo_destination_id     IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: UPDATE_REQUEST_DEST_STATUS_NOW                                                      |
-- |  Description: This procedure updates the process_status for the given XDO request dest     |
-- |                 using an autonomous transaction to update the record immediately.          | 
-- |                                                                                            | 
-- |  Parameters:  xdo_destination_id, process_status                                           | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_request_dest_status_now
( p_xdo_destination_id     IN   NUMBER,
  p_process_status         IN   VARCHAR2 );


-- +============================================================================================+ 
-- |  Name: CREATE_XDO_REQUEST                                                                  | 
-- |  Description: This procedure creates an XDO request.                                       | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request - XDO Request rowtype containing data to insert                | 
-- |                                                                                            | 
-- |  Returns:     x_xdo_request - current XDO Request rowtype values                           |  
-- +============================================================================================+ 
PROCEDURE create_xdo_request
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  x_xdo_request              OUT NOCOPY     XX_XDO_REQUESTS%ROWTYPE );


-- +============================================================================================+ 
-- |  Name: CREATE_XDO_REQUEST_DOC                                                              | 
-- |  Description: This procedure creates an XDO request document.                              | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request_doc - XDO Request document rowtype containing data to insert   | 
-- |               p_xdo_req_data_param_tab - XDO Request data parameter table rowtype          |
-- |                 containing data to insert (defaults to missing - no parameters)            | 
-- |                                                                                            | 
-- |  Returns:     x_xdo_request_doc - current XDO Request document rowtype values              |
-- |               x_xdo_req_data_param_tab - current XDO Request data parameter table rowtype  |
-- |                 values                                                                     | 
-- +============================================================================================+ 
PROCEDURE create_xdo_request_doc
( p_xdo_request_doc          IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE,
  p_xdo_req_data_param_tab   IN             GT_XDO_REQ_DATA_PARAM_TAB    DEFAULT G_MISS_REQ_DATA_PARAM_TAB,  
  x_xdo_request_doc          OUT NOCOPY     XX_XDO_REQUEST_DOCS%ROWTYPE,
  x_xdo_req_data_param_tab   OUT NOCOPY     GT_XDO_REQ_DATA_PARAM_TAB );


-- +============================================================================================+ 
-- |  Name: CREATE_XDO_REQUEST_DATA_PARAM                                                       | 
-- |  Description: This procedure creates an XDO request data parameter.                        | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request_data_param - XDO Request data parameter rowtype containing     |
-- |                 data to insert                                                             | 
-- |                                                                                            | 
-- |  Returns:     x_xdo_request_data_param - current XDO Request data parameter rowtype values |
-- +============================================================================================+ 
PROCEDURE create_xdo_request_data_param
( p_xdo_request_data_param   IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE,
  x_xdo_request_data_param   OUT NOCOPY     XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE );


-- +============================================================================================+ 
-- |  Name: CREATE_XDO_REQUEST_DEST                                                             | 
-- |  Description: This procedure creates an XDO request destination.                           | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request_dest - XDO Request destination rowtype with data to insert     | 
-- |                                                                                            | 
-- |  Returns:     x_xdo_request_dest - current XDO Request destination rowtype values          |
-- +============================================================================================+ 
PROCEDURE create_xdo_request_dest
( p_xdo_request_dest         IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE,
  x_xdo_request_dest         OUT NOCOPY     XX_XDO_REQUEST_DESTS%ROWTYPE );
  
  
-- +============================================================================================+ 
-- |  Name: ADD_XDO_REQUEST_DOC                                                                 | 
-- |  Description: This procedure adds an XDO request document to the given XDO Request         |
-- |                 including data parameters if given (defaults to missing - no parameters)   | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request - current XDO Request rowtype                                  | 
-- |               p_xdo_request_doc - XDO Request document rowtype containing data to insert   | 
-- |               p_xdo_req_data_param_tab - XDO Request data parameter table rowtype          |
-- |                 containing data to insert (defaults to missing - no parameters)            | 
-- |                                                                                            | 
-- |  Returns:     x_xdo_request_doc - current XDO Request document rowtype values              |
-- |               x_xdo_req_data_param_tab - current XDO Request data parameter table rowtype  |
-- |                 values                                                                     | 
-- +============================================================================================+ 
PROCEDURE add_xdo_request_doc
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_doc          IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE,
  p_xdo_req_data_param_tab   IN             GT_XDO_REQ_DATA_PARAM_TAB    DEFAULT G_MISS_REQ_DATA_PARAM_TAB,
  x_xdo_request_doc          OUT NOCOPY     XX_XDO_REQUEST_DOCS%ROWTYPE,
  x_xdo_req_data_param_tab   OUT NOCOPY     GT_XDO_REQ_DATA_PARAM_TAB );


-- +============================================================================================+ 
-- |  Name: ADD_XDO_REQUEST_DEST                                                                | 
-- |  Description: This procedure adds an XDO request destination to the given XDO Request      | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request - current XDO Request rowtype                                  | 
-- |               p_xdo_request_dest - XDO Request destination rowtype with values             | 
-- |                                                                                            |
-- |  Returns:     x_xdo_request_dest - current XDO Request destination table rowtype records   |
-- +============================================================================================+ 
PROCEDURE add_xdo_request_dest
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_dest         IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE,
  x_xdo_request_dest         OUT NOCOPY     XX_XDO_REQUEST_DESTS%ROWTYPE );


-- +============================================================================================+ 
-- |  Name: CREATE_NEW_REQUEST                                                                  | 
-- |  Description: This procedure creates an XDO request (along with the documents and          | 
-- |                 destinations.                                                              | 
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request - XDO Request rowtype containing data to insert                | 
-- |               p_xdo_request_doc_tab - XDO Request document table rowtype with records      |
-- |                 to insert                                                                  |  
-- |               p_xdo_request_dest_tab - XDO Request destination table rowtype with          |
-- |                 records to insert                                                          | 
-- |                                                                                            |
-- |  Returns:     x_xdo_request - current XDO Request rowtype values                           | 
-- |               x_xdo_request_docs_tab - current XDO Request document table rowtype          |  
-- |               x_xdo_request_dests_tab - current XDO Request destination table rowtype      |
-- +============================================================================================+ 
PROCEDURE create_new_request
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_docs_tab     IN OUT NOCOPY  GT_XDO_REQUEST_DOCS_TAB,
  p_xdo_request_dests_tab    IN OUT NOCOPY  GT_XDO_REQUEST_DESTS_TAB,
  x_xdo_request              OUT NOCOPY     XX_XDO_REQUESTS%ROWTYPE,
  x_xdo_request_docs_tab     OUT NOCOPY     GT_XDO_REQUEST_DOCS_TAB,
  x_xdo_request_dests_tab    OUT NOCOPY     GT_XDO_REQUEST_DESTS_TAB );


-- +============================================================================================+ 
-- |  Name: PROCESS_REQUEST                                                                     | 
-- |  Description: This procedure submits the Java Concurrent Program to submit the XDO         |
-- |                 request[s] through the XML Publisher Delivery Engine.                      |
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request_group_id - XDO Request Group ID (used to group XDO Requests    |
-- |                 to run together)                                                           |
-- |               p_xdo_request_id (optional) - XDO Request Group ID (if null, it will submit  |
-- |                 all XDO Requests for the given group)                                      |
-- |               p_wait_for_completion - wait for the completion of the submitted concurrent  |
-- |                 program before returning                                                   |
-- |               p_request_name - The desired name of the Concurrent Program when viewed in   |
-- |                 "View Requests"                                                            |
-- |                                                                                            | 
-- |  Returns:     Concurrent Program Request ID - request id of submitted program for          |
-- |                 XDO Request processing                                                     |
-- +============================================================================================+ 
FUNCTION process_request
( p_xdo_request_group_id     IN   NUMBER,
  p_xdo_request_id           IN   NUMBER    DEFAULT NULL ,
  p_wait_for_completion      IN   VARCHAR2  DEFAULT 'N',
  p_request_name             IN   VARCHAR2  DEFAULT NULL )
RETURN NUMBER;

-- +============================================================================================+ 
-- |  Name: PROCESS_IREC_REQUEST                                                                | 
-- |  Description: This procedure submits the Java Concurrent Program to submit the XDO         |
-- |                 request[s] through the XML Publisher Delivery Engine.                      |
-- |                                                                                            | 
-- |  Parameters:  p_xdo_request_group_id - XDO Request Group ID (used to group XDO Requests    |
-- |                 to run together)                                                           |
-- |               p_xdo_request_id (optional) - XDO Request Group ID (if null, it will submit  |
-- |                 all XDO Requests for the given group)                                      |
-- |               p_wait_for_completion - wait for the completion of the submitted concurrent  |
-- |                 program before returning                                                   |
-- |               p_request_name - The desired name of the Concurrent Program when viewed in   |
-- |                 "View Requests"                                                            |
-- |                                                                                            | 
-- |  Returns:     Concurrent Program Request ID - request id of submitted program for          |
-- |                 XDO Request processing                                                     |
-- +============================================================================================+ 
FUNCTION process_irec_request
( p_xdo_request_group_id     IN   NUMBER,
  p_xdo_request_id           IN   NUMBER    DEFAULT NULL ,
  p_wait_for_completion      IN   VARCHAR2  DEFAULT 'N',
  p_request_name             IN   VARCHAR2  DEFAULT NULL )
RETURN NUMBER;


END;
/  
SHOW ERRORS;
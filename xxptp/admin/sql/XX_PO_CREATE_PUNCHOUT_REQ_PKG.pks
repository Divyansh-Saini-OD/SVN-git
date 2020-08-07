SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_PO_CREATE_PUNCHOUT_REQ_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE xx_po_create_punchout_req_pkg 
AS

  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_CREATE_PUNCHOUT_REQ_PKG                                                      |
  -- |                                                                                            |
  -- |  Description:  This package is used to create the Purchase Requisitions automatically 	  | 
  -- |                for Puchout Cancelled Requisition Lines                                     |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         10-OCT-2017  Suresh Naragam   Initial version                                  |
  -- +============================================================================================+

  xx_po_req_hdr_rec            po_requisition_headers_all%ROWTYPE;
  
  TYPE xx_po_req_line_tab_type IS TABLE OF po_requisition_lines_all%ROWTYPE
                               INDEX BY BINARY_INTEGER;
  xx_po_req_line_tbl           xx_po_req_line_tab_type;
  
  PROCEDURE create_purchase_requisition(po_req_return_status    OUT VARCHAR2,
                                        po_req_return_message   OUT VARCHAR2,
                                        po_submit_req_import    OUT VARCHAR2,
                                        pi_debug_flag           IN  BOOLEAN,
                                        pi_batch_id             IN  NUMBER,
                                        pi_req_header_rec       IN  xx_po_req_hdr_rec%TYPE,
                                        pi_req_line_detail_tab  IN  xx_po_req_line_tbl%TYPE,
                                        pi_translation_info     IN  xx_fin_translatevalues%ROWTYPE);  

  PROCEDURE send_req_import_errors(errbuf     OUT VARCHAR2,
                                   retcode    OUT VARCHAR2);  
                                 
END xx_po_create_punchout_req_pkg;       
/

SHOW ERR                         
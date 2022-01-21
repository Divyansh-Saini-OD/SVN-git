SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xx_po_scm_data_insert AS
  -- +============================================================================================      +
  -- |  Office Depot                                                                                    |
  -- |                                                                                                  |
  -- +============================================================================================      +
  -- |  Name  :  xx_po_scm_data_insert                                                            	    | 
  -- |  RICE ID   :  I2193_PO to EBS Interface                                   				        | 
  -- |  Description:  Load PO Interface Data from file to Staging Tables                                |
  -- |                                                                          				        | 
  -- |                          																        | 
  -- +============================================================================================      +
  -- | Version     Date         Author           Remarks                                                |
  -- | =========   ===========  =============    =================================================      |
  -- | 1.0         04/10/2017   Phuoc Nguyen     Initial version                                        |
  -- +============================================================================================      +

    PROCEDURE load_scm_data(
        p_scm_header_data   IN OUT NOCOPY xx_po_scm_hdr_obj,
        p_scm_line_data     IN OUT NOCOPY xx_po_scm_lines_tab,
        p_return_code       OUT VARCHAR2,
        p_return_msg        OUT VARCHAR2
    );

END xx_po_scm_data_insert;
/
SHOW ERROR;
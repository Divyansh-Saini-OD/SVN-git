create or replace PACKAGE XX_TDM_PO_TRADE_EXTRACT
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_TDM_PO_TRADE_EXTRACT                                                           |
-- |  RICE ID 	 :  I----_PO to EBS Interface     			                        |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/14/2018   Phuoc Nguyen     Initial version                                  |
-- +============================================================================================+

PROCEDURE trade_po_extract
(
        p_error_msg     OUT VARCHAR2,
        p_return_code   OUT VARCHAR2,
        p_file_dir      IN VARCHAR2,
        p_file_name     IN VARCHAR2,
        p_send_to_tdm   IN VARCHAR2,
        p_date          IN VARCHAR2,
        p_num_days      IN NUMBER,
        p_po_number     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_one_off       IN VARCHAR2
);

END XX_TDM_PO_TRADE_EXTRACT;
/
SHOW ERROR
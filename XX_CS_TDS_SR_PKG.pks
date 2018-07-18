create or replace
PACKAGE XX_CS_TDS_SR_PKG AS

 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_SR_PKG                                         |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       21-Apr-10   Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Create_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_TDS_SR_REC_TYPE,
                                 x_request_id       out nocopy number,
                                 x_request_num      out nocopy varchar2,
                                 x_order_num        out nocopy varchar2,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL);

PROCEDURE CREATE_NOTE ( p_request_id    in number,
                        p_sr_notes_rec     in XX_CS_SR_NOTES_REC,
                        p_return_status    in out nocopy varchar2,
                        p_msg_data         in out nocopy varchar2);

Procedure Update_ServiceRequest(p_sr_number        in varchar2,
                                p_sr_status_id     in VARCHAR2,
                                p_cancel_log       in VARCHAR2,
                                p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                                x_return_status    in out nocopy varchar2,
                                x_msg_data         in out nocopy varchar2);
                                
PROCEDURE ENQUEUE_MESSAGE(P_REQUEST_ID  IN NUMBER,
                          P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                          P_RETURN_MSG  IN OUT NOCOPY VARCHAR2);
                          

PROCEDURE SUB_UPDATES(P_REQUEST_ID  IN NUMBER,
                      P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                      P_RETURN_MSG  IN OUT NOCOPY VARCHAR2);

END XX_CS_TDS_SR_PKG;
/

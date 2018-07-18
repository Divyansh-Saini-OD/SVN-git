create or replace
PACKAGE XX_CS_SERVICEREQUEST_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_SERVICEREQUEST_PKG                                 |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-Apr-07   Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Create_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 p_request_id       in out nocopy number,
                                 p_request_num      in out nocopy varchar2,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL);


PROCEDURE Search_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_sr_req_tbl       in out nocopy XX_CS_SR_TBL_TYPE,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2);

PROCEDURE Search_Single_SR (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                            p_sr_req_tbl       in out nocopy XX_CS_SR_TBL_TYPE,
                            p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                            p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                            x_return_status    in out nocopy varchar2,
                            x_msg_data         in out nocopy varchar2);

PROCEDURE Search_notes (p_request_id    in number,
                        p_sr_notes_tbl  in out nocopy XX_CS_SR_NOTES_TBL,
                        p_ecom_site_key in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                        p_return_status in out nocopy varchar2,
                        p_msg_data      in out nocopy varchar2);

PROCEDURE CREATE_NOTE ( p_request_id    in number,
                        p_sr_notes_rec     in XX_CS_SR_NOTES_REC,
                        p_return_status    in out nocopy varchar2,
                        p_msg_data         in out nocopy varchar2);
                        
PROCEDURE get_service_notes (p_request_id    in number,
                            p_sr_notes_tbl  in out nocopy XX_CS_TDS_NOTES_TBL,
                            p_ecom_site_key in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                            p_return_status in out nocopy varchar2,
                            p_msg_data      in out nocopy varchar2);    

Procedure Update_ServiceRequest(p_sr_request_id    in number,
                                p_sr_status_id     in varchar2,
                                p_sr_notes         in XX_CS_SR_NOTES_REC,
                                p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                p_user_id          in varchar2,
                                x_return_status    in out nocopy varchar2,
                                x_msg_data         in out nocopy varchar2);

FUNCTION GLOBAL_TICKET_NUMBER (P_INCIDENT_ID IN NUMBER,
                               P_GLOBAL_TICKET IN NUMBER,
                               P_GLOBAL_TICKET_FLAG IN VARCHAR2) RETURN NUMBER;


FUNCTION GET_GLOBAL_TICKET (P_INCIDENT_ID IN NUMBER) RETURN NUMBER;

END XX_CS_SERVICEREQUEST_PKG;
/

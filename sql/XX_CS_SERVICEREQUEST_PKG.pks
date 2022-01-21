CREATE OR REPLACE
PACKAGE "XX_CS_SERVICEREQUEST_PKG" AS

PROCEDURE Create_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 p_request_id       in out nocopy number,
                                 p_request_num      in out nocopy number,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL);


PROCEDURE Search_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
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

Procedure Update_ServiceRequest(p_sr_request_id    in number,
                                p_sr_status_id     in number,
                                p_sr_notes         in XX_CS_SR_NOTES_REC,
                                p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                p_user_id          in varchar2,
                                x_return_status    in out nocopy varchar2,
                                x_msg_data         in out nocopy varchar2);

END;

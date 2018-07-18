create or replace
PROCEDURE TEST_CREATE_TDS_SR AS
  P_SR_REQ_REC    APPS.XX_CS_TDS_SR_REC_TYPE;
  P_REQUEST_ID NUMBER;
  P_REQUEST_NUM varchar2(25);
  l_ORDER_NUM VARCHAR2(150);
  X_RETURN_STATUS VARCHAR2(200);
  X_MSG_DATA VARCHAR2(200);
  P_ORDER_TBL APPS.XX_CS_SR_ORDER_TBL;
  l_order_rec XX_CS_SR_ORDER_REC_TYPE;
  I               BINARY_INTEGER;
BEGIN

  P_REQUEST_ID := NULL;
  P_REQUEST_NUM := NULL;
  X_RETURN_STATUS := NULL;
  X_MSG_DATA := NULL;
  I := 1;
  P_ORDER_TBL := XX_CS_SR_ORDER_TBL();
  l_order_rec := XX_CS_SR_ORDER_REC_TYPE(' ',' ',' ',null,null,null,null,null,null,null,null,null);

  
  p_sr_req_rec := XX_CS_TDS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL);
                                
  
p_sr_req_rec.description	:= 'Tech Depot Services';
p_sr_req_rec.comments	:= 'testing with contact type';
p_sr_req_rec.user_id            := 491862;
p_sr_req_rec.request_date       := sysdate;
p_sr_req_rec.order_number       := '041146493001';
p_sr_req_rec.customer_id        := '31816538';
p_sr_req_rec.ship_to            := '00001';
p_sr_req_rec.location_id        := '00091';
--p_sr_req_rec.global_ticket_number      := 6448;
p_sr_req_rec.contact_name  := 'Raj jagarlamudi';
p_sr_req_rec.contact_phone := '999999999';
p_sr_req_rec.contact_id := '00000002472435';



  XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST(
    P_SR_REQ_REC => P_SR_REQ_REC,
    x_REQUEST_ID => P_REQUEST_ID,
    x_REQUEST_NUM => P_REQUEST_NUM,
    X_ORDER_NUM => l_ORDER_NUM,
    X_RETURN_STATUS => X_RETURN_STATUS,
    X_MSG_DATA => X_MSG_DATA,
    P_ORDER_TBL => P_ORDER_TBL
  );
  

  DBMS_OUTPUT.PUT_LINE('P_REQUEST_ID = ' || P_REQUEST_ID);
  DBMS_OUTPUT.PUT_LINE('P_REQUEST_NUM = ' || P_REQUEST_NUM);
  DBMS_OUTPUT.PUT_LINE('X_RETURN_STATUS = ' || X_RETURN_STATUS);
  DBMS_OUTPUT.PUT_LINE('X_MSG_DATA = ' || X_MSG_DATA);


END TEST_CREATE_TDS_SR;
/

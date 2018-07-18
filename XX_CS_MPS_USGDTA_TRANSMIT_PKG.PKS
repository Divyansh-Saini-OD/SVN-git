SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CS_MPS_USGDTA_TRANSMIT_PKG
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_USGDTA_TRANSMIT_PKG.pks                                                   |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        21-MAY-2013   Sreedhar Mohan	    Send Usage Data to Vendor periodically            |
-- +==============================================================================================+
AS

--Send Usage Data to a Customer                   
PROCEDURE TRANSMIT_USAGE_DATA(    p_errbuf            OUT NOCOPY VARCHAR2
                                , p_retcode           OUT NOCOPY VARCHAR2
                                , p_party_id          IN         NUMBER
                                , p_sr_number         IN         VARCHAR2);

--Update Usage Parameters to MPS Devices
PROCEDURE UPDATE_USAGE_PARAMS(    p_errbuf                  OUT NOCOPY VARCHAR2
                                , p_retcode                 OUT NOCOPY VARCHAR2
                                , p_aops_cust_id            IN         NUMBER  
                                , p_notification_date       IN         VARCHAR2 
                                , p_period_covered_st_date  IN         VARCHAR2 
                                , p_period_covered_end_date IN         VARCHAR2 
                                , p_usage_send_lead_days    IN         NUMBER );

--Update Usage Parameters -req number and service_credit to MPS Device Details
PROCEDURE UPDATE_REQ_NUMBER(      p_errbuf                  OUT NOCOPY VARCHAR2
                                , p_retcode                 OUT NOCOPY VARCHAR2
                                , p_aops_cust_id            IN         NUMBER  
                                , p_request_number          IN         VARCHAR2 
                                , p_service_credit          IN         NUMBER );

END XX_CS_MPS_USGDTA_TRANSMIT_PKG;
/
show errors;

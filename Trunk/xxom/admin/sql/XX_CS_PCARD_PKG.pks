CREATE OR REPLACE
PACKAGE "XX_CS_PCARD_PKG" AS
                        
FUNCTION PCARD_DECRYPT (P_SR_NUMBER IN VARCHAR2) RETURN VARCHAR2;
                        
FUNCTION ENC_PCARD_RULE_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2;
                            
PROCEDURE encrypt_attachment (p_incident_id in number);

PROCEDURE PCARD_DECRYPT_FILE (P_REQUEST_ID IN VARCHAR2);
            
END;
/
show errors;
exit;


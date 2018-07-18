create or replace
PACKAGE XX_CS_CUSTOM_EVENT_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
   FUNCTION CS_CUST_RULE_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2;

   FUNCTION CS_SR_STATUS_Func(p_subscription_guid in raw,
                             p_event in out nocopy WF_EVENT_T) RETURN varchar2;

   FUNCTION CS_SR_OWNER_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2;

  FUNCTION CS_WH_Func(p_subscription_guid in raw,
                     p_event in out nocopy WF_EVENT_T) RETURN varchar2;

  FUNCTION CS_WH_ESC_Func(p_subscription_guid in raw,
                     p_event in out nocopy WF_EVENT_T) RETURN varchar2;

                          
END XX_CS_CUSTOM_EVENT_PKG;
/
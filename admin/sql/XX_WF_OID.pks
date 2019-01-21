create or replace
package wf_oid AUTHID CURRENT_USER as
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_WF_OID.pkb                                      |
-- | Description :  Customized WF_OID package for setting up           |
-- |                configurable apps_initialize session               |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1   27-OCT-2014 Sreedhar Mohan     Initial draft version     |
-- |1.1       27-MAY-2015 Manikant Kasu      Made code changes to      |
-- |                                         capture error logs as per |
-- |                                         Defect # 33463            |
-- |1.2       23-Aug-2016 Vasu Raparla       Retrofitted for 12.2.5    |
-- |                                          upgrade                  |
-- +===================================================================+
/* $Header: WFOIDS.pls 120.2 2005/09/14 17:44:06 scheruku noship $ */
  -- Event Types --

  ENTRY_ADD            CONSTANT VARCHAR2(32) := 'ENTRY_ADD';
  ENTRY_DELETE         CONSTANT VARCHAR2(32) := 'ENTRY_DELETE';
  ENTRY_MODIFY         CONSTANT VARCHAR2(32) := 'ENTRY_MODIFY';

  USER_ADD             CONSTANT VARCHAR2(32) := 'USER_ADD';
  USER_DELETE          CONSTANT VARCHAR2(32) := 'USER_DELETE';
  USER_MODIFY          CONSTANT VARCHAR2(32) := 'USER_MODIFY';

  IDENTITY_ADD         CONSTANT VARCHAR2(32) := 'IDENTITY_ADD';
  IDENTITY_DELETE      CONSTANT VARCHAR2(32) := 'IDENTITY_DELETE';
  IDENTITY_MODIFY      CONSTANT VARCHAR2(32) := 'IDENTITY_MODIFY';

  GROUP_ADD            CONSTANT VARCHAR2(32) := 'GROUP_ADD';
  GROUP_DELETE         CONSTANT VARCHAR2(32) := 'GROUP_DELETE';
  GROUP_MODIFY         CONSTANT VARCHAR2(32) := 'GROUP_MODIFY';

  SUBSCRIBER_ADD       CONSTANT VARCHAR2(32) := 'SUBSCRIBER_ADD';
  SUBSCRIBER_DELETE    CONSTANT VARCHAR2(32) := 'SUBSCRIBER_DELETE';
  SUBSCRIBER_MODIFY    CONSTANT VARCHAR2(32) := 'SUBSCRIBER_MODIFY';

  SUBSCRIPTION_ADD     CONSTANT VARCHAR2(32) := 'SUBSCRIPTION_ADD';
  SUBSCRIPTION_DELETE  CONSTANT VARCHAR2(32) := 'SUBSCRIPTION_DELETE';
  SUBSCRIPTION_MODIFY  CONSTANT VARCHAR2(32) := 'SUBSCRIPTION_MODIFY';

  -- Attribute Types --

  ATTR_TYPE_STRING            CONSTANT NUMBER  := 0;
  ATTR_TYPE_BINARY            CONSTANT NUMBER  := 1;
  ATTR_TYPE_ENCRYPTED_STRING  CONSTANT NUMBER  := 2;
  ATTR_TYPE_DATE              CONSTANT NUMBER  := 3;

  -- The Attribute Modification Type --

  MOD_ADD              CONSTANT NUMBER  := 0;
  MOD_DELETE           CONSTANT NUMBER  := 1;
  MOD_REPLACE          CONSTANT NUMBER  := 2;

  -- The Event dispostions constants --

  EVENT_SUCCESS        CONSTANT VARCHAR2(32)  := 'EVENT_SUCCESS';
  EVENT_ERROR          CONSTANT VARCHAR2(32)  := 'EVENT_ERROR';
  EVENT_RESEND         CONSTANT VARCHAR2(32)  := 'EVENT_RESEND';

    -- Error Code is 0 for SUCCESS and non-zero for Errors and Resends --

  -- Return values for GetEvent --

  EVENT_FOUND          CONSTANT NUMBER  := 0;
  EVENT_NOT_FOUND      CONSTANT NUMBER  := 1403;

-----------------------------------------------------------------------------
/*
** PutOIDEvent - (OID --> EBiz) Receives the event status as an OUT parameter.
*/
PROCEDURE PutOIDEvent(event         IN  LDAP_EVENT,
                      event_status  OUT NOCOPY LDAP_EVENT_STATUS);
-----------------------------------------------------------------------------
/*
** GetAppEvent - (EBiz --> OID)
*/
FUNCTION GetAppEvent(event OUT NOCOPY LDAP_EVENT) return number;
-----------------------------------------------------------------------------
/*
** PutAppEventStatus -
*/
PROCEDURE PutAppEventStatus(event_status IN LDAP_EVENT_STATUS);
-----------------------------------------------------------------------------
/*
** user_change - rule function for the OID subscription to user.change events
*/
FUNCTION user_change(p_subscription_guid in            raw,
                     p_event             in out nocopy wf_event_t)
return varchar2;
-----------------------------------------------------------------------------
/*
** get_oid_session - establish OID session using SSL based on
**                   wf parameter values.
*/
FUNCTION get_oid_session return dbms_ldap.session;
-----------------------------------------------------------------------------
/*
** unbind - close OID session
*/
PROCEDURE unbind(p_session in out nocopy dbms_ldap.session);
-----------------------------------------------------------------------------
/*
** future_callback - Called when future events come due.
*/
PROCEDURE future_callback(p_parameters in wf_parameter_list_t default null);
-----------------------------------------------------------------------------
/*
** get_oid_debug_flag - check for debug level to capture logs.
*/
FUNCTION get_oid_debug_flag return varchar2;
-----------------------------------------------------------------------------
/*
** purge_data - purging log table for records more than 30 days old.
*/
Procedure Purge_Data(P_Aging_Days In NUMBER DEFAULT 30);
-----------------------------------------------------------------------------

END WF_OID;
/
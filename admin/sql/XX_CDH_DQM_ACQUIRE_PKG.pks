SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_DQM_ACQUIRE_PKG IS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CDH_DQM_ACQUIRE                                                        |
-- | Description : Functions for DQM aquisition of attributes. These functions are called    |
-- |               from DQM Match rules (Configuration)                                      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |DRAFT      01-MAY-2007     Sreekanth B          Initial draft version                    |
-- |1.0        14-JUN-2007     Sreekanth B          Include Sales Channel for Search         |
-- |2.0        18-Oct-2007     Rajeev Kamath        Add Contact-to-Site search capabilities  |
-- |2.1        22-Oct-2007     Rajeev Kamath        Add Function for BES on Site-Contact     |
-- |3.0        07-Dec-2007     Rajeev Kamath        Removed Address_Style; Change Related_id |
-- |                                                to related_number                        |
-- |4.0        24-Jan-2008     Sreedhar Mohan       Added function Get_Locationto search     |
-- |                                                based on location from hz_cust_site uses |
-- |5.0        12-Mar-2007     Rajeev Kamath        Added transformations for postal codes   |
-- +=========================================================================================+

FUNCTION   Get_Micr_Num (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_Cust_Category (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_Email_Contact (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_OD_Cust_Type (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_Ship_To_Seq (
        p_party_site_id IN      NUMBER,
        p_entity        IN      VARCHAR2,
        p_attribute     IN      VARCHAR2,
        p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_Sales_Channel (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION Get_Related_Org_Name (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION Get_Related_Org_Number (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

FUNCTION   Get_Location (
                          p_party_site_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL
                        )
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Address
FUNCTION Get_Contact_Ext_Address (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: City
FUNCTION Get_Contact_Ext_City (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: State
FUNCTION Get_Contact_Ext_State (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: County
FUNCTION Get_Contact_Ext_County (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Province
FUNCTION Get_Contact_Ext_Province (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address:Postal Code
FUNCTION Get_Contact_Ext_Postal_Code (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Country
FUNCTION Get_Contact_Ext_Country (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : Party_Site_Contact_Change                            |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will be re-stage a contact if there is |
-- |              any change (Create/Update) to the Party-Site Extended|
-- |              attribute group "SITE_CONTACTS"                      |
-- +===================================================================+   
FUNCTION Party_Site_Contact_Change(p_subscription_guid  IN             RAW,
                                   p_event              IN OUT NOCOPY  WF_EVENT_T) 
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : Account_Site_Use_Change                              |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will re-stage a party site if there is |
-- |              any change (Create/Update) to the Account-Site-Use   |
-- |              "Location" attribute is sourced from here            |
-- +===================================================================+   
FUNCTION Account_Site_Use_Change(p_subscription_guid  IN             RAW,
                                 p_event              IN OUT NOCOPY  WF_EVENT_T) 
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_3                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 3 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_3 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;


-- +===================================================================+
-- | Name       : trans_rmspl_substr_4                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 4 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_4 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_5                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 5 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_5 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_6                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 6 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_6 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_7                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 7 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_7 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_8                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 8 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_8 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name       : trans_rmspl_substr_9                                 |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: Remove spaces and returns first 9 characters for DQM |
-- +===================================================================+   
FUNCTION   trans_rmspl_substr_9 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +====================================================================+
-- | Name       : trans_rmspl_substr_10                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 10 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_10 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +====================================================================+
-- | Name       : trans_rmspl_substr_13                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 13 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_13 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;

-- +====================================================================+
-- | Name       : trans_rmspl_substr_15                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 15 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_15 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2;


-- Search based on AOPS Account Number
-- This is the first 8 of OSR mapping
-- for the party record
-- Attribute: Party: Custom
FUNCTION Get_AOPS_Account_Number (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;


END XX_CDH_DQM_ACQUIRE_PKG;
/
SHOW ERRORS;
EXIT;


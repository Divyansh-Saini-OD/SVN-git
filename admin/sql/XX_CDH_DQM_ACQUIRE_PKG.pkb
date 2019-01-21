SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_DQM_ACQUIRE_PKG IS
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
-- |4.1        26-Jul-2013     Manasa D             E0259- Changed for R12 Retrofit Upgrade  |
-- +=========================================================================================+



-- +===================================================================+
-- | Name        : Get_Micr_Num                                        |
-- | Description : Function to acquire MICR Number (Party Level Attr)  |
-- |                                                                   |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+
FUNCTION   Get_Micr_Num (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_micr_no varchar2(2000);

Cursor Cu_MICR (C_In_Party_Id IN NUMBER) is 

--Commented for R12 Retrofit
/*SELECT
  BACCT.bank_account_num
FROM
  ap_bank_account_uses_all BAUSES,
  ap_bank_accounts BACCT,
  hz_cust_accounts HZCA,
  hz_parties HZP
WHERE
     BAUSES.external_bank_account_id = BACCT.bank_account_id
 AND BAUSES.customer_id = HZCA.cust_account_id
 AND HZCA.party_id = HZP.party_id
 AND HZP.party_id = C_In_Party_Id;*/

-- Added for R12 Retrofit
SELECT
  IEBA.bank_account_num
FROM
  hz_parties hp,
  IBY_ACCOUNT_OWNERS iao,
  IBY_EXT_BANK_ACCOUNTS ieba,
  IBY_EXT_BANKS_V ieb
WHERE ieb.bank_party_id = ieba.bank_id
AND   iao.ext_bank_account_id = ieba.ext_bank_account_id
AND   iao.account_owner_party_id = hp.party_id --party_id of customer
AND   hp.party_id = C_In_Party_Id;

BEGIN

FOR i in Cu_MICR (p_record_id)
LOOP
lc_micr_no := substr(lc_micr_no||' ' ||i.bank_account_num, 1, 2000);
END LOOP;

  RETURN lc_micr_no;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'GET_MICR');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Micr_Num;

-- +=====================================================================+
-- | Name        : Get_Cust_Category                                     |
-- | Description : Function to acquire Customer Category-Party Attribute |
-- |               (Mapped to Customer Category Code)                    |
-- | Parameters :  p_record_id                                           |
-- |               p_entity                                              |
-- |               p_attribute                                           |
-- |               p_context                                             |
-- +=====================================================================+

FUNCTION   Get_Cust_Category (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_cust_category varchar2(2000):='';

Cursor Cu_Cust_Category (C_In_Party_Id IN NUMBER) is 
SELECT 
  FNDL.meaning cust_categ
FROM 
  hz_parties           HZP,
  fnd_lookup_values_vl FNDL
WHERE 
     HZP.category_code = FNDL.lookup_code
 AND FNDL.lookup_type='CUSTOMER_CATEGORY'
  AND HZP.party_id = C_In_Party_Id;

BEGIN

for i in Cu_Cust_Category (p_record_id)
LOOP
lc_cust_category := substr(lc_cust_category||' '||i.cust_categ, 1, 2000);
END LOOP;


RETURN lc_cust_category;
  
EXCEPTION
 WHEN NO_DATA_FOUND THEN
     RETURN '';
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Cust_Category');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Cust_Category;

-- +=====================================================================+
-- | Name        : Get_OD_Cust_Type                                      |
-- | Description : Function to acquire OD Customer Type -Party Attribute |
-- |               (Mapped to HZ_PARTIES Attribute 18)                    |
-- | Parameters :  p_record_id                                           |
-- |               p_entity                                              |
-- |               p_attribute                                           |
-- |               p_context                                             |
-- +=====================================================================+

FUNCTION   Get_OD_Cust_Type (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_od_cust_type varchar2(2000):='';

Cursor Cu_Cust_Type (C_In_Party_Id IN NUMBER) is 
SELECT 
   HZCA.attribute18 cust_type
FROM 
  hz_cust_accounts HZCA,
  hz_parties HZP
WHERE 
     HZCA.party_id = HZP.party_id
    AND HZP.party_id = C_In_Party_Id;
    
    
BEGIN
for i in Cu_Cust_Type (p_record_id)
LOOP
lc_od_cust_type := substr(lc_od_cust_type||' '||i.cust_type, 1, 2000);
END LOOP;

RETURN lc_od_cust_type;
  
EXCEPTION
 WHEN NO_DATA_FOUND THEN
     RETURN '';
     
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_OD_Cust_Type');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_OD_Cust_Type;

-- +===================================================================+
-- | Name        : Get_Ship_To_Seq                                     |
-- | Description : Function to acquire Ship to Sequence (Party Site)   |
-- |               (Mapped to Location at Account Site Uses)           |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+
FUNCTION   Get_Ship_To_Seq (
                          p_party_site_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_ship_to_seq varchar2(2000);

CURSOR Cu_Ship_To_Seq (C_In_Party_Site_Id IN NUMBER)IS
SELECT 
  nvl(substr(HZCSU.orig_system_reference,instr(HZCSU.orig_system_reference,'-',1,1)+1,instr(HZCSU.orig_system_reference,'-',1,2)-instr(HZCSU.orig_system_reference,'-',1)-1),'') ship_to_seq
FROM 
  hz_cust_site_uses_all    HZCSU,
  hz_cust_acct_sites_all   HZCS
WHERE 
     HZCS.cust_acct_site_id = HZCSU.cust_acct_site_id
 AND HZCS.party_site_id = C_In_Party_Site_Id;

BEGIN

for i in Cu_Ship_To_Seq (p_party_site_id)
LOOP
lc_ship_to_seq := substr(lc_ship_to_seq||' ' ||i.ship_to_seq, 1, 2000);
END LOOP;


  RETURN lc_ship_to_seq;
  
EXCEPTION
 WHEN NO_DATA_FOUND THEN
     RETURN '';

  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'GET_MICR');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Ship_To_Seq;

-- +===================================================================+
-- | Name        : Get_Location                                        |
-- | Description : Function to acquire Location from                   |
-- |                hz_cust_site_uses_all                              |
-- | Parameters :  p_party_site_id                                     |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+

FUNCTION   Get_Location (
                          p_party_site_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL
                        )
RETURN VARCHAR2 IS

lc_location varchar2(2000);

Cursor Cu_location   (C_In_Party_Site_Id IN NUMBER) is 
select su.location
from   hz_party_sites ps,
       hz_cust_acct_sites_all sa,
       hz_cust_site_uses_all  su
where  ps.party_site_id=sa.party_site_id and
       sa.cust_acct_site_id = su.cust_acct_site_id and
       ps.party_site_id=C_In_Party_Site_Id;
BEGIN

for i in Cu_Location(p_party_site_id)
LOOP
    lc_location := substr(lc_location ||' ' ||i.location , 1, 2000);
END LOOP;

RETURN lc_location;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Location');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Location;

-- +===================================================================+
-- | Name        : Get_Sales_Channel                                   |
-- | Description : Function to acquire Sales Channel (Party)           |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+

FUNCTION   Get_Sales_Channel (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_sales_channel varchar2(2000);

Cursor Cu_Sales_Channel (C_In_Party_Id IN NUMBER) is 
SELECT 
  SOLKP.meaning sales_channel
FROM 
  HZ_CUST_ACCOUNTS HZCA,
  SO_LOOKUPS       SOLKP
WHERE 
     SOLKP.lookup_type = 'SALES_CHANNEL'
 AND HZCA.sales_channel_code = SOLKP.lookup_code
 AND HZCA.party_id =C_In_Party_Id;

BEGIN

for i in Cu_Sales_Channel (p_record_id)
LOOP
lc_sales_channel := substr(lc_sales_channel||' ' ||i.sales_channel, 1, 2000);
END LOOP;

  RETURN lc_sales_channel;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'GET_MICR');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Sales_Channel;

-- +===================================================================+
-- | Name        : Get_Related_Org_Name                                |
-- | Description : Function to acquire Related Org Name(Party)         |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+

FUNCTION   Get_Related_Org_Name (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_Related_Org_Name varchar2(2000);

Cursor Cu_Related_Org_Name (C_In_Party_Id IN NUMBER) is 
SELECT 
   HZRP.party_name  Related_Org_Name
FROM 
  HZ_RELATIONSHIPS HZR,
  HZ_PARTIES       HZRP
WHERE 
 -- HZR.subject_type = 'ORGANIZATION' 
 -- AND HZR.object_type = 'ORGANIZATION'
 -- AND 
 HZR.directional_flag = 'F'
 AND HZR.object_id = HZRP.party_id
 AND HZR.subject_id = C_In_Party_Id;
BEGIN

for i in Cu_Related_Org_Name (p_record_id)
LOOP
lc_Related_Org_Name := substrb(lc_Related_Org_Name||' ' ||i.Related_Org_Name, 1, 2000);
END LOOP;

  RETURN lc_Related_Org_Name;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'GET_RELATED_ORG_NAME');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Related_Org_Name;

-- +===================================================================+
-- | Name        : Get_Email_Contact                                   |
-- | Description : Function to acquire Email Contact Name(Party)       |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+

FUNCTION   Get_Email_Contact (
                          p_record_id     IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

l_Email_Contact_Name varchar2(2000);

Cursor c_email_cp (p_party_id IN NUMBER)
is
select cp.email_address
from   hz_parties p,
       hz_relationships r,
       hz_contact_points cp
where  p.party_id = r.subject_id
and    r.subject_type='PERSON'
and    r.party_id = cp.owner_table_id
and    cp.owner_table_name = 'HZ_PARTIES'
and    cp.contact_point_type = 'EMAIL'
and    p.party_id = p_party_id;

BEGIN

for i in c_email_cp (p_record_id)
LOOP
 l_Email_Contact_Name := substr(l_Email_Contact_Name || ' ' ||i.email_address, 1, 2000);
END LOOP;

RETURN l_Email_Contact_Name;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'GET_EMAIL_CONTACT');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Email_Contact;

-- +===================================================================+
-- | Name        : Get_Related_Org_ID                                  |
-- | Description : Function to acquire Related Org ID                  |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+

FUNCTION   Get_Related_Org_Number (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS

lc_Related_Org_Number varchar2(2000);

Cursor Cu_Related_Org_Number (C_In_Party_Id IN NUMBER) is 
SELECT 
   HZRP.party_number  Related_Org_Number
FROM 
  HZ_RELATIONSHIPS HZR,
  HZ_PARTIES       HZRP
WHERE 
 HZR.directional_flag = 'F'
 AND HZR.object_id = HZRP.party_id
 AND HZR.subject_id = C_In_Party_Id;
BEGIN

for i in Cu_Related_Org_Number (p_record_id)
LOOP
    lc_Related_Org_Number := substr(lc_Related_Org_Number||' ' ||i.Related_Org_Number, 1, 2000);
END LOOP;

RETURN lc_Related_Org_Number;
  
EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Related_Org_ID');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Related_Org_Number;

-- +=====================================================================+
-- | Name        : Get_Contact_Ext_Address                               |
-- | Description : Function to acquire Address associated via extensible |
-- | Parameters :  p_record_id                                           |
-- |               p_entity                                              |
-- |               p_attribute                                           |
-- |               p_context                                             |
-- +=====================================================================+

-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Address
FUNCTION Get_Contact_Ext_Address (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_address  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.address1 ||' '|| l.address2 || ' '|| l.address3 || ' ' || l.address4) address
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_address  := substr(lc_address ||' ' ||i.address, 1, 2000) ;
    END LOOP;
    
    return lc_address;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_Address ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_Address;

-- +===================================================================+
-- | Name        : Get_Contact_Ext_City                                |
-- | Description : Function to acquire city associated via extensible  |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address: City
FUNCTION Get_Contact_Ext_City (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_city  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.city) city
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_city  := substr(lc_city ||' ' ||i.city, 1, 2000) ;
    END LOOP;
    
    return lc_city;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_City ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_City;

-- +===================================================================+
-- | Name        : Get_Contact_Ext_State                               |
-- | Description : Function to acquire state associated via extensible |
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address: State
FUNCTION Get_Contact_Ext_State (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_state  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.state) state
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_state  := substr(lc_state ||' ' ||i.state, 1, 2000) ;
    END LOOP;
    
    return lc_state;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_State ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_State;


-- +===================================================================+
-- | Name        : Get_Contact_Ext_County                              |
-- | Description : Function to acquire county associated via extensible|
-- | Parameters :  p_record_id                                         |
-- |               p_entity                                            |
-- |               p_attribute                                         |
-- |               p_context                                           |
-- +===================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address: County
FUNCTION Get_Contact_Ext_County (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_county  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.county) county
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_county  := substr(lc_county ||' ' ||i.county, 1, 2000) ;
    END LOOP;
    
    return lc_county;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_County ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_County;

-- +======================================================================+
-- | Name        : Get_Contact_Ext_Province                               |
-- | Description : Function to acquire province associated via extensible |
-- | Parameters :  p_record_id                                            |
-- |               p_entity                                               |
-- |               p_attribute                                            |
-- |               p_context                                              |
-- +======================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Province
FUNCTION Get_Contact_Ext_Province (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_province  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.province) province
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_province  := substr(lc_province ||' ' ||i.province, 1, 2000) ;
    END LOOP;
    
    return lc_province;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_Province ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_Province;


-- +=========================================================================+
-- | Name        : Get_Contact_Ext_Postal_Code                               |
-- | Description : Function to acquire postal-code associated via extensible |
-- | Parameters :  p_record_id                                               |
-- |               p_entity                                                  |
-- |               p_attribute                                               |
-- |               p_context                                                 |
-- +=========================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address:Postal Code
FUNCTION Get_Contact_Ext_Postal_Code (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_postal_code  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.postal_code) postal_code
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_postal_code  := substr(lc_postal_code ||' ' ||i.postal_code, 1, 2000) ;
    END LOOP;
    
    return lc_postal_code;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_Postal_Code ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_Postal_Code;


-- +=====================================================================+
-- | Name        : Get_Contact_Ext_Country                               |
-- | Description : Function to acquire country associated via extensible |
-- | Parameters :  p_record_id                                           |
-- |               p_entity                                              |
-- |               p_attribute                                           |
-- |               p_context                                             |
-- +=====================================================================+
-- Contact Search based on association with party-site via extensible
-- Attribute: Address: Country
FUNCTION Get_Contact_Ext_Country (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_country  varchar2(2000);

Cursor cu_contact_address (c_in_org_contact_id IN NUMBER) is 
select distinct (l.country) country
from hz_locations l, hz_party_sites ps, xx_cdh_s_ext_sitecntct_v xsct
, HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
where ps.location_id = l.location_id    
and   xsct.party_site_id = ps.party_site_id
and   xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
and   oc.party_relationship_id =  r.relationship_id
and   xsct.sitecntct_status = 'A'
and   trunc(sysdate) between  trunc(nvl(xsct.sitecntct_start_dt, sysdate)) and trunc(nvl(xsct.sitecntct_end_dt, sysdate)) 
and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
and   r.subject_type ='PERSON' 
AND   r.DIRECTIONAL_FLAG= 'F' 
AND   (oc.status is null OR oc.status = 'A' or oc.status = 'I') 
AND   (r.status is null OR r.status = 'A' or r.status = 'I')
AND   oc.org_contact_id =  c_in_org_contact_id;
BEGIN

    for i in cu_contact_address  (p_record_id)
    LOOP
        lc_country  := substr(lc_country ||' ' ||i.country, 1, 2000) ;
    END LOOP;
    
    return lc_country;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_Contact_Ext_Country ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_Contact_Ext_Country;

-- Search based on AOPS Account Number
-- Note: This is for AOPS only
-- This is the first 8 of OSR mapping
-- for the party record
-- Attribute: Party: Custom
FUNCTION Get_AOPS_Account_Number (
                          p_record_id IN      NUMBER,
                          p_entity        IN      VARCHAR2,
                          p_attribute     IN      VARCHAR2,
                          p_context       IN      VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2 IS
lc_aops_account_number  varchar2(2000);
Cursor cu_aops_osr (c_in_org_contact_id IN NUMBER) is 
    select orig_system_reference
    from hz_orig_sys_references
    where owner_table_name = 'HZ_CUST_ACCOUNTS'
    and owner_table_id in (select cust_account_id from hz_cust_accounts where party_id = p_record_id)
    and orig_system = 'A0'
    and nvl(STATUS,'A')='A';
BEGIN
    lc_aops_account_number := '';
    for i in cu_aops_osr  (p_record_id)
    LOOP
        lc_aops_account_number  := substr(lc_aops_account_number ||' ' ||i.orig_system_reference, 1, 2000) ;
    END LOOP;
    
    return lc_aops_account_number;

EXCEPTION
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('AR', 'HZ_ACQUIRE_PROC_ERROR');
    FND_MESSAGE.SET_TOKEN('PROC' ,'Get_AOPS_Account_Number ');
    FND_MESSAGE.SET_TOKEN('ERROR' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Get_AOPS_Account_Number;                          
                          
                          
-- +===================================================================+
-- | Name       : Party_Site_Contact_Change                            |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will be re-stage a contact if there is |
-- |              any change (Create/Update) to the Party-Site Extended|
-- |              attribute group "SITE_CONTACTS"                      |
-- |              Event: od.oracle.apps.ar.hz.PartySiteExt.update      |
-- +===================================================================+   
FUNCTION Party_Site_Contact_Change(p_subscription_guid  IN             RAW,
                                   p_event              IN OUT NOCOPY  WF_EVENT_T) 
RETURN VARCHAR2
 AS
   
   --Declaring local variable
   ln_count            PLS_INTEGER;
   
  lc_name                  VARCHAR2(240);
  lc_key                   VARCHAR2(240);
  lc_parameter_list        wf_parameter_list_t := wf_parameter_list_t();
  ln_org_id                org_organization_definitions.operating_unit%TYPE;
  ln_user_id 	           fnd_user.user_id%TYPE;
  ln_resp_id 	           fnd_responsibility.responsibility_id%TYPE;
  ln_resp_appl_id          fnd_responsibility.application_id%TYPE;
  ln_security_group_id     PLS_INTEGER;
  ln_extension_id          hz_party_sites_ext_b.extension_id%TYPE;	  
  lc_dml_type              VARCHAR2(240);
  lc_attr_group_name       VARCHAR2(240);
  lc_return_status         VARCHAR2(10);
  ln_msg_count             PLS_INTEGER;
  lc_msg_data              VARCHAR2(4000);
  lc_error_message         VARCHAR2(4000);
  lc_update_flag           VARCHAR2(1)   := 'N'; 
  ln_org_contact_id        PLS_INTEGER;
   
 BEGIN

   lc_name             := p_event.geteventname;
   lc_key              := p_event.geteventkey;
   lc_parameter_list   := p_event.getparameterlist;
 
   --Obtaining the event parameter values
   ln_org_id            := p_event.GetValueForParameter('ORG_ID');
   ln_user_id           := p_event.GetValueForParameter('USER_ID');
   ln_resp_id           := p_event.GetValueForParameter('RESP_ID');
   ln_resp_appl_id      := p_event.GetValueForParameter('RESP_APPL_ID');
   ln_security_group_id := p_event.GetValueForParameter('SECURITY_GROUP_ID');
   
   --Initializing the application environment
   fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id, ln_security_group_id);	  
   
   --Obtaining the event parameter value of the Customer Account
   lc_dml_type          := p_event.GetValueForParameter('DML_TYPE');  
   -- '
   -- 
   ln_extension_id      := p_event.GetValueForParameter('EXTENSION_ID');
   lc_attr_group_name   := p_event.GetValueForParameter('ATTR_GROUP_NAME');
   
   lc_return_status     := 'SUCCESS';
   
   -- Get the ORG_CONTACT_ID from this extension_id for this attribute-group
   if (lc_attr_group_name = 'SITE_CONTACTS') then
       ln_org_contact_id := 0;
       
       begin
         select oc.org_contact_id
         into   ln_org_contact_id
         from xx_cdh_s_ext_sitecntct_v xsct
         , HZ_RELATIONSHIPS r, HZ_ORG_CONTACTS oc
         where xsct.SITECNTCT_RELATIONSHIP_ID = r.relationship_id
         and   oc.party_relationship_id =  r.relationship_id
         and   r.SUBJECT_TABLE_NAME = 'HZ_PARTIES'  
         AND   r.OBJECT_TABLE_NAME = 'HZ_PARTIES'  
         and   r.subject_type ='PERSON' 
         AND   r.DIRECTIONAL_FLAG= 'F' 
         AND   xsct.extension_id = ln_extension_id;
       exception when others then
           ln_org_contact_id := 0;
       end;

       if (ln_org_contact_id = 0 ) then
           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                  p_return_code             => lc_return_status
                                 ,p_msg_count               => ln_msg_count
                                 ,p_program_type            =>'Business Event Subscription'
                                 ,p_program_name            =>'E0259: od.oracle.apps.ar.hz.PartySiteExt.update'
                                 ,p_module_name             =>'CDH'
                                 ,p_error_location          =>'Party_Site_Contact_Change'
                                 ,p_error_message_count     => ln_msg_count
                                 ,p_error_message_code      => SQLCODE
                                 ,p_error_message           => 'Could not find org-contact from XX_CDH_S_EXT_SITECNTCT_V [Id: ' ||ln_extension_id || ' ]'
                                 ,p_error_message_severity  =>'FATAL'
                                 ); 
           
            -- Set the return to status to avoid un-necessary email notifications
            -- to the admins. We have logs and report that need to be monitored.
            lc_return_status := 'SUCCESS';
        else
            hz_dqm_sync.sync_contact(P_ORG_CONTACT_ID => ln_org_contact_id
	                            ,p_create_upd  => 'U');					
	    begin
              update hz_dqm_sync_interface
                  set last_updated_by = ln_user_id, 
                  created_by = ln_user_id
              where entity = 'CONTACTS'
              and   staged_flag = 'N'
              and   operation = 'U'
	    and   org_contact_id = ln_org_contact_id;
	    
	    exception when others then
                -- Do nothing. Records may have been processed already
                -- Set the return to status to avoid un-necessary email notifications
                -- to the admins. We have logs and report that need to be monitored.
                lc_return_status := 'SUCCESS';
	    end;
        end if;
   end if;
          
   RETURN lc_return_status;
      
 EXCEPTION
   WHEN OTHERS THEN
     -- Commented out so that admins go not get email on failures.
     -- We log the erors and those should be monitored
     -- WF_CORE.CONTEXT('XX_CDH_DQM_ACQUIRE_PKG', 'Party_Site_Contact_Change', p_event.getEventName(), p_subscription_guid);
     -- WF_EVENT.setErrorInfo(p_event, 'SUCCESS');
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_0013_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_CDH_DQM_ACQUIRE_PKG.Party_Site_Contact_Change: Unexpected Error: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);

     XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => lc_return_status
                            ,p_msg_count               => ln_msg_count
                            ,p_program_type            =>'Business Event Subscription'
                            ,p_program_name            =>'E0259: od.oracle.apps.ar.hz.PartySiteExt.update'
                            ,p_module_name             =>'CDH'
                            ,p_error_location          =>'E0259_CusParty_Site_Contact_Change_Search'
                            ,p_error_message_count     => ln_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );     
     -- Set the return to status to avoid un-necessary email notifications
     -- to the admins. We have logs and report that need to be monitored.
     RETURN 'SUCCESS';
End Party_Site_Contact_Change;


-- +===================================================================+
-- | Name       : Account_Site_Use_Change                              |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will re-stage a party site if there is |
-- |              any change (Create/Update) to the Account-Site-Use   |
-- |              "Location" attribute is sourced from here            |
-- |              Event: oracle.apps.ar.hz.CustAcctSiteUse.create      |
-- |              Event: oracle.apps.ar.hz.CustAcctSiteUse.update      |
-- +===================================================================+   
FUNCTION Account_Site_Use_Change(p_subscription_guid  IN             RAW,
                                 p_event              IN OUT NOCOPY  WF_EVENT_T) 
RETURN VARCHAR2
 AS
   
   --Declaring local variable
   ln_count            PLS_INTEGER;
   
  lc_name                  VARCHAR2(240);
  lc_key                   VARCHAR2(240);
  lc_parameter_list        wf_parameter_list_t := wf_parameter_list_t();
  ln_org_id                org_organization_definitions.operating_unit%TYPE;
  ln_user_id 	           fnd_user.user_id%TYPE;
  ln_resp_id 	           fnd_responsibility.responsibility_id%TYPE;
  ln_resp_appl_id          fnd_responsibility.application_id%TYPE;
  ln_security_group_id     PLS_INTEGER;
  lc_return_status         VARCHAR2(10);
  ln_msg_count             PLS_INTEGER;
  lc_msg_data              VARCHAR2(4000);
  lc_error_message         VARCHAR2(4000);
  lc_update_flag           VARCHAR2(1)   := 'N'; 
  ln_party_site_id         PLS_INTEGER;
  ln_acct_site_use_id      PLS_INTEGER;
   
 BEGIN
   lc_name             := p_event.geteventname;
   lc_key              := p_event.geteventkey;
   lc_parameter_list   := p_event.getparameterlist;
 
   --Obtaining the event parameter values
   ln_org_id            := p_event.GetValueForParameter('ORG_ID');
   ln_user_id           := p_event.GetValueForParameter('USER_ID');
   ln_resp_id           := p_event.GetValueForParameter('RESP_ID');
   ln_resp_appl_id      := p_event.GetValueForParameter('RESP_APPL_ID');
   ln_security_group_id := p_event.GetValueForParameter('SECURITY_GROUP_ID');
   
   --Initializing the application environment
   fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id, ln_security_group_id);	  
   
   -- Get the Account Site Use Id of the record created/modified
   ln_acct_site_use_id  := p_event.GetValueForParameter('SITE_USE_ID');

    XX_COM_ERROR_LOG_PUB.log_error_crm(
        p_return_code             => lc_return_status
       ,p_msg_count               => ln_msg_count
       ,p_program_type            =>'Business Event Subscription'
       ,p_program_name            =>'E0259: oracle.apps.ar.hz.CustAcctSiteUse(create/update)'
       ,p_module_name             =>'CDH'
       ,p_error_location          =>'Account_Site_Use_Change'
       ,p_error_message_count     => ln_msg_count
       ,p_error_message_code      => SQLCODE
       ,p_error_message           => 'Account Site Use for Id [PartySiteId: ' ||ln_acct_site_use_id || ' ]'
       ,p_error_message_severity  =>'FATAL'
    ); 

   
   lc_return_status     := 'SUCCESS';
   
   -- Get the ORG_CONTACT_ID from this extension_id for this attribute-group
   ln_party_site_id := 0;
       
   begin
       select sa.party_site_id
       into   ln_party_site_id
       from hz_cust_site_uses_all sua
       , hz_cust_acct_sites_all sa
       where sa.cust_acct_site_id = sua.cust_acct_site_id
       and sua.site_use_id = ln_acct_site_use_id;
   exception when others then
           ln_party_site_id := 0;
   end;

   if (ln_party_site_id = 0 ) then
       XX_COM_ERROR_LOG_PUB.log_error_crm(
            p_return_code             => lc_return_status
           ,p_msg_count               => ln_msg_count
           ,p_program_type            =>'Business Event Subscription'
           ,p_program_name            =>'E0259: oracle.apps.ar.hz.CustAcctSiteUse(create/update)'
           ,p_module_name             =>'CDH'
           ,p_error_location          =>'Account_Site_Use_Change'
           ,p_error_message_count     => ln_msg_count
           ,p_error_message_code      => SQLCODE
           ,p_error_message           => 'Could not find party-site from Account Site Use [Id: ' || ln_acct_site_use_id || ' ]'
           ,p_error_message_severity  =>'FATAL'
        ); 
      
        lc_return_status := 'SUCCESS';
    else
        hz_dqm_sync.sync_party_site(p_party_site_id => ln_party_site_id
	                           ,p_create_upd  => 'U');					
	begin
	    update hz_dqm_sync_interface
	        set last_updated_by = ln_user_id, 
	        created_by = ln_user_id
	    where entity = 'PARTY_SITES'
	    and   operation = 'U'
            and   staged_flag = 'N'
	    and   party_site_id = ln_party_site_id;
	    
        exception when others then
            -- Do nothing
            -- Record may have been processed already 
            lc_return_status := 'SUCCESS';
	end;
    end if;
          
   RETURN lc_return_status;
      
 EXCEPTION
   WHEN OTHERS THEN
     -- Commented out so that admins go not get email on failures.
     -- We log the erors and those should be monitored
     -- WF_CORE.CONTEXT('XX_CDH_DQM_ACQUIRE_PKG', 'Account_Site_Use_Change', p_event.getEventName(), p_subscription_guid);
     -- WF_EVENT.setErrorInfo(p_event, 'SUCCESS');
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_0013_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_CDH_DQM_ACQUIRE_PKG.Account_Site_Use_Change: Unexpected Error: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);

     XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => lc_return_status
                            ,p_msg_count               => ln_msg_count
                            ,p_program_type            =>'Business Event Subscription'
                            ,p_program_name            =>'E0259: oracle.apps.ar.hz.CustAcctSiteUse(create/update)'
                            ,p_module_name             =>'CDH'
                            ,p_error_location          =>'E0259_Account_Site_Use_Change_Subscription'
                            ,p_error_message_count     => ln_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );     
     RETURN 'SUCCESS';
End Account_Site_Use_Change;


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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 3);
END trans_rmspl_substr_3;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 4);
END trans_rmspl_substr_4;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 5);
END trans_rmspl_substr_5;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 6);
END trans_rmspl_substr_6;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 7);
END trans_rmspl_substr_7;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 8);
END trans_rmspl_substr_8;

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
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 9);
END trans_rmspl_substr_9;

-- +================================================-===================+
-- | Name       : trans_rmspl_substr_10                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 10 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_10 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 10);
END trans_rmspl_substr_10;

-- +================================================-===================+
-- | Name       : trans_rmspl_substr_12                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 13 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_13 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 13);
END trans_rmspl_substr_13;

-- +================================================-===================+
-- | Name       : trans_rmspl_substr_15                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Remove spaces and returns first 15 characters for DQM |
-- +====================================================================+   
FUNCTION   trans_rmspl_substr_15 (
    p_original_value IN VARCHAR2,
    p_language       IN VARCHAR2,
    p_attribute_name IN VARCHAR2,
    p_entity_name IN VARCHAR2)
RETURN VARCHAR2
AS
BEGIN
    return substrc(hz_trans_pkg.RM_SPLCHAR(hz_trans_pkg.RM_BLANKS(p_original_value, p_language, p_attribute_name, p_entity_name), p_language, p_attribute_name, p_entity_name), 1, 15);
END trans_rmspl_substr_15;

END XX_CDH_DQM_ACQUIRE_PKG;
/
SHOW ERRORS;
EXIT;

CREATE OR REPLACE PACKAGE BODY XX_OD_DERIVE_CONTENT_SOURCE AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_OD_DERIVE_CONTENT_SOURCE                                               |
-- | Description : Custom package to derive actual content source for parties.               |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        12-Nov-2009     Kalyan               Initial version                          |
-- |2.0        11-Dec-2015     Manikant Kasu        Removed schema alias as part of GSCC     | 
-- |                                                R12.2.2 Retrofit                         |
-- +=========================================================================================+
procedure get_content_source_type (p_org_party_osr      IN    HZ_PARTIES.ORIG_SYSTEM_REFERENCE%TYPE,
                                   p_org_party_id       IN    HZ_PARTIES.PARTY_ID%TYPE,
                                   p_contact_party_osr  IN    HZ_PARTIES.ORIG_SYSTEM_REFERENCE%TYPE,
                                   p_contact_party_id   IN    HZ_PARTIES.PARTY_ID%TYPE, 
                                   x_org_party_cs       OUT   HZ_ORGANIZATION_PROFILES.ACTUAL_CONTENT_SOURCE%TYPE,
                                   x_contact_party_cs   OUT   HZ_PERSON_PROFILES.ACTUAL_CONTENT_SOURCE%TYPE,
                                   X_RETURN_STATUS      OUT   VARCHAR2,
                                   x_msg_data           OUT   NOCOPY  VARCHAR2
				   ) AS
                                   
l_org_party_id      HZ_PARTIES.PARTY_ID%TYPE;                              
l_contact_party_id  HZ_PARTIES.PARTY_ID%TYPE;  
--l_process           VARCHAR2(1);
BEGIN

X_RETURN_STATUS := 'S';
hz_common_pub.disable_cont_source_security;

IF p_org_party_osr IS NOT NULL THEN

  IF  (p_org_party_id IS NULL) OR (TO_NUMBER(p_org_party_id) = 0) THEN
  
  BEGIN
    select  party_id  into l_org_party_id
    from    hz_orig_sys_references
    where   orig_system = 'A0'
    and     OWNER_TABLE_NAME = 'HZ_PARTIES'
    and     status = 'A'
    AND     orig_system_reference = p_org_party_osr || '-00001-A0';
  
  EXCEPTION WHEN NO_DATA_FOUND THEN
      x_org_party_cs := 'A0';
      x_contact_party_cs := 'A0';
      return ;
  END;
  END IF;
  
 
  BEGIN
        SELECT  'A0' INTO  x_org_party_cs
        FROM    HZ_ORGANIZATION_PROFILES
        WHERE   PARTY_ID = NVL(l_org_party_id,p_org_party_id)
        and     ACTUAL_CONTENT_SOURCE = 'A0';
        
  EXCEPTION WHEN NO_DATA_FOUND THEN
        
     --   x_org_party_cs := 'USER_ENTERED';
        NULL;
  END;
  

END IF;
  
    
IF p_contact_party_osr IS NOT NULL THEN
  IF (p_contact_party_id IS NULL) OR (TO_NUMBER(p_contact_party_id) = 0) THEN

    BEGIN
    select  party_id  into l_contact_party_id
    from    hz_orig_sys_references
    where   orig_system = 'A0'
    and     OWNER_TABLE_NAME = 'HZ_PARTIES'
    and     status = 'A'
    AND     orig_system_reference = p_contact_party_osr;
    
    EXCEPTION WHEN NO_DATA_FOUND THEN
            x_contact_party_cs := 'A0';
            return;
    END;

  END IF;

  BEGIN
        SELECT  'A0' INTO x_contact_party_cs
        FROM    HZ_PERSON_PROFILES
        WHERE   PARTY_ID = NVL(l_contact_party_id,p_contact_party_id)
        AND     ACTUAL_CONTENT_SOURCE = 'A0';
        
  EXCEPTION WHEN NO_DATA_FOUND THEN
      --  x_contact_party_cs := 'USER_ENTERED';
        NULL;
  END;
END IF;

EXCEPTION WHEN OTHERS THEN
  x_msg_data := 'Failed with error ' || sqlerrm || ' in get_content_source_type ';
  X_RETURN_STATUS := 'E';
  
END get_content_source_type;

END XX_OD_DERIVE_CONTENT_SOURCE ;
/
SHOW ERRORS
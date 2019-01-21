CREATE OR REPLACE PACKAGE XX_OD_DERIVE_CONTENT_SOURCE AS
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
				   );
END XX_OD_DERIVE_CONTENT_SOURCE ;

/
SHOW ERRORS
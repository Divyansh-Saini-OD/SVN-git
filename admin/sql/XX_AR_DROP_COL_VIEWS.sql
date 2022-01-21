SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to drop Old versions of Collection Views                      |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     06/30/2008   Anusha Ramanujam     To drop all the old views to  |
-- |                                            avoid unnecessary confusions  |
-- +==========================================================================+

---------------**US operating unit**----------------

DROP VIEW APPS.IEX_F_OD_US_MIDLAR_SFA_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_MIDLAR_SFA_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_MIDLAR_SFA_TEL_V;
--older mid larg views--
DROP VIEW APPS.IEX_F_OD_US_MIDLARG_SFA_FAX_V ;

DROP VIEW APPS.IEX_F_OD_US_MIDLARG_SITE_SFA_V ;

DROP VIEW APPS.IEX_F_OD_US_MIDLARG_SITE_V ;


DROP VIEW APPS.IEX_F_OD_US_NATIONAL_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_NATIONAL_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_NATIONAL_TEL_V;


DROP VIEW APPS.IEX_F_OD_US_SCHOOL_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_SCHOOL_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_SCHOOL_TEL_V;

DROP VIEW APPS.IEX_F_OD_US_SCHOOL_SITE_V; 


DROP VIEW APPS.IEX_F_OD_US_GOVT_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_GOVT_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_GOVT_TEL_V;

DROP VIEW APPS.IEX_F_OD_US_GOVT_SITE_V;
	

DROP VIEW APPS.IEX_F_OD_US_DIRECT_CAT_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_DIRECT_CAT_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_DIRECT_CAT_TEL_V;
--older direct views--
DROP VIEW APPS.IEX_F_OD_US_DIRECT_CATALOG_V;

DROP VIEW APPS.IEX_F_OD_US_DIRECT_OTHERS_V;



DROP VIEW APPS.IEX_F_OD_US_NONTRAD_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_US_NONTRAD_FAX_V;

DROP VIEW APPS.IEX_F_OD_US_NONTRAD_TEL_V;

DROP VIEW APPS.IEX_F_OD_US_NONTRAD_SITE_V;



---------------**CA operating unit**------------------

DROP VIEW APPS.IEX_F_OD_CA_MIDLAR_SFA_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_CA_MIDLAR_SFA_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_MIDLAR_SFA_TEL_V;
--older mid larg views
DROP VIEW APPS.IEX_F_OD_CA_MIDLARG_SFA_FAX_V ;

DROP VIEW APPS.IEX_F_OD_CA_MIDLARG_SITE_SFA_V ;

DROP VIEW APPS.IEX_F_OD_CA_MIDLARG_SITE_V ;


DROP VIEW APPS.IEX_F_OD_CA_NATIONAL_EMAIL_V ;

DROP VIEW APPS.IEX_F_OD_CA_NATIONAL_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_NATIONAL_TEL_V;


DROP VIEW APPS.IEX_F_OD_CA_SCHOOL_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_CA_SCHOOL_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_SCHOOL_TEL_V;

DROP VIEW APPS.IEX_F_OD_CA_SCHOOL_SITE_V;


DROP VIEW APPS.IEX_F_OD_CA_GOVT_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_CA_GOVT_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_GOVT_TEL_V;

DROP VIEW APPS.IEX_F_OD_CA_GOVT_SITE_V; 


DROP VIEW APPS.IEX_F_OD_CA_DIRECT_CAT_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_CA_DIRECT_CAT_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_DIRECT_CAT_TEL_V;
--older direct views--
DROP VIEW APPS.IEX_F_OD_CA_DIRECT_CATALOG_V;

DROP VIEW APPS.IEX_F_OD_CA_DIRECT_OTHERS_V;


DROP VIEW APPS.IEX_F_OD_CA_NONTRAD_EMAIL_V;

DROP VIEW APPS.IEX_F_OD_CA_NONTRAD_FAX_V;

DROP VIEW APPS.IEX_F_OD_CA_NONTRAD_TEL_V;

DROP VIEW APPS.IEX_F_OD_CA_NONTRAD_SITE_V;

SHOW ERROR
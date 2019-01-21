-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  xxod_iSupport_Survey                                    |
-- |                                                                                   |
-- | Description      :   This will update the existing category, SFA_CUSTOMER_CATEGORY|
-- |                      to another name so that we can add SFA_CUSTOMER_CATEGORY     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  26-Jun-2010   Rajavel Ramalingam               Initial draft version           |
-- +===================================================================================+
create table xxod_iSupport_Survey(SRNUMBER VARCHAR2(50),QUESTION VARCHAR2(150),ANSWERS VARCHAR2(150),SRTYPE VARCHAR2(150));
create table xxod_iSupport_Survey_new(SRNUMBER VARCHAR2(50),FORM1 VARCHAR2(150),FORM2 VARCHAR2(150),FORM3 VARCHAR2(150),FORM4 VARCHAR2(150),FORM5 VARCHAR2(150));


commit;

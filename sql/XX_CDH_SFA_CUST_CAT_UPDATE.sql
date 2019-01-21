SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_CDH_SFA_CUST_CAT_UPDATE                                    |
-- |                                                                                   |
-- | Description      :   This will update the existing category, SFA_CUSTOMER_CATEGORY|
-- |                      to another name so that we can add SFA_CUSTOMER_CATEGORY     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  16-Jul-08   Sreedhar Mohan               Initial draft version           |
-- +===================================================================================+

update fnd_lookup_types
set    lookup_type='SFA_CUSTOMER_CATEGORY_OLD'
where  lookup_type='SFA_CUSTOMER_CATEGORY';

update fnd_lookup_values
set    lookup_type='SFA_CUSTOMER_CATEGORY_OLD'
where  lookup_type='SFA_CUSTOMER_CATEGORY';

commit;
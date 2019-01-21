create or replace
PACKAGE  XX_AR_IREC_USER_DATA_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_IREC_USER_DATA_PKG                                     |
-- | RICE ID :                                                           |
-- | Description : This package helps to get a report with               |
-- |                ireceivables user data                               |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author                 Remarks           |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 23-AUG-2010    Cindhu Nagarajan      Initial version        |
-- |                                              CR 803 Defect # 4221   |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  GET_IREC_USER_DATA                                          |
-- | RICE ID :                                                           |
-- | Description : This  procedure will get irec user data               |
-- |                                                                     |
-- | Parameters :  p_cycle_date,p_ext_user_id                              |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE GET_IREC_USER_DATA(x_err_buff         OUT NOCOPY VARCHAR2
                             ,x_ret_code        OUT NOCOPY NUMBER
                             ,p_from_date       IN  VARCHAR2
                             ,p_to_date         IN  VARCHAR2
                             ,p_report_type     IN  VARCHAR2
                             );

END XX_AR_IREC_USER_DATA_PKG;
/
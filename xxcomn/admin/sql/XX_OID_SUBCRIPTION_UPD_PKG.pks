create or replace PACKAGE XX_OID_SUBSCRIPTION_UPD_PKG
AS
-- +===================================================================================+
-- |                              Office Depot Inc.                                    |
-- +===================================================================================+
-- | Name             :  XX_OID_SUBSCRIPTION_UPD_PKG  E1328(Defect # 35947)            |
-- | Description      :  This process handles validating if a external user            |
-- |                     subscription exists and if user subscription does not exist   |
-- |                     then we create subscription for the user using LDAP APIs      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author           Remarks                                    |
-- |=======   ==========   =============    ======================                     |
-- | 1.0     10-SEP-2015  Manikant Kasu     Initial Version                            |
-- | 1.1     30-JUN-2016  Vasu Raparla      Added Procedure to purge table             |
-- |                                         XX_COM_OID_ERROR_LOG                      |
-- +===================================================================================+

PROCEDURE delete_orcl_owner_guid ( p_orclguid   IN  VARCHAR2 ); 

PROCEDURE delete_unique_member   ( p_user_name  IN  VARCHAR2 );

PROCEDURE link_user              ( p_user_name  IN  VARCHAR2 );

FUNCTION check_subscription      ( p_user_name  IN  VARCHAR2
                                  ,p_orclguid   IN  VARCHAR2 )
RETURN VARCHAR2;

FUNCTION get_oid_user_exists     ( p_user_name  IN  VARCHAR2
                                  ,p_orclguid OUT NOCOPY VARCHAR2)
RETURN VARCHAR2;

FUNCTION get_fnd_user_exists     ( p_user_name  IN  VARCHAR2
                                  ,p_user_guid  OUT NOCOPY VARCHAR2 )
RETURN VARCHAR2;

PROCEDURE update_subscription    ( p_user_name  IN  VARCHAR2 );
            
FUNCTION get_update_subscription_flag ( p_user_name    IN  VARCHAR2 )
RETURN VARCHAR2;

PROCEDURE update_subscription_conc_call ( x_errbuf     OUT VARCHAR2
                                         ,x_retcode    OUT NUMBER 
                                         ,p_user_name  IN  VARCHAR2
                                         ,p_debug      IN  VARCHAR2
                                        );

FUNCTION update_subscription_func    ( p_subscription_guid   IN     RAW,
                                       p_event               IN OUT wf_event_t )
RETURN VARCHAR2;

PROCEDURE   purge_com_oid_error_log       (  x_errbuf               OUT NOCOPY VARCHAR2
                                            ,x_retcode              OUT NOCOPY VARCHAR2
                                            ,p_age                  IN         NUMBER
                                                      );

END XX_OID_SUBSCRIPTION_UPD_PKG;
/

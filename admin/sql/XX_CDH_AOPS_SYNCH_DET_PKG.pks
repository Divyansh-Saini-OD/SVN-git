CREATE OR REPLACE
PACKAGE  XX_CDH_AOPS_SYNCH_DET_PKG
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_CDH_AOPS_SYNCH_DET_PKG.pks                                       |
-- | Description :  This Package gives the reocrd count details those were synchronized |
-- |                for the given period and user.                                      |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  29-Sep-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

PROCEDURE SYNCH_COUNT_MAIN(
                                            x_errbuf		OUT NOCOPY    VARCHAR2
                                          , x_retcode		OUT NOCOPY    VARCHAR2
                                          , p_from_date         IN            VARCHAR2
					  , p_to_date           IN            VARCHAR2
					  , p_user_name         IN            VARCHAR2
                                          , p_entity_level      IN            VARCHAR2
                                          );

FUNCTION get_user_name(p_user_name IN VARCHAR2) RETURN NUMBER;

FUNCTION get_account_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_account_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_site_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_site_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_org_contact_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_org_contact_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_contact_point_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_contact_point_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_web_user_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_web_user_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER;

FUNCTION get_spc_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE
				  ,p_group_id  IN NUMBER) RETURN NUMBER;

FUNCTION get_spc_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE
				  ,p_group_id  IN NUMBER) RETURN NUMBER;
END;

/
                              

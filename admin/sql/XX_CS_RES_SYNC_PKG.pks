CREATE OR REPLACE
PACKAGE XX_CS_RES_SYNC_PKG AS

PROCEDURE MAIN_PROC ( X_ERRBUF     OUT VARCHAR2,
                      X_RETCODE    OUT NUMBER,
                      P_GET_NEW_EMP IN  VARCHAR2);

 PROCEDURE CREATE_RESOURCE
                  (
                    p_api_version        IN  NUMBER
                  , p_commit             IN  VARCHAR2
                  , p_category           IN  jtf_rs_resource_extns.category%TYPE
                  , p_source_id          IN  jtf_rs_resource_extns.source_id%TYPE         DEFAULT  NULL
                  , p_start_date_active  IN  jtf_rs_resource_extns.start_date_active%TYPE
                  , p_resource_name      IN  jtf_rs_resource_extns_tl.resource_name%TYPE  DEFAULT NULL
                  , p_source_number      IN  jtf_rs_resource_extns.source_number%TYPE     DEFAULT NULL
                  , p_source_name        IN  jtf_rs_resource_extns.source_name%TYPE
                  , p_user_name          IN  VARCHAR2
                  , x_return_status      OUT NOCOPY  VARCHAR2
                  , x_msg_count          OUT NOCOPY  NUMBER
                  , x_msg_data           OUT NOCOPY  VARCHAR2
                  , x_resource_id        OUT NOCOPY  jtf_rs_resource_extns.resource_id%TYPE
                  , x_resource_number    OUT NOCOPY  jtf_rs_resource_extns.resource_number%TYPE
                  );
                  
PROCEDURE UPDATE_RESOURCE
                 ( p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_role_relate_id     IN  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
                 , p_end_date_active    IN  jtf_rs_resource_extns.end_date_active%type
                 , p_object_version_num IN  jtf_rs_resource_extns_vl.object_version_number%TYPE
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 );


END XX_CS_RES_SYNC_PKG;

/
show errors;
exit;
CREATE OR REPLACE PACKAGE XX_TM_TERRITORY_UTIL_PKG AS

---------------------------------------------------------------------
-- Custom Territory Lookup API out Record: Nam_Terr_Lookup_out_rec_type
---------------------------------------------------------------------
 TYPE Nam_Terr_Lookup_out_rec_type     IS RECORD
    (
       NAM_TERR_ID               NUMBER,
       RESOURCE_ID               NUMBER,
       ROLE_ID                   NUMBER,
       RSC_GROUP_ID              NUMBER,
       ENTITY_TYPE               XX_TM_NAM_TERR_ENTITY_DTLS.ENTITY_TYPE%TYPE,
       ENTITY_ID                 XX_TM_NAM_TERR_ENTITY_DTLS.ENTITY_ID%TYPE
    );

  G_MISS_NAM_TERR_LOOKUP_OUT_REC        Nam_Terr_Lookup_out_rec_type;


  TYPE   Nam_Terr_Lookup_out_tbl_type   IS TABLE OF   Nam_Terr_Lookup_out_rec_type
                                         INDEX BY BINARY_INTEGER;

  G_MISS_NAM_TERR_LOOKUP_OUT_TBL        Nam_Terr_Lookup_out_tbl_type;

PROCEDURE NAM_TERR_LOOKUP
(
   p_Api_Version_Number           IN  NUMBER,
   p_Nam_Terr_Id                  IN  NUMBER DEFAULT NULL,
   p_Resource_Id                  IN  NUMBER DEFAULT NULL,
   p_Res_Role_Id                  IN  NUMBER DEFAULT NULL,
   p_Res_Group_Id                 IN  NUMBER DEFAULT NULL,
   p_Entity_Type                  IN  VARCHAR2,
   p_Entity_ID                    IN  NUMBER,
   P_As_Of_Date                   IN  DATE DEFAULT SYSDATE,
   x_Nam_Terr_Lookup_out_tbl_type OUT NOCOPY Nam_Terr_Lookup_out_tbl_type,
   x_Return_Status                OUT NOCOPY VARCHAR2,
   x_Message_Data                 OUT NOCOPY VARCHAR2
);

PROCEDURE NAM_TERR_LOOKUP1
(
   p_Api_Version_Number           IN  NUMBER,
   p_Nam_Terr_Id                  IN  NUMBER DEFAULT NULL,
   p_Resource_Id                  IN  NUMBER DEFAULT NULL,
   p_Res_Role_Id                  IN  NUMBER DEFAULT NULL,
   p_Res_Group_Id                 IN  NUMBER DEFAULT NULL,
   p_Entity_Type                  IN  VARCHAR2,
   p_Entity_ID                    IN  NUMBER,
   P_As_Of_Date                   IN  DATE DEFAULT SYSDATE,
   x_Nam_Terr_Lookup_out_tbl_type OUT NOCOPY Nam_Terr_Lookup_out_tbl_type,
   x_Return_Status                OUT NOCOPY VARCHAR2,
   x_Message_Data                 OUT NOCOPY VARCHAR2
);

PROCEDURE TERR_RULE_BASED_WINNER_LOOKUP
            (
              p_party_site_id              IN NUMBER DEFAULT NULL,
              p_org_type                   IN VARCHAR2 DEFAULT 'PROSPECT',
              p_od_wcw                     IN NUMBER DEFAULT 0,
              p_sic_code                   IN VARCHAR2 DEFAULT NULL,
              p_postal_code                IN VARCHAR2 DEFAULT '0',
              p_division                   IN VARCHAR2 DEFAULT 'BSD',
              p_compare_creator_territory  IN VARCHAR2 DEFAULT NULL,
              p_nam_terr_id                OUT NUMBER,
              p_resource_id                OUT NUMBER,
              p_role_id                    OUT NUMBER,
              p_group_id                   OUT NUMBER,
              p_full_access_flag           OUT VARCHAR2,
              x_return_status              OUT NOCOPY VARCHAR2,
              x_message_data               OUT NOCOPY VARCHAR2
            );  
  
END XX_TM_TERRITORY_UTIL_PKG;
/
SHOW ERRORS;

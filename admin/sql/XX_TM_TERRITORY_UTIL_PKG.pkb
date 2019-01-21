CREATE OR REPLACE PACKAGE BODY XX_TM_TERRITORY_UTIL_PKG IS

---------------------------------------------------------------------
-- Custom Territory Lookup API 
---------------------------------------------------------------------
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
   x_message_data                 OUT NOCOPY VARCHAR2) IS

Cursor C_Named_Terr_Assignments (C_Nam_Terr_Id  IN  NUMBER,
                                 C_Resource_Id  IN  NUMBER,
                                 C_Res_Role_Id  IN  NUMBER,
                                 C_Res_Group_Id IN  NUMBER,
                                 C_Entity_Type  IN  VARCHAR2,
                                 C_Entity_ID    IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            TERR_ENT.ENTITY_TYPE,
            TERR_ENT.ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = nvl(C_Nam_Terr_Id,TERR.NAMED_ACCT_TERR_ID) AND
           TERR_RSC.RESOURCE_ID      = nvl(C_Resource_Id,TERR_RSC.RESOURCE_ID) AND
           TERR_RSC.RESOURCE_ROLE_ID = nvl(C_Res_Role_Id,TERR_RSC.RESOURCE_ROLE_ID) AND
           TERR_RSC.GROUP_ID         = nvl(C_Res_Group_Id,TERR_RSC.GROUP_ID) AND
           TERR_ENT.ENTITY_TYPE      = nvl(C_Entity_Type,TERR_ENT.ENTITY_TYPE) AND
           TERR_ENT.ENTITY_ID        = nvl(C_Entity_Id,TERR_ENT.ENTITY_ID) AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_ENT.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';
           
           
Cursor C_Named_Terr_Assign_rsc  (C_Resource_Id  IN  NUMBER,
                                 C_Res_Role_Id  IN  NUMBER,
                                 C_Res_Group_Id IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            TERR_ENT.ENTITY_TYPE,
            TERR_ENT.ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR_RSC.RESOURCE_ID      = C_Resource_Id AND
           TERR_RSC.RESOURCE_ROLE_ID = C_Res_Role_Id AND
           TERR_RSC.GROUP_ID         = C_Res_Group_Id AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_ENT.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';           
           
Cursor C_Named_Terr_Assign_entity
                                (C_Entity_Type  IN  VARCHAR2,
                                 C_Entity_ID    IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            TERR_ENT.ENTITY_TYPE,
            TERR_ENT.ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR_ENT.ENTITY_TYPE      = C_Entity_Type AND
           TERR_ENT.ENTITY_ID        = C_Entity_Id AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_ENT.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';  
           
      l_api_version_number CONSTANT NUMBER := 1.0;
      l_api_name           CONSTANT VARCHAR2(30) := 'Nam_Terr_Lookup';

BEGIN

      --  Initialize API return status to success
      x_return_status := fnd_api.g_ret_sts_success;
     
      -- Standard call to check for call compatibility.
      IF NOT fnd_api.compatible_api_call (
                l_api_version_number,
                p_Api_Version_Number,
                l_api_name,
                'XX_TM_TERRITORY_UTIL_PKG'
             )
      THEN
         RAISE fnd_api.g_exc_unexpected_error;
      END IF;
      IF p_Resource_Id IS NOT NULL AND
         p_Res_Role_Id IS NOT NULL  AND
         p_Res_Group_Id IS NOT NULL THEN 
        FOR l_assignments in C_Named_Terr_Assign_rsc (P_Resource_Id,P_Res_Role_Id,P_Res_Group_Id,P_As_Of_Date)
        LOOP
  
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;      
      elsif P_Entity_Type is not null and P_Entity_ID is not null then
        FOR l_assignments in C_Named_Terr_Assign_entity (P_Entity_Type,P_Entity_ID,P_As_Of_Date)
        LOOP
  
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;      
      else
        FOR l_assignments in C_Named_Terr_Assignments (P_Nam_Terr_Id,P_Resource_Id,P_Res_Role_Id,P_Res_Group_Id,P_Entity_Type,P_Entity_ID,P_As_Of_Date)
        LOOP

          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;
      end if;
EXCEPTION WHEN OTHERS THEN
x_return_status := FND_API.G_RET_STS_ERROR;
x_message_data := 'Error in XX_TM_TERRITORY_UTIL_PKG.NAM_TERR_LOOKUP '||sqlcode||sqlerrm;
END NAM_TERR_LOOKUP;

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
   x_message_data                 OUT NOCOPY VARCHAR2) IS

Cursor C_Named_Terr_Assignments (C_Nam_Terr_Id  IN  NUMBER,
                                 C_Resource_Id  IN  NUMBER,
                                 C_Res_Role_Id  IN  NUMBER,
                                 C_Res_Group_Id IN  NUMBER,
                                 C_Entity_Type  IN  VARCHAR2,
                                 C_Entity_ID    IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            TERR_ENT.ENTITY_TYPE,
            TERR_ENT.ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = nvl(C_Nam_Terr_Id,TERR.NAMED_ACCT_TERR_ID) AND
           TERR_RSC.RESOURCE_ID      = nvl(C_Resource_Id,TERR_RSC.RESOURCE_ID) AND
           TERR_RSC.RESOURCE_ROLE_ID = nvl(C_Res_Role_Id,TERR_RSC.RESOURCE_ROLE_ID) AND
           TERR_RSC.GROUP_ID         = nvl(C_Res_Group_Id,TERR_RSC.GROUP_ID) AND
           TERR_ENT.ENTITY_TYPE      = nvl(C_Entity_Type,TERR_ENT.ENTITY_TYPE) AND
           TERR_ENT.ENTITY_ID        = nvl(C_Entity_Id,TERR_ENT.ENTITY_ID) AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_ENT.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';
           
           
Cursor C_Named_Terr_Assign_rsc  (C_Resource_Id  IN  NUMBER,
                                 C_Res_Role_Id  IN  NUMBER,
                                 C_Res_Group_Id IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            NULL AS ENTITY_TYPE,
            NULL AS ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR_RSC.RESOURCE_ID      = C_Resource_Id AND
           TERR_RSC.RESOURCE_ROLE_ID = C_Res_Role_Id AND
           TERR_RSC.GROUP_ID         = C_Res_Group_Id AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';           
           
Cursor C_Named_Terr_Assign_entity
                                (C_Entity_Type  IN  VARCHAR2,
                                 C_Entity_ID    IN  NUMBER,
                                 C_As_Of_Date   IN  DATE) IS
        SELECT
            ROWNUM counter,
            TERR.NAMED_ACCT_TERR_ID,
            TERR_RSC.RESOURCE_ID,
            TERR_RSC.RESOURCE_ROLE_ID,
            TERR_RSC.GROUP_ID,
            TERR_ENT.ENTITY_TYPE,
            TERR_ENT.ENTITY_ID
        FROM
            XX_TM_NAM_TERR_DEFN         TERR,
            XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
            XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
        WHERE
           TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND
           TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND
           TERR_ENT.ENTITY_TYPE      = C_Entity_Type AND
           TERR_ENT.ENTITY_ID        = C_Entity_Id AND
           (C_As_Of_Date) between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND
           (C_As_Of_Date) between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1)
           AND NVL(TERR.status , 'A') = 'A'
           AND NVL(TERR_ENT.status , 'A') = 'A'
           AND NVL(TERR_RSC.status , 'A') = 'A';  
           
      l_api_version_number CONSTANT NUMBER := 1.0;
      l_api_name           CONSTANT VARCHAR2(30) := 'Nam_Terr_Lookup';

BEGIN

      --  Initialize API return status to success
      x_return_status := fnd_api.g_ret_sts_success;
     
      -- Standard call to check for call compatibility.
      IF NOT fnd_api.compatible_api_call (
                l_api_version_number,
                p_Api_Version_Number,
                l_api_name,
                'XX_TM_TERRITORY_UTIL_PKG'
             )
      THEN
         RAISE fnd_api.g_exc_unexpected_error;
      END IF;
      IF p_Resource_Id IS NOT NULL AND
         p_Res_Role_Id IS NOT NULL  AND
         p_Res_Group_Id IS NOT NULL THEN 
        FOR l_assignments in C_Named_Terr_Assign_rsc (P_Resource_Id,P_Res_Role_Id,P_Res_Group_Id,P_As_Of_Date)
        LOOP
  
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;      
      elsif P_Entity_Type is not null and P_Entity_ID is not null then
        FOR l_assignments in C_Named_Terr_Assign_entity (P_Entity_Type,P_Entity_ID,P_As_Of_Date)
        LOOP
  
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;      
      else
        FOR l_assignments in C_Named_Terr_Assignments (P_Nam_Terr_Id,P_Resource_Id,P_Res_Role_Id,P_Res_Group_Id,P_Entity_Type,P_Entity_ID,P_As_Of_Date)
        LOOP

          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).NAM_TERR_ID   := l_assignments.NAMED_ACCT_TERR_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RESOURCE_ID   := l_assignments.RESOURCE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).RSC_GROUP_ID  := l_assignments.GROUP_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ROLE_ID       := l_assignments.RESOURCE_ROLE_ID;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_TYPE   := l_assignments.ENTITY_TYPE;
          x_Nam_Terr_Lookup_out_tbl_type(l_assignments.counter).ENTITY_ID     := l_assignments.ENTITY_ID;

        END LOOP;
      end if;
EXCEPTION WHEN OTHERS THEN
x_return_status := FND_API.G_RET_STS_ERROR;
x_message_data := 'Error in XX_TM_TERRITORY_UTIL_PKG.NAM_TERR_LOOKUP '||sqlcode||sqlerrm;
END NAM_TERR_LOOKUP1;

---------------------------------------------------------------------
-- Custom Territory Rule based Winner Lookup API 
---------------------------------------------------------------------
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
            ) IS
---------------------------
--Declaring local variables
---------------------------
EX_PARTY_SITE_ERROR       EXCEPTION;
ln_created_by             PLS_INTEGER;
lc_party_type             VARCHAR2(30);
ln_party_id               NUMBER;
ln_creator_resource_id    PLS_INTEGER;
ln_creator_role_id        PLS_INTEGER;
lc_creator_role_division  VARCHAR2(50);
ln_creator_group_id       PLS_INTEGER;
ln_creator_manager_id     PLS_INTEGER;
ln_win_manager_id         PLS_INTEGER;
ln_api_version            PLS_INTEGER := 1.0;
lc_return_status          VARCHAR2(03);
ln_msg_count              PLS_INTEGER;
lc_msg_data               VARCHAR2(2000);
ln_win_resource_id        PLS_INTEGER;
ln_win_group_id           PLS_INTEGER;
ln_win_role_id            PLS_INTEGER;
lc_assignee_role_division VARCHAR2(50);
lc_error_message          VARCHAR2(2000);
lc_set_message            VARCHAR2(2000);
lc_win_full_access_flag   VARCHAR2(03);
lc_role                   VARCHAR2(50);
ln_win_manager_count      PLS_INTEGER;
ln_win_admin_count        PLS_INTEGER; 
ln_creator_manager_count  PLS_INTEGER;
ln_creator_admin_count    PLS_INTEGER;
lc_message_code           VARCHAR2(30);
lc_assignee_admin_flag    VARCHAR2(10);
lc_assignee_manager_flag  VARCHAR2(10);
ln_rank                   NUMBER;
ln_win_rank               NUMBER;
ln_role_id                NUMBER;
lc_role_division          VARCHAR2(50);   
lc_manager_territory_role VARCHAR2(50);
lc_mgr_role_lookup_code   VARCHAR2(50); 
lc_copy_identify_site_asgnmnt VARCHAR2(50);
lc_compare_creator_territory  VARCHAR2(1);


----------------------------------
--Declaring Record Type Variables
----------------------------------
lp_gen_bulk_rec           JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec         JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- -------------------------------------------------------------------
-- Declare cursor to check whether the resource is an admin or manager
-- -------------------------------------------------------------------
CURSOR lcu_admin_mgr(c_resource_id NUMBER
                     , c_role_id   VARCHAR2 DEFAULT NULL
                     , c_group_id  NUMBER   DEFAULT NULL
                    )
IS
SELECT NVL(SUM(DECODE(NVL(ROL.admin_flag, 'N'), 'Y', 1, 0)), 0) admin_role_count, 
       NVL(SUM(DECODE(NVL(ROL.manager_flag, 'N'), 'Y', 1, 0)), 0) mgr_role_count
FROM   jtf_rs_group_mbr_role_vl MEM   
       , jtf_rs_roles_vl ROL
WHERE  MEM.resource_id = c_resource_id
AND    MEM.role_id = NVL(c_role_id, MEM.role_id)
AND    MEM.group_id = NVL(c_group_id, MEM.group_id)
AND    SYSDATE BETWEEN MEM.start_date_active AND NVL(MEM.end_date_active, SYSDATE+1)
AND    ROL.role_id = MEM.role_id
AND    ROL.role_type_code = 'SALES'
AND    ROL.active_flag = 'Y'
AND    ROL.attribute15 = p_division;

BEGIN

  --  Initialize OUT parameters
  x_return_status := fnd_api.g_ret_sts_success;
  x_message_data  := NULL;
  p_nam_terr_id   := NULL;
  p_resource_id   := NULL;
  p_role_id       := NULL;
  p_group_id      := NULL; 
  p_full_access_flag := NULL;

  -- Get the right default manegerial role for territory assignment from lookup
  IF p_org_type = 'PROSPECT' then
    lc_mgr_role_lookup_code := 'PROSPECT_MGR_ROLE';
    -- Get profile otion value for copy identifying site assignment
    lc_copy_identify_site_asgnmnt := FND_PROFILE.VALUE('XX_TM_COPY_IDENTIFY_SITE_ASGNMNT');
  ELSIF p_org_type = 'CUSTOMER' then
    lc_mgr_role_lookup_code := 'CUSTOMER_MGR_ROLE';
    lc_copy_identify_site_asgnmnt := 'N';
  ELSE
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    lc_set_message     :=  'Invalid Organization Type: Choose PROSPECT/CUSTOMER';
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_error_message := FND_MESSAGE.GET;
    RAISE EX_PARTY_SITE_ERROR;
  END IF;

  -- Get the default manager role from lookup depending on organization type
  BEGIN
    SELECT description
    INTO   lc_manager_territory_role 
    FROM   FND_LOOKUP_VALUES_VL
    WHERE  lookup_type = 'XX_SFA_TM_MGR_DEFAULT_ROLE'
      AND  lookup_code = lc_mgr_role_lookup_code
      AND  enabled_flag = 'Y'
      AND  SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE+1);
  EXCEPTION
    WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    lc_set_message     :=  'No Lookup Value defined for Manager Territory Assignment Role.';
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_error_message := FND_MESSAGE.GET;
    RAISE EX_PARTY_SITE_ERROR;
  END;

  IF p_party_site_id IS NOT NULL THEN
    BEGIN
      -- Check whether the party_site_id is of party_type 'ORGANIZATION'   
      SELECT HP.party_type,
             HP.party_id
      INTO   lc_party_type,
             ln_party_id
      FROM   hz_party_sites HPS
             , hz_parties HP
      WHERE  HP.party_id = HPS.party_id
      AND    HP.party_type = 'ORGANIZATION'
      AND    HPS.party_site_id = p_party_site_id
      AND    HP.attribute13 = p_org_type;
    EXCEPTION
      WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0185_NOT_ORGANIZATION');
        FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', p_party_site_id );
        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR;    
    END;   

    -- IF additional sites have to be assigned to the identifying (main) site territory then find 
    -- resource/role/group assigned to the identifying site and return
    IF lc_copy_identify_site_asgnmnt = 'Y' and ln_party_id IS NOT NULL THEN
      -- Find the identifying party site assignment   
      BEGIN
        SELECT cur.named_acct_terr_id,
               cur.resource_id,
               cur.resource_role_id,
               cur.group_id,
               NVL(cur.full_access_flag, 'N')
        INTO   p_nam_terr_id,
               p_resource_id,
               p_role_id,
               p_group_id,
               p_full_access_flag
        FROM   xx_tm_nam_terr_curr_assign_v cur,
               hz_party_sites hps,
               jtf_rs_roles_vl jrrv
        WHERE  hps.party_id = ln_party_id
        AND    NVL(hps.identifying_address_flag, 'N') = 'Y'
        AND    cur.entity_type = 'PARTY_SITE'
        AND    cur.entity_id   = hps.party_site_id
        AND    jrrv.role_id    = cur.resource_role_id
        AND    jrrv.role_type_code = 'SALES'
        AND    jrrv.active_flag    = 'Y'
        AND    jrrv.attribute15    = p_division;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          p_nam_terr_id := NULL;
          p_resource_id := NULL;
          p_role_id     := NULL;
          p_group_id    := NULL;
          p_full_access_flag := NULL;
        WHEN OTHERS THEN
          p_nam_terr_id := NULL;
          p_resource_id := NULL;
          p_role_id     := NULL;
          p_group_id    := NULL;
          p_full_access_flag := NULL;
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Unexpected Error while deriving territory assignment for identifying site: ';
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          RAISE EX_PARTY_SITE_ERROR;
      END;
    END IF; -- lc_copy_identify_site_asgnmnt = 'Y'
  END IF; --p_party_site_id IS NOT NULL

  -- If we have not yet found the territory id then call get_winner 
  IF p_nam_terr_id IS NULL THEN
    lp_gen_bulk_rec.trans_object_id         := JTF_TERR_NUMBER_LIST(null);
    lp_gen_bulk_rec.trans_detail_object_id  := JTF_TERR_NUMBER_LIST(null);
   
    -- Extend Qualifier Elements
    lp_gen_bulk_rec.squal_char01.EXTEND;
    lp_gen_bulk_rec.squal_char02.EXTEND;
    lp_gen_bulk_rec.squal_char03.EXTEND;
    lp_gen_bulk_rec.squal_char04.EXTEND;
    lp_gen_bulk_rec.squal_char05.EXTEND;
    lp_gen_bulk_rec.squal_char06.EXTEND;
    lp_gen_bulk_rec.squal_char07.EXTEND;
    lp_gen_bulk_rec.squal_char08.EXTEND;
    lp_gen_bulk_rec.squal_char09.EXTEND;
    lp_gen_bulk_rec.squal_char10.EXTEND;
    lp_gen_bulk_rec.squal_char10.EXTEND;
    lp_gen_bulk_rec.squal_char11.EXTEND;
    lp_gen_bulk_rec.squal_char50.EXTEND;
    lp_gen_bulk_rec.squal_char59.EXTEND;
    lp_gen_bulk_rec.squal_char60.EXTEND;
    lp_gen_bulk_rec.squal_num60.EXTEND;
    lp_gen_bulk_rec.squal_num01.EXTEND;
    lp_gen_bulk_rec.squal_num02.EXTEND;
    lp_gen_bulk_rec.squal_num03.EXTEND;
    lp_gen_bulk_rec.squal_num04.EXTEND;
    lp_gen_bulk_rec.squal_num05.EXTEND;
    lp_gen_bulk_rec.squal_num06.EXTEND;
    lp_gen_bulk_rec.squal_num07.EXTEND;
    lp_gen_bulk_rec.squal_char61.EXTEND;   
   
    lp_gen_bulk_rec.squal_char01(1) := NULL;
    lp_gen_bulk_rec.squal_char02(1) := NULL;
    lp_gen_bulk_rec.squal_char03(1) := NULL;
    lp_gen_bulk_rec.squal_char04(1) := NULL;
    lp_gen_bulk_rec.squal_char05(1) := NULL;
    lp_gen_bulk_rec.squal_char06(1) := p_postal_code;  --Postal Code
    lp_gen_bulk_rec.squal_char07(1) := NULL;  --Country
    lp_gen_bulk_rec.squal_char08(1) := NULL;
    lp_gen_bulk_rec.squal_char09(1) := NULL;
    lp_gen_bulk_rec.squal_char10(1) := NULL;
    lp_gen_bulk_rec.squal_char11(1) := NULL;
    lp_gen_bulk_rec.squal_char50(1) := NULL;
    lp_gen_bulk_rec.squal_char59(1) := p_sic_code;  --SIC Code(Site Level)
    lp_gen_bulk_rec.squal_char60(1) := p_org_type;  --Customer/Prospect
    lp_gen_bulk_rec.squal_char61(1) := '1'; -- Partner Id passed to bypass custom logic 
    lp_gen_bulk_rec.squal_num60(1)  := p_od_wcw;   --WCW
    lp_gen_bulk_rec.squal_num01(1)  := FND_API.G_MISS_NUM;   --Party Id
    lp_gen_bulk_rec.squal_num02(1)  := p_party_site_id; --Party Site Id
    lp_gen_bulk_rec.squal_num03(1)  := NULL;
    lp_gen_bulk_rec.squal_num04(1)  := NULL;
    lp_gen_bulk_rec.squal_num05(1)  := NULL;
    lp_gen_bulk_rec.squal_num06(1)  := NULL;
    lp_gen_bulk_rec.squal_num07(1)  := NULL;  
   
    -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id OR (postal code, sic, wcw)
   
    JTF_TERR_ASSIGN_PUB.get_winners(  
                                   p_api_version_number  => ln_api_version
                                   , p_init_msg_list     => FND_API.G_FALSE
                                   , p_use_type          => 'LOOKUP'
                                   , p_source_id         => -1001
                                   , p_trans_id          => -1002
                                   , p_trans_rec         => lp_gen_bulk_rec
                                   , p_resource_type     => FND_API.G_MISS_CHAR
                                   , p_role              => FND_API.G_MISS_CHAR
                                   , p_top_level_terr_id => FND_API.G_MISS_NUM
                                   , p_num_winners       => FND_API.G_MISS_NUM
                                   , x_return_status     => lc_return_status
                                   , x_msg_count         => ln_msg_count
                                   , x_msg_data          => lc_msg_data
                                   , x_winners_rec       => lx_gen_return_rec
                                  );
   
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN     
      lc_error_message := NULL;
      FOR k IN 1 .. ln_msg_count LOOP     
        lc_msg_data := FND_MSG_PUB.GET( 
                                       p_encoded     => FND_API.G_FALSE 
                                       , p_msg_index => k
                                      );                                          
        lc_error_message := lc_error_message || ' ' || lc_msg_data;
      END LOOP;
      RAISE EX_PARTY_SITE_ERROR;   
    END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
   
    -- JTF_TERR_ASSIGN_PUB.get_winners did not return any resource   
    IF lx_gen_return_rec.resource_id.COUNT = 0 THEN     
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0121_NO_RES_RETURNED');
      lc_error_message := FND_MESSAGE.GET;
      RAISE EX_PARTY_SITE_ERROR;     
    END IF; -- lx_gen_return_rec.resource_id.COUNT = 0
   
    ln_rank             := 0;
    ln_win_rank         := 0;
    ln_win_resource_id  := NULL;
    ln_win_role_id      := NULL;
    ln_win_group_id     := NULL;
    lc_win_full_access_flag := NULL;

    -- Get the resource/role/group with highest absolute rank for the passed division from JTF_TERR_ASSIGN_PUB.get_winners     
    FOR i in 1..lx_gen_return_rec.resource_id.COUNT LOOP 
      -- Check if resource/role/group is returned by get_winner
      IF lx_gen_return_rec.resource_id(i) IS NULL OR
         lx_gen_return_rec.role(i) IS NULL OR 
         lx_gen_return_rec.group_id(i) IS NULL THEN
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
        lc_set_message     :=  'Resource or Role or Group of the winner is missing in Territory Manager.';
        FND_MESSAGE.SET_TOKEN('ERROR_CODE', NULL);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', NULL);
        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR;
      ELSE
        -- Get division for the role code
        BEGIN
          SELECT role_id,
                 attribute15
          INTO   ln_role_id,
                 lc_role_division             
          FROM   JTF_RS_ROLES_VL
          WHERE  role_code = lx_gen_return_rec.role(i)
          AND    role_type_code = 'SALES'
          AND    active_flag = 'Y';
        EXCEPTION
          WHEN OTHERS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Error Getting Role Id for Role Code in TM.';
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', NULL);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', NULL);
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          RAISE EX_PARTY_SITE_ERROR;
        END;

        -- Match the division 
        IF NVL(lc_role_division, 'XXX') = p_division THEN
          -- Get the absolute rank for the territory
          BEGIN
            SELECT absolute_rank
            INTO   ln_rank
            FROM   apps.JTF_TERR_DENORM_RULES_ALL
            WHERE  terr_id = lx_gen_return_rec.terr_id(i)
            AND    relative_rank > 0;
          EXCEPTION
            WHEN OTHERS THEN
              ln_rank := 0;
          END;        

          IF ln_rank > ln_win_rank THEN
            ln_win_rank := ln_rank;
            ln_win_resource_id := lx_gen_return_rec.resource_id(i);
            ln_win_role_id     := ln_role_id;
            ln_win_group_id    := lx_gen_return_rec.group_id(i);
            lc_win_full_access_flag := NVL(lx_gen_return_rec.full_access_flag(i), 'N');
          END IF;
        END IF;
      END IF;
    END LOOP; 

    -- By now we should have a winning resource/role/group as per territory rule
    IF ln_win_resource_id IS NULL OR ln_win_role_id IS NULL OR ln_win_group_id IS NULL THEN
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_set_message     :=  'No Winner (Resource/Role/Group) is found in Territory Manager with matching qualifiers.';
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', NULL);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', NULL);
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
      lc_error_message := FND_MESSAGE.GET;
      RAISE EX_PARTY_SITE_ERROR;
    ELSE
      p_resource_id := ln_win_resource_id;
      p_role_id     := ln_win_role_id;
      p_group_id    := ln_win_group_id;
      p_full_access_flag := lc_win_full_access_flag;
    END IF;

    -- Find the profile option value for compare creator vs. winner logic if the parameter value is null
    -- (Always online autoname will pass NULL as we want it to be profile option driven but batch autoname
    --  will pass 'N' as we do not want this logic) 
    IF p_compare_creator_territory IS NULL THEN
      lc_compare_creator_territory := FND_PROFILE.VALUE('XX_TM_COMPARE_CREATOR_VS_WINNER'); 
    ELSE
      lc_compare_creator_territory := p_compare_creator_territory;
    END IF;

    -- Compare the winner with creator if required
    IF lc_compare_creator_territory = 'Y' THEN                           
      -- Retrieve the creator resource    
      ln_created_by := FND_GLOBAL.user_id;
   
      -- Derive the resource_id of creator resource    
      BEGIN
        SELECT JRR.resource_id
        INTO   ln_creator_resource_id
        FROM   jtf_rs_resource_extns JRR
        WHERE  JRR.user_id = ln_created_by;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0158_RESOURCE_NOT_FOUND');
          FND_MESSAGE.SET_TOKEN('P_USER_ID', ln_created_by );
          lc_error_message := FND_MESSAGE.GET;
          RAISE EX_PARTY_SITE_ERROR;
        WHEN OTHERS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Unexpected Error while deriving resource_id of the creator: ';
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          RAISE EX_PARTY_SITE_ERROR;
      END;

      -- Check whether the winner is an admin/manager
      OPEN lcu_admin_mgr(c_resource_id => ln_win_resource_id,
                         c_role_id     => ln_win_role_id,
                         c_group_id    => ln_win_group_id
                        );
      FETCH lcu_admin_mgr INTO ln_win_admin_count, ln_win_manager_count;
      CLOSE lcu_admin_mgr;
   
      -- Check whether the creator resource is an admin/manager
      OPEN lcu_admin_mgr(c_resource_id => ln_creator_resource_id,
                         c_role_id     => ln_creator_role_id,
                         c_group_id    => ln_creator_group_id
                        );
      FETCH lcu_admin_mgr INTO ln_creator_admin_count, ln_creator_manager_count;
      CLOSE lcu_admin_mgr;
   
   
      IF ln_win_manager_count > 1 THEN         
        -- The resource has more than one manager role
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0226_CR_MGR_MR_THAN_ONE');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_win_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR;         
      END IF; -- ln_win_manager_count > 1   

      IF ln_creator_manager_count > 1 THEN         
        -- The resource has more than one manager role
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0226_CR_MGR_MR_THAN_ONE');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR; 
      END IF; -- ln_creator_manager_count > 1   
       
      IF ln_win_admin_count > 1 THEN              
        -- The resource has more than one admin role
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0225_ADM_MORE_THAN_ONE');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_win_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR;
      END IF ; -- ln_win_admin_count > 1

      IF ln_creator_admin_count > 1 THEN              
        -- The resource has more than one admin role
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0225_ADM_MORE_THAN_ONE');
        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
        lc_error_message := FND_MESSAGE.GET;
        RAISE EX_PARTY_SITE_ERROR;
      END IF ; -- ln_creator_admin_count > 1
   
      -- Derive the role_id , group_id, division and manager resource id of creator resource           
      BEGIN          
        SELECT DISTINCT 
               MEM_CR.role_id
               ,ROL_CR.attribute15
               ,MEM_CR.group_id
               ,MGR_CR.resource_id 
        INTO   ln_creator_role_id
               , lc_creator_role_division
               , ln_creator_group_id
               , ln_creator_manager_id
        FROM   jtf_rs_group_mbr_role_vl MEM_CR
               , jtf_rs_roles_b ROL_CR
               , jtf_rs_group_mbr_role_vl MGR_CR
               , jtf_rs_roles_b ROL_MGR
        WHERE  MEM_CR.resource_id = ln_creator_resource_id
        AND    SYSDATE BETWEEN MEM_CR.start_date_active AND NVL(MEM_CR.end_date_active, SYSDATE+1)
        AND    ROL_CR.role_id              = MEM_CR.role_id
        AND    ROL_CR.role_type_code       = 'SALES'
        AND    ROL_CR.active_flag          = 'Y'
        AND    ROL_CR.attribute15          = p_division
        AND    DECODE(ln_creator_admin_count, 1, ROL_CR.admin_flag, 'N') = 
                                                   DECODE(ln_creator_admin_count, 1, 'Y', 'N')
        AND    DECODE(ln_creator_manager_count, 1, ROL_CR.attribute14, 'N') = 
                                                    DECODE(ln_creator_manager_count, 1, lc_manager_territory_role, 'N')
        AND    MGR_CR.group_id = MEM_CR.group_id
        AND    SYSDATE BETWEEN MGR_CR.start_date_active AND NVL(MGR_CR.end_date_active, SYSDATE+1)
        AND    MGR_CR.manager_flag = 'Y'
        AND    ROL_MGR.role_id              = MGR_CR.role_id
        AND    ROL_MGR.role_type_code       = 'SALES'
        AND    ROL_MGR.active_flag          = 'Y'
        AND    ROL_MGR.attribute15          = p_division;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF ln_creator_manager_count = 1 THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0227_CR_MGR_NO_HSE_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0227_CR_MGR_NO_HSE_ROLE';
          ELSE
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0160_CR_NO_SALES_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0160_CR_NO_SALES_ROLE';
          END IF;
          RAISE EX_PARTY_SITE_ERROR;
        WHEN TOO_MANY_ROWS THEN
          IF ln_creator_manager_count = 1 THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0228_CR_MGR_HSE_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0228_CR_MGR_HSE_ROLE';
          ELSE
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0118_CR_MANY_SALES_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0118_CR_MANY_SALES_ROLE';
          END IF;
          RAISE EX_PARTY_SITE_ERROR;
        WHEN OTHERS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the creator';
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          RAISE EX_PARTY_SITE_ERROR;
      END;
     
      -- If creator is an admin or manager or winner is admin then return the winner        
      IF (ln_creator_admin_count = 1 OR ln_creator_manager_count = 1 OR ln_win_admin_count = 1) THEN
        p_resource_id      := ln_win_resource_id;
        p_role_id          := ln_win_role_id;
        p_group_id         := ln_win_group_id;
        p_full_access_flag := lc_win_full_access_flag;
      -- Else If the winner is a manager and creator is a sales rep
      ELSIF ln_win_manager_count = 1 THEN
        -- Check whether the creator and the winner belong to the same group
        IF ln_creator_group_id <> ln_win_group_id THEN
          -- This means that the winner and the creator belong to seperate group
          -- So assign it to the winner
          p_resource_id      := ln_win_resource_id;
          p_role_id          := ln_win_role_id;
          p_group_id         := ln_win_group_id;
          p_full_access_flag := lc_win_full_access_flag;
        ELSE
          -- This means that the winner and the creator belong to the same group
          -- So assign it to the creator
          p_resource_id      := ln_creator_resource_id;
          p_role_id          := ln_creator_role_id;
          p_group_id         := ln_creator_group_id;
          p_full_access_flag := 'Y';
        END IF; -- ln_creator_group_id <> ln_win_group_id
      -- The winner is a sales rep and creator is a sales rep
      ELSE
        -- Derive the manager of the winner
        BEGIN
          SELECT DISTINCT MGR_CR.resource_id
          INTO   ln_win_manager_id
          FROM   jtf_rs_group_mbr_role_vl MGR_CR
                 , jtf_rs_roles_b ROL_MGR
          WHERE  MGR_CR.group_id = ln_win_group_id
          AND    SYSDATE BETWEEN MGR_CR.start_date_active AND NVL(MGR_CR.end_date_active, SYSDATE+1)
          AND    MGR_CR.manager_flag = 'Y'
          AND    ROL_MGR.role_id              = MGR_CR.role_id
          AND    ROL_MGR.role_type_code       = 'SALES'
          AND    ROL_MGR.active_flag          = 'Y'
          AND    ROL_MGR.attribute15          = p_division;                                     
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0127_AS_NO_MANAGER');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_win_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            RAISE EX_PARTY_SITE_ERROR;
          WHEN TOO_MANY_ROWS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0128_AS_MANY_MANAGERS');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_win_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            RAISE EX_PARTY_SITE_ERROR;
          WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
            lc_set_message     :=  'Unexpected Error while deriving manager_id of the winner';
            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            lc_error_message := FND_MESSAGE.GET;
            RAISE EX_PARTY_SITE_ERROR;
        END;

        -- Compare the manager of the creator to that of the winner 
        IF ln_creator_manager_id = ln_win_manager_id THEN
          -- This means that the winner and the creator report to same person
          -- So assign it to the creator
          p_resource_id      := ln_creator_resource_id;
          p_role_id          := ln_creator_role_id;
          p_group_id         := ln_creator_group_id;
          p_full_access_flag := 'Y';
        ELSE
          -- This means that the winner and the creator do not report to same person
          -- So assign it to the winner
          p_resource_id      := ln_win_resource_id;
          p_role_id          := ln_win_role_id;
          p_group_id         := ln_win_group_id;
          p_full_access_flag := lc_win_full_access_flag;
        END IF; -- ln_creator_manager_id = ln_win_manager_id
      END IF; -- ln_win_manager_count = 1
    END IF; -- lc_compare_creator_territory = 'Y'
  END IF; -- p_nam_terr_id IS NULL
EXCEPTION
  WHEN EX_PARTY_SITE_ERROR THEN
    x_return_status  := FND_API.G_RET_STS_ERROR;
    x_message_data   := lc_error_message;
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_message_data := 'Error in XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP: '||sqlcode||sqlerrm;
END TERR_RULE_BASED_WINNER_LOOKUP;
  
END XX_TM_TERRITORY_UTIL_PKG;
/
SHOW ERRORS;

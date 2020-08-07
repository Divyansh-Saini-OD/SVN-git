create or replace 
PACKAGE BODY xxod_ar_sfa_hierarchy_pkg AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_SALESREP_GROUP_ID                         |
-- | RICE ID          :  R0028                                         |
-- | Description      :  This function will get the SALESREP GROUP ID  |
-- |                     for the entity_id that is passed as parameter |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION   get_salesrep_group_id(
                  p_entity_id IN NUMBER)
RETURN NUMBER
IS
   ln_group_id          NUMBER;
BEGIN
   BEGIN
      SELECT JRGMRV.group_id
      INTO ln_group_id
      FROM xx_tm_nam_terr_curr_assign_v  XTNTCAV
           ,jtf_rs_group_mbr_role_vl    JRGMRV
           ,jtf_rs_roles_vl             JRRV
      WHERE XTNTCAV.ENTITY_TYPE='PARTY_SITE'
      AND XTNTCAV.entity_id=p_entity_id
      AND XTNTCAV.GROUP_ID=JRGMRV.group_id
      AND XTNTCAV.resource_role_id=JRGMRV.role_id
      AND XTNTCAV.RESOURCE_ID=JRGMRV.RESOURCE_ID
      AND JRGMRV.MEMBER_FLAG='Y'
      AND JRRV.ROLE_ID=JRGMRV.role_id
      AND JRRV.role_type_code in ('SALES','TELESALES')
      AND JRRV.attribute15 ='BSD'
      AND JRRV.Active_flag ='Y'
      AND TRUNC(sysdate) BETWEEN
            nvl(JRGMRV.start_date_active,sysdate -1) AND nvl(JRGMRV.end_date_active,sysdate + 1);
      RETURN ln_group_id;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         ln_group_id:=0;
         RETURN ln_group_id;
      WHEN OTHERS THEN
         ln_group_id:=0;
         RETURN ln_group_id;
   END;
END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_RSD_GROUP_ID                              |
-- | RICE ID          :  R0505,R0506 and R0507                         |
-- | Description      :  This function will get the RSD GROUP ID       |
-- |                     for the entity_id that is passed as parameter |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION   get_rsd_group_id(
                  p_entity_id IN NUMBER)
RETURN NUMBER
IS
   ln_group_id          NUMBER;
   ln_rsd_group_id      NUMBER;
BEGIN

   ln_group_id:=get_salesrep_group_id(p_entity_id);
   IF ln_group_id >0
   THEN
      BEGIN
         SELECT JRGR.related_group_id
         INTO ln_rsd_group_id
         FROM jtf_rs_roles_vl JRRV
               ,jtf_rs_group_mbr_role_vl   JRGMRV
               ,jtf_rs_resource_extns      JRRE
               ,jtf_rs_grp_relations       JRGR
          WHERE JRRV.attribute14              ='RSD'
          AND JRRV.role_id = JRGMRV.role_id
         AND JRRV.role_type_code IN ('SALES','TELESALES')
         AND JRRV.attribute15 ='BSD'
         AND JRRV.active_flag= 'Y'
         AND JRRV.manager_flag ='Y'
         AND JRGMRV.group_id   = JRGR.related_group_id
         AND JRGR.group_id = ln_group_id
         AND JRGMRV.resource_id = JRRE.resource_id
         AND JRGR.relation_type = 'PARENT_GROUP'
         AND NVL(JRGR.delete_flag,'N')='N'
         AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                AND NVL(JRGMRV.end_date_active,SYSDATE+1)
         AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                AND NVL(JRRE.end_date_active,SYSDATE+1)
         AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                               AND NVL(JRGR.end_date_active,SYSDATE+1);
         RETURN ln_rsd_group_id;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            ln_rsd_group_id:=0;
            RETURN ln_rsd_group_id;
         WHEN OTHERS THEN
            ln_rsd_group_id:=0;
            RETURN ln_rsd_group_id;
      END;
   ELSE
      ln_rsd_group_id:=0;
      RETURN ln_rsd_group_id;
   END IF;
END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_SALESREP_NAME                             |
-- | RICE ID          :  R0505,R0506 and R0507                         |
-- | Description      :  This function will get the SALESREP Name      |
-- |                     for the entity_id that is passed as parameter |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_salesrep_name(p_entity_id IN NUMBER)
RETURN VARCHAR2
IS
   lc_salesrep_name        jtf_rs_resource_extns.source_name%TYPE;
BEGIN
   BEGIN
      SELECT JRREV.source_name
      INTO lc_salesrep_name
      FROM xx_tm_nam_terr_curr_assign_v  XTNTCAV
           ,jtf_rs_group_mbr_role_vl    JRGMRV
           ,jtf_rs_roles_vl             JRRV
           ,jtf_rs_resource_extns_vl    JRREV
      WHERE  XTNTCAV.entity_id=p_entity_id
      AND XTNTCAV.ENTITY_TYPE='PARTY_SITE'
      AND XTNTCAV.GROUP_ID=JRGMRV.group_id
      AND XTNTCAV.resource_role_id=JRGMRV.role_id
      AND XTNTCAV.RESOURCE_ID=JRGMRV.RESOURCE_ID
      AND JRGMRV.MEMBER_FLAG='Y'
      AND JRRV.ROLE_ID=JRGMRV.role_id
      AND JRREV.resource_id(+)=JRGMRV.resource_id
      AND JRRV.role_type_code in ('SALES','TELESALES')
      AND JRRV.attribute15 ='BSD'
      AND JRRV.Active_flag ='Y'
      AND TRUNC(sysdate) BETWEEN nvl(JRGMRV.start_date_active,sysdate -1)
         AND nvl(JRGMRV.end_date_active,sysdate + 1)
      AND TRUNC(sysdate) BETWEEN nvl(JRREV.start_date_active,sysdate -1)
            AND nvl(JRREV.end_date_active,sysdate + 1);
   RETURN lc_salesrep_name;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_salesrep_name:=NULL;
         RETURN lc_salesrep_name;
      WHEN OTHERS THEN
         lc_salesrep_name:=NULL;
         RETURN lc_salesrep_name;
    END;
END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_DSM_NAME                                  |
-- | RICE ID          :  R0505,R0506 and R0507                         |
-- | Description      :  This function will get the DSM Name for the   |
-- |                     salesrep that is passed as parameter          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_dsm_name(p_entity_id IN NUMBER)
RETURN VARCHAR2
IS
   lc_dsm_name         jtf_rs_resource_extns.source_name%TYPE;
   ln_group_id         NUMBER;
BEGIN
   BEGIN
      ln_group_id:=get_salesrep_group_id(p_entity_id);
      SELECT JRRE.source_name
      INTO   lc_dsm_name
      FROM  jtf_rs_roles_vl JRRV
            ,jtf_rs_group_mbr_role_vl   JRGMRV
           ,jtf_rs_resource_extns      JRRE
      WHERE JRRV.attribute14              ='DSM'
      AND JRRV.role_id = JRGMRV.role_id
      AND JRRV.role_type_code IN ('SALES','TELESALES')
      AND JRRV.attribute15 ='BSD'
      AND JRRV.active_flag= 'Y'
      AND JRRV.manager_flag ='Y'
      AND JRGMRV.group_id =ln_group_id
      AND JRGMRV.resource_id = JRRE.resource_id
      AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                    AND NVL(JRGMRV.end_date_active,SYSDATE+1)
      AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
            AND NVL(JRRE.end_date_active,SYSDATE+1);
      RETURN lc_dsm_name;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_dsm_name:=NULL;
         RETURN lc_dsm_name;
      WHEN OTHERS THEN
         lc_dsm_name:=NULL;
         RETURN lc_dsm_name;
   END;
END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_RSD_NAME                                  |
-- | RICE ID          :  R0505,R0506 and R0507                         |
-- | Description      :  This function will get the RSD Name for the   |
-- |                     salesrep/DSM that is passed as parameter      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_rsd_name(p_entity_id IN NUMBER
                      ,p_reportee IN VARCHAR2
                        )
RETURN VARCHAR2
IS
   lc_rsd_name         jtf_rs_resource_extns.source_name%TYPE;
   ln_group_id         NUMBER;
BEGIN
   BEGIN
      ln_group_id:=get_salesrep_group_id(p_entity_id);
      --IF DSM reports to RSD, then fetch RSD from the DSM
      IF(p_reportee = 'DSM')
      THEN
         BEGIN
         --FETCH RSD if exists in the above group of DSM group
            SELECT JRRE.source_name
            INTO lc_rsd_name
            FROM jtf_rs_roles_vl JRRV
               ,jtf_rs_group_mbr_role_vl   JRGMRV
               ,jtf_rs_resource_extns      JRRE
               ,jtf_rs_grp_relations       JRGR
            WHERE JRRV.attribute14              ='RSD'
            AND JRRV.role_id = JRGMRV.role_id
            AND JRRV.role_type_code IN ('SALES','TELESALES')
            AND JRRV.attribute15 ='BSD'
            AND JRRV.active_flag= 'Y'
            AND JRRV.manager_flag ='Y'
            AND JRGMRV.group_id   = JRGR.related_group_id
            AND JRGR.group_id = ln_group_id
            AND JRGMRV.resource_id = JRRE.resource_id
            AND JRGR.relation_type = 'PARENT_GROUP'
            AND NVL(JRGR.delete_flag,'N')='N'
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGMRV.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                   AND NVL(JRRE.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGR.end_date_active,SYSDATE+1);
            RETURN lc_rsd_name;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  lc_rsd_name:=NULL;
                  RETURN lc_rsd_name;
            WHEN OTHERS THEN
                  lc_rsd_name:=NULL;
                  RETURN lc_rsd_name;
         END;
      ELSIF (p_reportee = 'SALESREP')
      THEN
      --IF SALESREP reports directly to RSD, then fetch RSD from the SALES REP
         BEGIN
            --IF DSM not exists, then FETCH RSD from the same group of salesrep group
            SELECT JRRE.source_name
            INTO lc_rsd_name
            FROM jtf_rs_roles_vl JRRV
               ,jtf_rs_group_mbr_role_vl   JRGMRV
               ,jtf_rs_resource_extns      JRRE
            WHERE  JRRV.attribute14              ='RSD'
            AND JRRV.role_id = JRGMRV.role_id
            AND JRRV.role_type_code IN ('SALES','TELESALES')
            AND JRRV.attribute15 ='BSD'
            AND JRRV.active_flag= 'Y'
            AND JRRV.manager_flag ='Y'
            AND JRGMRV.group_id = ln_group_id
            AND JRGMRV.resource_id = JRRE.resource_id
            AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                             AND NVL(JRGMRV.end_date_active,SYSDATE+1)
            AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                             AND NVL(JRRE.end_date_active,SYSDATE+1);
            RETURN lc_rsd_name;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                     --IF DSM not exists, then FETCH RSD from the above group of salesrep group
                     SELECT JRRE.source_name
                     INTO lc_rsd_name
                     FROM jtf_rs_roles_vl JRRV
                           ,jtf_rs_group_mbr_role_vl   JRGMRV
                          ,jtf_rs_resource_extns      JRRE
                          ,jtf_rs_grp_relations       JRGR
                     WHERE JRRV.attribute14              ='RSD'
                     AND JRRV.role_id = JRGMRV.role_id
                     AND JRRV.role_type_code IN ('SALES','TELESALES')
                     AND JRRV.attribute15 ='BSD'
                     AND JRRV.active_flag= 'Y'
                     AND JRRV.manager_flag ='Y'
                     AND JRGMRV.group_id   = JRGR.related_group_id
                     AND JRGR.group_id = ln_group_id
                     AND JRGMRV.resource_id = JRRE.resource_id
                     AND JRGR.relation_type = 'PARENT_GROUP'
                     AND NVL(JRGR.delete_flag,'N')='N'
                     AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGMRV.end_date_active,SYSDATE+1)
                     AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                   AND NVL(JRRE.end_date_active,SYSDATE+1)
                     AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGR.end_date_active,SYSDATE+1);
                    RETURN lc_rsd_name;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_rsd_name:=NULL;
                     RETURN lc_rsd_name;
                  WHEN OTHERS THEN
                     lc_rsd_name:=NULL;
                     RETURN lc_rsd_name;
                END;
            WHEN OTHERS THEN
               lc_rsd_name:=NULL;
               RETURN lc_rsd_name;
         END;
      END IF;
   END;
END;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_VP_NAME                                   |
-- | RICE ID          :  R0505,R0506 and R0507                         |
-- | Description      :  This function will get the VP Name for the    |
-- |                     salesrep/DSM/RSD that is passed as parameter  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-APR-2008  Senthil Kumar   Initial draft version        |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_vp_name(p_entity_id IN NUMBER
                        ,p_reportee IN VARCHAR2
                        )
RETURN VARCHAR2
IS
   lc_vp_name           jtf_rs_resource_extns.source_name%TYPE;
   ln_group_id          NUMBER;
   ln_rsd_group_id      NUMBER;
BEGIN
   BEGIN
      --IF the RSD reports to VP, then fetch the VP from RSD.
      IF(p_reportee='RSD')
      THEN
         ln_rsd_group_id:=get_rsd_group_id(p_entity_id);
         dbms_output.put_line('rsd group :'||ln_rsd_group_id);
         IF ln_rsd_group_id > 0
         THEN
            BEGIN
               SELECT JRRE.source_name
               INTO lc_vp_name
               FROM jtf_rs_roles_vl JRRV
                  ,jtf_rs_group_mbr_role_vl   JRGMRV
                  ,jtf_rs_resource_extns      JRRE
                  ,jtf_rs_grp_relations       JRGR
               WHERE JRRV.attribute14              ='VP'
               AND JRRV.role_id = JRGMRV.role_id
               AND JRRV.role_type_code IN ('SALES','TELESALES')
               AND JRRV.attribute15 ='BSD'
               AND JRRV.active_flag= 'Y'
               AND JRRV.manager_flag ='Y'
               AND JRGMRV.group_id   = JRGR.related_group_id
               AND JRGR.group_id = ln_rsd_group_id
               AND JRGMRV.resource_id = JRRE.resource_id
               AND JRGR.relation_type = 'PARENT_GROUP'
               AND NVL(JRGR.delete_flag,'N')='N'
               AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGMRV.end_date_active,SYSDATE+1)
               AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                   AND NVL(JRRE.end_date_active,SYSDATE+1)
               AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGR.end_date_active,SYSDATE+1);
               dbms_output.put_line('no exception :'||lc_vp_name);
               RETURN lc_vp_name;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  lc_vp_name:=NULL;
                  RETURN lc_vp_name;
               WHEN OTHERS THEN
                  lc_vp_name:=NULL;
                  RETURN lc_vp_name;
            END;
         ELSE
            lc_vp_name:=NULL;
            dbms_output.put_line('Else exception :'||lc_vp_name);
            RETURN lc_vp_name;
         END IF;
      ELSIF(p_reportee='DSM')
      THEN
         ln_group_id:=get_salesrep_group_id(p_entity_id);
         IF(ln_group_id > 0)
         THEN
            BEGIN
            --FETCH VP if exists in the above group of DSM group
               SELECT JRRE.source_name
               INTO lc_vp_name
               FROM jtf_rs_roles_vl JRRV
                  ,jtf_rs_group_mbr_role_vl   JRGMRV
                  ,jtf_rs_resource_extns      JRRE
                  ,jtf_rs_grp_relations       JRGR
               WHERE JRRV.attribute14              ='VP'
               AND JRRV.role_id = JRGMRV.role_id
               AND JRRV.role_type_code IN ('SALES','TELESALES')
               AND JRRV.attribute15 ='BSD'
               AND JRRV.active_flag= 'Y'
               AND JRRV.manager_flag ='Y'
               AND JRGMRV.group_id   = JRGR.related_group_id
               AND JRGR.group_id = ln_group_id
               AND JRGMRV.resource_id = JRRE.resource_id
               AND JRGR.relation_type = 'PARENT_GROUP'
               AND NVL(JRGR.delete_flag,'N')='N'
               AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGMRV.end_date_active,SYSDATE+1)
               AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                   AND NVL(JRRE.end_date_active,SYSDATE+1)
               AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                                   AND NVL(JRGR.end_date_active,SYSDATE+1);
               RETURN lc_vp_name;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  lc_vp_name:=NULL;
                  RETURN lc_vp_name;
               WHEN OTHERS THEN
                  lc_vp_name:=NULL;
                  RETURN lc_vp_name;
            END;
         ELSE
            lc_vp_name:=NULL;
            RETURN lc_vp_name;
         END IF;
      ELSIF (p_reportee = 'SALESREP')
      THEN
         ln_group_id:=get_salesrep_group_id(p_entity_id);
      --IF SALESREP reports directly to VP, then fetch VP from the SALES REP
         IF(ln_group_id > 0)
         THEN
            BEGIN
               --IF DSM not exists, then FETCH VP from the same group of salesrep group
               SELECT JRRE.source_name
               INTO lc_vp_name
               FROM jtf_rs_roles_vl JRRV
                  ,jtf_rs_group_mbr_role_vl   JRGMRV
                  ,jtf_rs_resource_extns      JRRE
               WHERE  JRRV.attribute14              ='VP'
               AND JRRV.role_id = JRGMRV.role_id
               AND JRRV.role_type_code IN ('SALES','TELESALES')
               AND JRRV.attribute15 ='BSD'
               AND JRRV.active_flag= 'Y'
               AND JRRV.manager_flag ='Y'
               AND JRGMRV.group_id = ln_group_id
               AND JRGMRV.resource_id = JRRE.resource_id
               AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                             AND NVL(JRGMRV.end_date_active,SYSDATE+1)
               AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                             AND NVL(JRRE.end_date_active,SYSDATE+1);
               RETURN lc_vp_name;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   BEGIN
                     --IF DSM not exists, then FETCH VP from the above group of salesrep group
                        SELECT JRRE.source_name
                        INTO lc_vp_name
                        FROM jtf_rs_roles_vl JRRV
                              ,jtf_rs_group_mbr_role_vl   JRGMRV
                              ,jtf_rs_resource_extns      JRRE
                              ,jtf_rs_grp_relations       JRGR
                        WHERE JRRV.attribute14              ='VP'
                        AND JRRV.role_id = JRGMRV.role_id
                        AND JRRV.role_type_code IN ('SALES','TELESALES')
                        AND JRRV.attribute15 ='BSD'
                        AND JRRV.active_flag= 'Y'
                        AND JRRV.manager_flag ='Y'
                        AND JRGMRV.group_id   = JRGR.related_group_id
                        AND JRGR.group_id = ln_group_id
                        AND JRGMRV.resource_id = JRRE.resource_id
                        AND JRGR.relation_type = 'PARENT_GROUP'
                        AND NVL(JRGR.delete_flag,'N')='N'
                        AND TRUNC(SYSDATE) BETWEEN NVL(JRGMRV.start_date_active,SYSDATE-1)
                                                      AND NVL(JRGMRV.end_date_active,SYSDATE+1)
                        AND TRUNC(SYSDATE) BETWEEN NVL(JRRE.start_date_active,SYSDATE-1)
                                                      AND NVL(JRRE.end_date_active,SYSDATE+1)
                        AND TRUNC(SYSDATE) BETWEEN NVL(JRGR.start_date_active,SYSDATE-1)
                                                      AND NVL(JRGR.end_date_active,SYSDATE+1);
                       RETURN lc_vp_name;
                   EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        lc_vp_name:=NULL;
                        RETURN lc_vp_name;
                     WHEN OTHERS THEN
                        lc_vp_name:=NULL;
                        RETURN lc_vp_name;
                   END;
               WHEN OTHERS THEN
                  lc_vp_name:=NULL;
                  RETURN lc_vp_name;
            END;
         ELSE
            lc_vp_name:=NULL;
            RETURN lc_vp_name;
         END IF;
      END IF;
   END;
END;

-- Function OPEN_TRX_OF_CHILD_FN is ADDED FOR DEFECT#31519
FUNCTION OPEN_TRX_OF_CHILD_FN(P_PARENT_ID IN NUMBER,P_CURRENCY_CODE IN VARCHAR2,P_ORG_ID IN NUMBER,P_CREDITLIMIT IN NUMBER) RETURN NUMBER IS
l_open_trx NUMBER;
l_overall_cr_limit number;
l_parent_total number;
l_child_total number;
l_cust_balance number;
BEGIN
  	    
  begin
    select NVL(sum(amount_due_remaining),0) INTO l_parent_total  from apps.ar_payment_schedules_all where
    status = 'OP' 
    and amount_due_remaining > 0
    and org_id = p_org_id
    and INVOICE_CURRENCY_CODE = DECODE(UPPER(P_CURRENCY_CODE), null, INVOICE_CURRENCY_CODE,UPPER(P_CURRENCY_CODE)) 
    and CUSTOMER_ID in(
    select distinct cust_account_id from apps.Hz_Cust_Accounts_all 
    where party_Id = p_parent_id);
  EXCEPTION
  WHEN OTHERS THEN
      l_parent_total := 0;
  end; 
  
  BEGIN
    select NVL(sum(amount_due_remaining),0) INTO l_child_total  from apps.ar_payment_schedules_all where
    status = 'OP' 
    and amount_due_remaining > 0
    and org_id = p_org_id
    and INVOICE_CURRENCY_CODE = DECODE(UPPER(P_CURRENCY_CODE), null, INVOICE_CURRENCY_CODE,UPPER(P_CURRENCY_CODE))     
    and CUSTOMER_ID in(
    select distinct cust_account_id from apps.Hz_Cust_Accounts_all 
    where party_Id in
    (select distinct child_id from APPS.HZ_HIERARCHY_NODES hhn where            
           NVL(HHN.status(+),'A')='A'
    AND    NVL(HHN.effective_start_date(+),SYSDATE)<=SYSDATE
    AND    NVL(HHN.EFFECTIVE_END_DATE(+),sysdate) >= sysdate
    AND    HHN.PARENT_ID <> HHN.CHILD_ID
    AND    HHN.parent_id = P_PARENT_ID));
  EXCEPTION
	WHEN OTHERS THEN
	l_child_total := 0;
  END;
  
  l_cust_balance := (l_parent_total+l_child_total) - .75*P_CREDITLIMIT;
  
  IF l_cust_balance >= 0 THEN
  
     return (l_parent_total+l_child_total);
  ELSE
     return 0;
  END IF;
EXCEPTION
WHEN OTHERS THEN
RETURN 0; 
END OPEN_TRX_OF_CHILD_FN;

-- Function PARENT_BALANCE_FN is ADDED FOR DEFECT#31519
FUNCTION PARENT_BALANCE_FN(P_PARENT_ID IN NUMBER,P_CURRENCY_CODE IN VARCHAR2,P_ORG_ID IN NUMBER) RETURN NUMBER IS
l_open_trx NUMBER;
l_overall_cr_limit number;
l_parent_total number;
l_child_total number;
l_cust_balance number;
l_exchange_rate number;
BEGIN      
    
  begin
    select NVL(sum(AMOUNT_DUE_REMAINING * NVL (EXCHANGE_RATE, 1)),0) INTO l_parent_total  from apps.ar_payment_schedules_all where
    status = 'OP' 
    and amount_due_remaining > 0
    and org_id = p_org_id
    and INVOICE_CURRENCY_CODE = DECODE(UPPER(P_CURRENCY_CODE), null, INVOICE_CURRENCY_CODE,UPPER(P_CURRENCY_CODE))     
    and CUSTOMER_ID in(
    select distinct cust_account_id from apps.Hz_Cust_Accounts_all 
    where party_Id = p_parent_id);
  EXCEPTION
  WHEN OTHERS THEN
      l_parent_total := 0;
  end; 
  
  BEGIN
    select NVL(sum(AMOUNT_DUE_REMAINING * NVL (EXCHANGE_RATE, 1)),0) INTO l_child_total  from apps.ar_payment_schedules_all where
    status = 'OP' 
    and amount_due_remaining > 0
    and org_id = p_org_id
    and INVOICE_CURRENCY_CODE = DECODE(UPPER(P_CURRENCY_CODE), null, INVOICE_CURRENCY_CODE,UPPER(P_CURRENCY_CODE))     
    and CUSTOMER_ID in(
    select distinct cust_account_id from apps.Hz_Cust_Accounts_all 
    where party_Id in
    (select distinct child_id from APPS.HZ_HIERARCHY_NODES hhn where 
           NVL(HHN.status(+),'A')='A'
    AND    NVL(HHN.effective_start_date(+),SYSDATE)<=SYSDATE
    AND    NVL(HHN.EFFECTIVE_END_DATE(+),sysdate) >= sysdate
    AND    HHN.PARENT_ID <> HHN.CHILD_ID
    AND    HHN.parent_id = P_PARENT_ID));
  EXCEPTION
  WHEN OTHERS THEN
  l_child_total :=0;
  END;
  l_cust_balance := (l_parent_total+l_child_total);
  
       return l_cust_balance;  
EXCEPTION
WHEN OTHERS THEN
RETURN 0;
END PARENT_BALANCE_FN;
END xxod_ar_sfa_hierarchy_pkg;
/
SHOW ERROR
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CRM_USER_MANAGEMENT_PKG IS
  
  ROLE_PREFIC VARCHAR2(20) := 'OD_NA_SA_';
  ROLE_SUFFIX VARCHAR2(20) := '_ROL';
  MAX_ROLE_NAME_LENGTH NUMBER := 17; 
  MAX_ERRORS_REPORTED NUMBER := 3; 

  PROCEDURE delete_resource_job_roles(
      P_JOB_ROLE_ID        IN JTF_RS_JOB_ROLES.JOB_ROLE_ID%TYPE,
      P_OBJECT_VERSION_NUM IN JTF_RS_JOB_ROLES.OBJECT_VERSION_NUMBER%TYPE,
      P_COMMIT             IN   VARCHAR2   DEFAULT  FND_API.G_TRUE,
      X_MSG_COUNT OUT NOCOPY NUMBER,
      X_MSG_DATA OUT NOCOPY  VARCHAR2 )
  IS
    v_msg_index_out NUMBER;
    x_item_id       NUMBER;
    x_org_id        NUMBER;
    x_return_status VARCHAR2 (1);
    v_message       VARCHAR2 (4000);
    ret_message     VARCHAR2(4000);
  BEGIN
  
    X_MSG_COUNT := 0;
    X_MSG_DATA := '';
    
    jtf_rs_job_roles_pvt.delete_resource_job_roles (
                      P_API_VERSION         => 1.0, 
                      P_INIT_MSG_LIST       => FND_API.G_TRUE, 
                      P_COMMIT              => FND_API.G_TRUE, 
                      P_JOB_ROLE_ID         => P_JOB_ROLE_ID, 
                      P_OBJECT_VERSION_NUM  => P_OBJECT_VERSION_NUM , 
                      x_return_status       => x_return_status ,
                      x_msg_count           => x_msg_count , 
                      x_msg_data            => x_msg_data 
    );
    IF x_msg_count > 0 THEN
      FOR v_index IN 1 .. x_msg_count
      LOOP
        fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        ret_message := ret_message || x_msg_data || chr(10);
      END LOOP;
    END IF;
    x_msg_data := ret_message;
  END delete_resource_job_roles;
 
   
  PROCEDURE delete_resource_job_roles_bulk(
      P_RECORDS        XX_CRM_ROLE_JOB_DEL_TBL,
      X_MSG_COUNT OUT NOCOPY NUMBER,
      X_MSG_DATA OUT NOCOPY  VARCHAR2 )
  IS
    v_msg_index_out NUMBER;
    x_item_id       NUMBER;
    x_job_role_id   NUMBER;
    x_return_status VARCHAR2 (1);
    v_message       VARCHAR2 (4000);
    v_temp_message  VARCHAR2 (4000);
    v_temp_cnt      NUMBER;
    ret_message     VARCHAR2(4000);
  
  BEGIN
  
    X_MSG_COUNT := 0;
    X_MSG_DATA := '';
    
    FOR idx in 1..P_RECORDS.count
    LOOP
      delete_resource_job_roles(
        P_JOB_ROLE_ID        =>  P_RECORDS(idx).JOB_ROLE_ID,
        P_OBJECT_VERSION_NUM =>  P_RECORDS(idx).OBJECT_VERSION_NUM,
        P_COMMIT        =>  FND_API.G_FALSE,
        X_MSG_COUNT     => v_temp_cnt,
        X_MSG_DATA      => v_temp_message
      );
      
      if v_temp_cnt > 0 THEN
        X_MSG_COUNT := X_MSG_COUNT  +  v_temp_cnt;
        X_MSG_DATA := X_MSG_DATA || v_temp_message || chr(10);
      end if;
      
    END LOOP;
    
    commit;
  
  END delete_resource_job_roles_bulk;
  
  PROCEDURE create_resource_job_roles(
      P_JOB_ID        IN JTF_RS_JOB_ROLES.JOB_ID%TYPE,
      P_ROLE_ID       IN   JTF_RS_JOB_ROLES.ROLE_ID%TYPE,
      P_COMMIT        IN   VARCHAR2   DEFAULT  FND_API.G_TRUE,
      X_JOB_ROLE_ID   OUT NOCOPY JTF_RS_JOB_ROLES.JOB_ROLE_ID%TYPE,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2 )
  IS
    v_msg_index_out NUMBER;
    x_item_id       NUMBER;
    x_return_status VARCHAR2 (1);
    v_message       VARCHAR2 (4000);
    ret_message     VARCHAR2(4000);
  BEGIN
  
    X_MSG_COUNT := 0;
    X_MSG_DATA := '';
    
    jtf_rs_job_roles_pvt.create_resource_job_roles (
                      P_API_VERSION         => 1.0, 
                      P_INIT_MSG_LIST       => FND_API.G_TRUE, 
                      P_COMMIT              => P_COMMIT, 
                      P_JOB_ID              => P_JOB_ID, 
                      P_ROLE_ID             => P_ROLE_ID,
                      X_RETURN_STATUS       => X_RETURN_STATUS ,
                      X_MSG_COUNT           => X_MSG_COUNT , 
                      X_MSG_DATA            => X_MSG_DATA,
                      X_JOB_ROLE_ID         => X_JOB_ROLE_ID
    );
    IF x_msg_count > 0 THEN
      FOR v_index IN 1 .. x_msg_count
      LOOP
        fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        ret_message := ret_message || x_msg_data || chr(10);
      END LOOP;
    END IF;
    x_msg_data := ret_message;
  END create_resource_job_roles;  
  
  PROCEDURE create_resource_job_roles_bulk(
      P_RECORDS       XX_CRM_ROLE_JOB_REL_TBL,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2
  )
  IS
    v_msg_index_out NUMBER;
    x_item_id       NUMBER;
    x_job_role_id   NUMBER;
    x_return_status VARCHAR2 (1);
    v_message       VARCHAR2 (4000);
    v_temp_message  VARCHAR2 (4000);
    v_temp_cnt      NUMBER;
    RET_MESSAGE     VARCHAR2(4000);
    V_JOB_NAME      VARCHAR2(700);
    V_ROLE_NAME     VARCHAR2(60);
    c_max_err_reached  VARCHAR2(1);
    
    CURSOR C_USED_JOBS (P_JOB_ID IN  NUMBER) IS
    SELECT JR.JOB_NAME,  ROL.ROLE_NAME  FROM JTF_RS_JOB_ROLES_VL JR, JTF_RS_ROLES_VL ROL
              WHERE JR.ROLE_ID = ROL.ROLE_ID AND JR.JOB_ID = P_JOB_ID;
  BEGIN

    X_MSG_COUNT := 0;
    X_MSG_DATA := '';
    c_max_err_reached := 'N';

    
    FOR idx in 1..P_RECORDS.count
    LOOP
      --Make sure the job is not assigned already
      SELECT COUNT(1) INTO V_TEMP_CNT  FROM JTF_RS_JOB_ROLES_VL WHERE JOB_ID = P_RECORDS(IDX).JOB_ID;
      
      IF(V_TEMP_CNT = 0) THEN
               V_TEMP_CNT := 0;
               V_TEMP_MESSAGE := '';
               
               create_resource_job_roles(
                P_JOB_ID        =>  P_RECORDS(idx).job_id,
                P_ROLE_ID       =>  P_RECORDS(idx).role_id,
                P_COMMIT        =>  FND_API.G_FALSE,
                X_JOB_ROLE_ID   =>  x_job_role_id,
                X_MSG_COUNT     => v_temp_cnt,
                X_MSG_DATA      => v_temp_message
              );
              
              IF(v_temp_cnt > 0) THEN
              
                    IF(X_MSG_COUNT <= 10) THEN
                        
                          BEGIN
                            SELECT J.NAME INTO V_JOB_NAME FROM PER_JOBS_VL  J WHERE J.JOB_ID = P_RECORDS(IDX).JOB_ID;
                            EXCEPTION WHEN NO_DATA_FOUND THEN
                              V_JOB_NAME := '<UNKNOWN>';
                          END;
                          
                          X_MSG_COUNT := X_MSG_COUNT  +  V_TEMP_CNT;
                          X_MSG_DATA := 'Error adding job ' || V_JOB_NAME  || ' - ' || X_MSG_DATA || v_temp_message || chr(10);
        
                    ELSE
                      IF c_max_err_reached = 'N' THEN
                        C_MAX_ERR_REACHED := 'Y';
                        X_MSG_DATA := X_MSG_DATA  || 'More errors...' || chr(10);
                      END IF;
                    END IF;
                    
              END IF;   
        ELSE

          FOR MY_REC  IN C_USED_JOBS (P_RECORDS(IDX).JOB_ID) 
          LOOP
            IF(X_MSG_COUNT <= 10) THEN
              X_MSG_COUNT := X_MSG_COUNT  +  1;
              X_MSG_DATA := X_MSG_DATA || 'Error adding job ' || MY_REC.JOB_NAME  || ' - ' || 'Job already in use by role ''' || MY_REC.ROLE_NAME || '''' || chr(10);
            ELSE
              IF c_max_err_reached = 'N' THEN
                C_MAX_ERR_REACHED := 'Y';
                X_MSG_DATA := X_MSG_DATA  || 'More errors...' || CHR(10);
              END IF;
            END IF;
          END LOOP;

        END IF;
        
    END LOOP;
    
    commit;
  
  END create_resource_job_roles_bulk;
  
  FUNCTION NEW_ROLE_CODE(P_NAME VARCHAR2 ) RETURN VARCHAR2
  IS
  V_ROLE_CODE   VARCHAR2(30);
  V_TEMP_CODE   VARCHAR2(30);
  V_NEW_SEQ     VARCHAR2(7);
  n_cnt NUMBER;
  BEGIN
    
    V_TEMP_CODE := SUBSTR(REGEXP_REPLACE(UPPER(TRIM(P_NAME)), '\s+', '_'),1, MAX_ROLE_NAME_LENGTH);
    V_ROLE_CODE := ROLE_PREFIC || V_TEMP_CODE || ROLE_SUFFIX;
    
    --Find out if this code is already in use
    SELECT  COUNT(1) INTO N_CNT FROM JTF_RS_ROLES_B WHERE ROLE_CODE = V_ROLE_CODE;
    
    -- if already in use then remove the last 6 digits of V_TEMP_CODE and replace it with
    -- a zero padded numeric sequence
    if N_CNT > 0 THEN
      
      SELECT  '_' || TO_CHAR(XX_CDH_USR_MAN_ROLE_CODE_S.NEXTVAL,'FM000000') INTO V_NEW_SEQ  FROM DUAL;
      
      V_TEMP_CODE := SUBSTR(V_TEMP_CODE, 1, 10) || V_NEW_SEQ;
      V_ROLE_CODE := ROLE_PREFIC || V_TEMP_CODE || ROLE_SUFFIX;
      
    END IF;
    
    RETURN V_ROLE_CODE;
    
  end NEW_ROLE_CODE;
  
  PROCEDURE CREATE_ROLE(
      P_ROLE_ROW      XX_CRM_ROLE,
      X_ROLE_ID       OUT NOCOPY NUMBER,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2
    )
  IS
    V_MSG_INDEX_OUT NUMBER;
    X_ITEM_ID       NUMBER;
    V_ROLE_CODE   VARCHAR2(30);
    X_RETURN_STATUS VARCHAR2 (1);
    V_MESSAGE       VARCHAR2 (4000);
    RET_MESSAGE     VARCHAR2(4000);  
    n_count number;
    
  BEGIN
    X_MSG_COUNT := 0;
    X_MSG_DATA := '';   
  
    JTF_RS_ROLES_PVT.CREATE_RS_RESOURCE_ROLES(
     P_API_VERSION          =>   1.0,
      P_INIT_MSG_LIST       => FND_API.G_TRUE,
      P_COMMIT              => FND_API.G_TRUE,
      P_ROLE_TYPE_CODE      => P_ROLE_ROW.ROLE_TYPE_CODE,
      P_ROLE_CODE           => NEW_ROLE_CODE(P_ROLE_ROW.ROLE_NAME),
      P_ROLE_NAME           => P_ROLE_ROW.ROLE_NAME ,
      P_ROLE_DESC           => P_ROLE_ROW.ROLE_DESC,
      P_ACTIVE_FLAG         => P_ROLE_ROW.ACTIVE_FLAG,
      P_SEEDED_FLAG	        => P_ROLE_ROW.SEEDED_FLAG,
      P_MEMBER_FLAG         => P_ROLE_ROW.MEMBER_FLAG,
      P_ADMIN_FLAG          => P_ROLE_ROW.ADMIN_FLAG,
      P_LEAD_FLAG           => P_ROLE_ROW.LEAD_FLAG ,
      P_MANAGER_FLAG        => P_ROLE_ROW.MANAGER_FLAG,
      P_ATTRIBUTE1          => P_ROLE_ROW.ATTRIBUTE1,
      P_ATTRIBUTE2          => P_ROLE_ROW.ATTRIBUTE2,
      P_ATTRIBUTE3          => P_ROLE_ROW.ATTRIBUTE3,
      P_ATTRIBUTE4          => P_ROLE_ROW.ATTRIBUTE4,
      P_ATTRIBUTE5          => P_ROLE_ROW.ATTRIBUTE5,
      P_ATTRIBUTE6          => P_ROLE_ROW.ATTRIBUTE6,
      P_ATTRIBUTE7          => P_ROLE_ROW.ATTRIBUTE7,
      P_ATTRIBUTE8          => P_ROLE_ROW.ATTRIBUTE8,
      P_ATTRIBUTE9          => P_ROLE_ROW.ATTRIBUTE9,
      P_ATTRIBUTE10         => P_ROLE_ROW.ATTRIBUTE10,
      P_ATTRIBUTE11         => P_ROLE_ROW.ATTRIBUTE11,
      P_ATTRIBUTE12         => P_ROLE_ROW.ATTRIBUTE12,
      P_ATTRIBUTE13         => P_ROLE_ROW.ATTRIBUTE13,
      P_ATTRIBUTE14         => P_ROLE_ROW.ATTRIBUTE14,
      P_ATTRIBUTE15         => P_ROLE_ROW.ATTRIBUTE15,
      P_ATTRIBUTE_CATEGORY  => P_ROLE_ROW.ATTRIBUTE_CATEGORY,
      X_RETURN_STATUS       => X_RETURN_STATUS ,
      X_MSG_COUNT           => X_MSG_COUNT,
      X_MSG_DATA            => X_MSG_DATA,
      X_ROLE_ID 	          => X_ROLE_ID  
    );
  
      IF x_msg_count > 0 THEN
      FOR v_index IN 1 .. x_msg_count
      LOOP
        fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        ret_message := ret_message || x_msg_data || chr(10);
      END LOOP;
    END IF;
    X_MSG_DATA := RET_MESSAGE;
    
  END create_role;
  
  PROCEDURE UPDATE_ROLE(
      P_ROLE_ROW                XX_CRM_ROLE,
      X_OBJECT_VERSION_NUMBER   OUT NOCOPY NUMBER,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  VARCHAR2
    )
  IS
    v_msg_index_out NUMBER;
    x_item_id       NUMBER;
    x_return_status VARCHAR2 (1);
    V_MESSAGE       VARCHAR2 (4000);
    RET_MESSAGE     VARCHAR2(4000);  
    OLD_OBJECT_VERSION_NUMBER NUMBER;
    NEW_OBJECT_VERSION_NUMBER NUMBER;
  BEGIN
    X_MSG_COUNT := 0;
    X_MSG_DATA := ''; 
    OLD_OBJECT_VERSION_NUMBER := P_ROLE_ROW.OBJECT_VERSION_NUMBER;
    NEW_OBJECT_VERSION_NUMBER := P_ROLE_ROW.OBJECT_VERSION_NUMBER;

  
    JTF_RS_ROLES_PVT.UPDATE_RS_RESOURCE_ROLES(
     P_API_VERSION            =>   1.0,
      P_INIT_MSG_LIST         => FND_API.G_TRUE,
      P_COMMIT                => FND_API.G_TRUE,
      P_ROLE_ID               => P_ROLE_ROW.ROLE_ID,
      P_ROLE_CODE             => P_ROLE_ROW.ROLE_CODE,
      P_ROLE_TYPE_CODE        => P_ROLE_ROW.ROLE_TYPE_CODE,
      P_ROLE_NAME             => P_ROLE_ROW.ROLE_NAME ,
      P_ROLE_DESC             => P_ROLE_ROW.ROLE_DESC,
      P_ACTIVE_FLAG           => P_ROLE_ROW.ACTIVE_FLAG,
      P_SEEDED_FLAG	          => P_ROLE_ROW.SEEDED_FLAG,
      P_MEMBER_FLAG           => P_ROLE_ROW.MEMBER_FLAG,
      P_ADMIN_FLAG            => P_ROLE_ROW.ADMIN_FLAG,
      P_LEAD_FLAG             => P_ROLE_ROW.LEAD_FLAG ,
      P_MANAGER_FLAG          => P_ROLE_ROW.MANAGER_FLAG,
      P_ATTRIBUTE1            => P_ROLE_ROW.ATTRIBUTE1,
      P_ATTRIBUTE2            => P_ROLE_ROW.ATTRIBUTE2,
      P_ATTRIBUTE3            => P_ROLE_ROW.ATTRIBUTE3,
      P_ATTRIBUTE4            => P_ROLE_ROW.ATTRIBUTE4,
      P_ATTRIBUTE5            => P_ROLE_ROW.ATTRIBUTE5,
      P_ATTRIBUTE6            => P_ROLE_ROW.ATTRIBUTE6,
      P_ATTRIBUTE7            => P_ROLE_ROW.ATTRIBUTE7,
      P_ATTRIBUTE8            => P_ROLE_ROW.ATTRIBUTE8,
      P_ATTRIBUTE9            => P_ROLE_ROW.ATTRIBUTE9,
      P_ATTRIBUTE10           => P_ROLE_ROW.ATTRIBUTE10,
      P_ATTRIBUTE11           => P_ROLE_ROW.ATTRIBUTE11,
      P_ATTRIBUTE12           => P_ROLE_ROW.ATTRIBUTE12,
      P_ATTRIBUTE13           => P_ROLE_ROW.ATTRIBUTE13,
      P_ATTRIBUTE14           => P_ROLE_ROW.ATTRIBUTE14,
      P_ATTRIBUTE15           => P_ROLE_ROW.ATTRIBUTE15,
      P_ATTRIBUTE_CATEGORY    => P_ROLE_ROW.ATTRIBUTE_CATEGORY,
      P_OBJECT_VERSION_NUMBER => NEW_OBJECT_VERSION_NUMBER,
      X_RETURN_STATUS       => X_RETURN_STATUS ,
      X_MSG_COUNT           => X_MSG_COUNT,
      X_MSG_DATA            => X_MSG_DATA
    );
  
      
    IF x_msg_count > 0 THEN
      FOR v_index IN 1 .. x_msg_count
      LOOP
        fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        ret_message := ret_message || x_msg_data || chr(10);
      END LOOP;
    END IF;
    X_MSG_DATA := RET_MESSAGE;
    X_OBJECT_VERSION_NUMBER := NEW_OBJECT_VERSION_NUMBER;
  END UPDATE_ROLE;  
  
   PROCEDURE UPDATE_LGCY_ID_AND_BED(
      P_ROLE_RELATE_ID          JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE,
      P_ATTRIBUTE15             JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE,
      P_ATTRIBUTE14             JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE,
      P_OBJECT_VERSION_NUMBER   IN OUT NOCOPY JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  VARCHAR2
    )
  IS
    V_MSG_INDEX_OUT NUMBER;
    N_OLD_VER_NUMBER    JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE;
    x_return_status VARCHAR2 (1);
    V_MESSAGE       VARCHAR2 (4000);
    RET_MESSAGE     VARCHAR2(4000);  
    C_MAX_ERR_REACHED  VARCHAR2(1);
    NEW_OBJECT_VERSION_NUMBER NUMBER;
    N_TEMP_MSG_CNT      NUMBER;
    N_MSG_CNT  NUMBER;
    V_TEMP_MSG_DATA VARCHAR2(4000);
    N_RESOURCE_ID JTF_RS_RESOURCE_EXTNS.RESOURCE_ID%TYPE;
    N_ROLE_ID JTF_RS_ROLES_B.ROLE_ID%TYPE;
  
    
    -- Other resources with the same legacy sales id
    cursor CUR_RSC_ROL_GRP (X_ATTRIBUTE15 in JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%type,
                            X_RSC_ID in JTF_RS_RESOURCE_EXTNS.RESOURCE_ID%type,
                            X_ROL_ID in JTF_RS_ROLES_B.ROLE_ID%TYPE) is
    SELECT ROL.ROLE_NAME || ' ' || RSC.RESOURCE_NAME || '(' ||  RSC.SOURCE_NUMBER || ') group ' || GRP.GROUP_NAME RSC_ROL_GRP
       from jtf_rs_resource_extns_vl rsc,
            jtf_rs_group_members     mem,
            jtf_rs_groups_vl         grp,
            JTF_RS_ROLE_RELATIONS    RR,
            jtf_rs_roles_vl          rol
      where rsc.resource_id      = mem.resource_id
       AND mem.group_id          = grp.group_id
       AND mem.group_member_id   = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rr.role_resource_type = 'RS_GROUP_MEMBER'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND NVL(MEM.DELETE_FLAG,'N') <> 'Y'
       AND NVL(RR.DELETE_FLAG,'N')  <> 'Y' 
       AND UPPER(RR.ATTRIBUTE15) = UPPER(X_ATTRIBUTE15)
       AND RR.ROLE_RELATE_ID <> P_ROLE_RELATE_ID
       AND (  RSC.RESOURCE_ID <> X_RSC_ID
              OR
              RSC.RESOURCE_ID = X_RSC_ID AND  ROL.ROLE_ID <> X_ROL_ID
            );
       
  BEGIN 
    
      N_OLD_VER_NUMBER := P_OBJECT_VERSION_NUMBER;
      NEW_OBJECT_VERSION_NUMBER := P_OBJECT_VERSION_NUMBER;
      
      N_TEMP_MSG_CNT := 0;
      C_MAX_ERR_REACHED := 'N';
      
      X_MSG_DATA := '';
      V_TEMP_MSG_DATA := '';
      X_MSG_COUNT := 0;
      N_TEMP_MSG_CNT := 0;
      
      -- The resource id begin updated. 
      SELECT mem.resource_id, rol.role_id into N_RESOURCE_ID, N_ROLE_ID
       from 
            jtf_rs_group_members     mem,
            JTF_RS_ROLE_RELATIONS    RR,
            jtf_rs_roles_vl          rol
      where mem.group_member_id   = rr.role_resource_id
       AND rr.role_id            = rol.role_id
       AND rr.role_resource_type = 'RS_GROUP_MEMBER'
       AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
       AND NVL(MEM.DELETE_FLAG,'N') <> 'Y'
       AND NVL(RR.DELETE_FLAG,'N')  <> 'Y'
       AND RR.ROLE_RELATE_ID = P_ROLE_RELATE_ID; 
     
      FOR MY_REC IN CUR_RSC_ROL_GRP(P_ATTRIBUTE15, N_RESOURCE_ID, N_ROLE_ID) LOOP
        
          IF(N_TEMP_MSG_CNT <= MAX_ERRORS_REPORTED) THEN
            N_TEMP_MSG_CNT := N_TEMP_MSG_CNT  +  1;
            V_TEMP_MSG_DATA := V_TEMP_MSG_DATA || 'Legacy id already in use by ' || MY_REC.RSC_ROL_GRP ||  '.' || chr(10);
          ELSE
            IF C_MAX_ERR_REACHED = 'N' THEN
              C_MAX_ERR_REACHED := 'Y';
              V_TEMP_MSG_DATA := V_TEMP_MSG_DATA  || 'More errors...' || CHR(10);
            END IF;
          END IF;
        
      END LOOP;
    
      IF (N_TEMP_MSG_CNT = 0) THEN
        
        JTF_RS_ROLE_RELATE_PVT.UPDATE_RESOURCE_ROLE_RELATE
                   (P_API_VERSION         => 1,
                    P_INIT_MSG_LIST       => FND_API.G_TRUE,
                    P_COMMIT              => FND_API.G_TRUE,
                    p_role_relate_id      => P_ROLE_RELATE_ID,
                    p_object_version_num  => NEW_OBJECT_VERSION_NUMBER,
                    p_attribute15         => P_ATTRIBUTE15,
                    p_attribute14         => P_ATTRIBUTE14,
                    p_attribute_category  => 'SALES',
                    x_return_status       => X_RETURN_STATUS,
                    X_MSG_COUNT           => X_MSG_COUNT,
                    X_MSG_DATA            => X_MSG_DATA);
        
        IF x_msg_count > 0 THEN
          FOR v_index IN 1 .. x_msg_count
          LOOP
            EXIT WHEN C_MAX_ERR_REACHED = 'Y';
            IF(C_MAX_ERR_REACHED = 'N') THEN
              fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
              RET_MESSAGE := RET_MESSAGE || X_MSG_DATA || CHR(10);
            END IF;
            
            N_TEMP_MSG_CNT := N_TEMP_MSG_CNT + 1;
            
            IF(N_TEMP_MSG_CNT = MAX_ERRORS_REPORTED) THEN
              C_MAX_ERR_REACHED := 'Y';
            END IF;
          END LOOP;
        END IF;
                      
      END IF; --(X_MSG_COUNT = 0)
      
      X_MSG_DATA := V_TEMP_MSG_DATA || RET_MESSAGE;
      X_MSG_COUNT := N_TEMP_MSG_CNT;
      P_OBJECT_VERSION_NUMBER := NEW_OBJECT_VERSION_NUMBER;
  
  END   UPDATE_LGCY_ID_AND_BED;
  
  PROCEDURE CLEAR_LEGACY_SLS_ID(
      P_RECORDS      XX_CRM_ROLE_RELATE_MOD_TBL,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  VARCHAR2
    )
  IS
    
  NEW_OBJECT_VERSION_NUMBER NUMBER;  
  C_MAX_ERR_REACHED VARCHAR2(1);
  X_RETURN_STATUS varchar2 (1);
  V_MSG_INDEX_OUT number;
  RET_MESSAGE varchar2(4000);
  N_TEMP_MSG_CNT NUMBER;
  V_ATTRIBUTE15_TMP JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE;
  C_SKIP_RECORD varchar2(1);
  
  BEGIN
  
    X_MSG_DATA := '';
    X_MSG_COUNT := 0;
    N_TEMP_MSG_CNT :=0;
    C_MAX_ERR_REACHED := 'N';
    
    
    FOR idx in 1..P_RECORDS.count
    LOOP
      C_SKIP_RECORD := 'N';
      BEGIN
          SELECT ATTRIBUTE15 INTO V_ATTRIBUTE15_TMP FROM JTF_RS_ROLE_RELATIONS WHERE ROLE_RELATE_ID = P_RECORDS(IDX).ROLE_RELATE_ID;
         
          IF(V_ATTRIBUTE15_TMP IS NULL OR V_ATTRIBUTE15_TMP = '') THEN
            C_SKIP_RECORD := 'Y'; 
          END IF;
         
          EXCEPTION WHEN NO_DATA_FOUND THEN
                              C_SKIP_RECORD := 'Y';
      END;

      IF C_SKIP_RECORD = 'N' THEN
        
        NEW_OBJECT_VERSION_NUMBER := P_RECORDS(idx).OBJECT_VERSION_NUMBER;
    
            JTF_RS_ROLE_RELATE_PVT.UPDATE_RESOURCE_ROLE_RELATE
                       (P_API_VERSION         => 1,
                        P_INIT_MSG_LIST       => FND_API.G_TRUE,
                        P_COMMIT              => FND_API.G_FALSE,
                        p_role_relate_id      => P_RECORDS(idx).ROLE_RELATE_ID,
                        p_object_version_num  => NEW_OBJECT_VERSION_NUMBER,
                        p_attribute15         => '',
                        p_attribute_category  => 'SALES',
                        x_return_status       => X_RETURN_STATUS,
                        X_MSG_COUNT           => X_MSG_COUNT,
                        X_MSG_DATA            => X_MSG_DATA);
                        
              IF x_msg_count > 0 THEN
                  FOR v_index IN 1 .. x_msg_count
                  LOOP
                    EXIT WHEN C_MAX_ERR_REACHED = 'Y';
                    IF(C_MAX_ERR_REACHED = 'N') THEN
                      fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
                      RET_MESSAGE := RET_MESSAGE || X_MSG_DATA || CHR(10);
                    END IF;
                    
                    N_TEMP_MSG_CNT := N_TEMP_MSG_CNT + 1;
                    
                    IF(N_TEMP_MSG_CNT = MAX_ERRORS_REPORTED) THEN
                      C_MAX_ERR_REACHED := 'Y';
                    end if;
          
                  END LOOP;
              END IF;  
        END IF; --C_SKIP_RECORD = 'N'
    END LOOP;
    
    X_MSG_DATA := RET_MESSAGE;
    
    COMMIT;
    
  
  
  END CLEAR_LEGACY_SLS_ID;
  
 /* PROCEDURE CREATE_SFDC_ROLE_MAP(
      P_RECORD      XX_CRM_SFDC_JOBS_MAP,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  varchar2)
  is
  N_TEMP_COUNT number(15);
  N_TEMP_JOB_ID XXCRM_SFDC_PROF_JOBS_MA.JOB_ID%type;
  C_JOB_NAME PER_JOBS_VL.name%type;
  begin
  
 
    X_MSG_DATA := '';
    X_MSG_COUNT := 0;
    N_TEMP_COUNT := 0;
    
    
  --Make sure the job is not yet mapped.
    select job_id  into  N_TEMP_JOB_ID,  from  XXCRM_SFDC_PROF_JOBS_MAP
    where JOB_NAME = P_RECORD.JOB_NAME; 
      IF(V_ATTRIBUTE15_TMP IS NULL OR V_ATTRIBUTE15_TMP = '') THEN
        C_SKIP_RECORD := 'Y'; 
      END IF;
     
      EXCEPTION WHEN NO_DATA_FOUND THEN
                          C_SKIP_RECORD := 'Y';
   
   if(N_TEMP_COUNT > 0) then
   
    --Now make sure the job id does exist 
    N_TEMP_COUNT := 0;
    select COUNT(1) into N_TEMP_COUNT from PER_JOBS_VL
    where  JOB_ID = P_RECORD.JOB_ID
          and sysdate between NVL(DATE_FROM, sysdate-1) and  NVL(DATE_TO, sysdate +1);
    
    if(N_TEMP_COUNT > 0)
   
   end if;
  
      begin
      
        select count(1) from XXCRM_SFDC_PROF_JOBS_MAP
      

      END;
      
    
  
  END CREATE_SFDC_ROLE_MAP
  */
END XX_CRM_USER_MANAGEMENT_PKG;

/
SHOW ERRORS;
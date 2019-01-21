SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_GP_IMPORT_PKG.pkb                                                     |
-- | Description : GP Import                                                                    |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-Jun-2011     Indra Varada        Initial version                              |
-- |1.1        01-Aug-2011     Indra Varada        fix for defect#12951                         |
-- |1.2        18-May-2016     Shubashree R        Removed the schema reference for GSCC compliance QC#37898|
-- +============================================================================================+

create or replace
PACKAGE BODY XX_CDH_GP_IMPORT_PKG AS

  FUNCTION save_gp (
    p_gp_id                      IN NUMBER,
    p_gp_name                    IN VARCHAR2,
    p_owner                      IN VARCHAR2,
    p_segment                    IN VARCHAR2,
    p_revenue_band               IN VARCHAR2,
    p_written_agreement          IN VARCHAR2,
    p_requestor                  IN VARCHAR2, 
    p_notes                      IN VARCHAR2,
    p_active                     IN VARCHAR2
  ) RETURN VARCHAR2 
  IS
  l_gp_id            NUMBER;
  l_msg_count        NUMBER;
  l_party_id         NUMBER;
  x_ret_status       VARCHAR2(10);
  x_ret_msg          VARCHAR2(2000);
  ln_msg_text        VARCHAR2(2000);
  l_gp_rec           XX_CDH_GP_MAINT_PKG.gp_rec_type;
  l_exists           NUMBER;
  l_requestor        NUMBER;
  no_requestor       EXCEPTION;
  
  CURSOR RES_ROLE_GRP (legacy_rep_id   VARCHAR2)
  IS
  SELECT 
    mem.RESOURCE_ID           ,
    mem.GROUP_ID              ,
    rol.ROLE_ID               
  FROM jtf_rs_group_members mem,
       jtf_rs_role_relations rrl  ,
       jtf_rs_roles_vl rol
  WHERE mem.group_member_id    = rrl.role_resource_id
  AND NVL(rrl.delete_flag, 'N') <> 'Y'
  AND NVL(mem.delete_flag, 'N') <> 'Y'
  AND rrl.role_resource_type     = 'RS_GROUP_MEMBER'
  AND rrl.role_id                = rol.role_id
  AND rrl.attribute15            = legacy_rep_id;
  
  BEGIN
  
      l_gp_rec.gp_id              := p_gp_id;
      l_gp_rec.gp_name            := p_gp_name;
      l_gp_rec.segment            := p_segment;
      l_gp_rec.revenue_band       := p_revenue_band;
      l_gp_rec.w_agreement_flag   := NVL(p_written_agreement,'N');
      l_gp_rec.notes              := p_notes;
      l_gp_rec.status             := NVL(p_active,'I');
      
      IF p_owner IS NOT NULL THEN
      
         l_gp_rec.legacy_rep_id      := p_owner;
         
         FOR rrg IN RES_ROLE_GRP(p_owner) LOOP
             l_gp_rec.resource_id   := rrg.resource_id;
             l_gp_rec.role_id       := rrg.role_id;
             l_gp_rec.group_id      := rrg.group_id;
             EXIT;
         END LOOP;
      END IF;
      
      IF p_requestor IS NOT NULL THEN
             
          BEGIN   
           SELECT person_id
           INTO l_requestor
           FROM per_all_people_f
           WHERE employee_number = p_requestor
           AND TRUNC(SYSDATE) BETWEEN TRUNC(effective_start_date) AND TRUNC(effective_end_date)
           AND ROWNUM = 1;
           
           l_gp_rec.requestor := l_requestor;
         
          EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE no_requestor;
          END;
        
      END IF;
      
   
   IF l_gp_rec.resource_id IS NULL OR l_gp_rec.role_id IS NULL OR l_gp_rec.group_id IS NULL THEN
   
      RETURN 'FALSE_Failed","Owner could not be derived';
   
   END IF;
   
   IF l_gp_rec.segment IS NULL THEN
   
     RETURN 'FALSE_Failed","Value for Segment Cannot be NULL';
     
   ELSE
      
       BEGIN
           SELECT 1 INTO l_exists
           FROM FND_LOOKUP_VALUES
           WHERE LOOKUP_TYPE = 'Customer Segmentation'
           AND lookup_code = l_gp_rec.segment
           AND enabled_flag = 'Y';
                   
       EXCEPTION WHEN OTHERS THEN
           RETURN 'FALSE_Failed","Invalid Value for Segment'; 
       END;
        
   
   END IF;
   
   IF l_gp_rec.revenue_band IS NULL THEN
      
        RETURN 'FALSE_Failed","Value for Revenue Band Cannot be NULL';
   ELSE
       
       BEGIN
               SELECT 1 INTO l_exists
               FROM fnd_flex_value_sets vs,
            	    fnd_flex_values_vl vv
               WHERE vs.flex_value_set_id = vv.flex_value_set_id
               AND vs.flex_value_set_name = 'XXOD_CUST_US_REVENUE_BAND'
               AND vv.enabled_flag = 'Y'
               AND vv.flex_value = l_gp_rec.revenue_band;
            
       EXCEPTION WHEN OTHERS THEN
           RETURN 'FALSE_Failed","Invalid Value for Revenue Band'; 
       END;
          
   END IF;
   
   IF l_gp_rec.gp_name IS NULL THEN
         
           RETURN 'FALSE_Failed","Value for GrandParent Name Cannot be NULL';
         
   END IF;
   
   
      
      
      
    
    BEGIN
    
      SELECT gp_id
      INTO l_gp_id
      FROM xx_cdh_gp_master
      WHERE gp_id = p_gp_id;
      
      -- GrandParent Already Exists, Call Update
      
      XX_CDH_GP_MAINT_PKG.update_gp (
        p_gp_rec            => l_gp_rec,
        x_return_status     => x_ret_status,
        x_msg_count         => l_msg_count,
        x_msg_data          => x_ret_msg
        );
          
    EXCEPTION WHEN NO_DATA_FOUND THEN
    
    -- New GrandParent, Call Create
    
      XX_CDH_GP_MAINT_PKG.create_gp (
        p_gp_rec            => l_gp_rec,
        x_gp_id             => l_gp_id,
        x_party_id          => l_party_id,
        x_return_status     => x_ret_status,
        x_msg_count         => l_msg_count,
        x_msg_data          => x_ret_msg
        );
    
    END;
    
    COMMIT;
    IF x_ret_status = 'S' THEN
      RETURN 'TRUE' || 'Success';
    ELSE
          
            IF l_msg_count > 0 THEN
              ln_msg_text := NULL;
               FOR counter IN 1..l_msg_count
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
               END LOOP;
                RETURN 'FALSE_Failed","error during api call:' || ln_msg_text;
            END IF;
      RETURN 'FALSE_Failed","error during api call:'  || x_ret_msg;
    END IF;
    
  EXCEPTION WHEN no_requestor THEN
  
   RETURN 'FALSE_Failed","Error in save_gp_rel, Requestor Information not found';
  
  WHEN OTHERS THEN
  
  RETURN 'FALSE_Failed","Unexpected Exception in save_gp: ' || SQLERRM;

  END save_gp;

  FUNCTION save_gp_rel (
   p_parent_id          IN NUMBER,
   p_gp_id              IN NUMBER,
   p_start_date         IN DATE,
   p_end_date           IN DATE,
   p_requestor          IN VARCHAR2,
   p_notes              IN VARCHAR2
  ) RETURN VARCHAR2 
  IS
  l_relationship_id        NUMBER;
  l_requestor              NUMBER;
  l_msg_count              NUMBER;
  no_requestor             EXCEPTION;
  x_ret_status             VARCHAR2(10);
  x_ret_msg                VARCHAR2(4000);
  ln_msg_text              VARCHAR2(4000);
  l_parent_id              NUMBER;
  l_gp_id                  NUMBER;
  BEGIN
  
  IF p_parent_id IS NOT NULL THEN
  
   BEGIN
     SELECT PARTY_ID 
     INTO l_parent_id
     FROM hz_cust_accounts
     WHERE orig_system_reference = p_parent_id || '-00001-A0';
   EXCEPTION WHEN OTHERS THEN
     RETURN 'FALSE_Failed","Parent ID could not be derived';
   END;
  END IF;
  
 IF p_gp_id IS NOT NULL THEN
  
   BEGIN
     SELECT PARTY_ID 
     INTO l_gp_id
     FROM xx_cdh_gp_master
     WHERE gp_id = p_gp_id;
   EXCEPTION WHEN OTHERS THEN
     RETURN 'FALSE_Failed","GP ID could not be derived';
   END;
  END IF;
  
  IF p_requestor IS NOT NULL THEN
       
    BEGIN   
     SELECT person_id
     INTO l_requestor
     FROM per_all_people_f
     WHERE employee_number = p_requestor
     AND TRUNC(SYSDATE) BETWEEN TRUNC(effective_start_date) AND TRUNC(effective_end_date)
     AND ROWNUM = 1;
   
    EXCEPTION WHEN NO_DATA_FOUND THEN
      RAISE no_requestor;
    END;
  
  END IF;
  
    BEGIN
    
      SELECT relationship_id
      INTO l_relationship_id
      FROM HZ_RELATIONSHIPS rel,xx_cdh_gp_master gp
      WHERE rel.subject_id = gp.party_id
      AND  rel.relationship_type = 'OD_CUST_HIER'
      AND  rel.relationship_code = 'GRANDPARENT'
      AND  rel.direction_code = 'P'
      AND  gp.gp_id = p_gp_id
      AND  gp.status = 'A'
      AND  rel.status = 'A'
      AND  rel.object_id = l_parent_id
      AND  rel.start_date = p_start_date;
      
       -- Relationship Already Exists, Call Update
       
       XX_CDH_GP_REL_PKG.update_gp_rel (
        p_relationship_id      => l_relationship_id,
        p_parent_id               => NULL,
        p_gp_id                   => NULL,
        p_end_date                => p_end_date,
        p_requestor               => l_requestor,
        p_notes                   => p_notes,
        p_status                  => 'A',
        x_ret_status              => x_ret_status,
        x_m_count                 => l_msg_count,
        x_m_data                  => x_ret_msg
        );
   
   EXCEPTION WHEN NO_DATA_FOUND THEN
   
   -- No Relationship, Call Create
   
      XX_CDH_GP_REL_PKG.create_gp_rel (
        p_parent_id               => l_parent_id,
        p_gp_id                   => l_gp_id,
        p_start_date              => p_start_date,
        p_end_date                => p_end_date,
        p_requestor               => l_requestor,
        p_notes                   => p_notes,
        x_rel_id                  => l_relationship_id,
        x_ret_status              => x_ret_status,
        x_m_count                 => l_msg_count,
        x_m_data                  => x_ret_msg
        );
  
    END;
    
    COMMIT;
    IF x_ret_status = 'S' THEN
      RETURN 'TRUE' || 'Success';
    ELSE
          
            IF l_msg_count > 0 THEN
              ln_msg_text := NULL;
               FOR counter IN 1..l_msg_count
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
               END LOOP;
                RETURN 'FALSE_Failed","error during api call:' || ln_msg_text;
            END IF;
      RETURN 'FALSE_Failed","error during api call:'  || x_ret_msg;
    END IF;
  
  EXCEPTION WHEN no_requestor THEN
  
  RETURN 'FALSE_Failed","Error in save_gp_rel, Requestor Information not found';

  WHEN OTHERS THEN
    RETURN 'FALSE_Failed","Unexpected Exception in save_gp_rel:' || SQLERRM;
  END save_gp_rel;

END XX_CDH_GP_IMPORT_PKG;
/
SHOW ERRORS;
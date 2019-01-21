SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_GP_REL_PKG.pkb                                                        |
-- | Description : GP Relationship                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-Jun-2011     Indra Varada        Initial version                             |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- +============================================================================================+

create or replace
PACKAGE BODY XX_CDH_GP_REL_PKG AS

PROCEDURE insert_gp_hist (
  p_relationship_id       IN NUMBER,
  p_start_date            IN DATE,
  p_end_date              IN DATE ,
  p_requestor             IN NUMBER,
  p_notes                 IN VARCHAR2,
  p_status                IN VARCHAR2,
  p_status_updated        IN VARCHAR2,
  x_ret_status            OUT NOCOPY VARCHAR2,
  x_msg_count             OUT NOCOPY VARCHAR2,
  x_ret_msg               OUT NOCOPY VARCHAR2
 )
 AS
 BEGIN
   x_ret_status := 'S';
   x_ret_msg    := NULL;
   
   INSERT INTO XX_CDH_GP_REL_HIST
      (
      REL_HIST_PK,
      RELATIONSHIP_ID,
      START_DATE,
      END_DATE,
      STATUS,
      REQUESTOR,
      NOTES,
      STATUS_UPDATED,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY
      )
      VALUES
      (
      XXCRM.XX_CDH_GP_REL_HIST_S.NEXTVAL,
      p_relationship_id,
      p_start_date,
      NVL(p_end_date,TO_DATE('12/31/4712','MM/DD/RRRR')),
      p_status,
      DECODE(p_requestor,-1,NULL,p_requestor),
      p_notes,
      p_status_updated,
      apps.HZ_UTILITY_V2PUB.CREATION_DATE,
      apps.HZ_UTILITY_V2PUB.CREATED_BY,
      apps.HZ_UTILITY_V2PUB.LAST_UPDATE_DATE,
      apps.HZ_UTILITY_V2PUB.LAST_UPDATED_BY
      );
 
 EXCEPTION WHEN OTHERS THEN
   x_ret_status  := 'E';
   x_ret_msg     := 'Unhadled Error During Insertion Of Data Into History Table:' || SQLERRM;
 END insert_gp_hist;
 
 PROCEDURE insert_gp (
  p_relationship_id       IN NUMBER,
  p_start_date            IN DATE,
  p_end_date              IN DATE ,
  p_requestor             IN NUMBER,
  p_notes                 IN VARCHAR2,
  p_status                IN VARCHAR2,
  x_ret_status            OUT NOCOPY VARCHAR2,
  x_msg_count             OUT NOCOPY VARCHAR2,
  x_ret_msg               OUT NOCOPY VARCHAR2
 )
 AS
 BEGIN
   x_ret_status := 'S';
   x_ret_msg    := NULL;
   
   INSERT INTO XX_CDH_GP_REL
      (
      REL_PK,
      RELATIONSHIP_ID,
      REQUESTOR,
      NOTES,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY
      )
      VALUES
      (
      XXCRM.XX_CDH_GP_REL_S.NEXTVAL,
      p_relationship_id,
       DECODE(p_requestor,-1,NULL,p_requestor),
      p_notes,
      apps.HZ_UTILITY_V2PUB.CREATION_DATE,
      apps.HZ_UTILITY_V2PUB.CREATED_BY,
      apps.HZ_UTILITY_V2PUB.LAST_UPDATE_DATE,
      apps.HZ_UTILITY_V2PUB.LAST_UPDATED_BY
      );
 
 EXCEPTION WHEN OTHERS THEN
   x_ret_status  := 'E';
   x_ret_msg     := 'Unhadled Error During Insertion Of Data Into Custom GP Rel:' || SQLERRM;
 END insert_gp;

  PROCEDURE create_gp_rel (
    p_init_msg_list               IN      VARCHAR2:= apps.FND_API.G_TRUE,
    p_parent_id                   IN      NUMBER,
    p_gp_id                       IN      NUMBER,
    p_start_date                  IN      DATE,
    p_end_date                    IN      DATE,
    p_requestor                   IN      NUMBER,
    p_notes                       IN      VARCHAR2,
    x_rel_id                      OUT NOCOPY     NUMBER,
    x_ret_status                  OUT NOCOPY     VARCHAR2,
    x_m_count                     OUT NOCOPY     NUMBER,
    x_m_data                      OUT NOCOPY     VARCHAR2
) AS
  l_rel_rec                     apps.HZ_RELATIONSHIP_V2PUB.relationship_rec_type;
  l_p_id                        NUMBER;
  l_p_num                       NUMBER;
  l_requestor                   NUMBER := NULL;
  enddate_not_allowed           EXCEPTION;
  l_start_date                  DATE;
  l_end_date                    DATE;
  
  BEGIN
  
   IF NVL(p_requestor,-1) <> -1 THEN
      l_requestor := p_requestor;
   END IF;
   
   IF NVL(p_end_date,TRUNC(SYSDATE+1)) < TRUNC(SYSDATE) THEN
        RAISE enddate_not_allowed;
   END IF;
   
   IF TRUNC(p_start_date) = TRUNC(SYSDATE) THEN
         l_start_date  := TO_DATE(TO_CHAR(p_start_date,'MM/DD/RRRR') || ' ' || TO_CHAR(SYSDATE,'HH24:MI:SS'),'MM/DD/RRRR HH24:MI:SS');
   ELSE
         l_start_date  := TO_DATE(TO_CHAR(p_start_date,'MM/DD/RRRR') || ' 00:00:01','MM/DD/RRRR HH24:MI:SS');
   END IF;
      
   IF p_end_date IS NOT NULL AND TRUNC(p_end_date) = TRUNC(SYSDATE) THEN
      l_end_date  := TO_DATE(TO_CHAR(p_end_date,'MM/DD/RRRR') || ' ' || TO_CHAR(SYSDATE,'HH24:MI:SS'),'MM/DD/RRRR HH24:MI:SS');
   ELSE
      l_end_date  := p_end_date;
   END IF;
  
    SAVEPOINT  rel_create_save;
    
    x_ret_status := 'S';
  
    l_rel_rec.subject_id          := p_gp_id;
    l_rel_rec.subject_type        := 'ORGANIZATION';
    l_rel_rec.subject_table_name  := 'HZ_PARTIES';
    l_rel_rec.object_id           := p_parent_id;
    l_rel_rec.object_type         := 'ORGANIZATION';
    l_rel_rec.object_table_name   := 'HZ_PARTIES';
    l_rel_rec.relationship_code   := 'GRANDPARENT';
    l_rel_rec.relationship_type   := 'OD_CUST_HIER';
    l_rel_rec.start_date          := l_start_date;
    l_rel_rec.end_date            := l_end_date;
    l_rel_rec.created_by_module   := 'TCA_V2_API';
    
    apps.HZ_RELATIONSHIP_V2PUB.create_relationship (
    p_init_msg_list               => p_init_msg_list,
    p_relationship_rec            => l_rel_rec,
    x_relationship_id             => x_rel_id,
    x_party_id                    => l_p_id,
    x_party_number                => l_p_num,
    x_return_status               => x_ret_status,
    x_msg_count                   => x_m_count,
    x_msg_data                    => x_m_data,
    p_create_org_contact          => NULL
    );
    
    -- Create History Of the Change
    
    IF x_ret_status = 'S' AND x_rel_id IS NOT NULL THEN
    
     insert_gp (
        p_relationship_id   => x_rel_id,
        p_start_date        => l_start_date,
        p_end_date          => l_end_date,
        p_requestor         => l_requestor,
        p_notes             => p_notes,
        p_status            => 'A',
        x_ret_status        => x_ret_status,
        x_msg_count         => x_m_count,
        x_ret_msg           => x_m_data
      );
    
      insert_gp_hist (
        p_relationship_id   => x_rel_id,
        p_start_date        => l_start_date,
        p_end_date          => l_end_date,
        p_requestor         => l_requestor,
        p_notes             => p_notes,
        p_status            => 'A',
        p_status_updated    => 'Y',
        x_ret_status        => x_ret_status,
        x_msg_count         => x_m_count,
        x_ret_msg           => x_m_data
      );
      
    END IF;
    
    IF x_ret_status <> 'S' THEN
       ROLLBACK TO rel_create_save;
    END IF;
    
  EXCEPTION 
  
  WHEN enddate_not_allowed THEN
  
        x_ret_status  := 'E';
        x_m_count     :=  1;
        x_m_data      := 'EndDate Cannot be a Date In the Past';
  
  WHEN OTHERS THEN
     x_ret_status  := 'E';
     x_m_count     := 1;
     x_m_data      := 'Unhandled Exception in Procedure Create GP Relationship:' || SQLERRM;
     ROLLBACK TO rel_create_save;
  END create_gp_rel;

  PROCEDURE update_gp_rel (
    p_init_msg_list               IN      VARCHAR2:= apps.FND_API.G_TRUE,
    p_relationship_id             IN      NUMBER,
    p_parent_id                   IN      NUMBER,
    p_gp_id                       IN      NUMBER,
    p_end_date                    IN      DATE,
    p_requestor                   IN      NUMBER,
    p_notes                       IN      VARCHAR2,
    p_status                      IN      VARCHAR2,
    x_ret_status                  OUT NOCOPY     VARCHAR2,
    x_m_count                     OUT NOCOPY     NUMBER,
    x_m_data                      OUT NOCOPY     VARCHAR2
) AS
 l_rel_rec                     apps.HZ_RELATIONSHIP_V2PUB.relationship_rec_type;
 l_relationship_id             NUMBER;
 l_dt                          DATE;
 l_ovn                         NUMBER;
 l_p_ovn                       NUMBER;
 l_start_date                  DATE;
 l_creation_date               DATE;
 l_status_updated              VARCHAR2(1) := 'N';
 l_record_modified             VARCHAR2(1) := 'N';
 l_requestor                   NUMBER := NULL;
 l_end_date                    DATE;
 l_end_date_hist               DATE;
 no_relationship               EXCEPTION;
 inactive_not_allowed          EXCEPTION;
 enddate_not_allowed           EXCEPTION;
  l_pid NUMBER;
 
 CURSOR rel_cur (p_rel_id    NUMBER)
 IS
 SELECT NVL(end_date,TO_DATE('12/31/4712','MM/DD/RRRR')) end_date,
        NVL(requestor,-1) requestor,
        NVL(notes,'XX') notes,
        NVL(status,'A') status,
        NVL(processed_flag,'N') processed_flag
 FROM XX_CDH_GP_REL gprel, HZ_RELATIONSHIPS rel
 WHERE rel.relationship_id = gprel.relationship_id
 AND rel.direction_code = 'P'
 AND rel.relationship_id = p_rel_id;
 
  BEGIN
  
  
  SAVEPOINT rel_update_save;
  
  l_end_date_hist := trim(p_end_date);
  
  IF (trim(p_end_date) IS NULL) THEN
    l_end_date := TO_DATE('12/31/4712','MM/DD/RRRR');
  ELSE
    IF TRUNC(p_end_date) = TRUNC(SYSDATE) THEN
        l_end_date  := TO_DATE(TO_CHAR(p_end_date,'MM/DD/RRRR') || ' ' || TO_CHAR(SYSDATE,'HH24:MI:SS'),'MM/DD/RRRR HH24:MI:SS');
        l_end_date_hist := l_end_date;
    ELSE
        l_end_date  := trunc(p_end_date);
    END IF;
  END IF;
  
  
   IF NVL(p_requestor,-1) <> -1 THEN
      l_requestor := p_requestor;
   END IF;

  -- Validate End Date
  
  IF l_end_date < TRUNC(SYSDATE) THEN
     RAISE enddate_not_allowed;
  END IF;
  
   x_ret_status  := 'S';
   l_relationship_id     := p_relationship_id;
  
  --  Begins : Derive Relationship ID If Not Passed
  
  IF l_relationship_id IS NULL THEN
  
  
     BEGIN
       SELECT relationship_id, MAX(creation_date)
       INTO l_relationship_id,l_dt
       FROM HZ_RELATIONSHIPS
       WHERE subject_id = p_gp_id
       AND   object_id  = p_parent_id
       AND   relationship_type = 'OD_CUST_HIER'
       AND   relationship_code = 'GRANDPARENT'
       GROUP BY relationship_id;
    
    EXCEPTION WHEN NO_DATA_FOUND THEN
      RAISE no_relationship;
    END;
  END IF;
  
  --  Ends : Derive Relationship ID If Not Passed
  
  BEGIN
     SELECT party_id,OBJECT_VERSION_NUMBER,start_date,TRUNC(creation_date)
     INTO l_pid,l_ovn,l_start_date,l_creation_date
     FROM HZ_RELATIONSHIPS
     WHERE RELATIONSHIP_ID = l_relationship_id
     AND ROWNUM = 1;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE no_relationship;
  END;


BEGIN
SELECT OBJECT_VERSION_NUMBER 
INTO l_p_ovn
FROM HZ_PARTIES 
WHERE PARTY_ID=l_pid
AND ROWNUM=1;
EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE no_relationship;
END;
  
  
   -- Create History of the change
  
  FOR l_hist IN rel_cur (l_relationship_id) LOOP
       -- Validate Inactivation
  
   IF (l_creation_date <> TRUNC(SYSDATE) OR l_hist.processed_flag = 'Y') AND NVL(p_status,'A') = 'I' THEN
       RAISE inactive_not_allowed;
   END IF;
  
         IF  l_hist.end_date <> l_end_date
            OR l_hist.requestor <> NVL(trim(l_requestor),-1) 
            OR l_hist.notes <> NVL(trim(p_notes),'XX') 
            OR l_hist.status <> NVL(trim(p_status),'A') THEN
            

            IF l_hist.end_date <> l_end_date THEN
               l_status_updated  := 'Y';
            END IF;
            
                l_rel_rec.relationship_id   := l_relationship_id;
                l_rel_rec.end_date          := l_end_date;
                l_rel_rec.status            := p_status;

                apps.HZ_RELATIONSHIP_V2PUB.update_relationship (
                    p_init_msg_list                 => p_init_msg_list,
                    p_relationship_rec              => l_rel_rec,
                    p_object_version_number         => l_ovn,
                    p_party_object_version_number   => l_p_ovn,
                    x_return_status                 => x_ret_status,
                    x_msg_count                     => x_m_count,
                    x_msg_data                      => x_m_data
                  );

             IF x_ret_status = 'S' THEN
             
                UPDATE XX_CDH_GP_REL 
                SET requestor= DECODE(l_requestor,-1,NULL,l_requestor),
                    notes=p_notes,
                    last_update_date = SYSDATE,
                    last_updated_by = apps.HZ_UTILITY_V2PUB.LAST_UPDATED_BY
                WHERE relationship_id  = l_relationship_id;
   
   
                 insert_gp_hist (
                  p_relationship_id   => l_relationship_id,
                  p_start_date        => l_start_date,
                  p_end_date          => l_end_date_hist,
                  p_requestor         => l_requestor,
                  p_notes             => trim(p_notes),
                  p_status            => trim(p_status),
                  p_status_updated    => l_status_updated,
                  x_ret_status        => x_ret_status,
                  x_msg_count         => x_m_count,
                  x_ret_msg           => x_m_data
                 );
                 
               END IF;
               
         END IF; 
  
      EXIT;       
  
  END LOOP;
  
  
  IF x_ret_status <> 'S' THEN
     ROLLBACK TO rel_update_save;
  END IF;
    
  EXCEPTION 
  WHEN no_relationship THEN
      x_ret_status  := 'E';
      x_m_count     := 1;
      x_m_data      := 'No Valid GrandParent Relationships Found';
      ROLLBACK TO rel_update_save;
  WHEN inactive_not_allowed THEN
      x_ret_status  := 'E';
      x_m_count     := 1;
      x_m_data      := 'The Relationship Cannot Be Removed';
      ROLLBACK TO rel_update_save;
  WHEN enddate_not_allowed THEN
      x_ret_status  := 'E';
      x_m_count     := 1;
      x_m_data      := 'EndDate Cannot be a Date In the Past';
      ROLLBACK TO rel_update_save;
  WHEN OTHERS THEN
     x_ret_status  := 'E';
     x_m_count     := 1;
     x_m_data      := 'Unhandled Exception in Procedure Create GP Relationship:' || SQLERRM;
     ROLLBACK TO rel_update_save;
  END update_gp_rel;
  
PROCEDURE update_rel_processed (
    x_ret_status            OUT NOCOPY     VARCHAR2,
    x_m_data                OUT NOCOPY     VARCHAR2
 )
AS
BEGIN

x_ret_status := 'S';

UPDATE XX_CDH_GP_REL
SET PROCESSED_FLAG = 'Y'
WHERE PROCESSED_FLAG = 'N' OR PROCESSED_FLAG = NULL;

EXCEPTION WHEN OTHERS THEN
 x_ret_status := 'E';
END update_rel_processed;
  
END XX_CDH_GP_REL_PKG;
/
SHOW ERRORS;
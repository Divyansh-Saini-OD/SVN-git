SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_JTF_RS_NAMED_ACC_TERR_PUB
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_JTF_RS_NAMED_ACC_TERR_PUB                                     |
-- |                                                                                |
-- | Version Info:                                                                  |
-- |                                                                                |
-- |        Id: $Id$
-- |       Rev: $Rev$
-- |   HeadUrl: $HeadURL$
-- |    Author: $Author$
-- |      Date: $Date$
-- |                                                                                |
-- |                                                                                |
-- | Description:  This is a public package to facilitate inserts into the custom   |
-- |               tables XX_TM_NAM_TERR_DEFN, XX_TM_NAM_TERR_RSC_DTLS and          |
-- |               XX_TM_NAM_TERR_ENTITY_DTLS.                                      |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author         Remarks                                    |
-- |=======   =========== =============  ===========================================|
-- |DRAFT 1a  23-OCT-2007 Nabarun Ghosh  Initial draft version                      |
-- |1.0       17-MAR-2008 Nabarun Ghosh  Made the changes to accomodate             |
-- |                                     multiple resource for an Entity.           |
-- |                                                                                |
-- |1.1       23-Apr-2009 Phil Price     Parameter changes to Create_Territory:     |
-- |                                       Added: p_allow_inactive_resource         |
-- |                                       Added: p_set_extracted_status            |
-- |                                       Obsolete: p_source_system                |
-- |                                     Restructured Create_Territory.             |
-- |1.2       12-Jun-2009 Mohan K        Changed the code for defect# 12277 Customer|
-- |                                     assignment upload not loading data for     |
-- |                                     some customer assignments                  |
-- |1.3       23-Sep-2009 Kishore Jena   Parameter changes to Create_Territory:     |
-- |                                       Added: p_terr_asgnmnt_source to capture  |
-- |                                       territory assignment source in           |
-- |                                       xx_tm_nam_terr_entity_dtls.attribute19   |
-- |                                       column.                                  |
-- |1.4       Sep 15,2010 Mohan K        Defect 7027 fix                            |
-- |1.5       20-Jun-2016 Shubashree R   QC38032 Removed schema references for R12.2 GSCC compliance|
-- +================================================================================+

----------------------------
--Declaring Global Constants
----------------------------
--PRAGMA SERIALLY_REUSABLE;

G_LAST_UPDATE_DATE          DATE            := SYSDATE;
G_LAST_UPDATED_BY           PLS_INTEGER     := FND_GLOBAL.USER_ID;
G_CREATION_DATE             DATE            := SYSDATE;
G_CREATED_BY                PLS_INTEGER     := FND_GLOBAL.USER_ID;
G_LAST_UPDATE_LOGIN         PLS_INTEGER     := FND_GLOBAL.LOGIN_ID;
G_PROG_APPL_ID              PLS_INTEGER     := FND_GLOBAL.PROG_APPL_ID;
G_REQUEST_ID                PLS_INTEGER     := FND_GLOBAL.CONC_REQUEST_ID;

G_ENTITY_PARTY              VARCHAR2 (16)   := 'PARTY';
G_ENTITY_PARTY_SITE         VARCHAR2 (16)   := 'PARTY_SITE';
G_ENTITY_LEAD               VARCHAR2 (16)   := 'LEAD';
G_ENTITY_OPPT               VARCHAR2 (16)   := 'OPPORTUNITY';
G_PARTY_TYPE_ORG            VARCHAR2 (16)   := 'ORGANIZATION';

G_SENT_TO_AOPS              VARCHAR2 (20)   := 'Extracted';

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'E1309-B_Autonamed_Account_Creation'
     ,p_program_name            => 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;

-- +================================================================================+
-- | Name        :  Append_Str                                                      |
-- | Description :  Appends the contents of p_str2 to p_str1 up to a a max          |
-- |                of p_max_len characters.  Add a line separater if p_str1        |
-- |                already had a value.                                            |
-- +================================================================================+
PROCEDURE Append_Str (p_str1    IN OUT NOCOPY VARCHAR2,
                      P_str2    IN            VARCHAR2,
                      p_max_len IN            NUMBER) IS
begin
  if (p_str1 is null) then
    p_str1 := substr(p_str2, 1, p_max_len);

  else
    p_str1 := substr(p_str1 || FND_GLOBAL.NewLine || p_str2, 1, p_max_len);
  end if;
end Append_Str;

-- +================================================================================+
-- | Name        :  Validate_Terr_Resource                                          |
-- | Description :  This procedure is used to validate input parameters to populate |
-- |                XX_TM_NAM_TERR_RSC_DTLS                                         |
-- +================================================================================+
PROCEDURE Validate_terr_resource
                               (
                           p_resource_id             IN         XX_TM_NAM_TERR_RSC_DTLS.resource_id%TYPE
                          ,p_resource_role_id        IN         XX_TM_NAM_TERR_RSC_DTLS.resource_role_id%TYPE
                          ,p_group_id                IN         XX_TM_NAM_TERR_RSC_DTLS.group_id%TYPE
                          ,p_allow_inactive_resource IN         VARCHAR2
                          ,x_eligible_flag           OUT NOCOPY VARCHAR2
                          ,x_error_code              OUT NOCOPY VARCHAR2
                          ,x_error_message           OUT NOCOPY VARCHAR2
                          )
AS

  ln_count                      PLS_INTEGER       := 0;
  lc_message                    VARCHAR2(240)    ;

  EX_INVALID_RESOURCE_ID        EXCEPTION        ;
  EX_INVALID_ROLE_ID            EXCEPTION        ;
  EX_INVALID_ROLE_RES_COMBO     EXCEPTION        ;
  EX_INVALID_GROUP_ID           EXCEPTION        ;
  EX_INVALID_RL_RES_GRP_COMBO   EXCEPTION        ;


BEGIN
    x_eligible_flag := null;
    x_error_code    := null;
    x_error_message := null;
    
    ------------------------------------------------------------------
    -- Checking if the Resource ID is valid
    ------------------------------------------------------------------
    ln_count    := 0;

    SELECT COUNT (1)
    INTO   ln_count
    FROM   jtf_rs_resource_extns
    WHERE  resource_id = p_resource_id
    AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
                          AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1);

    IF (ln_count = 0) THEN

      IF p_allow_inactive_resource = 'Y' THEN
        SELECT COUNT (1)
        INTO   ln_count
        FROM   jtf_rs_resource_extns
        WHERE  resource_id = p_resource_id;
      END IF;
    END IF;

    IF (ln_count = 0) THEN
        RAISE EX_INVALID_RESOURCE_ID;
    END IF;

    ------------------------------------------------------------------
    -- Checking if the Role ID is valid
    ------------------------------------------------------------------
    SELECT COUNT (1)
    INTO   ln_count
    FROM   jtf_rs_roles_b
    WHERE  role_id     = p_resource_role_id
    AND    active_flag = 'Y';

    IF      (
                ln_count                    = 0
            )
    THEN
        RAISE EX_INVALID_ROLE_ID;
    END IF;
    ------------------------------------------------------------------
    -- Checking if the Role ID-Resource ID combination is valid
    ------------------------------------------------------------------
    SELECT COUNT (1)
    INTO   ln_count
    FROM   jtf_rs_role_relations
    WHERE  role_resource_id   = p_resource_id
    AND    role_id            = p_resource_role_id
    AND    role_resource_type = 'RS_INDIVIDUAL'
    AND    delete_flag        = 'N'
    AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
                          AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1);

    if (ln_count = 0) then
      if p_allow_inactive_resource = 'Y' then
        SELECT COUNT (1)
        INTO   ln_count
        FROM   jtf_rs_role_relations
        WHERE  role_resource_id   = p_resource_id
        AND    role_id            = p_resource_role_id
        AND    role_resource_type = 'RS_INDIVIDUAL'
        AND    delete_flag        = 'N'
        AND    end_date_active    < TRUNC(SYSDATE);
      end if;
    end if;

    IF      (
                ln_count                    = 0
            )
    THEN
        RAISE EX_INVALID_ROLE_RES_COMBO;
    END IF;
    ------------------------------------------------------------------
    -- Checking if the Group ID is valid
    ------------------------------------------------------------------
    SELECT COUNT (1)
    INTO   ln_count
    FROM   jtf_rs_groups_b
    WHERE  group_id = p_group_id
    AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
                          AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1);

    if (ln_count = 0) then
      if p_allow_inactive_resource = 'Y' then
        SELECT COUNT (1)
        INTO   ln_count
        FROM   jtf_rs_groups_b
        WHERE  group_id = p_group_id
        AND    end_date_active    < TRUNC(SYSDATE);
      end if;
    end if;

    IF      (
              ln_count                    = 0
            )
    THEN
        RAISE EX_INVALID_GROUP_ID;
    END IF;
    --------------------------------------------------------------------
    -- Checking if the Role ID-Resource ID-Group ID combination is valid
    --------------------------------------------------------------------
    SELECT COUNT (1)
    INTO   ln_count
    FROM   jtf_rs_role_relations   JTRR,
           jtf_rs_group_members_vl JTGM
    WHERE JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
    AND   JTRR.role_resource_id    = JTGM.group_member_id
    AND   nvl(JTGM.delete_flag,'N')='N'
    AND   nvl(JTRR.delete_flag,'N')='N'
    AND   JTGM.group_id            = p_group_id
    AND   TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
                         AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
    AND   JTRR.role_id             = p_resource_role_id
    AND   JTGM.resource_id         = p_resource_id;

    if (ln_count = 0) then
      if p_allow_inactive_resource = 'Y' then
        SELECT COUNT (1)
        INTO   ln_count
        FROM   jtf_rs_role_relations   JTRR,
               jtf_rs_group_members_vl JTGM
        WHERE JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
        AND   JTRR.role_resource_id    = JTGM.group_member_id
        AND   nvl(JTGM.delete_flag,'N')='N'
        AND   nvl(JTRR.delete_flag,'N')='N'
        AND   JTGM.group_id            = p_group_id
        AND   JTRR.end_date_active     < trunc(sysdate)
        AND   JTRR.role_id             = p_resource_role_id
        AND   JTGM.resource_id         = p_resource_id;
      end if;
    end if;

    IF      (
                ln_count                    = 0
            )
    THEN
        RAISE EX_INVALID_RL_RES_GRP_COMBO;
    END IF;

    x_eligible_flag  := 'Y';

EXCEPTION
WHEN EX_INVALID_RESOURCE_ID THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0108_INVALID_RES_ID');
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0108_INVALID_RES_ID'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_ROLE_ID THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0109_INVALID_ROLE_ID');
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;
    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0109_INVALID_ROLE_ID'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_ROLE_RES_COMBO THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0110_INVALID_RL_RES_ID');
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0110_INVALID_RL_RES_ID'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_GROUP_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0111_INVALID_GROUP_ID');
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0111_INVALID_GROUP_ID'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_RL_RES_GRP_COMBO THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0112_INVALID_RL_RES_GRP');
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0112_INVALID_RL_RES_GRP'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Validate_terr_resource');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message := FND_MESSAGE.GET;

    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;

END Validate_terr_resource;

-- +================================================================================+
-- | Name        :  Validate_Territory_Entity                                       |
-- | Description :  This procedure is used to validate input parameters to populate |
-- |                XX_TM_NAM_TERR_ENTITY_DTLS                                      |
-- +================================================================================+
PROCEDURE Validate_Territory_Entity
                               (
                                 p_entity_type        IN         XX_TM_NAM_TERR_ENTITY_DTLS.entity_type%TYPE
                                ,p_entity_id          IN         XX_TM_NAM_TERR_ENTITY_DTLS.entity_id%TYPE
                                ,x_eligible_flag      OUT NOCOPY VARCHAR2
                                ,x_error_code         OUT NOCOPY VARCHAR2
                                ,x_error_message      OUT NOCOPY VARCHAR2
                                )
AS

  ln_count                      PLS_INTEGER       := 0;
  lc_message                    VARCHAR2(240)    ;

  EX_INVALID_ENTITY_TYPE        EXCEPTION        ;
  EX_INVALID_PARTY_ID           EXCEPTION        ;
  EX_INVALID_PARTY_SITE_ID      EXCEPTION        ;
  EX_INVALID_LEAD_ID            EXCEPTION        ;
  EX_INVALID_OPPT_ID            EXCEPTION        ;

BEGIN

    ------------------------------------------------------------------
    -- Checking if the Entity Type is valid
    ------------------------------------------------------------------
    IF p_entity_type is null or
       p_entity_type NOT IN
            (G_ENTITY_PARTY,
             G_ENTITY_PARTY_SITE,
             G_ENTITY_LEAD,
             G_ENTITY_OPPT
            )
    THEN
        RAISE EX_INVALID_ENTITY_TYPE;
    END IF;

    ---------------------------------------------------------------------
    -- Checking if the Entity ID is a valid party ID if ENTITY_TYPE=PARTY
    ---------------------------------------------------------------------
    IF p_entity_type = G_ENTITY_PARTY
    THEN
        SELECT COUNT (1)
          INTO ln_count
          FROM hz_parties
         WHERE party_type = G_PARTY_TYPE_ORG
           AND party_id = p_entity_id;

            IF      (
                        ln_count            = 0
                    )
            THEN
                RAISE EX_INVALID_PARTY_ID;
            END IF;
    -------------------------------------------------------------------------------
    -- Checking if the Entity ID is a valid party site ID if ENTITY_TYPE=PARTY_SITE
    -------------------------------------------------------------------------------
    ELSIF p_entity_type = G_ENTITY_PARTY_SITE
    THEN

        SELECT  COUNT(1)
        INTO    ln_count
        FROM    DUAL
        WHERE   EXISTS
                      (
                       SELECT 1
                       FROM   hz_party_sites SITE
                       WHERE  SITE.party_site_id = p_entity_id
                       AND    EXISTS (
                                      SELECT 1
                                      FROM hz_parties PARTY
                                      WHERE PARTY.party_type = G_PARTY_TYPE_ORG
                                      AND   PARTY.party_id   = SITE.party_id
                                    )
                      ) ;

            IF      (
                        ln_count            = 0
                    )
            THEN
                RAISE EX_INVALID_PARTY_SITE_ID;
            END IF;
    -------------------------------------------------------------------------------
    -- Checking if the Entity ID is a valid Lead ID if ENTITY_TYPE=LEAD
    -------------------------------------------------------------------------------
    ELSIF p_entity_type = G_ENTITY_LEAD
    THEN
        SELECT COUNT (1)
          INTO ln_count
          FROM as_sales_leads
         WHERE sales_lead_id = p_entity_id;

            IF      (
                        ln_count            = 0
                    )
            THEN
                RAISE EX_INVALID_LEAD_ID;
            END IF;
    ---------------------------------------------------------------------------------
    -- Checking if the Entity ID is a valid opportunity ID if ENTITY_TYPE=OPPORTUNITY
    ---------------------------------------------------------------------------------
    ELSIF p_entity_type = G_ENTITY_OPPT
    THEN
        SELECT COUNT (1)
          INTO ln_count
          FROM as_leads_all
         WHERE lead_id = p_entity_id;

            IF      (
                        ln_count            = 0
                    )
            THEN
                RAISE EX_INVALID_OPPT_ID;
            END IF;
    END IF;

    x_eligible_flag  := 'Y';

EXCEPTION
WHEN EX_INVALID_OPPT_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0113_INVALID_OPPT_ID');
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0113_INVALID_OPPT_ID'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_LEAD_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0114_INVALID_LEAD_ID');
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0114_INVALID_LEAD_ID'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN EX_INVALID_PARTY_SITE_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0115_INVALID_PARTY_SITE');
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0115_INVALID_PARTY_SITE'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN EX_INVALID_PARTY_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0116_INVALID_PARTY_ID');
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0116_INVALID_PARTY_ID'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN EX_INVALID_ENTITY_TYPE THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0117_INVALID_ENT_TYPE');
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0117_INVALID_ENT_TYPE'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Validate_Territory_Entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Validate_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
END Validate_Territory_Entity;

-- +================================================================================+
-- | Name        :  Insert_territory                                                |
-- | Description :  This procedure is used to insert a territory into               |
-- |                the custom table XX_TM_NAM_TERR_DEFN.                           |
-- +================================================================================+
PROCEDURE Insert_territory
            (
             p_named_acct_terr_id        IN         xx_tm_nam_terr_defn.named_acct_terr_id%TYPE,
             p_named_acct_terr_name      IN         xx_tm_nam_terr_defn.named_acct_terr_name%TYPE,
             p_named_acct_terr_desc      IN         xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE,
             p_status                    IN         xx_tm_nam_terr_defn.status%TYPE,
             p_start_date_active         IN         xx_tm_nam_terr_defn.start_date_active%TYPE    ,
             p_end_date_active           IN         xx_tm_nam_terr_defn.end_date_active%TYPE    ,
             p_source_territory_id       IN         xx_tm_nam_terr_defn.source_territory_id%TYPE,
             x_insert_success            OUT NOCOPY VARCHAR2,
             x_error_code                OUT NOCOPY VARCHAR2,
             x_error_message             OUT NOCOPY VARCHAR2
            )
AS

  lc_message                              VARCHAR2(240);

BEGIN
    x_insert_success := null;
    x_error_code     := null;
    x_error_message  := null;

       --------------------------------------------
       -- Insert Statement for XX_TM_NAM_TERR_DEFN
       --------------------------------------------
       INSERT INTO XX_TM_NAM_TERR_DEFN
            (
                named_acct_terr_id,
                named_acct_terr_name,
                named_acct_terr_desc,
                status,
                start_date_active,
                end_date_active,
                source_territory_id,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id
            )
       VALUES
            (
                p_named_acct_terr_id,
                p_named_acct_terr_name,
                p_named_acct_terr_desc,
                p_status,
                p_start_date_active,
                p_end_date_active,
                p_source_territory_id,
                G_CREATED_BY,
                SYSDATE,
                G_LAST_UPDATED_BY,
                SYSDATE,
                G_LAST_UPDATE_LOGIN,
                G_REQUEST_ID,
                G_PROG_APPL_ID
            );

      x_insert_success := 'Y';
      x_error_code     := 'S';

EXCEPTION
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Insert_territory');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message := FND_MESSAGE.GET;

    Log_Exception ( p_error_location     =>  'Insert_territory'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    x_insert_success := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;
END Insert_territory;

-- +================================================================================+
-- | Name        :  Insert_terr_resource                                            |
-- | Description :  This procedure is used to insert a resource for a territory into|
-- |                the custom table XX_TM_NAM_TERR_RSC_DTLS.                       |
-- +================================================================================+
PROCEDURE Insert_terr_resource
            (
               p_named_acct_terr_rsc_id    IN         xx_tm_nam_terr_rsc_dtls.named_acct_terr_rsc_id%TYPE  ,
               p_named_acct_terr_id        IN         xx_tm_nam_terr_rsc_dtls.named_acct_terr_id%TYPE  ,
               p_resource_id               IN         xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  ,
               p_resource_role_id          IN         xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  ,
               p_group_id                  IN         xx_tm_nam_terr_rsc_dtls.group_id%TYPE  ,
               p_status                    IN         xx_tm_nam_terr_rsc_dtls.status%TYPE,
               p_start_date_active         IN         xx_tm_nam_terr_rsc_dtls.start_date_active%TYPE    ,
               p_end_date_active           IN         xx_tm_nam_terr_rsc_dtls.end_date_active%TYPE    ,
               p_set_extracted_status      IN         VARCHAR2,
               x_insert_success            OUT NOCOPY VARCHAR2,
               x_error_code                OUT NOCOPY VARCHAR2,
               x_error_message             OUT NOCOPY VARCHAR2
            )
AS

  lc_message                                VARCHAR2(240);
  lc_extracted varchar2(20);
BEGIN
  x_insert_success := null;
  x_error_code     := null;
  x_error_message  := null;

  if (p_set_extracted_status = 'Y') then
    lc_extracted := G_SENT_TO_AOPS;
  else
    lc_extracted := null;
  end if;

      ------------------------------------------------
      -- Insert Statement for XX_TM_NAM_TERR_RSC_DTLS
      ------------------------------------------------
       INSERT INTO XX_TM_NAM_TERR_RSC_DTLS
            (
                named_acct_terr_rsc_id,
                named_acct_terr_id,
                resource_id,
                resource_role_id,
                group_id,
                status,
                start_date_active,
                end_date_active,
                attribute20,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id
            )
       VALUES
            (
                p_named_acct_terr_rsc_id,
                p_named_acct_terr_id,
                p_resource_id,
                p_resource_role_id,
                p_group_id,
                p_status,
                p_start_date_active,
                p_end_date_active,
                lc_extracted,
                G_CREATED_BY,
                SYSDATE,
                G_LAST_UPDATED_BY,
                SYSDATE,
                G_LAST_UPDATE_LOGIN,
                G_REQUEST_ID,
                G_PROG_APPL_ID
            );

    x_insert_success := 'Y';
    x_error_code     := 'S';

EXCEPTION
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Insert_terr_resource');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message       := FND_MESSAGE.GET;

    Log_Exception ( p_error_location     =>  'Insert_terr_resource'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    x_insert_success := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;
END Insert_terr_resource;

-- +================================================================================+
-- | Name        :  Insert_terr_entity                                              |
-- | Description :  This procedure is used to insert an entity for a territory into |
-- |                the custom table XX_TM_NAM_TERR_ENTITY_DTLS.                    |
-- +================================================================================+
PROCEDURE Insert_terr_entity
            (
               p_named_acct_terr_entity_id  IN  xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE  ,
               p_named_acct_terr_id         IN  xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE         ,
               p_entity_type                IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE                ,
               p_entity_id                  IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE                  ,
               p_status                     IN  xx_tm_nam_terr_entity_dtls.status%TYPE                     ,
               p_start_date_active          IN  xx_tm_nam_terr_entity_dtls.start_date_active%TYPE          ,
               p_end_date_active            IN  xx_tm_nam_terr_entity_dtls.end_date_active%TYPE            ,
               p_full_access_flag           IN  xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE           ,
               p_source_entity_id           IN  xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE           ,
               p_set_extracted_status       IN  VARCHAR2,
               p_terr_asgnmnt_source        IN  VARCHAR2,  
               x_insert_success             OUT NOCOPY VARCHAR2,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
            )
AS

  lc_message                                  VARCHAR2(240);
  lc_extracted varchar2(20);

BEGIN
  x_insert_success := null;
  x_error_code     := null;
  x_error_message  := null;

  if (p_set_extracted_status = 'Y') then
    lc_extracted := G_SENT_TO_AOPS;
  else
    lc_extracted := null;
  end if;


       -------------------------------------------------------------------------------
       -- Insert Statement for XX_TM_NAM_TERR_ENTITY_DTLS
       -------------------------------------------------------------------------------
       INSERT INTO XX_TM_NAM_TERR_ENTITY_DTLS
            (
                named_acct_terr_entity_id,
                named_acct_terr_id,
                entity_type,
                entity_id,
                status,
                start_date_active,
                end_date_active,
                full_access_flag,
                source_entity_id,
                attribute19,
                attribute20,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id
            )
       VALUES
            (
               p_named_acct_terr_entity_id,
               p_named_acct_terr_id,
               p_entity_type,
               p_entity_id,
               p_status,
               p_start_date_active,
               p_end_date_active,
               p_full_access_flag,
               p_source_entity_id,
               p_terr_asgnmnt_source,
               lc_extracted,
               G_CREATED_BY,
               SYSDATE,
               G_LAST_UPDATED_BY,
               SYSDATE,
               G_LAST_UPDATE_LOGIN,
               G_REQUEST_ID,
               G_PROG_APPL_ID
            );

  x_insert_success := 'Y';
  x_error_code     := 'S';

EXCEPTION
WHEN OTHERS THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Insert_terr_entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Insert_terr_entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    x_insert_success := 'N';
    x_error_code     := 'E';
    x_error_message  := lc_message;
END Insert_terr_entity;

-- +================================================================================+
-- | Name        :  Update_Named_Territory                                          |
-- | Description :  This procedure is used to update an entity for a territory into |
-- |                the custom table XX_TM_NAM_TERR_RSC_DTLS.                       |
-- +================================================================================+
PROCEDURE Update_Named_Territory
            (
               p_named_acct_terr_id         IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE  ,
               p_from_start_date_active     IN  xx_tm_nam_terr_rsc_dtls.start_date_active%TYPE         ,
               x_update_success             OUT NOCOPY VARCHAR2,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
            )
AS

  lc_message                                  VARCHAR2(240);

BEGIN

       -------------------------------------------------------------------------------
       -- Update Statement for XX_TM_NAM_TERR_RSC_DTLS
       -------------------------------------------------------------------------------

       UPDATE xx_tm_nam_terr_defn
       SET    end_date_active         = p_from_start_date_active
             ,last_updated_by         = G_LAST_UPDATED_BY
             ,last_update_date        = SYSDATE
             ,last_update_login       = G_LAST_UPDATE_LOGIN
             ,request_id              = G_REQUEST_ID
             ,program_application_id  = G_PROG_APPL_ID
       WHERE  named_acct_terr_id = p_named_acct_terr_id;

   --COMMIT;
   x_update_success   := 'Y';  -- Calling procedure will check this flag and COMMIT statement.

EXCEPTION
WHEN OTHERS THEN
    x_update_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Update_Named_Territory');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Update_Named_Territory'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Update_Named_Territory;

-- +================================================================================+
-- | Name        :  Update_Terr_Resource                                            |
-- | Description :  This procedure is used to update an entity for a territory into |
-- |                the custom table XX_TM_NAM_TERR_RSC_DTLS.                       |
-- +================================================================================+
PROCEDURE Update_Terr_Resource
              (
               p_named_acct_terr_id         IN  xx_tm_nam_terr_rsc_dtls.named_acct_terr_id%TYPE  ,
               p_end_date_active            IN  xx_tm_nam_terr_rsc_dtls.end_date_active%TYPE     ,
               p_status                     IN  xx_tm_nam_terr_rsc_dtls.status%TYPE              ,
               p_from_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE         ,
               p_from_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE    ,
               p_from_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE            ,
               x_update_success             OUT NOCOPY VARCHAR2,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
              )
AS

  lc_message                                VARCHAR2(240);

BEGIN

       -------------------------------------------------------------------------------
       -- Update Statement for XX_TM_NAM_TERR_RSC_DTLS
       -------------------------------------------------------------------------------

       UPDATE xx_tm_nam_terr_rsc_dtls
       SET    end_date_active         = p_end_date_active
             ,status                  = NVL(p_status,status)
             ,last_updated_by         = G_LAST_UPDATED_BY
             ,last_update_date        = SYSDATE
             ,last_update_login       = G_LAST_UPDATE_LOGIN
             ,request_id              = G_REQUEST_ID
             ,program_application_id  = G_PROG_APPL_ID
       WHERE  named_acct_terr_id = p_named_acct_terr_id
       AND    resource_id        = p_from_resource_id
       AND    resource_role_id   = p_from_role_id
       AND    group_id           = p_from_group_id;

   --COMMIT;
   x_update_success   := 'Y';  -- Calling procedure will check this flag and COMMIT statement.

EXCEPTION
WHEN OTHERS THEN
    x_update_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Update_Terr_Resource');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Update_Terr_Resource'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Update_Terr_Resource;

-- +================================================================================+
-- | Name        :  Update_terr_entity                                              |
-- | Description :  This procedure is used to update an entity for a territory into |
-- |                the custom table XX_TM_NAM_TERR_ENTITY_DTLS.                    |
-- +================================================================================+
PROCEDURE Update_terr_entity
            (
               p_from_named_acct_terr_id    IN  xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE  ,
               p_end_date_active            IN  xx_tm_nam_terr_entity_dtls.end_date_active%TYPE          ,
               p_status                     IN  xx_tm_nam_terr_entity_dtls.status%TYPE                     ,
               p_entity_type                IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE                ,
               p_entity_id                  IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE                  ,
               x_update_success             OUT NOCOPY VARCHAR2,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
            )
AS

  lc_message                                  VARCHAR2(240);

BEGIN

       -------------------------------------------------------------------------------
       -- Update Statement for XX_TM_NAM_TERR_ENTITY_DTLS
       -------------------------------------------------------------------------------

       UPDATE xx_tm_nam_terr_entity_dtls
       SET    end_date_active         = p_end_date_active
             ,status                  = NVL(p_status,status)
             ,last_updated_by         = G_LAST_UPDATED_BY
             ,last_update_date        = SYSDATE
             ,last_update_login       = G_LAST_UPDATE_LOGIN
             ,request_id              = G_REQUEST_ID
             ,program_application_id  = G_PROG_APPL_ID
       WHERE  named_acct_terr_id = p_from_named_acct_terr_id
       AND    entity_type        = p_entity_type
       AND    entity_id          = p_entity_id;

   --COMMIT;
   x_update_success   := 'Y';

EXCEPTION
WHEN OTHERS THEN
    x_update_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Update_terr_entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Update_terr_entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Update_terr_entity;

-- +================================================================================+
-- | Name        :  Update_entity                                                   |
-- | Description :  This procedure is used to end-date an entity where the          |
-- |                corresponding resource role passed as parameter is having the   |
-- |                same role division.                                             |
-- +================================================================================+
PROCEDURE Update_entity
            (
               p_nmd_acct_terr_entity_id    IN  xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE  ,
               p_end_date_active            IN  xx_tm_nam_terr_entity_dtls.end_date_active%TYPE          ,
               p_status                     IN  xx_tm_nam_terr_entity_dtls.status%TYPE                     ,
               p_entity_type                IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE                ,
               p_entity_id                  IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE                  ,
               x_update_success             OUT NOCOPY VARCHAR2,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
            )
AS

  lc_message                                  VARCHAR2(240);

BEGIN

       -------------------------------------------------------------------------------
       -- Update Statement for XX_TM_NAM_TERR_ENTITY_DTLS
       -------------------------------------------------------------------------------

       UPDATE xx_tm_nam_terr_entity_dtls
       SET    end_date_active         = p_end_date_active
             ,status                  = NVL(p_status,status)
             ,last_updated_by         = G_LAST_UPDATED_BY
             ,last_update_date        = SYSDATE
             ,last_update_login       = G_LAST_UPDATE_LOGIN
             ,request_id              = G_REQUEST_ID
             ,program_application_id  = G_PROG_APPL_ID
       WHERE  named_acct_terr_entity_id = p_nmd_acct_terr_entity_id
       AND    entity_type               = p_entity_type
       AND    entity_id                 = p_entity_id;

   --COMMIT;
   x_update_success   := 'Y';

EXCEPTION
WHEN OTHERS THEN
    x_update_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Update_entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Update_entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Update_entity;

-- +================================================================================+
-- | Name        :  Update_Non_Dsm_Terr_Name                                        |
-- | Description :  This procedure is used to update the name of the Territory if   |
-- |                the role is of type Non DSM.                                    |
-- +================================================================================+
PROCEDURE Update_Non_Dsm_Terr_Name
              (
               p_named_acct_terr_id         IN  xx_tm_nam_terr_rsc_dtls.named_acct_terr_id%TYPE  ,
               p_resource_id                IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE         ,
               p_role_id                    IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE    ,
               x_error_code                 OUT NOCOPY VARCHAR2,
               x_error_message              OUT NOCOPY VARCHAR2
              )
AS

  lc_message                    VARCHAR2(240);
  ln_count                      PLS_INTEGER;
  lc_named_acct_terr_name       xx_tm_nam_terr_defn.named_acct_terr_name%TYPE;

  EX_NULL_RESOURCE_NAME         EXCEPTION    ;
  EX_INVALID_RESOURCE_ID        EXCEPTION    ;

BEGIN

  --Validating DSM / Manager Roles
  --SELECT COUNT (1)
  --INTO   ln_count
  --FROM   jtf_rs_roles_b
  --WHERE  role_id     = p_role_id
  --AND    manager_flag = 'Y';

  SELECT COUNT(1)
  INTO   ln_count
  FROM   jtf_rs_role_relations JRR
        ,jtf_rs_roles_b        ROLE
  WHERE  JRR.role_resource_id = p_resource_id
  AND    SYSDATE BETWEEN NVL(JRR.start_date_active,SYSDATE-1)
                     AND NVL(JRR.end_date_active,SYSDATE+1)
  AND    JRR.role_id          = ROLE.role_id
  AND    ROLE.active_flag     = 'Y'
  AND    ROLE.manager_flag    = 'Y';

  IF (ln_count   = 0) THEN

    --Obtaining the name of the New Resource
    BEGIN
       SELECT source_name
       INTO   lc_named_acct_terr_name
       FROM   jtf_rs_resource_extns
       WHERE  resource_id = p_resource_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE EX_NULL_RESOURCE_NAME;
      WHEN OTHERS THEN
        RAISE EX_INVALID_RESOURCE_ID;
    END;

    --Updating the From territory with the name of the new rsource assigned to.
    UPDATE xx_tm_nam_terr_defn
    SET    named_acct_terr_name    = lc_named_acct_terr_name
          ,named_acct_terr_desc    = lc_named_acct_terr_name
          ,last_updated_by         = G_LAST_UPDATED_BY
          ,last_update_date        = SYSDATE
          ,last_update_login       = G_LAST_UPDATE_LOGIN
          ,request_id              = G_REQUEST_ID
          ,program_application_id  = G_PROG_APPL_ID
    WHERE  named_acct_terr_id      = p_named_acct_terr_id;

  END IF;

EXCEPTION
WHEN EX_NULL_RESOURCE_NAME THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0180_NULL_RES_NAME');
    lc_message := FND_MESSAGE.GET;
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Update_Non_Dsm_Terr_Name'
                   ,p_error_message_code =>  'XX_TM_XXX_NULL_RES_NAME'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN EX_INVALID_RESOURCE_ID THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0108_INVALID_RES_ID');
    lc_message := FND_MESSAGE.GET;
    x_error_code     := 'E';
    x_error_message  := lc_message;

    Log_Exception ( p_error_location     =>  'Update_Non_Dsm_Terr_Name'
                   ,p_error_message_code =>  'XX_TM_0108_INVALID_RES_ID'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
WHEN OTHERS THEN

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Update_Non_Dsm_Terr_Name');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_code       := 'E';
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Update_Non_Dsm_Terr_Name'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Update_Non_Dsm_Terr_Name;

-- +=================================================================================+
-- | Name        :  Validate_Roles_Div_Role_Code                                     |
-- | Description :  This procedure is used to validate the Resource having the Role  |
-- |                where the Division and OD Role Code should not match with any    |
-- |                other resources Roles.                                           |
-- +=================================================================================+
PROCEDURE Validate_Roles_Div_Role_Code
                   (
                     p_role_id            IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
                    ,p_group_id           IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
                    ,p_entity_type        IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE
                    ,p_entity_id          IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE
                    ,p_start_date_active  IN  xx_tm_nam_terr_defn.start_date_active%TYPE
                    ,x_eligible_flag      OUT NOCOPY VARCHAR2
                   )
AS

  ln_count                      PLS_INTEGER       := 0;
  lc_message                    VARCHAR2(240)    ;

BEGIN

    --------------------------------------------------------------------------
    -- Obtaining the division of the Role corresponding to the from Territory
    --------------------------------------------------------------------------

    SELECT COUNT(1)
    INTO   ln_count
    FROM   xx_tm_nam_terr_entity_dtls XTNTED
          ,xx_tm_nam_terr_rsc_dtls    XTNTRD
          ,jtf_rs_roles_b             JSRV
    WHERE  XTNTED.entity_id           = p_entity_id
    AND    XTNTED.entity_type         = p_entity_type
    AND    XTNTED.named_acct_terr_id  = XTNTRD.named_acct_terr_id
    AND    XTNTRD.resource_role_id    = JSRV.role_id
    AND    p_start_date_active BETWEEN NVL(XTNTED.start_date_active,SYSDATE-1)
                                       AND     NVL(XTNTED.end_date_active,SYSDATE+1)
    AND    p_start_date_active BETWEEN NVL(XTNTRD.start_date_active,SYSDATE-1)
                                       AND     NVL(XTNTRD.end_date_active,SYSDATE+1)
    AND    NVL(XTNTED.status,'A') = 'A'
    AND    NVL(XTNTRD.status,'A') = 'A'
    AND    EXISTS (
                    SELECT 1
                    FROM   jtf_rs_roles_b     JRLV
                    WHERE JRLV.role_id        = p_role_id
                    AND   JRLV.attribute15    = JSRV.attribute15
                    AND   JRLV.attribute14    = JSRV.attribute14
                  );
    IF ln_count > 0 THEN
      x_eligible_flag  := 'N';
    ELSE
      x_eligible_flag  := 'Y';
    END IF;

EXCEPTION
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Validate_Roles_Div_Role_Code');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message       := FND_MESSAGE.GET;
    x_eligible_flag  := 'N';

    Log_Exception ( p_error_location     =>  'Validate_Roles_Div_Role_Code'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
END Validate_Roles_Div_Role_Code;


-- +================================================================================+
-- | Name        :  Create_Territory                                                |
-- | Description :  This procedure is used to create named account territories if   |
-- |                the parameters passed all the validations.                      |
-- +================================================================================+
PROCEDURE Create_Territory
          (
            p_api_version_number      IN  PLS_INTEGER
           ,p_named_acct_terr_id      IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE      DEFAULT NULL
           ,p_named_acct_terr_name    IN  xx_tm_nam_terr_defn.named_acct_terr_name%TYPE    DEFAULT NULL
           ,p_named_acct_terr_desc    IN  xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE    DEFAULT NULL
           ,p_status                  IN  xx_tm_nam_terr_defn.status%TYPE                  DEFAULT NULL
           ,p_start_date_active       IN  xx_tm_nam_terr_defn.start_date_active%TYPE       DEFAULT SYSDATE
           ,p_end_date_active         IN  xx_tm_nam_terr_defn.end_date_active%TYPE         DEFAULT NULL
           ,p_full_access_flag        IN  xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE DEFAULT 'Y'
           ,p_source_terr_id          IN  xx_tm_nam_terr_defn.source_territory_id%TYPE
           ,p_resource_id             IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_role_id                 IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_group_id                IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_entity_type             IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE
           ,p_entity_id               IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE
           ,p_source_entity_id        IN  xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE
           ,p_source_system           IN  VARCHAR2  DEFAULT NULL     -- OBSOLETE
           ,p_allow_inactive_resource IN  VARCHAR2  DEFAULT 'N'
           ,p_set_extracted_status    IN  VARCHAR2  DEFAULT 'N'
           ,p_terr_asgnmnt_source     IN  VARCHAR2  DEFAULT NULL
           ,p_commit                  IN  BOOLEAN DEFAULT TRUE
           ,x_error_code            OUT NOCOPY VARCHAR2
           ,x_error_message         OUT NOCOPY VARCHAR2
         )
AS
  lc_proc  constant varchar2(80) := 'Create_Territory';

  lc_message                      VARCHAR2(240);
  lc_eligible_flag                VARCHAR2(1);
  lc_insert_success               VARCHAR2(1);
  lc_okay                         VARCHAR2(1);
  lc_allow_inactive_resource      VARCHAR2(1);
  lc_set_extracted_status         VARCHAR2(1);
  ln_count                        PLS_INTEGER := 0;
  ln_resource_exists              PLS_INTEGER := 0;
  ln_named_acct_terr_id           xx_tm_nam_terr_defn.named_acct_terr_id              %TYPE;
  ln_named_terr_rsc_id            xx_tm_nam_terr_rsc_dtls.named_acct_terr_rsc_id      %TYPE;
  ln_named_terr_ent_id            xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE;
  lc_named_acct_terr_name         xx_tm_nam_terr_defn.named_acct_terr_name            %TYPE;
  ln_named_acct_terr_entity_id    xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE;
  lc_named_acct_terr_desc         xx_tm_nam_terr_defn.named_acct_terr_desc            %TYPE;

  lc_status                       xx_tm_nam_terr_defn.status                 %TYPE;
  ld_start_date_active            xx_tm_nam_terr_defn.start_date_active      %TYPE;
  ld_end_date_active              xx_tm_nam_terr_defn.end_date_active        %TYPE;
  lc_full_access_flag             xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE;
  ln_source_terr_id               xx_tm_nam_terr_defn.source_territory_id    %TYPE;
  ln_resource_id                  xx_tm_nam_terr_rsc_dtls.resource_id        %TYPE;
  ln_role_id                      xx_tm_nam_terr_rsc_dtls.resource_role_id   %TYPE;
  ln_group_id                     xx_tm_nam_terr_rsc_dtls.group_id           %TYPE;
  lc_entity_type                  xx_tm_nam_terr_entity_dtls.entity_type     %TYPE;
  ln_entity_id                    xx_tm_nam_terr_entity_dtls.entity_id       %TYPE;
  ln_source_entity_id             xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE;

  ln_api_version_number           CONSTANT PLS_INTEGER  := 1.0;
  lc_api_name                     CONSTANT VARCHAR2(30) := 'Named_Account_Territory_Pub';

  lc_error_code                   VARCHAR2(1);
  lc_error_message                VARCHAR2(4000) := null;
  lc_tmp_error_msg                VARCHAR2(4000);

  EX_INVALID_TERR_RES_DATES       EXCEPTION;
  EX_TERR_RES_NOT_EXISTS          EXCEPTION;
  EX_TERR_ENTITY_EXISTS           EXCEPTION;
  EX_TERR_NOT_EXISTS              EXCEPTION;
  EX_INVALID_API_VERSION          EXCEPTION;
  EX_DUPLICATE_ROLECD_DIV         EXCEPTION;
  EX_INVALID_STATUS               EXCEPTION;
  EX_MULTIPLE_RSC_FOR_ENTITY_ID   EXCEPTION;
  EX_ERROR_FETCHING_NMD_TERR_ID   EXCEPTION;
  EX_MULTIPLE_VALID_TERR_DEFNS    EXCEPTION; -- Mohan 06/12/2009


BEGIN

    -- Standard call to check for call compatibility.
    IF NOT FND_API.COMPATIBLE_API_CALL
               (ln_api_version_number,
                p_api_version_number,
                lc_api_name,
                'XX_JTF_RS_NAMED_ACC_TERR_PUB') THEN
       RAISE EX_INVALID_API_VERSION;
    END IF;

    --Assigning the parameters into local variables
    lc_status            := p_status;
    ld_start_date_active := p_start_date_active;

    IF ld_start_date_active IS NULL THEN
       ld_start_date_active := SYSDATE;
    END IF;

    IF lc_status IS NOT NULL THEN
       IF lc_status NOT IN ('A','I') THEN
          RAISE EX_INVALID_STATUS;
       END IF;
    END IF;

    IF (p_allow_inactive_resource = 'Y') THEN
        lc_allow_inactive_resource := 'Y';
    ELSE
        lc_allow_inactive_resource := 'N';
    END IF;

    IF (p_set_extracted_status = 'Y') THEN
        lc_set_extracted_status := 'Y';
    ELSE
        lc_set_extracted_status := 'N';
    END IF;

    --If the assignment is future dated then current record should be Inactivated
    IF ld_start_date_active > SYSDATE THEN
       lc_status := 'I' ;
    ELSE
       lc_status := 'A' ;
    END IF;

    ld_end_date_active  := p_end_date_active;
    lc_full_access_flag := p_full_access_flag;

    IF lc_full_access_flag IS NULL THEN
      lc_full_access_flag := 'Y';
    END IF;

    ln_source_terr_id   := p_source_terr_id;
    ln_resource_id      := p_resource_id;
    ln_role_id          := p_role_id;
    ln_group_id         := p_group_id;
    lc_entity_type      := p_entity_type;
    ln_entity_id        := p_entity_id;
    ln_source_entity_id := p_source_entity_id;
    lc_okay             := 'Y';

    --
    -- Verify ln_resource_id is valid
    --
    Validate_terr_resource (p_resource_id             => ln_resource_id
                           ,p_resource_role_id        => ln_role_id
                           ,p_group_id                => ln_group_id
                           ,p_allow_inactive_resource => lc_allow_inactive_resource
                           ,x_eligible_flag           => lc_eligible_flag
                           ,x_error_code              => lc_error_code
                           ,x_error_message           => lc_tmp_error_msg);

    IF lc_eligible_flag <> 'Y' THEN
        lc_okay := 'N';
        Append_Str (lc_error_message, lc_tmp_error_msg, 4000);
    END IF;

    --
    -- Verify ln_entity_id and lc_entity_type are valid
    --
    lc_eligible_flag := NULL;

    Validate_Territory_Entity (p_entity_type   => lc_entity_type
                              ,p_entity_id     => ln_entity_id
                              ,x_eligible_flag => lc_eligible_flag
                              ,x_error_code    => lc_error_code
                              ,x_error_message => lc_tmp_error_msg);

    IF lc_eligible_flag <> 'Y' THEN
        lc_okay := 'N';
        Append_Str (lc_error_message, lc_tmp_error_msg, 4000);
    END IF;

    --
    -- Check if End Date is less than Start Date
    --
    IF (ld_end_date_active < ld_start_date_active) THEN
        lc_okay := 'N';
        Append_Str (lc_error_message, 'End Date Active is less than Start Date Active.', 4000);
    END IF;

    --
    -- We are finished checking for parameter errors.
    -- At this point we only want to continue if no errors were found.
    --
    IF lc_okay  = 'Y' THEN

        IF p_named_acct_terr_id IS NOT NULL THEN

            ln_named_acct_terr_id := p_named_acct_terr_id;

            --
            -- p_named_acct_terr_id was passed in.
            -- Verify it refers to an active record in xx_tm_nam_terr_defn.
            --
            SELECT COUNT(1)
              INTO ln_count
              FROM DUAL
             WHERE EXISTS (SELECT 1
                             FROM xx_tm_nam_terr_defn
                            WHERE named_acct_terr_id =  ln_named_acct_terr_id
                              AND NVL(status,'A')    = 'A'
                              AND ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                           AND NVL(end_date_active,(SYSDATE)+1));

            IF ln_count = 0 THEN
                RAISE EX_TERR_NOT_EXISTS ;
            END IF;

            --
            -- Record was found in xx_tm_nam_terr_defn.
            -- This means that a record should also exist in xx_tm_nam_terr_rsc_dtls for the
            -- ln_named_acct_terr_id, resource, role, and group passed in.
            --
            ln_count := 0;
            SELECT COUNT(1)
              INTO ln_count
              FROM DUAL
             WHERE EXISTS (SELECT 1
                             FROM xx_tm_nam_terr_rsc_dtls
                            WHERE named_acct_terr_id = ln_named_acct_terr_id
                              AND resource_id        = ln_resource_id
                              AND resource_role_id   = ln_role_id
                              AND group_id           = ln_group_id
                              AND NVL(status,'A')    = 'A'
                              AND ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                           AND NVL(end_date_active,SYSDATE+1));

            IF ln_count = 0 THEN
                RAISE EX_TERR_RES_NOT_EXISTS;
            END IF;

        ELSE  -- IF p_named_acct_terr_id IS NOT NULL
            --
            -- p_named_acct_terr_id was not passed in.
            -- Check if it exists based on the resouce, group, and role passed in.
            --
           ln_named_acct_terr_id := NULL;
-- Block changed by Mohan 06/12/2009 for selecting only active territory definitions
           BEGIN
               SELECT r.named_acct_terr_id
                 INTO ln_named_acct_terr_id
                 FROM xx_tm_nam_terr_rsc_dtls r, xx_tm_nam_terr_defn t
                WHERE r.resource_id        = ln_resource_id
                  AND r.resource_role_id   = ln_role_id
                  AND r.group_id           = ln_group_id
                  AND NVL(r.status,'A')    = 'A'
                  AND (ld_start_date_active BETWEEN NVL(r.start_date_active,SYSDATE-1)
                                               AND NVL(r.end_date_active,(SYSDATE)+1))
                  AND r.named_acct_terr_id = t.named_acct_terr_id
                  AND t.status = 'A';
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_named_acct_terr_id := NULL;
             WHEN TOO_MANY_ROWS THEN -- Mohan 6/16
                RAISE EX_MULTIPLE_VALID_TERR_DEFNS;  -- Mohan 6/16
           END;
        END IF;
    END IF;  -- if lc_okay

    IF lc_okay = 'Y' THEN

        IF ln_named_acct_terr_id IS NOT NULL THEN
            --
            -- terr_defn and rsc_dtls records found.
            -- Now verify a record doesn't exist yet in xx_tm_nam_terr_entity_dtls.
            --
            ln_count := 0;
            SELECT COUNT(1)
              INTO ln_count
              FROM DUAL
             WHERE EXISTS (SELECT 1
                             FROM xx_tm_nam_terr_entity_dtls
                            WHERE named_acct_terr_id    = ln_named_acct_terr_id
                              AND entity_id             = ln_entity_id
                              AND NVL(status,'A')       = 'A'
                              AND ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                           AND NVL(end_date_active,SYSDATE+1));

            IF ln_count > 0 THEN
                RAISE EX_TERR_ENTITY_EXISTS;
            END IF;

            --
            -- OK to create a new entity record.  Logic is further down.
            --

        ELSE
            --
            -- Either p_named_acct_terr_id or it could not be derived
            -- using resource, role, and group passed in.
            --
            lc_named_acct_terr_name := NULL;

            IF p_named_acct_terr_name IS NOT NULL THEN
                lc_named_acct_terr_name := p_named_acct_terr_name;

            ELSE
                SELECT source_name
                  INTO lc_named_acct_terr_name
                  FROM jtf_rs_resource_extns
                 WHERE resource_id = ln_resource_id;
            END IF;

            --
            -- Set the territory description to the value passed in.  If null, set it to the territory name.
            --
            lc_named_acct_terr_desc := nvl(p_named_acct_terr_desc, lc_named_acct_terr_name);

            --
            -- Create a new territory record.
            --

            SELECT XXCRM.xx_tm_nam_terr_defn_s.NEXTVAL
              INTO ln_named_acct_terr_id
              FROM DUAL;

            Insert_territory
                 (p_named_acct_terr_id   => ln_named_acct_terr_id,
                  p_named_acct_terr_name => lc_named_acct_terr_name,
                  p_named_acct_terr_desc => lc_named_acct_terr_desc,
                  p_status               => lc_status,
                  p_start_date_active    => ld_start_date_active,
                  p_end_date_active      => ld_end_date_active,
                  p_source_territory_id  => ln_source_terr_id,
                  x_insert_success       => lc_insert_success,
                  x_error_code           => lc_error_code,
                  x_error_message        => lc_tmp_error_msg);

            IF lc_insert_success = 'Y' THEN

                --
                -- Create a new resource record.
                --

                SELECT xx_tm_nam_terr_rsc_dtls_s.NEXTVAL
                  INTO ln_named_terr_rsc_id
                  FROM DUAL;

                Insert_terr_resource
                     (p_named_acct_terr_rsc_id => ln_named_terr_rsc_id,
                      p_named_acct_terr_id     => ln_named_acct_terr_id,
                      p_resource_id            => ln_resource_id,
                      p_resource_role_id       => ln_role_id,
                      p_group_id               => ln_group_id,
                      p_status                 => lc_status,
                      p_start_date_active      => ld_start_date_active,
                      p_end_date_active        => ld_end_date_active,
                      p_set_extracted_status   => lc_set_extracted_status,
                      x_insert_success         => lc_insert_success,
                      x_error_code             => lc_error_code,
                      x_error_message          => lc_tmp_error_msg);
            END IF;

            lc_okay := lc_insert_success;

            if (lc_insert_success = 'N') then
                Append_Str (lc_error_message, lc_tmp_error_msg, 4000);
            end if;

        END IF;  -- else IF ln_named_acct_terr_id IS NOT NULL
    END IF;  -- IF lc_okay = 'Y'

    IF lc_okay = 'Y' THEN
        --
        -- Create a new entity record.
        --

        SELECT xx_tm_nam_terr_entity_dtls_s.NEXTVAL
          INTO ln_named_terr_ent_id
          FROM DUAL;

        Insert_terr_entity
             (p_named_acct_terr_entity_id => ln_named_terr_ent_id,
              p_named_acct_terr_id        => ln_named_acct_terr_id,
              p_entity_type               => lc_entity_type,
              p_entity_id                 => ln_entity_id,
              p_status                    => lc_status,
              p_start_date_active         => ld_start_date_active,
              p_end_date_active           => ld_end_date_active  ,
              p_full_access_flag          => lc_full_access_flag,
              p_source_entity_id          => ln_source_entity_id,
              p_set_extracted_status      => lc_set_extracted_status,
              p_terr_asgnmnt_source       => p_terr_asgnmnt_source,
              x_insert_success            => lc_insert_success,
              x_error_code                => lc_error_code,
              x_error_message             => lc_tmp_error_msg);

        lc_okay := lc_insert_success;

        if (lc_insert_success = 'N') then
            Append_Str (lc_error_message, lc_tmp_error_msg, 4000);
        end if;
    END IF;

    IF lc_okay = 'Y' THEN
        x_error_code      := 'S';
        x_error_message   := 'Record Created successfully';

        IF p_commit THEN
            COMMIT;
        END IF;

    ELSE
        x_error_code    := 'E';  -- no procedures return "U" so it's safe to hard code "E"
        x_error_message := lc_error_message;
    END IF;


EXCEPTION
WHEN EX_INVALID_API_VERSION THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0103_INVALID_API_VER');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0103_INVALID_API_VER'
                   ,p_error_msg          =>  lc_message);

WHEN EX_INVALID_STATUS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0183_INVALID_STATUS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0183_INVALID_STATUS'
                   ,p_error_msg          =>  lc_message);

WHEN EX_INVALID_TERR_RES_DATES THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0104_TERR_RES_DATES');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0104_TERR_RES_DATES'
                   ,p_error_msg          =>  lc_message);

WHEN EX_TERR_RES_NOT_EXISTS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0105_TERR_RES_NOTEXISTS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0105_TERR_RES_NOTEXISTS'
                   ,p_error_msg          =>  lc_message);

WHEN EX_DUPLICATE_ROLECD_DIV THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0182_DUPLICATE_RLCD_DIV');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0182_DUPLICATE_RLCD_DIV'
                   ,p_error_msg          =>  lc_message);

WHEN EX_TERR_ENTITY_EXISTS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0106_TERR_ENTITY_EXISTS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0106_TERR_ENTITY_EXISTS'
                   ,p_error_msg          =>  lc_message);

WHEN EX_TERR_NOT_EXISTS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0107_INVALID_TERR');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0107_INVALID_TERR'
                   ,p_error_msg          =>  lc_message);

WHEN EX_MULTIPLE_RSC_FOR_ENTITY_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0197_MULTIPLE_RSC');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0197_MULTIPLE_RSC'
                   ,p_error_msg          =>  lc_message);

WHEN EX_ERROR_FETCHING_NMD_TERR_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0198_ERR_IN_FETCH_RSC');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0198_ERR_IN_FETCH_RSC'
                   ,p_error_msg          =>  lc_message);
-- Mohan 06/12/2009 Introduced the following When EX_MULTIPLE_VALID_TERR_DEFNS block
WHEN EX_MULTIPLE_VALID_TERR_DEFNS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0198_MULTIPLE_TERR_DEFNS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0198_MULTIPLE_TERR_DEFNS'
                   ,p_error_msg          =>  lc_message);
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message);
END Create_Territory;


-- +================================================================================+
-- | Name        :  Create_Bulk_Territory                                           |
-- | Description :  This procedure is used to create named account territories in   |
-- |                bulk.                                                           |
-- +================================================================================+
PROCEDURE Create_Bulk_Territory
          (
            p_api_version_number          IN  PLS_INTEGER
           ,p_tm_terr_res_entity_tab_t    IN  xx_tm_terr_res_entity_tab_t
           ,x_tm_autonamed_apierr_t       OUT xx_tm_autonamed_apierr_tab_t
         )
AS

  lc_message                                  VARCHAR2(240)  ;
  lc_eligible_flag                            VARCHAR2(1)    ;
  lc_insert_success                           VARCHAR2(1)    ;
  lc_proceed                                  VARCHAR2(1)    ;

  lc_success                                  PLS_INTEGER    := 0;
  lc_error                                    PLS_INTEGER    := 0;

  ln_count                                    PLS_INTEGER    := 0;
  ln_total_count                              PLS_INTEGER    := 0;

  ln_named_acct_terr_id                       xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  ln_named_terr_rsc_id                        xx_tm_nam_terr_rsc_dtls.named_acct_terr_rsc_id%TYPE;
  ln_named_terr_ent_id                        xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE;
  lc_named_acct_terr_name                     xx_tm_nam_terr_defn.named_acct_terr_name%TYPE;
  lc_named_acct_terr_desc                     xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE;

  lc_status                                   xx_tm_nam_terr_defn.status%TYPE            ;
  ld_start_date_active                        xx_tm_nam_terr_defn.start_date_active%TYPE ;
  ld_end_date_active                          xx_tm_nam_terr_defn.end_date_active%TYPE   ;
  lc_full_access_flag                         xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE  ;
  ln_source_terr_id                           xx_tm_nam_terr_defn.source_territory_id%TYPE  ;
  ln_resource_id                              xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  ;
  ln_role_id                                  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  ;
  ln_group_id                                 xx_tm_nam_terr_rsc_dtls.group_id%TYPE  ;
  lc_entity_type                              xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
  ln_entity_id                                xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;
  ln_source_entity_id                         xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE;

  ln_api_version_number                       CONSTANT PLS_INTEGER       := 1.0;
  lc_api_name                                 CONSTANT VARCHAR2(30) := 'Named_Account_Territory_Pub';

  lc_error_code                               VARCHAR2(1);
  lc_error_message                            VARCHAR2(4000);
  ln_tab_count                                PLS_INTEGER;

  EX_INVALID_API_VERSION                      EXCEPTION;
  EX_DUPLICATE_ROLECD_DIV                     EXCEPTION;
  EX_INVALID_STATUS                           EXCEPTION;

BEGIN

    -- Standard call to check for call compatibility.
    IF NOT FND_API.COMPATIBLE_API_CALL
             (
              ln_api_version_number,
              p_api_version_number,
              lc_api_name,
              'XX_JTF_RS_NAMED_ACC_TERR_PUB'
             )
    THEN
       RAISE EX_INVALID_API_VERSION;
    END IF;

    lt_tm_terr_res_entity_tbl   :=  p_tm_terr_res_entity_tab_t;

    ln_tab_count                :=  lt_tm_terr_res_entity_tbl.count;
    dbms_output.put_line('Tab Count:  '||ln_tab_count);

    --FOR I_index IN lt_tm_terr_res_entity_tbl.FIRST..lt_tm_terr_res_entity_tbl.FIRST
    FOR I_index IN 1..ln_tab_count
    LOOP

      dbms_output.put_line('Inside Tab'||I_index);

      --Assigning the parameters into local variables
      lc_status                 := lt_tm_terr_res_entity_tbl(I_index).status           ;
      ld_start_date_active      := lt_tm_terr_res_entity_tbl(I_index).start_date_active;

      IF ld_start_date_active IS NULL THEN
         ld_start_date_active := SYSDATE;
      END IF;

      IF lc_status IS NOT NULL THEN
         IF lc_status NOT IN ('A','I') THEN
            RAISE EX_INVALID_STATUS;
         END IF;
      END IF;

      --If the assignment is future dated then current record should be Inactivated
      IF ld_start_date_active > SYSDATE THEN
         lc_status := 'I' ;
      ELSE
         lc_status := 'A' ;
      END IF;

      ld_end_date_active        := lt_tm_terr_res_entity_tbl(I_index).end_date_active  ;
      lc_full_access_flag       := lt_tm_terr_res_entity_tbl(I_index).full_access_flag ;
      IF lc_full_access_flag IS NULL THEN
        lc_full_access_flag       := 'Y';
      END IF;

      ln_source_terr_id         := lt_tm_terr_res_entity_tbl(I_index).source_terr_id   ;
      ln_resource_id            := lt_tm_terr_res_entity_tbl(I_index).resource_id      ;
      ln_role_id                := lt_tm_terr_res_entity_tbl(I_index).role_id          ;
      ln_group_id               := lt_tm_terr_res_entity_tbl(I_index).group_id         ;
      lc_entity_type            := lt_tm_terr_res_entity_tbl(I_index).entity_type      ;
      ln_entity_id              := lt_tm_terr_res_entity_tbl(I_index).entity_id        ;
      ln_source_entity_id       := lt_tm_terr_res_entity_tbl(I_index).source_entity_id ;

      lt_tm_autonamed_apierr_tbl(I_index).status               := NVL(lc_status,'-')              ;
      lt_tm_autonamed_apierr_tbl(I_index).start_date_active    := ld_start_date_active            ;
      lt_tm_autonamed_apierr_tbl(I_index).end_date_active      := ld_end_date_active              ;
      lt_tm_autonamed_apierr_tbl(I_index).full_access_flag     := NVL(lc_full_access_flag,'Y')    ;
      lt_tm_autonamed_apierr_tbl(I_index).source_terr_id       := NVL(ln_source_terr_id,'-')      ;
      lt_tm_autonamed_apierr_tbl(I_index).resource_id          := ln_resource_id                  ;
      lt_tm_autonamed_apierr_tbl(I_index).role_id              := ln_role_id                      ;
      lt_tm_autonamed_apierr_tbl(I_index).group_id             := ln_group_id                     ;
      lt_tm_autonamed_apierr_tbl(I_index).entity_type          := lc_entity_type                  ;
      lt_tm_autonamed_apierr_tbl(I_index).entity_id            := ln_entity_id                    ;
      lt_tm_autonamed_apierr_tbl(I_index).source_entity_id     := NVL(ln_source_entity_id,0)             ;


      --Performing validations on the required fields
      Validate_terr_resource
                         (
                           p_resource_id             => ln_resource_id
                          ,p_resource_role_id        => ln_role_id
                          ,p_group_id                => ln_group_id
                          ,p_allow_inactive_resource => 'N'
                          ,x_eligible_flag           => lc_eligible_flag
                          ,x_error_code              => lc_error_code
                          ,x_error_message           => lc_error_message
                          );

      IF lc_eligible_flag  = 'N' THEN
         lc_proceed        := 'N';
         lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
         lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;
      END IF;

      --dbms_output.put_line('Validate_terr_resource: '||'  '||lc_eligible_flag||'  '||lc_error_message);

      lc_eligible_flag := NULL;
      --Performing validations on the required fields
      Validate_Territory_Entity
                              (
                                p_entity_type         => lc_entity_type
                               ,p_entity_id           => ln_entity_id
                               ,x_eligible_flag       => lc_eligible_flag
                               ,x_error_code          => lc_error_code
                               ,x_error_message       => lc_error_message
                              );

      IF lc_eligible_flag = 'N' THEN
            lc_proceed   := 'N';
            lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
            lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;
      END IF;


      --dbms_output.put_line('Validate_Territory_Entity: '||'  '||lc_eligible_flag||'  '||lc_error_message);

      lc_proceed   := 'Y';
      -- Checking if End Date is lesser than Start Date
      IF      (
                 ld_end_date_active < ld_start_date_active
                )
      THEN
          lc_proceed   := 'N';

          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0104_TERR_RES_DATES');
          lc_message        := FND_MESSAGE.GET;
          lc_error_code     := 'E';
          lc_error_message  := lc_message;
          lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
          lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;
          Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                         ,p_error_message_code =>  'XX_TM_0104_TERR_RES_DATES'
                         ,p_error_msg          =>  lc_message
                        );
      END IF;

      --dbms_output.put_line('Date: '||'  '||lc_proceed);

      IF lc_proceed  = 'Y' THEN
         IF lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id IS NOT NULL THEN

            lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_id   := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id  ;
            lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_name := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_name;
            lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_desc := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_desc;

            SELECT COUNT(1)
            INTO   ln_count
            FROM   xx_tm_nam_terr_defn
            WHERE  named_acct_terr_id   =  lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id
            AND    NVL(status,'A')      = 'A'
            AND    ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                             AND     NVL(end_date_active,SYSDATE+1);

            IF ln_count > 0 THEN

               ln_count := 0;
               SELECT COUNT(1)
               INTO   ln_count
               FROM   xx_tm_nam_terr_rsc_dtls
               WHERE  named_acct_terr_id = lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id
               AND    NVL(status,'A')    = 'A'
               AND    resource_id        = ln_resource_id
               AND    resource_role_id   = ln_role_id
               AND    group_id           = ln_group_id
               AND    ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                AND     NVL(end_date_active,SYSDATE+1);
               IF  ln_count = 0 THEN
                   FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0105_TERR_RES_NOTEXISTS');
                   lc_message        := FND_MESSAGE.GET;

                   lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'E'   ;
                   lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_message;

                   Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                                  ,p_error_message_code =>  'XX_TM_0105_TERR_RES_NOTEXISTS'
                                  ,p_error_msg          =>  lc_message
                                 );
               ELSE

                  ln_count := 0;
                  SELECT COUNT(1)
                  INTO   ln_count
                  FROM   xx_tm_nam_terr_entity_dtls
                  WHERE  named_acct_terr_id    = lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id
                  AND    entity_id             = ln_entity_id
                  AND    NVL(status,'A')       = 'A'
                  AND    ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                   AND     NVL(end_date_active,SYSDATE+1);

                  IF  ln_count = 0 THEN

                    lc_proceed       := 'Y';

                    /*

                    --If the profile OD: TM Validate Division and Role Code is set to Yes, then
                    --this validation will be performed.
                    IF FND_PROFILE.VALUE('XX_TM_VALIDATE_DIV_ROLE') = 'Yes' THEN

                     --Validate the Division and Role Code of the current Roles with
                      --Roles associated with the resources corresponding to the current Entity Id/Type
                      lc_eligible_flag := NULL;
                      Validate_Roles_Div_Role_Code
                               (
                                 p_role_id            => ln_role_id
                                ,p_group_id           => ln_group_id
                                ,p_entity_type        => lc_entity_type
                                ,p_entity_id          => ln_entity_id
                                ,p_start_date_active  => ld_start_date_active
                                ,x_eligible_flag      => lc_eligible_flag
                               );
                      IF lc_eligible_flag = 'N' THEN
                         lc_proceed      := 'N';
                         RAISE EX_DUPLICATE_ROLECD_DIV;
                      END IF;

                    END IF;
                    */

                    IF lc_proceed       = 'Y' THEN

                      --Populate a new entity record in xx_tm_nam_terr_entity_dtls
                      --with entity details passed as parameters.

                      --Call the internal procedure to populate XX_TM_NAM_TERR_ENTITY_DTLS
                      SELECT XXCRM.xx_tm_nam_terr_entity_dtls_s.NEXTVAL
                      INTO   ln_named_terr_ent_id
                      FROM   DUAL;

                      lc_insert_success     := NULL;
                      ln_named_acct_terr_id := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_id;
                      Insert_terr_entity
                         (
                          p_named_acct_terr_entity_id  => ln_named_terr_ent_id,
                          p_named_acct_terr_id         => ln_named_acct_terr_id,
                          p_entity_type                => lc_entity_type,
                          p_entity_id                  => ln_entity_id,
                          p_status                     => lc_status,
                          p_start_date_active          => ld_start_date_active,
                          p_end_date_active            => ld_end_date_active  ,
                          p_full_access_flag           => lc_full_access_flag,
                          p_source_entity_id           => ln_source_entity_id,
                          p_set_extracted_status       => 'N',
                          p_terr_asgnmnt_source        => NULL,
                          x_insert_success             => lc_insert_success,
                          x_error_code                 => lc_error_code   ,
                          x_error_message              => lc_error_message
                         );

                       lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
                       lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;

                    END IF;

                  ELSE
                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0106_TERR_ENTITY_EXISTS');
                     lc_message        := FND_MESSAGE.GET;
                     lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'E'   ;
                     lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_message;

                     Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                                    ,p_error_message_code =>  'XX_TM_0106_TERR_ENTITY_EXISTS'
                                    ,p_error_msg          =>  lc_message
                                   );
                  END IF;

               END IF;

            ELSE

                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0107_INVALID_TERR');
                lc_message        := FND_MESSAGE.GET;
                lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'E'   ;
                lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_message;

                Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                               ,p_error_message_code =>  'XX_TM_0107_INVALID_TERR'
                               ,p_error_msg          =>  lc_message
                              );
            END IF;
         ELSE
           dbms_output.put_line('Territory Id is null');
           --
           --If Territory Id passed as NULL
           --
           --Obtain the existing terrtitory for the resource id from XX_TM_NAM_TERR_RSC_DTLS
           BEGIN
             SELECT named_acct_terr_id
             INTO   ln_named_acct_terr_id
             FROM   xx_tm_nam_terr_rsc_dtls
             WHERE  resource_id        = ln_resource_id
             AND    resource_role_id   = ln_role_id
             AND    group_id           = ln_group_id
             AND    NVL(status,'A')    = 'A'
             AND    ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                AND     NVL(end_date_active,(SYSDATE)+1);
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_named_acct_terr_id := NULL;
             WHEN OTHERS THEN
                ln_named_acct_terr_id := NULL;
           END;
           dbms_output.put_line('Territory Id: '||ln_named_acct_terr_id);
           IF ln_named_acct_terr_id IS NOT NULL THEN

              lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_id   := ln_named_acct_terr_id;
              lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_name := '-';
              lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_desc := '-';

              --dbms_output.put_line('Create Only Entity');
              ln_count := 0;
              SELECT COUNT(1)
              INTO   ln_count
              FROM   xx_tm_nam_terr_entity_dtls
              WHERE  named_acct_terr_id    = ln_named_acct_terr_id
              AND    entity_id             = ln_entity_id
              AND    NVL(status,'A')       = 'A'
              AND    ld_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                 AND     NVL(end_date_active,(SYSDATE)+1);

              dbms_output.put_line('Territory Id / Entity exists: '||ln_count);

              --If Entity Id already exists in XX_TM_NAM_TERR_ENTITY_DTLS,
              --then do not create record.
              IF ln_count > 0 THEN
                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0106_TERR_ENTITY_EXISTS');
                 lc_message        := FND_MESSAGE.GET;
                 lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'E'   ;
                 lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_message ||'('||ln_entity_id||')';
                 dbms_output.put_line('Territory Id / Entity exists Error Message: '||lc_message||'  '||ln_entity_id);
                 Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                                ,p_error_message_code =>  'XX_TM_0106_TERR_ENTITY_EXISTS'
                                ,p_error_msg          =>  lc_message
                               );
              ELSE

                --Populate a new entity record in xx_tm_nam_terr_entity_dtls
                --for the existing territory id ln_named_acct_terr_id.

                --Call the internal procedure to populate XX_TM_NAM_TERR_ENTITY_DTLS
                SELECT XXCRM.xx_tm_nam_terr_entity_dtls_s.NEXTVAL
                INTO   ln_named_terr_ent_id
                FROM   DUAL;

                lc_insert_success := NULL;
                Insert_terr_entity
                    (
                     p_named_acct_terr_entity_id  => ln_named_terr_ent_id,
                     p_named_acct_terr_id         => ln_named_acct_terr_id,
                     p_entity_type                => lc_entity_type,
                     p_entity_id                  => ln_entity_id,
                     p_status                     => lc_status,
                     p_start_date_active          => ld_start_date_active,
                     p_end_date_active            => ld_end_date_active  ,
                     p_full_access_flag           => lc_full_access_flag,
                     p_source_entity_id           => ln_source_entity_id,
                     p_set_extracted_status       => 'N',
                     p_terr_asgnmnt_source        => NULL,
                     x_insert_success             => lc_insert_success,
                     x_error_code                 => lc_error_code   ,
                     x_error_message              => lc_error_message
                    );

                lt_tm_autonamed_apierr_tbl(I_index).error_code           := lc_error_code   ;
                lt_tm_autonamed_apierr_tbl(I_index).error_message        := lc_error_message;
                dbms_output.put_line('Insert Terr Entity: '||lc_insert_success);
                dbms_output.put_line('Insert Terr Entity Error Code: '||lc_error_code);
                dbms_output.put_line('Insert Terr Entity Error Message: '||lc_error_message);
              END IF;

           ELSE
             dbms_output.put_line('Create All');

             --Generate a named account territory and create a record in
             --xx_tm_nam_terr_defn and populate xx_tm_nam_terr_rsc_dtls and
             --xx_tm_nam_terr_entity_dtls with the Resource and Entity Details
             --passed as parameters.

             --Obtaining Territory Name and Description
             lc_named_acct_terr_name := NULL;
             IF lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_name IS NOT NULL THEN
                lc_named_acct_terr_name := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_name;
             ELSE
                lc_named_acct_terr_name := NULL;
                SELECT NVL(source_name,'No Territoty Name')
                INTO   lc_named_acct_terr_name
                FROM   jtf_rs_resource_extns
                WHERE  resource_id = ln_resource_id;
             END IF;

             IF lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_desc IS NULL THEN
                lc_named_acct_terr_desc := lc_named_acct_terr_name;
             ELSIF lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_desc IS NOT NULL THEN
                lc_named_acct_terr_desc := lt_tm_terr_res_entity_tbl(I_index).named_acct_terr_desc;
             END IF;

             dbms_output.put_line('Terr name: '||lc_named_acct_terr_name||' desc: '||lc_named_acct_terr_desc);

             --Call the internal procedure to populate XX_TM_NAM_TERR_DEFN
             --Generate Territory
             ln_named_acct_terr_id := NULL;
             SELECT XXCRM.xx_tm_nam_terr_defn_s.NEXTVAL
             INTO   ln_named_acct_terr_id
             FROM   DUAL;

             Insert_territory
               (
                p_named_acct_terr_id   => ln_named_acct_terr_id,
                p_named_acct_terr_name => lc_named_acct_terr_name,
                p_named_acct_terr_desc => lc_named_acct_terr_desc,
                p_status               => lc_status,
                p_start_date_active    => ld_start_date_active,
                p_end_date_active      => ld_end_date_active  ,
                p_source_territory_id  => ln_source_terr_id,
                x_insert_success       => lc_insert_success ,
                x_error_code           => lc_error_code   ,
                x_error_message        => lc_error_message
               );

               lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_id   := ln_named_acct_terr_id;
               lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_name := lc_named_acct_terr_name;
               lt_tm_autonamed_apierr_tbl(I_index).named_acct_terr_desc := lc_named_acct_terr_desc;
               lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
               lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;

               dbms_output.put_line('Terr Insert: '||lc_insert_success||' Err Message: '||lc_error_message);

             --Call the internal procedure to populate XX_TM_NAM_TERR_RSC_DTLS
             IF lc_insert_success = 'Y' THEN

               SELECT XXCRM.xx_tm_nam_terr_rsc_dtls_s.NEXTVAL
               INTO   ln_named_terr_rsc_id
               FROM   DUAL;

               lc_insert_success := NULL;
               Insert_terr_resource
                   (
                    p_named_acct_terr_rsc_id => ln_named_terr_rsc_id,
                    p_named_acct_terr_id     => ln_named_acct_terr_id,
                    p_resource_id            => ln_resource_id,
                    p_resource_role_id       => ln_role_id,
                    p_group_id               => ln_group_id,
                    p_status                 => lc_status,
                    p_start_date_active      => ld_start_date_active,
                    p_end_date_active        => ld_end_date_active  ,
                    p_set_extracted_status   => 'N',
                    x_insert_success         => lc_insert_success,
                    x_error_code             => lc_error_code   ,
                    x_error_message          => lc_error_message
                 );

                 lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
                 lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;

                 dbms_output.put_line('Terr Resource Insert: '||lc_insert_success||' Err Message: '||lc_error_message);
             END IF;

             --Call the internal procedure to populate XX_TM_NAM_TERR_ENTITY_DTLS
             IF lc_insert_success = 'Y' THEN

               SELECT XXCRM.xx_tm_nam_terr_entity_dtls_s.NEXTVAL
               INTO   ln_named_terr_ent_id
               FROM   DUAL;

               lc_insert_success := NULL;
               Insert_terr_entity
                 (
                    p_named_acct_terr_entity_id  => ln_named_terr_ent_id,
                    p_named_acct_terr_id         => ln_named_acct_terr_id,
                    p_entity_type                => lc_entity_type,
                    p_entity_id                  => ln_entity_id,
                    p_status                     => lc_status,
                    p_start_date_active          => ld_start_date_active,
                    p_end_date_active            => ld_end_date_active  ,
                    p_full_access_flag           => lc_full_access_flag,
                    p_source_entity_id           => ln_source_entity_id,
                    p_set_extracted_status       => 'N',
                    p_terr_asgnmnt_source        => NULL,
                    x_insert_success             => lc_insert_success,
                    x_error_code                 => lc_error_code   ,
                    x_error_message              => lc_error_message
                 );

                lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
                lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;

                dbms_output.put_line('Terr Entity Insert: '||lc_insert_success||' Err Message: '||lc_error_message);

             END IF;

           END IF; -- If any existing Territory Id found for the resource id

         END IF;

         --dbms_output.put_line('Success: ');
          lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'S'   ;
          lt_tm_autonamed_apierr_tbl(I_index).error_message := 'Record Created Successfully.';

      ELSE

        lc_error    := NVL(lc_error,0) + 1;
        lt_tm_autonamed_apierr_tbl(I_index).error_code    := lc_error_code   ;
        lt_tm_autonamed_apierr_tbl(I_index).error_message := lc_error_message;
        COMMIT;
      END IF;

      dbms_output.put_line('Error Occured: '||lc_error);

      IF lc_error > 0 THEN
          --dbms_output.put_line('Error: ');
          lt_tm_autonamed_apierr_tbl(I_index).error_code    := 'E'   ;
          lt_tm_autonamed_apierr_tbl(I_index).error_message := 'All records are not created successfully.';
      END IF;
      --dbms_output.put_line('Index Count: '||I_index) ;

    END LOOP;

    x_tm_autonamed_apierr_t := lt_tm_autonamed_apierr_tbl;


EXCEPTION
WHEN EX_INVALID_API_VERSION THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0103_INVALID_API_VER');
    lc_message        := FND_MESSAGE.GET;
    lt_tm_autonamed_apierr_tbl(1).error_code    := 'E'   ;
    lt_tm_autonamed_apierr_tbl(1).error_message := lc_message;

    Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                   ,p_error_message_code =>  'XX_TM_0103_INVALID_API_VER'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_DUPLICATE_ROLECD_DIV THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0182_DUPLICATE_RLCD_DIV');
    lc_message        := FND_MESSAGE.GET;
    lt_tm_autonamed_apierr_tbl(1).error_code    := 'E'   ;
    lt_tm_autonamed_apierr_tbl(1).error_message := lc_message;
    Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                   ,p_error_message_code =>  'XX_TM_0182_DUPLICATE_RLCD_DIV'
                   ,p_error_msg          =>  lc_message
                  );
WHEN EX_INVALID_STATUS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0183_INVALID_STATUS');
    lc_message        := FND_MESSAGE.GET;
    lt_tm_autonamed_apierr_tbl(1).error_code    := 'E'   ;
    lt_tm_autonamed_apierr_tbl(1).error_message := lc_message;
    Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                   ,p_error_message_code =>  'XX_TM_0183_INVALID_STATUS'
                   ,p_error_msg          =>  lc_message
                  );
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Create_Bulk_Territory');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message        := FND_MESSAGE.GET;
    lt_tm_autonamed_apierr_tbl(1).error_code    := 'E'   ;
    lt_tm_autonamed_apierr_tbl(1).error_message := lc_message;

    Log_Exception ( p_error_location     =>  'Create_Bulk_Territory'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
END Create_Bulk_Territory;

-- +================================================================================+
-- | Name        :  Delete_Terr_Resource_Entity                                     |
-- | Description :  This procedure is used to delete Entity Records from all the    |
-- |                Three Custom Named Account Territory tables.                    |
-- +================================================================================+
PROCEDURE Delete_Terr_Resource_Entity
              (
                p_territory_id    IN         xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
               ,p_resource_id     IN         xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
               ,p_entity_type     IN         xx_tm_nam_terr_entity_dtls.entity_type%TYPE
               ,p_entity_id       IN         xx_tm_nam_terr_entity_dtls.entity_id%TYPE
               ,x_delete_success  OUT NOCOPY VARCHAR2
               ,x_error_code      OUT NOCOPY VARCHAR2
               ,x_error_message   OUT NOCOPY VARCHAR2
              )
AS

  lc_message               VARCHAR2(240);

  ln_territory_id          xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  ln_resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE     ;
  lc_entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
  ln_entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;

  EX_TM_INVALID_DELETE_PARAM EXCEPTION;

BEGIN


    ln_territory_id     := p_territory_id       ;
    ln_resource_id      := p_resource_id        ;
    lc_entity_type      := p_entity_type        ;
    ln_entity_id        := p_entity_id          ;

    CASE
         WHEN (ln_territory_id IS NULL OR
               ln_resource_id  IS NULL OR
               ln_entity_id    IS NULL   )
          THEN
               RAISE EX_TM_INVALID_DELETE_PARAM;
    END CASE;


    DELETE
    FROM    xx_tm_nam_terr_defn
    WHERE   named_acct_terr_id  = ln_territory_id;

    DELETE
    FROM   xx_tm_nam_terr_rsc_dtls
    WHERE  named_acct_terr_id  = ln_territory_id
    AND    resource_id         = ln_resource_id;


    DELETE
    FROM   xx_tm_nam_terr_entity_dtls
    WHERE  named_acct_terr_id = ln_territory_id
    AND    entity_type        = NVL(lc_entity_type,entity_type)
    AND    entity_id          = ln_entity_id;

    x_delete_success   := 'Y';

EXCEPTION
WHEN EX_TM_INVALID_DELETE_PARAM THEN
    x_delete_success   := 'N';
    x_error_code       := 'E';
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0184_INVALID_DELPARAM');
    lc_message         := FND_MESSAGE.GET;

    Log_Exception ( p_error_location     =>  'Delete_Terr_Resource_Entity'
                   ,p_error_message_code =>  'XX_TM_0184_INVALID_DELPARAM'
                   ,p_error_msg          =>  lc_message
                  );

WHEN OTHERS THEN
    x_delete_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Delete_Terr_Resource_Entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Delete_Terr_Resource_Entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Delete_Terr_Resource_Entity;

-- +================================================================================+
-- | Name        :  Delete_Territory_Entity                                         |
-- | Description :  This procedure is used to delete Entity Records from            |
-- |                XX_TM_NAM_TERR_DEFN                      .                      |
-- +================================================================================+
PROCEDURE Delete_Territory_Entity
                    (
                     p_territory_id    IN    xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE
                    ,p_entity_type     IN    xx_tm_nam_terr_entity_dtls.entity_type%TYPE
                    ,p_entity_id       IN    xx_tm_nam_terr_entity_dtls.entity_id%TYPE
                    ,x_delete_success  OUT NOCOPY VARCHAR2
                    ,x_error_code      OUT NOCOPY VARCHAR2
                    ,x_error_message   OUT NOCOPY VARCHAR2
                    )
IS

  lc_message               VARCHAR2(240);
  ln_territory_id          xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE;
  lc_entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
  ln_entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;

  EX_TM_INVALID_DELETE_PARAM EXCEPTION;

BEGIN


    ln_territory_id      := p_territory_id     ;
    lc_entity_type       := p_entity_type      ;
    ln_entity_id         := p_entity_id        ;

    CASE
        WHEN (ln_territory_id IS NULL OR
              ln_entity_id    IS NULL   )
        THEN
             RAISE EX_TM_INVALID_DELETE_PARAM;
    END CASE;

    DELETE
    FROM   xx_tm_nam_terr_entity_dtls
    WHERE  named_acct_terr_id = ln_territory_id
    AND    entity_type        = NVL(lc_entity_type,entity_type)
    AND    entity_id          = ln_entity_id;

    x_delete_success   := 'Y';

EXCEPTION
WHEN EX_TM_INVALID_DELETE_PARAM THEN
    x_delete_success   := 'N';
    x_error_code       := 'E';
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0184_INVALID_DELPARAM');
    lc_message         := FND_MESSAGE.GET;

    Log_Exception ( p_error_location     =>  'Delete_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0184_INVALID_DELPARAM'
                   ,p_error_msg          =>  lc_message
                  );

WHEN OTHERS THEN
    x_delete_success   := 'N';
    x_error_code       := 'E';

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Delete_Territory_Entity');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message         := FND_MESSAGE.GET;
    x_error_message    := lc_message;

    Log_Exception ( p_error_location     =>  'Delete_Territory_Entity'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Delete_Territory_Entity;

-- +=================================================================================+
-- | Name        :  Move_Party_Sites                                                 |
-- | Description :  This procedure is used to move entity from one territory to      |
-- |                another if the parameters passed all the validations.            |
-- +=================================================================================+
PROCEDURE Move_Party_Sites
          (
            p_api_version_number       IN  PLS_INTEGER
           ,p_from_named_acct_terr_id  IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    DEFAULT NULL
           ,p_to_named_acct_terr_id    IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    DEFAULT NULL
           ,p_from_start_date_active   IN  xx_tm_nam_terr_defn.start_date_active%TYPE     DEFAULT SYSDATE
           ,p_to_start_date_active     IN  xx_tm_nam_terr_defn.start_date_active%TYPE     DEFAULT NULL
           ,p_from_resource_id         IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       DEFAULT NULL
           ,p_to_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       DEFAULT NULL
           ,p_from_role_id             IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  DEFAULT NULL
           ,p_to_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  DEFAULT NULL
           ,p_from_group_id            IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE          DEFAULT NULL
           ,p_to_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE          DEFAULT NULL
           ,p_entity_type              IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE
           ,p_entity_id                IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE
           ,p_commit                   IN  BOOLEAN DEFAULT TRUE
           ,x_error_code               OUT NOCOPY VARCHAR2
           ,x_error_message            OUT NOCOPY VARCHAR2
         )
AS
  lc_proc  constant varchar2(80) := 'Move_Party_Sites';

  lc_message                           VARCHAR2(240)  ;
  lc_eligible_flag                     VARCHAR2(1)    ;
  lc_update_success                    VARCHAR2(1)    ;
  lc_insert_success                    VARCHAR2(1)    ;
  lc_proceed                           VARCHAR2(1)    ;
  ln_count                             PLS_INTEGER     := 0;
  lc_error_code                        VARCHAR2(1);
  lc_error_message                     VARCHAR2(4000);
  lc_terr_resource_msg                 VARCHAR2(4000);
  ln_named_terr_ent_id                 PLS_INTEGER;

  ln_from_named_acct_terr_id           xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    ;
  ln_to_named_acct_terr_id             xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    ;
  ld_from_start_date_active            xx_tm_nam_terr_defn.start_date_active%TYPE     ;
  ld_to_start_date_active              xx_tm_nam_terr_defn.start_date_active%TYPE     ;
  ln_from_resource_id                  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       ;
  ln_to_resource_id                    xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       ;
  ln_from_role_id                      xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  ;
  ln_to_role_id                        xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  ;
  ln_from_group_id                     xx_tm_nam_terr_rsc_dtls.group_id%TYPE           ;
  ln_to_group_id                       xx_tm_nam_terr_rsc_dtls.group_id%TYPE           ;
  lc_entity_type                       xx_tm_nam_terr_entity_dtls.entity_type%TYPE    ;
  ln_entity_id                         xx_tm_nam_terr_entity_dtls.entity_id%TYPE      ;
  lc_status                            xx_tm_nam_terr_entity_dtls.status%TYPE           ;
  lc_full_access_flag                  xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE ;
  ln_source_entity_id                  xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE ;
  ln_named_acct_terr_entity_id         xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE ;
  ln_to_named_terr_ent_exists          PLS_INTEGER;

  ln_api_version_number                CONSTANT PLS_INTEGER  := 1.0;
  lc_api_name                          CONSTANT VARCHAR2(30) := 'Named_Account_Territory_Pub';

  EX_INVALID_FROM_TERR_ID              EXCEPTION;
  EX_INVALID_TO_TERR_ID                EXCEPTION;

  EX_FROM_START_DATE_NULL              EXCEPTION;
  EX_INVALID_API_VERSION               EXCEPTION;
  EX_INVALID_STATUS                    EXCEPTION;
  EX_MULTIPLE_RSC_FOR_ENTITY_ID        EXCEPTION;
  EX_ERROR_FETCHING_NMD_TERR_ID        EXCEPTION;


BEGIN

    -- Standard call to check for call compatibility.
    IF NOT FND_API.COMPATIBLE_API_CALL
             (
              ln_api_version_number,
              p_api_version_number,
              lc_api_name,
              'XX_JTF_RS_NAMED_ACC_TERR_PUB'
             )
    THEN
       RAISE EX_INVALID_API_VERSION;
    END IF;

    --Assigning the parameters into local variables
    ln_from_named_acct_terr_id    := p_from_named_acct_terr_id ;
    ln_to_named_acct_terr_id      := p_to_named_acct_terr_id   ;
    ld_from_start_date_active     := p_from_start_date_active  ;

    IF ld_from_start_date_active IS NULL THEN
       ld_from_start_date_active := SYSDATE;
    END IF;

    ld_to_start_date_active       := p_to_start_date_active    ;
    ln_from_resource_id           := p_from_resource_id        ;
    ln_to_resource_id             := p_to_resource_id          ;
    ln_from_role_id               := p_from_role_id            ;
    ln_to_role_id                 := p_to_role_id              ;
    ln_from_group_id              := p_from_group_id           ;
    ln_to_group_id                := p_to_group_id             ;
    lc_entity_type                := p_entity_type             ;
    ln_entity_id                  := p_entity_id               ;
    lc_eligible_flag              := NULL                      ;
    lc_proceed                    := 'Y'                       ;

    IF lc_full_access_flag IS NULL THEN
       lc_full_access_flag       := 'Y';
    END IF;

    --Performing validations on the required Territory Entity fields
    Validate_Territory_Entity
                             (
                               p_entity_type     => lc_entity_type
                              ,p_entity_id       => ln_entity_id
                              ,x_eligible_flag   => lc_eligible_flag
                              ,x_error_code      => lc_error_code
                              ,x_error_message   => lc_error_message
                             );

    IF lc_eligible_flag <> 'Y' THEN
       lc_proceed   := 'N';
    END IF;


    --Checking Null value for From start date active
    IF ld_from_start_date_active IS NULL THEN
       lc_proceed       := 'N';
       lc_error_message := lc_error_message||CHR(13)||'From Start date active is NULL.';
    END IF;

    --Validating From Terr Id and From Res / Role / Grp Combination
    CASE
    WHEN ln_from_named_acct_terr_id IS NULL THEN

       IF ln_from_resource_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Resource Id is required As From Territory Id is passed as NULL.';
       ELSIF ln_from_role_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Role Id is required As From Territory Id is passed as NULL.';
       ELSIF ln_from_group_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Group Id is required As From Territory Id is passed as NULL.';
       ELSE

           --Performing validations on the From Resource Id , Role Id, Group id
           Validate_terr_resource
                                (
                                   p_resource_id             => ln_from_resource_id
                                  ,p_resource_role_id        => ln_from_role_id
                                  ,p_group_id                => ln_from_group_id
                                  ,p_allow_inactive_resource => 'N'
                                  ,x_eligible_flag           => lc_eligible_flag
                                  ,x_error_code              => lc_error_code
                                  ,x_error_message           => lc_terr_resource_msg
                                 );

           IF lc_eligible_flag  <> 'Y' THEN
              lc_proceed        := 'N';
              lc_error_message   := lc_error_message||CHR(13)||lc_terr_resource_msg ;
           END IF;

           IF  lc_proceed = 'Y' THEN
               --Obtain the existing terrtitory for the resource/role/group combination
               BEGIN
                 SELECT TERR.named_acct_terr_id
                 INTO   ln_from_named_acct_terr_id
                 FROM   xx_tm_nam_terr_rsc_dtls     RES
                       ,xx_tm_nam_terr_defn         TERR
                 WHERE  RES.resource_id        = ln_from_resource_id
                 AND    RES.resource_role_id   = ln_from_role_id
                 AND    RES.group_id           = ln_from_group_id
                 AND    NVL(RES.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(RES.start_date_active,SYSDATE-1)
                                                  AND       NVL(RES.end_date_active,(SYSDATE)+1)
                 AND    TERR.named_acct_terr_id = RES.named_acct_terr_id
                 AND    NVL(TERR.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(TERR.start_date_active,SYSDATE-1)
                                                  AND       NVL(TERR.end_date_active,(SYSDATE)+1)
                 ;
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   lc_proceed            := 'N';
                   lc_error_message := lc_error_message||CHR(13)||'No active territory assigned to the From Resource / Role / Groups combination.';
                 WHEN OTHERS THEN
                   lc_proceed            := 'N';
                   lc_error_message := lc_error_message||CHR(13)||'Unexpected Error: Deriving the From Terr for the From Res/Role/Grp Combination.';
               END;
           END IF;

       END IF;
    ELSE

         --Validating whether From_Named_Acct_Terr_Id exists in custom named account
         --teriitory definition table or not.
         SELECT COUNT(1)
         INTO   ln_count
         FROM   xx_tm_nam_terr_defn
         WHERE  named_acct_terr_id   =  ln_from_named_acct_terr_id
         AND    NVL(status,'A')      = 'A'
         AND    ld_from_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                                   AND   NVL(end_date_active,(SYSDATE)+1000);

         IF ln_count = 0 THEN
           lc_proceed            := 'N';
           lc_error_message := lc_error_message||CHR(13)||'Invalid From Territoty Id passed as parameter.';
         END IF;
    END CASE;  --End of CASE statement


    --Validating To Terr Id and From Res / Role / Grp Combination
    CASE
    WHEN ln_to_named_acct_terr_id IS NULL THEN

       IF ln_to_resource_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'To Resource Id is required as To Territory Id is passed as NULL.';
       ELSIF ln_to_role_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'To Role Id is required as To Territory Id is passed as NULL.';
       ELSIF ln_to_group_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'To Group Id is required as To Territory Id is passed as NULL.';
       ELSE
           --Performing validations on the From Resource Id , Role Id, Group id
           lc_terr_resource_msg  := NULL;
           Validate_terr_resource
                                (
                                   p_resource_id             => ln_to_resource_id
                                  ,p_resource_role_id        => ln_to_role_id
                                  ,p_group_id                => ln_to_group_id
                                  ,p_allow_inactive_resource => 'N'
                                  ,x_eligible_flag           => lc_eligible_flag
                                  ,x_error_code              => lc_error_code
                                  ,x_error_message           => lc_terr_resource_msg
                                 );

           IF lc_eligible_flag  <> 'Y' THEN
              lc_proceed        := 'N';
              lc_error_message   := lc_error_message||CHR(13)||lc_terr_resource_msg ;
           END IF;

           IF  lc_proceed = 'Y' THEN

              --Obtain the existing terrtitory for the To resource/role/group combination
              BEGIN
                 SELECT TERR.named_acct_terr_id
                 INTO   ln_to_named_acct_terr_id
                 FROM   xx_tm_nam_terr_rsc_dtls     RES
                       ,xx_tm_nam_terr_defn         TERR
                 WHERE  RES.resource_id        = ln_to_resource_id
                 AND    RES.resource_role_id   = ln_to_role_id
                 AND    RES.group_id           = ln_to_group_id
                 AND    NVL(RES.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(RES.start_date_active,SYSDATE-1)
                                                  AND       NVL(RES.end_date_active,(SYSDATE)+1)
                 AND    TERR.named_acct_terr_id = RES.named_acct_terr_id
                 AND    NVL(TERR.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(TERR.start_date_active,SYSDATE-1)
                                                  AND       NVL(TERR.end_date_active,(SYSDATE)+1)
                 ;
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   ln_to_named_acct_terr_id := NULL;
                 WHEN OTHERS THEN
                   ln_to_named_acct_terr_id := NULL;
               END;
           END IF;

       END IF;
    ELSE

         --Validating whether To_Named_Acct_Terr_Id exists in custom named account
         --teriitory definition table or not.
         SELECT COUNT(1)
         INTO   ln_count
         FROM   xx_tm_nam_terr_defn
         WHERE  named_acct_terr_id   =  ln_to_named_acct_terr_id
         AND    NVL(status,'A')      = 'A'
         AND    ld_from_start_date_active BETWEEN NVL(start_date_active,SYSDATE-1)
                                          AND     NVL(end_date_active,(SYSDATE)+1000);

         IF ln_count = 0 THEN
           lc_proceed            := 'N';
           lc_error_message := lc_error_message||CHR(13)||'Invalid To Territoty Id passed as parameter.';
         END IF;

    END CASE;  --End of CASE statement


    IF lc_proceed   = 'Y' THEN

       lc_update_success := NULL;

       IF ld_from_start_date_active <= SYSDATE THEN
         lc_status := 'I';
       END IF;

       BEGIN
         SELECT XTNTED.named_acct_terr_entity_id
         INTO   ln_named_acct_terr_entity_id
         FROM   xx_tm_nam_terr_entity_dtls XTNTED
         WHERE  XTNTED.entity_id           = ln_entity_id
         AND    XTNTED.entity_type         = lc_entity_type
         AND    XTNTED.named_acct_terr_id  = ln_from_named_acct_terr_id
         AND    ld_from_start_date_active BETWEEN NVL(XTNTED.start_date_active,SYSDATE-1)
                                          AND     NVL(XTNTED.end_date_active,SYSDATE+1)
         AND    NVL(XTNTED.status,'A') = 'A'
         AND    XTNTED.end_date_active IS NULL;
       EXCEPTION
       WHEN TOO_MANY_ROWS THEN
        RAISE EX_MULTIPLE_RSC_FOR_ENTITY_ID;
       WHEN OTHERS THEN
        RAISE EX_ERROR_FETCHING_NMD_TERR_ID;
       END;

       Update_entity
         (
           p_nmd_acct_terr_entity_id => ln_named_acct_terr_entity_id
          ,p_end_date_active         => ld_from_start_date_active
          ,p_status                  => lc_status
          ,p_entity_type             => lc_entity_type
          ,p_entity_id               => ln_entity_id
          ,x_update_success          => lc_update_success
          ,x_error_code              => x_error_code
          ,x_error_message           => x_error_message
         ) ;


       --Call the internal procedure to populate XX_TM_NAM_TERR_ENTITY_DTLS
       IF lc_update_success = 'Y' THEN

         lc_insert_success := NULL;

         SELECT XXCRM.xx_tm_nam_terr_entity_dtls_s.NEXTVAL
         INTO   ln_named_terr_ent_id
         FROM   DUAL;

         IF lc_status IS NOT NULL THEN
            IF lc_status NOT IN ('A','I') THEN
               RAISE EX_INVALID_STATUS;
            END IF;
         END IF;

         --If the assignment is future dated then current record should be Inactivated
         IF ld_from_start_date_active > SYSDATE THEN
           lc_status := 'I';
         ELSE
           lc_status := 'A';
         END IF;

         IF ln_to_named_acct_terr_id IS NOT NULL THEN

            SELECT COUNT(1)
            INTO   ln_to_named_terr_ent_exists
            FROM   xx_tm_nam_terr_entity_dtls XTNTED
            WHERE  XTNTED.entity_id           = ln_entity_id
            AND    XTNTED.entity_type         = lc_entity_type
            AND    XTNTED.named_acct_terr_id  = ln_to_named_acct_terr_id
            AND    ld_from_start_date_active BETWEEN NVL(XTNTED.start_date_active,SYSDATE-1)
                                             AND     NVL(XTNTED.end_date_active,SYSDATE+1)
            AND    NVL(XTNTED.status,'A') = 'A'
            AND    XTNTED.end_date_active IS NULL;

            IF  ln_to_named_terr_ent_exists = 0 THEN

                Insert_terr_entity
                                 (
                                 p_named_acct_terr_entity_id  => ln_named_terr_ent_id,
                                 p_named_acct_terr_id         => ln_to_named_acct_terr_id,
                                 p_entity_type                => lc_entity_type,
                                 p_entity_id                  => ln_entity_id,
                                 p_status                     => lc_status,
                                 p_start_date_active          => ld_from_start_date_active,
                                 p_end_date_active            => ld_to_start_date_active  ,
                                 p_full_access_flag           => lc_full_access_flag,
                                 p_source_entity_id           => ln_source_entity_id,
                                 p_set_extracted_status       => 'N',
                                 p_terr_asgnmnt_source        => NULL,
                                 x_insert_success             => lc_insert_success,
                                 x_error_code                 => x_error_code   ,
                                 x_error_message              => x_error_message
                                );
                IF lc_insert_success = 'Y' THEN
                   x_error_code      := 'S';
                   x_error_message   := 'Record Updated / Created successfully in Terr Entity table';
                   IF p_commit THEN
                      COMMIT;
                   END IF;
                END IF;

            END IF;

         ELSE
               --Call Create records in the three named account table using the prc CREATE_TERRITORY

                Create_Territory
                (
                  p_api_version_number    => 1.0
                 ,p_named_acct_terr_id    => NULL
                 ,p_named_acct_terr_name  => NULL
                 ,p_named_acct_terr_desc  => NULL
                 ,p_status                => lc_status
                 ,p_start_date_active     => ld_from_start_date_active
                 ,p_end_date_active       => NULL
                 ,p_full_access_flag      => lc_full_access_flag
                 ,p_source_terr_id        => ln_source_entity_id
                 ,p_resource_id           => ln_to_resource_id
                 ,p_role_id               => ln_to_role_id
                 ,p_group_id              => ln_to_group_id
                 ,p_entity_type           => lc_entity_type
                 ,p_entity_id             => ln_entity_id
                 ,p_source_entity_id      => ln_source_entity_id
                 ,p_source_system         => NULL
                 ,P_commit                => p_commit
                 ,x_error_code            => x_error_code
                 ,x_error_message         => x_error_message
               );

         END IF;

       END IF;

    ELSE
       x_error_code    := 'E';
       x_error_message := SUBSTR(lc_error_message,1,4000);
    END IF;

EXCEPTION
WHEN EX_INVALID_API_VERSION THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0103_INVALID_API_VER');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0103_INVALID_API_VER'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_STATUS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0183_INVALID_STATUS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0183_INVALID_STATUS'
                   ,p_error_msg          =>  lc_message
                  );

WHEN EX_MULTIPLE_RSC_FOR_ENTITY_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0197_MULTIPLE_RSC');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0197_MULTIPLE_RSC'
                   ,p_error_msg          =>  lc_message
                  );

WHEN EX_ERROR_FETCHING_NMD_TERR_ID THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0198_ERR_IN_FETCH_RSC');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0198_ERR_IN_FETCH_RSC'
                   ,p_error_msg          =>  lc_message
                  );

WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Move_Party_Sites');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  lc_proc
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Move_Party_Sites;

-- +================================================================================+
-- | Name        :  Move_Resource_Territories                                       |
-- | Description :  This procedure is used to move Territory from one resource to   |
-- |                another,if the parameters passed all the validations.           |
-- +================================================================================+
PROCEDURE Move_Resource_Territories
          (
            p_api_version_number       IN  PLS_INTEGER
           ,p_from_named_acct_terr_id  IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
           ,p_from_start_date_active   IN  xx_tm_nam_terr_defn.start_date_active%TYPE   DEFAULT SYSDATE
           ,p_from_resource_id         IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_to_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_from_role_id             IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_to_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_from_group_id            IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_to_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_commit                   IN  BOOLEAN DEFAULT TRUE
           ,x_error_code               OUT NOCOPY VARCHAR2
           ,x_error_message            OUT NOCOPY VARCHAR2
         )
AS

  lc_message                           VARCHAR2(240)   ;
  lc_eligible_flag                     VARCHAR2(1)     ;
  lc_update_success                    VARCHAR2(1)     ;
  lc_insert_success                    VARCHAR2(1)     ;
  lc_proceed                           VARCHAR2(1)     ;
  ln_count                             PLS_INTEGER := 0;
  lc_error_code                        VARCHAR2(1)     ;
  lc_error_message                     VARCHAR2(4000)  ;

  ln_named_terr_rsc_id                 xx_tm_nam_terr_rsc_dtls.named_acct_terr_rsc_id%TYPE;
  ln_from_named_acct_terr_id           xx_tm_nam_terr_defn.named_acct_terr_id%TYPE     ;
  ld_from_start_date_active            xx_tm_nam_terr_defn.start_date_active%TYPE      ;
  ln_from_resource_id                  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE        ;
  ln_to_resource_id                    xx_tm_nam_terr_rsc_dtls.resource_id%TYPE        ;
  ln_from_role_id                      xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE   ;
  ln_to_role_id                        xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE   ;
  ln_from_group_id                     xx_tm_nam_terr_rsc_dtls.group_id%TYPE           ;
  ln_to_group_id                       xx_tm_nam_terr_rsc_dtls.group_id%TYPE           ;
  lc_status                            xx_tm_nam_terr_rsc_dtls.status%TYPE             ;
  ld_end_date_active                   xx_tm_nam_terr_rsc_dtls.end_date_active%TYPE    ;


  ln_api_version_number                CONSTANT PLS_INTEGER  := 1.0                          ;
  lc_api_name                          CONSTANT VARCHAR2(30) := 'Named_Account_Territory_Pub';

  EX_INVALID_FROM_TERR_ID              EXCEPTION;
  EX_TERR_RES_NOT_EXISTS               EXCEPTION;
  EX_INVALID_API_VERSION               EXCEPTION;
  EX_FROM_START_DATE_NULL              EXCEPTION;
  EX_INVALID_STATUS                    EXCEPTION;

BEGIN

    -- Standard call to check for call compatibility.
    IF NOT FND_API.COMPATIBLE_API_CALL
             (
              ln_api_version_number,
              p_api_version_number,
              lc_api_name,
              'XX_JTF_RS_NAMED_ACC_TERR_PUB'
             )
    THEN
       RAISE EX_INVALID_API_VERSION;
    END IF;

    --Assigning the parameters into local variables
    ln_from_named_acct_terr_id    := p_from_named_acct_terr_id ;
    ld_from_start_date_active     := p_from_start_date_active  ;
    IF ld_from_start_date_active IS NULL THEN
       ld_from_start_date_active := SYSDATE;
    END IF;


    ln_from_resource_id           := p_from_resource_id        ;
    ln_to_resource_id             := p_to_resource_id          ;
    ln_from_role_id               := p_from_role_id            ;
    ln_to_role_id                 := p_to_role_id              ;
    ln_from_group_id              := p_from_group_id           ;
    ln_to_group_id                := p_to_group_id             ;
    lc_eligible_flag              := NULL                      ;
    lc_proceed                    := NULL                      ;
    lc_proceed                    := 'Y';

    --Validating from start date
    IF ld_from_start_date_active IS NULL THEN
       --RAISE EX_FROM_START_DATE_NULL;
       lc_proceed        := 'N';
       x_error_code      := 'E';
       lc_error_message  := 'From Start Date Active is NULL.';
       x_error_message   := lc_error_message ;
    END IF;

     --Validating named account territory id
    ln_count := 0;
    SELECT COUNT(1)
    INTO   ln_count
    FROM   xx_tm_nam_terr_defn
    WHERE  named_acct_terr_id   =  ln_from_named_acct_terr_id
    AND    NVL(status,'A')      = 'A'
    AND    ld_from_start_date_active BETWEEN NVL(start_date_active,SYSDATE)
                                            AND     NVL(end_date_active,(SYSDATE)+1/12);
    IF ln_count = 0 THEN
       --RAISE EX_INVALID_FROM_TERR_ID;
       lc_proceed        := 'N';
       lc_error_code     := 'E';
       x_error_code      := lc_error_code;
       lc_error_message  := 'Invalid From Territory Id.';
       x_error_message   := x_error_message||CHR(13)||lc_error_message ;
    END IF;
    lc_error_message     := NULL;
    --Performing validations on the From Resource Id , Role Id, Group id
    --Validating From Terr Id and From Res / Role / Grp Combination
-- Defect 7027 Block introduced by Mohan 9/13/2010
    CASE
    WHEN lc_proceed = 'N' THEN
      lc_eligible_flag := 'N';
    WHEN ln_from_named_acct_terr_id IS NULL THEN
       IF ln_from_resource_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Resource Id is required As From Territory Id is passed as NULL.';
       ELSIF ln_from_role_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Role Id is required As From Territory Id is passed as NULL.';
       ELSIF ln_from_group_id IS NULL THEN
            lc_proceed            := 'N';
            lc_error_message := lc_error_message||CHR(13)||'From Group Id is required As From Territory Id is passed as NULL.';
       ELSE
           --Performing validations on the From Resource Id , Role Id, Group id
           Validate_terr_resource
                                (
                                   p_resource_id             => ln_from_resource_id
                                  ,p_resource_role_id        => ln_from_role_id
                                  ,p_group_id                => ln_from_group_id
                                  ,p_allow_inactive_resource => 'N'
                                  ,x_eligible_flag           => lc_eligible_flag
                                  ,x_error_code              => lc_error_code
                                  ,x_error_message           => lc_error_message
                                 );

           IF lc_eligible_flag  <> 'Y' THEN
              lc_proceed        := 'N';
              lc_error_message   := lc_error_message||CHR(13)||lc_error_message ;
           END IF;

           IF  lc_proceed = 'Y' THEN
               --Obtain the existing terrtitory for the resource/role/group combination
               BEGIN
                 SELECT TERR.named_acct_terr_id
                 INTO   ln_from_named_acct_terr_id
                 FROM   xx_tm_nam_terr_rsc_dtls     RES
                       ,xx_tm_nam_terr_defn         TERR
                 WHERE  RES.resource_id        = ln_from_resource_id
                 AND    RES.resource_role_id   = ln_from_role_id
                 AND    RES.group_id           = ln_from_group_id
                 AND    NVL(RES.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(RES.start_date_active,SYSDATE-1)
                                                  AND       NVL(RES.end_date_active,(SYSDATE)+1)
                 AND    TERR.named_acct_terr_id = RES.named_acct_terr_id
                 AND    NVL(TERR.status,'A')    = 'A'
                 AND    ld_from_start_date_active BETWEEN   NVL(TERR.start_date_active,SYSDATE-1)
                                                  AND       NVL(TERR.end_date_active,(SYSDATE)+1)
                 ;
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   lc_proceed            := 'N';
                   lc_error_message := lc_error_message||CHR(13)||'No active territory assigned to the From Resource / Role / Groups combination.';
                 WHEN OTHERS THEN
                   lc_proceed            := 'N';
                   lc_error_message := lc_error_message||CHR(13)||'Unexpected Error: Deriving the From Terr for the From Res/Role/Grp Combination.';
               END;
           END IF;

       END IF;
    ELSE
        lc_eligible_flag := 'Y';
    END CASE;  --End of CASE statement
-- New block ends Defect 7027 - Mohan
    IF lc_eligible_flag  <> 'Y' THEN
       lc_proceed        := 'N';
       x_error_code      := NVL(lc_error_code,'E');
       x_error_message   := x_error_message||CHR(13)||lc_error_message ;
    END IF;

    ln_count             := 0;
    lc_error_message     := NULL;
    SELECT COUNT(1)
    INTO   ln_count
    FROM   xx_tm_nam_terr_rsc_dtls
    WHERE  named_acct_terr_id = ln_from_named_acct_terr_id
    AND    resource_id        = ln_from_resource_id
    AND    resource_role_id   = ln_from_role_id
    AND    group_id           = ln_from_group_id
    AND    NVL(status,'A')    = 'A'
    AND    ld_from_start_date_active BETWEEN NVL(start_date_active,SYSDATE)
                                              AND     NVL(end_date_active,(SYSDATE)+1/12);
    IF ln_count = 0 THEN
       --RAISE EX_TERR_RES_NOT_EXISTS;
       lc_proceed        := 'N';
       x_error_code      := 'E';
       lc_error_message  := 'From Resource Id / From Role Id / From Group Id does not exists in Custom Autonamed Territory Resource Table' ;
       x_error_message   := x_error_message||CHR(13)||lc_error_message ;
    END IF;


    lc_eligible_flag     := NULL;
    lc_error_message     := NULL;
    --Performing validations on the To Resource Id , Role Id, Group id
    Validate_terr_resource
                           (
                             p_resource_id             => ln_to_resource_id
                            ,p_resource_role_id        => ln_to_role_id
                            ,p_group_id                => ln_to_group_id
                            ,p_allow_inactive_resource => 'N'
                            ,x_eligible_flag           => lc_eligible_flag
                            ,x_error_code              => lc_error_code
                            ,x_error_message           => lc_error_message
                            );

    IF lc_eligible_flag  <> 'Y' THEN
       lc_proceed        := 'N';
       x_error_code      := NVL(lc_error_code,'E');
       x_error_message   := x_error_message||CHR(13)||lc_error_message ;
    END IF;


    IF lc_proceed  = 'Y' THEN

        --End Date from resource record

        IF ld_from_start_date_active <= SYSDATE THEN
         lc_status := 'I';
        END IF;

        Update_Terr_Resource
             (
              p_named_acct_terr_id      => ln_from_named_acct_terr_id,
              p_end_date_active         => ld_from_start_date_active ,
              p_status                  => lc_status                 ,
              p_from_resource_id        => ln_from_resource_id       ,
              p_from_role_id            => ln_from_role_id           ,
              p_from_group_id           => ln_from_group_id          ,
              x_update_success          => lc_update_success         ,
              x_error_code              => x_error_code              ,
              x_error_message           => x_error_message
             );

        --Call the internal procedure to populate XX_TM_NAM_TERR_RSC_DTLS
        IF lc_update_success = 'Y' THEN

          --If the Role of the Resource is not DSM then update the name of the old territory
          --with the resource name of the new resource.
          Update_Non_Dsm_Terr_Name
                                 (
                                  p_named_acct_terr_id      => ln_from_named_acct_terr_id,
                                  p_resource_id             => ln_to_resource_id,
                                  p_role_id                 => ln_to_role_id,
                                  x_error_code              => x_error_code,
                                  x_error_message           => x_error_message
                                 );

          lc_insert_success := NULL;

          SELECT XXCRM.xx_tm_nam_terr_rsc_dtls_s.NEXTVAL
          INTO   ln_named_terr_rsc_id
          FROM   DUAL;

          IF lc_status IS NOT NULL THEN
             IF lc_status NOT IN ('A','I') THEN
                RAISE EX_INVALID_STATUS;
             END IF;
          END IF;

          --If the assignment is future dated then current record should be Inactivated
          IF ld_from_start_date_active > SYSDATE THEN
           lc_status := 'I';
          ELSE
           lc_status := 'A';
          END IF;

          lc_insert_success := NULL;
          Insert_terr_resource
              (
               p_named_acct_terr_rsc_id => ln_named_terr_rsc_id,
               p_named_acct_terr_id     => ln_from_named_acct_terr_id,
               p_resource_id            => ln_to_resource_id,
               p_resource_role_id       => ln_to_role_id,
               p_group_id               => ln_to_group_id,
               p_status                 => lc_status,
               p_start_date_active      => ld_from_start_date_active,
               p_end_date_active        => ld_end_date_active  ,
               p_set_extracted_status   => 'N',
               x_insert_success         => lc_insert_success   ,
               x_error_code             => x_error_code        ,
               x_error_message          => x_error_message
            );

        END IF;

    END IF;

    IF lc_insert_success = 'Y' THEN
       x_error_code      := 'S';
       x_error_message   := 'Record Updated / Created successfully';
       IF p_commit THEN
         COMMIT;
       END IF;
    END IF;

EXCEPTION
WHEN EX_INVALID_API_VERSION THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0103_INVALID_API_VER');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  'Move_Resource_Territories'
                   ,p_error_message_code =>  'XX_TM_0103_INVALID_API_VER'
                   ,p_error_msg          =>  lc_message
                  );

    --RAISE;
WHEN EX_INVALID_STATUS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0183_INVALID_STATUS');
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  'Move_Resource_Territories'
                   ,p_error_message_code =>  'XX_TM_0183_INVALID_STATUS'
                   ,p_error_msg          =>  lc_message
                  );
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Move_Resource_Territories');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message        := FND_MESSAGE.GET;
    x_error_code      := 'E';
    x_error_message   := lc_message;

    Log_Exception ( p_error_location     =>  'Move_Resource_Territories'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Move_Resource_Territories;

-- +================================================================================+
-- | Name        :  Synchronize_Status_Flag                                         |
-- | Description :  This procedure is used to synchronize the status of the records |
-- |                in the custom territory resource assignment and territory entity|
-- |                records based on the start date active and end date active.     |
-- +================================================================================+

PROCEDURE Synchronize_Status_Flag
     (
      x_errbuf       OUT   VARCHAR2
     ,x_retcode      OUT   NUMBER
     )
IS

  lc_message         VARCHAR2(240)   ;

BEGIN

     --Updating the status field of the custom territory resource table
     --to 'Active' / 'Inactive'

     UPDATE xx_tm_nam_terr_rsc_dtls
     SET    status                  = 'I'
           ,last_updated_by         = G_LAST_UPDATED_BY
           ,last_update_date        = SYSDATE
           ,last_update_login       = G_LAST_UPDATE_LOGIN
           ,request_id              = G_REQUEST_ID
           ,program_application_id  = G_PROG_APPL_ID
     WHERE  end_date_active <= SYSDATE
     AND    end_date_active IS NOT NULL
     AND    status         = 'A';


     UPDATE xx_tm_nam_terr_rsc_dtls
     SET    status = 'A'
           ,last_updated_by         = G_LAST_UPDATED_BY
           ,last_update_date        = SYSDATE
           ,last_update_login       = G_LAST_UPDATE_LOGIN
           ,request_id              = G_REQUEST_ID
           ,program_application_id  = G_PROG_APPL_ID
     WHERE  start_date_active <= SYSDATE
     AND    end_date_active IS NULL
     AND    status         = 'I';

     --Updating the status field of the custom territory entity table
     --to 'Active' / 'Inactive'

     UPDATE xx_tm_nam_terr_entity_dtls
     SET    status = 'I'
           ,last_updated_by         = G_LAST_UPDATED_BY
           ,last_update_date        = SYSDATE
           ,last_update_login       = G_LAST_UPDATE_LOGIN
           ,request_id              = G_REQUEST_ID
           ,program_application_id  = G_PROG_APPL_ID
     WHERE  end_date_active <= SYSDATE
     AND    end_date_active IS NOT NULL
     AND    status         = 'A';

     UPDATE xx_tm_nam_terr_entity_dtls
     SET    status = 'A'
           ,last_updated_by         = G_LAST_UPDATED_BY
           ,last_update_date        = SYSDATE
           ,last_update_login       = G_LAST_UPDATE_LOGIN
           ,request_id              = G_REQUEST_ID
           ,program_application_id  = G_PROG_APPL_ID
     WHERE  start_date_active <= SYSDATE
     AND    end_date_active IS NULL
     AND    status         = 'I';

EXCEPTION
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', 'Synchronize_Status_Flag');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_message        := FND_MESSAGE.GET;
    x_retcode         := 2;

    FND_FILE.PUT_LINE(FND_FILE.log,'l_error_message  =>'||lc_message);

    Log_Exception ( p_error_location     =>  'Synchronize_Status_Flag'
                   ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                   ,p_error_msg          =>  lc_message
                  );
    --RAISE;
END Synchronize_Status_Flag;

END XX_JTF_RS_NAMED_ACC_TERR_PUB;
/

SHOW ERRORS
--EXIT;

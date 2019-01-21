SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_GP_REL_PKG.pks                                                        |
-- | Description : GP Relationship                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-Jun-2011     Indra Varada        Initial version                             |
-- +============================================================================================+

create or replace
PACKAGE XX_CDH_GP_REL_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  
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
);


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
);

PROCEDURE update_rel_processed (
    x_ret_status            OUT NOCOPY     VARCHAR2,
    x_m_data                OUT NOCOPY     VARCHAR2
);


END XX_CDH_GP_REL_PKG;
/
SHOW ERRORS;

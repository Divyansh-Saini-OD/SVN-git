create or replace 
PACKAGE xxod_ar_sfa_hierarchy_pkg AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_SALESREP_GROUP_ID                         |
-- | RICE ID          :  R0505,R0506 and R0507                         |
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

   FUNCTION get_salesrep_group_id(p_entity_id IN NUMBER)
   RETURN NUMBER;

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
RETURN NUMBER;
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
   RETURN VARCHAR2;
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
   RETURN VARCHAR2;
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
   RETURN VARCHAR2;
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
   RETURN VARCHAR2;

FUNCTION OPEN_TRX_OF_CHILD_FN(P_PARENT_ID IN NUMBER,P_CURRENCY_CODE IN VARCHAR2,P_ORG_ID IN NUMBER,P_CREDITLIMIT IN NUMBER) 
   RETURN NUMBER; -- ADDED FOR DEFECT#31519

FUNCTION PARENT_BALANCE_FN(P_PARENT_ID IN NUMBER,P_CURRENCY_CODE IN VARCHAR2,P_ORG_ID IN NUMBER) RETURN NUMBER; -- ADDED FOR DEFECT#31519

END xxod_ar_sfa_hierarchy_pkg;
/
SHOW ERROR
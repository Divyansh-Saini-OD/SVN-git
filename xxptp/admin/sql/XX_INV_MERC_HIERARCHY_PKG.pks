SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_MERC_HIERARCHY_PKG AUTHID CURRENT_USER
AS 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +===================================================================================+
-- | Name       : XX_INV_MERC_HIERARCHY_PKG                                            |
-- | Description: Declares the procedure PROCESS_MERC_HIERARCHY.This Procedure will be |
-- |              called from the BPEL Proces 'LoadMercHierarchyInProcess', to ADD,    |
-- |              MODIFY or DELETE Value Set Values.                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |==============                                                                     |
-- |Version   Date         Author           Remarks                                    |
-- |=======   ==========   ===============  ===========================================|
-- |DRAFT 1A  14-MAR-2007  Siddharth Singh  Initial draft version.                     |
-- |DRAFT 1B  04-JUN-2007  Siddharth Singh  Incorporated Peer Review Comments.         |
-- |DRAFT 1C  12-JUN-2007  Jayshree kale    Reviewed and Updated                       |
-- |DRAFT 1D  26-JUN-2007  Siddharth Singh  Added global variables for                 |
-- |                                        OD_GLOBAL_PO_UNSPSC and OD_GLOBAL_PO_TYPE  |
-- |                                        Value set names.                           | 
-- |1.0       11-JUL-2007  Jayshree         Baselined                                  |
-- +===================================================================================+

gc_class_vs_name         CONSTANT     VARCHAR2(100)  := 'XX_GI_CLASS_VS';
gc_dept_vs_name          CONSTANT     VARCHAR2(100)  := 'XX_GI_DEPARTMENT_VS';
gc_div_vs_name           CONSTANT     VARCHAR2(100)  := 'XX_GI_DIVISION_VS';
gc_group_vs_name         CONSTANT     VARCHAR2(100)  := 'XX_GI_GROUP_VS';
gc_potype_vs_name        CONSTANT     VARCHAR2(100)  := 'OD_GLOBAL_PO_TYPE';
gc_subclass_vs_name      CONSTANT     VARCHAR2(100)  := 'XX_GI_SUBCLASS_VS';
gc_structure_code        CONSTANT     VARCHAR2(30)   := 'ITEM_CATEGORIES';
gc_structure_code_po     CONSTANT     VARCHAR2(30)   := 'PO_ITEM_CATEGORY';
gc_unspsc_vs_name        CONSTANT     VARCHAR2(100)  := 'OD_GLOBAL_PO_UNSPSC';

PROCEDURE PROCESS_MERC_HIERARCHY(p_hierarchy_level                    IN   VARCHAR2     
                                ,p_value                              IN   NUMBER       
                                ,p_description                        IN   VARCHAR2
                                ,p_action                             IN   VARCHAR2
                                ,p_division_number                    IN   VARCHAR2
                                ,p_group_number                       IN   VARCHAR2
                                ,p_dept_number                        IN   VARCHAR2
                                ,p_class_number                       IN   VARCHAR2
                                ,p_dept_forecastingind                IN   VARCHAR2
                                ,p_dept_aipfilterind                  IN   VARCHAR2  DEFAULT NULL
                                ,p_dept_planningind                   IN   VARCHAR2
                                ,p_dept_noncodeind                    IN   VARCHAR2
                                ,p_dept_ppp_ind                       IN   VARCHAR2
                                ,p_class_nbrdaysamd                   IN   NUMBER
                                ,p_class_fifthmrkdwnprocsscd          IN   VARCHAR2
                                ,p_class_prczcostflg                  IN   VARCHAR2
                                ,p_class_prczpriceflag                IN   VARCHAR2
                                ,p_class_priczlistflag                IN   VARCHAR2
                                ,p_class_furnitureflag                IN   VARCHAR2
                                ,p_class_aipfilterind                 IN   VARCHAR2  DEFAULT NULL
                                ,p_subclass_defaulttaxcat             IN   VARCHAR2
                                ,p_subclass_globalcontentind          IN   VARCHAR2
                                ,p_subclass_aipfilterind              IN   VARCHAR2  DEFAULT NULL
                                ,p_subclass_ppp_ind                   IN   VARCHAR2
                                ,x_error_msg                          OUT  VARCHAR2
                                ,x_error_code                         OUT  NUMBER  
                                );


END XX_INV_MERC_HIERARCHY_PKG;
/
SHOW ERRORS;

EXIT;
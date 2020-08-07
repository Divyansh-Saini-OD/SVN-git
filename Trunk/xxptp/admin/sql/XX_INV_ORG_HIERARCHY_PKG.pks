SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
   
  CREATE OR REPLACE PACKAGE XX_INV_ORG_HIERARCHY_PKG AUTHID CURRENT_USER
    -- +===================================================================================== +
    -- |                  Office Depot - Project Simplify                                     |
    -- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                         |
    -- +===================================================================================== +
    -- |                                                                                      |
    -- | Name             :  XX_INV_ORG_HIERARCHY_PKG                                         |
    -- | Description      :  This package will contain the procedures to validate the         |
    -- |                     Organization hierarchy data in the XML message and to load the   |
    -- |                     validated data in Oracle                                         |
    -- |                     EBS using Standard API(FND_FLEX_LOADER_APIS.UP_VSET_VALUE)       |
    -- |                                                                                      |
    -- | This package contains the following sub programs:                                    |
    -- | =================================================                                    |
    -- |Type         Name                  Description                                        |
    -- |=========    ===========           ================================================   |
    -- |PROCEDURE    PROCESS_ORG_HIERARCHY This Procedure will be used to create the          |
    -- |                                   Organization Hierarchy values in EBS.              |
    -- |                                                                                      |
    -- |Change Record:                                                                        |
    -- |===============                                                                       |
    -- |Version   Date         Author           Remarks                                       |
    -- |=======   ==========   =============    ============================================= |
    -- |Draft 1a  09-APR-2007  Gowri Nagarajan  Initial draft version                         | 
    -- |Draft 1b  11-May-2007  Gowri Nagarajan  Updated value set names as per updated MD.050 |           
    -- |Draft 1c  11-Jun-2007  Gowri Nagarajan  Incorporated peer review comments             |
    -- |Draft 1d  12-Jun-2007  Jayshree Kale    Reviewed and Updated                          |
    -- |1.0       13-Jul-2007  Jayshree Kale    Baselined                                     |
    -- +===================================================================================== +

    AS
    
      -- ---------------------------
      -- Global Variable Declaration
      -- ---------------------------
         
      gn_value_set_id           fnd_flex_value_sets.flex_value_set_id%TYPE := NULL;      
      gn_area_value_set_id      fnd_flex_value_sets.flex_value_set_id%TYPE := NULL;
      gn_region_value_set_id    fnd_flex_value_sets.flex_value_set_id%TYPE := NULL;
      gn_district_value_set_id  fnd_flex_value_sets.flex_value_set_id%TYPE := NULL;  
      
      
      PROCEDURE PROCESS_ORG_HIERARCHY
                                   (
                                     p_hierarchy_level  IN  VARCHAR2
                                   , p_value            IN  NUMBER
                                   , p_description      IN  VARCHAR2
                                   , p_action           IN  VARCHAR2
                                   , p_chain_number     IN  NUMBER
                                   , p_area_number      IN  NUMBER
                                   , p_region_number    IN  NUMBER                                   
                                   , x_message_code     OUT NUMBER
                                   , x_message_data     OUT VARCHAR2
                                   );

    END  XX_INV_ORG_HIERARCHY_PKG;
/
SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
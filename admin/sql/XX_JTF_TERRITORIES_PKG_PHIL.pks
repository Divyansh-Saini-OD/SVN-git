SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XX_JTF_TERRITORIES_PKG_PHIL AUTHID CURRENT_USER AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                Oracle NAIO Consulting Organization                 |
-- +====================================================================+
-- | Name        :  XX_JTF_TERRITORIES_PKG.pks                          |
-- |                                                                    |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                    |
-- | Description :  Import Territories from staging table into          |
-- |                Oracle Territory Manager                            |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version     Date          Author              Remarks               |
-- |========  =========== ==================  ==========================|
-- |DRAFT 1a  18-Sep-2007  Sathya Prabha Rani  Initial draft version    |
-- +====================================================================+


-- ==================================================================================
-- Global Variables
-- ==================================================================================

    gn_success_records               NUMBER := 0;
    gn_error_records                 NUMBER := 0;
    
    gc_class_lookup_type             VARCHAR2(40) := 'XX_TM_TERR_CLASSIFICATION';
    gc_source_lookup_type            VARCHAR2(40) := 'XX_TM_SOURCE_SYSTEMS';
    gc_bl_lookup_type                VARCHAR2(40) := 'XX_TM_BUSINESS_LINE';
    gc_sales_rep_lookup_type         VARCHAR2(40) := 'XX_TM_SALESREP_TYPE';
    gc_vmc_lookup_type               VARCHAR2(40) := 'XX_TM_VERTICAL_MARKET_CODE';
    gc_terralign_qual_lookup_type    VARCHAR2(40) := 'XX_TM_TERRALIGN_QUALS';
    
    
--+=====================================================================+
--|Procedure  :  Import_Territories_Proc                                |
--|                                                                     |
--|Description:  This procedure will invoke the procedures              |
--|              in a pre determined order.                             |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_errbuf             -  Output from the Procedure      |
--|              x_retcode            -  Output from the Procedure      |
--|              p_region_name        -  Region under which the         |
--|                                      territories need to be set up  |
--+=====================================================================+
  
  PROCEDURE Import_Territories_Proc
   (  x_errbuf                 OUT NOCOPY  VARCHAR2,
      x_retcode                OUT NOCOPY  NUMBER,
      p_region_name            IN          VARCHAR2,
      p_commit_flag            in  varchar2  default 'Y', 
      p_debug_level            in  number    default 0
   );
 
--+=====================================================================+
--|Procedure  :  Validate_Terr_Data_Proc                                |
--|                                                                     |
--|Description:  This procedure will validate the staging table for a   |
--|              particular record all the required values are present. |
--|              If yes then that record is processed otherwise no.     |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_validate_flag      -  Output from the Procedure      |
--|              p_record_id          -  Input Record Id                |
--+=====================================================================+
  
  PROCEDURE Validate_Terr_Data_Proc
   (  x_validate_flag          OUT NOCOPY  VARCHAR2,
      p_record_id               IN         NUMBER 
   );
   
 
--+=====================================================================+
--|Function   :  Get_Parent_Terr_Func                                   |
--|                                                                     |
--|Description:  This function will retrieve the parent territory for a |
--|              record in the staging table.                           |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id          -  Input Record Id                |
--|              p_country_code       -  Input Country Code             |
--|              p_terr_classification - Input Terr Classification      |
--|              x_terr_id            -  Output Parent Territory ID     |
--+=====================================================================+
    
  FUNCTION Get_Parent_Terr_Func 
     ( x_terr_id                 OUT NOCOPY  NUMBER,
       p_record_id               IN          NUMBER,
       p_country_code            IN          VARCHAR2,
       p_terr_classification     IN          VARCHAR2
     ) 
     RETURN NUMBER;
  
  
 --+=====================================================================+
 --|Procedure  :  Create_Territory_Proc                                  |
 --|                                                                     |
 --|Description:  This procedure will retrieve the data from the staging |
 --|              table for a particular record and create the record    |
 --|              in the oracle database tables.                         |
 --|                                                                     |
 --|                                                                     |
 --|Parameters :  p_record_id          -  Input Record Id                |
 --|                                                                     |
 --+=====================================================================+
   
  PROCEDURE Create_Territory_Proc
    (   p_record_id               IN  NUMBER
    );
  
  
--+=====================================================================+
--|Procedure  :  Update_Territory_Proc                                  |
--|                                                                     |
--|Description:  This procedure will retrieve the data from the staging |
--|              table for a particular record and update the record    |
--|              in the oracle database tables.                         |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id              - Input Record Id             |
--|              p_exist_terr_id          - Existing territory ID       |
--|              p_exist_parent_terr_id   - Existing Parent territory ID|
--+=====================================================================+
     
  PROCEDURE Update_Territory_Proc
      (    p_record_id               IN  NUMBER,
           p_exist_terr_id           IN  NUMBER,
           p_exist_parent_terr_id    IN  NUMBER
      );
 
 
--+=====================================================================+
--|Procedure  :  Inferred_Deletion_Proc                                 |
--|                                                                     |
--|Description:  This procedure will loop through all the territories   |
--|              under a parent and delete the postal codes that will be|
--|              created again.                                         |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id              - Input Record Id             |
--|              p_exist_parent_terr_id   - Existing Parent territory ID|
--|                                                                     |
--+=====================================================================+
      
  PROCEDURE Inferred_Deletion_Proc
       (    p_exist_parent_terr_id    IN  NUMBER,
            p_record_id               IN  NUMBER
       );
      
      
--+=====================================================================+
--|Procedure  :  Update_Attribute_Proc                                  |
--|                                                                     |
--|Description:  This procedure will update the attribute value         |
--|              (either Division or Sales Rep Level) for territories.  |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_errbuf             -  Output from the Procedure      |
--|              x_retcode            -  Output from the Procedure      |
--|              p_attr_name          -  Attribute name can be either   |
--|                                      'Business Line' or             |
--|                                      'Sales Rep Level' or           |
--|                                      'Vertical Market Code'         |
--|              p_attr_val           -  Input Attribute Value          |
--|              p_terr_id1           -  Input Territory name           |
--|              p_terr_id2           -  Input Territory name           |
--|              p_terr_id3           -  Input Territory name           |
--|              p_terr_id4           -  Input Territory name           |
--|              p_terr_id5           -  Input Territory name           |
--|              p_terr_id6           -  Input Territory name           |
--|              p_terr_id7           -  Input Territory name           |
--|              p_terr_id8           -  Input Territory name           |
--|              p_terr_id9           -  Input Territory name           |
--|              p_terr_id10          -  Input Territory name           |
--+=====================================================================+
  
  PROCEDURE Update_Attribute_Proc
   (  x_errbuf                 OUT NOCOPY   VARCHAR2,
      x_retcode                OUT NOCOPY   NUMBER,
      p_attr_name              IN           VARCHAR2,
      p_attr_val               IN           VARCHAR2,
      p_terr_id1               IN           NUMBER,
      p_terr_id2               IN           NUMBER,
      p_terr_id3               IN           NUMBER,
      p_terr_id4               IN           NUMBER,
      p_terr_id5               IN           NUMBER,
      p_terr_id6               IN           NUMBER,
      p_terr_id7               IN           NUMBER,
      p_terr_id8               IN           NUMBER,
      p_terr_id9               IN           NUMBER,
      p_terr_id10              IN           NUMBER
   );
  
    
END XX_JTF_TERRITORIES_PKG_PHIL;
/
SHOW ERRORS;



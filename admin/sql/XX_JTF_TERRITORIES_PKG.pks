SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XX_JTF_TERRITORIES_PKG AUTHID CURRENT_USER AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                Oracle NAIO Consulting Organization                       |
-- +==========================================================================+
-- | Name        :  XX_JTF_TERRITORIES_PKG.pks                                |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- | Description :  Import Territories from staging table into                |
-- |                Oracle Territory Manager                                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version     Date          Author              Remarks                     |
-- |========  =========== ==================  ================================+
-- |DRAFT 1a  18-Sep-2007  Sathya Prabha Rani  Initial draft version          |
-- |1.1       24-Jul-2009  Phil Price          Moved globals to .pkb.         |
-- |                                           Removed unused procedure specs.|
-- |                                           Added Remove_Error_Records.    |
-- +==========================================================================+


--+===========================================================================+
--|Procedure  :  Import_Territories_Proc                                      |
--|                                                                           |
--|Description:  This procedure will invoke the procedures                    |
--|              in a pre determined order.                                   |
--|                                                                           |
--|                                                                           |
--|Parameters :  x_errbuf             -  Output from the Procedure            |
--|              x_retcode            -  Output from the Procedure            |
--|              p_region_name        -  Region under which the               |
--|                                      territories need to be set up        |
--|              p_debug_level        - 0 = no debug, 3 = max debug messages  |
--|              p_commit_flag        - Y = commit / rollback when upon exit  |
--+===========================================================================+
  
PROCEDURE Import_Territories_Proc
   (  x_errbuf                 OUT NOCOPY  VARCHAR2,
      x_retcode                OUT NOCOPY  NUMBER,
      p_region_name            IN          VARCHAR2,
      p_debug_level            in  number    default  0,  -- 0 = none, 1 = low, 2 = med, 3 = hi
      p_commit_flag            in  varchar2  default 'Y'
   );


--+===========================================================================+
--|Procedure  :  Delete_Interface_Errors                                      |
--|                                                                           |
--|Description:  Deletes certain records in xx_jtf_terr_qualifiers_int and    |
--|              xx_jtf_territories_int.  See package body for details.       |
--|                                                                           |
--|Parameters :  x_errbuf             - Output from the Procedure             |
--|              x_retcode            - Output from the Procedure             |
--|              p_record_id          - If null, process all recs in          |
--|                                     xx_jtf_territories_int.  Otherwise,   |
--|                                     process this record only.             |
--|              p_debug_level        - 0 = no debug, 3 = max debug messages  |
--|              p_commit_flag        - Y = commit / rollback when upon exit  |
--+===========================================================================+
PROCEDURE Delete_Interface_Errors
   (  x_errbuf                 OUT NOCOPY  VARCHAR2,
      x_retcode                OUT NOCOPY  NUMBER,
      p_record_id              IN  NUMBER    default null,
      p_debug_level            IN  NUMBER    default  0,  -- 0 = none, 1 = low, 2 = med, 3 = hi
      p_commit_flag            IN  VARCHAR2  default 'Y'
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
  
    
END XX_JTF_TERRITORIES_PKG;
/
SHOW ERRORS;
--EXIT;


SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_ADD_ATTR_ENT_REG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ADD_ATTR_ENT_REG.pks                        |
-- | Description :  CDH Additional Attributes Registration Package Spec|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  06-Apr-2007 V Jayamohan        Initial draft version     |
-- +===================================================================+
AS
                              
-- +===================================================================+
-- | Name        :  register_entity                                    |
-- | Description :  This procedure is invoked as a concurrent          | 
-- |                request for registering the entities               |
-- |                                                                   |
-- |	                                                               |	                                                       |
-- | Parameters  :						       |
-- |     p_entity_attribute_group_type		IN  VARCHAR2           |
-- |     p_entity_base_table			IN  VARCHAR2           |
-- |     p_entity_base_table_key		IN  VARCHAR2           |
-- |     p_entity_name				IN  VARCHAR2           |
-- |     p_extension_base_table			IN  VARCHAR2           |
-- |     p_extension_tl_table			IN  VARCHAR2           |
-- |     p_extension_vl				IN  VARCHAR2	       |
-- |                                                                   |
-- | Returns     :                                                     |
-- |     x_errbuf				OUT  VARCHAR2          |
-- |     x_retcode				OUT  VARCHAR2          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE register_entity
      (  x_errbuf				OUT VARCHAR2,
         x_retcode				OUT VARCHAR2,
         p_entity_attribute_group_type		IN  VARCHAR2,
         p_entity_base_table			IN  VARCHAR2,
	 p_entity_base_table_key		IN  VARCHAR2,
	 p_entity_name				IN  VARCHAR2,
	 p_extension_base_table			IN  VARCHAR2,
	 p_extension_tl_table			IN  VARCHAR2,
	 p_extension_vl				IN  VARCHAR2
      );
      
END XX_CDH_ADD_ATTR_ENT_REG;
/
SHOW ERRORS;
exit;

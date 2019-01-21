-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_TM_CURR_ASSIGN_LEGCY_RPID_V.vw                  |
-- | Description :  View for Assign Legacy RepID                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       25-Mar-2009   Kalyan    Initial version                  |
-- |                                                                   | 
-- +===================================================================+

CREATE OR REPLACE FORCE VIEW XX_TM_CURR_ASSIGN_LEGCY_RPID_V AS
	select 	 cav.entity_id    ENTITY_ID, 
		 cav.entity_type  ENTITY_TYPE, 
                 cav.resource_id  RESOURCE_ID, 
                 jrr.role_id      ROLE_ID,
                 g.group_id       GROUP_ID,
                 jrr.attribute15  LEGCY_ID 
	from 	 apps.XX_TM_NAM_TERR_CURR_ASSIGN_V cav,
 		 apps.jtf_rs_role_relations jrr,
  		 apps.jtf_rs_group_members g
  	where  g.group_member_id= jrr.role_resource_id
	and 	 jrr.role_resource_type='RS_GROUP_MEMBER'
  	and 	 jrr.role_id= cav.resource_role_id
  	and 	 g.resource_id=cav.resource_id
  	and 	 g.group_id=cav.group_id
  	and 	 sysdate between
 		 jrr.start_date_active and  nvl(jrr.end_date_active,sysdate+1) 
  	and    nvl(jrr.delete_flag,'N')<>'Y'
/
SHOW ERRORS;
EXIT;

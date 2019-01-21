SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_RM_RSC_ACTV_ROLE_PKG package specification'
PROMPT


 CREATE OR REPLACE PACKAGE XX_RM_RSC_ACTV_ROLE_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_RM_RSC_ACTV_ROLE_PKG                                           |
 -- | Description      : This program is for querying and detailing the Luis program.      |
 -- |                                                                                      | 
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  resource details with active sales role.      |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  01-JUL-2008  Satyasrinivas    Initial draft version                         |
 -- +===================================================================================== +

 AS
 
     -- +====================================================================+
     -- | Name        :  display_log                                         |
     -- | Description :  This procedure is invoked to print in the log file  |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+
 
     PROCEDURE display_log(
                           p_message IN VARCHAR2
                          );
    
        -- +====================================================================+
        -- | Name        :  display_out                                         |
        -- | Description :  This procedure is invoked to print in the output    |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+
    
        PROCEDURE display_out(
                              p_message IN VARCHAR2
                             );
	-- -----------------------
	-- Record Type Declaration
	-- -----------------------
	TYPE res_actrol_type IS RECORD
	  (
	   source_name           jtf_rs_resource_extns.source_name%TYPE
	  ,role_name             jtf_rs_role_details_vl.role_name%TYPE
	  ,admin_flag            jtf_rs_role_details_vl.admin_flag%TYPE
          ,manager_flag          jtf_rs_role_details_vl.manager_flag%TYPE
          ,member_flag           jtf_rs_role_details_vl.member_flag%TYPE
	  ,group_name            jtf_rs_groups_vl.group_name%TYPE
	  ,attribute15           jtf_rs_role_relations.attribute15%TYPE
          ,division              jtf_rs_role_details_vl.attribute15%TYPE
          ,attribute14           jtf_rs_role_details_vl.attribute14%TYPE
	  );
                             
   -- -----------------------
   -- Table type declaration
   -- -----------------------

   TYPE actres_tbl_type IS TABLE OF res_actrol_type   INDEX BY BINARY_INTEGER; 

   -- -----------------------
   -- Variable of table type
   -- -----------------------

   ln_res_act_tbl_type   actres_tbl_type;
       
			             
     -- +====================================================================+
     -- | Name        :  Main_Proc                                           |
     -- | Description :  This is the Main Procedure  invoked by the          |
     -- |                Concurrent Program                                  |
     -- |                file                                                |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+

			       
   PROCEDURE Main_Proc (
                      x_errbuf           OUT VARCHAR2
                    , x_retcode          OUT NUMBER       
                    );

END;

/ 

SHOW ERRORS;

EXIT;
SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XX_TM_RM_HIERARCHY_REPORT_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             :  XX_TM_RM_HIERARCHY_REPORT_PKG                                    |
 -- | Description      : This custom package extracts the resource details                 |
 -- |                    from resource manager and prints to a log output file             |
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  resource details                              |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  21-Apr-2008  Gowri Nagarajan  Initial draft version                         |
 -- |Draft 1b  12-Jan-2010  Kishore Jena     Added 3 new RM based reports.                 |
 -- +===================================================================================== +

AS
   -- -----------------------
   -- Record Type Declaration
   -- -----------------------
   TYPE res_rec_type IS RECORD
     (
      sales_rep_name        jtf_rs_resource_extns_vl.resource_name%TYPE
     ,sales_rep_id          jtf_rs_resource_extns_vl.resource_id%TYPE
     ,sales_rep_number      jtf_rs_salesreps.salesrep_number%TYPE
     ,sales_rep_role_name   jtf_rs_roles_tl.role_name%TYPE
     ,sales_rep_attribute14 jtf_rs_roles_b.attribute14%TYPE
     ,sales_rep_group_name  jtf_rs_groups_tl.group_name%TYPE
     ,sales_rep_legacy_id   jtf_rs_role_relations.attribute15%TYPE
     ,manager_name          jtf_rs_resource_extns_vl.resource_name%TYPE
     ,manager_id            jtf_rs_resource_extns_vl.resource_id%TYPE
     ,manager_role_name     jtf_rs_roles_tl.role_name%TYPE
     ,mgr_rep_attribute14   jtf_rs_roles_b.attribute14%TYPE
     ,parent_group_name     jtf_rs_groups_tl.group_name%TYPE
     );

   -- -----------------------
   -- Table type declaration
   -- -----------------------

   TYPE res_tbl_type IS TABLE OF res_rec_type
   INDEX BY BINARY_INTEGER; 

   -- -----------------------
   -- Variable of table type
   -- -----------------------

   ln_res_tbl_type   res_tbl_type;

   PROCEDURE MAIN_PROC
                   (
                     x_errbuf           OUT VARCHAR2
                   , x_retcode          OUT NUMBER
                   , p_resource_id      IN  NUMBER
                   );

   PROCEDURE RM_JOB_ROLE_MAPPING_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   );

   PROCEDURE RM_PRXY_ROLES_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   );

   PROCEDURE RM_RESOURCE_ROLES_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   );


END  XX_TM_RM_HIERARCHY_REPORT_PKG;
/
SHOW ERRORS;

--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================


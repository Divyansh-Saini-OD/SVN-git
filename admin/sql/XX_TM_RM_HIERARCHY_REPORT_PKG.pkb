SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_TM_RM_HIERARCHY_REPORT_PKG package body'
PROMPT


 CREATE OR REPLACE PACKAGE BODY XX_TM_RM_HIERARCHY_REPORT_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_TM_RM_HIERARCHY_REPORT_PKG                                     |
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
 -- |Draft 1b  02-Sep-2008  Gowri Nagarajan  Changed the cursor lcu_get_resource_dtls to   |
 -- |                                        eliminate the duplicate records 		       |
 -- |Draft 1c  12-Jan-2010  Kishore Jena     Added 3 new RM based reports to the package.  |
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
                         )

    IS

    BEGIN

         FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

    END display_log;

    -- +====================================================================+
    -- | Name        :  display_out                                         |
    -- | Description :  This procedure is invoked to print in the output    |
    -- |                file                                                |
    -- |                                                                    |
    -- | Parameters  :  Log Message                                         |
    -- +====================================================================+

    PROCEDURE display_out(
                          p_message IN VARCHAR2
                         )

    IS

    BEGIN

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

    END display_out;

    -- +===================================================================== +
    -- | Name       : MAIN_PROC                                               |
    -- |                                                                      |
    -- | Description: This procedure will be used to extract the resource     |
    -- |              information                                             |
    -- |                                                                      |
    -- | Parameters : p_resource_id   IN  Resource_id                         |
    -- |              x_retcode  OUT Holds '0','1','2'                        |
    -- |              x_errbuf   OUT Holds the error message                  |
    -- +======================================================================+

    PROCEDURE MAIN_PROC
                    (
                      x_errbuf           OUT VARCHAR2
                    , x_retcode          OUT NUMBER
                    , p_resource_id      IN  NUMBER        
                    )
    AS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------
       
       ln_resource_id  jtf_rs_resource_extns_vl.resource_id%TYPE;
       -- -------------------------------------
       -- Get the Resource_id for the person_id
       -- -------------------------------------
       --CURSOR lcu_get_resource_id 
       --IS
       --SELECT resource_id 
      -- FROM   jtf_rs_resource_extns_vl
      -- where  source_id = p_person_id;        
       
       -- ------------------------------------------------------
       -- Get all the records for the given resource_id
       -- ------------------------------------------------------
       CURSOR lc_get_mgr_resource_exists (p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
       is
       SELECT count (jrgt.group_id)
                                              FROM   JTF_RS_RESOURCE_EXTNS jrre,
                                                     jtf_rs_roles_b jrrb,
                                                     jtf_rs_roles_tl jrrt,
                                                     jtf_rs_role_relations jrrr,
                                                     jtf_rs_group_members jrgm,
                                                     jtf_rs_groups_tl jrgt,
                                                     jtf_rs_group_usages jrgu
                                              WHERE  jrrb.role_type_code       ='SALES'
                                              AND    ( jrrb.manager_flag       ='Y' OR jrrb.attribute14='HSE')
                                              AND    jrrt.role_id              = jrrb.role_id
                                              AND    jrrt.language             = userenv('LANG')
                                              AND    NVL(jrrr.delete_flag,'N') = 'N'
                                              AND    jrrr.role_id              = jrrb.role_id
                                              AND    SYSDATE BETWEEN jrrr.start_date_active
                                              AND    NVL(jrrr.end_date_active,SYSDATE)
                                              AND    jrgm.group_member_id      = jrrr.role_resource_id
                                              AND    NVL(jrgm.delete_flag,'N') = 'N'
                                              AND    jrgm.group_id             = jrgt.group_id
                                              AND    jrgu.group_id             = jrgm.group_id
                                              AND    jrgu.usage                ='SALES'
                                              AND    jrgt.language             = userenv('LANG')
                                              AND    jrre.resource_id          = jrgm.resource_id
                                       AND    jrre.resource_id          = p_resource_id;

       CURSOR lcu_get_resource_dtls(p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
       IS
       SELECT   manager.sales_rep_name,
                manager.sales_rep_id,
                manager.sales_rep_number,
                manager.sales_rep_role_name,               
                manager.sales_rep_attribute14,
                manager.sales_rep_group_name,
                manager.sales_rep_legacy_id,
                manager.manager_name,
                manager.manager_id,
                manager.manager_role_name,
                manager.mgr_rep_attribute14
              ,(SELECT   jrgt.group_name
                FROM     jtf_rs_groups_tl jrgt,
                         JTF_RS_GRP_RELATIONS jrgr
                WHERE    jrgt.group_id  = jrgr.related_group_id
                AND      jrgt.LANGUAGE  = userenv('LANG')
                AND      jrgr.group_id  = manager.group_id
                and      nvl(jrgr.delete_flag,'N') = 'N'
                and      sysdate between jrgr.start_date_active and nvl(jrgr.end_date_active,sysdate)
                )                                   parent_group_name
       FROM    (SELECT   sales_jrre.source_name                        sales_rep_name,
                         sales_jrre.resource_id                        sales_rep_id,
                         sales_jrs.salesrep_number                     sales_rep_number,
                         sales_jrrt.role_name                          sales_rep_role_name,
                         sales_jrrb.ATTRIBUTE14                        sales_rep_attribute14,
                         sales_jrgt.GROUP_name                         sales_rep_group_name,
                         sales_jrrr.attribute15                        sales_rep_legacy_id,
                         mgr_jrre.source_name                          manager_name,
                         mgr_jrre.resource_id                          manager_id,
                         mgr_jrrt.role_name                            manager_role_name,
                         mgr_jrrb.ATTRIBUTE14                          mgr_rep_attribute14,
                         mgr_jrgm.group_id                             group_id,
                         sales_jrgm.group_id                           s10
                FROM     jtf_rs_resource_extns                         sales_jrre,
                         jtf_rs_groups_tl                              sales_jrgt,
                         jtf_rs_group_usages                           sales_jrgu,
                         jtf_rs_group_members                          sales_jrgm,
                         jtf_rs_role_relations                         sales_jrrr,
                         jtf_rs_roles_b                                sales_jrrb,
                         jtf_rs_roles_tl                               sales_jrrt,
                         jtf_rs_salesreps                              sales_jrs,
                         jtf_rs_resource_extns                         mgr_jrre,
                         jtf_rs_group_members                          mgr_jrgm,
                         jtf_rs_role_relations                         mgr_jrrr,
                         jtf_rs_roles_b                                mgr_jrrb,
                         jtf_rs_roles_tl                               mgr_jrrt
                WHERE    sales_jrre.resource_id          = sales_jrgm.resource_id
                AND      sales_jrgm.group_id             = sales_jrgt.group_id
                AND      sales_jrgu.group_id             = sales_jrgt.group_id
                AND      sales_jrgu.usage                ='SALES'
                AND      NVL(sales_jrgm.delete_flag,'N') ='N'
                AND      sales_jrrr.role_resource_id     = SALES_jrgm.group_member_id
                AND      sales_jrrr.role_id              = sales_jrrb.role_id
                AND      sales_jrrb.attribute14 NOT IN ( 'OT','HSE')
                AND      sales_jrrb.ROLE_TYPE_CODE       ='SALES'
                AND      SYSDATE BETWEEN sales_jrrr.                   start_date_active
                AND      NVL(sales_jrrr.end_date_active,SYSDATE)
                AND      NVL(sales_jrrr.delete_flag,'N') = 'N'
                AND      sales_jrrb.role_id              = sales_jrrt.role_id
                AND      sales_jrrt.language             = userenv('LANG')
                AND      sales_jrgt.language             = userenv('LANG')
                AND      sales_jrs.resource_id           = sales_jrre.resource_id
                AND      sales_jrs.org_id                = fnd_profile.value('ORG_ID')
                AND      mgr_jrgm.group_id               = sales_jrgt.group_id
                AND      mgr_jrre.resource_id            = mgr_jrgm.resource_id
                AND      mgr_jrrr.role_resource_id       = mgr_jrgm.group_member_id
                AND      mgr_jrrr.role_id                = mgr_jrrb.role_id
                AND      mgr_jrrb.ROLE_TYPE_CODE         ='SALES'
                AND      SYSDATE BETWEEN mgr_jrrr.start_date_active
                AND      NVL(mgr_jrrr.end_date_active,SYSDATE)
                AND      NVL(mgr_jrrr.delete_flag,'N')   = 'N'
                AND      mgr_jrrb.role_id                = mgr_jrrt.role_id
                AND      mgr_jrrb.manager_flag           ='Y'
                AND      mgr_jrrt.language               = userenv('LANG')
                         ORDER BY 2)                                   manager
              -- ,jtf_rs_groups_denorm jrgd -- 02/Sep/08               
              ,(SELECT * 
                FROM   jtf_rs_groups_denorm d1 
                WHERE  sysdate BETWEEN start_date_active AND nvl(end_date_active,sysdate+1))jrgd -- 02/Sep/08
       WHERE    manager.group_id = jrgd.group_id
       AND      jrgd.parent_group_id IN
                                      (SELECT jrgt.group_id
                                       FROM   JTF_RS_RESOURCE_EXTNS jrre,
                                              jtf_rs_roles_b jrrb,
                                              jtf_rs_roles_tl jrrt,
                                              jtf_rs_role_relations jrrr,
                                              jtf_rs_group_members jrgm,
                                              jtf_rs_groups_tl jrgt,
                                              jtf_rs_group_usages jrgu
                                       WHERE  jrrb.role_type_code       ='SALES'
                                       AND    ( jrrb.manager_flag       ='Y' OR jrrb.attribute14='HSE')
                                       AND    jrrt.role_id              = jrrb.role_id
                                       AND    jrrt.language             = userenv('LANG')
                                       AND    NVL(jrrr.delete_flag,'N') = 'N'
                                       AND    jrrr.role_id              = jrrb.role_id
                                       AND    SYSDATE BETWEEN jrrr.start_date_active
                                       AND    NVL(jrrr.end_date_active,SYSDATE)
                                       AND    jrgm.group_member_id      = jrrr.role_resource_id
                                       AND    NVL(jrgm.delete_flag,'N') = 'N'
                                       AND    jrgm.group_id             = jrgt.group_id
                                       AND    jrgu.group_id             = jrgm.group_id
                                       AND    jrgu.usage                ='SALES'
                                       AND    jrgt.language             = userenv('LANG')
                                       AND    jrre.resource_id          = jrgm.resource_id
                                       AND    jrre.resource_id          = p_resource_id)
      ORDER BY sales_rep_group_name;
      
      CURSOR lcu_get_rsc_dtl(p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
      is
            SELECT   manager.sales_rep_name,
                     manager.sales_rep_id,
                     manager.sales_rep_number,
                     manager.sales_rep_role_name,
                     manager.sales_rep_attribute14,
                     manager.sales_rep_group_name,
                     manager.sales_rep_legacy_id,
                     manager.manager_name,
                     manager.manager_id,
                     manager.manager_role_name,
                     manager.mgr_rep_attribute14
                   ,(SELECT   jrgt.group_name
                     FROM     jtf_rs_groups_tl jrgt,
                              JTF_RS_GRP_RELATIONS jrgr
                     WHERE    jrgt.group_id  = jrgr.related_group_id
                     AND      jrgt.LANGUAGE  = userenv('LANG')
                     AND      jrgr.group_id  = manager.group_id
                     and      nvl(jrgr.delete_flag,'N') = 'N'
                     and      sysdate between jrgr.start_date_active and nvl(jrgr.end_date_active,sysdate)
                     )                                   parent_group_name
            FROM    (SELECT   sales_jrre.source_name                        sales_rep_name,
                              sales_jrre.resource_id                        sales_rep_id,
                              sales_jrs.salesrep_number                     sales_rep_number,
                              sales_jrrt.role_name                          sales_rep_role_name,
                              sales_jrrb.ATTRIBUTE14                        sales_rep_attribute14,
                              sales_jrgt.GROUP_name                         sales_rep_group_name,
                              sales_jrrr.attribute15                        sales_rep_legacy_id,
                              mgr_jrre.source_name                          manager_name,
                              mgr_jrre.resource_id                          manager_id,
                              mgr_jrrt.role_name                            manager_role_name,
                              mgr_jrrb.ATTRIBUTE14                          mgr_rep_attribute14,
                              mgr_jrgm.group_id                             group_id,
                              sales_jrgm.group_id                           s10
                     FROM     jtf_rs_resource_extns                         sales_jrre,
                              jtf_rs_groups_tl                              sales_jrgt,
                              jtf_rs_group_usages                           sales_jrgu,
                              jtf_rs_group_members                          sales_jrgm,
                              jtf_rs_role_relations                         sales_jrrr,
                              jtf_rs_roles_b                                sales_jrrb,
                              jtf_rs_roles_tl                               sales_jrrt,
                              jtf_rs_salesreps                              sales_jrs,
                              jtf_rs_resource_extns                         mgr_jrre,
                              jtf_rs_group_members                          mgr_jrgm,
                              jtf_rs_role_relations                         mgr_jrrr,
                              jtf_rs_roles_b                                mgr_jrrb,
                              jtf_rs_roles_tl                               mgr_jrrt
                     WHERE    sales_jrre.resource_id          = sales_jrgm.resource_id
                     AND      sales_jrre.resource_id          = p_resource_id
                     AND      sales_jrgm.group_id             = sales_jrgt.group_id
                     AND      sales_jrgu.group_id             = sales_jrgt.group_id
                     AND      sales_jrgu.usage                ='SALES'
                     AND      NVL(sales_jrgm.delete_flag,'N') ='N'
                     AND      sales_jrrr.role_resource_id     = SALES_jrgm.group_member_id
                     AND      sales_jrrr.role_id              = sales_jrrb.role_id
                     AND      sales_jrrb.ROLE_TYPE_CODE       ='SALES'
                     AND      SYSDATE BETWEEN sales_jrrr.                   start_date_active
                     AND      NVL(sales_jrrr.end_date_active,SYSDATE)
                     AND      NVL(sales_jrrr.delete_flag,'N') = 'N'
                     AND      sales_jrrb.role_id              = sales_jrrt.role_id
                     AND      sales_jrrt.language             = userenv('LANG')
                     AND      sales_jrgt.language             = userenv('LANG')
                     AND      sales_jrs.resource_id           = sales_jrre.resource_id
                     AND      sales_jrs.org_id                = fnd_profile.value('ORG_ID')
                     AND      mgr_jrgm.group_id               = sales_jrgt.group_id
                     AND      mgr_jrre.resource_id            = mgr_jrgm.resource_id
                     AND      mgr_jrrr.role_resource_id       = mgr_jrgm.group_member_id
                     AND      mgr_jrrr.role_id                = mgr_jrrb.role_id
                     AND      mgr_jrrb.ROLE_TYPE_CODE         ='SALES'
                     AND      SYSDATE BETWEEN mgr_jrrr.start_date_active
                     AND      NVL(mgr_jrrr.end_date_active,SYSDATE)
                     AND      NVL(mgr_jrrr.delete_flag,'N')   = 'N'
                     AND      mgr_jrrb.role_id                = mgr_jrrt.role_id
                     AND      mgr_jrrb.manager_flag           ='Y'
                     AND      mgr_jrrt.language               = userenv('LANG')
                         ORDER BY 2)                                   manager;
                         
     CURSOR lcu_get_rsc_nomgr_dtls(p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
     IS
     SELECT   manager.sales_rep_name,
              manager.sales_rep_id,
              manager.sales_rep_number,
              manager.sales_rep_role_name,
              manager.sales_rep_attribute14,
              manager.sales_rep_group_name,
              manager.sales_rep_legacy_id,
              manager.manager_name,
              manager.manager_id,
              manager.manager_role_name,
              manager.mgr_rep_attribute14,
                        null   parent_group_name
                        from
                        (
                        SELECT   sales_jrre.source_name              sales_rep_name,
                       sales_jrre.resource_id                        sales_rep_id,
                       sales_jrs.salesrep_number                     sales_rep_number,
                       sales_jrrt.role_name                          sales_rep_role_name,
                       sales_jrrb.ATTRIBUTE14                        sales_rep_attribute14,
                       sales_jrgt.GROUP_name                         sales_rep_group_name,
                       sales_jrrr.attribute15                        sales_rep_legacy_id,
                       null                          manager_name,
                       null                          manager_id,
                       null                            manager_role_name,
                       null                          mgr_rep_attribute14,
                       null                             group_id, 
                       sales_jrgm.group_id                           s10
              FROM     jtf_rs_resource_extns                         sales_jrre,
                       jtf_rs_groups_tl                              sales_jrgt,
                       jtf_rs_group_usages                           sales_jrgu,
                       jtf_rs_group_members                          sales_jrgm,
                       jtf_rs_role_relations                         sales_jrrr,
                       jtf_rs_roles_b                                sales_jrrb,
                       jtf_rs_roles_tl                               sales_jrrt,
                       jtf_rs_salesreps                              sales_jrs--,
             WHERE    
                       sales_jrre.resource_id          = p_resource_id
              AND      sales_jrre.resource_id          = sales_jrgm.resource_id
              AND      sales_jrgm.group_id             = sales_jrgt.group_id
              AND      sales_jrgu.group_id             = sales_jrgt.group_id
              AND      sales_jrgu.usage                ='SALES'
              AND      NVL(sales_jrgm.delete_flag,'N') ='N'
              AND      sales_jrrr.role_resource_id     = SALES_jrgm.group_member_id
              AND      sales_jrrr.role_id              = sales_jrrb.role_id
              AND      sales_jrrb.ROLE_TYPE_CODE       ='SALES'
              AND      SYSDATE BETWEEN sales_jrrr.                   start_date_active
              AND      NVL(sales_jrrr.end_date_active,SYSDATE)
              AND      NVL(sales_jrrr.delete_flag,'N') = 'N'
              AND      sales_jrrb.role_id              = sales_jrrt.role_id
              AND      sales_jrrt.language             = userenv('LANG')
              AND      sales_jrgt.language             = userenv('LANG')
              AND      sales_jrs.resource_id(+)           = sales_jrre.resource_id
              )manager;
              
              ln_count_rsc_mgr  number:=0;
                                                 
    BEGIN

       x_retcode := 0;

       display_out(RPAD(' SALES REP NAME',50)||chr(9)
                 ||RPAD(' SALES REP ID',20)||chr(9)
                 ||RPAD(' SALES REP NUMBER',30)||chr(9)
                 ||RPAD(' SALES REP ROLE NAME',20)||chr(9)
                 ||RPAD(' SALES LEGACY ID',30)||chr(9)
                 ||RPAD(' SALES REP ROLE CODE',30)||chr(9)
                 ||RPAD(' SALES REP GROUP NAME',60)||chr(9)
                 ||RPAD(' SUPERVISOR NAME',50)||chr(9)
                 ||RPAD(' SUPERVISOR ID',20)||chr(9)
                 ||RPAD(' SUPERVISOR ROLE NAME',20)||chr(9)
                 ||RPAD(' SUPERVISOR ROLE CODE',30)||chr(9)
                 ||RPAD(' PARENT GROUP NAME',60)||chr(9));
                 
      /*display_out(RPAD(' ',50,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',50,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')); */                
 
       
       --OPEN  lcu_get_resource_id;
       --FETCH lcu_get_resource_id INTO ln_resource_id;
       --CLOSE lcu_get_resource_id;
       ln_resource_id := p_resource_id;
       display_log ('ln_resource_id =>'||ln_resource_id );
       begin
       open lc_get_mgr_resource_exists(ln_resource_id);
       fetch lc_get_mgr_resource_exists into ln_count_rsc_mgr;
       close lc_get_mgr_resource_exists;
       exception 
       when others then 
       ln_count_rsc_mgr:=0;
       end;
       display_log ('ln_count_rsc_mgr step 1 =>'||ln_count_rsc_mgr );
       IF ln_count_rsc_mgr > 0 THEN 
       
         ln_res_tbl_type.delete;
         OPEN  lcu_get_resource_dtls(ln_resource_id);
         FETCH lcu_get_resource_dtls BULK COLLECT INTO ln_res_tbl_type;
         CLOSE lcu_get_resource_dtls;    
         IF ln_res_tbl_type.count>0 THEN
              FOR i IN ln_res_tbl_type.FIRST.. ln_res_tbl_type.LAST
                 LOOP
  
                    display_log('Displaying the resource details in the out file');
                 
                    -- ------------------------------------------
                    -- Display the extracted data in the log file
                    -- ------------------------------------------
                    display_out(' '
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_name,'(null)'),50)||chr(9)
                              ||RPAD(NVL(to_char(ln_res_tbl_type(i).sales_rep_id),'(null)'),20)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_number,'(null)'),30)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_role_name,'(null)'),20)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_legacy_id,'(null)'),30)||chr(9)  
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_attribute14,'(null)'),30)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).sales_rep_group_name,'(null)'),60)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).manager_name,'(null)'),50)||chr(9)
                              ||RPAD(NVL(to_char(ln_res_tbl_type(i).manager_id),'(null)'),20)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).manager_role_name,'(null)'),20)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).mgr_rep_attribute14,'(null)'),30)||chr(9)
                              ||RPAD(NVL(ln_res_tbl_type(i).parent_group_name,'(null)'),60)||chr(9)                       
                               );
            
                 END LOOP;
         END IF;
       Else
         
         begin
         OPEN  lcu_get_rsc_dtl(ln_resource_id);
         FETCH lcu_get_rsc_dtl INTO ln_res_tbl_type(1);
         CLOSE lcu_get_rsc_dtl;
         IF ln_res_tbl_type(1).sales_rep_ID IS NULL Then
         NULL;
         END IF;
         exception
         when others then 
            display_log ('ln_count_rsc_mgr step 2 =>'||ln_count_rsc_mgr );
            OPEN  lcu_get_rsc_nomgr_dtls(ln_resource_id);
            FETCH lcu_get_rsc_nomgr_dtls INTO ln_res_tbl_type(1);
            CLOSE lcu_get_rsc_nomgr_dtls;
         end;
         display_out(' '
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_name,'(null)'),50)||chr(9)
                   ||RPAD(NVL(to_char(ln_res_tbl_type(1).sales_rep_id),'(null)'),20)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_number,'(null)'),30)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_role_name,'(null)'),20)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_legacy_id,'(null)'),30)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_attribute14,'(null)'),30)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).sales_rep_group_name,'(null)'),60)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).manager_name,'(null)'),50)||chr(9)
                   ||RPAD(NVL(to_char(ln_res_tbl_type(1).manager_id),'(null)'),20)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).manager_role_name,'(null)'),20)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).mgr_rep_attribute14,'(null)'),30)||chr(9)
                   ||RPAD(NVL(ln_res_tbl_type(1).parent_group_name,'(null)'),60)||chr(9)                         
                    );          
       END IF;
       /*display_out(RPAD('-',50,'-')
                 ||RPAD('-',20,'-')
                 ||RPAD('-',30,'-')
                 ||RPAD('-',60,'-')
                 ||RPAD('-',30,'-')
                 ||RPAD('-',30,'-')
                 ||RPAD('-',60,'-')
                 ||RPAD('-',50,'-')
                 ||RPAD('-',20,'-')
                 ||RPAD('-',60,'-')
                 ||RPAD('-',30,'-')
                 ||RPAD('-',60,'-'));  */
  
    EXCEPTION

       WHEN OTHERS THEN

          x_retcode := 2;

          x_errbuf  := SUBSTR('Unexpected error occurred.Error:'||SQLERRM,1,255);

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                          P_PROGRAM_TYPE            => 'CONCURRENT PROGRAM'
                                         ,P_PROGRAM_NAME            => 'XX_TM_RM_HIERARCHY_REPORT_PKG.MAIN_PROC'
                                         ,P_PROGRAM_ID              => NULL
                                         ,P_MODULE_NAME             => 'CN'
                                         ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                         ,P_ERROR_MESSAGE_COUNT     => NULL
                                         ,P_ERROR_MESSAGE_CODE      => x_retcode
                                         ,P_ERROR_MESSAGE           => x_errbuf
                                         ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                         ,P_NOTIFY_FLAG             => 'Y'
                                         ,P_OBJECT_TYPE             => 'RM Hierarchy Report'
                                         ,P_OBJECT_ID               => NULL
                                         ,P_ATTRIBUTE1              => p_resource_id
                                         ,P_ATTRIBUTE3              => NULL
                                         ,P_RETURN_CODE             => NULL
                                         ,P_MSG_COUNT               => NULL
                                        );
    END MAIN_PROC;

   PROCEDURE RM_JOB_ROLE_MAPPING_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   ) IS
     CURSOR lcu_jobrole IS
     SELECT jrr.role_id, 
            jrr.role_code, 
            jrr.role_name, 
            jrr.role_type_code, 
            jrr.attribute14 od_role_code, 
            jrr.attribute15 division, 
            jrv.job_id, 
            jrv.job_name
     FROM   apps.jtf_rs_job_roles_vl jrv,
            apps.jtf_rs_roles_vl     jrr
     WHERE  jrr.role_id = jrv.role_id
     ORDER BY jrv.job_id, jrv.job_name;

     l_count NUMBER := 0;
   BEGIN
     display_out(RPAD('Office Depot',163)||LPAD(' Date: '||trunc(SYSDATE),16));
     display_out(RPAD('-',320,'-'));
     display_out(LPAD('OD HRMS Job - CRM Role Mapping Report',107));
     display_out(RPAD('-',320,'-'));
     display_out(RPAD('Job Name',60)         || CHR(9) ||
                 RPAD('Role Code',30)        || CHR(9) ||
                 RPAD('Role Name',60)        || CHR(9) ||
                 RPAD('Role Type Code',60)   || CHR(9) ||
                 RPAD('OD Role Code',35)     || CHR(9) ||
                 RPAD('Division',35)         
                );
     display_out(RPAD('-',320,'-'));

     FOR jr_rec IN lcu_jobrole LOOP
       display_out(RPAD(NVL(jr_rec.job_name, ' '), 60)         || CHR(9) ||
                   RPAD(NVL(jr_rec.role_code, ' '), 30)        || CHR(9) ||
                   RPAD(NVL(jr_rec.role_name, ' '), 60)        || CHR(9) ||
                   RPAD(NVL(jr_rec.role_type_code, ' '), 60)   || CHR(9) ||
                   RPAD(NVL(jr_rec.od_role_code, ' '), 35)     || CHR(9) ||
                   RPAD(NVL(jr_rec.division, ' '), 35)         
                  );       
       l_count := l_count + 1;
     END LOOP;

     IF l_count = 0 THEN
       display_out('No Records Found');
     END IF;

   END RM_JOB_ROLE_MAPPING_RPT;

   PROCEDURE RM_PRXY_ROLES_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   ) IS
     CURSOR lcu_prxy IS
     SELECT jrre.resource_id, 
            jrre.resource_name, 
            jrre.source_number employee_id,
            jrrr.attribute15 sales_id,
            jrrv.role_id, 
            jrrv.role_name, 
            jrgv.group_id, 
            jrgv.group_name, 
            jrgm.start_date_active, 
            jrgm.end_date_active
     FROM   apps.jtf_rs_group_mbr_role_vl jrgm, 
            apps.jtf_rs_role_relations jrrr,
            apps.jtf_rs_roles_vl jrrv,
            apps.jtf_rs_groups_vl jrgv, 
            apps.jtf_rs_resource_extns_vl jrre
     WHERE  jrgm.role_relate_id = jrrr.role_relate_id
       AND  jrgm.role_id = jrrv.role_id
       AND  jrrv.role_name = 'PRXY'
       AND  jrrv.role_type_code = 'SALES'
       AND  sysdate between jrgm.start_date_active and nvl(jrgm.end_date_active, sysdate+1)
       AND  jrgv.group_id = jrgm.group_id
       AND  jrre.resource_id = jrgm.resource_id
     ORDER BY 1;

     l_count NUMBER := 0;
   BEGIN
     display_out(RPAD('Office Depot',163)||LPAD(' Date: '||trunc(SYSDATE),16));
     display_out(RPAD('-',300,'-'));
     display_out(LPAD('OD CRM - Resources with Sales Proxy Role Report',107));
     display_out(RPAD('-',300,'-'));
     display_out(RPAD('Resource Name',60)    || CHR(9) ||
                 RPAD('Employee Number',35)  || CHR(9) ||
                 RPAD('OD Sales ID',35)      || CHR(9) ||
                 RPAD('Role Name',60)        || CHR(9) ||
                 RPAD('Group Name',60)       || CHR(9) ||
                 RPAD('Start Date',11)       || CHR(9) ||
                 RPAD('End Date',11)
                );
     display_out(RPAD('-',300,'-'));

     FOR prxy_rec IN lcu_prxy LOOP
       display_out(RPAD(NVL(prxy_rec.resource_name, ' '), 60)       || CHR(9) ||
                   RPAD(NVL(prxy_rec.employee_id, ' '), 35)         || CHR(9) ||
                   RPAD(NVL(prxy_rec.sales_id, ' '),35)             || CHR(9) ||
                   RPAD(NVL(prxy_rec.role_name, ' '), 60)           || CHR(9) ||
                   RPAD(NVL(prxy_rec.group_name, ' '), 60)          || CHR(9) ||
                   RPAD(NVL(TO_CHAR(prxy_rec.start_date_active, 'MM/DD/YYYY'), ' '), 11)   || CHR(9) ||
                   RPAD(NVL(TO_CHAR(prxy_rec.end_date_active, 'MM/DD/YYYY'), ' '), 11)
                  );
       l_count := l_count + 1;
     END LOOP;

     IF l_count = 0 THEN
       display_out('No Records Found');
     END IF;

   END RM_PRXY_ROLES_RPT;

   PROCEDURE RM_RESOURCE_ROLES_RPT
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   ) IS

     CURSOR lcu_rsc IS
     SELECT jrre.resource_name, 
            jrre.source_number res_employee_number,
            fu.user_name resource_creator, 
            fu.description res_creator_name, 
            jrrv.role_name, 
            jrrv.role_type_code, 
            fu1.user_name role_creator, 
            fu1.description role_creator_name, 
            jrgv.group_name
     FROM   apps.jtf_rs_group_mbr_role_vl jrgm, 
            apps.jtf_rs_resource_extns_vl jrre, 
            apps.jtf_rs_roles_vl          jrrv,
            apps.jtf_rs_groups_vl         jrgv,
            apps.fnd_user                 fu,
            apps.fnd_user                 fu1,
            apps.jtf_rs_role_relations    jrrr
     WHERE  sysdate between jrgm.start_date_active and nvl(jrgm.end_date_active, sysdate+1)
       AND  jrre.resource_id = jrgm.resource_id
       AND  fu.user_id = jrre.created_by
       AND  jrrv.role_id  = jrgm.role_id
       AND  jrgv.group_id = jrgm.group_id  
       AND  jrrr.role_relate_id = jrgm.role_relate_id
       AND  fu1.user_id = jrrr.created_by
     ORDER BY 1;

     l_count NUMBER := 0;
   BEGIN
     display_out(RPAD('Office Depot',163)||LPAD(' Date: '||trunc(SYSDATE),16));
     display_out(RPAD('-',450,'-'));
     display_out(LPAD('OD CRM - Resource Manager User Report',107));
     display_out(RPAD('-',450,'-'));
     display_out(RPAD('Resource Name',60)|| CHR(9) ||
                 RPAD('Resource Employee Number',35)  || CHR(9) ||
                 RPAD('Resource Creator ID',35)  || CHR(9) ||
                 RPAD('Resource Creator Name',60)      || CHR(9) ||
                 RPAD('Role Name',60)    || CHR(9) ||
                 RPAD('Role Type Code',35)     || CHR(9) ||
                 RPAD('Role Creator ID',35)  || CHR(9) ||
                 RPAD('Role Creator Name',60)      || CHR(9) ||
                 RPAD('Group Name',60)
                );
     display_out(RPAD('-',450,'-'));

     FOR rsc_rec IN lcu_rsc LOOP
       display_out(RPAD(NVL(rsc_rec.resource_name, ' '),60)|| CHR(9) ||
                   RPAD(NVL(rsc_rec.res_employee_number, ' '), 35)  || CHR(9) ||
                   RPAD(NVL(rsc_rec.resource_creator, ' '), 35)  || CHR(9) ||
                   RPAD(NVL(rsc_rec.res_creator_name, ' '), 60)      || CHR(9) ||
                   RPAD(NVL(rsc_rec.role_name, ' '), 60)    || CHR(9) ||
                   RPAD(NVL(rsc_rec.role_type_code, ' '), 35)     || CHR(9) ||
                   RPAD(NVL(rsc_rec.role_creator, ' '), 35)  || CHR(9) ||
                   RPAD(NVL(rsc_rec.role_creator_name, ' '), 60)      || CHR(9) ||
                   RPAD(NVL(rsc_rec.group_name, ' '), 60)
                  );
       l_count := l_count + 1;
     END LOOP;

     IF l_count = 0 THEN
       display_out('No Records Found');
     END IF;

   END RM_RESOURCE_ROLES_RPT;


END XX_TM_RM_HIERARCHY_REPORT_PKG;

/

SHOW ERRORS


--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================


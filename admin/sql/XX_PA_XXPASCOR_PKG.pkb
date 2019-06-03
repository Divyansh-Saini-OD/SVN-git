CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_XXPASCOR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPAPRJI_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

FUNCTION get_lu_namedate(p_prod_dtl_id IN NUMBER) RETURN VARCHAR2
IS

V_DATE DATE;
V_USER NUMBER;
v_luname varchar2(100);
BEGIN
  SELECT MAX(LAST_UPDATE_DATE) 
    INTO V_DATE
    FROM (select last_update_date
	    from xx_pa_pb_genprd_dtl 
           where prod_dtl_id=p_prod_dtl_id
	  union
	  select last_update_date
	    from XX_PA_PB_PRD_LOGISTICS 
           where prod_dtl_id=p_prod_dtl_id
	  union
	  select last_update_date
	    from XX_PA_PB_TARIFF_APRV 
           where prod_dtl_id=p_prod_dtl_id
	  union
	  select last_update_date
	    from xx_pa_pb_prd_qatstr 
	   where prod_dtl_id=p_prod_dtl_id
	     and task_description like 'Product Testing%'
	  );
  BEGIN
  SELECT LAST_UPDATED_BY
    INTO V_USER
    FROM (SELECT LAST_UPDATED_BY
	    FROM xx_pa_pb_genprd_dtl where prod_dtl_id=p_prod_dtl_id
  	     AND LAST_UPDATE_DATE=V_DATE
          union
          SELECT LAST_UPDATED_BY
            from XX_PA_PB_PRD_LOGISTICS where prod_dtl_id=p_prod_dtl_id
	     AND LAST_UPDATE_DATE=V_DATE
          union
          SELECT LAST_UPDATED_BY
            from XX_PA_PB_TARIFF_APRV where prod_dtl_id=p_prod_dtl_id
	     AND LAST_UPDATE_DATE=V_DATE
          union
          SELECT LAST_UPDATED_BY
	    from xx_pa_pb_prd_qatstr where prod_dtl_id=p_prod_dtl_id
             and task_description like 'Product Testing%'
	     AND LAST_UPDATE_DATE=V_DATE
         );
  EXCEPTION
    WHEN others THEN
      v_user:=NULL;
  END;
  BEGIN
    SELECT c.full_name
      INTO v_luname
      FROM apps.per_all_people_f c,
           apps.fnd_user a
     WHERE a.user_id=v_user
       AND c.person_id=a.employee_id;
  EXCEPTION
    WHEN others THEn
      v_luname:=NULL;
  END;
  RETURN(v_luname||', '||TO_CHAR(v_date,'DD-MON-RR HH24:MI:SS'));
END get_lu_namedate;

FUNCTION get_dmm(p_dept IN VARCHAR2) RETURN VARCHAR2
IS
v_dmm varchar2(50);
BEGIN
 SELECT od_pb_dmm
   INTO v_dmm
   FROM apps.q_OD_GSO_DEPT_CATEGORY_v
  WHERE od_pb_sc_dept_num=p_dept;
 RETURN(v_dmm);
EXCEPTION
  WHEN others THEN
    RETURN(NULL);
END get_dmm;


FUNCTION BeforeReportTrigger return boolean is
BEGIN
  IF p_cancelled='N' THEN
     p_status_where:=' AND  pps1.project_status_name NOT IN ('||'''Rejected'''||','||'''Cancelled'''||','||'''On Hold'''||  ')';
  ELSE
    p_status_where:=' AND 1=1';
  END IF;
  RETURN(TRUE);
END BeforeReportTrigger;

FUNCTION get_total_proj(p_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_total_proj NUMBER;
BEGIN
  IF p_cancelled='N' THEN
     SELECT COUNT(distinct ppa1.project_id)  
       INTO v_total_proj
       FROM apps.PA_PROJECT_STATUSES PPS1,
	    apps.xx_pa_pb_genprd_dtl dtl,
            APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND dtl.project_id=ppa1.project_id
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EEB1.C_EXT_ATTR5 IS NOT NULL
        AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold');
  ELSE
     SELECT COUNT(distinct ppa1.project_id)  
       INTO v_total_proj
       FROM apps.xx_pa_pb_genprd_dtl dtl,
	    APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.SEGMENT1 LIKE 'PB%' 
	AND dtl.project_id=ppa1.project_id
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EEB1.C_EXT_ATTR5 IS NOT NULL;
  END IF;
   RETURN(v_total_proj);
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_total_proj;

FUNCTION get_total_sku(P_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_total_sku NUMBER;
BEGIN
  IF p_cancelled='N' THEN
     SELECT COUNT(1)
       INTO v_total_sku
       FROM apps.PA_PROJECT_STATUSES PPS1,
	    apps.xx_pa_pb_genprd_dtl dtl,
            APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
        AND PPA1.SEGMENT1 LIKE 'PB%' 
	AND DTL.project_id=PPA1.project_id
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EEB1.C_EXT_ATTR5 IS NOT NULL
        AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold');
  ELSE
     SELECT COUNT(1)
       INTO v_total_sku
       FROM apps.xx_pa_pb_genprd_dtl dtl,
	    APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND dtl.project_id=ppa1.project_id
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EEB1.C_EXT_ATTR5 IS NOT NULL;
  END IF;
  RETURN(v_total_sku);
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_total_sku;


FUNCTION get_total_fcst(P_cancelled IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_total_fcst NUMBER;
BEGIN
  IF p_cancelled='N' THEN
     SELECT NVL(SUM(pbl.revenue),0)
       INTO v_total_fcst
       FROM apps.pa_budget_lines pbl,
            apps.pa_resource_assignments pra,
            apps.pa_budget_versions pbv,
   	    apps.PA_PROJECT_STATUSES PPS1,
	    apps.pa_projects_all ppa LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA.PROJECT_ID = EEB1.PROJECT_ID
      WHERE ppa.segment1 like 'PB%'
        AND pbl.resource_assignment_id =pra.resource_assignment_id
        AND pra.budget_version_id = pbv.budget_version_id
        AND pbv.budget_status_code = 'B'
        AND pbv.current_flag = 'Y'
        AND pra.project_id=ppa.project_id
        AND EEB1.C_EXT_ATTR5 IS NOT NULL
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND PPA.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
        AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold');
  ELSE
   SELECT NVL(SUM(pbl.revenue),0)
     INTO v_total_fcst
     FROM apps.pa_budget_lines pbl,
          apps.pa_resource_assignments pra,
          apps.pa_budget_versions pbv,
          apps.pa_projects_all ppa LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA.PROJECT_ID = EEB1.PROJECT_ID
    WHERE ppa.segment1 like 'PB%'
      AND pbl.resource_assignment_id =pra.resource_assignment_id
      AND pra.budget_version_id = pbv.budget_version_id
      AND pbv.budget_status_code = 'B'
      AND pbv.current_flag = 'Y'
      AND EEB1.C_EXT_ATTR5 IS NOT NULL
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND pra.project_id=ppa.project_id;
  END IF;
  IF v_total_fcst=0 THEN 
     RETURN(-1);
  ELSE
     RETURN(v_total_fcst); 
  END IF;
EXCEPTION
  WHEN others THEN
    RETURN(v_total_fcst);
END get_total_fcst;

FUNCTION get_fcst_sku(p_cancelled IN VARCHAR2, p_division IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_cnt NUMBER;
v_division varchar2(50) :='%'||p_division||'%';
BEGIN
  IF p_cancelled='N' THEN
     SELECT COUNT(1)
       INTO v_cnt
       FROM apps.PA_PROJECT_STATUSES PPS1,
	    apps.xx_pa_pb_genprd_dtl dtl,
            APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
        AND dtl.project_id=ppa1.project_id
        AND EEB1.C_EXT_ATTR5 Like v_division
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EXISTS (   SELECT 'x'
		    FROM apps.pa_budget_lines pbl,
		         apps.pa_resource_assignments pra,
		         apps.pa_budget_versions pbv
		   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
		     AND pra.budget_version_id = pbv.budget_version_id
		     AND pbv.budget_status_code = 'B'
		     AND pbv.current_flag = 'Y'
		     AND pra.project_id=ppa1.project_id);
  ELSE
     SELECT COUNT(1)
       INTO v_cnt
       FROM apps.xx_pa_pb_genprd_dtl dtl,
	    APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND dtl.project_id=ppa1.project_id
        AND EEB1.C_EXT_ATTR5 Like v_division
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EXISTS (   SELECT 'x'
		    FROM apps.pa_budget_lines pbl,
		         apps.pa_resource_assignments pra,
		         apps.pa_budget_versions pbv
		   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
		     AND pra.budget_version_id = pbv.budget_version_id
		     AND pbv.budget_status_code = 'B'
		     AND pbv.current_flag = 'Y'
		     AND pra.project_id=ppa1.project_id);
  END IF;
  IF v_cnt=0 THEN 
     RETURN(-1);
  ELSE
     RETURN(v_cnt); 
  END IF;
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_sku;

FUNCTION get_fcst_skuc(p_cancelled IN VARCHAR2, p_division IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_cnt NUMBER;
v_division varchar2(50) :='%'||p_division||'%';
BEGIN
  IF p_cancelled='N' THEN
     SELECT COUNT(1)
       INTO v_cnt
       FROM apps.PA_PROJECT_STATUSES PPS1,
	    apps.xx_pa_pb_genprd_dtl dtl,
            APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
        AND dtl.project_id=ppa1.project_id
        AND EEB1.C_EXT_ATTR5 Like v_division
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EXISTS (   SELECT 'x'
		    FROM apps.pa_budget_lines pbl,
		         apps.pa_resource_assignments pra,
		         apps.pa_budget_versions pbv
		   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
		     AND pra.budget_version_id = pbv.budget_version_id
		     AND pbv.budget_status_code = 'B'
		     AND pbv.current_flag = 'Y'
		     AND pra.project_id=ppa1.project_id);
  ELSE
     SELECT COUNT(1)
       INTO v_cnt
       FROM apps.xx_pa_pb_genprd_dtl dtl,
	    APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0
        AND PPA1.TEMPLATE_FLAG = 'N'
        AND PPA1.SEGMENT1 LIKE 'PB%' 
        AND dtl.project_id=ppa1.project_id
        AND EEB1.C_EXT_ATTR5 Like v_division
        AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
        AND EXISTS (   SELECT 'x'
		    FROM apps.pa_budget_lines pbl,
		         apps.pa_resource_assignments pra,
		         apps.pa_budget_versions pbv
		   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
		     AND pra.budget_version_id = pbv.budget_version_id
		     AND pbv.budget_status_code = 'B'
		     AND pbv.current_flag = 'Y'
		     AND pra.project_id=ppa1.project_id);
  END IF;
  RETURN(v_cnt); 
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_skuc;


FUNCTION get_fcst_sku_di(p_cancelled IN VARCHAR2,p_division IN VARCHAR2, p_di_asoc_merc IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_cnt NUMBER;
v_di_asoc_merch varchar2(100):='%'||p_di_asoc_merc||'%';
BEGIN
 IF p_cancelled='N' THEN
    SELECT COUNT(1)
      INTO v_cnt
      FROM apps.per_all_people_f d,
           apps.pa_project_role_types_vl c,
           apps.pa_project_parties b,
           apps.PA_PROJECT_STATUSES PPS1,
	   apps.xx_pa_pb_genprd_dtl dtl,
           APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0
      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
      AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND b.project_id=ppa1.project_id
      AND c.project_role_id=b.project_role_id
      AND c.project_role_type='PROJECT MANAGER'
      AND d.person_id=b.resource_source_id
      AND d.full_name like v_di_asoc_merch
      AND EEB1.C_EXT_ATTR5=p_division
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
 ELSE
   SELECT COUNT(1)
     INTO v_cnt
     FROM apps.per_all_people_f d,
          apps.pa_project_role_types_vl c,
          apps.pa_project_parties b,
	  apps.xx_pa_pb_genprd_dtl dtl,
          APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
   WHERE PPA1.PROJECT_ID > 0
     AND PPA1.TEMPLATE_FLAG = 'N'
     AND PPA1.SEGMENT1 LIKE 'PB%' 
     AND dtl.project_id=ppa1.project_id
     AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
     AND b.project_id=ppa1.project_id
     AND c.project_role_id=b.project_role_id
     AND c.project_role_type='PROJECT MANAGER'
     AND d.person_id=b.resource_source_id
     AND d.full_name like v_di_asoc_merch
     AND EEB1.C_EXT_ATTR5=p_division
     AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
 END IF;
  IF v_cnt=0 THEN 
     RETURN(-1);
  ELSE
     RETURN(v_cnt); 
  END IF;
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_sku_di;


FUNCTION get_fcst_sku_dic(p_cancelled IN VARCHAR2,p_division IN VARCHAR2, p_di_asoc_merc IN VARCHAR2,p_year IN NUMBER) return NUMBER
IS
v_cnt NUMBER;
v_di_asoc_merch varchar2(100):='%'||p_di_asoc_merc||'%';
BEGIN
 IF p_cancelled='N' THEN
    SELECT COUNT(1)
      INTO v_cnt
      FROM apps.per_all_people_f d,
           apps.pa_project_role_types_vl c,
           apps.pa_project_parties b,
           apps.PA_PROJECT_STATUSES PPS1,
	   apps.xx_pa_pb_genprd_dtl dtl,
           APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0

      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
      AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND b.project_id=ppa1.project_id
      AND c.project_role_id=b.project_role_id
      AND c.project_role_type='PROJECT MANAGER'
      AND d.person_id=b.resource_source_id
      AND d.full_name like v_di_asoc_merch
      AND EEB1.C_EXT_ATTR5=p_division
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
 ELSE
   SELECT COUNT(1)
     INTO v_cnt
     FROM apps.per_all_people_f d,
          apps.pa_project_role_types_vl c,
          apps.pa_project_parties b,
	  apps.xx_pa_pb_genprd_dtl dtl,
          APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID
   WHERE PPA1.PROJECT_ID > 0
     AND PPA1.TEMPLATE_FLAG = 'N'
     AND PPA1.SEGMENT1 LIKE 'PB%' 
     AND dtl.project_id=ppa1.project_id
     AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
     AND b.project_id=ppa1.project_id
     AND c.project_role_id=b.project_role_id
     AND c.project_role_type='PROJECT MANAGER'
     AND d.person_id=b.resource_source_id
     AND d.full_name like v_di_asoc_merch
     AND EEB1.C_EXT_ATTR5=p_division
     AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
 END IF;
 RETURN(v_cnt); 
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_sku_dic;


FUNCTION get_fcst_sku_trk(p_cancelled IN VARCHAR2,p_tracker IN VARCHAR2,p_year IN NUMBER) return NUMBER 
IS
v_cnt NUMBER;
v_tracker varchar2(30):='%'||p_tracker||'%';
BEGIN
  IF p_cancelled='N' THEN
    SELECT COUNT(1)
      INTO v_cnt
      FROM apps.PA_PROJECT_STATUSES PPS1,
	   apps.xx_pa_pb_genprd_dtl dtl,
           APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0
      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
      AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND PPA2.project_id=PPA1.project_id
      AND EEB2.C_EXT_ATTR1 IS NOT NULL
      AND EEB2.C_EXT_ATTR1 LIKE v_tracker
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);

  ELSE
    SELECT COUNT(1)
      INTO v_cnt
      FROM  apps.xx_pa_pb_genprd_dtl dtl,
		APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0
      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND PPA2.project_id=PPA1.project_id
      AND EEB2.C_EXT_ATTR1 IS NOT NULL
      AND EEB2.C_EXT_ATTR1 LIKE v_tracker
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
  END IF;
  IF v_cnt=0 THEN 
     RETURN(-1);
  ELSE
     RETURN(v_cnt); 
  END IF;
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_sku_trk;

FUNCTION get_fcst_sku_trkc(p_cancelled IN VARCHAR2,p_tracker IN VARCHAR2,p_year IN NUMBER) return NUMBER 
IS
v_cnt NUMBER;
v_tracker varchar2(30):='%'||p_tracker||'%';
BEGIN
  IF p_cancelled='N' THEN
    SELECT COUNT(1)
      INTO v_cnt
      FROM apps.PA_PROJECT_STATUSES PPS1,
	   apps.xx_pa_pb_genprd_dtl dtl,
           APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0
      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
      AND pps1.project_status_name NOT IN ('Rejected','Cancelled','On Hold')
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND PPA2.project_id=PPA1.project_id
      AND EEB2.C_EXT_ATTR1 IS NOT NULL
      AND EEB2.C_EXT_ATTR1 LIKE v_tracker
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);

  ELSE
    SELECT COUNT(1)
      INTO v_cnt
      FROM  apps.xx_pa_pb_genprd_dtl dtl,
		APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID
    WHERE PPA1.PROJECT_ID > 0
      AND PPA1.TEMPLATE_FLAG = 'N'
      AND PPA1.SEGMENT1 LIKE 'PB%' 
      AND dtl.project_id=ppa1.project_id
      AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
      AND PPA2.project_id=PPA1.project_id
      AND EEB2.C_EXT_ATTR1 IS NOT NULL
      AND EEB2.C_EXT_ATTR1 LIKE v_tracker
      AND EXISTS (   SELECT 'x'
            FROM apps.pa_budget_lines pbl,
                 apps.pa_resource_assignments pra,
                 apps.pa_budget_versions pbv
           WHERE pbl.resource_assignment_id =pra.resource_assignment_id
             AND pra.budget_version_id = pbv.budget_version_id
             AND pbv.budget_status_code = 'B'
             AND pbv.current_flag = 'Y'
             AND pra.project_id=ppa1.project_id);
  END IF;
  RETURN(v_cnt); 
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_fcst_sku_trkc;


FUNCTION get_division(p_division IN VARCHAR2,p_project_id IN NUMBER,p_year IN NUMBER) return NUMBER 
IS
v_cnt NUMBER;
v_division VARCHAR2(30);
BEGIN
  SELECT DECODE(p_division,'FURT','%FURNITURE%','SUPP','%SUPPLIES%','TECH','%TECHNOLOGY%','PHER','%PERIPHERALS%')
    INTO v_division
    FROM DUAL;

  SELECT COUNT(1)
    INTO v_cnt
    FROM APPS.PA_PROJECTS_ERP_EXT_B EEB1,
         APPS.EGO_FND_DSC_FLX_CTX_EXT FND1
   WHERE EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID
     AND EEB1.C_EXT_ATTR5 like v_division
     AND FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO'
     AND TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY')=NVL(p_year,TO_CHAR(NVL(EEB1.D_EXT_ATTR2,EEB1.D_EXT_ATTR1),'YYYY'))
     AND EEB1.PROJECT_ID=p_project_id
     AND exists (SELECT 'X'
	           FROM apps.xx_pa_pb_genprd_dtl
		  WHERE project_id=eeb1.project_id);
 RETURN(v_cnt);
EXCEPTION
 WHEN others THEN
   RETURN(0);
END get_division;


END XX_PA_XXPASCOR_PKG;
/


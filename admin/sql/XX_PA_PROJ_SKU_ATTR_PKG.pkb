CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PROJ_SKU_ATTR_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PROJ_SKU_ATTR_PKG.pks                                          |
-- | Description      : Package spec for CR853 PLM Projects Enhancements                     |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        23-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_project_number IN  VARCHAR2 
                           )
IS                           

--p_project_number varchar2(100) := 'PB_D13_002' ;
l_api_version_num               NUMBER            := 1.0;
l_commit                        VARCHAR2(10)      := 'T';
l_init_msg_list                 VARCHAR2(10)      := 'T';
l_msg_count                     NUMBER;
l_msg_data                      VARCHAR2(4000);
l_return_status                 VARCHAR2(1);
l_error_data                    VARCHAR2(4000);
l_msg_index_out                 VARCHAR2(1000);
l_user_name                     fnd_user.user_name%TYPE;
l_resp_name                     pa_user_resp_v.responsibility_name%TYPE;
l_user_id                       NUMBER;
l_resp_id                       NUMBER;
l_resp_appl_id                  NUMBER;
l_profile_org_id                NUMBER;
l_resource_list_member_id       NUMBER;
l_progress_status_code          VARCHAR2(100);

l_prod_dtl_id                   NUMBER;
l_tariff_aprv_id                NUMBER;
l_prd_logistics_id              NUMBER;
l_prd_test_id                   NUMBER;
l_test_result_id                NUMBER;
l_line_count                    NUMBER := 0;


l_domestic_import               VARCHAR2(100);
l_sourcing_agent                VARCHAR2(100);
l_country_origin                VARCHAR2(100);
l_supplier                      VARCHAR2(100);

        
CURSOR cur_proj_info IS
 SELECT ppa.segment1,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id,
           substr(ppe.c_ext_attr1,1,2) dept_num,
           substr(ppe.c_ext_attr1,4,100) dept_name,
           substr(ppe.c_ext_attr2,1,3) class_num,
           substr(ppe.c_ext_attr2,5,100) class_name,
           ppe.c_ext_attr3 brand,
           ppe.c_ext_attr4 progress_status,
           substr(ppe.c_ext_attr5,1,1) division_num,
           substr(ppe.c_ext_attr5,3,100) division_name,
           ppe.c_ext_attr6 di_merchant,
           ppe.c_ext_attr7 dom_merchant,
           ppe.n_ext_attr1 num_of_sku,
           ppe.d_ext_attr1 initial_launch_date,
           ppe.d_ext_attr1 revised_launch_date
      FROM apps.pa_projects_all ppa,
           apps.pa_projects_erp_ext_b ppe,
           apps.ego_attr_groups_v eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = 275
       AND eag.attr_group_name = 'PB_GEN_INFO'
       AND ppa.segment1 = nvl(p_project_number,ppa.segment1)
       AND not exists (select 'x' 
                         from XX_PA_PB_GENPRD_DTL xpd
                        where xpd.project_id = ppa.project_id )  ;
       
       
        CURSOR cur_proj_sourcing (p_project_id number ) IS      
        SELECT ppa.segment1,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id,
           ppe.c_ext_attr1 domestic_import,
           ppe.c_ext_attr2 sourcing_agent,
           ppe.c_ext_attr3 country_origin,
           ppe.c_ext_attr4 supplier,
           ppe.c_ext_attr5 contact,
           ppe.c_ext_attr6 contact_phone,
           ppe.c_ext_attr7 contact_email
      FROM apps.pa_projects_all ppa,
           apps.pa_projects_erp_ext_b ppe,
           apps.ego_attr_groups_v eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = 275
       AND eag.attr_group_name = 'PB_SOURCING'
       AND ppa.project_id = p_project_id ;



       CURSOR cur_proj_ext (p_project_id number ) IS
     SELECT ppa.segment1 project_number,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id,
           ppe.c_ext_attr1 prd_tested,
           ppe.c_ext_attr2 art_tested,
           ppe.c_ext_attr3 trans_tested,
           ppe.c_ext_attr4 product_approved,
           ppe.c_ext_attr5 new_item,
           ppe.c_ext_attr6 sku,
           nvl(ppe.c_ext_attr8,'To Be Entered') item_desc,
           nvl(ppe.c_ext_attr9,'Dummy VPC : '||ppe.c_ext_attr10) vpc,
           ppe.c_ext_attr10 odpb_item_id,
           ppe.c_ext_attr11 prod_report_num,
           ppe.c_ext_attr12 artwork_report_num,
           ppe.c_ext_attr13 transit_report_num,
           ppe.c_ext_attr17 prod_results,
           ppe.c_ext_attr18 artwork_results,
           ppe.c_ext_attr19 transit_results,
           ppe.n_ext_attr1 group_num
      FROM apps.pa_projects_all ppa,
           apps.pa_projects_erp_ext_b ppe,
           apps.ego_attr_groups_v eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = 275
       AND eag.attr_group_name = 'QA'
       AND ppa.project_id = p_project_id;

Begin
--------
              -- User Login  Info
                BEGIN
                           l_user_name      := FND_PROFILE.value('USERNAME');
                           l_resp_name      := FND_PROFILE.value('RESP_NAME');
                           l_resp_appl_id   := FND_PROFILE.value('RESP_APPL_ID');
                           l_user_id        := FND_PROFILE.value('USER_ID');
                           l_resp_id        := FND_PROFILE.value('RESP_ID');
                           l_profile_org_id := FND_PROFILE.value('ORG_ID');

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'USER ID:'||l_user_id||'RESP ID:'||
                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);
                   DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||
                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);

                END;




-------
    
    FOR pa_proj_rec IN cur_proj_info LOOP
    
         FOR pa_proj_source_rec IN cur_proj_sourcing (pa_proj_rec.project_id) LOOP
        
            l_domestic_import := pa_proj_source_rec.domestic_import ;
            l_sourcing_agent  := pa_proj_source_rec.sourcing_agent ;
            l_country_origin  := pa_proj_source_rec.country_origin ;
            l_supplier        := pa_proj_source_rec.supplier ;
     
         END LOOP ;
    
        FOR pa_proj_ext_rec IN cur_proj_ext (pa_proj_rec.project_id)
        LOOP
        
            l_line_count := l_line_count + 1 ;
            
            select XX_PA_PB_PROD_DTL_S.nextval
              into l_prod_dtl_id
              from dual ;
              
    
            Insert into XX_PA_PB_GENPRD_DTL
                        (  PROD_DTL_ID  
                          ,PROJECT_ID        
                          ,PROJECT_NO    
                          ,VPC           
                          ,LINE_NO              
                          ,VENDOR_NAME          
                          ,SOURCING_AGENT       
                          ,CLASS                
                          ,CLASS_NAME           
                          ,DEPT                 
                          ,DEPT_NAME            
                          ,DIVISION             
                          ,DIVISION_NAME        
                          ,SKU                  
                          ,PRODUCT_DESC         
                          ,BRAND                
                          ,ATTRIBUTE1            
                          ,CREATION_DATE         
                          ,CREATED_BY            
                          ,LAST_UPDATE_DATE      
                          ,LAST_UPDATED_BY       
                          )
                        values
                        (l_prod_dtl_id
                        ,pa_proj_ext_rec.project_id
                        ,pa_proj_ext_rec.project_number
                        ,pa_proj_ext_rec.vpc
                        ,l_line_count
                        ,l_supplier
                        ,l_sourcing_agent
                        ,pa_proj_rec.class_num
                        ,pa_proj_rec.class_name
                        ,pa_proj_rec.dept_num
                        ,pa_proj_rec.dept_name
                        ,pa_proj_rec.division_num
                        ,pa_proj_rec.division_name
                        ,pa_proj_ext_rec.sku
                        ,pa_proj_ext_rec.item_desc
                        ,pa_proj_rec.brand
                        ,pa_proj_ext_rec.extension_id
                        ,sysdate
                        ,l_user_id
                        ,sysdate
                        ,l_user_id
                        );
                        
            select XX_PA_PB_TARIFF_APRV_S.nextval
              into l_tariff_aprv_id
              from dual ;                        
                        
            Insert into XX_PA_PB_TARIFF_APRV
                        (PROD_DTL_ID
                        ,TARIFF_APRV_ID
                        ,TARIFF_VERIFICATION
                        ,CREATION_DATE
                        ,CREATED_BY
                        ,LAST_UPDATE_DATE
                        ,LAST_UPDATED_BY
                        )
                        values
                        (l_prod_dtl_id
                        ,l_tariff_aprv_id
                        ,'To be Determined'
                        ,sysdate
                        ,l_user_id
                        ,sysdate
                        ,l_user_id
                        );          
                        
            select XX_PA_PB_PRD_LOGISTICS_S.nextval
              into l_prd_logistics_id
              from dual ;                          
                        
            Insert into XX_PA_PB_PRD_LOGISTICS
                            (PROD_DTL_ID
                            ,PRD_LOGISTICS_ID
                            ,COUNTRY_OF_ORIGIN
                            ,PORT_OF_SHIPPING
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATED_BY
                        )
                        values
                        (l_prod_dtl_id
                        ,l_prd_logistics_id
                        ,l_country_origin
                        ,'NA'
                        ,sysdate
                        ,l_user_id
                        ,sysdate
                        ,l_user_id
                        );        
                        
            select XX_PA_PB_PRD_TEST_S.nextval
              into l_prd_test_id
              from dual ;              
                        
            Insert into XX_PA_PB_PRD_QATST
                        (PROD_DTL_ID
                        ,PRD_TEST_ID
                        ,COMMENTS
                        ,CREATION_DATE
                        ,CREATED_BY
                        ,LAST_UPDATE_DATE
                        ,LAST_UPDATED_BY
                        )
                        values
                        (l_prod_dtl_id
                        ,l_prd_test_id
                        ,'To Be Determined'
                        ,sysdate
                        ,l_user_id
                        ,sysdate
                        ,l_user_id
                        ); 
                        
            select XX_PA_PB_PRD_TESTR_S.nextval
              into l_test_result_id
              from dual ;              
                        
            Insert into XX_PA_PB_PRD_QATSTR
                        (PROD_DTL_ID
                        ,TEST_RESULT_ID
                        ,REPORT_NO
                        ,COMMENTS
                        ,CREATION_DATE
                        ,CREATED_BY
                        ,LAST_UPDATE_DATE
                        ,LAST_UPDATED_BY
                        )
                        values
                        (l_prod_dtl_id
                        ,l_test_result_id
                        ,pa_proj_ext_rec.prod_report_num
                        ,'To be Determined'
                        ,sysdate
                        ,l_user_id
                        ,sysdate
                        ,l_user_id
                        );                                                                               
                        
              
    
        END LOOP;
    
        l_line_count := 0 ;
        commit;
        
    END LOOP;
    


commit;

exception 
when others then

--DBMS_OUTPUT.put_line('Create Project API Other Error:'||sqlerrm);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Project API Other Error:'||sqlerrm);

END Process_main;

End XX_PA_PROJ_SKU_ATTR_PKG;
/
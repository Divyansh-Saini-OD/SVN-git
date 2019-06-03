CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PA_INTERFACE_PKG AS
/******************************************************************************
   NAME:       XX_QA_PA_INTERFACE_PKG
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/24/2008   Youngmi Kwon       1. Created this package body.
   1.1        6/18/2008   Ian Bassaragh      1. Fix SQL BV export extract.
   1.2        7/31/2008   Ian Bassaragh      1. Fix SQL BV export NVL compare.
******************************************************************************/
PROCEDURE XXOD_INSERT_QA_FROM_PA (errbuf OUT VARCHAR2,
                                                retcode OUT VARCHAR2
                                                  ) IS

  l_user_name fnd_user.user_name%TYPE;
    CURSOR PA_DATA IS
        SELECT  pa.segment1 project_number
                ,pa.NAME project_name
                ,pa.long_name project_description
                ,eeb1.c_ext_attr5 qa_project_name
                ,pf.last_name||', '||pf.first_name project_manager
                ,eeb2.c_ext_attr1 domestic_import
                ,eeb2.c_ext_attr2 sourcing_agent
                ,eeb3.c_ext_attr1 item_dept
                ,eeb3.c_ext_attr2 item_cls
                ,eeb1.c_ext_attr10 odpb_item_id
                ,eeb1.c_ext_attr8 item_description
                ,eeb1.c_ext_attr6 sku
                ,eeb1.c_ext_attr9 vendor_vpc
                ,eeb2.c_ext_attr4 supplier
                ,eeb2.c_ext_attr5 vendor_contact_name
                ,eeb2.c_ext_attr6 vendor_contact_phone
                ,eeb2.c_ext_attr7 vendor_contact_email
                ,eeb2.c_ext_attr3 country_of_origin
                ,eeb1.c_ext_attr7 item_action_code
                ,ps.PROJECT_STATUS_NAME project_status
                ,pe.full_name qa_engineer
                ,pe_all.email_address qa_engineer_email
          FROM pa_projects_all pa
              ,pa_project_statuses ps
              ,pa_project_players pp
              ,per_all_people_f pf
              ,pa_projects_erp_ext_b eeb1
              ,ego_fnd_dsc_flx_ctx_ext fnd1
              ,pa_projects_erp_ext_b eeb2
              ,ego_fnd_dsc_flx_ctx_ext fnd2
              ,pa_projects_erp_ext_b eeb3
              ,ego_fnd_dsc_flx_ctx_ext fnd3
              ,pa_project_parties ppp
              ,pa_employees pe    
              ,per_all_people_f pe_all 
              ,pa_project_role_types_tl tl                         
         WHERE pa.project_id = pp.project_id
           AND pp.person_id = pf.person_id
           AND pa.project_id = eeb1.project_id
           AND eeb1.attr_group_id = fnd1.attr_group_id
           AND pa.project_id = eeb2.project_id
           AND eeb2.attr_group_id = fnd2.attr_group_id
           AND pa.project_id = eeb3.project_id
           AND eeb3.attr_group_id = fnd3.attr_group_id
           AND fnd1.descriptive_flex_context_code = 'QA'
           AND fnd2.descriptive_flex_context_code = 'PB_SOURCING'
           AND fnd3.descriptive_flex_context_code = 'PB_GEN_INFO'
           AND fnd3.descriptive_flexfield_name = 'PA_PROJ_ATTR_GROUP_TYPE'
           AND pp.project_role_type = 'PROJECT MANAGER'
           AND pa.project_status_code=ps.project_status_code
           and pp.project_id = ppp.project_id
           and ppp.project_role_id = tl.project_role_id
           and tl.meaning = 'QA ENG'
           and pe.person_id = PPP.RESOURCE_SOURCE_ID  
           and pe.person_id = pe_all.person_id                                   
           AND ps.project_status_name IN ('Approved','Cancelled','On Hold','Rejected')
           AND eeb1.D_EXT_ATTR1 IS  null  --- FOR insert records
         ORDER BY pa.segment1, eeb1.c_ext_attr10;

    BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR PA_DATA_REC IN PA_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before');
            INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT
                        , OD_PB_QA_PROJECT_DESC
                        , OD_PB_SEND_EMAIL
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '1' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.item_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        ,'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'PRODUCT'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                        , 'CAP'
                      );
                   
                     INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT    
                        , OD_PB_QA_PROJECT_DESC         
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '1' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.item_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        ,'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'ARTWORK'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                      ); 
                      
                     INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT
                        , OD_PB_QA_PROJECT_DESC
                  )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '1' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.item_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        ,'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'TRANSIT'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                      );      
                  
                UPDATE pa_projects_erp_ext_b
                SET  d_ext_attr1 = SYSDATE
                WHERE c_ext_attr10 = PA_DATA_REC.odpb_item_id; 
                                
                update q_od_pb_pre_purchase_iv
                set od_pb_item_action_code = 'C'
                where od_pb_proj_stat in ('Cancelled', 'Rejected'); 
                
                update q_od_pb_pre_purchase_iv
                set od_pb_item_action_code = 'H'
                where od_pb_proj_stat = 'On Hold';
                
                     
     END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
 END XXOD_INSERT_QA_FROM_PA;
  
 
 PROCEDURE XXOD_UPDATE_QA_FROM_PA (errbuf OUT VARCHAR2,
                                                retcode OUT VARCHAR2
                                                  ) IS

  l_user_name fnd_user.user_name%TYPE;
    CURSOR PA_DATA IS
        SELECT  pa.segment1 project_number
                ,pa.NAME project_name
                ,pa.long_name project_description
                ,eeb1.c_ext_attr5 qa_project_name
                ,pf.last_name||', '||pf.first_name project_manager
                ,eeb2.c_ext_attr1 domestic_import
                ,eeb2.c_ext_attr2 sourcing_agent
                ,eeb3.c_ext_attr1 item_dept
                ,eeb3.c_ext_attr2 item_cls
                ,eeb1.c_ext_attr10 odpb_item_id
                ,eeb1.c_ext_attr8 item_description
                ,eeb1.c_ext_attr6 sku
                ,eeb1.c_ext_attr9 vendor_vpc
                ,eeb2.c_ext_attr4 supplier
                ,eeb2.c_ext_attr5 vendor_contact_name
                ,eeb2.c_ext_attr6 vendor_contact_phone
                ,eeb2.c_ext_attr7 vendor_contact_email
                ,eeb2.c_ext_attr3 country_of_origin
                ,eeb1.c_ext_attr7 bv_action_code
                ,ps.PROJECT_STATUS_NAME project_status
                ,pe.full_name qa_engineer
                ,pe_all.email_address qa_engineer_email
          FROM pa_projects_all pa
              ,pa_project_statuses ps
              ,pa_project_players pp
              ,per_all_people_f pf
              ,pa_projects_erp_ext_b eeb1
              ,ego_fnd_dsc_flx_ctx_ext fnd1
              ,pa_projects_erp_ext_b eeb2
              ,ego_fnd_dsc_flx_ctx_ext fnd2
              ,pa_projects_erp_ext_b eeb3
              ,ego_fnd_dsc_flx_ctx_ext fnd3
              ,pa_project_parties ppp
              ,pa_employees pe    
              ,per_all_people_f pe_all   
              ,pa_project_role_types_tl tl                       
         WHERE pa.project_id = pp.project_id
           AND pp.person_id = pf.person_id
           AND pa.project_id = eeb1.project_id
           AND eeb1.attr_group_id = fnd1.attr_group_id
           AND pa.project_id = eeb2.project_id
           AND eeb2.attr_group_id = fnd2.attr_group_id 
           AND pa.project_id = eeb3.project_id
           AND eeb3.attr_group_id = fnd3.attr_group_id
           AND fnd1.descriptive_flex_context_code = 'QA'
           AND fnd2.descriptive_flex_context_code = 'PB_SOURCING'
           AND fnd3.descriptive_flex_context_code = 'PB_GEN_INFO'
           AND fnd3.descriptive_flexfield_name = 'PA_PROJ_ATTR_GROUP_TYPE'
           AND pp.project_role_type = 'PROJECT MANAGER'
           AND pa.project_status_code=ps.project_status_code
           and pp.project_id = ppp.project_id
           and ppp.project_role_id = tl.project_role_id
           and tl.meaning = 'QA ENG'
           and pe.person_id = PPP.RESOURCE_SOURCE_ID  
           and pe.person_id = pe_all.person_id                                   
           AND ps.project_status_name IN ('Approved','Cancelled','On Hold','Rejected')
           AND (eeb1.D_EXT_ATTR1 < eeb1.LAST_UPDATE_DATE -- for update records
               OR eeb1.D_EXT_ATTR1 < eeb2.LAST_UPDATE_DATE
               OR eeb1.D_EXT_ATTR1 < eeb3.LAST_UPDATE_DATE
               OR eeb1.D_EXT_ATTR1 < pa.last_update_date)
           AND exists (SELECT * from apps.q_od_pb_pre_purchase_v ppv
                   where eeb1.c_ext_attr10 = ppv.od_pb_item_id)
        ORDER BY pa.segment1, eeb1.c_ext_attr10;

         
    BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR PA_DATA_REC IN PA_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before insert');
            INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT
                        , OD_PB_QA_PROJECT_DESC
                        , OD_PB_SEND_EMAIL
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '2' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.bv_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        , 'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'PRODUCT'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                        , 'CAP'
                      );
                      
                 INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT
                        , OD_PB_QA_PROJECT_DESC
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '2' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.bv_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        , 'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'ARTWORK'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                      );
           
                INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_PROJ_NUM
                        , OD_PB_PROJ_NAME
                        , OD_PB_PROJ_DESC
                        , OD_PB_PROJ_MGR
                        , OD_PB_DOM_IMP
                        , OD_PB_SOURCING_AGENT
                        , OD_PB_ITEM_ID
                        , OD_PB_SKU
                        , OD_PB_ITEM_DESC
                        , OD_PB_VENDOR_VPC
                        , OD_PB_SUPPLIER
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_PHONE
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_COUNTRY_OF_ORIGIN
                        , OD_PB_ITEM_ACTION_CODE
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                        , OD_PB_PROJ_STAT 
                        , OD_PB_CA_TYPE
                        , OD_PB_QA_ENGINEER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TESTING_TYPE
                        , OD_PB_CLASS
                        , OD_PB_DEPARTMENT
                        , OD_PB_QA_PROJECT_DESC
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '2' --1 for insert --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , PA_DATA_REC.project_number
                        , PA_DATA_REC.project_name
                        , NVL(PA_DATA_REC.project_description,'NULL')
                        , PA_DATA_REC.project_manager
                        , PA_DATA_REC.domestic_import
                        , PA_DATA_REC.sourcing_agent
                        , PA_DATA_REC.odpb_item_id
                        , PA_DATA_REC.sku
                        , PA_DATA_REC.item_description
                        , PA_DATA_REC.vendor_vpc
                        , PA_DATA_REC.supplier
                        , PA_DATA_REC.vendor_contact_name
                        , PA_DATA_REC.vendor_contact_phone
                        , PA_DATA_REC.vendor_contact_email
                        , PA_DATA_REC.country_of_origin
                        , PA_DATA_REC.bv_action_code
                        , l_user_name 
                        , l_user_name 
                        , PA_DATA_REC.project_status
                        , 'CAP'
                        , PA_DATA_REC.qa_engineer
                        , PA_DATA_REC.qa_engineer_email
                        , 'TRANSIT'
                        , PA_DATA_REC.item_cls
                        , PA_DATA_REC.item_dept
                        , PA_DATA_REC.qa_project_name
                      );
           
                UPDATE pa_projects_erp_ext_b
                SET  d_ext_attr1 = SYSDATE
                WHERE c_ext_attr10 = PA_DATA_REC.odpb_item_id;    
                
                update q_od_pb_pre_purchase_iv
                set od_pb_item_action_code = 'C'
                where od_pb_proj_stat in ('Cancelled','Rejected');
                
                update q_od_pb_pre_purchase_iv
                set od_pb_item_action_code = 'H'
                where od_pb_proj_stat = 'On Hold';
                            
     END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
 END XXOD_UPDATE_QA_FROM_PA;
  
 PROCEDURE XXOD_UPDATE_QA_FROM_BV (errbuf OUT VARCHAR2,
                                                  retcode OUT VARCHAR2
                                                  ) IS
  
   l_user_name                         fnd_user.user_name%TYPE;
   
    CURSOR BV_DATA IS
        SELECT  T.PROJ_NUMBER
                ,T.SKU_NUMBER
                ,UPPER(T.TESTING_TYPE) AS TESTING_TYPE
                ,T.S1
               ,case CORRECTIVE_ACTION_STATUS when 0 then 'None'
                    when 1 then 'No CAP required'
                    when 2 then 'Pending CAP receipt'
                    when 3 then 'Accept CAP retest required'
                    when 4 then 'Reject CAP resubmit'
                    when 5 then 'Accept CAP no retest needed'
                else 'None'
                end CORRECTIVE_ACTION_STATUS
            ,COMMENTS
            ,substr(tr,1,4) as TEST_RESULTS
   
            ,case T.STATUS when 1 then 'Assignment confirmed'
                    when 2 then 'On Hold - Waiting for payments'
                    when 3 then 'On Hold - Waiting for samples'
                    when 4 then 'On Hold - Other reasons'
                    when 5 then 'On Hold - Need additional samples'
                    when 6 then 'In testing'
                    when 7 then 'Not applicable'
                    when 8 then 'Completed lab number'
                    when 9 then 'Change'
               else 'Not applicable'
              end AS STATUS
             ,T.TECH_REPORT_NUMBER
             ,T.PROTOCOL_NAME
              
    FROM
        (SELECT  PROJ_NUMBER
                ,TESTING_TYPE 
                ,to_char(max(status_timestamp), 'yyyy/mm/dd hh:mm:ss')  s1
               FROM XX_QA_VENDOR_DATA_TEMP
                group by PROJ_NUMBER, TESTING_TYPE) M
                     
    LEFT OUTER JOIN (SELECT PROJ_NUMBER
                            ,SKU_NUMBER
                            ,TESTING_TYPE 
                            ,TECH_REPORT_NUMBER
                            ,STATUS
                            ,CORRECTIVE_ACTION_STATUS 
                            ,COMMENTS
                            ,to_char(status_timestamp, 'yyyy/mm/dd hh:mm:ss') s1
                            ,upper(TEST_RESULTS) as tr
                            ,PROTOCOL_NAME                   
                     FROM XX_QA_VENDOR_DATA_TEMP ) T
            
         ON T.PROJ_NUMBER = M.PROJ_NUMBER
        AND T.TESTING_TYPE = M.TESTING_TYPE
        AND T.s1 = M.s1
    WHERE T.PROJ_NUMBER = M.PROJ_NUMBER
    AND T.TESTING_TYPE = M.TESTING_TYPE
    AND T.s1 = M.s1
    AND exists (SELECT * from apps.q_od_pb_pre_purchase_v ppv
                        where T.PROJ_NUMBER = ppv.od_pb_item_id
                        and  T.TESTING_TYPE = ppv.od_pb_testing_type);
    
BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR BV_DATA_REC IN BV_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before insert');
              INSERT INTO q_od_pb_pre_purchase_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_ITEM_ID
                        , OD_PB_TESTING_TYPE
                        , OD_PB_TECH_RPT_NUM
                        , OD_PB_ITEM_STATUS
                        , OD_PB_CAP_STATUS
                        , OD_PB_COMMENTS
                        , OD_PB_RESULTS
                        , OD_PB_PROTOCOL_NAME
                        , OD_PB_STATUS_TIMESTAMP
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_PRE_PURCHASE'
                        , '2' --2 for update
                        , 'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE'
                        , BV_DATA_REC.PROJ_NUMBER
                        , BV_DATA_REC.TESTING_TYPE
                        , BV_DATA_REC.TECH_REPORT_NUMBER
                        , BV_DATA_REC.STATUS
                        , BV_DATA_REC.CORRECTIVE_ACTION_STATUS
                        , NVL(BV_DATA_REC.COMMENTS,'NULL')
                        , BV_DATA_REC.TEST_RESULTS
                        , BV_DATA_REC.PROTOCOL_NAME
				        , BV_DATA_REC.S1		
	                    , l_user_name 
                        , l_user_name 
                      );
     
                                              
       END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
         
END XXOD_UPDATE_QA_FROM_BV;

PROCEDURE XXOD_QA_INSERT_CA_REQUEST (errbuf OUT VARCHAR2,
                                    retcode OUT VARCHAR2
                                    ) IS
  
   l_user_name  fnd_user.user_name%TYPE;
   
    CURSOR CA_DATA IS

    	SELECT   OD_PB_COMMENTS
                ,OD_PB_CA_TYPE
                ,OD_PB_CONTACT
                ,OD_PB_CONTACT_EMAIL
                ,OD_PB_ITEM_DESC
                ,OD_PB_ITEM_ID
                ,OD_PB_CLASS
                ,OD_PB_QA_ENGINEER
                ,OD_PB_RESULTS
                ,OD_PB_SKU
                ,OD_PB_SUPPLIER
                ,OD_PB_QA_ENGR_EMAIL
                ,OD_PB_TECH_RPT_NUM
                ,OD_PB_VENDOR_VPC
                ,NULL as OD_PB_DATE_DUE 
                ,NULL as OD_PB_DATE_REPORTED 
                ,NULL as OD_PB_DEFECT_SUM  
        FROM q_od_pb_pre_purchase_v pp
        WHERE trim(upper(OD_PB_RESULTS)) = 'FAIL'
          AND OD_PB_TECH_RPT_NUM IS NOT NULL
          AND OD_PB_ITEM_ID IS NOT NULL
          AND not exists (SELECT * from q_od_pb_ca_request_v ca
                        where pp.od_pb_item_id = ca.od_pb_item_id
                        and  pp.od_pb_tech_rpt_num = ca.od_pb_tech_rpt_num
                        and trim(ca.od_pb_ca_type) = 'CAP' )
                        
    UNION ALL

        SELECT   OD_PB_COMMENTS
                ,OD_PB_CA_TYPE
                ,OD_PB_CONTACT
                ,' ' as OD_PB_CONTACT_EMAIL
                ,' ' as OD_PB_ITEM_DESC
                ,' ' as OD_PB_ITEM_ID
                ,OD_PB_CLASS
                ,' ' as OD_PB_QA_ENGINEER
                ,OD_PB_RESULTS
                ,OD_PB_SKU
                ,OD_PB_SUPPLIER
                ,' ' as OD_PB_QA_ENGR_EMAIL
                ,OD_PB_TECH_RPT_NUM
                ,' ' as OD_PB_VENDOR_VPC
                ,OD_PB_DATE_DUE  
                ,OD_PB_DATE_REPORTED 
                ,OD_PB_DEFECT_SUM  
        FROM q_od_pb_TESTING_v pp
        WHERE trim(upper(OD_PB_RESULTS)) = 'FAIL'
          AND OD_PB_TECH_RPT_NUM IS NOT NULL
          AND OD_PB_SKU IS NOT NULL
          AND not exists (SELECT * from q_od_pb_ca_request_v ca
                        where pp.od_pb_SKU = ca.od_pb_SKU
                        and  pp.od_pb_tech_rpt_num = ca.od_pb_tech_rpt_num
                        and trim(ca.od_pb_ca_type) = 'CAPA' );
     
BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR CA_DATA_REC IN CA_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before insert');
            INSERT INTO q_OD_PB_CA_REQUEST_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_COMMENTS
                        , OD_PB_CA_TYPE
                        , OD_PB_CONTACT
                        , OD_PB_CONTACT_EMAIL
                        , OD_PB_ITEM_DESC
                        , OD_PB_ITEM_ID
                        , OD_PB_CLASS
                        , OD_PB_QA_ENGINEER
                        , OD_PB_RESULTS
                        , OD_PB_SKU
                        , OD_PB_SUPPLIER
                        , OD_PB_QA_ENGR_EMAIL
                        , OD_PB_TECH_RPT_NUM
                        , OD_PB_VENDOR_VPC
                        , OD_PB_DATE_DUE 
                        , OD_PB_DATE_REPORTED 
                        , OD_PB_DEFECT_SUM  
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_CA_REQUEST'
                        , '1' --1 for INSERT
                        , 'OD_PB_ITEM_ID,OD_PB_SKU,OD_PB_TECH_RPT_NUM'
                        , CA_DATA_REC.OD_PB_COMMENTS
                        , CA_DATA_REC.OD_PB_CA_TYPE
                        , CA_DATA_REC.OD_PB_CONTACT
                        , CA_DATA_REC.OD_PB_CONTACT_EMAIL
                        , CA_DATA_REC.OD_PB_ITEM_DESC
                        , CA_DATA_REC.OD_PB_ITEM_ID
                        , CA_DATA_REC.OD_PB_CLASS
                        , CA_DATA_REC.OD_PB_QA_ENGINEER
                        , CA_DATA_REC.OD_PB_RESULTS
                        , CA_DATA_REC.OD_PB_SKU
                        , CA_DATA_REC.OD_PB_SUPPLIER
                        , CA_DATA_REC.OD_PB_QA_ENGR_EMAIL
                        , CA_DATA_REC.OD_PB_TECH_RPT_NUM
                        , CA_DATA_REC.OD_PB_VENDOR_VPC
                        , CA_DATA_REC.OD_PB_DATE_DUE 
                        , CA_DATA_REC.OD_PB_DATE_REPORTED 
                        , CA_DATA_REC.OD_PB_DEFECT_SUM
		                , l_user_name 
                        , l_user_name 
                      );
                                              
       END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
         
END XXOD_QA_INSERT_CA_REQUEST;


PROCEDURE XXOD_QA_BV_OUTBOUND (errbuf OUT VARCHAR2,
                               retcode OUT VARCHAR2) IS

  l_file_name             VARCHAR2(100) ;
  l_out_put_dir           VARCHAR2(100) ;
  fhandle                 UTL_FILE.FILE_TYPE;
  l_write_data            VARCHAR2(5000);
  l_header                VARCHAR2(1000);

    CURSOR QA_DATA IS
            select DISTINCT OD_PB_PROJ_NUM
                  , OD_PB_PROJ_NAME
                  , OD_PB_PROJ_DESC
                  , OD_PB_PROJ_MGR
                  , OD_PB_DOM_IMP
                  , OD_PB_SOURCING_AGENT
                  , OD_PB_ITEM_ID
                  , OD_PB_SKU
                  , OD_PB_ITEM_DESC
                  , OD_PB_VENDOR_VPC
                  , OD_PB_SUPPLIER
                  , OD_PB_CONTACT
                  , OD_PB_CONTACT_PHONE
                  , OD_PB_CONTACT_EMAIL
                  , OD_PB_COUNTRY_OF_ORIGIN
                  , NVL(OD_PB_ITEM_ACTION_CODE,'-') AS OD_PB_ITEM_ACTION_CODE
              from q_od_pb_pre_purchase_v
              where OD_PB_PROJ_STAT in ('Approved')
              and NVL(OD_PB_ITEM_ACTION_CODE,' ') <> 'C'
              order by OD_PB_PROJ_NUM, OD_PB_ITEM_ID;
              
  BEGIN

         l_file_name    :='QA_Export_BV.xls';
         l_out_put_dir  :='XXMER_OUTBOUND';

         l_header       := 'PB_Project_Number'||chr(9)||'Project_Name'||chr(9)||'Project_Description'||chr(9)||'Brand_Management_Contact'||chr(9)||
                           'Domestic_or_Import'||chr(9)||'Sourcing_Agent'||chr(9)||'PB_Project_item_id'||chr(9)||
                           'Item_Description'||chr(9)||'SKU_Number'||chr(9)||'Vendor_VPC'||chr(9)||'Vendor_Name'||chr(9)||
                           'Vendor_Contact_Name'||chr(9)||'Vendor_Contact_Phone'||chr(9)||'Vendor_Contact_Email'||chr(9)||
                           'Country_Origion'||chr(9)||'BV_Action_Code';

         fhandle:=UTL_FILE.FOPEN(l_out_put_dir,l_file_name,'W');

         UTL_FILE.PUT_LINE(fhandle,l_header);

          FOR QA_DATA_REC IN QA_DATA
          LOOP
          
          l_write_data :=QA_DATA_REC.OD_PB_PROJ_NUM          ||chr(9)||
                         QA_DATA_REC.OD_PB_PROJ_NAME         ||chr(9)||
                         QA_DATA_REC.OD_PB_PROJ_DESC         ||chr(9)||
                         QA_DATA_REC.OD_PB_PROJ_MGR          ||chr(9)||
                         QA_DATA_REC.OD_PB_DOM_IMP           ||chr(9)||
                         QA_DATA_REC.OD_PB_SOURCING_AGENT    ||chr(9)||
                         QA_DATA_REC.OD_PB_ITEM_ID           ||chr(9)||
                         QA_DATA_REC.OD_PB_ITEM_DESC         ||chr(9)||
                         QA_DATA_REC.OD_PB_SKU               ||chr(9)||
                         QA_DATA_REC.OD_PB_VENDOR_VPC        ||chr(9)||
                         QA_DATA_REC.OD_PB_SUPPLIER          ||chr(9)||
                         QA_DATA_REC.OD_PB_CONTACT           ||chr(9)||
                         QA_DATA_REC.OD_PB_CONTACT_PHONE     ||chr(9)||
                         QA_DATA_REC.OD_PB_CONTACT_EMAIL     ||chr(9)||
                         QA_DATA_REC.OD_PB_COUNTRY_OF_ORIGIN ||chr(9)||
                         QA_DATA_REC.OD_PB_ITEM_ACTION_CODE ;

                      UTL_FILE.PUT_LINE(fhandle, l_write_data);
          END LOOP;
                      UTL_FILE.FCLOSE(fhandle);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,l_file_name||' File Created');
        EXCEPTION
        WHEN UTL_FILE.INVALID_PATH THEN

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UTL_FILE.INVALID_PATH');
               UTL_FILE.FCLOSE(fhandle);
               errbuf :=SQLERRM||' '||l_file_name;

         WHEN UTL_FILE.READ_ERROR THEN

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' UTL_FILE.READ_ERROR');
               UTL_FILE.FCLOSE(fhandle);
               errbuf :=SQLERRM||' '||l_file_name;

         WHEN UTL_FILE.WRITE_ERROR THEN

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UTL_FILE.WRITE_ERROR');
               UTL_FILE.FCLOSE(fhandle);
               errbuf :=SQLERRM||' '||l_file_name;

         WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OTHER ERROR');
               UTL_FILE.FCLOSE(fhandle);
               errbuf :=SQLERRM||' '||l_file_name;

  END XXOD_QA_BV_OUTBOUND;
  

  
PROCEDURE XXOD_QA_INSERT_BV_TESTS (errbuf OUT VARCHAR2,
                                                  retcode OUT VARCHAR2
                                                  ) IS
                                                  
     l_user_name                         fnd_user.user_name%TYPE;
   
    CURSOR BV_DATA IS
       SELECT   TECH_REPORT_NUMBER
                ,OD_PROJ_NUMBER
                ,OD_ITEM_NUMBER
                ,TEST_NAME
                ,SUBSTR(TEST_RESULTS,1,length(TEST_RESULTS)-1) AS TEST_RESULTS
         FROM   XXMER.XX_QA_VENDOR_DATA_TA_TEMP
    ;
    
BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR BV_DATA_REC IN BV_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before insert');
              INSERT INTO q_od_pb_test_details_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_TECH_RPT_NUM
                        , OD_PB_PROJ_NUM
                        , OD_PB_ITEM_ID
                        , OD_PB_TEST_NAME
                        , OD_PB_RESULTS
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_TEST_DETAILS'
                        , '1' --1for update
                        , 'OD_PB_TECH_RPT_NUM'
                        , BV_DATA_REC.TECH_REPORT_NUMBER
                        , NVL(BV_DATA_REC.OD_PROJ_NUMBER,'NULL')
                        , NVL(BV_DATA_REC.OD_ITEM_NUMBER,'NULL')
                        , NVL(BV_DATA_REC.TEST_NAME,'NULL')
                        , NVL(BV_DATA_REC.TEST_RESULTS,'NULL')
                        , l_user_name 
                        , l_user_name 
                      );
                                                   
       END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
         
END XXOD_QA_INSERT_BV_TESTS;

  
  
PROCEDURE XXOD_QA_INSERT_BV_FAILCODE (errbuf OUT VARCHAR2,
                                                  retcode OUT VARCHAR2
                                                  ) IS
                                                  
     l_user_name                         fnd_user.user_name%TYPE;
   
    CURSOR BV_DATA IS
        SELECT   TECH_REPORT_NUMBER
                ,OD_PROJ_NUMBER
                ,OD_ITEM_NUMBER
                ,SUBSTR(FAILURE_CODE,1,length(FAILURE_CODE)-1) AS FAILURE_CODE             
          FROM  XXMER.XX_QA_VENDOR_DATA_FC_TEMP
    ;
    
BEGIN
        l_user_name      := FND_PROFILE.value('USERNAME');
        
        --DBMS_OUTPUT.put_line('Before cursor');
     BEGIN  
       FOR BV_DATA_REC IN BV_DATA
       LOOP
            --DBMS_OUTPUT.put_line('Before insert');
              INSERT INTO q_od_pb_failure_codes_iv
                     (    PROCESS_STATUS
                        , ORGANIZATION_CODE
                        , PLAN_NAME
                        , INSERT_TYPE
                        , MATCHING_ELEMENTS
                        , OD_PB_TECH_RPT_NUM
                        , OD_PB_PROJ_NUM
                        , OD_PB_ITEM_ID
                        , OD_PB_FAILURE_CODES              
                        , QA_LAST_UPDATED_BY_NAME
                        , QA_CREATED_BY_NAME 
                     )
               VALUES
                    (     '1'
                        , 'PRJ'
                        , 'OD_PB_FAILURE_CODES'
                        , '1' --1for update
                        , 'OD_PB_TECH_RPT_NUM'
                        , BV_DATA_REC.TECH_REPORT_NUMBER
                        , NVL(BV_DATA_REC.OD_PROJ_NUMBER,'NULL')
                        , NVL(BV_DATA_REC.OD_ITEM_NUMBER,'NULL')
                        , NVL(BV_DATA_REC.FAILURE_CODE,'NULL')
                        , l_user_name 
                        , l_user_name 
                      );
                                                   
       END LOOP;
   END;
     COMMIT;
     
     EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
         DBMS_OUTPUT.put_line('Undefind Err Msg: ' ||SQLERRM);
         
END XXOD_QA_INSERT_BV_FAILCODE;
 

END XX_QA_PA_INTERFACE_PKG; 
/


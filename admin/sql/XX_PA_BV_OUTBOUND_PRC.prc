CREATE OR REPLACE PROCEDURE XX_PA_BV_OUTBOUND_PRC (errbuf OUT VARCHAR2,
                                                  retcode OUT VARCHAR2) IS
    
  /**********************************************************************************
   Program Name: XX_PA_OUTBOUND_PRC
   Purpose:  This procedure Extract the Projects data and Create the .xls file
             in the Outbound directory.
   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     17-Oct-2007 Siva Boya, Clear path Technologies. Created base version.
  
  **********************************************************************************/
  l_file_name             VARCHAR2(100) ;
  l_out_put_dir           VARCHAR2(100) ;
  fhandle                 UTL_FILE.FILE_TYPE;
  l_write_data            VARCHAR2(5000);
  l_header                VARCHAR2(1000);  
    
    CURSOR PA_DATA IS
        SELECT   pa.segment1 project_number, pa.NAME project_name,
                 pa.description project_description,
                 pf.first_name||' '||pf.last_name brand_management_contact,
                 eeb2.c_ext_attr1 domestic_import, eeb2.c_ext_attr2 sourcing_agent,
                 eeb1.c_ext_attr10 odpb_project_id, eeb1.c_ext_attr8 item_description,
                 eeb1.c_ext_attr6 sku, eeb1.c_ext_attr9 vendor_vpc,
                 eeb2.c_ext_attr4 vendor_name, eeb2.c_ext_attr5 vendor_contact_name,
                 eeb2.c_ext_attr6 vendor_contact_phone,
                 eeb2.c_ext_attr7 vendor_contact_email,
                 eeb2.c_ext_attr3 country_of_origin, eeb1.c_ext_attr7 bv_action_code
            FROM pa_projects pa,
                 pa_project_statuses ps,
                 pa_project_players pp,
                 per_all_people_f pf,
                 pa_projects_erp_ext_b eeb1,
                 ego_fnd_dsc_flx_ctx_ext fnd1,
                 pa_projects_erp_ext_b eeb2,
                 ego_fnd_dsc_flx_ctx_ext fnd2
           WHERE pa.project_id = pp.project_id
             AND pp.person_id = pf.person_id
             AND pa.project_id = eeb1.project_id
             AND eeb1.attr_group_id = fnd1.attr_group_id
             AND pa.project_id = eeb2.project_id
             AND eeb2.attr_group_id = fnd2.attr_group_id
             AND fnd1.descriptive_flex_context_code = 'QA'
             AND fnd2.descriptive_flex_context_code = 'PB_SOURCING'
             AND pp.project_role_type = 'PROJECT MANAGER'
             AND pa.project_status_code=ps.project_status_code
             AND ps.project_status_name IN ('Approved','Cancelled','On Hold')
        ORDER BY pa.segment1;
       
  BEGIN
        
         l_file_name    :='Qry_Export_BV.xls';
         l_out_put_dir  :='XXMER_OUTBOUND'; 
                 
         l_header       := 'PB_Project_Number'||chr(9)||'Project_Name'||chr(9)||'Project_Description'||chr(9)||'Brand_Management_Contact'||chr(9)||
                           'Domestic_or_Import'||chr(9)||'Sourcing_Agent'||chr(9)||'PB_Project_item_id'||chr(9)||
                           'Item_Description'||chr(9)||'SKU_Number'||chr(9)||'Vendor_VPC'||chr(9)||'Vendor_Name'||chr(9)||
                           'Vendor_Contact_Name'||chr(9)||'Vendor_Contact_Phone'||chr(9)||'Vendor_Contact_Email'||chr(9)||
                           'Country_Origion'||chr(9)||'BV_Action_Code';  
         
         fhandle:=UTL_FILE.FOPEN(l_out_put_dir,l_file_name,'W'); 
         
         UTL_FILE.PUT_LINE(fhandle,l_header);
  
          FOR PA_DATA_REC IN PA_DATA
          LOOP
          
          l_write_data :=PA_DATA_REC.PROJECT_NUMBER           ||chr(9)||
                         PA_DATA_REC.PROJECT_NAME             ||chr(9)||
                         PA_DATA_REC.PROJECT_DESCRIPTION      ||chr(9)||
                         PA_DATA_REC.BRAND_MANAGEMENT_CONTACT ||chr(9)||
                         PA_DATA_REC.DOMESTIC_IMPORT          ||chr(9)||
                         PA_DATA_REC.SOURCING_AGENT           ||chr(9)||
                         PA_DATA_REC.ODPB_PROJECT_ID          ||chr(9)||
                         PA_DATA_REC.ITEM_DESCRIPTION         ||chr(9)||
                         PA_DATA_REC.SKU                      ||chr(9)||
                         PA_DATA_REC.VENDOR_VPC               ||chr(9)||
                         PA_DATA_REC.VENDOR_NAME              ||chr(9)||
                         PA_DATA_REC.VENDOR_CONTACT_NAME      ||chr(9)||
                         PA_DATA_REC.VENDOR_CONTACT_PHONE     ||chr(9)||
                         PA_DATA_REC.VENDOR_CONTACT_EMAIL     ||chr(9)||
                         PA_DATA_REC.COUNTRY_OF_ORIGIN        ||chr(9)||
                         PA_DATA_REC.BV_ACTION_CODE ;               
                      
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
      
  END XX_PA_BV_OUTBOUND_PRC; 
/
EXIT;

CREATE OR REPLACE PACKAGE BODY XX_PA_QUALITY_UPDATE_PKG IS
/**********************************************************************************
 Program Name: XX_PA_IDEA_PROJECT_PKG
 Purpose:      To Create Projects from PLM to Oracle Projects.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     24-SEP-2007 Siva Boya, Clearpath.         Created base version.
--
**********************************************************************************/
PROCEDURE XXOD_QUALITY_PROJECT_ATTR (retcode   OUT VARCHAR2,errbuf  OUT VARCHAR2) IS  
    
    l_total_records               NUMBER;
    l_valid_records               NUMBER;
    l_sku_number                  VARCHAR2(25);   
    l_prod_tech_number            VARCHAR2(25);
    l_prod_item_status            NUMBER;
    l_prod_corr_action_status     NUMBER;
    l_prod_comments               VARCHAR2(150);
    l_prod_test_results           VARCHAR2(10);
    l_art_tech_number             VARCHAR2(25);
    l_art_item_status             NUMBER;
    l_art_corr_action_status      NUMBER;
    l_art_comments                VARCHAR2(150);
    l_art_test_results            VARCHAR2(10);
    l_tra_tech_number             VARCHAR2(25);
    l_tra_item_status             NUMBER;
    l_tra_corr_action_status      NUMBER;
    l_tra_comments                VARCHAR2(150);
    l_tra_test_results            VARCHAR2(10);
                         
     /* Cursor to select Distinct project item ids */
     CURSOR proj_num IS      
           
         SELECT DISTINCT temp.proj_number
           FROM xx_pa_vendor_data_temp temp, pa_projects_erp_ext_b ppe
          WHERE temp.proj_number = ppe.c_ext_attr10;
     
     /* Cursor to select Distinct Test types */       
     CURSOR test_type (p_proj_num xx_pa_vendor_data_temp.PROJ_NUMBER%TYPE)  IS
     
         SELECT DISTINCT temp.testing_type, temp.proj_number
           FROM xx_pa_vendor_data_temp temp, pa_projects_erp_ext_b ppe
          WHERE temp.proj_number = ppe.c_ext_attr10
            AND temp.proj_number = p_proj_num;
            
   
 BEGIN
        BEGIN
           /* Total Records to Process */                         
           SELECT COUNT (*) total_records
                   INTO l_total_records
                   FROM xx_pa_vendor_data_temp;
              EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                        l_total_records:=0;
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Records Found');
        END;
                
        BEGIN
           /* Total Valide Records to Process */ 
           SELECT COUNT (*) valid_records
                   INTO l_valid_records
                   FROM xx_pa_vendor_data_temp temp,pa_projects_erp_ext_b ppe
                  WHERE temp.proj_number=ppe.C_EXT_ATTR10 ;
              EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                        l_valid_records:=0;
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Valid Records Found');
        END;
                     
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records :'||l_total_records);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Valid Records :'||l_valid_records);
       
    FOR proj_num_rec IN proj_num
    LOOP    
        l_prod_tech_number        :=NULL;
        l_prod_item_status        :=NULL;
        l_prod_corr_action_status :=NULL;
        l_prod_comments           :=NULL;
        l_prod_test_results       :=NULL;                         
        l_art_tech_number         :=NULL;
        l_art_item_status         :=NULL;
        l_art_corr_action_status  :=NULL;
        l_art_comments            :=NULL;
        l_art_test_results        :=NULL;                       
        l_tra_tech_number         :=NULL;
        l_tra_item_status         :=NULL;
        l_tra_corr_action_status  :=NULL;
        l_tra_comments            :=NULL;
        l_tra_test_results        :=NULL;  
          
       BEGIN
            SELECT distinct sku_number
              INTO l_sku_number 
              FROM xx_pa_vendor_data_temp
             WHERE proj_number=proj_num_rec.proj_number;
         EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   l_sku_number :=NULL;
                   FND_FILE.PUT_LINE(fnd_file.LOG,'No Sku For Project_item_id:'||proj_num_rec.PROJ_NUMBER);
                  DBMS_OUTPUT.put_line('No Sku For Project_item_id:'||proj_num_rec.PROJ_NUMBER);
       END;
        
       FOR test_type_rec IN test_type(proj_num_rec.PROJ_NUMBER)
       LOOP
                             
          IF test_type_rec.TESTING_TYPE='PRODUCT'
          THEN                           
                SELECT temp.tech_report_number, temp.status, temp.corrective_action_status,
                       temp.comments, temp.test_results
                  INTO l_prod_tech_number, l_prod_item_status, l_prod_corr_action_status,
                       l_prod_comments, l_prod_test_results
                  FROM xx_pa_vendor_data_temp temp
                 WHERE temp.proj_number = test_type_rec.proj_number            
                   AND temp.testing_type = test_type_rec.testing_type              
                   AND temp.status_timestamp =(SELECT MAX (temp.status_timestamp)
                                                 FROM xx_pa_vendor_data_temp temp
                                                WHERE temp.proj_number = test_type_rec.proj_number
                                                  AND temp.testing_type = test_type_rec.testing_type);
          
          ELSIF test_type_rec.TESTING_TYPE='ARTWORK'
          THEN                                                             
                SELECT temp.tech_report_number, temp.status, temp.corrective_action_status,
                       temp.comments, temp.test_results
                  INTO l_art_tech_number, l_art_item_status, l_art_corr_action_status,
                       l_art_comments, l_art_test_results
                  FROM xx_pa_vendor_data_temp temp
                 WHERE temp.proj_number = test_type_rec.proj_number
                   AND temp.testing_type = test_type_rec.testing_type
                   AND temp.status_timestamp =(SELECT MAX (temp.status_timestamp)
                                                 FROM xx_pa_vendor_data_temp temp
                                                WHERE temp.proj_number = test_type_rec.proj_number
                                                  AND temp.testing_type = test_type_rec.testing_type);
                   
          ELSIF test_type_rec.TESTING_TYPE='TRANSIT'
          THEN                
                SELECT temp.tech_report_number, temp.status, temp.corrective_action_status,
                       temp.comments, temp.test_results
                  INTO l_tra_tech_number, l_tra_item_status, l_tra_corr_action_status,
                       l_tra_comments, l_tra_test_results
                  FROM xx_pa_vendor_data_temp temp
                 WHERE temp.proj_number = test_type_rec.proj_number
                   AND temp.testing_type = test_type_rec.testing_type
                   AND temp.status_timestamp =(SELECT MAX (temp.status_timestamp)
                                                 FROM xx_pa_vendor_data_temp temp
                                                WHERE temp.proj_number = test_type_rec.proj_number
                                                  AND temp.testing_type = test_type_rec.testing_type);
                   
          END IF;                
       END LOOP;       
           BEGIN
            /* Update the Project Attributes */    
                UPDATE pa_projects_erp_ext_b
                   SET c_ext_attr6  = l_sku_number,
                       c_ext_attr11 = l_prod_tech_number,
                       n_ext_attr4  = l_prod_item_status,
                       n_ext_attr7  = l_prod_corr_action_status,
                       c_ext_attr14 = l_prod_comments,
                       c_ext_attr17 = SUBSTR (l_prod_test_results, 1, 4),
                       c_ext_attr12 = l_art_tech_number,
                       n_ext_attr5  = l_art_item_status,
                       n_ext_attr8  = l_art_corr_action_status,
                       c_ext_attr15 = l_art_comments,
                       c_ext_attr18 = SUBSTR (l_art_test_results, 1, 4),
                       c_ext_attr13 = l_tra_tech_number,
                       n_ext_attr6  = l_tra_item_status,
                       n_ext_attr9  = l_tra_corr_action_status,
                       c_ext_attr16 = l_tra_comments,
                       c_ext_attr19 = SUBSTR (l_tra_test_results, 1, 4),
                       LAST_UPDATE_DATE = SYSDATE
                 WHERE c_ext_attr10 = proj_num_rec.proj_number;
             EXCEPTION 
                  WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(fnd_file.LOG,'Error Updating Attr Table For :'||proj_num_rec.proj_number||sqlerrm);
                      DBMS_OUTPUT.put_line('Error Updating Attr Table :Project_item_id:'||proj_num_rec.proj_number);
               
           END;         
    END LOOP;  
  COMMIT;   
  EXCEPTION
       WHEN OTHERS THEN
            FND_FILE.PUT_LINE(fnd_file.LOG, 'Unhandled exception: '||SQLERRM);     
 END;  
END;
/
EXIT;
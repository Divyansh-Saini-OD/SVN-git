CREATE OR REPLACE PACKAGE BODY XX_PA_CREATE_ITEMID_PKG IS
/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA/QA-Project                     |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_CREATE_ITEMID_PKG                             |
-- | Description:  This procedure is Created for the PBCGS PA to QA    |
-- |               as a concurrent program which will auto create      |
-- |               item ids for projects with a new or revised SKU NUM |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      14-Apr-2008  Ian Bassaragh    Created This procedure      |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
PROCEDURE XXOD_CREATE_ITEMID ( retcode     OUT VARCHAR2,
                             errbuf        OUT VARCHAR2,
                             p_project_id   IN VARCHAR2,
                             p_num_skus     IN VARCHAR2,
                             p_updated_by   IN VARCHAR2                                                        
                             ) IS
   
   x_project_id             NUMBER;
   x_num_skus               NUMBER;
   x_updated_by             NUMBER;
   x_project_number         PA_PROJECTS_ALL.SEGMENT1%TYPE;
   x_sku_id                 PA_PROJECTS_ERP_EXT_B.C_EXT_ATTR10%TYPE;
   x_sku_count              NUMBER;
   x_max_skuid              NUMBER;
   x_new_ext_id             NUMBER;
   x_attr_id                NUMBER;
   x_rows                   NUMBER;
   x_login                  NUMBER;
 
 BEGIN
                         
      BEGIN
          x_project_id     := TO_NUMBER(p_project_id);
          x_num_skus       := TO_NUMBER(p_num_skus);
          x_updated_by     := TO_NUMBER(p_updated_by); 
          x_project_number :=NULL;
          x_sku_count      :=NULL;
          x_new_ext_id     :=NULL;
          x_attr_id        :=NULL;

          /* Get the PA Project Number that had SKU count changes  */ 
	  SELECT 
                PA1.SEGMENT1,
                PA1.LAST_UPDATE_LOGIN
           INTO x_project_number, x_login
           FROM APPS.PA_PROJECTS_ALL PA1 
          WHERE PA1.PROJECT_ID = x_project_id
            AND PA1.TEMPLATE_FLAG = 'N';

          IF x_project_number IS NOT NULL
          THEN
   
            BEGIN
                /* Get the total number of existing valid SKUs for the Project  */ 
	  	SELECT 
	       	      COUNT(*)
                 INTO x_sku_count
 	         FROM APPS.PA_PROJECTS_ALL PA LEFT OUTER JOIN
                     (APPS.PA_PROJECTS_ERP_EXT_B EEB1
                 JOIN APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 
                   ON EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                      FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'QA') 
                   ON PA.PROJECT_ID = EEB1.PROJECT_ID
                WHERE EEB1.PROJECT_ID = x_project_id
                  AND PA.TEMPLATE_FLAG = 'N';
                                     
                IF x_sku_count IS NULL
                THEN
                   x_sku_count := 0;
                END IF;
             
                             

               /* Get the UAD attribute ID for insert  */ 
                SELECT FNDX.ATTR_GROUP_ID
                  INTO x_attr_id
  		  FROM APPS.EGO_FND_DSC_FLX_CTX_EXT FNDX
    		 WHERE FNDX.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'QA'
                   AND FNDX.APPLICATION_ID = 275;

                IF x_attr_id IS NULL
                THEN
                   x_attr_id := 124;
                END IF;	

                /* Get the max project sku id being used for next values */ 
                SELECT
                      NVL( MAX(TO_NUMBER(SUBSTR(EEB2.C_EXT_ATTR10,LENGTH(x_project_number)+2)) ),0)
                 INTO x_max_skuid
                 FROM APPS.PA_PROJECTS_ERP_EXT_B EEB2
                 JOIN APPS.EGO_FND_DSC_FLX_CTX_EXT FND2
                   ON EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                      FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'QA'
                WHERE EEB2.C_EXT_ATTR10 LIKE x_project_number||'%';

		EXCEPTION
                  WHEN INVALID_NUMBER
                       THEN
                         x_max_skuid := 0;

	    END;	
         
	    IF x_num_skus > x_sku_count
            THEN
               
               x_rows := (x_num_skus - x_sku_count);
              
              
               BEGIN

	       -- Build the SKU ID and insert the attribute rows
     	       
                  FOR I IN 1..x_rows LOOP
                     
                      x_max_skuid := x_max_skuid + 1;
                      x_sku_id := x_project_number||'-'||x_max_skuid;

                     --- Get the extension id to use 
                     SELECT EGO_EXTFWK_S.NEXTVAL INTO x_new_ext_id FROM DUAL;


                      --- GET ORACLE API TO INSERT PA_PROJECT_ERP_EXT_B ROWS -----
                     BEGIN
                 
                      INSERT INTO APPS.PA_PROJECTS_ERP_EXT_B
        			(EXTENSION_ID       
         			,PROJECT_ID         
         			,ATTR_GROUP_ID      
         			,CREATED_BY         
         			,CREATION_DATE 
         			,LAST_UPDATED_BY          
         			,LAST_UPDATE_DATE   
         			,C_EXT_ATTR10
                                ,C_EXT_ATTR5
                                ,C_EXT_ATTR8
                                ,LAST_UPDATE_LOGIN       
				)
    		             VALUES
        		  	(x_new_ext_id
         			,x_project_id
         			,x_attr_id
         			,x_updated_by
         			,SYSDATE
         			,x_updated_by
         			,SYSDATE
         			,x_sku_id
                                ,'New_Item'
                                ,'To Be Entered'
                                ,x_login
          		       );
                        EXCEPTION
                         WHEN OTHERS THEN
                          DBMS_OUTPUT.put_line('Error Inserting uad,Project Number :'||x_project_number||SQLERRM);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Inserting UAD,Project Number :'||x_project_number||SQLERRM);

                     END;


		 END LOOP;

                BEGIN

                 INSERT INTO PA_PROJECTS_ERP_EXT_TL (
    			EXTENSION_ID,
    			PROJECT_ID,
    			PROJ_ELEMENT_ID,
    			ATTR_GROUP_ID,
    			CREATED_BY,
    			CREATION_DATE,
    			LAST_UPDATED_BY,
    			LAST_UPDATE_DATE,
    			LAST_UPDATE_LOGIN,
    			LANGUAGE,
    			SOURCE_LANG
  			) SELECT
    			B.EXTENSION_ID,
    			B.PROJECT_ID,
    			B.PROJ_ELEMENT_ID,
    			B.ATTR_GROUP_ID,
    			B.CREATED_BY,
    			B.CREATION_DATE,
    			B.LAST_UPDATED_BY,
    			B.LAST_UPDATE_DATE,
    			B.LAST_UPDATE_LOGIN,
    			'US',
    			'US'
 		  FROM  PA_PROJECTS_ERP_EXT_B B
 			WHERE B.PROJECT_ID = x_project_id AND B.ATTR_GROUP_ID = x_attr_id
       			AND NOT EXISTS
    			(SELECT T.EXTENSION_ID
    				FROM PA_PROJECTS_ERP_EXT_TL T
    				WHERE T.EXTENSION_ID = B.EXTENSION_ID);
                    EXCEPTION
                         WHEN OTHERS THEN
                          DBMS_OUTPUT.put_line('Error Inserting uad,Project Number :'||x_project_number||SQLERRM);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Inserting UAD,Project Number :'||x_project_number||SQLERRM);

                END;

                
              END;
            ELSE
               RAISE NO_DATA_FOUND;
            END IF;

         ELSE
	
          RAISE NO_DATA_FOUND;
         
	END IF;
    
     END;
 COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN            
    DBMS_OUTPUT.put_line('No data Found');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No data Found');  
    WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('Unhandled exception Found:'||SQLERRM);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unhandled exception Found:'||SQLERRM);                
 END;  
      
END   XX_PA_CREATE_ITEMID_PKG; 
/
EXIT;

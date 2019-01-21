create or replace 
PACKAGE BODY XX_TOPS_RETIRE_OAF_PKG
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |            Oracle Office Depot   Organization                                             |
-- +===========================================================================================+
-- | Name        : XX_TOPS_RETIRE_OAF_PKG                                                          |
-- | Description : This package is developed to TOPS Retire Project to Drop OAF Pages from Mds repository            |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version     Date           Author               Remarks                                    |
-- |=======    ==========      ================     ===========================================|
-- |1.0        11-May-2016     Shubashree Rajanna   Initial draft version                     |
-- |1.1        19-Aug-2016     Shubashree Rajanna   removed schema references                  |
-- +===========================================================================================+
AS

G_REQUEST_ID NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  
-- +===================================================================+
-- | Name        : main                                                |
-- | Description : This program is directly called from the concurrent | 
-- |               Program to drop objects                             |
-- |                                                                   |
-- | Parameters  : P_DROP_FLAG flag list objects or drop               |
-- +===================================================================+
PROCEDURE MAIN(X_ERRBUF OUT  VARCHAR2,X_RETCODE OUT  VARCHAR2,P_DROP_FLAG  VARCHAR2) IS

  L_RET_STATUS VARCHAR2(2):='S';
  X_RET_STATUS VARCHAR2(2);
  L_COUNTER    number:=1;
  l_inv_cou    number:=null;
  l_error_msg  VARCHAR2(2000);
  lc_err_flag  VARCHAR2(2) := 'N';
begin  
    
    
    fnd_file.put_line(fnd_file.output,'================================================================== Drop OAF customizations program Start ===============================================');
    --Delete the contents of retired objects
    DELETE XXOD_RETIRED_OBJECTS;
    -- Update all the records with the request Id.
    UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
       SET REQUEST_ID = G_REQUEST_ID
     WHERE STATUS = 'N';
    COMMIT;
    
    -- For loop to read the objects from custom table and drop objects squentially
        FOR I IN (SELECT * 
                    FROM XXOD_TOPS_RETIRE_OAF_TABLE 
                    where STATUS = 'N'
                      and page_type = 'C'
                      AND DROP_FLAG = 'Y'
                  ) LOOP
                  
            L_RET_STATUS:='S';     
            X_RET_STATUS:='S';
            
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------------  ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_counter||')  '||'Page  :  '||I.PAGE_NAME);
          
          L_COUNTER:=L_COUNTER+1;
          l_error_msg := NULL;
          
          --List all the functions 
          FOR J IN (   SELECT * FROM FND_FORM_FUNCTIONS 
                        WHERE TYPE = 'JSP' 
                          AND WEB_HTML_CALL LIKE '%'||I.PAGE_NAME||'%'
                    )
          LOOP
             --
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Function:  '||J.FUNCTION_NAME);
             INSERT INTO XXOD_RETIRED_OBJECTS VALUES (J.FUNCTION_ID, J.FUNCTION_NAME, -1, NULL, -1, NULL);
             COMMIT;
             lc_err_flag := 'N';
             --Open all the menus entries with function Id 
             FOR K IN ( SELECT * FROM
                      (SELECT 
                            fr.responsibility_id
                           , frt.responsibility_name
                           , fr.end_date
                           , fr.menu_id
                           , fmv.user_menu_name
                           , fme.entry_sequence
                           , fmet.prompt
                           , fme.sub_menu_id
                           , fme.function_id
                           , fme.grant_flag
                        FROM  fnd_responsibility fr
                           , fnd_menus_vl fmv
                           , fnd_responsibility_tl frt
                           , fnd_menu_entries fme
                           , fnd_menu_entries_tl fmet
                       --joins and constant selection
                       WHERE fr.menu_id = fmv.menu_id(+)
                         AND fr.responsibility_id = frt.responsibility_id(+)
                         AND fr.menu_id = fme.menu_id(+)
                         AND fme.menu_id = fmet.menu_id(+)
                         AND fme.entry_sequence = fmet.entry_sequence(+)
                         AND fmet.language = 'US'
                         AND fme.function_id = J.FUNCTION_ID
                      UNION
                      SELECT 
                            fr.responsibility_id
                           , frt.responsibility_name
                           , fr.end_date
                           , fr.menu_id
                           , fmv.user_menu_name
                           , fme.entry_sequence
                           , fmet.prompt
                           , fme.sub_menu_id
                           , fme.function_id
                           , fme.grant_flag
                        FROM  fnd_responsibility fr
                           , fnd_menus_vl fmv
                           , fnd_responsibility_tl frt
                           , fnd_menu_entries fme
                           , fnd_menu_entries_tl fmet
                       --joins and constant selection
                       WHERE fr.menu_id = fmv.menu_id(+)
                         AND fr.responsibility_id = frt.responsibility_id(+)
                         AND fr.menu_id = fme.menu_id(+)
                         AND fme.menu_id = fmet.menu_id(+)
                         AND fme.entry_sequence = fmet.entry_sequence(+)
                         AND fmet.language = 'US'
                         AND fme.sub_menu_id in ( select menu_id from fnd_menu_entries where function_id = J.FUNCTION_ID)) RESP_MENUS
                    ORDER BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
             )LOOP
                --
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Menu:  '||K.USER_MENU_NAME||'  Responsibility:  '||K.RESPONSIBILITY_NAME);
                INSERT INTO XXOD_RETIRED_OBJECTS VALUES (J.FUNCTION_ID, J.FUNCTION_NAME, K.MENU_ID, K.USER_MENU_NAME, K.RESPONSIBILITY_ID, K.RESPONSIBILITY_NAME);
                COMMIT;
                IF p_drop_flag = 'Y'  THEN
                    -- end date the responsibilities if already not end dated.
                    BEGIN
                       --Update the responsibility end_date to sysdate if the end_date is null
                       UPDATE FND_RESPONSIBILITY
                          SET END_DATE = SYSDATE
                        WHERE responsibility_id = K.RESPONSIBILITY_ID
                          AND end_date IS null;
                       commit;
                    EXCEPTION
                       WHEN OTHERS THEN
                         --
                         lc_err_flag := 'Y';
                         l_error_msg := 'Error occured while end dating  the responsibility : '||K.RESPONSIBILITY_NAME || ' Error: '||SQLERRM;
                         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_error_msg);
                         UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
                            SET STATUS = 'E',
                                COMMENTS = l_error_msg
                          WHERE PAGE_NAME = I.PAGE_NAME;
                          COMMIT;
                    END;
                END IF;
             END LOOP;
             --Delete the Function
             IF p_drop_flag = 'Y'  THEN
                --delete the function and commit.
                BEGIN
                   DELETE FND_FORM_FUNCTIONS 
                    WHERE FUNCTION_ID = J.FUNCTION_ID;
                   COMMIT;
                EXCEPTION
                  WHEN OTHERS THEN
                     --
                     lc_err_flag := 'Y';
                     l_error_msg := 'Error occured while delete the function : '||J.FUNCTION_NAME || ' Error: '||SQLERRM;
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_error_msg);
                     UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
                        SET STATUS = 'E',
                            COMMENTS = l_error_msg
                      WHERE PAGE_NAME = I.PAGE_NAME;
                      COMMIT;
                END;
             END IF;
          END LOOP;               
          --Delete the document from mds.
          IF p_drop_flag = 'Y' THEN
             
             IF lc_err_flag = 'N' THEN 
                 --
                 --delet the document 
                 jdr_utils.deleteDocument(I.PAGE_NAME);
                 UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
                    SET STATUS = 'S'
                  WHERE PAGE_NAME = I.PAGE_NAME;
             END IF;
             COMMIT;
          END IF;
        END LOOP;
        
    fnd_file.put_line(fnd_file.output,'==================================================================== Personalization files ==============================================-');    
    L_COUNTER := 1;
    FOR L IN (SELECT * FROM XXOD_TOPS_RETIRE_OAF_TABLE 
                    where STATUS = 'N'
                      and page_type = 'P'
                      AND DROP_FLAG = 'Y') LOOP
       --
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------------  ');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_counter||')  '||'Page  :  '||L.PAGE_NAME);
          
       L_COUNTER:=L_COUNTER+1;
       IF P_DROP_FLAG = 'Y' THEN
          BEGIN
             JDR_UTILS.DELETEDOCUMENT(L.PAGE_NAME);
             UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
                        SET STATUS = 'S'
                      WHERE PAGE_NAME = L.PAGE_NAME;
          EXCEPTION
             WHEN OTHERS THEN
                l_error_msg := 'Error occured while deleting the MDS document: '||SQLERRM;
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_error_msg);
                UPDATE XXOD_TOPS_RETIRE_OAF_TABLE
                        SET STATUS = 'E',
                            COMMENTS = l_error_msg
                      WHERE PAGE_NAME = L.PAGE_NAME;
                COMMIT;
          END;
       END IF;
    END LOOP;
    
       
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    --PRITN ALL THE FND OBJECTS THAT WERE RETIRED
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*****************************************************************Retired / End dated FND Objects*********************************************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Function Name, Menu Name, Responsibility Name');
    FOR recs IN (SELECT * FROM XXOD_RETIRED_OBJECTS) LOOP
       --
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, recs.FUNCTION_NAME||', '||
                                          recs.MENU_NAME||', '||
                                          recs.RESPONSIBILITY_NAME);
    END LOOP;
    fnd_file.put_line(fnd_file.output,'==================================================================== Drop objects program End ==============================================-'); 
  EXCEPTION 
    WHEN OTHERS THEN 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception in Main Program : '||SQLERRM);
      X_RETCODE:=2;
  END MAIN;

      
END XX_TOPS_RETIRE_OAF_PKG ;
/

SHOW ERRORS;
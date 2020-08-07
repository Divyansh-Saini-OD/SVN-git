CREATE OR REPLACE PACKAGE BODY XX_GI_WAC_TEMP_UPLOAD_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  Oracle NAIO                                                   |
-- +================================================================================+
-- | Name       : XX_GI_WAC_TEMP_UPLOAD_PKG                                         |
-- |                                                                                |
-- | Description: This package  is used to upload the template file from Linux to   |
-- |              fnd_lobs table                                                    |              
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  23-JUL-07      Mithun D S       Initial draft version                 |
-- |1.1       08-OCT-07      Archie           Modified for CR to fetch              |
-- |                                          only one template                     |
-- +================================================================================+

PROCEDURE UPLOAD_TEMPLATE (
                             x_errbuf     OUT VARCHAR2 -- Standard Out variable
                            ,x_retcode    OUT NUMBER   -- Standard Out variable
                          )

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  Oracle NAIO                                                   |
-- +================================================================================+
-- | Name       : UPLOAD_TEMPLATE                                                   |
-- |                                                                                |
-- | Description: This procedure is used to upload the template file from Linux to  |
-- |              fnd_lobs table                                                    |  
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  23-JUL-07      Mithun D S       Initial draft version                 |
-- +================================================================================+

IS

ex_no_prof         EXCEPTION;
lc_prof            VARCHAR2(1000);
lc_file_loc        BFILE;
lc_diagram_loc     BLOB;
ln_diagram_size    INTEGER;

BEGIN

  FND_PROFILE.GET('XX_GI_WAC_TEMP_UPLOAD',lc_prof);
  
  IF (lc_prof IS NULL) THEN
  
     RAISE ex_no_prof;
  
  END IF;
  
  -- Delete already existing template files from fnd_lobs
  BEGIN
  
     DELETE FROM fnd_lobs
     WHERE  FILE_NAME IN ('Template.xls')
     AND    PROGRAM_NAME = 'OD_GI_WCA_EXT_TEMPLATE';

     COMMIT;
     
  EXCEPTION 
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No rows to delelte in fnd_lobs'|| sqlerrm);

  END;

  BEGIN
  
    lc_file_loc      := BFILENAME(lc_prof,'Template.xls');
    ln_diagram_size  := DBMS_LOB.GETLENGTH(lc_file_loc);
    
    DBMS_LOB.FILEOPEN(lc_file_loc,dbms_lob.file_readonly); 
    
    -- Inserting Template.xls file into fnd_lobs
    INSERT INTO FND_LOBS 
    (
      FILE_ID            
     ,FILE_NAME          
     ,FILE_CONTENT_TYPE  
     ,FILE_DATA          
     ,UPLOAD_DATE        
     ,EXPIRATION_DATE    
     ,PROGRAM_NAME       
     ,PROGRAM_TAG        
     ,LANGUAGE           
     ,ORACLE_CHARSET     
     ,FILE_FORMAT        
    )
    VALUES 
    (  
      fnd_lobs_s.nextval
     ,'Template.xls'
     ,'application/vnd.ms-excel; charset=UTF-8'
     ,EMPTY_BLOB
     ,SYSDATE
     ,NULL
     ,'OD_GI_WCA_EXT_TEMPLATE'
     ,NULL
     ,'US'
     ,'UTF8'
     ,'BINARY'
    )    
    RETURNING FILE_DATA INTO lc_diagram_loc;
 
    DBMS_LOB.LOADFROMFILE(lc_diagram_loc, lc_file_loc, ln_diagram_size);
    COMMIT;
    
    DBMS_LOB.fileclose(lc_file_loc);
  
  EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error inserting Template.xls into fnd_lobs'|| sqlerrm);
         x_retcode := 1;
  END;
  
  
  x_retcode := 0;

EXCEPTION
   WHEN ex_no_prof THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No profile value defined for UNIX Path in XX_GI_WAC_TEMP_UPLOAD');
        x_retcode := 2;
  
   WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to load template file'|| sqlerrm);
        x_retcode := 2;
  
END UPLOAD_TEMPLATE;

END XX_GI_WAC_TEMP_UPLOAD_PKG;
/
SHOW ERROR;
EXIT;
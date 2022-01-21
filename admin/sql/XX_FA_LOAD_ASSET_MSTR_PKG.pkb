create or replace
PACKAGE BODY   XX_FA_LOAD_ASSET_MSTR_PKG
AS

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization                                |
    -- +===================================================================+
    -- | Name  : XX_FA_LOAD_ASSET_MSTR_PKG                                 |
    -- | Description: CR865 Loading Reinstated asset to the mass_additions |
    -- | table and loading Accelerated Assets to the FA_TAX_iNTERFACE.     |
    -- | Updating the FA_TAX_INTERFACE table with adjustments from the     |
    -- | reinstated assets.                                                |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |1.7       30-Oct-2015 Madhu Bolli      122 Retrofit - Remove schema|
    -- +===================================================================+


    ---------------------
    -- Global Variables
    ---------------------
    gc_current_step        VARCHAR2(500); 
    GN_USER_ID             NUMBER   := FND_PROFILE.VALUE('USER_ID');
    gn_SOB_id              NUMBER   := FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
    gn_request_id          NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();
    

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : Validation_Report                                         |
    -- | Description : Procedure to allow user to run validation report    |
    -- |                                                                   |  
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    procedure VALIDATION_REPORT (ERRBUFF               OUT NOCOPY VARCHAR2 
                                ,RETCODE               OUT NOCOPY VARCHAR2 
                                ,P_BOOK_TYPE_CODE1     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE2     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE3     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE4     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE5     IN VARCHAR2   
                                ,P_ATTRIBUTE11         IN VARCHAR2
                                ,P_PERIOD_NAME         IN NUMBER
                                ,P_DELIMITER           IN VARCHAR2
                                 )
     AS  



        LC_PERIOD_NAME_DISP  VARCHAR2(15);
        LC_CONCAT_BOOKS      VARCHAR2(1000);
        ln_counter           NUMBER;

        -------------------
        -- Define Cursor
        ------------------- 
        CURSOR C_VAL_REPORT
            is           
            select FAB.ATTRIBUTE13            -- as BU,
                   ,DTL.BOOK_TYPE_CODE         -- as BOOK,
                   ,FAA.ASSET_ID               -- as ORACLE_ID,
                   ,FAB.ATTRIBUTE6             -- as PSFT_ID,
                   ,FAB.ATTRIBUTE10            -- as BNA_ID,
                   ,FAB.ATTRIBUTE_CATEGORY_CODE-- as ORACLE_CATEGORY,
                   ,FAA.cost                   -- as ORACLE_COST,
                   ,DTL.DEPRN_AMOUNT
                   ,DTL.YTD_DEPRN
                   ,DTL.DEPRN_RESERVE
                   ,FAA.DEPRN_METHOD_CODE      -- as ORACLE_METHOD,
                   ,FAA.LIFE_IN_MONTHS
                   ,FAA.PRORATE_CONVENTION_CODE -- as CONVENTION,
                   ,FAA.DATE_PLACED_IN_SERVICE  --as DATE_PIS,
                   ,DTL.PERIOD_COUNTER
                   ,FAB.ATTRIBUTE11
              from FA_BOOKS FAA,
                   FA_ADDITIONS_B FAB,
                   FA_DEPRN_DETAIL DTL
             where FAA.ASSET_ID       = FAB.ASSET_ID
               AND DTL.ASSET_ID       = FAB.ASSET_ID
               AND FAA.BOOK_TYPE_CODE IN (P_BOOK_TYPE_CODE1
                                         ,P_BOOK_TYPE_CODE2
                                         ,P_BOOK_TYPE_CODE3
                                         ,P_BOOK_TYPE_CODE4
                                         ,P_BOOK_TYPE_CODE5) 
               AND DTL.BOOK_TYPE_CODE = FAA.BOOK_TYPE_CODE
                   AND FAB.ATTRIBUTE11 LIKE  P_ATTRIBUTE11 ||'%' -- 24129 MAY-2009
               AND DTL.PERIOD_COUNTER = P_PERIOD_NAME 
               AND FAA.TRANSACTION_HEADER_ID_OUT IS NULL
              ORDER BY DTL.BOOK_TYPE_CODE, FAA.ASSET_ID;
              
     
    BEGIN
        
--    FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_BOOK_TYPE_CODE = '||P_BOOK_TYPE_CODE1);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_ATTRIBUTE11    = '||P_ATTRIBUTE11 );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PERIOD_NAME     = '||P_PERIOD_NAME);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_DELIMITER     = '||P_DELIMITER);
      -----------------------------------------                                
      -- Concat book type code for display only
      -----------------------------------------
      lc_concat_books := ''''||P_BOOK_TYPE_CODE1||'''';
      
      IF P_BOOK_TYPE_CODE2  IS NOT NULL
        THEN
         LC_CONCAT_BOOKS  := LC_CONCAT_BOOKS ||','''||P_BOOK_TYPE_CODE2||'''';
      END IF;   
     
      IF P_BOOK_TYPE_CODE3  IS NOT NULL
        THEN
         LC_CONCAT_BOOKS  := LC_CONCAT_BOOKS ||','''||P_BOOK_TYPE_CODE3||'''';
      END IF;        
    
      IF P_BOOK_TYPE_CODE4  IS NOT NULL
        THEN
         LC_CONCAT_BOOKS  := LC_CONCAT_BOOKS ||','''||P_BOOK_TYPE_CODE4||'''';
      END IF;    
  
      IF P_BOOK_TYPE_CODE5  IS NOT NULL
        THEN
         LC_CONCAT_BOOKS  := LC_CONCAT_BOOKS ||','''||P_BOOK_TYPE_CODE5||'''';
      END IF;  

      BEGIN
      
         SELECT distinct PERIOD_NAME 
           INTO LC_PERIOD_NAME_DISP
           FROM FA_DEPRN_PERIODS 
          where period_counter = P_PERIOD_NAME;
    
      END; 
    
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'ASSET VALIDATION REPORT '
                         || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PERIOD = '
                         || lc_period_name_disp );
                         
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'LABEL = '
                         || P_ATTRIBUTE11);                    
 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BOOK TYPES = '
                         ||LC_CONCAT_BOOKS );
                                  
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' '); 
    
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BU'
                   ||P_DELIMITER||'ASSET_BOOK'
                   ||P_DELIMITER||'ASSET_ID'
                   ||P_DELIMITER||'LEGACY_ASSET_ID'
                   ||P_DELIMITER||'TAX_ASSET_ID'
                   ||P_DELIMITER||'CATEGORY'
                   ||P_DELIMITER||'COST'
                   ||P_DELIMITER||'DEPRN_AMOUNT'
                   ||P_DELIMITER||'YTD_DEPRN'
                   ||P_DELIMITER||'DEPRN_RESERVE'
                   ||P_DELIMITER||'DEPRN_METHOD_CODE'
                   ||P_DELIMITER||'LIFE_IN_MONTHS'
                   ||P_DELIMITER||'PRO_CONVENT_CODE'
                   ||P_DELIMITER||'PLACED_IN_SERV_DATE'
                   ||P_DELIMITER||'PERIOD_COUNTER'
                   ||P_DELIMITER||'ATTRIBUTE11'
                        ); 
                                
      ln_counter := 0; 
      FOR LC_VAL_REPORT IN C_VAL_REPORT         
          LOOP     
                    
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                          LC_VAL_REPORT.ATTRIBUTE13             
                   ||P_DELIMITER||LC_VAL_REPORT.BOOK_TYPE_CODE         
                   ||P_DELIMITER||LC_VAL_REPORT.ASSET_ID               
                   ||P_DELIMITER||LC_VAL_REPORT.ATTRIBUTE6             
                   ||P_DELIMITER||LC_VAL_REPORT.ATTRIBUTE10            
                   ||P_DELIMITER||LC_VAL_REPORT.ATTRIBUTE_CATEGORY_CODE
                   ||P_DELIMITER||LC_VAL_REPORT.cost                   
                   ||P_DELIMITER||LC_VAL_REPORT.DEPRN_AMOUNT
                   ||P_DELIMITER||LC_VAL_REPORT.YTD_DEPRN
                   ||P_DELIMITER||LC_VAL_REPORT.DEPRN_RESERVE
                   ||P_DELIMITER||LC_VAL_REPORT.DEPRN_METHOD_CODE      
                   ||P_DELIMITER||LC_VAL_REPORT.LIFE_IN_MONTHS
                   ||P_DELIMITER||LC_VAL_REPORT.PRORATE_CONVENTION_CODE 
                   ||P_DELIMITER||LC_VAL_REPORT.DATE_PLACED_IN_SERVICE  
                   ||P_DELIMITER||LC_VAL_REPORT.PERIOD_COUNTER
                   ||P_DELIMITER||LC_VAL_REPORT.ATTRIBUTE11
                                  );   
              
                   ln_counter := ln_counter +1;
  
              end LOOP; 
       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total records count = '
                         || ln_counter);  
            
        ERRBUFF  :=0;   
            
    END VALIDATION_REPORT;
    
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : PURGE_INTERFACE_TBL                                       |
    -- | Description : Procedure for purging interface tables              |
    -- |                                                                   |  
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE REC_UPLOAD_RPT (ERRBUFF           OUT NOCOPY VARCHAR2
                             ,RETCODE           OUT NOCOPY VARCHAR2
                             ,P_MASS_RPT_FLG    IN  VARCHAR2 DEFAULT 'N'
                             ,P_TAX_RPT_FLG     IN  VARCHAR2 DEFAULT 'N'
                             ,P_ATTRIBUTE11     IN  VARCHAR2
                             ,p_attribute11_1   IN  VARCHAR2
                                   )
     AS  
        -------------------
        -- Define Cursor
        ------------------- 
        CURSOR C_TAX_INT_REC_RPT
            IS           
          SELECT  BOOK_TYPE_CODE
                 ,ASSET_NUMBER  
                 ,ATTRIBUTE10  --TAX_ASSET_ID     
                 ,ATTRIBUTE11  --TAX_RECONCILE
                 ,COST
                 ,DEPRN_RESERVE
                 ,YTD_DEPRN
                 ,LIFE_IN_MONTHS
                 ,DEPRN_METHOD_CODE
                 ,PRORATE_CONVENTION_CODE
                 ,POSTING_STATUS  
            FROM  FA_TAX_INTERFACE 
           WHERE POSTING_STATUS = 'POST'
             AND (ATTRIBUTE11 IN (P_ATTRIBUTE11,P_ATTRIBUTE11_1)
                  OR ATTRIBUTE11 IS NULL);
           
        CURSOR C_MASS_ADD_REC_RPT
            IS           
        SELECT
            BOOK_TYPE_CODE             
            ,ATTRIBUTE13               
	          ,ATTRIBUTE10               
	          ,ATTRIBUTE6                
	          ,ATTRIBUTE11               
	          ,ATTRIBUTE12               
	          ,DESCRIPTION               
	          ,FIXED_ASSETS_UNITS        
	          ,FIXED_ASSETS_COST         
	          ,DEPRN_RESERVE             
	          ,DATE_PLACED_IN_SERVICE    
	          ,LIFE_IN_MONTHS            
	          ,DEPRN_METHOD_CODE         
	          ,PRORATE_CONVENTION_CODE   
            ,POSTING_STATUS        
            ,MASS_ADDITION_ID
          FROM FA_MASS_ADDITIONS
         WHERE POSTING_STATUS = 'POST' 
           AND ATTRIBUTE11 IN (P_ATTRIBUTE11,P_ATTRIBUTE11_1);  
           
        LN_PURGE_CNT  NUMBER;   

    BEGIN
            
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_MASS_RPT_FLG  = '||P_MASS_RPT_FLG);            
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_TAX_RPT_FLG   = '||P_TAX_RPT_FLG);               
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_attribute11   = '||P_ATTRIBUTE11);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_attribute11_1 = '||p_attribute11_1);
        
        IF P_MASS_RPT_FLG = 'Y' THEN
            
            GC_CURRENT_STEP :=' Executeing upload MASS_ADDITIONS TABLE Report ';
            FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP); 
            
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                          'FA_MASS_ADDITIONS Upload Report '
                          || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                          'Below are records loaded to the FA_MASS_ADDITIONS'
                          || ' table.' ); 
                          
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ' ); 
    
    
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BOOK_TYPE_CODE'
                                        ||'|'||'BU' 
	                                      ||'|'||'TAX_ASSET_ID'
	                                      ||'|'||'LEGACY_ASSET_ID' 
	                                      ||'|'||'TAX_RECONCILE'
	                                      ||'|'||'PAN_NUMBER'
	                                      ||'|'||'DESCRIPTION'
	                                      ||'|'||'FIXED_ASSETS_UNITS'
	                                      ||'|'||'FIXED_ASSETS_COST'
	                                      ||'|'||'DEPRN_RESERVE'
	                                      ||'|'||'DATE_PLACED_IN_SERVICE'  
	                                      ||'|'||'LIFE_IN_MONTHS'   
	                                      ||'|'||'DEPRN_METHOD_CODE'   
	                                      ||'|'||'PRORATE_CONVENTION_CODE'
                                        ||'|'||'POSTIN_STATUS'
                               );     

               FOR LC_MASS_ADD_REC IN C_MASS_ADD_REC_RPT
                LOOP        
  
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  
                          LC_MASS_ADD_REC.BOOK_TYPE_CODE             
                          ||'|'||LC_MASS_ADD_REC.ATTRIBUTE13               
	                        ||'|'||LC_MASS_ADD_REC.ATTRIBUTE10               
	                        ||'|'||LC_MASS_ADD_REC.ATTRIBUTE6                
	                        ||'|'||LC_MASS_ADD_REC.ATTRIBUTE11               
	                        ||'|'||LC_MASS_ADD_REC.ATTRIBUTE12               
	                        ||'|'||LC_MASS_ADD_REC.DESCRIPTION               
	                        ||'|'||LC_MASS_ADD_REC.FIXED_ASSETS_UNITS        
	                        ||'|'||LC_MASS_ADD_REC.FIXED_ASSETS_COST         
	                        ||'|'||LC_MASS_ADD_REC.DEPRN_RESERVE             
	                        ||'|'||LC_MASS_ADD_REC.DATE_PLACED_IN_SERVICE    
	                        ||'|'||LC_MASS_ADD_REC.LIFE_IN_MONTHS            
	                        ||'|'||LC_MASS_ADD_REC.DEPRN_METHOD_CODE         
	                        ||'|'||LC_MASS_ADD_REC.PRORATE_CONVENTION_CODE   
                          ||'|'||LC_MASS_ADD_REC.POSTING_STATUS    ) ; 
  
              END LOOP; 
          
              LN_PURGE_CNT := 0;
               
              SELECT COUNT(1) 
                 INTO LN_PURGE_CNT
                 FROM FA_MASS_ADDITIONS 
                WHERE POSTING_STATUS = 'POST'
                 AND ATTRIBUTE11 IN (p_attribute11,p_attribute11_1);
                 
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LN_PURGE_CNT ||' records'
                                 ||' Uploaded!');    


        END IF;
            
      
        IF P_TAX_RPT_FLG = 'Y' THEN
            
            GC_CURRENT_STEP := 'Execute TAX_INTERFACE_TABLE Report';
            FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP); 
            
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                       'FA_TAX_INTERFACE Upload Report'
                       || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                       'Below are records loaded to the FA_TAX_INTERFACED');
                       
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ' );            
    
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,    'BOOK_TYPE_CODE'
                                           ||'|'||'ASSET_NUMBER'  
                                           ||'|'||'TAX_ASSET_ID'     
                                           ||'|'||'TAX_RECONCILE'
                                           ||'|'||'COST'
                                           ||'|'||'DEPRN_RESERVE'
                                           ||'|'||'YTD_DEPRN'         
                                           ||'|'||'LIFE_IN_MONTHS'
                                           ||'|'||'DEPRN_METHOD_CODE'
                                           ||'|'||'PRORATE_CONVENTION_CODE'
                                           ||'|'||'POSTING_STATUS' 
                              );   
       
            FOR LC_TAX_REC IN C_TAX_INT_REC_RPT
              LOOP       
              
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                              LC_TAX_REC.BOOK_TYPE_CODE
                       ||'|'||LC_TAX_REC.ASSET_NUMBER  
                       ||'|'||LC_TAX_REC.ATTRIBUTE10  --TAX_ASSET_ID     
                       ||'|'||LC_TAX_REC.ATTRIBUTE11  --TAX_RECONCILE
                       ||'|'||LC_TAX_REC.COST
                       ||'|'||LC_TAX_REC.DEPRN_RESERVE
                       ||'|'||LC_TAX_REC.YTD_DEPRN
                       ||'|'||LC_TAX_REC.LIFE_IN_MONTHS
                       ||'|'||LC_TAX_REC.DEPRN_METHOD_CODE
                       ||'|'||LC_TAX_REC.PRORATE_CONVENTION_CODE
                       ||'|'||LC_TAX_REC.POSTING_STATUS) ;   

              END LOOP; 
              
              LN_PURGE_CNT := 0;
               
              SELECT COUNT(1) 
                 INTO LN_PURGE_CNT
                 FROM FA_TAX_INTERFACE  
                WHERE POSTING_STATUS = 'POST'
             AND (ATTRIBUTE11 IN (P_ATTRIBUTE11,P_ATTRIBUTE11_1)
                  OR ATTRIBUTE11 IS NULL);
               
                 
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LN_PURGE_CNT ||' records'
                                 ||' Uploaded!');                    
       END IF;
          
       RETCODE := 0;
          
       EXCEPTION  WHEN OTHERS  THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' 
                                         || SQLERRM ());
        RETCODE := 2;     
         
       END REC_UPLOAD_RPT;    
    
   
    
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : PURGE_INTERFACE_TBL                                       |
    -- | Description : Procedure for purging interface tables              |
    -- |                                                                   |  
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE PURGE_INTERFACE_TBL (ERRBUFF         OUT NOCOPY VARCHAR2
                                  ,RETCODE         OUT NOCOPY VARCHAR2
                                  ,P_PURG_MASS_FLG IN  VARCHAR2 DEFAULT 'N'
                                  ,P_PURG_TAX_FLG  IN  VARCHAR2 DEFAULT 'N'
                               --   ,P_TAX_LABEL     IN  VARCHAR2
                               --   ,p_asset_book    IN  VARCHAR2
                                   )
     AS  
        -------------------
        -- Define Cursor
        ------------------- 
        CURSOR C_TAX_INT_REC_PURGE
            IS           
          SELECT posting_status, 
                 Asset_number, 
                 book_type_code,
                 COST,
                 deprn_method_code,
                 life_in_months,
                 Tax_request_id 
            FROM  FA_TAX_INTERFACE 
           where POSTING_STATUS <> 'POSTED';
           
        CURSOR C_MASS_ADD_REC_PURGE
            IS           
        SELECT MASS_ADDITION_ID, 
               ATTRIBUTE10,
               DESCRIPTION,
               BOOK_TYPE_CODE, 
               DATE_PLACED_IN_SERVICE,
               FIXED_ASSETS_COST, 
               POSTING_STATUS
          FROM FA_MASS_ADDITIONS
         WHERE POSTING_STATUS <> 'POSTED' ;  
           
           
        LN_PURGE_CNT     NUMBER;  
        LN_PURGE_CNT_CHK NUMBER;
        
    
    BEGIN
            
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PURG_MASS_FLG = '||P_PURG_MASS_FLG);            
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PURG_TAX_FLG  = '||P_PURG_TAX_FLG);               
   --     FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_TAX_LABEL     = '||P_TAX_LABEL);
        
        IF P_PURG_MASS_FLG = 'Y' THEN
            
               GC_CURRENT_STEP := 'Purging MASS_ADDITIONS TABLE';
               FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP); 
            
          /*     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  '
                          ||'FA_MASS_ADDITIONS Purge Report'
                          || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  '
                          ||'Below are records not in the status of POSTED'
                          || ' that will be purged.' ); 
    
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'MASS_ADD_ID'
                                      ||' ' ||'ATTRIBUTE10   '
                                      ||' ' ||'DESCRIPTION            '
                                      ||' ' ||'BOOK_TYPE_CODE        '
                                      ||' ' ||'DATE_IN_SERVICE'
                                      ||' ' ||'ASSETS_COST'
                                      ||' ' ||'POSTING_STATUS'
                                );     

               FOR LC_MASS_ADD_REC IN C_MASS_ADD_REC_PURGE
                LOOP        
  
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                      RPAD(TRIM(LC_MASS_ADD_REC.MASS_ADDITION_ID),12)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.ATTRIBUTE10),15)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.DESCRIPTION),23) ||' ' 
                     ||RPAD(TRIM(NVL(LC_MASS_ADD_REC.BOOK_TYPE_CODE,0)),23)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.DATE_PLACED_IN_SERVICE),16)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.FIXED_ASSETS_COST),12)
                     ||RPAD(TRIM(NVL(LC_MASS_ADD_REC.POSTING_STATUS,0)),10)) ; 
  
              END LOOP; 
          */
              LN_PURGE_CNT := 0;
               
              SELECT COUNT(1) 
                 INTO LN_PURGE_CNT
                 FROM FA_MASS_ADDITIONS 
                WHERE POSTING_STATUS <> 'POSTED';
                
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LN_PURGE_CNT ||' records'
                                 ||' purged!'); 
            
                EXECUTE IMMEDIATE 'truncate table fa_massadd_distributions';
                EXECUTE IMMEDIATE 'truncate table fa_mass_additions';
                
               SELECT COUNT(1) 
                 INTO LN_PURGE_CNT_CHK
                 FROM FA_MASS_ADDITIONS 
                WHERE POSTING_STATUS <> 'POSTED';
               
               IF LN_PURGE_CNT_CHK = 0  THEN
               
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA_TAX_INTERFACE'
                                   ||' was sucessfully pruged.');
                  RETCODE :=0 ;
                  
                ELSE
               
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA_TAX_INTERFACE'
                                 ||' was not fully purged! ');
                  RETCODE := 2;   
                    
                END IF;   

        END IF;
            
        IF P_PURG_TAX_FLG = 'Y' THEN
        
     --       IF P_TAX_LABEL is NULL  THEN
            
         /*      GC_CURRENT_STEP := 'Purging TAX_INTERFACE_TABLE';
               FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP); 
            
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '
                          ||'FA_TAX_INTERFACE Purge Report'
                          || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   '
                          ||'Below are records not in the status of POSTED'
                          || ' that will be purged.' ); 
    
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'POSTING STATUS'
                                      ||' ' ||'ASSET NUMBER'
                                      ||' ' ||'BOOK TYPE CODE     '
                                      ||' ' ||'COST          '
                                      ||' ' ||'DEPR METHOD CODE'
                                      ||' ' ||'LIFE IN MONTHS'
                                      ||' ' ||'REQUEST ID'
                                );   
       
               FOR LC_TAX_REC IN C_TAX_INT_REC_PURGE
                LOOP        
  
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                                  RPAD(TRIM(LC_TAX_REC.POSTING_STATUS),15)
                                  ||RPAD(TRIM(LC_TAX_REC.ASSET_NUMBER),13)
                                  ||RPAD(TRIM(LC_TAX_REC.BOOK_TYPE_CODE),20)
                                  ||RPAD(TRIM(NVL(LC_TAX_REC.cost,0)),15)
                                  ||RPAD(TRIM(LC_TAX_REC.DEPRN_METHOD_CODE),17)
                                  ||RPAD(TRIM(LC_TAX_REC.LIFE_IN_MONTHS),15)
                                  ||RPAD(TRIM(NVL(LC_TAX_REC.TAX_REQUEST_ID,0)),10)) ;   
  
  
              END LOOP; 
      */    
              LN_PURGE_CNT := 0;
               
              SELECT COUNT(1) 
                 INTO LN_PURGE_CNT
                 FROM FA_TAX_INTERFACE 
                WHERE POSTING_STATUS <> 'POSTED';
                
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LN_PURGE_CNT ||' records'
                                 ||' purged!'); 
            
               EXECUTE IMMEDIATE 'truncate table FA_TAX_INTERFACE';
                
               SELECT COUNT(1) 
                 INTO LN_PURGE_CNT_CHK
                 FROM FA_TAX_INTERFACE 
                WHERE POSTING_STATUS <> 'POSTED';
               
               IF LN_PURGE_CNT_CHK = 0  THEN
               
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA_TAX_INTERFACE'
                                   ||' was sucessfully pruged.');
                  RETCODE :=0 ;
                  
                ELSE
               
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA_TAX_INTERFACE'
                                 ||' was not fully purged! ');
                  RETCODE := 2;   
                    
                END IF;   
                
         -- ELSE    
            
         --      IF P_ASSET_BOOK  IS NULL  THEN
                
         --           EXECUTE IMMEDIATE ' DELETE FROM FA_TAX_INTERFACE WHERE '
         --                      ||' ATTRIBUTE11 = '|| P_TAX_LABEL ;
         --      ELSE
                
          --          EXECUTE IMMEDIATE ' DELETE FROM FA_TAX_INTERFACE WHERE '
          --                     ||' ATTRIBUTE11 LIKE '|| P_TAX_LABEL ||'% '                 
          --                     ||' AND book_type_code = '|| P_ASSET_BOOK;
          --     END IF;
                
         --   END IF;

          END IF;
          RETCODE := 0;
       EXCEPTION  WHEN OTHERS  THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' 
                                         || SQLERRM ());
        RETCODE := 2;     
         
       END PURGE_INTERFACE_TBL;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : GET_ASSET_NUMBER                                          |
    -- | Description : Used during the SQLLOADING of Adjusted Asset.  The  |
    -- |  Function will look up the new created asset number to and add it |  
    -- |  to the  FA_TAX_INTERACE table                                    |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+  
    FUNCTION  GET_ASSET_NUMBER (P_BUS_UNIT     IN  VARCHAR2
                               ,P_TAX_ASSET_ID IN VARCHAR2 ) 
      RETURN VARCHAR2 AS
  
      lc_asset_number VARCHAR2(50);

      BEGIN
     
        SELECT ASSET_NUMBER 
          INTO LC_ASSET_NUMBER
          FROM FA_ADDITIONS_B
         WHERE  ATTRIBUTE13 = P_BUS_UNIT
           AND  ATTRIBUTE10 = P_TAX_ASSET_ID;
           
        RETURN lc_asset_number;

      END;


    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : GET_LOCATION_ID                                           |
    -- | Description : Used during the SQLLOADING of Reinstated Assets. The|
    -- |  Function will look up the location_ID and add it                 |  
    -- |  to the FA_MASS_ADDTIONS table                                    |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+  
    FUNCTION  GET_LOCATION_ID (P_LOCATION  IN  VARCHAR2 ) 
      RETURN  NUMBER AS
  
      ln_location_id NUMBER;

      BEGIN
     
	         SELECT FL.LOCATION_ID
             INTO  LN_LOCATION_ID
	           FROM  FND_APPLICATION FA,
	                 FND_ID_FLEX_STRUCTURES_VL  FFS,
	                 FND_SHORTHAND_FLEX_ALIASES FSFA,
	                 FA_LOCATIONS FL
	          WHERE  FA.APPLICATION_SHORT_NAME ='OFA'
	            AND  FA.APPLICATION_ID = FFS.APPLICATION_ID
	            AND  FFS.ID_FLEX_STRUCTURE_CODE='LOCATION_FLEXFIELD'
	            AND  FFS.APPLICATION_ID = FSFA.APPLICATION_ID
	            AND  FSFA.ID_FLEX_CODE = FFS.ID_FLEX_CODE
              AND  FSFA.ALIAS_NAME   = P_LOCATION   
    	        AND    FL.SEGMENT1 || '.' || FL.SEGMENT2 || '.' 
              || FL.SEGMENT3 || '.' || FL.SEGMENT4 || '.' || FL.SEGMENT6 
              || '.' ||FL. segment5 = FSFA.CONCATENATED_SEGMENTS;
           
        RETURN LN_LOCATION_ID;

      END;



    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : PURGE_RPT                                                 |
    -- | Description : Procedure to display what will be purged from both  |
    -- | the FA_MASS_ADDITIONS and FA_TAX_INTERFACE tables                 |  
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE PURGE_RPT  (P_RETCODE         OUT NOCOPY VARCHAR2
                         ,P_TAX_FLG  IN  VARCHAR2 DEFAULT 'N'
                                  )
     AS  

        -------------------
        -- Define Cursor
        ------------------- 
        CURSOR C_TAX_INT_REC_PURGE
            IS           
          SELECT posting_status, 
                 Asset_number, 
                 book_type_code,
                 COST,
                 deprn_method_code,
                 life_in_months,
                 Tax_request_id 
            FROM  FA_TAX_INTERFACE 
           where POSTING_STATUS <> 'POSTED';
 
        CURSOR C_MASS_ADD_REC
            IS           
        SELECT MASS_ADDITION_ID, 
               ATTRIBUTE10,
               DESCRIPTION,
               BOOK_TYPE_CODE, 
               DATE_PLACED_IN_SERVICE,
               FIXED_ASSETS_COST, 
               POSTING_STATUS
          FROM FA_MASS_ADDITIONS
         WHERE POSTING_STATUS <> 'POSTED' ; 
 
    
    BEGIN

       IF P_TAX_FLG = 'Y' THEN
       
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PURGE FA_TAX_INTERFACE REPORT: '
                         || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Below are records not in the'||
                                   ' status of POSTED'); 
                                   
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' '); 
    
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'POSTING STATUS'
                                      ||' ' ||'ASSET NUMBER'
                                      ||' ' ||'BOOK TYPE CODE     '
                                      ||' ' ||'COST          '
                                      ||' ' ||'DEPR METHOD CODE'
                                      ||' ' ||'LIFE IN MONTHS'
                                      ||' ' ||'REQUEST ID'
                                ); 
                                
            FOR LC_TAX_REC IN C_TAX_INT_REC_PURGE         
              LOOP 
              
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                                  RPAD(TRIM(LC_TAX_REC.POSTING_STATUS),15)
                                  ||RPAD(TRIM(LC_TAX_REC.ASSET_NUMBER),13)
                                  ||RPAD(TRIM(LC_TAX_REC.BOOK_TYPE_CODE),20)
                                  ||RPAD(TRIM(NVL(LC_TAX_REC.cost,0)),15)
                                  ||RPAD(TRIM(LC_TAX_REC.DEPRN_METHOD_CODE),17)
                                  ||RPAD(TRIM(LC_TAX_REC.LIFE_IN_MONTHS),15)
                                  ||RPAD(TRIM(NVL(LC_TAX_REC.TAX_REQUEST_ID,0)),10)) ;   

            end LOOP; 
       
       ELSE
       
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'PURGE FA_MASS_ADDITIONS REPORT: '
                         || to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS') );  
                         
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Below are records not in '
                                       ||' the status of POSTED'); 
    
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' '); 
    
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'MASS_ADD_ID'
                                      ||' ' ||'ATTRIBUTE10   '
                                      ||' ' ||'DESCRIPTION            '
                                      ||' ' ||'BOOK_TYPE_CODE        '
                                      ||' ' ||'DATE_IN_SERVICE'
                                      ||' ' ||'ASSETS_COST'
                                      ||' ' ||'POSTING_STATUS'
                                );   
       
             FOR LC_MASS_ADD_REC IN C_MASS_ADD_REC
              LOOP        
  
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                      RPAD(TRIM(LC_MASS_ADD_REC.MASS_ADDITION_ID),12)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.ATTRIBUTE10),15)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.DESCRIPTION),23) ||' ' 
                     ||RPAD(TRIM(NVL(LC_MASS_ADD_REC.BOOK_TYPE_CODE,0)),23)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.DATE_PLACED_IN_SERVICE),16)
                     ||RPAD(TRIM(LC_MASS_ADD_REC.FIXED_ASSETS_COST),12)
                     ||RPAD(TRIM(NVL(LC_MASS_ADD_REC.POSTING_STATUS,0)),10)) ;    
  
  
            end LOOP; 
       END IF;
            
         p_retcode :=1;   
            
    END PURGE_RPT;
  
  
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : UPDATE_MASS_ADD_DATA                                      |
    -- | Description :  Procedure to derive needed values for mass addition|
    -- |   upload.                                                          |  
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE UPDATE_MASS_ADD_DATA  (P_RETCODE         OUT NOCOPY VARCHAR2
                                 --, p_attrib_val      IN  VARCHAR2
                                     )
     AS 
        
        -------------------
        -- Define Cursor
        ------------------- 
        CURSOR C_UPDATE_MASS_ADDITIONS
            IS
        SELECT  ATTRIBUTE10
               ,ATTRIBUTE28
               ,ATTRIBUTE29
               ,ATTRIBUTE30
               ,ATTRIBUTE11
               ,TH_ATTRIBUTE1
               ,TH_ATTRIBUTE2
               ,TH_ATTRIBUTE3
               ,TH_ATTRIBUTE4
               ,TH_ATTRIBUTE5                                           
               ,TH_ATTRIBUTE6
               ,TH_ATTRIBUTE7
          FROM    FA_MASS_ADDITIONS 
         WHERE   POSTING_STATUS = 'POST';
           
        lc_update_row_cnt      number; 
        lc_Cleaned_row_cnt     NUMBER;           
        LN_CATEGORY_ID NUMBER;
        ln_exp_ccid    number; 
        
        
        FA_MASS_ADD_ROW_CNT EXCEPTION;         
     
     BEGIN
               lc_update_row_cnt := 0;
     
               FOR LCU_UPDATE_REC IN C_UPDATE_MASS_ADDITIONS
               LOOP
        
                 LN_EXP_CCID := NULL;

               BEGIN     
                 GC_CURRENT_STEP := ' Step: Lookup of CCID ';
                 
                 SELECT GCC.CODE_COMBINATION_ID 
                   INTO   LN_EXP_CCID
                   FROM   GL_CODE_COMBINATIONS_V  GCC
                         ,GL_SETS_OF_BOOKS_V     GSB
                  WHERE GCC.SEGMENT1 = LCU_UPDATE_REC.TH_ATTRIBUTE1 --company 
                    AND GCC.SEGMENT2 = LCU_UPDATE_REC.TH_ATTRIBUTE2 --cost_cent 
                    AND GCC.SEGMENT3 = LCU_UPDATE_REC.TH_ATTRIBUTE3 --account 
                    AND GCC.SEGMENT4 = LCU_UPDATE_REC.TH_ATTRIBUTE4 --location 
                    AND GCC.SEGMENT5 = LCU_UPDATE_REC.TH_ATTRIBUTE5 --intercomp 
                    AND GCC.SEGMENT6 = LCU_UPDATE_REC.TH_ATTRIBUTE6 --lob 
                    AND GCC.SEGMENT7 = LCU_UPDATE_REC.TH_ATTRIBUTE7 --future 
                    AND GCC.CHART_OF_ACCOUNTS_ID = GSB.CHART_OF_ACCOUNTS_ID
                    AND GSB.SET_OF_BOOKS_ID      = gn_SOB_id;
           
                    
           
              EXCEPTION
                   
                 WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No CCID found for the '
                                                  ||'following segment: '
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE1 
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE2
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE3
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE4                                                  
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE5                                                  
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE6
                                                  ||'.'
                                                  ||LCU_UPDATE_REC.TH_ATTRIBUTE7    
                                                  );
                    p_retcode := 1;


                  WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' 
                                         || SQLERRM ());
                    p_retcode := 2;

                   
              END;

              BEGIN  
              
                   GC_CURRENT_STEP := ' Step: Lookup of Category ID ';
                   
                   SELECT CATEGORY_ID
                     INTO LN_CATEGORY_ID
                     FROM FA_CATEGORIES_B
                    WHERE LTRIM(RTRIM(SEGMENT1|| '.'
                                   || SEGMENT2|| '.'
                                   || SEGMENT3)) 
                             = LTRIM(RTRIM(LCU_UPDATE_REC.ATTRIBUTE28|| '.'
                                 || LCU_UPDATE_REC.ATTRIBUTE29|| '.'
                                 || LCU_UPDATE_REC.ATTRIBUTE30));
                                 
             EXCEPTION
                   
                 WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Category ID found '
                                               ||  'following segment: '
                                               || LCU_UPDATE_REC.ATTRIBUTE28
                                               || '.'
                                               || LCU_UPDATE_REC.ATTRIBUTE29
                                               || '.'
                                               || LCU_UPDATE_REC.ATTRIBUTE30    
                                                );
                    p_retcode := 1;

                  WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);  
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' 
                                         || sqlerrm ());
                    p_retcode := 2;

                END;
          
          ------------------------------------
          -- Update Derived values from above.
          ------------------------------------ 
         begin
        
            GC_CURRENT_STEP := ' Step: Updating FA_MASS_ADDITIONS Table';
         
            UPDATE FA_MASS_ADDITIONS 
               SET ASSET_CATEGORY_ID  = LN_CATEGORY_ID,
                     MASS_ADDITION_ID = FA_MASS_ADDITIONS_S.NEXTVAL,
                     ASSET_TYPE   = 'CAPITALIZED',
                     EXPENSE_CODE_COMBINATION_ID = LN_EXP_CCID
               WHERE ATTRIBUTE10   = LCU_UPDATE_REC.ATTRIBUTE10
               AND   TH_ATTRIBUTE1 = LCU_UPDATE_REC.TH_ATTRIBUTE1;
               
               lc_update_row_cnt := lc_update_row_cnt + 1;
               
             COMMIT;                           
         END;
         
         END LOOP;
 
         BEGIN  
            GC_CURRENT_STEP := ' Step: Nulling Temp Values from '
                               ||'FA_MASS_ADDITIONS Table';  
            
            UPDATE FA_MASS_ADDITIONS 
               SET ATTRIBUTE27   = NULL,
                   ATTRIBUTE28   = NULL,
                   ATTRIBUTE29   = NULL,
                   ATTRIBUTE30   = NULL,
                   TH_ATTRIBUTE1 = NULL,
                   TH_ATTRIBUTE2 = NULL,
                   TH_ATTRIBUTE3 = NULL,
                   TH_ATTRIBUTE4 = NULL,
                   TH_ATTRIBUTE5 = NULL,                                          
                   TH_ATTRIBUTE6 = NULL,
                   TH_ATTRIBUTE7 = NULL,
                   TH_ATTRIBUTE8 = NULL
             WHERE   POSTING_STATUS = 'POST';
           --    AND   TRIM(ATTRIBUTE11) = p_attrib_val;
        
          
             lc_Cleaned_row_cnt := SQL%ROWCOUNT;
                
             COMMIT;
             
          END;    
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,' Total Number Rows Updated: '
                       || LC_UPDATE_ROW_CNT);
          FND_FILE.PUT_LINE(FND_FILE.LOG,' Temp Values Rows Updated : '
                      || lc_Cleaned_row_cnt);  
                      
          IF  LC_UPDATE_ROW_CNT  <>  lc_Cleaned_row_cnt THEN
          
              raise fa_mass_add_row_cnt;
              
          else  
              p_retcode :=0;    
             
          END IF;     


     EXCEPTION
     
          WHEN FA_MASS_ADD_ROW_CNT THEN
              
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);     
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Total Number Rows Updated '
                    ||'Do not match total number of temp values cleaned up!');
             FND_FILE.PUT_LINE( FND_FILE.LOG,'Confirm that all rows on the '
                                 ||'Mass Additions table had ASSET_CATEGORY_ID,'
                                 ||' MASS_ADDITION_ID, ASSET_TYPE, '
                                 ||'and EXPENSE_CODE_COMBINATION_ID '
                                 ||'are derived correctly.');
                                 
             FND_FILE.PUT_LINE( FND_FILE.LOG,'Also, Confirm that the temp '
                                 ||'Values ATTRIBUTE27, ATTRIBUTE28, '
                                 ||'ATTRIBUTE29, ATTRIBUTE30,TH_ATTRIBUTE1, '
                                 ||'TH_ATTRIBUTE2,TH_ATTRIBUTE3,TH_ATTRIBUTE4 '
                                 ||'TH_ATTRIBUTE5,TH_ATTRIBUTE6, TH_ATTRIBUTE7'
                                 ||'are null for upload records.'   );                    
             p_retcode := 2;
     
     END UPDATE_MASS_ADD_DATA;
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : UPDATE_ATTRIBUTE                                    |
    -- | Description : Procedure to update attribute11 on FA_ADDITIONS_B   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE UPDATE_ATTRIBUTE  (P_RETCODE         OUT NOCOPY VARCHAR2
                                ,P_ATTRIBUTE11     IN VARCHAR2
                                ,P_ATTRIBUTE11_1   IN VARCHAR2
                                       )
     AS 
     
          LC_RETCODE             NUMBER;
          
          LC_CURRENT_ASSET       NUMBER;
          
          --------------------------------------------------------
          -- Cursor to select assets that need to have attribute11
          -- updated
          --------------------------------------------------------
          CURSOR C_UPDATE_TAX_ATTRIBUTE
              IS
          SELECT ASSET_NUMBER,
               --  POSTING_STATUS,
                 BOOK_TYPE_CODE,
                 LIFE_IN_MONTHS,
                 DEPRN_METHOD_CODE,
                 ATTRIBUTE11,
                 ROWNUM                
            FROM FA_TAX_INTERFACE 
           WHERE POSTING_STATUS = 'POST'
         --    AND ATTRIBUTE11 = p_attribute11
             AND ATTRIBUTE11 IN (p_attribute11,p_attribute11_1)
           ORDER BY ASSET_NUMBER;
   
           TAX_ASSET_NUM_NULL EXCEPTION; 
      
           lc_null_asset_num   NUMBER;
           lc_row_update_cnt   NUMBER;
           lc_attribute11_b    VARCHAR2(150);
           lc_concat_attr11    VARCHAR2(150);
      
      BEGIN
      
        LC_RETCODE := 0;
        
        LC_CURRENT_ASSET := 0;
      
        GC_CURRENT_STEP := 'Executing UPDATE_ATTRIBUTE ';

         FOR LCU_UPDATE_REC IN C_UPDATE_TAX_ATTRIBUTE
          LOOP
       
             ------------------------------------
             -- Asset Number should never be null
             ------------------------------------
             IF LCU_UPDATE_REC.ASSET_NUMBER IS NULL THEN
            
                lc_null_asset_num := lcu_update_rec.ROWNUM;
                RAISE TAX_ASSET_NUM_NULL;
              
             END IF;
       
             BEGIN  
           
                -------------------------------------------------
                -- Checking fa_additions_b to determine if existing
                -- values in attribute11 need to be concat to
                -- parameter value
                --------------------------------------------------
                GC_CURRENT_STEP := 'Selecting attribute11 from fa_addtions ';
                
                LC_CONCAT_ATTR11 := NULL;
                
                IF LC_CURRENT_ASSET != LCU_UPDATE_REC.ASSET_NUMBER
                   THEN
                   
                   LC_CURRENT_ASSET := LCU_UPDATE_REC.ASSET_NUMBER;
                   
                   SELECT ATTRIBUTE11 
                     INTO lc_attribute11_b 
                     FROM FA_ADDITIONS_B
                    WHERE asset_number = lcu_update_rec.asset_number;
           
                    IF LC_ATTRIBUTE11_B IS NULL THEN
                    
                     --   LC_CONCAT_ATTR11  := LCU_UPDATE_REC.ATTRIBUTE11;
                      
                        UPDATE FA_ADDITIONS_B 
                           SET ATTRIBUTE11  = LCU_UPDATE_REC.ATTRIBUTE11
                         WHERE ASSET_NUMBER = LCU_UPDATE_REC.ASSET_NUMBER;

                        COMMIT;
                  
                     ELSIF INSTR(LC_ATTRIBUTE11_B,P_ATTRIBUTE11) = 0
                       AND INSTR(LC_ATTRIBUTE11_B,P_ATTRIBUTE11_1) = 0
                         THEN
                         ---------------------------------------------------
                         -- confirmed that value has not been update already
                         ----------------------------------------------------
                          LC_CONCAT_ATTR11  := LCU_UPDATE_REC.ATTRIBUTE11
                                           ||'-'||LC_ATTRIBUTE11_B;
                                           
                          UPDATE FA_ADDITIONS_B 
                             SET ATTRIBUTE11 =LC_CONCAT_ATTR11
                           WHERE ASSET_NUMBER = LCU_UPDATE_REC.ASSET_NUMBER;

                          COMMIT;

                      END IF;     
             
                     GC_CURRENT_STEP := 'Updating attribute11 from fa_addtions '
                                   ||'for accelerated assets.' ;
                                      

                  END IF; 
                  
             EXCEPTION WHEN NO_DATA_FOUND THEN
             
                 FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error: '||GC_CURRENT_STEP
                                       ||' Asset Number = '
                                       ||LCU_UPDATE_REC.ASSET_NUMBER
                                       ||' Tax Book = '
                                       ||lcu_update_rec.BOOK_TYPE_CODE
                                       ||' '|| SQLERRM   );
                                       
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Please confirm that '
                                                ||'asset number is valid. ');
                                                
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Correct data file and '
                                                ||'resubmit upload process');                                       
                                       
              --  UPDATE FA_TAX_INTERFACE SET ATTRIBUTE11 =  p_attribute11
              --     WHERE ASSET_NUMBER = lcu_update_rec.asset_number;
             
              --   COMMIT;   
              
              
               -- after testing in dev01 lc_retcode 
               -- below will needs to be uncommented
                  lc_retcode  := 1;
                 
                      WHEN OTHERS  THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'When other '
                                      ||GC_CURRENT_STEP|| SQLERRM   );
                 lc_retcode  := 1;
               
             END;  
                      
          END LOOP;    
 
          IF   lc_retcode = 0 THEN          
               p_retcode := 0;                
          ELSE
               p_retcode := 1;                
          END IF;  
 
      EXCEPTION
         WHEN TAX_ASSET_NUM_NULL THEN
      
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Rownum '|| LC_NULL_ASSET_NUM 
                                ||' has a null value for Asset Number '
                                ||'Asset numbers can not be null. Please '
                                ||'correct data in file and upload file '
                                ||'once again!'
                                );
              p_retcode  := 1;                  
                                
        WHEN OTHERS  THEN                                  
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'When other '
                      || GC_CURRENT_STEP || SQLERRM   );   

              p_retcode  := 1;  

     END UPDATE_ATTRIBUTE;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : SUBMIT_SQLLOADER                                          |
    -- | Description : Program that will execute all sql loaders           |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE SUBMIT_SQLLOADER          (RETCODE           OUT NOCOPY VARCHAR2
                                        ,P_DATA_FILE       IN VARCHAR2
                                        ,p_program_name    IN VARCHAR2
                                         )
    AS
	    ---------------------
	    -- Variables defined
  	  ---------------------
        ln_req_id              NUMBER;
        lc_phase               VARCHAR2(50);
        lc_status              VARCHAR2(50);
        lc_dev_phase           VARCHAR2(50);
        LC_DEV_STATUS          VARCHAR2(50);
        LC_MESSAGE             VARCHAR2(1000);
        LB_RESULT              BOOLEAN;
        LC_DATA_FILE           VARCHAR2(250);
        lc_display_name        VARCHAR2(250);
        
      -------------------
      -- Define Exception
      -------------------   
      FA_ASSET_LOAD_EXP  EXCEPTION;
       
    BEGIN
      -------------------------------------------------
      gc_current_step := ' Step: Executing SUBMIT_LOAD for ';
      ------------------------------------------------- 
     
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_display_name
                                || ' '
                                ||to_char(SYSDATE, 'DD-Mon-YYYY HH24:MI:SS')); 
                                
      BEGIN
        SELECT USER_CONCURRENT_PROGRAM_NAME
          INTO lc_display_name
          FROM FND_CONCURRENT_PROGRAMS_VL 
         WHERE CONCURRENT_PROGRAM_NAME = P_PROGRAM_NAME
         AND rownum < 2;
  
      END;
             
      LN_REQ_ID := FND_REQUEST.SUBMIT_REQUEST('xxfin',
                                               p_program_name, --'XXFACR685REPAIR',
                                               NULL, 
                                               NULL, 
                                               FALSE, 
                                               P_DATA_FILE  --lc_data_file
                                              ); 
      COMMIT; 
        
      IF LN_REQ_ID = 0 THEN 
        ----------------------------------------------------------------------  
        GC_CURRENT_STEP := 'Warning: '|| LC_DISPLAY_NAME||' was Not Submitted';
        ---------------------------------------------------------------------- 
          RAISE FA_ASSET_LOAD_EXP;

       ELSE 
         ------------------------------------------------------------ 
         GC_CURRENT_STEP := ' Step: '|| lc_display_name||' Waiting ';
         ------------------------------------------------------------ 
         LB_RESULT := FND_CONCURRENT.WAIT_FOR_REQUEST(LN_REQ_ID,           
                                                       60,         -- Intervals
                                                       0,          -- Max wait 
                                                       LC_PHASE, 
                                                       lc_status, 
                                                       lc_dev_phase, 
                                                       lc_dev_status, 
                                                       LC_MESSAGE); 
         COMMIT;  

         FND_FILE.PUT_LINE(FND_FILE.LOG, ' '|| lc_display_name
                                          ||' completed at: ' 
                                 ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');             
 
       END IF; 
  
 
       IF LB_RESULT = FALSE OR LC_STATUS = 'Error' OR LC_STATUS = 'Warning' 
           OR lc_status ='Terminated' THEN
              
         -----------------------------------------------------------------
         GC_CURRENT_STEP := ' Step: '|| LC_DISPLAY_NAME
             ||' completed with Errors/Warnings or was terminated. ';
         ----------------------------------------------------------------
         
                          
         RAISE FA_ASSET_LOAD_EXP;
               
       ELSE
             RETCODE :=0;
             
       END IF;
       
     EXCEPTION
          WHEN FA_ASSET_LOAD_EXP THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,  gc_current_step);  
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA_ASSET_LOAD_EXP' || SQLERRM ());
             
             FND_FILE.PUT_LINE(FND_FILE.LOG, '    Review Output file for '||
                            'possible rejected records.' ); 
             
             retcode := 1;
   
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG, gc_current_step);  
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());
             RETCODE := 2;
  
    END SUBMIT_SQLLOADER; 
    
-- +===================================================================+
-- | Name  :EXECUTE_LOAD                                               |
-- | Description : Main program called from the following concurrent   |
-- |   OD: FA Mass Additions for Reinstated R and M Assets             |
-- |   OD: FA Tax Interface for Accelerated R and M Assets             |
-- |   OD: FA Tax Interface for Reinstated Adjusted R and M Assets     |
-- |   OD: FA Tax Interface for Bonus Depreciation                     |
-- | Parameters :                                                      |
-- |      errbuff          OUT VARCHAR2  Error message                 |  
-- |      retcode          OUT VARCHAR2  Error Code                    |
-- |      P_LOAD_PROGRAM    IN VARCHAR2  Sql Loader program            | 
-- |      P_DATA_FILE       IN VARCHAR2  Loader dta file               |
-- |      P_ATTRIBUTE11     IN VARCHAR2  Label to identify records     | 
-- |      P_PURGE_TABLE_FLG IN VARCHAR2  Purge table flag              |
-- |                                                                   | 
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE EXECUTE_LOAD     (ERRBUFF               OUT NOCOPY VARCHAR2
                               ,RETCODE               OUT NOCOPY VARCHAR2
                               ,P_LOAD_PROGRAM        IN  VARCHAR2 
                               ,P_DATA_FILE           IN VARCHAR2
                               ,P_PURGE_TABLE_FLG     IN VARCHAR2
                               ,P_ATTRIBUTE11         IN VARCHAR2 DEFAULT NULL
                               ,P_ATTRIBUTE11_1       IN VARCHAR2 DEFAULT NULL

                                )
    AS
        ---------------------
	      -- Variables defined
	      ---------------------
        LC_MESSAGE              VARCHAR2(1000);
        LC_DATA_FILE            VARCHAR2(250);
        LC_ATTRIB_VAL           VARCHAR2(250);
        LC_RET_CODE             NUMBER;
        LC_RET_CODE1            NUMBER;
        LC_RET_CODE2            NUMBER;
        LC_RET_CODE3            NUMBER;
      --  LC_RET_CODE4            NUMBER;
        LC_RET_CODE5            NUMBER;
       -- LC_RET_CODE6            NUMBER;
      -- LC_RET_CODE7            NUMBER;
        LC_RET_CODE8            NUMBER;
        LC_RET_CODE9            NUMBER;
        LC_PROGRAM_NAME         VARCHAR2(250);
        ln_mass_add_cnt         NUMBER;
        LN_TAX_INT_CNT          NUMBER;
        lc_step                 VARCHAR2(250);

        -------------------
        -- Define Exception
        -------------------   
        FA_ACCEL_UPLOAD_ERR    EXCEPTION;
        fa_accel_update_err    EXCEPTION;
        FA_MASS_ADD_UPDATE_ERR EXCEPTION;
        MASS_ADD_ROW_EXIST     EXCEPTION;
        TAX_INT_ROWS_EXIST     EXCEPTION;
        MASS_ADD_PURGE_ERR     EXCEPTION;
        TAX_INTER_PURGE_ERR    EXCEPTION;
        FA_BONUS_UPDATE_ERR    EXCEPTION;
        ln_copy_request_id     NUMBER;
        
    BEGIN

       -------------------------------------------------
       gc_current_step := ' Step: Executing EXECUTE_LOAD';
       ------------------------------------------------- 
       FND_FILE.PUT_LINE(FND_FILE.LOG,'P_LOAD_PROGRAM        = '
                                         ||P_LOAD_PROGRAM);  
       FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_SOB_id             = '
                                          || GN_SOB_ID);        
       FND_FILE.PUT_LINE(FND_FILE.LOG,'P_DATA_FILE = '
                                          || P_DATA_FILE);                                         
                                     
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_attribute11        = '
                                          ||  p_attribute11);                                        
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_attribute11_1        = '
                                          ||  p_attribute11_1);     
       FND_FILE.PUT_LINE(FND_FILE.LOG,' ');  
       ---------------------------------------
       -- Execute of the Mass additions upload
       ---------------------------------------
         IF P_LOAD_PROGRAM = 'XXFACR685REPAIR' THEN
         ------------------------------------------------------------------
         -- Confirming that no records exist on the fa_mass_additions table
         ------------------------------------------------------------------
         ln_mass_add_cnt :=0;
         
         SELECT count(1) 
           INTO ln_mass_add_cnt
           FROM FA_MASS_ADDITIONS;
           
         IF ln_mass_add_cnt <> 0  THEN

             IF  P_PURGE_TABLE_FLG = 'Y' THEN
             
               PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'Y','N');        
          --     PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'Y','N', NULL, NULL);
               
               IF LC_RET_CODE  <> 0 THEN  
                    RAISE MASS_ADD_PURGE_ERR; 
                    
               END IF;
            
             ELSE
             
                PURGE_RPT  (RETCODE,'N' );
                RAISE mass_add_row_exist;
            
             END IF;             
         
         END IF;    
 
         -----------------------------------------------------------
         GC_CURRENT_STEP := ' Step: Executing Mass Additions Upload';
          ----------------------------------------------------------- 
         FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
          
         LC_PROGRAM_NAME := P_LOAD_PROGRAM;
         
         SUBMIT_SQLLOADER(lc_ret_code, P_DATA_FILE, lc_program_name);
          
         IF LC_RET_CODE = 0 THEN 
          
                ------------------------------------------------------------
                GC_CURRENT_STEP := ' Step: Submitting Mass Additions update';
                ------------------------------------------------------------ 
                FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);

                update_mass_add_data (LC_RET_CODE);
               
                IF lc_ret_code = 0 THEN
                
                     fnd_file.put_line(fnd_file.log, 
                             'Mass Additions table sucessfully uploaded ');
                      
                      
                      ----------------------------------
                      -- Write output of records loaded
                      ----------------------------------
                      REC_UPLOAD_RPT (ERRBUFF 
                                     ,RETCODE
                                     ,'Y'
                                     ,NULL
                                     ,P_ATTRIBUTE11     
                                     ,P_ATTRIBUTE11_1);                
   
                      RETCODE  :=  0;                              
                             
                ELSE
                     retcode := lc_ret_code;
                     raise fa_mass_add_update_err; 
    
                END IF; 
       ELSE 
      
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured submitting '
                             ||'SQLLOADER '|| lc_program_name);
        END IF;
       
     END IF;  -- End IF (p_mass_load_flg)
     
     -----------------------------------------------------------------------
     --IF Statement below is executed for the FA_TAX_INTERFACE upload of
     -- Accelerated assets
     -----------------------------------------------------------------------
     IF P_LOAD_PROGRAM = 'XXFACR685ACCEL' THEN
         ------------------------------------------------------------------
         -- Confirming that no records exist on the fa_mass_additions table
         ------------------------------------------------------------------
         ln_tax_int_cnt :=0;
         
         SELECT count(1) 
           INTO ln_tax_int_cnt
           FROM FA_TAX_INTERFACE;
           
         IF LN_TAX_INT_CNT <> 0 THEN
         
             IF  P_PURGE_TABLE_FLG = 'Y' THEN
             
             
                PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y');      
        --        PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y', NULL, NULL);
                
                IF LC_RET_CODE <> 0 THEN
                
                    RAISE TAX_INTER_PURGE_ERR;
             
                END IF;
             ELSE

                PURGE_RPT  (RETCODE,'Y' );
                lc_step:= ' OD: FA Tax Interface for Accelerated R and M Assets ';
                RAISE tax_int_rows_exist;
            
             END IF;    

        END IF;    
        ----------------------------------------------------------------------
        GC_CURRENT_STEP := ' Step:Tax Interface for Accelerated Assets Upload';
        ----------------------------------------------------------- -----------
        FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);

        LC_PROGRAM_NAME := P_LOAD_PROGRAM;
        
        SUBMIT_SQLLOADER(lc_ret_code, P_DATA_FILE, lc_program_name);
         
        IF LC_RET_CODE = 0 THEN  
         
             GC_CURRENT_STEP := 'Tax Interface for Accelerated Assets '
                                || 'was uploaded!';
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
        ELSE
             RAISE FA_ACCEL_UPLOAD_ERR;
              
        END IF;

        ---------------------------------------------------------------
        GC_CURRENT_STEP := 'Calling UPDATE_ATTRIBUTE for Accel Assets';
        ---------------------------------------------------------------
        UPDATE_ATTRIBUTE  (LC_RET_CODE ,P_ATTRIBUTE11,P_ATTRIBUTE11_1);  

        IF LC_RET_CODE = 0 THEN  
             GC_CURRENT_STEP := 'Tax Interface Attribute11 (tax reconcile)'
                                || ' was updated succesfully!';
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
        ELSE
             RAISE FA_ACCEL_UPDATE_ERR;
              
        END IF;

        -------------------------------------------
        -- Write out upload report to output file
        --------------------------------------------
        REC_UPLOAD_RPT (ERRBUFF,RETCODE,NULL,'Y',P_ATTRIBUTE11,P_ATTRIBUTE11_1);  
 
        GC_CURRENT_STEP := 'Tax Interface for Accelerated Assets '
                             || 'was succesful!';
                             
        RETCODE  :=  0;                     
        FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
      END IF;  -- END IF (P_TAX_LOAD_ACCEL_FLG)
      
     -----------------------------------------------------------------------
     --IF Statement below is executed for the FA_TAX_INTERFACE upload of
     -- adjustment assets
     -----------------------------------------------------------------------      
     IF P_LOAD_PROGRAM = 'XXFACR685ADJREPAIR' THEN
         ---------------------------------------------------
         -- User can Purge Table prior to loading adjustment 
         ---------------------------------------------------
         IF  P_PURGE_TABLE_FLG = 'Y' THEN
         
           PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y');  
         --  PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y', NULL, NULL);
                
           IF LC_RET_CODE <> 0 THEN
           
               RAISE TAX_INTER_PURGE_ERR;
             
            END IF;
         END IF; 
       
         -------------------------------------------------------------------
         GC_CURRENT_STEP := 'Step: Tax Interface upload for Adjusted Assets ';   
         -------------------------------------------------------------------- 
         FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);

         LC_PROGRAM_NAME := P_LOAD_PROGRAM;
        
         SUBMIT_SQLLOADER(lc_ret_code, P_DATA_FILE, lc_program_name);
  
     
          IF LC_RET_CODE = 0 THEN 
                        
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting the '
                             ||'SQLLOADER '|| LC_PROGRAM_NAME 
                             ||' Was successful!'); 
                             
                             
             -------------------------------------------
             -- Write out upload report to output file
             --------------------------------------------
             REC_UPLOAD_RPT (ERRBUFF
                            ,RETCODE
                            ,NULL
                            ,'Y'
                            ,P_ATTRIBUTE11
                            ,P_ATTRIBUTE11_1);                             
                             
                             
             RETCODE  :=  0;                

          ELSE 
      
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured submitting '
                             ||'SQLLOADER '|| LC_PROGRAM_NAME);
               
             --------------------------------------------------
             -- Calling proc to determine display output if null 
             -- values exist for ASSET_NUMBER
             ---------------------------------------------------
            -- ASSET_NUM_NULL_CHK; 
             
             RETCODE  :=   LC_RET_CODE;

          END IF;        
     
     END IF; -- END IF (P_TAX_LOAD_ADJ_FLG)
     -----------------------------------------------------------------------
     --IF Statement below is executed for the FA_TAX_INTERFACE upload of
     -- Bonus Depr assets
     -----------------------------------------------------------------------      
     IF P_LOAD_PROGRAM = 'XXFABONUSDEPR' THEN     
         ------------------------------------------------------------------
         -- Confirming that no records exist on the fa_mass_additions table
         ------------------------------------------------------------------
         ln_tax_int_cnt :=0;
         
         SELECT count(1) 
           INTO ln_tax_int_cnt
           FROM FA_TAX_INTERFACE;
           
         IF LN_TAX_INT_CNT <> 0 THEN
         
             IF  p_purge_table_flg = 'Y' THEN
             
                PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y');  
      --        PURGE_INTERFACE_TBL (ERRBUFF, LC_RET_CODE,'N','Y', NULL, NULL);
                
                IF LC_RET_CODE <> 0 THEN
                
                    RAISE TAX_INTER_PURGE_ERR;
             
                END IF;
 
                
             ELSE

                PURGE_RPT  (RETCODE,'Y' );
                lc_step:= ' OD: FA Tax Interface for Bonus Depreciation ';
                RAISE tax_int_rows_exist;
            
             END IF;    

        END IF;    
        -------------------------------------------------------------------
        GC_CURRENT_STEP := 'Step: Tax Interface upload for Bonus Depr Assets ';   
        -------------------------------------------------------------------- 
        FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
          
        LC_PROGRAM_NAME := P_LOAD_PROGRAM;
        
        SUBMIT_SQLLOADER(LC_RET_CODE, P_DATA_FILE, LC_PROGRAM_NAME);
          
        IF LC_RET_CODE = 0 THEN 
                        
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting the '
                             ||'SQLLOADER '|| LC_PROGRAM_NAME 
                             ||' Was successful!');   
            
             
            UPDATE_ATTRIBUTE  (LC_RET_CODE ,P_ATTRIBUTE11,NULL);  
                
            IF LC_RET_CODE = 0 THEN  
               GC_CURRENT_STEP := 'Tax Interface Attribute11 (Bonus Depr)'
                                || ' was updated succesfully!';
                                
                FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
            ELSE
                RAISE FA_BONUS_UPDATE_ERR;
              
           END IF;

           -------------------------------------------
           -- Write out upload report to output file
           --------------------------------------------
           REC_UPLOAD_RPT (ERRBUFF
                            ,RETCODE
                            ,NULL
                            ,'Y'
                            ,P_ATTRIBUTE11
                            ,P_ATTRIBUTE11_1);  


           RETCODE  :=  0;   

        ELSE 
      
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Occured submitting '
                             ||'SQLLOADER '|| LC_PROGRAM_NAME);

             RETCODE  :=   LC_RET_CODE;

        END IF;        
     
     END IF; -- END IF (P_BONUS_DEPR_FLG)     
     
     
     IF RETCODE  =  0 THEN  
     -- =====================================================================
     -- Submit "Common File Copy" to copy file to /xxfin/ftp/out/escheats/
     -- =====================================================================
         ln_copy_request_id :=
            fnd_request.submit_request
               (application => 'XXFIN'  ,    -- application short name
                program => 'XXCOMFILCOPY',   -- concurrent program name
                DESCRIPTION => NULL,         -- additional request description
                start_time => NULL,          -- request submit time
                sub_request => FALSE,        -- is this a sub-request?
                ARGUMENT1 => P_DATA_FILE, -- Source file
                ARGUMENT2 => '$XXFIN_DATA/archive/inbound/' || P_LOAD_PROGRAM
                           ||'.txt_' ||TO_CHAR(SYSDATE, 'yymmddHH24MISS_SSSSS')        
              ,                              -- Destination file
                argument3 => '' ,            -- Source string
                ARGUMENT4 => '',
                ARGUMENT5=> 'Y');   
     
      END IF;
     
     
     EXCEPTION

        WHEN TAX_INTER_PURGE_ERR THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        
             GC_CURRENT_STEP :='Error occured purging the FA_MASS_ADDITIONS '||
             'table. All records may not have been purged!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);   
             retcode := 2;  
    
    
        WHEN MASS_ADD_PURGE_ERR THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        
             GC_CURRENT_STEP :='Error occured purging the FA_MASS_ADDITIONS '||
             'table. All records may not have been purged!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);   
             retcode := 2;  

        WHEN TAX_INT_ROWS_EXIST THEN
            
             FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        
             GC_CURRENT_STEP :=  ln_tax_int_cnt ||' '
                               ||'row(s) exist on the FA_TAX_INTERFACE table. '
                               ||'Please review request output report for '
                               ||'details!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
             
             FND_FILE.PUT_LINE(FND_FILE.LOG, 
                   lc_step 
                   ||'can be submitted with ''Purge Interface Table'' flag set '
                   ||'to ''Yes''. ');
                   
             FND_FILE.PUT_LINE(FND_FILE.LOG,' This will force all records to be'
                   ||' purged from the TAX_INTERFACE table');      
            
             retcode := 2;        

        WHEN mass_add_row_exist THEN
            
             gc_current_step :=  ln_mass_add_cnt ||' '
                               ||'row(s) exist on the FA_MASS_ADDITIONS table. '
                               ||'Please purge mass addition table before '
                               ||'executing the reinstatement upload of '
                               ||'Assets!';

             fnd_file.put_line(fnd_file.LOG, gc_current_step);

             FND_FILE.PUT_LINE(FND_FILE.LOG, 
                    'OD: FA Mass Additions for Reinstated Assets R and M '
                   ||'contains details of these records in the output file ');  

                   
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit the Purge Table flag set '
                   ||'to ''Yes''. ' ||' to force all records to be'
                   ||' purged from the fa_mass_additions table');            
             retcode := 2;
     
        WHEN  fa_mass_add_update_err then
        
             gc_current_step := 'Mass additions data updated contains '
                                ||'errors/warnings!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
              retcode := 2;      
     
        WHEN  FA_ACCEL_UPDATE_ERR THEN
         
             gc_current_step := 'Tax Interface Attribute11 (tax reconcile)'
                                || 'updated Upload contains errors/warnings!';
  
             fnd_file.put_line(fnd_file.log, gc_current_step);
             retcode := 1;              
                   
         WHEN  FA_BONUS_UPDATE_ERR THEN
         
             gc_current_step := 'Tax Interface Attribute11 (Bonus Depr '
                                || 'updated Upload contains errors/warnings!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
             retcode := 1;  
             
         WHEN  FA_ACCEL_UPLOAD_ERR THEN
         
              GC_CURRENT_STEP := ' Step:Tax Interface for Accelerated Assets '
                                || 'Upload contains errors/warnings!';
  
             FND_FILE.PUT_LINE(FND_FILE.LOG, GC_CURRENT_STEP);
             retcode := 1;        
     
            
          WHEN OTHERS THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG, gc_current_step);  
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());
             retcode := 2;
             errbuff := gc_current_step;

    END EXECUTE_LOAD;

END XX_FA_LOAD_ASSET_MSTR_PKG;
/


SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE BODY XX_CE_TMS_JE_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE BODY XX_CE_TMS_JE_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- +==========================================================================+
  -- | Name :  XX_CE_TMS_JE_PKG                                                 |
  -- | Description :  This package is used to create Journal entry              |
  -- |                with the help of translation codes and                    |
  -- |                CE headers and lines data                                 |
  -- | RICEID      :  I2197  TR Automated Journal Entries                       |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date              Author              Remarks                   |
  -- |======   ==========     =============        =======================      |
  -- |1.0       31-Mar-2017    praveen vanga       Initial version              |
  -- |1.1       23-Jun-2017    dsomavanshi        UAT - Defect 42346 and        |
  -- |                                            Additional requirement for    |
  -- |                                           'Catch all' Bank Transactions  |
  -- |1.2       23-Oct-2017    M K Pramod         Modified for Defect 43393 to  |
  -- |                                            fix Unbalanced Journals issue |
  -- |                                            due to timing issue    |
  -- +==========================================================================+
  
  -- +===================================================================+
  -- | Name        : XX_CE_BANK_AC                                       |
  -- |                                                                   |
  -- | Description : This Function is used to Validate Bank AC Details   |
  -- |               for translation set-ups                             |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_bank_account_number                               |
  -- | Returns     : status                                              |
  -- +===================================================================+
FUNCTION XX_CE_BANK_AC(p_bank_account_number varchar2) return varchar2
IS
L_count Number:=0;
BEGIN
           
               SELECT COUNT(cba.bank_account_id)                    
               INTO l_count
               FROM ce_bank_accounts cba 
              WHERE cba.bank_account_num = p_bank_account_number
              AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date,SYSDATE)) and TRUNC(NVL(end_date,SYSDATE)); 
              
              if l_count > 0 then
                Return 'S';
              else
                Return 'E';
              end if;
              
  

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Return 'E';
END XX_CE_BANK_AC;

 -- +===================================================================+
  -- | Name        : XX_CE_TXN_CODE                                      |
  -- |                                                                   |
  -- | Description : This Function is used to Validate txn code Details |
  -- |               for translation set-ups                              |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_bank_account_number  ,p_bank_bai_codes            |
  -- | Returns     : status                                              |
  -- +===================================================================+
FUNCTION XX_CE_TXN_CODE(p_bank_account_number varchar2,p_bank_bai_codes varchar2) return varchar2
IS
L_count Number:=0;
BEGIN
           
               SELECT COUNT(ctc.transaction_code_id)                    
               INTO l_count
               FROM ce_bank_accounts cba,
                    ce_transaction_codes  ctc               
              WHERE cba.bank_account_id  = ctc.bank_account_id
                AND cba.bank_account_num = p_bank_account_number
                AND ctc.trx_code = p_bank_bai_codes
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(cba.start_date,SYSDATE)) and TRUNC(NVL(cba.end_date,SYSDATE))
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ctc.start_date,SYSDATE)) and TRUNC(NVL(ctc.end_date,SYSDATE)); 
              
              if l_count > 0 then
                Return 'S';
              else
                Return 'E';
              end if;
              
  

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Return 'E';
END XX_CE_TXN_CODE;

 -- +===================================================================+
  -- | Name        : XX_CE_SEARCH_STRG                                   |
  -- |                                                                   |
  -- | Description : This Function is used to Validate Search String     |
  -- |               length and % symbols                                |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_search_string                                     |
  -- | Returns     : status                                              |
  -- +===================================================================+
FUNCTION XX_CE_SEARCH_STRG(p_search_string varchar2) return varchar2
IS
L_count Number:=0;
l_r_char varchar2(1);
l_l_char varchar2(1);
BEGIN
  -- Start commneted for Defect 42346 dsomavanshi 23/6/2017
  /*SELECT LENGTH(p_search_string)                    
               INTO l_count
               FROM dual; 
              
              if l_count < 7 then
                Return 'E';
              else
  */      
  -- End commneted for Defect 42346 dsomavanshi 23/6/2017
  
   SELECT SUBSTR(p_search_string,1,1) ,SUBSTR(p_search_string,-1)
     INTO l_r_char,l_l_char
     FROM  DUAL;
                
   IF l_r_char <> '%' OR l_l_char <> '%' THEN
      RETURN 'E';
   ELSE
      RETURN 'S';
   END IF;

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Return 'E';
END XX_CE_SEARCH_STRG;


 -- +===================================================================+
  -- | Name        : XX_CE_GL_STRING                                     |
  -- |                                                                   |
  -- | Description : This Function is used to Validate txn code Details |
  -- |               for translation set-ups                              |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_bank_account_number  ,p_gl_coding_debit           |
  -- |               p_gl_coding_credit                                  |
  -- | Returns     : status  ,p_ret_gl_message                           |
  -- +===================================================================+
FUNCTION XX_CE_GL_STRING(p_gl_coding_debit varchar2,p_gl_coding_credit varchar2,p_ret_gl_message OUT varchar2) return varchar2
IS
L_count Number:=0;
l_r_status varchar2(1):='S';
BEGIN
            -- Checking GL Debit String
                SELECT COUNT(gcc.code_combination_id)                    
               INTO l_count
               FROM  gl_code_combinations gcc 
              WHERE gcc.enabled_flag ='Y'
                and trunc(sysdate) between trunc(nvl(gcc.start_date_active,sysdate)) and trunc(nvl(gcc.end_date_active,sysdate))
                and GCC.SEGMENT1 = substr(p_gl_coding_debit,1,instr(p_gl_coding_debit,'.',1)-1)
                and GCC.SEGMENT2 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,1)+1,instr(p_gl_coding_debit,'.',1,2)-instr(p_gl_coding_debit,'.',1,1)-1)
                and GCC.SEGMENT3 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,2)+1,instr(p_gl_coding_debit,'.',1,3)-instr(p_gl_coding_debit,'.',1,2)-1)
                and GCC.SEGMENT4 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,3)+1,instr(p_gl_coding_debit,'.',1,4)-instr(p_gl_coding_debit,'.',1,3)-1)
                and gcc.segment5 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,4)+1,instr(p_gl_coding_debit,'.',1,5)-instr(p_gl_coding_debit,'.',1,4)-1)
                and GCC.SEGMENT6 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,5)+1,instr(p_gl_coding_debit,'.',1,6)-instr(p_gl_coding_debit,'.',1,5)-1)
                and GCC.SEGMENT7 = substr(p_gl_coding_debit,instr(p_gl_coding_debit,'.',1,6)+1)
                        
                ; 
              
              if l_count = 0 then
                       p_ret_gl_message:=p_ret_gl_message||' '||'Validation Error for GL Debit Sting : '||p_gl_coding_debit;
                       l_r_status:='E';
              end if;
                     
              
                 
                   -- Checking GL Credit String
                     SELECT COUNT(gcc.code_combination_id)                    
                       INTO l_count
                       FROM  gl_code_combinations gcc 
                      WHERE gcc.enabled_flag ='Y'
                        and trunc(sysdate) between trunc(nvl(gcc.start_date_active,sysdate)) and trunc(nvl(gcc.end_date_active,sysdate))
                        and GCC.SEGMENT1 = substr(p_gl_coding_credit,1,instr(p_gl_coding_credit,'.',1)-1)
                        and GCC.SEGMENT2 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,1)+1,instr(p_gl_coding_credit,'.',1,2)-instr(p_gl_coding_credit,'.',1,1)-1)
                        and GCC.SEGMENT3 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,2)+1,instr(p_gl_coding_credit,'.',1,3)-instr(p_gl_coding_credit,'.',1,2)-1)
                        and GCC.SEGMENT4 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,3)+1,instr(p_gl_coding_credit,'.',1,4)-instr(p_gl_coding_credit,'.',1,3)-1)
                        and gcc.segment5 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,4)+1,instr(p_gl_coding_credit,'.',1,5)-instr(p_gl_coding_credit,'.',1,4)-1)
                        and GCC.SEGMENT6 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,5)+1,instr(p_gl_coding_credit,'.',1,6)-instr(p_gl_coding_credit,'.',1,5)-1)
                        and GCC.SEGMENT7 = substr(p_gl_coding_credit,instr(p_gl_coding_credit,'.',1,6)+1)
                        ; 
                        
                      if l_count = 0 then
                       p_ret_gl_message:=p_ret_gl_message||' '||'Validation Error for GL Credit Sting : '||p_gl_coding_credit;
                       l_r_status:='E';
                     end if;                     
             
              
              Return l_r_status;
  

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Return 'E';
END XX_CE_GL_STRING;


-- +===================================================================+
  -- | Name        : XX_CE_GL_SOB                                        |
  -- |                                                                   |
  -- | Description : This Function is used to get SOB for GL String      |
  -- |               for translation set-ups                              |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_bank_account_number  ,p_gl_coding_debit           |
  -- |               p_gl_coding_credit                                  |
  -- | Returns     : Number                                              |
  -- +===================================================================+
FUNCTION XX_CE_GL_SOB(p_gl_coding varchar2,p_currency_code varchar2) return Number
IS 
lc_sob number:=null;
BEGIN
    
        -- Getting SOB Details              
               SELECT  gld.ledger_id
                 INTO  lc_sob
                 FROM  gl_code_combinations gcc ,
                       gl_ledgers gld
                WHERE 1                      =1
                  AND gld.chart_of_accounts_id = gcc.chart_of_accounts_id
                  AND gld.ledger_category_code ='PRIMARY'
                  and gld.currency_code        = p_currency_code
                 AND gcc.enabled_flag ='Y'
                 AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(gcc.start_date_active,SYSDATE)) AND TRUNC(NVL(gcc.end_date_active,SYSDATE))                
                   and GCC.SEGMENT1 = substr(p_gl_coding,1,instr(p_gl_coding,'.',1)-1)
                and GCC.SEGMENT2 = substr(p_gl_coding,instr(p_gl_coding,'.',1,1)+1,instr(p_gl_coding,'.',1,2)-instr(p_gl_coding,'.',1,1)-1)
                and GCC.SEGMENT3 = substr(p_gl_coding,instr(p_gl_coding,'.',1,2)+1,instr(p_gl_coding,'.',1,3)-instr(p_gl_coding,'.',1,2)-1)
                and GCC.SEGMENT4 = substr(p_gl_coding,instr(p_gl_coding,'.',1,3)+1,instr(p_gl_coding,'.',1,4)-instr(p_gl_coding,'.',1,3)-1)
                and gcc.segment5 = substr(p_gl_coding,instr(p_gl_coding,'.',1,4)+1,instr(p_gl_coding,'.',1,5)-instr(p_gl_coding,'.',1,4)-1)
                and GCC.SEGMENT6 = substr(p_gl_coding,instr(p_gl_coding,'.',1,5)+1,instr(p_gl_coding,'.',1,6)-instr(p_gl_coding,'.',1,5)-1)
                and GCC.SEGMENT7 = substr(p_gl_coding,instr(p_gl_coding,'.',1,6)+1)
              ;
              
             Return lc_sob;

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Return null;
END XX_CE_GL_SOB;

  -- +===================================================================+
  -- | Name        : XX_CE_GL_INSERT_STG                                 |
  -- |                                                                   |
  -- | Description : This procedure is used to insert records into stage |
  -- |               table                                               |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id  and column values                       |
  -- | Returns     :                                                     |
  -- +===================================================================+
PROCEDURE XX_CE_GL_INSERT_STG(p_bank_account_number varchar2,p_bank_account_id number,p_trx_code varchar2,
                                            p_trx_code_id Number, p_search_string varchar2, p_gl_coding_debit  varchar2,
                              p_gl_coding_credit varchar2, p_cr_je_line_dsc varchar2, p_dr_je_line_dsc varchar2,
                              p_statement_header_id number, p_statement_line_id number, p_statement_number varchar2,
                              p_statement_line_number varchar2, p_entered_cr_dr number, p_currency_code varchar2,
                              p_cr_set_of_books_id Number, p_dr_set_of_books_id Number,p_group_id Number, 
                              p_validation_status varchar2,p_validation_text varchar2
                             ) 
IS
BEGIN
                         --- insert the records into staging table 
                          INSERT 
                          INTO xx_ce_tms_jrnl_stg
                               (bank_account_number,
                                bank_account_id,
                                trx_code,
                                trx_code_id,
                                search_string,
                                gl_coding_debit,
                                gl_coding_credit,
                                cr_je_line_dsc,
                                dr_je_line_dsc,
                                statement_header_id,
                                statement_line_id ,
                                statement_number,
                                statement_line_number,
                                entered_cr_dr,
                                currency_code,
                                cr_set_of_books_id,
                                dr_set_of_books_id,
                                process_flag,
                                process_date,
                                group_id,
                                validation_level,  
                                validation_status,
                                validation_text,
                                creation_date,
                                created_by,
                                last_update_date,
                                last_updated_by
                               )              
                          VALUES
                            ( p_bank_account_number,    --bank_account_number
                              p_bank_account_id,         --bank_account_id
                              p_trx_code ,
                              p_trx_code_id,            --trx_code_id
                              p_search_string,
                              p_gl_coding_debit,
                              p_gl_coding_credit,
                              p_cr_je_line_dsc,         --cr_je_line_dsc
                              p_dr_je_line_dsc,         --dr_je_line_dsc                  
                              p_statement_header_id,       --statement_header_id
                              p_statement_line_id,        --statement_line_id
                              p_statement_number,        --statement_number
                              p_statement_line_number,  --statement_line_number
                              p_entered_cr_dr ,         --entered_cr_dr
                              p_currency_code ,         --currency_code
                              p_cr_set_of_books_id ,     --cr_set_of_books_id
                              p_dr_set_of_books_id,     --dr_set_of_books_id                  
                              'N',                        --process_flag
                              TRUNC(SYSDATE),             --process_date 
                              p_group_id ,               --group_id
                              'CE_TRANSLATION' ,        --validation_level
                              P_VALIDATION_STATUS ,       --validation_status
                              p_validation_text ,        --validation_text
                              SYSDATE,                    --creation_date
                              FND_GLOBAL.USER_ID,         --created_by
                              SYSDATE,                    --last_update_date
                              FND_GLOBAL.USER_ID          --last_updated_by
                            );
                        
                           COMMIT;

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
   Rollback;
END XX_CE_GL_INSERT_STG;

  -- +===================================================================+
  -- | Name        : XX_CE_GL_VALIDATION                                 |
  -- |                                                                   |
  -- | Description : This procedure is used to Validate Transaction      |
  -- |               set-ups                                             |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id                                          |
  -- | Returns     :                                                     |
  -- +===================================================================+
PROCEDURE XX_CE_GL_VALIDATION(p_group_id NUMBER,
                              p_ln_cnt1 OUT NUMBER,
                              p_tot_trans_count OUT NUMBER,
                              p_tot_trans_error OUT NUMBER) 
                          
IS
  
  -- Cursor to pull translation set-ups defined in the application
  CURSOR trans_val
  IS
    SELECT target_value1 bank_account_number,
           target_value2 bank_bai_codes,
           target_value3 search_string,
           target_value4 gl_coding_debit,
           target_value5 gl_debit_description,
           target_value6 gl_coding_credit,
           target_value7 gl_credit_description
     FROM xx_fin_translatevalues xftv,
          xx_fin_translatedefinition xftd
    WHERE xftv.translate_id = xftd.translate_id
      AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
      AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
      AND xftd.translation_name = 'XX_TREASURY_JRNL_MAPPING'
      AND xftv.enabled_flag     = 'Y'
      AND xftd.enabled_flag     = 'Y'
      --AND target_value1 = '2090002608308'  --dsomavanshi 23/06/2017
      --AND target_value2 = '577' --dsomavanshi 23/06/2017
    ORDER BY 1,2,decode(target_value3,'%CATCH ALL%',2,1);  
      

  -- Cursor to pull all valid records from Translation Setup once first cursor completes the validaion   
  CURSOR trans_valid(p_group_id NUMBER)
  IS
    SELECT DISTINCT
          target_value1 bank_account_number,
          target_value2 bank_bai_codes,
          target_value3 search_string,
          target_value4 gl_coding_debit,
          target_value5 gl_debit_description,
          target_value6 gl_coding_credit,
          target_value7 gl_credit_description,
          ctc.transaction_code_id ,
          cba.bank_account_id,
          cba.currency_code
    FROM xx_fin_translatevalues xftv,
         xx_fin_translatedefinition xftd,
         ce_transaction_codes ctc ,
         ce_bank_accounts cba
    WHERE xftv.translate_id = xftd.translate_id
    AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
    AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
    AND xftd.translation_name = 'XX_TREASURY_JRNL_MAPPING'
    AND xftv.enabled_flag     = 'Y'
    AND xftd.enabled_flag     = 'Y'
    AND cba.bank_account_num  = target_value1
    AND cba.bank_account_id   = ctc.bank_account_id
    AND ctc.trx_code          = target_value2
    --    AND target_value1 = '2090002608308'   --dsomavanshi 23/06/2017
    --    AND target_value2 = '577'  --dsomavanshi 23/06/2017
     AND NOT EXISTS
                  (SELECT 'X'
                     FROM xx_ce_tms_jrnl_stg
                    WHERE group_id             = p_group_id
                      AND validation_status    ='E'
                      AND bank_account_number = target_value1
                      AND trx_code = target_value2
                      AND search_string = target_value3
                      and nvl(gl_coding_debit,'XYZ') = nvl(target_value4,'XYZ')
                      and nvl(gl_coding_credit,'XYZ') = nvl(target_value6,'XYZ')
                  )
    ORDER BY 1,2,decode(target_value3,'%CATCH ALL%',2,1);

   --- cursor to extract CE statement data for valid translation bank account and codes
  CURSOR ce_tms(p_bank_account_id number,p_search_string varchar2,p_txn_code varchar2)
  IS
   SELECT csh.statement_number ,
          csh.statement_date ,
          csl.line_number ,
          csl.statement_line_id ,
          csl.trx_date ,
          csl.amount ,
          csl.statement_header_id ,
          csl.invoice_text ,
          csl.status ,
          csl.trx_text 
    FROM ce_statement_headers csh ,
         ce_statement_lines csl 
    WHERE csh.statement_header_id = csl.statement_header_id
      AND csh.bank_account_id     = p_bank_account_id
      and csl.trx_code            = p_txn_code
    --  AND TRUNC(csl.creation_date)=  '28-JUL-16'   -- Changed for testing
      AND TRUNC(csl.creation_date)=  TRUNC(SYSDATE)  
      AND UPPER(csl.trx_text) LIKE UPPER(p_search_string)
      AND NOT EXISTS
                  (SELECT 'X'
                     from xx_ce_tms_jrnl_stg
                    where 1=1
                      AND validation_status in ('S','I') 
                     -- AND TRUNC(process_date)=  TRUNC(SYSDATE)
                      AND bank_account_id   = csh.bank_account_id
                      AND trx_code              = csl.trx_code
                      AND statement_header_id   = csh.statement_header_id
                      AND statement_line_id     = csl.statement_line_id
                      AND statement_number      = csh.statement_number
                      and statement_line_number = csl.line_number
                  ) 
    ;    
  --  Cursor added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017
  --- cursor to extract All CE statement data for valid translation bank account and codes (Catch All)
  CURSOR ce_catch_all(p_bank_account_id number,p_txn_code varchar2)
  IS
   SELECT csh.statement_number ,
          csh.statement_date ,
          csl.line_number ,
          csl.statement_line_id ,
          csl.trx_date ,
          csl.amount ,
          csl.statement_header_id ,
          csl.invoice_text ,
          csl.status ,
          csl.trx_text 
    FROM ce_statement_headers csh ,
         ce_statement_lines csl 
    WHERE csh.statement_header_id = csl.statement_header_id
      AND csh.bank_account_id     = p_bank_account_id
      and csl.trx_code            = p_txn_code
     -- AND TRUNC(csl.creation_date)=   '28-JUL-16'  --changed for testing dbs
      AND TRUNC(csl.creation_date)=  TRUNC(SYSDATE)  
      AND NOT EXISTS
                  (SELECT 'X'
                     from xx_ce_tms_jrnl_stg
                    where 1=1
                      AND validation_status in ('S','I') 
                     -- AND TRUNC(process_date)=  TRUNC(SYSDATE)
                      AND bank_account_id   = csh.bank_account_id
                      AND trx_code              = csl.trx_code
                      AND statement_header_id   = csh.statement_header_id
                      AND statement_line_id     = csl.statement_line_id
                      AND statement_number      = csh.statement_number
                      and statement_line_number = csl.line_number
                  ) 
    ;    
    
lc_dr_sob hr_operating_units.set_of_books_id%type;
lc_cr_sob hr_operating_units.set_of_books_id%type;
lc_currency_code  varchar2(3);    
ln_cnt1           number:=0;

lc_error_text varchar2(2000);
lc_rec_status varchar2(1):='S';     
lc_fun_rec_status varchar2(1);
lc_ledger_id       number;      
lc_ret_gl_message varchar2(1000);
ln_tot_trans_count Number:=0;
ln_tot_trans_error Number:=0;


BEGIN
         p_ln_cnt1:=0;  

      -- Main cursor for translation set-ups validation
      FOR c1 IN trans_val  LOOP
          
        lc_error_text     := NULL;
        lc_rec_status     :='S';
        lc_ret_gl_message :=NULL;
        
        ln_tot_trans_count:=ln_tot_trans_count+1;
          
        if LENGTH(LTRIM(RTRIM(c1.bank_account_number))) is  null OR LENGTH(LTRIM(RTRIM(c1.bank_bai_codes))) is  null OR  LENGTH(LTRIM(RTRIM(c1.search_string))) is  null OR 
                 LENGTH(LTRIM(RTRIM(c1.gl_coding_debit))) is  null OR  LENGTH(LTRIM(RTRIM(c1.gl_debit_description))) is  null  OR 
                     LENGTH(LTRIM(RTRIM(c1.gl_credit_description))) is  null OR LENGTH(LTRIM(RTRIM(c1.gl_coding_credit))) is  null then        
               lc_rec_status     :='E';
               lc_error_text:='Validation Error for the Translation set-ups column value is null ';
        
        End if; 
        
        
         -- Function to validate search string validation of length and search char
             lc_fun_rec_status:=xx_ce_search_strg(LTRIM(RTRIM(c1.search_string)));      
           
            if lc_fun_rec_status <> 'S' then
              lc_rec_status     :='E';            
              lc_error_text:=lc_error_text||' -- '||'Validation Error for the Search string length < 5 or search % is missing : '|| c1.search_string;
            end if;
           
         -- Function to Validate Translation Bank Account number set-up
               lc_fun_rec_status:=xx_ce_bank_ac(c1.bank_account_number);

               if     lc_fun_rec_status <> 'S' then
               lc_rec_status     :='E'; 
               lc_error_text:=lc_error_text||' -- '||'Validation Error for the Bank Account Number : '|| c1.bank_account_number;
            end if;
            
         -- Function to Validate Translation txn code setup
               lc_fun_rec_status:=xx_ce_txn_code(c1.bank_account_number,c1.bank_bai_codes);
                
            if     lc_fun_rec_status <> 'S' then
                lc_rec_status     :='E'; 
                lc_error_text:=lc_error_text||' -- '||'Validation Error for the Transaction Code : '||c1.bank_bai_codes||'  for Bank AC '||c1.bank_account_number;
            end if;
            
         -- Function to Validate Translation Credit and Debit GL String setup
              lc_fun_rec_status:=xx_ce_gl_string(c1.gl_coding_debit,c1.gl_coding_credit,lc_ret_gl_message);
                 
            if lc_fun_rec_status <> 'S' then
                lc_rec_status     :='E'; 
                lc_error_text:=lc_error_text||' -- '||lc_ret_gl_message;
            end if; -- Gl string validation

              
        
            --insert into staging table for validation failed records of the translation definitions
            IF lc_rec_status <> 'S'  THEN
               
             -- insert procedure call
              xx_ce_gl_insert_stg
                (  
                  c1.bank_account_number,--bank_account_number
                  null,                           --bank_account_id
                  c1.bank_bai_codes ,
                  null,                 --trx_code_id
                  c1.search_string,
                  c1.gl_coding_debit,
                  c1.gl_coding_credit,
                  c1.gl_credit_description,    --cr_je_line_dsc
                  c1.gl_debit_description,  --dr_je_line_dsc                  
                  null,                  --statement_header_id
                  null,                    --statement_line_id
                  null,                     --statement_number
                  null,                  --statement_line_number
                  0 ,                     --entered_cr_dr
                  null ,                 --currency_code
                  null ,                 --cr_set_of_books_id
                  null,                 --dr_set_of_books_id                  
                  p_group_id ,           --group_id
                  lc_rec_status ,       --validation_status
                  lc_error_text         --validation_text
                );
                
                  ln_tot_trans_error:=ln_tot_trans_error+1;
                  
            END IF;
            
         END LOOP; -- End of main Cursor        
            
            COMMIT;
      
      -- Translation cursor with valid codes
      -- This cursor gets the data for valid translation excluding the error records from first cursor
      FOR c2 IN trans_valid(p_group_id) LOOP
        FND_FILE.PUT_LINE(FND_FILE.LOG,'c2.bank_account_id :'||c2.bank_account_id||' '||'c2.bank_bai_codes'||' '||c2.bank_bai_codes);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Search_string:'|| c2.search_string);
          -- CE statement tables cursor
          
        IF c2.search_string NOT LIKE '%CATCH ALL%' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside Standard ');
             FOR c3 IN ce_tms(c2.bank_account_id,c2.search_string,c2.bank_bai_codes)  LOOP
        
                lc_error_text:= null;
                lc_rec_status:='S';
                lc_cr_sob:= null;
                lc_dr_sob:= null;
    
                 -- function call to get gl Debit ac SOB id
                   lc_dr_sob:= xx_ce_gl_sob(c2.gl_coding_debit,c2.currency_code);
                
                
                     -- function call to get gl Credit ac SOB id
                   lc_cr_sob:= xx_ce_gl_sob(c2.gl_coding_credit,c2.currency_code);
                 
                 if lc_dr_sob is null or lc_cr_sob is null then
                   lc_cr_sob:= null;
                   lc_dr_sob:= null;
                   lc_error_text:= 'SOB fetching Error ';
                   lc_rec_status:='E';
                end if;
       
                --- insert the records into staging table procedure call
                xx_ce_gl_insert_stg
                (  
                  c2.bank_account_number,--bank_account_number
                  c2.bank_account_id,     --bank_account_id
                  c2.bank_bai_codes ,
                  c2.transaction_code_id,--trx_code_id
                  c2.search_string,
                  c2.gl_coding_debit,
                  c2.gl_coding_credit,
                  c2.gl_credit_description, --cr_je_line_dsc
                  c2.gl_debit_description,     --dr_je_line_dsc                  
                  c3.statement_header_id,   --statement_header_id
                  c3.statement_line_id,        --statement_line_id
                  c3.statement_number,    --statement_number
                  c3.line_number,       --statement_line_number
                  c3.amount ,             --entered_cr_dr
                  c2.currency_code ,     --currency_code
                  lc_cr_sob ,             --cr_set_of_books_id
                  lc_dr_sob,             --dr_set_of_books_id                  
                  p_group_id ,           --group_id
                  lc_rec_status ,       --validation_status
                  lc_error_text         --validation_text
                );
            
                COMMIT;
               
               ln_cnt1:=ln_cnt1+1;
    
              END LOOP; -- End of CE Statement Cursor
              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_cnt1:'|| ln_cnt1);
        END IF;  ------IF c2.search_string NOT LIKE '%CATCH ALL%' THEN            
 
       -- Start  Process  added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017
       -- CURSOR ce_catch_all(p_bank_account_id number,p_txn_code varchar2)

        IF c2.search_string LIKE '%CATCH ALL%' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside Catch All ');
              FOR c4 IN ce_catch_all(c2.bank_account_id,c2.bank_bai_codes)  LOOP
        
                lc_error_text:= null;
                lc_rec_status:='S';
                lc_cr_sob:= null;
                lc_dr_sob:= null;
    
                 -- function call to get gl Debit ac SOB id
                   lc_dr_sob:= xx_ce_gl_sob(c2.gl_coding_debit,c2.currency_code);
                
                
                     -- function call to get gl Credit ac SOB id
                   lc_cr_sob:= xx_ce_gl_sob(c2.gl_coding_credit,c2.currency_code);
                 
                 if lc_dr_sob is null or lc_cr_sob is null then
                   lc_cr_sob:= null;
                   lc_dr_sob:= null;
                   lc_error_text:= 'SOB fetching Error ';
                   lc_rec_status:='E';
                end if;
       
                --- insert the records into staging table procedure call
                xx_ce_gl_insert_stg
                (  
                  c2.bank_account_number,--bank_account_number
                  c2.bank_account_id,     --bank_account_id
                  c2.bank_bai_codes ,
                  c2.transaction_code_id,--trx_code_id
                  c2.search_string,
                  c2.gl_coding_debit,
                  c2.gl_coding_credit,
                  c2.gl_credit_description, --cr_je_line_dsc
                  c2.gl_debit_description,     --dr_je_line_dsc                  
                  c4.statement_header_id,   --statement_header_id
                  c4.statement_line_id,        --statement_line_id
                  c4.statement_number,    --statement_number
                  c4.line_number,       --statement_line_number
                  c4.amount ,             --entered_cr_dr
                  c2.currency_code ,     --currency_code
                  lc_cr_sob ,             --cr_set_of_books_id
                  lc_dr_sob,             --dr_set_of_books_id                  
                  p_group_id ,           --group_id
                  lc_rec_status ,       --validation_status
                  lc_error_text         --validation_text
                );
            
                COMMIT;
               
               ln_cnt1:=ln_cnt1+1;
    
              END LOOP; -- End of CE Statement Cursor
        END IF;  ------IF c2.search_string LIKE '%CATCH ALL%' THEN            
     -- End  Process  added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017
      END LOOP;   -- Valid translation cursor    
    
      p_ln_cnt1:=ln_cnt1;
      p_tot_trans_count:= ln_tot_trans_count ;
      p_tot_trans_error:= ln_tot_trans_error;
      
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
END XX_CE_GL_VALIDATION;


  -- +===================================================================+
  -- | Name        : XX_CE_GL_REVALIDATION                               |
  -- |                                                                   |
  -- | Description : This procedure is used to Re Validate Error         |
  -- |                Translation set-ups                                 |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id ,                                           |
  -- | Returns     :                                                     |
  -- +===================================================================+
PROCEDURE XX_CE_GL_REVALIDATION(p_group_id number,
                                p_reprocess_date varchar2, 
                                p_ln_cnt1 OUT NUMBER,
                                p_tot_trans_count OUT NUMBER,
                                p_tot_trans_error OUT NUMBER)    
IS

-- Cursor to revalidate error Translation Setup
CURSOR trans_val
IS
SELECT  target_value1 bank_account_number,
        target_value2 bank_bai_codes,
        target_value3 search_string,
        target_value4 gl_coding_debit,
        target_value5 gl_debit_description,
        target_value6 gl_coding_credit,
        target_value7 gl_credit_description
  FROM xx_fin_translatevalues xftv,
       xx_fin_translatedefinition xftd
  WHERE xftv.translate_id = xftd.translate_id
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
  AND xftd.translation_name = 'XX_TREASURY_JRNL_MAPPING'
  AND xftv.enabled_flag     = 'Y'
  AND xftd.enabled_flag     = 'Y'
  AND EXISTS
            (SELECT 'X'
                FROM xx_ce_tms_jrnl_stg
                WHERE 1=1
                AND TRUNC(process_date) = TRUNC(FND_DATE.CANONICAL_TO_DATE(p_reprocess_date)) 
                AND validation_status ='E'
                and process_flag = 'N'
                and validation_level = 'CE_TRANSLATION'
                --AND UPPER(target_value3) = UPPER(search_string)
                AND target_value1        = bank_account_number
                AND target_value2        = trx_code  
            ) 
            
            Order by 1,2,decode(target_value3,'%CATCH ALL%',2,1);

   --- cursor to extract CE statement data for valid translation bank account and codes
  CURSOR ce_tms(p_bank_account_number VARCHAR2,p_search_string VARCHAR2,p_bank_bai_codes VARCHAR2)
  IS
   SELECT CSH.statement_number ,
          CSH.statement_date ,
          CSL.line_number ,
          CSL.statement_line_id ,
          CSL.trx_date ,
          CSL.amount ,
          CSL.statement_header_id ,
          CSL.invoice_text ,
          CSL.status ,
          CSL.trx_text ,
          ctc.trx_code ,
      ctc.transaction_code_id,
          CBA.bank_account_num,
          CBA.bank_account_id,
          CBA.currency_code
    FROM ce_statement_headers csh ,
         ce_statement_lines csl ,
         ce_transaction_codes ctc ,
         ce_bank_accounts cba
    WHERE csh.statement_header_id = csl.statement_header_id
      AND csh.bank_account_id       = ctc.bank_account_id
      AND csl.trx_code              = ctc.trx_code
      AND csh.bank_account_id = cba.bank_account_id
      AND TRUNC(csl.creation_date) = TRUNC(FND_DATE.CANONICAL_TO_DATE(p_reprocess_date))
      AND ctc.trx_code = p_bank_bai_codes
      AND UPPER(csl.trx_text) LIKE UPPER(p_search_string)
      AND cba.bank_account_num = p_bank_account_number    
      AND NOT EXISTS
                  (SELECT 'X'
                     from xx_ce_tms_jrnl_stg
                    where 1=1
                      AND validation_status in ('S','I') 
                      AND bank_account_id   = csh.bank_account_id
                      AND trx_code              = csl.trx_code
                      AND statement_header_id   = csh.statement_header_id
                      AND statement_line_id     = csl.statement_line_id
                      AND statement_number      = csh.statement_number
                      and statement_line_number = csl.line_number
                  )       
      ;    
  -- Start  cursor  added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017    
  --- cursor to extract All CE statement data for valid translation bank account and codes (Catch All)
  CURSOR ce_catch_all(p_bank_account_number VARCHAR2,p_bank_bai_codes VARCHAR2)   
    IS
   SELECT CSH.statement_number ,
          CSH.statement_date ,
          CSL.line_number ,
          CSL.statement_line_id ,
          CSL.trx_date ,
          CSL.amount ,
          CSL.statement_header_id ,
          CSL.invoice_text ,
          CSL.status ,
          CSL.trx_text ,
          ctc.trx_code ,
      ctc.transaction_code_id,
          CBA.bank_account_num,
          CBA.bank_account_id,
          CBA.currency_code
    FROM ce_statement_headers csh ,
         ce_statement_lines csl ,
         ce_transaction_codes ctc ,
         ce_bank_accounts cba
    WHERE csh.statement_header_id = csl.statement_header_id
      AND csh.bank_account_id       = ctc.bank_account_id
      AND csl.trx_code              = ctc.trx_code
      AND csh.bank_account_id = cba.bank_account_id
      AND TRUNC(csl.creation_date) = TRUNC(FND_DATE.CANONICAL_TO_DATE(p_reprocess_date))
      AND ctc.trx_code = p_bank_bai_codes
      AND cba.bank_account_num = p_bank_account_number    
      AND NOT EXISTS
                  (SELECT 'X'
                     from xx_ce_tms_jrnl_stg
                    where 1=1
                      AND validation_status in ('S','I') 
                      AND bank_account_id   = csh.bank_account_id
                      AND trx_code              = csl.trx_code
                      AND statement_header_id   = csh.statement_header_id
                      AND statement_line_id     = csl.statement_line_id
                      AND statement_number      = csh.statement_number
                      and statement_line_number = csl.line_number
                  )       
      ;  
lc_dr_sob hr_operating_units.set_of_books_id%TYPE;
lc_cr_sob hr_operating_units.set_of_books_id%TYPE;
ln_cnt1            number:=0;
ln_tot_trans_count number:=0;
ln_tot_trans_error number:=0;
                                
lc_error_text varchar2(2000);
lc_rec_status varchar2(1);    
lc_fun_rec_status varchar2(1);
lc_ret_gl_message varchar2(1000);

                  

BEGIN
      p_ln_cnt1:=0;

     -- Main cursor for translation table set-ups validation
     FOR c1 IN trans_val  LOOP
          
        lc_error_text     := NULL;
        lc_rec_status     :='S';
        lc_ret_gl_message :=NULL;
         
        ln_tot_trans_count:=ln_tot_trans_count+1; 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'c1.bank_account_number :'||c1.bank_account_number||' '||'c1.bank_bai_codes'||' '||c1.bank_bai_codes);
        if LENGTH(LTRIM(RTRIM(c1.search_string))) is  null OR LENGTH(LTRIM(RTRIM(c1.gl_coding_debit))) is  null OR  LENGTH(LTRIM(RTRIM(c1.gl_debit_description))) is  null  OR 
                     LENGTH(LTRIM(RTRIM(c1.gl_credit_description))) is  null OR LENGTH(LTRIM(RTRIM(c1.gl_coding_credit))) is  null then        
               lc_rec_status     :='E';
               lc_error_text:='Validation Error for the Translation set-ups column value is null ';
        
        end if;
        
            -- Function to validate search string validation of length and search char
               lc_fun_rec_status:=xx_ce_search_strg(LTRIM(RTRIM(c1.search_string)));      
           
            if lc_fun_rec_status <> 'S' then
              lc_rec_status     :='E';             
              lc_error_text:=lc_error_text||' -- '||'Validation Error for the Search string length < 5 or search % is missing : '|| c1.search_string;
            end if;
        
            -- Function to Validate Translation Bank Account number set-up
               lc_fun_rec_status:=xx_ce_bank_ac(c1.bank_account_number);

               if lc_fun_rec_status <> 'S' then
               lc_rec_status     :='E'; 
               lc_error_text:=lc_error_text||' -- '||'Validation Error for the Bank Account Number : '|| c1.bank_account_number;
            end if;
            

               -- Function to Validate Translation txn code setup
               lc_fun_rec_status:=xx_ce_txn_code(c1.bank_account_number,c1.bank_bai_codes);
                
            if lc_fun_rec_status <> 'S' then
                lc_rec_status     :='E';
                lc_error_text:=lc_error_text||' -- '||'Validation Error for the Transaction Code : '||c1.bank_bai_codes||'  for Bank AC '||c1.bank_account_number;
            end if;
            
            -- Function to Validate Translation Credit and Debit GL String setup
              lc_fun_rec_status:=xx_ce_gl_string(c1.gl_coding_debit,c1.gl_coding_credit,lc_ret_gl_message);
                 
            if lc_fun_rec_status <> 'S' then
                lc_rec_status     :='E';
                lc_error_text:=lc_error_text||' -- '||lc_ret_gl_message;
            end if; -- Gl string validation


          --insert into staging table for validation failed records of the translation definitions
            If lc_rec_status <> 'S'  THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error :'||lc_error_text);
               --- Update the Existing Record with new group id error message
              UPDATE xx_ce_tms_jrnl_stg 
                 SET group_id = p_group_id 
                     ,validation_status= lc_rec_status 
                     ,validation_text = lc_error_text
                     ,gl_coding_debit = c1.gl_coding_debit
                     ,gl_coding_credit = c1.gl_coding_credit
                     ,search_string = c1.search_string
                     ,DR_JE_LINE_DSC = c1.gl_debit_description
                     ,CR_JE_LINE_DSC = c1.gl_credit_description
               WHERE bank_account_number = c1.bank_account_number     
                 AND trx_code = c1.bank_bai_codes
                 --AND rowid = c1.rowid
                 AND validation_status = 'E'
                 AND process_flag = 'N';
               
                ln_tot_trans_error:=ln_tot_trans_error+1; 
            Else
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'c1.bank_account_number :'||c1.bank_account_number||' '||'c1.bank_bai_codes'||' '||c1.bank_bai_codes);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Search_string:'|| c1.search_string);
                -- Cursor to process Records from CE Statements    for revalidation success records    
                -- CE statement tables cursor
            IF c1.search_string NOT LIKE '%CATCH ALL%' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside search string Standard');
                FOR C2 IN ce_tms(c1.bank_account_number,c1.search_string,c1.bank_bai_codes) LOOP 
        
                
                      lc_error_text:= null;
                      lc_rec_status:='S';
                      lc_cr_sob:= null;
                      lc_dr_sob:= null;
                
                             -- function call to get gl Debit ac SOB id
                             lc_dr_sob:= xx_ce_gl_sob(c1.gl_coding_debit,c2.currency_code);
                            
                            
                             -- function call to get gl Credit ac SOB id
                             lc_cr_sob:= xx_ce_gl_sob(c1.gl_coding_credit,c2.currency_code);
                             
                             if lc_dr_sob is null or lc_cr_sob is null then
                                  lc_cr_sob:= null;
                                  lc_dr_sob:= null;
                                  lc_error_text:= 'SOB fetching Error ';
                                  lc_rec_status:='E';
                             end if;
                   
                         --- insert the records into staging table procedure call
                          xx_ce_gl_insert_stg
                            (  
                              c1.bank_account_number,--bank_account_number
                              c2.bank_account_id,     --bank_account_id
                              c1.bank_bai_codes ,
                              c2.transaction_code_id,--trx_code_id
                              c1.search_string,
                              C1.GL_CODING_DEBIT,
                              c1.gl_coding_credit,
                              c1.gl_credit_description, --cr_je_line_dsc
                              c1.gl_debit_description,     --dr_je_line_dsc                  
                              c2.statement_header_id,   --statement_header_id
                              c2.statement_line_id,        --statement_line_id
                              c2.statement_number,    --statement_number
                              c2.line_number,       --statement_line_number
                              c2.amount ,             --entered_cr_dr
                              c2.currency_code ,     --currency_code
                              lc_cr_sob ,             --cr_set_of_books_id
                              lc_dr_sob,             --dr_set_of_books_id                  
                              p_group_id ,           --group_id
                              lc_rec_status ,       --validation_status
                              lc_error_text         --validation_text
                             );
                        
                           ln_cnt1:=ln_cnt1+1;
                
                        
                      END LOOP; -- End of CE Statement Cursor
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_cnt1'||' '||ln_cnt1);
       
        END IF;
        -- Start  Process  added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017
        IF c1.search_string LIKE '%CATCH ALL%' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside search string %CATCH ALL%');
         -- CURSOR ce_catch_all(bank_account_number number,bank_bai_codes varchar2)
        FOR C2 IN ce_catch_all(c1.bank_account_number,c1.bank_bai_codes) LOOP 
                      lc_error_text:= null;
                      lc_rec_status:='S';
                      lc_cr_sob:= null;
                      lc_dr_sob:= null;
                
                             -- function call to get gl Debit ac SOB id
                             lc_dr_sob:= xx_ce_gl_sob(c1.gl_coding_debit,c2.currency_code);
                            
                            
                             -- function call to get gl Credit ac SOB id
                             lc_cr_sob:= xx_ce_gl_sob(c1.gl_coding_credit,c2.currency_code);
                             
                             if lc_dr_sob is null or lc_cr_sob is null then
                                  lc_cr_sob:= null;
                                  lc_dr_sob:= null;
                                  lc_error_text:= 'SOB fetching Error ';
                                  lc_rec_status:='E';
                             end if;
                   
                         --- insert the records into staging table procedure call
                          xx_ce_gl_insert_stg
                            (  
                              c1.bank_account_number,--bank_account_number
                              c2.bank_account_id,     --bank_account_id
                              c1.bank_bai_codes ,
                              c2.transaction_code_id,--trx_code_id
                              c1.search_string,
                              C1.GL_CODING_DEBIT,
                              c1.gl_coding_credit,
                              c1.gl_credit_description, --cr_je_line_dsc
                              c1.gl_debit_description,     --dr_je_line_dsc                  
                              c2.statement_header_id,   --statement_header_id
                              c2.statement_line_id,        --statement_line_id
                              c2.statement_number,    --statement_number
                              c2.line_number,       --statement_line_number
                              c2.amount ,             --entered_cr_dr
                              c2.currency_code ,     --currency_code
                              lc_cr_sob ,             --cr_set_of_books_id
                              lc_dr_sob,             --dr_set_of_books_id                  
                              p_group_id ,           --group_id
                              lc_rec_status ,       --validation_status
                              lc_error_text         --validation_text
                             );
                        
                           ln_cnt1:=ln_cnt1+1;
                
                        
                      END LOOP; -- End of CE ce_catch_all Cursor
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_cnt1'||' '||ln_cnt1);
          END IF;     ------IF c2.search_string LIKE '%CATCH ALL%' THEN       
          -- End Process  added for missing bank transactions type CATCH all code --dsomavanshi 23/06/2017
                       -- Update the Error Record as success    
                      UPDATE xx_ce_tms_jrnl_stg 
                         SET group_id = p_group_id 
                             ,validation_status= lc_rec_status 
                             ,validation_text = lc_error_text
                             ,gl_coding_debit = c1.gl_coding_debit
                             ,gl_coding_credit = c1.gl_coding_credit
                             ,search_string = c1.search_string
                             ,DR_JE_LINE_DSC = c1.gl_debit_description
                             ,CR_JE_LINE_DSC = c1.gl_credit_description
                             ,process_flag = 'P'
                       WHERE bank_account_number = c1.bank_account_number     
                         AND trx_code = c1.bank_bai_codes
                         --AND rowid = c1.rowid
                         AND validation_status = 'E'
                         AND process_flag = 'N';        
            
                End if;
            
         END LOOP; -- End of main Cursor        
            
            COMMIT;
            
            p_ln_cnt1:=ln_cnt1;
            p_tot_trans_count:= ln_tot_trans_count ;
            p_tot_trans_error:= ln_tot_trans_error;
                
 
  
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
END XX_CE_GL_REVALIDATION;
  
  -- +===================================================================+
  -- | Name        : XX_CE_CHECK_DUPLICATE                               |
  -- |                                                                   |
  -- | Description : This procedure is used to check duplicates in       |
  -- |               xx_ce_tms_jrnl_stg table                            |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id                                          |
  -- | Returns     :                                                     |
  -- +===================================================================+

PROCEDURE XX_CE_CHECK_DUPLICATE(p_group_id number) 
IS   
BEGIN
  
          --- Check any Duplicate records exists with same Statement Details
          FOR duprec IN (SELECT distinct 
                           statement_header_id ,
                           statement_line_id ,
                           statement_number ,
                           statement_line_number,
                           trx_code,
                           gl_coding_debit,
                           gl_coding_credit,
                           entered_cr_dr
                      FROM xx_ce_tms_jrnl_stg
                     WHERE process_flag = 'N'
                       AND validation_status ='S'
                       AND validation_level ='CE_STATEMENT'
                       AND group_id = p_group_id
                    ) LOOP
                
            
            --- update the staging table 
            UPDATE xx_ce_tms_jrnl_stg t1
            SET validation_status = 'E'
                  ,process_flag ='P'
                  ,validation_text = 'Duplicate Statement Lines Pulled for the different Search Text '
             WHERE process_flag = 'N'
               AND validation_status ='S'
               and validation_level ='CE_STATEMENT'
               AND group_id = p_group_id
               AND statement_header_id = duprec.statement_header_id
               AND statement_line_id = duprec.statement_line_id
               AND statement_number = duprec.statement_number
               AND statement_line_number  = duprec.statement_line_number
               AND trx_code  = duprec.trx_code
               AND gl_coding_debit = duprec.gl_coding_debit
               AND gl_coding_credit = duprec.gl_coding_credit
               AND entered_cr_dr  = duprec.entered_cr_dr
               AND rowid in (select rowid
                               FROM  
                                     (SELECT rowid,statement_header_id,statement_line_id,statement_number,statement_line_number,trx_code,gl_coding_debit,
                                             gl_coding_credit,entered_cr_dr,
                                             ROW_NUMBER() OVER(PARTITION BY statement_header_id,statement_line_id,statement_number,statement_line_number,
                                                trx_code,gl_coding_debit,gl_coding_credit,entered_cr_dr order by statement_header_id,statement_line_id,statement_number,statement_line_number,
                                                trx_code) rn
                                     FROM xx_ce_tms_jrnl_stg t2    
                                    WHERE 1=1    
                                      AND validation_status in ('I','S')
                                      AND validation_level ='CE_STATEMENT'
                                       AND statement_header_id = duprec.statement_header_id
                                       AND statement_line_id = duprec.statement_line_id
                                       AND statement_number = duprec.statement_number
                                       AND statement_line_number  = duprec.statement_line_number
                                       AND trx_code  = duprec.trx_code
                                       AND gl_coding_debit = duprec.gl_coding_debit
                                       AND gl_coding_credit = duprec.gl_coding_credit
                                       AND entered_cr_dr  = duprec.entered_cr_dr
                                       -----AND process_flag = 'N'
                                       -----AND group_id = p_group_id
                                    )
                                WHERE rn >1
                              ); 
                                                             
        COMMIT;
 
      END LOOP;  -- end of Duplicate Check Cursor

 EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
    FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);        
 END XX_CE_CHECK_DUPLICATE;      

  -- +===================================================================+
  -- | Name        : XX_CE_GL_NA_STG                                     |
  -- |                                                                   |
  -- | Description : This procedure is used to insert the records into   |
  -- |               XX_GL_INTERFACE_NA_STG table through an API         |
  -- |               insert valid data                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id                                          |
  -- | Returns     :                                                     |
  -- +===================================================================+

PROCEDURE XX_CE_GL_NA_STG(
                          p_group_id number,
                          p_rec_count out number
                          ) 
IS 

ln_cnt2 number:=0;
lc_output_msg  varchar2(2000);

BEGIN
     p_rec_count:=0;
     
           -- Check Duplicates exists in staging table
            xx_ce_check_duplicate(p_group_id);
     
            -- insert the validated records into GL Stating table
            FOR I  IN  (SELECT *
                          FROM xx_ce_tms_jrnl_stg
                          WHERE process_flag  = 'N'
                          AND validation_status ='S'
                          AND group_id   = p_group_id
                          )  
              LOOP

                ln_cnt2:= ln_cnt2+1;
                
                BEGIN
                 
                   lc_output_msg:=null; 
                   
                   -- DR Details
                   xx_gl_interface_pkg.create_stg_jrnl_line(
                                                            p_status => 'NEW'
                                                          , p_date_created => i.creation_date
                                                          , p_created_by => i.created_by
                                                          , p_actual_flag => 'A'
                                                          , p_group_id => p_group_id
                                                          , p_batch_name => G_Batch_Name
                                                          , p_batch_desc => null
                                                          , p_user_source_name => G_Je_Source_Name
                                                          , p_user_catgory_name => G_Category_Name
                                                          , p_set_of_books_id => i.dr_set_of_books_id
                                                          , p_accounting_date => Trunc(SYSDATE)--Modified for Defect#43393 V1.2 to fix Unbalanced Journals timing issue
                                                          , p_currency_code => i.currency_code
                                                          , p_company => substr(i.gl_coding_debit,1,instr(i.gl_coding_debit,'.',1)-1)  
                                                          , p_cost_center => substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,1)+1,instr(i.gl_coding_debit,'.',1,2)-instr(i.gl_coding_debit,'.',1,1)-1) 
                                                          , p_account =>  substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,2)+1,instr(i.gl_coding_debit,'.',1,3)-instr(i.gl_coding_debit,'.',1,2)-1)
                                                          , p_location => substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,3)+1,instr(i.gl_coding_debit,'.',1,4)-instr(i.gl_coding_debit,'.',1,3)-1) 
                                                          , p_intercompany => substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,4)+1,instr(i.gl_coding_debit,'.',1,5)-instr(i.gl_coding_debit,'.',1,4)-1) 
                                                          , p_channel => substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,5)+1,instr(i.gl_coding_debit,'.',1,6)-instr(i.gl_coding_debit,'.',1,5)-1) 
                                                          , p_future => substr(i.gl_coding_debit,instr(i.gl_coding_debit,'.',1,6)+1)
                                                          , p_entered_dr => i.entered_cr_dr
                                                          , p_entered_cr => null
                                                          , p_je_name => null 
                                                          , p_je_reference => p_group_id
                                                          , p_je_line_dsc => i.dr_je_line_dsc
                                                          , x_output_msg => lc_output_msg
                                                          );
                                                          
                    
                    -- CR Details insert
                    xx_gl_interface_pkg.create_stg_jrnl_line(
                                                            p_status => 'NEW'
                                                          , p_date_created => i.creation_date
                                                          , p_created_by => i.created_by
                                                          , p_actual_flag => 'A'
                                                          , p_group_id => p_group_id
                                                          , p_batch_name => G_Batch_Name
                                                          , p_batch_desc =>  null
                                                          , p_user_source_name => G_Je_Source_Name
                                                          , p_user_catgory_name => G_Category_Name
                                                          , p_set_of_books_id => i.cr_set_of_books_id
                                                          , p_accounting_date => Trunc(SYSDATE)--Modified for Defect#43393 V1.2 to fix Unbalanced Journals timing issue
                                                          , p_currency_code => i.currency_code
                                                          , p_company => substr(i.gl_coding_credit,1,instr(i.gl_coding_credit,'.',1)-1)  
                                                          , p_cost_center => substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,1)+1,instr(i.gl_coding_credit,'.',1,2)-instr(i.gl_coding_credit,'.',1,1)-1) 
                                                          , p_account =>  substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,2)+1,instr(i.gl_coding_credit,'.',1,3)-instr(i.gl_coding_credit,'.',1,2)-1)
                                                          , p_location => substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,3)+1,instr(i.gl_coding_credit,'.',1,4)-instr(i.gl_coding_credit,'.',1,3)-1) 
                                                          , p_intercompany => substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,4)+1,instr(i.gl_coding_credit,'.',1,5)-instr(i.gl_coding_credit,'.',1,4)-1) 
                                                          , p_channel => substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,5)+1,instr(i.gl_coding_credit,'.',1,6)-instr(i.gl_coding_credit,'.',1,5)-1) 
                                                          , p_future => substr(i.gl_coding_credit,instr(i.gl_coding_credit,'.',1,6)+1)
                                                          , p_entered_dr => null
                                                          , p_entered_cr => i.entered_cr_dr
                                                          , p_je_name => null 
                                                          , p_je_reference => p_group_id
                                                          , p_je_line_dsc => i.cr_je_line_dsc
                                                          , x_output_msg => lc_output_msg
                                                          );
                                                          
                                                          
                              --Update the staging table with status flag
                              UPDATE xx_ce_tms_jrnl_stg tjs
                              SET  process_flag = 'P'
                                   ,validation_status ='I'
                              WHERE process_flag        = 'N'
                              AND validation_status ='S'
                              AND group_id   = p_group_id
                              AND statement_header_id = i.statement_header_id
                              AND statement_line_id = i.statement_line_id
                              AND statement_number = i.statement_number
                              AND statement_line_number  = i.statement_line_number
                              AND trx_code  = i.trx_code
                              AND gl_coding_debit = i.gl_coding_debit
                              AND gl_coding_credit = i.gl_coding_credit
                              AND entered_cr_dr  = i.entered_cr_dr;
                     
                     
                     
                     If lc_output_msg is not null then
                        
                       ln_cnt2:= ln_cnt2-1;
                       
                       UPDATE xx_ce_tms_jrnl_stg tjs
                          SET validation_status ='E'
                             ,validation_level ='CE_STATEMENT'
                             ,validation_text='Record Failed in inserting into XX_GL_INTERFACE_NA_STG table - '||LC_OUTPUT_MSG
                          WHERE process_flag    = 'N'
                          AND validation_status ='S'
                          AND statement_header_id = i.statement_header_id
                          AND statement_line_id = i.statement_line_id
                          AND statement_number = i.statement_number
                          AND statement_line_number  = i.statement_line_number
                          AND trx_code  = i.trx_code
                          AND gl_coding_debit = i.gl_coding_debit
                          AND gl_coding_credit = i.gl_coding_credit
                          AND entered_cr_dr  = i.entered_cr_dr
                          AND group_id   = p_group_id;
                       
                     end if;
                 
                 EXCEPTION
                   WHEN OTHERS THEN
                       ln_cnt2:= ln_cnt2-1;
                       
                        UPDATE xx_ce_tms_jrnl_stg tjs
                          SET validation_status ='E'
                             ,validation_level ='CE_STATEMENT'
                             ,validation_text='Record Failed in inserting into XX_GL_INTERFACE_NA_STG table - '||LC_OUTPUT_MSG
                          WHERE process_flag    = 'N'
                          AND validation_status ='S'
                          AND statement_header_id = i.statement_header_id
                          AND statement_line_id = i.statement_line_id
                          AND statement_number = i.statement_number
                          AND statement_line_number  = i.statement_line_number
                          AND trx_code  = i.trx_code
                          AND gl_coding_debit = i.gl_coding_debit
                          AND gl_coding_credit = i.gl_coding_credit
                          AND entered_cr_dr  = i.entered_cr_dr
                          AND group_id   = p_group_id;
                 END;                
            
                COMMIT;
          
             END LOOP;
            

              p_rec_count:=ln_cnt2;

EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error:'|| SQLERRM);
END XX_CE_GL_NA_STG;

  -- +===================================================================+
  -- | Name        : XX_CE_GL_INTF                                       |
  -- |                                                                   |
  -- | Description : This procedure is used to call Journal Import       |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : P_group_id , P_Je_Source_Name                       |
  -- | Returns     :                                                     |
  -- +===================================================================+

PROCEDURE XX_CE_GL_INTF(p_group_id number) 
IS
  ln_conc_id NUMBER;
  lb_bool    BOOLEAN;
  lc_phase                 VARCHAR2(100);
  lc_status                VARCHAR2(100);
  lc_dev_phase             VARCHAR2(100);
  lc_dev_status            VARCHAR2(100);
  lc_message               VARCHAR2(100);
BEGIN

    ---- Submit OD: GL Interface for OD CM Treasury 2 to transfer the records into XX_GL_INTERFACE_NA_STG table and launch Journal Import program

                               ln_conc_id := fnd_request.submit_request(
                                                                         application => 'XXFIN'
                                                                        ,program     => 'XX_GL_CE_INT_TREASURY2'
                                                                        ,description => NULL
                                                                        ,start_time  => SYSDATE
                                                                        ,sub_request => FALSE
                                                                        ,argument1   => G_Je_Source_Name
                                                                        ,argument2   => 'N'
                                                                         );
                                     COMMIT;                                
                                        
                                     lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                                ,5
                                                                                ,5000
                                                                                ,lc_phase
                                                                                ,lc_status
                                                                                ,lc_dev_phase
                                                                                ,lc_dev_status
                                                                                ,lc_message
                                                                                 );
  
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
END XX_CE_GL_INTF;

  -- +===================================================================+
  -- | Name        : MAIN                                                |
  -- |                                                                   |
  -- | Description : This procedure is used to validate translation      |
  -- |               code againes CE headers and lines table data and    |
  -- |               insert valid data into GL Interface table           |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters  : p_reprocess                                         |
  -- |               p_reprocess_DATE                                    |
  -- |                                                                   |
  -- | Returns     :                                                     |
  -- +===================================================================+
PROCEDURE MAIN(
               X_ERRBUF          OUT NOCOPY      VARCHAR2
              ,X_RETCODE         OUT NOCOPY      NUMBER
                ,p_reprocess      VARCHAR2
              ,p_reprocess_date VARCHAR2)
IS

ln_conc_id1 NUMBER:=FND_GLOBAL.CONC_REQUEST_ID();
lb_bool    BOOLEAN;
lc_phase                 VARCHAR2(100);
lc_status                VARCHAR2(100);
lc_dev_phase             VARCHAR2(100);
lc_dev_status            VARCHAR2(100);
lc_message               VARCHAR2(100);
gc_email_lkup            XX_FIN_TRANSLATEVALUES.SOURCE_VALUE1%TYPE;
ln_group_id   NUMBER;
lc_error_text VARCHAR2(2000);
lc_rec_status VARCHAR2(1);
l_rec_count NUMBER:=0;  
ln_cnt1 NUMBER:=0;
ln_tot_trans_count NUMBER:=0;
ln_tot_trans_error NUMBER:=0;
lc_currency_code  VARCHAR2(3);
l_rec_flag  varchar2(1):='N';
l_process_date_count Number:=0;
l_line_space varchar2(1):='N';
lp_reprocess_date  varchar2(50);
 
BEGIN

  select decode(p_reprocess,'YES',p_reprocess_date,null) into lp_reprocess_date from dual;

  --- Print Log file for parameter details
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                         Custom Treasury Journal Entry Creation Execution Report                                                     Report Date :  ' ||TO_CHAR(SYSDATE,'DD-MON-YY HH:MM'));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                                                  ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                                                  ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                                                  ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Reprocess Flag   :' || p_reprocess);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Reprocess Date   :' || lp_reprocess_date);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                                                  ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                                                  ');
  
  --- Getting interface control sequence ID as Batch id 
  BEGIN
    SELECT gl_interface_control_s.NEXTVAL INTO ln_group_id FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error in GL Interface sequence.');
  END;
      
        --IF Flag is Yes Reprocess the error Translation setup records from staging table 
        If p_reprocess = 'YES' THEN
        -- Call Revalidation PROCEDURE          
             xx_ce_gl_revalidation(ln_group_id,p_reprocess_date,ln_cnt1,ln_tot_trans_count,ln_tot_trans_error);
         
         --- added this flag to execute the insert into NA STG table for revalidation success records
         l_process_date_count:=0; 
        Else    
              -- Call Validation Procedure
                xx_ce_gl_validation(ln_group_id,ln_cnt1,ln_tot_trans_count,ln_tot_trans_error);
        
        End if;  -- Revalidation flag end if

      
       -- Calling procedure to insert valid records into gl_interface_na_stg table and l_rec_count will return number rows inserted
       xx_ce_gl_na_stg(ln_group_id,l_rec_count);
       
       --- if  Records inserted into gl_interface_na_stg table, then Submit the Journal Import and OD: GL Interface for OD CM Treasury 2 program
       if l_rec_count > 0 then
          xx_ce_gl_intf(ln_group_id);
       end if;

      
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bank Acc #               Statement #          Currency    Statement Line    TRX Code   GL DR Acct String                               GL CR Acct String                                             DR $ Amount                CR $ Amount  Validation Level  Error Message');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------               -----------          --------    --------------    --------   -----------------                               -----------------                                             ------------               -----------  ----------------  -------------');
      
      -- for loop to pull all the records for current group id to display output messages
      for i  in
              (select a.* 
                 FROM xx_ce_tms_jrnl_stg a
                WHERE 1=1
                  and group_id       = ln_group_id
          order by VALIDATION_STATUS 
              )
      loop
      
           if i.VALIDATION_STATUS = 'I' and l_line_space='N' then
              l_line_space:='Y';
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
           end if;
    
      
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,(RPAD(I.bank_account_number,25,' ') || RPAD(NVL(TO_CHAR(I.statement_number),' '),21,' ') ||RPAD(NVL(I.currency_code,' '),12,' ')|| RPAD(NVL(TO_CHAR(I.statement_line_number),' '),18,' ') || RPAD(NVL(I.trx_code,' '),11,' ') ||RPAD(NVL(I.gl_coding_debit,' '),48,' ')||RPAD(NVL(I.gl_coding_credit,' '),48,' ') || LPAD(LTRIM(RTRIM(TO_CHAR(I.entered_cr_dr,'$999,999,999,990.00'))),26,' ') || LPAD(LTRIM(RTRIM(TO_CHAR(I.entered_cr_dr,'$999,999,999,990.00'))),26,' ') || RPAD(' ',2,' ') || RPAD(I.validation_level,18,' ') || RPAD(i.validation_text,250,' ') ));
     
            
        l_rec_flag:='Y';
      end loop;

       -- If any records processed then log message display with complete information
      if l_rec_flag = 'Y'  then
     
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                ***************** End of Report *******************                                                    ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          
        If p_reprocess = 'YES' THEN
          
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of ReValidation Translation Setup records fetched : '||ln_tot_trans_count);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of ReValidation Translation Setup Error records   : '||ln_tot_trans_error);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of ReValidation Statement Lines Fetched           : '||ln_cnt1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of ReValidation Inserted in GL NA Staging Table   : '||l_rec_count);

        else
             
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of Translation Setup records fetched : '||ln_tot_trans_count);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of Translation Setup Error records   : '||ln_tot_trans_error);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of Statement Lines Fetched           : '||ln_cnt1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No. Of Inserted in GL NA Staging Table   : '||l_rec_count);
          
        end if;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Group Id : '||ln_group_id); 
     else
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                       NO DATA EXISTS TO PROCESS                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       '); 
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                ***************** End of Report *******************                                                    ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                                                                       ');
    
       End if;          
        
   
                                  ----------------------------------------------
                                  -- Submit request to email the program output
                                  ----------------------------------------------
         
                                  ln_conc_id1 := fnd_request.submit_request(
                                                                            application => 'XXFIN'
                                                                           ,program     => 'XXGLINTERFACEEMAIL'
                                                                           ,description => NULL
                                                                           ,start_time  => SYSDATE
                                                                           ,SUB_REQUEST => FALSE
                                                                           ,argument1   => ln_conc_id1
                                                                           ,argument2   => g_je_source_name
                                                                           ,argument3   => 'OD CM Treasury 2 GL Import Validation Report'
                                                                          );

                                    COMMIT;
        
            -------------------------------------------------------------------------------
            ---  Script to delete 90 days old processed records from staging table
            -------------------------------------------------------------------------------
            DELETE FROM xx_ce_tms_jrnl_stg
            WHERE process_flag = 'P'
              AND validation_status in ('I','S')
              AND trunc(process_date) <= trunc(sysdate)-90 ;

            -------------------------------------------------------------------------------
            ---  Script to delete 180 days old processed records from staging table
            -------------------------------------------------------------------------------
            DELETE FROM xx_ce_tms_jrnl_stg
            WHERE trunc(process_date) <= trunc(sysdate)-180 ;   
                     
              
            COMMIT;
      
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.output,'Error:'|| SQLERRM);
  X_RETCODE:=2;
END MAIN;


END XX_CE_TMS_JE_PKG;
/
SHOW ERROR

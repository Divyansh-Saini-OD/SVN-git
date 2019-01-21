CREATE OR REPLACE PACKAGE BODY XXOD_GL_IRS_QTRLY_EXTRACT_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT Office Depot                                          |
-- +===========================================================================+
-- | Name             :  XXOD_GL_IRS_QTRLY_EXTRACT_PKG.pkb                     |
-- | Description      :  This Package is used  to Extract GL COA, GL Balances, |  
-- |                     GL Journal Detail for IRS quarterly Audit             | 
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author         Remarks                                |
-- |=======  ==========  =============  =======================================|
-- |1.0      4-Aug-2009  Lenny Lee      Initial programming         	       |
-- |1.1      2-Jun-2011  Lenny Lee      Defect#11390 - expand extract numeric  |
-- |                                    from 13 t0 16 digits                   |
-- |1.2      29-Aug-2013 Anantha Reddy  R12 Retrofit                  	       |
-- |1.3      19-Dec-2013 Jay Gupta      Defect#27309 - Adding Parameter Ledger |
-- |1.4      19-Mar-2014 Jay Gupta      Defect#28419 -Removing Ledger Parameter|
-- |1.5	     13-Oct-2014 Avinash Baddam Defect#31281 FTP EBS files to Mainframe|
-- |1.6      19-Nov-2015 Harvinder Rakhra Retrofit R12.2                       |
-- |1.7      07-DEC-2016 Punita Kumari	Defect#40349- Incorporate the change of| 
-- |                                    Defect#31281 with Retrofit 12.2		   |
-- +===========================================================================+
gc_file_path VARCHAR2(500)  := 'XXFIN_OUTBOUND';
  PROCEDURE write_log(p_debug_flag VARCHAR2,
        p_msg VARCHAR2)
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT Office Depot                                          |
-- +===========================================================================+
-- | Name             :  write_log                                             |
-- | Description      :  This procedure is used to write in to log file based  |
-- |                     on the debug flag                                     |
-- +===========================================================================+
AS
BEGIN
    IF(p_debug_flag = 'Y') Then
        fnd_file.put_line(FND_FILE.LOG,p_msg);
    END IF;
END;

PROCEDURE generate_file(p_directory VARCHAR2
                       ,p_file_name VARCHAR2
                       ,p_request_id NUMBER)
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT Office Depot                                          |
-- +===========================================================================+
-- | Name             :  generate_file                                         |
-- | Description      :  This procedure is used to generate a output extract   |
-- |                     file and it calls XPTR                                |
-- +===========================================================================+
AS
   ln_req_id         	NUMBER;
   lc_source_dir_path   VARCHAR2(4000);
BEGIN
    BEGIN
       SELECT directory_path
         INTO lc_source_dir_path
         FROM   dba_directories
        WHERE  directory_name = gc_file_path;
       EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
    END;
    
    /* AB for defect# 31281*/    
    ln_req_id := fnd_request.submit_request(application      => 'XXFIN',
					        program      => 'XXGLIRSCOPYFTP',
					      argument1      => lc_source_dir_path||'/'||p_request_id||'.out',
					      argument2      => p_directory,
					      argument3      => p_file_name,
					      argument4      => p_request_id);

        
        
    /*    ln_req_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP'
                                    ,''
                                    ,''
                                    ,FALSE
                                    ,lc_source_dir_path||'/'||p_request_id||'.out'
                                        ,p_directory||'/'||p_file_name
                                    ,'','','','',p_request_id,'','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','') ;*/

END;

/* For defect# 31281*/
PROCEDURE copyftp(p_ret_code OUT NUMBER
             	 ,p_err_msg  OUT VARCHAR2
		 ,p_source_file  VARCHAR2
                 ,p_dest_directory      VARCHAR2
                 ,p_dest_file		VARCHAR2
                 ,p_parent_request_id 	NUMBER)
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT Office Depot                                          |
-- +===========================================================================+
-- | Name             :  copyftp                                               |
-- | Description      :  This procedure is used to submit copy and ftp programs|
-- |                     Called from 'OD: GL IRS File Copy and Put Program'    |
-- +===========================================================================+
AS
   ln_req_id         		NUMBER;
   ln_ftp_req_id		NUMBER;
   
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (50);
   lc_dev_status          VARCHAR2 (50);
   lc_message             VARCHAR2 (1000);
   lb_result              BOOLEAN;
   
   lc_process_name        VARCHAR2 (50) ;
   lc_dest_file_name	  VARCHAR2 (50);
   lc_del_source_file	  VARCHAR2 (1) := 'Y';
   lc_dest_string	  VARCHAR2(50) := NULL;
   
BEGIN
    
    ln_req_id:=fnd_request.submit_request('XXFIN','XXCOMFILCOPYREP'
                                    ,''
                                    ,''
                                    ,FALSE
                                    ,p_source_file
                                    ,p_dest_directory||'/'||p_dest_file
                                    ,'','','','',p_parent_request_id,'','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','','','','','','',''
                                    ,'','','','','','','','','','','','','','','','') ;
                                    
    COMMIT;
 
    FND_FILE.PUT_LINE(FND_FILE.LOG , 'OD:Common File Copy for Reports Submitted. Request Id : ' || ln_req_id);

    WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call wait for request till the request is not completed
    LOOP
	lb_result := fnd_concurrent.wait_for_request (ln_req_id,
						      10,
						      200,
						      lc_phase,
						      lc_status,
						      lc_dev_phase,
		     				      lc_dev_status,
						      lc_message);
     END LOOP;  
     
     IF lc_status = 'Normal'
     THEN
		 -- -------------------------------------------------------
		 -- Added code to submit the OD: Common Put Program
		 -- -------------------------------------------------------
		 lc_process_name := rtrim(p_dest_file,'.txt');
		 
		 IF p_dest_file = 'OD_GL_BALC_IRS_MVSFTP.txt' THEN
		    lc_dest_file_name := 'BALC';
		 ELSIF p_dest_file = 'OD_GL_COA_IRS_MVSFTP.txt' THEN
		    lc_dest_file_name := 'COA';
		 ELSIF p_dest_file = 'OD_GL_JRNL_DETAIL_IRS_MVSFTP.txt' THEN
		    lc_dest_file_name := 'JRNL';
		 END IF;
		 
		 ln_ftp_req_id := fnd_request.submit_request(application      => 'XXFIN',
							     program          => 'XXCOMFTP',
							     argument1        => lc_process_name,
							     argument2        => p_dest_file,
							     argument3        => lc_dest_file_name,
							     argument4        => lc_del_source_file,
							     argument5        => lc_dest_string);

		 COMMIT;

                 FND_FILE.PUT_LINE(FND_FILE.LOG , 'OD: Common Put Program Submitted. Request Id : ' || to_char(ln_ftp_req_id));  
     END IF;                 

END copyftp;

PROCEDURE Extract_Journal(p_ret_code OUT NUMBER
             ,p_err_msg  OUT VARCHAR2
        --V1.4     ,p_ledger_id NUMBER --V1.3
             ,p_directory VARCHAR2
             ,p_file_name VARCHAR2
             ,p_debug_flag VARCHAR2
             ,p_file_path  VARCHAR2
             ,p_period_name_begin VARCHAR2
             ,p_period_name_end VARCHAR2)
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT OfficeDepot                                           |
-- +===========================================================================+
-- | Name             :  Extract_Journal                                       |
-- | Description      : This procedure is used to extract the journal details  |
-- |                    for the first open period                              |
-- +===========================================================================+
AS
    l_data            VARCHAR2(4000);
    l_period_name_begin    VARCHAR2(30);
        l_period_name_end    VARCHAR2(30);
        l_out_cnt               NUMBER;
       ln_buffer       BINARY_INTEGER  := 32767;
        lt_file         utl_file.file_type;
        lc_filename  VARCHAR2(4000);
        ln_req_id NUMBER;
BEGIN
   gc_file_path := p_file_path;
    write_log(p_debug_flag,'Extracting the Journal Details');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
        lc_filename:= ln_req_id||'.out';
         lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
         l_period_name_begin:=p_period_name_begin;
         L_period_name_end:=p_period_name_end;
         write_log(p_period_name_begin,'Begin Period Name from Parameter');
         write_log(p_period_name_end,'End Period Name from Parameter');
         l_out_cnt := 0;

IF p_period_name_end IS NULL THEN
         BEGIN
        SELECT period_name
        INTO l_period_name_end
        FROM GL_PERIOD_STATUSES
        WHERE CLOSING_STATUS='O'
        AND APPLICATION_ID=101
        -- V1.3, Commented AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID')
      --V1.4  AND ledger_id = p_ledger_id --V1.3, Added
        AND ledger_id=FND_PROFILE.value('GL_SET_OF_BKS_ID') --V1.4
        AND EFFECTIVE_PERIOD_NUM =
            (SELECT MIN(EFFECTIVE_PERIOD_NUM)
              FROM GL_PERIOD_STATUSES
              WHERE CLOSING_STATUS='O'
              AND APPLICATION_ID=101 
              -- V1.3, Commented AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID')
              --AND ledger_id = p_ledger_id); --V1.3, Added
              AND ledger_id=FND_PROFILE.value('GL_SET_OF_BKS_ID')); --V1.4
              l_period_name_begin:=TO_CHAR(ADD_MONTHS(TO_DATE(l_period_name_end,'MON-YY'),  -3), 'MON-YY');
              EXCEPTION
        WHEN OTHERS THEN
            l_period_name_begin:=NULL;
            l_period_name_end:=NULL;
            fnd_file.put_line(FND_FILE.LOG,'unable to fetch the minimum open period from GL ');
          END;

ELSE
 l_period_name_begin := P_period_name_begin;
 l_period_name_end   := P_period_name_end;
 l_out_cnt := 0;

END IF;

    IF l_period_name_end  IS NOT NULL  and l_period_name_begin IS NOT NULL THEN
        FOR Journal_Cur IN
        (SELECT
             lpad(GJH.je_header_id,15,0) je_header_id
            --,lpad(GJH.set_of_books_id,15,0) set_of_books_id--1.2-Replaced equivalent table columns as per R12 upgrade
            ,lpad(GJH.ledger_id,15,0) ledger_id
            ,lpad(GJH.je_batch_id,15,0) je_batch_id
                        ,rpad(to_char(to_date(GJH.period_name,'MON-YY'),'YYYYMM'),15)     period_name
            ,rpad(nvl(GJH.description,' '),50) description
            ,decode(GJH.posted_date,NULL,'          ',rpad(to_char(GJH.posted_date,'YYYY-MM-DD'),10)) posted_date
            ,rpad(nvl(GJS.user_je_source_name,' '),25) je_source
                        ,rpad(nvl(GJC.user_je_category_name,' '),25) je_category
            ,rpad(nvl(GJH.actual_flag,' '),1) actual_flag
            ,rpad(nvl(GJH.currency_code,' '),15) currency_code
            ,rpad(nvl(GJH.status,' '),1) status
            ,decode(GJH.date_created,NULL,'          ',rpad(to_char(GJH.date_created,'YYYY-MM-DD'),10)) date_created
            ,lpad(nvl(GJL.je_line_num,0),15,0) je_line_num
            ,rpad(nvl(GJL.status,' '),1) line_status
                        ,rpad(nvl(GCC.SEGMENT1,' '),6) segment1
            ,rpad(nvl(GCC.SEGMENT2 || '.' || GCC.SEGMENT3 || '.' || GCC.SEGMENT4 || '.' || GCC.SEGMENT5 || '.' || GCC.SEGMENT6 || '.' || GCC.SEGMENT7,' '),50) gl_accounting_string
            ,rpad(nvl(GJL.description,' '),50) line_description
            ,DECODE(sign(NVL(GJL.accounted_dr,0)),1,'+'||TRIM(TO_CHAR(GJL.accounted_dr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(GJL.accounted_dr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(GJL.accounted_dr,0),'0999999999999999.99'))) accounted_dr
            ,DECODE(sign(NVL(GJL.accounted_cr,0)),1,'+'||TRIM(TO_CHAR(GJL.accounted_cr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(GJL.accounted_cr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(GJL.accounted_cr,0),'0999999999999999.99'))) accounted_cr
        FROM
             gl_je_headers GJH
            ,gl_je_lines GJL
            ,gl_code_combinations GCC
            ,gl_je_sources  GJS
            ,gl_je_categories GJC
        WHERE
                GJH.je_header_id=GJL.je_header_id
            AND GJL.code_combination_id=GCC.code_combination_id
            --AND GJH.set_of_books_id=fnd_profile.value('GL_SET_OF_BKS_ID') -- allow extract for all companies
            --V1.4AND gjh.ledger_id = p_ledger_id
            --V1.4AND gjl.ledger_id = p_ledger_id
            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(l_period_name_begin,'MON-YY') AND to_date(l_period_name_end,'MON-YY')
            AND GJH.status='P'
            AND GJH.je_source=GJS.je_source_name
            AND GJH.je_category=GJC.je_category_name
               ORDER BY GJH.je_header_id
        )
                LOOP
                --l_data:=Journal_Cur.je_header_id||Journal_Cur.set_of_books_id||Journal_Cur.je_batch_id||Journal_Cur.Period_Name--1.2-Replaced equivalent table columns as per R12 upgrade
                l_data:=Journal_Cur.je_header_id||Journal_Cur.ledger_id||Journal_Cur.je_batch_id||Journal_Cur.Period_Name
                ||Journal_Cur.Description||Journal_Cur.Posted_Date||Journal_Cur.Je_Source||Journal_Cur.Je_Category
                ||Journal_Cur.actual_flag||Journal_Cur.Currency_Code||Journal_Cur.status||Journal_Cur.date_created
                --||Journal_Cur.set_of_books_id||Journal_Cur.je_header_id||Journal_Cur.je_line_num--1.2-Replaced equivalent table columns as per R12 upgrade
                ||Journal_Cur.ledger_id||Journal_Cur.je_header_id||Journal_Cur.je_line_num
                ||Journal_Cur.segment1||Journal_Cur.status||Journal_Cur.gl_accounting_string
                ||Journal_Cur.description||Journal_Cur.accounted_dr||Journal_Cur.accounted_cr||chr(13);
                     UTL_FILE.PUT_LINE(lt_file,l_data);
                                 l_out_cnt := l_out_cnt + 1;
                END LOOP;
                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'Calling XPTR Program');
                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'Journal extract has been completed');
                write_log(p_debug_flag,l_out_cnt||' Total Records Written');
        END IF;
END Extract_Journal;

PROCEDURE Extract_COA(p_ret_code OUT NUMBER
             ,p_err_msg  OUT VARCHAR2
             ,p_directory VARCHAR2
             ,p_file_name VARCHAR2
             ,p_debug_flag VARCHAR2
             ,p_file_path  VARCHAR2)

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT OfficeDepot                                           |
-- +===========================================================================+
-- | Name             :  Extract_COA                                           |
-- | Description      : This procedure is used to extract the Chart of Account |
-- |                    and Descriptions                                       |                                                                               |
-- +===========================================================================+
AS
    l_data            VARCHAR2(4000);
    l_out_cnt               NUMBER;
    ln_buffer       BINARY_INTEGER  := 32767;
    lt_file         utl_file.file_type;
    lc_filename  VARCHAR2(4000);
    ln_req_id NUMBER;
BEGIN
   gc_file_path := p_file_path;
    write_log(p_debug_flag,'Extracting the Chart of Accounts Begins');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
        lc_filename:= ln_req_id||'.out';
        lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
        l_out_cnt := 0;

     FOR COA_Cur IN
            (SELECT     lpad(ffv.flex_value,15,0)  coa_account
                        ,rpad(nvl(ffvt.description,' '),50) coa_desc
                  FROM      fnd_flex_value_sets ffvs
                        ,fnd_flex_values     ffv
                        ,fnd_flex_values_tl  ffvt
                WHERE     ffvs.flex_value_set_name='OD_GL_GLOBAL_ACCOUNT'
                    AND ffvs.flex_value_set_id=ffv.flex_value_set_id
                    AND ffv.flex_value_id=ffvt.flex_value_id
                ORDER BY ffv.flex_value
        )
                LOOP
                    l_data:=COA_Cur.coa_account||COA_Cur.coa_desc||chr(13);
           UTL_FILE.PUT_LINE(lt_file,l_data);
                   l_out_cnt := l_out_cnt + 1;
                END LOOP;
                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'Calling XPTR Program');
                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'Chart of Accounts extract is completed');
                write_log(p_debug_flag,l_out_cnt||' Total Records Written');
END Extract_COA;

PROCEDURE Extract_Balances(p_ret_code OUT NUMBER
             ,p_err_msg  OUT VARCHAR2
         --V1.4    ,p_ledger_id NUMBER  -- V1.3
             ,p_directory VARCHAR2
             ,p_file_name VARCHAR2
             ,p_debug_flag VARCHAR2
             ,p_file_path  VARCHAR2
             ,p_period_name_begin VARCHAR2
             ,p_period_name_end VARCHAR2)
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  IT OfficeDepot                                           |
-- +===========================================================================+
-- | Name             :  Extract_Balances                                      |
-- | Description      : This procedure is used to extract the Account Balances |
-- |                    for the open period                                    |
-- |===========================================================================+
AS
    l_data            VARCHAR2(4000);
    l_period_name_begin    VARCHAR2(30);
        l_period_name_end    VARCHAR2(30);
        l_out_cnt               NUMBER;
       ln_buffer       BINARY_INTEGER  := 32767;
        lt_file         utl_file.file_type;
        lc_filename  VARCHAR2(4000);
        ln_req_id NUMBER;
        l_created     DATE;
   l_last_compiled  VARCHAR2(30);
   l_status VARCHAR2(20);
BEGIN
  select timestamp, status, created  INTO l_last_compiled, l_status, l_created from dba_objects
  where object_type = 'PACKAGE BODY'
  and object_name = 'XXOD_GL_IRS_QTRLY_EXTRACT_PKG'
  and owner = 'APPS';
  write_log(p_debug_flag,' ');
  write_log(p_debug_flag,'Package XXOD_GL_IRS_QTRLY_EXTRACT_PKG --->  created:'||l_created||'   last_DDL_time:'||l_last_compiled
      ||'   Status:'||l_status);
  write_log(p_debug_flag,' ');
   gc_file_path := p_file_path;
    write_log(p_debug_flag,'Extracting the Account Balances Begins');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
        lc_filename:= ln_req_id||'.out';
         lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
         l_period_name_begin:=p_period_name_begin;
         L_period_name_end:=p_period_name_end;
         write_log(p_period_name_begin,'Begin Period Name from Parameter');
         write_log(p_period_name_end,'End Period Name from Parameter');
         l_out_cnt := 0;

IF p_period_name_end IS NULL THEN
         BEGIN
        SELECT period_name
        INTO l_period_name_end
        FROM GL_PERIOD_STATUSES
        WHERE CLOSING_STATUS='O'
        AND APPLICATION_ID=101
      --V1.3, Commented  AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID')
      --  AND ledger_id = p_ledger_id -- V1.3, Added
        AND ledger_id=FND_PROFILE.value('GL_SET_OF_BKS_ID')
        AND EFFECTIVE_PERIOD_NUM =
            (SELECT MIN(EFFECTIVE_PERIOD_NUM)
              FROM GL_PERIOD_STATUSES
              WHERE CLOSING_STATUS='O'
              AND APPLICATION_ID=101 
              -- V1.3, Commented AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID'))
              AND ledger_id=FND_PROFILE.value('GL_SET_OF_BKS_ID')--V1.4
            --V1.4  AND ledger_id = p_ledger_id
            ); -- V1.3, Added

                l_period_name_begin:=TO_CHAR(ADD_MONTHS(TO_DATE(l_period_name_end,'MON-YY'),  -3), 'MON-YY');
              EXCEPTION
        WHEN OTHERS THEN
            l_period_name_begin:=NULL;
            l_period_name_end:=NULL;
            fnd_file.put_line(FND_FILE.LOG,'unable to fetch the minimum open period from GL ');
          END;

ELSE
 l_period_name_begin := P_period_name_begin;
 l_period_name_end   := P_period_name_end;
 l_out_cnt := 0;

END IF;

    IF l_period_name_end  IS NOT NULL  THEN
        FOR Balance_Cur IN
        	--(SELECT lpad(gb.set_of_books_id,15,0)  set_of_books_id,--1.2-Replaced equivalent table columns as per R12 upgrade
                (SELECT lpad(gb.ledger_id,15,0)  ledger_id,
                lpad(gb.code_combination_id,15,0)  cc_id,
                rpad(gb.currency_code,15)   currency_code,
                rpad(gb.period_name,15)    period_name,
                rpad(gb.actual_flag,1)   actual_flag,
                lpad(gb.period_year,10,0) period_year,
                Lpad(gb.period_num,10,0)  period_num,
                decode(gb.last_update_date,NULL,'          ',rpad(to_char(gb.last_update_date,'YYYY-MM-DD'),10))  last_update_date,
                rpad(nvl(cc.SEGMENT1,' '),6) segment1,
                --rpad(nvl(cc.SEGMENT1 || '.' || cc.SEGMENT2 || '.' || cc.SEGMENT3 || '.' || cc.SEGMENT4 || '.' || cc.SEGMENT5 || '.' || cc.SEGMENT6 || '.' || cc.SEGMENT7,' '),50) gl_accounting_string,
                rpad(nvl(cc.SEGMENT2 || '.' || cc.SEGMENT3 || '.' || cc.SEGMENT4 || '.' || cc.SEGMENT5 || '.' || cc.SEGMENT6 || '.' || cc.SEGMENT7,' '),50) gl_accounting_string,
                DECODE(sign(NVL(gb.period_net_dr,0)),1,'+'||TRIM(TO_CHAR(gb.period_net_dr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(gb.period_net_dr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(gb.period_net_dr,0),'0999999999999999.99'))) period_net_dr,
                DECODE(sign(NVL(gb.period_net_cr,0)),1,'+'||TRIM(TO_CHAR(gb.period_net_cr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(gb.period_net_cr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(gb.period_net_cr,0),'0999999999999999.99'))) period_net_cr,
                DECODE(sign(NVL(gb.begin_balance_dr,0)),1,'+'||TRIM(TO_CHAR(gb.begin_balance_dr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(gb.begin_balance_dr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(gb.begin_balance_dr,0),'0999999999999999.99'))) begin_balance_dr,
                DECODE(sign(NVL(gb.begin_balance_cr,0)),1,'+'||TRIM(TO_CHAR(gb.begin_balance_cr,'0999999999999999.99')),
                0,'+'||TRIM(TO_CHAR(NVL(gb.begin_balance_cr,0),'0999999999999999.99')),
                TRIM(TO_CHAR(NVL(gb.begin_balance_cr,0),'0999999999999999.99'))) begin_balance_cr
                FROM gl_balances gb, gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
           AND gb.period_name=p_period_name_end
        --V1.4   AND gb.ledger_id = p_ledger_id -- V1.3 
      ORDER BY cc_id
        )
                LOOP
                 -- l_data:=Balance_Cur.set_of_books_id||Balance_Cur.cc_id||Balance_Cur.currency_code--1.2-Replaced equivalent table columns as per R12 upgrade
                  l_data:=Balance_Cur.ledger_id||Balance_Cur.cc_id||Balance_Cur.currency_code
                  ||Balance_Cur.period_name||Balance_Cur.actual_flag||Balance_Cur.period_year
                  ||Balance_Cur.period_num||Balance_Cur.last_update_date
                  ||Balance_cur.segment1
                  ||Balance_Cur.gl_accounting_string
                  ||Balance_Cur.period_net_dr||Balance_Cur.period_net_cr
                  ||Balance_Cur.begin_balance_dr||Balance_Cur.begin_balance_cr||chr(13);
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                  l_out_cnt := l_out_cnt + 1;
                END LOOP;
                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'Calling XPTR Program');
                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'Balances extract is completed');
                write_log(p_debug_flag,l_out_cnt||' Total Records Written');
        END IF;
END Extract_Balances;
END XXOD_GL_IRS_QTRLY_EXTRACT_PKG;
/

create or replace PACKAGE BODY XXOD_GL_IRS_QTRLY_EXTRACT_PKG AS
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
-- |1.8      08-JUL-2019 Arun DSouza	LNS EBS Cloud Mainframe Code Retrofit  |
-- |                                                                		   |
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
        l_saved_company    gl_code_combinations.segment1%TYPE := '-1';
        l_timestamp     varchar2(30) :=  to_char(sysdate,'YYYY_MM_DD_HHMISS');

      l_company_ctr  NUMBER := 0;

       TYPE company_tab_type IS TABLE OF VARCHAR2(50) 
             INDEX BY BINARY_INTEGER; 

       all_company_tab company_tab_type;

       company_files_tab company_tab_type;
       
       l_company_file_missing BOOLEAN;
              
 
  cursor journal_cursor 
  is
          SELECT GJH.je_header_id  gl_je_hdr_id,
                GJL.je_line_num    gl_je_line_num,
                gcc.SEGMENT1  company,
                gcc.SEGMENT2  cost_center,                
                gcc.SEGMENT3  account,
                gcc.SEGMENT4  location,
                gcc.SEGMENT6  lob,
                upper(GJS.user_je_source_name) j_source,
                to_char(to_date(GJH.period_name,'MON-YY'),'YYYYMM')     perd_name,
                GJH.description jrnl_desc,
                to_char((NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)),'S0999999999999.99') gl_line_net_amt,                
                GJH.currency_code  gl_curr_code,
                decode(GJH.posted_date,NULL,'          ',rpad(to_char(GJH.posted_date,'YYYY-MM-DD'),10)) posted_date,
                lpad(' ',30) blnk_invoice_id,
                lpad(' ',10) blnk_vendor_id,
                lpad(' ',40) blnk_vendor_name,
                lpad(' ',10) blnk_invoice_date,
                lpad(' ',8)  blnk_voucher_id,
                lpad(' ',5)  blnk_ap_bu,
                lpad(' ',30)  blnk_voucher_desc,
                to_char(NVL(GJL.accounted_dr,0),'S0999999999999999.99') gl_accounted_dr,
                to_char(NVL(GJL.accounted_cr,0),'S0999999999999999.99') gl_accounted_cr,
--               gb.period_year perd_year,
--               lpad(gb.period_num,2,'0')  perd_num,                 
             lpad(GJH.je_header_id,15,0) je_header_id
            --,lpad(GJH.set_of_books_id,15,0) set_of_books_id--1.2-Replaced equivalent table columns as per R12 upgrade
            ,lpad(GJH.ledger_id,15,0) ledger_id
            ,lpad(GJH.je_batch_id,15,0) je_batch_id
                        ,rpad(to_char(to_date(GJH.period_name,'MON-YY'),'YYYYMM'),15)     period_name
            ,rpad(nvl(GJH.description,' '),50) description
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
            AND gcc.SEGMENT1
            in ('1000E','1001','1002','1003','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1055','1055P','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060')
--            AND ROWNUM < 3000
          ORDER BY 
                gcc.SEGMENT1, -- company
                to_char(to_date(gjh.period_name,'MON-YY'),'YYYY'), -- period_yyyy
                to_char(to_date(gjh.period_name,'MON-YY'),'MM'),   -- period_mm
                gjh.je_header_id,
                gjl.je_line_num,
                gcc.SEGMENT2, -- cost_center                
                gcc.SEGMENT4, -- location
                gcc.SEGMENT6, -- lob,
                gcc.SEGMENT3; -- account


--               ORDER BY GJH.je_header_id;
            
BEGIN
   gc_file_path := p_file_path;
    write_log(p_debug_flag,'Extracting the Journal Details');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
--        lc_filename:= ln_req_id||'.out';
--        lc_filename:= 'gl_jrnl_detail_irs_1001.txt';
--         lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
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

/*
014100*--- Output journal detail record.                                00016800
x014200 01  JRLD-RECORD.
x014300     05  JRLD-CO             PIC  X(005).
x014400     05  JRLD-FILLER-01      PIC  X(003).
x014500     05  JRLD-LOCATION       PIC  X(008).
x014600     05  JRLD-FILLER-02      PIC  X(003).
x014700     05  JRLD-CSTCTR         PIC  X(010).
x014800     05  JRLD-FILLER-03      PIC  X(003).
x014900     05  JRLD-LOB            PIC  X(010).
x015000     05  JRLD-FILLER-04      PIC  X(003).
x015100     05  JRLD-ACCT           PIC  X(010).
x015200     05  JRLD-FILLER-05      PIC  X(003).
x015300     05  JRLD-SRC            PIC  X(020).
x015400     05  JRLD-FILLER-06      PIC  X(003).
x015500     05  JRLD-PERIOD         PIC  X(006).
x015600     05  JRLD-FILLER-07      PIC  X(003).
x015700     05  JRLD-DESC           PIC  X(030).
x015800     05  JRLD-FILLER-08      PIC  X(003).
x015900     05  JRLD-JRNL-ID        PIC  X(010).
x016000     05  JRLD-FILLER-09      PIC  X(003).
x016100     05  JRLD-LINE           PIC  9(006).
x016200     05  JRLD-LINE-X   REDEFINES
x016300         JRLD-LINE           PIC  X(006).
x016400     05  JRLD-FILLER-10      PIC  X(003).
x016500     05  JRLD-AMT            PIC  -9(13).99.
x016600     05  JRLD-AMT-X       REDEFINES
x016700         JRLD-AMT            PIC  X(017).
x016800     05  JRLD-FILLER-11      PIC  X(002).
x016900     05  JRLD-CURRENCY       PIC  X(003).
x017000     05  JRLD-FILLER-12      PIC  X(003).
x017100     05  JRLD-JRNL-DT        PIC  X(010).
x017200     05  JRLD-FILLER-13      PIC  X(003).
x017300     05  JRLD-INVC-ID        PIC  X(030).
x017400     05  JRLD-FILLER-14      PIC  X(003).
x017500     05  JRLD-VENDOR-ID      PIC  X(010).
x017600     05  JRLD-FILLER-15      PIC  X(003).
x017700     05  JRLD-VENDOR-NAME1   PIC  X(040).
x017800     05  JRLD-FILLER-16      PIC  X(003).
x017900     05  JRLD-INVC-DT        PIC  X(010).
x018000     05  JRLD-FILLER-17      PIC  X(003).
x018100     05  JRLD-VOUCHER-ID     PIC  X(008).
x018200     05  JRLD-FILLER-18      PIC  X(003).
x018300     05  JRLD-AP-BU          PIC  X(005).
x018400     05  JRLD-FILLER-19      PIC  X(003).
x018500     05  JRLD-VCHR-DESC      PIC  X(030).
x018600     05  JRLD-FILLER-20      PIC  X(003).
x018700     05  JRLD-ACCOUNTED-DR   PIC  X(020).                         00008700
x018800     05  JRLD-ACCOUNTED-CR   PIC  X(020).                         00008700
018900     05  FILLER              PIC  X(058).
*/

    l_company_ctr := 1;

    IF l_period_name_end  IS NOT NULL  and l_period_name_begin IS NOT NULL THEN
    
        FOR Journal_Cur IN Journal_cursor
            LOOP
              IF (l_saved_company != Journal_Cur.company) then

               IF l_saved_company != '-1' THEN
                 UTL_FILE.fclose(lt_file);

               END IF;

               l_saved_company := Journal_Cur.company;

                company_files_tab(l_company_ctr) :=  l_saved_company;
                l_company_ctr := l_company_ctr + 1; 

                            
               lc_filename:= 'gl_jrnl_detail_irs_' || LTRIM(RTRIM(l_saved_company)) || '_' || l_timestamp || '.txt';
               lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
               write_log(p_debug_flag,'Writing to File :' || lc_filename);

               l_data:= 'COMP  | LOCATION | CSTCTR     | LOB        | ACCOUNT    | SRC                  | PERIOD | DESC                           | JOURNAL ID | LINE   | AMOUNT            |CUR | EFF DT     | INVOICE ID                     | VENDOR     | VENDOR NAME1                             | INVC DT    | VOUCHER  | AP CO | VOUCHER DESC                   |                                                                                 ' || chr(13);

--                    IF  l_out_cnt = 0 then
               UTL_FILE.PUT_LINE(lt_file,l_data);
--                    END IF; 

              END IF;

                --l_data:=Journal_Cur.je_header_id||Journal_Cur.set_of_books_id||Journal_Cur.je_batch_id||Journal_Cur.Period_Name--1.2-Replaced equivalent table columns as per R12 upgrade
                --||Journal_Cur.set_of_books_id||Journal_Cur.je_header_id||Journal_Cur.je_line_num--1.2-Replaced equivalent table columns as per R12 upgrade
 /*
                l_data:=Journal_Cur.je_header_id||Journal_Cur.ledger_id||Journal_Cur.je_batch_id||Journal_Cur.Period_Name
                ||Journal_Cur.Description||Journal_Cur.Posted_Date||Journal_Cur.Je_Source||Journal_Cur.Je_Category
                ||Journal_Cur.actual_flag||Journal_Cur.Currency_Code||Journal_Cur.status||Journal_Cur.date_created
                ||Journal_Cur.ledger_id||Journal_Cur.je_header_id||Journal_Cur.je_line_num
                ||Journal_Cur.segment1||Journal_Cur.status||Journal_Cur.gl_accounting_string
                ||Journal_Cur.description||Journal_Cur.accounted_dr||Journal_Cur.accounted_cr||chr(13);
*/ 
 
                l_data :=  rpad(journal_cur.company,5)               || ' | ' ||
                           rpad(journal_cur.location,8)              || ' | ' ||
                           rpad(journal_cur.cost_center,10)          || ' | ' ||  
                           rpad(journal_cur.lob,10)                  || ' | ' || 
                           rpad(journal_cur.account,10)              || ' | ' ||  
                           rpad(journal_cur.j_source,20)             || ' | ' || 
                           rpad(journal_cur.perd_name,6)             || ' | ' || 
                           rpad(journal_cur.jrnl_desc,30)            || ' | ' || 
                           lpad(journal_cur.gl_je_hdr_id,10,'0')     || ' | ' || 
                           lpad(journal_cur.gl_je_line_num,6,'0')    || ' | ' ||  
                           journal_cur.gl_line_net_amt               || ' |' ||  
                           journal_cur.gl_curr_code                  || ' | ' ||  
                           journal_cur.posted_date                   || ' | ' ||  
                           journal_cur.blnk_invoice_id               || ' | ' ||  
                           journal_cur.blnk_vendor_id                || ' | ' || 
                           journal_cur.blnk_vendor_name              || ' | ' ||  
                           journal_cur.blnk_invoice_date             || ' | ' ||  
                           journal_cur.blnk_voucher_id               || ' | ' ||  
                           journal_cur.blnk_ap_bu                    || ' | ' ||  
                           journal_cur.blnk_voucher_desc             || ' | ' ||  
                           journal_cur.gl_accounted_dr               ||  
                           journal_cur.gl_accounted_cr               ||  
                           lpad(' ',58)                              ||chr(13);                      
                           


                 UTL_FILE.PUT_LINE(lt_file,l_data);
 
                 l_out_cnt := l_out_cnt + 1;
 
             END LOOP;
             
               IF l_saved_company != '-1' THEN
                UTL_FILE.fclose(lt_file);
               END IF;

/*     
               all_company_tab := company_tab_type('1000E','1001','1002','1003','1005',
                                                   '1012','1014','1015','1015E','1016',
                                                   '1017','1020','1021','1032','1039',
                                                   '1041','1043','1044','1049','1051',
                                                   '1052','1053','1055','1055P','1056',
                                                   '1057','1058','1059','1060','5010',
                                                   '5020','5030','5040','5050','5060');
*/

      all_company_tab(1)   :=   '1000E';
      all_company_tab(2)   :=   '1001';
      all_company_tab(3)   :=   '1002';
      all_company_tab(4)   :=   '1003';
      all_company_tab(5)   :=   '1005';
      all_company_tab(6)   :=   '1012';
      all_company_tab(7)   :=   '1014';
      all_company_tab(8)   :=   '1015';
      all_company_tab(9)   :=   '1015E';
      all_company_tab(10)   :=   '1016';
      all_company_tab(11)   :=   '1017';
      all_company_tab(12)   :=   '1020';
      all_company_tab(13)   :=   '1021';
      all_company_tab(14)   :=   '1032';
      all_company_tab(15)   :=   '1039';
      all_company_tab(16)   :=   '1041';
      all_company_tab(17)   :=   '1043';
      all_company_tab(18)   :=   '1044';
      all_company_tab(19)   :=   '1049';
      all_company_tab(20)   :=   '1051';
      all_company_tab(21)   :=   '1052';
      all_company_tab(22)   :=   '1053';
      all_company_tab(23)   :=   '1055';
      all_company_tab(24)   :=   '1055P';
      all_company_tab(25)   :=   '1056';
      all_company_tab(26)   :=   '1057';
      all_company_tab(27)   :=   '1058';
      all_company_tab(28)   :=   '1059';
      all_company_tab(29)   :=   '1060';
      all_company_tab(30)   :=   '5010';
      all_company_tab(31)   :=   '5020';
      all_company_tab(32)   :=   '5030';
      all_company_tab(33)   :=   '5040';
      all_company_tab(34)   :=   '5050';
      all_company_tab(35)   :=   '5060';


               FOR i in all_company_tab.FIRST..all_company_tab.LAST LOOP

                 l_company_file_missing := TRUE;

                  FOR j in company_files_tab.FIRST..company_files_tab.LAST LOOP
                     IF company_files_tab(j) = all_company_tab(i) THEN
                       l_company_file_missing := FALSE;
                       EXIT;
                     END IF;
                  END LOOP;

                  IF l_company_file_missing 
                    THEN
                       lc_filename:= 'gl_jrnl_detail_irs_' || LTRIM(RTRIM(all_company_tab(i))) || '_' || l_timestamp || '.txt';
                       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
                       write_log(p_debug_flag,'Writing to Missing Array File :' || lc_filename);
                       l_data:= 'COMP  | LOCATION | CSTCTR     | LOB        | ACCOUNT    | SRC                  | PERIOD | DESC                           | JOURNAL ID | LINE   | AMOUNT            |CUR | EFF DT     | INVOICE ID                     | VENDOR     | VENDOR NAME1                             | INVC DT    | VOUCHER  | AP CO | VOUCHER DESC                   |                                                                                 ' || chr(13);
                       UTL_FILE.PUT_LINE(lt_file,l_data);
                       UTL_FILE.fclose(lt_file);
                  END IF;
               END LOOP;

      
                write_log(p_debug_flag,'Not Calling XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'Journal extract has been completed');
                write_log(p_debug_flag,l_out_cnt||' Total Records Written');
        END IF;  -- l_period_name beg_end  IS NOT NULL
        
        
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
    l_timestamp     varchar2(30) :=  to_char(sysdate,'YYYY_MM_DD_HHMISS');

--005100 01  COA-RECORD.
--005200     05  COA-ACCOUNT         PIC  X(008).
--005300     05  COA-FILLER-01       PIC  X(003).
--005400     05  COA-DESCR           PIC  X(050).
--005500     05  COA-FILLER-02       PIC  X(003).

BEGIN
   gc_file_path := p_file_path;
    write_log(p_debug_flag,'Extracting the Chart of Accounts Begins');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
--        lc_filename:= ln_req_id||'.out';
          lc_filename:= 'gl_coa_irs_' || l_timestamp || '.txt';

        lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
        l_out_cnt := 0;

          UTL_FILE.PUT_LINE(lt_file,'ACCOUNT  | DESCRIPTION                                        |      ' ||chr(13));

        FOR COA_Cur IN
            (SELECT   
               -- lpad(ffv.flex_value,15,0)  coa_account,rpad(nvl(ffvt.description,' '),50) coa_desc
                rpad(ffv.flex_value,9) || '| ' || rpad(nvl(ffvt.description,' '),51) || '|      ' coa_desc
                  FROM      fnd_flex_value_sets ffvs
                        ,fnd_flex_values     ffv
                        ,fnd_flex_values_tl  ffvt
                WHERE     ffvs.flex_value_set_name='OD_GL_GLOBAL_ACCOUNT'
                    AND ffvs.flex_value_set_id=ffv.flex_value_set_id
                    AND ffv.flex_value_id=ffvt.flex_value_id
                ORDER BY ffv.flex_value
             )
                LOOP
                    l_data:=COA_Cur.coa_desc ||chr(13);
                     UTL_FILE.PUT_LINE(lt_file,l_data);
                   l_out_cnt := l_out_cnt + 1;
                END LOOP;

                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'NOT Calling XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
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
    v_report_count VARCHAR2(50);
    v_all_accts_net   number;
    v_all_accts_net_fmt VARCHAR2(50);
    l_account_from  varchar2(8);
    l_account_to    varchar2(8); 
    l_country       varchar2(30);
    l_timestamp     varchar2(30) :=  to_char(sysdate,'YYYY_MM_DD_HHMISS');
   
   
   cursor canada_cur (cp_period_name_end in varchar2)
   is
     SELECT lpad(gb.ledger_id,15,0)  ledger_id,
                cc.SEGMENT1  company,
                cc.SEGMENT2  cost_center,                
                cc.SEGMENT3  account,
                cc.SEGMENT4  location,
                cc.SEGMENT6  lob,
                gb.period_year perd_year,
                lpad(gb.period_num,2,'0')  perd_num,                 
       --         (WS-DR-AMT-BEG - WS-CR-AMT-BEG)        
       --          + (WS-DR-AMT-PER - WS-CR-AMT-PER)       
                  to_char(
                    ((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     ),'S0999999999999.99') balance_amount,
                gb.currency_code   curr_code,
                lpad(gb.code_combination_id,15,0)  cc_id,
                rpad(gb.currency_code,15)   currency_code,
                rpad(gb.period_name,15)    period_name,
                rpad(gb.actual_flag,1)   actual_flag,
                lpad(gb.period_year,10,0) period_year,
                Lpad(gb.period_num,10,0)  period_num,
                to_char(NVL(gb.period_net_dr,0)   ,'S0999999999999999.99') perd_net_dr,
                to_char(NVL(gb.period_net_cr,0)   ,'S0999999999999999.99') perd_net_cr,
                to_char(NVL(gb.begin_balance_dr,0),'S0999999999999999.99') begn_bal_dr,
                to_char(NVL(gb.begin_balance_cr,0),'S0999999999999999.99') begn_bal_cr,
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
                FROM gl_balances gb, 
                     gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
--           AND gb.period_name=p_period_name_end
             AND gb.period_name = cp_period_name_end  -- 'JAN-16' 
             AND cc.SEGMENT1  in ('1003','1055','1055P')
             AND gb.currency_code =  'CAD'
             AND gb.actual_flag   =  'A'
        --V1.4   AND gb.ledger_id = p_ledger_id -- V1.3
          ORDER BY gb.period_year,gb.period_num,
                cc.SEGMENT1, -- company
                cc.SEGMENT2, -- cost_center                
                cc.SEGMENT4, -- location
                cc.SEGMENT6, -- lob,
                cc.SEGMENT3; -- account
         
--      ORDER BY cc_id;    


   cursor  usa_cur (cp_period_name_end in varchar2)
   is
     SELECT lpad(gb.ledger_id,15,0)  ledger_id,
                cc.SEGMENT1  company,
                cc.SEGMENT2  cost_center,                
                cc.SEGMENT3  account,
                cc.SEGMENT4  location,
                cc.SEGMENT6  lob,
                gb.period_year perd_year,
                lpad(gb.period_num,2,'0')  perd_num,                 
       --         (WS-DR-AMT-BEG - WS-CR-AMT-BEG)        
       --          + (WS-DR-AMT-PER - WS-CR-AMT-PER)       
                  to_char(
                    ((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     ),'S0999999999999.99') balance_amount,
                gb.currency_code   curr_code,
                lpad(gb.code_combination_id,15,0)  cc_id,
                rpad(gb.currency_code,15)   currency_code,
                rpad(gb.period_name,15)    period_name,
                rpad(gb.actual_flag,1)   actual_flag,
                lpad(gb.period_year,10,0) period_year,
                Lpad(gb.period_num,10,0)  period_num,
                to_char(NVL(gb.period_net_dr,0)   ,'S0999999999999999.99') perd_net_dr,
                to_char(NVL(gb.period_net_cr,0)   ,'S0999999999999999.99') perd_net_cr,
                to_char(NVL(gb.begin_balance_dr,0),'S0999999999999999.99') begn_bal_dr,
                to_char(NVL(gb.begin_balance_cr,0),'S0999999999999999.99') begn_bal_cr,
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
--           AND gb.period_name=p_period_name_end
             AND gb.period_name = cp_period_name_end  -- 'JAN-16' 
--             AND cc.SEGMENT1  NOT IN ('1003','1055','1055P')            
             AND cc.SEGMENT1
            in ('1000E','1001','1002','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060')             
             AND gb.currency_code =  'USD'
             AND gb.actual_flag   =  'A'
        --V1.4   AND gb.ledger_id = p_ledger_id -- V1.3
          ORDER BY gb.period_year,gb.period_num,
                cc.SEGMENT1, -- company
                cc.SEGMENT2, -- cost_center                
                cc.SEGMENT4, -- location
                cc.SEGMENT6, -- lob,
                cc.SEGMENT3; -- account

--      ORDER BY cc_id;    


 cursor usa_report_cur(cp_period_name_end in varchar2,
                       cp_account_from in varchar2,
                       cp_account_to in varchar2)
  is
      SELECT   'COMPANY ', cc.SEGMENT1  company,'NET =',
--                gb.period_year perd_year,
--                lpad(gb.period_num,2,'0')  perd_num,                 
                 sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  sum_net_amount,
                 count(*) total_record_count,
                to_char(
                    sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )
                     ,'999,999,999,999.99S') formatted_sum_net_amount
                FROM gl_balances gb, 
                     gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
             AND gb.period_name =   cp_period_name_end  -- 'JAN-16' 
             AND cc.SEGMENT1
             IN ('1000E','1001','1002','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060') 
             and cc.segment3 between  cp_account_from and  cp_account_to -- '10000000' AND '39999999'
             AND gb.currency_code =  'USD'
             AND gb.actual_flag   =  'A'
          group by 
          --gb.period_year,gb.period_num,
                cc.SEGMENT1
          having                  sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  != 0
        ORDER BY cc.segment1; -- company
 

 cursor usa_rep_count(cp_period_name_end in varchar2)
  is
     SELECT      to_char(count(*),'999,999,999') total_record_count,
                 sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  sum_net_amount,
                to_char(
                    sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )
                     ,'099,999,999.99S') formatted_sum_net_amount
                FROM gl_balances gb, 
                     gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
             AND gb.period_name =  cp_period_name_end  -- 'JAN-16' 
             AND cc.SEGMENT1
            in ('1000E','1001','1002','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060') 
             and cc.segment3 between '10000000' AND '99999999'
             AND gb.currency_code =  'USD'
             AND gb.actual_flag   =  'A';
 
------- Canada --------------

cursor can_report_cur(cp_period_name_end in varchar2,
                       cp_account_from in varchar2,
                       cp_account_to in varchar2)
  is
      SELECT   'COMPANY ', cc.SEGMENT1  company,'NET =',
--                gb.period_year perd_year,
--                lpad(gb.period_num,2,'0')  perd_num,                 
                 sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  sum_net_amount,
                 count(*) total_record_count,
                to_char(
                    sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )
                     ,'999,999,999,999.99S') formatted_sum_net_amount
                FROM gl_balances gb, 
                     gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
             AND gb.period_name =   cp_period_name_end  -- 'JAN-16' 
             AND cc.SEGMENT1  in ('1003','1055','1055P')
             and cc.segment3 between  cp_account_from and  cp_account_to -- '10000000' AND '39999999'
             AND gb.currency_code =  'CAD'
             AND gb.actual_flag   =  'A'
          group by 
          --gb.period_year,gb.period_num,
                cc.SEGMENT1
          having                  sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  != 0
        ORDER BY cc.segment1; -- company

 

 cursor can_rep_count(cp_period_name_end in varchar2)
  is
     SELECT      to_char(count(*),'999,999,999') total_record_count,
                 sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )  sum_net_amount,
                to_char(
                    sum((NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0))
                      +
                    (NVL(gb.period_net_dr,0) - NVL(gb.period_net_cr,0))
                     )
                     ,'099,999,999.99S') formatted_sum_net_amount
                FROM gl_balances gb, 
                     gl_code_combinations cc
         WHERE cc.code_combination_id=gb.code_combination_id
             AND gb.period_name =  cp_period_name_end  -- 'JAN-16' 
             AND cc.SEGMENT1  in ('1003','1055','1055P')
             and cc.segment3 between '10000000' AND '99999999'
             AND gb.currency_code =  'CAD'
             AND gb.actual_flag   =  'A';
 
-------------------------------------------------------------- 
----------- Journal Report Cursors below ---------------------
--------------------------------------------------------------

    cursor jrnl_usa_rep_cur(cp_period_name_begin in varchar2,
                            cp_period_name_end in varchar2,
                            cp_account_from in varchar2,
                            cp_account_to in varchar2)
    is
      SELECT    gcc.SEGMENT1  company,
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )  sum_net_amount,
                 count(*) total_record_count,
                to_char(
                sum(                 
                      NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                   )                     
                     ,'999,999,999,999.99S') formatted_sum_net_amount
        FROM
             gl_je_headers GJH
            ,gl_je_lines GJL
            ,gl_code_combinations GCC
            ,gl_je_sources  GJS
            ,gl_je_categories GJC
        WHERE
                GJH.je_header_id=GJL.je_header_id
            AND GJL.code_combination_id=GCC.code_combination_id
--            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(l_period_name_begin,'MON-YY') AND to_date(l_period_name_end,'MON-YY')
--            AND gjh.period_name =   cp_period_name_end  -- 'JAN-16' 
            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(cp_period_name_begin,'MON-YY') AND to_date(cp_period_name_end,'MON-YY')
            AND gcc.segment3 between  cp_account_from and  cp_account_to -- '10000000' AND '39999999'
            AND GJH.status  =  'P'
            AND GJH.je_source=GJS.je_source_name
            AND GJH.je_category=GJC.je_category_name
--          AND gcc.SEGMENT1 NOT in ('1003','1055','1055P')
            AND gcc.SEGMENT1
            in ('1000E','1001','1002','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060')
group by  gcc.SEGMENT1
order by gcc.SEGMENT1;

 cursor jrnl_usa_rep_count (cp_period_name_begin varchar2,cp_period_name_end varchar2,
                           cp_account_from varchar2,cp_account_to varchar2)
  is
     SELECT      to_char(count(*),'999,999,999') total_record_count,
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )   sum_net_amount,
                to_char(
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )                     
                     ,'099,999,999.99S') formatted_sum_net_amount
        FROM
             gl_je_headers GJH
            ,gl_je_lines GJL
            ,gl_code_combinations GCC
            ,gl_je_sources  GJS
            ,gl_je_categories GJC
        WHERE
                GJH.je_header_id=GJL.je_header_id
            AND GJL.code_combination_id=GCC.code_combination_id
            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(cp_period_name_begin,'MON-YY') AND to_date(cp_period_name_end,'MON-YY')
            AND gcc.segment3 between  cp_account_from and  cp_account_to -- '10000000' AND '39999999'
--            AND GJH.period_name = cp_period_name_end
            AND GJH.status  =  'P'
            AND gjh.currency_code =  'USD'
            AND GJH.je_source=GJS.je_source_name
            AND GJH.je_category=GJC.je_category_name
--          AND gcc.SEGMENT1 NOT in ('1003','1055','1055P')
            AND gcc.SEGMENT1
            in ('1000E','1001','1002','1005',
                '1012','1014','1015','1015E','1016',
                '1017','1020','1021','1032','1039',
                '1041','1043','1044','1049','1051',
                '1052','1053','1056',
                '1057','1058','1059','1060','5010',
                '5020','5030','5040','5050','5060');




/*

  cursor jrnl_can_rep_cur(cp_period_name_end in varchar2,
                       cp_account_from in varchar2,
                       cp_account_to in varchar2)
    is
      SELECT    gcc.SEGMENT1  company,
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )  sum_net_amount,
                 count(*) total_record_count,
                to_char(
                sum(                 
                      NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                   )                     
                     ,'999,999,999,999.99S') formatted_sum_net_amount
        FROM
             gl_je_headers GJH
            ,gl_je_lines GJL
            ,gl_code_combinations GCC
            ,gl_je_sources  GJS
            ,gl_je_categories GJC
        WHERE
                GJH.je_header_id=GJL.je_header_id
            AND GJL.code_combination_id=GCC.code_combination_id
--            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(l_period_name_begin,'MON-YY') AND to_date(l_period_name_end,'MON-YY')
            AND gjh.period_name =   cp_period_name_end  -- 'JAN-16' 
            AND gcc.segment3 between  cp_account_from and  cp_account_to -- '10000000' AND '39999999'
            AND GJH.status  =  'P'
            AND GJH.je_source=GJS.je_source_name
            AND GJH.je_category=GJC.je_category_name
            AND gcc.SEGMENT1  in ('1003','1055','1055P')
            AND gjh.currency_code =  'CAD'
group by  gcc.SEGMENT1
order by gcc.SEGMENT1;


 cursor jrnl_can_rep_count(cp_period_name_end in varchar2)
  is
     SELECT      to_char(count(*),'999,999,999') total_record_count,
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )   sum_net_amount,
                to_char(
                 sum(                 
                       NVL(GJL.accounted_dr,0) - NVL(GJL.accounted_cr,0)                    
                     )                     
                     ,'099,999,999.99S') formatted_sum_net_amount
        FROM
             gl_je_headers GJH
            ,gl_je_lines GJL
            ,gl_code_combinations GCC
            ,gl_je_sources  GJS
            ,gl_je_categories GJC
        WHERE
                GJH.je_header_id=GJL.je_header_id
            AND GJL.code_combination_id=GCC.code_combination_id
--            AND to_date(GJH.period_name,'MON-YY') BETWEEN to_date(l_period_name_begin,'MON-YY') AND to_date(l_period_name_end,'MON-YY')
            AND GJH.period_name = cp_period_name_end
            AND GJH.status  =  'P'
            AND GJH.je_source=GJS.je_source_name
            AND GJH.je_category=GJC.je_category_name
            AND gcc.SEGMENT1  in ('1003','1055','1055P')
            AND gjh.currency_code =  'CAD';

*/

-- arun3
   
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

--        lc_filename:= ln_req_id||'.out';

--         lc_filename:= 'gl_balances_irs_can.txt';
--         lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
 
         l_period_name_begin:=p_period_name_begin;
         L_period_name_end:=p_period_name_end;
         write_log(p_debug_flag,p_period_name_begin || ':Begin Period Name from Parameter');
         write_log(p_debug_flag,p_period_name_end || ':End Period Name from Parameter');
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

/*  Mainframe Record Structure
014100 01  ACCTB-RECORD.
x014200     05  ACCTB-CO            PIC  X(005).
x014300     05  ACCTB-FILLER-01     PIC  X(003).
x014400     05  ACCTB-LOCATION      PIC  X(008).
x014500     05  ACCTB-FILLER-02     PIC  X(003).
x014600     05  ACCTB-CSTCTR        PIC  X(010).
x014700     05  ACCTB-FILLER-03     PIC  X(003).
x014800     05  ACCTB-LOB           PIC  X(010).
x014900     05  ACCTB-FILLER-04     PIC  X(003).
x015000     05  ACCTB-ACCT          PIC  X(010).
x015100     05  ACCTB-FILLER-05     PIC  X(003).
x015200     05  ACCTB-YEAR          PIC  9(004).
x015300     05  ACCTB-FILLER-06     PIC  X(003).
x015400     05  ACCTB-PER           PIC  Z99.
x015500     05  ACCTB-PER-X REDEFINES ACCTB-PER PIC X(03).
x015600     05  ACCTB-FILLER-07     PIC  X(003).
x015700     05  ACCTB-ACCT-BAL      PIC  -9(13).99.
x015800     05  ACCTB-ACCT-BAL-X  redefines  ACCTB-ACCT-BAL
x015900                             PIC  X(15).
x016000     05  ACCTB-FILLER-08     PIC  X(003).
x016100     05  ACCTB-CURRENCY-CD   PIC  X(003).
x016200     05  ACCTB-FILLER-09     PIC  X(003).
016200     05  ACCTB-PER-DR-AMT    PIC  X(020).
016200     05  ACCTB-PER-CR-AMT    PIC  X(020).
016200     05  ACCTB-BEG-DR-AMT    PIC  X(020).
016200     05  ACCTB-BEG-CR-AMT    PIC  X(020).
016300     05  FILLER              PIC  X(032).

*/

-- l_data:=Balance_Cur.set_of_books_id||Balance_Cur.cc_id||Balance_Cur.currency_code--1.2-Replaced equivalent table columns as per R12 upgrade

/*   Old EBS to Mainframe record layout
                  l_data:=Balance_Cur.ledger_id||Balance_Cur.cc_id||Balance_Cur.currency_code
                  ||Balance_Cur.period_name||Balance_Cur.actual_flag||Balance_Cur.period_year
                  ||Balance_Cur.period_num||Balance_Cur.last_update_date
                  ||Balance_cur.segment1
                  ||Balance_Cur.gl_accounting_string
                  ||Balance_Cur.period_net_dr||Balance_Cur.period_net_cr
                  ||Balance_Cur.begin_balance_dr||Balance_Cur.begin_balance_cr||chr(13);
*/


    write_log(p_debug_flag,'Derived L_Period_Name_end value :' || l_period_name_end);

    IF l_period_name_end  IS NOT NULL  THEN

    write_log(p_debug_flag,'------------------------------------------------------');
    write_log(p_debug_flag,'-------Extracting CANADA COMPANY BALANCES-------------');
    write_log(p_debug_flag,'------------------------------------------------------');

       lc_filename:= 'gl_balances_irs_can_' || l_timestamp || '.txt';
       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

        l_data := 'COMP  | LOCATION | CSTCTR     | LOB        | ACCOUNT    |      | PER | AMOUNT            | CUR |                                             ' || chr(13);
        UTL_FILE.PUT_LINE(lt_file,l_data);

        FOR Balance_Cur IN canada_cur(p_period_name_end)
                LOOP

                 l_data := rpad(balance_cur.company,5)           || ' | ' ||
                           rpad(balance_cur.location,8)          || ' | ' ||
                           rpad(balance_cur.cost_center,10)      || ' | ' ||
                           rpad(balance_cur.lob,10)              || ' | ' ||
                           rpad(balance_cur.account,10)          || ' | ' ||
                           balance_cur.perd_year                 || ' | ' ||
                           lpad(balance_cur.perd_num,3)          || ' | ' ||
                           lpad(balance_cur.balance_amount,17)   || ' | ' ||
                           balance_cur.curr_code                 || ' | ' ||                         
                           balance_cur.perd_net_dr               ||                                                                
                           balance_cur.perd_net_cr               ||                                                                
                           balance_cur.begn_bal_dr               ||                                                                
                           balance_cur.begn_bal_cr               || chr(13);                                                                              


                  UTL_FILE.PUT_LINE(lt_file,l_data);
                  l_out_cnt := l_out_cnt + 1;
                END LOOP;
                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'NOT Calling Canada XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'Canada Balances extract is completed');
                write_log(p_debug_flag,l_out_cnt||' Total Canada Records Written');


    write_log(p_debug_flag,'------------------------------------------------------');
    write_log(p_debug_flag,'----------Extracting USA COMPANY BALANCES-------------');
    write_log(p_debug_flag,'------------------------------------------------------');

       lc_filename:= 'gl_balances_irs_usa_' || l_timestamp || '.txt';
       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

        l_data := 'COMP  | LOCATION | CSTCTR     | LOB        | ACCOUNT    |      | PER | AMOUNT            | CUR |                                             ' || chr(13);
        UTL_FILE.PUT_LINE(lt_file,l_data);
        
        l_out_cnt := 0;

        FOR Balance_Cur IN usa_cur(p_period_name_end)
                LOOP


                 l_data := rpad(balance_cur.company,5)           || ' | ' ||
                           rpad(balance_cur.location,8)          || ' | ' ||
                           rpad(balance_cur.cost_center,10)      || ' | ' ||
                           rpad(balance_cur.lob,10)              || ' | ' ||
                           rpad(balance_cur.account,10)          || ' | ' ||
                           balance_cur.perd_year                 || ' | ' ||
                           lpad(balance_cur.perd_num,3)          || ' | ' ||
                           lpad(balance_cur.balance_amount,17)   || ' | ' ||
                           balance_cur.curr_code                 || ' | ' ||                         
                           balance_cur.perd_net_dr               ||                                                                
                           balance_cur.perd_net_cr               ||                                                                
                           balance_cur.begn_bal_dr               ||                                                                
                           balance_cur.begn_bal_cr               || chr(13);                                                                              


                  UTL_FILE.PUT_LINE(lt_file,l_data);
                  l_out_cnt := l_out_cnt + 1;
                END LOOP;
                UTL_FILE.fclose(lt_file);
                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
                write_log(p_debug_flag,'USA Balances extract is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total USA Records Written');

        END IF; -- Period end name not null 

    write_log(p_debug_flag,'------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating USA Balance Report-------------');
    write_log(p_debug_flag,'------------------------------------------------------');

       lc_filename:= 'gl_irs_reports_' || l_timestamp || '.txt';
       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

       l_country := 'USA';
       
       l_data := '  EBSCLOUD     IRS ACCOUNT BALANCES BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '   CURRENCY     : USD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '10000000';
       l_account_to   := '39999999';
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                            
       l_out_cnt := 0;

        FOR usa_rep_rec IN usa_report_cur(p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(usa_rep_rec.company,8,' ') || ' NET =      ' ||  usa_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

                 v_report_count        := '0';
                 v_all_accts_net       :=  0;
                 v_all_accts_net_fmt   := '0.00';

                 OPEN usa_rep_count(p_period_name_end);   
                    FETCH usa_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE usa_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                
--                UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag,l_country || ' Balances Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total ' || l_country || ' Records Written');
 

    write_log(p_debug_flag,'------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating CANADA Balance Report-------------');
    write_log(p_debug_flag,'------------------------------------------------------');

       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '  EBSCLOUD     IRS ACCOUNT BALANCES BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_country := 'CANADA';

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '   CURRENCY     : CAD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '10000000';
       l_account_to   := '39999999';
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                            
       l_out_cnt := 0;

        FOR can_rep_rec IN can_report_cur(p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(can_rep_rec.company,8,' ') || ' NET =      ' ||  can_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

                 v_report_count        := '0';
                 v_all_accts_net       :=  0;
                 v_all_accts_net_fmt   := '0.00';

                 OPEN can_rep_count(p_period_name_end);   
                    FETCH can_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE can_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                
--                UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag,'Canada Balances Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total Canada Records Written');


    write_log(p_debug_flag,'----------------------------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating USA Balance Report Expenses 40000 and Above -------------');
    write_log(p_debug_flag,'----------------------------------------------------------------------------');

    UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     
    UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     


-- x      lc_filename:= 'gl_irs_reports.txt';
--       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

       l_country := 'USA';
       
       l_data := '  EBSCLOUD     IRS ACCOUNT BALANCES BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '   CURRENCY     : USD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '40000000';
       l_account_to   := '99999999';
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                            
       l_out_cnt := 0;

        FOR usa_rep_rec IN usa_report_cur(p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(usa_rep_rec.company,8,' ') || ' NET =      ' ||  usa_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

                 v_report_count        := '0';
                 v_all_accts_net       :=  0;
                 v_all_accts_net_fmt   := '0.00';

                 OPEN usa_rep_count(p_period_name_end);   
                    FETCH usa_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE usa_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                
--                UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag,l_country || ' Balances Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total ' || l_country || ' Records Written');
 

    write_log(p_debug_flag,'-----------------------------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating CANADA Balance Expenses Report 40000 onwards -------------');
    write_log(p_debug_flag,'-----------------------------------------------------------------------------');

       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

        l_data := '  EBSCLOUD     IRS ACCOUNT BALANCES BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_country := 'CANADA';

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '   CURRENCY     : CAD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '40000000';
       l_account_to   := '99999999';
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                            
       l_out_cnt := 0;

        FOR can_rep_rec IN can_report_cur(p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(can_rep_rec.company,8,' ') || ' NET =      ' ||  can_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

                 v_report_count        := '0';
                 v_all_accts_net       :=  0;
                 v_all_accts_net_fmt   := '0.00';

                 OPEN can_rep_count(p_period_name_end);   
                    FETCH can_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE can_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                
--                UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag, l_country || ' Balances Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total ' || l_country || ' Records Written');


-- arun4

    write_log(p_debug_flag,'------------------------------------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating Journal US Detail Balancing Report 10000 thru 399999--------------');
    write_log(p_debug_flag,'-------------------------------------------------------------------------------------');

       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

--       lc_filename:= 'gl_irs_reports_' || l_timestamp || '.txt';
--       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

    write_log(p_debug_flag,'----1');
    
       l_country := 'USA';
       
       l_data := '  EBSCLOUD     IRS JOURNAL DETAIL BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   DATE OF REPORT: ' || TO_CHAR(SYSDATE,'YYYY/MM/DD'); --2019/05/31 
--       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

    write_log(p_debug_flag,'----2');

       l_data := '   CURRENCY     : USD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '10000000';
       l_account_to   := '39999999';
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

    write_log(p_debug_flag,'----3');

                                                            
       l_out_cnt := 0;

        FOR usa_jrnl_rep_rec IN jrnl_usa_rep_cur(p_period_name_begin,p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(usa_jrnl_rep_rec.company,8,' ') || ' NET =      ' ||  usa_jrnl_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

    write_log(p_debug_flag,'----4');

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

--                 v_report_count        := '0';
--                 v_all_accts_net       :=  0;
--                 v_all_accts_net_fmt   := '0.00';

    write_log(p_debug_flag,'----5');

                 OPEN jrnl_usa_rep_count(p_period_name_begin,p_period_name_end,l_account_from,l_account_to); 
                    FETCH jrnl_usa_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE jrnl_usa_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
    write_log(p_debug_flag,'----6');
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                
--                UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag,l_country || ' Journal Detail Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total ' || l_country || ' Records Written');
 --arun5
 
    write_log(p_debug_flag,'------------------------------------------------------------------------------------');
    write_log(p_debug_flag,'----------Creating Journal US Detail Balancing Report 40000 thru 99999--------------');
    write_log(p_debug_flag,'-------------------------------------------------------------------------------------');

       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

--       lc_filename:= 'gl_irs_reports_' || l_timestamp || '.txt';
--       lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);

    write_log(p_debug_flag,'----7');


       l_country := 'USA';
       
       l_data := '  EBSCLOUD     IRS JOURNAL DETAIL BALANCING REPORT' || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);

       l_data := '  DATE OF REPORT:' || TO_CHAR(SYSDATE,'YYYY/MM/DD') || '  TIME: ' || TO_CHAR(SYSDATE,'HH:MI:SS') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                     

       l_data := '   DATE OF REPORT: ' || TO_CHAR(SYSDATE,'YYYY/MM/DD'); --2019/05/31 
--       l_data := '   PERIOD= ' || TO_CHAR(TO_DATE(p_period_name_end,'MON-YY'),'YYYYMM') || chr(13);
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

       l_data := '   CURRENCY     : USD' || chr(13);                                                                                                               
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13)); 
       
       l_account_from := '40000000';
       l_account_to   := '99999999';
                                 
    write_log(p_debug_flag,'----8');
                                                                                                                                     
       l_data := '   ACCOUNT RANGE: ' || l_account_from || ' THRU ' || l_account_to || chr(13);                                                                                           
       UTL_FILE.PUT_LINE(lt_file,l_data);
       UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                                                            
       l_out_cnt := 0;

        FOR usa_jrnl_rep_rec IN jrnl_usa_rep_cur(p_period_name_begin,p_period_name_end,l_account_from,l_account_to)
           LOOP
                  l_data := '   COMPANY ' || lpad(usa_jrnl_rep_rec.company,8,' ') || ' NET =      ' ||  usa_jrnl_rep_rec.formatted_sum_net_amount;  

                  UTL_FILE.PUT_LINE(lt_file,l_data);

                  l_out_cnt := l_out_cnt + 1;
           END LOOP;

    write_log(p_debug_flag,'----9');


                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

                 v_report_count        := '0';
                 v_all_accts_net       :=  0;
                 v_all_accts_net_fmt   := '0.00';

    write_log(p_debug_flag,'----10');


                 OPEN jrnl_usa_rep_count(p_period_name_begin,p_period_name_end,l_account_from,l_account_to); 
                    FETCH jrnl_usa_rep_count INTO v_report_count,v_all_accts_net,v_all_accts_net_fmt;
                  CLOSE jrnl_usa_rep_count; 

                  l_data := '   ALL ACCOUNTS  NET =             ' || v_all_accts_net_fmt;
                  UTL_FILE.PUT_LINE(lt_file,l_data);

                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        

    write_log(p_debug_flag,'----11');

                                                                                                                                                         
                  l_data := '   TOTAL RECORD COUNT=    ' || v_report_count;                                                                                                  
                  UTL_FILE.PUT_LINE(lt_file,l_data);
                                                                                                                                     
                                                                                                                                     
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                 UTL_FILE.PUT_LINE(lt_file,' ' || chr(13));                                                                                                                                                                                                                                                                        
                  l_data := '   ****  END  OF  REPORT   *****';
                  UTL_FILE.PUT_LINE(lt_file,l_data);

    write_log(p_debug_flag,'----12');

                
                  UTL_FILE.fclose(lt_file);
--                write_log(p_debug_flag,'NOT Calling USA XPTR Program');
--                generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));

                write_log(p_debug_flag,l_country || ' Journal Detail Report ' || l_account_from || ' thru ' || l_account_to ||  ' is completed');
                write_log(p_debug_flag,l_out_cnt ||' Total ' || l_country || ' Records Written');
 

END Extract_Balances;
END XXOD_GL_IRS_QTRLY_EXTRACT_PKG;
/
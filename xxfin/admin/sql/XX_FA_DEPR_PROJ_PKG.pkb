create or replace
PACKAGE BODY      XX_FA_DEPR_PROJ_PKG
AS

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization                          |
    -- +===================================================================+
    -- | Name  : XX_FA_DEPR_PROJ_PKG                                       |
    -- | Description:  CR646                                               |
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |1.1       06-MAY-2010 Sundaram S       Modified for defect #5643   |
    -- |                                       Unusable index              |
    -- |1.2       20-MAY-2010 Rama Krishna K   Reverted defect #5643 to    |
    -- |                                       include analyze statement   |
    -- |                                       as per PERF Team Recommend  |
    -- |1.3       05-DEC-13   sivalanka        Modified to display the     |
    -- |                                          report output            |
    -- |                                       Defect #26391               |
    -- |1.4       30-Oct-2015 Madhu Bolli      122 Retrofit - Remove schema|
	-- |1.5       06-Nov-2015 Madhu Bolli      Replaced FA_PROJ_INTERIM_RPT with FA_PROJ_INTERIM_REP| 
    -- +===================================================================+


    ---------------------
    -- Global Variables
    ---------------------
    gc_current_step        VARCHAR2(500);
    gn_user_id             NUMBER   := FND_PROFILE.VALUE('USER_ID');
    gn_org_id              NUMBER   := FND_PROFILE.VALUE('ORG_ID');
    gn_request_id          NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();


    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : XX_DEPR_PROJ_RPT                                          |
    -- | Description : Per CR646 This procedure will be used to generate   |
    -- |               a pipe delimited file from data on the staging table|
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE XX_DEPR_PROJ_RPT  (errbuff        OUT VARCHAR2
                                ,retcode        OUT VARCHAR2
                                ,P_asset_book   IN  VARCHAR2
                                ,P_corp         IN  VARCHAR2 DEFAULT NULL
                                ,P_cost_center  IN  VARCHAR2 DEFAULT NULL
                                ,P_Account      IN  VARCHAR2 DEFAULT NULL
                                ,P_location     IN  VARCHAR2 DEFAULT NULL
                                ,P_lob          IN  VARCHAR2 DEFAULT NULL
                                ,P_delimiter    IN  VARCHAR2 DEFAULT NULL
                                )
    as

          lc_corp                   gl_code_combinations.segment1%TYPE;
          lc_cost_center            gl_code_combinations.segment2%TYPE;
          lc_account                gl_code_combinations.segment3%TYPE;
          lc_location               gl_code_combinations.segment4%TYPE;
          lc_lob                    gl_code_combinations.segment6%TYPE;
          lc_period_name            XX_FA_DEPR_PROJ_STG.period_name%TYPE;
          lc_year                   XX_FA_DEPR_PROJ_STG.fiscal_year%TYPE;
          ln_amount                 XX_FA_DEPR_PROJ_STG.depreciation%TYPE;
          lc_datafound              VARCHAR2(1);
          lc_delimiter              VARCHAR2(1);

         -----------------------
         -- Define report cursor
         -----------------------
         CURSOR proj_depr_cur IS
         SELECT cc.segment1,
                cc.segment2,
                cc.segment3,
                cc.segment4,
                cc.segment6,
                DP.period_name,
                DP.fiscal_year,
                sum (dp.depreciation)
           FROM
           --XX_FA_DEPR_PROJ_STG  DP,  --commented by sivalanka 05-DEC-13
          FA_PROJ_INTERIM_RPT  DP,     --Added by sivalanka 05-DEC-13
          gl_code_combinations cc
          WHERE DP.code_combination_id = cc.code_combination_id
            AND cc.segment1 = nvl(P_corp,cc.segment1)
            AND cc.segment2 = nvl(P_cost_center, cc.segment2)
            AND cc.segment3 = nvl(P_Account, cc.segment3)
            AND cc.segment4 = nvl(P_location, cc.segment4)
            AND cc.segment6 = nvl(P_lob, cc.segment6)
            AND DP.BOOK_TYPE_CODE = P_ASSET_BOOK
            AND request_id=(select max(request_id) from FA_PROJ_INTERIM_REP where BOOK_TYPE_CODE = P_asset_Book ) --Added by sivalanka 05-DEC-13 -- 1.5
         GROUP BY
	        cc.segment1, cc.segment2, cc.segment3, cc.segment4,
                cc.segment6, DP.period_index, DP.fiscal_year, DP.period_name
         ORDER BY
                cc.segment1, cc.segment2, cc.segment3, cc.segment4,
                cc.segment6, DP.fiscal_year, DP.period_index;

     BEGIN


       lc_datafound := 'N';

       -------------------------------------------
       gc_current_step := ' Step: Set Delimiter';
       -------------------------------------------

       IF P_delimiter IS NULL THEN

           lc_delimiter := '|';

       ELSE

           lc_delimiter := P_delimiter;

       END IF;
       -------------------------------------------
       gc_current_step := ' Step: Printing Header';
       -------------------------------------------

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                       ||'               '
                                       ||'               '
                                       ||'               '
                                       ||'               '
                                       ||'Report Date: '
                                       || to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'            '
                                       ||'            '
                                       ||'            '
                                       ||'Depreciation Projection Report');



       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Asset Book: '|| P_asset_book);

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company'    ||lc_delimiter||
                                         'Cost Center'||lc_delimiter||
                                         'Account'    ||lc_delimiter||
                                         'Location'   ||lc_delimiter||
                                         'LOB'        ||lc_delimiter||
                                         'Period'     ||lc_delimiter||
                                         'Proj Depre Amt' );

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');



       --------------------------------------------------------
       gc_current_step := ' Step: OPEN Cursor - proj_depr_cur ';
       --------------------------------------------------------

       OPEN proj_depr_cur;

          LOOP

              FETCH proj_depr_cur
               INTO       lc_corp
                         ,lc_cost_center
                         ,lc_account
                         ,lc_location
                         ,lc_lob
                         ,lc_period_name
                         ,lc_year
                         ,ln_amount;

          EXIT WHEN proj_depr_cur%NOTFOUND;

              lc_datafound := 'Y';


              ---------------------------------------------------------
              gc_current_step := ' Step: Write Details to output file ';
              ---------------------------------------------------------

              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_corp         || lc_delimiter ||
                                                 lc_cost_center  || lc_delimiter ||
                                                 lc_account      || lc_delimiter ||
                                                 lc_location     || lc_delimiter ||
                                                 lc_lob          || lc_delimiter ||
                                                 lc_period_name  || lc_delimiter ||
                                                 ln_amount );

          END LOOP;

       CLOSE proj_depr_cur;


       IF lc_datafound = 'N' THEN

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     ***** No Data Found *****' );

       END IF;


     EXCEPTION


          WHEN OTHERS THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG, gc_current_step);
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             retcode := 2;

             errbuff := gc_current_step;

    END XX_DEPR_PROJ_RPT;



    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : XX_DEPR_PROJ_LOAD_STG                                     |
    -- | Description : Per CR646 This procedure will be used to submit the |
    -- | Standard Depreciation Projection program and copy the data from   |
    -- | the temp table to the staging table.                              |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE XX_DEPR_PROJ_LOAD_STG (errbuff        OUT VARCHAR2
                                    ,retcode        OUT VARCHAR2
                                    ,p_calendar     IN  VARCHAR2
                                    ,p_start_period IN  VARCHAR2
                                    ,p_num_periods  IN  VARCHAR2
                                    ,p_asset_Bk1    IN  VARCHAR2 DEFAULT NULL
                                    ,p_asset_Bk2    IN  VARCHAR2 DEFAULT NULL
                                    ,p_asset_Bk3    IN  VARCHAR2 DEFAULT NULL
                                    ,p_asset_Bk4    IN  VARCHAR2 DEFAULT NULL)
    AS


	---------------------
	-- Variables defined
	---------------------
        ln_req_id              NUMBER;
        lc_phase               VARCHAR2(50);
        lc_status              VARCHAR2(50);
        lc_dev_phase           VARCHAR2(50);
        lc_dev_status          VARCHAR2(50);
        lc_message             VARCHAR2(1000);
        lb_result              BOOLEAN;
        ln_rows_to_del         NUMBER;
        ln_rows_deleted        NUMBER;
        ld_time_date           DATE := sysdate;
        lc_currency            VARCHAR2(3);


        -------------------------------------
        -- Declare collection for asset books
        -------------------------------------
        TYPE asset_Books_col IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
        lc_asset_Books asset_Books_col;


        -------------------
        -- Define Exception
        -------------------

        FA_DEPR_PROJ_EXP EXCEPTION;



     BEGIN

        ----------------------------------------------------
        gc_current_step := ' Step: Parameters for Program ';
        ----------------------------------------------------

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parameters for Program');
          FND_FILE.PUT_LINE(FND_FILE.LOG, '-------------------------------');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_Calendar     = ' ||p_calendar);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_start_period = ' ||p_start_period);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_num_periods  = ' ||p_num_periods);

        --------------------------------------------------------
        gc_current_step := ' Step: intitalize lc_asset_book(1) ';
        --------------------------------------------------------
          lc_asset_Books(1)  := p_asset_Bk1;

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_asset_Bk1    = ' ||p_asset_Bk1);

        ---------------------------------------------------------------
        gc_current_step := ' Step: intitalize lc_asset_books(2) - (4) ';
        ---------------------------------------------------------------

          lc_asset_Books(2)  := NULL;
          lc_asset_Books(3)  := NULL;
          lc_asset_Books(4)  := NULL;

          IF p_asset_Bk2 is not null THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_asset_Bk2    = ' ||p_asset_Bk2);
               lc_asset_Books(2)   := p_asset_Bk2;

          END IF;

          IF  p_asset_Bk3 is not null THEN


               FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_asset_Bk3    = ' ||p_asset_Bk3);
               lc_asset_Books(3)   := p_asset_Bk3;

          END IF;

          IF  p_asset_Bk4 is not null THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_asset_Bk4    = ' ||p_asset_Bk4 );
               lc_asset_Books(4)   := p_asset_Bk4;

          END IF;

        ---------------------------------------------------------------
        gc_current_step := ' Step: Set currency code ';
        ---------------------------------------------------------------

          IF gn_org_id = 404 THEN

             lc_currency := 'USD';

          ELSIF gn_org_id = 403  THEN

             lc_currency := 'CAD';

          ELSE

             gc_current_step := ' Error - Invalid currency code: ' || lc_currency;
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Confirm Org_id '||gn_org_id ||' is correct.');

             RAISE FA_DEPR_PROJ_EXP;

          END IF;

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_currency    = ' ||lc_currency);
          FND_FILE.PUT_LINE(FND_FILE.LOG, '-------------------------------');


        --------------------------------------------------------------
        gc_current_step := ' Step: Submitting Standard FA Projection ';
        --------------------------------------------------------------

          FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Standard FA Projection submitted at: '
                            ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));

          ln_req_id := fnd_request.submit_request('OFA',
                                                  'FAPROJ',
                                                  NULL,
                                                  NULL,
                                                  FALSE,
                                                  p_calendar,
                                                  p_start_period,
                                                  to_number(p_num_periods, '99'),
                                                  lc_currency,
                                                  lc_asset_Books(1),
                                                  lc_asset_Books(2),
                                                  lc_asset_Books(3),
                                                  lc_asset_Books(4));

          COMMIT;


          IF ln_req_id = 0 THEN
               ---------------------------------------------------------------------------------------------
               gc_current_step := 'Warning: FA Projections (Depreciation Projection) Request Not Submitted';
               ---------------------------------------------------------------------------------------------
               RAISE FA_DEPR_PROJ_EXP;

          ELSE

               ------------------------------------------------------------------------------------
               gc_current_step := ' Step: waiting for standard FA Projection request to complete ';
               ------------------------------------------------------------------------------------
               lb_result := fnd_concurrent.wait_for_request(ln_req_id,
                                                            60,            -- Intervals
                                                            0,             -- Max wait
                                                            lc_phase,
                                                            lc_status,
                                                            lc_dev_phase,
                                                            lc_dev_status,
                                                            lc_message);
               COMMIT;

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Standard FA Projection completed at: '
                                ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));
               FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

          END IF;


          IF lb_result = FALSE OR lc_status = 'Error' OR lc_status = 'Warning' OR lc_status ='Terminated' THEN

               ------------------------------------------------------------------------------------------------------
               gc_current_step := ' Step: Standard FA Projection completed with Errors/Warnings or was terminated. ';
               ------------------------------------------------------------------------------------------------------

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'FA Projections (Depreciation Projection) Request ID '
                                  || ln_req_id || ' Failed:' || lc_message);

               RAISE FA_DEPR_PROJ_EXP;

          END IF;

              -------------------------------------------------------------------------------------------
              gc_current_step := ' Step: Loop to truncate and insert asset book details on staging table ';
              -------------------------------------------------------------------------------------------
              FOR i IN lc_asset_Books.FIRST..lc_asset_Books.LAST LOOP

                  IF lc_asset_Books(i) IS NOT NULL  THEN

                       FND_FILE.PUT_LINE(FND_FILE.LOG,  'Processing Asset Book: ' || lc_asset_Books(i));

                       ----------------------------------------------------------------------------
                       gc_current_step := ' Step: Select Row cnt to be deleted from staging table ';
                       ----------------------------------------------------------------------------
                       SELECT nvl(count(1),0)
                         INTO ln_rows_to_del
                         FROM XX_FA_DEPR_PROJ_STG
                        WHERE book_type_code = lc_asset_Books(i);


                       IF ln_rows_to_del != 0 THEN

                            ------------------------------------------------------------------------------
                            gc_current_step := ' Step: truncate existing asset books from staging table ';
                            ------------------------------------------------------------------------------

                            FND_FILE.PUT_LINE(FND_FILE.LOG, '    Truncation of table started at: '
                                ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));

                            execute immediate 'ALTER TABLE XXFIN.XX_FA_DEPR_PROJ_STG TRUNCATE PARTITION '
                                         -- Commented below UPDATE INDEXES clause as we do not need this since
					 -- we are going with Code Combination Id Local Index as part of QC #5644
					 -- by Rama Krishna K on 5/20 for Version 1.2
					 --|| REPLACE(lc_asset_Books(i),' ','_')||' UPDATE INDEXES'; -- Added 'UPDATE INDEXES' for defect #5643 on 06-May-2010
                                         || REPLACE(lc_asset_Books(i),' ','_'); -- Added 'UPDATE INDEXES' for defect #5643 on 06-May-2010

                            COMMIT;

                            FND_FILE.PUT_LINE(FND_FILE.LOG, '    Truncation of table completed at: '
                                ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));

                      END IF;

                      -----------------------------------------------------------------------------
                      gc_current_step := ' Step: Confirm all rows are deleted from staging table ';
                      -----------------------------------------------------------------------------

                      SELECT nvl(count(1),0)
                        INTO ln_rows_deleted
                        FROM XX_FA_DEPR_PROJ_STG
                       WHERE book_type_code = lc_asset_Books(i);

                      IF  ln_rows_deleted = 0 then
                          -------------------------------------------------------------------------
                          gc_current_step := ' Step: Confirm all rows deleted from staging table ';
                          -------------------------------------------------------------------------
                           FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
                           FND_FILE.PUT_LINE(FND_FILE.LOG, '    '||lc_asset_Books(i)||' Asset book rows deleted: '
                                                                   ||ln_rows_to_del);

                       ELSE

                          gc_current_step := ' Exception found: not all records have been deleted' ||
                                             ' from staging table for asset book: '|| lc_asset_Books(i);

                          RAISE FA_DEPR_PROJ_EXP;

                       END IF;


                       ----------------------------------------------------------------------------
                       gc_current_step := ' Step: Insert records from temp table to staging table ';
                       ----------------------------------------------------------------------------

                       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
                       FND_FILE.PUT_LINE(FND_FILE.LOG, '    Insert of table started at: '
                              ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));


                       execute immediate 'INSERT INTO XX_FA_DEPR_PROJ_STG ' ||
                                           ' SELECT book_type_code '              ||
                                                 ',asset_id '                     ||
                                                 ',Period_Name '                  ||
                                                 ',Period_Index '                 ||
                                                 ',Fiscal_Year '                  ||
                                                 ',Code_combination_id '          ||
                                                 ',Depreciation '                 ||
                                                 ',sysdate '                      ||
                                                 ','||gn_request_id               ||
                                          ' FROM FA_PROJ_INTERIM_'|| ln_req_id ||
                                          ' WHERE book_type_code = '|| ''''|| lc_asset_Books(i)||'''';



                       FND_FILE.PUT_LINE(FND_FILE.LOG, '    Insert of table completed at: '
                              ||to_char(sysdate, 'DD-Mon-YYYY HH24:MI:SS'));


                       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'    '|| lc_asset_Books(i)||' Asset book rows inserted: '
                                                       ||TO_CHAR(SQL%ROWCOUNT));
                       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

                       COMMIT;

			 -- Commented below UPDATE INDEXES clause as we do not need this since
			 -- we are going with Code Combination Id Local Index as part of QC #5644
			 -- by Rama Krishna K on 5/20 for Version 1.2

			/* execute immediate 'EXEC FND_STATS.GATHER_TABLE_STATS('  ||
			                    ''''XXFIN''','''XX_FA_DEPR_PROJ_STG',null,null,|| REPLACE(lc_asset_Books(i),' ','_'));*/

			 -- Commented by Ganesan since the below is a function call and it can be directly called from the package
			/* execute immediate 'EXEC FND_STATS.GATHER_TABLE_STATS('||
                       '''XXFIN'''||','||'''XX_FA_DEPR_PROJ_STG'''||','||'null'||','||'null'||','||'''' ||REPLACE(lc_asset_Books(i),' ','_')||'''' ||')';*/
                        FND_STATS.GATHER_TABLE_STATS('XXFIN','XX_FA_DEPR_PROJ_STG',null,null,REPLACE(lc_asset_Books(i),' ','_'));


                  END IF;

              END LOOP;

              -------------------
              -- DROP TEMP TABLE
              -------------------

              -----------------------------------------------------------------------
              gc_current_step := ' Step: Dropping TABLE FA_PROJ_INTERIM_'|| ln_req_id;
              -----------------------------------------------------------------------
              execute immediate 'DROP TABLE FA_PROJ_INTERIM_'|| ln_req_id;


     EXCEPTION

          WHEN FA_DEPR_PROJ_EXP THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG,  gc_current_step);
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             ------------------------------------
             -- If error found cleanup temp table
             ------------------------------------
             execute immediate 'DROP TABLE FA_PROJ_INTERIM_'|| ln_req_id;

             retcode := 2;

             errbuff := gc_current_step;

          WHEN OTHERS THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG, gc_current_step);
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             ------------------------------------
             -- If error found cleanup temp table
             ------------------------------------
             execute immediate 'DROP TABLE FA_PROJ_INTERIM_'|| ln_req_id;

             retcode := 2;

             errbuff := gc_current_step;


END XX_DEPR_PROJ_LOAD_STG ;

END XX_FA_DEPR_PROJ_PKG;
/
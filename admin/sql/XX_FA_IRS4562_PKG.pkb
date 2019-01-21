create or replace 
PACKAGE BODY XX_FA_IRS4562_PKG AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :     OD FA IRS TAX FORM 4652                                |
 -- | Description :To calulate the depreciation and amortization        |
 -- |              details and provide the information in the format to |
 -- |              populate the IRS Tax Form                            |
 -- |                                                                   |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author                Remarks              |
 -- |=======   ==========   =============        =======================|
 -- |1.0       16-SEP-2009  Priyanka Nagesh       Initial version       |
 -- |1.1       21-OCT-2009  Priyanka Nagesh       Defect # 2967         |
 -- |1.2       23-DEC-09    Bhuvaneswary          Updated for the Defect|
 -- |                                             1178 CR 431 R1.2      |
 -- |1.3       04-FEB-2010  Rani Asaithambi       Updated for the defect|
 -- |                                             3224.                 |
 -- |1.4       15-JAN-2015  John Willson          update for the defect |
 --                                               33304.                |
 -- |1.5       14-MAR-2015 John Willson           update for the defect |
 --                                                33397                |
 -- |1.7       30-Oct-2015 Madhu Bolli      122 Retrofit - Remove schema|
 -- +===================================================================+
 -- +===================================================================+
 -- | Name : XX_FA_IRS4562_PROC                                         |
 -- | Description : This Program will produce the details               |
 -- |               for current year assets and summary information     |
 -- |               for prior year assets                               |
 -- |                                                                   |
 -- | Program "OD: FA IRS Tax Form 4562"                                |
 -- |                                                                   |
 -- | Parameters : p_book,p_fiscal_year,p_company,p_category_id         |
 -- |              p_spfrom_date,p_spto_date                            |
 -- |                                                                   |
 -- |                                                                   |
 -- +===================================================================+
    PROCEDURE XX_FA_IRS4562_PROC(p_book                    IN VARCHAR2
                                ,p_fiscal_year             IN VARCHAR2
                                ,p_company                 IN VARCHAR2
                                ,p_category_id             IN NUMBER
                                ,p_spfrom_date             IN DATE-- Added for the defect 1178 CR 431 R1.2
                                ,p_spto_date               IN DATE-- Added for the defect 1178 CR 431 R1.2
                                ) AS




    CURSOR c_fa_irs4652( p_start_period_counter     NUMBER
                        ,p_end_period_counter       NUMBER  --Added for Defect 2967 on Oct 20th 2009
                        ,p_period_counter           NUMBER
                        ,p_report_period_close_date DATE
                       )
    IS
    SELECT  GCC.segment1                                                        COMPANY_CODE
           ,TO_CHAR(p_fiscal_year)                                              FISCAL_YEAR_ADDED
           ,FBK.deprn_method_code                                               DEPRN_METHOD_CODE
           ,FCAT.segment1||'-'||FCAT.segment2||'-'||FCAT.segment3                ASSET_CATEGORY
           ,FAD.asset_number ||' - '||FAD.description                           ASSET_NUMBER
           ,FAD.ASSET_ID                                                        ASSET_ID
           ,SUM(FDD.cost)                                                       COST
           ,(FBK.life_in_months/12)                                             LIFE_IN_MONTHS
           ,FBK.adjusted_rate                                                   ADJUSTED_RATE
           ,FDS.bonus_rate                                                      BONUS_RATE
           ,FBK.Date_placed_in_service                                          PIS_DATE
           ,FBK.production_capacity                                             PRODUCTION
           ,FBK.prorate_convention_code                                         PRORATE_CONVENTION
           ,SUM(FDD.ytd_deprn)                                                  YTD_DEPRN
           ,DECODE( INSTR(FBK.deprn_method_code, '30B')
                  ,0,DECODE (INSTR(FBK.deprn_method_code, '50B')
                              ,0,0
                              , DECODE(FFY.fiscal_year
                                       ,p_fiscal_year,(FBK.recoverable_cost * .5 )
                                       , 0
                                       )
                              )
                   ,DECODE(FFY.fiscal_year
                           ,p_fiscal_year,(FBK .recoverable_cost * .3 ) , 0
                               )
                   )                                                            SPECIAL_DEPRN
          ,FAD.attribute11                                                      TAX_RECONCILE
          ,FAD.description                                                      DESCRIPTION
    FROM   fa_deprn_detail           FDD
          ,fa_deprn_summary          FDS
          ,fa_additions              FAD
          ,fa_asset_history          FAH
          ,fa_categories             FCAT
          ,fa_books                  FBK
          ,gl_code_combinations      GCC
          ,fa_distribution_history   FDH
          ,fa_fiscal_year            FFY
          ,fa_book_controls          FBC
    WHERE FBK.book_type_code         = p_book
    AND   FBK.asset_id               = FAD.asset_id
	-- added for the defect 33397
    --AND   TRUNC(TO_DATE(p_report_period_close_date,'DD-MON-YY')) BETWEEN TRUNC(FBK.date_effective) AND TRUNC(NVL(FBK.date_ineffective,SYSDATE)) --Added for the defect 33304
    AND FBK.date_ineffective is null   -- added for the defect 33397
	AND   TRUNC(FBK.date_placed_in_service)   BETWEEN TRUNC(FFY.start_date) and TRUNC(FFY.end_date)  --Added for the defect 33304
    AND   TRUNC(FBK.date_placed_in_service)   BETWEEN TRUNC(NVL(p_spfrom_date,FBK.date_placed_in_service)) AND   --Added for the defect 33304
	TRUNC(NVL(p_spto_date,FBK.date_placed_in_service))-- Added for the defect 1178 CR 431 R1.2  --Added for the defect 33304
    AND   NVL(FBK.period_counter_fully_retired,p_start_period_counter) >= p_start_period_counter
    AND   FBC.book_type_code          = p_book
    AND   FBC.fiscal_year_name        = FFY.fiscal_year_name
    AND   FDD.book_type_code          = p_book
    AND   FDD.asset_id                = FBK.asset_id
    AND   FDD.deprn_source_code       = 'D'
    AND   FDD.period_counter          = -- p_period_counter --Commented for Defect 2967 on Oct 20th 2009
                                  (                             --Added for Defect 2967 on Oct 20th 2009
                                SELECT  MAX(FDD1.period_counter)
                                FROM    fa_deprn_detail FDD1
                                WHERE   FDD1.book_type_code  = p_book
                                AND FDD1.asset_id=FDD.asset_id
                                AND FDD1.deprn_source_code='D'
                                AND  FDD1.period_counter  BETWEEN p_start_period_counter AND p_end_period_counter
                                )
    AND   FDH.distribution_id         = FDD.distribution_id
    AND   FDS.book_type_code          = p_book
    AND   FDS.asset_id                = FBK.asset_id
    AND   FDS.period_counter          = FDD.period_counter
    AND   FAH.asset_id                = FBK.asset_id
    AND   TRUNC(TO_DATE(p_report_period_close_date,'DD-MON-YY')) BETWEEN TRUNC(FAH.date_effective) AND TRUNC(NVL(FAH.date_ineffective,SYSDATE))  --Added for the defect 33304
    AND   FCAT.category_id             = FAH.category_id
    AND   FDH.code_combination_id      = GCC.code_combination_id (+)
    /*AND   DECODE(FFY.fiscal_year
                 ,p_fiscal_year,TO_CHAR(FFY.fiscal_year)
                 ,'Prev'
                 )                     <> 'Prev'*/
    AND   FFY.fiscal_year = p_fiscal_year
    AND   GCC.segment1                 LIKE NVL(p_company, '%')
    AND   FCAT.category_id             = NVL(p_category_id,FCAT.CATEGORY_ID)
    GROUP BY  GCC.segment1
             ,p_fiscal_year
             ,FBK.deprn_method_code
             ,FCAT.segment1||'-'||FCAT.segment2||'-'||FCAT.segment3
             ,FAD.asset_number ||' - '||FAD.description
             ,FAD.asset_id
             ,FBK.life_in_months/12
             ,FBK.adjusted_rate
             ,FBK.production_capacity
             ,FDS.bonus_rate
             ,FBK.Date_placed_in_service
             ,FBK.production_capacity
             ,FBK.prorate_convention_code
             ,DECODE( INSTR(FBK.deprn_method_code, '30B')
                  ,0,DECODE (INSTR(FBK.deprn_method_code, '50B')
                              ,0,0
                              , DECODE(FFY.fiscal_year
                                       ,p_fiscal_year,(FBK.recoverable_cost * .5 )
                                       , 0
                                       )
                              )
                   ,DECODE(FFY.fiscal_year
                           ,p_fiscal_year,(FBK .recoverable_cost * .3 ) , 0
                               )
                   )
             ,FAD.attribute11
             ,FAD.description
    UNION  ALL
    SELECT  GCC.segment1                                                        COMPANY_CODE
       --  ,'PREV'                                                              FISCAL_YEAR_ADDED -- Commented for the Defect 3224
           ,TO_CHAR(FFY.fiscal_year)                                            FISCAL_YEAR_ADDED -- Added for the Defect 3224
           ,FBK.deprn_method_code                                               DEPRN_METHOD_CODE
           ,FCAT.segment1||'-'||FCAT.segment2||'-'||FCAT.segment3               ASSET_CATEGORY
           ,NULL                                                                ASSET_NUMBER
           ,NULL                                                                ASSET_ID
           ,SUM(FDD.cost)                                                       COST
           ,NULL                                                                LIFE_IN_MONTHS
           ,NULL                                                                ADJUSTED_RATE
           ,NULL                                                                BONUS_RATE
           ,NULL                                                                PIS_DATE
           ,NULL                                                                PRODUCTION
           ,NULL                                                                PRORATE_CONVENTION
           ,SUM(FDD.ytd_deprn)                                                  YTD_DEPRN
           ,SUM(DECODE(INSTR(FBK.deprn_method_code, '30B')
                       ,0,DECODE (INSTR(FBK.deprn_method_code, '50B')
                                  ,0,0
                                  ,DECODE(FFY.fiscal_year
                                          ,p_fiscal_year,(FBK.recoverable_cost * .5 )
                                          ,0
                                          )
                                  )
                      ,DECODE(FFY.fiscal_year
                              ,p_fiscal_year,(FBK.recoverable_cost * .3 )
                              ,0
                              )
                      )
                 )                                                              SPECIAL_DEPRN
           ,NULL                                                                TAX_RECONCILE
           ,NULL                                                                DESCRIPTION
    FROM     fa_deprn_detail           FDD
            ,fa_deprn_summary          FDS
            ,fa_additions              FAD
            ,fa_asset_history          FAH
            ,fa_categories             FCAT
            ,fa_books                  FBK
            ,gl_code_combinations      GCC
            ,fa_distribution_history   FDH
            ,fa_fiscal_year            FFY
            ,fa_book_controls          FBC
    WHERE    FBK.book_type_code            = p_book
    AND      FBK.asset_id                  = FAD.asset_id
	 -- added for the defect 33397
  --  AND      TRUNC(TO_DATE(p_report_period_close_date,'DD-MON-YY')) BETWEEN TRUNC(FBK.date_effective) AND TRUNC(NVL(FBK.date_ineffective,SYSDATE))  --Added for the defect 33304
    AND FBK.date_ineffective is null  -- added for the defect 33397
	AND      TRUNC(FBK.date_placed_in_service)    BETWEEN TRUNC(FFY.start_date) AND TRUNC(FFY.end_date)  --Added for the defect 33304
    AND      TRUNC(FBK.date_placed_in_service)   BETWEEN TRUNC(NVL(p_spfrom_date,FBK.date_placed_in_service)) AND   --Added for the defect 33304
	TRUNC(NVL(p_spto_date,FBK.date_placed_in_service))-- Added for the defect 1178 CR 431 R1.2  --Added for the defect 33304
    AND      NVL(FBK.period_counter_fully_retired,p_start_period_counter) >= p_start_period_counter
    AND      FBC.book_type_code            = p_book
    AND      FBC.fiscal_year_name          = FFY.fiscal_year_name
    AND      FDD.book_type_code            = p_book
    AND      FDD.asset_id                  = FBK.asset_id
    AND      FDD.deprn_source_code         = 'D'
    AND      FDD.period_counter            = -- p_period_counter -- Commenetd for Defect 2967 on Oct 20th 2009
                                (                                -- Added for Defecr 2967 on Oct 20th 2009
                                SELECT  MAX(FDD1.period_counter)
                                FROM    fa_deprn_detail FDD1
                                WHERE   FDD1.book_type_code  = p_book
                                AND FDD1.asset_id=FDD.asset_id
                                AND FDD1.deprn_source_code='D'
                                AND FDD1.period_counter  BETWEEN p_start_period_counter AND p_end_period_counter
                               )
    AND      FDH.distribution_id           = FDD.distribution_id
    AND      FDS.book_type_code            = p_book
    AND      FDS.asset_id                  = FBK.asset_id
    AND      FDS.period_counter            = FDD.period_counter
    AND      FAH.asset_id                  = FBK.asset_id
    AND      TRUNC(TO_DATE(p_report_period_close_date,'DD-MON-YY')) BETWEEN TRUNC(FAH.date_effective) AND  TRUNC(NVL(FAH.date_ineffective,SYSDATE))  --Added for the defect 33304
    AND      FCAT.category_id              = FAH.category_id
    AND      FDH.code_combination_id       = GCC.code_combination_id (+)
    /*AND      DECODE( FFY.fiscal_year
                    ,p_fiscal_year,TO_CHAR(FFY.fiscal_year)   -- Commented for the Defect 3224
                    ,'Prev'
                    )                      = 'Prev'*/
    AND      FFY.fiscal_year               < p_fiscal_year                 -- Added for the Defect 3224
    AND      GCC.segment1                  LIKE NVL(p_company,'%')
    AND      FCAT.category_id              = NVL(p_CATEGORY_ID,FCAT.CATEGORY_ID)
    GROUP BY  GCC.segment1
             ,FFY.fiscal_year
             ,FBK.deprn_method_code
             ,FCAT.segment1||'-'||FCAT.segment2||'-'||FCAT.segment3
             ,FBK.Date_placed_in_service
    ORDER BY 1,2,3,4,5,6;
    --Cursor
    ln_start_period_counter       NUMBER           := 0;
    ln_end_period_counter         NUMBER           := 0;
    ln_period_counter             NUMBER           := 0;
    ld_report_period_close_date   DATE;
    lc_line_item                  VARCHAR2(200);
  --ln_cost                       NUMBER           :=0; --Commented for CR # 439 on OCT 1
    ln_basis_cy_deprn             NUMBER           := 0;
    ln_cy_exp_excl_deprn          NUMBER           := 0;
    ln_total_26                   NUMBER           := 0;
    ln_total_21                   NUMBER           := 0;
    ln_total_44                   NUMBER           := 0;
    ln_total_22                   NUMBER           := 0;
    ln_total_26_cost              NUMBER           := 0;
    ln_fiscal_year                NUMBER           := 0;

    --Exceptions
        lc_error_location             VARCHAR2(4000);
        lc_error_debug                VARCHAR2(4000);



    BEGIN
    	-- Added for the Defect 3224 --Starts Here
      BEGIN
	SELECT meaning
        INTO   ln_fiscal_year
	FROM   fnd_lookup_values FLV
	WHERE  lookup_type = 'XXOD_FA_IRS4562'
        AND    SYSDATE BETWEEN FLV.start_date_active AND NVL(FLV.end_date_active,sysdate+1)
        AND    FLV.enabled_flag = 'Y'
	AND    FLV.lookup_code = 'FIS';
      EXCEPTION
          WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
      END;

    -- Added for the Defect 3224 --Ends Here
        BEGIN
           SELECT  MIN(FDP.period_counter)       START_PERIOD_COUNTER
                  ,MAX(FDP.period_counter)       END_PERIOD_COUNTER
           INTO    ln_start_period_counter
                  ,ln_end_period_counter
           FROM    fa_deprn_periods               FDP
           WHERE   FDP.book_type_code = p_book
           AND     FDP.fiscal_year    = p_fiscal_year;
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'start_period_counter : '||ln_start_period_counter);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'end_period_counter : '||ln_end_period_counter);
        EXCEPTION
          WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
               ln_start_period_counter := 0;
               ln_end_period_counter   := 0;
        END;
       /*BEGIN                              -- Commented for Defect 2967 on Oct 20th 2009
          SELECT  MAX(FDD.period_counter)
          INTO    ln_period_counter
          FROM    fa_deprn_detail FDD
          WHERE   FDD.book_type_code  = p_book
          AND     FDD.distribution_id = FDD.distribution_id
          AND     FDD.period_counter  BETWEEN ln_start_period_counter AND ln_end_period_counter;
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'period_counter : '||ln_period_counter);
                         EXCEPTION
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
               ln_period_counter := 0;
       END;*/
       BEGIN
          SELECT NVL(period_close_date,SYSDATE)
          INTO   ld_report_period_close_date
          FROM   fa_deprn_periods
          WHERE  book_type_code = p_book
          AND    period_counter = ln_end_period_counter;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ld_report_period_close_date : '||ld_report_period_close_date);
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'report_period_close_date not obtained'||SQLERRM);
             ld_report_period_close_date := SYSDATE;
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
             ld_report_period_close_date := SYSDATE;
       END;

        lc_error_location := 'Opening the Cursor';
        lc_error_debug    := '';
       FOR lcu_fa_irs4652 IN c_fa_irs4652( ln_start_period_counter
                                           , ln_end_period_counter
                                           , ln_period_counter
                                           , ld_report_period_close_date
                                         )
       LOOP
       lc_line_item                :=  NULL; --Added for CR # 439 on OCT 1
       ln_basis_cy_deprn           := 0;--Added for CR # 439 on OCT 1
       ln_cy_exp_excl_deprn        := 0;--Added for CR # 439 on OCT 1


         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Row_Count : '||c_fa_irs4652%rowcount);
       --To fetch Data for Line 14+19 -C/Y MACRS --
          IF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) NOT IN('VEH','LAQ','INT')) AND (lcu_fa_irs4652.fiscal_year_added=p_fiscal_year) THEN
             lc_line_item                     := 'Line 14+19 -C/Y MACRS';
             ln_basis_cy_deprn                := lcu_fa_irs4652.cost - lcu_fa_irs4652.special_deprn;
             ln_cy_exp_excl_deprn             := lcu_fa_irs4652.YTD_DEPRN - lcu_fa_irs4652.special_deprn;
             ln_total_22                      := ln_total_22 + lcu_fa_irs4652.special_deprn + ln_cy_exp_excl_deprn;
      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 14+19 -C/Y MACRS is fetched');

      -- Commented for the Defect 3224 -- Starts here --
        /*  --To fetch Data for Line 16 -ACRS+STL--
          ELSIF (SUBSTR(lcu_fa_irs4652.deprn_method_code,1,2) <> 'MA') AND (SUBSTR(lcu_fa_irs4652.asset_category,1,3) NOT IN('VEH','LAQ','INT'))
                                                                       AND (lcu_fa_irs4652.fiscal_year_added='PREV') THEN
             lc_line_item                      := 'Line 16 -ACRS+STL';
             ln_cy_exp_excl_deprn              := lcu_fa_irs4652.ytd_deprn;
             ln_total_22                      := ln_total_22 + ln_cy_exp_excl_deprn;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 16 -ACRS+STL is fetched');
          --To fetch Data for Line 17 - P/Y MACRS --
          ELSIF (SUBSTR(lcu_fa_irs4652.deprn_method_code,1,2) = 'MA') AND (SUBSTR(lcu_fa_irs4652.asset_category,1,3) <> 'VEH')
                                                                   AND (lcu_fa_irs4652.fiscal_year_added='PREV') THEN
             lc_line_item                      := 'Line 17 - P/Y MACRS';
             ln_cy_exp_excl_deprn              := lcu_fa_irs4652.ytd_deprn;
             ln_total_22                       := ln_total_22 +  ln_cy_exp_excl_deprn;*/
      -- Commented for the Defect 3224 -- Ends here --

      -- Added for the Defect 3224 -- Starts here --
      --To fetch Data for Line 16 -ACRS+STL--
          ELSIF (((SUBSTR(lcu_fa_irs4652.asset_category,1,3) NOT IN('VEH','LAQ','INT')) AND (lcu_fa_irs4652.fiscal_year_added < ln_fiscal_year))
                 OR((SUBSTR(lcu_fa_irs4652.asset_category,1,4) ='SOFT') AND (lcu_fa_irs4652.fiscal_year_added < p_fiscal_year))) THEN
             lc_line_item                      := 'Line 16 -ACRS+STL';
             ln_cy_exp_excl_deprn              := lcu_fa_irs4652.ytd_deprn;
             ln_total_22                      := ln_total_22 + ln_cy_exp_excl_deprn;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 16 -ACRS+STL is fetched');

      --To fetch Data for Line 17 - P/Y MACRS --
          ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) NOT IN('VEH','LAQ','INT'))
	            AND (SUBSTR(lcu_fa_irs4652.asset_category,1,4) <> 'SOFT')
                    AND (lcu_fa_irs4652.fiscal_year_added BETWEEN ln_fiscal_year AND p_fiscal_year) THEN
             lc_line_item                      := 'Line 17 - P/Y MACRS';
             ln_cy_exp_excl_deprn              := lcu_fa_irs4652.ytd_deprn;
             ln_total_22                       := ln_total_22 +  ln_cy_exp_excl_deprn;
      -- Added for the Defect 3224 -- Ends here --

      --To fetch Data for Line 25+26a -C/Y VEH Adds--
      --ELSIF (lcu_fa_irs4652.asset_category ='VEH') AND (lcu_fa_irs4652.fiscal_year_added=p_fiscal_year) THEN
          ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) = 'VEH') AND (lcu_fa_irs4652.fiscal_year_added=p_fiscal_year) THEN
             lc_line_item                       := 'Line 25+26a -C/Y VEH Adds';
             --lcu_fa_irs4652.special_deprn       := lcu_fa_irs4652.ytd_deprn;
             ln_basis_cy_deprn                  := lcu_fa_irs4652.cost - lcu_fa_irs4652.special_deprn;
             ln_cy_exp_excl_deprn               := lcu_fa_irs4652.ytd_deprn - lcu_fa_irs4652.special_deprn;
             ln_total_22                       := ln_total_22 + lcu_fa_irs4652.special_deprn + ln_cy_exp_excl_deprn;
             ln_total_26                       := ln_total_26 + ln_cy_exp_excl_deprn;
             ln_total_26_cost                  := ln_total_26_cost + lcu_fa_irs4652.cost;
             ln_total_21                       := ln_total_21 + lcu_fa_irs4652.special_deprn + ln_cy_exp_excl_deprn;

      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 25+26a -C/Y VEH Adds is fetched');
      --To fetch data for Line 26b - P/Y VEH Adds--
      -- ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) = 'VEH') AND (lcu_fa_irs4652.fiscal_year_added = 'PREV') THEN -- Commented for the Defect 3224
         ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) = 'VEH') AND (lcu_fa_irs4652.fiscal_year_added < p_fiscal_year) THEN --Added for the Defect 3224
             lc_line_item                       := 'Line 26b - P/Y VEH Adds';
             ln_cy_exp_excl_deprn               := lcu_fa_irs4652.ytd_deprn - lcu_fa_irs4652.special_deprn;
             ln_total_22                        := ln_total_22 +  ln_cy_exp_excl_deprn;
             ln_total_26                       := ln_total_26 + ln_cy_exp_excl_deprn;
              ln_total_26_cost                  := ln_total_26_cost + lcu_fa_irs4652.cost;
             ln_total_21                       := ln_total_21 + ln_cy_exp_excl_deprn;

      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 26b - P/Y VEH Adds is fetched');

      --To fetch data for Line 42 Amort - C/Y Adds--
          ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) IN('LAQ','INT')) AND (lcu_fa_irs4652.fiscal_year_added=p_fiscal_year) THEN
             lc_line_item                       := 'Line 42 Amort - C/Y Adds';
             ln_cy_exp_excl_deprn               := lcu_fa_irs4652.ytd_deprn - lcu_fa_irs4652.special_deprn;
             ln_basis_cy_deprn                  := NULL;--Added for CR # 439 on OCT 1
             ln_total_44                        :=  ln_total_44 + ln_cy_exp_excl_deprn;

      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 43 Amort C/Y is fetched');
      --To fetch Data for Line 43 Amort -P/Y Adds--
      --ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) IN('LAQ','INT')) AND (lcu_fa_irs4652.fiscal_year_added='PREV') THEN -- Commented for the Defect 3224
          ELSIF (SUBSTR(lcu_fa_irs4652.asset_category,1,3) IN('LAQ','INT')) AND (lcu_fa_irs4652.fiscal_year_added < p_fiscal_year) THEN  --Added for the Defect 3224
             lc_line_item                      := 'Line 43 Amort -P/Y Adds';
             ln_cy_exp_excl_deprn              := lcu_fa_irs4652.ytd_deprn - lcu_fa_irs4652.special_deprn;
             ln_total_44                        :=  ln_total_44 + ln_cy_exp_excl_deprn;

              --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 43 Amort -P/Y Adds is fetched');
          END IF;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Inserting Asset Number'||lcu_fa_irs4652.asset_number);
      --IF lcu_fa_irs4652.fiscal_year_added= 'PREV' THEN -- Commented for the Defect 3224
          IF lcu_fa_irs4652.fiscal_year_added < p_fiscal_year THEN  --Added for the Defect 3224
             INSERT INTO xx_fa_irs4562_temp
             VALUES(lcu_fa_irs4652.company_code
                    ,NULL
		    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,lcu_fa_irs4652.ytd_deprn
                    ,NULL
                    ,NULL
                    ,NULL
                    ,ln_cy_exp_excl_deprn
                    ,lc_line_item
             );
      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Prev year data is fetched');
          ELSIF lcu_fa_irs4652.fiscal_year_added = p_fiscal_year THEN
             INSERT INTO xx_fa_irs4562_temp
             VALUES(lcu_fa_irs4652.company_code
                  ,lcu_fa_irs4652.fiscal_year_added
                  ,lcu_fa_irs4652.pis_date
                  ,lcu_fa_irs4652.deprn_method_code
                  ,lcu_fa_irs4652.asset_category
                  ,lcu_fa_irs4652.asset_number
                  ,lcu_fa_irs4652.asset_id
                  ,lcu_fa_irs4652.adjusted_rate
                  ,lcu_fa_irs4652.bonus_rate
                  ,lcu_fa_irs4652.description
                  ,lcu_fa_irs4652.cost
                  ,lcu_fa_irs4652.life_in_months
                  ,lcu_fa_irs4652.production
                  ,lcu_fa_irs4652.prorate_convention
                  ,lcu_fa_irs4652.ytd_deprn
                  ,DECODE(lc_line_item,'Line 42 Amort - C/Y Adds'
                         ,NULL
                         ,lcu_fa_irs4652.special_deprn) --Added for CR # 439 on OCT 1
                  ,NULL
                  ,ln_basis_cy_deprn
                  ,ln_cy_exp_excl_deprn
                  ,lc_line_item
                );
          --COMMIT;--Commented for CR # 439 on OCT 1
          END IF;
           END LOOP;
           COMMIT;--Added for CR # 439 on OCT 1
       BEGIN


         INSERT INTO xx_fa_irs4562_temp
         VALUES(NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_44
                 ,'Line 44 - Total Amortization'
                );
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 44 - Total Amortization is fetched');
                END;
                BEGIN

         INSERT INTO xx_fa_irs4562_temp
         VALUES(NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_26_cost
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_26
                 ,'Line 26 - All Vehicles including Bonus'
                );
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 26 - All Vehicles including Bonus is fetched');
          lc_error_location := 'SELECT for Line 21 - Total Vehicles Sum';
          END;
        BEGIN


         lc_error_location := 'INSERT for Line 21 Sum';
         INSERT INTO xx_fa_irs4562_temp
         VALUES(NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_21
                 ,'Line 21 - Total Vehicles'
                 );
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 21 - Total Vehicles is fetched');
                  END;
        lc_error_location := 'SELECT for Line 22 - Total Depreciation including Bonus Sum';
        BEGIN

        lc_error_location := 'INSERT for Line 22 - Total Depreciation including Bonus Sum';
         INSERT INTO xx_fa_irs4562_temp
         VALUES(NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_22
                 ,'Line 22 - Total Depreciation including Bonus'
                );
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Line 22 - Total Depreciation including Bonus is fetched');
                END;
         lc_error_location := 'SELECT for Grand Total';
         BEGIN

           lc_error_location := 'INSERT for Grand Total';
         INSERT INTO xx_fa_irs4562_temp
         VALUES(NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,ln_total_22 + ln_total_44
                 ,'Grand Total - Depr + Amort'
                );
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Grand Total - Depr + Amort is fetched');
         EXCEPTION
              WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
              END;
                COMMIT;
         END  XX_FA_IRS4562_PROC;
 END XX_FA_IRS4562_PKG;
 /
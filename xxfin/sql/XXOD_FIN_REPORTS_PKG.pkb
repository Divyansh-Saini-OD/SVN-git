create or replace PACKAGE BODY xxod_fin_reports_pkg AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    IT Convergence/Office Depot                    |
-- +===================================================================+
-- | Name             :  XXOD_FIN_REPORTS_PKG                          |
-- | Description      :  This Package is used by Financial Reports     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-MAY-2007  M.Cahuas         Initial draft version       |
-- +===================================================================+

   FUNCTION ar_ultimate_party_func (p_party_id NUMBER, p_hierarchy VARCHAR2)
     RETURN NUMBER

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    IT Convergence/Office Depot                    |
-- +===================================================================+
-- | Name             :  AR_ULTIMATE_PARTY_FUNC                        |
-- | Description      :  This Function will be used to get the global  |
-- |                    ultimate party corresponding FOR a given party |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-MAY-2007  M.Cahuas         Initial draft version       |
-- |DRAFT 2  31-MAY-2007  M.Cahuas         Change Connect by clause by |
-- |                                       loop sentence               |
-- +===================================================================+
   IS

      l_global_ultimate_party   ar.hz_parties.party_id%TYPE;
      l_root                    NUMBER;
   BEGIN
      l_root := p_party_id;


      LOOP
         BEGIN
            SELECT hr.subject_id
              INTO l_root
              FROM hz_relationships hr, hz_relationship_types hrt
             WHERE hrt.relationship_type = hr.relationship_type
               AND hrt.direction_code = hr.direction_code
               AND hrt.forward_rel_code = hr.relationship_code
               AND hr.direction_code = 'P'
               AND hrt.relationship_type = p_hierarchy
               AND hr.subject_type = 'ORGANIZATION'
               AND hr.object_type = 'ORGANIZATION'
               AND object_id = l_root;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               RETURN (l_root);
	    WHEN TOO_MANY_ROWS THEN
               RETURN (l_root);--Added for defect 1756
         END;
      END LOOP;
   END;
FUNCTION ap_get_business_day (p_date DATE)
      RETURN DATE
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  AP_GET_BUSINESS_DAY                           |
-- | RICE ID          :  R0460
-- | Description      :  This Function will be used to get the         |
-- |                     business day for the settle date              |
-- |                                                                 |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-JUL-2007  Malathi         Initial draft version        |
-- |                      karpagam												  |
-- +===================================================================+
IS
 lc_wkflag  CHAR(1) := 'N';
 ld_hday    DATE;
 ld_wday    DATE;
BEGIN
 ld_wday := p_date;
 WHILE lc_wkflag = 'N' LOOP
  SELECT  GTD.business_day_flag
  INTO lc_wkflag
  FROM gl_transaction_dates GTD
      ,gl_transaction_calendar GTC
  WHERE GTD.transaction_Calendar_id = GTC.transaction_calendar_id
  AND GTC.name='EFT Calendar'
  AND GTD.transaction_date= ld_wday;
  IF lc_wkflag = 'N' THEN
   ld_wday := to_date(ld_wday) + 1;
  ELSE
   BEGIN
    SELECT AP.start_Date
    INTO ld_hday
    FROM ap_other_periods AP
    WHERE AP.period_type='EFT HOLIDAY'
    AND start_Date = ld_wday;
    ld_wday := ld_hday +1;
    lc_wkflag := 'N';
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_wkflag := 'Y';
   END;
  END IF;
 END LOOP;
 RETURN ld_wday;
END;
FUNCTION fa_deprn_reserve_book (
							    p_asset_id  IN NUMBER,
							    p_book_type_code IN VARCHAR2,
							    p_period_counter_low IN NUMBER,
							    p_period_counter_high IN NUMBER
							)
 RETURN NUMBER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  DEPRN_RESERVE_BOOK                            |
-- | RICE ID          :  R0296					                          |
-- | Description      :  This Function will be used to get the         |
-- |                     Depreciation Amount for an asset for          |
-- |                     that period                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								        												  |
-- +===================================================================+
IS
   ln_deprn_reserve  NUMBER;
 BEGIN
	SELECT SUM(nvl(FDD.deprn_reserve,0))
	INTO ln_deprn_reserve
	FROM fa_deprn_detail FDD
	WHERE FDD.asset_id=p_asset_id
	AND FDD.book_type_code=p_book_type_code
	AND FDD.deprn_source_code='D'
	AND FDD.period_counter =
                (SELECT MAX(FDD1.period_counter)
                 FROM fa_deprn_detail FDD1
                 WHERE FDD1.book_type_code=p_book_type_code
		           AND FDD1.asset_id=FDD.asset_id
                 AND FDD1.deprn_source_code='D'
                 AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high);

	RETURN ln_deprn_reserve;
  EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
	WHEN OTHERS THEN
		RETURN 0;
  END;

 FUNCTION fa_cost_book (
                      p_asset_id IN NUMBER,
		                p_book_type_code IN VARCHAR2,
                      p_transaction_type_code IN VARCHAR2,
                      p_period_start_date IN DATE,
                      p_period_end_date IN DATE
                     )
 RETURN NUMBER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  COST_BOOK                                     |
-- | RICE ID          :  R0296	        			                       |
-- | Description      :  This Function will be used to get the         |
-- |                     Cost Amount for an asset for		              |
-- |                     that period for a given book                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								       												  |
-- +===================================================================+
 IS
	  ln_cost NUMBER :=0;
	  lc_transaction_type_code	VARCHAR2(20);
	  lc_debit_credit_flag		VARCHAR2(20);
  BEGIN
    IF(p_transaction_type_code='ACTIVE') THEN
        BEGIN
		SELECT NVL(FB.cost,0)
		INTO ln_cost
		FROM fa_books FB
		WHERE asset_id=p_asset_id
		AND book_type_code=p_book_type_code
		AND transaction_header_id_in = (
			 SELECT MAX(transaction_header_id)
			 FROM fa_transaction_headers FTH
			 WHERE FTH.book_type_code=p_book_type_code
			 AND FTH.asset_id=p_asset_id
			 AND FTH.date_effective between p_period_start_date
			AND p_period_end_date
         AND FTH.transaction_type_code NOT IN ('TRANSFER'        -- Active Assets Problem, Changed by Ganesan Since Fa_books will not have any entry for these transactions,they can be ommited for getting those records so the cost got will be misleading
                                               ,'RECLASS'
                                               ,'TRANSFER IN'
                                               ,'TRANSFER OUT')
			 );

		RETURN ln_cost;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
		WHEN OTHERS THEN
			RETURN 0;
	END;
   ELSE
    BEGIN

		IF (p_transaction_type_code ='REINSTATEMENT' ) Then
			lc_transaction_type_code:='RETIREMENT';
		ELSE
			lc_transaction_type_code:=p_transaction_type_code;
		END IF;

		---Changed by Senthil for 2315 on 21-Jan-2007
		-- For Adjustment , if debit_credit_flag is CR , then adjustment amount need to be negative amount
		--							 if its DR . then adjustment amount will be positive
		--For Retirement , if debit_credit_flag is CR, then its Retirment record in fa_adjustments.
		---			  			     if its DR, then its REINSTATEMENT record in fa_adjustments.
		SELECT nvl(sum(decode(p_transaction_type_code,
						'ADJUSTMENT',decode(fa.debit_credit_flag,'CR',(FA.adjustment_amount*-1),FA.adjustment_amount),
						'RETIREMENT',decode(fa.debit_credit_flag,'DR',(FA.adjustment_amount*-1),FA.adjustment_amount),
						FA.adjustment_amount)),0)
		  INTO ln_cost
		  FROM fa_transaction_headers FTH
			    ,fa_adjustments FA
		 WHERE ((FTH.transaction_header_id=FA.transaction_header_id AND FA.book_type_code=FTH.book_type_code)
                         OR (FTH.transaction_header_id=FA.transaction_header_id))
		   AND FA.asset_id=FTH.asset_id
		  AND FA.book_type_code=p_book_type_code
		  AND FTH.asset_id=p_asset_id
		  AND FA.source_type_code= lc_transaction_type_code
					                         --DECODE(p_transaction_type_code   commented by Senthil on 08-Jan-08 to improve performance for 2315
                                        --        ,'REINSTATEMENT','RETIREMENT'   -- Added 'RETIREMENT' instead of 'ADDITION' by Ganesan
                                        --        ,p_transaction_type_code)
		   AND FA.adjustment_type='COST'
		   AND FA.debit_credit_flag=DECODE(p_transaction_type_code
                                        ,'RECLASS','DR'
                                        ,'TRANSFER','DR'
                                        ,'REINSTATEMENT','DR'          -- This condition is added by Ganesan for handling the REINSTATEMENT transaction
                                        --,'RETIREMENT','CR'             -- This condition is added by Ganesan
                                        ,FA.debit_credit_flag)
		   AND FTH.date_effective between p_period_start_date
         AND p_period_end_date;
           --- Commented to take all the transactions made in the book by Ganesan
	       /*AND FA.transaction_header_id = (SELECT MAX(transaction_header_id)       This Condition is to get the latest transaction happened to the asset for the given transaction Added by Ganesan
                                      FROM fa_transaction_headers FTH1
                                      WHERE FTH1.book_type_code=p_book_type_code
                                      AND FTH1.asset_id=p_asset_id
                                      AND (FTH1.transaction_type_code = DECODE(p_transaction_type_code
                                                                               ,'RETIREMENT','FULL RETIREMENT'
                                                                               ,p_transaction_type_code)
                                      OR FTH1.transaction_type_code = DECODE(p_transaction_type_code
                                                                             ,'RETIREMENT','PARTIAL RETIREMENT'
                                                                             ,p_transaction_type_code))
                                      AND to_date(FTH1.date_effective,'DD-MON-YY') between p_period_start_date
                                      AND p_period_end_date);*/


                /*SELECT NVL(SUM(FA.adjustment_amount),0)
		INTO ln_cost
		FROM fa_transaction_headers FTH
			   ,fa_adjustments FA
		WHERE FTH.asset_id=p_asset_id
		AND FTH.book_type_code=p_book_type_code
                AND FTH.book_type_code=FA.book_type_code
		AND FA.asset_id=FTH.asset_id
                AND FTH.transaction_header_id=FA.transaction_header_id
                AND FA.source_type_code=
			DECODE(p_transaction_type_code,'REINSTATEMENT','ADDITION',p_transaction_type_code)
                AND FA.adjustment_type='COST'
		AND FA.debit_credit_flag=DECODE(p_transaction_type_code,'RECLASS','DR','TRANSFER','DR',FA.debit_credit_flag)
                AND to_date(FTH.date_effective,'DD-MON-YY') between p_period_start_date
                AND p_period_end_date;*/

		RETURN ln_cost;
--END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
		WHEN OTHERS THEN
			RETURN 0;
	END;
     END IF;
 END fa_cost_book;

 FUNCTION get_cost_for_transaction (
                      p_asset_id IN NUMBER,
                      p_book_type_code IN VARCHAR2,
                      p_transaction_type_code IN VARCHAR2,
                      p_period_start_date IN DATE,
                      p_period_end_date IN DATE,
		      p_transaction_header_id IN NUMBER
                     )
 RETURN NUMBER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  get_cost_for_transaction                                     |
-- | RICE ID          :  R0296	        			                       |
-- | Description      :  This Function will be used to get the         |
-- |                     Transfer / Addition Cost Amount for an asset for		              |
-- |                     that period for a given book                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								       												  |
-- +===================================================================+
 IS
	  ln_cost NUMBER :=0;
	  lc_transaction_type_code	VARCHAR2(20);
	  lc_debit_credit_flag		VARCHAR2(20);
  BEGIN
	
	IF p_transaction_type_code = 'TRANSFER' Then
		BEGIN	
			SELECT NVL(adjustment_amount,0)
			INTO ln_cost
			  FROM fa_transaction_headers FTH
				    ,fa_adjustments FA
			 WHERE ((FTH.transaction_header_id=FA.transaction_header_id AND FA.book_type_code=FTH.book_type_code)
				 OR (FTH.transaction_header_id=FA.transaction_header_id))
			   AND FA.asset_id=FTH.asset_id
			  AND FA.book_type_code=p_book_type_code
			  AND FTH.asset_id=p_asset_id
			  AND FA.source_type_code = 'TRANSFER'
			  AND FA.adjustment_type='COST'
			  AND FA.debit_credit_flag='DR'
			  AND FA.transaction_header_id=p_transaction_header_id
			  AND FTH.date_effective between p_period_start_date
			  AND p_period_end_date;
			  
			  RETURN ln_cost;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN 0;
			WHEN OTHERS THEN
				RETURN 0;
		END;
	ELSE
		--For Addition Cost is always the first transaction cost 
		BEGIN
			SELECT fb.cost 
			INTO ln_cost
			FROM fa_books FB
			WHERE FB.asset_id=p_asset_id
			AND FB.book_type_code = p_book_type_code 
			AND FB.transaction_header_id_in = 
				( SELECT MIN(transaction_header_id) 
				   FROM fa_transaction_headers
				   WHERE book_type_code=p_book_type_code			   
				   AND asset_id=p_asset_id);
			
			RETURN ln_cost;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN 0;
			WHEN OTHERS THEN
				RETURN 0;
		END;
	END IF;		
	
	RETURN ln_cost;
END;


FUNCTION fa_deprn_amount(
							    p_asset_id  IN NUMBER,
							    p_book_type_code IN VARCHAR2,
							    p_period_counter_low IN NUMBER,
							    p_period_counter_high IN NUMBER
							)
 RETURN NUMBER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  DEPRN_RESERVE_BOOK                            |
-- | RICE ID          :  R0296					              				  |
-- | Description      :  This Function will be used to get the         |
-- |                     Depreciation Amount for an asset for          |
-- |                     that period                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								         											  |
-- +===================================================================+
IS
   ln_deprn_reserve  NUMBER;
 BEGIN
	SELECT SUM(nvl(FDD.deprn_amount,0))
	INTO ln_deprn_reserve
	FROM fa_deprn_detail FDD
	WHERE FDD.asset_id=p_asset_id
	AND FDD.book_type_code=p_book_type_code
	AND FDD.deprn_source_code='D'
	AND FDD.period_counter =
                (SELECT MAX(FDD1.period_counter)
                 FROM fa_deprn_detail FDD1
                 WHERE FDD1.book_type_code=p_book_type_code
		           AND FDD1.asset_id=FDD.asset_id
                 AND FDD1.deprn_source_code='D'
                 AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high);

	RETURN ln_deprn_reserve;
  EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
	WHEN OTHERS THEN
		RETURN 0;
  END;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  FA_DEPRN_AMOUNTS                              |
-- | RICE ID          :  R0296					              				  |
-- | Description      :  This Procedure will be used to get the        |
-- |                     Depreciation Amount and accumulated           |
-- |                     depreciation for an asset for that period     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 20-NOV-2007  Ganesan.JV      Initial draft version        |
-- |								         											  |
-- +===================================================================+
PROCEDURE FA_DEPRN_AMOUNTS (
			     p_asset_id  IN NUMBER,
			     p_book_type_code IN VARCHAR2,
			     p_period_counter_low IN NUMBER,
			     p_period_counter_high IN NUMBER,
			     x_deprn_amount OUT NUMBER,
			     x_deprn_reserve OUT NUMBER
			    )
AS
	ln_deprn_reserve  NUMBER;
	ln_deprn_amount NUMBER;
   BEGIN

	--Added the Sum by Ganesan on 23-01-2008 to accumulate the depreciation amount for multiple distribution.
	SELECT SUM(nvl(FDD.deprn_reserve,0))
	       ,SUM(nvl(FDD.deprn_amount,0))
	INTO ln_deprn_reserve
	     ,ln_deprn_amount
	FROM fa_deprn_detail FDD
	WHERE FDD.asset_id=p_asset_id
	AND FDD.book_type_code=p_book_type_code
	AND FDD.deprn_source_code='D'
	AND FDD.period_counter =
                (SELECT MAX(FDD1.period_counter)
                 FROM fa_deprn_detail FDD1
                 WHERE FDD1.book_type_code=p_book_type_code
                 AND FDD1.deprn_source_code='D'
		 AND FDD1.asset_id=FDD.asset_id
                 AND FDD1.period_counter BETWEEN p_period_counter_low and p_period_counter_high)
        GROUP BY FDD.asset_id;
	x_deprn_reserve := ln_deprn_reserve;
	x_deprn_amount := ln_deprn_amount;

	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		x_deprn_amount :=  0;
                x_deprn_reserve := 0;
	WHEN OTHERS THEN
		x_deprn_reserve := 0;
                x_deprn_amount :=  0;
  END FA_DEPRN_AMOUNTS;

END xxod_fin_reports_pkg;
/

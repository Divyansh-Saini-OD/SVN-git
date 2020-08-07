CREATE OR REPLACE VIEW XXOD_FA_PROPERTY_TAX_REPORT_V AS 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Oracle/Office Depot                          |
-- +===================================================================+
-- | Name  : XXOD_FA_PROPERTY_TAX_REPORT_V                             |
-- | Description: Custom view used for extracting active,transfer and  |
-- |              retired assets.                                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       22-APR-2007  Sudha Seetharaman Initial version           |
-- |1.1       27-APR-2007  Sudha Seetharaman Included TRANSFER         | 
-- |                                         transaction type code     |  
-- |1.2       07-MAY-2007  Sudha Seetharaman Added ap_invoices table   |
-- |                                         for invoice number        |
-- |1.3	      19-AUG-2007  Sudha Seetharaman Changed the cost column   |
-- |1.4	      10-NOV-2009  Ganesan JV        Changed to pick original  |
-- |                                        cost for the defect 3227   |
-- +===================================================================+|
  (SELECT
 'active' report_type
 ,FB.book_type_code book
 ,GCC.segment1 company
 ,GCC.segment4 location
 ,GCC.segment2 cost_center
 ,GCC.segment6 lob
 ,FA.asset_number asset_number
 ,FA.attribute6 legacy_id    
 ,FB. Date_effective effective_date
 ,FA.attribute8 hist_acq_date
 ,FB.date_placed_in_service date_placed_in_service
 ,FC.segment1 major
 ,sysdate retire_date
 ,FC.segment2 minor
 ,FA.description description
-- ,FB.cost/FA.current_units * FDH.units_assigned cost   -- Commented for defect 3227
 ,FB.original_cost/FA.current_units * FDH.units_assigned cost   -- Changed to Original Cost from Cost for defect 3227
 ,FA.attribute7/FA.current_units * FDH.units_assigned hist_cost
 ,FL.location_id location_no
 ,'trans_type' trans_type
 ,FL.segment6 zip  --Changed by Sudha for the defect 2447
 ,FL.segment4 city
 ,FL.segment3 county
 ,FL.segment2 state
 ,FL.segment5 building          --Changed by Sudha for the defect 2447
 ,AI.invoice_num invoice_number
 ,AI.voucher_num voucher_number
 ,'pn' period_name
 ,FB.date_effective  book_effective
 ,FB.date_ineffective book_ineffective
 ,FDH.date_effective  dist_effective
 ,FDH.date_ineffective dist_ineffective
 ,FB.transaction_header_id_in books_header_id
,FA.asset_id asset_id
,sysdate trans_effective_date
 FROM
 gl_code_combinations GCC
,fa_additions FA
,fa_books FB
,fa_distribution_history FDH
,fa_locations FL
,fa_asset_invoices FAI
,fa_categories FC
,ap_invoices AI
,fa_asset_history FAH
WHERE
 FA.asset_id=FB.asset_id
 AND FB.period_counter_fully_retired IS NULL
 AND FDH.code_combination_id=GCC.code_combination_id
 AND FDH.asset_id=FA.asset_id
 AND FDH.book_type_code=FB.book_type_code
 AND FDH.location_id=FL.location_id
 AND FAI.asset_id(+)=FB.asset_id
 AND FAH.asset_id = FA.asset_id
 AND FB.transaction_header_id_in >= FAH.transaction_header_id_in
 AND FB.transaction_header_id_in < NVL(FAH.transaction_header_id_out,
					FB.transaction_header_id_in + 1)
 AND FAI.invoice_id=AI.invoice_id(+)
 AND FC.category_id=FAH.category_id
 AND FC.category_type <>'LEASE'
 AND FDH.date_ineffective IS NULL           -- Added by Ganesan for defect 15442
 AND FB.date_ineffective IS NULL             -- Added by Ganesan for defect 15442
UNION ALL
SELECT
'disposal' report_type
 ,FB.book_type_code book 
 ,GCC.segment1 company
 ,GCC.segment4 location
 ,GCC.segment2 cost_center
 ,GCC.segment6 lob
 ,FA.asset_number asset_number
 ,FA.attribute6 legacy_id   
 ,FB.date_effective effective_date
 ,FA.attribute8 hist_acq_date
 ,FB.date_placed_in_service date_placed_in_service
 ,FC.segment1 major
 ,FR.date_retired retire_date
 ,'minor' minor
 ,FA.description      description
 --,FR.cost_retired/FA.current_units * FDH.units_assigned cost  Commented for defect 3227
 ,FB.original_cost/FA.current_units * FDH.units_assigned cost -- added orginal_cost instead of cost for defect 3227
 ,FA.attribute7/FA.current_units * FDH.units_assigned hist_cost
 ,1 location_no
 ,FTH.transaction_type_code trans_type
 ,'building' building
 ,'city' city
 ,'county' county
 ,FL.segment2 state
 ,'zip' zip
 ,'invoice'  invoice_number
 ,'voucher' voucher_number
 , FDP.period_name period_name
 ,FB.date_effective  book_effective
 ,FB.date_ineffective book_ineffective
 ,FDH.date_effective  dist_effective
 ,FDH.date_ineffective dist_ineffective
 ,FB.transaction_header_id_in books_header_id
 ,FA.asset_id asset_id
 ,FTH.date_effective trans_effective_date
FROM
 fa_deprn_periods FDP
,fa_asset_history FAH
,gl_code_combinations GCC
,fa_additions FA
,fa_books FB
,fa_distribution_history FDH
,fa_locations FL
,fa_retirements FR
,fa_categories FC
,fa_transaction_headers FTH
WHERE
 FA.asset_id=FB.asset_id 
 AND FB.book_type_code=FDP.book_type_code
 AND FTH.date_effective >=FDP.period_open_date
 AND FTH.date_effective <= NVL(FDP.period_close_date,sysdate)
 AND FC.category_id =FAH.category_id
 AND FAH.asset_id = FA.asset_id
 AND FTH.transaction_header_id >= FAH.transaction_header_id_in
 AND FTH.transaction_header_id < NVL(FAH.transaction_header_id_out,
					FTH.transaction_header_id + 1)
 AND FDH.code_combination_id=GCC.code_combination_id
 AND FDH.asset_id=FA.asset_id
 AND FDH.book_type_code=FB.book_type_code
 AND FDH.location_id=FL.location_id
 AND FC.CATEGORY_ID=FA.ASSET_CATEGORY_ID
 AND FR.asset_id=FA.asset_id
 AND FR.book_type_code=FB.book_type_code
 AND FTH.asset_id=FA.asset_id
 AND FTH.book_type_code=FB.book_type_code
 AND FTH.transaction_type_code in ('FULL RETIREMENT','PARTIAL RETIREMENT')
 AND FTH.transaction_header_id=FR.transaction_header_id_in  
 AND FTH.transaction_header_id=FB.transaction_header_id_in
 AND FDP.book_type_code =FB.book_type_code
 AND (FDH.retirement_id =FR.retirement_id or 
         (FR.date_effective >= FDH.date_effective       AND
          FR.date_effective <= NVL(FDH.date_ineffective,sysdate)
    AND FR.UNITS IS NULL))
 AND FR.status in ('PROCESSED','PENDING')
 AND FC.category_type <>'LEASE'
UNION ALL
SELECT    
 'transfer' report_type
 ,FB.book_type_code book
 ,GCC.segment1 company
 ,GCC.segment4 location
 ,GCC.segment2 cost_center
 ,GCC.segment6 lob
 ,FA.asset_number asset_number
 ,FA.attribute6 legacy_id   
 ,FB.date_effective effective_date
 ,FA.attribute8 hist_acq_date
 ,FB.date_placed_in_service date_placed_in_service
 ,FC.segment1 major
 ,FTH.transaction_date_entered retire_date
 ,FC.segment2 minor
 ,FA.description description
 ,DECODE(FTH.TRANSACTION_HEADER_ID,
--		FDH.TRANSACTION_HEADER_ID_IN,TRUNC((FB.cost /FA.current_units * FDH.units_assigned),2) , -- Commented for defect 3227
		FDH.TRANSACTION_HEADER_ID_IN,TRUNC((FB.original_cost /FA.current_units * FDH.units_assigned),2) , -- Changed to Original Cost for defect 3227
--		FDH.TRANSACTION_HEADER_ID_OUT,TRUNC ((FB.cost /FA.current_units *-1* FDH.units_assigned),2) )    COST Commented for defect 3227
		FDH.TRANSACTION_HEADER_ID_OUT,TRUNC ((FB.original_cost /FA.current_units *-1* FDH.units_assigned),2) )    COST -- Changed to Original Cost for defect 3227
 ,DECODE(FTH.TRANSACTION_HEADER_ID,
		FDH.TRANSACTION_HEADER_ID_IN,TRUNC((FA.attribute7 /FA.current_units * FDH.units_assigned),2) ,
		FDH.TRANSACTION_HEADER_ID_OUT,TRUNC ((FA.attribute7 /FA.current_units *-1* FDH.units_assigned),2) ) 
 hist_cost
 ,1 location_no
 ,DECODE(FTH.TRANSACTION_HEADER_ID,
		FDH.TRANSACTION_HEADER_ID_IN,'TRANSFER IN',
		FDH.TRANSACTION_HEADER_ID_OUT, 'TRANSFER OUT')   
           trans_type
 ,'building' building
 ,FL.segment1||'.'||
  FL.segment2||'.'||
  FL.segment3||'.'||
  FL.segment4||'.'||
  FL.segment5||'.'||
  FL.segment6 city
 ,'county' county
 ,FL.segment2 state
 ,'zip' zip
 ,'invoice'  invoice_number
 ,'voucher' voucher_number
 ,FDP.period_name period_name
 ,FB.date_effective  book_effective
 ,FB.date_ineffective book_ineffective
 ,FDH.date_effective  dist_effective
 ,FDH.date_ineffective dist_ineffective
 ,FB.transaction_header_id_in books_header_id
 ,FA.asset_id asset_id
 ,FTH.date_effective trans_effective_date
FROM
  gl_code_combinations GCC
 ,fa_additions FA
 ,fa_transaction_headers FTH
 ,fa_books FB
 ,fa_locations FL
 ,fa_distribution_history FDH
 ,fa_categories FC
 ,fa_asset_history FAH
 ,fa_deprn_periods FDP
WHERE
 FA.asset_id=FB.asset_id
 AND FDP.book_type_code =FB.book_type_code
 AND FTH.date_effective >=FDP.period_open_date
 AND FTH.date_effective <= NVL(FDP.period_close_date,sysdate)
 AND FDH.code_combination_id=GCC.code_combination_id
 AND FDH.asset_id=FA.asset_id
 AND FAH.asset_id = FA.asset_id
 AND FDH.book_type_code=FB.book_type_code
 AND FDH.location_id=FL.location_id
 AND FTH.asset_id=FA.asset_id
 AND FTH.book_type_code=fb.book_type_code
 AND FTH.transaction_type_code  = 'TRANSFER'
 AND FTH.transaction_header_id >= FAH.transaction_header_id_in
 AND FTH.transaction_header_id < NVL(FAH.transaction_header_id_out,
					FTH.transaction_header_id + 1)
 AND FC.category_id=FAH.category_id
 AND     (FTH.TRANSACTION_HEADER_ID =  FDH.TRANSACTION_HEADER_ID_IN	OR
	     FTH.TRANSACTION_HEADER_ID   =  FDH.TRANSACTION_HEADER_ID_OUT)
 AND FC.category_type <>'LEASE'
)
/

 
-- This should update 1 row
-- Defect # 14866
UPDATE xx_ce_999_interface
SET trx_type = 'PAYMENT'
, match_amount = match_amount *-1 --825.68
WHERE trx_id = 2915;
COMMIT;
/
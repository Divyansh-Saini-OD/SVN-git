-- This should update 4 rows
-- Defect # 14866
UPDATE xx_ce_999_interface
SET trx_type = 'PAYMENT'
, amount = amount *-1
WHERE trx_id in (9044,13065,13066,13072);
COMMIT;
/
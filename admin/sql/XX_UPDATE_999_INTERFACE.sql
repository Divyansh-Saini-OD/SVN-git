--This should update 1 row.
--Defect # 14866

UPDATE xx_ce_999_interface
SET amount = 825.68,
match_amount = 825.68
WHERE trx_id = 2915;
COMMIT;
/
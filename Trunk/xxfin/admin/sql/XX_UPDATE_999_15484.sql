--- This Statement should update 1 line.
--- Defect # 15484

UPDATE xx_ce_ajb999
SET store_num = 005125
WHERE store_num = 008888;
COMMIT;
/

--- This Query should update 8869 rows
 
UPDATE ce_statement_lines
SET attribute1 = NULL
  WHERE attribute1 = 'Y';
  
COMMIT;
/

UPDATE apps.xx_om_legacy_deposits
SET    I1025_status   =   'VOID'
      ,I1025_message  =    I1025_message||'Voided to Implement CR 722'
WHERE  I1025_message LIKE '%I1025 cannot process deposit reversals for multi-tender deposits%';
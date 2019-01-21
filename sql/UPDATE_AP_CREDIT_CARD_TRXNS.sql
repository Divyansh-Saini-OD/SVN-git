--Script to Update the Credit card transactions
UPDATE ap.ap_credit_card_trxns_all acct
SET CATEGORY                 = NULL
WHERE acct.report_header_id IS NULL
AND acct.category           IS NOT NULL
AND EXISTS
  (SELECT 1
  FROM apps.ap_cards_all aca
  WHERE aca.card_id  = acct.card_id
  AND aca.employee_id=2660197
  );
COMMIT;

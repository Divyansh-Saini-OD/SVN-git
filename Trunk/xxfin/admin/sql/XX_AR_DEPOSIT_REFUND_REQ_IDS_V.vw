CREATE OR REPLACE VIEW APPS.XX_AR_DEPOSIT_REFUND_REQ_IDS_V AS
  SELECT payment_type,
         request_id,
         request_date,
         payment_count
    FROM (SELECT 'DEPOSIT' payment_type,
                 xold.request_id,
                 TRUNC(xold.creation_date) request_date,
                 COUNT(1) payment_count
            FROM xx_om_legacy_deposits xold
           --WHERE xold.process_code IN ('P','E')
           GROUP BY xold.request_id,
                 TRUNC(xold.creation_date)
          UNION
          SELECT 'REFUND' payment_type,
                 xort.request_id,
                 TRUNC(xort.creation_date) request_date,
                 COUNT(1) payment_count
            FROM xx_om_return_tenders_all xort,
                 oe_order_headers_all ooh
           WHERE xort.header_id = ooh.header_id
             --AND xort.process_code IN ('P','E')
           GROUP BY xort.request_id,
                 TRUNC(xort.creation_date) )
  ORDER BY request_id;
/ 
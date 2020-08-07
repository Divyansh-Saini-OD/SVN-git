CREATE OR REPLACE VIEW APPS.XX_AR_DEPOSIT_REFUND_ORDERS_V AS
  SELECT payment_type,
         orig_sys_document_ref,
         payment_date,
         order_number,
         process_code,
         CASE process_code
           WHEN 'P' THEN 'Pending'
           WHEN 'E' THEN 'Errored'
           WHEN 'C' THEN 'Completed'
           WHEN 'X' THEN 'Deleted'
           WHEN 'H' THEN 'On Hold'
           ELSE 'Undefined' END process_status,
         payment_count
    FROM (SELECT 'DEPOSIT' payment_type,
                 xold.orig_sys_document_ref,
                 TRUNC(xold.creation_date) payment_date,
                 TO_NUMBER(NULL) order_number,
                 xold.process_code,
                 COUNT(1) payment_count
            FROM xx_om_legacy_deposits xold
           --WHERE xold.process_code IN ('P','E')
           GROUP BY xold.orig_sys_document_ref,
                 TRUNC(xold.creation_date),
                 xold.process_code
          UNION
          SELECT 'REFUND' payment_type,
                 xort.orig_sys_document_ref,
                 TRUNC(xort.creation_date) payment_date,
                 ooh.order_number,
                 xort.process_code,
                 COUNT(1) payment_count
            FROM xx_om_return_tenders_all xort,
                 oe_order_headers_all ooh
           WHERE xort.header_id = ooh.header_id
             --AND xort.process_code IN ('P','E')
           GROUP BY xort.orig_sys_document_ref,
                 TRUNC(xort.creation_date),
                 ooh.order_number,
                 xort.process_code )
  ORDER BY orig_sys_document_ref;
/ 
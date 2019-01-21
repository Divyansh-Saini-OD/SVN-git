-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Providge Consulting                           |
-- +=====================================================================+
-- |                                                                     |
-- | Description :E0286 OBJECTS USED BY REPRINT AND SPECIAL HANDLING     |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       03-JUN-2008   Balaguru Seshadri,   Created Base version    |
-- |                        Providge Consulting                          |
-- |======   ==========     =============        ======================= |
-- |1.0       03-JUN-2008   Balaguru Seshadri,   Created Base version    |
-- |                        Providge Consulting                          |
-- |1.1       04-JAN-2016   Suresh Naragam       Removed Schema References |
-- |                                              as part of R12.2       |
-- |                                                                     |
-- +=====================================================================+
CREATE OR REPLACE VIEW xx_ar_cbi_rprn_trx AS
SELECT * FROM xx_ar_cbi_rprn_trx_all
WHERE NVL (org_id,
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                    ' ', NULL,
                                    SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           ),
                 -99
                )
           ) =
          NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                  ' ', NULL,
                                  SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                 )
                         ),
               -99
              )
/ 
CREATE OR REPLACE VIEW xx_ar_cbi_rprn_trx_lines AS
SELECT * FROM xx_ar_cbi_rprn_trx_lines_all
WHERE NVL (org_id,
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                    ' ', NULL,
                                    SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           ),
                 -99
                )
           ) =
          NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                  ' ', NULL,
                                  SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                 )
                         ),
               -99
              )
/ 
CREATE OR REPLACE VIEW xx_ar_cbi_rprn_trx_totals AS
SELECT * FROM xx_ar_cbi_rprn_trx_totals_all
WHERE NVL (org_id,
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                    ' ', NULL,
                                    SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           ),
                 -99
                )
           ) =
          NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                  ' ', NULL,
                                  SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                 )
                         ),
               -99
              )
/
CREATE OR REPLACE VIEW xx_ar_cbi_rprn_rows AS
SELECT * FROM xx_ar_cbi_rprn_rows_all
WHERE NVL (org_id,
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                    ' ', NULL,
                                    SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           ),
                 -99
                )
           ) =
          NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                  ' ', NULL,
                                  SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                 )
                         ),
               -99
              )
/
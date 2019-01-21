CREATE OR REPLACE VIEW XX_AR_GEN_BILL_TEMP AS
SELECT * FROM XX_AR_GEN_BILL_TEMP_ALL
WHERE NVL (ORG_ID,
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
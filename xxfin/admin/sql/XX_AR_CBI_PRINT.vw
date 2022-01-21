---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+
CREATE OR REPLACE VIEW XX_AR_CBI_PRINT AS
SELECT * FROM XX_AR_CBI_PRINT_ALL
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
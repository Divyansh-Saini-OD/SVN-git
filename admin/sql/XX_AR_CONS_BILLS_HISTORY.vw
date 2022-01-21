SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating VIEW XX_AR_CONS_BILLS_HISTORY

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_CONS_BILLS_HISTORY                                            |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             10-FEB-2009       Sambasiva Reddy D  Initial Version                                |
---|                                                                                                        |
---+========================================================================================================+

CREATE OR REPLACE VIEW XX_AR_CONS_BILLS_HISTORY AS
SELECT * FROM XX_AR_CONS_BILLS_HISTORY_ALL
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
              );

SHOW ERROR
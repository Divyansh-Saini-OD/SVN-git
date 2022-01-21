---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_od_ardeft_FTBCHICRET.ctl                                         |
---|                                                                                                        |
---|    Description             :       The control file loads the data into the temporary table            |
---|          XX_AR_PAYMENTS_INTERFACE                                                                      |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             14-AUG-2007       Shiva Rao         Initial Version                                 |
---|    1.1             10-JUL-2008       Brian J Looman    Separated to have one .ctl file per BAI file    |
---|    1.2             24-NOV-09         RamyaPriya M      Modified for the Defect #1614                   |
---|    1.3             20-MAY-2011       Deepti S          Modified for CR #872                            |
---|                                                                                                        |
---+========================================================================================================+        


LOAD DATA
APPEND

-- Type 1 - Transmission Header

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '1'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 DESTINATION_ACCOUNT    POSITION(03:13) CHAR,
 ORIGINATION      POSITION(14:23) CHAR, 
 DEPOSIT_DATE      POSITION(24:29) DATE 'RRMMDD' NULLIF DEPOSIT_DATE=BLANKS,
 DEPOSIT_TIME      POSITION(30:33) CHAR
          NULLIF DEPOSIT_TIME=BLANKS)

-- Type 2 - Service Header

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '2'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE                    POSITION(01:01) CHAR,
 DESTINATION_ACCOUNT            POSITION(02:12) CHAR,
 ORIGINATION                    POSITION(13:22) CHAR,
 ATTRIBUTE1                     POSITION(23:32) CHAR,
 ATTRIBUTE2                     POSITION(33:35) CHAR,
 ATTRIBUTE3                     POSITION(36:38) CHAR,
 ATTRIBUTE4                     POSITION(39:42) CHAR,
 ATTRIBUTE5                     POSITION(43:43) CHAR )

-- Type 5 - Lockbox Header

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '5'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 BATCH_NAME      POSITION(02:06) CHAR,
 LOCKBOX_NUMBER      POSITION(08:14) CHAR,
 DEPOSIT_DATE      POSITION(15:20) DATE 'RRMMDD' 
        NULLIF DEPOSIT_DATE=BLANKS,
 DESTINATION_ACCOUNT    POSITION(21:31) CHAR,
 ORIGINATION      POSITION(32:41) CHAR )

-- Type 6 - Receipt

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '6'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 BATCH_NAME      POSITION(02:06) CHAR,
 ITEM_NUMBER      POSITION(07:09) CHAR,
 REMITTANCE_AMOUNT    POSITION(10:19) CHAR,
 TRANSIT_ROUTING_NUMBER   POSITION(20:28) CHAR,
 ACCOUNT      POSITION(29:48) CHAR,
 CHECK_NUMBER      POSITION(49:63) CHAR,
 CUSTOMER_NUMBER    POSITION(64:75) CHAR,
 SENDING_COMPANY_ID POSITION(76:85) CHAR --Added for CR# 872
)




-- Type 4 - Overflow

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '4'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 BATCH_NAME      POSITION(02:06) CHAR,
 ITEM_NUMBER      POSITION(07:09) CHAR,
 OVERFLOW_SEQUENCE    POSITION(10:14) CHAR,
 OVERFLOW_INDICATOR    POSITION(15:15) CHAR,
-- INVOICE1      POSITION(16:27) CHAR,                         -- Commented for the Defect #1614
 INVOICE1       POSITION(16:27) CHAR "LTRIM(:INVOICE1,'0')",   -- Added for the Defect #1614
 AMOUNT_APPLIED1    POSITION(28:37) CHAR,
-- INVOICE2      POSITION(38:49) CHAR,                         -- Commented for the Defect #1614
 INVOICE2       POSITION(38:49) CHAR "LTRIM(:INVOICE2,'0')",   -- Added for the Defect #1614
 AMOUNT_APPLIED2    POSITION(50:59) CHAR,
-- INVOICE3      POSITION(60:71) CHAR,                         -- Commented for the Defect #1614
 INVOICE3       POSITION(60:71) CHAR "LTRIM(:INVOICE3,'0')",   -- Added for the Defect #1614
 AMOUNT_APPLIED3    POSITION(72:81) CHAR
 )

-- Type 7 - Batch Trailer

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '7'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 BATCH_NAME      POSITION(02:06) CHAR,
 LOCKBOX_NUMBER      POSITION(08:14) CHAR,
 DEPOSIT_DATE      POSITION(15:20) DATE 'RRMMDD'
        NULLIF DEPOSIT_DATE=BLANKS,
 BATCH_RECORD_COUNT    POSITION(21:26) CHAR,
 BATCH_AMOUNT      POSITION(27:38) CHAR )

-- Type 8 - Lockbox Trailer

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '8'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 LOCKBOX_NUMBER      POSITION(08:14) CHAR,
 DEPOSIT_DATE      POSITION(15:20) DATE 'RRMMDD'
        NULLIF DEPOSIT_DATE=BLANKS,
 LOCKBOX_RECORD_COUNT    POSITION(21:26) CHAR,
 LOCKBOX_AMOUNT      POSITION(27:38) CHAR )

-- Type 9 - Transmission Trailer

INTO TABLE XX_AR_PAYMENTS_INTERFACE
WHEN RECORD_TYPE = '9'
(STATUS        CONSTANT 'AR_PLB_NEW_RECORD',
 PROCESS_NUM      CONSTANT 'RCT-BATCH',
 FILE_NAME        CONSTANT 'FTBCHICRET',
 RECORD_TYPE      POSITION(01:01) CHAR,
 TRANSMISSION_RECORD_COUNT  POSITION(02:07) CHAR,
 TRANSMISSION_AMOUNT    POSITION(08:19) CHAR )




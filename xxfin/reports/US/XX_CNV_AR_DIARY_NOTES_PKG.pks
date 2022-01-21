CREATE OR REPLACE PACKAGE APPS.XX_CNV_AR_DIARY_NOTES_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Providge Consulting                        |
-- +===================================================================+
-- |        Name : AR Collector Diary Notes conversion (FIN-1134)      |
-- | Description : To convert the Customer Diary Notes                 |
-- |               from MARS to ORACLE AR                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       23-JAN-2007  Terry Banks,         Initial version        |
-- |                       Providge Consulting                         |
-- |          21-MAR-2007  Terry Banks          Added CNV_ in name     |
-- +===================================================================+
-- |        Name : CONVERT_NOTES                                       |
-- | Description : Convert MARS Customer Diary Notes into Oracle       |
-- |               Collection Notes in the JTF schema                  |
-- |  Parameters : x_error_buff, x_ret_code,                           |
-- |               p_cust_start, p_cust_end                            |
-- +===================================================================+
-- +===================================================================+
    PROCEDURE CONVERT_NOTES_MASTER(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_process_name        IN VARCHAR2);
    PROCEDURE CONVERT_NOTES_CHILD(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_process_name        IN VARCHAR2
       ,p_validate_only_flag  IN VARCHAR2
       ,p_batch_id            in VARCHAR2);
END XX_CNV_AR_DIARY_NOTES_PKG;
/

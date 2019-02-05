CREATE OR REPLACE PACKAGE XX_INV_PROCESS_DUMMY_ITEMS 
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                Oracle NAIO Consulting Organization                      |
-- +=========================================================================+
-- | Name        :  XX_INV_PROCESS_DUMMY_ITEMS.pks                           |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Ver   Date        Author               Remarks                           |
-- |===== =========== ==================== ==================================|
-- |1.0   12-DEC-2007 GANESH B NADAKUDHITI Initial  version                  |
-- +=========================================================================+
IS

PROCEDURE main(p_errbuf        OUT VARCHAR2 ,
               p_retcode       OUT VARCHAR2 ,
               p_master_org_id  IN NUMBER   ,
               p_item           IN VARCHAR2 ,
	       p_start_rec      IN NUMBER   ,
	       p_end_rec        IN NUMBER   ,
               p_user_name      IN VARCHAR2 ,
               p_resp_key       IN VARCHAR2
              );
END ;
/

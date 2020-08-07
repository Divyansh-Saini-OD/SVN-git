CREATE OR REPLACE
PACKAGE XX_BKPTBL_DEL_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                    	    |
-- |                  Office Depot                                         	    |
-- +=================================================================================+
-- | Name  	   :RICE ID:E7028 XX_BKPTBL_DEL_PKG (XX_BKPTBL_DEL_PKG.pks)                      |
-- | Description   :OD: Backup Tables Deletion Program 	                    |
-- |                                  	    				            |
-- |Change Record:                                                         	    |
-- |===============                                                        	    |
-- |Version Date        Author            Remarks                 Description       |
-- |======= ========   ===========       ===========             ===============    |
-- |1.0     10-MAR-17  Pritdarshini Jena Initial draft version   Defect # 4082      |
-- |                                                             Automation of      |
-- |                                                             Dropping the       |
-- |                                                             Backup Tables      |
-- |                                                             created for        |
-- |                                                             Standard and Normal|
-- |                                                             changes as Part    |
-- |                                                             of Backup within   |
-- |                                                            an agreed time frame|
-- +=================================================================================+
  PROCEDURE XX_BKPTBL_DEL_PROC(
      P_DATE IN VARCHAR2,
      ERRBUFF OUT VARCHAR2,
      RETCODE OUT VARCHAR2);
END XX_BKPTBL_DEL_PKG;
/
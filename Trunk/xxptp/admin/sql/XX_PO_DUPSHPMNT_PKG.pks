create or replace package XX_PO_DUPSHPMNT_PKG
AS
-- +=======================================================================================+
-- |                  Office Depot - Project Simplify                                      |
-- +=======================================================================================+
-- | Name :XX_PO_DUPSHPMNT_PKG.pks                                                         |
-- | Description : Created to clear PO duplicate shipments for defect 20551                |
-- | Rice : E3069                                                                          |
-- |                                                                                       |
-- |                                                                                       |
-- |                                                                                       |
-- |Change Record:                                                                         |
-- |===============                                                                        |
-- |Version   Date         Author               Remarks                                    |
-- |=======   ==========   =============        ===========================================|
-- | V1.0     19-NOV-12    Saritha Mummaneni    Intital Draft Version 			   |
-- |                                                                                       |
-- +=======================================================================================+ 

Procedure XX_PO_DUPSHPMNT_RECS( errbuf             OUT VARCHAR2
                            , retcode            OUT NUMBER
                            , p_email_list        IN VARCHAR2                         
                           );                                    
                          
                             
END;
/



create or replace
PACKAGE XX_AR_AME_CMWF_API AS

  g_debug_mesg		VARCHAR2(240);

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |      		Office Depot Organization   	               	  |
   -- +===================================================================+
   -- | Name  : InsertResolvedResponseNotes                               |
   -- | Description : This procedure was copied from AR_AME_CMWR  called  |
   -- |               to insert notes into the resolved invoice           |
   -- |                                                                   |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date        Author           Remarks            	  |
   -- |=======   ==========  =============    ============================|
   -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
   -- |V 1.0     05-OCT-2010 Lincy K          Added procedure CallTrxApi  |
   -- |                                       for defect 3890             |
   -- *********************************************************************
  PROCEDURE InsertResolvedResponseNotes(p_item_type        IN  VARCHAR2,
                                        p_item_key         IN  VARCHAR2,
                                        p_actid            IN  NUMBER,
                                        p_funcmode         IN  VARCHAR2,
                                        p_result           OUT NOCOPY VARCHAR2);

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |      		Office Depot Organization   	               	  |
   -- +===================================================================+
   -- | Name  : FindRequestor                                             |
   -- | Description :Created as a work around for bug found during testing|
   -- |               of CR788. Bug was introduced by bug/patch 6045933   |
   -- |             Procedure will be called by XX Find Requestor function|
   -- |             in the AR Credit Memo Request Approval workflow.      |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date        Author           Remarks            	  |
   -- |=======   ==========  =============    ============================|
   -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
   -- |                                                                   |
   -- *********************************************************************

  PROCEDURE FindRequestor(              p_item_type        IN  VARCHAR2,
                                        p_item_key         IN  VARCHAR2,
                                        p_actid            IN  NUMBER,
                                        p_funcmode         IN  VARCHAR2,
                                        p_result           OUT NOCOPY VARCHAR2);

  -- Added below procedure for defect 3890
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                         Wipro Technologies                        |
   -- +===================================================================+
   -- | Name  : CallTrxApi                                                |
   -- | Description : This procedure was copied from AR_AME_CMWR called   |
   -- |               to create credit memo. Cutomized to exclude manual  |
   -- |               credit memo from billing                            |
   -- |                                                                   |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date        Author           Remarks                     |
   -- |=======   ==========  =============    ============================|
   -- |DRAFT 1A  05-OCT-2010 Lincy K          Initial draft version for   |
   -- |                                       defect 3890                 |
   -- |                                                                   |
   -- *********************************************************************

PROCEDURE CallTrxApi(p_item_type        IN  VARCHAR2,
                     p_item_key         IN  VARCHAR2,
                     p_actid            IN  NUMBER,
                     p_funcmode         IN  VARCHAR2,
                     p_result           OUT NOCOPY VARCHAR2);

END XX_AR_AME_CMWF_API;
/




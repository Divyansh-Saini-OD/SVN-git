SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
 
PROMPT Creating Package Specification XX_PO_MASSUPD_PKG
 
PROMPT Program exits if the creation is not successful
 
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_PO_MASSUPD_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Implemented to perform the Mass Updation of PO      |
-- | Description : To perform the Mass updation of a PO for            |
-- |               RICE ID E0315.Mass updation can be done at both the |
-- |               header level and at the line level.                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author               Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       26-MAY-2007  MadanKumar J         Initial version        |
-- |                                                                   |
-- +===================================================================+
AS
                  
-- +===================================================================+
-- | Name        : Main                                                |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters : x_error_buff, x_ret_code,p_batch_id                  |
-- +===================================================================+
PROCEDURE MAIN(
               x_error_buff  OUT NOCOPY VARCHAR2
               ,x_ret_code   OUT NOCOPY VARCHAR2
               ,p_batch_id   IN   NUMBER
              );
                                  
-- +===================================================================+
-- | Name        : INSERT_SUMMARY_RECORD                               |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :                                                      |
-- +===================================================================+    
PROCEDURE INSERT_SUMMARY_RECORD;
                                   
-- +===================================================================+
-- | Name        : PROCESS_MASS_UPDATE                                 |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE PROCESS_MASS_UPDATE(
                              p_batch_id NUMBER
                              ,x_ret_code OUT NOCOPY NUMBER
                             );
                               
-- +===================================================================+
-- | Name        : OPEN_PO_HDR                                         |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE OPEN_PO_HDR(
                      p_batch_id NUMBER,
                      p_ret_code OUT NOCOPY NUMBER
                      );
                                           
-- +===================================================================+
-- | Name        : APPROVE_PO_HDR                                      |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE APPROVE_PO_HDR(
                         p_batch_id NUMBER
                        );
                                           
-- +===================================================================+
-- | Name        : Update_PO_Line                                      |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE UPDATE_PO_LINE(
                         p_batch_id NUMBER
                        );
                                           
-- +===================================================================+
-- | Name        : XX_PO_MASSUPD_REPORT                                |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE XX_PO_MASSUPD_REPORT(
                              p_batch_id IN NUMBER
                              );
                                           
-- +===================================================================+
-- | Name        : CLOSE_PO_HDR                                        |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE CLOSE_PO_HDR(
                       p_batch_id NUMBER
                      );
                                           
-- +===================================================================+
-- | Name        : INSERT_PO_LINE                                      |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE INSERT_PO_LINE(
                         p_batch_id NUMBER
                        );
                                           
-- +===================================================================+
-- | Name        : CLOSE_PO_HDR_LINE                                   |
-- | Description : This procedure will validate the data of custom     |
-- |               staging tables.                                     |
-- | Parameters :  p_batch_id                                          |
-- +===================================================================+
PROCEDURE CLOSE_PO_HDR_LINE(
                            p_batch_id NUMBER
                           );
                                           
END XX_PO_MASSUPD_PKG;
/
SHOW ERROR
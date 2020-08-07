CREATE OR REPLACE
PACKAGE XX_PO_REQ_AME_PKG AS

  FUNCTION NONBUYERMANAGER(
    p_Requestor         IN NUMBER
   ,p_MinApprAuth       IN NUMBER
  ) RETURN po_tbl_varchar100 PIPELINED;

  PROCEDURE GETEMPLOYEEATTRIBUTES(
    p_Employee          IN NUMBER
   ,x_JobName           IN OUT VARCHAR2
   ,x_ApprovalAuthority IN OUT NUMBER
   ,x_Supervisor        IN OUT NUMBER
   ,x_AgentId           IN OUT NUMBER -- person_id if Buyer, else null
  );

END XX_PO_REQ_AME_PKG;

/

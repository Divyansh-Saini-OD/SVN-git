create or replace
PACKAGE XX_AP_OIE_UTIL_PKG AS

  FUNCTION missing_receipts
  (p_expense_report_id IN NUMBER) RETURN VARCHAR2;

  PROCEDURE wf_set_last_appr_responded
  ( p_item_type IN VARCHAR2
   ,p_item_key  IN VARCHAR2
   ,p_actid    IN NUMBER
   ,p_funcmode IN VARCHAR2
   ,p_RESULT   IN OUT VARCHAR2);

  PROCEDURE wf_set_approval_authority_attr
  ( p_item_type IN VARCHAR2
   ,p_item_key  IN VARCHAR2
   ,p_actid    IN NUMBER
   ,p_funcmode IN VARCHAR2
   ,p_RESULT   IN OUT VARCHAR2);

  PROCEDURE SetApprovalStatus(
                                p_item_type      IN VARCHAR2,
                                p_item_key       IN VARCHAR2,
                                p_actid          IN NUMBER,
                                p_funmode        IN VARCHAR2,
                                p_result         OUT NOCOPY VARCHAR2);   

END XX_AP_OIE_UTIL_PKG;


/

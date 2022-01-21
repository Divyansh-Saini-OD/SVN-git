create or replace PACKAGE BODY XX_OM_ADI_ERROR_TRACKING_PKG
AS
   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name       : XX_OM_ADI_ERROR_TRACKING_PKG                                           |
   -- | RICE ID    : NA                                                                     |
   -- | Description: This package is used to insert records into XX_OM_ADI_ERROR_STATUS     |
   -- |              from Web ADI integrator OD: OM Order Error Status Tracking             |
   -- |                                                                                     |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version    Date         Author         Remarks                                       |
   -- |=========  ===========  =============  =============================                 |
   -- |1.0        12-Aug-2020  Atul K         Initial version                               |
   -- +=====================================================================================+
PROCEDURE GET_ADI_RECORD(
    P_ORIG_SYS_DOCUMENT_REF IN VARCHAR2,
    P_ACTION_PERFORMED      IN VARCHAR2,
    P_PERFORMED_BY          IN VARCHAR2)
IS
l_osr_exp EXCEPTION;
l_action_per_exp EXCEPTION;
l_performed_by_exp EXCEPTION;

BEGIN
  IF P_ORIG_SYS_DOCUMENT_REF            IS NOT NULL THEN
    IF LTRIM(RTRIM(P_ACTION_PERFORMED)) IS NOT NULL THEN
      IF LTRIM(RTRIM(P_PERFORMED_BY))   IS NOT NULL THEN
        INSERT
        INTO XX_OM_ADI_ERROR_STATUS
          (
            ORIG_SYS_DOCUMENT_REF,
            action_performed,
            performed_by,
            uploaded_on
          )
          VALUES
          (
            P_ORIG_SYS_DOCUMENT_REF,
            P_ACTION_PERFORMED,
            P_PERFORMED_BY,
            SYSDATE
          );
        COMMIT;
      ELSE
	    raise l_performed_by_exp;
      END IF;
    ELSE
	  raise l_action_per_exp;
    END IF;
  ELSE
   raise l_osr_exp;
  END IF;
EXCEPTION
WHEN l_performed_by_exp THEN
 raise_application_error(-20001, 'PERFORMED_BY is required field to upload the record ');
WHEN l_action_per_exp THEN
  raise_application_error(-20002, 'ACTION_PERFORMED is required field to upload the record ');
WHEN  l_osr_exp THEN
  raise_application_error(-20003, 'ORIG_SYS_DOCUMENT_REF is required field to upload the record '||P_ORIG_SYS_DOCUMENT_REF);
WHEN OTHERS THEN
  raise_application_error(-20004, 'Unexpected Exception in GET_ADI_RECORD due to: '||SQLERRM);
END GET_ADI_RECORD;
END XX_OM_ADI_ERROR_TRACKING_PKG;
/
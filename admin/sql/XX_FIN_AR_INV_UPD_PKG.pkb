create or replace PACKAGE BODY XX_FIN_AR_INV_UPD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_AR_INV_UPD_PKG                                                              |
  -- |                                                                                            |
  -- |  Description: This package is used by WEB services to update                               |
  -- |               Daily AR Invoice data from VPS.                                              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         12-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- | 1.1         19-DEC-2017  Thejaswini Rajula    Add Error message for Closed Transactions    |
  -- +============================================================================================+

 PROCEDURE UPDATE_INVOICE(
    P_PGM_ID            IN NUMBER,
    P_METH_OF_PMT_CD    IN VARCHAR2,
    P_PGM_DATE          IN VARCHAR2,
    P_PGM_STATUS        IN VARCHAR2,
    P_DUE_DATE          IN VARCHAR2,
    P_TRAN_SOURCE       IN VARCHAR2,
    P_OUT               OUT VARCHAR2
   )
IS
  CURSOR cur_invoices 
    IS 
      SELECT rct.customer_trx_id,rct.trx_number,aps.status status
        FROM ra_customer_trx_all rct,
             ra_batch_sources_all rbs,
             ar_payment_schedules_all aps
       WHERE 1=1
        AND rct.attribute14=TO_CHAR(P_PGM_ID)
        AND rct.attribute_category='US_VPS'
        AND rbs.name=P_TRAN_SOURCE
        AND rct.batch_source_id=rbs.batch_source_id
        AND rct.customer_trx_id=aps.customer_trx_id;
        --AND aps.status='OP';

v_count       NUMBER(10)   := 0;
v_cnt_exist   NUMBER(10)   := 0;
BEGIN
FOR i in cur_invoices LOOP
P_OUT:=NULL;
IF i.status='OP' THEN  --Added by Theja Rajula 12/19/2017
		UPDATE ra_customer_trx_all rct
				   SET rct.attribute8=NVL(P_PGM_STATUS,attribute8)
				   ,rct.attribute6=NVL(P_PGM_DATE,attribute6)
				   ,rct.attribute9=NVL(P_METH_OF_PMT_CD,attribute9)
				   ,rct.attribute12=NVL(P_DUE_DATE,attribute12)
				   ,rct.last_update_date = SYSDATE
				   ,rct.last_updated_by = fnd_global.user_id
				   ,rct.last_update_login = fnd_global.login_id			   
				WHERE 1=1
          AND rct.customer_trx_id=i.customer_trx_id
          AND EXISTS (SELECT aps.customer_trx_id
                            FROM ar_payment_schedules_all aps
                            WHERE 1=1
                             AND aps.customer_trx_id=rct.customer_trx_id
                             AND aps.status='OP' );
  
    UPDATE ar_payment_schedules_all
       SET due_date=NVL(TRUNC(TO_DATE(P_DUE_DATE,'DD-MON-YYYY HH:MI:SS')),due_date)
          ,last_update_date = SYSDATE
				   ,last_updated_by = fnd_global.user_id
				   ,last_update_login = fnd_global.login_id	
    WHERE 1=1
			AND customer_trx_id=i.customer_trx_id
      AND status='OP';
   v_count:=v_count+1;
   IF v_count>0 THEN
      P_OUT:='S';
      P_OUT:=SUBSTR(P_OUT||'|'||i.trx_number||'|'||i.status||'|'||SYSDATE,1,4000);
    END IF;
  ELSE
      P_OUT:='E';
      P_OUT:=SUBSTR((P_OUT||'|'||i.trx_number||'|'||i.status||'|'||SYSDATE),1,4000);
  END IF;
  v_cnt_exist:=v_cnt_exist+1;
END LOOP;
COMMIT;
IF v_cnt_exist=0 THEN
  P_OUT:='E';
  P_OUT:=SUBSTR((P_OUT||'|'||P_PGM_ID||'|'||'Invoice doesnot exist in oracle'||'|'||SYSDATE),1,4000);
END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected Error :'||SQLERRM);
  P_OUT:='E';
  P_OUT:=Substr((P_OUT||'|'||'Unexpected Error :'||SQLERRM||'|'||SYSDATE),1,4000);
END UPDATE_INVOICE;
  
 PROCEDURE UPDATE_PROGRAM(
      PGM_ID            IN NUMBER,
      METH_OF_PMT_CD    IN VARCHAR2,
      PGM_DATE          IN VARCHAR2,
      PGM_STATUS        IN VARCHAR2,
      DUE_DATE          IN VARCHAR2,
      TRAN_SOURCE       IN VARCHAR2,
      P_OUT             OUT VARCHAR2)
  IS
  BEGIN 
    XX_FIN_AR_INV_UPD_PKG.UPDATE_INVOICE(
    P_PGM_ID            =>  PGM_ID,
    P_METH_OF_PMT_CD    =>  METH_OF_PMT_CD,
    P_PGM_DATE          =>  PGM_DATE,
    P_PGM_STATUS        =>  PGM_STATUS,
    P_DUE_DATE          =>  DUE_DATE,
    P_TRAN_SOURCE       =>  TRAN_SOURCE,
    P_OUT               =>  P_OUT
    );
  EXCEPTION
 WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in calling Updating Pkg'||SUBSTR(sqlerrm,1,200));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  END UPDATE_PROGRAM;
END XX_FIN_AR_INV_UPD_PKG;
/
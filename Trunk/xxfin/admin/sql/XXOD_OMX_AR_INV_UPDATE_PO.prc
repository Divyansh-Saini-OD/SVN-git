DECLARE
  CURSOR c_update_po_num
  IS
    --SELECT INV_NO,PO_NO FROM XXFIN.XXOD_OMX_CNV_AR_TRX_STG WHERE process_flag = 4;
	SELECT RCT.TRX_NUMBER,RCT.customer_trx_id,STG.PO_NO,STG.INV_NO 
	FROM   xxod_omx_cnv_ar_trx_stg STG, ra_customer_trx_all RCT
    WHERE RCT.TRX_NUMBER = STG.INV_NO
    AND STG.process_flag = 4;
BEGIN
  FOR rec_update_po_num IN c_update_po_num
  LOOP
    BEGIN
      UPDATE RA_CUSTOMER_TRX_ALL
      SET PURCHASE_ORDER = rec_update_po_num.PO_NO
      WHERE customer_trx_id = rec_update_po_num.customer_trx_id;
    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error while updating Purchase Order Number for AR Invoice'||SQLCODE||SQLERRM);
      ROLLBACK;
    END;
    COMMIT;
  END LOOP;
END;

SHOW ERRORS;

EXIT;


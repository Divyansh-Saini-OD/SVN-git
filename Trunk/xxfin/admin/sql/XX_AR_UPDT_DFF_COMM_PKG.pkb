create or replace
PACKAGE BODY XX_AR_UPDT_DFF_COMM_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_UPDATE_DFF_COMM_PKG                                                             |
  -- |  Description:  Mass Update of DFF and Comments                                             |
  -- |  Rice ID : E3058                                                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         02-Apr-2013   Adithya        Initial version                                   |
  -- | 1.1         24-Oct-2013   Archana N.     Added fix for defect# 25962, reset lc_flag at the |
  -- |                                          begining of each iteration.                       |
  -- | 1.2         27-Oct-2015   Vasu Raparla   Removed Schema References for R12.2               | 
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name: XX_UPDATE_DFF_COMM_PKG.XX_MAIN                                                      |
  -- |  Description: This pkg.procedure will do the validations required and perform the mass     |
  -- |   update.                                                                                  |
  -- =============================================================================================|
  --Note:-
  --Status I for Insert
  --Status P for Processed
  --Status E for error
PROCEDURE XX_MAIN(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER)
IS
  CURSOR c_stg_data
  IS
    SELECT customer_name ,
      account_number ,
      trx_number ,
      dff_attribute9,
      comments
    FROM xx_ar_inv_dff_upload
    WHERE 1   =1
    AND status='I';
  CURSOR c_trxns_data(p_trx_number RA_CUSTOMER_TRX_ALL.TRX_NUMBER%TYPE)
  IS
    SELECT rcta.attribute9,
      rcta.comments,
      Arp.Status,
      hca.Account_number
    FROM Ra_Customer_Trx_All Rcta,
      Ar_Payment_Schedules_All Arp,
      hz_cust_accounts_all hca
    WHERE 1                     =1
    AND Rcta.Customer_Trx_Id    =Arp.Customer_Trx_Id
    AND rcta.bill_to_customer_id=hca.cust_account_id
    AND rcta.Trx_Number         =p_trx_number;
  ln_total_processed NUMBER    :=0;
  ln_success_count   NUMBER    :=0;
  ln_error_count     NUMBER    :=0;
  lc_attribute9      VARCHAR2(50);
  lc_comments        VARCHAR2(250);
  lc_status          VARCHAR2(10);
  lc_account HZ_CUST_ACCOUNTS_ALL.ACCOUNT_NUMBER%TYPE;
  lc_flag BOOLEAN:=TRUE ;
BEGIN
  --Delete Old processed records
  DELETE
  FROM xx_ar_inv_dff_upload
  WHERE status IN ('P','E');
  --Delete blank lines
  DELETE
  FROM xx_ar_inv_dff_upload
  WHERE trx_number   IS NULL
  AND customer_name  IS NULL
  AND account_number IS NULL
  AND comments       IS NULL
  AND dff_attribute9 IS NULL;
  COMMIT;
  FOR c_stg_rec IN c_stg_data
  LOOP
    lc_flag           :=TRUE; --added for defect# 25962 by Archana N.
    ln_total_processed:=ln_total_processed+1;
    ---checking if the comments and attribute9 are not already populated
    OPEN c_trxns_data(c_stg_rec.trx_number);
    FETCH c_trxns_data INTO lc_attribute9,lc_comments,lc_status,lc_account;
    IF c_trxns_data%NOTFOUND THEN
      lc_flag:=FALSE;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Transaction Number = ' || c_stg_rec.trx_number || ':Not Present in AR' );
    ELSIF (lc_attribute9 IS NOT NULL) OR (lc_comments IS NOT NULL) THEN
      lc_flag            :=FALSE;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Transaction Number = ' || c_stg_rec.trx_number || ':Records already have a value' );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Attribute9 = ' || lc_attribute9 || ' '||'Comments =' ||lc_comments);
    END IF;
    CLOSE c_trxns_data;
    --checking if the transaction is closed
    IF lc_status = 'CL' THEN
      lc_flag   :=FALSE;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Transaction Number = ' || c_stg_rec.trx_number || ':This transaction is closed' );
    END IF;
    --checking if the account number is different in AR than given in file
    IF lc_account<>c_stg_rec.account_number THEN
      lc_flag    :=FALSE;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Transaction Number = ' || c_stg_rec.trx_number || ':This Account number is different in AR than in file' );
    END IF;
    --checking if the attribute9 is valid value
    IF c_stg_rec.dff_attribute9 NOT IN ('Escheat','Send Refund','Send Refund Alt') THEN
      lc_flag                       :=FALSE;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Transaction Number = ' || c_stg_rec.trx_number || ':Invalid value given for attribute 9 - DFF update' );
    END IF;
    IF lc_flag=TRUE THEN
      --Update record
      UPDATE ra_customer_trx_all
      SET attribute9  =c_stg_rec.dff_attribute9,
        comments      =c_stg_rec.comments
      WHERE trx_number=c_stg_rec.trx_number;
      UPDATE xx_ar_inv_dff_upload
      SET status       ='P'
      WHERE trx_number =c_stg_rec.trx_number;
      ln_success_count:=ln_success_count+1;
    ELSE
      UPDATE xx_ar_inv_dff_upload
      SET status      ='E'
      WHERE trx_number=c_stg_rec.trx_number;
      ln_error_count :=ln_error_count+1;
    END IF;
  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Transactions processed              :' || ln_total_processed);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Transactions successfully Updated   :' || ln_success_count);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Transactions errored                :' || ln_error_count);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Refer Log for Error record details');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------');
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Others Exception :'|| SUBSTR (SQLERRM, 1, 225) );
END;
END XX_AR_UPDT_DFF_COMM_PKG;

/
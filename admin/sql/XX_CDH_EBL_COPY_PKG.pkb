create or replace 
PACKAGE BODY  XX_CDH_EBL_COPY_PKG
  -- +======================================================================================+
  -- |                  Office Depot - Project Simplify                                     |
  -- |                  WIPRO/Office Depot/Consulting Organization                          |
  -- +======================================================================================|
  -- | Name       : XX_CDH_EBL_COPY_PKG                                                     |
  -- | Description: This package is for the Copy functionality in the Search Page           |
  -- |                                                                                      |
  -- |                                                                                      |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version     Date        Author        Remarks                                         |
  -- |=======   ===========   =========     ================================================|
  -- |DRAFT 1A  20-APR-2010   Mangala       Initial draft version                           |
  -- |                                                                                      |
  -- |1.1       04-AUG-2010   Mangala       Code change to fix Defect 7231                  |
  -- |                                                                                      |
  -- |1.2       11-AUG-2010   Srini         Added "include_in_standard" condition for 7321. |
  -- |1.3       07-SEP-2010   Mangala       Code change to Fix Defect 7588, 7635            |
  -- |1.4       07-JAN-2016   Suresh N      Module 4B Release 3 Changes(Defect#36320)       |
  -- |1.5       30-MAR-2016   Havish K      Module 4B Release 4 Changes                     |
  -- |1.6       25-MAR-2017   Thilak E      Defect#40015 and 2302 Changes                   |  
  -- |1.7       10-Aug-2017   Reddy Sekhar  Defect#41307                                    |
  -- |1.8       23-Mar-2018   Thilak CG     Defect#33309                                    |
  -- |1.9       09-May-2018   Reddy Sekhar  Defect# NAIT-29364                              |
  -- |1.10      29-May-2018   Reddy Sekhar  Defect# NAIT-27146                              |
  -- |2.0       20-Nov-2018   Reddy Sekhar   code changes for Req NAIT-61952 and 66520      |
  -- |======================================================================================|
  -- |                                                                                      |
  -- +======================================================================================+
AS
gc_delv_method              VARCHAR2(100);
  -- +==================================================================================+
  -- | Name             : MAIN_PROC                                                     |
  -- | Description      : This procedure will in turn call all the other procedures to  |
  -- |                    perform the COPY functioanlity                                |
  -- |                                                                                  |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE MAIN_PROC(
                     x_cust_document_id OUT NUMBER
                    ,p_cust_account_id  IN  NUMBER
                    ,p_scust_doc_id     IN  NUMBER
                    ,p_dcust_account_id IN  NUMBER
                   )
IS
         ln_customer_doc_id NUMBER;

BEGIN
      gc_delv_method := NULL;

      SELECT   XCEB.c_ext_attr3 delivery_method
        INTO   gc_delv_method
        FROM   XX_CDH_CUST_ACCT_EXT_B XCEB
       WHERE   XCEB.n_ext_attr2  = p_scust_doc_id;

         --Call COPY_CUST_DOC to copy the Cust_Doc_Id

          COPY_CUST_DOC(x_cust_document_id,
                        p_cust_account_id ,
                        p_scust_doc_id ,
                        p_dcust_account_id
                        );

         --Assign the value of the Cust Doc Id to the variable p_scust_doc_id for passing
         -- to the remaining procedures.

          ln_customer_doc_id := x_cust_document_id;

            --Call COPY_DOC_EXCEPTION to copy the Exception details

            COPY_DOC_EXCEPTION( p_scust_doc_id
                              ,ln_customer_doc_id
                              ,p_cust_account_id
                              ,p_dcust_account_id
                              );


         -- Call COPY_EBL_MAIN to copy the Ebill Main Details

              COPY_EBILL_MAIN (p_scust_doc_id ,
                              ln_customer_doc_id ,
                              p_dcust_account_id
                              );

         -- Call COPY_TRANSMISSION_DTL to copy the Transmission details

              COPY_TRANSMISSION_DTL (p_scust_doc_id ,
                                ln_customer_doc_id
                                );

         -- Call COPY_TEMPL_HEADER to copy the template Header details

           COPY_TEMPL_HEADER (p_scust_doc_id ,
                             ln_customer_doc_id
                             );

         --Call COPY_TEMPL_DETAIL  to copy the Template details

           COPY_TEMPL_DETAIL (p_scust_doc_id ,
                             ln_customer_doc_id
                             );

           IF  gc_delv_method = 'eTXT'
           THEN
            --Call COPY_TEMPL_TRAILER_TXT  to copy the Template Trailer details

           COPY_TEMPL_TRAILER_TXT (p_scust_doc_id ,
                                   ln_customer_doc_id
                                   );
           END IF;

         -- Call COPY_CONCATENATE_DETAIL to copy the template Header details

           COPY_CONCATENATE_DETAIL (p_scust_doc_id ,
                             ln_customer_doc_id
                             );
         -- Call COPY_SPLIT_DETAIL to copy the template Header details

           COPY_SPLIT_DETAIL (p_scust_doc_id ,
                             ln_customer_doc_id
                             );

         -- Call COPY_EBL_CONTACTS to copy the Ebill Contact details

           COPY_EBL_CONTACTS (p_scust_doc_id ,
                             ln_customer_doc_id,
                             p_cust_account_id,
                             p_dcust_account_id
                             );

         --Call COPY_EBL_FILE_NAME_DTL to copy the eBill file name details

           COPY_EBL_FILE_NAME_DTL(p_scust_doc_id ,
                                 ln_customer_doc_id
                                 );

         --Call COPY_EBL_STD_AGGR_DTL to copy the eBill Agrregate details

           COPY_EBL_STD_AGGR_DTL(p_scust_doc_id,
                                ln_customer_doc_id
                                );

           COMMIT;

END MAIN_PROC;


  -- +==================================================================================+
  -- | Name             : COPY_CUST_DOC                                                 |
  -- | Description      : This procedure will copy the cust doc id values from the      |
  -- |                    EGO table XX_CDH_CUST_ACCT_EXT_B and insert a record into the |
  -- |                    same table                                                    |
  -- |                                                                                  |
  -- +==================================================================================+



PROCEDURE COPY_CUST_DOC(
                         x_cust_doc_id   OUT NUMBER
                        ,p_cust_acct_id  IN  NUMBER
                        ,p_cust_doc_id   IN  NUMBER
                        ,p_dcust_acct_id IN  NUMBER
                       )
IS
       lt_rec XX_CDH_CUST_ACCT_EXT_B%ROWTYPE;
       ln_ext_id                     NUMBER;
       ln_cust_doc_id                NUMBER;
       ln_row_id                     VARCHAR2(100);
       ln_start_date                 DATE;
       ln_pay_doc_start              DATE;

       CURSOR lcu_cust_doc
       IS
       SELECT *
       FROM   XX_CDH_CUST_ACCT_EXT_B
       WHERE  CUST_ACCOUNT_ID = p_cust_acct_id
       AND    n_ext_attr2     = p_cust_doc_id;
BEGIN

     ln_pay_doc_start := trunc(SYSDATE); -- This will be applicable for all Info Doc

     OPEN lcu_cust_doc;
     FETCH lcu_cust_doc INTO lt_rec;
     IF(lcu_cust_doc%NOTFOUND) THEN
        CLOSE lcu_cust_doc;
        RAISE NO_DATA_FOUND;
     END IF;


-- Fetch the sequence generated values for Cust doc Id and Extension Id

       SELECT EGO_EXTFWK_S.NEXTVAL
       INTO ln_ext_id
       FROM DUAL;

       SELECT XX_CDH_CUST_DOC_ID_S.NEXTVAL
       INTO ln_cust_doc_id
       FROM DUAL;

-- Assign the sequence generated Cust Doc Id to the Out Parameter so that it will be returned back to the calling procedure
       x_cust_doc_id := ln_cust_doc_id;

-- Code Fix to fix the issue with changing the Start Date for the Pay Doc

        IF (lt_rec.c_ext_attr2 ='Y')
        THEN
             ln_start_date := XX_CDH_CUST_ACCT_EXT_W_PKG.GET_PAY_DOC_VALID_DATE(p_cust_acc_id  => p_dcust_acct_id
                                                                               ,p_attr_grp_id  => lt_rec.attr_group_id
                                                                               ,p_combo_type   => lt_rec.c_ext_attr13
                                                                                );
             IF ( trunc(ln_start_date) < trunc(SYSDATE) )
             THEN
                  ln_pay_doc_start  := trunc(SYSDATE);
             ELSE
                  ln_pay_doc_start  := ln_start_date;
             END IF;

        END IF;


-- Call the Wrapper Package to Insert records into the EGO tables XX_CDH_CUST_ACCT_EXT_B and XX_CDH_CUST_ACCT_EXT_TL tables.

    XX_CDH_CUST_ACCT_EXT_W_PKG.INSERT_ROW(  x_rowid            => ln_row_id
                                          , p_extension_id     => ln_ext_id
                                          , p_cust_account_id  => p_dcust_acct_id
                                          , p_attr_group_id    => lt_rec.attr_group_id
                                          , p_c_ext_attr1      => lt_rec.c_ext_attr1
                                          , p_c_ext_attr2      => lt_rec.c_ext_attr2
                                          , p_c_ext_attr3      => lt_rec.c_ext_attr3
                                          , p_c_ext_attr4      => lt_rec.c_ext_attr4
                                          , p_c_ext_attr5      => lt_rec.c_ext_attr5
                                          , p_c_ext_attr6      => lt_rec.c_ext_attr6
                                          , p_c_ext_attr7      => lt_rec.c_ext_attr7
                                          , p_c_ext_attr8      => lt_rec.c_ext_attr8
                                          , p_c_ext_attr9      => lt_rec.c_ext_attr9
                                          , p_c_ext_attr10     => lt_rec.c_ext_attr10
                                          , p_c_ext_attr11     => lt_rec.c_ext_attr11
                                          , p_c_ext_attr12     => lt_rec.c_ext_attr12
                                          , p_c_ext_attr13     => lt_rec.c_ext_attr13
                                          , p_c_ext_attr14     => lt_rec.c_ext_attr14
                                          , p_c_ext_attr15     => lt_rec.c_ext_attr15
                                          , p_c_ext_attr16     => 'IN_PROCESS'
                                          , p_c_ext_attr17     => lt_rec.c_ext_attr17
                                          , p_c_ext_attr18     => lt_rec.c_ext_attr18
                                          , p_c_ext_attr19     => lt_rec.c_ext_attr19
                                          , p_c_ext_attr20     => lt_rec.c_ext_attr20
                                          , p_n_ext_attr1      => lt_rec.n_ext_attr1
                                          , p_n_ext_attr2      => ln_cust_doc_id
                                          , p_n_ext_attr3      => lt_rec.n_ext_attr3
                                          , p_n_ext_attr4      => lt_rec.n_ext_attr4
                                          , p_n_ext_attr5      => lt_rec.n_ext_attr5
                                          , p_n_ext_attr6      => lt_rec.n_ext_attr6
                                          , p_n_ext_attr7      => lt_rec.n_ext_attr7
                                          , p_n_ext_attr8      => lt_rec.n_ext_attr8
                                          , p_n_ext_attr9      => lt_rec.n_ext_attr9
                                          , p_n_ext_attr10     => lt_rec.n_ext_attr10
                                          , p_n_ext_attr11     => lt_rec.n_ext_attr11
                                          , p_n_ext_attr12     => lt_rec.n_ext_attr12
                                          , p_n_ext_attr13     => lt_rec.n_ext_attr13
                                          , p_n_ext_attr14     => lt_rec.n_ext_attr14
                                          , p_n_ext_attr15     => lt_rec.n_ext_attr15
                                          , p_n_ext_attr16     => lt_rec.n_ext_attr16
                                          , p_n_ext_attr17     => lt_rec.n_ext_attr17
                                          , p_n_ext_attr18     => lt_rec.n_ext_attr18
                                          , p_n_ext_attr19     => lt_rec.n_ext_attr19
                                          , p_n_ext_attr20     => lt_rec.n_ext_attr20
                                          , p_d_ext_attr1      => NULL
                                          , p_d_ext_attr2      => NULL
                                          , p_d_ext_attr3      => lt_rec.d_ext_attr3
                                          , p_d_ext_attr4      => lt_rec.d_ext_attr4
                                          , p_d_ext_attr5      => lt_rec.d_ext_attr5
                                          , p_d_ext_attr6      => lt_rec.d_ext_attr6
                                          , p_d_ext_attr7      => lt_rec.d_ext_attr7
                                          , p_d_ext_attr8      => lt_rec.d_ext_attr8
                                          , p_d_ext_attr9      => ln_pay_doc_start
                                          , p_d_ext_attr10     => NULL
                                          , p_tl_ext_attr1     => NULL
                                          , p_tl_ext_attr2     => NULL
                                          , p_tl_ext_attr3     => NULL
                                          , p_tl_ext_attr4     => NULL
                                          , p_tl_ext_attr5     => NULL
                                          , p_tl_ext_attr6     => NULL
                                          , p_tl_ext_attr7     => NULL
                                          , p_tl_ext_attr8     => NULL
                                          , p_tl_ext_attr9     => NULL
                                          , p_tl_ext_attr10    => NULL
                                          , p_tl_ext_attr11    => NULL
                                          , p_tl_ext_attr12    => NULL
                                          , p_tl_ext_attr13    => NULL
                                          , p_tl_ext_attr14    => NULL
                                          , p_tl_ext_attr15    => NULL
                                          , p_tl_ext_attr16    => NULL
                                          , p_tl_ext_attr17    => NULL
                                          , p_tl_ext_attr18    => NULL
                                          , p_tl_ext_attr19    => NULL
                                          , p_tl_ext_attr20    => NULL
                                          , p_creation_date    => SYSDATE
                                          , p_created_by       => FND_GLOBAL.USER_ID
                                          , p_last_update_date => SYSDATE
                                          , p_last_updated_by  => FND_GLOBAL.USER_ID
                                          , p_last_update_login=> FND_GLOBAL.USER_ID
										  , p_bc_pod_flag      => lt_rec.BC_POD_FLAG --code added by Reddy Sekhar on 20-Nov-2018 for NAIT-61952 and 66520
                                          );

CLOSE lcu_cust_doc;

EXCEPTION
   WHEN OTHERS THEN
      RAISE;

END COPY_CUST_DOC;

  -- +==================================================================================+
  -- | Name             : COPY_DOC_EXCEPTION                                            |
  -- | Description      : This procedure will copy the cust doc id values from the      |
  -- |                    EGO table XX_CDH_CUST_ACCT_EXT_B and insert a record into the |
  -- |                    Exception tables XX_CDH_ACCT_SITE_EXT_B and                   |
  -- |                    XX_CDH_ACCT_SITE_EXT_TL.The Exceptions are copied only for    |
  -- |                     Info Docs                                                    |
  -- +==================================================================================+

PROCEDURE COPY_DOC_EXCEPTION(
                             p_scust_doc_id  IN NUMBER
                            ,p_dcust_doc_id  IN NUMBER
                            ,p_scust_acct_id IN NUMBER
                            ,p_dcust_acct_id IN NUMBER
                           )
IS

ln_extn_id      NUMBER;
ln_xrow_id      VARCHAR2(100);
ln_ret_status    VARCHAR2(100);
ln_doc_type     VARCHAR2(10);
ln_attr_grp_id  NUMBER;

CURSOR lcu_exception
IS
SELECT *
FROM   XX_CDH_ACCT_SITE_EXT_B
WHERE  n_ext_attr1 = p_scust_doc_id;


BEGIN

       -- Fetch the Attr group Id

       SELECT attr_group_id
       INTO   ln_attr_grp_id
       FROM   ego_attr_groups_v
       WHERE  attr_group_type   ='XX_CDH_CUST_ACCT_SITE'
       AND    attr_group_name   = 'BILLDOCS';



      -- check if it is a Info Doc. If so, then proceed with Copy

     SELECT c_ext_attr2
     INTO   ln_doc_type
     FROM   XX_CDH_CUST_ACCT_EXT_B
     WHERE  CUST_ACCOUNT_ID   = p_scust_acct_id
     AND    n_ext_attr2       = p_scust_doc_id;




 -- The Records should be copied in the Exception table only for the Info Docs
 IF ln_doc_type = 'N' AND p_scust_acct_id = p_dcust_acct_id
 THEN

    FOR lcu_rec IN lcu_exception
    LOOP

                    SELECT EGO_EXTFWK_S.NEXTVAL
                    INTO   ln_extn_id
                    FROM   DUAL;


                     XX_CDH_CUST_ACCT_SITE_EXTW_PKG.insert_row(  x_rowid             =>ln_xrow_id
                                                                ,x_return_status     =>ln_ret_status
                                                                ,p_extension_id      =>ln_extn_id
                                                                ,p_cust_acct_site_id =>lcu_rec.cust_acct_site_id
                                                                ,p_attr_group_id     =>ln_attr_grp_id
                                                                ,p_c_ext_attr1       =>lcu_rec.c_ext_attr1
                                                                ,p_c_ext_attr2       =>lcu_rec.c_ext_attr2
                                                                ,p_c_ext_attr3       =>lcu_rec.c_ext_attr3
                                                                ,p_c_ext_attr4       =>lcu_rec.c_ext_attr4
                                                                ,p_c_ext_attr5       =>lcu_rec.c_ext_attr5
                                                                ,p_c_ext_attr6       =>lcu_rec.c_ext_attr6
                                                                ,p_c_ext_attr7       =>lcu_rec.c_ext_attr7
                                                                ,p_c_ext_attr8       =>lcu_rec.c_ext_attr8
                                                                ,p_c_ext_attr9       =>lcu_rec.c_ext_attr9
                                                                ,p_c_ext_attr10      =>lcu_rec.c_ext_attr10
                                                                ,p_c_ext_attr11      =>lcu_rec.c_ext_attr11
                                                                ,p_c_ext_attr12      =>lcu_rec.c_ext_attr12
                                                                ,p_c_ext_attr13      =>lcu_rec.c_ext_attr13
                                                                ,p_c_ext_attr14      =>lcu_rec.c_ext_attr14
                                                                ,p_c_ext_attr15      =>lcu_rec.c_ext_attr15
                                                                ,p_c_ext_attr16      =>lcu_rec.c_ext_attr16
                                                                ,p_c_ext_attr17      =>lcu_rec.c_ext_attr17
                                                                ,p_c_ext_attr18      =>lcu_rec.c_ext_attr18
                                                                ,p_c_ext_attr19      =>lcu_rec.c_ext_attr19
                                                                ,p_c_ext_attr20      =>lcu_rec.c_ext_attr20
                                                                ,p_n_ext_attr1       =>p_dcust_doc_id
                                                                ,p_n_ext_attr2       =>lcu_rec.n_ext_attr2
                                                                ,p_n_ext_attr3       =>lcu_rec.n_ext_attr3
                                                                ,p_n_ext_attr4       =>lcu_rec.n_ext_attr4
                                                                ,p_n_ext_attr5       =>lcu_rec.n_ext_attr5
                                                                ,p_n_ext_attr6       =>lcu_rec.n_ext_attr6
                                                                ,p_n_ext_attr7       =>lcu_rec.n_ext_attr7
                                                                ,p_n_ext_attr8       =>lcu_rec.n_ext_attr8
                                                                ,p_n_ext_attr9       =>lcu_rec.n_ext_attr9
                                                                ,p_n_ext_attr10      =>lcu_rec.n_ext_attr10
                                                                ,p_n_ext_attr11      =>lcu_rec.n_ext_attr11
                                                                ,p_n_ext_attr12      =>lcu_rec.n_ext_attr12
                                                                ,p_n_ext_attr13      =>lcu_rec.n_ext_attr13
                                                                ,p_n_ext_attr14      =>lcu_rec.n_ext_attr14
                                                                ,p_n_ext_attr15      =>lcu_rec.n_ext_attr15
                                                                ,p_n_ext_attr16      =>lcu_rec.n_ext_attr16
                                                                ,p_n_ext_attr17      =>lcu_rec.n_ext_attr17
                                                                ,p_n_ext_attr18      =>lcu_rec.n_ext_attr18
                                                                ,p_n_ext_attr19      =>lcu_rec.n_ext_attr19
                                                                ,p_n_ext_attr20      =>lcu_rec.n_ext_attr20
                                                                ,p_d_ext_attr1       =>lcu_rec.d_ext_attr1
                                                                ,p_d_ext_attr2       =>lcu_rec.d_ext_attr2
                                                                ,p_d_ext_attr3       =>lcu_rec.d_ext_attr3
                                                                ,p_d_ext_attr4       =>lcu_rec.d_ext_attr4
                                                                ,p_d_ext_attr5       =>lcu_rec.d_ext_attr5
                                                                ,p_d_ext_attr6       =>lcu_rec.d_ext_attr6
                                                                ,p_d_ext_attr7       =>lcu_rec.d_ext_attr7
                                                                ,p_d_ext_attr8       =>lcu_rec.d_ext_attr8
                                                                ,p_d_ext_attr9       =>lcu_rec.d_ext_attr9
                                                                ,p_d_ext_attr10      =>lcu_rec.d_ext_attr10
                                                                ,p_tl_ext_attr1      =>NULL
                                                                ,p_tl_ext_attr2      =>NULL
                                                                ,p_tl_ext_attr3      =>NULL
                                                                ,p_tl_ext_attr4      =>NULL
                                                                ,p_tl_ext_attr5      =>NULL
                                                                ,p_tl_ext_attr6      =>NULL
                                                                ,p_tl_ext_attr7      =>NULL
                                                                ,p_tl_ext_attr8      =>NULL
                                                                ,p_tl_ext_attr9      =>NULL
                                                                ,p_tl_ext_attr10     =>NULL
                                                                ,p_tl_ext_attr11     =>NULL
                                                                ,p_tl_ext_attr12     =>NULL
                                                                ,p_tl_ext_attr13     =>NULL
                                                                ,p_tl_ext_attr14     =>NULL
                                                                ,p_tl_ext_attr15     =>NULL
                                                                ,p_tl_ext_attr16     =>NULL
                                                                ,p_tl_ext_attr17     =>NULL
                                                                ,p_tl_ext_attr18     =>NULL
                                                                ,p_tl_ext_attr19     =>NULL
                                                                ,p_tl_ext_attr20     =>NULL
                                                                ,p_creation_date     =>SYSDATE
                                                                ,p_created_by        =>FND_GLOBAL.USER_ID
                                                                ,p_last_update_date  =>SYSDATE
                                                                ,p_last_updated_by   =>FND_GLOBAL.USER_ID
                                                                ,p_last_update_login =>FND_GLOBAL.USER_ID
                                                              );

    END LOOP;
END IF;

  EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_DOC_EXCEPTION;

  -- +==================================================================================+
  -- | Name             : COPY_EBILL_MAIN                                                 |
  -- | Description      : This procedure will copy the Ebill main details corresponding |
  -- |                    to Cust doc id and insert into the table XX_CDH_EBL_MAIN      |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_EBILL_MAIN(
                         p_scust_doc_id     IN NUMBER
                        ,p_dcust_doc_id     IN NUMBER
                        ,p_dcust_account_id IN NUMBER
                         )
IS

       lt_rec XX_CDH_EBL_MAIN%ROWTYPE;

       CURSOR lcu_ebl_main
       IS
       SELECT *
       FROM   XX_CDH_EBL_MAIN
       WHERE  cust_doc_id = p_scust_doc_id;

BEGIN

     OPEN lcu_ebl_main;
     LOOP
     FETCH lcu_ebl_main INTO lt_rec;
     EXIT WHEN lcu_ebl_main%NOTFOUND;

-- Call the Package XX_CDH_EBL_MAIN_PKG to Insert records into the XX_CDH_EBL_MAIN TABLE.

       IF (lcu_ebl_main%ROWCOUNT >0)
       THEN
                XX_CDH_EBL_MAIN_PKG.insert_row ( p_cust_doc_id              =>p_dcust_doc_id
                                                ,p_cust_account_id          =>p_dcust_account_id
                                                ,p_ebill_transmission_type  =>lt_rec.ebill_transmission_type
                                                ,p_ebill_associate          =>lt_rec.ebill_associate
                                                ,p_file_processing_method   =>lt_rec.file_processing_method
                                                ,p_file_name_ext            =>lt_rec.file_name_ext
                                                ,p_max_file_size            =>lt_rec.max_file_size
                                                ,p_max_transmission_size    =>lt_rec.max_transmission_size
                                                ,p_zip_required             =>lt_rec.zip_required
                                                ,p_zipping_utility          =>lt_rec.zipping_utility
                                                ,p_zip_file_name_ext        =>lt_rec.zip_file_name_ext
                                                ,p_od_field_contact         =>lt_rec.od_field_contact
                                                ,p_od_field_contact_email   =>lt_rec.od_field_contact_email
                                                ,p_od_field_contact_phone   =>lt_rec.od_field_contact_phone
                                                ,p_client_tech_contact      =>lt_rec.client_tech_contact
                                                ,p_client_tech_contact_email=>lt_rec.client_tech_contact_email
                                                ,p_client_tech_contact_phone=>lt_rec.client_tech_contact_phone
                                                ,p_file_name_seq_reset      =>lt_rec.file_name_seq_reset
                                                ,p_file_next_seq_number     =>lt_rec.file_next_seq_number
                                                ,p_file_seq_reset_date      =>lt_rec.file_seq_reset_date
                                                ,p_file_name_max_seq_number =>lt_rec.file_name_max_seq_number
                                                ,p_attribute1               =>lt_rec.attribute1
                                                ,p_attribute2               =>NULL
                                                ,p_attribute3               =>NULL
                                                ,p_attribute4               =>NULL
                                                ,p_attribute5               =>NULL
                                                ,p_attribute6               =>NULL
                                                ,p_attribute7               =>NULL
                                                ,p_attribute8               =>NULL
                                                ,p_attribute9               =>NULL
                                                ,p_attribute10              =>NULL
                                                ,p_attribute11              =>NULL
                                                ,p_attribute12              =>NULL
                                                ,p_attribute13              =>NULL
                                                ,p_attribute14              =>NULL
                                                ,p_attribute15              =>NULL
                                                ,p_attribute16              =>NULL
                                                ,p_attribute17              =>NULL
                                                ,p_attribute18              =>NULL
                                                ,p_attribute19              =>NULL
                                                ,p_attribute20              =>NULL
                                                ,p_last_update_date         =>SYSDATE
                                                ,p_last_updated_by          =>FND_GLOBAL.USER_ID
                                                ,p_creation_date            =>SYSDATE
                                                ,p_created_by               =>FND_GLOBAL.USER_ID
                                                ,p_last_update_login        =>FND_GLOBAL.USER_ID
                                                ,p_request_id               =>NULL
                                                ,p_program_application_id   =>NULL
                                                ,p_program_id               =>NULL
                                                ,p_program_update_date      =>NULL
                                                ,p_wh_update_date           =>NULL
                                                ,p_delimiter_char           =>lt_rec.delimiter_char     -- Added for MOD4B Rel 4 Changes
                                                ,p_file_creation_type       =>lt_rec.file_creation_type -- Added for MOD4B Rel 4 Changes
												,p_summary_bill             =>lt_rec.summary_bill
												,p_nondt_qty                =>lt_rec.nondt_quantity
												,p_parent_doc_id            =>lt_rec.parent_doc_id --Added by Reddy Sekhar K for the defect # NAIT-27146 on 29-May-2018 
                                                );
												
         END IF;
       END LOOP;
       CLOSE lcu_ebl_main;

EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      RAISE;

   WHEN OTHERS THEN
      RAISE;

END COPY_EBILL_MAIN;


  -- +==================================================================================+
  -- | Name             : COPY_TRANSMISSION_DTL                                         |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TRANSMISSION_DTL                                  |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_TRANSMISSION_DTL(
                                p_scust_doc_id IN NUMBER,
                                p_dcust_doc_id IN NUMBER
                               )
IS
       lt_rec  XX_CDH_EBL_TRANSMISSION_DTL%ROWTYPE;

       CURSOR lcu_ebl_trans
       IS
       SELECT *
       FROM   XX_CDH_EBL_TRANSMISSION_DTL
       WHERE  cust_doc_id = p_scust_doc_id;
BEGIN

     OPEN lcu_ebl_trans;
     LOOP
     FETCH lcu_ebl_trans INTO lt_rec;
     EXIT WHEN lcu_ebl_trans%NOTFOUND;

-- Call the Package XX_CDH_EBL_TRANS_DTL_PKG to Insert records into the XX_CDH_EBL_TRANSMISSION_DTL.

    IF (lcu_ebl_trans%rowcount >0)
    THEN
                        XX_CDH_EBL_TRANS_DTL_PKG.insert_row( p_cust_doc_id               =>p_dcust_doc_id
                                                            ,p_email_subject             =>lt_rec.email_subject
                                                            ,p_email_std_message         =>lt_rec.email_std_message
                                                            ,p_email_custom_message      =>lt_rec.email_custom_message
                                                            ,p_email_std_disclaimer      =>lt_rec.email_std_disclaimer
                                                            ,p_email_signature           =>lt_rec.email_signature
                                                            ,p_email_logo_required       =>lt_rec.email_logo_required
                                                            ,p_email_logo_file_name      =>lt_rec.email_logo_file_name
                                                            ,p_ftp_direction             =>lt_rec.ftp_direction
                                                            ,p_ftp_transfer_type         =>lt_rec.ftp_transfer_type
                                                            ,p_ftp_destination_site      =>lt_rec.ftp_destination_site
                                                            ,p_ftp_destination_folder    =>lt_rec.ftp_destination_folder
                                                            ,p_ftp_user_name             =>lt_rec.ftp_user_name
                                                            ,p_ftp_password              =>lt_rec.ftp_password
                                                            ,p_ftp_pickup_server         =>lt_rec.ftp_pickup_server
                                                            ,p_ftp_pickup_folder         =>lt_rec.ftp_pickup_folder
                                                            ,p_ftp_cust_contact_name     =>lt_rec.ftp_cust_contact_name
                                                            ,p_ftp_cust_contact_email    =>lt_rec.ftp_cust_contact_email
                                                            ,p_ftp_cust_contact_phone    =>lt_rec.ftp_cust_contact_phone
                                                            ,p_ftp_notify_customer       =>lt_rec.ftp_notify_customer
                                                            ,p_ftp_cc_emails             =>lt_rec.ftp_cc_emails
                                                            ,p_ftp_email_sub             =>lt_rec.ftp_email_sub
                                                            ,p_ftp_email_content         =>lt_rec.ftp_email_content
                                                            ,p_ftp_send_zero_byte_file   =>lt_rec.ftp_send_zero_byte_file
                                                            ,p_ftp_zero_byte_file_text   =>lt_rec.ftp_zero_byte_file_text
                                                            ,p_ftp_zero_byte_notifi_txt  =>lt_rec.ftp_zero_byte_notification_txt
                                                            ,p_cd_file_location          =>lt_rec.cd_file_location
                                                            ,p_cd_send_to_address        =>lt_rec.cd_send_to_address
                                                            ,p_comments                  =>lt_rec.comments
                                                            ,p_attribute1                =>lt_rec.attribute1
                                                            ,p_attribute2                =>lt_rec.attribute2
                                                            ,p_attribute3                =>lt_rec.attribute3
                                                            ,p_attribute4                =>lt_rec.attribute4
                                                            ,p_attribute5                =>lt_rec.attribute5
                                                            ,p_attribute6                =>lt_rec.attribute6
                                                            ,p_attribute7                =>lt_rec.attribute7
                                                            ,p_attribute8                =>lt_rec.attribute8
                                                            ,p_attribute9                =>lt_rec.attribute9
                                                            ,p_attribute10               =>lt_rec.attribute10
                                                            ,p_attribute11               =>lt_rec.attribute11
                                                            ,p_attribute12               =>lt_rec.attribute12
                                                            ,p_attribute13               =>lt_rec.attribute13
                                                            ,p_attribute14               =>lt_rec.attribute14
                                                            ,p_attribute15               =>lt_rec.attribute15
                                                            ,p_attribute16               =>lt_rec.attribute16
                                                            ,p_attribute17               =>lt_rec.attribute17
                                                            ,p_attribute18               =>lt_rec.attribute18
                                                            ,p_attribute19               =>lt_rec.attribute19
                                                            ,p_attribute20               =>lt_rec.attribute20
                                                            ,p_last_update_date          =>SYSDATE
                                                            ,p_last_updated_by           =>FND_GLOBAL.USER_ID
                                                            ,p_creation_date             =>SYSDATE
                                                            ,p_created_by                =>FND_GLOBAL.USER_ID
                                                            ,p_last_update_login         =>FND_GLOBAL.USER_ID
                                                            ,p_request_id                =>NULL
                                                            ,p_program_application_id    =>NULL
                                                            ,p_program_id                =>NULL
                                                            ,p_program_update_date       =>NULL
                                                            ,p_wh_update_date            =>NULL
                                                            );
      END IF;
      END LOOP;
      CLOSE lcu_ebl_trans;

   EXCEPTION
     WHEN OTHERS THEN
       RAISE;

END COPY_TRANSMISSION_DTL;

  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_HEADER                                             |
  -- | Description      : This procedure inserts data into the tables                   |
  -- |                     XX_CDH_EBL_TEMPL_HEADER and XX_CDH_EBL_TEMPL_HDR_TXT         |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_TEMPL_HEADER(
                            p_scust_doc_id IN NUMBER,
                            p_dcust_doc_id IN NUMBER
                           )

IS
       lt_rec                     XX_CDH_EBL_TEMPL_HEADER%ROWTYPE;

       CURSOR lcu_templ_hdr
       IS
       SELECT *
       FROM   XX_CDH_EBL_TEMPL_HEADER
       WHERE  cust_doc_id = p_scust_doc_id;

       -- Added for MOD4B Rel 4
       ln_templ_hdr_txt_id        NUMBER;
       ln_max_hdr_seq             NUMBER;

       CURSOR lcu_templ_hdr_txt
       IS
       SELECT nvl(xceth.cust_doc_id,null)              cust_doc
             ,xcehf.field_id                           field_id_val
             ,xcehf.field_name                         field_name_val
             ,nvl(xceth.record_type,'000')             record_type_val
             ,xcehf.include_in_core                    attribute2_val
             ,xcehf.include_in_detail                  attribute3_val
             ,nvl(xceth.seq, rownum*10000)             seq_val
             ,xcehf.default_seq_num
             ,xceth.*
       FROM  XX_CDH_EBL_TEMPL_HDR_TXT xceth
            ,XX_CDH_EBL_TXT_HDR_FIELDS_V xcehf
      WHERE xceth.field_id         = xcehf.field_id
        AND xceth.cust_doc_id      = p_scust_doc_id --Source Document Id
        AND xcehf.include_in_standard = 'Y'; -- Added for 1.2.

      CURSOR  lcu_temp_hdr_txt_null
      IS
       SELECT   field_id
               ,rownum * 10 rownumber -- Not used
         FROM  XX_CDH_EBL_TEMPL_HDR_TXT
        WHERE    cust_doc_id      =  p_dcust_doc_id
          AND    seq                   >  10000
        ORDER BY field_id;
BEGIN
     -- Added for MOD4B Release 4
     IF  gc_delv_method = 'eTXT'
     THEN
     BEGIN

        FOR lcu_rec IN lcu_templ_hdr_txt
        LOOP

            SELECT XX_CDH_EBL_TEMPL_HDR_TXT_S.NEXTVAL
              INTO ln_templ_hdr_txt_id
              FROM dual;
            -- Call the Package XX_CDH_EBL_TEMPL_HEADER_PKG to Insert records into the XX_CDH_EBL_TEMPL_HDR_TXT.
            XX_CDH_EBL_TEMPL_HEADER_PKG.insert_row_txt(p_ebl_templhdr_id          => ln_templ_hdr_txt_id
                                                      ,p_cust_doc_id              => p_dcust_doc_id
                                                      ,p_include_label            => lcu_rec.include_label
                                                      ,p_record_type              => lcu_rec.record_type_val
                                                      ,p_seq                      => lcu_rec.seq_val
                                                      ,p_field_id                 => lcu_rec.field_id_val
                                                      ,p_label                    => nvl(lcu_rec.label,lcu_rec.field_name_val)
                                                      ,p_start_pos                => lcu_rec.start_pos
                                                      ,p_field_len                => lcu_rec.field_len
                                                      ,p_data_format              => lcu_rec.data_format
                                                      ,p_string_fun               => lcu_rec.string_fun
                                                      ,p_sort_order               => lcu_rec.sort_order
                                                      ,p_sort_type                => lcu_rec.sort_type
                                                      ,p_mandatory                => lcu_rec.mandatory
                                                      ,p_seq_start_val            => lcu_rec.seq_start_val
                                                      ,p_seq_inc_val              => lcu_rec.seq_inc_val
                                                      ,p_seq_reset_field          => lcu_rec.seq_reset_field
                                                      ,p_constant_value           => lcu_rec.constant_value
                                                      ,p_alignment                => lcu_rec.alignment
                                                      ,p_padding_char             => lcu_rec.padding_char
                                                      ,p_default_if_null          => lcu_rec.default_if_null
                                                      ,p_comments                 => lcu_rec.comments
                                                      ,p_attribute1               => nvl(lcu_rec.attribute1,'N')
                                                      ,p_attribute2               => lcu_rec.attribute2_val
                                                      ,p_attribute3               => lcu_rec.attribute3_val
                                                      ,p_attribute4               => lcu_rec.attribute4
                                                      ,p_attribute5               => lcu_rec.attribute5
                                                      ,p_attribute6               => lcu_rec.attribute6
                                                      ,p_attribute7               => lcu_rec.attribute7
                                                      ,p_attribute8               => lcu_rec.attribute8
                                                      ,p_attribute9               => lcu_rec.attribute9
                                                      ,p_attribute10              => lcu_rec.attribute10
                                                      ,p_attribute11              => lcu_rec.attribute11
                                                      ,p_attribute12              => lcu_rec.attribute12
                                                      ,p_attribute13              => lcu_rec.attribute13
                                                      ,p_attribute14              => lcu_rec.attribute14
                                                      ,p_attribute15              => lcu_rec.attribute15
                                                      ,p_attribute16              => lcu_rec.attribute16
                                                      ,p_attribute17              => lcu_rec.attribute17
                                                      ,p_attribute18              => lcu_rec.attribute18
                                                      ,p_attribute19              => lcu_rec.attribute19
                                                      ,p_attribute20              => nvl(lcu_rec.attribute20,'Y')
                                                      ,p_request_id               => NULL
                                                      ,p_program_application_id   => NULL
                                                      ,p_program_id               => NULL
                                                      ,p_program_update_date      => NULL
                                                      ,p_wh_update_date           => NULL
                                                      ,p_concatenate              => lcu_rec.concatenate
                                                      ,p_split                    => lcu_rec.split
                                                      ,p_base_field_id            => lcu_rec.base_field_id
                                                      ,p_split_field_id           => lcu_rec.split_field_id
                                                      ,p_rownumber                => lcu_rec.rownumber
                                                      ,p_start_txt_pos            => lcu_rec.start_txt_pos
                                                      ,p_end_txt_pos              => lcu_rec.end_txt_pos
                                                      ,p_fill_txt_pos             => lcu_rec.fill_txt_pos
                                                      ,p_justify_txt              => lcu_rec.justify_txt
                                                      ,p_start_val_pos            => lcu_rec.start_val_pos
                                                      ,p_end_val_pos              => lcu_rec.end_val_pos
                                                      ,p_prepend_char             => lcu_rec.prepend_char
                                                      ,p_append_char              => lcu_rec.append_char
                                                      ,p_absolute_value_flag      => lcu_rec.absolute_flag   ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                      ,p_dcindicator              => lcu_rec.dc_indicator  ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
													  ,p_db_cr_seperator          => lcu_rec.db_cr_seperator ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364 
                                                  );
        END LOOP;

        -- Loop through the records that have sequence value greater than 10000
        -- and each time replace them with max sequence +10

      SELECT      max(seq)
        INTO      ln_max_hdr_seq
        FROM      XX_CDH_EBL_TEMPL_HDR_TXT
        WHERE     cust_doc_id      = p_dcust_doc_id
        AND       seq <10000;

        FOR  lcu_temp_hdr_txt_null_rec IN  lcu_temp_hdr_txt_null
        LOOP
       --Defect 7588

      --Update the seq > 10000 each time with max sequence + rownumber
        UPDATE    XX_CDH_EBL_TEMPL_HDR_TXT
        SET       seq                   = lcu_temp_hdr_txt_null_rec.rownumber + ln_max_hdr_seq
        WHERE     cust_doc_id      = p_dcust_doc_id
        AND       seq                   > 10000
        AND       field_id              = lcu_temp_hdr_txt_null_rec.field_id;

        --COMMIT;

        END LOOP;
     EXCEPTION
        WHEN OTHERS THEN
        RAISE;
        END;
     ELSE
     -- End of adding MOD4B Rel 4 Changes
     OPEN lcu_templ_hdr;
     LOOP
     FETCH lcu_templ_hdr INTO lt_rec;
     EXIT WHEN lcu_templ_hdr%NOTFOUND;

-- Call the Package XX_CDH_EBL_TEMPL_HEADER_PKG to Insert records into the XX_CDH_EBL_TEMPL_HEADER.
    IF (lcu_templ_hdr%rowcount >0)
    THEN

               XX_CDH_EBL_TEMPL_HEADER_PKG.insert_row (  p_cust_doc_id              =>p_dcust_doc_id
                                                        ,p_ebill_file_creation_type =>lt_rec.ebill_file_creation_type
                                                        ,p_delimiter_char           =>lt_rec.delimiter_char
                                                        ,p_line_feed_style          =>lt_rec.line_feed_style
                                                        ,p_include_header           =>lt_rec.include_header
                                                        ,p_logo_file_name           =>lt_rec.logo_file_name
                                                        ,p_file_split_criteria      =>lt_rec.file_split_criteria
                                                        ,p_file_split_value         =>lt_rec.file_split_value
                                                        ,p_attribute1               =>lt_rec.attribute1
                                                        ,p_attribute2               =>lt_rec.attribute2
                                                        ,p_attribute3               =>lt_rec.attribute3
                                                        ,p_attribute4               =>lt_rec.attribute4
                                                        ,p_attribute5               =>lt_rec.attribute5
                                                        ,p_attribute6               =>lt_rec.attribute6
                                                        ,p_attribute7               =>lt_rec.attribute7
                                                        ,p_attribute8               =>lt_rec.attribute8
                                                        ,p_attribute9               =>lt_rec.attribute9
                                                        ,p_attribute10              =>lt_rec.attribute10
                                                        ,p_attribute11              =>lt_rec.attribute11
                                                        ,p_attribute12              =>lt_rec.attribute12
                                                        ,p_attribute13              =>lt_rec.attribute13
                                                        ,p_attribute14              =>lt_rec.attribute14
                                                        ,p_attribute15              =>lt_rec.attribute15
                                                        ,p_attribute16              =>lt_rec.attribute16
                                                        ,p_attribute17              =>lt_rec.attribute17
                                                        ,p_attribute18              =>lt_rec.attribute18
                                                        ,p_attribute19              =>lt_rec.attribute19
                                                        ,p_attribute20              =>lt_rec.attribute20
                                                        ,p_last_update_date         =>SYSDATE
                                                        ,p_last_updated_by          =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date            =>SYSDATE
                                                        ,p_created_by               =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login        =>FND_GLOBAL.USER_ID
                                                        ,p_request_id               =>NULL
                                                        ,p_program_application_id   =>NULL
                                                        ,p_program_id               =>NULL
                                                        ,p_program_update_date      =>NULL
                                                        ,p_wh_update_date           =>NULL
                                                        ,p_splittabsby              => lt_rec.split_tabs_by
                                                        ,p_enablexlsubtotal         => lt_rec.enable_xl_subtotal
                                                        ,p_concatsplit              =>lt_rec.concatsplit
                                                        );
    END IF;
    END LOOP;
    CLOSE lcu_templ_hdr;
   END IF;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_TEMPL_HEADER;

  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_DETAIL                                             |
  -- | Description      : This procedure inserts data into the tables                   |
  -- |                     XX_CDH_EBL_TEMPL_DTL and XX_CDH_EBL_TEMPL_DTL_TXT            |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_TEMPL_DETAIL(
                            p_scust_doc_id  IN NUMBER
                            ,p_dcust_doc_id IN NUMBER
                           )
IS

ln_ebl_templ_id             NUMBER;
-- lc_delv_method              VARCHAR2(100);    --Defect 7635 -- Commented for MOD 4B Release 4 , Declared a new global variable gc_delv_method instead of lc_delv_method
ln_max_seq                  NUMBER;           --Defect 7588
lc_field_selection          VARCHAR2(20);

CURSOR lcu_templ_dtl
IS
/* Fix for Defect 7231*/
/*SELECT *
FROM   XX_CDH_EBL_TEMPL_DTL
WHERE  cust_doc_id = p_scust_doc_id;*/


SELECT    nvl(xcet.cust_doc_id,p_scust_doc_id)    cust_doc
         ,xcef.field_id                           field_id_val
         ,xcef.field_name                         field_name_val
         ,nvl(xcet.record_type,'000')             record_type_val
         ,xcef.include_in_core                    attribute2_val
         ,xcef.include_in_detail                  attribute3_val
         ,nvl(xcet.seq, rownum*10000)             seq_val -- Defect 7588 (Updating the seq value to some junk value which is greater than 10000, as NULL values cannot be inserted into Detail table)
         --,rownum *10                            seq_val --Defect 7588
         ,xcef.default_seq
         ,xcet.*
FROM      XX_CDH_EBL_TEMPL_DTL xcet
         ,XX_CDH_EBILLING_FIELDS_V xcef
WHERE     xcet.field_id (+)        = xcef.field_id
AND       xcet.cust_doc_id(+)      = p_scust_doc_id --Source Document Id
AND       xcef.include_in_standard = 'Y'; -- Added for 1.2.


--Defect 7588
CURSOR  lcu_temp_dtl_null
IS
SELECT   field_id
        ,rownum * 10 rownumber -- Not used
FROM     XX_CDH_EBL_TEMPL_DTL xcet
WHERE    xcet.cust_doc_id      =  p_dcust_doc_id
AND      seq                   >  10000
ORDER BY field_id;

-- Added for MOD 4B Release 4
ln_templ_dtl_txt_id         NUMBER;
ln_max_dtl_txt_seq          NUMBER;

CURSOR lcu_templ_dtl_txt
IS
SELECT    nvl(xcet.cust_doc_id,p_scust_doc_id)    cust_doc
         ,xcef.field_id                           field_id_val
         ,xcef.field_name                         field_name_val
         ,nvl(xcet.record_type,'000')             record_type_val
         ,xcef.include_in_core                    attribute2_val
         ,xcef.include_in_detail                  attribute3_val
         ,nvl(xcet.seq, rownum*10000)             seq_val
         ,xcef.default_seq_num
         ,xcet.*
FROM      XX_CDH_EBL_TEMPL_DTL_TXT xcet
         ,XX_CDH_EBL_TXT_DET_FIELDS_V xcef
WHERE     xcet.field_id         = xcef.field_id
AND       xcet.cust_doc_id      = p_scust_doc_id
AND       xcef.include_in_standard = 'Y';

CURSOR  lcu_temp_dtl_txt_null
IS
SELECT   field_id
        ,rownum * 10 rownumber -- Not used
FROM     XX_CDH_EBL_TEMPL_DTL_TXT
WHERE    cust_doc_id      =  p_dcust_doc_id
AND      seq              >  10000
ORDER BY field_id;

BEGIN

--Defect 7635
     /*   SELECT    XCEB.c_ext_attr3 delivery_method
        INTO      lc_delv_method
        FROM      XX_CDH_CUST_ACCT_EXT_B XCEB
        WHERE     XCEB.n_ext_attr2         = p_scust_doc_id; */ -- Commented for the MOD 4B Release 4

    IF gc_delv_method = 'eXLS' -- Defect 7635
    THEN                       -- Defect 7635
        SELECT attribute1
        INTO lc_field_selection
        FROM XX_CDH_EBL_MAIN
        WHERE cust_doc_id = p_dcust_doc_id;

    FOR lcu_rec IN lcu_templ_dtl
    LOOP

                 SELECT XX_CDH_EBL_TEMPL_ID_S.NEXTVAL
                 INTO ln_ebl_templ_id
                 FROM dual;

                 IF lcu_rec.default_seq IS NOT NULL AND lc_field_selection = 'DETAIL' THEN
                   lcu_rec.attribute1 := 'Y';
                   lcu_rec.seq_val := lcu_rec.default_seq;
                 END IF;

                     XX_CDH_EBL_TEMPL_DTL_PKG.insert_row(p_ebl_templ_id           =>ln_ebl_templ_id
                                                        ,p_cust_doc_id            =>p_dcust_doc_id
                                                        ,p_record_type            =>lcu_rec.record_type_val--Defect 7231
                                                        ,p_seq                    =>lcu_rec.seq_val  --Defect 7588
                                                        ,p_field_id               =>lcu_rec.field_id_val --Defect 7231
                                                        ,p_label                  =>nvl(lcu_rec.label,lcu_rec.field_name_val) --Defect 7231
                                                        ,p_start_pos              =>lcu_rec.start_pos
                                                        ,p_field_len              =>lcu_rec.field_len
                                                        ,p_data_format            =>lcu_rec.data_format
                                                        ,p_string_fun             =>lcu_rec.string_fun
                                                        ,p_sort_order             =>lcu_rec.sort_order
                                                        ,p_sort_type              =>lcu_rec.sort_type
                                                        ,p_mandatory              =>lcu_rec.mandatory
                                                        ,p_seq_start_val          =>lcu_rec.seq_start_val
                                                        ,p_seq_inc_val            =>lcu_rec.seq_inc_val
                                                        ,p_seq_reset_field        =>lcu_rec.seq_reset_field
                                                        ,p_constant_value         =>lcu_rec.constant_value
                                                        ,p_alignment              =>lcu_rec.alignment
                                                        ,p_padding_char           =>lcu_rec.padding_char
                                                        ,p_default_if_null        =>lcu_rec.default_if_null
                                                        ,p_comments               =>lcu_rec.comments
                                                        ,p_attribute1             =>nvl(lcu_rec.attribute1,'N')--Defect 7231
                                                        ,p_attribute2             =>lcu_rec.attribute2_val--Defect 7231
                                                        ,p_attribute3             =>lcu_rec.attribute3_val--Defect 7231
                                                        ,p_attribute4             =>lcu_rec.attribute4
                                                        ,p_attribute5             =>lcu_rec.attribute5
                                                        ,p_attribute6             =>lcu_rec.attribute6
                                                        ,p_attribute7             =>lcu_rec.attribute7
                                                        ,p_attribute8             =>lcu_rec.attribute8
                                                        ,p_attribute9             =>lcu_rec.attribute9
                                                        ,p_attribute10            =>lcu_rec.attribute10
                                                        ,p_attribute11            =>lcu_rec.attribute11
                                                        ,p_attribute12            =>lcu_rec.attribute12
                                                        ,p_attribute13            =>lcu_rec.attribute13
                                                        ,p_attribute14            =>lcu_rec.attribute14
                                                        ,p_attribute15            =>lcu_rec.attribute15
                                                        ,p_attribute16            =>lcu_rec.attribute16
                                                        ,p_attribute17            =>lcu_rec.attribute17
                                                        ,p_attribute18            =>lcu_rec.attribute18
                                                        ,p_attribute19            =>lcu_rec.attribute19
                                                        ,p_attribute20            =>nvl(lcu_rec.attribute20,'Y')--Defect 7231
                                                        ,p_last_update_date       =>SYSDATE
                                                        ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date          =>SYSDATE
                                                        ,p_created_by             =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                        ,p_request_id             =>NULL
                                                        ,p_program_application_id =>NULL
                                                        ,p_program_id             =>NULL
                                                        ,p_program_update_date    =>NULL
                                                        ,p_wh_update_date         =>NULL
                                                        ,p_concatenate            =>lcu_rec.concatenate
                                                        ,p_split                  =>lcu_rec.split
                                                        ,p_base_field_id          =>lcu_rec.base_field_id
                                                        ,p_split_field_id         =>lcu_rec.split_field_id
                                                        ,p_repeat_total_flag      =>NVL(lcu_rec.repeat_total_flag,'N') --Added NVL for Defect#33309 by Thilak CG on 23-Mar-2018
                                                        );

    END LOOP;


--Defect 7588
-- Loop through the records that have sequence value greater than 10000
-- and each time replace them with max sequence +10


        SELECT    max(seq)
        INTO      ln_max_seq
        FROM      XX_CDH_EBL_TEMPL_DTL xcet
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       xcet.seq <10000;


   FOR  lcu_temp_dtl_null_rec IN  lcu_temp_dtl_null
   LOOP
       --Defect 7588

      --Update the seq > 10000 each time with max sequence + rownumber
        UPDATE    XX_CDH_EBL_TEMPL_DTL xcet
        SET       seq                   = lcu_temp_dtl_null_rec.rownumber + ln_max_seq --ln_max_seq + 10
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       seq                   > 10000
        AND       field_id              = lcu_temp_dtl_null_rec.field_id;

        --COMMIT;

   END LOOP;  -- End of Defect 7588

   END IF;   -- Defect 7635

-- We copy all the exisiting records from Source Document . No Logic is followed for eTXT copy.
-- Hence we make use of a seperate Procedure to copy the Parent Document records

   IF gc_delv_method = 'eTXT' -- Defect 7635
   THEN
       /* COPY_TEMPL_DETAIL_ETXT  (   p_scust_doc_id
                                   ,p_dcust_doc_id
                                ); */ -- Commented for MOD 4B Release 4

      -- Added for MOD4B Release 4
      BEGIN

        FOR lcu_rec IN lcu_templ_dtl_txt
        LOOP

            SELECT XX_CDH_EBL_TEMPL_DTL_TXT_S.NEXTVAL
              INTO ln_templ_dtl_txt_id
              FROM dual;
            -- Call the Package XX_CDH_EBL_TEMPL_DTL_PKG to Insert records into the XX_CDH_EBL_TEMPL_DTL_TXT.
            XX_CDH_EBL_TEMPL_DTL_PKG.insert_row_txt(p_ebl_templ_id           =>ln_templ_dtl_txt_id
                                                   ,p_cust_doc_id            =>p_dcust_doc_id
                                                   ,p_seq                    =>lcu_rec.seq_val
                                                   ,p_field_id               =>lcu_rec.field_id_val
                                                   ,p_label                  =>nvl(lcu_rec.label,lcu_rec.field_name_val)
                                                   ,p_start_pos              =>lcu_rec.start_pos
                                                   ,p_field_len              =>lcu_rec.field_len
                                                   ,p_data_format            =>lcu_rec.data_format
                                                   ,p_string_fun             =>lcu_rec.string_fun
                                                   ,p_sort_order             =>lcu_rec.sort_order
                                                   ,p_sort_type              =>lcu_rec.sort_type
                                                   ,p_mandatory              =>lcu_rec.mandatory
                                                   ,p_seq_start_val          =>lcu_rec.seq_start_val
                                                   ,p_seq_inc_val            =>lcu_rec.seq_inc_val
                                                   ,p_seq_reset_field        =>lcu_rec.seq_reset_field
                                                   ,p_constant_value         =>lcu_rec.constant_value
                                                   ,p_alignment              =>lcu_rec.alignment
                                                   ,p_padding_char           =>lcu_rec.padding_char
                                                   ,p_default_if_null        =>lcu_rec.default_if_null
                                                   ,p_comments               =>lcu_rec.comments
                                                   ,p_attribute1             =>nvl(lcu_rec.attribute1,'N')
                                                   ,p_attribute2             =>lcu_rec.attribute2_val
                                                   ,p_attribute3             =>lcu_rec.attribute3_val
                                                   ,p_attribute4             =>lcu_rec.attribute4
                                                   ,p_attribute5             =>lcu_rec.attribute5
                                                   ,p_attribute6             =>lcu_rec.attribute6
                                                   ,p_attribute7             =>lcu_rec.attribute7
                                                   ,p_attribute8             =>lcu_rec.attribute8
                                                   ,p_attribute9             =>lcu_rec.attribute9
                                                   ,p_attribute10            =>lcu_rec.attribute10
                                                   ,p_attribute11            =>lcu_rec.attribute11
                                                   ,p_attribute12            =>lcu_rec.attribute12
                                                   ,p_attribute13            =>lcu_rec.attribute13
                                                   ,p_attribute14            =>lcu_rec.attribute14
                                                   ,p_attribute15            =>lcu_rec.attribute15
                                                   ,p_attribute16            =>lcu_rec.attribute16
                                                   ,p_attribute17            =>lcu_rec.attribute17
                                                   ,p_attribute18            =>lcu_rec.attribute18
                                                   ,p_attribute19            =>lcu_rec.attribute19
                                                   ,p_attribute20            =>nvl(lcu_rec.attribute20,'Y')
                                                   ,p_request_id             =>NULL
                                                   ,p_program_application_id =>NULL
                                                   ,p_program_id             =>NULL
                                                   ,p_program_update_date    =>NULL
                                                   ,p_wh_update_date         =>NULL
                                                   ,p_concatenate            =>lcu_rec.concatenate
                                                   ,p_split                  =>lcu_rec.split
                                                   ,p_base_field_id          =>lcu_rec.base_field_id
                                                   ,p_split_field_id         =>lcu_rec.split_field_id
                                                   ,p_start_txt_pos          =>lcu_rec.start_txt_pos
                                                   ,p_end_txt_pos            =>lcu_rec.end_txt_pos
                                                   ,p_fill_txt_pos           =>lcu_rec.fill_txt_pos
                                                   ,p_justify_txt            =>lcu_rec.justify_txt
                                                   ,p_include_header         =>lcu_rec.include_header
                                                   ,p_repeat_header          =>lcu_rec.repeat_header
                                                   ,p_start_val_pos          =>lcu_rec.start_val_pos
                                                   ,p_end_val_pos            =>lcu_rec.end_val_pos
                                                   ,p_prepend_char           =>lcu_rec.prepend_char
                                                   ,p_append_char            =>lcu_rec.append_char
                                                   ,p_record_type            =>lcu_rec.record_type_val
												   ,p_repeat_total_flag      =>lcu_rec.repeat_total_flag
												   ,p_tax_up_flag            =>lcu_rec.tax_up_flag
												   ,p_freight_up_flag        =>lcu_rec.freight_up_flag
												   ,p_misc_up_flag           =>lcu_rec.misc_up_flag
												   ,p_tax_ep_flag            =>lcu_rec.tax_ep_flag
												   ,p_freight_ep_flag        =>lcu_rec.freight_ep_flag
												   ,p_misc_ep_flag           =>lcu_rec.misc_ep_flag	
                                                   ,p_rownumber              => lcu_rec.rownumber	-- Added by Reddy Sekhar K on 10-AUG-2017 for Defect#41307										   
                                                   ,p_absolute_value_flag    =>lcu_rec.absolute_flag  ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                   ,p_dcindicator            =>lcu_rec.dc_indicator   ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
												   ,p_db_cr_seperator        => lcu_rec.db_cr_seperator  ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                                                  );
				   	
        END LOOP;
      -- Loop through the records that have sequence value greater than 10000
      -- and each time replace them with max sequence +10
      SELECT      max(seq)
        INTO      ln_max_dtl_txt_seq
        FROM      XX_CDH_EBL_TEMPL_DTL_TXT xcet
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       xcet.seq <10000;

      FOR  lcu_temp_dtl_txt_null_rec IN  lcu_temp_dtl_txt_null
      LOOP
      --Update the seq > 10000 each time with max sequence + rownumber
        UPDATE    XX_CDH_EBL_TEMPL_DTL_TXT xcet
        SET       seq                   = lcu_temp_dtl_txt_null_rec.rownumber + ln_max_dtl_txt_seq
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       seq                   > 10000
        AND       field_id              = lcu_temp_dtl_txt_null_rec.field_id;

        --COMMIT;
     END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
      RAISE;
   END;
   END IF;
   -- End of adding MOD4B Rel 4 Changes
  EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_TEMPL_DETAIL;

-- Added for MOD4B Release 4
  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_TRAILER_TXT                                        |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_TEMPL_TRL_TXT                                     |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_TEMPL_TRAILER_TXT(
                            p_scust_doc_id IN NUMBER,
                            p_dcust_doc_id IN NUMBER
                           )

IS
       lt_rec                XX_CDH_EBL_TEMPL_TRL_TXT%ROWTYPE;
       ln_templ_trl_txt_id   NUMBER;
       ln_max_trl_txt_seq    NUMBER;

       CURSOR lcu_templ_trl_txt
       IS
       SELECT    nvl(xcet.cust_doc_id,p_scust_doc_id)    cust_doc
                ,xcef.field_id                           field_id_val
                ,xcef.field_name                         field_name_val
                ,nvl(xcet.record_type,'000')             record_type_val
                ,xcef.include_in_core                    attribute2_val
                ,xcef.include_in_detail                  attribute3_val
                ,nvl(xcet.seq, rownum*10000)             seq_val
                ,xcef.default_seq_num
                ,xcet.*
       FROM     XX_CDH_EBL_TEMPL_TRL_TXT xcet
               ,XX_CDH_EBL_TXT_TRL_FIELDS_V xcef
      WHERE     xcet.field_id         = xcef.field_id
        AND     xcet.cust_doc_id      = p_scust_doc_id --Source Document Id
        AND     xcef.include_in_standard = 'Y';

     CURSOR  lcu_temp_trl_txt_null
     IS
     SELECT   field_id
             ,rownum * 10 rownumber -- Not used
       FROM   XX_CDH_EBL_TEMPL_TRL_TXT
      WHERE   cust_doc_id      =  p_dcust_doc_id
        AND   seq              >  10000
      ORDER BY field_id;

BEGIN

     IF gc_delv_method = 'eTXT'
     THEN
     BEGIN
        FOR lcu_rec_txt IN lcu_templ_trl_txt
        LOOP
        SELECT XX_CDH_EBL_TEMPL_TRL_TXT_S.NEXTVAL
          INTO ln_templ_trl_txt_id
          FROM dual;

               XX_CDH_EBL_TEMPL_TRL_TXT_PKG.insert_row_txt ( p_ebl_templtrl_id          => ln_templ_trl_txt_id
                                                            ,p_cust_doc_id              => p_dcust_doc_id
                                                            ,p_include_label            => lcu_rec_txt.include_label
                                                            ,p_record_type              => lcu_rec_txt.record_type_val
                                                            ,p_seq                      => lcu_rec_txt.seq_val
                                                            ,p_field_id                 => lcu_rec_txt.field_id_val
                                                            ,p_label                    => nvl(lcu_rec_txt.label,lcu_rec_txt.field_name_val)
                                                            ,p_start_pos                => lcu_rec_txt.start_pos
                                                            ,p_field_len                => lcu_rec_txt.field_len
                                                            ,p_data_format              => lcu_rec_txt.data_format
                                                            ,p_string_fun               => lcu_rec_txt.string_fun
                                                            ,p_sort_order               => lcu_rec_txt.sort_order
                                                            ,p_sort_type                => lcu_rec_txt.sort_type
                                                            ,p_mandatory                => lcu_rec_txt.mandatory
                                                            ,p_seq_start_val            => lcu_rec_txt.seq_start_val
                                                            ,p_seq_inc_val              => lcu_rec_txt.seq_inc_val
                                                            ,p_seq_reset_field          => lcu_rec_txt.seq_reset_field
                                                            ,p_constant_value           => lcu_rec_txt.constant_value
                                                            ,p_alignment                => lcu_rec_txt.alignment
                                                            ,p_padding_char             => lcu_rec_txt.padding_char
                                                            ,p_default_if_null          => lcu_rec_txt.default_if_null
                                                            ,p_comments                 => lcu_rec_txt.comments
                                                            ,p_attribute1               => nvl(lcu_rec_txt.attribute1,'N')
                                                            ,p_attribute2               => lcu_rec_txt.attribute2_val
                                                            ,p_attribute3               => lcu_rec_txt.attribute3_val
                                                            ,p_attribute4               => lcu_rec_txt.attribute4
                                                            ,p_attribute5               => lcu_rec_txt.attribute5
                                                            ,p_attribute6               => lcu_rec_txt.attribute6
                                                            ,p_attribute7               => lcu_rec_txt.attribute7
                                                            ,p_attribute8               => lcu_rec_txt.attribute8
                                                            ,p_attribute9               => lcu_rec_txt.attribute9
                                                            ,p_attribute10              => lcu_rec_txt.attribute10
                                                            ,p_attribute11              => lcu_rec_txt.attribute11
                                                            ,p_attribute12              => lcu_rec_txt.attribute12
                                                            ,p_attribute13              => lcu_rec_txt.attribute13
                                                            ,p_attribute14              => lcu_rec_txt.attribute14
                                                            ,p_attribute15              => lcu_rec_txt.attribute15
                                                            ,p_attribute16              => lcu_rec_txt.attribute16
                                                            ,p_attribute17              => lcu_rec_txt.attribute17
                                                            ,p_attribute18              => lcu_rec_txt.attribute18
                                                            ,p_attribute19              => lcu_rec_txt.attribute19
                                                            ,p_attribute20              => nvl(lcu_rec_txt.attribute20,'Y')
                                                            ,p_request_id               => NULL
                                                            ,p_program_application_id   => NULL
                                                            ,p_program_id               => NULL
                                                            ,p_program_update_date      => NULL
                                                            ,p_wh_update_date           => NULL
                                                            ,p_concatenate              => lcu_rec_txt.concatenate
                                                            ,p_split                    => lcu_rec_txt.split
                                                            ,p_base_field_id            => lcu_rec_txt.base_field_id
                                                            ,p_split_field_id           => lcu_rec_txt.split_field_id
                                                            ,p_rownumber                => lcu_rec_txt.rownumber
                                                            ,p_start_txt_pos            => lcu_rec_txt.start_txt_pos
                                                            ,p_end_txt_pos              => lcu_rec_txt.end_txt_pos
                                                            ,p_fill_txt_pos             => lcu_rec_txt.fill_txt_pos
                                                            ,p_justify_txt              => lcu_rec_txt.justify_txt
                                                            ,p_start_val_pos            => lcu_rec_txt.start_val_pos
                                                            ,p_end_val_pos              => lcu_rec_txt.end_val_pos
                                                            ,p_prepend_char             => lcu_rec_txt.prepend_char
                                                            ,p_append_char              => lcu_rec_txt.append_char
                                                            ,p_absolute_value_flag      => lcu_rec_txt.absolute_flag
                                                            ,p_dcindicator              => lcu_rec_txt.dc_indicator
															,p_db_cr_seperator          => lcu_rec_txt.db_cr_seperator   ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                                                        );

        END LOOP;
     -- Loop through the records that have sequence value greater than 10000
     -- and each time replace them with max sequence +10

        SELECT    max(seq)
        INTO      ln_max_trl_txt_seq
        FROM      XX_CDH_EBL_TEMPL_TRL_TXT xcet
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       xcet.seq <10000;


       FOR  lcu_temp_trl_txt_null_rec IN  lcu_temp_trl_txt_null
       LOOP

      --Update the seq > 10000 each time with max sequence + rownumber
        UPDATE    XX_CDH_EBL_TEMPL_TRL_TXT xcet
        SET       seq                   = lcu_temp_trl_txt_null_rec.rownumber + ln_max_trl_txt_seq
        WHERE     xcet.cust_doc_id      = p_dcust_doc_id
        AND       seq                   > 10000
        AND       field_id              = lcu_temp_trl_txt_null_rec.field_id;

        --COMMIT;
   END LOOP;
  EXCEPTION
      WHEN OTHERS THEN
        RAISE;
  END;
  END IF;

  EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_TEMPL_TRAILER_TXT;

-- End of adding MOD 4B Release 4

  -- +==================================================================================+
  -- | Name             : COPY_CONCATENATE_DETAIL                                       |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_CONCAT_FIELDS                                     |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_CONCATENATE_DETAIL(
                            p_scust_doc_id IN NUMBER,
                            p_dcust_doc_id IN NUMBER
                           )

IS
       lt_rec  XX_CDH_EBL_CONCAT_FIELDS%ROWTYPE;

       CURSOR lcu_concat_fields
       IS
       SELECT *
       FROM   XX_CDH_EBL_CONCAT_FIELDS
       WHERE  cust_doc_id = p_scust_doc_id;
       ln_concat_field_id  XX_CDH_EBL_CONCAT_FIELDS.conc_field_id%TYPE;

       CURSOR lcu_templ_dtl(p_field_id IN NUMBER)
       IS
       SELECT   nvl(xcet.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcecf.conc_field_id)            field_id_val
         ,xcecf.conc_field_label                  field_name_val
         ,nvl(xcet.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcet.seq                                seq_val
         ,xcet.*
       FROM  XX_CDH_EBL_TEMPL_DTL xcet,
             XX_CDH_EBL_CONCAT_FIELDS xcecf
       WHERE xcet.cust_doc_id = xcecf.cust_doc_id
       AND xcet.field_id = xcecf.conc_field_id
       AND xcet.cust_doc_id = p_scust_doc_id
       AND xcecf.conc_field_id = p_field_id;
       ln_ebl_templ_id                NUMBER;

       -- Added for MOD 4B Release 4
       ln_concat_fields_txt_id        NUMBER;
       lt_rec_txt                     XX_CDH_EBL_CONCAT_FIELDS_TXT%ROWTYPE;
       CURSOR lcu_concat_fields_txt
       IS
       SELECT *
       FROM   XX_CDH_EBL_CONCAT_FIELDS_TXT
       WHERE  cust_doc_id = p_scust_doc_id;

       -- Detail Information -- Added for MOD 4B Release 4
       ln_templ_dtl_txt_id     NUMBER;
       CURSOR lcu_templ_dtl_txt(p_field_id IN NUMBER)
       IS
       SELECT   nvl(xcett.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcecft.conc_field_id)            field_id_val
         ,xcecft.conc_field_label                  field_name_val
         ,nvl(xcett.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcett.seq                                seq_val
         ,xcett.*
       FROM  XX_CDH_EBL_TEMPL_DTL_TXT xcett,
             XX_CDH_EBL_CONCAT_FIELDS_TXT xcecft
       WHERE xcett.cust_doc_id = xcecft.cust_doc_id
       AND xcett.field_id = xcecft.conc_field_id
       AND xcett.cust_doc_id = p_scust_doc_id
       AND xcecft.conc_field_id = p_field_id
       AND xcecft.tab = 'D';

       -- Header Information -- Added for MOD 4B Release 4
       ln_templ_hdr_txt_id     NUMBER;
       CURSOR lcu_templ_hdr_txt(p_field_id IN NUMBER)
       IS
       SELECT   nvl(xcett.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcecft.conc_field_id)            field_id_val
         ,xcecft.conc_field_label                  field_name_val
         ,nvl(xcett.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcett.seq                                seq_val
         ,xcett.*
       FROM  XX_CDH_EBL_TEMPL_HDR_TXT xcett,
             XX_CDH_EBL_CONCAT_FIELDS_TXT xcecft
       WHERE xcett.cust_doc_id = xcecft.cust_doc_id
       AND xcett.field_id = xcecft.conc_field_id
       AND xcett.cust_doc_id = p_scust_doc_id
       AND xcecft.conc_field_id = p_field_id
       AND xcecft.tab = 'H';

       -- Trailer Information -- Added for MOD 4B Release 4
       ln_templ_trl_txt_id     NUMBER;
       CURSOR lcu_templ_trl_txt(p_field_id IN NUMBER)
       IS
       SELECT   nvl(xcett.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcecft.conc_field_id)            field_id_val
         ,xcecft.conc_field_label                  field_name_val
         ,nvl(xcett.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcett.seq                                seq_val
         ,xcett.*
       FROM  XX_CDH_EBL_TEMPL_TRL_TXT xcett,
             XX_CDH_EBL_CONCAT_FIELDS_TXT xcecft
       WHERE xcett.cust_doc_id = xcecft.cust_doc_id
       AND xcett.field_id = xcecft.conc_field_id
       AND xcett.cust_doc_id = p_scust_doc_id
       AND xcecft.conc_field_id = p_field_id
       AND xcecft.tab = 'T';

BEGIN
    -- -- Adding for MOD 4B Release 4
    IF  gc_delv_method = 'eTXT'
     THEN
       OPEN lcu_concat_fields_txt;
       LOOP
       FETCH lcu_concat_fields_txt INTO lt_rec_txt;
       EXIT WHEN lcu_concat_fields_txt%NOTFOUND;

         IF (lcu_concat_fields_txt%rowcount >0)
         THEN

            SELECT XX_CDH_EBL_CONCAT_FIELDS_TXT_S.NEXTVAL
              INTO ln_concat_fields_txt_id
              FROM dual;
        -- Call the Package XX_CDH_EBL_CONCATENATE_PKG to Insert records into the XX_CDH_EBL_CONCAT_FIELDS_TXT.
             XX_CDH_EBL_CONCATENATE_PKG.insert_row_txt(p_conc_field_id            => ln_concat_fields_txt_id
                                                      ,p_cust_doc_id              => p_dcust_doc_id
                                                      ,p_cust_account_id          => lt_rec_txt.cust_account_id
                                                      ,p_conc_base_field_id1      => lt_rec_txt.conc_base_field_id1
                                                      ,p_conc_base_field_id2      => lt_rec_txt.conc_base_field_id2
                                                      ,p_conc_base_field_id3      => lt_rec_txt.conc_base_field_id3
                                                      ,p_conc_base_field_id4      => lt_rec_txt.conc_base_field_id4
                                                      ,p_conc_base_field_id5      => lt_rec_txt.conc_base_field_id5
                                                      ,p_conc_base_field_id6      => lt_rec_txt.conc_base_field_id6
                                                      ,p_conc_field_label         => lt_rec_txt.conc_field_label
                                                      ,p_attribute1               => lt_rec_txt.attribute1
                                                      ,p_attribute2               => lt_rec_txt.attribute2
                                                      ,p_attribute3               => lt_rec_txt.attribute3
                                                      ,p_attribute4               => lt_rec_txt.attribute4
                                                      ,p_attribute5               => lt_rec_txt.attribute5
                                                      ,p_attribute6               => lt_rec_txt.attribute6
                                                      ,p_attribute7               => lt_rec_txt.attribute7
                                                      ,p_attribute8               => lt_rec_txt.attribute8
                                                      ,p_attribute9               => lt_rec_txt.attribute9
                                                      ,p_attribute10              => lt_rec_txt.attribute10
                                                      ,p_attribute11              => lt_rec_txt.attribute11
                                                      ,p_attribute12              => lt_rec_txt.attribute12
                                                      ,p_attribute13              => lt_rec_txt.attribute13
                                                      ,p_attribute14              => lt_rec_txt.attribute14
                                                      ,p_attribute15              => lt_rec_txt.attribute15
                                                      ,p_attribute16              => lt_rec_txt.attribute16
                                                      ,p_attribute17              => lt_rec_txt.attribute17
                                                      ,p_attribute18              => lt_rec_txt.attribute18
                                                      ,p_attribute19              => lt_rec_txt.attribute19
                                                      ,p_attribute20              => lt_rec_txt.attribute20
                                                      ,p_request_id               => NULL
                                                      ,p_program_application_id   => NULL
                                                      ,p_program_id               => NULL
                                                      ,p_program_update_date      => NULL
                                                      ,p_wh_update_date           => NULL
                                                      ,p_tab                      => lt_rec_txt.tab
                                                      ,p_seq1                     => lt_rec_txt.seq1
                                                      ,p_seq2                     => lt_rec_txt.seq2
                                                      ,p_seq3                     => lt_rec_txt.seq3
                                                      ,p_seq4                     => lt_rec_txt.seq4
                                                      ,p_seq5                     => lt_rec_txt.seq5
                                                      ,p_seq6                     => lt_rec_txt.seq6
                                                  );
                 -- Inserting into XX_CDH_EBL_TEMPL_DTL_TXT table
                 FOR lcu_rec_txt IN lcu_templ_dtl_txt(lt_rec_txt.conc_field_id)
                 LOOP

                     SELECT XX_CDH_EBL_TEMPL_DTL_TXT_S.NEXTVAL
                       INTO ln_templ_dtl_txt_id
                       FROM dual;

                       XX_CDH_EBL_TEMPL_DTL_PKG.insert_row_txt(p_ebl_templ_id           =>ln_templ_dtl_txt_id
                                                              ,p_cust_doc_id            =>p_dcust_doc_id
                                                              ,p_seq                    =>lcu_rec_txt.seq_val
                                                              ,p_field_id               =>ln_concat_fields_txt_id
                                                              ,p_label                  =>nvl(lcu_rec_txt.label,lcu_rec_txt.field_name_val)
                                                              ,p_start_pos              =>lcu_rec_txt.start_pos
                                                              ,p_field_len              =>lcu_rec_txt.field_len
                                                              ,p_data_format            =>lcu_rec_txt.data_format
                                                              ,p_string_fun             =>lcu_rec_txt.string_fun
                                                              ,p_sort_order             =>lcu_rec_txt.sort_order
                                                              ,p_sort_type              =>lcu_rec_txt.sort_type
                                                              ,p_mandatory              =>lcu_rec_txt.mandatory
                                                              ,p_seq_start_val          =>lcu_rec_txt.seq_start_val
                                                              ,p_seq_inc_val            =>lcu_rec_txt.seq_inc_val
                                                              ,p_seq_reset_field        =>lcu_rec_txt.seq_reset_field
                                                              ,p_constant_value         =>lcu_rec_txt.constant_value
                                                              ,p_alignment              =>lcu_rec_txt.alignment
                                                              ,p_padding_char           =>lcu_rec_txt.padding_char
                                                              ,p_default_if_null        =>lcu_rec_txt.default_if_null
                                                              ,p_comments               =>lcu_rec_txt.comments
                                                              ,p_attribute1             =>nvl(lcu_rec_txt.attribute1,'N')
                                                              ,p_attribute2             =>lcu_rec_txt.attribute2_val
                                                              ,p_attribute3             =>lcu_rec_txt.attribute3_val
                                                              ,p_attribute4             =>lcu_rec_txt.attribute4
                                                              ,p_attribute5             =>lcu_rec_txt.attribute5
                                                              ,p_attribute6             =>lcu_rec_txt.attribute6
                                                              ,p_attribute7             =>lcu_rec_txt.attribute7
                                                              ,p_attribute8             =>lcu_rec_txt.attribute8
                                                              ,p_attribute9             =>lcu_rec_txt.attribute9
                                                              ,p_attribute10            =>lcu_rec_txt.attribute10
                                                              ,p_attribute11            =>lcu_rec_txt.attribute11
                                                              ,p_attribute12            =>lcu_rec_txt.attribute12
                                                              ,p_attribute13            =>lcu_rec_txt.attribute13
                                                              ,p_attribute14            =>lcu_rec_txt.attribute14
                                                              ,p_attribute15            =>lcu_rec_txt.attribute15
                                                              ,p_attribute16            =>lcu_rec_txt.attribute16
                                                              ,p_attribute17            =>lcu_rec_txt.attribute17
                                                              ,p_attribute18            =>lcu_rec_txt.attribute18
                                                              ,p_attribute19            =>lcu_rec_txt.attribute19
                                                              ,p_attribute20            =>nvl(lcu_rec_txt.attribute20,'Y')
                                                              ,p_request_id             =>NULL
                                                              ,p_program_application_id =>NULL
                                                              ,p_program_id             =>NULL
                                                              ,p_program_update_date    =>NULL
                                                              ,p_wh_update_date         =>NULL
                                                              ,p_concatenate            =>lcu_rec_txt.concatenate
                                                              ,p_split                  =>lcu_rec_txt.split
                                                              ,p_base_field_id          =>lcu_rec_txt.base_field_id
                                                              ,p_split_field_id         =>lcu_rec_txt.split_field_id
                                                              ,p_start_txt_pos          =>lcu_rec_txt.start_txt_pos
                                                              ,p_end_txt_pos            =>lcu_rec_txt.end_txt_pos
                                                              ,p_fill_txt_pos           =>lcu_rec_txt.fill_txt_pos
                                                              ,p_justify_txt            =>lcu_rec_txt.justify_txt
                                                              ,p_include_header         =>lcu_rec_txt.include_header
                                                              ,p_repeat_header          =>lcu_rec_txt.repeat_header
                                                              ,p_start_val_pos          =>lcu_rec_txt.start_val_pos
                                                              ,p_end_val_pos            =>lcu_rec_txt.end_val_pos
                                                              ,p_prepend_char           =>lcu_rec_txt.prepend_char
                                                              ,p_append_char            =>lcu_rec_txt.append_char
                                                              ,p_record_type            =>lcu_rec_txt.record_type_val
															  ,p_repeat_total_flag      =>lcu_rec_txt.repeat_total_flag
															  ,p_tax_up_flag            =>lcu_rec_txt.tax_up_flag
															  ,p_freight_up_flag        =>lcu_rec_txt.freight_up_flag
															  ,p_misc_up_flag           =>lcu_rec_txt.misc_up_flag
															  ,p_tax_ep_flag            =>lcu_rec_txt.tax_ep_flag
															  ,p_freight_ep_flag        =>lcu_rec_txt.freight_ep_flag
															  ,p_misc_ep_flag           =>lcu_rec_txt.misc_ep_flag	
                                                              ,p_rownumber              =>lcu_rec_txt.rownumber	-- Added by Reddy Sekhar K on 10-AUG-2017 for Defect#41307														  
                                                              ,p_absolute_value_flag    =>lcu_rec_txt.absolute_flag	 ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                              ,p_dcindicator            =>lcu_rec_txt.dc_indicator	 ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                              ,p_db_cr_seperator        => lcu_rec_txt.db_cr_seperator ---Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                                                             );
                 END LOOP;
                 -- Inserting into XX_CDH_EBL_TEMPL_HDR_TXT table
                 FOR lcu_rec_txt IN lcu_templ_hdr_txt(lt_rec_txt.conc_field_id)
                 LOOP

                     SELECT XX_CDH_EBL_TEMPL_HDR_TXT_S.NEXTVAL
                       INTO ln_templ_hdr_txt_id
                       FROM dual;

                       XX_CDH_EBL_TEMPL_HEADER_PKG.insert_row_txt(p_ebl_templhdr_id        =>ln_templ_hdr_txt_id
                                                                 ,p_cust_doc_id            =>p_dcust_doc_id
                                                                 ,p_include_label          =>lcu_rec_txt.include_label
                                                                 ,p_record_type            =>lcu_rec_txt.record_type_val
                                                                 ,p_seq                    =>lcu_rec_txt.seq_val
                                                                 ,p_field_id               =>ln_concat_fields_txt_id
                                                                 ,p_label                  =>nvl(lcu_rec_txt.label,lcu_rec_txt.field_name_val)
                                                                 ,p_start_pos              =>lcu_rec_txt.start_pos
                                                                 ,p_field_len              =>lcu_rec_txt.field_len
                                                                 ,p_data_format            =>lcu_rec_txt.data_format
                                                                 ,p_string_fun             =>lcu_rec_txt.string_fun
                                                                 ,p_sort_order             =>lcu_rec_txt.sort_order
                                                                 ,p_sort_type              =>lcu_rec_txt.sort_type
                                                                 ,p_mandatory              =>lcu_rec_txt.mandatory
                                                                 ,p_seq_start_val          =>lcu_rec_txt.seq_start_val
                                                                 ,p_seq_inc_val            =>lcu_rec_txt.seq_inc_val
                                                                 ,p_seq_reset_field        =>lcu_rec_txt.seq_reset_field
                                                                 ,p_constant_value         =>lcu_rec_txt.constant_value
                                                                 ,p_alignment              =>lcu_rec_txt.alignment
                                                                 ,p_padding_char           =>lcu_rec_txt.padding_char
                                                                 ,p_default_if_null        =>lcu_rec_txt.default_if_null
                                                                 ,p_comments               =>lcu_rec_txt.comments
                                                                 ,p_attribute1             =>nvl(lcu_rec_txt.attribute1,'N')
                                                                 ,p_attribute2             =>lcu_rec_txt.attribute2_val
                                                                 ,p_attribute3             =>lcu_rec_txt.attribute3_val
                                                                 ,p_attribute4             =>lcu_rec_txt.attribute4
                                                                 ,p_attribute5             =>lcu_rec_txt.attribute5
                                                                 ,p_attribute6             =>lcu_rec_txt.attribute6
                                                                 ,p_attribute7             =>lcu_rec_txt.attribute7
                                                                 ,p_attribute8             =>lcu_rec_txt.attribute8
                                                                 ,p_attribute9             =>lcu_rec_txt.attribute9
                                                                 ,p_attribute10            =>lcu_rec_txt.attribute10
                                                                 ,p_attribute11            =>lcu_rec_txt.attribute11
                                                                 ,p_attribute12            =>lcu_rec_txt.attribute12
                                                                 ,p_attribute13            =>lcu_rec_txt.attribute13
                                                                 ,p_attribute14            =>lcu_rec_txt.attribute14
                                                                 ,p_attribute15            =>lcu_rec_txt.attribute15
                                                                 ,p_attribute16            =>lcu_rec_txt.attribute16
                                                                 ,p_attribute17            =>lcu_rec_txt.attribute17
                                                                 ,p_attribute18            =>lcu_rec_txt.attribute18
                                                                 ,p_attribute19            =>lcu_rec_txt.attribute19
                                                                 ,p_attribute20            =>nvl(lcu_rec_txt.attribute20,'Y')
                                                                 ,p_request_id             =>NULL
                                                                 ,p_program_application_id =>NULL
                                                                 ,p_program_id             =>NULL
                                                                 ,p_program_update_date    =>NULL
                                                                 ,p_wh_update_date         =>NULL
                                                                 ,p_concatenate            =>lcu_rec_txt.concatenate
                                                                 ,p_split                  =>lcu_rec_txt.split
                                                                 ,p_base_field_id          =>lcu_rec_txt.base_field_id
                                                                 ,p_split_field_id         =>lcu_rec_txt.split_field_id
                                                                 ,p_rownumber              =>lcu_rec_txt.rownumber
                                                                 ,p_start_txt_pos          =>lcu_rec_txt.start_txt_pos
                                                                 ,p_end_txt_pos            =>lcu_rec_txt.end_txt_pos
                                                                 ,p_fill_txt_pos           =>lcu_rec_txt.fill_txt_pos
                                                                 ,p_justify_txt            =>lcu_rec_txt.justify_txt
                                                                 ,p_start_val_pos          =>lcu_rec_txt.start_val_pos
                                                                 ,p_end_val_pos            =>lcu_rec_txt.end_val_pos
                                                                 ,p_prepend_char           =>lcu_rec_txt.prepend_char
                                                                 ,p_append_char            =>lcu_rec_txt.append_char
                                                                 ,p_absolute_value_flag    =>lcu_rec_txt.absolute_flag
                                                                 ,p_dcindicator            =>lcu_rec_txt.dc_indicator
                                                                 ,p_db_cr_seperator        =>lcu_rec_txt.db_cr_seperator  ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364																	 
                                                                );
                 END LOOP;

                 -- Inserting into XX_CDH_EBL_TEMPL_TRL_TXT table
                 FOR lcu_rec_txt IN lcu_templ_trl_txt(lt_rec_txt.conc_field_id)
                 LOOP

                     SELECT XX_CDH_EBL_TEMPL_TRL_TXT_S.NEXTVAL
                       INTO ln_templ_trl_txt_id
                       FROM dual;

                      XX_CDH_EBL_TEMPL_TRL_TXT_PKG.insert_row_txt(p_ebl_templtrl_id        =>ln_templ_trl_txt_id
                                                                 ,p_cust_doc_id            =>p_dcust_doc_id
                                                                 ,p_include_label          =>lcu_rec_txt.include_label
                                                                 ,p_record_type            =>lcu_rec_txt.record_type_val
                                                                 ,p_seq                    =>lcu_rec_txt.seq_val
                                                                 ,p_field_id               =>ln_concat_fields_txt_id
                                                                 ,p_label                  =>nvl(lcu_rec_txt.label,lcu_rec_txt.field_name_val)
                                                                 ,p_start_pos              =>lcu_rec_txt.start_pos
                                                                 ,p_field_len              =>lcu_rec_txt.field_len
                                                                 ,p_data_format            =>lcu_rec_txt.data_format
                                                                 ,p_string_fun             =>lcu_rec_txt.string_fun
                                                                 ,p_sort_order             =>lcu_rec_txt.sort_order
                                                                 ,p_sort_type              =>lcu_rec_txt.sort_type
                                                                 ,p_mandatory              =>lcu_rec_txt.mandatory
                                                                 ,p_seq_start_val          =>lcu_rec_txt.seq_start_val
                                                                 ,p_seq_inc_val            =>lcu_rec_txt.seq_inc_val
                                                                 ,p_seq_reset_field        =>lcu_rec_txt.seq_reset_field
                                                                 ,p_constant_value         =>lcu_rec_txt.constant_value
                                                                 ,p_alignment              =>lcu_rec_txt.alignment
                                                                 ,p_padding_char           =>lcu_rec_txt.padding_char
                                                                 ,p_default_if_null        =>lcu_rec_txt.default_if_null
                                                                 ,p_comments               =>lcu_rec_txt.comments
                                                                 ,p_attribute1             =>nvl(lcu_rec_txt.attribute1,'N')
                                                                 ,p_attribute2             =>lcu_rec_txt.attribute2_val
                                                                 ,p_attribute3             =>lcu_rec_txt.attribute3_val
                                                                 ,p_attribute4             =>lcu_rec_txt.attribute4
                                                                 ,p_attribute5             =>lcu_rec_txt.attribute5
                                                                 ,p_attribute6             =>lcu_rec_txt.attribute6
                                                                 ,p_attribute7             =>lcu_rec_txt.attribute7
                                                                 ,p_attribute8             =>lcu_rec_txt.attribute8
                                                                 ,p_attribute9             =>lcu_rec_txt.attribute9
                                                                 ,p_attribute10            =>lcu_rec_txt.attribute10
                                                                 ,p_attribute11            =>lcu_rec_txt.attribute11
                                                                 ,p_attribute12            =>lcu_rec_txt.attribute12
                                                                 ,p_attribute13            =>lcu_rec_txt.attribute13
                                                                 ,p_attribute14            =>lcu_rec_txt.attribute14
                                                                 ,p_attribute15            =>lcu_rec_txt.attribute15
                                                                 ,p_attribute16            =>lcu_rec_txt.attribute16
                                                                 ,p_attribute17            =>lcu_rec_txt.attribute17
                                                                 ,p_attribute18            =>lcu_rec_txt.attribute18
                                                                 ,p_attribute19            =>lcu_rec_txt.attribute19
                                                                 ,p_attribute20            =>nvl(lcu_rec_txt.attribute20,'Y')
                                                                 ,p_request_id             =>NULL
                                                                 ,p_program_application_id =>NULL
                                                                 ,p_program_id             =>NULL
                                                                 ,p_program_update_date    =>NULL
                                                                 ,p_wh_update_date         =>NULL
                                                                 ,p_concatenate            =>lcu_rec_txt.concatenate
                                                                 ,p_split                  =>lcu_rec_txt.split
                                                                 ,p_base_field_id          =>lcu_rec_txt.base_field_id
                                                                 ,p_split_field_id         =>lcu_rec_txt.split_field_id
                                                                 ,p_rownumber              =>lcu_rec_txt.rownumber
                                                                 ,p_start_txt_pos          =>lcu_rec_txt.start_txt_pos
                                                                 ,p_end_txt_pos            =>lcu_rec_txt.end_txt_pos
                                                                 ,p_fill_txt_pos           =>lcu_rec_txt.fill_txt_pos
                                                                 ,p_justify_txt            =>lcu_rec_txt.justify_txt
                                                                 ,p_start_val_pos          =>lcu_rec_txt.start_val_pos
                                                                 ,p_end_val_pos            =>lcu_rec_txt.end_val_pos
                                                                 ,p_prepend_char           =>lcu_rec_txt.prepend_char
                                                                 ,p_append_char            =>lcu_rec_txt.append_char
                                                                 ,p_absolute_value_flag    =>lcu_rec_txt.absolute_flag   ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                                 ,p_dcindicator            =>lcu_rec_txt.dc_indicator
													             ,p_db_cr_seperator        =>lcu_rec_txt.db_cr_seperator  ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                                                                 );
                 END LOOP;
        END IF;
    END LOOP;
    CLOSE lcu_concat_fields_txt;

     ELSE
    -- End of adding MOD4B Release 4 Changes
     OPEN lcu_concat_fields;
     LOOP
     FETCH lcu_concat_fields INTO lt_rec;
     EXIT WHEN lcu_concat_fields%NOTFOUND;

-- Call the Package XX_CDH_EBL_TEMPL_HEADER_PKG to Insert records into the XX_CDH_EBL_CONCAT_FIELDS.
    IF (lcu_concat_fields%rowcount >0)
    THEN
               SELECT xx_cdh_ebl_concat_fields_s.nextval
               INTO ln_concat_field_id
               FROM dual;

               XX_CDH_EBL_CONCATENATE_PKG.insert_row (  p_conc_field_id       =>ln_concat_field_id
                                                   ,p_conc_field_label        =>lt_rec.conc_field_label
                                                   ,p_cust_account_id         =>lt_rec.cust_account_id
                                                   ,p_cust_doc_id              =>p_dcust_doc_id
                                                   ,p_conc_base_field_id1     =>lt_rec.conc_base_field_id1
                                                   ,p_conc_base_field_id2     =>lt_rec.conc_base_field_id2
                                                   ,p_conc_base_field_id3     =>lt_rec.conc_base_field_id3
                                                   ,p_attribute1              =>lt_rec.attribute1
                                                   ,p_attribute2              =>lt_rec.attribute2
                                                   ,p_attribute3              =>lt_rec.attribute3
                                                   ,p_attribute4              =>lt_rec.attribute4
                                                   ,p_attribute5              =>lt_rec.attribute5
                                                   ,p_attribute6              =>lt_rec.attribute6
                                                   ,p_attribute7              =>lt_rec.attribute7
                                                   ,p_attribute8              =>lt_rec.attribute8
                                                   ,p_attribute9              =>lt_rec.attribute9
                                                   ,p_attribute10             =>lt_rec.attribute10
                                                   ,p_attribute11             =>lt_rec.attribute11
                                                   ,p_attribute12             =>lt_rec.attribute12
                                                   ,p_attribute13             =>lt_rec.attribute13
                                                   ,p_attribute14             =>lt_rec.attribute14
                                                   ,p_attribute15             =>lt_rec.attribute15
                                                   ,p_attribute16             =>lt_rec.attribute16
                                                   ,p_attribute17             =>lt_rec.attribute17
                                                   ,p_attribute18             =>lt_rec.attribute18
                                                   ,p_attribute19             =>lt_rec.attribute19
                                                   ,p_attribute20             =>lt_rec.attribute20
                                                   ,p_last_update_date        =>SYSDATE
                                                   ,p_last_updated_by         =>FND_GLOBAL.USER_ID
                                                   ,p_creation_date           =>SYSDATE
                                                   ,p_created_by              =>FND_GLOBAL.USER_ID
                                                   ,p_last_update_login       =>FND_GLOBAL.USER_ID
                                                   ,p_request_id              =>NULL
                                                   ,p_program_application_id  =>NULL
                                                   ,p_program_id              =>NULL
                                                   ,p_program_update_date     =>NULL
                                                   ,p_wh_update_date          =>NULL
                                                   );

               FOR lcu_rec IN lcu_templ_dtl(lt_rec.conc_field_id)
               LOOP

                 SELECT XX_CDH_EBL_TEMPL_ID_S.NEXTVAL
                 INTO ln_ebl_templ_id
                 FROM dual;

                 XX_CDH_EBL_TEMPL_DTL_PKG.insert_row(p_ebl_templ_id           =>ln_ebl_templ_id
                                                        ,p_cust_doc_id            =>p_dcust_doc_id
                                                        ,p_record_type            =>lcu_rec.record_type_val--Defect 7231
                                                        ,p_seq                    =>lcu_rec.seq_val  --Defect 7588
                                                        ,p_field_id               =>ln_concat_field_id --lcu_rec.field_id_val --Defect 7231
                                                        ,p_label                  =>nvl(lcu_rec.label,lcu_rec.field_name_val) --Defect 7231
                                                        ,p_start_pos              =>lcu_rec.start_pos
                                                        ,p_field_len              =>lcu_rec.field_len
                                                        ,p_data_format            =>lcu_rec.data_format
                                                        ,p_string_fun             =>lcu_rec.string_fun
                                                        ,p_sort_order             =>lcu_rec.sort_order
                                                        ,p_sort_type              =>lcu_rec.sort_type
                                                        ,p_mandatory              =>lcu_rec.mandatory
                                                        ,p_seq_start_val          =>lcu_rec.seq_start_val
                                                        ,p_seq_inc_val            =>lcu_rec.seq_inc_val
                                                        ,p_seq_reset_field        =>lcu_rec.seq_reset_field
                                                        ,p_constant_value         =>lcu_rec.constant_value
                                                        ,p_alignment              =>lcu_rec.alignment
                                                        ,p_padding_char           =>lcu_rec.padding_char
                                                        ,p_default_if_null        =>lcu_rec.default_if_null
                                                        ,p_comments               =>lcu_rec.comments
                                                        ,p_attribute1             =>nvl(lcu_rec.attribute1,'N')--Defect 7231
                                                        ,p_attribute2             =>lcu_rec.attribute2_val--Defect 7231
                                                        ,p_attribute3             =>lcu_rec.attribute3_val--Defect 7231
                                                        ,p_attribute4             =>lcu_rec.attribute4
                                                        ,p_attribute5             =>lcu_rec.attribute5
                                                        ,p_attribute6             =>lcu_rec.attribute6
                                                        ,p_attribute7             =>lcu_rec.attribute7
                                                        ,p_attribute8             =>lcu_rec.attribute8
                                                        ,p_attribute9             =>lcu_rec.attribute9
                                                        ,p_attribute10            =>lcu_rec.attribute10
                                                        ,p_attribute11            =>lcu_rec.attribute11
                                                        ,p_attribute12            =>lcu_rec.attribute12
                                                        ,p_attribute13            =>lcu_rec.attribute13
                                                        ,p_attribute14            =>lcu_rec.attribute14
                                                        ,p_attribute15            =>lcu_rec.attribute15
                                                        ,p_attribute16            =>lcu_rec.attribute16
                                                        ,p_attribute17            =>lcu_rec.attribute17
                                                        ,p_attribute18            =>lcu_rec.attribute18
                                                        ,p_attribute19            =>lcu_rec.attribute19
                                                        ,p_attribute20            =>nvl(lcu_rec.attribute20,'Y')--Defect 7231
                                                        ,p_last_update_date       =>SYSDATE
                                                        ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date          =>SYSDATE
                                                        ,p_created_by             =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                        ,p_request_id             =>NULL
                                                        ,p_program_application_id =>NULL
                                                        ,p_program_id             =>NULL
                                                        ,p_program_update_date    =>NULL
                                                        ,p_wh_update_date         =>NULL
                                                        ,p_concatenate            =>lcu_rec.concatenate
                                                        ,p_split                  =>lcu_rec.split
                                                        ,p_base_field_id          =>lcu_rec.base_field_id
                                                        ,p_split_field_id         =>lcu_rec.split_field_id
														,p_repeat_total_flag      =>lcu_rec.repeat_total_flag
                                                        );

               END LOOP;
    END IF;
    END LOOP;
    CLOSE lcu_concat_fields;
   END IF;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_CONCATENATE_DETAIL;

  -- +==================================================================================+
  -- | Name             : COPY_SPLIT_DETAIL                                             |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_SPLIT_FIELDS                                      |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_SPLIT_DETAIL(
                            p_scust_doc_id IN NUMBER,
                            p_dcust_doc_id IN NUMBER
                           )

IS
       lt_rec  XX_CDH_EBL_SPLIT_FIELDS%ROWTYPE;

       CURSOR lcu_split_fields
       IS
       SELECT *
       FROM   XX_CDH_EBL_SPLIT_FIELDS
       WHERE  cust_doc_id = p_scust_doc_id;
       ln_split_field_id XX_CDH_EBL_SPLIT_FIELDS.split_field_id%TYPE;

       CURSOR lcu_templ_dtl(p_split_field_id IN NUMBER)
       IS
       SELECT   nvl(xcet.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcet.field_id)                  field_id_val
         ,xcet.label                              field_name_val
         ,nvl(xcet.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcet.seq                                seq_val
         ,xcet.*
       FROM  XX_CDH_EBL_TEMPL_DTL xcet,
             XX_CDH_EBL_SPLIT_FIELDS xcecf
       WHERE xcet.cust_doc_id = xcecf.cust_doc_id
       AND xcet.base_field_id = xcecf.split_base_field_id
       AND xcet.cust_doc_id = p_scust_doc_id
       AND xcecf.split_field_id = p_split_field_id;

       ln_ebl_templ_id NUMBER;
       ln_dtl_field_id NUMBER;

       -- Added for MOD 4B Release 4
       ln_split_fields_txt_id  NUMBER;
       lt_rec_txt              XX_CDH_EBL_SPLIT_FIELDS_TXT%ROWTYPE;

       CURSOR lcu_split_fields_txt
       IS
       SELECT *
       FROM   XX_CDH_EBL_SPLIT_FIELDS_TXT
       WHERE  cust_doc_id = p_scust_doc_id;   -- Added for MOD 4B Release 4

       -- Detail Information -- Added for MOD4B Release 4
       ln_templ_dtl_txt_id     NUMBER;
       ln_dtl_txt_field_id     NUMBER;
       CURSOR lcu_templ_dtl_txt(p_split_field_id IN NUMBER)
       IS
       SELECT   nvl(xcett.cust_doc_id,p_scust_doc_id)     cust_doc
         ,to_char(xcett.field_id)                  field_id_val
         ,xcett.label                              field_name_val
         ,nvl(xcett.record_type,'000')             record_type_val
         ,NULL                                    attribute2_val
         ,NULL                                    attribute3_val
         ,xcett.seq                                seq_val
         ,xcett.*
       FROM  XX_CDH_EBL_TEMPL_DTL_TXT xcett,
             XX_CDH_EBL_SPLIT_FIELDS_TXT xcecft
       WHERE xcett.cust_doc_id = xcecft.cust_doc_id
       AND xcett.base_field_id = xcecft.split_base_field_id
       AND xcett.cust_doc_id = p_scust_doc_id
       AND xcecft.split_field_id = p_split_field_id;

BEGIN
     -- Adding for MOD4B Rel 4 Changes
     IF  gc_delv_method = 'eTXT'
     THEN
       OPEN lcu_split_fields_txt;
       LOOP
       FETCH lcu_split_fields_txt INTO lt_rec_txt;
       EXIT WHEN lcu_split_fields_txt%NOTFOUND;

        IF (lcu_split_fields_txt%ROWCOUNT > 0)
        THEN

            SELECT XX_CDH_EBL_SPLIT_FIELDS_TXT_S.NEXTVAL
              INTO ln_split_fields_txt_id
              FROM dual;
        -- Call the Package XX_CDH_EBL_SPLIT_PKG to Insert records into the XX_CDH_EBL_SPLIT_FIELDS_TXT.
             XX_CDH_EBL_SPLIT_PKG.insert_row_txt(p_split_field_id           => ln_split_fields_txt_id
                                                ,p_cust_doc_id              => p_dcust_doc_id
                                                ,p_cust_account_id          => lt_rec_txt.cust_account_id
                                                ,p_split_base_field_id      => lt_rec_txt.split_base_field_id
                                                ,p_split_field1_label       => lt_rec_txt.split_field1_label
                                                ,p_split_field2_label       => lt_rec_txt.split_field2_label
                                                ,p_split_field3_label       => lt_rec_txt.split_field3_label
                                                ,p_split_field4_label       => lt_rec_txt.split_field4_label
                                                ,p_split_field5_label       => lt_rec_txt.split_field5_label
                                                ,p_split_field6_label       => lt_rec_txt.split_field6_label
                                                ,p_fixed_position           => lt_rec_txt.fixed_position
                                                ,p_delimiter                => lt_rec_txt.delimiter
                                                ,p_attribute1               => lt_rec_txt.attribute1
                                                ,p_attribute2               => lt_rec_txt.attribute2
                                                ,p_attribute3               => lt_rec_txt.attribute3
                                                ,p_attribute4               => lt_rec_txt.attribute4
                                                ,p_attribute5               => lt_rec_txt.attribute5
                                                ,p_attribute6               => lt_rec_txt.attribute6
                                                ,p_attribute7               => lt_rec_txt.attribute7
                                                ,p_attribute8               => lt_rec_txt.attribute8
                                                ,p_attribute9               => lt_rec_txt.attribute9
                                                ,p_attribute10              => lt_rec_txt.attribute10
                                                ,p_attribute11              => lt_rec_txt.attribute11
                                                ,p_attribute12              => lt_rec_txt.attribute12
                                                ,p_attribute13              => lt_rec_txt.attribute13
                                                ,p_attribute14              => lt_rec_txt.attribute14
                                                ,p_attribute15              => lt_rec_txt.attribute15
                                                ,p_attribute16              => lt_rec_txt.attribute16
                                                ,p_attribute17              => lt_rec_txt.attribute17
                                                ,p_attribute18              => lt_rec_txt.attribute18
                                                ,p_attribute19              => lt_rec_txt.attribute19
                                                ,p_attribute20              => lt_rec_txt.attribute20
                                                ,p_request_id               => NULL
                                                ,p_program_application_id   => NULL
                                                ,p_program_id               => NULL
                                                ,p_program_update_date      => NULL
                                                ,p_wh_update_date           => NULL
                                                ,p_split_type               => lt_rec_txt.split_type
                                                ,p_tab                      => lt_rec_txt.tab
                                              );
              -- Inserting into XX_CDH_EBL_TEMPL_DTL_TXT table
              FOR lcu_rec_txt IN lcu_templ_dtl_txt(lt_rec_txt.split_field_id)
               LOOP

                 SELECT XX_CDH_EBL_TEMPL_DTL_TXT_S.NEXTVAL
                 INTO ln_templ_dtl_txt_id
                 FROM dual;

                 SELECT XX_CDH_EBL_SPLIT_FIELDS_TXT_S.NEXTVAL
                 INTO ln_dtl_txt_field_id
                 FROM dual;

                 XX_CDH_EBL_TEMPL_DTL_PKG.insert_row_txt(p_ebl_templ_id           =>ln_templ_dtl_txt_id
                                                        ,p_cust_doc_id            =>p_dcust_doc_id
                                                        ,p_seq                    =>lcu_rec_txt.seq_val
                                                        ,p_field_id               =>ln_dtl_txt_field_id
                                                        ,p_label                  =>nvl(lcu_rec_txt.label,lcu_rec_txt.field_name_val)
                                                        ,p_start_pos              =>lcu_rec_txt.start_pos
                                                        ,p_field_len              =>lcu_rec_txt.field_len
                                                        ,p_data_format            =>lcu_rec_txt.data_format
                                                        ,p_string_fun             =>lcu_rec_txt.string_fun
                                                        ,p_sort_order             =>lcu_rec_txt.sort_order
                                                        ,p_sort_type              =>lcu_rec_txt.sort_type
                                                        ,p_mandatory              =>lcu_rec_txt.mandatory
                                                        ,p_seq_start_val          =>lcu_rec_txt.seq_start_val
                                                        ,p_seq_inc_val            =>lcu_rec_txt.seq_inc_val
                                                        ,p_seq_reset_field        =>lcu_rec_txt.seq_reset_field
                                                        ,p_constant_value         =>lcu_rec_txt.constant_value
                                                        ,p_alignment              =>lcu_rec_txt.alignment
                                                        ,p_padding_char           =>lcu_rec_txt.padding_char
                                                        ,p_default_if_null        =>lcu_rec_txt.default_if_null
                                                        ,p_comments               =>lcu_rec_txt.comments
                                                        ,p_attribute1             =>nvl(lcu_rec_txt.attribute1,'N')
                                                        ,p_attribute2             =>lcu_rec_txt.attribute2_val
                                                        ,p_attribute3             =>lcu_rec_txt.attribute3_val
                                                        ,p_attribute4             =>lcu_rec_txt.attribute4
                                                        ,p_attribute5             =>lcu_rec_txt.attribute5
                                                        ,p_attribute6             =>lcu_rec_txt.attribute6
                                                        ,p_attribute7             =>lcu_rec_txt.attribute7
                                                        ,p_attribute8             =>lcu_rec_txt.attribute8
                                                        ,p_attribute9             =>lcu_rec_txt.attribute9
                                                        ,p_attribute10            =>lcu_rec_txt.attribute10
                                                        ,p_attribute11            =>lcu_rec_txt.attribute11
                                                        ,p_attribute12            =>lcu_rec_txt.attribute12
                                                        ,p_attribute13            =>lcu_rec_txt.attribute13
                                                        ,p_attribute14            =>lcu_rec_txt.attribute14
                                                        ,p_attribute15            =>lcu_rec_txt.attribute15
                                                        ,p_attribute16            =>lcu_rec_txt.attribute16
                                                        ,p_attribute17            =>lcu_rec_txt.attribute17
                                                        ,p_attribute18            =>lcu_rec_txt.attribute18
                                                        ,p_attribute19            =>lcu_rec_txt.attribute19
                                                        ,p_attribute20            =>nvl(lcu_rec_txt.attribute20,'Y')
                                                        ,p_request_id             =>NULL
                                                        ,p_program_application_id =>NULL
                                                        ,p_program_id             =>NULL
                                                        ,p_program_update_date    =>NULL
                                                        ,p_wh_update_date         =>NULL
                                                        ,p_concatenate            =>lcu_rec_txt.concatenate
                                                        ,p_split                  =>lcu_rec_txt.split
                                                        ,p_base_field_id          =>lcu_rec_txt.base_field_id
                                                        ,p_split_field_id         =>ln_split_fields_txt_id
                                                        ,p_start_txt_pos          =>lcu_rec_txt.start_txt_pos
                                                        ,p_end_txt_pos            =>lcu_rec_txt.end_txt_pos
                                                        ,p_fill_txt_pos           =>lcu_rec_txt.fill_txt_pos
                                                        ,p_justify_txt            =>lcu_rec_txt.justify_txt
                                                        ,p_include_header         =>lcu_rec_txt.include_header
                                                        ,p_repeat_header          =>lcu_rec_txt.repeat_header
                                                        ,p_start_val_pos          =>lcu_rec_txt.start_val_pos
                                                        ,p_end_val_pos            =>lcu_rec_txt.end_val_pos
                                                        ,p_prepend_char           =>lcu_rec_txt.prepend_char
                                                        ,p_append_char            =>lcu_rec_txt.append_char
                                                        ,p_record_type            =>lcu_rec_txt.record_type_val
													    ,p_repeat_total_flag      =>lcu_rec_txt.repeat_total_flag
													    ,p_tax_up_flag            =>lcu_rec_txt.tax_up_flag
													    ,p_freight_up_flag        =>lcu_rec_txt.freight_up_flag
													    ,p_misc_up_flag           =>lcu_rec_txt.misc_up_flag
													    ,p_tax_ep_flag            =>lcu_rec_txt.tax_ep_flag
													    ,p_freight_ep_flag        =>lcu_rec_txt.freight_ep_flag
													    ,p_misc_ep_flag           =>lcu_rec_txt.misc_ep_flag
                                                        ,p_rownumber              =>lcu_rec_txt.rownumber  --Added by Reddy Sekhar K on 10-AUG-2017 for Defect#41307														
                                                        ,p_absolute_value_flag    =>lcu_rec_txt.absolute_flag  --Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                                                        ,p_dcindicator            =>lcu_rec_txt.dc_indicator,
							                             p_db_cr_seperator        =>lcu_rec_txt.db_cr_seperator  --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                                                        );

               END LOOP;

        END IF;
      END LOOP;
      CLOSE lcu_split_fields_txt;
     ELSE
     -- End of adding for MOD4B Rel 4 Changes
     OPEN lcu_split_fields;
     LOOP
     FETCH lcu_split_fields INTO lt_rec;
     EXIT WHEN lcu_split_fields%NOTFOUND;

-- Call the Package XX_CDH_EBL_TEMPL_HEADER_PKG to Insert records into the XX_CDH_EBL_SPLIT_FIELDS.
    IF (lcu_split_fields%rowcount >0)
    THEN
               SELECT XX_CDH_EBL_SPLIT_FIELDS_S.nextval
               INTO ln_split_field_id
               FROM dual;

               XX_CDH_EBL_SPLIT_PKG.insert_row (  p_split_field_id            =>ln_split_field_id
                                                  ,p_split_base_field_id      =>lt_rec.split_base_field_id
                                                  ,p_fixed_position           =>lt_rec.fixed_position
                                                  ,p_delimiter                =>lt_rec.delimiter
                                                  ,p_split_field1_label       =>lt_rec.split_field1_label
                                                  ,p_split_field2_label       =>lt_rec.split_field2_label
                                                  ,p_split_field3_label       =>lt_rec.split_field3_label
                                                  ,p_split_field4_label       =>lt_rec.split_field4_label
                                                  ,p_split_field5_label       =>lt_rec.split_field5_label
                                                  ,p_split_field6_label       =>lt_rec.split_field6_label
                                                  ,p_cust_account_id          =>lt_rec.cust_account_id
                                                  ,p_cust_doc_id              =>p_dcust_doc_id
                                                  ,p_attribute1               =>lt_rec.attribute1
                                                  ,p_attribute2               =>lt_rec.attribute2
                                                  ,p_attribute3               =>lt_rec.attribute3
                                                  ,p_attribute4               =>lt_rec.attribute4
                                                  ,p_attribute5               =>lt_rec.attribute5
                                                  ,p_attribute6               =>lt_rec.attribute6
                                                  ,p_attribute7               =>lt_rec.attribute7
                                                  ,p_attribute8               =>lt_rec.attribute8
                                                  ,p_attribute9               =>lt_rec.attribute9
                                                  ,p_attribute10              =>lt_rec.attribute10
                                                  ,p_attribute11              =>lt_rec.attribute11
                                                  ,p_attribute12              =>lt_rec.attribute12
                                                  ,p_attribute13              =>lt_rec.attribute13
                                                  ,p_attribute14              =>lt_rec.attribute14
                                                  ,p_attribute15              =>lt_rec.attribute15
                                                  ,p_attribute16              =>lt_rec.attribute16
                                                  ,p_attribute17              =>lt_rec.attribute17
                                                  ,p_attribute18              =>lt_rec.attribute18
                                                  ,p_attribute19              =>lt_rec.attribute19
                                                  ,p_attribute20              =>lt_rec.attribute20
                                                  ,p_last_update_date         =>SYSDATE
                                                  ,p_last_updated_by          =>FND_GLOBAL.USER_ID
                                                  ,p_creation_date            =>SYSDATE
                                                  ,p_created_by               =>FND_GLOBAL.USER_ID
                                                  ,p_last_update_login        =>FND_GLOBAL.USER_ID
                                                  ,p_request_id               =>NULL
                                                  ,p_program_application_id   =>NULL
                                                  ,p_program_id               =>NULL
                                                  ,p_program_update_date      =>NULL
                                                  ,p_wh_update_date           =>NULL
                                                  ,p_split_type               =>lt_rec.split_type
                                                  );

               FOR lcu_rec IN lcu_templ_dtl(lt_rec.split_field_id)
               LOOP

                 SELECT XX_CDH_EBL_TEMPL_ID_S.NEXTVAL
                 INTO ln_ebl_templ_id
                 FROM dual;

                 SELECT XX_CDH_EBL_SPLIT_FIELDS_S.nextval
                 INTO ln_dtl_field_id
                 FROM dual;

                 XX_CDH_EBL_TEMPL_DTL_PKG.insert_row(p_ebl_templ_id           =>ln_ebl_templ_id
                                                        ,p_cust_doc_id            =>p_dcust_doc_id
                                                        ,p_record_type            =>lcu_rec.record_type_val--Defect 7231
                                                        ,p_seq                    =>lcu_rec.seq_val  --Defect 7588
                                                        ,p_field_id               =>ln_dtl_field_id --lcu_rec.field_id_val --Defect 7231
                                                        ,p_label                  =>nvl(lcu_rec.label,lcu_rec.field_name_val) --Defect 7231
                                                        ,p_start_pos              =>lcu_rec.start_pos
                                                        ,p_field_len              =>lcu_rec.field_len
                                                        ,p_data_format            =>lcu_rec.data_format
                                                        ,p_string_fun             =>lcu_rec.string_fun
                                                        ,p_sort_order             =>lcu_rec.sort_order
                                                        ,p_sort_type              =>lcu_rec.sort_type
                                                        ,p_mandatory              =>lcu_rec.mandatory
                                                        ,p_seq_start_val          =>lcu_rec.seq_start_val
                                                        ,p_seq_inc_val            =>lcu_rec.seq_inc_val
                                                        ,p_seq_reset_field        =>lcu_rec.seq_reset_field
                                                        ,p_constant_value         =>lcu_rec.constant_value
                                                        ,p_alignment              =>lcu_rec.alignment
                                                        ,p_padding_char           =>lcu_rec.padding_char
                                                        ,p_default_if_null        =>lcu_rec.default_if_null
                                                        ,p_comments               =>lcu_rec.comments
                                                        ,p_attribute1             =>nvl(lcu_rec.attribute1,'N')--Defect 7231
                                                        ,p_attribute2             =>lcu_rec.attribute2_val--Defect 7231
                                                        ,p_attribute3             =>lcu_rec.attribute3_val--Defect 7231
                                                        ,p_attribute4             =>lcu_rec.attribute4
                                                        ,p_attribute5             =>lcu_rec.attribute5
                                                        ,p_attribute6             =>lcu_rec.attribute6
                                                        ,p_attribute7             =>lcu_rec.attribute7
                                                        ,p_attribute8             =>lcu_rec.attribute8
                                                        ,p_attribute9             =>lcu_rec.attribute9
                                                        ,p_attribute10            =>lcu_rec.attribute10
                                                        ,p_attribute11            =>lcu_rec.attribute11
                                                        ,p_attribute12            =>lcu_rec.attribute12
                                                        ,p_attribute13            =>lcu_rec.attribute13
                                                        ,p_attribute14            =>lcu_rec.attribute14
                                                        ,p_attribute15            =>lcu_rec.attribute15
                                                        ,p_attribute16            =>lcu_rec.attribute16
                                                        ,p_attribute17            =>lcu_rec.attribute17
                                                        ,p_attribute18            =>lcu_rec.attribute18
                                                        ,p_attribute19            =>lcu_rec.attribute19
                                                        ,p_attribute20            =>nvl(lcu_rec.attribute20,'Y')--Defect 7231
                                                        ,p_last_update_date       =>SYSDATE
                                                        ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date          =>SYSDATE
                                                        ,p_created_by             =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                        ,p_request_id             =>NULL
                                                        ,p_program_application_id =>NULL
                                                        ,p_program_id             =>NULL
                                                        ,p_program_update_date    =>NULL
                                                        ,p_wh_update_date         =>NULL
                                                        ,p_concatenate            =>lcu_rec.concatenate
                                                        ,p_split                  =>lcu_rec.split
                                                        ,p_base_field_id          =>lcu_rec.base_field_id
                                                        ,p_split_field_id         =>ln_split_field_id
														,p_repeat_total_flag      =>lcu_rec.repeat_total_flag
                                                        );

               END LOOP;
    END IF;
    END LOOP;
    CLOSE lcu_split_fields;
  END IF;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_SPLIT_DETAIL;

  -- +==================================================================================+
  -- | Name             : COPY_TEMPL_DETAIL_ETXT                                        |
  -- | Description      : This procedure copies data into the table                     |
  -- |                     XX_CDH_EBL_TEMPL_DTL only for eTXT Documents                 |
  -- |                                                                                  |
  -- +==================================================================================+


PROCEDURE COPY_TEMPL_DETAIL_ETXT (   p_scust_doc_id IN NUMBER
                                    ,p_dcust_doc_id IN NUMBER
                                 )
IS

ln_ebl_temp_id      NUMBER;

CURSOR lcu_temp_dtl_etxt
IS
SELECT *
FROM   XX_CDH_EBL_TEMPL_DTL
WHERE  cust_doc_id = p_scust_doc_id;

BEGIN

        FOR lcu_rec IN lcu_temp_dtl_etxt
        LOOP

                 SELECT XX_CDH_EBL_TEMPL_ID_S.NEXTVAL
                 INTO ln_ebl_temp_id
                 FROM dual;


                     XX_CDH_EBL_TEMPL_DTL_PKG.insert_row(p_ebl_templ_id           =>ln_ebl_temp_id
                                                        ,p_cust_doc_id            =>p_dcust_doc_id
                                                        ,p_record_type            =>lcu_rec.record_type
                                                        ,p_seq                    =>lcu_rec.seq
                                                        ,p_field_id               =>lcu_rec.field_id
                                                        ,p_label                  =>lcu_rec.label
                                                        ,p_start_pos              =>lcu_rec.start_pos
                                                        ,p_field_len              =>lcu_rec.field_len
                                                        ,p_data_format            =>lcu_rec.data_format
                                                        ,p_string_fun             =>lcu_rec.string_fun
                                                        ,p_sort_order             =>lcu_rec.sort_order
                                                        ,p_sort_type              =>lcu_rec.sort_type
                                                        ,p_mandatory              =>lcu_rec.mandatory
                                                        ,p_seq_start_val          =>lcu_rec.seq_start_val
                                                        ,p_seq_inc_val            =>lcu_rec.seq_inc_val
                                                        ,p_seq_reset_field        =>lcu_rec.seq_reset_field
                                                        ,p_constant_value         =>lcu_rec.constant_value
                                                        ,p_alignment              =>lcu_rec.alignment
                                                        ,p_padding_char           =>lcu_rec.padding_char
                                                        ,p_default_if_null        =>lcu_rec.default_if_null
                                                        ,p_comments               =>lcu_rec.comments
                                                        ,p_attribute1             =>lcu_rec.attribute1
                                                        ,p_attribute2             =>lcu_rec.attribute2
                                                        ,p_attribute3             =>lcu_rec.attribute3
                                                        ,p_attribute4             =>lcu_rec.attribute4
                                                        ,p_attribute5             =>lcu_rec.attribute5
                                                        ,p_attribute6             =>lcu_rec.attribute6
                                                        ,p_attribute7             =>lcu_rec.attribute7
                                                        ,p_attribute8             =>lcu_rec.attribute8
                                                        ,p_attribute9             =>lcu_rec.attribute9
                                                        ,p_attribute10            =>lcu_rec.attribute10
                                                        ,p_attribute11            =>lcu_rec.attribute11
                                                        ,p_attribute12            =>lcu_rec.attribute12
                                                        ,p_attribute13            =>lcu_rec.attribute13
                                                        ,p_attribute14            =>lcu_rec.attribute14
                                                        ,p_attribute15            =>lcu_rec.attribute15
                                                        ,p_attribute16            =>lcu_rec.attribute16
                                                        ,p_attribute17            =>lcu_rec.attribute17
                                                        ,p_attribute18            =>lcu_rec.attribute18
                                                        ,p_attribute19            =>lcu_rec.attribute19
                                                        ,p_attribute20            =>lcu_rec.attribute20
                                                        ,p_last_update_date       =>SYSDATE
                                                        ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date          =>SYSDATE
                                                        ,p_created_by             =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                        ,p_request_id             =>NULL
                                                        ,p_program_application_id =>NULL
                                                        ,p_program_id             =>NULL
                                                        ,p_program_update_date    =>NULL
                                                        ,p_wh_update_date         =>NULL
														,p_repeat_total_flag      =>lcu_rec.repeat_total_flag
                                                        );
        END LOOP;
EXCEPTION
WHEN OTHERS THEN
  RAISE;

END COPY_TEMPL_DETAIL_ETXT;

  -- +==================================================================================+
  -- | Name             : COPY_EBL_CONTACTS                                             |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                     XX_CDH_EBL_CONTACTS                                          |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_EBL_CONTACTS(
                             p_scust_doc_id  IN NUMBER
                            ,p_dcust_doc_id  IN NUMBER
                            ,p_scust_acct_id IN NUMBER
                            ,p_dcust_acct_id IN NUMBER
                           )
IS

ln_ebl_doc_contact_id      NUMBER;

CURSOR lcu_ebl_contacts
IS
SELECT *
FROM   XX_CDH_EBL_CONTACTS
WHERE  cust_doc_id = p_scust_doc_id;

BEGIN

    FOR lcu_rec IN lcu_ebl_contacts
    LOOP

    -- The Records should be copied in the Contacts table only if the Source and the Target Cust Account Ids are same.
     IF (p_scust_acct_id = p_dcust_acct_id)
     THEN
                     SELECT XX_CDH_EBL_DOC_CONTACT_ID_S.NEXTVAL
                     INTO ln_ebl_doc_contact_id
                     FROM dual;


                     XX_CDH_EBL_CONTACTS_PKG.insert_row( p_cust_doc_id               =>p_dcust_doc_id
                                                        ,p_ebl_doc_contact_id        =>ln_ebl_doc_contact_id
                                                        ,p_org_contact_id            =>lcu_rec.org_contact_id
                                                        ,p_cust_acct_site_id         =>lcu_rec.cust_acct_site_id
                                                        ,p_attribute1                =>lcu_rec.attribute1
                                                        ,p_attribute2                =>lcu_rec.attribute2
                                                        ,p_attribute3                =>lcu_rec.attribute3
                                                        ,p_attribute4                =>lcu_rec.attribute4
                                                        ,p_attribute5                =>lcu_rec.attribute5
                                                        ,p_attribute6                =>lcu_rec.attribute6
                                                        ,p_attribute7                =>lcu_rec.attribute7
                                                        ,p_attribute8                =>lcu_rec.attribute8
                                                        ,p_attribute9                =>lcu_rec.attribute9
                                                        ,p_attribute10               =>lcu_rec.attribute10
                                                        ,p_attribute11               =>lcu_rec.attribute11
                                                        ,p_attribute12               =>lcu_rec.attribute12
                                                        ,p_attribute13               =>lcu_rec.attribute13
                                                        ,p_attribute14               =>lcu_rec.attribute14
                                                        ,p_attribute15               =>lcu_rec.attribute15
                                                        ,p_attribute16               =>lcu_rec.attribute16
                                                        ,p_attribute17               =>lcu_rec.attribute17
                                                        ,p_attribute18               =>lcu_rec.attribute18
                                                        ,p_attribute19               =>lcu_rec.attribute19
                                                        ,p_attribute20               =>lcu_rec.attribute20
                                                        ,p_last_update_date          =>SYSDATE
                                                        ,p_last_updated_by           =>FND_GLOBAL.USER_ID
                                                        ,p_creation_date             =>SYSDATE
                                                        ,p_created_by                =>FND_GLOBAL.USER_ID
                                                        ,p_last_update_login         =>FND_GLOBAL.USER_ID
                                                        ,p_request_id                =>NULL
                                                        ,p_program_application_id    =>NULL
                                                        ,p_program_id                =>NULL
                                                        ,p_program_update_date       =>NULL
                                                        ,p_wh_update_date            =>NULL
                                                        );
    END IF;
    END LOOP;

  EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_EBL_CONTACTS;

  -- +==================================================================================+
  -- | Name             : COPY_EBL_FILE_NAME_DTL                                        |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                    XX_CDH_EBL_FILE_NAME_DTL                                      |
  -- |                                                                                  |
  -- +==================================================================================+
PROCEDURE COPY_EBL_FILE_NAME_DTL( p_scust_doc_id IN NUMBER
                                 ,p_dcust_doc_id IN NUMBER
                                )
IS

ln_ebl_file_name_id             NUMBER;

CURSOR lcu_ebl_file
IS
SELECT *
FROM   XX_CDH_EBL_FILE_NAME_DTL
WHERE  cust_doc_id = p_scust_doc_id;

BEGIN

    FOR lcu_rec IN lcu_ebl_file
    LOOP
                     SELECT XX_CDH_EBL_FILE_NAME_ID_S.NEXTVAL
                     INTO ln_ebl_file_name_id
                     FROM dual;


              XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row( p_ebl_file_name_id       =>ln_ebl_file_name_id
                                                      ,p_cust_doc_id            =>p_dcust_doc_id
                                                      ,p_file_name_order_seq    =>lcu_rec.file_name_order_seq
                                                      ,p_field_id               =>lcu_rec.field_id
                                                      ,p_constant_value         =>lcu_rec.constant_value
                                                      ,p_default_if_null        =>lcu_rec.default_if_null
                                                      ,p_comments               =>lcu_rec.comments
                                                      ,p_attribute1             =>lcu_rec.attribute1
                                                      ,p_attribute2             =>lcu_rec.attribute2
                                                      ,p_attribute3             =>lcu_rec.attribute3
                                                      ,p_attribute4             =>lcu_rec.attribute4
                                                      ,p_attribute5             =>lcu_rec.attribute5
                                                      ,p_attribute6             =>lcu_rec.attribute6
                                                      ,p_attribute7             =>lcu_rec.attribute7
                                                      ,p_attribute8             =>lcu_rec.attribute8
                                                      ,p_attribute9             =>lcu_rec.attribute9
                                                      ,p_attribute10            =>lcu_rec.attribute10
                                                      ,p_attribute11            =>lcu_rec.attribute11
                                                      ,p_attribute12            =>lcu_rec.attribute12
                                                      ,p_attribute13            =>lcu_rec.attribute13
                                                      ,p_attribute14            =>lcu_rec.attribute14
                                                      ,p_attribute15            =>lcu_rec.attribute15
                                                      ,p_attribute16            =>lcu_rec.attribute16
                                                      ,p_attribute17            =>lcu_rec.attribute17
                                                      ,p_attribute18            =>lcu_rec.attribute18
                                                      ,p_attribute19            =>lcu_rec.attribute19
                                                      ,p_attribute20            =>lcu_rec.attribute20
                                                      ,p_last_update_date       =>SYSDATE
                                                      ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                      ,p_creation_date          =>SYSDATE
                                                      ,p_created_by             =>FND_GLOBAL.USER_ID
                                                      ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                      ,p_request_id             =>NULL
                                                      ,p_program_application_id =>NULL
                                                      ,p_program_id             =>NULL
                                                      ,p_program_update_date    =>NULL
                                                      ,p_wh_update_date         =>NULL
                                                      );
    END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_EBL_FILE_NAME_DTL;


  -- +==================================================================================+
  -- | Name             : COPY_EBL_STD_AGGR_DTL                                         |
  -- | Description      : This procedure inserts data into the table                    |
  -- |                    XX_CDH_EBL_STD_AGGR_DTL                                       |
  -- |                                                                                  |
  -- +==================================================================================+

PROCEDURE COPY_EBL_STD_AGGR_DTL(  p_scust_doc_id IN NUMBER
                                 ,p_dcust_doc_id IN NUMBER
                               )
IS

ln_ebl_aggr_id                 NUMBER;

CURSOR lcu_ebl_aggr
IS
SELECT  *
FROM    XX_CDH_EBL_STD_AGGR_DTL
WHERE   cust_doc_id = p_scust_doc_id;

BEGIN

    FOR lcu_rec IN lcu_ebl_aggr
    LOOP
                     SELECT XX_CDH_EBL_AGGR_ID_S.NEXTVAL
                     INTO ln_ebl_aggr_id
                     FROM dual;


              XX_CDH_EBL_STD_AGGR_DTL_PKG.insert_row( p_ebl_aggr_id           =>ln_ebl_aggr_id
                                                    ,p_cust_doc_id            =>p_dcust_doc_id
                                                    ,p_aggr_fun               =>lcu_rec.aggr_fun
                                                    ,p_aggr_field_id          =>lcu_rec.aggr_field_id
                                                    ,p_change_field_id        =>lcu_rec.change_field_id
                                                    ,p_label_on_file          =>lcu_rec.label_on_file
                                                    ,p_attribute1             =>lcu_rec.attribute1
                                                    ,p_attribute2             =>lcu_rec.attribute2
                                                    ,p_attribute3             =>lcu_rec.attribute3
                                                    ,p_attribute4             =>lcu_rec.attribute4
                                                    ,p_attribute5             =>lcu_rec.attribute5
                                                    ,p_attribute6             =>lcu_rec.attribute6
                                                    ,p_attribute7             =>lcu_rec.attribute7
                                                    ,p_attribute8             =>lcu_rec.attribute8
                                                    ,p_attribute9             =>lcu_rec.attribute9
                                                    ,p_attribute10            =>lcu_rec.attribute10
                                                    ,p_attribute11            =>lcu_rec.attribute11
                                                    ,p_attribute12            =>lcu_rec.attribute12
                                                    ,p_attribute13            =>lcu_rec.attribute13
                                                    ,p_attribute14            =>lcu_rec.attribute14
                                                    ,p_attribute15            =>lcu_rec.attribute15
                                                    ,p_attribute16            =>lcu_rec.attribute16
                                                    ,p_attribute17            =>lcu_rec.attribute17
                                                    ,p_attribute18            =>lcu_rec.attribute18
                                                    ,p_attribute19            =>lcu_rec.attribute19
                                                    ,p_attribute20            =>lcu_rec.attribute20
                                                    ,p_last_update_date       =>SYSDATE
                                                    ,p_last_updated_by        =>FND_GLOBAL.USER_ID
                                                    ,p_creation_date          =>SYSDATE
                                                    ,p_created_by             =>FND_GLOBAL.USER_ID
                                                    ,p_last_update_login      =>FND_GLOBAL.USER_ID
                                                    ,p_request_id             =>NULL
                                                    ,p_program_application_id =>NULL
                                                    ,p_program_id             =>NULL
                                                    ,p_program_update_date    =>NULL
                                                    ,p_wh_update_date         =>NULL
                                                    );
    END LOOP;

  EXCEPTION
      WHEN OTHERS THEN
        RAISE;

END COPY_EBL_STD_AGGR_DTL;

END XX_CDH_EBL_COPY_PKG;
/
SHOW ERRORS;
EXIT;
SET VERIFY       OFF

  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  UPDATE_XX_OM_HEADER_ATTRIBUTES_ALL table                                           |
  -- |                                                                                            |
  -- |  Description:                                                                              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         20-NOV-2018  Aarthi           Initial version                                  |
  -- +============================================================================================+

update xx_ar_ebl_cons_hdr_main
set email_address = 'thilak.ethiraj@officedepot.com',bill_due_date = '25-FEB-19',status = 'MARKED_FOR_RENDER',batch_id=8976543249
where transmission_id in (3473775,
3473776,
3473774);

update xx_ar_ebl_transmission
set dest_email_addr = 'thilak.ethiraj@officedepot.com',status='SEND'
where transmission_id in 
(3479286,
3479281,
3479344,
3479282,
3473775,
3473776,
3473774);

update xx_ar_ebl_cons_hdr_main
set file_name = '28615186_117523437__405765970_3703009.PDF'
where transmission_id in (3473774);

update xx_ar_ebl_cons_hdr_main
set file_name = '28615186_117523437__405765956_3703007.PDF'
where transmission_id in (3473775);

update xx_ar_ebl_cons_hdr_main
set file_name = '28615186_117523437__405765908_3703008.PDF'
where transmission_id in (3473776);

update xx_ar_ebl_file
set billing_dt = '07-FEB-19',bill_due_dt = '25-FEB-19'
where transmission_id in (3473775,
3473776,
3473774);

UPDATE XX_AR_EBL_FILE SET CUST_DOC_ID =117705278
where transmission_id=3479282;

UPDATE XX_AR_EBL_TRANSMISSION SET CUSTOMER_DOC_ID = 117705278
where transmission_id=3479282;

update xx_ar_ebl_file
set file_name = '28615186_117523437__405765970_3703009.PDF'
where transmission_id in (3473774);

update xx_ar_ebl_file
set file_name = '28615186_117523437__405765956_3703007.PDF'
where transmission_id in (3473775);

update xx_ar_ebl_file
set file_name = '28615186_117523437__405765908_3703008.PDF'
where transmission_id in (3473776);


UPDATE xx_ar_ebl_transmission
set status='TEST_CG' 
where status='SEND'
and transmission_id NOT in 
(3479286,
3479281,
3479344,
3479282,
3473775,
3473776,
3473774);

COMMIT;
/

SHOW ERRORS;
EXIT;
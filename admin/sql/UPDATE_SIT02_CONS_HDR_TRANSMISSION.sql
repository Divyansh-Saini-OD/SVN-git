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
set email_address = 'thilak.ethiraj@officedepot.com',bill_due_date = '25-FEB-19',status = 'MARKED_FOR_RENDER' 
where transmission_id in (3473775,
3473776,
3473774);

update xx_ar_ebl_file
set billing_dt = '07-FEB-19',bill_due_dt = '25-FEB-19'
where transmission_id in (3473775,
3473776,
3473774);

update xx_ar_ebl_transmission
set dest_email_addr = 'thilak.ethiraj@officedepot.com'
where transmission_id in 
(3479286,
3479281,
3479344,
3479282,
3473775,
3473776,
3473774);


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
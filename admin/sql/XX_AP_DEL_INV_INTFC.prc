create or replace PROCEDURE XX_AP_DEL_INV_INTFC
( p_batch_id IN NUMBER
) AS
/******************************************************************************
   NAME:       xx_ap_del_inv_intfc
   PURPOSE:    This procedure will read the Supplier base tables for any changes and write
               it to outputfile for TDM and Datalink.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        7/09/2008   Sandeep Pandhare Created this procedure.
   1.1        01/03/2017  Paddy Sanjeevi   GSCC Fix
******************************************************************************/

 /* Define constants */ 
c_when constant DATE := sysdate;

BEGIN

delete from xx_ap_inv_lines_interface_stg
where invoice_id in (select invoice_id from xx_ap_inv_interface_stg
where batch_id = p_batch_id);

delete from xx_ap_inv_interface_stg
where batch_id = p_batch_id;

Commit;

END XX_AP_DEL_INV_INTFC;

/

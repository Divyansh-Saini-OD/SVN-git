CREATE OR REPLACE PACKAGE xx_po_global_vendor_pkg IS
/**********************************************************************************
 Program Name: XX_PO_GLOBAL_VENDOR_PKG
 Purpose:      To translate legacy vendor_id to Oracle vendor_site_id and vice versa.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ------------------------------------ ---------------------
-- 1.0     07-FEB-2007 Greg Dill, Providge Consulting, LLC. Created base version.
-- 1.1     13-SEP-2007 Greg Dill, Providge Consulting, LLC. Added trx_date to f_translate_inbound.
--
**********************************************************************************/
  --Function to translate the inbound global vendor ID into the Oracle vendor_site_id.
  FUNCTION f_translate_inbound (v_global_vendor_id IN VARCHAR2 DEFAULT NULL,
                                v_trx_date DATE DEFAULT SYSDATE) RETURN NUMBER;

  --Function to translate the Oracle vendor_site_id into the outbound global vendor ID.
  FUNCTION f_get_outbound (v_vendor_site_id IN NUMBER DEFAULT NULL) RETURN VARCHAR2;

END xx_po_global_vendor_pkg;
/

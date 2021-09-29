SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON
PROMPT Creating PACKAGE XX_PO_GLOBAL_VENDOR_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY xx_po_global_vendor_pkg
IS
  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                         Wipro Technology                                      |
  -- +===============================================================================+
  -- | Program Name: XX_PO_GLOBAL_VENDOR_PKG                                         |
  -- | Purpose: To translate legacy vendor_id to Oracle vendor_site_id and vice versa|
  -- |                                                                               |
  -- | REVISIONS:                                                                    |
  -- | Version Date        Author                               Description          |
  -- | --------------- ----------- ------------------------------------ ------------ |
  -- | 1.0    07-FEB-2007 Greg Dill, Providge Consulting, LLC. Created base version. |
  -- | 1.1    10-JUL-2007 Greg Dill, Providge Consulting, LLC. Revised error handling|
  -- | 1.2    13-SEP-2007 Greg Dill, Providge Consulting, LLC. Added trx_date to     |
  -- |                                                         f_translate_inbound.  |
  -- | 1.3    23-SEP-2010 Sneha Anand                          Modified for Defect   |
  -- |                                                         6883 to pull the Pay  |
  -- |                                                         site ID for           |
  -- |                                                         Non-Converted Sites   |
  -- | 1.4    23-JUL-2013  Veronica M                          I1141 - Modified for  |
  -- |                                                         R12 Upgrade Retrofit. |
  -- | 1.5    23-SEP-2021  Mayur Palsokar                      NAIT-195643 - Modifie f_translate_inbound for Split change  |
  -- +===============================================================================+
FUNCTION f_translate_inbound(
    v_global_vendor_id IN VARCHAR2 DEFAULT NULL,
    v_trx_date DATE DEFAULT SYSDATE)
  RETURN NUMBER
IS
  --v_target_value po_vendor_sites_all.vendor_site_id%TYPE := -1;
  v_target_value ap_supplier_sites_all.vendor_site_id%TYPE := -1; -- Commented/Added for R12 Upgrade Retrofit By Veronica on 23-Jul-13
BEGIN
  BEGIN
    SELECT vendor_site_id
    INTO v_target_value
    FROM --po_vendor_sites_all                                                      -- Commented/Added for R12 Upgrade Retrofit By Veronica on 23-Jul-13
      ap_supplier_sites_all
    WHERE (attribute9   = v_global_vendor_id
    OR (vendor_site_id  = v_global_vendor_id
    AND attribute9     IS NULL))
    AND pay_site_flag   = 'Y'
    AND (inactive_date IS NULL
    OR inactive_date    > v_trx_date)
    AND ORG_ID          = FND_GLOBAL.ORG_ID(); -- Added for NAIT-195643
  EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    SELECT vendor_site_id
    INTO v_target_value
    FROM --po_vendor_sites_all                                                  -- Commented/Added for R12 Upgrade Retrofit By Veronica on 23-Jul-13
      ap_supplier_sites_all
    WHERE (attribute9         = v_global_vendor_id
    OR (vendor_site_id        = v_global_vendor_id
    AND attribute9           IS NULL))
    AND primary_pay_site_flag = 'Y'
    AND (inactive_date       IS NULL
    OR inactive_date          > v_trx_date)
    AND ORG_ID                = FND_GLOBAL.ORG_ID(); -- Added for NAIT-195643
  END;
  RETURN v_target_value;
EXCEPTION
WHEN OTHERS THEN
  RETURN -1;
END f_translate_inbound;

FUNCTION f_get_outbound(
    v_vendor_site_id IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2
IS
  -- v_target_value po_vendor_sites_all.attribute9%TYPE := -1;
  v_target_value ap_supplier_sites_all.attribute9%TYPE := -1; -- Commented/Added for R12 Upgrade Retrofit By Veronica on 23-Jul-13
BEGIN
  -- Start of changes for defect 6883
  -- SELECT NVL(attribute9, vendor_site_id)
  SELECT NVL(attribute9, NVL(vendor_site_code_alt,vendor_site_id))
    -- End of changes for defect 6883
  INTO v_target_value
  FROM --po_vendor_sites_all                                                          -- Commented/Added for R12 Upgrade Retrofit By Veronica on 23-Jul-13
    ap_supplier_sites_all
  WHERE vendor_site_id = v_vendor_site_id;
  RETURN v_target_value;
EXCEPTION
WHEN OTHERS THEN
  RETURN -1;
END f_get_outbound;
END xx_po_global_vendor_pkg;
/
SHO ERR
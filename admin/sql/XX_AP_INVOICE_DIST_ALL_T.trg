create or replace
TRIGGER xx_ap_invoice_dist_all_t
   BEFORE INSERT
   ON ap_invoice_distributions_all
   FOR EACH ROW
   WHEN (new.attribute7 = 'P')

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- +===============================================================================+
  -- | Name        : XX_AP_INVOICE_DIST_ALL_T.trg                                    |
  -- | Description : Trigger created per CR766. This trigger will set                |
  -- |               attribute7, attribute8, attribute9 to NULL if attribute7 = 'P'  | 
  -- |               on insert to table ap_invoice_distributions_all.  This is used  |
  -- |               to null out the attributes when any invoice distribution lines  |
  -- |               are copied or reversed from the Invoice Distribution form.      |
  -- |               Reference the MD70 for I2033_TWE_AP_ADAPTOR for more details.   |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |  1.0     27-AUG-2010 Joe Klein          Initial version                       |
  -- +===============================================================================+



BEGIN
   :new.attribute7 := NULL; 
   :new.attribute8 := NULL; 
   :new.attribute9 := NULL; 
END;

/
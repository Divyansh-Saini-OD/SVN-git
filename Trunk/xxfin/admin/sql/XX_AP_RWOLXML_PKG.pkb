create or replace 
PACKAGE BODY XX_AP_RWOLXML_PKG
AS
 FUNCTION beforeReport return BOOLEAN
  IS
   lc_boolean BOOLEAN;
   lc_boolean1 BOOLEAN;
  BEGIN
  fnd_file.put_line(fnd_file.log, 'setting printer in before report' );
  lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',style=>'A4',copies=>1);  
  lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);
commit;
 RETURN(TRUE);
   EXCEPTION WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Exception in before_report function '||SQLERRM );
  END beforeReport;
 FUNCTION afterReport return BOOLEAN
  IS
   lc_boolean BOOLEAN;
   lc_boolean1 BOOLEAN;
  BEGIN
  fnd_file.put_line(fnd_file.log, 'setting printer in before report' );
 -- lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);  
 -- lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);
 null;
 RETURN(TRUE);

   EXCEPTION WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Exception in after_report function '||SQLERRM );
  END afterReport;

END;
/
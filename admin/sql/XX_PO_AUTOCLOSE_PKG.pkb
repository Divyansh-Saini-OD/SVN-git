SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_AUTOCLOSE_PKG  
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_AUTOCLOSE_PKG                                                  |
-- | Description      : Package Body containing procedure AUTOCLOSEPO                        |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   05-MAR-2007      Madhusudan Aray   Initial draft version                      |
-- |DRAFT 1B   09-APR-2007      Madhusudan Aray   Incorporated Peer review Comments          |
-- |1.0        09-APR-2007      Madhusudan Aray   Base line                                  |
-- |1.1        18-JUN-2007      Ajit.P            Modified Query POH.type_lookup_code = 'STANDARD' |
-- |1.2        12-JUL-2007      Arun Andavar      Update the code to check for errored records|
-- |                                              and also added the statstics for it.       |
-- |1.3        18-JUL-2007      Vikas Raina       Updated the Query for closed_code!= 'CLOSED|
-- +=========================================================================================+

AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : AUTOCLOSEPO                                                          |
-- | Description      : This procedure is used to call a standard API "PO_ACTIONS.close_po"  |
-- |                      that will close the PO Lines based on the inactivity criteria.     |
-- |                    This procedure will print Supplier Name, Supplier No, PO No,         |
-- |                      Promise Date and Last Receipt Date  in the output.                 |
-- | Parameters       : p_inactive_days                                                      |
-- |                    p_po_type                                                            |
-- |                    p_debug_flag                                                         |
-- |                    x_err_buf                                                            |
-- |                    x_ret_code                                                           |
-- |                                                                                         |
-- +=========================================================================================+

PROCEDURE AUTOCLOSEPO (x_err_buf       OUT  VARCHAR2
                     , x_ret_code      OUT  NUMBER
                     , p_inactive_days IN   NUMBER
                     , p_po_type       IN   VARCHAR2
                     , p_debug_flag    IN   VARCHAR2 
                      )
IS  
  
-- Declaring Local variables

lc_return_code       VARCHAR2(100);
lb_status            BOOLEAN:=FALSE;
ln_no_of_lines       NUMBER := 0;
ln_succ_lines        NUMBER := 0;
ln_error_lines       NUMBER := 0;
lc_date              DATE   :=SYSDATE;

-- Declaring Cursor

CURSOR lcu_close_po_lines(p_inactive_days NUMBER
                         ,p_po_type       VARCHAR2)
IS

   SELECT PV.segment1          Supplier_No
         ,PV.vendor_name       Supplier_Name
         ,POH.segment1         PO_No
         ,PLL.promised_date    Promise_Date
         ,PO_LINE_LOCATIONS_AP_PKG.GET_LAST_RECEIPT(PLL.line_location_id) Last_Receipt_Date   
         ,POH.po_header_id
         ,POL.po_line_id
         ,PLL.line_location_id
   FROM   po_headers        POH
         ,po_lines          POL
         ,po_vendors        PV
         ,po_line_locations PLL
   WHERE POH.po_header_id = POL.po_header_id
   AND   POH.po_header_id = PLL.po_header_id 
   AND   POL.po_line_id = PLL.po_line_id 
   AND   POH.vendor_id = PV.vendor_id 
   AND   NVL(POH.approved_flag,'N')='Y' 
   AND   NVL(POL.closed_code,'OPEN') != 'CLOSED'
   AND   NVL(PLL.closed_code,'OPEN') != 'CLOSED'
   AND   POH.attribute_category = p_po_type
   AND   POH.type_lookup_code = 'STANDARD' -- Modified by Ajit.P 18-Jun-07
   AND   ((PLL.quantity_received > 0 AND
          SYSDATE - PO_LINE_LOCATIONS_AP_PKG.GET_LAST_RECEIPT(PLL.line_location_id) > = p_inactive_days)
   OR (PLL.quantity_received = 0 AND SYSDATE - PLL.promised_date > = p_inactive_days));

   -- Declaring Table type 

   TYPE lt_close_po_lines_ty IS TABLE OF lcu_close_po_lines%ROWTYPE
   INDEX BY BINARY_INTEGER;

   lt_close_po_lines lt_close_po_lines_ty;

   -- Beginning of the procedure

BEGIN
   
   --Printing the header of the output
   
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'_________________________________________________________________________________________');    
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Office Depot, Inc.                                         Report Date: '||lc_date);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');  
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                PO Auto-Close for Inactivity Report                              ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' PO Type         :'|| p_po_type);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Vendor          :All Vendors');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Inactivity Days :'|| p_inactive_days);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               '); 
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Supplier No.      Supplier Name                     PO No.       Promise Date    Last Receipt Date');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');        
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'               ');
   
   --Opening of cursor
   
   OPEN lcu_close_po_lines(p_inactive_days,p_po_type);

   FETCH lcu_close_po_lines BULK COLLECT INTO lt_close_po_lines;   
   ln_no_of_lines  := lt_close_po_lines.count ;
   
       IF ln_no_of_lines > 0 THEN
          FOR i IN lt_close_po_lines.FIRST..lt_close_po_lines.LAST
          LOOP

             IF (p_debug_flag = 'Y') THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'PO No. : '||lt_close_po_lines(i).PO_No);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Header Id : '||lt_close_po_lines(i).po_header_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Line Id : '||lt_close_po_lines(i).po_line_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Line Location Id : '||lt_close_po_lines(i).line_location_id);
             END IF;

             --Calling the API "PO_ACTIONS.close_po"

             lb_status := PO_ACTIONS.close_po
               (p_docid         => lt_close_po_lines(i).po_header_id,
                p_doctyp        => 'PO',
                p_docsubtyp     => 'STANDARD',
                p_lineid        => lt_close_po_lines(i).po_line_id,
                p_shipid        => lt_close_po_lines(i).line_location_id,
                p_action        => 'FINALLY CLOSE',
                p_reason        => 'Closed due to Inactivity',
                p_calling_mode  => 'PO',
                p_conc_flag     => 'Y',
                p_return_code   => lc_return_code,
                p_auto_close    => 'N',
                p_action_date   => SYSDATE,
                p_origin_doc_id => NULL
                );  

             IF lb_status= TRUE THEN 
                ln_succ_lines := ln_succ_lines + 1;
                --Printing the records
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lt_close_po_lines(i).Supplier_No,15,' ')||'   '
                                  ||RPAD(lt_close_po_lines(i).Supplier_Name,30,'  ')||'   '
                                  ||LPAD(lt_close_po_lines(i).PO_No,10,'   ')||'   '
                                  ||NVL(LPAD(lt_close_po_lines(i).Promise_Date,10,'   '),'          ')||'      '
                                  ||NVL(LPAD(lt_close_po_lines(i).Last_Receipt_Date,10,'   '),'          '));
             ELSE  -- when lb_status = FALSE ( When API returns FALSE for errored PO lines)
                ln_error_lines := ln_no_of_lines - ln_succ_lines;
             END IF;
             
          END LOOP;
       END IF;
       
       --Printing the footer of the output

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      '); 
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'__________________________________________________________________________________');  
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      ');                             
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Purchase Order Lines                                     : '||ln_no_of_lines);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Purchase Order Lines Successfully Closed                 : '||ln_succ_lines);       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Purchase Order Lines Errored Out while Closing           : '||ln_error_lines);       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'__________________________________________________________________________________');  
    
   CLOSE lcu_close_po_lines;
 
   COMMIT;

-- EXCEPTION
--   WHEN OTHERS THEN
--     NULL;
END AUTOCLOSEPO;

END XX_PO_AUTOCLOSE_PKG;
/
SHOW ERRORS;
EXIT;

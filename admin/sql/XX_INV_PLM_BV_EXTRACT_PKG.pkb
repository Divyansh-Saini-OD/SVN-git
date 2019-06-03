SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_PLM_BV_EXTRACT_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- +============================================================================================+ 
-- |  Name:  XX_INV_PLM_BV_EXTRACT_PKG                                                          | 
-- |  Description: Used to extract data for BV                                                  |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author             Remarks                                        | 
-- | =========   ===========  =============      =============================================  | 
-- | 1.0         13-JAN-2011  Bapuji Nanapaneni  Initial version                                |
-- | 1.1         03-Mar-2011  Paddy Sanjeevi     Removed hard code                              |
-- +============================================================================================+

PROCEDURE BV_EXTRACT AS

CURSOR c_bv_data IS 
SELECT a.vendor_no            VendorId
     , a.vendor_name          VendorName	   
     , ''                     ManufName	   
     , b.category             division_name	   
     , b.dept                 Dept#	   
     , a.po_number            PO#	   
     , a.po_date              PODate	   
     , b.po_line_no           POLine#	   
     , b.item                 SKU	   
     , b.origin               Origin	   
     , c.container_movement   CTNMovement	   
     , b.std_pack             STDPack	   
     , b.carton_pack          CTNPack	   
     , b.uom                  UOM
     , b.description          Description
     , b.ordered_qty          Qty
     , b.shipment_date        ShipDate
     , a.country_code         Country
     , a.port                 Port
     , a.edi_status           EdiStatus
     , a.PO_RECD_JDA_DATE     FromJDA
     , a.PO_CONFM_VEND_DATE    confByVendor	   
  FROM  apps.xx_gso_po_kn_dtl c
     ,  apps.xx_gso_po_dtl    b
     ,	apps.xx_gso_po_hdr    a	   
 WHERE  b.po_header_id = a.po_header_id    	  
   AND  a.vendor_no <> '729015'	   
   AND  c.po_number = a.po_number	   
   AND  c.sku = b.item	   
   AND  a.is_latest='Y'    	   
   AND  a.buying_agent = 'ODC'      	   
   AND  a.need_bv = 'Y'	   
   AND  b.latest_line_flag='Y'
   AND  b.bv_status <> 'Close'    	   
   AND  (c.kn_status <> 'Void' OR c.kn_status IS NULL)	   
   AND  c.cargo_received_date IS NULL	   
ORDER BY a.po_number, b.po_line_no;

-- Variable Declaration
  TYPE c_bv_data_type IS TABLE OF c_bv_data%rowtype;
  data_rec                c_bv_data_type;
  lc_outdata              VARCHAR2(4000);
  v_file                  UTL_FILE.FILE_TYPE;
  lc_file_path            VARCHAR2(100) := 'XXMER_OUTBOUND';
  lc_file_name            VARCHAR2(100);
  lc_sysdate              VARCHAR2(20);
  lc_header               VARCHAR2(4000);

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Begin of Program');
    
    SELECT TO_CHAR(SYSDATE,'MMDDYYYY') INTO lc_sysdate FROM DUAL;
    
    /* File Name Defined */
    lc_file_name := 'ODPOBV'||lc_sysdate||'.csv';
    
    /* Header Record defined */
    lc_header := 'VendorId'||','||'VendorName'||','||'ManufName'||','||'division_name'||','||'Dept#'||','||'PO#'||','||'PODate'||','||'POLine#'||','||'SKU'||','||'Origin'||','||'CTNMovement'||','||'STDPack'||','||'CTNPack'||','||'UOM'||','||'Description'||','||'Qty'||','||'ShipDate'||','||'Country'||','||'Port'||','||'EdiStatus'||','||'FromJDA'||','||'confByVendor';
    
    /* Open UTL file to write the content */
    v_file := UTL_FILE.FOPEN( location     => lc_file_path
                            , filename     => lc_file_name
                            , open_mode    => 'w'
                            , max_linesize => 32767
                            );
                            
     /* write Header record */
     UTL_FILE.PUT_LINE( v_file , lc_header);
     
     /* open cursor for bulk collect */
    OPEN c_bv_data;
    LOOP
    FETCH c_bv_data BULK COLLECT INTO data_rec LIMIT 2000;
        FOR i IN 1..data_rec.count
        LOOP
            --DBMS_OUTPUT.PUT_LINE('c_order.order_number :'|| data_rec(i).PO#);
            UTL_FILE.PUT_LINE( v_file ,
                            data_rec(i).VendorId        ||','||
                            data_rec(i).VendorName      ||','||
                            data_rec(i).ManufName       ||','||
                            data_rec(i).division_name   ||','||
                            data_rec(i).Dept#           ||','||
                            data_rec(i).PO#             ||','||
                            data_rec(i).PODate          ||','||
                            data_rec(i).POLine#         ||','||
                            data_rec(i).SKU             ||','||
                            data_rec(i).Origin          ||','||
                            data_rec(i).CTNMovement     ||','||
                            data_rec(i).STDPack         ||','||
                            data_rec(i).CTNPack         ||','||
                            data_rec(i).UOM             ||','||
                            data_rec(i).Description     ||','||
                            data_rec(i).Qty             ||','||
                            data_rec(i).ShipDate        ||','||
                            data_rec(i).Country         ||','||
                            data_rec(i).Port            ||','||
                            data_rec(i).EdiStatus       ||','||
                            data_rec(i).FromJDA         ||','||
                            data_rec(i).confByVendor    );
              --DBMS_OUTPUT.PUT_LINE('lc_outdata :'|| lc_outdata);
         END LOOP;
    EXIT WHEN c_bv_data%NOTFOUND;
    END LOOP;
    CLOSE c_bv_data;
    
    /*close UTL file */
    UTL_FILE.FCLOSE(v_file); 
    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'End of Program');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN 
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NO DATA FOUND');
    WHEN UTL_FILE.INVALID_PATH THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File location is invalid.');
    WHEN UTL_FILE.INVALID_MODE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The open_mode parameter in FOPEN is invalid.');
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File handle is invalid.');
    WHEN UTL_FILE.INVALID_OPERATION THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File could not be opened or operated on as requested.');
    WHEN UTL_FILE.READ_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Operating system error occurred during the read operation.');
    WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Operating system error occurred during the write operation.');
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unspecified PL/SQL error.');
    WHEN UTL_FILE.CHARSETMISMATCH THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                          'operations use nonchar functions such as PUTF or GET_LINE.');
    WHEN UTL_FILE.FILE_OPEN THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested operation failed because the file is open.');
    WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' || 
                                          'be within the range 1 to 32767.');
    WHEN UTL_FILE.INVALID_FILENAME THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The filename parameter is invalid.');
    WHEN UTL_FILE.ACCESS_DENIED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Permission to access to the file location is denied.');
    WHEN UTL_FILE.INVALID_OFFSET THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                          'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file.');
    WHEN UTL_FILE.DELETE_FAILED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested file delete operation failed.');
    WHEN UTL_FILE.RENAME_FAILED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested file rename operation failed.');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'WHEN OTHERS RAISED :'||SQLERRM);
END BV_EXTRACT;
END XX_INV_PLM_BV_EXTRACT_PKG;
/
SHOW ERRORS PACKAGE BODY XX_INV_PLM_BV_EXTRACT_PKG;
EXIT;

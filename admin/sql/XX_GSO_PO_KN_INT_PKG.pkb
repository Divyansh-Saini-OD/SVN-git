SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY APPS.xx_gso_po_kn_int_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gso_po_kn_int_pkg                                     |
-- | Description      : TThis package will interface GSO PO Shipment   |
-- |     Data from K+N staging table to the base tables                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0       25-DEC-2010  Rama Dwibhashyam Initial draft version      |
-- |1.1       06-Apr-2011  Paddy Sanjeevi   Reset the lv_valid_flag    |    
-- |1.2       19-Apr-2011  Paddy Sanjeevi   Modified existence of record check      |    
-- |1.3       15-Jun-2011  Paddy Sanjeevi   Modified to set PO status  |    
-- +===================================================================+
-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;
-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;
--
FUNCTION submit_report(p_prg IN VARCHAR2, p_name IN VARCHAR2,p_batch_id IN NUMBER)
RETURN VARCHAR2
IS
  v_addlayout 		boolean;
  v_wait 		BOOLEAN;
  v_request_id 		NUMBER;
  vc_request_id 	NUMBER;
  v_file_name 		varchar2(50);
  v_dfile_name		varchar2(50);
  v_sfile_name 		varchar2(50);
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;
BEGIN
   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXMER',
	 	                template_code => p_prg, 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');
  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER',p_prg,p_name,NULL,FALSE,
		TO_CHAR(p_batch_id),NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:=p_prg||'_'||to_char(v_request_id)||'_1.EXCEL';
     v_dfile_name:='$XXMER_DATA/outbound/'||to_char(v_request_id)||'.xls';
     v_sfile_name:=to_char(v_request_id)||'.xls';
  END IF;
  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN
        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;
        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;
 	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN
	   IF v_cdphase = 'COMPLETE' THEN  -- child 
	      RETURN(v_sfile_name);
 	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child
 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main
  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
END submit_report;
PROCEDURE send_exception_rpt(p_batch_id IN NUMBER)
IS
  v_addlayout         boolean;
  v_wait         BOOLEAN;
  v_request_id         NUMBER;
  vc_request_id     NUMBER;
  v_file_name         varchar2(50);
  v_dfile_name        varchar2(50);
  v_sfile_name         varchar2(50);
  x_dummy        varchar2(2000)     ;
  v_dphase        varchar2(100)    ;
  v_dstatus        varchar2(100)    ;
  v_phase        varchar2(100)   ;
  v_status        varchar2(100)   ;
  x_cdummy        varchar2(2000)     ;
  v_cdphase        varchar2(100)    ;
  v_cdstatus        varchar2(100)    ;
  v_cphase        varchar2(100)   ;
  v_cstatus        varchar2(100)   ;
  conn             utl_smtp.connection;
  lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_SC_SEND_MAIL');
  v_recipient        varchar2(100);
  v_sendfile1	varchar2(100);
  v_sendfile2	varchar2(100);
  v_sendfile3	varchar2(100);
BEGIN
  BEGIN
    SELECT a.description
      INTO v_recipient
      FROM apps.fnd_flex_values_vl a,
           apps.fnd_flex_value_sets b
     WHERE b.flex_value_set_name='XX_GSO_NOTIFICATION_LIST'
       AND b.flex_value_set_id=a.flex_value_set_id
       AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate) 
       AND a.flex_value='KN';
  EXCEPTION
    WHEN others THEN
      v_recipient:='IT_MerchEBS_Oncall@officedepot.com';
  END;
  conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'Oracle-EBS@officedepot.com',
	  	        recipients => v_recipient,
			cc_recipients=>v_recipient,
		        subject => 'GSO PO Shipment Exception Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
  v_sendfile1:=submit_report('XXMERRBNS','OD: MER Received But Not Ship Report',p_batch_id);
  v_sendfile2:=submit_report('XXMERSHPST','OD: MER Shipment Status Report',p_batch_id);
  v_sendfile3:=submit_report('XXMERSSOS','OD: MER Short and Over Ship Report',p_batch_id);
  xx_pa_pb_mail. xx_attach_excel(conn,v_sendfile1);
  xx_pa_pb_mail. xx_attach_excel(conn,v_sendfile2);
  xx_pa_pb_mail. xx_attach_excel(conn,v_sendfile3);
--  xx_pa_pb_mail.end_attachment(conn => conn);
  xx_pa_pb_mail.attach_text(conn => conn,
 		                      data => 'GSO PO Shipment Exceptions',
		                      mime_type => 'multipart/html');
  xx_pa_pb_mail.end_mail( conn => conn );
END send_exception_rpt;

-- +===================================================================+
-- | Name  :  process_kn_details                                                |
-- | Description      : TThis package will interface GSO PO Shipment   |
-- |     Data from K+N staging table to the base tables                |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-Dec-2010  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  --
  PROCEDURE process_kn_details ( x_errbuf   OUT NOCOPY varchar2
                                ,x_retcode  OUT NOCOPY varchar2 
                                ,p_load_batch_id IN number)
  IS
  lv_error_code varchar2(200);
  lv_error_msg  varchar2(2000);
  ln_kn_id     number ;
  ln_po_header_id number;
  ln_po_line_id   number;
  ln_po_line_no   number;
  lv_vendor_name  varchar2(150);
  lv_valid_flag   varchar2(1);
  ln_record_exist number ;
  lv_kn_status    varchar2(100);
  ld_cargo_rcv_dt  date ;
  ln_ordered_qty  number;
  ln_shipped_qty  number;
  ln_poship_qty	  number;
  ln_poship_amt	  number;  
  ln_total_ship	  number;
  ln_total_ord	  number;
  
  CURSOR cur_kn_dtl (p_load_batch_id number) is
  SELECT kn.rowid lrowid, kn.*
    FROM xx_gso_po_kn_stg kn
   WHERE process_flag = 1
     AND load_batch_id = p_load_batch_id
   ORDER BY po_number,po_line_no;

  CURSOR cur_po_dtl (p_po_number varchar2, p_sku varchar2) is
  SELECT dtl.po_header_id,dtl.po_line_id,dtl.po_line_no,hdr.vendor_name,dtl.ordered_qty,
	 NVL(dtl.shipped_qty,0) shipped_qty
    FROM xx_gso_po_dtl dtl,
         xx_gso_po_hdr hdr
   WHERE dtl.po_header_id = hdr.po_header_id
     AND hdr.po_number = p_po_number
     AND dtl.item = p_sku
     AND dtl.latest_line_flag='Y'
     AND hdr.is_latest = 'Y';

  CURSOR ln_update(p_load_batch_id number) IS
  select po_line_id,sum(actual_quantity) tqty,
	 kn_status
   from xx_gso_po_kn_dtl 
  where (po_header_id,po_line_id) in (select b.po_header_id,b.po_line_id
    					from apps.xx_gso_po_dtl b,apps.xx_gso_po_hdr a,
					     apps.xx_gso_po_kn_stg c
				       where c.load_batch_id=p_load_batch_id
					 and a.po_number=c.po_number
					 and a.is_latest='Y'
					 and b.po_header_id=a.po_header_id
					 and b.latest_line_flag='Y'
					 and b.po_line_no=c.po_line_no)
  group by po_line_id,kn_status
  order by 1;


  CURSOR cur_po_hdr (p_load_batch_id number) is
  sELECT hdr.po_header_id
    FROM xx_gso_po_hdr hdr
   WHERE EXISTS  ( SELECT 'x'
                     FROM xx_gso_po_kn_stg stg
                    WHERE hdr.po_number = stg.po_number
                      AND stg.load_batch_id = p_load_batch_id ) ;

    cursor cur_po_lines (p_load_batch_id number) is
    select dtl.po_header_id,dtl.po_line_id
      from xx_gso_po_dtl dtl
     where exists (select 'x'
                     from xx_gso_po_kn_stg stg,
                          xx_gso_po_hdr hdr
                    where hdr.po_number = stg.po_number
                      and dtl.item      = stg.sku
                      and stg.load_batch_id = p_load_batch_id ) ;

 BEGIN

    lv_error_msg := 'No Errors' ;
    --x_error_msg := lv_error_msg ;

    FOR kn_rec in cur_kn_dtl (p_load_batch_id)
    LOOP

	lv_valid_flag:='Y';
        IF     kn_rec.VEND_BOOK_DATE is null
           and (nvl(kn_rec.PO_LINE_CFS_RECD_D,kn_rec.FCL_CNTNR_CY_RECD_D) is null)
           and kn_rec.DATE_SHIPPED is null
        THEN
            lv_valid_flag := 'N' ;
--            lv_error_code := 'SHIP_DATE_NOT_FOUND' ;
--            lv_error_msg  := 'Book Date, Ship Date and Received date Not found for the KN Reference Line' ;
--            fnd_file.put_line (fnd_file.log,'Error Code :'||lv_error_code );
--            fnd_file.put_line (fnd_file.log,'Error Message :'||lv_error_msg );
            update xx_gso_po_kn_stg
               set process_flag = 7,
		   kn_process_Flag=7,
--                   error_flag   = 'Y',
--                   error_message = lv_error_msg,
                   last_update_date = sysdate,
                   last_updated_by = pvg_user_id
             where rowid = kn_rec.lrowid ;
             commit;
        END IF;

        OPEN cur_po_dtl (kn_rec.po_number,kn_rec.sku);
        FETCH cur_po_dtl INTO ln_po_header_id,ln_po_line_id,ln_po_line_no,lv_vendor_name,ln_ordered_qty,ln_shipped_qty;
        IF  cur_po_dtl%notfound THEN
       
            lv_valid_flag := 'N' ;
            lv_error_code := 'PO_NOT_FOUND' ;
            lv_error_msg  := 'PO Line Not found for the KN Reference Line' ;
            fnd_file.put_line (fnd_file.log,'Error Code :'||lv_error_code );
            fnd_file.put_line (fnd_file.log,'Error Message :'||lv_error_msg );
            update xx_gso_po_kn_stg
               set process_flag = 6,
		   kn_process_Flag=6,
                   error_flag   = 'Y',
                   error_message = lv_error_msg,
                   last_update_date = sysdate,
                   last_updated_by = pvg_user_id
             where rowid = kn_rec.lrowid ;
             commit;
			
       END IF;
       CLOSE cur_po_dtl ;

       IF ln_po_header_id is not null 
          and ln_po_line_id is not null
          and lv_valid_flag = 'Y'
       THEN
          begin
            select count(1)
              into ln_record_exist
              from xx_gso_po_kn_dtl
             where po_header_id=ln_po_header_id
	       and po_line_id=ln_po_line_id
	       and kn_reference = kn_rec.kn_reference;
          exception
            when no_data_found then
              ln_record_exist := 0 ;
          end ;
          If ln_record_exist = 0
          then
             ld_cargo_rcv_dt := nvl(kn_rec.PO_LINE_CFS_RECD_D,kn_rec.FCL_CNTNR_CY_RECD_D) ;
             if  kn_rec.date_shipped is not null then
                 lv_kn_status := 'SHIPPED' ;
             elsif ld_cargo_rcv_dt is not null  then
                lv_kn_status := 'RECEIVED' ;
             elsif kn_rec.vend_book_date is not null then
                   lv_kn_status := 'BOOKED' ;
             end if;

             select XX_GSO_PO_KN_S.NEXTVAL
               into ln_kn_id
               from dual ;
             Insert into xx_gso_po_kn_dtl
              (KN_ID        
              ,SUPPLIER_NAME        
              ,SUPPLIER_EDI_CODE     
              ,PO_NUMBER             
              ,PO_HEADER_ID          
              ,PO_LINE_ID            
              ,SKU                   
              ,VEND_BOOK_DATE        
              ,KN_BEFORE_BV_ALERT    
              ,PO_LINE_CFS_RECD_D    
              ,FCL_CNTNR_CY_RECD_D   
              ,CARGO_RECEIVED_ALERT  
              ,CARGO_RECEIVED_DATE   
              ,SHIPMENT_TYPE         
              ,KN_STATUS             
              ,SHIP_WINDOW_START     
              ,SHIP_WINDOW_END       
              ,ETS_ATS_D             
              ,DATE_SHIPPED          
              ,CONTAINER             
              ,CONTAINER_MOVEMENT    
              ,ACTUAL_QUANTITY       
              ,TOTAL_FOB_SHIPPED     
              ,UOM                   
              ,VOLUME                
              ,GROSSWEIGHT           
              ,KN_REFERENCE          
              ,ETA_ATA_D             
              ,ETA_PLACE_DELIVERY_D  
              ,PLACE_OF_DELIVERY     
              ,REQUIRED_DELIVERY_D   
              ,DELAY_CODE            
              ,DELAY_REASON          
              ,LOADING_PLACE         
              ,IMPORT_AGENT_FLAG   
              ,SH_ARRIVAL_PLACE   
              ,CREATION_DATE         
              ,CREATED_BY            
              ,LAST_UPDATED_BY       
              ,LAST_UPDATE_DATE      
              ,LAST_UPDATE_LOGIN     
              ,PO_LINE_NO            
              ,UPC                   
              ,DEPT_CODE             
              ,EXCHG_RATE            
              ,FIN_REPORT_DATE       
              ,FIN_REPORT_FLAG 
              ,final_destination      
              ) values
              (LN_KN_ID
              ,lv_vendor_name
              ,kn_rec.SUPPLIER_EDI_CODE     
              ,kn_rec.PO_NUMBER             
              ,ln_PO_HEADER_ID          
              ,ln_PO_LINE_ID            
              ,kn_rec.SKU                   
              ,kn_rec.VEND_BOOK_DATE        
              ,null  -- kn_before_bv_alert 
              ,kn_rec.PO_LINE_CFS_RECD_D    
              ,kn_rec.FCL_CNTNR_CY_RECD_D   
              , null  -- cargo_received_alert 
              ,ld_cargo_rcv_dt   --kn_rec.CARGO_RECEIVED_DATE   
              ,kn_rec.SHIPMENT_TYPE         
              ,lv_kn_status   --kn_rec.KN_STATUS             
              ,kn_rec.SHIP_WINDOW_START     
              ,kn_rec.SHIP_WINDOW_END       
              ,kn_rec.ETS_ATS_D             
              ,kn_rec.DATE_SHIPPED          
              ,kn_rec.CONTAINER             
              ,kn_rec.CONTAINER_MOVEMENT    
              ,kn_rec.ACTUAL_QUANTITY       
              ,kn_rec.TOTAL_FOB_SHIPPED     
              ,kn_rec.UOM                   
              ,kn_rec.VOLUME                
              ,kn_rec.GROSSWEIGHT           
              ,kn_rec.KN_REFERENCE          
              ,kn_rec.ETA_ATA_D             
              ,kn_rec.ETA_PLACE_DELIVERY_D  
              ,kn_rec.PLACE_OF_DELIVERY     
              ,kn_rec.REQUIRED_DELIVERY_D   
              ,kn_rec.DELAY_CODE            
              ,kn_rec.DELAY_REASON          
              ,kn_rec.LOADING_PLACE         
              ,kn_rec.IMPORT_AGENT_FLAG     
              ,kn_rec.SH_ARRIVAL_PLACE      
              ,sysdate         
              ,pvg_user_id            
              ,pvg_user_id       
              ,sysdate      
              ,pvg_login_id     
              ,ln_po_line_no
              ,null
              ,null
              ,null
              ,null
              ,null
              ,kn_rec.final_destination
              ) ;

            if  kn_rec.date_shipped is not null then
	         lv_kn_status := 'SHIPPED' ;
                 update xx_gso_po_dtl
                    set shipment_status = lv_kn_status
                  where po_line_id = ln_po_line_id ;
           
             elsif ld_cargo_rcv_dt is not null    then
	        lv_kn_status := 'RECEIVED' ;
        	     update xx_gso_po_dtl
                	set shipment_status = lv_kn_status
	              where po_line_id = ln_po_line_id ;
	      elsif kn_rec.vend_book_date is not null     then
	        lv_kn_status := 'BOOKED' ;
        	   update xx_gso_po_dtl
                      set shipment_status = lv_kn_status
	             where po_line_id = ln_po_line_id ;
	      end if;       

             update xx_gso_po_kn_stg
               set process_flag = 7,
                   kn_process_flag = 7,
                   error_flag   = 'N',
                   error_message = 'Success',
                   last_update_date = sysdate,
                   last_updated_by = pvg_user_id
             where rowid = kn_rec.lrowid ;
             
           ELSE   --ln_record_exist = 0

	       ld_cargo_rcv_dt := nvl(kn_rec.PO_LINE_CFS_RECD_D,kn_rec.FCL_CNTNR_CY_RECD_D) ;
               if  kn_rec.date_shipped is not null then
	           lv_kn_status := 'SHIPPED' ;
             
                   update xx_gso_po_dtl
                      set shipment_status = lv_kn_status
                    where po_line_id = ln_po_line_id ;
           
               elsif ld_cargo_rcv_dt is not null    then
	   
                    lv_kn_status := 'RECEIVED' ;
        	     update xx_gso_po_dtl
                	set shipment_status = lv_kn_status
	              where po_line_id = ln_po_line_id ;

 	       elsif kn_rec.vend_book_date is not null     then

 	            lv_kn_status := 'BOOKED' ;
          	    update xx_gso_po_dtl
                       set shipment_status = lv_kn_status
	             where po_line_id = ln_po_line_id ;
	       end if;       
            
               update xx_gso_po_kn_dtl
                 set vend_book_date = kn_rec.vend_book_date
                  ,po_line_cfs_recd_d = kn_rec.po_line_cfs_recd_d
                  ,fcl_cntnr_cy_recd_d = kn_rec.fcl_cntnr_cy_recd_d
                  ,cargo_received_date = ld_cargo_rcv_dt
                  ,shipment_type       = kn_rec.shipment_type
                  ,kn_status = lv_kn_status
                  ,ship_window_start   = kn_rec.ship_window_start
                  ,ship_window_end     = kn_rec.ship_window_end
                  ,ets_ats_d           = kn_rec.ets_ats_d
                  ,date_shipped        = kn_rec.date_shipped
                  ,container           = kn_rec.container
                  ,container_movement  = kn_rec.container_movement
                  ,actual_quantity     = kn_rec.actual_quantity
                  ,total_fob_shipped   = kn_rec.total_fob_shipped
                  ,uom                 = kn_rec.uom
                  ,volume              = kn_rec.volume
                  ,grossweight         = kn_rec.grossweight
                  ,kn_reference        = kn_rec.kn_reference
                  ,eta_ata_d           = kn_rec.eta_ata_d
                  ,eta_place_delivery_d= kn_rec.eta_place_delivery_d
                  ,place_of_delivery   = kn_rec.place_of_delivery
                  ,required_delivery_d = kn_rec.required_delivery_d
                  ,delay_code          = kn_rec.delay_code
                  ,delay_reason        = kn_rec.delay_reason
                  ,loading_place       = kn_rec.loading_place
                  ,po_line_no          = ln_po_line_no
                  ,sh_arrival_place    = kn_rec.sh_arrival_place
                  ,final_destination   = kn_rec.final_destination
                  ,last_update_date    = sysdate
                  ,last_updated_by     = pvg_user_id
             where kn_reference = kn_rec.kn_reference 
               and po_line_id   = ln_po_line_id;
                         
            update xx_gso_po_kn_stg
               set process_flag = 7,
                   kn_process_flag = 7,
                   error_flag   = 'N',
                   error_message = 'Success',
                   last_update_date = sysdate,
                   last_updated_by = pvg_user_id
             where rowid = kn_rec.lrowid ;
             


	   END IF; -- --ln_record_exist = 0
       END IF;  --ln_po_header_id is not null and ln_po_line_id is not null and lv_valid_flag = 'Y'

    END LOOP;
    commit;

    BEGIN

      FOR cur IN ln_update(p_load_batch_id) LOOP

	  IF cur.kn_status='SHIPPED' THEN
		
	     UPDATE xx_gso_po_dtl
	        SET shipped_qty=cur.tqty
	      WHERE po_line_id=cur.po_line_id;

	     UPDATE xx_gso_po_dtl
        	SET line_status = 'SHIPPED'
	      WHERE po_line_id = ln_po_line_id 
        	AND ordered_qty=NVL(cur.tqty,0);

	  ELSIF cur.kn_status='RECEIVED' THEN

	     UPDATE xx_gso_po_dtl
	        SET received_qty=cur.tqty
	      WHERE po_line_id=cur.po_line_id;


	  ELSIF cur.kn_status='BOOKED' THEN

	     UPDATE xx_gso_po_dtl
	        SET booked_qty=cur.tqty
	      WHERE po_line_id=cur.po_line_id;

	  END IF;

      END LOOP; 

    END;
    COMMIT;

    FOR hdr_rec in cur_po_hdr (p_load_batch_id)
    LOOP

	SELECT sum(nvl(shipped_qty,0)),
   	       sum(nvl(shipped_qty,0) * fob_origin_cost)
          INTO ln_poship_Qty,
	       ln_poship_amt
	  FROM xx_gso_po_dtl
         WHERE po_header_id=hdr_rec.po_header_id;

        SELECT sum(ordered_qty),sum(NVL(shipped_qty,0))
	  INTO ln_total_ord,ln_total_ship
	  FROM apps.xx_gso_po_dtl
	 WHERE po_header_id=hdr_rec.po_header_id;

	IF ln_total_ord=ln_total_ship THEN

	   update xx_gso_po_hdr hdr
              set hdr.ship_amnt = ln_poship_amt,
                  hdr.ship_qty = ln_poship_qty,
	          po_status_cd='SHIPPED'
            where hdr.po_header_id = hdr_rec.po_header_id;
	
        ELSE

           update xx_gso_po_hdr hdr
              set hdr.ship_amnt = ln_poship_amt,
                  hdr.ship_qty = ln_poship_qty
            where hdr.po_header_id = hdr_rec.po_header_id;
	
        END IF;
    END LOOP;
    commit;
   EXCEPTION 
    WHEN OTHERS THEN
  
    pvg_sqlerrm := SQLERRM;
    pvg_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_kn_details procedure - '||substr(pvg_sqlerrm,1,100);
    x_retcode := 2;
    fnd_file.put_line (fnd_file.log,'Other Exceptions in process_kn_details procedure :'||sqlerrm );

  END process_kn_details;
--
-- +===================================================================+
-- | Name        :  Import_kn_data                                          |
-- | Description :  This procedure is called from the concurrent       |
-- |                Program OD GSO PO  KN Import.                          |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE import_kn_data(
                       x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                    )
IS
---------------------------
--Declaring local variables
---------------------------
lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);
ln_seq			    PLS_INTEGER;
ln_total		    PLS_INTEGER;
l_btotal		    PLS_INTEGER;
ln_err_count        PLS_INTEGER := 0;
BEGIN
    ln_seq:=fnd_global.conc_request_id;
    ------------------------------------------------------------
    --Updating KN Staging with load batch id and process flags
    ------------------------------------------------------------

    UPDATE apps.xx_gso_po_kn_stg a
       SET load_batch_id=null,process_Flag=1,kn_process_flag=null,error_message=null
     WHERE EXISTS (select 'x' 
		     from apps.xx_gso_po_hdr 
		    where po_number=a.po_number)
       AND NOT EXISTS (select 'x' 
		         from apps.xx_gso_po_kn_dtl 
                        where po_number=a.po_number
		          and sku=a.sku);
	
    COMMIT;

    UPDATE xx_gso_po_kn_stg
       SET load_batch_id=ln_seq
     WHERE  process_flag=1
       AND  load_batch_id IS NULL ;
    COMMIT;
    ln_total := SQL%ROWCOUNT;
    UPDATE  xx_gso_po_kn_stg
       SET  process_flag=1
	       ,load_batch_id=ln_seq
     WHERE process_Flag=6
       AND nvl(kn_process_Flag,0) <> 7;
    COMMIT;
    SELECT COUNT(1)
      INTO l_btotal
      FROM xx_gso_po_kn_stg
     WHERE load_batch_id=ln_seq;
    BEGIN
        display_out('*Batch_id* '||to_char(ln_seq));
        display_out('*Total KN Records* '||to_char(l_btotal));
        --------------------------------------------------------------------
        --Calling process_po_data to process and insert into PO Base tables
        --------------------------------------------------------------------
        lx_errbuf     := NULL;
        lx_retcode    := NULL;
          process_kn_details( x_errbuf          =>lx_errbuf
                             ,x_retcode         =>lx_retcode
                             ,p_load_batch_id   =>ln_seq
                         );
        IF lx_retcode <> 0 THEN
           x_retcode := lx_retcode;
           CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
                ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
           END CASE;
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL
             THEN x_errbuf  := pvg_sqlerrm;
             ELSE x_errbuf  := x_errbuf||'/'||pvg_sqlerrm;
        END CASE;
        x_retcode := 2;
    END;
    
    SELECT COUNT(1)
      INTO ln_err_count
      FROM xx_gso_po_kn_stg
     WHERE load_batch_id=ln_seq
       AND error_flag = 'Y';
--    send_notification('OD GSO KN Import Exceptions','IT_MerchEBS_Oncall@officedepot.com',v_text);    
     IF NVL(ln_err_count,0)>0 THEN
        send_exception_rpt(ln_seq);
     END IF;
     commit;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in import_kn_data - '||SQLERRM;
        x_retcode := 2;
END import_kn_data;  
--
END xx_gso_po_kn_int_pkg;
/

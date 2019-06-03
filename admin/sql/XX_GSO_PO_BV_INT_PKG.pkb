SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY APPS.xx_gso_po_bv_int_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gso_po_bv_int_pkg                                     |
-- | Description      : This package will interface GSO PO Inspection  |
-- |     Data from BV  staging table to the base tables                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0       25-DEC-2010  Rama Dwibhashyam Initial draft version      |
-- |1.1       25-DEC-2010  Paddy Sanjeevi   Modified to add columns    |
-- |1.1       25-DEC-2010  Paddy Sanjeevi   Reset ln_valid_flag        | 
-- |1.2       15-Jun-2011  Paddy Sanjeevi   Modified to reset flag     |   
-- |+==================================================================+

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
  ln_process_count   number ;
  lv_error_flag      varchar2(1);
  
  
  
BEGIN
  BEGIN
    SELECT a.description
      INTO v_recipient
      FROM apps.fnd_flex_values_vl a,
           apps.fnd_flex_value_sets b
     WHERE b.flex_value_set_name='XX_GSO_NOTIFICATION_LIST'
       AND b.flex_value_set_id=a.flex_value_set_id
       AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate) 
       AND a.flex_value='BV';
  EXCEPTION
    WHEN others THEN
      v_recipient:='IT_MerchEBS_Oncall@officedepot.com';
  END;
 
  begin
  
    select count(1)
      into ln_process_count
      from xx_gso_po_bv_stg
     where load_batch_id = p_batch_id ;
  
  exception
  when no_data_found then
     ln_process_count := 0 ;
  
  end;
  
  conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'Oracle-EBS@officedepot.com',
	  	        recipients => v_recipient,
			cc_recipients=>v_recipient,
		        subject => 'GSO PO Inspection Process Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
          xx_pa_pb_mail.attach_text(conn => conn,
 		                      data => 'GSO PO Inspection Process Records Count ='||ln_process_count,
		                      mime_type => 'multipart/html');
          xx_pa_pb_mail.end_mail( conn => conn );



END send_exception_rpt;

--
  PROCEDURE process_bv_details (  x_errbuf             OUT NOCOPY VARCHAR2
                              ,x_retcode            OUT NOCOPY VARCHAR2
                              ,p_load_batch_id IN number) 
  IS
  
  lv_error_code varchar2(200);
  lv_error_msg  varchar2(2000);
  ln_bv_id     number ;
  ln_po_header_id number;
  ln_po_line_id   number;
  ln_po_line_no   number;
  ln_ordered_qty  number;
  ln_insp_qty	  number;
  lv_valid_flag   varchar2(1) := 'Y';
  ln_record_exist number ;
      
    cursor cur_bv_dtl (p_load_batch_id number) is
     select bv.rowid, bv.*
       from xx_gso_po_bv_stg bv
      where process_flag = 1
        and load_batch_id = p_load_batch_id ;
        
    
    cursor cur_po_dtl (p_po_number varchar2, p_sku varchar2) is
    select dtl.po_header_id,dtl.po_line_id,dtl.po_line_no,dtl.ordered_qty
      from xx_gso_po_dtl dtl,
           xx_gso_po_hdr hdr
     where dtl.po_header_id = hdr.po_header_id
       and hdr.po_number = p_po_number
       and dtl.item = p_sku
       and hdr.is_latest='Y'
       and dtl.latest_line_flag='Y';
  
  BEGIN

    lv_error_msg := 'No Errors' ;

    
    FOR  bv_rec in cur_bv_dtl (p_load_batch_id) 
    LOOP

        fnd_file.put_line (fnd_file.log,'Inside BV main loop :');
	lv_valid_flag := 'Y' ;

        IF bv_rec.inspection_no IS NULL THEN

            lv_valid_flag := 'N' ;
      
            update xx_gso_po_bv_stg
               set process_flag = 7 
             where rowid = bv_rec.rowid ;
      
        END IF;

        OPEN cur_po_dtl (bv_rec.po_number,bv_rec.sku);
        FETCH cur_po_dtl 
        INTO  ln_po_header_id,ln_po_line_id,ln_po_line_no,ln_ordered_qty ;
           
        --  fnd_file.put_line (fnd_file.log,'PO Header ID:'||ln_po_header_id );
        --  fnd_file.put_line (fnd_file.log,'PO Line ID:'||ln_po_line_id );
        --  fnd_file.put_line (fnd_file.log,'PO Line No:'||ln_po_line_no );

        IF cur_po_dtl%NOTFOUND THEN

            lv_valid_flag := 'N' ;
            lv_error_code := 'PO_NOT_FOUND' ;
            lv_error_msg  := 'PO Line Not found for the BV Reference Line' ;
            fnd_file.put_line (fnd_file.log,'Error Code :'||lv_error_code );
            fnd_file.put_line (fnd_file.log,'Error Message :'||lv_error_msg );
            
            update xx_gso_po_bv_stg
               set process_flag = 6,
                   error_flag   = 'Y',
                   error_message = lv_error_msg
              where rowid = bv_rec.rowid ;

         END IF;
       
         CLOSE cur_po_dtl ;


	 IF ln_po_header_id is not null AND ln_po_line_id is not null AND lv_valid_flag = 'Y'
         THEN

	    IF bv_rec.bv_status = 'CLOSE' THEN

               lv_valid_flag := 'N' ;

              UPDATE xx_gso_po_dtl
	         set bv_status='CLOSE'
	       WHERE po_line_id=ln_po_line_id;
      
              update xx_gso_po_bv_stg
                 set process_flag = 7
               where rowid = bv_rec.rowid ;
      
            END IF;

     
     	   BEGIN
             select count(1)
               into ln_record_exist
               from xx_gso_po_bv_dtl
              where inspection_no = bv_rec.inspection_no
                and po_number     = bv_rec.po_number
                and sku           = bv_rec.sku ;

	      fnd_file.put_line (fnd_file.log,'Record Exist value:'||ln_record_exist );

      	   EXCEPTION
	     WHEN no_data_found THEN
                ln_record_exist := 0 ;
      	   END;
     
      
 	   IF ln_record_exist = 0 THEN
     
     	      select XX_GSO_PO_BV_S.NEXTVAL
                into ln_bv_id
                from dual ;
    
    	      Insert into xx_gso_po_bv_dtl
             ( bv_id
              ,PO_HEADER_ID         
              ,PO_LINE_ID           
              ,INSPECTION_NO        
              ,INSPECTION_DATE      
              ,INSPECTION_QTY       
              ,INSP_SERV_TYPE       
              ,INSPECTION_RESULT    
              ,DISPOSITION          
              ,RE_INSP_DATE         
              ,RE_INSP_RESULT       
              ,SHORT_SHIPMENT       
              ,PO_NUMBER            
              ,ORDERED_QTY          
              ,ITEM_STYLE_NO        
              ,SKU                  
              ,DESCRIPTION          
              ,VENDOR_REF           
              ,SKU_UPC_NO           
              ,BOOKING_DATE         
              ,BV_BOOKING_ALERT     
              ,BV_SCHED_DATE        
              ,BV_ACTL_DATE         
              ,BV_STATUS            
              ,QA_CONTACT           
              ,CLIENT_REQUEST_DATE  
              ,OPERATION_OFFICE     
              ,VENDOR_NAME          
              ,FACTORY_NAME         
              ,FACTORY_CITY         
              ,FACTORY_COUNTRY      
              ,COUNTRY_ORIGIN       
              ,COLLECTION_NO        
              ,CLIENT_DEPT_NO       
              ,FIRST_SHIP_DATE      
              ,SHIP_DESTINATION     
              ,REASON_CODE          
              ,REMARKS              
              ,IC_ISSUE_DATE        
              ,CREATION_DATE        
              ,CREATED_BY           
              ,LAST_UPDATE_DATE     
              ,LAST_UPDATED_BY      
              ,LAST_UPDATE_LOGIN    
              ,PO_LINE_NO           
              ,VENDOR_NO            
              ,MANUFACTURER_NAME    
              ,SHIP_DATE            
              ,INSP_BOOKING_NO      
              ,FACTORY_ADDRESS      
              ,INVOICE_NO           
              ,INVOICE_DATE         
              ,INVOICE_CONTACT      
              ,INVOICE_COMPANY      
              ,OPRN_OFFICE_CNTRY
	      ,final_book_entry_date
	      ,bv_confirm_date
	      ,bv_service_date
	      ,announced
              ) values
              (LN_BV_ID
              ,ln_PO_HEADER_ID          
              ,ln_PO_LINE_ID                  
              ,ltrim(rtrim(bv_rec.inspection_no))
              ,bv_rec.inspection_date     
              ,bv_rec.ordered_qty             
              ,ltrim(rtrim(bv_rec.insp_serv_type))     
              ,ltrim(rtrim(bv_rec.inspection_result))       
              ,bv_rec.disposition 
              ,bv_rec.re_insp_date    
              ,ltrim(rtrim(bv_rec.re_insp_result))   
              ,bv_rec.short_shipment
              ,bv_rec.po_number   
              ,ln_ordered_qty   --bv_rec.ordered_qty         
              ,bv_rec.item_style_no            
              ,ltrim(rtrim(bv_rec.sku))  
              ,ltrim(rtrim(bv_rec.description))   
              ,bv_rec.vendor_ref       
              ,bv_rec.sku_upc_no             
              ,bv_rec.bv_book_date          
              ,'N'             
              ,bv_rec.bv_sched_date    
              ,bv_rec.bv_act_date       
              ,ltrim(rtrim(bv_rec.bv_status))     
              ,ltrim(rtrim(bv_rec.qa_contact))                               
	      ,bv_rec.client_request_date              
              ,ltrim(rtrim(bv_rec.operation_office))           
              ,ltrim(rtrim(bv_rec.vendor_name))          
              ,ltrim(rtrim(bv_rec.factory_name))             
              ,ltrim(rtrim(bv_rec.factory_city))  
              ,ltrim(rtrim(bv_rec.factory_country))     
              ,ltrim(rtrim(bv_rec.country_origin))   
              ,ltrim(rtrim(bv_rec.collection_no))            
              ,bv_rec.client_dept_no          
              ,bv_rec.first_ship_date         
              ,ltrim(rtrim(bv_rec.ship_destination))     
              ,null
              ,bv_rec.remarks
              ,bv_rec.ic_issue_date      
              ,sysdate         
              ,pvg_user_id            
              ,sysdate   
              ,pvg_user_id   
              ,pvg_login_id     
              ,ln_po_line_no
              ,null
              ,null
              ,bv_rec.first_ship_date
              ,null
              ,ltrim(rtrim(bv_rec.factory_address))
              ,ltrim(rtrim(bv_rec.invoice_no))
              ,bv_rec.invoice_date
              ,ltrim(rtrim(bv_rec.invoice_contact))
              ,ltrim(rtrim(bv_rec.invoice_company))
              ,ltrim(rtrim(bv_rec.oprn_office_cntry))        
	      ,bv_rec.final_book_entry_date
	      ,bv_rec.bv_confirm_date
	      ,bv_rec.bv_service_date
	      ,ltrim(rtrim(bv_rec.announced))
              ) ;
               

/*
          if ln_ordered_qty = bv_rec.actual_qty
          then
       
           update xx_gso_po_dtl
              set bv_status = 'CLOSE'
                 ,insp_qty  = bv_rec.actual_qty
            where po_line_id = ln_po_line_id ;
            
          else
          
           update xx_gso_po_dtl
              set bv_status = 'OPEN'
                 ,insp_qty  = bv_rec.actual_qty  -- is it to add insp+actual qty
            where po_line_id = ln_po_line_id ;
            
          end if;
*/
     

             IF  bv_rec.inspection_result is not null THEN

	         IF  bv_rec.inspection_result='PASS' THEN

		    SELECT sum(ordered_qty),sum(nvl(insp_qty,0))
		      INTO ln_ordered_qty,ln_insp_qty
		      FROM xx_gso_po_dtl
		     WHERE po_line_id=ln_po_line_id;

	  	    IF ln_ordered_qty=ln_insp_qty+bv_rec.actual_qty THEN

 	               update xx_gso_po_dtl
          	          SET bv_status = 'CLOSE',
		  	      insp_qty=NVL(insp_qty,0)+bv_rec.actual_qty
	                WHERE po_line_id = ln_po_line_id ;

  	 	    ELSE
	
          	        update xx_gso_po_dtl
                 	   set bv_status = 'OPEN',
	                      insp_qty  = nvl(insp_qty,0)+bv_rec.actual_qty  
        	         WHERE po_line_id = ln_po_line_id ;

		    END IF;

	         ELSIF bv_rec.inspection_result in ('FAILED','MISSING') THEN

	             update xx_gso_po_dtl
           	        set bv_status = 'REINSPECT'
		      where po_line_id = ln_po_line_id ;

	         END IF;
	
	    END IF;

	    IF bv_rec.inspection_result is null THEN
          
               update xx_gso_po_dtl
                  set bv_status = 'OPEN'
                where po_line_id = ln_po_line_id ;
            
            END IF;

            update xx_gso_po_bv_stg
               set process_flag = 7,
                   bv_process_flag = 7,
                   error_flag   = 'N',
                   error_message = 'Success'
                  -- last_update_date = sysdate
                  -- last_updated_by = pvg_user_id
             where rowid = bv_rec.rowid ;
             
	   ELSE   -- 	   IF ln_record_exist = 0 THEN
     
	       
             UPDATE xx_gso_po_bv_dtl
	        SET inspection_date   = bv_rec.inspection_date
	       	   ,inspection_no     = ltrim(rtrim(bv_rec.inspection_no))
        	   ,inspection_qty    = bv_rec.actual_qty
	           ,invoice_no        = ltrim(rtrim(bv_rec.invoice_no))
        	   ,invoice_date      = bv_rec.invoice_date
	           ,invoice_contact   = ltrim(rtrim(bv_rec.invoice_contact))
        	   ,bv_confirm_date   = bv_rec.bv_confirm_date
	           ,bv_service_date   = bv_rec.bv_service_date
        	   ,bv_status         = ltrim(rtrim(bv_rec.bv_status))
	           ,inspection_result = ltrim(rtrim(bv_rec.inspection_result))
	     WHERE inspection_no = bv_rec.inspection_no
               AND po_header_id  = ln_po_header_id
	       AND po_line_id    = ln_po_line_id ;
          

            IF  bv_rec.inspection_result is not null THEN

	         IF  bv_rec.inspection_result='PASS' THEN

		    SELECT sum(ordered_qty),sum(nvl(insp_qty,0))
		      INTO ln_ordered_qty,ln_insp_qty
		      FROM xx_gso_po_dtl
		     WHERE po_line_id=ln_po_line_id;

	  	    IF ln_ordered_qty=ln_insp_qty+bv_rec.actual_qty THEN

 	               update xx_gso_po_dtl
          	          SET bv_status = 'CLOSE',
		  	      insp_qty=NVL(insp_qty,0)+bv_rec.actual_qty
	                WHERE po_line_id = ln_po_line_id ;

  	 	    ELSE
	
          	        update xx_gso_po_dtl
                 	   set bv_status = 'OPEN',
	                      insp_qty  = nvl(insp_qty,0)+bv_rec.actual_qty  
        	         WHERE po_line_id = ln_po_line_id ;

		    END IF;

	         ELSIF bv_rec.inspection_result in ('FAILED','MISSING') THEN

	             update xx_gso_po_dtl
           	        set bv_status = 'REINSPECT'
		      where po_line_id = ln_po_line_id ;

	         END IF;
	
	    END IF;

	    IF bv_rec.inspection_result is null THEN
          
               update xx_gso_po_dtl
                  set bv_status = 'OPEN'
                where po_line_id = ln_po_line_id ;
            
            END IF;


            UPDATE xx_gso_po_bv_stg
	        SET process_flag = 7,
        	    bv_process_flag = 7,
                    error_flag   = 'N',
	            error_message = 'Success'
              WHERE rowid = bv_rec.rowid;
             
     
	   END IF;  -- lv_record_exist condition


	 END IF;  --	 IF ln_po_header_id is not null AND ln_po_line_id is not null AND lv_valid_flag = 'Y'
                  
    END LOOP;
    
    COMMIT;
   EXCEPTION 
    WHEN OTHERS THEN
      --
    pvg_sqlerrm := SQLERRM;
    pvg_sqlcode := SQLCODE;
    
    x_errbuf  := 'Unexpected error in process_bv_details procedure - '||substr(pvg_sqlerrm,1,100);
    x_retcode := 2;      
      fnd_file.put_line (fnd_file.log,'Other Exceptions in process_bv_details procedure :'||sqlerrm );
     -- ROLLBACK;
  --
  END process_bv_details;
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
PROCEDURE import_bv_data(
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
BEGIN

    UPDATE apps.xx_gso_po_bv_stg a
       SET load_batch_id=null,process_Flag=1,bv_process_flag=null,error_message=null
     WHERE EXISTS (select 'x' 
		     from apps.xx_gso_po_hdr 
		    where po_number=a.po_number)
       AND NOT EXISTS (select 'x' 
		         from apps.xx_gso_po_bv_dtl 
                        where po_number=a.po_number
		          and sku=a.sku);
    commit;

    ln_seq:=fnd_global.conc_request_id;
    ------------------------------------------------------------
    --Updating KN Staging with load batch id and process flags
    ------------------------------------------------------------
    UPDATE xx_gso_po_bv_stg
       SET load_batch_id=ln_seq
     WHERE  process_flag=1
       AND  load_batch_id IS NULL ;
       
    COMMIT;

    ln_total := SQL%ROWCOUNT;

    UPDATE  xx_gso_po_bv_stg
       SET  process_flag=1
	       ,load_batch_id=ln_seq
     WHERE process_Flag=6
       AND nvl(bv_process_Flag,0) <> 7;
    COMMIT;
    
    SELECT COUNT(1)
      INTO l_btotal
      FROM xx_gso_po_bv_stg
     WHERE load_batch_id=ln_seq;
     
    BEGIN
        display_out('*Batch_id* '||to_char(ln_seq));
        display_out('*Total BV Records* '||to_char(l_btotal));

        --------------------------------------------------------------------
        --Calling process_po_data to process and insert into PO Base tables
        --------------------------------------------------------------------
        lx_errbuf     := NULL;
        lx_retcode    := NULL;
          process_bv_details( x_errbuf          =>lx_errbuf
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
--    send_notification('OD GSO BV Import Exceptions','IT_MerchEBS_Oncall@officedepot.com',v_text);    
     IF NVL(l_btotal,0)>0 THEN
           fnd_file.put_line (fnd_file.log,'No of records processed :'||l_btotal );
        send_exception_rpt(ln_seq);
     END IF;
     commit;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in import_kn_data - '||SQLERRM;
        x_retcode := 2;
END import_bv_data;  
--
END xx_gso_po_bv_int_pkg;
/

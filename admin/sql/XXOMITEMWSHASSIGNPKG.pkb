CREATE OR REPLACE PACKAGE BODY xx_om_item_wsh_assign_pkg
-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_ITEM_WSG_ASSIGN                                       |
-- | Rice ID     : Item Warehouse Assignment                                   |
-- | Description : Procedure to call RMS to insert the Item and Location to fix|
-- |               the Item errors from HVOP				                   |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                       Remarks                 |
-- |=======   ==========  =============    ====================================|
-- |DRAFT 1A 09-OCT-2008  Bala E		   Initial draft version               |
-- |V1.0     17-OCT-2008  Bala E		 			                           |
-- |V2.0     23-OCT-2008  Bala E		   Added DC Location Filter            |
-- |V3.0     20-OCT-2015  Havish Kasina	   Removed the schema references in the|
-- |                                       existing code as per R12.2 Retrofit |
-- |                                       Changes                             |
-- +===========================================================================+
AS
-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------
    -- +===================================================================+
    -- | Name  : Exec_rms_wsh_assign                                       |
    -- | Description : Procedure to call RMS to insert the Item and Loc    |
    -- |               to fix the item Errors from HVOP                    |
    -- |                                                                   |
    -- | Parameters :       p_request_id                                   |
    -- |                    p_process_date  				               |
    -- |		            retcode                                        |
    -- |                    Errbuf                                         |
    -- +===================================================================+
    PROCEDURE Exec_item_rms_wsh_assign 
                                  (  retcode OUT NOCOPY  NUMBER
                                  , errbuf OUT NOCOPY VARCHAR2
                                  , p_sch_flag IN VARCHAR2
			                            , p_request_id IN NUMBER
			                            , p_process_Date IN VARCHAR2 	
                                  ) IS
    x_ln_retcode INTEGER;
    x_lc_retmsg VARCHAR2(300);
    p_lc_user VARCHAR2(30) := 'EBS';
    item_rec OD_ITEMLOC_BATCH_SQL.TYPE_CHARACTER_TBL@RMS.NA.ODCORP.NET;
    loc_rec OD_ITEMLOC_BATCH_SQL.TYPE_NUMBER_TBL@RMS.NA.ODCORP.NET;
    retcode_rec OD_ITEMLOC_BATCH_SQL.TYPE_NUMBER_TBL@RMS.NA.ODCORP.NET;
    retmsg_rec OD_ITEMLOC_BATCH_SQL.TYPE_CHARACTER_TBL@RMS.NA.ODCORP.NET ;
    ln_counter number;
    p_item_rec item_rec%type;
    p_loc_rec loc_rec%type;
    x_retcode_rec retcode_rec%type;
    x_retmsg_rec retmsg_rec%type;
	
    CURSOR item_all_cur
        IS
        SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
            and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and substr(m.message_text,1,8) = '10000018'
            and nvl(h.error_flag,'N') = 'Y';  
			
    CURSOR item_processdate_cur(p_process_date IN VARCHAR2)
    IS
    SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
        from  oe_headers_iface_all h
            , xx_om_headers_attr_iface_all xh
            , oe_processing_msgs_vl m
            , xx_om_sacct_file_history s
            , hr_all_organization_units hr
            , hr_locations l
            , xx_inv_org_loc_rms_attribute xi
        where h.orig_sys_document_ref = xh.orig_sys_document_ref
        and   h.order_source_id = xh.order_source_id
        and  xh.imp_file_name = s.file_name
        and s.file_type = 'ORDER'
        and to_char(s.process_date,'YYYY/MM/DD') = substr(p_process_date,1,10)
        and  h.orig_sys_document_ref = m.original_sys_document_ref
        and h.order_source_id = m.order_source_id
        and h.ship_from_org_id = hr.organization_id
        and hr.location_id = l.location_id
        and hr.attribute1 = xi.location_number_sw
	and xi.org_type = 'WH'
        and xi.od_type_sw = 'CS'
        and substr(m.message_text,1,8) = '10000018'
        and nvl(h.error_flag,'N') = 'Y';
		
      CURSOR item_processid_cur(p_request_id IN NUMBER)
        IS
        SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and s.master_request_id = p_request_id
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
	    and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and substr(m.message_text,1,8) = '10000018'
            and nvl(h.error_flag,'N') = 'Y';
			
      CURSOR item_sch_cur 
           IS
           SELECT Trim(substr(m.message_text,(Instr(m.message_text,': Item ',1)+7),7)) item,hr.attribute1 location
            from  oe_headers_iface_all h
                , xx_om_headers_attr_iface_all xh
                , oe_processing_msgs_vl m
                , xx_om_sacct_file_history s
                , hr_all_organization_units hr
                , hr_locations l
                , xx_inv_org_loc_rms_attribute xi
            where h.orig_sys_document_ref = xh.orig_sys_document_ref
            and   h.order_source_id = xh.order_source_id
            and  xh.imp_file_name = s.file_name
            and s.file_type = 'ORDER'
            and  h.orig_sys_document_ref = m.original_sys_document_ref
            and h.order_source_id = m.order_source_id
            and h.ship_from_org_id = hr.organization_id
            and hr.location_id = l.location_id
            and hr.attribute1 = xi.location_number_sw
	    and xi.org_type = 'WH'
            and xi.od_type_sw = 'CS'
            and substr(m.message_text,1,8) = '10000018'
            and nvl(h.error_flag,'N') = 'Y'
            and s.request_id in (select request_id from fnd_concurrent_requests where parent_request_id in(select max(request_id) parent_request_id
                                from fnd_concurrent_requests r,fnd_concurrent_programs_tl P
                                where r.concurrent_program_id = p.concurrent_program_id
                                and   p.user_concurrent_program_name = 'OD: SAS Trigger HVOP'
                                group by substr(r.argument1,4,2)));       
    BEGIN    
    
    If p_sch_flag = 'N' then
    FND_FILE.put_line(FND_FILE.log,'Manually submitted the program to update the Items in RMS');
              if p_process_date is null and p_request_id is null then
                     Open item_all_cur;
                     fetch item_all_cur bulk collect into p_item_rec,p_loc_rec;
                     Close item_all_cur;
              End if;
              if p_process_date is not null and p_request_id is null then
                     Open item_processdate_cur(p_process_date);
                     Fetch item_processdate_cur bulk collect into p_item_rec,p_loc_rec;
                     Close item_processdate_cur;     
              End if;
              If p_request_id is not null and p_process_date is null then
                      Open item_processid_cur(p_request_id);
                      fetch item_processid_cur bulk collect into p_item_rec,p_loc_rec;
                      close item_processid_cur;         
              End if;
              
      Else
      FND_FILE.put_line(FND_FILE.log,'Schduled job to update the Items in RMS');
                    Open item_sch_cur;
                    Fetch item_sch_cur bulk collect into p_item_rec, p_loc_rec;
                    Close item_sch_cur;              
      
      End if;     
        
    -- Execucting RMS procedure if item_rec count is more than zero..      
     FND_FILE.put_line(FND_FILE.log,'Items Idetified: ' ||p_item_rec.count);
     if p_item_rec.count >0  then
         FND_FILE.put_line(FND_FILE.log,'Called the RMS procedure at: '|| to_char(sysdate,'DD-MON-YYYY HH24:MM:SS'));
         OD_ITEMLOC_BATCH_SQL.INSERT_ITEMLOC_BATCH@RMS.NA.ODCORP.NET( x_ln_retcode,x_lc_retmsg,p_item_rec, p_loc_rec,p_lc_user,x_retcode_rec, x_retmsg_rec );
         FND_FILE.put_line(FND_FILE.log,'RMS procedure call ended at: ' || to_char(sysdate,'DD-MON-YYYY HH24:MM:SS'));   
        If x_ln_retcode = 0 then
              FND_FILE.put_line(FND_FILE.log,'All Items updated successfully in RMS');
          Else if x_ln_retcode = -1 then
              FND_FILE.put_line(FND_FILE.log,'Some of the Items are not updated sucessfully');
          End if;
        End if;
        
        If x_retmsg_rec.count >0 then  
        FND_FILE.put_line(FND_FILE.log,'Below are the Details'); 
        FND_FILE.put_line(FND_FILE.log,'*************************************************');
            For j IN x_retmsg_rec.FIRST .. x_retmsg_rec.LAST 
            loop
                FND_FILE.put_line(FND_FILE.log, x_retmsg_rec(j));
            End loop; 
         FND_FILE.put_line(FND_FILE.log,'*************************************************');   
        End if;
     Else  
        retcode := 01;
        errbuf := 'The RMS procedure has not been called as there are no items Identified';
      	FND_FILE.put_line(FND_FILE.log,errbuf);   
     End if;
           
      
   commit; 
    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          retcode := 10;
          errbuf := 'Time Out Error when executing the procedure' ;
        WHEN LOGIN_DENIED THEN
          retcode := 11;
          errbuf := 'Login Failed Error';
        WHEN NO_DATA_FOUND THEN
          retcode := 04; -- No Data found error 
          errbuf := 'No Data found Error' ;
        WHEN OTHERS THEN
          retcode := 05; -- No Data found error 
          errbuf := 'Unexpecter Error from the procedure' ;
      END Exec_item_rms_wsh_assign;
    END xx_om_item_wsh_Assign_pkg;

/
SHOW ERRORS;


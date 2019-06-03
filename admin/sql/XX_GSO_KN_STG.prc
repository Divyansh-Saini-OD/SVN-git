update apps.xx_gso_po_kn_stg a
    set load_batch_id=null,process_Flag=1,kn_process_flag=null,error_message=null
  where exists (select 'x' 
		  from apps.xx_gso_po_hdr 
		 where po_number=a.po_number)
   and not exists (select 'x' 
		     from apps.xx_gso_po_kn_dtl 
                    where po_number=a.po_number);
commit;


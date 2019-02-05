create or replace 
package body xx_inv_copy_item_attr_pkg
as
-- +========================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                       |
-- |                  Office Depot                                                                                          |
-- +========================================================================================================================+
-- | Name  : XX_INV_COPY_ITEM_ATTR_PKG                                                                                  |
-- | Rice ID:                                                                                                          |
-- | Description      : This Program will re-process the tracking number from EBIZ to DB2                                   |
-- |                                                                                                                        |
-- |                                                                                                                        |
-- |Change Record:                                                                                                          |
-- |===============                                                                                                         |
-- |Version     Date          Author                     Remarks                                                            |
-- |=======     ==========    =============              ==============================                                     |
-- |DRAFT 1A    02-NOV-2017   Venkata Battu              Initial draft version                                              |
-- +========================================================================================================================+
-- global variables declaration

g_def_debug    varchar2(1)  :='N';
g_debug_lvl    varchar2(1);
g_org_id       number := fnd_profile.value('ORG_ID');
g_user_id      number := fnd_profile.value('USER_ID');
procedure msg(p_mode in varchar2 
             ,p_msg  in varchar2)
is
begin
   if p_mode ='L'
   then 
      fnd_file.put_line(fnd_file.log,p_msg);
   else 	  
     fnd_file.put_line(fnd_file.output,p_msg);
   end if;	 
end;
procedure debug(p_msg in varchar2)
is
begin
     if g_debug_lvl <> g_def_debug
     then
        fnd_file.put_line(fnd_file.log,p_msg);
     end if;
end;
procedure update_item_cost(p_item       in varchar2
                          ,p_master_org in varchar2
			  ,p_child_orgs in varchar2
			  )
is
   -- variable declarations 
    ln_item_id                 number:=null;
    l_item_tbl                 ego_item_pub.item_tbl_type;
    ln_list_price              number;
    x_item_tbl                 ego_item_pub.item_tbl_type;
    x_return_status            varchar2(1);
    x_msg_count                number;
    x_message_list             error_handler.error_tbl_type;
    x_msg                      varchar2(4000);
    item_tbl                   item_t;	
    l_application_id           number;
    l_resp_id                  number;
    ln_invoice_close_tolerance number;
    ln_receive_close_tolerance number;
    lc_receipt_required_flag   varchar2(1);
    lc_inventory_item_status_code varchar2(10);
cursor c_item(cp_item_id                    in number
             ,cp_child_orgs                 in varchar2
             ,cp_item_cost                  in number
             ,cp_invoice_close_tolerance    in number
             ,cp_receive_close_tolerance    in number
             ,cp_receipt_required_flag      in varchar2
             ,cp_inventory_item_status_code in varchar2
             )
    is
	select msib.inventory_item_id
              ,msib.segment1
              ,msib.organization_id
	      ,ood.organization_code
              ,msib.list_price_per_unit
              ,msib.invoice_close_tolerance
              ,msib.receive_close_tolerance 
              ,msib.receipt_required_flag
              ,msib.inventory_item_status_code
         from mtl_system_items_b msib
             ,org_organization_definitions ood
        where msib.inventory_item_id   = cp_item_id --32671
          and msib.organization_id     = ood.organization_id
          and ood.organization_code    = decode(cp_child_orgs,'all',ood.organization_code,cp_child_orgs)
          and ood.organization_code    <> p_master_org
	  and ood.operating_unit       =  g_org_id;	  
begin
     --validate item and org at master organization
     begin
     	select msib.inventory_item_id
              ,msib.list_price_per_unit
              ,msib.invoice_close_tolerance
              ,msib.receive_close_tolerance 
              ,msib.receipt_required_flag
              ,msib.inventory_item_status_code
          into ln_item_id
              ,ln_list_price
              ,ln_invoice_close_tolerance 
              ,ln_receive_close_tolerance 
              ,lc_receipt_required_flag  
              ,lc_inventory_item_status_code
          from mtl_system_items_b msib
	      ,org_organization_definitions ood
         where msib.segment1         = p_item
           and msib.organization_id  = ood.organization_id
           and ood.organization_code = p_master_org;
     exception
     when no_data_found
     then
	     msg('L','sku does not exist in item master :'||p_item || ' organization :'||p_master_org);
     when others
     then
         msg('L','exception in item master validation for  :'||p_item || ' organization :'||p_master_org ||' error code :'||sqlerrm); 	 
     end;

      debug('master organization item id : '||ln_item_id ||'   '|| 'list price :'||ln_list_price);

     begin
          select application_id
                ,responsibility_id
            into l_application_id
                ,l_resp_id
            from fnd_responsibility
           where responsibility_key = UPPER('XX_US_INVENTORY');  --od inv inventory

        debug('application id : '||l_application_id ||'   '|| 'responsibility id :'||l_resp_id);   
     exception 
      when others
      then
          ln_item_id :=null;
          ln_list_price :=null;
          msg('L','exception in getting responsibility id and application id values:'||sqlerrm);
     end;
     if ln_item_id is not null and ln_list_price is not null 
     then
         debug('Step :1 ');
	 open c_item(ln_item_id
	             ,p_child_orgs
	             ,ln_list_price
                     ,ln_invoice_close_tolerance 
                     ,ln_receive_close_tolerance 
                     ,lc_receipt_required_flag  
                     ,lc_inventory_item_status_code
		   );
	 fetch c_item bulk collect into  item_tbl;   
         debug('Step :2 ');  
      end if;

      if g_debug_lvl <> g_def_debug 
      then
          debug('table type count:'||item_tbl.count);
          if item_tbl.count >0
          then
              debug('Step :3 ');  
              for i in item_tbl.first..item_tbl.last
              loop
              debug('sku    :'||item_tbl(i).lc_sku||'   '|| 'organication code :  '||item_tbl(i).lc_org_code||'  item price :'||item_tbl(i).ln_list_price);

              end loop;
              debug('Step :4 ');
          else 
               debug('no eligible records to copy attributes from Organization'); 
          end if;   
      end if; 
     -- initializing apps conext 
     fnd_global.apps_initialize (g_user_id,l_resp_id,l_application_id);
     debug('Step :5 ');
    if item_tbl.count >0
    then
	    debug('Step :6 ');
        for i in item_tbl.first..item_tbl.last
        loop
            l_item_tbl(i).transaction_type          := ego_item_pub.g_ttype_update;
            l_item_tbl(i).segment1                  := item_tbl(i).lc_sku;
            l_item_tbl(i).inventory_item_id	    := item_tbl(i).ln_item_id;
            l_item_tbl(i).organization_id           := item_tbl(i).ln_org_id;
            l_item_tbl(i).organization_code         := item_tbl(i).lc_org_code;
            l_item_tbl(i).list_price_per_unit       := ln_list_price;
            l_item_tbl(i).invoice_close_tolerance   := item_tbl(i).ln_invoice_close_tolerance;
            l_item_tbl(i).receive_close_tolerance   := item_tbl(i).ln_receive_close_tolerance;
            l_item_tbl(i).receipt_required_flag     := item_tbl(i).lc_receipt_required_flag;  
            l_item_tbl(i).inventory_item_status_code:= item_tbl(i).lc_inventory_item_status_code; 
        end loop;
        debug('Step :7 '); 		
        if g_debug_lvl <> g_def_debug
        then
		    debug('ego item pub table type data'); 
            for i in l_item_tbl.first..l_item_tbl.last
            loop
                debug(' sku    :'||l_item_tbl(i).segment1||'   '|| 'organication code :  '||l_item_tbl(i).organization_code||' '||'item price :'||l_item_tbl(i).list_price_per_unit);

            end loop;
			debug('Step :8 ');
        end if;    
        msg('L','calling ego_item_pub api:');                                                                                     
        ego_item_pub.process_items( p_api_version     => 1.0
                                   ,p_init_msg_list   => fnd_api.g_true
                                   ,p_commit          => fnd_api.g_true
                                   ,p_item_tbl        => l_item_tbl
                                   ,x_item_tbl        => x_item_tbl
                                   ,x_return_status   => x_return_status
                                   ,x_msg_count       => x_msg_count
				  );		
            msg('L','return status :'|| x_return_status);
            if x_return_status = fnd_api.g_ret_sts_success
            then 
                  msg('O','list price is updated successfully for below organizations');
                  msg('O','inventory item    :'||x_item_tbl(1).segment1);
            	for i in 1..x_item_tbl.count
                loop
				     msg('O','organization code :'||x_item_tbl(i).organization_code);                    
                end loop;
               commit; 
            else 
                error_handler.get_message_list (x_message_list      => x_message_list);
                for i in 1 .. x_message_list.count
                loop
                    msg('L',x_message_list (i).message_text);
                end loop;
                rollback;
            end if; 			
    end if; 
exception
when others
then
    msg('L','error in update_item_cost procedure :'||sqlerrm);
end; --update_item_cost
procedure main( x_error_buff  out  varchar2
               ,x_ret_code    out  varchar2
               ,p_item         in  varchar2
	       ,p_master_org   in  varchar2
               ,p_child_orgs   in  varchar2
               ,p_debug        in  varchar2 default 'N'
              )
is
begin
    -- disply input parameters
	msg('L','sku         :' ||p_item);
	msg('L','master org  :' ||p_master_org);
	msg('L','child orgs  :' ||p_child_orgs);
	msg('L','debug flag  :' ||p_debug);

    g_debug_lvl := p_debug;

    -- calling update item cost procedure
	update_item_cost(p_item       => p_item
                        ,p_master_org => p_master_org
                        ,p_child_orgs => p_child_orgs
                       );
exception
when others
then
    msg('L','excetion in main procedure :'||sqlerrm);	
end; --main
end xx_inv_copy_item_attr_pkg;
create or replace 
package xx_inv_copy_item_attr_pkg
as
-- +========================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                       |
-- |                  Office Depot                                                                                          |
-- +========================================================================================================================+
-- | Name  : XX_INV_COPY_ITEM_ATTR_PKG                                                                                     |
-- | Rice ID:                                                                                                               |
-- | Description      : This Program update Item cost from Master Org to Child orgs                                         |
-- |                                                                                                                        |
-- |                                                                                                                        |
-- |Change Record:                                                                                                          |
-- |===============                                                                                                         |
-- |Version     Date          Author                     Remarks                                                            |
-- |=======     ==========    =============              ==============================                                     |
-- |DRAFT 1A    02-NOV-2017   Venkata Battu              Initial draft version                                              |
-- +========================================================================================================================+
type item_rec is record(
 ln_item_id                       number
,lc_sku                           varchar2(100) 
,ln_org_id                        number
,lc_org_code                      varchar2(100)
,ln_list_price                    number
,ln_invoice_close_tolerance       number
,ln_receive_close_tolerance       number
,lc_receipt_required_flag         varchar2(1)
,lc_inventory_item_status_code    varchar2(10)
);

type item_t is table of item_rec index by binary_integer;

procedure main( x_error_buff  out  varchar2
               ,x_ret_code    out  varchar2
	       ,p_item         in  varchar2
	       ,p_master_org   in  varchar2
	       ,p_child_orgs   in  varchar2
	       ,p_debug        in  varchar2 default 'N'
	      );
end xx_inv_copy_item_attr_pkg;
/

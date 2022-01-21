update icx.icx_cat_items_tlp
      set  internal_item_num = ltrim(rtrim(internal_item_num));
	     
COMMIT;

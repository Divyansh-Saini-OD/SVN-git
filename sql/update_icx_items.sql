update icx.icx_cat_items_tlp
      set  picture = ltrim(rtrim(internal_item_num)||'.jpg',
	     thumbnail_image = ltrim(rtrim(internal_item_num)||'.jpg'      
      where  picture is null 
        and thumbnail_image is null 
        and supplier is null;
COMMIT;

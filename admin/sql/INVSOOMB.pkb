SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY inv_salesorder AS
/* $Header: INVSOOMB.pls 115.17.115100.1 2004/10/29 20:02:07 appldev ship $ */

TYPE order_hdr_rec_type IS RECORD
  (  salesorder_id     NUMBER,
     oe_header_id      NUMBER,
     order_number      NUMBER,
     order_type        VARCHAR2(2000),
     order_source      VARCHAR2(2000));

TYPE order_hdr_tbl_type IS TABLE OF order_hdr_rec_type
  INDEX BY BINARY_INTEGER;

  -- Global constant for package name
     g_package_name		CONSTANT	VARCHAR2(50) := 'INV_SALESORDER';
     g_om_installed		 		VARCHAR2(3)  := NULL;
     g_order_source				VARCHAR2(2000) := NULL;

  -- Cache used to improve performance of get_salesorder_for_oeheader
     g_order_headers                            order_hdr_tbl_type;


Procedure create_salesorder (
		p_api_version_number	IN	NUMBER,
		p_init_msg_list		IN	VARCHAR2 DEFAULT FND_API.G_FALSE,
		p_segment1		IN	NUMBER,
		p_segment2		IN	VARCHAR2,
		p_segment3		IN	VARCHAR2,
		p_validate_full		IN	NUMBER DEFAULT 1,
		p_validation_date	IN	DATE,
		x_salesorder_id		OUT	NUMBER,
		x_message_data		OUT	VARCHAR2,
		x_message_count		OUT	NUMBER,
		x_return_status		OUT	VARCHAR2) IS

  -- Constants
     c_api_version_number CONSTANT NUMBER  	:= 1.0 ;
     c_api_name 	  CONSTANT VARCHAR2(50):= 'CREATE_SALESORDER';

  -- Variables
     l_segment1		  VARCHAR2(150);
     l_segment2		  VARCHAR2(150);
     l_segment3		  VARCHAR2(150);
     l_segment_arr	  FND_FLEX_EXT.SEGMENTARRAY ;
     l_validation_date	  DATE;
     l_so_id		  NUMBER;
BEGIN

  -- check for api call compatibility
     if not fnd_api.compatible_api_call(
	c_api_version_number,
	p_api_version_number,
	c_api_name,
	g_package_name) then
	  raise fnd_api.g_exc_unexpected_error ;
     end if;

  -- initialize message list
     if fnd_api.to_boolean(p_init_msg_list) then
       fnd_msg_pub.initialize;
     end if;

  -- initialize return status to success
     x_return_status := fnd_api.g_ret_sts_success;

  -- start input parameter validation now
  -- validate if order number is passed in (segment 1)
     if ( p_segment1 is NULL ) then
       fnd_message.set_name('INV', 'BAD_INPUT_ARGUMENTS');
	fnd_msg_pub.add;
       raise fnd_api.g_exc_error ;
     else
       -- convert this to varchar since the flexfield table stores as char(240)
      l_segment1 := to_char(p_segment1);
     end if;

  -- validate if order type is passed in (segment 2)
     if ( p_segment2 is NULL ) then
       fnd_message.set_name('INV', 'BAD_INPUT_ARGUMENTS');
	fnd_msg_pub.add;
       raise fnd_api.g_exc_error ;
     elsif ( p_segment2 is NOT NULL) then
       l_segment2 := p_segment2;
     end if;

  -- validate if order source is passed in
     if ( p_segment3 is NULL ) then
       fnd_message.set_name('INV', 'BAD_INPUT_ARGUMENTS');
	fnd_msg_pub.add;
       raise fnd_api.g_exc_error ;
     else
       l_segment3 := p_segment3 ;
     end if;

     -- if validate_full is not required, then we can do a quick select and insert
     -- to create a new sales order if needed or return an existing one
     if ( p_validate_full = 1 ) then
    -- validate if validation_date is passed in, if not use sysdate
       if ( p_validation_date IS NULL ) then
         l_validation_date := sysdate ;
       else
         l_validation_date := p_validation_date;
       end if;


    -- now we have values for all 4 segments required for sales order flex field
    -- so we can call the flexfield api to create a sales order

       l_segment_arr(1) := l_segment1 ;
       l_segment_arr(2) := l_segment2 ;
       l_segment_arr(3) := l_segment3 ;


       if NOT ( fnd_flex_ext.get_combination_id(
  	 application_short_name		=> 'INV'
	,key_flex_code			=> 'MKTS'
  	,structure_number		=> 101
	,validation_date		=> l_validation_date
	,n_segments			=> 3
	,segments			=> l_segment_arr
	,combination_id			=> x_salesorder_id) ) then
       fnd_msg_pub.add ;
       raise fnd_api.g_exc_error ;
       end if;
     else
       -- check if sales order already exists
       BEGIN
       SELECT sales_order_id
       INTO l_so_id
       FROM MTL_SALES_ORDERS
	 WHERE segment1 = l_segment1
	 AND segment2 = l_segment2
       AND segment3 = l_segment3 ;

       x_salesorder_id := l_so_id ;
       return ;
       EXCEPTION
	   WHEN NO_DATA_FOUND THEN
	-- sales order does not exist, create a new one

         SELECT mtl_sales_orders_s.nextval into l_so_id from dual ;

         INSERT into MTL_SALES_ORDERS (sales_order_id, segment1, segment2, segment3, last_updated_by,
			last_update_date, last_update_login, creation_date, created_by,
			summary_flag, enabled_flag) values
           (l_so_id, l_segment1, l_segment2, l_segment3, fnd_global.user_id, sysdate,
		fnd_global.login_id, sysdate, fnd_global.user_id, 'N', 'Y') ;

          x_salesorder_id := l_so_id ;

       END;

     end if;

     EXCEPTION
       when fnd_api.g_exc_error then
         x_return_status := fnd_api.g_ret_sts_error ;

         fnd_msg_pub.count_and_get(
           p_count   => x_message_count
         , p_data    => x_message_data
         , p_encoded => 'F');

       when fnd_api.g_exc_unexpected_error then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

         fnd_msg_pub.count_and_get(
           p_count   => x_message_count
         , p_data    => x_message_data
         , p_encoded => 'F');

       when others then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

         if (fnd_msg_pub.check_msg_level
           (fnd_msg_pub.g_msg_lvl_unexp_error))then
           fnd_msg_pub.add_exc_msg(g_package_name,c_api_name);
         end if;

         fnd_msg_pub.count_and_get(
           p_count   => x_message_count
         , p_data    => x_message_data
         , p_encoded => 'F');


end create_salesorder;


/*-------------------------------------------------------------------------------------+
 | get_oe_header_for_salesorder returns the order management order header id given a   |
 | sales order id. If the sales order id does not have a matching order managemnet     |
 | order header id, then a value (-1) is returned. This is possible since not all rows |
 | in mtl_sales_orders may be created by Order Management.			       |
 +-------------------------------------------------------------------------------------*/

Procedure get_oeheader_for_salesorder(
		p_salesorder_id		IN	NUMBER,
		x_oe_header_id		OUT	NUMBER,
		x_return_status		OUT	VARCHAR2) IS

  -- Constants
     c_api_version_number CONSTANT NUMBER  	:= 1.0 ;
     c_api_name 	  CONSTANT VARCHAR2(50)	:= 'GET_OEHEADER_FOR_SALESORDER';

  -- Local Variables
     l_order_source	VARCHAR2(1000);
     l_order_header_id	VARCHAR2(50);
     l_order_number	VARCHAR2(50);
     l_order_type	VARCHAR2(50);

BEGIN

  -- initialize return status to success
     x_return_status := fnd_api.g_ret_sts_success;

  -- initialize x_oe_order_id to -1, assume default that SO row not created by OOM
     x_oe_header_id := -1 ;

  -- now check if the SO was created by Oracle Order Management (OOM). If not return (-1)
     if ( g_om_installed IS NULL ) then
       g_om_installed := oe_install.get_active_product ;
     end if;
     if (g_om_installed <> 'ONT') then -- OOM is not active
       return ;
     end if;

  -- now select segment 2 for the given sales order id
     SELECT segment1,segment2,segment3
     INTO l_order_number, l_order_type, l_order_source
     FROM mtl_sales_orders
     WHERE sales_order_id = p_salesorder_id ;


     x_oe_header_id := get_header_id(to_number(l_order_number),
							l_order_type,
							l_order_source);

     EXCEPTION
       when fnd_api.g_exc_error then
         x_return_status := fnd_api.g_ret_sts_error ;

       when fnd_api.g_exc_unexpected_error then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

       when no_data_found then
         x_return_status := fnd_api.g_ret_sts_success ;

       when others then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

         if (fnd_msg_pub.check_msg_level
           (fnd_msg_pub.g_msg_lvl_unexp_error))then
           fnd_msg_pub.add_exc_msg(g_package_name,c_api_name);
         end if;

end get_oeheader_for_salesorder;


/*---------------------------------------------------------------------------------------+
 | Function get_salesorder_for_oeheader returns the corresponding sales order id for a   |
 | given order management header id. If a sales order does not exist, then a null is     |
 | returned by this function.								 |
 +---------------------------------------------------------------------------------------*/

Function get_salesorder_for_oeheader(
		p_oe_header_id		IN	NUMBER) return number is

  --local variables
  l_salesorder_id	NUMBER;
  l_order_source	VARCHAR2(2000);
  l_order_type		VARCHAR2(2000);
  l_order_number	NUMBER ;

BEGIN

IF g_order_headers.exists(p_oe_header_id) THEN

  l_salesorder_id := g_order_headers(p_oe_header_id).salesorder_id;
ELSE
   oe_header_util.get_order_info(p_oe_header_id,
				l_order_number,
				l_order_type,
				l_order_source);

   SELECT sales_order_id
   INTO l_salesorder_id
   FROM mtl_sales_orders
   WHERE segment1 = to_char(l_order_number)
   AND segment2 = l_order_type
   AND segment3 = l_order_source ;

   g_order_headers(p_oe_header_id).salesorder_id := l_salesorder_id;
   g_order_headers(p_oe_header_id).order_number := l_order_number;
   g_order_headers(p_oe_header_id).order_type := l_order_type;
   g_order_headers(p_oe_header_id).order_source := l_order_source;
   g_order_headers(p_oe_header_id).oe_header_id := p_oe_header_id;

END IF;

return l_salesorder_id ;

Exception

  WHEN OTHERS then
    return to_number(null);

end get_salesorder_for_oeheader ;

/*----------------------------------------------------------------------------------------+
 | This function,  synch_salesorders_with_om, is used to update an existing sales order   |
 | with new segment values for either order_number and/or order type and/or order source  |
 | given an original order number and/or order type and/or order source. This API is      |
 | is provided because in Order Management the order number and order type can be updated |
 | even after a sales order has been created. The input parameter "multiple_rows"         |
 | determines whether it is teh intention of the caller to update multiple rows.	  |
 +----------------------------------------------------------------------------------------*/

function synch_salesorders_with_om(
		p_original_order_number	IN	VARCHAR2,
		p_original_order_type	IN	VARCHAR2,
		p_original_source_code	IN	VARCHAR2,
		p_new_order_number	IN	VARCHAR2,
		p_new_order_type	IN	VARCHAR2,
		p_new_order_source	IN	VARCHAR2,
		p_multiple_rows		IN	VARCHAR2 default 'N') return number IS

BEGIN

   -- Bug 2648869: Performance fix. The update statement was changed based on
   -- whether thep_multiple_rows is Y or N. If it is N, then all the
   -- parameters are passed, so the SQL need not have the NVL.
   -- This is will help is utilizing the index
   -- and the fetch will be faster.

   if (p_multiple_rows <> 'Y' ) THEN

      if ( (p_original_order_number IS NULL) OR
	   (p_original_order_type IS NULL) OR
	   (p_original_source_code IS NULL) ) then
	 return 0 ;
       ELSE
	 UPDATE mtl_sales_orders
	   SET segment1 = NVL(p_new_order_number,segment1),
	   segment2 = NVL(p_new_order_type, segment2),
	   segment3 = NVL(p_new_order_source, segment3)
	   WHERE segment1 = p_original_order_number
	   AND   segment2 = p_original_order_type
	   AND   segment3 = p_original_source_code;
      end if;

    ELSE

      UPDATE mtl_sales_orders
	SET segment1 = NVL(p_new_order_number,segment1),
	segment2 = NVL(p_new_order_type, segment2),
	segment3 = NVL(p_new_order_source, segment3)
	WHERE segment1 = NVL(p_original_order_number,segment1)
	AND   segment2 = NVL(p_original_order_type,segment2)
	AND   segment3 = NVL(p_original_source_code,segment3);

   end if;

   return 1;

EXCEPTION

  WHEN NO_DATA_FOUND then
    return 0 ;

end synch_salesorders_with_om ;
FUNCTION Get_Header_Id (p_order_number    IN  NUMBER,
                        p_order_type      IN  VARCHAR2,
                        p_order_source    IN  VARCHAR2)
RETURN NUMBER
IS
        l_order_type_id          NUMBER;
        l_order_type             VARCHAR2(240);
        l_header_id              NUMBER;
BEGIN

    Select header_id
    into l_header_id
    from oe_order_headers_all
    where order_number = p_order_number AND
          order_type_id = (select tl.transaction_type_id
                           from oe_transaction_types_tl tl,
                                                  oe_transaction_types_all ta
                           where ta.transaction_type_id =
                                          tl.transaction_type_id and
                                          tl.name = p_order_type and
                                          ta.transaction_type_code = 'ORDER'
                                         and LANGUAGE = (
                                        select language_code
                        from fnd_languages
                        where installed_flag = 'B'));

    RETURN l_header_id;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RETURN -1;
   WHEN OTHERS THEN
     RETURN -1;

END Get_Header_Id;

Procedure create_mtl_sales_orders_bulk (
		p_api_version_number	IN	NUMBER,
		p_init_msg_list		IN	VARCHAR2 DEFAULT FND_API.G_FALSE,
		p_header_rec		IN	OE_BULK_ORDER_PVT.HEADER_REC_TYPE,
		x_message_data		OUT	VARCHAR2,
		x_message_count		OUT	NUMBER,
		x_return_status		OUT	VARCHAR2) IS

  -- Constants
     c_api_version_number CONSTANT NUMBER  	:= 1.0 ;
     c_api_name 	  CONSTANT VARCHAR2(50):= 'CREATE_MTL_SALES_ORDERS_BULK';

  l_source_code		VARCHAR2(40) := FND_PROFILE.VALUE('ONT_SOURCE_CODE');

BEGIN
  -- check for api call compatibility
     if not fnd_api.compatible_api_call(
	c_api_version_number,
	p_api_version_number,
	c_api_name,
	g_package_name) then
	  raise fnd_api.g_exc_unexpected_error ;
     end if;

  -- initialize message list
     if fnd_api.to_boolean(p_init_msg_list) then
       fnd_msg_pub.initialize;
     end if;

  -- initialize return status to success
     x_return_status := fnd_api.g_ret_sts_success;


     FORALL i IN p_header_rec.order_number.FIRST..p_header_rec.order_number.LAST
     INSERT INTO MTL_SALES_ORDERS
     (sales_order_id,
      segment1,
      segment2,
      segment3,
      last_updated_by,
      last_update_date,
      last_update_login,
      creation_date,
      created_by,
      summary_flag,
      enabled_flag)
     Values(
      mtl_sales_orders_s.nextval,
      p_header_rec.order_number(i),
      p_header_rec.order_type_name(i),
      l_source_code,
      fnd_global.user_id,
      sysdate,
      fnd_global.login_id,
      sysdate,
      fnd_global.user_id,
      'N',
      'Y');

EXCEPTION
       when fnd_api.g_exc_unexpected_error then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

         fnd_msg_pub.count_and_get(
           p_count   => x_message_count
         , p_data    => x_message_data
         , p_encoded => 'F');

         OE_MSG_PUB.Add_Exc_Msg(g_package_name, c_api_name, x_message_data);

       when others then
         x_return_status := fnd_api.g_ret_sts_unexp_error;

         if (fnd_msg_pub.check_msg_level
           (fnd_msg_pub.g_msg_lvl_unexp_error))then
           fnd_msg_pub.add_exc_msg(g_package_name,c_api_name);
         end if;

         fnd_msg_pub.count_and_get(
           p_count   => x_message_count
         , p_data    => x_message_data
         , p_encoded => 'F');
         OE_MSG_PUB.Add_Exc_Msg(g_package_name, c_api_name, x_message_data);

END create_mtl_sales_orders_bulk;


PROCEDURE delete_mtl_sales_orders_bulk(
		p_api_version_number	IN	NUMBER,
		p_init_msg_list		IN	VARCHAR2 DEFAULT FND_API.G_FALSE,
		p_error_rec		IN	OE_BULK_ORDER_PVT.INVALID_HDR_REC_TYPE,
		x_message_data		OUT	VARCHAR2,
		x_message_count		OUT	NUMBER,
		x_return_status		OUT	VARCHAR2) IS

  -- Constants
     c_api_version_number CONSTANT NUMBER  	:= 1.0 ;
     c_api_name 	  CONSTANT VARCHAR2(50):= 'DELETE_MTL_SALES_ORDERS_BULK';
BEGIN
  -- check for api call compatibility
     if not fnd_api.compatible_api_call(
        c_api_version_number,
        p_api_version_number,
        c_api_name,
        g_package_name) then
          raise fnd_api.g_exc_unexpected_error ;
     end if;

  -- initialize message list
     if fnd_api.to_boolean(p_init_msg_list) then
       fnd_msg_pub.initialize;
     end if;

  -- initialize return status to success
     x_return_status := fnd_api.g_ret_sts_success;

  --Delete MTL Sales Order Records
  /*Bug3575085:Changed the sequence of the sub-query from b.name,a.order_number
    to a.order_number,b.name*/
    /* Modified by nbapuji on 14/04/09 for performance improvement */
    /* Added to_char to order number */
     FORALL i IN 1..P_ERROR_REC.header_id.COUNT
	DELETE from mtl_sales_orders
	WHERE (segment1, segment2) IN
	(select TO_CHAR(a.order_number),b.name
	 FROM oe_order_headers a,
	      oe_order_types_v b
	 WHERE a.header_id = p_error_rec.header_id(i)
	   AND a.order_type_id = b.order_type_id);


EXCEPTION
    when others then
      fnd_msg_pub.count_and_get(
         p_count   => x_message_count
       , p_data    => x_message_data
       , p_encoded => 'F');

      OE_MSG_PUB.Add_Exc_Msg(g_package_name, c_api_name, x_message_data);
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

END delete_mtl_sales_orders_bulk;

end inv_salesorder ;

/
SHOW ERRORS PACKAGE BODY inv_salesorder;
EXIT;

create or replace
PACKAGE      XX_CS_TDS_PARTS_RECEIPTS AS 

G_PROD_CODE            CONSTANT VARCHAR2(5) := 'CSP';

TYPE rcv_hdr_rec_type IS RECORD (
			header_interface_id 	  NUMBER,
			group_id 		            NUMBER,
      vendor_id               NUMBER    ,
			vendor_site_id		      NUMBER	  ,
      source_type_code        VARCHAR2(30),
			receipt_source_code	    VARCHAR2(25),
			ship_to_org_id		      NUMBER	  ,
			rcv_shipment_num 	      VARCHAR2(30),
			receipt_header_id 	    NUMBER,
			receipt_num		          VARCHAR2(30),
			bill_of_lading		      VARCHAR2(25),
			packing_slip 		        VARCHAR2(25),
			shipped_date 		        DATE,
			freight_carrier_code 	  VARCHAR2(25),
			expected_receipt_date 	DATE,
			employee_id 		        NUMBER,
			waybill_airbill_num 	  VARCHAR2(20),
			usggl_transaction_code 	VARCHAR2(30),
			processing_request_id 	NUMBER,
			customer_id 		        NUMBER,
			customer_site_id 	      NUMBER);

TYPE rcv_rec_type IS RECORD(
    interface_transaction_id 		  NUMBER
  , transaction_interface_id 		  NUMBER
  , header_interface_id 		      NUMBER
  , group_id 				              NUMBER
  , inv_loc_assignment_id		      NUMBER
  , source_type_code               VARCHAR2(30)
  , receipt_source_code            VARCHAR2(30)
  , transaction_type               VARCHAR2(25)
  , order_type_code                VARCHAR2(30)
  , order_type                     VARCHAR2(80)
  , po_header_id                   NUMBER
  , po_number                      VARCHAR2(30)
  , po_line_id                     NUMBER
  , po_line_number                 NUMBER
  , po_line_location_id            NUMBER
  , po_shipment_number             NUMBER
  , po_release_id                  NUMBER
  , po_release_number              NUMBER
  , req_header_id                  NUMBER
  , req_number                     VARCHAR2(80)
  , req_line_id                    NUMBER
  , req_line                       NUMBER
  , req_distribution_id            NUMBER
  , rcv_shipment_header_id         NUMBER
  , rcv_shipment_number            VARCHAR2(30)
  , rcv_shipment_line_id           NUMBER
  , rcv_line_number                NUMBER
  , parent_transaction_id          NUMBER
  , from_organization_id           NUMBER
  , from_subinventory              VARCHAR2(10)
  , to_organization_id             NUMBER
  , vendor_id                      NUMBER
  , SOURCE                         VARCHAR2(255)
  , vendor_site_id                 NUMBER
  , outside_operation_flag         VARCHAR2(1)
  , receipt_exception         	   VARCHAR2(1)
  , item_id                        NUMBER
  , uom_code                       VARCHAR2(3)
  , primary_uom                    VARCHAR2(25)
  , primary_uom_class              VARCHAR2(10)
  , item_allowed_units_lookup_code NUMBER
  , item_locator_control           NUMBER
  , restrict_locators_code         VARCHAR2(1)
  , restrict_subinventories_code   VARCHAR2(1)
  , shelf_life_code                NUMBER
  , shelf_life_days                NUMBER
  , serial_number_control_code     NUMBER
  , lot_control_code               NUMBER
  , item_rev_control_flag_to       VARCHAR2(1)
  , item_rev_control_flag_from     VARCHAR2(1)
  , item_number                    VARCHAR2(40)
  , item_revision                  VARCHAR2(3)
  , item_description               VARCHAR2(240)
  , item_category_id               NUMBER
  , hazard_class                   VARCHAR2(40)
  , un_number                      VARCHAR2(30)
  , vendor_item_number             VARCHAR2(30)
  , ship_to_location_id            NUMBER
  , ship_to_location               VARCHAR2(60)
  , packing_slip                   VARCHAR2(80)
  , routing_id                     NUMBER
  , routing_name                   VARCHAR2(30)
  , need_by_date                   DATE
  , expected_receipt_date          DATE
  , ordered_qty                    NUMBER
  , ordered_uom                    VARCHAR2(25)
  , ussgl_transaction_code         VARCHAR2(30)
  , government_context             VARCHAR2(30)
  , inspection_required_flag       VARCHAR2(1)
  , receipt_required_flag          VARCHAR2(1)
  , enforce_ship_to_location_code  VARCHAR2(30)
  , substitute_receipt  	         VARCHAR2(30)
  , unit_price                     NUMBER
  , currency_code                  VARCHAR2(30)
  , currency_conversion_type       VARCHAR2(30)
  , currency_conversion_date       DATE
  , currency_conversion_rate       NUMBER
  , note_to_receiver               VARCHAR2(240)
  , destination_type_code          VARCHAR2(30)
  , deliver_to_person_id           NUMBER
  , deliver_to_location_id         NUMBER
  , destination_subinventory       VARCHAR2(10)
  , attribute_category             VARCHAR2(30)
  , attribute1                     VARCHAR2(240)
  , attribute2                     VARCHAR2(240)
  , attribute3                     VARCHAR2(240)
  , attribute4                     VARCHAR2(240)
  , attribute5                     VARCHAR2(240)
  , attribute6                     VARCHAR2(240)
  , attribute7                     VARCHAR2(240)
  , attribute8                     VARCHAR2(240)
  , attribute9                     VARCHAR2(240)
  , attribute10                    VARCHAR2(240)
  , attribute11                    VARCHAR2(240)
  , attribute12                    VARCHAR2(240)
  , attribute13                    VARCHAR2(240)
  , attribute14                    VARCHAR2(240)
  , attribute15                    VARCHAR2(240)
  , closed_code                    VARCHAR2(30)
  , asn_type                       VARCHAR2(30)
  , bill_of_lading                 VARCHAR2(30)
  , shipped_date                   DATE
  , freight_carrier_code           VARCHAR2(30)
  , waybill_airbill_num            VARCHAR2(80)
  , freight_bill_num               VARCHAR2(35)
  , vendor_lot_num                 VARCHAR2(30)
  , container_num                  VARCHAR2(35)
  , truck_num                      VARCHAR2(35)
  , bar_code_label                 VARCHAR2(35)
  , rate_type_display              VARCHAR2(30)
  , match_option                   VARCHAR2(25)
  , country_of_origin_code         VARCHAR2(2)
  , oe_order_header_id             NUMBER
  , oe_order_num                   NUMBER
  , oe_order_line_id               NUMBER
  , oe_order_line_num              NUMBER
  , customer_id                    NUMBER
  , customer_site_id               NUMBER
  , customer_item_num              VARCHAR2(50)
  , pll_note_to_receiver           VARCHAR2(240)
  , po_distribution_id             NUMBER
  , qty_ordered                    NUMBER
  , wip_entity_id                  NUMBER
  , wip_operation_seq_num          NUMBER
  , wip_resource_seq_num           NUMBER
  , wip_repetitive_schedule_id     NUMBER
  , wip_line_id                    NUMBER
  , bom_resource_id                NUMBER
  , destination_type               VARCHAR2(80)
  , LOCATION                       VARCHAR2(60)
  , currency_conversion_rate_pod   NUMBER
  , currency_conversion_date_pod   DATE
  , project_id                     NUMBER
  , task_id                        NUMBER
  , locator_id                     NUMBER
  , employee_id 		               NUMBER
  , lot_number 			               VARCHAR2(30)
  , transaction_quantity           NUMBER
  , transaction_uom                VARCHAR2(25)
  , primary_quantity               NUMBER
  , lot_quantity                   NUMBER
  , lot_primary_quantity           NUMBER
  , expiration_date                DATE
  , status_id                      NUMBER
  , product_transaction_id         NUMBER
  , product_code 		               VARCHAR2(5)  
  , att_exist 		                  VARCHAR2(1)  
  , update_mln 		                  VARCHAR2(1)  
  , description 		                VARCHAR2(256)  
  , vendor_name 		                VARCHAR2(240)  
  , supplier_lot_number 	          VARCHAR2(150)  
  , origination_date               DATE      
  , date_code 		                VARCHAR2(150)  
  , grade_code 		                VARCHAR2(150)  
  , change_date                   DATE      
  , maturity_date                 DATE      
  , retest_date                   DATE      
  , age                           NUMBER    
  , item_size                     NUMBER    
  , color 			                  VARCHAR2(150)  
  , volume                        NUMBER    
  , volume_uom 		                VARCHAR2(3)  
  , place_of_origin 	            VARCHAR2(150)  
  , best_by_date                  DATE      
  , length                        NUMBER    
  , length_uom 		                VARCHAR2(3)  
  , recycled_content              NUMBER    
  , thickness                     NUMBER    
  , thickness_uom 		            VARCHAR2(3)  
  , width                         NUMBER    
  , width_uom 		                VARCHAR2(3)  
  , curl_wrinkle_fold 	          VARCHAR2(150)  
  , territory_code 		            VARCHAR2(30)  
  , fm_serial_number 	            VARCHAR2(30)
  , to_serial_number 	            VARCHAR2(30)
  , update_msn 		                VARCHAR2(1)  
  , vendor_serial_number 	        VARCHAR2(30) 
  , vendor_lot_number 	          VARCHAR2(30) 
  , parent_serial_number 	        VARCHAR2(30) 
  , time_since_new 		            NUMBER
  , cycles_since_new 	            NUMBER
  , time_since_overhaul 	        NUMBER
  , cycles_since_overhaul 	      NUMBER
  , time_since_repair 	          NUMBER
  , cycles_since_repair 	        NUMBER
  , time_since_visit 	            NUMBER
  , cycles_since_visit 	          NUMBER
  , time_since_mark 	            NUMBER
  , cycles_since_mark 	          NUMBER
  , number_of_repairs   	        NUMBER
  , set_of_books_id_sob           NUMBER
  , reason_id   		              NUMBER
  , create_debit_memo_flag        VARCHAR2(1)
  , currency_code_sob             VARCHAR2(15)
  , department_code               VARCHAR2(10)
  , comments     		              VARCHAR2(240) );


TYPE csp_global_var_rec IS RECORD (
			transaction_interface_id NUMBER);

g_csp_var_rec csp_global_var_rec;

TYPE rcv_rec_tbl_type IS TABLE OF rcv_rec_type INDEX BY BINARY_INTEGER;

PROCEDURE receive_shipments
		       (P_Api_Version_Number 	IN NUMBER,
            P_init_Msg_List      	IN VARCHAR2,
            P_Commit             	IN VARCHAR2,
            P_Validation_Level   	IN NUMBER,
            p_document_number	    IN VARCHAR2,
            p_resource_id           IN NUMBER,
            X_Return_Status      	OUT NOCOPY VARCHAR2,
            X_Msg_Count           OUT NOCOPY NUMBER,
            X_Msg_Data 		        OUT NOCOPY VARCHAR2);

PROCEDURE insert_rcv_hdr_interface
		       (P_Api_Version_Number 	IN NUMBER,
			P_init_Msg_List      	IN VARCHAR2,
    			P_Commit             	IN VARCHAR2,
    			P_Validation_Level   	IN NUMBER,
    			X_Return_Status      	OUT NOCOPY VARCHAR2,
    			X_Msg_Count             OUT  NOCOPY NUMBER,
    		 	X_Msg_Data              OUT  NOCOPY VARCHAR2,
			p_header_interface_id   IN NUMBER,
			p_group_id       	IN NUMBER,
			p_receipt_source_code	IN VARCHAR2,
			p_source_type_code	IN VARCHAR2,
			p_vendor_id		IN NUMBER,
			p_vendor_site_id	IN NUMBER,
			p_ship_to_org_id	IN NUMBER,
			p_shipment_num		IN VARCHAR2,
			p_receipt_header_id	IN NUMBER,
			p_receipt_num		IN VARCHAR2,
			p_bill_of_lading	IN VARCHAR2,
			p_packing_slip		IN VARCHAR2,
			p_shipped_date		IN DATE,
			p_freight_carrier_code	IN VARCHAR2,
			p_expected_receipt_date	IN DATE,
			p_employee_id		IN NUMBER,
			p_waybill_airbill_num	IN VARCHAR2,
			p_usggl_transaction_code IN VARCHAR2,
			p_processing_request_id	IN NUMBER,
			p_customer_id		IN NUMBER,
			p_customer_site_id	IN NUMBER,
			x_header_interface_id 	OUT NOCOPY NUMBER,
			x_group_id 		OUT NOCOPY NUMBER);

PROCEDURE insert_rcv_txn_interface
		       (P_Api_Version_Number 	IN NUMBER,
			P_init_Msg_List      	IN VARCHAR2,
    			P_Commit             	IN VARCHAR2,
    			P_Validation_Level   	IN NUMBER,
    			X_Return_Status      	OUT NOCOPY VARCHAR2,
    			X_Msg_Count             OUT  NOCOPY NUMBER,
    		 	X_Msg_Data              OUT  NOCOPY VARCHAR2,
			x_interface_transaction_id OUT NOCOPY NUMBER,
			p_receive_rec 		IN rcv_rec_type);


/**********************************************************************/
-- This procedure is to process interface
-- transaction records online.
/*********************************************************************/
PROCEDURE rcv_online_request ( p_group_id	IN NUMBER,
			      x_return_status OUT NOCOPY VARCHAR2,
			      x_msg_data        OUT NOCOPY VARCHAR2);

FUNCTION USER_INPUT_REQUIRED(p_header_id IN
number) RETURN VARCHAR2;

function vendor(p_vendor_id in number) return varchar2;


END XX_CS_TDS_PARTS_RECEIPTS;

/
show errors;
exit;
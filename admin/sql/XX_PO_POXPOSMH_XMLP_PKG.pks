CREATE OR REPLACE PACKAGE APPS.XX_PO_POXPOSMH_XMLP_PKG AUTHID CURRENT_USER AS
-- +========================================================================================+
-- |                           Office Depot - Project Simplify                          	|
-- +========================================================================================+
-- |Package Name : XXPOX_POSMH_INVOKE_PKG                                  		    		|
-- |Purpose      : RICE ID# R0286. This package contains the functions required             |
-- |               to create the OD: Matching Holds by Buyer Report and burst the output	|
-- |			   via XML Bursting in the after report.                   		            |
-- |                                                                           				|
-- |                                                                           				|
-- |Change History                                                             				|
-- |                                                                          				|
-- |Ver   Date          Author                     Description                        		|
-- |---   -----------   -----------------          ------------------------------------		|
-- |1.0   19-OCT-2017  Jimmy "JimGymGem" Nguyen    For Defect 43410. Inital Creation via 	|
-- |                                               a copy of PO_POXPOSMH_XMLP_PKG, an       |
-- |                                               oracle standard package.					|
-- |                                                        								|
-- |																						|
-- +========================================================================================+
	P_title					varchar2(50);
	P_FLEX_ITEM				varchar2(800);
	P_FLEX_CAT				varchar2(3100);
	P_CONC_REQUEST_ID		number;
	P_BUYER					varchar2(240);
	P_VENDOR_FROM			varchar2(240);
	P_VENDOR_TO				varchar2(240);
	P_INVOICE_DATE_FROM		varchar2(40);
	P_INVOICE_DATE_TO		varchar2(40);
	PRICE_HOLD				varchar2(40);
	QTY_ORD_HOLD			varchar2(40);
	QTY_REC_HOLD			varchar2(40);
	QUALITY_HOLD			varchar2(40);
	ORG_ID					varchar2(40);
	P_PRICE_HOLD			varchar2(40);
	P_QTY_ORD_HOLD			varchar2(40);
	P_QTY_REC_HOLD			varchar2(40);
	P_QUALITY_HOLD			varchar2(40);
	P_QTY_PRECISION			number;
	P_WHERE_CAT				varchar2(2000);
	P_WHERE_ITEM			varchar2(2000);
	P_STRUCT_NUM			varchar2(15);
	P_category_from			varchar2(900);
	P_category_to			varchar2(900);
	P_item_from				varchar2(900);
	P_item_to				varchar2(900);
	P_ITEM_STRUCT_NUM		varchar2(32767);
    FORMAT_MASK 			varchar2(100);
	--Defect 43410
    l_layout				BOOLEAN;
	l_orgid					NUMBER;
	v_request_id        	NUMBER;
	v_sub_req           	NUMBER := 0;
	l_req_return_status 	BOOLEAN;
	lc_phase            	VARCHAR2(50);
	lc_status           	VARCHAR2(50);
	lc_dev_phase        	VARCHAR2(50);
	lc_dev_status       	VARCHAR2(50);
	lc_message          	VARCHAR2(50);
	
	function BeforeReport return boolean  ;
	function AfterReport return boolean  ;
	procedure get_precision  ;
	function get_p_struct_num return boolean  ;
	function c_report_avg_no_of_daysformula(C_report_tot_days_hold in number, C_report_number_total in number) return number  ;
	function c_total_days_holdingformula(average in number, number_amount_tot in number) return number  ;
	function c_unit_price_round(unit_price in varchar2, parent_currency_precision in number) return number  ;
	function c_invoice_price_round(invoice_price in number, parent_currency_precision in number) return number  ;
END XX_PO_POXPOSMH_XMLP_PKG;
/
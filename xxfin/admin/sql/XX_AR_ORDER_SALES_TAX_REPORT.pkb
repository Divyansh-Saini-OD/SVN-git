create or replace
PACKAGE BODY XX_AR_ORDER_SALES_TAX_REPORT
IS
PROCEDURE SALES_TAX_REPORT
(    errbuf             IN OUT NOCOPY VARCHAR2,
     retcode            IN OUT NOCOPY VARCHAR2,
     p_fromdate         IN            VARCHAR2,
     p_todate           IN            VARCHAR2,
     p_org_id           IN            VARCHAR2)
AS
/*The purpose of this program is to generate a report that will list orders
  that have a different ship-to order from the customer master file **/
/*Declare variables**/
v_order_nbr	        varchar2(20);
v_cust_nbr	        varchar2(240);
v_acct_name	        varchar2(240);
v_ord_ship_to_seq	varchar2(5);
v_ord_ship_to_st	varchar2(60);
v_ord_ship_to_country	varchar2(60);
v_ord_cust_state	varchar2(60);
v_ord_cust_province	varchar2(60);
v_ord_cust_country	varchar2(60);
v_tax_amount            number := 0;
v_filehandle            utl_file.file_type; 
v_filedate              varchar(50);
v_counter	        number:= 0;
ln_request_id           number;
v_fromdate              date;
v_todate                date;
v_first_pass            boolean := TRUE;
/* Create a cursor to extract multiple records*/
CURSOR AR_cur is
  select a.trx_number,
         d.orig_system_reference,
         d.account_name,
         c.ship_to_sequence,
         c.ship_to_state,
         c.ship_to_country,
         h.state,
         h.province,
         h.country,
         i.tax_value
  from (select /* index(a1) */ * from ra_customer_trx_all a1 where a1.interface_header_attribute2 in ('SA US Standard', 'SA CA Standard','SA US Return','SA CA Return')) a,
       (select /* index(a1)  */* from oe_order_headers_all a1) b,
       (select /* index(a1)  */* from xx_om_header_attributes_all a1 ) c,
       (select /* index(a1)  */* from hz_cust_accounts_all a1) d,
       (select /* index(a1)  */* from hz_cust_acct_sites_all a1)e,
       (select /* index(a1)  */* from hz_cust_site_uses_all a1) f,
       (select /* index(a1)  */* from hz_party_sites a1)g,
       (select /* index(a1)  */* from hz_locations a1)h,
       (select /* index(a1)  */* from oe_order_lines_all a1)i
    where a.trx_date between v_fromdate and v_todate
    and a.org_id = p_org_id
    and a.attribute14 = b.header_id
    and b.header_id = i.header_id
    and c.header_id = b.header_id
    and d.cust_account_id = a.ship_to_customer_id
    and e.cust_account_id = d.cust_account_id
    and f.cust_acct_site_id = e.cust_acct_site_id
    and f.site_use_id = a.ship_to_site_use_id
    and g.party_site_id  = e.party_site_id
    and h.location_id = g.location_id;
AR_rec   AR_cur%ROWTYPE;

BEGIN   
    v_fromdate := fnd_date.canonical_to_date(p_fromdate);
    v_todate   := fnd_date.canonical_to_date(p_todate);
    v_filedate := TO_CHAR(SYSDATE,'MMDDYYYYHH24MISS');
    v_filehandle := utl_file.fopen('XXFIN_OUTBOUND', 'XX_AR_SHIPTO_DIFFERENCE_REPORT_' || v_filedate || '.txt', 'w', 4000);
    utl_file.put_line(v_filehandle, 'ORDER NBR |CUSTOMER NUMBER |ACCOUNT NAME  |TAX AMOUNT  |ORD SHIP-TO SEQUENCE|ORD SHIP-TO STATE |ORD SHIP-TO COUNTRY|CUSTOMER STATE |CUSTOMER PROVINCE |CUSTOMER COUNTRY');
    OPEN AR_cur;
	LOOP
 	   FETCH AR_cur INTO AR_rec;
	   EXIT WHEN AR_cur%NOTFOUND;
           IF ((AR_rec.ship_to_country = 'USA' and AR_rec.ship_to_state <> AR_rec.state) or
               (AR_rec.ship_to_country = 'CAN' and AR_rec.ship_to_state <> AR_rec.province))
           THEN
              IF NOT v_first_pass and
                    (v_order_nbr           <> AR_rec.trx_number or
                     v_cust_nbr            <> AR_rec.orig_system_reference or
                     v_acct_name 	        <> AR_rec.account_name  or
	             v_ord_ship_to_seq     <> AR_rec.ship_to_sequence or
    	             v_ord_ship_to_st 	<> AR_rec.ship_to_state or
	             v_ord_ship_to_country <> AR_rec.ship_to_country or
	             v_ord_cust_state 	<> AR_rec.state or
	             v_ord_cust_province   <> AR_rec.province or
                     v_ord_cust_country    <> AR_rec.country)
                 THEN    
                      utl_file.put_line(v_filehandle, v_order_nbr           || '|' || 
                                v_cust_nbr            || '|' ||
                                v_acct_name           || '|' ||
                                v_tax_amount          || '|' ||
                       	        v_ord_ship_to_seq     || '|' ||
              		        v_ord_ship_to_st      || '|' ||
  			        v_ord_ship_to_country || '|' ||
                                v_ord_cust_state      || '|' ||
             		        v_ord_cust_province   || '|' ||
                                v_ord_cust_country);
                     v_tax_amount := 0;
              END IF;       
           v_first_pass := FALSE;
	   v_counter 		 := v_counter + 1;
	   v_order_nbr 		 := AR_rec.trx_number;
	   v_cust_nbr 		 := AR_rec.orig_system_reference;
	   v_acct_name 	  	 := AR_rec.account_name;
	   v_ord_ship_to_seq 	 := AR_rec.ship_to_sequence;
    	   v_ord_ship_to_st 	 := AR_rec.ship_to_state;
	   v_ord_ship_to_country := AR_rec.ship_to_country;
	   v_ord_cust_state 	 := AR_rec.state;
	   v_ord_cust_province 	 := AR_rec.province;
	   v_ord_cust_country 	 := AR_rec.country;
           v_tax_amount          := v_tax_amount + AR_rec.tax_value;
	  -- dbms_output.put_line('Record    : '  || v_counter);
	  -- dbms_output.put_line('order nbr : '  || v_order_nbr);
	  -- dbms_output.put_line('cust nbr  : '  || v_cust_nbr);
           END IF;
        END LOOP;
        --IF v_tax_amount <> 0 THEN
           utl_file.put_line(v_filehandle, v_order_nbr           || '|' || 
                                           v_cust_nbr            || '|' ||
                                           v_acct_name           || '|' ||
                                           v_tax_amount          || '|' ||
                                           v_ord_ship_to_seq     || '|' ||
                                           v_ord_ship_to_st      || '|' ||
                                           v_ord_ship_to_country || '|' ||
                                           v_ord_cust_state      || '|' ||
                                           v_ord_cust_province   || '|' ||
                                           v_ord_cust_country);
        --   v_tax_amount := 0;
        --END IF;
--        dbms_output.put_line('Total Records created : '  || v_counter);
        close AR_cur;
          utl_file.fclose(v_filehandle);
         ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,'XX_AR_SHIPTO_DIFFERENCE_REPORT_' || v_filedate || '.txt' --source_file_name
                                               ,'XX_AR_SHIPTO_DIFFERENCE_REPORT_' || v_filedate || '.txt' --destination_file_name
                                               ,'Y'                                    -- Delete source file?
                                               ,NULL
                                              );            
        EXCEPTION
        WHEN OTHERS THEN
        /*fnd_file.put_line(FND_FILE.LOG, 'Exception raised while writing into test file.' ||
                        SQLERRM);*/
        RAISE;
END SALES_TAX_REPORT;
END XX_AR_ORDER_SALES_TAX_REPORT;

/
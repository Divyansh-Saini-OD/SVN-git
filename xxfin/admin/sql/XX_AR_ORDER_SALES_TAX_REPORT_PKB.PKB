create or replace PACKAGE BODY XX_AR_ORDER_SALES_TAX_REPORT
IS
PROCEDURE SALES_TAX_REPORT
(    errbuf             IN OUT NOCOPY VARCHAR2,
     retcode            IN OUT NOCOPY VARCHAR2,
     p_fromdate         IN            VARCHAR2,
     p_todate           IN            VARCHAR2)
AS
/*The purpose of this program is to generate a report that will list orders
  that have a different ship-to order from the customer master file **/
/*Declare variables**/
v_order_nbr	varchar2(20);
v_cust_nbr	varchar2(240);
v_acct_name	varchar2(240);
v_ord_ship_to_seq	varchar2(5);
v_ord_ship_to_st	varchar2(60);
v_ord_ship_to_country	varchar2(60);
v_ord_cust_state	varchar2(60);
v_ord_cust_province	varchar2(60);
v_ord_cust_country	varchar2(60);
v_filehandle            utl_file.file_type; 
v_filedate              varchar(50);
v_counter	        number:= 0;
ln_request_id           number;
v_fromdate              date;
v_todate                date;
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
         h.country
  from apps.ra_customer_trx a,
       apps.oe_order_headers b,
       apps.xx_om_header_attributes_all c,
       apps.hz_cust_accounts d,
       apps.hz_cust_acct_sites e,
       apps.hz_cust_site_uses f,
       apps.hz_party_sites g,
       apps.hz_locations h
    where TRUNC(a.trx_date) between trunc(v_fromdate) and trunc(v_todate)
    and a.interface_header_attribute2 in ('SA US Standard', 'SA CA Standard','SA US Return','SA CA Return')
    and to_char(b.order_number) = a.trx_number
    and c.header_id = b.header_id
    and d.cust_account_id = a.ship_to_customer_id
    and e.cust_account_id = d.cust_account_id
    and f.cust_acct_site_id = e.cust_acct_site_id
    and f.site_use_id = a.ship_to_site_use_id
    and g.party_site_id  = e.party_site_id
    and h.location_id = g.location_id
    and ((c.ship_to_country = 'USA' and c.ship_to_state <> h.state) or
         (c.ship_to_country = 'CAN' and c.ship_to_state <> h.province));
AR_rec   AR_cur%ROWTYPE;

BEGIN   
    v_fromdate := fnd_date.canonical_to_date(p_fromdate);
    v_todate   := fnd_date.canonical_to_date(p_todate);
    v_filedate := TO_CHAR(SYSDATE,'MMDDYYYYHH24MISS');
    v_filehandle := utl_file.fopen('XXFIN_OUTBOUND', 'XX_AR_SHIPTO_DIFFERENCE_REPORT_' || v_filedate || '.txt', 'w', 4000);
    utl_file.put_line(v_filehandle, 'ORDER NBR |CUSTOMER NUMBER |ACCOUNT NAME |ORD SHIP-TO SEQUENCE|ORD SHIP-TO STATE |ORD SHIP-TO COUNTRY|CUSTOMER STATE |CUSTOMER PROVINCE |CUSTOMER COUNTRY');
    OPEN AR_cur;
	LOOP
 	   FETCH AR_cur INTO AR_rec;
	   EXIT WHEN AR_cur%NOTFOUND;
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
	  -- dbms_output.put_line('Record    : '  || v_counter);
	  -- dbms_output.put_line('order nbr : '  || v_order_nbr);
	  -- dbms_output.put_line('cust nbr  : '  || v_cust_nbr);
           utl_file.put_line(v_filehandle, v_order_nbr           || '|' || 
                             v_cust_nbr            || '|' ||
                 	     v_acct_name           || '|' ||
			     v_ord_ship_to_seq     || '|' ||
              		     v_ord_ship_to_st      || '|' ||
  			     v_ord_ship_to_country || '|' ||
                             v_ord_cust_state      || '|' ||
             		     v_ord_cust_province   || '|' ||
                             v_ord_cust_country);
        END LOOP;
        dbms_output.put_line('Total Records created : '  || v_counter);
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
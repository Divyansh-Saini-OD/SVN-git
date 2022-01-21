/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  Govind Jayanth                                    A#
 *#W  Company: Smart ERP Solutions, Inc                          X#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARParmbv2.0            March 30, 2007
 *#     Modification History 
 *#     5/30/2007    Govind      Created utility procedures for Office Depot 
 *#                              customization  
 *###############################################################
 *	 Source	File		  :-  XXARTWEUTILS.pls 
 *	 ---> Office Depot <---
 *###############################################################
 */
create or replace
PACKAGE BODY XX_AR_TWE_UTIL_PKG /* $Header: $Twev5ARTaxpsv2.0 */ AS

  /* Given an order number and order type, get tax_value from order line #1 */
  FUNCTION get_legacy_tax_value ( 
    p_cust_trx_id IN NUMBER ) return number is
  
    /* Office Depot Customizations: 5/20/2007: */
    cursor csr_inv_orderinfo (p_cust_trx_id NUMBER) IS
      select interface_header_attribute1 as order_number,
      interface_header_attribute2 as order_type
      from apps.ra_customer_trx
      where customer_trx_id = p_cust_trx_id;

    cursor csr_get_tax_value (p_order_number NUMBER, p_order_type varchar2) is 
    select ordline.tax_value
    from apps.oe_order_lines ordline ,
          apps.oe_order_headers ordhdr,
          apps.oe_order_types_v ordtype
    where ordline.header_id = ordhdr.header_id
    and   ordtype.order_type_id = ordhdr.order_type_id
    and   ordhdr.version_number = 0
    and   ordtype.name = p_order_type
    and   ordhdr.order_number = p_order_number
    and   ordline.line_number = 1;
    
    cursor csr_gt_trx_id IS
    select CUSTOMER_TRX_ID,
           CREATED_BY,
           CREATION_DATE
    from  xx_ar_twe_inv_glb_tmp
    where customer_trx_id = p_cust_trx_id;
    
    l_order_number    number(15);
    l_order_type      varchar2(150);
    l_tax_value       number;
    l_trx_found           varchar2(1);
    
  BEGIN
      taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_legacy_tax_value + ');
      
      /* TAXFN_TAX010 is called multiple times, once for each invoice line
         of the same order. In this case, we must pass in the order-level tax_value
         for the invoice line 1 call, and 0 for the other invoice lines, to the 
         TWE audit tables. To achieve this we store the customer_trx_id in the
         global temporary table during the AR call to TWE for invoice line 1,
         and check the presence of this trx id in the GT table for the other 
         invoice lines and return tax as 0 for these other lines. */
      
      /* GT logic:
         - select trx id from gt
         - if trx_id not present, store the trx id and return the true tax-value.
         - if trx_id is present, return tax_value as 0
      */
      l_trx_found := 'N';
      taxpkg_10.PrintOut(':OD Custom: Checking global temp table for trx id : '||
                                  to_char(p_cust_trx_id));
      for gtrec in csr_gt_trx_id
      loop
         l_trx_found := 'Y';
         taxpkg_10.PrintOut(':OD Custom: FOUND trx_id=['||to_char(gtrec.customer_trx_id)||'],'||
                              ' created_by, date = ['||to_char(gtrec.created_by)||
                              ' ],['||to_char(gtrec.creation_date)||']');
      end loop;
      
      IF (l_trx_found = 'Y')
      then
         /* trx found in gt. return 0 as tax_value for invoice lines 2 and above,
            going into the audit table */
            l_tax_value := 0;
      else
      
         /* First we have to store the customer_trx_id into the GT for future lines */
         taxpkg_10.PrintOut(':OD Custom: trx id NOT FOUND. Creating GTT row.');
         insert into xx_ar_twe_inv_glb_tmp
           (customer_trx_id,
            created_by,
            creation_date
            )
            values
            (p_cust_trx_id,
            APPS.arp_tax.profinfo.user_id,
            sysdate
            );
         taxpkg_10.PrintOut(':OD Custom: Getting order header info from trx_id.');                                                        
          /* TAXWARE called for the first invoice line. Return tax_value from 
             order line 1, for storing into twe audit tables */
          for ordrec in csr_inv_orderinfo ( p_cust_trx_id ) 
          loop
              l_order_number := ordrec.order_number;
              l_order_type := ordrec.order_type;
          end loop;
  
          taxpkg_10.PrintOut(':OD Custom: (Order#,OrderType) = ['||
                            to_char(l_order_number)||'],['||l_order_type||']');
                            
          for crec in csr_get_tax_value (l_order_number, l_order_type)
          loop
            l_tax_value := crec.tax_value;
          end loop;
          taxpkg_10.PrintOut(':OD Custom: Tax Value = ['||to_char(l_tax_value)||']');
          taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_legacy_tax_value - ');
      end if; /* if l_trx_found */    

    taxpkg_10.PrintOut(':OD Custom: Tax Value = ['||to_char(l_tax_value)||']');
    return l_tax_value;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-get_legacy_tax_value:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-get_legacy_tax_value:' || SQLERRM);
      return null;
  END get_legacy_tax_value;


FUNCTION is_legacy_batch_source ( 
    p_ar_batch_source in varchar2 ) return number is
  
    l_is_legacy_batch_source number(15) := 0;
    
     cursor csr_twe_recsrc_lkp IS
      select lookup_code
      from apps.fnd_lookup_values
      where lookup_type = 'TWE_RECORD_SOURCES'
      and enabled_flag ='Y'
      and sysdate between start_date_active and nvl(end_date_active,sysdate); 

  BEGIN
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.is_legacy_batch_source + ');    
    for crec in csr_twe_recsrc_lkp
    loop
      if (crec.lookup_code = p_ar_batch_source)
      then
        l_is_legacy_batch_source := 1;
        exit;
      end if;
    end loop;
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.is_legacy_batch_source - ');    
    return l_is_legacy_batch_source;
    
  EXCEPTION
    WHEN OTHERS THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-is_legacy_batch_source:' || SQLERRM);
      return 0;
  END is_legacy_batch_source;

  /* OD Customization: 
     Given an order number and order type, get tax_value,gst and pst from order line #1.
     This gst,pst component breakup is for Canada for initial phase - May 07 */
  PROCEDURE get_gstpst_tax ( 
    p_cust_trx_id IN NUMBER ,
    p_tax_value IN OUT NOCOPY NUMBER,
    p_pst_value IN OUT NOCOPY NUMBER,
    p_gst_value IN OUT NOCOPY NUMBER) IS
  
    /* Office Depot Customizations: 5/20/2007: */
    cursor csr_inv_orderinfo (p_cust_trx_id NUMBER) IS
      select interface_header_attribute1 as order_number,
      interface_header_attribute2 as order_type
      from apps.ra_customer_trx
      where customer_trx_id = p_cust_trx_id;

    cursor csr_get_tax_value (p_order_number NUMBER, p_order_type varchar2) is 
    select ordline.line_id, ordline.tax_value
    from apps.oe_order_lines ordline ,
          apps.oe_order_headers ordhdr,
          apps.oe_order_types_v ordtype
    where ordline.header_id = ordhdr.header_id
    and   ordtype.order_type_id = ordhdr.order_type_id
    and   ordhdr.version_number = 0
    and   ordtype.name = p_order_type
    and   ordhdr.order_number = p_order_number
    and   ordline.line_number = 1;
    
    cursor csr_gt_trx_id IS
    select CUSTOMER_TRX_ID,
           CREATED_BY,
           CREATION_DATE
    from  xx_ar_twe_inv_glb_tmp
    where customer_trx_id = p_cust_trx_id;
    
    cursor csr_pst_value (p_line_id NUMBER) is 
    select  lines.attribute6 as attr_comb_id, 
            lineattrs.segment34 as pst_value
    from    apps.OE_ORDER_LINES lines , 
            apps.xx_om_lines_attributes_all lineattrs
    where   lines.attribute6 = lineattrs.combination_id 
    and     lines.line_id = p_line_id;
    
    l_order_number    number(15);
    l_order_type      varchar2(150);
    l_trx_found           varchar2(1);
    
    l_tax_value       number := 0;    
    l_gst_value       number := 0;
    l_pst_value       number := 0;
    l_line_id         number(15);
  BEGIN
      taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_gstpst_tax + ');
      
      /* TAXFN_TAX010 is called multiple times, once for each invoice line
         of the same order. In this case, we must pass in the order-level tax_value
         for the invoice line 1 call, and 0 for the other invoice lines, to the 
         TWE audit tables. To achieve this we store the customer_trx_id in the
         global temporary table during the AR call to TWE for invoice line 1,
         and check the presence of this trx id in the GT table for the other 
         invoice lines and return tax as 0 for these other lines. */
      
      /* GT logic:
         - select trx id from gt
         - if trx_id not present, store the trx id and return the true tax-value.
         - if trx_id is present, return tax_value as 0
      */
      l_trx_found := 'N';
      taxpkg_10.PrintOut(':OD Custom: Checking global temp table for trx id : '||
                                  to_char(p_cust_trx_id));
      for gtrec in csr_gt_trx_id
      loop
         l_trx_found := 'Y';
         taxpkg_10.PrintOut(':OD Custom: FOUND trx_id=['||to_char(gtrec.customer_trx_id)||'],'||
                              ' created_by, date = ['||to_char(gtrec.created_by)||
                              ' ],['||to_char(gtrec.creation_date)||']');
      end loop;
      
      IF (l_trx_found = 'Y')
      then
         /* trx found in gt. return 0 as tax_value for invoice lines 2 and above,
            going into the audit table */
            l_tax_value := 0;
            l_pst_value := 0;
            l_gst_value := 0;
      else
      
         /* First we have to store the customer_trx_id into the GT for future lines */
         taxpkg_10.PrintOut(':OD Custom: trx id NOT FOUND. Creating GTT row.');
         insert into xx_ar_twe_inv_glb_tmp
           (customer_trx_id,
            created_by,
            creation_date
            )
            values
            (p_cust_trx_id,
            APPS.arp_tax.profinfo.user_id,
            sysdate
            );
         taxpkg_10.PrintOut(':OD Custom: Getting order header info from trx_id.');                                                        
          /* TAXWARE called for the first invoice line. Return tax_value from 
             order line 1, for storing into twe audit tables */
          for ordrec in csr_inv_orderinfo ( p_cust_trx_id ) 
          loop
              l_order_number := ordrec.order_number;
              l_order_type := ordrec.order_type;
          end loop;
  
          taxpkg_10.PrintOut(':OD Custom: (Order#,OrderType) = ['||
                            to_char(l_order_number)||'],['||l_order_type||']');
                            
          for crec in csr_get_tax_value (l_order_number, l_order_type)
          loop
            l_tax_value := crec.tax_value;
            l_line_id   := crec.line_id; /* order line id */
          end loop;

          taxpkg_10.PrintOut(':OD Custom: Order line id = ['||to_char(l_line_id)||']');          
          taxpkg_10.PrintOut(':OD Custom: Tax Value = ['||to_char(l_tax_value)||']');
          
          /* Get PST value from XX_OM_LINES_ATTRIBUTES_ALL custom table */
          for pstrec in csr_pst_value (l_line_id)
          loop
            l_pst_value := pstrec.pst_value;
            l_gst_value := l_tax_value - l_pst_value;
            taxpkg_10.PrintOut(':OD Custom: GST=['||to_char(l_gst_value)||'], PST=['||
                      to_char(l_pst_value)||']');  
          end loop;
 
      end if; /* else if l_trx_found */    
   
      p_tax_value := l_tax_value; /* total tax for order from legacy */
      p_gst_value := l_gst_value;
      p_pst_value := l_pst_value;
    
      taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_gstpst_tax - ');    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-get_gstpst_tax:NO_DATA_FOUND');
    WHEN OTHERS THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-get_gstpst_tax:' || SQLERRM);
  END get_gstpst_tax;

FUNCTION is_internal_order ( 
    p_line_id in varchar2) return number is
  
    l_is_iso number(15) := 0;
    
    cursor csr_iso_lkp IS
      select line.line_id,
             'Y' as iso_flag
      from  apps.oe_order_headers hdr, 
            apps.oe_order_lines line,  
            apps.oe_order_types_v ordtype
      where line.line_id = p_line_id
      and   line.header_id = hdr.header_id
      --and   hdr.order_source_id = 10      /* Internal */                    
      and   ordtype.name = 'Internal Order'
      and   ordtype.order_type_id = hdr.order_type_id;

  BEGIN
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.is_internal_order + ');    
    for crec in csr_iso_lkp
    loop
      if ((crec.line_id = p_line_id) and (crec.iso_flag = 'Y'))
      then
        l_is_iso := 1;
        taxpkg_10.PrintOut(':OD Custom: ...INTERNAL ORDER LINE... ');
        exit;
      end if;
    end loop;
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.is_internal_order - ');    
    return l_is_iso;
    
  EXCEPTION
    WHEN OTHERS THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-is_internal_order:' || SQLERRM);
      return 0;
  END is_internal_order;

  FUNCTION get_order_date (
    p_view_name       IN VARCHAR2,
    p_cust_trx_id     IN NUMBER,
    p_order_line_id   IN NUMBER
    ) RETURN DATE IS
  
    l_order_date  DATE;
    CURSOR csr_inv_order_date IS
      select ordhdr.ordered_date
        from apps.ra_customer_trx    trx,
             apps.oe_order_headers   ordhdr,
             apps.oe_order_types_v ordtyp
       where trx.customer_trx_id = p_cust_trx_id
         and ordhdr.order_number = trx.interface_header_attribute1
         and ordhdr.order_type_id = ordtyp.order_type_id
         and ordtyp.name = trx.interface_header_attribute2;
         
         
    cursor csr_so_order_date IS
      select hdr.ordered_date
      from  apps.oe_order_headers hdr, 
            apps.oe_order_lines line
      where line.line_id = p_order_line_id
      and   line.header_id = hdr.header_id;
  BEGIN
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_order_date + '); 
    IF p_view_name = 'OE_TAX_LINES_SUMMARY' 
    THEN
      /* Get order data from order. This will work TWE is called for internal orders */
      for crec in csr_so_order_date loop
        l_order_date := crec.ordered_date;
      end loop;
      
    ELSIF p_view_name = 'TAX_LINES_INVOICE_IM' 
    THEN  
      /* Get order date from order, based on invoice. This will work when TWE is called from AR */
      for crec in csr_inv_order_date loop
        l_order_date := crec.ordered_date;
      end loop;

    END IF;

    TAXPKG_10.PrintOut(':Order Date (OD custom code): ' || to_char(l_order_date));    
    taxpkg_10.PrintOut(':OD Custom: XX_AR_TWE_UTIL_PKG.get_order_date - ');       
    return l_order_date;
      
  EXCEPTION
    WHEN OTHERS THEN
      TAXPKG_10.PrintOut('XX_AR_TWE_UTIL_PKG:(E)-get_order_date:' || SQLERRM);
      return null;
  END get_order_date;

END XX_AR_TWE_UTIL_PKG;
/

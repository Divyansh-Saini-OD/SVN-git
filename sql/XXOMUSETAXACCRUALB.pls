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
 *#     5/29/2007    Govind      Created : Procedure Request to accrue 
 *#                              use tax for internal sales orders      
 *###############################################################
 *	 Source	File		  :-  XXOMUSETAXACCRUALB.pls 
 *	 ---> Office Depot <---
 *###############################################################
 */
 
 CREATE OR REPLACE PACKAGE BODY XX_OM_USETAXACCRUAL_PKG AS

--  Global constant holding the package name

G_PKG_NAME                    CONSTANT VARCHAR2(30) := 'XX_OM_USETAXACCRUAL_PKG';
 error_code  	        number;
 error_buf		varchar2(1000);
 l_interface_run_id	number(15);
 l_group_id		number(15);
 l_sob_id		number;


 
/*-----------------------------------------------------------------
PROCEDURE  : Request
DESCRIPTION: OD Custom for TWE: Internal sales order to gl interface for Use Tax Accruals.
-----------------------------------------------------------------*/

Procedure Request
(ERRBUF OUT NOCOPY VARCHAR2,
 RETCODE OUT NOCOPY VARCHAR2,
 p_order_number_low   IN  NUMBER,
 p_order_number_high  IN  NUMBER,
 p_order_date_low   IN  varchar2,
 p_order_date_high  IN  varchar2
) IS

   l_msg_count               NUMBER;
   l_msg_data                VARCHAR2(2000) := NULL;
   l_order_date_low	      date := null;
   l_order_date_high	      date := null;

  a_segments	fnd_flex_ext.SegmentArray;
  l_start_date		date;
  l_entered_dr	number;
  l_entered_cr	number;
  l_status              varchar2(5);
  l_currency_code       varchar2(15);
  err_code   	 	number(15);
--  cr_account	      gl_ussgl_account_pairs.cr_account_segment_value%type;
--  dr_account	      gl_ussgl_account_pairs.cr_account_segment_value%type;
  l_shipto_state      varchar2(10);
  l_use_tax_code      varchar2(15);
  l_flex_num          number;
  seg_num	      number(15) := 0;
  l_use_tax_ccid      number(15);
  l_charge_ccid       number(15);
  
/* Cursor to select data from internal sales order to call TWE.
   oe_order_lines.attribute15 is used to indicate order line already processed
   for tax accrual */
cursor csr_internal_order_lines (p_date_low   date, 
                                 p_date_high  date,
                                 p_order_num_low number,
                                 p_order_num_high number) IS
select  hdr.TRANSACTIONAL_CURR_CODE, 
        line.source_document_line_id as req_line_id,
        dist.code_combination_id as charge_ccid,
        hdr.order_number, 
        hdr.ordered_date, 
        hdr.creation_date, 
        hdr.order_type_id,
        hdr.header_id, 
        line.line_id,
        line.tax_value,
        (line.ordered_quantity * line.unit_selling_price) as line_amount
from  oe_order_headers hdr,
      oe_order_lines line,
      oe_order_types_v ordtype,
      po_req_distributions dist
where line.header_id = hdr.header_id                     
and   ordtype.name = 'Internal Order'
and   line.attribute15 is null
and   hdr.order_type_id = ordtype.order_type_id
and   dist.requisition_line_id = line.source_document_line_id
and   trunc(hdr.creation_date) >=  trunc(nvl(p_date_low,hdr.creation_date))
and   trunc(hdr.creation_date) <= trunc(nvl(p_date_high,hdr.creation_date)) 
and   hdr.order_number >= nvl(p_order_num_low,hdr.order_number)
and   hdr.order_number <= nvl(p_order_num_high,hdr.order_number)
order by hdr.header_id , line.line_id ;

/* Get charge account segments */
cursor csr_charge_segments (p_ccid number) IS
select  glcc.segment1, glcc.segment2, glcc.segment3, glcc.segment4,
        glcc.segment5, glcc.segment6, glcc.segment7
from    gl_code_combinations glcc
where   glcc.code_combination_id = p_ccid;

/* Get shipto state */
cursor csr_shipto_state (p_order_num NUMBER) IS
select ship_loc.state
from OE_ORDER_HEADERS H
, HZ_CUST_SITE_USES_ALL SHIP_SU
, HZ_PARTY_SITES SHIP_PS
, HZ_LOCATIONS SHIP_LOC
, HZ_CUST_ACCT_SITES_ALL SHIP_CAS
where h.order_number = p_order_num 
AND H.SHIP_TO_ORG_ID = SHIP_SU.SITE_USE_ID(+)
AND SHIP_SU.CUST_ACCT_SITE_ID= SHIP_CAS.CUST_ACCT_SITE_ID(+)
AND SHIP_CAS.PARTY_SITE_ID = SHIP_PS.PARTY_SITE_ID(+)
AND SHIP_LOC.LOCATION_ID(+) = SHIP_PS.LOCATION_ID;

/* Get use tax code combination */
cursor csr_use_tax_segments (p_taxcode varchar2,
                            p_sob_id number) IS
select  taxcodes.tax_code_combination_id as use_tax_ccid,
        glcc.segment1, glcc.segment2, glcc.segment3, glcc.segment4,
        glcc.segment5, glcc.segment6, glcc.segment7
from gl_code_combinations glcc,
ap_tax_codes taxcodes
where glcc.code_combination_id = taxcodes.tax_code_combination_id
and taxcodes.tax_type = 'USE'
and taxcodes.set_of_books_id = p_sob_id
and trunc(nvl(taxcodes.start_date,sysdate)) <= trunc(sysdate)
and trunc(nvl(taxcodes.inactive_date,sysdate)) >= trunc(sysdate) 
and taxcodes.name  = p_taxcode;
    
/* Check if we already have a row for this ccid in GT.
   Acct_type_code is a local variable used to denote charge account vs
   tax liability account. 1=charge acct, 2=tax liab acct  */
cursor csr_gt_row ( p_acct_type_code number, p_tax_code varchar2, p_ccid number) IS
select 'Y'
from  xx_om_twe_usetax_glb_tmp
where acct_type_code = p_acct_type_code
and   tax_code = p_tax_code
and   ccid = p_ccid
and   rownum = 1;

cursor csr_gt IS
select decode(acct_type_code,1,'CHARGE ACCT',2,'TAXLIAB ACCT') AS acct_type,
tax_code,
currency_code,
ccid,
entered_dr,
entered_cr,
segment1,
segment2,
segment3,
segment4,
segment5,
segment6,
segment7
from xx_om_twe_usetax_glb_tmp;

l_row_exists varchar2(1);

  
BEGIN
  fnd_file.put_line(FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG.Request + '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));
  error_code := 0;
  error_buf  := NULL;

    l_order_date_low := fnd_date.canonical_to_date(p_order_date_low);
    l_order_date_high := fnd_date.canonical_to_date(p_order_date_high);
  
   fnd_file.put_line(FND_FILE.LOG, 'Program Parameters:');

   fnd_file.put_line(FND_FILE.LOG, '	order_number_low =  '||
                                        p_order_number_low);
   fnd_file.put_line(FND_FILE.LOG, '	order_number_high = '||
                                        p_order_number_high);
   fnd_file.put_line(FND_FILE.LOG, '	order_date_low = '||
                                        l_order_date_low);
   fnd_file.put_line(FND_FILE.LOG, '	order_date_high = '||
                                        l_order_date_high); 

  
  -- Set of Books ID
  select set_of_books_id
  into l_sob_id
  from ar_system_parameters;
  
  SELECT chart_of_accounts_id
    INTO l_flex_num
    FROM gl_sets_of_books
   WHERE set_of_books_id = l_sob_id;

  fnd_file.put_line(FND_FILE.LOG, 'Chart_of_accounts_id/flexnum =  '||to_number(l_flex_num));
 
  --     Obtain the group id
  SELECT gl_interface_control_s.nextval
     INTO l_group_id
     FROM SYS.DUAL;
   
      fnd_file.put_line(FND_FILE.LOG, 'GL INTERFACE GROUP ID =  '||to_number(l_group_id));
      
   /* Get list of internal orders */
   fnd_file.put_line(FND_FILE.LOG, '-----------------------------------------------');
  fnd_file.put_line(FND_FILE.LOG, '--------- Process ISO Cursor START: ------ '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));

   savepoint start_cursor;
   fnd_file.put_line(FND_FILE.LOG, 'Order#, HdrID, LineID, LineAmount, Tax, TaxCode ');
   for isorec in csr_internal_order_lines (
                                    l_order_date_low, 
                                    l_order_date_high,
                                    p_order_number_low,
                                    p_order_number_high)
   loop
      l_currency_code := isorec.transactional_curr_code;
      l_charge_ccid   := isorec.charge_ccid;
            
       /* Get Ship-to State from order */
       for strec in csr_shipto_state (isorec.order_number)
       loop
          l_shipto_state := strec.state;
          l_use_tax_code  := 'USE_'||rtrim(l_shipto_state);
       end loop;
       
      fnd_file.put_line(FND_FILE.LOG, 
            to_char(isorec.order_number)||', '||
            to_char(isorec.header_id)||', '||
            to_char(isorec.line_id)||', '||
            to_char(isorec.line_amount)||', '||
            to_char(isorec.tax_value)||', '||
            l_use_tax_code);       
          
      /* mark the order line as processed, so we don't process this row again. Stamp with gl interface group ID */
      update oe_order_lines 
      set attribute15 = l_group_id
      where line_id = isorec.line_id;
      
       FOR I IN 1..2 LOOP
    
          IF I = 1 THEN
             /* Charge Account from Internal Requisition Line */
                 a_segments(1) := null;
                 a_segments(2) := null;
                 a_segments(3) := null;
                 a_segments(4) := null;
                 a_segments(5) := null;
                 a_segments(6) := null;
                 a_segments(7) := null;  
             for chargerec in csr_charge_segments ( l_charge_ccid )
             loop
                 a_segments(1) := chargerec.segment1;
                 a_segments(2) := chargerec.segment2;
                 a_segments(3) := chargerec.segment3;
                 a_segments(4) := chargerec.segment4;
                 a_segments(5) := chargerec.segment5;
                 a_segments(6) := chargerec.segment6;
                 a_segments(7) := chargerec.segment7;  
                 exit;
             end loop;
             
             l_entered_dr := isorec.tax_value;
             l_entered_cr := 0;
             
             l_row_exists := 'N';
             for gtrec in csr_gt_row ( 1, l_use_tax_code, l_charge_ccid )
             loop
                l_row_exists := 'Y';
             end loop;
             
             if (l_row_exists = 'Y')
             then
                  update xx_om_twe_usetax_glb_tmp
                  set entered_dr = entered_dr + l_entered_dr, 
                      entered_cr = 0
                  where acct_type_code = 1
                  and   tax_code = l_use_tax_code
                  and   ccid = l_charge_ccid;
             else
                  /* GT rows doesn't exist for this tax code,ccid row. Add a row */
                  INSERT into xx_om_twe_usetax_glb_tmp
                      ( acct_type_code,                  
                        tax_code 	,
                        currency_code,
                        created_by,
                        creation_date,
                        ccid ,
                        segment1, segment2, segment3, segment4,
                        segment5, segment6, segment7,
                        entered_dr, entered_cr  )
                    VALUES
                        (1,
                        l_use_tax_code,
                        l_currency_code,
                        3,
                        sysdate,
                        l_charge_ccid,
                        a_segments(1), a_segments(2), a_segments(3), a_segments(4), 
                        a_segments(5), a_segments(6), a_segments(7),
                        l_entered_dr, l_entered_cr                 
                        );
             end if; /* if (l_row_exists */

          ELSE /* IF I = 2 THEN */

             /* State Tax Liability Account */
                 a_segments(1) := null;
                 a_segments(2) := null;
                 a_segments(3) := null;
                 a_segments(4) := null;
                 a_segments(5) := null;
                 a_segments(6) := null;
                 a_segments(7) := null;
             for tcrec in csr_use_tax_segments (l_use_tax_code, l_sob_id)
             loop
               l_use_tax_ccid := tcrec.use_tax_ccid;
               a_segments(1) := tcrec.segment1;
               a_segments(2) := tcrec.segment2;
               a_segments(3) := tcrec.segment3;
               a_segments(4) := tcrec.segment4;
               a_segments(5) := tcrec.segment5;
               a_segments(6) := tcrec.segment6;
               a_segments(7) := tcrec.segment7;  
               exit;
             end loop;
             
             l_entered_cr := isorec.tax_value;
             l_entered_dr := 0;
             
             l_row_exists := 'N';
             for gtrec in csr_gt_row ( 2, l_use_tax_code, l_use_tax_ccid )
             loop
                l_row_exists := 'Y';
             end loop;
             
             if (l_row_exists = 'Y')
             then
                  update xx_om_twe_usetax_glb_tmp
                  set entered_cr = entered_cr + l_entered_cr, 
                      entered_dr = 0
                  where acct_type_code = 2
                  and   tax_code = l_use_tax_code
                  and   ccid = l_use_tax_ccid;
             else
                  /* GT rows doesn't exist for this tax code,ccid row. Add a row */
                  INSERT into xx_om_twe_usetax_glb_tmp
                      ( acct_type_code,                  
                        tax_code 	,
                        currency_code,
                        created_by,
                        creation_date,
                        ccid    ,
                        segment1, segment2, segment3, segment4,
                        segment5, segment6, segment7,
                        entered_dr, entered_cr  )
                    VALUES
                        (2,
                        l_use_tax_code,
                        l_currency_code,
                        3,
                        sysdate,
                        l_use_tax_ccid,
                        a_segments(1), a_segments(2), a_segments(3), a_segments(4), 
                        a_segments(5), a_segments(6), a_segments(7),
                        l_entered_dr, l_entered_cr                
                        );
               end if; /* if (l_row_exists */
             
          END IF;
    
        END LOOP;  /* I - Debit/Credit*/    

   end loop;   /* for isorec in csr_internal_order_lines */  
        
  /* Print GT for debug */
  fnd_file.put_line(FND_FILE.LOG, ' ');
  fnd_file.put_line(FND_FILE.LOG, '--------- Process ISO Cursor END: ------ '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));

  fnd_file.put_line(FND_FILE.LOG, ' ');
  fnd_file.put_line(FND_FILE.LOG, '----- Printing gl_interface data from global temporary table -----');

   for drec in csr_gt
   loop
      fnd_file.put_line(FND_FILE.LOG,
              drec.acct_type||', '||
              drec.tax_code||', '||
              drec.currency_code||', '||
              to_char(drec.ccid)||', Segs: ['||
              drec.segment1||', '||
              drec.segment2||', '||
              drec.segment3||', '||
              drec.segment4||', '||
              drec.segment5||', '||
              drec.segment6||', '||
              drec.segment7||'], '||
              'DR:'||to_char(drec.entered_dr)||', '||
              'CR:'||to_char(drec.entered_cr));
   end loop;
   
  /* Populate GL_INTERFACE table from global temporary table */    
  fnd_file.put_line(FND_FILE.LOG, ' ');
  fnd_file.put_line(FND_FILE.LOG, '------ Populate GL_INTERFACE table from global temporary table ------');  
        INSERT INTO gl_interface(
            status, 
            date_created,
            created_by,
            actual_flag, 
            group_id,
            reference1,
            reference2,
            reference4,
            reference5,
            user_je_source_name,        
            user_je_category_name, 
            set_of_books_id,
            accounting_date, 
            currency_code,
            segment1,
            segment2, segment3,
            segment4, segment5,
            segment6, segment7,
            entered_dr,
            entered_cr,
            reference10)
        SELECT 
            'NEW', 
            SYSDATE, 
            3, --fnd_global.user_id
            'A',
             l_group_id,
             'OD Use Tax',
             null,
             null,
             null,
             'Taxware',
             'OD Use Tax',
            l_sob_id,
            sysdate, 
            gt.currency_code,
            gt.segment1, gt.segment2, gt.segment3, gt.segment4,
            gt.segment5, gt.segment6, gt.segment7,
            gt.entered_dr,
            gt.entered_cr,
            'Internal Sales Order'
        FROM xx_om_twe_usetax_glb_tmp gt;

        fnd_file.put_line(FND_FILE.LOG, 'GL_INTERFACE: Rows inserted = '||to_char(sql%rowcount));
        
        commit;

      fnd_file.put_line(FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG.Request - '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));

        
EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
         fnd_file.put_line(FND_FILE.LOG,
            'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_ERROR');
        fnd_file.put_line(FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
         ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_ERROR';
         RETCODE := 2;
         rollback to start_cursor;
         
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        fnd_file.put_line(FND_FILE.LOG,
            'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_UNEXPECTED_ERROR');
        fnd_file.put_line(FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
        ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_UNEXPECTED_ERROR'; 
        RETCODE := 2;
        rollback to start_cursor;
        
   WHEN OTHERS THEN
	 fnd_file.put_line(FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG errored out.');
          fnd_file.put_line(FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
          ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Check log for details.'; 
          RETCODE := 2;
          rollback to start_cursor;
END Request;

END XX_OM_USETAXACCRUAL_PKG;
/

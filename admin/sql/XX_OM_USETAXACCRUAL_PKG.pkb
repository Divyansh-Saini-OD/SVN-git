CREATE OR REPLACE PACKAGE BODY APPS.XX_OM_USETAXACCRUAL_PKG AS

--  Global constant holding the package name

 G_PKG_NAME             CONSTANT VARCHAR2(30) := 'XX_OM_USETAXACCRUAL_PKG';
 error_code  	        NUMBER;
 error_buf		VARCHAR2(1000);
 l_interface_run_id	NUMBER(15);
 l_group_id		NUMBER(15);
 l_sob_id		NUMBER;
 l_company_code         VARCHAR2(30);

-- Function to get Company Code based on Ship to Location
-- Update made as per defect # 8013
  FUNCTION get_company ( p_line_id  IN NUMBER)
  RETURN VARCHAR2
  IS

  l_company_id VARCHAR2(30);

  BEGIN
         SELECT  attribute1
	 INTO 	l_company_id
	 FROM 	apps.fnd_flex_values_vl fvv
               ,apps.fnd_flex_value_sets fv
         WHERE  fv.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
         AND    fvv.flex_value_set_id = fv.flex_value_set_id
         AND 	fvv.flex_value = (SELECT substr(ship_to,1,6)
                     	          FROM APPS.oe_order_lines_v oev
                        	  WHERE line_id = p_line_id);

         RETURN l_company_id;

  EXCEPTION
  WHEN NO_DATA_FOUND  THEN

	 fnd_file.put_line(APPS.FND_FILE.LOG, 'Cant derive company code for ship to location :');
	 
	 RETURN NULL; -- Added for the defect#32153

  END get_company;
/*-----------------------------------------------------------------
PROCEDURE  : Request
DESCRIPTION: OD Custom for TWE: Internal sales order to gl interface for Use Tax Accruals.
-----------------------------------------------------------------*/

PROCEDURE Request ( ERRBUF              OUT NOCOPY VARCHAR2
                   ,RETCODE             OUT NOCOPY VARCHAR2
                   ,p_order_date_low    IN         VARCHAR2
                   ,p_order_date_high   IN         VARCHAR2
                   ,p_order_number_low  IN         NUMBER
                   ,p_order_number_high IN         NUMBER)
IS

/*
--  #DI001 David Isbell 09/27/2007 for tpr#1941
--  Although details show dollar amounts at the item level, when they are rolled into
--  the G/L entries, they become null.
--  It seems that whenever a null value is involved in any of the items (or at least the last item),
--  null is the result being sent to G/L.
--   SOLUTION: I will add the NVL function on the values going to G/L
*/

  l_msg_count               NUMBER;
  l_msg_data                VARCHAR2(2000) := NULL;
  l_order_date_low	    DATE := null;
  l_order_date_high	    DATE := null;
  a_segments	            APPS.fnd_flex_ext.SegmentArray;
  l_start_date		    DATE;
  l_entered_dr              NUMBER := 0;  --#DI001: initialized
  l_entered_cr	            NUMBER := 0;  --#DI001: initialized
  l_status                  VARCHAR2(5);
  l_currency_code           VARCHAR2(15);
  err_code   	 	    NUMBER(15);
  --  cr_account	    gl_ussgl_account_pairs.cr_account_segment_value%type;
  --  dr_account	    gl_ussgl_account_pairs.cr_account_segment_value%type;
  l_shipto_state            VARCHAR2(10);
  l_use_tax_code            VARCHAR2(15);
  l_flex_num                NUMBER;
  seg_num	            NUMBER(15) := 0;
  l_use_tax_ccid            NUMBER(15);
  l_charge_ccid             NUMBER(15);

  TYPE lcu_internal_order_lines is REF CURSOR   ;                   --Added for Defect 13284
  internal_order_lines_type  lcu_internal_order_lines;

/* Cursor to select data from internal sales order to call TWE.
   oe_order_lines.attribute15 is used to indicate order line already processed
   for tax accrual */

/*Cursor csr_internal_order_lines (p_date_low   date,
                                 p_date_high  date,
                                 p_order_num_low number,
                                 p_order_num_high number) IS*/      --Commented for Defect 13284 - Making it a REF Cursor instead.

lc_internal_select_qry VARCHAR2(32767) :=
    'SELECT /*+ USE_HASH(wdd) */hdr.TRANSACTIONAL_CURR_CODE' -- Added on 19-03-2010 for the Defect 4561
  --  /*+ LEADING(HDR) */hdr.TRANSACTIONAL_CURR_CODE'
	||',line.source_document_line_id as req_line_id'
        ||',dist.code_combination_id as charge_ccid'
	||',dist.set_of_books_id'
        ||',hdr.order_number'
        ||',hdr.ordered_date'
       	||',hdr.creation_date'
        ||',hdr.order_type_id'
        ||',hdr.header_id'
        ||',line.line_id'
        ||',line.tax_value'
        ||',(line.ordered_quantity * line.unit_selling_price) as line_amount'
	||',gsb.chart_of_accounts_id'                               --Added for Defect 13417
||' FROM apps.oe_order_headers_all hdr'                             -- Defect #5150 MV - 20-Mar-2008
        ||',apps.oe_order_lines_all line'                           -- Defect #5150 MV - 20-Mar-2008
    --      apps.oe_order_types_v ordtype,                          -- Defect #5150 MV - 20-Mar-2008
    --      ont.oe_transaction_types_all ordtype,                   -- Commented For Defect 13284 - 19-Feb-09
        ||',apps.oe_order_sources ordtype'                          -- Added for Defect 13284 - 19-Feb-09
        ||',apps.po_req_distributions_all dist'                     -- Defect #5150 MV - 20-Mar-2008
        ||',gl_sets_of_books gsb'                                   --Added for Defect 13417
/* Added on 02-03-2010 for the Defect 4561 -- Starts Here */
	||',wsh.wsh_delivery_details wdd'  ;
	--||',apps.wsh_lookups wl';            --  As per defect# 21112
/* Added on 02-03-2010 for the Defect 4561 -- Ends Here */


lc_internal_where_qry VARCHAR2(32767) :=

  ' WHERE line.header_id = hdr.header_id'
   --and   ordtype.name = 'OD US INTERNAL - ORDER'                  --Remove line Defect #5150 MV - 20-Mar-2008
||' AND ordtype.Name =''Internal'''                                 --Added for Defect 13284 - 19-Feb-09
||' AND line.attribute15 is NULL'
   --and   hdr.order_type_id = ordtype.transaction_type_id          -- Defect #5150 MV - 20-Mar-2008  --Commented For defect 13284
||' AND hdr.order_source_id = ordtype.order_source_id'              -- Added For Defect 13284 - 19-Feb-09
||' AND dist.requisition_line_id = line.source_document_line_id'
||' AND line.tax_value <> 0'
||' AND gsb.set_of_books_id=dist.set_of_books_id'                   --Added for Defect 13417
/* Added on 02-03-2010 for the Defect 4561 -- Starts Here */
--||' AND wdd.released_status = wl.lookup_code'    --  As per defect# 21112
--||' AND wl.lookup_type = ''PICK_STATUS'''         --  As per defect# 21112
||' AND wdd.source_line_id = line.line_id'
--||' AND wl.meaning = ''Shipped''';            --  As per defect# 21112
/* Added on 02-03-2010 for the Defect 4561 -- Ends Here */
||' AND wdd.delivery_detail_id= (SELECT MAX(WDD1.delivery_detail_id)'  --   Added  as per defect# 21112
                               ||' FROM WSH.wsh_delivery_details WDD1'
	                       ||',APPS.wsh_lookups WL'
			       ||' WHERE WDD1.released_status = WL.lookup_code'
                               ||' AND wl.lookup_type = ''PICK_STATUS'''
                               ||' AND wl.meaning = ''Shipped'''
                               ||'AND WDD1.source_line_id = line.line_id)';

TYPE c_intorder_rec_type IS RECORD(
                                   TRANSACTIONAL_CURR_CODE	oe_order_headers_all.TRANSACTIONAL_CURR_CODE%TYPE
                                  ,REQ_LINE_ID	                oe_order_lines_all.SOURCE_DOCUMENT_LINE_ID%TYPE
                                  ,CHARGE_CCID		        po_req_distributions_all.CODE_COMBINATION_ID%TYPE
                                  ,SET_OF_BOOKS_ID		po_req_distributions_all.SET_OF_BOOKS_ID%TYPE
                                  ,ORDER_NUMBER			oe_order_headers_all.ORDER_NUMBER%TYPE
                                  ,ORDERED_DATE			oe_order_headers_all.ORDERED_DATE%TYPE
                                  ,LAST_UPDATE_DATE		oe_order_headers_all.LAST_UPDATE_DATE%TYPE
                                  ,ORDER_TYPE_ID		oe_order_headers_all.ORDER_TYPE_ID%TYPE
				  ,HEADER_ID			oe_order_headers_all.HEADER_ID%TYPE
				  ,LINE_ID			oe_order_lines_all.LINE_ID%TYPE
				  ,TAX_VALUE			oe_order_lines_all.TAX_VALUE%TYPE
				  ,LINE_AMOUNT			NUMBER
				  ,CHART_OF_ACCOUNTS_ID		gl_sets_of_books.CHART_OF_ACCOUNTS_ID%TYPE
                                 );
lr_intorder_rec_type     c_intorder_rec_type;


--and   hdr.creation_date >=  nvl(p_date_low,hdr.creation_date)     --Removed Trunc Function - Defect 13284  Commented for Defect 13284
--and   hdr.creation_date <= nvl(p_date_high,hdr.creation_date)     --Removed Trunc Function - Defect 13284
--and   hdr.order_number >= nvl(p_order_num_low,hdr.order_number)
--and   hdr.order_number <= nvl(p_order_num_high,hdr.order_number)




/* Get charge account segments */
        CURSOR csr_charge_segments (p_ccid NUMBER)
	IS
        SELECT  glcc.segment1
	       ,glcc.segment2
	       ,glcc.segment3
               ,glcc.segment4
	       ,glcc.segment5
	       ,glcc.segment6
	       ,glcc.segment7
        FROM    APPS.gl_code_combinations glcc
        WHERE   glcc.code_combination_id = p_ccid;

/* Get shipto state */
        --cursor csr_shipto_state (p_order_num NUMBER) IS
        CURSOR csr_shipto_state (p_line_id NUMBER)
	IS
        SELECT NVL(ship_loc.state,ship_loc.province)  State         -- Defect #5150 MV - 20-Mar-2008
        FROM apps.OE_ORDER_HEADERS H
            ,apps.oe_order_lines  L
            ,HZ_CUST_SITE_USES_ALL SHIP_SU
            ,HZ_PARTY_SITES SHIP_PS
            ,HZ_LOCATIONS SHIP_LOC
            ,HZ_CUST_ACCT_SITES_ALL SHIP_CAS
        WHERE l.line_id = p_line_id
        --h.order_number = p_order_num
        AND H.HEADER_ID = L.HEADER_ID
        AND L.SHIP_TO_ORG_ID = SHIP_SU.SITE_USE_ID                  --(+)Commented outer join defect 13284
        AND SHIP_SU.CUST_ACCT_SITE_ID= SHIP_CAS.CUST_ACCT_SITE_ID   --(+) Commented outer join defect 13284
        AND SHIP_CAS.PARTY_SITE_ID = SHIP_PS.PARTY_SITE_ID          --(+) Commented outer join defect 13284
        AND SHIP_LOC.LOCATION_ID/*(+)*/ = SHIP_PS.LOCATION_ID;      -- Commented outer join defect 13284

/* Get use tax code combination */
        CURSOR csr_use_tax_segments (p_taxcode VARCHAR2
	                            ,p_sob_id  NUMBER)
        IS
               /*** modification for R12 - use new set of tables to retrieve the liability account ****/
SELECT     a.tax_account_ccid as use_tax_ccid
          ,glcc.segment1
	        ,glcc.segment2
	        ,glcc.segment3
	        ,glcc.segment4
	        ,glcc.segment5
			    ,glcc.segment6
			    ,glcc.segment7
from apps.gl_code_combinations  glcc
    ,apps.zx_rates_b     b
    ,apps.zx_accounts    a
    where b.tax_rate_id = a.TAX_ACCOUNT_ENTITY_ID
    and   glcc.code_combination_id = a.tax_account_ccid
    and   b.tax = p_taxcode;

/*** modification for R12 - use new set of tables to retrieve the liability account ****/
  /**** removed select statement by sinon      SELECT  distinct taxcodes.tax_code_combination_id as use_tax_ccid
	                ,glcc.segment1
	                ,glcc.segment2
	                ,glcc.segment3
	                ,glcc.segment4
	                ,glcc.segment5
			,glcc.segment6
			,glcc.segment7
        FROM APPS.gl_code_combinations glcc
	    ,apps.ap_tax_codes taxcodes
        WHERE glcc.code_combination_id = taxcodes.tax_code_combination_id
        AND taxcodes.tax_type = 'USE'
        --and taxcodes.set_of_books_id = p_sob_id
        AND trunc(nvl(taxcodes.start_date,sysdate)) <= trunc(sysdate)
        AND trunc(nvl(taxcodes.inactive_date,sysdate)) >= trunc(sysdate)
        AND taxcodes.name  = p_taxcode;  removed select statement by sinon ****/

/* Check if we already have a row for this ccid in GT.
   Acct_type_code is a local variable used to denote charge account vs
   tax liability account. 1=charge acct, 2=tax liab acct  */
        CURSOR csr_gt_row ( p_acct_type_code NUMBER
	                  , p_tax_code VARCHAR2
			  , p_ccid NUMBER)
        IS

	SELECT 'Y'
        FROM  apps.xx_om_twe_usetax_glb_tmp
        WHERE acct_type_code = p_acct_type_code
        AND   tax_code = p_tax_code
        AND   ccid = p_ccid
        AND   rownum = 1;

        CURSOR csr_gt
	IS
        SELECT decode(acct_type_code,1,'CHARGE ACCT',2,'TAXLIAB ACCT') AS acct_type
	      ,tax_code
	      ,currency_code
 	      ,ccid
	      ,entered_dr
	      ,entered_cr
              ,segment1
              ,segment2
              ,segment3
              ,segment4
              ,segment5
              ,segment6
              ,segment7
        FROM apps.xx_om_twe_usetax_glb_tmp;

l_row_exists VARCHAR2(1);

XX_OD_TAX_ACCT_EXCEPTION EXCEPTION; -- for the defect# 32153
l_err_msg  VARCHAR2(2000);  -- for the defect# 32153

BEGIN

  fnd_file.put_line(APPS.FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG.Request + '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));
  error_code := 0;
  error_buf  := NULL;

    IF (p_order_date_low IS NOT NULL) THEN
       l_order_date_low := TO_DATE(TO_CHAR(fnd_date.canonical_to_date(p_order_date_low),'DD-MON-YY')||' 00:00:00','DD-MON-YY HH24:MI:SS');
    END IF;

    IF (p_order_date_high IS NOT NULL) THEN
       l_order_date_high := TO_DATE(TO_CHAR(fnd_date.canonical_to_date(p_order_date_high),'DD-MON-YY')||' 23:59:59','DD-MON-YY HH24:MI:SS');
    END IF;

   fnd_file.put_line(APPS.FND_FILE.LOG, 'Program Parameters:');
   fnd_file.put_line(APPS.FND_FILE.LOG, '	order_number_low =  '||
                                        p_order_number_low);
   fnd_file.put_line(APPS.FND_FILE.LOG, '	order_number_high = '||
                                        p_order_number_high);
   fnd_file.put_line(APPS.FND_FILE.LOG, '	order_date_low = '||
                                        to_char(l_order_date_low,'DD-MON-YY HH24:MI:SS'));
   fnd_file.put_line(APPS.FND_FILE.LOG, '	order_date_high = '||
                                        to_char(l_order_date_high,'DD-MON-YY HH24:MI:SS'));


  -- Set of Books ID

  /*select set_of_books_id
  into l_sob_id
  from ar_system_parameters;
  */

  fnd_file.put_line(APPS.FND_FILE.LOG, 'Chart_of_accounts_id/flexnum =  '||to_number(l_flex_num));

  --     Obtain the group id

   SELECT gl_interface_control_s.nextval
   INTO l_group_id
   FROM SYS.DUAL;



   fnd_file.put_line(APPS.FND_FILE.LOG, 'GL INTERFACE GROUP ID =  '||to_number(l_group_id));

   /* Get list of internal orders */
   fnd_file.put_line(APPS.FND_FILE.LOG, '-----------------------------------------------');
   fnd_file.put_line(APPS.FND_FILE.LOG, '--------- Process ISO Cursor START: ------ '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));

   savepoint start_cursor;
   fnd_file.put_line(APPS.FND_FILE.LOG, 'Order#, HdrID, LineID, LineAmount, Tax, TaxCode ');


   --Added for defect 13284 - Start
   IF l_order_date_low IS NOT NULL THEN
--	lc_internal_where_qry:=lc_internal_where_qry||' AND hdr.last_update_date >= :l_order_date_low' ;
	lc_internal_where_qry:=lc_internal_where_qry||' AND line.last_update_date >= :l_order_date_low' ; --last_update_date is taken from OE_ORDER_LINES_ALL instead of OE_ORDER_HEADERS_ALL for rhe Defect 4561.
   ELSE
        lc_internal_where_qry:=lc_internal_where_qry||' AND :l_order_date_low IS NULL';
   END IF;

   IF l_order_date_high IS NOT NULL THEN
--	lc_internal_where_qry:=lc_internal_where_qry||' AND hdr.last_update_date <= :l_order_date_high';
	lc_internal_where_qry:=lc_internal_where_qry||' AND line.last_update_date <= :l_order_date_high'; --last_update_date is taken from OE_ORDER_LINES_ALL instead of OE_ORDER_HEADERS_ALL for rhe Defect 4561.
   ELSE
        lc_internal_where_qry:=lc_internal_where_qry||' AND :l_order_date_high IS NULL';

   END IF;

   IF p_order_number_low IS NOT NULL THEN
   	lc_internal_where_qry:=lc_internal_where_qry||' AND hdr.order_number >= :p_order_number_low';
   ELSE
        lc_internal_where_qry:=lc_internal_where_qry||' AND :p_order_number_low IS NULL';

   END IF;

   IF p_order_number_high IS NOT NULL THEN
	lc_internal_where_qry:=lc_internal_where_qry||' AND hdr.order_number <= :p_order_number_high';
   ELSE
        lc_internal_where_qry:=lc_internal_where_qry||' AND :p_order_number_high IS NULL';

   END IF;  --Defect fix -13284 -End

   lc_internal_where_qry:=lc_internal_where_qry ||' ORDER BY hdr.header_id , line.line_id' ;


   /*for isorec in csr_internal_order_lines (
                                    l_order_date_low,
                                    l_order_date_high,
                                    p_order_number_low,
                                    p_order_number_high)*/

   OPEN internal_order_lines_type FOR lc_internal_select_qry||lc_internal_where_qry	--Opening REF Cursor.Added for Defect 13284
   USING l_order_date_low, l_order_date_high, p_order_number_low, p_order_number_high;


    LOOP

      FETCH internal_order_lines_type INTO lr_intorder_rec_type;  --Added for Defect 13284
      EXIT WHEN internal_order_lines_type%NOTFOUND;

           l_currency_code := lr_intorder_rec_type.transactional_curr_code;
           l_charge_ccid   := lr_intorder_rec_type.charge_ccid;

	   l_sob_id       := lr_intorder_rec_type.set_of_books_id;
           l_flex_num     := lr_intorder_rec_type.chart_of_accounts_id;

            /*SELECT chart_of_accounts_id       Commented as chart of accounts ID
            INTO l_flex_num                     has been added in the main cursor itself(csr_internal_order_lines)
             FROM APPS.gl_sets_of_books
            WHERE set_of_books_id = l_sob_id; */


       /* Get Ship-to State from order */
       --for strec in csr_shipto_state (isorec.order_number)
       FOR strec in csr_shipto_state (lr_intorder_rec_type.line_id)
       loop
          l_shipto_state := strec.state;
           /**** modified for R12 by sinon - line below replaced with the next line instead of "USE_xx" it is now "USExx" ***/
          /**** removed by sinon l_use_tax_code  := 'USE_'||rtrim(l_shipto_state); *****/
          l_use_tax_code  := 'USE'||rtrim(l_shipto_state);
         /**** modified for R12 by sinon - line above replaced with the next line instead of "USE_xx" it is now "USExx" ***/
       END loop;

      fnd_file.put_line(APPS.FND_FILE.LOG,
            to_char(lr_intorder_rec_type.order_number)||', '||
            to_char(lr_intorder_rec_type.header_id)||', '||
            to_char(lr_intorder_rec_type.line_id)||', '||
            to_char(lr_intorder_rec_type.line_amount)||', '||
            to_char(lr_intorder_rec_type.tax_value)||', '||
            l_use_tax_code);

      /* mark the order line as processed, so we don't process this row again. Stamp with gl interface group ID */
      UPDATE oe_order_lines
      SET attribute15 = l_group_id
      WHERE line_id = lr_intorder_rec_type.line_id;

	   SAVEPOINT xx_savepoint1; -- addded for the defect#32153
	   
       FOR I IN 1..2 LOOP

	    BEGIN
		
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
             END loop;

             l_entered_dr := NVL(lr_intorder_rec_type.tax_value,0); -- #DI001: added NVL
             l_entered_cr := null;    ---0; move null instead of zero. added by sinon

             l_row_exists := 'N';
             for gtrec in csr_gt_row ( 1, l_use_tax_code, l_charge_ccid )
             loop
                l_row_exists := 'Y';
             END loop;
								
				
             IF (l_row_exists = 'Y') THEN

                  UPDATE apps.xx_om_twe_usetax_glb_tmp
                  SET entered_dr = entered_dr + l_entered_dr,
                      entered_cr = null --0  move null instead of zero. added by sinon
                  WHERE acct_type_code = 1
                  AND   tax_code = l_use_tax_code
                  AND   ccid = l_charge_ccid;
             ELSE
                  /* GT rows doesn't exist for this tax code,ccid row. Add a row */
                  INSERT INTO apps.xx_om_twe_usetax_glb_tmp
                      ( acct_type_code,
                        tax_code 	,
                        currency_code,
                        created_by,
                        creation_date,
                        ccid ,
                        segment1, segment2, segment3, segment4,
                        segment5, segment6, segment7,
                        entered_dr, entered_cr,set_of_books_id  )
                    VALUES
                        (1,
                        l_use_tax_code,
                        l_currency_code,
                        3,
                        sysdate,
                        l_charge_ccid,
                        a_segments(1), a_segments(2), a_segments(3), a_segments(4),
                        a_segments(5), a_segments(6), a_segments(7),
                        l_entered_dr, l_entered_cr , l_sob_id
                        );
             END IF; /* if (l_row_exists */

          ELSE /* IF I = 2 THEN */

             /* State Tax Liability Account */
                 a_segments(1) := null;
                 a_segments(2) := null;
                 a_segments(3) := null;
                 a_segments(4) := null;
                 a_segments(5) := null;
                 a_segments(6) := null;
                 a_segments(7) := null;
             FOR tcrec in csr_use_tax_segments (l_use_tax_code, l_sob_id)
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
             END loop;

         -- Added Code to derive Code Combination id based on Ship to Location
         -- as per defect # 8013
                  l_company_code:=null; -- Added for the defect#32153
		BEGIN

		l_company_code := get_company(lr_intorder_rec_type.line_id);
                --fnd_file.put_line(APPS.FND_FILE.LOG, l_company_code);
		--fnd_file.put_line(APPS.FND_FILE.LOG, a_segments(2)||' '||a_segments(3)||' '||a_segments(4)||' '||a_segments(5)||' '||a_segments(6)||' '||a_segments(7));

	IF l_company_code IS NOT NULL THEN   -- Added for the defect#32153		
	         l_use_tax_ccid:=null;  -- Added for the defect#32153
		SELECT  code_combination_id
		INTO l_use_tax_ccid
		FROM	apps.gl_code_combinations
		WHERE       segment1 = l_company_code
                AND   segment2 =  a_segments(2)
               	AND   segment3 =  a_segments(3)
               	AND   segment4 =  a_segments(4)
               	AND   segment5 =  a_segments(5)
               	AND   segment6 =  a_segments(6)
               	AND   segment7 =  a_segments(7)
                AND   enabled_flag='Y';

                a_segments(1) := l_company_code;
	ELSE   -- Added for the defect#32153
	
	 l_err_msg := 'Cannot derive valid Code combination id for the State Tax Liability Account as the company code does not exists for the ship-to location in the ISO line id# '||lr_intorder_rec_type.line_id; 
	 
	 ROLLBACK TO xx_savepoint1;
	 
	 RAISE XX_OD_TAX_ACCT_EXCEPTION;
	END IF;
				
	EXCEPTION  -- added for the defect#32153
	        WHEN NO_DATA_FOUND THEN
		   l_err_msg := 'Cannot derive valid Code combination id for segments : '||l_company_code||', '||a_segments(2)||', '||a_segments(3)||', '||a_segments(4)||', '||a_segments(5)||', '||a_segments(6)||', '||a_segments(7);

		  ROLLBACK TO xx_savepoint1;
		  
		RAISE XX_OD_TAX_ACCT_EXCEPTION;
	END;


        -- Modification Ends for Defect # 8013


             l_entered_cr := NVL(lr_intorder_rec_type.tax_value,0); --#DI001: added NVL
             l_entered_dr := null; --0; move null instead of zero. added by sinon

             l_row_exists := 'N';
             for gtrec in csr_gt_row ( 2, l_use_tax_code, l_use_tax_ccid )
             loop
                l_row_exists := 'Y';
             end loop;

             IF (l_row_exists = 'Y') THEN

                  UPDATE apps.xx_om_twe_usetax_glb_tmp
                  SET entered_cr = entered_cr + l_entered_cr,
                      entered_dr = null   --0 move null instead of zero. added by sinon
                  WHERE acct_type_code = 2
                  AND   tax_code       = l_use_tax_code
                  AND   ccid           = l_use_tax_ccid;
             ELSE
                  /* GT rows doesn't exist for this tax code,ccid row. Add a row */
                  INSERT INTO apps.xx_om_twe_usetax_glb_tmp
                             ( acct_type_code
                               ,tax_code
			       ,currency_code
                               ,created_by
                               ,creation_date
                               ,ccid
                               ,segment1
			       , segment2
			       , segment3
			       , segment4
			       ,segment5
			       , segment6
			       , segment7
   			       , entered_dr
			       , entered_cr
   			       , set_of_books_id)--Added for Defect 13417
                  VALUES
                               (2
			       ,l_use_tax_code
			       ,l_currency_code
			       ,3
			       ,sysdate
			       ,l_use_tax_ccid
			       ,a_segments(1)
			       ,a_segments(2)
			       ,a_segments(3)
			       ,a_segments(4)
			       ,a_segments(5)
			       ,a_segments(6)
			       ,a_segments(7)
			       ,l_entered_dr
			       ,l_entered_cr
			       ,l_sob_id
                               );
               END IF; /* if (l_row_exists */

          END IF;
		EXCEPTION
		WHEN XX_OD_TAX_ACCT_EXCEPTION THEN  -- Added for the defect#32153
		
		 /* mark the order line as unprocessed (attribute15 = null), so that this line will be picked up in the next run. */
			UPDATE oe_order_lines
			SET attribute15 = null
			WHERE line_id = lr_intorder_rec_type.line_id;
			
			fnd_file.put_line(APPS.FND_FILE.LOG, l_err_msg);
			
			fnd_file.put_line(APPS.FND_FILE.LOG, 'Skipping this line...');
		END;
		
      END LOOP;  /* I - Debit/Credit*/
                          -- Added for the defect#32153
           l_currency_code := null;
           l_charge_ccid   := null;
	       l_sob_id        := null;
           l_flex_num      := null;

   END loop; --REF Cursor Loop  /* for isorec in csr_internal_order_lines */

  /* Print GT for debug */
  fnd_file.put_line(APPS.FND_FILE.LOG, ' ');
  fnd_file.put_line(APPS.FND_FILE.LOG, '--------- Process ISO Cursor END: ------ '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));

  fnd_file.put_line(APPS.FND_FILE.LOG, ' ');
  fnd_file.put_line(APPS.FND_FILE.LOG, '----- Printing gl_interface data from global temporary table -----');

   for drec in csr_gt
   loop
      fnd_file.put_line(APPS.FND_FILE.LOG,
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
   END loop;

  /* Populate GL_INTERFACE table from global temporary table */
  fnd_file.put_line(APPS.FND_FILE.LOG, ' ');
  fnd_file.put_line(APPS.FND_FILE.LOG, '------ Populate xxfin.xx_gl_interface_na_stg from global temporary table ------');
        --INSERT INTO gl_interface(  -- Anamitra Banerjee: changed table name
            INSERT INTO xxfin.xx_gl_interface_na_stg(
	    status,
            date_created,
            created_by,
            actual_flag,
            group_id,
            reference1,
            reference2,
            reference4,
            reference5,
            reference6,
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
            reference10
	    )
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
             l_group_id,
             'Taxware',
             'OD Use Tax',
	     --l_sob_id        Commented for defect 13417
            gt.set_of_books_id,--Added for defect 13417
            sysdate,
            gt.currency_code,
            gt.segment1, gt.segment2, gt.segment3, gt.segment4,
            gt.segment5, gt.segment6, gt.segment7,
            gt.entered_dr,
            gt.entered_cr,
            'Internal Sales Order'

        FROM apps.xx_om_twe_usetax_glb_tmp gt;

        fnd_file.put_line(APPS.FND_FILE.LOG, 'GL_INTERFACE: Rows inserted = '||to_char(sql%rowcount));

        commit;

      fnd_file.put_line(APPS.FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG.Request - '||
                      to_char(sysdate,'DD-MON-RRRR:HH:MI:SS'));


EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
         fnd_file.put_line(APPS.FND_FILE.LOG,
            'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_ERROR');
        fnd_file.put_line(APPS.FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
         ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_ERROR';
         RETCODE := 2;
         rollback to start_cursor;

   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        fnd_file.put_line(APPS.FND_FILE.LOG,
            'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_UNEXPECTED_ERROR');
        fnd_file.put_line(APPS.FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
        ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Exception:G_EXC_UNEXPECTED_ERROR';
        RETCODE := 2;
        rollback to start_cursor;

   WHEN OTHERS THEN
	 fnd_file.put_line(APPS.FND_FILE.LOG, 'XX_OM_USETAXACCRUAL_PKG errored out.');
          fnd_file.put_line(APPS.FND_FILE.LOG, 'SQLERRM: '||sqlerrm);
          ERRBUF := 'XX_OM_USETAXACCRUAL_PKG errored out: Check log for details.';
          RETCODE := 2;
          rollback ; -- to start_cursor;-- Anamitra Banerjee: removed reference to savepoint
END Request;

END XX_OM_USETAXACCRUAL_PKG;

/
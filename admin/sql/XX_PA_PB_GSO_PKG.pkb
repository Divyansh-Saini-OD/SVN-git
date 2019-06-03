SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY XX_PA_PB_GSO_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_PA_PB_GSO_PKG.pkb         	                                |
-- | Description :  INV ASL 							        |
-- |                                                                                    |
-- | Change History  :                                                                  |
-- | Version           Date             Changed By              Description             |
--+=====================================================================================+
--| 1.0              21-Jun-2010       Paddy Sanjeevi          Original                 |
--| 1.1		     15-Feb-2011       Paddy Sanjeevi          Modified to get MO from  |
--|                                                            vendor Master            |
--+=====================================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------
G_USER_ID                   CONSTANT fnd_user.user_id%TYPE                 :=   FND_GLOBAL.user_id;
G_DATE                      CONSTANT fnd_user.creation_date%TYPE           :=   SYSDATE;
gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
l_errmsg		    varchar2(5000);


-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;


PROCEDURE send_exception_rpt(p_batch_id IN NUMBER)
IS

  v_addlayout 		boolean;
  v_wait 		BOOLEAN;
  v_request_id 		NUMBER;
  vc_request_id 	NUMBER;
  v_file_name 		varchar2(50);
  v_dfile_name		varchar2(50);
  v_sfile_name 		varchar2(50);
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;

  conn 			utl_smtp.connection;
  lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_SC_SEND_MAIL');
  v_recipient		varchar2(100);

BEGIN

  BEGIN
    SELECT a.description
      INTO v_recipient
      FROM apps.fnd_flex_values_vl a,
           apps.fnd_flex_value_sets b
     WHERE b.flex_value_set_name='XX_GSO_NOTIFICATION_LIST'
       AND b.flex_value_set_id=a.flex_value_set_id
       AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate) 
       AND a.flex_value='PO';
  EXCEPTION
    WHEN others THEN
      v_recipient:='IT_MerchEBS_Oncall@officedepot.com';
  END;

   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXMER',
	 	                template_code => 'XXPAGSPE', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXPAGSPE','OD GSO PO Import Exceptions Report',NULL,FALSE,
		TO_CHAR(p_batch_id),NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='XXPAGSPE_'||to_char(v_request_id)||'_1.EXCEL';
     v_dfile_name:='$XXMER_DATA/outbound/'||to_char(v_request_id)||'.xls';
     v_sfile_name:=to_char(v_request_id)||'.xls';

  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN

        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;


        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;

 	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN
	
	   IF v_cdphase = 'COMPLETE' THEN  -- child 
	 
 
  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'Oracle-EBS@officedepot.com',
	  	        recipients => v_recipient,
			cc_recipients=>v_recipient,
		        subject => 'PO Exception Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);


             xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text(conn => conn,
  		                      data => 'GSO PO Import Exceptions',
		                      mime_type => 'multipart/html');

             xx_pa_pb_mail.end_mail( conn => conn );


	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child

 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,



     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main

END send_exception_rpt;

PROCEDURE insert_sku_master(p_batch_id IN NUMBER)
IS

CURSOR lcu_sku IS
SELECT distinct vendor_no,
       vendor_name,
       sku,
       description
  FROM xx_gso_po_stg a
 WHERE load_batch_id=p_batch_id
   AND sku_process_Flag=3
   AND NOT EXISTS (SELECT 'x'
		     FROM apps.Q_OD_GSO_VEND_SKU_FOB_V
		    WHERE od_pb_vendor_id=a.vendor_no
		      AND od_pb_sku=a.sku);

  v_request_id 		NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
BEGIN

  FOR cur IN lcu_sku LOOP
    i:=i+1;
    BEGIN
      INSERT INTO apps.Q_OD_GSO_VEND_SKU_FOB_IV
        (      process_status, 
               organization_code ,
               plan_name,
               insert_type,
	       matching_elements,
	       OD_PB_VENDOR_ID            ,              
	       OD_PB_VENDOR_NAME,             
	       OD_PB_SKU                  ,            
	       OD_PB_SKU_DESCRIPTION,
	       qa_created_by_name,
               qa_last_updated_by_name
        )
      VALUES
	(
 	      '1',
               'PRJ',
               'OD_GSO_VEND_SKU_FOB',
               '1', --1 for INSERT
               'OD_PB_VENDOR_ID,OD_PB_SKU',
		cur.vendor_no,
		cur.vendor_name,
		cur.sku,
		cur.description,
		'510093',
     	        '510093'
	);
    EXCEPTION
      WHEN others THEN
	NULL;
    END;
  END LOOP;
  COMMIT;
  IF i>1 THEN
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'Yes');
      IF v_request_id>0 THEN
         COMMIT;
      END IF;
  END IF;
END insert_sku_master;


-- +===================================================================+
-- | Name        :  validate_po_data                                   |
-- | Description :  This procedure is invoked from the OD GSO PO Import|
-- |                Process Concurrent Request.                        |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_po_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                          )
IS

------------------------------------------
--Declaring Exceptions and local variables
------------------------------------------

  ln_herror_message	varchar2(5000);
  ln_lerror_message	varchar2(5000);
  l_sqlerrm		varchar2(2000);
  l_pohdr_id 		NUMBER;
  l_podtl_id 		NUMBER;



  l_vend_name	varchar2(100);
  l_agent	varchar2(40);
  l_mo		varchar2(40);
  l_lmo		varchar2(40);
  l_gsomo	varchar2(40);
  l_currency	varchar2(10);
  l_mst_fob	number;
  l_nb_flag	varchar2(1);
  l_inline_flag varchar2(1);
  l_sstk_flag	varchar2(1);
  l_bv_flag     varchar2(1);
  l_eol_flag	varchar2(1);
  l_herr_flag	varchar2(1):='N';
  l_lerr_flag	varchar2(1):='N';

  l_diff_price	VARCHAR2(1):='N';
  l_category	varchar2(60);
  l_gso_dept_id	varchar2(30);

  CURSOR lcu_PO(p_batch_id NUMBER) IS
  SELECT DISTINCT 
	 VENDOR_NO,
	 VENDOR_NAME,
	 PO_NUMBER
    FROM xx_gso_po_stg
   WHERE load_batch_id=p_batch_id
     AND vendor_process_Flag=4
     AND dept_process_flag=4
     AND process_Flag=1;


  CURSOR lcu_pol(p_ponum VARCHAR2,p_batch_id NUMBER) IS
  SELECT a.rowid lrowid,a.*
    FROM xx_gso_po_stg a
   WHERE po_number=p_ponum
     AND process_flag=1
     AND vendor_process_Flag=4
     AND dept_process_flag=4
     AND load_batch_id=p_batch_id;

BEGIN

  UPDATE xx_gso_po_stg stg
     SET process_flag=7,vendor_process_Flag=7,sku_process_Flag=7,dept_process_Flag=7,error_message='Duplicate Data'
   WHERE load_batch_id=p_batch_id
     AND edi_status like 'Orig%'
     AND EXISTS (SELECT 'x'
		   FROM  xx_gso_po_dtl b,
			 xx_gso_po_hdr a
		  WHERE  a.po_number=stg.po_number
		    AND  a.edi_status=stg.edi_status
		    AND  b.po_header_id=a.po_header_id
		    AND  b.po_line_no=stg.po_line_no);
    COMMIT;


  UPDATE xx_gso_po_stg a
     SET vendor_process_flag=4
   WHERE load_batch_id=p_batch_id
     AND process_Flag=1
     AND vendor_process_flag<>7
     AND EXISTS (SELECT 'x'
		       FROM apps.q_OD_GSO_VENDOR_MASTER_v
		      WHERE od_sc_vendor_number=a.vendor_no);
  COMMIT;

  UPDATE xx_gso_po_stg
     SET vendor_process_Flag=3,process_Flag=6,
	 error_message=error_message||'Missing Vendor Setup'
   WHERE load_batch_id=p_batch_id
     AND process_Flag=1
     AND vendor_process_flag NOT IN (4,7);
  COMMIT;
 
  
  UPDATE xx_gso_po_stg a
     SET dept_process_flag=4
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND dept_process_flag<>7
     AND edi_status NOT LIKE 'V%'
     AND EXISTS (SELECT 'x'
		       FROM apps.q_OD_GSO_DEPT_CATEGORY_v
		      WHERE OD_PB_SC_DEPT_NUM=a.dept);
  COMMIT;

  UPDATE xx_gso_po_stg a
     SET dept_process_flag=3,process_Flag=6,
	 error_message=error_message||' Missing Dept setup'
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND edi_status NOT LIKE 'V%'
     AND dept_process_flag NOT IN (4,7);
  COMMIT;


  UPDATE xx_gso_po_stg a
     SET sku_process_flag=4
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND sku_process_flag<>7
     AND vendor_process_Flag IN (4,7)
     AND dept_process_Flag IN (4,7)
     AND EXISTS (SELECT 'x'
		       FROM apps.q_OD_GSO_VEND_SKU_FOB_v
		      WHERE OD_PB_VENDOR_ID=a.vendor_no
			AND OD_PB_SKU=a.sku);
  COMMIT;


  UPDATE xx_gso_po_stg a
     SET sku_process_flag=3
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND sku_process_flag NOT IN (4,7);
  COMMIT;

  UPDATE xx_gso_po_stg stg
     SET sku_process_Flag=4,dept_process_Flag=4
   WHERE load_batch_id=p_batch_id
     AND edi_status like 'Void%';
    COMMIT;

  FOR cur IN lcu_po(p_batch_id) LOOP

    l_vend_name		:=NULL;
    l_agent		:=NULL;
    l_currency		:=NULL;
    l_gso_dept_id	:=NULL;
    l_mo		:=NULL;

    ln_herror_message 	:=NULL;

    BEGIN
      SELECT OD_SC_VENDOR_NAME,
	     OD_SC_AUDIT_AGENT,
	     OD_SC_CURRENCY,
	     OD_PB_ABM_NAME,
	     OD_GSO_DEPT_ID
        INTO l_vend_name,
	     l_agent,
	     l_currency,
	     l_mo,
	     l_gso_dept_id
	FROM apps.q_OD_GSO_VENDOR_MASTER_v
       WHERE OD_SC_VENDOR_NUMBER=cur.vendor_no;
    EXCEPTION
      WHEN others THEN
	l_errmsg:=substr(sqlerrm,1,100);
	ln_herror_message:=l_errmsg||' Error in Getting Agent';
    END;

    FOR cr IN lcu_pol(cur.po_number,p_batch_id) LOOP

	l_lmo		:=NULL;			
	l_mst_fob	:=NULL;			
	l_nb_flag	:='N';			
	l_inline_flag   :='N';			
	l_sstk_flag	:='N';			
	l_bv_flag       :='N';			
  	l_eol_flag	:='N';
        l_diff_price	:='N';
	l_errmsg	:=NULL;
	ln_lerror_message:=NULL;

	IF l_gso_dept_id IS NOT NULL THEN

  	  BEGIN
	    SELECT OD_PB_CATEGORY,
	 	   OD_PB_ABM_NAME
	      INTO l_category,l_lmo
	      FROM apps.q_OD_GSO_DEPT_CATEGORY_v
	     WHERE OD_PB_SC_DEPT_NUM=l_gso_dept_id;
          EXCEPTION
	    WHEN others THEN
	      l_errmsg:=substr(sqlerrm,1,100);
	      ln_lerror_message:=l_errmsg||' Error in MO from dept master';
  	  END;

	ELSE

  	  BEGIN
	    SELECT OD_PB_CATEGORY,
	 	   OD_PB_ABM_NAME
	      INTO l_category,l_lmo
	      FROM apps.q_OD_GSO_DEPT_CATEGORY_v
	     WHERE OD_PB_SC_DEPT_NUM=cr.dept;
          EXCEPTION
	    WHEN others THEN
	      l_errmsg:=substr(sqlerrm,1,100);
	      ln_lerror_message:=l_errmsg||' Error in MO from dept master';
  	  END;

	END IF;

	IF l_agent='ODC' AND cr.country_cd='USA' THEN
	   l_gsomo:=l_lmo;
        ELSE
	   l_gsomo:=l_mo;
	END IF;

	BEGIN
	  SELECT OD_SC_FOB_VALUE,
		 OD_SC_NB,
		 OD_SC_INLINE,
		 OD_SC_SAFETY_STOCK,
		 OD_SC_BV,
		 OD_PB_EOFL
	    INTO l_mst_fob,
		 l_nb_flag,
		 l_inline_flag,
		 l_sstk_flag,
		 l_bv_flag,
	         l_eol_flag
	    FROM apps.q_OD_GSO_VEND_SKU_FOB_v
	   WHERE OD_PB_VENDOR_ID=cur.vendor_no
	     AND OD_PB_SKU=cr.sku;
	EXCEPTION
	  WHEN others THEN
	    l_errmsg:=substr(sqlerrm,1,100);
	    ln_lerror_message:=ln_lerror_message||' '||l_errmsg||' Error in getting master fob';
	END;

	IF cr.fob_origin_cost<>l_mst_fob THEN
	   l_diff_price	:='Y';
	END IF;

        UPDATE xx_gso_po_stg
	   SET  master_fob=l_mst_fob,
	        eol_flag=l_eol_flag,
	        agent=l_agent,
	        mo=l_mo,	
	        gso_mo=l_gsomo,
	        currency=l_currency,
	        category=l_category,
		nb_flag=l_nb_flag,
		inline_flag=l_inline_flag,
		sstk_flag=l_sstk_flag,
		bv_flag=l_bv_flag,
		diff_price=l_diff_price,
		gso_dept_id=DECODE(cr.dept,7,TO_NUMBER(l_gso_dept_id),cr.dept),
		error_message=ln_lerror_message	       
         WHERE rowid=cr.lrowid;
    END LOOP;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in validate_item_data - '||substr(gc_sqlerrm,1,100);
    x_retcode := 2;
END validate_po_data;

-- +===================================================================+
-- | Name        :  process_po_data                                    |
-- | Description :  This procedure is invoked import_po procedue       | 
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_po_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                          )
IS

------------------------------------------
--Declaring Exceptions and local variables
------------------------------------------

  l_sqlerrm		varchar2(5000);
  l_pohdr_id 		NUMBER;
  l_podtl_id 		NUMBER;
  ln_herror_message	varchar2(5000);
  ln_lerror_message	varchar2(5000);
  l_herr_flag		varchar2(1):='N';
  l_lerr_flag		varchar2(1):='N';

  L_OPOHDR_ID		NUMBER;
  L_OPOLINE_ID		NUMBER;

  l_version		number;
  l_sent_to_vendor	date;
  l_conf_by_vendor	date;
  l_hremarks		varchar2(2000);
  l_hlatecode		varchar2(60);
  l_hlate_reason	varchar2(2000);
  l_potype		varchar2(30);
  l_need_bv		varchar2(1);
  l_insp_party		varchar2(100);
  l_merchant		varchar2(100);

  l_ispartial		varchar2(1);
  l_shipped_qty		NUMBER;
  l_nb			varchar2(1);
  l_inline		varchar2(1);
  l_safety_stock	varchar2(1);
  l_bv			varchar2(1);
  l_new_item		varchar2(1);
  l_first_shipment	varchar2(1);
  l_bv_status		varchar2(30);
  l_bv_code		varchar2(100);
  l_bv_reason		varchar2(2000);
  l_lremarks		varchar2(2000);
  l_tqty		NUMBER;
  l_tamt		NUMBER;
  

  CURSOR lcu_PO(p_batch_id NUMBER,p_action VARCHAR2) IS
  SELECT DISTINCT 
	 VENDOR_NO,
	 VENDOR_NAME,
	 PO_NUMBER,
	 PO_DATE,
	 po_status_cd,
	 ORIGIN_COUNTRY,
	 batch_id,
	 company_source_cd,
	 COUNTRY_CD,
	 port_name,
	 location_name,
	 edi_status,
	 PO_RECD_TO_JDA,
	 po_rel_to_vend,
	 po_conf_by_vend,
	 ship_date,
	 agent,
	 mo,
	 currency
    FROM xx_gso_po_stg a
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND vendor_process_Flag=4
     AND dept_process_flag=4
     AND action_type=p_action
     AND NOT EXISTS (SELECT 'x'
		       FROM xx_gso_po_hdr
		      WHERE po_number=a.po_number)
   ORDER BY po_number;

  CURSOR lcu_MPO(p_batch_id NUMBER) IS
  SELECT DISTINCT 
	 VENDOR_NO,
	 VENDOR_NAME,
	 PO_NUMBER,
	 PO_DATE,
	 po_status_cd,
	 ORIGIN_COUNTRY,
	 batch_id,
	 company_source_cd,
	 COUNTRY_CD,
	 port_name,
	 location_name,
	 edi_status,
	 PO_RECD_TO_JDA,
	 po_rel_to_vend,
	 po_conf_by_vend,
	 ship_date,
	 agent,
	 mo,
	 currency
    FROM xx_gso_po_stg a
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND vendor_process_Flag=4
     AND dept_process_flag=4
     AND action_type='A'
     AND EXISTS (SELECT 'x'
		       FROM xx_gso_po_hdr
		      WHERE po_number=a.po_number)
   ORDER BY po_number;

  CURSOR lcu_POC(p_batch_id NUMBER,p_action VARCHAR2) IS
  SELECT DISTINCT 
	 VENDOR_NO,
	 VENDOR_NAME,
	 PO_NUMBER,
	 PO_DATE,
	 po_status_cd,
	 ORIGIN_COUNTRY,
	 batch_id,
	 company_source_cd,
	 COUNTRY_CD,
	 port_name,
	 location_name,
	 edi_status,
	 PO_RECD_TO_JDA,
	 po_rel_to_vend,
	 po_conf_by_vend,
	 ship_date,
	 agent,
	 mo,
	 currency
    FROM xx_gso_po_stg a
   WHERE load_batch_id=p_batch_id
     AND process_flag=1
     AND vendor_process_Flag=4
     AND dept_process_flag=4
     AND action_type=p_action
   ORDER BY po_number;


  CURSOR lcu_pol(p_ponum VARCHAR2,p_batch_id NUMBER,p_action VARCHAR2) IS
  SELECT a.rowid lrowid,a.*
    FROM xx_gso_po_stg a
   WHERE po_number=p_ponum
     AND process_flag=1
     AND action_type=p_action
     AND load_batch_id=p_batch_id
   order by po_line_no;

BEGIN

  FOR cur IN lcu_mpo(p_batch_id) LOOP

      SELECT po_header_id 
        INTO l_pohdr_id
        FROM xx_gso_po_hdr
       WHERE po_number=cur.po_number
         AND is_latest='Y';

    FOR cr IN lcu_pol(cur.po_number,p_batch_id,'A') LOOP

        SELECT xx_gso_po_dtl_S.nextval INTO l_podtl_id FROM DUAL;

	l_merchant :=NULL;

	BEGIN
	  SELECT OD_PB_SOURCING_MERCHANT
	    INTO l_merchant
	    FROM apps.q_OD_GSO_DEPT_CATEGORY_v
	   WHERE OD_PB_SC_DEPT_NUM=cr.gso_dept_id;
        EXCEPTION
	  WHEN others THEN
	     l_merchant:=NULL;
  	END;

	BEGIN
	  INSERT INTO xx_gso_po_dtl
	    (   po_header_id,
		po_line_id,
		po_line_no,
		item,
		description,
		ordered_qty,
		uom,	
		vpc,
		dept,
		class,
  	        STD_PACK                     ,  
	        CARTON_PACK                  ,  
                CARTON_CUBE                  ,  
                CARTON_WEIGHT                ,  
                MASTER_CARTON                ,  
                RETAIL_COST                  ,  
                FOB_ORIGIN_COST              ,  
		master_fob_cost		     ,
                EST_LAND_COST                ,  
                ACT_LAND_COST                ,  
                MERCH_DEC_COST               ,   		
   		SHIPMENT_DATE		     ,
		SOURCE_PORT_NAME       ,
		DESTN_PORT_NAME,
		category,
		od_merchant,
		gso_mo,
		partial_line_flag,
		latest_line_flag,
		new_item_flag,
		over_shipped_flag,
		gso_dept_id,
		origin,
		nb_flag,
		inline_flag,
		safety_stock_flag,
		bv_flag,
		first_shipment_flag,
		diff_price,
		creation_date,
		last_update_date,
		created_by,
		last_updated_by,
		total_carton_cube,
		total_retail_cost,
		total_estland_cost,		
		total_actland_cost,
		total_merchdec_cost,
		line_total,
		line_status)
	  VALUES
	    (   l_pohdr_id,
		l_podtl_id,
		cr.po_line_no,
		ltrim(rtrim(cr.sku)),
		cr.description,
		cr.ordered_qty,
		cr.uom,
		cr.vpc,
		cr.dept,
		cr.class,
		cr.std_pack,
		cr.carton_pack,
		cr.carton_cube,
		cr.carton_weight,
		cr.master_carton,
		cr.retail_price,
		cr.fob_origin_cost,
		cr.master_fob,
		cr.est_landed_cost,
		cr.act_landed_cost,
		cr.merch_dec_cost,
		cr.ship_date,
		ltrim(rtrim(cr.port_name)),
		ltrim(rtrim(cr.location_name)),
		cr.category,
		ltrim(rtrim(l_merchant)),
		ltrim(rtrim(cr.gso_mo)),
		'N',	-- partial line flag
		'Y',	-- latest_line_flag
		'N',	-- new_item
		'N',	-- over_shipped
		cr.gso_dept_id,
		ltrim(rtrim(cur.origin_country)),
	        cr.nb_flag,
		cr.inline_flag,
		cr.sstk_flag,
		cr.bv_flag,
		'N',		-- first_shipment
		cr.diff_price,
		sysdate,
		sysdate,
		33963,
		33963,
		cr.master_carton*cr.carton_cube,
		cr.ordered_qty*cr.retail_price,
		cr.ordered_qty*cr.est_landed_cost,
		cr.ordered_qty*cr.act_landed_cost,
		cr.ordered_qty*cr.merch_dec_cost,
		cr.ordered_qty*cr.fob_origin_cost,
		'OPEN');

	  UPDATE xx_gso_po_stg
	     SET process_Flag=7,
		 vendor_process_flag=7,dept_process_flag=7
 	   WHERE rowid=cr.lrowid;

	EXCEPTION
	  WHEN others THEN
	    l_errmsg:=sqlerrm;
            UPDATE xx_gso_po_stg
	       SET error_message=error_message||' '||l_errmsg,
		   error_flag='Y',
		   process_flag=6,
		   sku_process_flag=6
	     WHERE rowid=cr.lrowid;
	END;
    END LOOP;

    SELECT SUM(ordered_qty),
	   SUM(ordered_qty*fob_origin_cost)
      INTO l_tqty,
	   l_tamt
      FROM xx_gso_po_dtl
     WHERE po_header_id=l_pohdr_id
       AND latest_line_flag='Y';

    UPDATE xx_gso_po_hdr
       SET po_qty=l_tqty,
	   po_amnt=l_tamt
     WHERE po_header_id=l_pohdr_id
       AND is_latest='Y';

  END LOOP;
  COMMIT;

  FOR cur IN lcu_po(p_batch_id,'A') LOOP

    SELECT xx_gso_po_hdr_S.nextval INTO l_pohdr_id FROM DUAL;

    FOR cr IN lcu_pol(cur.po_number,p_batch_id,'A') LOOP

        SELECT xx_gso_po_dtl_S.nextval INTO l_podtl_id FROM DUAL;

	l_merchant:=NULL;

	BEGIN
	  SELECT OD_PB_SOURCING_MERCHANT
	    INTO l_merchant
	    FROM apps.q_OD_GSO_DEPT_CATEGORY_v
	   WHERE OD_PB_SC_DEPT_NUM=cr.gso_dept_id;
        EXCEPTION
	  WHEN others THEN
	     l_merchant:=NULL;
  	END;

	BEGIN
	  INSERT INTO xx_gso_po_dtl
	    (   po_header_id,
		po_line_id,
		po_line_no,
		item,
		description,
		ordered_qty,
		uom,	
		vpc,
		dept,
		class,
  	        STD_PACK                     ,  
	        CARTON_PACK                  ,  
                CARTON_CUBE                  ,  
                CARTON_WEIGHT                ,  
                MASTER_CARTON                ,  
                RETAIL_COST                  ,  
                FOB_ORIGIN_COST              ,  
		master_fob_cost		     ,
                EST_LAND_COST                ,  
                ACT_LAND_COST                ,  
                MERCH_DEC_COST               ,   		
   		SHIPMENT_DATE		     ,
		SOURCE_PORT_NAME       ,
		DESTN_PORT_NAME,
		category,
		od_merchant,
		gso_mo,
		partial_line_flag,
		latest_line_flag,
		new_item_flag,
		over_shipped_flag,
		gso_dept_id,
		origin,
		nb_flag,
		inline_flag,
		safety_stock_flag,
		bv_flag,
		first_shipment_flag,
		diff_price,
		creation_date,
		last_update_date,
		created_by,
		last_updated_by,
		total_carton_cube,
		total_retail_cost,
		total_estland_cost,		
		total_actland_cost,
		total_merchdec_cost,
		line_total,
		line_status)
	  VALUES
	    (   l_pohdr_id,
		l_podtl_id,
		cr.po_line_no,
		ltrim(rtrim(cr.sku)),
		cr.description,
		cr.ordered_qty,
		cr.uom,
		cr.vpc,
		cr.dept,
		cr.class,
		cr.std_pack,
		cr.carton_pack,
		cr.carton_cube,
		cr.carton_weight,
		cr.master_carton,
		cr.retail_price,
		cr.fob_origin_cost,
		cr.master_fob,
		cr.est_landed_cost,
		cr.act_landed_cost,
		cr.merch_dec_cost,
		cr.ship_date,
		ltrim(rtrim(cr.port_name)),
		ltrim(rtrim(cr.location_name)),
		cr.category,
		ltrim(rtrim(l_merchant)),
		ltrim(rtrim(cr.gso_mo)),
		'N',	-- partial line flag
		'Y',	-- latest_line_flag
		'N',	-- new_item
		'N',	-- over_shipped
		cr.gso_dept_id,
		ltrim(rtrim(cur.origin_country)),
	        cr.nb_flag,
		cr.inline_flag,
		cr.sstk_flag,
		cr.bv_flag,
		'N',		-- first_shipment
		cr.diff_price,
		sysdate,
		sysdate,
		33963,
		33963,
		cr.master_carton*cr.carton_cube,
		cr.ordered_qty*cr.retail_price,
		cr.ordered_qty*cr.est_landed_cost,
		cr.ordered_qty*cr.act_landed_cost,
		cr.ordered_qty*cr.merch_dec_cost,
		cr.ordered_qty*cr.fob_origin_cost,
		'OPEN');

	  UPDATE xx_gso_po_stg
	     SET process_Flag=7,
		 vendor_process_flag=7,dept_process_flag=7
 	   WHERE rowid=cr.lrowid;

	EXCEPTION
	  WHEN others THEN
	    l_errmsg:=sqlerrm;
            UPDATE xx_gso_po_stg
	       SET error_message=error_message||' '||l_errmsg,
		   error_flag='Y',
		   process_flag=6,
		   sku_process_flag=6
	     WHERE rowid=cr.lrowid;
	END;
    END LOOP;

    SELECT SUM(ordered_qty),
	   SUM(ordered_qty*fob_origin_cost)
      INTO l_tqty,
	   l_tamt
      FROM xx_gso_po_dtl
     WHERE po_header_id=l_pohdr_id
       AND latest_line_flag='Y';
	

    BEGIN
      INSERT INTO xx_gso_po_hdr
	(
		po_header_id,
		version,
		is_latest,
		vendor_no,
		vendor_name,
		po_number,
		po_date,
		PO_STATUS_CD ,
		edi_status,
		ORIGIN_COUNTRY_CD,
   	        country_code,
	        PO_RECD_JDA_DATE,
		PO_SENT_VENDOR_DATE ,
		PO_CONFM_VEND_DATE,
	        COMPANY_SOURCE_CODE,
		port,
		loc,
		batch_id,
		po_ship_date,
		need_bv,
		buying_agent,
		od_merchant,
		currency_code,
		po_qty,
		po_amnt,
		creation_date,
		last_update_date,
		created_by,
		last_updated_by
	)
      VALUES
	(       l_pohdr_id,
		0,
		'Y',
		cur.vendor_no,
		ltrim(rtrim(cur.vendor_name)),
		cur.po_number,
		cur.po_date,
		'OPEN',
		cur.edi_status,
		ltrim(rtrim(cur.origin_country)),
		ltrim(rtrim(cur.country_cd)),
		cur.po_recd_to_jda,
		cur.po_rel_to_vend,
		cur.po_conf_by_vend,
		cur.company_source_cd,
		ltrim(rtrim(cur.port_name)),
		ltrim(rtrim(cur.location_name)),
		cur.batch_id,
		cur.ship_date,
		'N',		-- need_bv
		ltrim(rtrim(cur.agent)),
		ltrim(rtrim(cur.mo)),
		cur.currency,
		l_tqty,
		l_tamt,
		sysdate,
		sysdate,
		33963,
		33963
	);
    UPDATE xx_gso_po_stg 
       SET process_flag=7
     WHERE po_number=cur.po_number
       AND action_type='A'
       AND process_flag=1
       AND load_batch_id=p_batch_id;
    EXCEPTION
      WHEN others THEN
	l_errmsg:=sqlerrm;
	ROLLBACK;
	UPDATE xx_gso_po_stg 
	   SET error_message=error_message||','||l_errmsg,
	       error_Flag='Y',process_Flag=6
         WHERE po_number=cur.po_number
	   AND action_type='A'
	   AND load_batch_id=p_batch_id;
    END;
    COMMIT;

  END LOOP;

    -- For processing changed po

  FOR cur IN lcu_poc(p_batch_id,'C') LOOP

	l_opohdr_id		:=NULL;
    	l_version 		:=NULL;
	l_sent_to_vendor	:=NULL;	
	l_conf_by_vendor	:=NULL;
	l_hremarks		:=NULL;
	l_hlatecode		:=NULL;
	l_hlate_reason		:=NULL;
	l_potype		:=NULL;
	l_need_bv		:=NULL;
	l_insp_party		:=NULL;
	l_herr_flag		:='N';

    BEGIN
      SELECT po_header_id,
	     NVL(version,0),
	     po_sent_vendor_date,
	     po_confm_vend_date,
	     remarks,
	     late_code,
	     late_reason,
	     po_type,
	     need_bv,
	     inspection_party
        INTO l_opohdr_id,
	     l_version,
	     l_sent_to_vendor,
	     l_conf_by_vendor,
	     l_hremarks,
	     l_hlatecode,
	     l_hlate_reason,
	     l_potype,
	     l_need_bv,
	     l_insp_party
	FROM xx_gso_po_hdr
       WHERE po_number=cur.po_number
         AND is_latest='Y';
    EXCEPTION
      WHEN others THEN
	l_herr_flag:='Y';
	ln_herror_message:='Error in getting old po '||cur.po_number;
	l_version:=0;
    END;

    SELECT xx_gso_po_hdr_S.nextval INTO l_pohdr_id FROM DUAL;

    IF cur.edi_status NOT like 'V%' THEN

       FOR cr IN lcu_pol(cur.po_number,p_batch_id,'C') LOOP

      	l_opoline_id		:=NULL;
	l_ispartial		:=NULL;
	l_shipped_qty		:=NULL;
	l_nb			:=NULL;
	l_inline		:=NULL;
	l_safety_stock		:=NULL;
	l_bv			:=NULL;
	l_new_item		:=NULL;
	l_first_shipment	:=NULL;
	l_bv_status		:=NULL;
	l_bv_code		:=NULL;
	l_bv_reason		:=NULL;
	l_lremarks		:=NULL;
	l_lerr_flag		:=NULL;
	ln_lerror_message	:=NULL;
	l_merchant		:=NULL;

	BEGIN
	  SELECT OD_PB_SOURCING_MERCHANT
	    INTO l_merchant
	    FROM apps.q_OD_GSO_DEPT_CATEGORY_v
	   WHERE OD_PB_SC_DEPT_NUM=cr.gso_dept_id;
        EXCEPTION
	  WHEN others THEN
	     l_merchant:=NULL;
  	END;

        BEGIN	
	  SELECT po_line_id,
		 partial_line_flag,
		 shipped_qty,
		 nb_flag,
		 inline_flag,
		 safety_stock_flag,
		 bv_flag,
		 new_item_flag,
		 first_shipment_flag,
	         bv_status,
		 bv_code,
	 	 bv_reason,
		 remarks
	   INTO  l_opoline_id,
		 l_ispartial,
		 l_shipped_qty,
		 l_nb,
		 l_inline,
		 l_safety_stock,
		 l_bv,
		 l_new_item,
		 l_first_shipment,
		 l_bv_status,
		 l_bv_code,
		 l_bv_reason,
		 l_lremarks
	   FROM xx_gso_po_dtl
	  WHERE po_header_id=l_opohdr_id
	    AND item=cr.sku
	    AND po_line_no=cr.po_line_no
	    AND latest_line_flag='Y';
        EXCEPTION
          WHEN others THEN
	    l_lerr_flag:='Y';
	    ln_lerror_message:='Error in getting old po '||cur.po_number||','||cr.sku;
        END;

        SELECT xx_gso_po_dtl_S.nextval INTO l_podtl_id FROM DUAL;


	BEGIN
	  INSERT INTO xx_gso_po_dtl
	    (   po_header_id,
		po_line_id,
		po_line_no,
		item,
		description,
		ordered_qty,
		uom,	
		vpc,
		dept,
		class,
  	        STD_PACK                     ,  
	        CARTON_PACK                  ,  
                CARTON_CUBE                  ,  
                CARTON_WEIGHT                ,  
                MASTER_CARTON                ,  
                RETAIL_COST                  ,  
                FOB_ORIGIN_COST              ,  
		master_fob_cost		     ,
                EST_LAND_COST                ,  
                ACT_LAND_COST                ,  
                MERCH_DEC_COST               ,   		
   		SHIPMENT_DATE		     ,
		SOURCE_PORT_NAME       ,
		DESTN_PORT_NAME,
		category,
		od_merchant,
		gso_mo,
		partial_line_flag,
		latest_line_flag,
		new_item_flag,
		over_shipped_flag,
		gso_dept_id,
		origin,
		nb_flag,
		inline_flag,
		safety_stock_flag,
		bv_flag,
		first_shipment_flag,
		diff_price,
	         bv_status,
		 bv_code,
	 	 bv_reason,
		 remarks,
		 shipped_qty,
		creation_date,
		last_update_date,
		created_by,
		last_updated_by,
		total_carton_cube,
		total_retail_cost,
		total_estland_cost,		
		total_actland_cost,
		total_merchdec_cost,
		line_total,
		line_status)
	  VALUES
	    (   l_pohdr_id,
		l_podtl_id,
		cr.po_line_no,
		ltrim(rtrim(cr.sku)),
		cr.description,
		cr.ordered_qty,
		cr.uom,
		cr.vpc,
		cr.dept,
		cr.class,
		cr.std_pack,
		cr.carton_pack,
		cr.carton_cube,
		cr.carton_weight,
		cr.master_carton,
		cr.retail_price,
		cr.fob_origin_cost,
		cr.master_fob,
		cr.est_landed_cost,
		cr.act_landed_cost,
		cr.merch_dec_cost,
		cr.ship_date,
		ltrim(rtrim(cr.port_name)),
		ltrim(rtrim(cr.location_name)),
		cr.category,
		ltrim(rtrim(l_merchant)),
		ltrim(rtrim(cr.gso_mo)),
		l_ispartial,
		'Y',	-- latest_line_flag
		l_new_item,
		'N',	-- over_shipped
		cr.gso_dept_id,
		ltrim(rtrim(cur.origin_country)),
	        l_nb,
		l_inline,
		l_safety_stock,
		l_bv,
		l_first_shipment,
		cr.diff_price,
		 l_bv_status,
		 l_bv_code,
		 l_bv_reason,
		 l_lremarks,
		 l_shipped_qty,
		sysdate,
		sysdate,
		33963,
		33963,
		cr.master_carton*cr.carton_cube,
		cr.ordered_qty*cr.retail_price,
		cr.ordered_qty*cr.est_landed_cost,
		cr.ordered_qty*cr.act_landed_cost,
		cr.ordered_qty*cr.merch_dec_cost,
		cr.ordered_qty*cr.fob_origin_cost,
		'OPEN');


	  UPDATE xx_gso_po_dtl
	     SET latest_line_flag='N'
	   WHERE po_line_id=l_opoline_id;

	  UPDATE xx_gso_po_stg
	     SET process_Flag=7,
		 vendor_process_flag=7,dept_process_flag=7
 	   WHERE rowid=cr.lrowid;

	EXCEPTION
	  WHEN others THEN
	    l_errmsg:=sqlerrm;
            UPDATE xx_gso_po_stg
	       SET error_message=ln_lerror_message||' '||l_errmsg,
		   error_flag='Y',
		   process_flag=6,sku_process_flag=6
	     WHERE rowid=cr.lrowid;
	END;
      END LOOP;
    END IF;  -- cur.edi_status NOT like 'V%' THEN

    SELECT SUM(ordered_qty),
	   SUM(ordered_qty*fob_origin_cost)
      INTO l_tqty,
	   l_tamt
      FROM xx_gso_po_dtl
     WHERE po_header_id=l_pohdr_id
       AND latest_line_flag='Y';

    BEGIN
      INSERT INTO xx_gso_po_hdr
	(
		po_header_id,
		version,
		is_latest,
		vendor_no,
		vendor_name,
		po_number,
		po_date,
		PO_STATUS_CD ,
		edi_status,
		ORIGIN_COUNTRY_CD,
   	        country_code,
	        PO_RECD_JDA_DATE,
		PO_SENT_VENDOR_DATE ,
		PO_CONFM_VEND_DATE,
	        COMPANY_SOURCE_CODE,
		port,
		loc,
		batch_id,
		po_ship_date,
		buying_agent,
		od_merchant,
		currency_code,
  	        remarks,
	        late_code,
	        late_reason,
	        po_type,
	        need_bv,
	        inspection_party,
		po_qty,
		po_amnt,
		creation_date,
		last_update_date,
		created_by,
		last_updated_by
	)
      VALUES
	(       l_pohdr_id,
		l_version+1,
		'Y',
		cur.vendor_no,
		ltrim(rtrim(cur.vendor_name)),
		cur.po_number,
		cur.po_date,
		decode(cur.edi_status,'Void','VOID','OPEN'),
		cur.edi_status,
		ltrim(rtrim(cur.origin_country)),
		ltrim(rtrim(cur.country_cd)),
		cur.po_recd_to_jda,
		l_sent_to_vendor,
		l_conf_by_vendor,
		cur.company_source_cd,
		ltrim(rtrim(cur.port_name)),
		ltrim(rtrim(cur.location_name)),
		cur.batch_id,
		cur.ship_date,
		ltrim(rtrim(cur.agent)),
		ltrim(rtrim(cur.mo)),
		cur.currency,
  	        l_hremarks,
	        l_hlatecode,
	        l_hlate_reason,
	        l_potype,
	        l_need_bv,
	        l_insp_party,
		l_tqty,
		l_tamt,
		sysdate,
		sysdate,
		33963,
		33963
	);

    UPDATE xx_gso_po_hdr
       SET is_latest='N'
     WHERE po_header_id=l_opohdr_id;

    UPDATE xx_gso_po_stg 
       SET process_flag=7
     WHERE po_number=cur.po_number
       AND process_flag=1
       AND action_type='C'
       AND load_batch_id=p_batch_id;
    EXCEPTION
      WHEN others THEN
	l_errmsg:=sqlerrm;
	ROLLBACK;
	UPDATE xx_gso_po_stg 
	   SET error_message=ln_herror_message||','||l_errmsg,
	       error_Flag='Y',process_Flag=6
         WHERE po_number=cur.po_number
	   AND action_type='C'
	   AND load_batch_id=p_batch_id;
    END;
    COMMIT;
  END LOOP;

  insert_sku_master(p_batch_id);
EXCEPTION
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_po_data - '||gc_sqlerrm;
    x_retcode := 2;
END process_po_data;

-- +===================================================================+
-- | Name        :  Import_po                                          |
-- | Description :  This procedure is called from the concurrent       |
-- |                Program OD GSO PO Import.                          |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE import_po(
                       x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                    )
IS
---------------------------
--Declaring local variables
---------------------------

lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);
ln_seq			    PLS_INTEGER;
ln_total		    PLS_INTEGER;
l_btotal		    PLS_INTEGER;

BEGIN

    ln_seq:=fnd_global.conc_request_id;

    ------------------------------------------------------------
    --Updating PO Staging with load batch id and process flags
    ------------------------------------------------------------
    UPDATE xx_gso_po_stg
       SET load_batch_id=ln_seq,
	   action_type='A'
	  ,vendor_process_flag = (CASE WHEN vendor_process_flag IS NULL OR vendor_process_flag = 1 THEN 2 ELSE vendor_process_flag END)
	  ,dept_process_flag = (CASE WHEN dept_process_flag IS NULL OR dept_process_flag = 1 THEN 2 ELSE dept_process_flag END)
	  ,sku_process_flag = (CASE WHEN sku_process_flag IS NULL OR sku_process_flag = 1 THEN 2 ELSE sku_process_flag END)
    WHERE  process_flag=1
      AND  load_batch_id IS NULL
      AND  edi_status like 'Ori%';

    COMMIT;

    UPDATE xx_gso_po_stg
       SET load_batch_id=ln_seq,
	   action_type='C'
	  ,vendor_process_flag = (CASE WHEN vendor_process_flag IS NULL OR vendor_process_flag = 1 THEN 2 ELSE vendor_process_flag END)
	  ,dept_process_flag = (CASE WHEN dept_process_flag IS NULL OR dept_process_flag = 1 THEN 2 ELSE dept_process_flag END)
	  ,sku_process_flag = (CASE WHEN sku_process_flag IS NULL OR sku_process_flag = 1 THEN 2 ELSE sku_process_flag END)
    WHERE  process_flag=1
      AND  load_batch_id IS NULL
      AND  ( edi_status like 'Revised%' or edi_status like 'V%');

    COMMIT;


    ln_total := SQL%ROWCOUNT;

    UPDATE  xx_gso_po_stg
       SET  process_flag=1
	   ,load_batch_id=ln_seq
     WHERE process_Flag=6
       AND ( vendor_process_flag<>7 OR dept_process_flag<>7 or sku_process_Flag<>7);
 
    COMMIT;

    BEGIN

        display_out('*Batch_id* '||to_char(ln_seq));
        display_out('*Total PO Records* '||to_char(ln_total));


        -----------------------------------------------------------
        --Calling validate_po_data for Data Validations
        -----------------------------------------------------------
        validate_po_data(   x_errbuf                  =>lx_errbuf
                           ,x_retcode                 =>lx_retcode
                           ,p_batch_id                =>ln_seq
                          );
        IF lx_retcode <> 0 THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL
                 THEN x_errbuf  := lx_errbuf;
                 ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
        END IF;

        --------------------------------------------------------------------
        --Calling process_po_data to process and insert into PO Base tables
        --------------------------------------------------------------------

        lx_errbuf     := NULL;
        lx_retcode    := NULL;



          process_po_data(  x_errbuf     =>lx_errbuf
                           ,x_retcode    =>lx_retcode
                          ,p_batch_id   =>ln_seq
                         );



        IF lx_retcode <> 0 THEN
           x_retcode := lx_retcode;
           CASE WHEN x_errbuf IS NULL
                THEN x_errbuf  := lx_errbuf;
                ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
           END CASE;
        END IF;

    EXCEPTION
    WHEN OTHERS THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL
             THEN x_errbuf  := gc_sqlerrm;
             ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
        END CASE;
        x_retcode := 2;
    END;

    SELECT COUNT(1)
      INTO l_btotal
      FROM xx_gso_po_Stg
     WHERE load_batch_id=ln_seq
       AND (vendor_process_Flag=3 or dept_process_Flag=3 or sku_process_flag=3 or eol_Flag='Y');

     IF NVL(l_btotal,0)>0 THEN
        send_exception_rpt(ln_seq);
     END IF;
     commit;

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in import_po - '||SQLERRM;
        x_retcode := 2;
END import_po;
 
END XX_PA_PB_GSO_PKG;
/
SHOW ERRORS

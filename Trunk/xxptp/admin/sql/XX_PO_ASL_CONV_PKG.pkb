SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_ASL_CONV_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_PO_ASL_CONV_PKG.pkb         	                                |
-- | Description :  INV ASL 							        |
-- |                                                                                    |
-- | Change History  :                                                                  |
-- | Version           Date             Changed By              Description             |
--+=====================================================================================+
--| 1.0              21-Jun-2010       Paddy Sanjeevi          Original                 |
--+=====================================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------
G_USER_ID                   CONSTANT mtl_system_items_interface.created_by%TYPE                 :=   FND_GLOBAL.user_id;
G_DATE                      CONSTANT mtl_system_items_interface.last_update_date%TYPE           :=   SYSDATE;
G_PACKAGE_NAME              CONSTANT VARCHAR2(30)                                               :=  'XX_PO_ASL_CONV_PKG';
G_APPLICATION               CONSTANT VARCHAR2(10)                                               :=  'PO';
G_ASL_STATUS_ID             CONSTANT NUMBER                                             		:=   2;
G_VENDOR_BUSINESS_TYPE      CONSTANT VARCHAR2(25)                                               :=  'DIRECT';
G_DOCUMENT_SOURCING_METHOD  CONSTANT VARCHAR2(25)                                               :=  'ASL';
G_RELEASE_GENERATION_METHOD CONSTANT VARCHAR2(25)                                               :=  'CREATE_AND_APPROVE';
G_DOCUMENT_TYPE             CONSTANT VARCHAR2( 25)                                              :=  'QUOTATION';
G_MASTER_ORG_ID             mtl_parameters.organization_id%TYPE;

gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
gn_master_org_id            mtl_parameters.organization_id%TYPE;



PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
			    ,p_email_list IN VARCHAR2
			    ,p_text IN VARCHAR2 )
IS
  lc_mailhost    VARCHAR2(64) := FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
  lc_from        VARCHAR2(64) := 'Workflow-Mailer@officedepot.com';
  l_mail_conn    UTL_SMTP.connection;
  lc_to          VARCHAR2(2000);
  lc_to_all      VARCHAR2(2000) := p_email_list ;
  i              BINARY_INTEGER;
  TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
  lc_to_tbl      T_V100;
  crlf VARCHAR2 (10) := UTL_TCP.crlf; 
BEGIN
  -- If setup data is missing then return

  IF lc_mailhost IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  l_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, lc_mailhost);
  UTL_SMTP.mail(l_mail_conn, lc_from);

  -- Check how many recipients are present in lc_to_all

  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(l_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || lc_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || Chr(13));

  --UTL_SMTP.write_data(l_mail_conn, Chr(13));

  -- Checl all recipients

  FOR i IN 1..lc_to_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'To: '      || lc_to_tbl(i) || Chr(13));

  END LOOP;
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.write_data(l_mail_conn, p_text||crlf);
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.close_data(l_mail_conn);
  UTL_SMTP.quit(l_mail_conn);
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END SEND_NOTIFICATION;


-- +====================================================================+
-- | Name        :  xx_po_asl_extract                                   |
-- | Description :  This procedure is to extract asl data from RMS      |
-- |                                                                    |
-- +====================================================================+


PROCEDURE xx_po_asl_extract( x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
			   )
IS
  CURSOR c1 IS
  SELECT DISTINCT item,
	          supplier,
		  vpn,
		  primary_supp
    FROM XX_PO_ITEM_SUPP_loc_int
   WHERE process_Flag=1
     AND load_batch_id IS NULL;
BEGIN

  DELETE 
    FROM xx_po_item_supp_loc_int
   WHERE creation_date<SYSDATE-7;
  COMMIT;

  DELETE 
    FROM xx_po_item_supp_int
   WHERE creation_date<SYSDATE-7;
  COMMIT;

  BEGIN
    INSERT 
      INTO xx_po_item_supp_loc_int 
	   (control_id,
	    process_flag,
            item,
            supplier,
            vpn,
            primary_supp,
            loc,
	    av_cost,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by
           )
    SELECT XX_PO_ITEM_SUPP_s.nextval,
	   1,
	   item,
	   supplier,
	   vpn,
           primary_supp_ind,
           loc,
	   av_cost,
	   sysdate,
	   fnd_global.user_id,
	   sysdate,
	   fnd_global.user_id
      FROM od_ebs_asl_data@RMS.NA.ODCORP.NET;
  EXCEPTION
    WHEN others THEN
      gc_sqlerrm := SQLERRM;
      gc_sqlcode := SQLCODE;
      x_errbuf  := 'Unexpected error in po_asl_extract - '||gc_sqlerrm;
      x_retcode := 2;
  END;

  FOR cur IN C1 LOOP
    BEGIN
      INSERT
        INTO XX_PO_ITEM_SUPP_int
	   (control_id,
	    process_flag,
            item,
            supplier,
            vpn,
            primary_supp,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by
           )
     VALUES
           ( XX_PO_ITEM_SUPP_s.nextval,
	     1,
	     cur.item,
	     cur.supplier,
	     cur.vpn,
             cur.primary_supp,
	     sysdate,
	     fnd_global.user_id,
	     sysdate,
	     fnd_global.user_id
	    );
    EXCEPTION
      WHEN others THEN
        gc_sqlerrm := SQLERRM;
        gc_sqlcode := SQLCODE;
        x_errbuf  := 'Unexpected error in po_asl_extract - '||gc_sqlerrm;
        x_retcode := 2;
    END;
  END LOOP;
  COMMIT;
END xx_po_asl_extract;


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


-- +===================================================================+
-- | Name        :  validate_item_data                                 |
-- | Description :  This procedure is invoked from the OD: ASL Items   |
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input          |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_item_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                            )
IS

------------------------------------------
--Declaring Exceptions and local variables
------------------------------------------

ln_vendor_site_id           po_vendor_sites_all.vendor_site_id%TYPE;
ln_vendor_id                po_vendors.vendor_id%TYPE;
ln_supplier		    VARCHAR2(10);
ln_org_id                   po_vendor_sites_all.org_id%TYPE;
ln_inventory_item_id        XX_INV_ITEM_MASTER_ATTRIBUTES.inventory_item_id%TYPE;
ln_val_organization_id      mtl_parameters.organization_id%TYPE;
ln_inv_organization_id 	    mtl_parameters.organization_id%TYPE;
ln_error_message	varchar2(2000);


-----------------------------------------
--Cursor to get the Item/Supplier Details
-----------------------------------------
CURSOR lcu_item_supp(p_batch_id IN NUMBER)
IS
SELECT rowid isrowid ,
       control_id,
       item,
       supplier
  FROM XX_PO_ITEM_SUPP_int
 WHERE load_batch_id=p_batch_id
 ORDER BY control_id;

--------------------------------------------------
--Cursor to get the Item/Supplier/Location Details
--------------------------------------------------
CURSOR lcu_location(p_batch_id IN NUMBER)
IS
SELECT ROWID lrowid,
       control_id,
       loc,inventory_item_id
  FROM XX_PO_ITEM_SUPP_loc_int
 WHERE load_batch_id = p_batch_id
 ORDER BY control_id;

------------------------------------------------------------------
--Cursor to determine the Vendor details (Vendor ID, Site ID and Operating Unit)
------------------------------------------------------------------
CURSOR lcu_vendor(p_site_id NUMBER)
IS
SELECT vendor_id,
       org_id
FROM   po_vendor_sites_all Vsite
WHERE  vendor_site_id=p_site_id;

---------------------------------------------------------------------------
--Cursor to determine Inventory Item ID ---------------------
---------------------------------------------------------------------------
CURSOR lcu_master_item(p_item VARCHAR2)
IS
SELECT  inventory_item_id
FROM    apps.mtl_system_items_b
WHERE   organization_id=G_MASTER_ORG_ID
AND     segment1=p_item;

----------------------------------------------------------------------------
---Cursor to dtermine the Validation Organization to load the Attribute column
-------------------------------------------------------------------------------
CURSOR lcu_val_org(p_org_id Number)
IS
SELECT hoi.organization_id
FROM   hr_organization_information hoi,
       hr_organization_units hou
WHERE  hou.type = 'VAL'
AND    hou.organization_id = hoi.organization_id
AND    hoi.org_information_context = 'Accounting Information'
AND    hoi.org_information3 = p_org_id;

----------------------------------------------
--Cursor to get inventory org for RMS Location
----------------------------------------------
CURSOR lcu_inv_org (p_location VARCHAR2)
IS
SELECT HOU.organization_id
FROM   hr_organization_units HOU
WHERE  HOU.attribute1   =  p_location
AND    SYSDATE BETWEEN NVL(HOU.date_from,SYSDATE) AND 
       NVL(HOU.date_to,SYSDATE+1);

CURSOR lcu_item_org (p_item_id NUMBER,p_inv_org NUMBER)
IS
SELECT inventory_item_id 
FROM   mtl_system_items_b
WHERE  organization_id=p_inv_org
AND    inventory_item_id=p_item_id;

--------------------------------
--Declaring Table Type Variables
--------------------------------

TYPE item_supp_tbl_type IS TABLE OF lcu_item_supp%ROWTYPE INDEX BY BINARY_INTEGER;
lt_item_supp_tbl item_supp_tbl_type;

TYPE mst_rowid_tbl_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
lt_master_row_id_tbl mst_rowid_tbl_type;

TYPE item_supp_loc_tbl_type IS TABLE OF lcu_location%ROWTYPE INDEX BY BINARY_INTEGER;
lt_item_supp_loc_tbl item_supp_loc_tbl_type;

TYPE loc_rowid_tbl_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
lt_loc_row_id_tbl loc_rowid_tbl_type;

TYPE vendor_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.vendor_id%TYPE INDEX BY BINARY_INTEGER;
lt_vendor_id_tbl  vendor_id_tbl_type;

TYPE vendor_site_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
lt_vendor_site_id_tbl  vendor_site_id_tbl_type;

TYPE val_org_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.organization_id%TYPE INDEX BY BINARY_INTEGER;
lt_val_org_id_tbl val_org_id_tbl_type;

TYPE item_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
lt_item_id_tbl  item_id_tbl_type;

TYPE ou_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.operating_unit%TYPE INDEX BY BINARY_INTEGER;
lt_ou_id_tbl ou_id_tbl_type;

TYPE loc_pf_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_loc_int.loc_process_flag%TYPE INDEX BY BINARY_INTEGER;
lt_loc_pf_tbl loc_pf_tbl_type;

TYPE inv_org_id_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_loc_int.organization_id%TYPE INDEX BY BINARY_INTEGER;
lt_inv_org_id_tbl inv_org_id_tbl_type;

TYPE error_mesg_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.error_message%TYPE INDEX BY BINARY_INTEGER;
lt_error_mesg_tbl error_mesg_tbl_type;

TYPE error_loc_tbl_type IS TABLE OF XX_PO_ITEM_SUPP_int.error_message%TYPE INDEX BY BINARY_INTEGER;
lt_error_loc_tbl error_loc_tbl_type;

BEGIN

  -----------------------------------------
  --Feching and Validating Master Item Data
  --
  --LIMIT clause not used here because batch
  --size will be used to limit the fetch
  -----------------------------------------
    OPEN  lcu_item_supp(p_batch_id);
    FETCH lcu_item_supp BULK COLLECT INTO lt_item_supp_tbl;
    CLOSE lcu_item_supp;

    IF lt_item_supp_tbl.COUNT <> 0 THEN

       FOR i IN 1..lt_item_supp_tbl.COUNT
       LOOP

           lt_master_row_id_tbl(i)     := lt_item_supp_tbl(i).ISROWID;
	   ln_vendor_site_id           :=NULL;
	   ln_vendor_id                :=NULL;
	   ln_org_id                   :=NULL;
	   ln_inventory_item_id        :=NULL;
	   ln_val_organization_id      :=NULL;
	   ln_error_message:=NULL;

	   ln_supplier:=LPAD(TO_CHAR(lt_item_supp_tbl(i).supplier),10,0);
	   ln_vendor_site_id:=xx_po_global_vendor_pkg.f_translate_inbound(ln_supplier);

           OPEN  lcu_vendor(ln_vendor_site_id);
           FETCH lcu_vendor INTO ln_vendor_id,ln_org_id;

           IF lcu_vendor%NOTFOUND THEN      ----       Check for Vendor exists
	      lt_vendor_id_tbl(i)		:=-1;
	      lt_vendor_site_id_tbl(i)	:=-1;
	      lt_ou_id_tbl(i)			:=-1;
	      ln_error_message:='Vendor does not exists in EBS';
	   ELSE
	     lt_vendor_id_tbl(i):=ln_vendor_id;
   	     lt_vendor_site_id_tbl(i):=ln_vendor_site_id;
	     lt_ou_id_tbl(i):=ln_org_id;
	   END IF;
	   CLOSE lcu_vendor;
	  
           OPEN lcu_master_item(lt_item_supp_tbl(i).item);
           FETCH lcu_master_item INTO ln_inventory_item_id;

           IF lcu_master_item%NOTFOUND THEN
   	      lt_item_id_tbl(i):=-1;
	      ln_error_message:=ln_error_message||', Item does not exists';
	   ELSE
	      lt_item_id_tbl(i):=ln_inventory_item_id;
	   END IF;
	   CLOSE lcu_master_item;
 
	   IF ln_org_id IS NOT NULL THEN
              OPEN lcu_val_org(ln_org_id);
              FETCH lcu_val_org INTO ln_val_organization_id;

              IF lcu_val_org%NOTFOUND THEN
		 lt_val_org_id_tbl(i):=-1;
		 ln_error_message:=ln_error_message||', Validation Org does not exists';
              ELSE
		 lt_val_org_id_tbl(i):=ln_val_organization_id;
              END IF;
              CLOSE lcu_val_org;
	   ELSE
		 lt_val_org_id_tbl(i):=-1;
           END IF;
	   lt_error_mesg_tbl(i):=ln_error_message;
       END LOOP; --End of Master Items Loop


       ------------------------------------------------------------
       -- Bulk Update XX_PO_ITEM_SUPP_int with Process flags and Ids
       ------------------------------------------------------------

       FORALL i IN 1 .. lt_item_supp_tbl.LAST 
         UPDATE XX_PO_ITEM_SUPP_int
            SET  vendor_id  	   = lt_vendor_id_tbl(i)
                ,vendor_site_id    = lt_vendor_site_id_tbl(i)
                ,operating_unit    = lt_ou_id_tbl(i)
                ,inventory_item_id = lt_item_id_tbl(i)
	        ,organization_id   = lt_val_org_id_tbl(i)
		,error_message     = lt_error_mesg_tbl(i)
                ,asl_process_flag  = (CASE WHEN asl_process_flag <> 7
                                                       AND
                                                        (   lt_vendor_id_tbl(i)   = -1
                                                         OR lt_item_id_tbl(i)     = -1
                                                         OR lt_val_org_id_tbl(i)  = -1
                                                         )   THEN 3
                                            WHEN asl_process_flag < 4        THEN 4
                                            ELSE asl_process_flag
                                      END
                                     )
          WHERE  ROWID=lt_master_row_id_tbl(i);  
          COMMIT;
    END IF; --lt_itemmaster.count <> 0

    UPDATE XX_PO_ITEM_SUPP_loc_int xisl
       SET (vendor_id,vendor_site_id,
	    inventory_item_id,vpn,primary_supp)=(    SELECT vendor_id,
							        vendor_site_id,
								inventory_item_id,
								vpn,
							        primary_supp
							   FROM XX_PO_ITEM_SUPP_int
						          WHERE load_batch_id=xisl.load_batch_id
							    AND item=xisl.item
							    AND supplier=xisl.supplier
							    AND load_batch_id=xisl.load_batch_id)
     WHERE load_batch_id=p_batch_id;
    COMMIT;

    --------------------------------------
    --Fetching and Validating Location Data
    --------------------------------------
    OPEN lcu_location(p_batch_id);
    FETCH lcu_location BULK COLLECT INTO lt_item_supp_loc_tbl;
    CLOSE lcu_location;

    IF lt_item_supp_loc_tbl.COUNT <> 0 THEN
       FOR i IN 1 .. lt_item_supp_loc_tbl.COUNT
       LOOP
         lt_loc_row_id_tbl(i)        :=   lt_item_supp_loc_tbl(i).LROWID;
         ln_inv_organization_id      :=   NULL;
         ln_error_message:=NULL;                   
         OPEN lcu_inv_org(TO_CHAR(lt_item_supp_loc_tbl(i).loc));
         FETCH lcu_inv_org INTO ln_inv_organization_id;

         IF lcu_inv_org%NOTFOUND THEN
            lt_loc_pf_tbl(i) 	:=   3;
            lt_inv_org_id_tbl(i)   :=  -1;
	    ln_error_message:='Inventory Org does not exists';
         ELSE
            lt_loc_pf_tbl(i) := 4;
            lt_inv_org_id_tbl(i)  := ln_inv_organization_id;
	    lt_error_loc_tbl(i):=NULL;
         END IF;	        --lcu_inv_org%NOTFOUND
         CLOSE lcu_inv_org;


         OPEN lcu_item_org(lt_item_supp_loc_tbl(i).inventory_item_id,ln_inv_organization_id);
         FETCH lcu_item_org INTO ln_inventory_item_id;

         IF lcu_item_org%NOTFOUND THEN
            lt_loc_pf_tbl(i) 	:=   3;
	    ln_error_message:=ln_error_message||', Item/Org does not exists';
         ELSE
            lt_loc_pf_tbl(i) := 4;
	    lt_error_loc_tbl(i):=NULL;
         END IF;	        --lcu_inv_org%NOTFOUND
         CLOSE lcu_item_org;
	 lt_error_loc_tbl(i):=ln_error_message;
       END LOOP; --End of lt_item_supp_loc_tbl.COUNT loop

       ------------------------------------------------------------
       -- Bulk Update XX_PO_ITEM_SUPP_int with Process flags and Ids
       ------------------------------------------------------------

       FORALL i IN 1..lt_item_supp_loc_tbl.LAST    
         UPDATE  XX_PO_ITEM_SUPP_loc_int
            SET  loc_process_flag  =   lt_loc_pf_tbl(i)
                ,organization_id   =   lt_inv_org_id_tbl(i)
		,error_message=lt_error_loc_tbl(i)
          WHERE  ROWID             =   lt_loc_row_id_tbl(i);
         COMMIT;

    END IF;  -- lt_item_supp_loc_tbl.COUNT <> 0 THEN



/*
    UPDATE XX_PO_ITEM_SUPP_int xiss
       SET asl_process_flag=3
     WHERE load_batch_id=p_batch_id
       AND EXISTS (SELECT 'x'
			   FROM XX_PO_ITEM_SUPP_loc_int
			  WHERE load_batch_id=xiss.load_batch_id
			    AND item=xiss.item
			    AND loc_process_flag=3);
*/
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    IF lcu_location%ISOPEN THEN
       CLOSE lcu_location;
    END IF;
    IF lcu_vendor%ISOPEN THEN
       CLOSE lcu_vendor;
    END IF;
    IF lcu_val_org%ISOPEN THEN
       CLOSE lcu_val_org;
    END IF;
    IF lcu_master_item%ISOPEN THEN
	 CLOSE lcu_master_item;
    END IF;
    IF lcu_inv_org%ISOPEN THEN
	 CLOSE lcu_inv_org;
    END IF;

    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in validate_item_data - '||gc_sqlerrm;
    x_retcode := 2;
END validate_item_data;

-- +===================================================================+
-- | Name        :  process_asl_data                                   |
-- | Description :  This procedure is invoked from import_asl procedure|
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- +===================================================================+
PROCEDURE process_asl_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                           )
IS

---------------------------
--Declaring Local Variables
---------------------------

ln_asl_id      		NUMBER;
i			NUMBER;
---------------------------------------------
--Cursor to fetch ASL records for processing
---------------------------------------------
CURSOR lcu_asl_item(p_batch_id NUMBER) IS
SELECT   rowid isrowid
	,item
	,supplier
	,vendor_id
	,vendor_site_id
	,organization_id
	,inventory_item_id
	,vpn
	,primary_supp
 FROM   XX_PO_ITEM_SUPP_int
WHERE  load_batch_id=p_batch_id
  AND  asl_process_flag=4;

CURSOR lcu_asl_upd(p_batch_id NUMBER) IS
SELECT   rowid isrowid
	,item
	,supplier
	,vendor_id
	,vendor_site_id
	,organization_id
	,inventory_item_id
	,vpn
	,primary_supp
 FROM   XX_PO_ITEM_SUPP_int
WHERE  load_batch_id=p_batch_id
  AND  asl_process_flag=5;

------------------------------------------------------
--Cursor to fetch ASL Location records for processing
------------------------------------------------------
CURSOR lcu_asl_loc(p_batch_id NUMBER) IS
SELECT   rowid lrowid
	,item
	,supplier
	,loc
	,vendor_id
	,vendor_site_id
	,organization_id
	,inventory_item_id
	,vpn
	,primary_supp
	,av_cost
  FROM   XX_PO_ITEM_SUPP_loc_int
 WHERE  load_batch_id=p_batch_id
   AND  loc_process_flag=4;


CURSOR lcu_loc_upd(p_batch_id NUMBER) IS
SELECT   rowid lrowid
	,item
	,supplier
	,loc
	,vendor_id
	,vendor_site_id
	,organization_id
	,inventory_item_id
	,vpn
	,primary_supp
	,av_cost
  FROM   XX_PO_ITEM_SUPP_loc_int
 WHERE  load_batch_id=p_batch_id
   AND  loc_process_flag=5;

--------------------------------
--Declaring Table Type Variables
--------------------------------

TYPE asl_master_tbl_type IS TABLE OF lcu_asl_item%ROWTYPE INDEX BY BINARY_INTEGER;
lt_asl_master_tbl asl_master_tbl_type;

TYPE asl_loc_tbl_type  IS TABLE OF lcu_asl_loc%ROWTYPE INDEX BY BINARY_INTEGER;
lt_asl_loc_tbl asl_loc_tbl_type  ;

BEGIN

  UPDATE XX_PO_ITEM_SUPP_int xisi
     SET asl_process_flag=5,
	 process_flag=5
   WHERE load_batch_id=p_batch_id
     AND asl_process_flag=4
     AND EXISTS (SELECT 'x'
		   FROM apps.po_approved_supplier_list
		  WHERE item_id=xisi.inventory_item_id
	            AND vendor_id=xisi.vendor_id
		    AND using_organization_id=xisi.organization_id
		    AND vendor_site_id=xisi.vendor_site_id);
  COMMIT;

  i:=0;
  FOR cur IN lcu_asl_upd(p_batch_id) LOOP
    i:=i+1;
    UPDATE apps.po_approved_supplier_list
       SET attribute6=cur.primary_supp,attribute_category='RMS Attributes',
	   last_updated_by=fnd_global.user_id,
	   last_update_date=sysdate
     WHERE item_id=cur.inventory_item_id
       AND vendor_id=cur.vendor_id
       AND using_organization_id=cur.organization_id
       AND vendor_site_id=cur.vendor_site_id;
    IF SQL%FOUND THEN
       UPDATE XX_PO_ITEM_SUPP_int xisi
          SET asl_process_flag=7,
	      process_flag=7
        WHERE rowid=cur.isrowid;
       IF i>=10000 THEN
	  COMMIT;
	  i:=0;
       END IF;
    END IF;
  END LOOP;
  COMMIT;

  OPEN  lcu_asl_item(p_batch_id);
  FETCH lcu_asl_item BULK COLLECT INTO lt_asl_master_tbl;
  CLOSE lcu_asl_item;

  IF lt_asl_master_tbl.COUNT <> 0 THEN

     FOR i IN 1..lt_asl_master_tbl.COUNT
     LOOP

       SELECT po_approved_supplier_list_s.NEXTVAL
         INTO ln_asl_id
         FROM DUAL;

       BEGIN
         INSERT 
	   INTO po_approved_supplier_list
	 	   (  asl_id,
		      asl_status_id,
		      using_organization_id,
		      owning_organization_id,
		      vendor_id,
		      vendor_site_id,
		      vendor_business_type,
		      item_id,
		      primary_vendor_item,
		      creation_date,
		      created_by,
		      last_update_date,
		      last_updated_by,
		      last_update_login,attribute_category,
                      attribute6)
         VALUES   (   ln_asl_id,
		      G_ASL_STATUS_ID,
		      lt_asl_master_tbl(i).organization_id,
		      lt_asl_master_tbl(i).organization_id,
		      lt_asl_master_tbl(i).vendor_id,
		      lt_asl_master_tbl(i).vendor_site_id,
  		      G_VENDOR_BUSINESS_TYPE,
		      lt_asl_master_tbl(i).inventory_item_id,
		      lt_asl_master_tbl(i).vpn,
		      SYSDATE,
		      G_USER_ID,
		      SYSDATE,
		      G_USER_ID,
		      G_USER_ID,'RMS Attributes',
		      lt_asl_master_tbl(i).primary_supp
		  );
 	BEGIN
          INSERT 
	    INTO po_asl_attributes
	 	 ( asl_id,
		   using_organization_id,
		   vendor_id,
		   vendor_site_id,
		   item_id,
		   document_sourcing_method,
		   release_generation_method,
		   creation_date,
		   created_by,
		   last_update_date,
		   last_updated_by,
		   last_update_login)
     	  VALUES
	  	( ln_asl_id,
  	 	  lt_asl_master_tbl(i).organization_id,
  		  lt_asl_master_tbl(i).vendor_id,
		  lt_asl_master_tbl(i).vendor_site_id,
  		  lt_asl_master_tbl(i).inventory_item_id,
	 	  G_DOCUMENT_SOURCING_METHOD,
		  G_RELEASE_GENERATION_METHOD,
		  SYSDATE,
		  G_USER_ID,
		  SYSDATE,
		  G_USER_ID,
		  G_USER_ID
		);
	   UPDATE XX_PO_ITEM_SUPP_int
              SET asl_process_flag=7,process_flag=7
            WHERE rowid=lt_asl_master_tbl(i).isrowid;
	EXCEPTION
          WHEN OTHERS THEN
            gc_sqlerrm := SQLERRM;
 	    UPDATE XX_PO_ITEM_SUPP_int
               SET error_message='ASL Attr Insert :'||gc_sqlerrm,
	  	   asl_process_flag=6,process_Flag=7
             WHERE rowid=lt_asl_master_tbl(i).isrowid;
        END;
       EXCEPTION
         WHEN OTHERS THEN
           gc_sqlerrm := SQLERRM;
	   UPDATE XX_PO_ITEM_SUPP_int
              SET error_message='ASL Insert :'||gc_sqlerrm,
		  asl_process_flag=6,process_Flag=7
            WHERE rowid=lt_asl_master_tbl(i).isrowid;
       END;
     END LOOP;  -- FOR i IN 1..lt_asl_master_tbl.COUNT
  END IF; 	-- lt_asl_master_tbl.COUNT <> 0 THEN
  COMMIT;   

  UPDATE XX_PO_ITEM_SUPP_loc_int xisl
     SET loc_process_flag=5,
	 process_flag=5
   WHERE load_batch_id=p_batch_id
     AND loc_process_Flag=4
     AND EXISTS (SELECT 'x'
  	  	       FROM apps.po_approved_supplier_list
  	  	      WHERE item_id=xisl.inventory_item_id
			AND using_organization_id=xisl.organization_id
	                AND vendor_id=xisl.vendor_id
   		        AND vendor_site_id=xisl.vendor_site_id);
  COMMIT;

  i:=0;
  FOR cur IN lcu_loc_upd(p_batch_id) LOOP

    i:=i+1;
    UPDATE apps.po_approved_supplier_list
       SET attribute6=cur.primary_supp,attribute_category='RMS Attributes',
	   attribute8=cur.av_cost,
	   last_updated_by=fnd_global.user_id,
	   last_update_date=sysdate
     WHERE item_id=cur.inventory_item_id
       AND vendor_id=cur.vendor_id
       AND using_organization_id=cur.organization_id
       AND vendor_site_id=cur.vendor_site_id;

    IF SQL%FOUND THEN
       UPDATE XX_PO_ITEM_SUPP_loc_int xisl
          SET loc_process_flag=7,
	      process_flag=7
        WHERE rowid=cur.lrowid;
    END IF;
    IF i>=10000 THEN
       COMMIT;
       i:=0;
    END IF;
  END LOOP;
  COMMIT;

  OPEN lcu_asl_loc(p_batch_id);
  FETCH lcu_asl_loc BULK COLLECT INTO lt_asl_loc_tbl;
  CLOSE lcu_asl_loc;

  IF lt_asl_loc_tbl.COUNT <> 0 THEN

     FOR i IN 1..lt_asl_loc_tbl.COUNT
     LOOP

       SELECT po_approved_supplier_list_s.NEXTVAL
         INTO ln_asl_id
         FROM DUAL;

       BEGIN
         INSERT 
	   INTO po_approved_supplier_list
	 	   (  asl_id,
		      asl_status_id,
		      using_organization_id,
		      owning_organization_id,
		      vendor_id,
		      vendor_site_id,
		      vendor_business_type,
		      item_id,
		      primary_vendor_item,
		      creation_date,
		      created_by,
		      last_update_date,
		      last_updated_by,
		      last_update_login,attribute_category,
                      attribute6,attribute8)
         VALUES   (   ln_asl_id,
		      G_ASL_STATUS_ID,
		      lt_asl_loc_tbl(i).organization_id,
		      lt_asl_loc_tbl(i).organization_id,
		      lt_asl_loc_tbl(i).vendor_id,
		      lt_asl_loc_tbl(i).vendor_site_id,
  		      G_VENDOR_BUSINESS_TYPE,
		      lt_asl_loc_tbl(i).inventory_item_id,
		      lt_asl_loc_tbl(i).vpn,
		      SYSDATE,
		      G_USER_ID,
		      SYSDATE,
		      G_USER_ID,
		      G_USER_ID,'RMS Attributes',
		      lt_asl_loc_tbl(i).primary_supp,
		      lt_asl_loc_tbl(i).av_cost
		  );
 	 BEGIN
           INSERT 
	     INTO po_asl_attributes
	  	 ( asl_id,
		   using_organization_id,
		   vendor_id,
		   vendor_site_id,
		   item_id,
		   document_sourcing_method,
		   release_generation_method,
		   creation_date,
		   created_by,
		   last_update_date,
		   last_updated_by,
	 	   last_update_login)
     	   VALUES
	  	( ln_asl_id,
  	 	  lt_asl_loc_tbl(i).organization_id,
  		  lt_asl_loc_tbl(i).vendor_id,
		  lt_asl_loc_tbl(i).vendor_site_id,
  		  lt_asl_loc_tbl(i).inventory_item_id,
	 	  G_DOCUMENT_SOURCING_METHOD,
		  G_RELEASE_GENERATION_METHOD,
		  SYSDATE,
		  G_USER_ID,
		  SYSDATE,
		  G_USER_ID,
		  G_USER_ID
		);
	   UPDATE XX_PO_ITEM_SUPP_loc_int
              SET loc_process_flag=7,process_flag=7
            WHERE rowid=lt_asl_loc_tbl(i).lrowid;
	 EXCEPTION
           WHEN OTHERS THEN
             gc_sqlerrm := SQLERRM;
  	     UPDATE XX_PO_ITEM_SUPP_loc_int
                SET error_message='ASL Attr Insert :'||gc_sqlerrm,
	  	    loc_process_flag=6,process_flag=7
              WHERE rowid=lt_asl_loc_tbl(i).lrowid;
         END;
       EXCEPTION
         WHEN OTHERS THEN
           gc_sqlerrm := SQLERRM;
	   UPDATE XX_PO_ITEM_SUPP_LOC_INT
              SET error_message='ASL Insert :'||gc_sqlerrm,
		  loc_process_flag=6,process_flag=7
            WHERE rowid=lt_asl_loc_tbl(i).lrowid;
       END;
     END LOOP;
  END IF;  	-- lt_asl_loc_tbl.COUNT <> 0 THEN
EXCEPTION
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_item_data - '||gc_sqlerrm;
    x_retcode := 2;
END process_asl_data;

-- +===================================================================+
-- | Name        :  Import_asl                                         |
-- | Description :  This procedure is called from the concurrent       |
-- |                Program OD PO ASL Import.                          |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE import_asl(
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
ln_asl_count		    PLS_INTEGER;
ln_loc_count		    PLS_INTEGER;
ln_asl_invalid              PLS_INTEGER;
ln_asl_failed               PLS_INTEGER;
ln_asl_processed            PLS_INTEGER;
ln_locations_invalid        PLS_INTEGER;
ln_locations_failed         PLS_INTEGER;
ln_locations_processed      PLS_INTEGER;
LN_ASL_TOTAL		    PLS_INTEGER;
LN_LOCATION_TOTAL	    PLS_INTEGER;
v_text 			    varchar2(32000);
v_subject 		    varchar2(100):='ASL Interface execution report : '||to_char(sysdate,'dd-mon-rr HH24:MI:SS');
-------------------------------------------------
--Cursor to get the Control Information for ASL
-------------------------------------------------
CURSOR lcu_master_info
IS
SELECT COUNT (CASE WHEN asl_process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN asl_process_flag ='6' THEN 1 END),
       COUNT (CASE WHEN asl_process_flag ='7' THEN 1 END)
FROM   XX_PO_ITEM_SUPP_int 
WHERE  load_batch_id=ln_seq;

-----------------------------------------------------
--Cursor to get the Control Information for Locations
-----------------------------------------------------
CURSOR lcu_location_info
IS
SELECT COUNT (CASE WHEN loc_process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN loc_process_flag ='6' THEN 1 END),
       COUNT (CASE WHEN loc_process_flag ='7' THEN 1 END)
FROM   XX_PO_ITEM_SUPP_loc_int
WHERE  load_batch_id=ln_seq;

CURSOR lcu_message
IS
select count(1) tot,'ItemSupp' etype,error_message
  from xxptp.xx_po_item_supp_int
 where load_batch_id=ln_seq
   and asl_process_flag<>7
 group by error_message
union
select count(1) tot,'ItemSuppLOC' etype,error_message
  from xxptp.xx_po_item_supp_loc_int
 where load_batch_id=ln_seq
   and loc_process_flag<>7 
 group by error_message;

BEGIN

    -----------------------------------------------------------
    --Calling xx_po_asl_extract to extract asl data from RMS
    -----------------------------------------------------------
        xx_po_asl_extract(  x_errbuf                  =>lx_errbuf
                           ,x_retcode                 =>lx_retcode
                          );
        IF lx_retcode <> 0 THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL
                 THEN x_errbuf  := lx_errbuf;
                 ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
        END IF;

    ------------------------------------------------------------
    --Updating Master table with load batch id and process flags
    ------------------------------------------------------------
    SELECT XX_PO_ITEM_SUPP_s.nextval
    INTO   ln_seq
    FROM   DUAL;

    ------------------------------------------------------------
    --Updating Master table with load batch id and process flags
    ------------------------------------------------------------
    UPDATE XX_PO_ITEM_SUPP_int
       SET load_batch_id=ln_seq
	  ,asl_process_flag = (CASE WHEN asl_process_flag IS NULL OR asl_process_flag = 1 THEN 2 ELSE asl_process_flag END)
    WHERE  process_flag=1
      AND  load_batch_id IS NULL;

    --Fetching Count of Eligible Records in the Master Table

    ln_asl_count := SQL%ROWCOUNT;
    COMMIT;


    UPDATE XX_PO_ITEM_SUPP_loc_int
       SET load_batch_id=ln_seq
	  ,loc_process_flag = (CASE WHEN loc_process_flag IS NULL OR loc_process_flag = 1 THEN 2 ELSE loc_process_flag END)
    WHERE  process_flag=1
      AND  load_batch_id IS NULL;

    --Fetching Count of Eligible Records in the Master Table

    ln_loc_count := SQL%ROWCOUNT;
    COMMIT;

    BEGIN

        display_out('*Batch_id* '||to_char(ln_seq));
        display_out('*Total ASL* '||to_char(ln_asl_count));
        display_out('*Total ASL Locations* '||to_char(ln_loc_count));        

       SELECT master_organization_id
         INTO G_MASTER_ORG_ID
         FROM mtl_parameters
        WHERE ROWNUM<2;

        -----------------------------------------------------------
        --Calling validate_item_data for SetUp and Data Validations
        -----------------------------------------------------------
        validate_item_data( x_errbuf                  =>lx_errbuf
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
        --Calling process_asl_data to process and insert into PO Base tables
        --------------------------------------------------------------------

        lx_errbuf     := NULL;
        lx_retcode    := NULL;

        process_asl_data(  x_errbuf     =>lx_errbuf
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

    OPEN lcu_master_info;
    FETCH lcu_master_info INTO ln_asl_invalid,ln_asl_failed,ln_asl_processed;
    CLOSE lcu_master_info;


    OPEN lcu_location_info;
    FETCH lcu_location_info INTO ln_locations_invalid,ln_locations_failed,ln_locations_processed;
    CLOSE lcu_location_info;

    UPDATE xx_po_item_supp_int
       SET process_flag=7
     WHERE load_batch_id=ln_seq;

    UPDATE xx_po_item_supp_loc_int
       SET process_flag=7
     WHERE load_batch_id=ln_seq;

    COMMIT;
    --------------------------------------------------
    --Displaying the ASL Information in the Out file
    --------------------------------------------------
    ln_asl_total := ln_asl_invalid+ ln_asl_failed + ln_asl_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of ASL Records       : ',49,' ')||RPAD(ln_asl_total,9,' '));
    display_out(RPAD('No. Of ASL  Records Processed  : ',49,' ')||RPAD(ln_asl_processed,9,' '));
    display_out(RPAD('No. Of ASL Records Errored     : ',49,' ')||RPAD(ln_asl_failed,9,' '));
    display_out(RPAD('No. Of ASL Records Failed Validation    : ',49,' ')||RPAD(ln_asl_invalid,9,' '));
    display_out(RPAD('=',58,'='));
    ------------------------------------------------------
    --Displaying the Locations Information in the Out file
    ------------------------------------------------------
    ln_location_total := ln_locations_invalid+ ln_locations_failed + ln_locations_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Location Records      : ',49,' ')||RPAD(ln_location_total,9,' '));
    display_out(RPAD('No. Of Location Records Processed  : ',49,' ')||RPAD(ln_locations_processed,9,' '));
    display_out(RPAD('No. Of Location Records Errored    : ',49,' ')||RPAD(ln_locations_failed,9,' '));
    display_out(RPAD('No. Of Location Records Failed Validation    : ',49,' ')||RPAD(ln_locations_invalid,9,' '));
    display_out(RPAD('=',58,'='));

    FOR cur IN lcu_message LOOP
        display_out(to_char(cur.tot)||', '||cur.etype||','||cur.error_message);
    END LOOP;
    display_out(RPAD('=',58,'='));

    v_text:=RPAD('=',58,'=')||chr(10);
    v_text:=v_text||RPAD('Total No. Of ASL Records       : ',49,' ')||RPAD(ln_asl_total,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of ASL  Records Processed  : ',49,' ')||RPAD(ln_asl_processed,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of ASL Records Errored     : ',49,' ')||RPAD(ln_asl_failed,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of ASL Records Failed Validation    : ',49,' ')||RPAD(ln_asl_invalid,9,' ')||chr(10);
    v_text:=v_text||RPAD('=',58,'=')||chr(10);
    ------------------------------------------------------
    --Displaying the Locations Information in the Out file
    ------------------------------------------------------

    v_text:=v_text||RPAD('=',58,'=')||chr(10);
    v_text:=v_text||RPAD('Total No. Of Location Records      : ',49,' ')||RPAD(ln_location_total,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of Location Records Processed  : ',49,' ')||RPAD(ln_locations_processed,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of Location Records Errored    : ',49,' ')||RPAD(ln_locations_failed,9,' ')||chr(10);
    v_text:=v_text||RPAD('No. Of Location Records Failed Validation    : ',49,' ')||RPAD(ln_locations_invalid,9,' ')||chr(10);
    v_text:=v_text||RPAD('=',58,'=')||chr(10);

    FOR cur IN lcu_message LOOP
        v_text:=v_text||to_char(cur.tot)||', '||cur.etype||','||cur.error_message||chr(10);
    END LOOP;
    v_text:=v_text||RPAD('=',58,'=')||chr(10);
    send_notification(v_subject,'IT_MerchEBS_Oncall@officedepot.com',v_text);

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
        x_retcode := 2;
END import_asl;
END XX_PO_ASL_CONV_PKG;
/
SHOW ERRORS

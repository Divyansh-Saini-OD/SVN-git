SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_WFL_POSCHORD_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXWFLPOSCHORDPKGB.pkb                                           |
-- | Rice Id     :  E0242 PO cancellation from ISP                                  |
-- | Description :  This script creates custom package body required for            |
-- |                PoCancellationFromIsp.                             		    |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks            	                    |
-- |=======   ==========  =============    ============================             |
-- |DRAFT 1A 09-FEB-2007  Niharika        Initial draft version                     |
-- |1.0      10-Mar-2007  Niharika           Baselined after testing 		    |	                                                            |
-- |                                                            		    |
-- +================================================================================+
AS
-- Declaration of global variable
gd_sysdate DATE := SYSDATE;

-- Procedure  Get_Posrc_Type_Proc  will derive value of  attribute_category from po_headers_all table 
-- and check  whether it exist in  custom  lookup code or not.


PROCEDURE GET_POSRC_TYPE_PROC( p_itemtype     IN  VARCHAR2
                             , p_itemkey      IN  VARCHAR2
                             , p_actid        IN  NUMBER
                             , p_funcmode     IN  VARCHAR2
                             , x_resultout    OUT VARCHAR2)

-- +================================================================================+
-- | Name        :  GET_POSRC_TYPE_PROC                                             |
-- | Description :  This  custom procedure to get value of                          |
-- |                attribute_category and to check whether it exist in custom      |
-- |                lookup code or not                                              |
-- +================================================================================+
AS
-- Declaration of local variables
    ln_po_header_id                NUMBER      := 0;
    lc_attribute_category          VARCHAR2(20):= NULL;
    lc_flag                        VARCHAR2(1) := NULL;
    lc_err_buff                    VARCHAR2(40);
    lc_ret_code                    VARCHAR2(10);
    lc_err_code                    xxom.xxod_global_exceptions_tbl.error_code%TYPE;
    lc_err_desc                    xxom.xxod_global_exceptions_tbl.description%TYPE;
    lc_entity_ref                  xxom.xxod_global_exceptions_tbl.entity_ref%TYPE;
    ln_entity_ref_id               xxom.xxod_global_exceptions_tbl.entity_ref_id%TYPE;
    err_report_type                xxod_report_exception;


    -- Declaration of cursors
    CURSOR    lcu_get_attr_cat(p_po_header_id IN NUMBER)
    IS
    SELECT    UPPER(attribute_category)
    FROM      apps.po_headers_all
    WHERE     po_header_id = p_po_header_id;

    CURSOR    lcu_get_lookup( p_attribute_category IN VARCHAR2)
    IS
    SELECT 'Y'
    FROM   apps.fnd_lookup_values
    WHERE  lookup_type ='OD_PO_CANCEL_ISP'
    AND    UPPER(meaning) = p_attribute_category
    AND  sysdate BETWEEN TO_DATE(TO_CHAR(NVL(start_date_active,sysdate),'DDMMYYYY')
                               ||'000000','DDMMYYYYHH24MISS')
                       AND     TO_DATE(TO_CHAR(NVL(end_date_active,sysdate),'DDMMYYYY')
                               ||'235959','DDMMYYYYHH24MISS')
    AND    language ='US'
    AND    enabled_flag='Y';


BEGIN
    ln_po_header_id:= Wf_Engine.GetItemAttrNumber(itemtype => p_itemtype
                                                 ,itemkey => p_itemkey
                                                 ,aname   => 'PO_HEADER_ID');
    lc_err_code := '010';

    -- Opening of the cursors and fetching value into local variables
    OPEN  lcu_get_attr_cat(ln_po_header_id);
    FETCH lcu_get_attr_cat INTO lc_attribute_category;
    CLOSE lcu_get_attr_cat;

    lc_err_code := '020';

    OPEN  lcu_get_lookup(lc_attribute_category);
    FETCH lcu_get_lookup INTO lc_flag ;
    CLOSE lcu_get_lookup;

    lc_err_code := '030';
    IF  lc_flag IS NOT NULL THEN
      x_resultout:= 'COMPLETE:'||'Y';
    ELSE
       x_resultout:= 'COMPLETE:'||'N';
    END IF;
EXCEPTION
WHEN OTHERS THEN
      x_resultout :='COMPLETE:'||'N';
      lc_err_desc := SQLERRM;
      lc_entity_ref := 'PO Header ID';
      ln_entity_ref_id := NVL(ln_po_header_id,0);
      err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                );
       --used to insert exception in xxod_global_exceptions_tbl table	
       xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );  

END GET_POSRC_TYPE_PROC;
----------------------------------------------------------------------------

PROCEDURE VALIDATE_POSTATUS_PROC( p_itemtype     IN  VARCHAR2
                             	, p_itemkey      IN  VARCHAR2
                             	, p_actid        IN  NUMBER
                             	, p_funcmode     IN  VARCHAR2
                             	, x_resultout    OUT VARCHAR2)


-- +================================================================================+
-- | Name        :  VALIDATE_POSTATUS_PROC                                          |
-- | Description :  This script creates custom procedure to check status of PO      |
-- |                whether it is cancelled or not. If it is cancelled then it will |
-- |                update table apps.po_change_requests with request_status        |
-- |                ='BUYER_APP'                                                    |
-- +================================================================================+
AS
-- Declaration of local variables
	 
   lc_action_type                 VARCHAR2(20):=null;
   ln_po_header_id                NUMBER      := 0;
   lc_err_buff                    VARCHAR2(40);
   lc_ret_code                    VARCHAR2(10);
   lc_err_code                    xxom.xxod_global_exceptions_tbl.error_code%TYPE;
   lc_err_desc                    xxom.xxod_global_exceptions_tbl.description%TYPE;
   lc_entity_ref                  xxom.xxod_global_exceptions_tbl.entity_ref%TYPE;
   ln_entity_ref_id               xxom.xxod_global_exceptions_tbl.entity_ref_id%TYPE;
   err_report_type                xxod_report_exception;

-- Declaration of cursor
   CURSOR   lcu_get_action_type 
   IS
   SELECT   action_type
   FROM     apps.po_change_requests
   WHERE    wf_item_key = p_itemkey;


BEGIN
    lc_err_code := '010';
   -- Fetch PO header id , to be used while capturing error in error handler pkg

   ln_po_header_id:= Wf_Engine.GetItemAttrNumber(itemtype => p_itemtype
                                                 ,itemkey => p_itemkey
                                                 ,aname   => 'PO_HEADER_ID');

   -- Opening the cursor and fetching value into local variable
   OPEN lcu_get_action_type ;
   FETCH lcu_get_action_type INTO lc_action_type;
   CLOSE lcu_get_action_type;

   lc_err_code := '020';
   IF lc_action_type ='CANCELLATION'  THEN 	
      -- If the status of PO is ‘Cancelled’, update  table apps.po_change_requests with request_status = 'BUYER_APP'
      lc_err_code := '030';
      UPDATE  apps.po_change_requests
      SET     request_status   = 'BUYER_APP',
              last_updated_by  = fnd_global.user_id,
              last_update_date = gd_sysdate
      WHERE   wf_item_key      = p_itemkey ;
        
      COMMIT;   
      x_resultout:= 'COMPLETE:'||'ACCEPT';
   ELSE
      x_resultout:= 'COMPLETE:'||'REJECT';
   END IF;



EXCEPTION
WHEN OTHERS THEN
     x_resultout :='COMPLETE:' ||'REJECT';
     lc_err_desc := SQLERRM;
     lc_entity_ref := 'PO Header ID';
     ln_entity_ref_id := NVL(ln_po_header_id,0);
     err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                );
       --used to insert exception in xxod_global_exceptions_tbl table	
       xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );  
END VALIDATE_POSTATUS_PROC;
-----------------------------------------------------------------------------
END XX_WFL_POSCHORD_PKG;
/
SHOW ERROR

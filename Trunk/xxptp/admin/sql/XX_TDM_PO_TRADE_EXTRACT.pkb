CREATE OR REPLACE PACKAGE BODY xx_tdm_po_trade_extract AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_TDM_PO_TRADE_EXTRACT                                                          |
  -- |  RICE ID   :  I3124 Trade PO to EBS Interface                                   			  |
  -- |  Description:  Extract Trade POs for TDM                                                   |
  -- |                                                                          				  |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08/16/2018   Phuoc Nguyen     Initial version                                  |
  -- +============================================================================================+

    PROCEDURE trade_po_extract (
        p_error_msg     OUT VARCHAR2,
        p_return_code   OUT VARCHAR2,
        p_file_dir      IN VARCHAR2,
        p_file_name     IN VARCHAR2,
        p_num_days      IN NUMBER
    ) IS
    
--Initialize Variables
        gn_user_id        fnd_concurrent_requests.requested_by%TYPE;
        gn_resp_id        fnd_responsibility.responsibility_id%TYPE;
        gn_resp_appl_id   fnd_responsibility.application_id%TYPE;
        v_file_handle     utl_file.file_type;
        v_file_line       VARCHAR2(200);
        v_file_dir        VARCHAR2(200) := p_file_dir;
        v_file_name       VARCHAR2(200) := p_file_name;
        indx              NUMBER;
        l_orgid           NUMBER := fnd_profile.value('ORG_ID');
        nodata 			  EXCEPTION;

-- cursor to collect all Open Trade POs
        CURSOR trade_po_extract 
        IS 
        SELECT
            poh.segment1,
            supa.vendor_site_code_alt,
            poh.attribute_category
        FROM
            po_headers_all poh,
            ap_supplier_sites_all supa
        WHERE
            1 = 1
            AND   poh.vendor_id = supa.vendor_id
            AND   poh.vendor_site_id = supa.vendor_site_id
            AND   nvl(poh.cancel_flag,'N') = 'N'
            AND   poh.attribute1 IN ('NA-POINTR','NA-POCONV')
            AND   poh.closed_code NOT IN ('CLOSED')
            AND   nvl(poh.status_lookup_code,'NA') != 'C'
            AND   poh.type_lookup_code NOT IN ('RFQ','QUOTATION')
            AND   poh.creation_date > (SYSDATE - p_num_days)
        ORDER BY
            poh.po_header_id DESC;

        TYPE tradeextract IS
            TABLE OF trade_po_extract%rowtype INDEX BY PLS_INTEGER;
        trade_po_tab      tradeextract;
    BEGIN
--Initalizing Setting Context
        fnd_client_info.set_org_context(l_orgid);
        fnd_request.set_org_id(l_orgid);
        fnd_profile.put('ORG_ID',l_orgid);
        gn_user_id := fnd_global.user_id;
        gn_resp_id := fnd_global.resp_id;
        gn_resp_appl_id := fnd_global.resp_appl_id;
        fnd_global.apps_initialize(gn_user_id,gn_resp_id,gn_resp_appl_id);
        mo_global.set_policy_context('S',l_orgid);
        mo_global.init('PO');
        
        OPEN trade_po_extract;
        FETCH trade_po_extract BULK COLLECT INTO trade_po_tab;
        CLOSE trade_po_extract;
                
        IF
            ( trade_po_tab.count >= 0 )
        THEN
            RAISE nodata;
        ELSE
            v_file_handle := utl_file.fopen(v_file_dir,v_file_name,'W');

-- Go through PO cursor
  --FOR indx IN trade_po_tab.first..trade_po_tab.last
            FOR indx IN 1..trade_po_tab.count LOOP
	--check for dropshipflag
                IF
                    ( trade_po_tab(indx).attribute_category IN ('DropShip NonCode-SPL Order','DropShip VW') )
                THEN
                    v_file_line := ( 'A'|| lpad(translate(trade_po_tab(indx).segment1,'-','0'),14,'0')|| lpad(ltrim(trade_po_tab(indx).vendor_site_code_alt,'0'),9,'0')|| 'Y' );
                ELSE
                    v_file_line := ( 'A'|| lpad(translate(trade_po_tab(indx).segment1,'-','0'),14,'0')|| lpad(ltrim(trade_po_tab(indx).vendor_site_code_alt,'0'),9,'0')|| 'N' );
                END IF;
                
                --Enter Line into file
                utl_file.put_line(v_file_handle,v_file_line);
            END LOOP;
  
            --Close Line
            utl_file.fclose(v_file_handle);
        END IF;

    EXCEPTION
        WHEN nodata THEN
            p_return_code := 2;
            p_error_msg := 'NO DATA FOUND :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.LOG, p_error_msg);
        WHEN utl_file.invalid_path THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'Invalid UTL file path: '
            || sqlerrm;
            fnd_file.put_line(fnd_file.LOG, p_error_msg);
        WHEN utl_file.write_error THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'UTL write error :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.LOG, p_error_msg);
        WHEN OTHERS THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'Error while Extracting Trade POs for TDM :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.LOG, p_error_msg);
    END;
--END trade_po_extract;

END xx_tdm_po_trade_extract;
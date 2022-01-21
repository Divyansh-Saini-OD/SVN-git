create or replace PACKAGE BODY  XXPOX_POSMH_INVOKE_PKG AS
-- +========================================================================================+
-- |                           Office Depot - Project Simplify                          	|
-- +========================================================================================+
-- |Package Name : XXPOX_POSMH_INVOKE_PKG                                  		    		|
-- |Purpose      : This package contains the functions required                				|
-- |               to get the values in XXPOXPOSMH_XML and  							    |
-- |			   and call XML Bursting.                   		                		|
-- |                                                                           				|
-- |                                                                           				|
-- |Change History                                                             				|
-- |                                                                          				|
-- |Ver   Date          Author                     Description                        		|
-- |---   -----------   -----------------          ------------------------------------		|
-- |1.0   19-OCT-2017  Jimmy "JimGymGem" Nguyen    For Defect 43410. Tis package is to call |
-- |                                               XXPOXPOSMH_XML and then trigger          |
-- |                                               XML bursting in XXPOXPOSMHBURST.			|
-- |                                                        								|
-- +========================================================================================+
    PROCEDURE invoke_xml_request (
        errorbuff             OUT VARCHAR2,
        retcode               OUT VARCHAR2,
        p_title               IN VARCHAR2,
        p_buyer_name          IN VARCHAR2,
        p_vendor_from         IN VARCHAR2,
        p_vendor_to           IN VARCHAR2,
        p_invoice_date_from   IN VARCHAR2,
        p_invoice_date_to     IN VARCHAR2,
        p_struct_num          IN VARCHAR2,
        p_category_from       IN VARCHAR2,
        p_category_to         IN VARCHAR2,
        p_item_from           IN VARCHAR2,
        p_item_to             IN VARCHAR2,
        p_price_hold          IN VARCHAR2,
        p_qty_ord_hold        IN VARCHAR2,
        p_qty_rec_hold        IN VARCHAR2,
        p_quality_hold        IN VARCHAR2,
        p_qty_precision       IN NUMBER,
        debugflag             IN VARCHAR2
    ) IS

        lc_phase              VARCHAR2(50);
        lc_status             VARCHAR2(50);
        lc_dev_phase          VARCHAR2(50);
        lc_dev_status         VARCHAR2(50);
        lc_message            VARCHAR2(50);
        l_req_return_status   BOOLEAN;
        l_orgid               NUMBER := fnd_profile.value('ORG_ID');
        l_layout              BOOLEAN;
    BEGIN	
		--Setting Context
        fnd_client_info.set_org_context(l_orgid);
        fnd_request.set_org_id(l_orgid);
        fnd_profile.put('ORG_ID',l_orgid);
		
        MO_GLOBAL.set_policy_context('S',l_orgid);
        MO_GLOBAL.INIT('PO');

        -- Load Template
        l_layout := fnd_request.add_layout(
        template_appl_name => 'XXFIN',
        template_code => 'XXPOXPOSMH_XML',
        template_language => 'en',
        template_territory => 'US',
        output_format => 'PDF'
        );	
		
        lb_boolean := fnd_request.set_print_options (
        printer => 'XPTR', 
        style => NULL, 
        copies => 1, 
        save_output => TRUE, 
        print_together => 'N');

		-- Call OD: Matching Holds by Buyer Report
		
        l_req_id := fnd_request.submit_request(
        application => 'XXFIN',
        program => 'XXPOXPOSMH_XML',
        description => '',
        start_time => '',
        sub_request => false,
        argument1 => p_title,
        argument2 => p_buyer_name,
        argument3 => p_vendor_from,
        argument4 => p_vendor_to,
        argument5 => p_invoice_date_from,
        argument6 => p_invoice_date_to,
        argument7 => p_struct_num,
        argument8 => p_category_from,
        argument9 => p_category_to,
        argument10 => p_item_from,
        argument11 => p_item_to,
        argument12 => p_price_hold,
        argument13 => p_qty_ord_hold,
        argument14 => p_qty_rec_hold,
        argument15 => p_quality_hold,
        argument16 => p_qty_precision,
        argument17 => debugflag
        );

        COMMIT;
        IF
            l_req_id > 0
        THEN
            LOOP
                l_req_return_status := fnd_concurrent.wait_for_request(
                request_id => l_req_id,
                INTERVAL => 5,
                max_wait => 60,
                phase => lc_phase,
                status => lc_status,
                dev_phase => lc_dev_phase,
                dev_status => lc_dev_status,
                message => lc_message
                );

                EXIT WHEN upper(lc_phase) = 'COMPLETED' OR upper(lc_status) IN (
                    'CANCELLED',
                    'ERROR',
                    'TERMINATED'
                );

            END LOOP;

            IF
                upper(lc_phase) = 'COMPLETED' AND upper(lc_status) = 'NORMAL'
            THEN
                BEGIN
						-- Call XML bursting if job 1 clears
                    p_req_id := fnd_request.submit_request(
                    application => 'XDO',
                    program => 'XDOBURSTREP',
                    description => '',
                    start_time => '',
                    sub_request => false,
                    argument1 => 'Y',
                    argument2 => l_req_id,
                    argument3 => 'Y'
                    );
                    COMMIT;          
                END;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'OTHERS exception while submitting XML Bursting: '
            || sqlerrm);
            end;
    END xxpox_posmh_invoke_pkg;
	/
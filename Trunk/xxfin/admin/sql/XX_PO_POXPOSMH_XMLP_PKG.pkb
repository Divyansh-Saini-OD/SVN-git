create or replace PACKAGE BODY xx_po_poxposmh_xmlp_pkg AS

    FUNCTION beforereport RETURN BOOLEAN
    IS
    ln_responsibility_id      fnd_responsibility_tl.responsibility_id%TYPE 	:= fnd_profile.VALUE('RESP_ID');
    ln_user_id                fnd_user.user_id%TYPE 							:= fnd_profile.VALUE('USER_ID');
    ln_application_id         fnd_responsibility_tl.application_id%TYPE 		:= fnd_profile.VALUE('RESP_APPL_ID');	
   
    BEGIN
    	l_orgid := FND_PROFILE.VALUE('ORG_ID');
        MO_GLOBAL.set_policy_context('S', 404);
        MO_GLOBAL.INIT('PO');
        fnd_file.put_line(fnd_file.log,'ORG_ID =' || l_orgid);
        
        --Find request ID
        SELECT fnd_global.conc_request_id INTO v_request_id
        FROM apps.fnd_user, v$instance
        WHERE user_id = fnd_global.user_id;
				
--	Set Context
--        fnd_global.apps_initialize(
--        user_id => ln_user_id,
--        resp_id => ln_responsibility_id,
--        resp_appl_id => ln_application_id);
--        
        fnd_file.put_line(fnd_file.log,
        'USER_ID =' || ln_user_id || 
        ' RESP_ID =' || ln_responsibility_id || 
        ' RESP_APPL_ID =' || ln_application_id);
    
    	--Load Template
        l_layout := fnd_request.add_layout(
        template_appl_name => 'XXFIN',
        template_code => 'XXPOXPOSMH_XML',
        template_language => 'en',
        template_territory => 'US',
        output_format => 'EXCEL');
        
        BEGIN
--           SRW.USER_EXIT('FND SRWINIT');
            NULL;
            IF
                ( get_p_struct_num <> true )
            THEN /*SRW.MESSAGE('1','INIT FAILED');*/
                NULL;
            END IF;
            format_mask := po_common_xmlp_pkg.get_precision(p_qty_precision);
            NULL;
            NULL;
            NULL;
            NULL;
            RETURN true;
        END;
        return(true);
    END;

    FUNCTION afterreport RETURN BOOLEAN
        IS
--Defect 43410
    BEGIN

	--Put Request ID in Log
        fnd_file.put_line(fnd_file.log,'v_request_id =' || v_request_id);
	
	--Submit XML Bursting 
        v_sub_req := fnd_request.submit_request(
        application => 'XDO',
        program => 'XDOBURSTREP',
        description => '',
        start_time => '',
        argument1 => 'N',
        argument2 => v_request_id,
        argument3 => 'Y');

        IF
            v_sub_req <= 0
        THEN
            fnd_file.put_line(fnd_file.log,'Failed to submit Bursting XML Publisher Request');
            NULL;
            return(false);
        ELSE
            COMMIT;
            fnd_file.put_line(fnd_file.log,'XDOBURSTREP :'
            || lc_status);
            fnd_file.put_line(fnd_file.log,'XDOBURSTREP :'
            || lc_phase);
            return(true);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'ORA exception occurred while '
            || 'executing the XDO Program - '
            || sqlerrm);
            return(false);
--/*SRW.USER_EXIT('FND SRWINIT');*/null;

    END;

    PROCEDURE get_precision
        IS
    BEGIN
/*srw.attr.mask        :=  SRW.FORMATMASK_ATTR;*/
        NULL;
        IF
            p_qty_precision = 0
        THEN /*srw.attr.formatmask  := '-NNN,NNN,NNN,NN0';*/
            NULL;
        ELSE
            IF
                p_qty_precision = 1
            THEN /*srw.attr.formatmask  := '-NNN,NNN,NNN,NN0.0';*/
                NULL;
            ELSE
                IF
                    p_qty_precision = 3
                THEN /*srw.attr.formatmask  :=  '-NN,NNN,NNN,NN0.000';*/
                    NULL;
                ELSE
                    IF
                        p_qty_precision = 4
                    THEN /*srw.attr.formatmask  :=   '-N,NNN,NNN,NN0.0000';*/
                        NULL;
                    ELSE
                        IF
                            p_qty_precision = 5
                        THEN /*srw.attr.formatmask  :=     '-NNN,NNN,NN0.00000';*/
                            NULL;
                        ELSE
                            IF
                                p_qty_precision = 6
                            THEN /*srw.attr.formatmask  :=      '-NN,NNN,NN0.000000';*/
                                NULL;
                            ELSE /*srw.attr.formatmask  :=  '-NNN,NNN,NNN,NN0.00';*/
                                NULL;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
/*srw.set_attr(0,srw.attr);*/

        NULL;
    END;

    FUNCTION get_p_struct_num RETURN BOOLEAN IS
        l_p_struct_num   NUMBER;
    BEGIN
        SELECT
            structure_id
        INTO
            l_p_struct_num
        FROM
            mtl_default_sets_view
        WHERE
            functional_area_id = 2;

        p_struct_num := l_p_struct_num;
        return(true);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            return(false);
    END;

    FUNCTION c_report_avg_no_of_daysformula (
        c_report_tot_days_hold   IN NUMBER,
        c_report_number_total    IN NUMBER
    ) RETURN NUMBER
        IS
    BEGIN
        IF
            ( c_report_number_total = 0 )
        THEN
            return(0);
        ELSE
            return(c_report_tot_days_hold / c_report_number_total);
        END IF;
    END;

    FUNCTION c_total_days_holdingformula (
        average             IN NUMBER,
        number_amount_tot   IN NUMBER
    ) RETURN NUMBER
        IS
    BEGIN
        return(average * number_amount_tot);
    END;

    FUNCTION c_unit_price_round (
        unit_price                  IN VARCHAR2,
        parent_currency_precision   IN NUMBER
    ) RETURN NUMBER
        IS
    BEGIN

  /*srw.reference(unit_price);*/
        NULL;

  /*srw.reference(parent_currency_precision);*/
        NULL;
        return(round(unit_price,parent_currency_precision) );
    END;

    FUNCTION c_invoice_price_round (
        invoice_price               IN NUMBER,
        parent_currency_precision   IN NUMBER
    ) RETURN NUMBER
        IS
    BEGIN

  /*srw.reference(invoice_price);*/
        NULL;

  /*srw.reference(Parent_currency_precision);*/
        NULL;
        return(round(invoice_price,parent_currency_precision) );
    END;

--Functions to refer Oracle report placeholders--

END xx_po_poxposmh_xmlp_pkg;
/
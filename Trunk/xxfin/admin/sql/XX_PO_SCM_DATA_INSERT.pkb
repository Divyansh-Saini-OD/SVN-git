CREATE OR REPLACE PACKAGE BODY xx_po_scm_data_insert AS

  -- +============================================================================================      +
  -- |  Office Depot                                                                                    |
  -- |                                                                                                  |
  -- +============================================================================================      +
  -- |  Name  :  xx_po_scm_data_insert                                                            	    | 
  -- |  RICE ID   :  I2193_PO to EBS Interface                                   				        | 
  -- |  Description:  Load PO Interface Data from file to Staging Tables                                |
  -- |                                                                          				        | 
  -- |                          																        | 
  -- +============================================================================================      +
  -- | Version     Date         Author           Remarks                                                |
  -- | =========   ===========  =============    =================================================      |
  -- | 1.0         04/10/2017   Phuoc Nguyen     Initial version                                        |
  -- +============================================================================================      +

    PROCEDURE load_scm_data (
        p_scm_header_data   IN OUT NOCOPY xx_po_scm_hdr_obj,
        p_scm_line_data     IN OUT NOCOPY xx_po_scm_lines_tab,
        p_return_code       OUT VARCHAR2,
        p_return_msg        OUT VARCHAR2
    ) IS
        ln_header_count   NUMBER := 0;
        ln_line_count     NUMBER := 0;
        --ln_total_line_count   NUMBER := 0;
    BEGIN
        BEGIN
            SELECT po_headers_interface_s.NEXTVAL
            INTO p_scm_header_data.record_id
            FROM dual;
            
            --Check for canceled process code of D if not put I

            IF
				p_scm_header_data.process_code IS NULL
            THEN 
				p_scm_header_data.process_code := 'I';
            END IF;
			
            --Check for null divide error
            IF
                p_scm_header_data.disc_pct IS NOT NULL
            THEN
                p_scm_header_data.disc_pct := (p_scm_header_data.disc_pct / 100);
            ELSE
                p_scm_header_data.disc_pct := p_scm_header_data.disc_pct;
            END IF;   

            --p_scm_header_data.process_code := 'I';
            p_scm_header_data.record_status := ''; -- Hardcoded in XX_PO_POM_INT_PKG
            p_scm_header_data.error_description := ''; -- Hardcoded in XX_PO_POM_INT_PKG
			p_scm_header_data.fob_code := '';
			p_scm_header_data.freight_code := '';
            p_scm_header_data.request_id := '';
            p_scm_header_data.created_by := '';
			p_scm_header_data.date_entered := SYSDATE;
            p_scm_header_data.creation_date := SYSDATE;
            --p_scm_header_data.disc_pct := nvl( (p_scm_header_data.disc_pct / 100),p_scm_header_data.disc_pct);
            p_scm_header_data.last_updated_by := '';
            p_scm_header_data.last_update_date := SYSDATE;
            p_scm_header_data.last_update_login := '';
            p_scm_header_data.attribute2 := 'NEW'; -- Used for report_master_program_stats to report for latest records
            p_scm_header_data.attribute3 := 'SCM';
			
            INSERT INTO xx_po_pom_hdr_int_stg (
                record_id,
                process_code,
                po_number,
                currency_code,
                vendor_site_code,
                loc_id,
                fob_code,
                freight_code,
                note_to_vendor,
                note_to_receiver,
                status_code,
                import_manual_po,
                date_entered,
                date_changed,
                rate_type,
                distribution_code,
                po_type,
                num_lines,
                cost,
                units_ord_rec_shpd,
                lbs,
                net_po_total_cost,
                drop_ship_flag,
                ship_via,
                back_orders,
                order_dt,
                ship_dt,
                arrival_dt,
                cancel_dt,
                release_date,
                revision_flag,
                last_ship_dt,
                last_receipt_dt,
                disc_pct,
                disc_days,
                net_days,
                allowance_basis,
                allowance_dollars,
                allowance_percent,
                pom_created_by,
                time_entered,
                program_entered_by,
                pom_changed_by,
                changed_time,
                program_changed_by,
                cust_id,
                cust_order_nbr,
                vendor_doc_num,
                cust_order_sub_nbr,
                batch_id,
                record_status,
                error_description,
                request_id,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute_category,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                error_column,
                error_value
            ) VALUES (
                p_scm_header_data.record_id,
                p_scm_header_data.process_code,
                p_scm_header_data.po_number,
                p_scm_header_data.currency_code,
                p_scm_header_data.vendor_site_code,
                p_scm_header_data.loc_id,
                p_scm_header_data.fob_code,
                p_scm_header_data.freight_code,
                p_scm_header_data.note_to_vendor,
                p_scm_header_data.note_to_receiver,
                p_scm_header_data.status_code,
                p_scm_header_data.import_manual_po,
                p_scm_header_data.date_entered,
                p_scm_header_data.date_changed,
                p_scm_header_data.rate_type,
                p_scm_header_data.distribution_code,
                p_scm_header_data.po_type,
                p_scm_header_data.num_lines,
                p_scm_header_data.cost,
                p_scm_header_data.units_ord_rec_shpd,
                p_scm_header_data.lbs,
                p_scm_header_data.net_po_total_cost,
                p_scm_header_data.drop_ship_flag,
                p_scm_header_data.ship_via,
                p_scm_header_data.back_orders,
                p_scm_header_data.order_dt,
                p_scm_header_data.ship_dt,
                p_scm_header_data.arrival_dt,
                p_scm_header_data.cancel_dt,
                p_scm_header_data.release_date,
                p_scm_header_data.revision_flag,
                p_scm_header_data.last_ship_dt,
                p_scm_header_data.last_receipt_dt,
                p_scm_header_data.disc_pct,
                p_scm_header_data.disc_days,
                p_scm_header_data.net_days,
                p_scm_header_data.allowance_basis,
                p_scm_header_data.allowance_dollars,
                p_scm_header_data.allowance_percent,
                p_scm_header_data.pom_created_by,
                p_scm_header_data.time_entered,
                p_scm_header_data.program_entered_by,
                p_scm_header_data.pom_changed_by,
                p_scm_header_data.changed_time,
                p_scm_header_data.program_changed_by,
                p_scm_header_data.cust_id,
                p_scm_header_data.cust_order_nbr,
                p_scm_header_data.vendor_doc_num,
                p_scm_header_data.cust_order_sub_nbr,
                p_scm_header_data.batch_id,
                p_scm_header_data.record_status,
                p_scm_header_data.error_description,
                p_scm_header_data.request_id,
                p_scm_header_data.attribute1,
                p_scm_header_data.attribute2,
                p_scm_header_data.attribute3,
                p_scm_header_data.attribute4,
                p_scm_header_data.attribute5,
                p_scm_header_data.attribute_category,
                p_scm_header_data.created_by,
                p_scm_header_data.creation_date,
                p_scm_header_data.last_updated_by,
                p_scm_header_data.last_update_date,
                p_scm_header_data.last_update_login,
                p_scm_header_data.error_column,
                p_scm_header_data.error_value
            );

            ln_header_count := ln_header_count + SQL%rowcount;
            IF
			-- Check if there are any lines for insert/update don't enter lines for delete
                (p_scm_line_data.count > 0 AND p_scm_header_data.process_code IN ('U','I')) 
            THEN
				-- line loop
                FOR i IN p_scm_line_data.first..p_scm_line_data.last LOOP
            
            -- sync with std interface xx_po_pom_headers_int_stg_s.NEXTVAL
                    SELECT
                        po_lines_interface_s.NEXTVAL
                    INTO
                        p_scm_line_data(i).record_line_id
                    FROM
                        dual;
                    
                    --Check for canceled lines, if not canceled insert     

                    /* 
					IF
                        p_scm_line_data(i).process_code IS NULL
                    THEN
                        p_scm_line_data(i).process_code := 'I';
                    END IF;
					*/ 
                    
                    p_scm_line_data(i).process_code := 'I';
                    p_scm_line_data(i).record_status := '';
                    p_scm_line_data(i).error_description := '';
                    p_scm_line_data(i).request_id := '';
                    p_scm_line_data(i).created_by := '';
                    p_scm_line_data(i).creation_date := SYSDATE;
                    p_scm_line_data(i).last_updated_by := '';
                    p_scm_line_data(i).last_update_date := SYSDATE;
                    p_scm_line_data(i).last_update_login := '';
                    p_scm_line_data(i).attribute2 := ''; --only need NEW in header
                    p_scm_line_data(i).attribute3 := 'SCM';
                    INSERT INTO xx_po_pom_lines_int_stg (
                        record_line_id,
                        record_id,
                        process_code,
                        po_number,
                        line_num,
                        item,
                        quantity,
                        ship_to_location,
                        need_by_date,
                        promised_date,
                        line_reference_num,
                        uom_code,
                        unit_price,
                        shipmentnumber,
                        dept,
                        class,
                        vendor_product_code,
                        extended_cost,
                        qty_shipped,
                        qty_received,
                        seasonal_large_order,
                        batch_id,
                        record_status,
                        error_description,
                        request_id,
                        attribute1,
                        attribute2,
                        attribute3,
                        attribute4,
                        attribute5,
                        attribute_category,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        last_update_login,
                        error_column,
                        error_value
                    ) VALUES (
                        p_scm_line_data(i).record_line_id,
                        p_scm_header_data.record_id,
                        p_scm_line_data(i).process_code,
                        p_scm_header_data.po_number,
                        p_scm_line_data(i).line_num,
                        p_scm_line_data(i).item,
                        p_scm_line_data(i).quantity,
                        p_scm_line_data(i).ship_to_location,
                        p_scm_line_data(i).need_by_date,
                        p_scm_line_data(i).promised_date,
                        p_scm_line_data(i).line_reference_num,
                        p_scm_line_data(i).uom_code,
                        p_scm_line_data(i).unit_price,
                        p_scm_line_data(i).shipmentnumber,
                        p_scm_line_data(i).dept,
                        p_scm_line_data(i).class,
                        p_scm_line_data(i).vendor_product_code,
                        p_scm_line_data(i).extended_cost,
                        p_scm_line_data(i).qty_shipped,
                        p_scm_line_data(i).qty_received,
                        p_scm_line_data(i).seasonal_large_order,
                        p_scm_line_data(i).batch_id,
                        p_scm_line_data(i).record_status,
                        p_scm_line_data(i).error_description,
                        p_scm_line_data(i).request_id,
                        p_scm_line_data(i).attribute1,
                        p_scm_line_data(i).attribute2,
                        p_scm_line_data(i).attribute3,
                        p_scm_line_data(i).attribute4,
                        p_scm_line_data(i).attribute5,
                        p_scm_line_data(i).attribute_category,
                        p_scm_line_data(i).created_by,
                        p_scm_line_data(i).creation_date,
                        p_scm_line_data(i).last_updated_by,
                        p_scm_line_data(i).last_update_date,
                        p_scm_line_data(i).last_update_login,
                        p_scm_line_data(i).error_column,
                        p_scm_line_data(i).error_value
                    );

                    ln_line_count := ln_line_count + SQL%rowcount;
                END LOOP;
            END IF;
            
        --Updates for Header if needed due to line values
        --UPDATE xx_po_pom_hdr_int_stg
        --SET num_lines = ln_line_count;

        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                p_return_code := 'ERROR';
                p_return_msg := 'Error while processing the PO :'
                || p_scm_header_data.po_number
                || sqlerrm;
                dbms_output.put_line(p_return_msg);
        END;

        dbms_output.put_line(' Number of Header Records inserted :'
        || ln_header_count);
        dbms_output.put_line(' Number of Line Records inserted :'
        || ln_line_count);
        IF
            ln_header_count > 0
        THEN
            p_return_code := 'SUCCESS';
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_return_code := 'ERROR';
            p_return_msg := 'Error while processing the PO :'
            || sqlerrm;
            dbms_output.put_line(p_return_msg);
    END load_scm_data;

END xx_po_scm_data_insert;
/
SHOW ERRORS;
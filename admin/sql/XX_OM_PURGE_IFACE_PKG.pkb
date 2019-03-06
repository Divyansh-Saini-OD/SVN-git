SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_purge_iface_pkg
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Office Depot                                         |
-- +=====================================================================+
-- | Name  : XX_OM_PURGE_IFACE_PKG (XXOMSPURGB.pkb)                      |
-- | Description  : This package contains procedure that will purge data |
-- | from custom interface tables that out of the box import program     |
-- | doesn't purge.                                                      |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |1.0        05-MAY-2007   Manish Chavan    Initial version            |
-- |                                                                     |
-- |2.0        27-MAR-2014  Edson Morales    Updates per Defect 29155    |
-- +=====================================================================+
    PROCEDURE purge_data(
        errbuf         OUT NOCOPY     VARCHAR2,
        retcode        OUT NOCOPY     NUMBER,
        p_purge_iface  IN             VARCHAR2,
        p_purge_tran   IN             VARCHAR2)
    IS
        ln_count  NUMBER := 0;
    BEGIN
        IF p_purge_iface = 'Y'
        THEN
            -- Delete data from oe_payments_iface_all. This is the data that HVOP doesn't
            -- clear on success.
            BEGIN
                DELETE FROM oe_payments_iface_all pi
                WHERE       NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_headers_iface_all hi
                                WHERE  hi.orig_sys_document_ref = REPLACE(pi.orig_sys_document_ref, '-BYPASS')
                                AND    hi.order_source_id = pi.order_source_id)
                AND         NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_order_headers_all oh
                                WHERE  flow_status_code <> 'CLOSED'
                                AND    oh.orig_sys_document_ref = REPLACE(pi.orig_sys_document_ref, '-BYPASS')
                                AND    oh.order_source_id = pi.order_source_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of payments iface lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from oe_payments_iface_all');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;

            -- Delete data from XX_OM_HEADERS_ATTR_IFACE_ALL. This is the data that HVOP or SOI
            -- doesn't clear on success.
            BEGIN
                DELETE FROM xx_om_headers_attr_iface_all hai
                WHERE       NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_headers_iface_all hi
                                WHERE  hi.orig_sys_document_ref = hai.orig_sys_document_ref
                                AND    hi.order_source_id = hai.order_source_id)
                AND         NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_order_headers_all oh
                                WHERE  flow_status_code <> 'CLOSED'
                                AND    oh.orig_sys_document_ref = hai.orig_sys_document_ref
                                AND    oh.order_source_id = hai.order_source_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of header attr iface lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from XX_OM_HEADERS_ATTR_IFACE_ALL');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;

            -- Delete data from XX_OM_LINES_ATTR_IFACE_ALL. This is the data that HVOP or SOI
            -- doesn't clear on success.
            BEGIN
                DELETE FROM xx_om_lines_attr_iface_all lai
                WHERE       NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_headers_iface_all hi
                                WHERE  hi.orig_sys_document_ref = lai.orig_sys_document_ref
                                AND    hi.order_source_id = lai.order_source_id)
                AND         NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_order_headers_all oh
                                WHERE  flow_status_code <> 'CLOSED'
                                AND    oh.orig_sys_document_ref = lai.orig_sys_document_ref
                                AND    oh.order_source_id = lai.order_source_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of lines attr iface lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from XX_OM_LINES_ATTR_IFACE_ALL');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;

            -- Delete data from XX_OM_RET_TENDERS_IFACE_ALL. This is the data that SOI
            -- doesn't clear on success.
            BEGIN
                DELETE FROM xx_om_ret_tenders_iface_all rti
                WHERE       NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_headers_iface_all hi
                                WHERE  hi.orig_sys_document_ref = rti.orig_sys_document_ref
                                AND    hi.order_source_id = rti.order_source_id)
                AND         NOT EXISTS(
                                SELECT orig_sys_document_ref
                                FROM   oe_order_headers_all oh
                                WHERE  flow_status_code <> 'CLOSED'
                                AND    oh.orig_sys_document_ref = rti.orig_sys_document_ref
                                AND    oh.order_source_id = rti.order_source_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of return tender iface lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from XX_OM_RET_TENDERS_IFACE_ALL');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;
        END IF;   -- IFACE DATA ONLY

        IF p_purge_tran = 'Y'
        THEN
            -- Delete data from xx_om_return_tenders_all where order has already been purged
            BEGIN
                DELETE FROM xx_om_return_tenders_all rti
                WHERE       NOT EXISTS(SELECT header_id
                                       FROM   oe_order_headers_all hi
                                       WHERE  hi.header_id = rti.header_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of return tenders alllines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from xx_om_return_tenders_all');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;

            -- Delete data from xx_om_line_attributes_all where order has already been purged
            BEGIN
                DELETE FROM xx_om_line_attributes_all rti
                WHERE       NOT EXISTS(SELECT line_id
                                       FROM   oe_order_lines_all li
                                       WHERE  li.line_id = rti.line_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of lines attributes all lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from xx_om_line_attributes_all');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;

            -- Delete data from xx_om_header_attributes_all where order has already been purged
            BEGIN
                DELETE FROM xx_om_header_attributes_all rti
                WHERE       NOT EXISTS(SELECT header_id
                                       FROM   oe_order_headers_all hi
                                       WHERE  hi.header_id = rti.header_id);

                fnd_file.put_line(fnd_file.output,
                                     'Total number of header attributes all lines purged::'
                                  || SQL%ROWCOUNT);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.output,
                                      'Failed to delete data from xx_om_header_attributes_all');
                    errbuf :=    errbuf
                              || SUBSTR(SQLERRM,
                                        1,
                                        80);
            END;

            -- Issue Commit
            COMMIT;
        END IF;   -- Only Transaction Table

        fnd_file.put_line(fnd_file.LOG,
                          'Successfully Purged the data from Interface Tables');
        retcode := 0;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            fnd_file.put_line(fnd_file.output,
                              'Failure in Iface Purge Data');
            fnd_file.put_line(fnd_file.output,
                              SUBSTR(SQLERRM,
                                     1,
                                     80) );
            errbuf :=    errbuf
                      || SUBSTR(SQLERRM,
                                1,
                                80);
            retcode := -1;
    END purge_data;
END xx_om_purge_iface_pkg;
/

SHOW ERRORS PACKAGE BODY XX_OM_PURGE_IFACE_PKG;
EXIT;
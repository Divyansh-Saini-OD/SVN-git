CREATE OR REPLACE
package body XX_OM_PURGE_IFACE_PKG as
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
-- +=====================================================================+

PROCEDURE Purge_Data(
    errbuf     OUT NOCOPY VARCHAR2
 ,  retcode    OUT NOCOPY NUMBER
)
IS
BEGIN

   -- Delete data from oe_payments_iface_all. This is the data that HVOP doesn't
   -- clear on success.
   BEGIN
       DELETE from oe_payments_iface_all pi
       WHERE NOT EXISTS ( SELECT orig_sys_document_ref
                      FROM oe_headers_iface_all hi
                      WHERE hi.orig_sys_document_ref = pi.orig_sys_document_ref
                      AND hi.request_id = pi.request_id
                      AND hi.order_source_id = pi.order_source_id
                      AND hi.org_id = pi.org_id
                      AND nvl(hi.error_flag,'N') = 'N');
   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(FND_FILE.OUTPUT,'Failed to delete data from oe_payments_iface_all');
       errbuf  := errbuf || substr(SQLERRM,1,80);
   END;

   -- Issue Commit
   commit;

   -- Delete data from XX_OM_HEADERS_ATTR_IFACE_ALL. This is the data that HVOP or SOI
   -- doesn't clear on success.
   BEGIN
       DELETE from XX_OM_HEADERS_ATTR_IFACE_ALL hai
       WHERE NOT EXISTS ( SELECT orig_sys_document_ref
                      FROM oe_headers_iface_all hi
                      WHERE hi.orig_sys_document_ref = hai.orig_sys_document_ref
                      AND hi.request_id = hai.request_id
                      AND hi.order_source_id = hai.order_source_id
                      AND hi.org_id = hai.org_id
                      AND nvl(hi.error_flag,'N') = 'N');
   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(FND_FILE.OUTPUT,'Failed to delete data from XX_OM_HEADERS_ATTR_IFACE_ALL');
       errbuf  := errbuf || substr(SQLERRM,1,80);
   END;

   -- Issue Commit
   commit;

   -- Delete data from XX_OM_LINES_ATTR_IFACE_ALL. This is the data that HVOP or SOI
   -- doesn't clear on success.
   BEGIN
       DELETE from XX_OM_LINES_ATTR_IFACE_ALL lai
       WHERE NOT EXISTS ( SELECT orig_sys_document_ref
                      FROM oe_headers_iface_all hi
                      WHERE hi.orig_sys_document_ref = lai.orig_sys_document_ref
                      AND hi.request_id = lai.request_id
                      AND hi.order_source_id = lai.order_source_id
                      AND hi.org_id = lai.org_id
                      AND nvl(hi.error_flag,'N') = 'N');

   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(FND_FILE.OUTPUT,'Failed to delete data from XX_OM_LINES_ATTR_IFACE_ALL');
       errbuf  := errbuf || substr(SQLERRM,1,80);
   END;

   -- Issue Commit
   commit;

   -- Delete data from XX_OM_RET_TENDERS_IFACE_ALL. This is the data that SOI
   -- doesn't clear on success.
   BEGIN

       DELETE from XX_OM_RET_TENDERS_IFACE_ALL rti
       WHERE NOT EXISTS ( SELECT orig_sys_document_ref
                      FROM oe_headers_iface_all hi
                      WHERE hi.orig_sys_document_ref = rti.orig_sys_document_ref
                      AND hi.request_id = rti.request_id
                      AND hi.order_source_id = rti.order_source_id
                      AND hi.org_id = rti.org_id
                      AND nvl(hi.error_flag,'N') = 'N');
   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(FND_FILE.OUTPUT,'Failed to delete data from XX_OM_RET_TENDERS_IFACE_ALL');
       errbuf  := errbuf || substr(SQLERRM,1,80);
   END;

   -- Issue Commit
   commit;

   -- Delete data from OE_CREDITS_IFACE_ALL. This is the data that SOI
   -- doesn't clear on success.
   BEGIN

       DELETE from OE_CREDITS_IFACE_ALL rti
       WHERE NOT EXISTS ( SELECT orig_sys_document_ref
                      FROM oe_headers_iface_all hi
                      WHERE hi.orig_sys_document_ref = rti.orig_sys_document_ref
                      AND hi.request_id = rti.request_id
                      AND hi.order_source_id = rti.order_source_id
                      AND hi.org_id = rti.org_id
                      AND nvl(hi.error_flag,'N') = 'N');
   EXCEPTION
       WHEN OTHERS THEN
       fnd_file.put_line(FND_FILE.OUTPUT,'Failed to delete data from OE_CREDITS_IFACE_ALL');
       errbuf  := errbuf || substr(SQLERRM,1,80);
   END;

   -- Issue Commit
   commit;
   fnd_file.put_line(FND_FILE.LOG,'Successfully Purged the data from Interface Tables');
   retcode := 0;

EXCEPTION
  WHEN OTHERS THEN
   rollback;
   fnd_file.put_line(FND_FILE.OUTPUT,'Failure in Iface Purge Data');
   fnd_file.put_line(FND_FILE.OUTPUT,SUBSTR(SQLERRM,1,80));
   errbuf  := errbuf || substr(SQLERRM,1,80);
   retcode := -1;
END Purge_Data;


END XX_OM_PURGE_IFACE_PKG;

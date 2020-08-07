CREATE OR REPLACE PACKAGE APPS.XXPO_APPROVED_SUPPLIER_LIST_SV AUTHID CURRENT_USER AS
/* $Header: POXVASLS.pls 120.0 2005/06/02 15:09:29 appldev noship $ */

G_EXC_ERES_ERROR EXCEPTION;  -- <ASL ERECORD FPJ>

/*==================================================================
  PROCEDURE NAME:  create_asl_entry()

  DESCRIPTION:    This API inserts row into po_approved_supplier_list,
                  po_asl_attributes,po_asl_documents

  PARAMETERS: X_interface_header_id, X_interface_line_id - Values from the
                po_headers_interface and po_lines_interface tables.
              X_item_id, X_vendor_id, X_po_header_id,
              X_po_line_id,X_document_type
                Values of the document that needs to be created from
                the PDOI interface tables.
              X_category_id - Creatgory_id for the Category
              X_header_processable_flag - Value is N if there was any
                error encountered. Set in the procedure
                PO_INTERFACE_ERRORS_SV1.handle_interface_errors
		      X_po_interface_error_code - This is the code used to populate interface_type
        		field in po_interface_errors table.


=======================================================================*/

PROCEDURE create_po_asl_entries
(   x_interface_header_id      IN NUMBER,
    X_interface_line_id        IN NUMBER,
    X_item_id                  IN NUMBER,
    X_category_id              IN NUMBER,
    X_po_header_id             IN NUMBER,
    X_po_line_id               IN NUMBER,
    X_document_type            IN VARCHAR2,
    x_vendor_site_id           IN NUMBER,       -- GA FPI
    X_rel_gen_method           IN VARCHAR2,
    X_asl_org_id               IN NUMBER,
    X_header_processable_flag  OUT NOCOPY VARCHAR2,
    X_po_interface_error_code  IN  VARCHAR2,
    ----<LOCAL SR/ASL PROJECT 11i11 START>
    p_sourcing_level           IN  VARCHAR2 DEFAULT NULL
    ----<LOCAL SR/ASL PROJECT 11i11 END>
    );
--
end XXPO_APPROVED_SUPPLIER_LIST_SV;
/
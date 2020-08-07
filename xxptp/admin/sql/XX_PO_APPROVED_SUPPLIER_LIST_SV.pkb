CREATE OR REPLACE PACKAGE BODY APPS.XXPO_APPROVED_SUPPLIER_LIST_SV AS
/* $Header: POXVASLB.pls 120.8.12020000.4 2015/03/17 04:45:14 shikapoo ship $ */

-- Read the profile option that enables/disables the debug log
g_po_pdoi_write_to_file VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_PDOI_WRITE_TO_FILE'),'N');

-- <INBOUND LOGISTICS FPJ START>
g_pkg_name    CONSTANT VARCHAR2(30) := 'PO_APPROVED_SUPPLIER_LIST_SV';
c_log_head    CONSTANT VARCHAR2(50) := 'po.plsql.'|| g_pkg_name || '.';
g_fnd_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('AFLOG_ENABLED'),'N');
-- <INBOUND LOGISTICS FPJ END>

/*==================================================================
  PROCEDURE NAME:  create_po_asl_entries()

  DESCRIPTION:    This API inserts row into po_approved_supplier_list,
                  po_asl_attributes,po_asl_documents

  PARAMETERS: X_interface_header_id, X_interface_line_id - 
                Sequence number generated from po_headers_interface_s 
                and po_lines_interface_s.
              X_item_id, X_vendor_id, X_po_header_id,
              X_po_line_id,X_document_type
                Values of the document that is created from
                the PDOI interface tables.
              X_category_id - Creatgory_id for the Category
              X_header_processable_flag - Value is N if there was any
                error encountered. Set in the procedure
                PO_INTERFACE_ERRORS_SV1.handle_interface_errors
            X_po_interface_error_code - This is the code used to populate interface_type
            field in po_interface_errors table.
              p_sourcing_level
                This parameter specifies if the Sourcing Rule /ASL should be Global/Local 
                and if the assignment should be Item or Item Organization.

=======================================================================*/

PROCEDURE create_po_asl_entries
(   x_interface_header_id      IN NUMBER,
    X_interface_line_id        IN NUMBER,
    X_item_id                  IN NUMBER,
    X_category_id              IN NUMBER,
    X_po_header_id             IN NUMBER,
    X_po_line_id               IN NUMBER,
    X_document_type            IN VARCHAR2,
    x_vendor_site_id           IN NUMBER,        --  GA FPI
    X_rel_gen_method           IN VARCHAR2,
    x_asl_org_id               IN NUMBER,
    X_header_processable_flag  OUT NOCOPY VARCHAR2,
    X_po_interface_error_code  IN VARCHAR2,
    --<LOCAL SR/ASL PROJECT 11i11 START>    
    p_sourcing_level           IN VARCHAR2  DEFAULT NULL
    --<LOCAL SR/ASL PROJECT 11i11 END>  
    )
--
IS 
--
    x_last_update_date          date := sysdate;
    x_last_updated_by           number := fnd_global.user_id ;
    x_creation_date             date := sysdate;
    x_effective_date            date ;  
    x_disable_date              date;
    x_last_update_login         number := fnd_global.user_id;
    x_created_by                number := fnd_global.user_id;
--
    x_record_unique             BOOLEAN;
    x_asl_id                    number := null;
    x_owning_organization_id    number := null;
    x_vs_org_id                 number := null;
    x_vendor_product_num        VARCHAR2(30);
    x_progress                  VARCHAR2(3);
--
    x_asl_status_id             number := null;
    x_sequence_num              number := 1;
    x_purch_uom                 varchar2(25) := null;
    x_att_puom                  varchar2(25) := null;
    x_dummy_count               number := null;
    X_process_flag              varchar2(1) := 'Y';
--
    X_vendor_id                 number;
    x_type_lookup_code          varchar2(20);
    l_rel_gen_method            varchar2(25);

    x_purchasing_flag           varchar2(1) := 'Y';
    x_osp_flag           varchar2(1) := 'Y';
--
    -- <INBOUND LOGISTICS FPJ START>
    l_api_version      CONSTANT NUMBER := 1.0;
    l_return_status    VARCHAR2(1);
    l_msg_count        NUMBER;
    l_msg_data         FND_NEW_MESSAGES.message_text%TYPE;
    l_msg_buf          VARCHAR2(2000);
    l_api_name         CONSTANT VARCHAR2(40) := 'create_po_asl_entries';
    l_progress         VARCHAR2(3) := '001';
    -- <INBOUND LOGISTICS FPJ END>

    --<LOCAL SR/ASL PROJECT 11i11 START>    
    l_using_organization_id HR_ORGANIZATION_UNITS.organization_id%type;
    --<LOCAL SR/ASL PROJECT 11i11 END>    
    
     ---------- 10022351
      x_line_id                   number := null;
      x_date                      date;
    --Bug 18524781 Start
    x_closed_code PO_LINES_ALL.closed_code%TYPE;
    x_cancel_flag PO_LINES_ALL.cancel_flag%TYPE;
    --Bug 18524781 End
 
BEGIN
    x_header_processable_flag := 'Y';  -- Bug 2692597

    -- <ASL ERECORD FPJ>
    -- Adding a Save Point here. If this procedure has an exception it
    -- will be rollbacked to this point. We need to do this because Approval WF
    -- simply ignores the exception and PDOI will treat an exception here as an
    -- error, but either way the ASL should not be created.
    SAVEPOINT create_po_asl_entries_SP;
    
  /* GA FPI Start */
  /* check to see if the item is valid in the OU of the vendor_site_id passed in */
 
        SELECT org_id 
          INTO x_vs_org_id
          FROM po_vendor_sites_all 
         WHERE vendor_site_id = x_vendor_site_id;

        -- Bug 3795146: Handle null org id for a single org instance
    
    --<LOCAL SR/ASL PROJECT 11i11 START>    
    /*
       The value of using organization id for Global ASL's is -1. Set the value of 
       l_using_organization_id to -1 if the sourcing level is 'ITEM'. Else if the 
       Sourcing level is 'ITEM-ORGANIZATION'we need to set the value to x_asl_org_id

       We need to select the value of inventory organization id only if the value
       of sourcing_level is  is 'ITEM'. This would happen if the calling program is Approval 
       Workflow or if POASLGEN AND PDOI call the program with Sourcing Level set to Item
    */

       IF(nvl(p_sourcing_level,'ITEM')='ITEM-ORGANIZATION') THEN
          l_using_organization_id :=x_asl_org_id;
          x_owning_organization_id:=x_asl_org_id;
       ELSE
          SELECT inventory_organization_id
           INTO x_owning_organization_id 
           FROM financials_system_params_all
          WHERE nvl(org_id,-99) = nvl(x_vs_org_id,-99);
          l_using_organization_id :=-1;
       END IF;

    --<LOCAL SR/ASL PROJECT 11i11 END>  
    
    IF (g_po_pdoi_write_to_file = 'Y') THEN
        PO_DEBUG.put_line('Create PO ASL Entry for item: '||x_item_id||
                          ' vendor site id: '||x_vendor_site_id||
                          ' inv org: '||x_owning_organization_id);
    END IF;

    BEGIN       --< Bug 3560121 > Moved BEGIN for exception handling purposes.

    --<LOCAL SR/ASL PROJECT 11i11 START>    
    /*
      If the value of x_asl_org_id is not null then we need to verify that
      the item for which ASL needs to be created is enabled in the inventory 
      organization x_asl_org_id
    */
/* Bug 6142693 commented the or clause ("_asl_org_id is not null") 
       in order to ensure only global documents go through this check 
       Reverted the condition introduced in Local SR/ASL project. */

     IF (po_ga_pvt.is_global_agreement(X_po_header_id)) Then
            -- or (x_asl_org_id is not null)) THEN    -- Bug 2737193
    --<LOCAL SR/ASL PROJECT 11i11 END>    

        SELECT purchasing_enabled_flag,
               outside_operation_flag
          INTO x_purchasing_flag,
               x_osp_flag
          FROM mtl_system_items
         WHERE inventory_item_id = x_item_id
           AND organization_id = x_owning_organization_id;

        --<Shared Proc FPJ>
        --Introducing the NVL around purchasing org
        IF nvl(x_purchasing_flag, 'N') = 'N' 
        -- OR x_osp_flag = 'Y'  <bug#14539961>
        THEN
            --< Bug 3560121 Start >
            IF (g_po_pdoi_write_to_file = 'Y') THEN
                PO_DEBUG.put_line('Cannot create ASL entry. Purchasable: '
                                  ||x_purchasing_flag||' OSP item: '
                                  ||x_osp_flag||'. Insert warning msg');
            END IF;
            PO_INTERFACE_ERRORS_SV1.handle_interface_errors
                ( x_interface_type          => 'PO_DOCS_OPEN_INTERFACE'
                , x_error_type              => 'WARNING'
                , x_batch_id                => NULL
                , x_interface_header_id     => x_interface_header_id
                , x_interface_line_id       => x_interface_line_id
                , x_error_message_name      => 'PO_PDOI_CREATE_ASL_INVAL_ITEM'
                , x_table_name              => 'PO_LINES_INTERFACE'
                , x_column_name             => 'ITEM_ID'
                , x_tokenname1              => 'ORG_NAME'
                , x_tokenname2              => NULL
                , x_tokenname3              => NULL
                , x_tokenname4              => NULL
                , x_tokenname5              => NULL
                , x_tokenname6              => NULL
                , x_tokenvalue1             => PO_GA_PVT.get_org_name(p_org_id => x_owning_organization_id)
                , x_tokenvalue2             => NULL
                , x_tokenvalue3             => NULL
                , x_tokenvalue4             => NULL
                , x_tokenvalue5             => NULL
                , x_tokenvalue6             => NULL
                , x_header_processable_flag => x_header_processable_flag
                , x_interface_dist_id       => NULL
                );
            -- This is just a warning. Processing should continue, so reset the
            -- flag back to 'Y' before returning.
            x_header_processable_flag := 'Y';
            --< Bug 3560121 End >
            return;
        END IF;
        
     END IF;
           
    EXCEPTION
        --< Bug 3560121 Start > Should only catch NO_DATA_FOUND here. Also, need
        -- to insert a warning message in this case.
        WHEN NO_DATA_FOUND THEN
            IF (g_po_pdoi_write_to_file = 'Y') THEN
                PO_DEBUG.put_line('Cannot create ASL entry; item not defined in inv org. Insert warning msg');
            END IF;
            PO_INTERFACE_ERRORS_SV1.handle_interface_errors
                ( x_interface_type          => 'PO_DOCS_OPEN_INTERFACE'
                , x_error_type              => 'WARNING'
                , x_batch_id                => NULL
                , x_interface_header_id     => x_interface_header_id
                , x_interface_line_id       => x_interface_line_id
                , x_error_message_name      => 'PO_PDOI_CREATE_ASL_NO_ITEM'
                , x_table_name              => 'PO_LINES_INTERFACE'
                , x_column_name             => 'ITEM_ID'
                , x_tokenname1              => 'ORG_NAME'
                , x_tokenname2              => NULL
                , x_tokenname3              => NULL
                , x_tokenname4              => NULL
                , x_tokenname5              => NULL
                , x_tokenname6              => NULL
                , x_tokenvalue1             => PO_GA_PVT.get_org_name(p_org_id => x_owning_organization_id)
                , x_tokenvalue2             => NULL
                , x_tokenvalue3             => NULL
                , x_tokenvalue4             => NULL
                , x_tokenvalue5             => NULL
                , x_tokenvalue6             => NULL
                , x_header_processable_flag => x_header_processable_flag
                , x_interface_dist_id       => NULL
                );
            -- This is just a warning. Processing should continue, so reset the
            -- flag back to 'Y' before returning.
            x_header_processable_flag := 'Y';
            return; 
        --< Bug 3560121 End >
    END;
 /* GA FPI End */

  -- check to see if default asl status is available
  -- Get the default status from po_asl_statuses.  If no default status has
  -- been selected, insert error message and terminate transaction.
  BEGIN
  --
    SELECT status_id
      INTO x_asl_status_id
      FROM po_asl_statuses
     WHERE asl_default_flag = 'Y';
  --
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF (g_po_pdoi_write_to_file = 'Y') THEN
         PO_DEBUG.put_line('** ERROR: Please specify a default status in the ASL');
         PO_DEBUG.put_line('** Statuses form before proceeding with this.');
      END IF;
      X_process_flag := 'N';
      po_interface_errors_sv1.handle_interface_errors(
                                 X_po_interface_error_code,
                                 'FATAL',      
                                 null,
                                 X_interface_header_id,
                                 X_interface_line_id,
                                 'PO_PDOI_NO_ASL_STATUS',
                                 'PO_HEADERS_INTERFACE',
                                 'APPROVAL_STATUS',
                                 null, null,null,null,null,null,
                                 null, null,null, null,null,null,
                                 X_header_processable_flag);

  END;
  --
  -- Get Vendor_id and Vendor_site_id from Blanket
  --
  
  /*
      We would have to replace the views po_headers with table
      po_headers_all because the concurrent program POASLGEN can
      access global agreements from OU's which are merely Purchasing Org's
      for the GA and not necessarily Owning Orgs
  */

  SELECT vendor_id, 
         type_lookup_code
    INTO x_vendor_id,
         x_type_lookup_code
    FROM po_headers_all  --<LOCAL SR/ASL PROJECT 11i11>  
   WHERE po_header_id = X_po_header_id;

   -- 
  -- Get the Purchasing UOM from P.O.
  --
  
  /*
      We would have to replace the views po_headers with table
      po_headers_all because the concurrent program POASLGEN can
      access global agreements from OU's which are merely Purchasing Org's
      for the GA and not necessarily Owning Orgs
  */

     SELECT pol.unit_meas_lookup_code,
            pol.vendor_product_num
       INTO x_purch_uom,
            x_vendor_product_num
       FROM po_lines_all pol  --<LOCAL SR/ASL PROJECT 11i11>  
      WHERE po_line_id = x_po_line_id;
  -- 
  --
  -- Check if ASL already exists for this combination.
  --
  --<LOCAL SR/ASL PROJECT 11i11 START>  
  /*
    Depending on the value of sourcing level we would have to pass
    in the value of inventory_organization_id appropriately to check
    for uniqueness of asl record
  */

  IF nvl(p_sourcing_level,'ITEM')='ITEM' THEN
  x_record_unique := po_asl_sv.check_record_unique(
                               NULL,
                               x_vendor_id,
                               x_vendor_site_id,
                               x_item_id,
                               NULL,
                               -1);
  ELSE
  x_record_unique := po_asl_sv.check_record_unique(
                               NULL,
                               x_vendor_id,
                               x_vendor_site_id,
                               x_item_id,
                               NULL,
                               x_owning_organization_id);

  END IF;    
  --<LOCAL SR/ASL PROJECT 11i11 END>  
  --
  IF x_record_unique THEN
  
     SELECT PO_APPROVED_SUPPLIER_LIST_S.NEXTVAL
       INTO x_asl_id
       FROM SYS.DUAL;
 
     IF (g_po_pdoi_write_to_file = 'Y') THEN
        PO_DEBUG.put_line('Creating Record in Po approved Supplier List'); 
     END IF;
  -- 
     INSERT INTO PO_APPROVED_SUPPLIER_LIST (
         asl_id                  ,
         using_organization_id   ,
         owning_organization_id  ,
         vendor_business_type    ,
         asl_status_id           ,
         last_update_date        ,
         last_updated_by         ,
         creation_date           ,
         created_by              ,
         vendor_id               ,
         vendor_site_id          ,
         item_id                 ,
         primary_vendor_item     ,
         last_update_login       ,
         request_id              
     )  VALUES                    (
         x_asl_id                  ,
         l_using_organization_id,  --<LOCAL SR/ASL PROJECT 11i11>  
         x_owning_organization_id  ,
         'DIRECT'                  ,
         x_asl_status_id           ,
         x_last_update_date        ,
         x_last_updated_by         ,
         x_creation_date           ,
         x_created_by              ,
         x_vendor_id               ,
         x_vendor_site_id          ,
         x_item_id                 ,
         x_vendor_product_num      ,
         x_last_update_login       ,
         null                      
     );

     -- <INBOUND LOGISTICS FPJ START>
     l_progress := '020';
     l_return_status  := FND_API.G_RET_STS_SUCCESS;
     IF (g_fnd_debug = 'Y') THEN
         IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
           FND_LOG.string( LOG_LEVEL => FND_LOG.LEVEL_STATEMENT,
                         MODULE    => c_log_head || '.'||l_api_name||'.' || l_progress,
                         MESSAGE   => 'Call PO_BUSINESSEVENT_PVT.raise_event'
                       );
         END IF;
     END IF;

     PO_BUSINESSEVENT_PVT.raise_event
     (
         p_api_version      =>    l_api_version,
         x_return_status    =>    l_return_status,
         x_msg_count        =>    l_msg_count,
         x_msg_data         =>    l_msg_data,
         p_event_name       =>    'oracle.apps.po.event.create_asl',
         p_entity_name      =>    'ASL',
         p_entity_id        =>    x_asl_id
     );

     IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         IF (g_fnd_debug = 'Y') THEN
             l_msg_buf := NULL;
             l_msg_buf := FND_MSG_PUB.Get( p_msg_index => 1,
                                           p_encoded   => 'F');
             l_msg_buf := SUBSTR('ASL' || x_asl_id || 'errors out at' || l_progress || l_msg_buf, 1, 2000);
             IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
               FND_LOG.string( LOG_LEVEL => FND_LOG.level_unexpected,
                             MODULE    => c_log_head || '.'||l_api_name||'.error_exception',
                             MESSAGE   => l_msg_buf
                           );
             END IF;
         END IF;
     ELSE 
         IF (g_fnd_debug = 'Y') THEN     
             l_msg_buf := NULL;
             l_msg_buf := SUBSTR('ASL' || x_asl_id||'raised business event successfully', 1, 2000);
             IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
               FND_LOG.string( LOG_LEVEL => FND_LOG.level_statement,
                             MODULE    => c_log_head || '.'||l_api_name,
                             MESSAGE   => l_msg_buf
                           );
             END IF;
         END IF;
     END IF;  -- IF (l_return_status <> FND_API.G_RET_STS_SUCCESS)

     -- <INBOUND LOGISTICS FPJ END>
     
     IF (g_po_pdoi_write_to_file = 'Y') THEN
        PO_DEBUG.put_line('Creating Record in Po Asl Attribbutes ');
     END IF;

     -- create global ASL in po_asl_documents


     INSERT INTO po_asl_attributes(
         asl_id,
         using_organization_id,
         last_update_date,
         last_updated_by,
         creation_date,
         created_by,
         last_update_login,
         document_sourcing_method,
         release_generation_method,
         enable_plan_schedule_flag,
         enable_ship_schedule_flag,
         enable_autoschedule_flag,
         enable_authorizations_flag,
         vendor_id,
         vendor_site_id,
         purchasing_unit_of_measure,
         item_id
     ) VALUES (
         x_asl_id,
         l_using_organization_id,  --<LOCAL SR/ASL PROJECT 11i11>  
         x_last_update_date,
         x_last_updated_by,
         x_creation_date,
         x_created_by,
         x_last_update_login,
         'ASL',
         DECODE(X_type_lookup_code, 'BLANKET', X_rel_gen_method, NULL),
         'N',
         'N',
         'N',
         'N',
         x_vendor_id,
         x_vendor_site_id,
         x_purch_uom,
         x_item_id);
    --
         
     -- <ASL ERECORD FPJ START>
     -- bug3236816: Move the code that raises eres event after
     --             PO ASL Attribute is created 

     PO_ASL_SV.raise_asl_eres_event
     ( x_return_status => l_return_status,
       p_asl_id        => x_asl_id,
       p_action        => PO_ASL_SV.G_EVENT_INSERT,
       p_calling_from  => 'PO_APPROVED_SUPPLIER_LIST_SV.create_po_asl_entries',
       p_ackn_note     => NULL,
       p_autonomous_commit => FND_API.G_FALSE
     );
                        
     IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         RAISE G_EXC_ERES_ERROR;
     END IF;
      
     -- <ASL ERECORD FPJ END>

    ELSE  --Record Not Unique
    -- If supplier-item relation exists, return asl_id for this asl entry.
    --
      IF (g_po_pdoi_write_to_file = 'Y') THEN
         PO_DEBUG.put_line('ASL exists for Vndr' || to_char(x_vendor_id));
         PO_DEBUG.put_line('ASL exists for VndrSite' || to_char(x_vendor_site_id));
         PO_DEBUG.put_line('ASL already exists for Item' || to_char(x_item_id));
      END IF;
    --
      /* BUG No.1541387:For the case when the sourcing rule is purged and the
                        corresponding ASL consists of no supplier_site_code - 
                        making the provision for vendor_site_id and 
                        x_vendor_site_id to be null without an error.
       */

      x_progress := '050';


      SELECT asl_id
        INTO x_asl_id
        FROM po_approved_supplier_list pasl
       WHERE pasl.vendor_id = x_vendor_id
         AND (    pasl.vendor_site_id = x_vendor_site_id
               OR (    pasl.vendor_site_id is NULL
                   AND x_vendor_site_id is NULL))
         AND pasl.item_id = x_item_id
         AND using_organization_id = l_using_organization_id;  --<LOCAL SR/ASL PROJECT 11i11>  


   /* 
      Bug 2361161 If the ASL entry exists then we update the attributes with the release generation method
      passed from the approval window. if the Purchasing UOM has not been entered update that with the value
      from the po line 
   */

       select purchasing_unit_of_measure,
              release_generation_method
       into x_att_puom,
            l_rel_gen_method
       from po_asl_attributes
       where asl_id = x_asl_id
       and using_organization_id =l_using_organization_id --<LOCAL SR/ASL PROJECT 11i11>  
       and vendor_id = x_vendor_id
       and vendor_site_id = x_vendor_site_id
       and item_id = x_item_id;

      if x_att_puom is null then
         x_att_puom := x_purch_uom;
      end if;

      /* Bug 2438375 fix by davidng. Added the constraint "l_rel_gen_method is null" 
         Hence we are only updating the Release Generation Method if it is originally null */
      if (X_type_lookup_code = 'BLANKET' and X_rel_gen_method is not null 
          --and l_rel_gen_method is null  -- Defect 42727 
          ) then
         l_rel_gen_method := X_rel_gen_method;          
      end if;

 
      UPDATE po_asl_attributes
      set release_generation_method =  l_rel_gen_method, 
          purchasing_unit_of_measure = x_att_puom,
          last_update_date = x_last_update_date,
          last_updated_by = x_last_updated_by,
          last_update_login = last_update_login
      where asl_id = x_asl_id
       and using_organization_id =l_using_organization_id --<LOCAL SR/ASL PROJECT 11i11>  
       and vendor_id = x_vendor_id
       and vendor_site_id = x_vendor_site_id
       and item_id = x_item_id;
  
   END IF;

   -- Make sure that this source document does not already exist for
   -- this ASL entry.
   x_progress := '020';
   SELECT count(*)
     INTO x_dummy_count
     FROM po_asl_documents
    WHERE asl_id = x_asl_id
      AND using_organization_id = l_using_organization_id --<LOCAL SR/ASL PROJECT 11i11>  
      AND document_header_id = x_po_header_id
      AND document_type_code = x_type_lookup_code;

   IF x_dummy_count > 0 THEN
   
   ---Bug10022351 START
       SELECT document_line_id
         INTO x_line_id
         FROM po_asl_documents
        WHERE asl_id = x_asl_id
          AND using_organization_id = l_using_organization_id --<LOCAL SR/ASL PROJECT 11i11>  
          AND document_header_id = x_po_header_id
          AND document_type_code = x_type_lookup_code;

       SELECT expiration_date, nvl(pl.closed_code,'OPEN'), nvl(pl.cancel_flag,'N') --Bug#18524781
         INTO x_date, x_closed_code, x_cancel_flag --Bug#18524781
         FROM po_lines_all pl
        WHERE po_header_id = x_po_header_id
          AND po_line_id = x_line_id;
          
      -- Bug 20397604
      IF (trunc(NVL(x_date , sysdate+1)) >= trunc(SYSDATE)
              AND x_closed_code <> 'FINALLY CLOSED' --Bug#18524781
              AND x_cancel_flag = 'N') THEN  ---10192008 --Bug#18524781
          
             IF (g_po_pdoi_write_to_file = 'Y') THEN
                  PO_DEBUG.put_line('Doc already exists for this ASL');
             END IF;
             null;
      
          ELSE

          UPDATE PO_ASL_DOCUMENTS
                SET document_line_id = x_po_line_id,
                    last_update_date = x_last_update_date,
                    last_updated_by = x_last_updated_by,
                    last_update_login = last_update_login
                WHERE asl_id = x_asl_id
                AND document_header_id = x_po_header_id;


              IF (g_po_pdoi_write_to_file = 'Y') THEN
                  PO_DEBUG.put_line('Updating the expired line on this ASL');
              END IF;
             
          END IF;
          
          ---Bug10022351 END
              
   ELSE
   --
      SELECT nvl(max(sequence_num)+1, 1)
        INTO x_sequence_num
        FROM po_asl_documents
       WHERE asl_id = x_asl_id
         AND using_organization_id = l_using_organization_id;  --<LOCAL SR/ASL PROJECT 11i11>  
      --
      IF (g_po_pdoi_write_to_file = 'Y') THEN
         PO_DEBUG.put_line('Creating record in Po Asl Docs');
      END IF;
      --
      -- Insert doc into po_asl_documents
      --

      INSERT INTO PO_ASL_DOCUMENTS(
          asl_id,
          using_organization_id,
          sequence_num,
          document_type_code,
          document_header_id,
          document_line_id,
          last_update_date,
          last_updated_by,
          last_update_login,
          creation_date,
          created_by
      ) VALUES (
          x_asl_id,
          l_using_organization_id,  --<LOCAL SR/ASL PROJECT 11i11>  
          x_sequence_num,
          x_type_lookup_code,
          x_po_header_id,
          x_po_line_id,
          x_last_update_date,
          x_last_updated_by,
          x_last_update_login,
          x_creation_date,
          x_created_by
      );

    END IF; 
 
--  END IF;

  EXCEPTION
  WHEN others THEN
      ROLLBACK TO create_po_asl_entries_SP;  -- <ASL ERECORD FPJ>
      x_header_processable_flag := 'N';  -- Bug 2692597
      --< Bug 3560121 Start >
      IF (g_po_pdoi_write_to_file = 'Y') THEN
          PO_DEBUG.put_line('Exception caught while creating ASL entries.'); 
      END IF;
      --< Bug 3560121 End >
      po_message_s.sql_error('create_po_asl_entries', x_progress, sqlcode);
      raise;
END create_po_asl_entries;

END XXPO_APPROVED_SUPPLIER_LIST_SV;
/
SET SHOW         OFF  
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF

SET TERM ON
PROMPT Creating Package body XX_WFL_POAPPRV_ATTACH_PKG 
PROMPT Program exits if the creation is not successful
SET TERM OFF
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE BODY XX_WFL_POAPPRV_ATTACH_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  File Attachment to PO                                    |
-- | Description   :  This package fetches attachments made to a PO    |
-- |                  and saves as document attributes in the message  |                                                 
-- |                  that is used to send notification to the         |                                                 
-- |                  Supplier so that the supplier can see all        |                                           
-- |                  attachments made to a PO                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 28-FEB-2007  Radhika Raman    Initial draft version       |
-- |1.0      03-JUL-2009  Subbu Pillai     Fix for PRDGB Defect 499    |
-- |2.0      1-FEB-2013   Saritha M        Added condition to pick only|
-- |                                       File types  as              |
-- |                                       per Defect # 22115          |
-- |3.0      26-JUN-2015  Madhu Bolli     Defect#24466 - Punchout patch Retrofit|
-- |                                     refer media_id from fnd_documents table|
-- |4.0      26-JUN-2015  Madhu Bolli     Rollback the code as mentioned in 3.0 |
-- |                              bcoz it is the expected functionality in R12  |
-- |       and the version 3.0 is only updated to UAT and now rollback from UAT |
-- +===================================================================+


-- +===================================================================+
-- | Name  : GET_ATTACHMENTS                                           |
-- | Description  : This procedure fetches the attachments of a PO     | 
-- |                and calls a procedure to attach the BLOB to a      | 
-- |                document attribute of the message                  |
-- |                                                                   |
-- | Parameters :   Standard Workflow Parameters  - itemtype, itemkey, |
-- |                actid, funcmode, resultout                         |                                                   
-- |                                                                   |
-- +===================================================================+

-- In the GET_ATTACHMENTS procedure we fetch the number of attachments for 
-- a PO at header, line and shipment level and for each file we set the 
-- message attribute by passing the file_id to SET_ATTACHMENT procedure.

  PROCEDURE GET_ATTACHMENTS (itemtype    IN  VARCHAR2
                             ,itemkey     IN  VARCHAR2
                             ,actid       IN  NUMBER
                             ,funcmode    IN  VARCHAR2
                             ,resultout   OUT NOCOPY VARCHAR2
                             ) 
  IS
    ln_document_id       NUMBER;
	 ln_document_type     VARCHAR2(100); ---Added for 499(PRDGB)
    ln_loop_count        NUMBER:=0; 
    
    lc_error_loc                VARCHAR2(200) := '';
    lc_error_debug              VARCHAR2(200) := '';
    lc_err_msg                  VARCHAR2(4000):= '';    
    lc_preparer_user_name       VARCHAR2(200);
   
    ln_notification_id          NUMBER;
    
    CURSOR lcu_attachments (p_document_id NUMBER)
    IS
    (
      (SELECT FL.file_id
       FROM fnd_attached_documents     FAD
           ,fnd_documents              FD
           ,fnd_document_categories_tl FDCT
           ,fnd_documents_tl           FDT
           ,fnd_lobs                   FL
       WHERE FD.document_id = FAD.document_id
       AND   FD.category_id = FDCT.category_id
       AND   FDT.document_id = FD.document_id
       AND   FL.file_id = FDT.media_id   -- 3.0 and 4.0 - rollback
       AND   FAD.entity_name = 'PO_HEADERS'
       AND   FDCT.user_name = 'To Supplier' 
       AND   FAD.pk1_value = TO_CHAR(p_document_id)
       AND   FD.datatype_id  = 6                         -- Added as per Ver 2.0 by Oracle AMS SCM Team
      )
      UNION
      (SELECT FL.file_id
       FROM po_lines_all               PLA
           ,fnd_attached_documents     FAD
           ,fnd_documents              FD
           ,fnd_document_categories_tl FDCT
           ,fnd_documents_tl           FDT
           ,fnd_lobs                   FL
       WHERE PLA.po_header_id = p_document_id
       AND   FAD.pk1_value = TO_CHAR(PLA.po_line_id)
       AND   FD.document_id = FAD.document_id
       AND   FD.category_id = FDCT.category_id
       AND   FDT.document_id = FD.document_id
       AND   FL.file_id = FDT.media_id   -- 3.0 and 4.0 - rollback
       AND   FAD.entity_name = 'PO_LINES'
       AND   FDCT.user_name = 'To Supplier' 
       AND   FD.datatype_id  = 6                         -- Added as per Ver 2.0 by Oracle AMS SCM Team
      )
      UNION
      (SELECT FL.file_id
       FROM po_lines_all               PLA
           ,po_line_locations_all      PLLA
           ,fnd_attached_documents     FAD
           ,fnd_documents              FD
           ,fnd_document_categories_tl FDCT
           ,fnd_documents_tl           FDT
           ,fnd_lobs                   FL
       WHERE PLA.po_header_id = p_document_id
       AND   PLLA.po_line_id = PLA.po_line_id
       AND   FAD.pk1_value = TO_CHAR(PLLA.line_location_id)
       AND   FD.document_id = FAD.document_id
       AND   FD.category_id = FDCT.category_id
       AND   FDT.document_id = FD.document_id
       AND   FL.file_id = FDT.media_id  -- 3.0 and 4.0 - rollback
       AND   FAD.entity_name = 'PO_SHIPMENTS'
       AND   FDCT.user_name = 'To Supplier'
       AND   FD.datatype_id  = 6                         -- Added as per Ver 2.0 by Oracle AMS SCM Team
      ) 
     );
    
  BEGIN
    lc_error_loc := 'Get the po_header_id from workflow attribute';
    
    -- Get PO_HEADER_ID stored in Workflow Attribute
    ln_document_id :=Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                                  itemkey  => itemkey,
                                                  aname    => 'DOCUMENT_ID');
																  
    -- Get the Document Type ---Added for 499(PRDGB)
   ln_document_type :=Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                                  itemkey  => itemkey,
                                                  aname    => 'DOCUMENT_TYPE');
                                                  
    --If the document type is RELEASE no need to process any additional attachment.                                                  
    IF ln_document_type <> 'RELEASE' Then																  
                                              
		 lc_error_loc := 'Looping for each attachment';
		 lc_error_debug := 'PO_HEADER_ID='||ln_document_id;
		 
		 -- Loop for the number of file attachments
		 FOR lcu_attachments_rec IN lcu_attachments(ln_document_id)  
		 LOOP
			 ln_loop_count := ln_loop_count + 1;
			 
			 -- Set message attribute
			 lc_error_loc := 'Setting attachment in attribute'; 
			 lc_error_debug:='ln_loop_count='||ln_loop_count||'  File ID:'||lcu_attachments_rec.file_id;
			 Wf_Engine.SetItemAttrText (itemtype => itemtype,
												 itemkey  => itemkey,
												 aname    => 'PO_ATTACHMENT_'||ln_loop_count,
												 avalue   => 'PLSQLBLOB:XX_WFL_POAPPRV_ATTACH_PKG.SET_ATTACHMENT/'||lcu_attachments_rec.file_id);
												 
		 END LOOP;
	 END IF;
  EXCEPTION
  WHEN OTHERS THEN 
      FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0066_ERROR');
      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
      lc_err_msg :=  FND_MESSAGE.get;
      
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'PACKAGE' 
                ,p_program_name            => 'XX_WFL_POAPPRV_ATTACH_PKG.GET_ATTACHMENTS'
                ,p_module_name             => 'PO'
                ,p_error_location          => lc_error_loc
                ,p_error_message_code      => 'XX_PO_0066_ERROR'
                ,p_error_message           => lc_err_msg
                ,p_notify_flag             => 'Y'
                ,p_object_type             => 'Extension'
                ,p_object_id               => 'E0987');                 
     
     lc_preparer_user_name  := WF_ENGINE.GETITEMATTRTEXT ( itemtype => itemtype,
                                                           itemkey  => itemkey,
                                                           aname    => 'BUYER_USER_NAME');
     WF_ENGINE.SETITEMATTRTEXT ( itemtype => itemtype
                                   ,itemkey  => itemkey
                                   ,aname    => 'EXCEPTION_OTHERS'
                                   ,avalue   => lc_err_msg  );    
                                   
      ln_notification_id := WF_NOTIFICATION.SEND(role      => lc_preparer_user_name
                                                 ,msg_type => 'POAPPRV'
                                                 ,msg_name => 'EXCEPTION_OTHERS'
                                                 ,due_date => SYSDATE
                                                 ,callback => 'WF_ENGINE.CB'
                                                 ,context  => itemtype||':'||itemkey||':'||actid);      
  
  END GET_ATTACHMENTS;
  

-- +===================================================================+
-- | Name  : SET_ATTACHMENT                                            |
-- | Description  : This procedure copies the BLOB attachment to a     | 
-- |                output variable such that it is saved as a value   | 
-- |                document attribute of the message                  |
-- |                                                                   |
-- | Parameters :   document_id, content_type, document, document_type |                                                
-- |                                                                   |
-- +===================================================================+

--In this procedure we get the BLOB data from database from the file_id
--and store it in BLOB output variable.

  PROCEDURE SET_ATTACHMENT(document_id    IN            VARCHAR2
                          ,content_type   IN            VARCHAR2
                          ,document       IN OUT NOCOPY BLOB
                          ,document_type  IN OUT NOCOPY VARCHAR2)   
  IS
    lbl_document         BLOB; 
    ln_document_length   NUMBER;
    lc_file_name         fnd_lobs.file_name%TYPE;
    lc_content_type      fnd_lobs.file_content_type%TYPE;   
    
    lc_error_loc                VARCHAR2(200) := '';
    lc_error_debug              VARCHAR2(200) := '';
    lc_err_msg                  VARCHAR2(4000):= '';
    lc_preparer_user_name       VARCHAR2(200);
    lc_doc_string               VARCHAR2(200);
  BEGIN
   lc_error_loc:='Fetch the file using file_id';
   lc_error_debug:='File ID: '||document_id;
   
   BEGIN
    --Fetch BLOB data                  
    SELECT file_data
          ,file_name
          ,file_content_type
    INTO   lbl_document
          ,lc_file_name
          ,lc_content_type
    FROM  fnd_lobs FL
    WHERE FL.file_id = to_number(document_id); 
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0067_ERROR');
      FND_MESSAGE.SET_TOKEN('FILE_ID',document_id);
      lc_err_msg :=  FND_MESSAGE.get;
      
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'PACKAGE' 
                ,p_program_name            => 'XX_WFL_POAPPRV_ATTACH_PKG.SET_ATTACHMENT'
                ,p_module_name             => 'PO'
                ,p_error_location          => lc_error_loc
                ,p_error_message_code      => 'XX_PO_0067_ERROR'
                ,p_error_message           => lc_err_msg
                ,p_notify_flag             => 'Y'
                ,p_object_type             => 'Extension'
                ,p_object_id               => 'E0987');        
        
   END;
    
    --Get BLOB data's length
    lc_error_loc:='Get BLOB length'; 
    lc_error_debug:='';
    ln_document_length := dbms_lob.GetLength(lbl_document);
    
    --Copy the BLOB data to output variable
    lc_error_loc:='Copy into BLOB output variable';
    lc_error_debug:='Document Length:='||ln_document_length;
    dbms_lob.copy(document, lbl_document, ln_document_length, 1, 1);
    
    --assign file type of the BLOB to output variable
    document_type:=lc_content_type||'; name='||lc_file_name;
  EXCEPTION
  WHEN OTHERS THEN 
      FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0066_ERROR');
      FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
      FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
      FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
      lc_err_msg :=  FND_MESSAGE.get;
      
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'PACKAGE' 
                ,p_program_name            => 'XX_WFL_POAPPRV_ATTACH_PKG.SET_ATTACHMENT'
                ,p_module_name             => 'PO'
                ,p_error_location          => lc_error_loc
                ,p_error_message_code      => 'XX_PO_0066_ERROR'
                ,p_error_message           => lc_err_msg
                ,p_notify_flag             => 'Y'
                ,p_object_type             => 'Extension'
                ,p_object_id               => 'E0987');                 

  END SET_ATTACHMENT;  
  
END XX_WFL_POAPPRV_ATTACH_PKG;
/

SHOW ERRORS

SET TERM OFF
WHENEVER SQLERROR EXIT 1

SET SHOW         ON
SET VERIFY       ON
SET ECHO         ON
SET TAB          ON
SET FEEDBACK     ON

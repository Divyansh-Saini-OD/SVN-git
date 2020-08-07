CREATE OR REPLACE PACKAGE BODY APPS.gl_import_hook_pkg AS
/* $Header: FVCTAGLHKB.pls 120.0.12020000.3 2015/01/13 17:59:16 ksriniva noship $ */

--
-- PUBLIC FUNCTIONS
--

  --
  -- Procedure
  --   pre_module_hook
  -- Purpose
  --   Hook into journal import for Federal CTA BETC Validation .
  --   TRUE - upon success (allows journal import to continue)
  --   FALSE - upon failure (causes journal import to abort and display the
  --			     error in errbuf)

  -------------------------------------------------------------------------------
  FUNCTION pre_module_hook(run_id    IN     NUMBER,
			   errbuf    IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS

  l_reclass_category varchar2(100):= fnd_profile.value('FV_RECLASSIFICATION_JOURNAL_CATEGORY');
  l_reclass_count  number(15);

  p_status varchar2(2) := 'Y';
  p_errbuf varchar2(300) ;

  l_sob_id number(15);

  LN_GROUP_ID GL_INTERFACE_CONTROL.GROUP_ID%TYPE;
  Lc_Interface_Table_Name Gl_Interface_Control.Interface_Table_Name%Type;
  Lc_Stmt Varchar2(2000);
  Lc_Crd_Accu_Stmt Varchar2(2000);
  Lc_Je_Source_Name Gl_Interface_Control.Je_Source_Name%TYPE;

  Cursor C_Group_Id
  Is
  Select Group_Id
  From Gl_Interface_Control
  WHERE Interface_Run_Id =RUN_ID;

  BEGIN

   fnd_file.put_line(fnd_file.log , 'In GL import pre hook');

   --Added for Defect#27857, for reassigning the GL Category for Sales Invoices
   -- Jay Gupta, 02/28/2014
   BEGIN
    UPDATE gl_interface gi
    SET gi.user_je_CATEGORY_NAME = 'OD COGS'
    WHERE EXISTS
      (SELECT 'X'
      FROM xla_ae_lines xal
      WHERE gi.User_je_source_name   = 'Receivables'
      AND gi.user_je_CATEGORY_NAME   = 'Sales Invoices'
      AND xal.application_id         = 222
      AND xal.GL_SL_LINK_ID          = gi.gl_sl_link_id
      AND xal.gl_sl_link_table       = gi.gl_sl_link_table
      AND xal.accounting_class_code IN ('COST_OF_GOODS_SOLD', 'INVENTORY_VALUATION')
      );


   -- COMMIT;
   EXCEPTION
    WHEN OTHERS THEN
     RETURN(FALSE);
   End;

   Begin
     Select Je_Source_Name, Group_Id,Interface_Table_Name
     Into Lc_Je_Source_Name, Ln_Group_Id, LC_INTERFACE_TABLE_NAME
     FROM GL_INTERFACE_CONTROL
     Where Interface_Run_Id      =Run_Id;


     IF LC_INTERFACE_TABLE_NAME IS NOT NULL  THEN
       lc_stmt                  := 'UPDATE '||LC_INTERFACE_TABLE_NAME|| ' gi SET gi.user_je_CATEGORY_NAME = ''OD COGS''
       WHERE  EXISTS (SELECT ''X'' FROM xla_ae_lines xal
       WHERE gi.User_je_source_name   = ''Receivables''
       AND gi.user_je_CATEGORY_NAME = ''Sales Invoices''
       AND xal.application_id = 222
       AND xal.GL_SL_LINK_ID = gi.gl_sl_link_id
       AND xal.gl_sl_link_table = gi.gl_sl_link_table
       AND xal.accounting_class_code
       IN (''COST_OF_GOODS_SOLD'', ''INVENTORY_VALUATION''))';
            Execute Immediate Lc_Stmt;
       --Added for Defect#30254
       --Manjusha Tangirala, 07/28/2014

     If Upper(Lc_Je_Source_Name) In('3084','OD CM Credit Accruals')
     Then

      For Rec_Group_Id In C_Group_Id
      Loop
      begin

        Lc_Crd_Accu_Stmt       :='UPDATE '||Lc_Interface_Table_Name|| ' gic
        SET gic.reference4 = gic.reference4||gic.Accounting_Date
        WHERE gic.group_id='|| REC_GROUP_ID.GROUP_ID  ;
        Execute Immediate  Lc_Crd_Accu_Stmt;

        --  Fnd_File.Put_Line(Fnd_File.Log,Lc_Crd_Accu_Stmt||Rec_Group_Id.Group_Id);
      Exception
        When No_Data_Found Then
          Fnd_File.Put_Line(Fnd_File.Log,'no_data'||Rec_Group_Id.Group_Id);

        When Others Then
         Fnd_File.Put_Line(Fnd_File.Log,'others'||Rec_Group_Id.Group_Id);

      End;

      End Loop;
      
     END IF;

    END IF;
  --  COMMIT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN TRUE;
  WHEN OTHERS THEN
    RETURN(FALSE);
  END;

   --select set_of_books_id into l_sob_id
   --from gl_interface_control
   --where interface_run_id = run_id;

   --fnd_file.put_line(fnd_file.log , 'GL import Set of Bookd id  is : ' || l_sob_id);

  if (l_reclass_category is null ) then
     fnd_file.put_line(fnd_file.log , 'CTA - Reclass Journal category Not set and so validate BETC pre process is not required ');
     fnd_file.put_line(fnd_file.log , 'GL import pre hook status : SUCCESS ');
     g_cta_flag := 'N';
     return true;
  End if;

  select count(*) into l_reclass_count
    from gl_interface_control c ,
         gl_interface i ,
         gl_je_categories g
   where interface_run_id = run_id
     and i.group_id = c.group_id
     and i.user_je_category_name = g.user_je_category_name
     and g.je_category_name = l_reclass_category;

   fnd_file.put_line(fnd_file.log , 'No of  reclass transaction in gl interface : ' || l_reclass_count );
   g_cta_flag := 'N';

  if (l_reclass_count = 0  ) then
     fnd_file.put_line(fnd_file.log , 'GL import does not containt any reclass transactions  to validate BETC ');
     fnd_file.put_line(fnd_file.log , 'GL import pre hook status : SUCCESS ');
     g_cta_flag := 'N';
     return true;
  End if;
  g_cta_flag := 'Y';

  fnd_file.put_line(fnd_file.log , 'deleting fv_cta_process rows');

  delete from fv_cta_process_temp
   where set_of_books_id = l_sob_id;
  fnd_file.put_line(fnd_file.log , 'deleted records ' || sql%rowcount);

  fnd_file.put_line(fnd_file.log , 'Calling CTA_GLIMP_VALIDATION IN pre hook');
  IF (NOT FV_CTA_TRANSACTIONS.CTA_GLIMP_VALIDATION(run_id,p_errbuf,p_status)) THEN
         fnd_file.put_line(fnd_file.log , 'CTA CALL FAILURE');
      RETURN(FALSE);
  END IF;
  fnd_file.put_line(fnd_file.log , 'CTA CALL SUCCESSFUL');
  fnd_file.put_line(fnd_file.log , errbuf);

  if (p_status = 'S') then
         fnd_file.put_line(fnd_file.log , 'POST GL HOOK SUCCESS... ');
         RETURN(TRUE);
  else
         fnd_file.put_line(fnd_file.log , 'POST GL HOOK FAILURE... ');
         RETURN(FALSE);

  End if;


  RETURN(TRUE);


  END pre_module_hook;

 ----------------------------------------------------------------------------------
  --
  -- Procedure
  --   post_module_hook
  -- Purpose
  --   Hook into journal import for other products.
  --   This procedure is called after journal import has inserted all of the
  --   data into gl_je_batches, gl_je_headers, and gl_je_lines, but before
  --   it does the final commit.
  --
  FUNCTION post_module_hook(batch_ids  IN     VARCHAR2,
                            separator  IN     VARCHAR2,
                            last_set   IN     BOOLEAN,
			    errbuf     IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS

  p_status varchar2(2) := 'Y';
  p_errbuf varchar2(300) ;
  BEGIN

         fnd_file.put_line(fnd_file.log , 'in post hook  ');

      if (nvl(g_cta_flag, 'N') = 'N') then
        fnd_file.put_line(fnd_file.log , 'No need to call CTA post hook ' );
        fnd_file.put_line(fnd_file.log , 'setting Post Hook Status : Success  ' );
         return true;
      End if;
         fnd_file.put_line(fnd_file.log , 'calling CTA_CTA_GLIMP_UPDATE ');
       IF (NOT FV_CTA_TRANSACTIONS.CTA_GLIMP_UPDATE(batch_ids,separator,p_status,errbuf)) then
         fnd_file.put_line(fnd_file.log , 'CTA CALL FAILURE');
         RETURN(FALSE);
      END IF;

         fnd_file.put_line(fnd_file.log , 'Setting Post Hook Status :SUCCESS  ');
         RETURN(TRUE);
  END post_module_hook;

END gl_import_hook_pkg;
/

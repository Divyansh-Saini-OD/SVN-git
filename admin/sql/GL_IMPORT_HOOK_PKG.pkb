create or replace
PACKAGE BODY gl_import_hook_pkg
AS
  /* $Header: glujihkb.pls 120.5 2005/05/05 01:39:55 kvora ship $ */
  --
  -- PUBLIC FUNCTIONS
  --
  --
  -- Procedure
  --   pre_module_hook
  -- Purpose
  --   Hook into journal import for other products.
  --   This procedure is called after journal import has selected
  --   the sources to process, but before it has started processing the data.
  --   If you need to use this hook, please add a call to your own
  --   package before the return statement.  Please do NOT commit
  --   your changes in your package.
  -- Returns
  --   TRUE - upon success (allows journal import to continue)
  --   FALSE - upon failure (causes journal import to abort and display the
  --        error in errbuf)
  -- History
  --   19-JUN-95  D. J. Ogg    Created
  -- Arguments
  --   run_id  The import run id
  --   errbuf  The error message printed upon error
  -- Example
  --   gl_import_hook_pkg.pre_module_hook(2, 100, errbuf);
  -- Notes
  --
FUNCTION pre_module_hook(
    run_id IN NUMBER,
    errbuf IN OUT NOCOPY VARCHAR2)
  RETURN BOOLEAN
IS
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
  -- Please put your function call here.  Make it the following format:
  --    IF (NOT dummy(sob_id, run_id, errbuf)) THEN
  --      RETURN(FALSE);
  --    END IF;
  RETURN(TRUE);
END pre_module_hook;
--
-- Procedure
--   post_module_hook
-- Purpose
--   Hook into journal import for other products.
--   This procedure is called after journal import has inserted all of the
--   data into gl_je_batches, gl_je_headers, and gl_je_lines, but before
--   it does the final commit.
--   This routine is called once per 100 batches.
--   If you need to use this hook, please add a call to your own
--   package before the return statement.  Please do NOT commit
--   your changes in your package.
-- Returns
--   TRUE - upon success (allows journal import to continue)
--   FALSE - upon failure (causes journal import to abort and display the
--        error in errbuf)
-- History
--   28-FEB-00  D. J. Ogg    Created
-- Arguments
--   batch_ids        A list of batch ids, separated by the separator
--   separator        The separator
--   last_set         Indicates whether or not this is the last set
--   errbuf  The error message printed upon error
-- Example
--   gl_import_hook_pkg.post_module_hook(2, 100, errbuf);
-- Notes
--
FUNCTION post_module_hook(
    batch_ids IN VARCHAR2,
    separator IN VARCHAR2,
    last_set  IN BOOLEAN,
    Errbuf    In Out Nocopy Varchar2)
  RETURN BOOLEAN
Is


BEGIN
  -- gl_ip_process_batches_pkg.process_batches(batch_ids, separator, last_set);
  -- Please put your function call here.  Make it the following format:
  --    IF (NOT dummy(sob_id, run_id, errbuf)) THEN
  --      RETURN(FALSE);
  --    END IF;
  
 
    RETURN TRUE;
 
END post_module_hook;
END gl_import_hook_pkg;
/
SHOW ERR;
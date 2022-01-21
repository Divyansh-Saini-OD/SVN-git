create or replace
PACKAGE BODY XXOD_GL_INT_MAINS_PKG IS
-- +====================================================================+
  -- |                  Office Depot - Project Simplify                   |
  -- +====================================================================+
  -- | Name         : XXOD_GL_INT_MAINS_PKG                               |
  -- | Description  : This package is used to submit the OD: Journal GL   |
  -- |                Interface Report with default output as EXCEL.      |
  -- |                                                                    |
  -- |Change Record:                                                      |
  -- |===============                                                     |
  -- |Version  Date         Author         Remarks                        |
  -- |=======  ===========  =============  ===============================|
  -- | 1       26-NOV-2013  Ankit Arora    Initial version                |
  -- |                                     Created for Defect 15713       |
  -- | 2       19-may-2014  Lakshmi Tangirala Fix for defect 29970
  -- | 3       31-Jul-2014  Lakshmi Tangirala Fix for defect 30541       |
  -- +====================================================================+
  -- +====================================================================+
  -- | Name        : XXOD_GL_INT_MAINS_PKG.MAIN                           |
  -- | Description : This procedure is used to the OD: Journal GL         |
  -- |                Interface Report with default output as EXCEL.      |
  -- |                                                                    |
  -- | Parameters  : 1. P_START_PERIOD                                    |
  -- |               2  P_END_PERIOD                                      |
  -- |               3. P_SET_OF_BOOK_ID                                  |
  -- |                                                                    |
  -- | Returns     :   x_errbuf, x_ret_code                               |
  -- |                                                                    |
  -- |                                                                    |
  -- +====================================================================+

PROCEDURE MAIN( x_err_buf OUT VARCHAR2 ,
    x_retcode OUT NUMBER ,
    P_START_PERIOD IN VARCHAR2 ,
    P_END_PERIOD  IN VARCHAR2 ,
    P_SET_OF_BOOK_ID IN VARCHAR2,
    p_all_or_error in Varchar2
                            )
  IS
    -- Local Variable declaration
    x_errbuf        VARCHAR2(1000);
    x_ret_code      VARCHAR2(1000);
    ln_request_id   NUMBER := 0;
    lc_phase        VARCHAR2 (200);
    lc_status       VARCHAR2 (200);
    lc_dev_phase    VARCHAR2 (200);
    lc_dev_status   VARCHAR2 (200);
    Lc_Message      Varchar2 (200);
    Lb_Wait         Boolean;
    LC_SET_OF_BOOK_ID VARCHAR2(200) :=NULL;
    Lb_Layout       Boolean;
    
    Lc_Request_Data Varchar2(120);
    
  Begin
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the program OD: Journal GL Interface Report');
     Fnd_File.Put_Line(Fnd_File.Log,'Display All Or Errored interface records?: ' ||P_All_Or_Error);  
  /*   Begin                                             ----------DEFECT 30541
     Select Set_Of_Books_Id
     Into Lc_Set_Of_Book_Id
     From Gl_Sets_Of_Books
     Where Name=P_Set_Of_Book_Id;
     Exception
     When OTHERS
     Then 
     Lc_Set_Of_Book_Id:='ALL';   
     End;*/
     
    lb_layout    := fnd_request.add_layout( 'XXFIN' ,'XXOD_GL_INT_MAINS' ,'en' ,'US' ,'EXCEL' );
    ln_request_id:=FND_REQUEST.SUBMIT_REQUEST ( 'XXFIN' --application name
    ,'XXOD_GL_INT_MAINS'                                --short name of the AP concurrent program
    ,''                                                 -- description
    ,SYSDATE                                           --- start time
    ,FALSE                                              -- sub request
    ,P_SET_OF_BOOK_ID        --parameter3                        ------------Parameter1 Defect #29970
    ,P_START_PERIOD                                    --parameter1
    ,P_END_PERIOD                                      --parameter2
    ,P_All_Or_Error    );           ------------ Added for defect 30254
    COMMIT;
    lb_wait          := fnd_concurrent.wait_for_request (ln_request_id, 20, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
    IF ln_request_id <> 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OD: Journal GL Interface Report has been submitted and the request id is: '||ln_request_id);
      IF lc_dev_status    ='E' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN ERROR';
        x_ret_code       := 2;
      ELSIF lc_dev_status ='G' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN WARNING';
        x_ret_code       := 1;
      ELSE
        x_errbuf   := 'PROGRAM COMPLETED NORMAL';
        x_ret_code := 0;
      END IF;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report is not submitted');
    END IF;
  END ;
End Xxod_Gl_Int_Mains_Pkg;
/

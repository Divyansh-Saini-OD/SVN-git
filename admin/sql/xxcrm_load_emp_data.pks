/******************************************************************************
*
* File Name   : xxcrm_load_emp_data.pks
* Created By  : Phil Price
* Created Date: 08-SEP-2007
* Description : This file contains the procedures to synchronize Oracle HR data
*               using employee data supplied from an external system.
*
* Comments    :  
*
* Modification History
*
* 08-Sep-2007   Phil Price   Initial version.
* 10-Oct-2007   Phil Price   Ability to create emps without fnd_user record.
*
******************************************************************************/

create or replace package xxcrm_load_emp_data as

G_PACKAGE       CONSTANT        VARCHAR2(30) := 'XXCRM_LOAD_EMP_DATA';

procedure do_main (errbuf                    out varchar2,
                   retcode                   out number,
                   p_max_warnings            in  number    default 100,
                   p_process_emps            in  varchar2  default 'Y',
                   p_process_mgr_assignments in  varchar2  default 'Y',
                   p_check_missing_emps      in  varchar2  default 'Y',
                   p_auto_update_when_null   in  varchar2  default 'N',  -- pgm updates ppf recs w/ null attr1
                   p_allow_missing_fnd_user  in  varchar2  default 'N',
                   p_process_one_emp         in  varchar2  default null,
                   p_commit_flag             in  varchar2  default 'Y',
                   p_debug_level             in  number    default  0,
                   p_sql_trace               in  varchar2  default 'N'); 

end xxcrm_load_emp_data;
/

show errors

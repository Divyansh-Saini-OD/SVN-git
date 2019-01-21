CREATE OR REPLACE PACKAGE XX_TM_ASSIGN_RESOURCE_TO_TERR AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_TM_ASSIGN_RESOURCE_TO_TERR.pks                         |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- | Description :  Assigns sales reps to territories                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version     Date          Author              Remarks                     |
-- |========  =========== ==================  ================================|
-- |1.0       14-APR-2009  Phil Price         Initial version                 |
-- +==========================================================================+


procedure do_main (errbuf           out varchar2,
                   retcode          out number,
                   p_region_name    in  varchar2,
                   p_verbose_mode   in  varchar2  default 'N',
                   p_simulate_mode  in  varchar2  default 'N',
                   p_commit_flag    in  varchar2  default 'Y',
                   p_debug_level    in  number    default 0,
                   p_sql_trace      in  varchar2  default 'N');

end xx_tm_assign_resource_to_terr;
/

show errors

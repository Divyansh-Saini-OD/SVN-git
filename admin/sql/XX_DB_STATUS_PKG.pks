SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_DB_STATUS_PKG AUTHID CURRENT_USER

-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                                                                                         |
-- +=========================================================================================+
-- | Name        : XX_DB_STATUS_PKG                                                          |
-- | Description : Custom package specification for d/b status CRM data.                     |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        07-Jan-2009     Naga Kalyan          Initial Draft to output from database    |
-- |                                                system tables.                           |
-- +=========================================================================================+

AS

g_translate_name  constant varchar2(30)  := 'XX_PROD_MODULES_MAPPING'; 
g_prod_family     varchar2(30)  ; 
-- +===================================================================+
-- | Name        : get_bg_processes                                    |
-- |                                                                   |
-- | Description : Show the background processes.                      |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+


procedure get_bg_processes 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);
procedure view_source 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);procedure show_table_status 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);
-- +===================================================================+
-- | Name        : get_locks                                           |
-- |                                                                   |
-- | Description : Show the existing locks.                            |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure get_locks 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);

-- +===================================================================+
-- | Name        : get_invalid_objects                                 |
-- |                                                                   |
-- | Description : Show the invalid state objects.                     |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure get_invalid_objects 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);

-- +===================================================================+
-- | Name        : get_conc_prog_processes                             |
-- |                                                                   |
-- | Description : Show the invalid state objects.                     |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+
procedure get_conc_prog_processes 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
);

-- +===================================================================+
-- | Name        : execute_all_procs                                   |
-- |                                                                   |
-- | Description : Execute all procedures in this package.             |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure execute_all_procs 
(
    p_module_name IN           VARCHAR2 := NULL
    ,p_comp_op      IN          VARCHAR2
    ,x_retcode    OUT NOCOPY   VARCHAR2
    ,x_errbuf     OUT NOCOPY   VARCHAR2
);

PROCEDURE main_proc
(	
 
     x_errbuf       OUT NOCOPY   VARCHAR2
    ,x_retcode      OUT NOCOPY   VARCHAR2
    ,p_prod_family  IN          VARCHAR2
    ,p_proc_name    IN          VARCHAR2
    ,p_comp_op      IN          VARCHAR2
    ,p_module_name  IN          VARCHAR2 := NULL
);

END XX_DB_STATUS_PKG;
/
SHOW ERRORS;
EXIT;

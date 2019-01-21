SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE  xx_cdh_gp_report_pkg
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             :xx_cdh_gp_report_pkg.pks                            |
-- | Description      :OD: CDH Grandparent Maintenance                     |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     27-JUN-2011 Sreedhar Mohan     Initial Draft                  |
-- | 1.1     28-JUN-2011 Indra Varada       Code added for 2 new reports   |
-- |-------  ----------- -----------------  -------------------------------|
IS
--
--Procedure for Daily Grand Parent Changes Report
--
PROCEDURE gp_change_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            );
--
--Procedure for Grand Parent Active Status Report
--
PROCEDURE gp_active_status_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            );
--
--Procedure for Daily Grand Parent Hierarchy Changes Report
--
PROCEDURE gp_hierarchy_change_rpt
                            (  x_ret_code            OUT NOCOPY NUMBER
                              ,x_err_buf             OUT NOCOPY VARCHAR2
                              ,p_from_date           IN         VARCHAR2
                              ,p_to_date             IN         VARCHAR2
                            );
end xx_cdh_gp_report_pkg;
/
SHOW ERRORS;

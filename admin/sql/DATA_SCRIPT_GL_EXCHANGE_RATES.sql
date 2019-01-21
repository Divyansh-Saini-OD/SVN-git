-- Data script is being moved for the defect 4980/4981 Release 10.4
Delete from gl.gl_daily_rates_interface
where conversion_rate = 0;
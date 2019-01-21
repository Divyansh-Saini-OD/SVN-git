-- Defect 7550 Failure of Payables Import Purge program.
-- Sandeep Pandhare - 5/29/08

delete from ap.AP_INTERFACE_CONTROLS
where 1 = 1;

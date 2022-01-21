-- This should update 1262 records. 

UPDATE xx_gl_interface_na
SET segment6 = '80'
where status = 'EF04'
and user_je_source_name = 'OD COGS'
and request_id in (4740680
,4740702
,4748747
,4748776
,4740683
,4740668
,4740663
,4740672
,4740695);
COMMIT;
/
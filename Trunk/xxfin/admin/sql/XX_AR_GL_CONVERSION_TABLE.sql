-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | Name :     XX_AR_GL_CONVERSION_TABLE Conversion Script                   |
-- |                                                                          |
-- |            SQL Script to convert the data in XX_FIN_PROGRAN_STATS table  |
-- |             to the XX_GL_HIGH_VOLUME_JRNL_CONTROL table                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     05-JAN-2010  Sneha Anand           Initial version              |
-- |                                             Created for Defect 2851      |
-- |                                                                          |
-- +==========================================================================+
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | Name :     XX_AR_GL_CONVERSION_TABLE Conversion Script                   |
-- |                                                                          |
-- |            SQL Script to convert the data in XX_FIN_PROGRAN_STATS table  |
-- |             to the XX_GL_HIGH_VOLUME_JRNL_CONTROL table                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     05-JAN-2010  Sneha Anand           Initial version              |
-- |                                                                          |
-- +==========================================================================+
INSERT INTO XX_GL_HIGH_VOLUME_JRNL_CONTROL(request_id
                                          ,parent_request_id
                                          ,program_short_name
                                          ,concurrent_program_id
                                          ,program_application_id
                                          ,responsibility_id
                                          ,responsibility_application_id
                                          ,request_status
                                          ,request_start_date
                                          ,request_end_date
                                          ,user_je_source_name
                                          ,org_id
                                          ,set_of_books_id
                                          ,volume
                                          ,currency
                                          ,entered_dr
                                          ,entered_cr
                                          ,accounted_dr
                                          ,accounted_cr
                                          ,process_date
                                          ,event_number
                                          ,gl_interface_group_id
                                          ,interface_status
                                          ,journal_import_group_id
                                          ,request_argument_text
                                          ,creation_date
                                          ,created_by
                                          ,last_update_date
                                          ,last_updated_by
                                         )
                                         (
                                          SELECT   request_id
                                                  ,parent_request_id
                                                  ,program_short_name
                                                  ,concurrent_program_id
                                                  ,application_id
                                                  ,-1
                                                  ,-1
                                                  ,DECODE(request_status,'C','Completed','G','Warning')
                                                  ,request_start_time
                                                  ,request_end_time
                                                  ,'Receivables'
                                                  ,NVL(org_id,-1)
                                                  ,sob
                                                  ,count
                                                  ,currency
                                                  ,total_dr
                                                  ,total_cr
                                                  ,-1
                                                  ,-1
                                                  ,run_date
                                                  ,event_number
                                                  ,group_id
                                                  ,'IMPORTED'
                                                  ,-1
                                                  ,', , , ,'
                                                  ,SYSDATE
                                                  ,-1
                                                  ,SYSDATE
                                                  ,-1                                           
                                          FROM    xx_fin_program_stats
                                          WHERE   program_short_name='ARGLTP'
                                         );
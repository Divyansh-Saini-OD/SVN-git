create or replace PACKAGE XX_GI_SS_DAILY_IMPORT_PROCESS AS

/*
COMMENTS HERE
*/

v_start_time date;
v_end_time date;
v_nbr_inp_records number;
v_nbr_inserts     number;
v_trailer_count   number;
v_nbr_commits     number;
v_index_name varchar2(50);
v_table_name varchar2(50);

/*
This procedure will either a single job or ALL active jobs
*/
PROCEDURE XX_GI_SS_DAILY_BATCH(
                            p_job_name       IN        varchar2,
                            p_run_date       IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_step_name     OUT NOCOPY varchar2
                            );

/*
This procedure executes the various steps for each import. Truncate table,
drop index, load table, build index, check trailer counts.
*/
PROCEDURE XX_GI_SS_DAILY_BATCH_IMPORT(
                            p_job_name       IN        varchar2,
                            p_run_date       IN OUT NOCOPY    varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_step_name     OUT NOCOPY varchar2
                            );

/*
This procedure will load the FDATE source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_FDATE(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );

/*
This procedure will load the forecast source data from RDF
*/

PROCEDURE XX_GI_SS_IMPORT_FORECAST(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                   
                                               
/*
This procedure will load the ITEM source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_ITEM(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );

/*
This procedure will load the ITEMAUM source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_ITEMAUM(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );

/*
This procedure will load the ITEMLOC source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_ITEMLOC(
                            p_step_name      IN OUT NOCOPY  varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                            
                     
/*
This procedure will load the LOC source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_LOC(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                   

/*
This procedure will load the RDFMAD source data from Legacy
*/

PROCEDURE XX_GI_SS_IMPORT_RDFMAD(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                   
/*
This procedure will load the list of SKUs from RDF
*/

PROCEDURE XX_GI_SS_IMPORT_RDFSKU(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                   
/*
This procedure will load the SDG0282 source data from Legacy. 
This is the SS engine OUTPUT
*/

PROCEDURE XX_GI_SS_IMPORT_SDG0282(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
/*                   
This procedure will load the Product Hierarchy data from DB2.
*/

PROCEDURE XX_GI_SS_IMPORT_SKUHIER(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );

/*                   
This procedure will load the SS Parms data from DB2.
*/

PROCEDURE XX_GI_SS_IMPORT_SSPARMS(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
                                     
/*
This procedure will load the VENLOC source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_VENLOC(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
/*
This procedure will load the Vendor review time source data from Legacy
*/

PROCEDURE XX_GI_SS_IMPORT_VENRVT(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
               
/*
This procedure will load the VENLTV source data from Legacy
*/

PROCEDURE XX_GI_SS_IMPORT_VENLTV(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
               
/*
This procedure will load the VENTRD source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_VENTRD(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );
               
                          
/*
This procedure will load the WHSELOC source data from DB2
*/

PROCEDURE XX_GI_SS_IMPORT_WHSELOC(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );

/*
This procedure will load the WHSFCST source data from SDG0281
*/

PROCEDURE XX_GI_SS_IMPORT_WHSFCST(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );


/*
This procedure will load the job statistic table
*/ 

PROCEDURE XX_GI_SS_CAPTURE_JOB_STATS(
                            p_job_name      IN varchar2,
                            p_start_time    IN date,
                            p_end_time      IN date,
                            p_error_code    IN        varchar2,
                            p_error_message IN        varchar2,
                            p_row_count     IN number,
                            p_step_name     IN        varchar2,
                            p_process_flg   IN varchar2,
                            p_run_date      IN date,
                            p_start_step    IN varchar2
                            );   

                          
/*
This procedure will build the sku/warehouse forecast table for non-GSS
SKUs. Procedure XX_GI_SS_IMPORT_FORECAST must be run first.
*/ 

PROCEDURE XX_GI_SS_BUILD_WHSE_FCST_STG(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
                            
/*
This procedure will build the sku/loc/wic forecast table. Used to build the whse forecast
Procedure XX_GI_SS_IMPORT_FORECAST must be run first.
*/ 

PROCEDURE XX_GI_SS_BUILD_ITEMLOC_FCST(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   

/*
This procedure will build the sku/warehouse forecast table for GSS skus
Procedure XX_GI_SS_IMPORT_FORECAST must be run first.
*/ 

PROCEDURE XX_GI_SS_BUILD_WHSE_FCST_GSS(
                            p_step_name      IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
                            
/*
This procedure will build the Silver Bullet Master table
This should be the LAST job executed.
*/

PROCEDURE XX_GI_SS_BUILD_SB_MASTER(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   

/*
This procedure will UPDATE the Silver Bullet Master table
with the RDFMAD data.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_MAD_ARS(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   

/*
This procedure will UPDATE the Silver Bullet Master table
with the store forecast data.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_STR_FCST(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   

/*
This procedure will UPDATE the Silver Bullet Master table
with the Whse forecast data.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_WHS_FCST(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   

/*
This procedure will UPDATE the Silver Bullet Master table
with the lead time from either VENLOC or VENTRD.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_LEAD_TIME(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
        
/*
This procedure will UPDATE the Silver Bullet Master table
with the review_time fron VENRVT.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_REVIEW_TIME(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
        
/*
This procedure will UPDATE the Silver Bullet Master table
with the lead_time_variance fron VENLTV.
*/

PROCEDURE XX_GI_SS_UPDATE_SB_LT_VARIANCE(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
        
               
                                                            
/*
This procedure will build the Summarized forecast table
for all Itemloc sku/locs for the next 6 weeks of forecast
*/

PROCEDURE XX_GI_SS_BUILD_SUMMARIZED_FCST(
                            p_step_name     IN OUT NOCOPY varchar2,
                            p_start_record   IN        number,
                            p_source_file    IN        varchar2,
                            p_error_code    OUT NOCOPY varchar2,
                            p_error_message OUT NOCOPY varchar2,
                            p_row_count     OUT NOCOPY number,
                            p_start_time    OUT NOCOPY date,
                            p_end_time      OUT NOCOPY date
                            );   
                              
END;

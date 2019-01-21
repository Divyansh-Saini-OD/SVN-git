create or replace PACKAGE BODY HZ_BATCH_IMPORT_PKG AS
/*$Header: ARHIBASB.pls 120.29 2011/01/31 19:56:10 awu ship $ */
------------------------------------------------------------------------------------------------------------
-- 12.1.3 Changes
-- OfficeDepot: 11-Mar-2014    Sreedhar Mohan
-- Call to DQM Sync is commented out to not execute DQM Sync as a part of each bulk import batch
-- We need the staging/inserts into HZ_DQM_SYNC_INTERFACE, so that
-- a future sync job can be used to update the DQM staging tables.
-- The plan is to scheuled DQM Sync to run at specific times per day
-- All of the data in HZ_DQM_SYNC_INTERFACE will not be real-time from bulk import (Based on responsibility)
------------------------------------------------------------------------------------------------------------
-- 12.2.5 changes 
-- In 12.1.3 Call to DQM Sync process was controlled based on custom 
--  profile option 'OD: CDH Enable DQM during Conversion Post Processing'  in 12.2.5 version 
--  a seeded profile option 'HZ: DQM Synchronization Method' was added to restrict call to DQM Sync process
--  hence  the Customization is not needed
------------------------------------------------------------------------------------------------------------

/******
Pseudo code of hz_batch_import_pkg.import_batch
===============================================

Check database version

get id of last request from batch summary table
get status of the request
if (last stage is BATCH_DEDUP or ADDR_VAL) then
{
    if error then
    { update batch summary table and exit }
}
if (last stage is DATA_LOAD) then
{
    if (error) then
    {
	    update batch summary table
        update batch detail table
	    if(run is COMPLETE or CONTINUE) then
	    {
	        if(ran BATCH_DEDUP and REGISTRY_DEDUP) then
	        {
                call DQM cleanup routine
	        }
	        if(ran REGISTRY_DEDUP) then
	        {
	            call DQM interface tca sanitize report
                kick off automerge if necessary
	        }
            call post processing
			sleep
        }
		else if(run is WHAT_IF) then
		{
	        if(ran BATCH_DEDUP and REGISTRY_DEDUP) then
	        {
                call DQM cleanup routine
	        }
			skip
			set last_stage to POST_PROCESS (why? not necessary)
		}
		return
    }
}

if(request_data is null, i.e. first stage) then
{
    validate OS and OSR
    if(run is CONTINUE) then
	{
	    report error if pre-import has not been run
		report error if batch is already complete
	}

	if(current run is not the first run) then
	{
	    if(status of last run is not PENDING) then
		{
	        create entry in batch details
	    }
	else
    {
	    create entry in batch details
    }
}

if(run is WHAT_IF or COMPLETE) then
{
    if(request_data is null, i.e. first stage) then
    {
	    check availability of match rule id if any dedup
        update status of batch summary table
        if(what_if_flag='Y' in batch summary table, i.e.last run is what-if)
		{
		    (need to check if necessary before cleanup?)
		    clean up batch-dedup info
			clean up address validation info
            call dqm cleanup
        }
    }

    if(request_data is null, i.e. first stage and
	   run batch_dedup) then
	{
	  generate work units
	  run batch dedup
	  sleep
	}
	else
	{
        if(request_data is null, i.e. first stage and
	       NOT run batch_dedup) then
	    {
		    set request_data to SKIP_BATCH_DEDUP
			skip
		}
	}

	if(last stage is BATCH_DEDUP or SKIP_BATCH_DEDUP)
	{
	    if(run is COMPLETE and run batch_dedup) then
		{
		    apply batch dedup action
	    }
        if(run addr_val) then
	    {
	        submit address validation request
	        sleep
	    }
		else
		{
		    set request_data to SKIP_ADDR_DEDUP
			skip
		}
	}

	if(last stage is ADDR_VAL or SKIP_ADDR_VAL) then
	{
	    call DQM cleanup for staging reuse if ran registry dedup
	    submit concurrent request for dataload
		sleep
    }

	if(last stage is DATALOAD) then
	{
	    if(run is COMPLETE) then
		{
	        call the DQM cleanup routine if ran registry dedup or batch dedup
		    if(ran registry dedup) then
    	    {
		        call the report dupsets API
                update batch details
	            submit automerge request
			    call dataload postprocessing request
			    sleep
	        }
		}
		elseif(run is WHAT_IF) then
	    { (why is it possible to have this stage for WHAT-IF??)
		  call the DQM cleanup routine if ran batch or registry dedup
		  skip
		}
    }
}

if(run is CONTINUE) then
{
    if(request_data is null, i.e. first stage) then
    {
        update batch summmary table
		if(run batch dedup and
		   import_status was ACTION_REQUIRED) then
		{
		    apply batch dedup action
        }

        if(run registry dedup) then
		{
            apply registry dedup action
	    }
        submit dataload request
		sleep
    }

    if(last_stage is DATALOAD) then
	{
         call DQM post import cleanup if ran batch or registry dedup
         call the report dupsets API if ran registry dedup
		 submit automerge request
		 submit postprocessing request
		 sleep
    }

	if(last_stage is POST_PROCESS) then
	{
	  update batch summary table
    }
}
*******/


---------------------
-- private procedures
---------------------

PROCEDURE final_steps_whatif(
    p_batch_id                         IN             NUMBER,
    x_return_status                    OUT NOCOPY     VARCHAR2,
    x_msg_count                        OUT NOCOPY     NUMBER,
    x_msg_data                         OUT NOCOPY     VARCHAR2
)
IS

  l_reg_dedup   VARCHAR2(1);
  l_batch_dedup VARCHAR2(1);
BEGIN

  SELECT registry_dedup_flag, batch_dedup_flag
  INTO   l_reg_dedup, l_batch_dedup
  FROM   hz_imp_batch_summary
  WHERE  batch_id = p_batch_id;

  -- call the DQM cleanup routine
  IF l_reg_dedup = 'Y' OR l_batch_dedup = 'Y' THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** POST - Calling dqm_post_imp_cleanup');
    HZ_IMP_DQM_STAGE.dqm_post_imp_cleanup
      (p_batch_id => p_batch_id,
       x_return_status => x_return_status,
       x_msg_count     => x_msg_count,
       x_msg_data      => x_msg_data);
  END IF;

END;


PROCEDURE get_current_run(
    p_batch_id          IN         NUMBER,
    x_run_number        OUT NOCOPY NUMBER)
IS

  CURSOR c1 IS
    SELECT max(run_number)
    FROM   hz_imp_batch_details
    WHERE  batch_id = p_batch_id;

  l_run_number        NUMBER;

BEGIN

  OPEN c1;
  FETCH c1 INTO l_run_number;

  IF c1%NOTFOUND OR l_run_number IS NULL THEN
    l_run_number := 1;
  ELSE
    l_run_number := l_run_number+1;
  END IF;

  CLOSE c1;

  x_run_number := l_run_number;

END;

FUNCTION STAGING_DATA_EXISTS(
  P_BATCH_ID         IN NUMBER,
  P_BATCH_MODE_FLAG  IN VARCHAR2
) RETURN VARCHAR2 IS

  CURSOR c_what_if_sg_data(p_batch_id number, p_batch_mode_flag varchar2) IS
    SELECT 'Y'
    FROM dual
    WHERE EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_PARTIES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTPTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CREDITRTNGS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINREPORTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_FINNUMBERS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CLASSIFICS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_RELSHIPS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTROLES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_CONTACTS_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1)
    OR EXISTS (
    SELECT 'Y'
    FROM HZ_IMP_ADDRESSUSES_SG
    WHERE batch_id = p_batch_id
    AND batch_mode_flag = p_batch_mode_flag
    AND rownum = 1);

  l_what_if_sg_data_exists VARCHAR2(1);

BEGIN

    OPEN c_what_if_sg_data(P_BATCH_ID, P_BATCH_MODE_FLAG);
    FETCH c_what_if_sg_data INTO l_what_if_sg_data_exists;
    CLOSE c_what_if_sg_data;

fnd_file.put_line(FND_FILE.LOG, 'l_what_if_sg_data_exists = ' || l_what_if_sg_data_exists);
  RETURN NVL(l_what_if_sg_data_exists, 'N');
END STAGING_DATA_EXISTS;

/* Clean up staging. Delete for online, truncate for batch */
/* Also chean up the following tables:  */
/*     hz_imp_osr_change                */
/*     HZ_IMP_INT_DEDUP_RESULTS         */
/*     HZ_IMP_TMP_REL_END_DATE          */
PROCEDURE CLEANUP_STAGING(
  P_BATCH_ID         IN NUMBER,
  P_BATCH_MODE_FLAG  IN VARCHAR2
) IS
l_bool BOOLEAN;
l_status VARCHAR2(255);
l_schema VARCHAR2(255);
l_tmp    VARCHAR2(2000);
--l_debug_prefix	VARCHAR2(30) := '';
BEGIN

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
	hz_utility_v2pub.debug(p_message=>'WRP:CLEANUP_STAGING()+',
	                       p_prefix=>'',
			       p_msg_level=>fnd_log.level_procedure);
  END IF;

  l_bool := fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_schema);

  IF P_BATCH_MODE_FLAG = 'Y' THEN

fnd_file.put_line(FND_FILE.LOG, ' l_schema = ' || l_schema);

    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_PARTIES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_ADDRESSES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTPTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CREDITRTNGS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CLASSIFICS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_FINREPORTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_FINNUMBERS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_RELSHIPS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTS_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_CONTACTROLES_SG TRUNCATE PARTITION batchpar DROP STORAGE';
    execute immediate 'ALTER TABLE ' || l_schema || '.HZ_IMP_ADDRESSUSES_SG TRUNCATE PARTITION batchpar DROP STORAGE';

  ELSE
    DELETE HZ_IMP_PARTIES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_ADDRESSES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTPTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CREDITRTNGS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CLASSIFICS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_FINREPORTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_FINNUMBERS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_RELSHIPS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTS_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_CONTACTROLES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;
    DELETE HZ_IMP_ADDRESSUSES_SG
     WHERE batch_id = P_BATCH_ID
     AND batch_mode_flag = P_BATCH_MODE_FLAG;

  END IF;

  DELETE hz_imp_osr_change WHERE batch_id = P_BATCH_ID;
  --DELETE HZ_IMP_INT_DEDUP_RESULTS WHERE batch_id = P_BATCH_ID;
  DELETE HZ_IMP_TMP_REL_END_DATE WHERE batch_id = P_BATCH_ID;

  IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
	hz_utility_v2pub.debug(p_message=>'WRP:CLEANUP_STAGING()-',
	                       p_prefix=>'',
			       p_msg_level=>fnd_log.level_procedure);
  END IF;
  COMMIT;
END CLEANUP_STAGING;

--------------------
-- public procedures
--------------------

/**
 * PROCEDURE import_batch
 *
 * DESCRIPTION
 *     Concurrent program for importing batch
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   09-JUL-2003    Indrajit Sen        o Created.
 *
 */

PROCEDURE import_batch (
    errbuf                             OUT NOCOPY     VARCHAR2,
    retcode                            OUT NOCOPY     VARCHAR2,
    p_batch_id                         IN             NUMBER,
    p_import_run_option                IN             VARCHAR2,
    p_run_batch_dedup                  IN             VARCHAR2,
    p_batch_dedup_rule_id              IN             NUMBER,
    p_batch_dedup_action               IN             VARCHAR2,
    p_run_addr_val                     IN             VARCHAR2,
    p_run_registry_dedup               IN             VARCHAR2,
    p_registry_dedup_rule_id           IN             NUMBER,
    p_run_automerge                    IN             VARCHAR2 := 'N',
    p_generate_fuzzy_key               IN             VARCHAR2 := 'Y'
    /*,
/*
    p_bd_action_on_parties             IN             VARCHAR2 DEFAULT NULL,
    p_bd_action_on_addresses           IN             VARCHAR2 DEFAULT NULL,
    p_bd_action_on_contacts            IN             VARCHAR2 DEFAULT NULL,
    p_bd_action_on_contact_points      IN             VARCHAR2 DEFAULT NULL
*/
)
IS

  -- cursor to get the batch information
  cursor c_batch_info
  is
  select * from hz_imp_batch_summary
  where batch_id = p_batch_id;

  r_batch_info  c_batch_info%ROWTYPE;

  l_return_status                    VARCHAR2(1);
  l_msg_count                        NUMBER;
  l_msg_data                         VARCHAR2(255);
  /*
  l_bd_action_on_parties             VARCHAR2(30) := p_bd_action_on_parties;
  l_bd_action_on_addresses           VARCHAR2(30) := p_bd_action_on_addresses;
  l_bd_action_on_contacts            VARCHAR2(30) := p_bd_action_on_contacts;
  l_bd_action_on_contact_points      VARCHAR2(30) := p_bd_action_on_contact_points;
  */
  l_dup_batch_id                     NUMBER;
  l_bd_sub_request                   NUMBER;
  l_av_sub_request                   NUMBER;
  l_dl_sub_request                   NUMBER;
  l_num_of_workers                   NUMBER;
  l_req_data                         VARCHAR2(30);
  l_dataload_rerun                   VARCHAR2(30);
  l_what_if                          VARCHAR2(1);
  l_current_run                      NUMBER;
  l_last_req                         NUMBER;
  l_temp_rphase                      VARCHAR2(80);
  l_temp_rstatus                     VARCHAR2(80);
  l_temp_dphase                      VARCHAR2(30);
  l_temp_dstatus                     VARCHAR2(30);
  l_temp_message                     VARCHAR2(240);
  l_call_status                      BOOLEAN;
  l_ver                              NUMBER;
  l_str                              VARCHAR2(2000);
  l_last_run_imp_status              VARCHAR2(30);
  l_work_unit                        VARCHAR2(1);
  --l_reg_dedup                        VARCHAR2(1);
  l_pp_sub_request                   NUMBER;
  l_am_sub_request                   NUMBER;
  l_automerge_flag                   VARCHAR2(30);
  l_rule_id_missing                  BOOLEAN;

  l_index_conc_program_req_id        NUMBER;

  os_exists_flag                     VARCHAR2(1) :='N'; /* Bug 4079902 */
  l_batch_mode_flag                  VARCHAR2(1);
  l_post_process_flag                VARCHAR2(1) := 'N';
  l_wng_msg                          VARCHAR2(1000) := 'WARNING****';

  l_pp_error                         VARCHAR2(1) := 'N';

  CURSOR c_batch_status(p_batch_id number) IS
    select bs.import_status
    from hz_imp_batch_details bs
    where bs.batch_id = p_batch_id
    and run_number = (select max(run_number)
                      from hz_imp_batch_details
    	              where batch_id = p_batch_id);

  CURSOR c_pp_error(p_batch_id number) IS
    select 'Y'
    from hz_imp_work_units
    where batch_id=p_batch_id
    and (postprocess_status is null
    OR postprocess_status='U')
    and rownum=1;
BEGIN
  -- check the database version and exit if not 9i and higher
  SELECT REPLACE(substr(version,  1, instr(version, '.', 1, 3)),'.')
  INTO l_ver
  FROM v$instance;

  IF l_ver < 920 THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** FATAL ERROR: The feature is only available for Oracle 9iR2 or higher');
    RETURN;
  END IF;

  l_req_data := fnd_conc_global.request_data;
  l_work_unit := 'N';

  -----------------------------------------------------
  -- get the batch information from batch summary table
  -----------------------------------------------------
  open c_batch_info;
  fetch c_batch_info into r_batch_info;
  close c_batch_info;

    BEGIN
    -- This check shall indicate that atleast some workers have finished stage 2
    -- and hence post processing needs to be done for them.
    SELECT 'Y' INTO l_post_process_flag
    FROM HZ_IMP_WORK_UNITS
    WHERE batch_id=p_batch_id
    AND (
         (stage>=2
          AND status='C')
        -- to take care of the case when unexpected error in stage 3 and just 1 work unit
        OR
         (stage=3
          AND status='P')
        )
    AND rownum=1;
    EXCEPTION
    WHEN OTHERS THEN NULL;
    END;

  IF r_batch_info.load_type = 'CSV' THEN
    l_batch_mode_flag := 'N';
  ELSE
    l_batch_mode_flag := 'Y';
  END IF;

  --------------------------------------------------------
  -- Check what the last stage is, get the last request id
  --------------------------------------------------------
  -- check for any error that has happened and discontinue if error
  IF l_req_data = 'BATCH_DEDUP' THEN
    l_last_req := r_batch_info.batch_dedup_req_id;
  ELSIF l_req_data = 'ADDR_VAL' THEN
    l_last_req := r_batch_info.addr_val_req_id;
  ELSIF l_req_data = 'DATA_LOAD' THEN
    l_last_req := r_batch_info.import_req_id;
  END IF;

  l_call_status := fnd_concurrent.get_request_status(
    l_last_req,
    null,
    null,
    l_temp_rphase,
    l_temp_rstatus,
    l_temp_dphase,
    l_temp_dstatus,
    l_temp_message);

  -----------------------------------------
  -- Report error if problem im batch dedup
  -----------------------------------------
  IF l_req_data = 'BATCH_DEDUP'
     AND
     (l_temp_dstatus <> 'NORMAL' OR r_batch_info.batch_dedup_status = 'ERROR')
  THEN
    UPDATE hz_imp_batch_summary
    SET batch_dedup_status = 'ERROR',
        batch_status = 'ACTION_REQUIRED',
        main_conc_status = 'COMPLETED'
    WHERE batch_id = p_batch_id;

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Batch de-duplication program errored...exiting');
    retcode := 1;
    errbuf := 'WARNING**** Unexpected error occured Batch de-duplication program.';
    RETURN;
  END IF;

  ---------------------------------------------
  -- Report error if problem in addr validation
  ---------------------------------------------
  IF l_req_data = 'ADDR_VAL'
     AND
     (l_temp_dstatus <> 'NORMAL' OR r_batch_info.addr_val_status = 'ERROR')
  THEN
    UPDATE hz_imp_batch_summary
    SET addr_val_status = 'ERROR',
        batch_status = 'ACTION_REQUIRED',
        main_conc_status = 'COMPLETED'
    WHERE batch_id = p_batch_id;

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Address validation program errored...exiting');
    retcode := 1;
    errbuf := 'WARNING****** Unexpected error occured Address validation program.';
    RETURN;
  END IF;

  ---------------------------------------------
  -- Report error if problem in data load
  ---------------------------------------------
  IF l_req_data = 'DATA_LOAD'
     AND
     (l_temp_dstatus <> 'NORMAL' OR r_batch_info.import_status = 'ERROR')
  THEN
   UPDATE hz_imp_batch_summary
    SET import_status = 'ERROR',
        batch_status = 'ACTION_REQUIRED',
        main_conc_status = 'COMPLETED'
    WHERE batch_id = p_batch_id;


    --------------------------------------------------
    -- get last entry in batch detail table and update
    --------------------------------------------------
    get_current_run(
      p_batch_id          => p_batch_id,
      x_run_number        => l_current_run);
    UPDATE hz_imp_batch_details
    SET import_status = 'ERROR'
    WHERE batch_id = p_batch_id
    AND   run_number = l_current_run;

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Data load program errored...exiting');
    -- since the data load might have run partially, there is a need to perform the
    -- post-processing here
    -- final steps on import
    fnd_file.put_line(FND_FILE.LOG, 'UIC***** Performing the post processes');

    IF p_import_run_option = 'COMPLETE' OR p_import_run_option = 'CONTINUE' THEN

      -- retrieve number of workers
      IF r_batch_info.load_type = 'CSV' THEN
        l_num_of_workers := 1;
      ELSE
        l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
        IF l_num_of_workers IS NULL THEN
          l_num_of_workers := 1;
        END IF;
      END IF;

      -- call the DQM cleanup routine
      IF r_batch_info.registry_dedup_flag = 'Y' OR r_batch_info.batch_dedup_flag = 'Y' THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM post import cleanup');
        HZ_IMP_DQM_STAGE.dqm_post_imp_cleanup
          (p_batch_id      => p_batch_id,
           x_return_status => l_return_status,
           x_msg_count     => l_msg_count,
           x_msg_data      => l_msg_data);
      END IF;

      IF l_post_process_flag='Y'
      THEN
      IF NVL(r_batch_info.registry_dedup_flag,'N') = 'Y' THEN

        -- call the report dupsets API
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM interface tca sanitize report');
        HZ_DQM_DUP_ID_PKG.interface_tca_sanitize_report
          (p_batch_id      => p_batch_id,
           p_match_rule_id => p_registry_dedup_rule_id,
           p_request_id    => fnd_global.conc_request_id,
           x_dup_batch_id  => l_dup_batch_id,
           x_return_status => l_return_status,
           x_msg_count     => l_msg_count,
           x_msg_data      => l_msg_data);

        -- l_current_run already set, can comment this out
        /*
        get_current_run(                                --
          p_batch_id          => p_batch_id,            --
          x_run_number        => l_current_run);        --
        */
        UPDATE hz_imp_batch_details
        SET dup_batch_id = l_dup_batch_id
        WHERE batch_id = p_batch_id
        AND   run_number = l_current_run;

        ------------------------------------------
        -- if automerge flag, kick off the process
        ------------------------------------------
        IF p_run_automerge = 'Y' THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking auto merge post process');
            l_am_sub_request := FND_REQUEST.SUBMIT_REQUEST(
              'AR',
              'ARHAMRGP',
              '',
              to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
              true,
              to_char(l_dup_batch_id),
              to_char(l_num_of_workers)
              );

          IF l_am_sub_request = 0 THEN
            fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting auto merge post process');
          ELSE
            fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for auto merge post process');
          END IF;

        END IF;  --nvl(l_automerge_flag,'N') = 'Y'

      END IF;  --NVL(l_reg_dedup,'N') = 'Y'

        IF (Nvl(FND_PROFILE.VALUE('HZ_DQM_ENABLE_REALTIME_SYNC'),'Y') <> 'DISABLE') THEN --Bug 10435345
        -- Bug 4594407 : Call DQM Sync Index
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Calling Parallel Sync Index concurrent program');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of the program to be waited on, that is being passed to this : ' || fnd_global.conc_request_id );
        l_index_conc_program_req_id := FND_REQUEST.SUBMIT_REQUEST('AR',
                                         'ARHDQMPP',
                                         'DQM Parallel Sync Index Parent Program',
                                         NULL,
                                         FALSE,
                                         fnd_global.conc_request_id
                                         );
        IF l_index_conc_program_req_id = 0 THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error submitting DQM Sync Index Program.');
        ELSE
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of Parallel Sync concurrent Program is  : ' || l_index_conc_program_req_id );
        END IF;
        END IF;

      -- call dataload post processing
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking data load post process');
      FOR i IN 1..l_num_of_workers LOOP
        l_pp_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHLPPLB',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id,
          r_batch_info.original_system,
          l_batch_mode_flag,
          to_char(fnd_global.conc_request_id),
          'N' -- p_generate_fuzzy_key
          );

        IF l_pp_sub_request = 0 THEN
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting data load post processing ' || l_num_of_workers);
        ELSE
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for data load  post processing ' || l_num_of_workers);
        END IF;
      END LOOP;

      -- wait for the conc program to finish
      fnd_conc_global.set_req_globals(
        conc_status => 'PAUSED',
        request_data => 'POST_PROCESS');
      ELSE
        fnd_conc_global.set_req_globals(
        conc_status => 'NORMAL',
        request_data => 'POST_PROCESS');
        l_req_data := 'POST_PROCESS'; -- not necessary
    retcode := 1;
    errbuf := 'WARNING**** Unexpected error occured in the Data Load program';
      END IF;

    ELSIF p_import_run_option = 'WHAT_IF' THEN

      final_steps_whatif(
        p_batch_id                         => p_batch_id,
        x_return_status                    => l_return_status,
        x_msg_count                        => l_msg_count,
        x_msg_data                         => l_msg_data
       );

    fnd_conc_global.set_req_globals(
        conc_status => 'NORMAL',
        request_data => 'POST_PROCESS');
        l_req_data := 'POST_PROCESS'; -- not necessary
    retcode := 1;
    errbuf := 'WARNING**** Unexpected error occured in the Data Load program';

    END IF; -- p_import_run_option = 'COMPLETE'/'WHAT_IF'

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
        RETURN;
    END IF;

    RETURN;
  END IF;

  -----------------------------
  -- do the one time processing
  -----------------------------

  IF l_req_data IS NULL THEN
    ------------------------------
    -- print the parameters passed
    ------------------------------
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Parameters passed');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** -----------------');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Batch ID: '||p_batch_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Import Run Option: '||p_import_run_option);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Run Batch Dedup?: '||p_run_batch_dedup);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Batch dedup rule id: '||p_batch_dedup_rule_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Batch dedup action: '||p_batch_dedup_action);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Run addr val?: '||p_run_addr_val);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Run registry dedup?: '||p_run_registry_dedup);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Registry dedup rule id?: '||p_registry_dedup_rule_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Run Automerge?: '||p_run_automerge);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** -----------------');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');

    ---------------------
    -- validate the batch
    ---------------------

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Validating the batch');

    -- Bug 4079902. Validated orig_system against HZ_ORIG_SYSTEMS_B instead of
    -- the lookup.

    -- validate original_system against lookup ORIG_SYSTEM
    /*
    hz_utility_v2pub.validate_lookup (
        p_column                 => 'original_system',
        p_lookup_type            => 'ORIG_SYSTEM',
        p_column_value           => r_batch_info.original_system,
        x_return_status          => l_return_status);
    */
    BEGIN
    SELECT 'Y' INTO os_exists_flag
    FROM hz_orig_systems_b
    WHERE
    orig_system= r_batch_info.original_system
    AND orig_system<>'SST'
    AND status='A';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME('AR','HZ_API_INVALID_FK');
        FND_MESSAGE.SET_TOKEN('FK','orig_system');
        FND_MESSAGE.SET_TOKEN('COLUMN','orig_system');
        FND_MESSAGE.SET_TOKEN('TABLE','HZ_ORIG_SYSTEMS_B');

        -- Bug 4530477
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error***** '||FND_MESSAGE.GET);

        UPDATE hz_imp_batch_summary
        SET main_conc_status = 'ERROR',
        batch_status = 'ACTION_REQUIRED'
        WHERE batch_id = p_batch_id;

        Errbuf := fnd_message.get;
        Retcode := 2;

        RETURN;
    END;

    BEGIN
      IF p_run_registry_dedup = 'Y'
         and p_registry_dedup_rule_id IS NOT NULL
      THEN
        IF p_run_automerge='Y' THEN
          SELECT automerge_flag
          INTO   l_automerge_flag
          FROM   hz_match_rules_b
          WHERE  match_rule_id = p_registry_dedup_rule_id;

          IF l_automerge_flag is NULL
          or l_automerge_flag='N'
          THEN

            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error***** '||'The Match Rule selected for Registry De-duplication does not allow Automerge. Please resubmit the batch for import and select No for request parameter Run Automerge.');

            UPDATE hz_imp_batch_summary
            SET main_conc_status = 'ERROR',
            batch_status = 'ACTION_REQUIRED'
            WHERE batch_id = p_batch_id;

            Errbuf := 'The Match Rule selected for Registry De-duplication does not allow Automerge. Please resubmit the batch for import and select No for request parameter Run Automerge.';
            Retcode := 1;

            RETURN;
         END IF;
        END IF;
        UPDATE HZ_IMP_BATCH_SUMMARY
        SET AUTOMERGE_FLAG=p_run_automerge
        WHERE batch_id=p_batch_id;
     END IF;
    END;

    -- validate that if it request for CONTINUE, that the what-if has
    -- already been performed
    IF p_import_run_option = 'CONTINUE' THEN

        IF not ( NVL(r_batch_info.import_status,'X') in
                 ( 'ACTION_REQUIRED', 'COMPL_ERROR_LIMIT', 'COMPL_ERRORS' )) THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Pre-import has not been performed for this batch.');
            UPDATE hz_imp_batch_summary
            SET batch_status = 'ACTION_REQUIRED'
            WHERE batch_id = p_batch_id;
            RETURN;
        END IF;
    END IF;

    -- validate that the batch is not already completed one
    IF NVL(r_batch_info.import_status,'X') = 'COMPLETED' THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** The batch has already been completed.');
        RETURN;
    END IF;

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Completed validation');

    -- update batch summary table and create row in batch detail table
    get_current_run(
      p_batch_id          => p_batch_id,
      x_run_number        => l_current_run);

    IF l_current_run > 1 THEN

      -- get import_status of last run
      select import_status
      into l_last_run_imp_status
      from hz_imp_batch_details
      where batch_id = p_batch_id
      and run_number = l_current_run - 1;

      IF l_last_run_imp_status <> 'PENDING' THEN
        -- create an entry in the batch details table
        INSERT INTO hz_imp_batch_details
          (batch_id,
           run_number,
           import_status,
           import_req_id,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login,
           main_conc_req_id)
         values
           (p_batch_id,
           l_current_run,
           'PENDING',
           null,
           HZ_UTILITY_V2PUB.created_by,
           HZ_UTILITY_V2PUB.creation_date,
           HZ_UTILITY_V2PUB.last_updated_by,
           HZ_UTILITY_V2PUB.last_update_date,
           HZ_UTILITY_V2PUB.last_update_login,
           fnd_global.conc_request_id);

         FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Created entry in batch details table');

      END IF;  -- l_last_run_imp_status <> 'PENDING'

    ELSE

      -- create an entry in the batch details table
      INSERT INTO hz_imp_batch_details
        (batch_id,
         run_number,
         import_status,
         import_req_id,
         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,
         main_conc_req_id)
       values
         (p_batch_id,
         l_current_run,
         'PENDING',
         null,
         HZ_UTILITY_V2PUB.created_by,
         HZ_UTILITY_V2PUB.creation_date,
         HZ_UTILITY_V2PUB.last_updated_by,
         HZ_UTILITY_V2PUB.last_update_date,
         HZ_UTILITY_V2PUB.last_update_login,
         fnd_global.conc_request_id);

     FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Created entry in batch details table');

    END IF;

  END IF; -- l_req_data IS NULL

  /* Clean up staging tables if previous run did not complete successfully */
  /* Get latest batch details status */
  IF l_req_data is null THEN
    IF ((l_last_run_imp_status <> 'ACTION_REQUIRED' OR p_import_run_option <> 'CONTINUE') OR
      (l_last_run_imp_status = 'ACTION_REQUIRED' AND p_import_run_option = 'CONTINUE'
       AND l_batch_mode_flag = 'Y' AND
       STAGING_DATA_EXISTS(p_batch_id, l_batch_mode_flag) <> 'Y')) THEN
      CLEANUP_STAGING(p_batch_id, l_batch_mode_flag);
    END IF;
  END IF;

  -----------------------------------
  -- count total records in the batch
  -----------------------------------


  -----------------------
  -- start business logic
  -----------------------

  -- //////////////////////////
  -- what if or complete import
  -- //////////////////////////

  -- if it is what-if or complete import, then do the following.
  -- the basic flow is same, except for a few things.
  -- the different things are done using the actual option.
  IF (p_import_run_option = 'WHAT_IF'
      OR
      p_import_run_option = 'COMPLETE') THEN

    IF l_req_data IS NULL THEN
      -- check if the right parameters have been passed,
      -- otherwise error out
      -- if no match rule has been provided, error out
      IF (p_run_batch_dedup = 'Y' and p_batch_dedup_rule_id IS NULL) THEN
        l_rule_id_missing := true;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** FATAL ERROR: No match rule provided for batch dedup.');
      END IF;
      IF (p_run_registry_dedup = 'Y' and p_registry_dedup_rule_id IS NULL) THEN
        l_rule_id_missing := true;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** FATAL ERROR: No match rule provided for registry dedup.');
      END IF;

      IF (l_rule_id_missing) then
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Data Import cannot proceed, exit with error');
        UPDATE hz_imp_batch_summary
          SET main_conc_status = 'ERROR'
          WHERE batch_id = p_batch_id;
        retcode := 2;
        RETURN;
      END IF;

      -- set the processing status appropriately
      UPDATE hz_imp_batch_summary
      SET batch_dedup_flag = decode(p_run_batch_dedup, 'Y', 'Y', 'N'),
          batch_dedup_status = decode(p_run_batch_dedup, 'Y', 'PENDING', 'DECLINED'),
          batch_dedup_match_rule_id = decode(p_run_batch_dedup, 'Y', p_batch_dedup_rule_id, null),
          addr_val_flag = decode(p_run_addr_val, 'Y', 'Y', 'N'),
          addr_val_status = decode(p_run_addr_val, 'Y', 'PENDING', 'DECLINED'),
          registry_dedup_flag = decode(p_run_registry_dedup, 'Y', 'Y', 'N'),
          registry_dedup_match_rule_id = decode(p_run_registry_dedup, 'Y', p_registry_dedup_rule_id, null),
          import_status = 'PENDING',
          what_if_flag = decode(p_import_run_option, 'WHAT_IF', 'Y', 'N'),
          main_conc_status = 'PROCESSING',
          batch_status = 'PROCESSING',
          main_conc_req_id = fnd_global.conc_request_id,
          bd_action_on_parties = NVL(p_batch_dedup_action,bd_action_on_parties),
          bd_action_on_addresses = NVL(p_batch_dedup_action,bd_action_on_addresses),
          bd_action_on_contacts = NVL(p_batch_dedup_action,bd_action_on_contacts),
          bd_action_on_contact_points = NVL(p_batch_dedup_action,bd_action_on_contact_points)
      WHERE batch_id = p_batch_id;

      -- do some cleanup if it is a rerun after what-if
      IF r_batch_info.what_if_flag = 'Y' THEN
        -- cleanup the previous what-if results
        -- 1. call batch deduplication cleanup routine
        -- 2. call registry deduplication cleanup routine
        -- it is the same cleanup routine that does both the above.
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Cleaning up batch de-duplication actions');
        HZ_BATCH_ACTION_PUB.clear_status(
          p_batch_id         => p_batch_id,
          x_return_status    => l_return_status);

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
            RETURN;
        END IF;

        -- 3. cleanup address validation information
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Cleaning up address validation actions');
        UPDATE hz_imp_addresses_int
        SET VALIDATION_SUBSET_ID = null,
            ACCEPT_STANDARDIZED_FLAG = null,
            ADAPTER_CONTENT_SOURCE = null,
            ADDR_VALID_STATUS_CODE = null,
            DATE_VALIDATED = null,
            ADDRESS1_STD = null,
            ADDRESS2_STD = null,
            ADDRESS3_STD = null,
            ADDRESS4_STD = null,
            CITY_STD = null,
            PROV_STATE_ADMIN_CODE_STD = null,
            COUNTY_STD = null,
            COUNTRY_STD = null,
            POSTAL_CODE_STD = null
        WHERE batch_id = p_batch_id;

        -- 4. call dqm cleanup routine
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM pre-import cleanup');
        IF p_run_batch_dedup = 'Y' OR p_run_registry_dedup = 'Y' THEN
          HZ_IMP_DQM_STAGE.dqm_pre_imp_cleanup(
            p_batch_id           => p_batch_id,
            x_return_status      => l_return_status,
            x_msg_count          => l_msg_count,
            x_msg_data           => l_msg_data);

          IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
              RETURN;
          END IF;

        END IF;  -- p_run_batch_dedup = 'Y' OR p_run_registry_dedup = 'Y'

      END IF; -- r_batch_info.what_if_flag = 'Y'

    END IF; -- l_req_data IS NULL

    -- calculate number of workers
    IF r_batch_info.load_type = 'CSV' THEN
      l_num_of_workers := 1;
    ELSE
      l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
      IF l_num_of_workers IS NULL THEN
        l_num_of_workers := 1;
      END IF;  --l_num_of_workers IS NULL
    END IF; --r_batch_info.load_type = 'CSV'

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Number of workers used : '||l_num_of_workers);

    -- call the batch deduplication process if needed.
    IF NVL(p_run_batch_dedup,'N') = 'Y' AND l_req_data IS NULL THEN
      l_str := 'begin HZ_IMP_LOAD_WRAPPER.DATA_LOAD_PREPROCESSING(:1,:2,:3,:4); end;';
      execute immediate l_str using p_batch_id, r_batch_info.original_system, l_what_if, OUT l_dataload_rerun;
      l_work_unit := 'Y';

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Called data load wrapper to generate work units');

      -- submit batch dedup program
      l_bd_sub_request := FND_REQUEST.SUBMIT_REQUEST(
        'AR',
        'ARHDIDIP',
        '',
        to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
        true,
        p_batch_id,
        p_batch_dedup_rule_id,
        l_num_of_workers
        );

      IF l_bd_sub_request = 0 THEN
        UPDATE hz_imp_batch_summary
        SET main_conc_status = 'COMPLETED',
            batch_status = 'ACTION_REQUIRED'
        WHERE batch_id = p_batch_id;
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting batch de-duplication');
        RETURN;
      ELSE
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for batch de-dupication');

        UPDATE hz_imp_batch_summary
        SET batch_dedup_req_id = l_bd_sub_request
        WHERE batch_id = p_batch_id;

      END IF;

      -- wait for the conc program to finish
      fnd_conc_global.set_req_globals(
        conc_status => 'PAUSED',
        request_data => 'BATCH_DEDUP');

    ELSE
      IF NVL(p_run_batch_dedup,'N') = 'N' AND l_req_data IS NULL THEN
        -- just set the l_req_data
        fnd_conc_global.set_req_globals(
        conc_status => 'NORMAL',
        request_data => 'SKIP_BATCH_DEDUP');
        l_req_data := fnd_conc_global.request_data;
      END IF;

    END IF; -- p_run_batch_dedup = 'Y' AND l_req_data IS NULL

    -- call the address validation process if needed.

    IF (l_req_data = 'BATCH_DEDUP' OR l_req_data = 'SKIP_BATCH_DEDUP')
    THEN
      -- apply the batch actions if this is a complete import run
      -- and batch de-duplication was performed
      IF p_import_run_option = 'COMPLETE' AND
         p_run_batch_dedup = 'Y'
      THEN
        HZ_BATCH_ACTION_PUB.batch_dedup_action(
          p_batch_id                 => p_batch_id,
          p_action_on_parties        => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_parties),
          p_action_on_addresses      => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_addresses),
          p_action_on_contacts       => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_contacts),
          p_action_on_contact_points => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_contact_points),
          x_return_status            => l_return_status,
          x_msg_data                 => l_msg_data,
          x_msg_count                => l_msg_count
          );

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
            RETURN;
        END IF;
      END IF; /***p_import_run_option = 'COMPLETE' AND p_run_batch_dedup = 'Y' ***/

      IF NVL(p_run_addr_val,'N') = 'Y' THEN
        -- submit address validation program
        l_av_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHADDRM',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id
          );

        IF l_av_sub_request = 0 THEN
          UPDATE hz_imp_batch_summary
             SET main_conc_status = 'COMPLETED',
                 batch_status = 'ACTION_REQUIRED'
           WHERE batch_id = p_batch_id;
           fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting address validation');
           RETURN;
        ELSE
           fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for addrress validation');

           UPDATE hz_imp_batch_summary
              SET addr_val_req_id = l_av_sub_request
            WHERE batch_id = p_batch_id;
        END IF;

        -- wait for the con program to finish
        fnd_conc_global.set_req_globals(
          conc_status => 'PAUSED',
          request_data => 'ADDR_VAL');
      else
        -- skip address validation
        fnd_conc_global.set_req_globals(
          conc_status => 'NORMAL',
          request_data => 'SKIP_ADDR_VAL');
          l_req_data := fnd_conc_global.request_data;
      end if;

    end if;

    -- call the data load process
    IF l_req_data = 'ADDR_VAL' OR l_req_data = 'SKIP_ADDR_VAL' THEN

      IF p_import_run_option = 'COMPLETE' THEN
        l_what_if := null;
      ELSIF p_import_run_option = 'WHAT_IF' THEN
        l_what_if := 'A';
      END IF;

      -- DQM cleanup for staging reuse
      IF r_batch_info.registry_dedup_flag = 'Y' THEN
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling DQM intermediate cleanup');
        HZ_IMP_DQM_STAGE.dqm_inter_imp_cleanup(
          p_batch_id        => p_batch_id,
          x_return_status   => l_return_status,
          x_msg_count       => l_msg_count,
          x_msg_data        => l_msg_data);

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
          RETURN;
        END IF;
      END IF;

      IF l_work_unit <> 'Y' THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling data load preprocessing for work unit calculation');
        l_str := 'begin HZ_IMP_LOAD_WRAPPER.DATA_LOAD_PREPROCESSING(:1,:2,:3,:4); end;';
        execute immediate l_str using p_batch_id, r_batch_info.original_system, l_what_if, OUT l_dataload_rerun;
      END IF;

      -- submit data load program
      IF r_batch_info.load_type = 'CSV' THEN
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling ARHLWRPO - Online Data Load');
        l_dl_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHLWRPO',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id,
          r_batch_info.original_system,
          l_what_if,
          NVL(p_run_registry_dedup,'N'),
          nvl(p_registry_dedup_rule_id, r_batch_info.registry_dedup_match_rule_id),
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          nvl(r_batch_info.error_limit,FND_PROFILE.value('HZ_IMP_ERROR_LIMIT')),
          l_dataload_rerun,
          fnd_global.conc_request_id,
          fnd_global.prog_appl_id,
          fnd_global.conc_program_id
          );

      ELSE
        -- generate number of workers
        -- wawong r_batch_info.load_type <> 'CSV' here
        /*
        IF r_batch_info.load_type = 'CSV' THEN
          l_num_of_workers := 1;
        ELSE
        */
          l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
          IF l_num_of_workers IS NULL THEN
            l_num_of_workers := 1;
          END IF;
       --END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'UIC***** Calculated number of workers : '||l_num_of_workers);
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling ARHLWRPB - Batch Data Load');

        l_dl_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHLWRPB',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id,
          r_batch_info.original_system,
          l_what_if,
          NVL(p_run_registry_dedup,'N'),
          nvl(p_registry_dedup_rule_id, r_batch_info.registry_dedup_match_rule_id),
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          l_num_of_workers,
          nvl(r_batch_info.error_limit,FND_PROFILE.value('HZ_IMP_ERROR_LIMIT')),
          l_dataload_rerun,
          fnd_global.conc_request_id,
          fnd_global.prog_appl_id,
          fnd_global.conc_program_id
          );

      END IF;

      IF l_dl_sub_request = 0 THEN
        UPDATE hz_imp_batch_summary
        SET main_conc_status = 'COMPLETED',
            batch_status = 'ACTION_REQUIRED'
        WHERE batch_id = p_batch_id;
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting data load');
        RETURN;
      ELSE
        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for data load');

        -- update batch summary table and create row in batch detail table
        get_current_run(
          p_batch_id          => p_batch_id,
          x_run_number        => l_current_run);

        UPDATE hz_imp_batch_summary
        SET import_req_id = l_dl_sub_request
        WHERE batch_id = p_batch_id;

      END IF;

      -- wait for the con program to finish
      fnd_conc_global.set_req_globals(
        conc_status => 'PAUSED',
        request_data => 'DATA_LOAD');

    END IF; -- p_run_addr_val = 'Y' AND l_req_data = 'BACTH_DEDUP'

    IF l_req_data = 'DATA_LOAD' THEN
      -- final steps on import
      fnd_file.put_line(FND_FILE.LOG, 'UIC***** Performing the post processes');

      IF p_import_run_option = 'COMPLETE' THEN

        -- generate number of workers
        IF r_batch_info.load_type = 'CSV' THEN
          l_num_of_workers := 1;
        ELSE
          l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
          IF l_num_of_workers IS NULL THEN
            l_num_of_workers := 1;
          END IF;
        END IF;

        -- call the DQM cleanup routine
        IF r_batch_info.registry_dedup_flag = 'Y' OR r_batch_info.batch_dedup_flag = 'Y' THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM post import cleanup');
          HZ_IMP_DQM_STAGE.dqm_post_imp_cleanup
            (p_batch_id      => p_batch_id,
             x_return_status => l_return_status,
             x_msg_count     => l_msg_count,
             x_msg_data      => l_msg_data);
        END IF;

        /*
        SELECT registry_dedup_flag
        INTO   l_reg_dedup
        FROM   hz_imp_batch_summary
        WHERE  batch_id = p_batch_id;
        */
        IF NVL(r_batch_info.registry_dedup_flag,'N') = 'Y' THEN

          -- call the report dupsets API
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM interface tca sanitize report');
          HZ_DQM_DUP_ID_PKG.interface_tca_sanitize_report
            (p_batch_id      => p_batch_id,
             p_match_rule_id => p_registry_dedup_rule_id,
             p_request_id    => fnd_global.conc_request_id,
             x_dup_batch_id  => l_dup_batch_id,
             x_return_status => l_return_status,
             x_msg_count     => l_msg_count,
             x_msg_data      => l_msg_data);

          get_current_run(
            p_batch_id          => p_batch_id,
            x_run_number        => l_current_run);

          UPDATE hz_imp_batch_details
          SET dup_batch_id = l_dup_batch_id
          WHERE batch_id = p_batch_id
          AND   run_number = l_current_run;

          IF p_run_automerge = 'Y' THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking auto merge post process');
              l_am_sub_request := FND_REQUEST.SUBMIT_REQUEST(
                'AR',
                'ARHAMRGP',
                '',
                to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
                true,
                to_char(l_dup_batch_id),
                to_char(l_num_of_workers)
                );

            IF l_am_sub_request = 0 THEN
              fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting auto merge post process');
            ELSE
              fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for auto merge post process');
            END IF;

          END IF;
        END IF;  --NVL(r_batch_info.registry_dedup_flag,'N') = 'Y'

        IF (Nvl(FND_PROFILE.VALUE('HZ_DQM_ENABLE_REALTIME_SYNC'),'Y') <> 'DISABLE') THEN --Bug 10435345
        -- Bug 4594407 : Call DQM Sync Index
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Calling Parallel Sync Index concurrent program');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of the program to be waited on, that is being passed to this : ' || fnd_global.conc_request_id );
        l_index_conc_program_req_id := FND_REQUEST.SUBMIT_REQUEST('AR',
                                         'ARHDQMPP',
                                         'DQM Parallel Sync Index Parent Program',
                                         NULL,
                                         FALSE,
                                         fnd_global.conc_request_id
                                         );
        IF l_index_conc_program_req_id = 0 THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error submitting DQM Sync Index Program.');
        ELSE
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of Parallel Sync concurrent Program is  : ' || l_index_conc_program_req_id );
        END IF;
        END IF;

        -- call dataload post processing
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking data load post process');
        FOR i IN 1..l_num_of_workers LOOP

          l_pp_sub_request := FND_REQUEST.SUBMIT_REQUEST(
            'AR',
            'ARHLPPLB',
            '',
            to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
            true,
            p_batch_id,
            r_batch_info.original_system,
            l_batch_mode_flag,
            to_char(fnd_global.conc_request_id),
            'N' --p_generate_fuzzy_key
            );

          IF l_pp_sub_request = 0 THEN
            fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting data load post processing ' || l_num_of_workers);
          ELSE
            fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for data load  post processing ' || l_num_of_workers);
          END IF;
        END LOOP;

        -- wait for the conc program to finish
        fnd_conc_global.set_req_globals(
          conc_status => 'PAUSED',
          request_data => 'POST_PROCESS');

      ELSIF p_import_run_option = 'WHAT_IF' THEN
        final_steps_whatif(
          p_batch_id                         => p_batch_id,
          x_return_status                    => l_return_status,
          x_msg_count                        => l_msg_count,
          x_msg_data                         => l_msg_data
         );

        fnd_conc_global.set_req_globals(
          conc_status => 'NORMAL',
          request_data => 'POST_PROCESS');
        l_req_data := 'POST_PROCESS';

      END IF; -- p_import_run_option = 'COMPLETE'/'WHAT_IF'

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
          RETURN;
      END IF;

    END IF;  --l_req_data = 'DATA_LOAD'

  END IF; -- p_import_run_option = 'WHAT_IF'/'COMPLETE'








  -- if it is continuation from what-if, then do the following
  -- //////////////////////////////////
  -- continue to import from what if
  -- //////////////////////////////////

  -- if it is continuation from what-if, then do the following
  IF p_import_run_option = 'CONTINUE' THEN

    IF l_req_data IS NULL THEN

      -- set the data load status to pending
      UPDATE hz_imp_batch_summary
      SET import_status = 'PENDING',
          main_conc_status = 'PROCESSING',
          main_conc_req_id = fnd_global.conc_request_id
      WHERE batch_id = p_batch_id;

      -- apply the batch de-duplication actions if needed.
      -- this is done becuase during what-if run, batch deduplication actions
      -- will not be performed, the options will just be stored. the actions will
      -- be performed only when users continue to import.

     -- IF nvl(p_run_batch_dedup, r_batch_info.batch_dedup_flag) = 'Y' THEN
      IF (r_batch_info.batch_dedup_flag = 'Y') THEN

          -- call batch dedup actions api with the r_batch_info.bd_action_on* parameters
          IF r_batch_info.import_status = 'ACTION_REQUIRED' THEN

            fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling the batch de-duplication actions API');
            HZ_BATCH_ACTION_PUB.batch_dedup_action(
              p_batch_id                 => p_batch_id,
              p_action_on_parties        => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_parties),
              p_action_on_addresses      => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_addresses),
              p_action_on_contacts       => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_contacts),
              p_action_on_contact_points => nvl(p_batch_dedup_action, r_batch_info.bd_action_on_contact_points),
              x_return_status            => l_return_status,
              x_msg_data                 => l_msg_data,
              x_msg_count                => l_msg_count
              );

          END IF;  -- r_batch_info.import_status = 'ACTION_REQUIRED'

          IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
              RETURN;
          END IF;

      END IF; -- r_batch_info.batch_dedup_flag = 'Y'

      -- apply the registry deduplication actions if needed.
      -- again the options are recorded in the batch summery table previously.
      IF r_batch_info.registry_dedup_flag = 'Y' THEN

          -- call registry dedup actions api with the r_batch_info.rd_action_on* parameters
          -- call to be added later since it is only needed for UI pages
          IF r_batch_info.rd_action_new_parties IS NOT NULL
             OR
             r_batch_info.rd_action_existing_parties IS NOT NULL
             OR
             r_batch_info.rd_action_dup_parties IS NOT NULL
             OR
             r_batch_info.rd_action_pot_dup_parties IS NOT NULL
             OR
             r_batch_info.rd_action_new_addrs IS NOT NULL
             OR
             r_batch_info.rd_action_existing_addrs IS NOT NULL
             OR
             r_batch_info.rd_action_pot_dup_addrs IS NOT NULL
             OR
             r_batch_info.rd_action_new_contacts IS NOT NULL
             OR
             r_batch_info.rd_action_existing_contacts IS NOT NULL
             OR
             r_batch_info.rd_action_pot_dup_contacts IS NOT NULL
             OR
             r_batch_info.rd_action_new_cpts IS NOT NULL
             OR
             r_batch_info.rd_action_existing_cpts IS NOT NULL
             OR
             r_batch_info.rd_action_pot_dup_cpts IS NOT NULL
             OR
             r_batch_info.rd_action_new_supents IS NOT NULL
             OR
             r_batch_info.rd_action_existing_supents IS NOT NULL
             OR
             r_batch_info.rd_action_new_finents IS NOT NULL
             OR
             r_batch_info.rd_action_existing_finents IS NOT NULL
          THEN
              fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling the registry de-duplication actions API');
              HZ_BATCH_ACTION_PUB.registry_dedup_action(
                p_batch_id                  => p_batch_id,
                p_action_new_parties        => r_batch_info.rd_action_new_parties,
                p_action_existing_parties   => r_batch_info.rd_action_existing_parties,
                p_action_dup_parties        => r_batch_info.rd_action_dup_parties,
                p_action_pot_dup_parties    => r_batch_info.rd_action_pot_dup_parties,
                p_action_new_addrs          => r_batch_info.rd_action_new_addrs,
                p_action_existing_addrs     => r_batch_info.rd_action_existing_addrs,
                p_action_pot_dup_addrs      => r_batch_info.rd_action_pot_dup_addrs,
                p_action_new_contacts       => r_batch_info.rd_action_new_contacts,
                p_action_existing_contacts  => r_batch_info.rd_action_existing_contacts,
                p_action_pot_dup_contacts   => r_batch_info.rd_action_pot_dup_contacts,
                p_action_new_cpts           => r_batch_info.rd_action_new_cpts,
                p_action_existing_cpts      => r_batch_info.rd_action_existing_cpts,
                p_action_pot_dup_cpts       => r_batch_info.rd_action_pot_dup_cpts,
                p_action_new_supents        => r_batch_info.rd_action_new_supents,
                p_action_existing_supents   => r_batch_info.rd_action_existing_supents,
                p_action_new_finents        => r_batch_info.rd_action_new_finents,
                p_action_existing_finents   => r_batch_info.rd_action_existing_finents,
                x_return_status             => l_return_status,
                x_msg_count                 => l_msg_count,
                x_msg_data                  => l_msg_data
              );
          END IF;

          IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** '||FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE));
              RETURN;
          END IF;

      END IF; -- r_batch_info.registry_dedup_flag = 'Y'

      -- set l_what_if to 'R' to inform it is a resume / continue option
      l_what_if := 'R';

      -- call create work unit api (if not already called) and then call data load
      l_str := 'begin HZ_IMP_LOAD_WRAPPER.DATA_LOAD_PREPROCESSING(:1,:2,:3,:4); end;';
      execute immediate l_str using p_batch_id, r_batch_info.original_system, l_what_if, OUT l_dataload_rerun;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Called data load wrapper to generate work units');

      IF r_batch_info.load_type = 'CSV' THEN

        fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling ARHLWRPO - Online Data Load');

        l_dl_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHLWRPO',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id,
          r_batch_info.original_system,
          l_what_if,
          NVL(r_batch_info.registry_dedup_flag,'N'),
          r_batch_info.registry_dedup_match_rule_id,
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          nvl(r_batch_info.error_limit,FND_PROFILE.value('HZ_IMP_ERROR_LIMIT')),
          l_dataload_rerun,
          fnd_global.conc_request_id,
          fnd_global.prog_appl_id,
          fnd_global.conc_program_id
          );

        ELSE

          -- generate number of workers
          IF r_batch_info.load_type = 'CSV' THEN
            l_num_of_workers := 1;
          ELSE
            l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
            IF l_num_of_workers IS NULL THEN
              l_num_of_workers := 1;
            END IF;
          END IF;

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'UIC***** Calculated number of workers : '||l_num_of_workers);
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Calling ARHLWRPB - Batch Data Load');

          l_dl_sub_request := FND_REQUEST.SUBMIT_REQUEST(
            'AR',
            'ARHLWRPB',
            '',
            to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
            true,
            p_batch_id,
            r_batch_info.original_system,
            l_what_if,
            NVL(r_batch_info.registry_dedup_flag,'N'),
            r_batch_info.registry_dedup_match_rule_id,
            to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
            l_num_of_workers,
            nvl(r_batch_info.error_limit,FND_PROFILE.value('HZ_IMP_ERROR_LIMIT')),
            l_dataload_rerun,
            fnd_global.conc_request_id,
            fnd_global.prog_appl_id,
            fnd_global.conc_program_id
            );

      END IF; -- IF r_batch_info.load_type = 'CSV'

      IF l_dl_sub_request = 0 THEN
          UPDATE hz_imp_batch_summary
          SET main_conc_status = 'COMPLETED',
              batch_status = 'ACTION_REQUIRED'
          WHERE batch_id = p_batch_id;
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting data load');
          RETURN;
      ELSE
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for data load');

          -- update batch summary table and create row in batch detail table
          get_current_run(
            p_batch_id          => p_batch_id,
            x_run_number        => l_current_run);

          UPDATE hz_imp_batch_summary
          SET import_req_id = l_dl_sub_request
          WHERE batch_id = p_batch_id;

      END IF;

      -- wait for the con program to finish
      fnd_conc_global.set_req_globals(
        conc_status => 'PAUSED',
        request_data => 'DATA_LOAD');

    END IF; -- l_req_data IS NULL

    IF l_req_data = 'DATA_LOAD' THEN
      -- final steps on import
      fnd_file.put_line(FND_FILE.LOG, 'UIC***** Performing the post processes');

      -- generate number of workers
      IF r_batch_info.load_type = 'CSV' THEN
        l_num_of_workers := 1;
      ELSE
        l_num_of_workers := fnd_profile.value('HZ_IMP_NUM_OF_WORKERS');
        IF l_num_of_workers IS NULL THEN
          l_num_of_workers := 1;
        END IF;
      END IF;

      IF r_batch_info.registry_dedup_flag = 'Y' OR r_batch_info.batch_dedup_flag = 'Y' THEN
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM post import cleanup');
        HZ_IMP_DQM_STAGE.dqm_post_imp_cleanup
          (p_batch_id      => p_batch_id,
           x_return_status => l_return_status,
           x_msg_count     => l_msg_count,
           x_msg_data      => l_msg_data);
      END IF;

      /*
      SELECT registry_dedup_flag
      INTO   l_reg_dedup
      FROM   hz_imp_batch_summary
      WHERE  batch_id = p_batch_id;
      */
      IF NVL(r_batch_info.registry_dedup_flag,'N') = 'Y' THEN

        -- call the report dupsets API
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Calling DQM interface tca sanitize report');
        HZ_DQM_DUP_ID_PKG.interface_tca_sanitize_report
          (p_batch_id      => p_batch_id,
           p_match_rule_id => r_batch_info.registry_dedup_match_rule_id,
           p_request_id    => fnd_global.conc_request_id,
           x_dup_batch_id  => l_dup_batch_id,
           x_return_status => l_return_status,
           x_msg_count     => l_msg_count,
           x_msg_data      => l_msg_data);

        get_current_run(
          p_batch_id          => p_batch_id,
          x_run_number        => l_current_run);

        UPDATE hz_imp_batch_details
        SET dup_batch_id = l_dup_batch_id
        WHERE batch_id = p_batch_id
        AND   run_number = l_current_run;

        IF p_run_automerge = 'Y' THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking auto merge post process');
            l_am_sub_request := FND_REQUEST.SUBMIT_REQUEST(
              'AR',
              'ARHAMRGP',
              '',
              to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
              true,
              to_char(l_dup_batch_id),
              to_char(l_num_of_workers)
              );

            IF l_am_sub_request = 0 THEN
              fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting auto merge post process');
            ELSE
              fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for auto merge post process');
            END IF;

        END IF;
      END IF;  --NVL(r_batch_info.r_batch_info.registry_dedup_flag,'N') = 'Y'

      IF (Nvl(FND_PROFILE.VALUE('HZ_DQM_ENABLE_REALTIME_SYNC'),'Y') <> 'DISABLE') THEN --Bug 10435345
      -- Bug 4594407 : Call DQM Sync Index
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Calling Parallel Sync Index concurrent program');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of the program to be waited on, that is being passed to this : ' || fnd_global.conc_request_id );
      l_index_conc_program_req_id := FND_REQUEST.SUBMIT_REQUEST('AR',
                                         'ARHDQMPP',
                                         'DQM Parallel Sync Index Parent Program',
                                         NULL,
                                         FALSE,
                                         fnd_global.conc_request_id
                                         );
      IF l_index_conc_program_req_id = 0 THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error submitting DQM Sync Index Program.');
      ELSE
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request Id of Parallel Sync concurrent Program is  : ' || l_index_conc_program_req_id );
      END IF;
      END IF;

      -- call dataload post processing
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Invoking data load post process');
      FOR i IN 1..l_num_of_workers LOOP
        l_pp_sub_request := FND_REQUEST.SUBMIT_REQUEST(
          'AR',
          'ARHLPPLB',
          '',
          to_char(sysdate,'DD-MM-YY HH24:MI:SS'),
          true,
          p_batch_id,
          r_batch_info.original_system,
          l_batch_mode_flag,
          to_char(fnd_global.conc_request_id),
          'N' --p_generate_fuzzy_key
          );

        IF l_pp_sub_request = 0 THEN
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Error submitting data load post processing ' || l_num_of_workers);
        ELSE
          fnd_file.put_line(FND_FILE.LOG, 'UIC***** Submitted request for data load post processing ' || l_num_of_workers);
        END IF;
      END LOOP;

      -- wait for the conc program to finish
      fnd_conc_global.set_req_globals(
        conc_status => 'PAUSED',
        request_data => 'POST_PROCESS');

    END IF;  --l_req_data = 'DATA_LOAD'

  END IF; -- p_import_run_option = 'CONTINUE'


  IF l_req_data = 'POST_PROCESS' THEN

    /* Clean up staging if not a what-if */
    IF p_import_run_option <> 'WHAT_IF'
    THEN
      CLEANUP_STAGING(p_batch_id, l_batch_mode_flag);
    END IF;

    -- program completed successfully
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'UIC***** Program completed successfully');

    /* Delete Work Unit if not what-if */
    IF p_import_run_option <> 'WHAT_IF'
       and (r_batch_info.import_status='COMPLETED'
       or r_batch_info.import_status='COMPL_ERRORS')
    THEN
      delete hz_imp_work_units where batch_id = P_BATCH_ID;
    END IF;

    -- set the data load status to COMPLETED
    UPDATE hz_imp_batch_summary
    SET main_conc_status = 'COMPLETED',
        batch_status = decode(r_batch_info.import_status,'COMPLETED','COMPLETED','ACTION_REQUIRED')
    WHERE batch_id = p_batch_id;


    l_last_req := r_batch_info.import_req_id;
    l_call_status := fnd_concurrent.get_request_status(
                                       l_last_req,
                                       null,
                                       null,
                                       l_temp_rphase,
                                       l_temp_rstatus,
                                       l_temp_dphase,
                                       l_temp_dstatus,
                                       l_temp_message);

    IF l_temp_dstatus <> 'NORMAL' OR r_batch_info.import_status = 'ERROR'
    THEN
       l_wng_msg := l_wng_msg||' Unexpected error occured in the Data Load program.';
    END IF;

    IF p_import_run_option <> 'WHAT_IF'
    THEN
    open c_pp_error(p_batch_id);
    fetch c_pp_error into l_pp_error;
    close c_pp_error;
    END IF;

    IF l_pp_error = 'Y'
    THEN
       l_wng_msg := l_wng_msg||' Unexpected error occured in the Post Processing program.';
    END IF;


    IF l_wng_msg<>'WARNING****'
    THEN
      errbuf := l_wng_msg;
      retcode := 1;
    END IF;



  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      Errbuf := fnd_message.get||'     '||SQLERRM;
      Retcode := 2;

END;

END HZ_BATCH_IMPORT_PKG;
/

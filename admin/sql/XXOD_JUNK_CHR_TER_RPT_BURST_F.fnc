-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XXOD_JUNK_CHR_TER_RPT_BURST_F.sql                                  |
-- | Rice ID     : XXX                                                          |
-- | Description : Function to send bursting email for Deffered Report          |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date         Author           Remarks                              |
-- |=======  ===========   =============    =====================================|
-- |1.0      08-July-2021  Kayed Ahmed      Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT Creating Function XXOD_JUNK_CHR_TER_RPT_BURST_F in APPS.....
PROMPT

CREATE OR REPLACE FUNCTION XXOD_JUNK_CHR_TER_RPT_BURST_F
  RETURN BOOLEAN
IS
  P_CONC_REQUEST_ID   NUMBER;
  l_request_id        NUMBER;
BEGIN
  P_CONC_REQUEST_ID        := FND_GLOBAL.CONC_REQUEST_ID;

  fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
  l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO',            --Application Short name
                                            'XDOBURSTREP',     --Program Short name
											NULL,              --Description 
											SYSDATE,           --Start_time 
											FALSE,             --Sub_request
											'Y',               --Dummy for Data Security 
											P_CONC_REQUEST_ID, --Request ID
											'Y'                --Debug
											);
  Fnd_File.PUT_LINE(Fnd_File.LOG, 'After submitting bursting ');
  COMMIT;

  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in XXOD_JUNK_CHR_TER_RPT_BURST_F function '||SQLERRM );
END XXOD_JUNK_CHR_TER_RPT_BURST_F;
/
show error;
exit;
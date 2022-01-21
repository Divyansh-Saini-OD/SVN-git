CREATE OR REPLACE PACKAGE BODY APPS.XX_SPC_OPEN_TRANSACTIONS_PKG
AS
-- +======================================================================================+
-- |                        Office Depot                                                  |
-- +======================================================================================+
-- | Name  : XX_SPC_OPEN_TRANSACTIONS_PKG                                                 |
-- | Rice ID: R1395                                                                       |
-- | Description      : This program will submit the concurrent requests for two programs |
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version Date        Author            Remarks                                         |
-- |======= =========== =============== ==================================================|
-- |1.0     25-APR-2015 Havish Kasina   Initial draft version                             |
-- +======================================================================================+

  PROCEDURE EXTRACT(x_retcode              OUT NOCOPY    NUMBER,
                    x_errbuf               OUT NOCOPY    VARCHAR2,
					p_operating_unit       IN            NUMBER,
                    p_as_of_date           IN            VARCHAR2,
                    p_no_of_days           IN            NUMBER,
                    p_order_source         IN            VARCHAR2,
                    p_smtp_server          IN            VARCHAR2,
                    p_mail_from            IN            VARCHAR2,
                    p_mail_to              IN            VARCHAR2,
					p_mail_cc              IN            VARCHAR2
                   )
  IS  
  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  ln_request_id             NUMBER;
  ln_operating_unit         VARCHAR2 (100);
  lb_complete               BOOLEAN;
  lc_phase                  VARCHAR2 (100);
  lc_status                 VARCHAR2 (100);
  lc_dev_phase              VARCHAR2 (100);
  lc_dev_status             VARCHAR2 (100);
  lc_message                VARCHAR2 (100);
  ln_request                NUMBER;
  
  BEGIN
  
      SELECT NAME 
        INTO ln_operating_unit
        FROM hr_operating_units
       WHERE organization_id = p_operating_unit;
       
      fnd_file.put_line (fnd_file.log,'Input parameters .....:');
	  fnd_file.put_line (fnd_file.log,'Operating Unit :' || ln_operating_unit);
      fnd_file.put_line (fnd_file.log,'As of Date : ' || p_as_of_date);
      fnd_file.put_line (fnd_file.log,'Number of Days : ' || p_no_of_days);
      fnd_file.put_line (fnd_file.log,'Order Source :'||p_order_source);
      fnd_file.put_line (fnd_file.log,'SMTP Server :'|| p_smtp_server);
      fnd_file.put_line (fnd_file.log,'Mail from :'||p_mail_from);
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Mail to :'|| P_MAIL_TO);
	    fnd_file.put_line (fnd_file.log,'Mail cc :'|| p_mail_cc);
      
      fnd_file.put_line (fnd_file.log,'Submitting the Report Program to generate the Excel File :');
      ln_request_id :=
                     fnd_request.submit_request (
                        application   => 'XXFIN',     -- Application short name
                        program       => 'XXODSPCNONABOPTRANS', --- conc program short name
                        description   => NULL,
                        start_time    => SYSDATE,
                        sub_request   => FALSE,
                        argument1     => p_operating_unit,
                        argument2     => p_as_of_date,
                        argument3     => p_no_of_days,
                        argument4     => p_order_source,
                        ARGUMENT5     => P_SMTP_SERVER,
						argument6     => p_mail_from,
                        ARGUMENT7     => P_MAIL_TO,
						argument8     => p_mail_cc);

     IF ln_request_id > 0
     THEN
     COMMIT;
	   fnd_file.put_line(fnd_file.log,'Able to submit the Report Program');
     ELSE
       fnd_file.put_line(fnd_file.log,'Failed to submit the Report Program to generate the output file - ' || SQLERRM);
     END IF;
     fnd_file.put_line (fnd_file.LOG, 'While Waiting Report Request to Finish');

     -- wait for request to finish
        lb_complete :=fnd_concurrent.wait_for_request (
                           request_id   => ln_request_id,
                           INTERVAL     => 15,
                           max_wait     => 0,
                           phase        => lc_phase,
                           status       => lc_status,
                           dev_phase    => lc_dev_phase,
                           dev_status   => lc_dev_status,
                           MESSAGE      => lc_message);


        IF UPPER (lc_dev_phase) = 'COMPLETE'
        THEN
             fnd_file.put_line (fnd_file.LOG,'Submitting XML Bursting Program to email the output file');
			 
            ln_request :=fnd_request.submit_request (
                        application   => 'XDO',     -- Application short name
                        program       => 'XDOBURSTREP', --- conc program short name
                        description   => NULL,
                        start_time    => SYSDATE,
                        sub_request   => FALSE,
                        argument1     => NULL,
                        argument2     => ln_request_id,
                        argument3     => NULL);    
        END IF;
        
        IF ln_request > 0
        THEN
            COMMIT;
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Able to submit the XML Bursting Program to e-mail the output file');
		ELSE
            fnd_file.put_line(fnd_file.log,'Failed to submit the XML Bursting Program to e-mail the file - ' || SQLERRM);
        END IF;
    EXCEPTION
      WHEN OTHERS
       THEN
         fnd_file.put_line(fnd_file.log,'Unable to run the Report'|| SQLERRM);
         x_retcode := 2;
   END EXTRACT;
END XX_SPC_OPEN_TRANSACTIONS_PKG;
/
SHOW ERRORS;

SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package Body XX_TAXWARE_TEST
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE  PACKAGE BODY XX_TAXWARE_TEST AS

/*******************************************/
PROCEDURE  MAIN_PROGRAM
    (errbuf                         IN OUT NOCOPY VARCHAR2,
     retcode                        IN OUT NOCOPY VARCHAR2,
     p_threads				              IN NUMBER,
     p_batch_size_per_thread        IN NUMBER)
AS
     ln_threads				NUMBER;
     ln_batch_size		NUMBER;
     ln_counter				NUMBER;
     ln_conc_id				NUMBER;
     
BEGIN
     ln_threads 	 := p_threads;
     ln_batch_size := p_batch_size_per_thread;
     
     FOR ln_counter in 1..ln_threads LOOP
     
             ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XX_TAXWARE_TEST_PROCESS_THREAD'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => ln_counter
                                                ,argument2   => ln_batch_size);
                                                
						 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitted Thread ' || ln_counter || ' with Request ID ' || ln_conc_id);
						 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Submitted Thread ' || ln_counter || ' with Request ID ' || ln_conc_id);						 
     END LOOP;

EXCEPTION
  WHEN OTHERS THEN
	RAISE;
END MAIN_PROGRAM;



/*******************************************/
PROCEDURE PROCESS_THREAD
   (errbuf												IN OUT NOCOPY VARCHAR2,
    retcode												IN OUT NOCOPY VARCHAR2,
    p_thread											IN NUMBER,
    p_batch_size									IN NUMBER)
AS

    ln_batch_size    NUMBER;    
    ln_loop_counter  NUMBER;
    ln_thread				 NUMBER;
    lc_return_code   VARCHAR2(8);

BEGIN

   ln_thread     := p_thread;
   ln_batch_size := p_batch_size;
   
   FOR ln_loop_counter in 1..ln_batch_size LOOP

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Processing Thread : ' || ln_thread || ' Row : ' || ln_loop_counter); 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Processing Thread : ' || ln_thread || ' Row : ' || ln_loop_counter);       
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'BEFORE CALCULATE_TAX');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BEFORE CALCULATE_TAX');      
      
      twe_ora_common.calculate_tax
             (ln_loop_counter,																			-- g_trx_id,																	
              'UNITED STATES',                                      -- jrparm.shipfr.country,										
              'FL',                                                 -- jrparm.shipfr.state,											
              '',                                                   -- jrparm.shipfr.cnty,												
              'DELRAY BEACH',                                       -- jrparm.shipfr.city,												
              '33445',                                              -- jrparm.shipfr.zip,												
              '',                                                   -- jrparm.shipfr.zipext,											
              'US',                                                 -- jrparm.shipto.country,										
              'FL',                                                 -- jrparm.shipto.state,											
              '',                                                   -- jrparm.shipto.cnty,												
              'DELRAY BEACH',                                       -- jrparm.shipto.city,												
              '33445',                                              -- jrparm.shipto.zip,												
              '',                                                   -- jrparm.shipto.zipext,											
              'UNITED STATES',                                      -- jrparm.poa.country,												
              'FL',                                                 -- jrparm.poa.state,													
              '',                                                   -- jrparm.poa.cnty,													
              'DELRAY BEACH',                                       -- jrparm.poa.city,													
              '33445',                                              -- jrparm.poa.zip,														
              '',                                                   -- jrparm.poa.zipext,												
              'UNITED STATES',                                      -- jrparm.poo.country,												
              'FL',                                                 -- jrparm.poo.state,													
              '',                                                   -- jrparm.poo.cnty,													
              'DELRAY BEACH',                                       -- jrparm.poo.city,													
              '33445',                                              -- jrparm.poo.zip,														
              '',                                                   -- jrparm.poo.zipext,												
              'US',                                                 -- jrparm.billto.country,										
              'FL',                                                 -- jrparm.billto.state,                      
              '',                                                   -- jrparm.billto.cnty,                       
              'DELRAY BEACH',                                       -- jrparm.billto.city,                       
              '33445',                                              -- jrparm.billto.zip,                        
              '',                                                   -- jrparm.billto.zipext,                     
              'O',                                                  -- jrparm.pot,                               
              100.00,                                               -- 100.00,     															
              0.00,                                                 -- txparm.frghtamt,                          
              0.00,                                                 -- txparm.discountamt,                       
              '63102',                                              -- txparm.custno,                            
              'CITY OF DELRAY BEACH',                               -- txparm.custname,                          
              1,                                                    -- txparm.numitems,													
              '10',                                                   -- txparm.calctype,													
              '2039690',                                            -- txparm.prodcode,													
              0,                                                    -- creditind,																
              0,                                                    -- invoicesumind,														
              '11-JUN-08',                                          -- g_order_date,															
              '9999999999',                                           -- txparm.invoiceno,													
              99999999,                                             -- txparm.invoicelineno,											
              '1001',                                                 -- txparm.companyid,													
              '',                                                   -- txparm.locncode,													
              '',                                                   -- txparm.costcenter,												
              0,                                                    -- REPTIND                                       
              '',                                                   -- txparm.jobno,															
              '',                                                   -- txparm.volume,														
              '',                                                   -- txparm.afeworkord,                        
              '',                                                   -- txparm.partnumber,												
              '',                                                   -- txparm.miscinfo,													
              'USD',                                                -- txparm.currencycd1,          							
              0,                                                    -- dropshipind,                 							
              '',                                                   -- txparm.streasoncode,											
              'UNITED STATES',                                      -- jrparm.shipto.country,        						
              'FL',                                                 -- jrparm.shipto.state,          						
              '',                                                   -- jrparm.shipto.cnty,           						
              'DELRAY BEACH',                                       -- jrparm.shipto.city,           						
              '33445',                                              -- jrparm.shipto.zip,            						
              '',                                                   -- jrparm.shipto.zipext,         						
              'UNITED STATES',                                      -- jrparm.shipto.country,										
              'FL',                                                 -- jrparm.shipto.state,            					
              '',                                                   -- jrparm.shipto.cnty,              					
              'DELRAY BEACH',                                       -- jrparm.shipto.city,              					
              '33445',                                              -- jrparm.shipto.zip,                				
              '',                                                   -- jrparm.shipto.zipext,          						
              '',                                                   -- l_shiptogeocode,              						
              NULL,                                                   -- NULL,                         						
              '',                                                   -- l_billtogeocode,              						
              NULL,                                                   -- NULL,                            					
              NULL,                                                   -- NULL,                            					
              NULL,                                                   -- NULL,                            					
              NULL,                                                   -- NULL,                                     
              'E',                                                  -- txparm.audit_flag,												
              '10',                                                  -- txparm.calctype,													
              'Admin',                                              -- taxpkg_10_param.tweusername,							
              'Admin123',                                           -- taxpkg_10_param.tweuserpassword,					
              'N',                                                  -- 'N',                                      
              NULL,                                                   -- NULL,                                     
              '',                                                   -- txparm.forcestate,												
              '',                                                   -- txparm.forcecounty,												
              '',                                                   -- txparm.forcecity,													
              '',                                                   -- txparm.forcedist,													
              '',                                                   -- txparm.shipto_code,												
              '',                                                   -- txparm.billto_code,												
              '',                                                   -- txparm.shipfrom_code,											
              '',                                                   -- txparm.poo_code,													
              '',                                                   -- txparm.poa_code,													
              NULL,                                                   -- NULL,                            					
              NULL,                                                   -- NULL,                           					
              ''                                                    -- txparm.custom_attributes									
            );
            
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'AFTER CALCULATE_TAX');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'AFTER CALCULATE_TAX');      
            
      LC_RETURN_CODE := twe_ora_common.get_gen_compl_code (ln_loop_counter);
            
      IF LC_RETURN_CODE IS NULL 
      THEN
      	FND_FILE.PUT_LINE(FND_FILE.LOG, 'CALC SUCESSFUL');
      	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'CALC SUCESSFUL');      	
        twe_ora_common.end_line_transaction (ln_loop_counter);
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'CALC UNSUCCESSFUL - RETURN CODE =' || LC_RETURN_CODE);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'CALC UNSUCCESSFUL - RETURN CODE =' || LC_RETURN_CODE);        
      END IF;
   
   END LOOP;
   
EXCEPTION
  WHEN OTHERS THEN
	RAISE;
END PROCESS_THREAD;

END XX_TAXWARE_TEST;
/
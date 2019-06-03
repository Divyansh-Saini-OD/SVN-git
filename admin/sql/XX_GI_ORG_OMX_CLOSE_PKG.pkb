CREATE OR REPLACE PACKAGE BODY XX_GI_ORG_OMX_CLOSE_PKG
AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_GI_ORG_OMX_CLOSE_PKG                            |
-- | Description      :    Pkg to close inventory periods for OMX Locations   |
-- | RICE ID          :    E0351b                                             |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      09-Jun-2014  Paddy Sanjeevi      Initial                        |
-- | 1.1      19-Oct-2015   Madhu Bolli        Remove schema for 12.2 retrofit |
-- +==========================================================================+

PROCEDURE XX_OMX_INV_ORG_CLOSE (  x_errbuf     OUT NOCOPY VARCHAR2,
			          x_retcode    OUT NUMBER,
				  p_no_periods  IN NUMBER
                               )

IS

CURSOR C1(p_open_date DATE) IS
SELECT period_start_date,period_name
  FROM ( select distinct period_start_date,period_name
           from ORG_ACCT_PERIODS
          where organization_id in (select a.organization_id
                                      from  xx_inv_org_loc_def_stg b,
                                            hr_all_organization_units a
                                     where trunc(a.creation_date)='04-MAY-14'
                                       and to_char(b.location_number_sw)=a.attribute1
                                       and trunc(b.creation_date)='04-MAY-14'
				   )   
            and period_set_name='OD 445 CALENDAR'
            and open_flag='Y' 
	    and period_start_date<p_open_date
          order by 1 asc
        )
 WHERE ROWNUM<p_no_periods;


CURSOR C_period(p_period VARCHAR2)
IS
SELECT ocp.period_start_date,ocp.period_name,ocp.open_flag,ocp.organization_id,
       a.name
  FROM ORG_ACCT_PERIODS ocp,
       xx_inv_org_loc_def_stg b,
       hr_all_organization_units a
 WHERE trunc(a.creation_date)='04-MAY-14'
   AND to_char(b.location_number_sw)=a.attribute1
   AND trunc(b.creation_date)='04-MAY-14'
   AND ocp.organization_id=a.organization_id
   AND ocp.period_set_name='OD 445 CALENDAR'
   AND ocp.open_flag='Y' 
   and ocp.period_name=p_period
 ORDER BY 1 asc;

 v_request_id 		NUMBER;
 v_phase		varchar2(100)   ;
 v_status		varchar2(100)   ;
 v_dphase		varchar2(100)	;
 v_dstatus		varchar2(100)	;
 x_dummy		varchar2(2000) 	;
 v_structure_id		NUMBER;
 v_open_date		DATE;
 ln_run_count		NUMBER;
BEGIN

  BEGIN
  SELECT MAX(period_start_date)
    INTO v_open_date
    FROM ORG_ACCT_PERIODS 
   WHERE period_set_name='OD 445 CALENDAR' 
     AND open_flag='Y';
  EXCEPTION
    WHEN others THEN
      v_open_date:='25-MAY-14';
  END;	
 
  BEGIN
    SELECT organization_structure_id
      INTO v_structure_id
      FROM PER_ORGANIZATION_STRUCTURES
     WHERE name='OD Period Heirarchy';
  EXCEPTION
    WHEN others THEN
      v_structure_id:=NULL;
      x_retcode := 2 ;
      x_errbuf  := 'OD Period Hierarchy Not Defined';
  END;

  FOR cur IN C1(v_open_date) LOOP

    FOR c IN c_period(cur.period_name) LOOP

      v_request_id:=FND_REQUEST.SUBMIT_REQUEST( 'INV'
					       ,'INVCPCLOS'
					       ,'Close Period Control'
					       ,NULL
					       ,FALSE
					       ,c.organization_id
					       ,v_structure_id
					       ,c.period_name
					       ,'Y'
					       ,NULL
					       ,'C'
					       ,'1'
					    );


       IF v_request_id>0 THEN

          COMMIT;
          fnd_file.PUT_LINE(fnd_file.LOG,   'Close Period Control for the Org : '||c.name ||',' ||c.period_name);
 
       END IF;

    END LOOP;

    LOOP
     SELECT COUNT(1)
       INTO ln_run_count
       FROM fnd_concurrent_requests
      WHERE concurrent_program_id IN (SELECT concurrent_program_id
						   FROM fnd_concurrent_programs
					        WHERE concurrent_program_name='INVCPCLOS'
					          AND application_id=401
					          AND enabled_flag='Y')
       AND program_application_id=401
       AND phase_code IN ('P','R');

     IF ln_run_count<11 THEN
        EXIT;
     ELSE
	DBMS_LOCK.Sleep( 30 );
     END IF;

    END LOOP;
  END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      fnd_file.PUT_LINE(fnd_file.LOG,'Error when others');
      x_retcode := 2 ;
      x_errbuf  := sqlerrm ;
END XX_OMX_INV_ORG_CLOSE;

END XX_GI_ORG_OMX_CLOSE_PKG;
/

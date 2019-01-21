SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_SFA_TERR_CORRECTION_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_SFA_TERR_CORRECTION_PKG                                                |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        26-Sep-2007     Jeevan Babu          Initial version to correct Territory id  |
-- |                                                in JTF_TERR_ALL tables                   |
-- +=========================================================================================+


AS
-- +===================================================================+
-- | Name        : P_Main                                              |
-- |                                                                   |
-- | Description : he procedure to be invoked from the                 |
-- |               concurrent program to fix the data issues           |
-- | Parameters  :                                                     |
-- |               p_commit                                            |
-- +===================================================================+

PROCEDURE P_Main
    (
         x_errbuf            OUT     VARCHAR2
        ,x_retcode           OUT     VARCHAR2
        ,p_commit            IN      VARCHAR2
    )
IS 
BEGIN 

update jtf_terr_all
set parent_territory_id = 89
where orig_system_reference in
('N106D00',
'C603D00',
'W106D00',
'C403D00',
'N304D00',
'S605D00',
'N102D00',
'N105D00',
'N103D00',
'W405D00',
'C402D00',
'W602D00',
'W407D00',
'W605D00',
'W406D00',
'W308D00',
'C302D00',
'W402D00',
'S604D00',
'S504D00',
'S508D00',
'S602D00',
'W203D00',
'C103D00',
'C508D00',
'W202D00',
'W103D00',
'S203D00',
'S402D00',
'S404D00',
'N509D00',
'N602D00',
'N702D00',
'N407D00',
'N800D00',
'N405D00',
'N306D00',
'N305D00',
'N311D00',
'N309D00',
'N403D00',
'N603D00',
'N604D00',
'N605D00',
'N402D00',
'N503D00',
'N508D00',
'N506D00',
'S703D00',
'S107D00',
'S103D00',
'S206D00',
'S204D00',
'S205D00',
'S702D00',
'N207D00',
'S802D00',
'S403D00',
'S503D00',
'S502D00',
'S302D00',
'S306D00',
'S108D00',
'S305D00',
'S603D00',
'S104D00',
'S106D00',
'C106D00',
'C104D00',
'C102D00',
'C202D00',
'C205D00',
'N206D00',
'N204D00',
'N203D00',
'C105D00',
'C207D00',
'C209D00',
'C602D00',
'C303D00',
'C208D00',
'C507D00',
'W607D00',
'W704D00',
'W606D00',
'W706D00',
'W703D00',
'W608D00',
'W710D00',
'W708D00',
'C505D00',
'C605D00',
'W502D00',
'C504D00',
'W604D00',
'W707D00',
'W600D00',
'W306D00',
'W305D00',
'W304D00',
'W303D00',
'W307D00',
'W102D00')
and parent_territory_id = 86;

 fnd_file.put_line(fnd_file.log, 'Number of records processed '||SQL%ROWCOUNT);   
 
   IF (upper(nvl(p_commit, 'N')) = 'Y') then
      COMMIT;
      fnd_file.put_line(fnd_file.log, 'Commit Executed');         
   ELSE
       ROLLBACK;
       fnd_file.put_line(fnd_file.log, 'Rollback Executed');
   END IF;
END P_Main;



END XX_SFA_TERR_CORRECTION_PKG;
/

SHOW ERRORS
--EXIT;

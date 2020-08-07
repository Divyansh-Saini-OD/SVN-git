CREATE OR REPLACE PROCEDURE XX_OD_XNET_LOAD_PRC( P_CURRENCY_CODE IN VARCHAR2
                                                ,P_ORG_ID IN NUMBER
                                                ,P_RETURN_STATUS OUT VARCHAR2
												,P_ERR_MSG OUT VARCHAR2)
AS
   /*==========================================================================+
   |      Office Depot - Project AMS Support                                   |
   |          Oracle/Office Depot
   +===========================================================================+
   |Name        :XX_OD_XNET_LOAD_PRC                                           |
   |RICE        : R0428 Credit Limit Report                                    |
   |Description :This procedure loads data into a                              |
   |              custom table XX_OD_XNET_REPORT_DATA_ITM                          |
   |Change Record:                                                             |
   |==============                                                             |
   |Version  Date         Author                  Remarks                      |
   |=======  ===========  ======================  =============================|
   |  1.0    01-Dec-2014  Ravi Palikala           Initial Version Defect#31519 |
   |  1.1    30-Nov-2015  Vasu Raparla            Removed Schema References for| 
   |                                              R12.2                        |
   */

CURSOR C_PARENT IS
select distinct parent_id from HZ_HIERARCHY_NODES hhn2 where hhn2.child_id in(
SELECT distinct hhn.child_id
FROM XX_AR_OPEN_TRANS_ITM    APS,hz_cust_accounts_all hca,HZ_HIERARCHY_NODES hhn
WHERE hhn.child_id = hca.party_id
and hhn.top_parent_flag = 'N'
and hca.cust_account_id = aps.customer_id
AND   HHN.hierarchy_type = 'OD_FIN_HIER'
AND    NVL(HHN.status,'A')='A'
AND    NVL(HHN.effective_start_date,SYSDATE)<=SYSDATE
AND    NVL(HHN.EFFECTIVE_END_DATE,sysdate) >= sysdate
)
and    NVL(hhn2.top_parent_flag,'Y') = 'Y'
AND   HHN2.hierarchy_type = 'OD_FIN_HIER'
and   hhn2.parent_id <> hhn2.child_id
MINUS
SELECT distinct hhn.parent_id
FROM XX_AR_OPEN_TRANS_ITM    APS,hz_cust_accounts_all hca,HZ_HIERARCHY_NODES hhn
WHERE hhn.parent_id = hca.party_id
and hca.cust_account_id = aps.customer_id
and NVL(hhn.top_parent_flag,'Y') = 'Y'
AND   HHN.hierarchy_type = 'OD_FIN_HIER'
AND    NVL(HHN.status,'A')='A'
AND    NVL(HHN.effective_start_date,SYSDATE)<=SYSDATE
AND    NVL(HHN.EFFECTIVE_END_DATE,sysdate) >= sysdate
AND    NVL(hhn.level_number,0) = 0;

CURSOR C_DATA (P_PARENT_ID NUMBER,P_CUR VARCHAR2) IS
SELECT      HP.party_id                      PARTY_ID,
            HPS.party_site_id  party_site_id,
            P_PARENT_ID      PARENT_ID,
            'Y'   TOP_PARENT_FLAG,
            HP.PARTY_NUMBER                 PARTY_NUMBER,
             HP.PARTY_NAME                  PARTY_NAME,
            decode(HP.party_name, null, 'Unidentified Payment',substrb(HP.party_name,1,50)) SHORT_CUST_NAME_1,   
            HCA.account_number             CUST_NO_1,
            HCA.account_number            ACCOUNT_NUMBER,
            HCA.cust_account_id            CUST_ACCT_ID,
            DECODE(HP.PARTY_NAME, null, 2, 1)  CUST_SORT_1,    
            HCPA.overall_credit_limit CREDIT_LIMIT_1,
            ARC.name             COLLECTOR_NAME_P,
             HRE.full_name                 collector_name,
            HRE.EMAIL_ADDRESS          COLLECTOR_EMAIL
         from  HZ_CUST_ACCOUNTS HCA,
            HZ_PARTIES HP,
           HZ_PARTY_SITES HPS,
            HZ_CUSTOMER_PROFILES HCP,
            HZ_CUST_PROFILE_AMTS HCPA,
            AR_COLLECTORS  ARC, 
            XX_HR_PER_ALL_PEOPLE_F_V HRE,
            AR_LOOKUPS ALP
where   
HP.PARTY_ID = P_PARENT_ID
AND HP.PARTY_ID = HCA.PARTY_ID
AND     HP.status='A'
AND    HPS.party_id  = HP.party_id
AND    HPS.status    = 'A'
AND    HPS.IDENTIFYING_ADDRESS_FLAG    = 'Y'
AND    HCP.PARTY_ID = HCA.PARTY_ID
AND    HCP.CUST_ACCOUNT_ID =  HCA.cust_account_id
AND    HCP.SITE_USE_ID is null
AND    HCP.credit_hold='N'   
AND    HCPA.cust_account_id(+) =HCA.cust_account_id
AND    HCPA.currency_code(+) = P_CUR
AND    HCPA.site_use_id IS NULL                                            
AND   ARC.COLLECTOR_ID(+) = HCP.COLLECTOR_ID
AND   HRE.person_id(+)=ARC.employee_id
AND   NVL(Hre.effective_start_date,SYSDATE)<=SYSDATE
AND   NVL(Hre.effective_end_date,SYSDATE) >= SYSDATE
AND  ALP.lookup_code(+) = HCA.customer_class_code
AND  ALP.LOOKUP_TYPE(+) = 'CUSTOMER CLASS';

TYPE T_PARENT IS TABLE OF C_PARENT%ROWTYPE INDEX BY BINARY_INTEGER;
R_PARENT T_PARENT;
R_DATA C_DATA%ROWTYPE;

TYPE T_MAIN IS TABLE OF XX_OD_XNET_REPORT_DATA_ITM%ROWTYPE INDEX BY BINARY_INTEGER;
R_MAIN T_MAIN;

L_CNT NUMBER:=0;

V_FINAL_AMT         NUMBER:=0;
V_CHILD_AMT         NUMBER:=0;
V_PARENT_AMT        NUMBER:=0;
V_FINAL_PARENT_BAL  NUMBER:=0;
V_CHILD_BAL         NUMBER:=0;
V_PARENT_BAL        NUMBER:=0;

BEGIN

DELETE FROM XX_OD_XNET_REPORT_DATA_ITM ;
COMMIT;

P_RETURN_STATUS:='S';
P_ERR_MSG:='Success';


OPEN C_PARENT;
LOOP
FETCH C_PARENT BULK COLLECT INTO R_PARENT LIMIT 5000;
EXIT WHEN R_PARENT.COUNT=0;
L_CNT:=0;
FOR I IN 1..R_PARENT.COUNT
LOOP

OPEN C_DATA (R_PARENT(I).PARENT_ID,P_CURRENCY_CODE);
FETCH C_DATA INTO R_DATA;
CLOSE C_DATA;

L_CNT:=L_CNT+1;

V_FINAL_AMT             :=0;
V_FINAL_PARENT_BAL      :=0;

 R_MAIN(L_CNT).PARTY_ID             := R_DATA.PARTY_ID;
 R_MAIN(L_CNT).party_site_id        := R_DATA.party_site_id;  
 R_MAIN(L_CNT).PARENT_ID            := R_DATA.PARENT_ID;
 R_MAIN(L_CNT).TOP_PARENT_FLAG      := R_DATA.TOP_PARENT_FLAG;
 R_MAIN(L_CNT).PARTY_NUMBER         := R_DATA.PARTY_NUMBER;
 R_MAIN(L_CNT).PARTY_NAME           := R_DATA.PARTY_NAME;
 R_MAIN(L_CNT).SHORT_CUST_NAME_1    := R_DATA.SHORT_CUST_NAME_1;   
 R_MAIN(L_CNT).CUST_NO_1            := R_DATA.CUST_NO_1;
 R_MAIN(L_CNT).ACCOUNT_NUMBER       := R_DATA.ACCOUNT_NUMBER;
 R_MAIN(L_CNT).CUST_ACCT_ID         := R_DATA.CUST_ACCT_ID;
 R_MAIN(L_CNT).CUST_SORT_1          := R_DATA.CUST_SORT_1;   
 R_MAIN(L_CNT).CREDIT_LIMIT_1       := R_DATA.CREDIT_LIMIT_1;
 R_MAIN(L_CNT).COLLECTOR_NAME_P     := R_DATA.COLLECTOR_NAME_P;
 R_MAIN(L_CNT).collector_name       := R_DATA.collector_name;
 R_MAIN(L_CNT).COLLECTOR_EMAIL      := R_DATA.COLLECTOR_EMAIL;
 R_MAIN(L_CNT).PARENT_BALANCE       := V_FINAL_PARENT_BAL;
 R_MAIN(L_CNT).TOTAL_CUST_AMT_1     := V_FINAL_AMT;
 

END LOOP;


 -- Loading the data into XX_OD_XNET_REPORT_DATA_ITM  table
FORALL i in 1..R_MAIN.count 
insert into XX_OD_XNET_REPORT_DATA_ITM values R_MAIN(i);
commit;

END LOOP;

CLOSE C_PARENT;


EXCEPTION
  WHEN OTHERS THEN
   P_RETURN_STATUS:='E';
  P_ERR_MSG:='ERRROR AT outer most exception block please check the procedure XX_OD_XNET_LOAD_PRC:'||SQLERRM;
END XX_OD_XNET_LOAD_PRC;

/
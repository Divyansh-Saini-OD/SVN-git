CREATE OR REPLACE PACKAGE BODY XX_BPEL_INTEGRATION_PKG
IS
-- +===================================================================+
-- |                  Office Depot - Project SimplIFy                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  BPEL INTERFACE                                           |
-- | Description      :     Common Package for BPEL Integrations       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 09-JAN-2007  Rajesh Iyangar    Initial draft version      |
-- |                      Sathish                                      |
-- |                      ,WIPRO                                       |
-- |                                                                   |
-- |1.0      14-AUG-2009  Aravind A         PRD Defect 1014, Added log |
-- |                                        messages                   |
-- |1.1      05-SEP-2017  Uday Jadahv       VPS Org Context Intialization|
-- |                                        based on the lockbox Number|
-- +===================================================================|
   PROCEDURE submit_concurrent_program (
       x_errbuff                OUT      VARCHAR2
      ,x_requestid              OUT      NUMBER
      ,p_User_name              IN       VARCHAR2
      ,p_Resp_Name              IN       VARCHAR2
      ,p_Appl_short_name        IN       VARCHAR2
      ,p_Conc_short_name        IN       VARCHAR2
      ,p_sub_request            IN       VARCHAR2
      ,P_argument1              IN       VARCHAR2
      ,P_argument2              IN       VARCHAR2
      ,P_argument3              IN       VARCHAR2
      ,P_argument4              IN       VARCHAR2
      ,P_argument5              IN       VARCHAR2
      ,P_argument6              IN       VARCHAR2
      ,P_argument7              IN       VARCHAR2
      ,P_argument8              IN       VARCHAR2
      ,P_argument9              IN       VARCHAR2
      ,P_argument10             IN       VARCHAR2
      ,P_argument11             IN       VARCHAR2
      ,P_argument12             IN       VARCHAR2
      ,P_argument13             IN       VARCHAR2
      ,P_argument14             IN       VARCHAR2
      ,P_argument15             IN       VARCHAR2
      ,P_argument16             IN       VARCHAR2
      ,P_argument17             IN       VARCHAR2
      ,P_argument18             IN       VARCHAR2
      ,P_argument19             IN       VARCHAR2
      ,P_argument20             IN       VARCHAR2
      ,P_argument21             IN       VARCHAR2
      ,P_argument22             IN       VARCHAR2
      ,P_argument23             IN       VARCHAR2
      ,P_argument24             IN       VARCHAR2
      ,P_argument25             IN       VARCHAR2
      ,P_argument26             IN       VARCHAR2
      ,P_argument27             IN       VARCHAR2
      ,P_argument28             IN       VARCHAR2
      ,P_argument29             IN       VARCHAR2
      ,P_argument30             IN       VARCHAR2
      ,P_argument31             IN       VARCHAR2
      ,P_argument32             IN       VARCHAR2
      ,P_argument33             IN       VARCHAR2
      ,P_argument34             IN       VARCHAR2
      ,P_argument35             IN       VARCHAR2
      ,P_argument36             IN       VARCHAR2
      ,P_argument37             IN       VARCHAR2
      ,P_argument38             IN       VARCHAR2
      ,P_argument39             IN       VARCHAR2
      ,P_argument40             IN       VARCHAR2
      ,P_argument41             IN       VARCHAR2
      ,P_argument42             IN       VARCHAR2
      ,P_argument43             IN       VARCHAR2
      ,P_argument44             IN       VARCHAR2
      ,P_argument45             IN       VARCHAR2
      ,P_argument46             IN       VARCHAR2
      ,P_argument47             IN       VARCHAR2
      ,P_argument48             IN       VARCHAR2
      ,P_argument49             IN       VARCHAR2
      ,P_argument50             IN       VARCHAR2
      ,P_argument51             IN       VARCHAR2
      ,P_argument52             IN       VARCHAR2
      ,P_argument53             IN       VARCHAR2
      ,P_argument54             IN       VARCHAR2
      ,P_argument55             IN       VARCHAR2
      ,P_argument56             IN       VARCHAR2
      ,P_argument57             IN       VARCHAR2
      ,P_argument58             IN       VARCHAR2
      ,P_argument59             IN       VARCHAR2
      ,P_argument60             IN       VARCHAR2
      ,P_argument61             IN       VARCHAR2
      ,P_argument62             IN       VARCHAR2
      ,P_argument63             IN       VARCHAR2
      ,P_argument64             IN       VARCHAR2
      ,P_argument65             IN       VARCHAR2
      ,P_argument66             IN       VARCHAR2
      ,P_argument67             IN       VARCHAR2
      ,P_argument68             IN       VARCHAR2
      ,P_argument69             IN       VARCHAR2
      ,P_argument70             IN       VARCHAR2
      ,P_argument71             IN       VARCHAR2
      ,P_argument72             IN       VARCHAR2
      ,P_argument73             IN       VARCHAR2
      ,P_argument74             IN       VARCHAR2
      ,P_argument75             IN       VARCHAR2
      ,P_argument76             IN       VARCHAR2
      ,P_argument77             IN       VARCHAR2
      ,P_argument78             IN       VARCHAR2
      ,P_argument79             IN       VARCHAR2
      ,P_argument80             IN       VARCHAR2
      ,P_argument81             IN       VARCHAR2
      ,P_argument82             IN       VARCHAR2
      ,P_argument83             IN       VARCHAR2
      ,P_argument84             IN       VARCHAR2
      ,P_argument85             IN       VARCHAR2
      ,P_argument86             IN       VARCHAR2
      ,P_argument87             IN       VARCHAR2
      ,P_argument88             IN       VARCHAR2
      ,P_argument89             IN       VARCHAR2
      ,P_argument90             IN       VARCHAR2
      ,P_argument91             IN       VARCHAR2
      ,P_argument92             IN       VARCHAR2
      ,P_argument93             IN       VARCHAR2
      ,P_argument94             IN       VARCHAR2
      ,P_argument95             IN       VARCHAR2
      ,P_argument96             IN       VARCHAR2
      ,P_argument97             IN       VARCHAR2
      ,P_argument98             IN       VARCHAR2
      ,P_argument99             IN       VARCHAR2
      ,P_argument100            IN       VARCHAR2
   )
   IS
      lc_user_id fnd_user.user_id%TYPE;
      lc_resp_id fnd_responsibility_tl.responsibility_id%TYPE;
      lc_appl_id fnd_responsibility_tl.application_id%TYPE;
      lc_sub_request    BOOLEAN;
      lc_no_ofparameters   NUMBER;
      lc_appl_id_resp      NUMBER;


        l_argument1     VARCHAR2(100)   :=p_argument1;
        l_argument2     VARCHAR2(100)   :=p_argument2;
        l_argument3     VARCHAR2(100)   :=p_argument3;
        l_argument4     VARCHAR2(100)   :=p_argument4;
        l_argument5     VARCHAR2(100)   :=p_argument5;
        l_argument6     VARCHAR2(100)   :=p_argument6;
        l_argument7     VARCHAR2(100)   :=p_argument7;
        l_argument8     VARCHAR2(100)   :=p_argument8;
        l_argument9     VARCHAR2(100)   :=p_argument9;
        l_argument10    VARCHAR2(100)   :=p_argument10;
        l_argument11    VARCHAR2(100)   :=p_argument11;
        l_argument12    VARCHAR2(100)   :=p_argument12;
        l_argument13    VARCHAR2(100)   :=p_argument13;
        l_argument14    VARCHAR2(100)   :=p_argument14;
        l_argument15    VARCHAR2(100)   :=p_argument15;
        l_argument16    VARCHAR2(100)   :=p_argument16;
        l_argument17    VARCHAR2(100)   :=p_argument17;
        l_argument18    VARCHAR2(100)   :=p_argument18;
        l_argument19    VARCHAR2(100)   :=p_argument19;
        l_argument20    VARCHAR2(100)   :=p_argument20;
        l_argument21    VARCHAR2(100)   :=p_argument21;
        l_argument22    VARCHAR2(100)   :=p_argument22;
        l_argument23    VARCHAR2(100)   :=p_argument23;
        l_argument24    VARCHAR2(100)   :=p_argument24;
        l_argument25    VARCHAR2(100)   :=p_argument25;
        l_argument26    VARCHAR2(100)   :=p_argument26;
        l_argument27    VARCHAR2(100)   :=p_argument27;
        l_argument28    VARCHAR2(100)   :=p_argument28;
        l_argument29    VARCHAR2(100)   :=p_argument29;
        l_argument30    VARCHAR2(100)   :=p_argument30;
        l_argument31    VARCHAR2(100)   :=p_argument31;
        l_argument32    VARCHAR2(100)   :=p_argument32;
        l_argument33    VARCHAR2(100)   :=p_argument33;
        l_argument34    VARCHAR2(100)   :=p_argument34;
        l_argument35    VARCHAR2(100)   :=p_argument35;
        l_argument36    VARCHAR2(100)   :=p_argument36;
        l_argument37    VARCHAR2(100)   :=p_argument37;
        l_argument38    VARCHAR2(100)   :=p_argument38;
        l_argument39    VARCHAR2(100)   :=p_argument39;
        l_argument40    VARCHAR2(100)   :=p_argument40;
        l_argument41    VARCHAR2(100)   :=p_argument41;
        l_argument42    VARCHAR2(100)   :=p_argument42;
        l_argument43    VARCHAR2(100)   :=p_argument43;
        l_argument44    VARCHAR2(100)   :=p_argument44;
        l_argument45    VARCHAR2(100)   :=p_argument45;
        l_argument46    VARCHAR2(100)   :=p_argument46;
        l_argument47    VARCHAR2(100)   :=p_argument47;
        l_argument48    VARCHAR2(100)   :=p_argument48;
        l_argument49    VARCHAR2(100)   :=p_argument49;
        l_argument50    VARCHAR2(100)   :=p_argument50;
        l_argument51    VARCHAR2(100)   :=p_argument51;
        l_argument52    VARCHAR2(100)   :=p_argument52;
        l_argument53    VARCHAR2(100)   :=p_argument53;
        l_argument54    VARCHAR2(100)   :=p_argument54;
        l_argument55    VARCHAR2(100)   :=p_argument55;
        l_argument56    VARCHAR2(100)   :=p_argument56;
        l_argument57    VARCHAR2(100)   :=p_argument57;
        l_argument58    VARCHAR2(100)   :=p_argument58;
        l_argument59    VARCHAR2(100)   :=p_argument59;
        l_argument60    VARCHAR2(100)   :=p_argument60;
        l_argument61    VARCHAR2(100)   :=p_argument61;
        l_argument62    VARCHAR2(100)   :=p_argument62;
        l_argument63    VARCHAR2(100)   :=p_argument63;
        l_argument64    VARCHAR2(100)   :=p_argument64;
        l_argument65    VARCHAR2(100)   :=p_argument65;
        l_argument66    VARCHAR2(100)   :=p_argument66;
        l_argument67    VARCHAR2(100)   :=p_argument67;
        l_argument68    VARCHAR2(100)   :=p_argument68;
        l_argument69    VARCHAR2(100)   :=p_argument69;
        l_argument70    VARCHAR2(100)   :=p_argument70;
        l_argument71    VARCHAR2(100)   :=p_argument71;
        l_argument72    VARCHAR2(100)   :=p_argument72;
        l_argument73    VARCHAR2(100)   :=p_argument73;
        l_argument74    VARCHAR2(100)   :=p_argument74;
        l_argument75    VARCHAR2(100)   :=p_argument75;
        l_argument76    VARCHAR2(100)   :=p_argument76;
        l_argument77    VARCHAR2(100)   :=p_argument77;
        l_argument78    VARCHAR2(100)   :=p_argument78;
        l_argument79    VARCHAR2(100)   :=p_argument79;
        l_argument80    VARCHAR2(100)   :=p_argument80;
        l_argument81    VARCHAR2(100)   :=p_argument81;
        l_argument82    VARCHAR2(100)   :=p_argument82;
        l_argument83    VARCHAR2(100)   :=p_argument83;
        l_argument84    VARCHAR2(100)   :=p_argument84;
        l_argument85    VARCHAR2(100)   :=p_argument85;
        l_argument86    VARCHAR2(100)   :=p_argument86;
        l_argument87    VARCHAR2(100)   :=p_argument87;
        l_argument88    VARCHAR2(100)   :=p_argument88;
        l_argument89    VARCHAR2(100)   :=p_argument89;
        l_argument90    VARCHAR2(100)   :=p_argument90;
        l_argument91    VARCHAR2(100)   :=p_argument91;
        l_argument92    VARCHAR2(100)   :=p_argument92;
        l_argument93    VARCHAR2(100)   :=p_argument93;
        l_argument94    VARCHAR2(100)   :=p_argument94;
        l_argument95    VARCHAR2(100)   :=p_argument95;
        l_argument96    VARCHAR2(100)   :=p_argument96;
        l_argument97    VARCHAR2(100)   :=p_argument97;
        l_argument98    VARCHAR2(100)   :=p_argument98;
        l_argument99    VARCHAR2(100)   :=p_argument99;
        l_argument100   VARCHAR2(100)   :=p_argument100;
        --Added for defect 1014
        gt_file         UTL_FILE.FILE_TYPE;                                      --Added for the defect#1014
        lc_file_name    VARCHAR2(256)           DEFAULT 'FIN_BPEL_INT_PKG_LOG';  --Added for the defect#1014
-- +===================================================================+
-- | Name  : SUBMIT_CONCURRENT_PROGRAM                                 |
-- | Description      : This Program submits the concurrent Program    |
-- |                    with necessary parameters                      |
-- |                                                                   |
-- | Parameters :       Username,Responsibility Name,                  |
-- |                    Application Short Name, Concurrent Program name|
-- +===================================================================+


   BEGIN

       --Start of fix for defect 1014
       lc_file_name := lc_file_name || TO_CHAR(SYSTIMESTAMP,'_YYYYMMDD_HH24MISSFFFF');    --Added for the defect#1014
       gt_file := UTL_FILE.FOPEN('XXFIN_OUTBOUND',lc_file_name,'a',32767);      --Added for the defect#1014
       UTL_FILE.PUT_LINE(gt_file,'***************************************************************************************');   --Added for the defect#1014
       UTL_FILE.PUT_LINE(gt_file,'                        BPEL Intgration Package LOG');                                       --Added for the defect#1014
       UTL_FILE.PUT_LINE(gt_file,'***************************************************************************************');   --Added for the defect#1014
      ---Start Changes Done for VPS Lockboxes to submit the concurrent program from VPS OU Responsibility
       IF INSTR(L_ARGUMENT1,'840878')>0 or INSTR(L_ARGUMENT1,'9998447')>0 then
           BEGIN
                SELECT user_id,
                       responsibility_id,
                       RESPONSIBILITY_APPLICATION_ID
                INTO   lc_user_id,
                       lc_resp_id,
                       lc_appl_id_resp
                FROM   fnd_user_resp_groups
                WHERE  user_id=(SELECT user_id
                                 FROM  fnd_user
                                WHERE  user_name='SVC_ESP_FIN')
                  AND   responsibility_id=(SELECT responsibility_id
                                             FROM FND_RESPONSIBILITY
                                            WHERE responsibility_key = 'XX_US_VPS_AR_BATCH_JOBS');
               UTL_FILE.PUT_LINE(gt_file ,'User ID:'|| lc_user_id ||' Responsibility ID: '||lc_resp_id||'  lc_appl_id_resp:'||lc_appl_id_resp); 
               EXCEPTION
                WHEN OTHERS THEN
                 UTL_FILE.PUT_LINE(gt_file ,'Exception in initializing : ' || SQLERRM); 
            END; ---END apps intialization
       ELSE
           SELECT FU.user_id
           into
             lc_user_id
           FROM FND_USER FU
           WHERE USER_NAME = p_User_name;
    
           UTL_FILE.PUT_LINE(gt_file ,'User ID fetched for user name '|| p_User_name ||' is '||lc_user_id);  --Added for the defect#1014
    
           SELECT FRT.responsibility_id , FRT.APPLICATION_ID
           INTO
                  lc_resp_id , lc_appl_id_resp
           FROM FND_RESPONSIBILITY_TL FRT
           WHERE FRT.responsibility_name=p_resp_name;
    
           UTL_FILE.PUT_LINE(gt_file ,'Responsibility and Application ID fetched for Responsibility name '|| p_resp_name ||' is '||lc_resp_id||' and '||lc_appl_id_resp);  --Added for the defect#1014
          
          END IF;
       -- End
           SELECT application_id
           INTO
                  lc_appl_id
           FROM   fnd_concurrent_programs
           WHERE  CONCURRENT_PROGRAM_NAME = p_Conc_short_name
           AND    ENABLED_FLAG = 'Y';
    
           UTL_FILE.PUT_LINE(gt_file ,'Concurrent Program Application ID fetched for Concurrent Program name '|| p_Conc_short_name ||' is '||lc_appl_id);  --Added for the defect#1014
        
       SELECT count(*)
       INTO
             lc_no_ofparameters
       FROM FND_DESCR_FLEX_COL_USAGE_VL
       WHERE (DESCRIPTIVE_FLEXFIELD_NAME='$SRS$.'||p_Conc_short_name)
       And application_id = lc_appl_id;

       UTL_FILE.PUT_LINE(gt_file ,'Number of parameters needed for '|| p_Conc_short_name ||' is '||lc_no_ofparameters);   --Added for the defect#1014

   IF p_sub_request = 'TRUE' THEN
        lc_sub_request := TRUE;
   ELSE
        lc_sub_request := FALSE;
   END IF;

       UTL_FILE.PUT_LINE(gt_file ,'Subrequest is '|| p_sub_request);        --Added for the defect#1014

   IF (lc_no_ofparameters=0)  THEN        l_argument1:=chr(0);      END IF;
   IF (lc_no_ofparameters=1)  THEN        l_argument2:=chr(0);      END IF;
   IF (lc_no_ofparameters=2)  THEN        l_argument3:=chr(0);      END IF;
   IF (lc_no_ofparameters=3)  THEN        l_argument4:=chr(0);      END IF;
   IF (lc_no_ofparameters=4)  THEN        l_argument5:=chr(0);      END IF;
   IF (lc_no_ofparameters=5)  THEN        l_argument6:=chr(0);      END IF;
   IF (lc_no_ofparameters=6)  THEN        l_argument7:=chr(0);      END IF;
   IF (lc_no_ofparameters=7)  THEN        l_argument8:=chr(0);      END IF;
   IF (lc_no_ofparameters=8)  THEN        l_argument9:=chr(0);      END IF;
   IF (lc_no_ofparameters=9)  THEN        l_argument10:=chr(0);     END IF;
   IF (lc_no_ofparameters=10) THEN        l_argument11:=chr(0);     END IF;
   IF (lc_no_ofparameters=11) THEN        l_argument12:=chr(0);     END IF;
   IF (lc_no_ofparameters=12) THEN        l_argument13:=chr(0);     END IF;
   IF (lc_no_ofparameters=13) THEN        l_argument14:=chr(0);     END IF;
   IF (lc_no_ofparameters=14) THEN        l_argument15:=chr(0);     END IF;
   IF (lc_no_ofparameters=15) THEN        l_argument16:=chr(0);     END IF;
   IF (lc_no_ofparameters=16) THEN        l_argument17:=chr(0);     END IF;
   IF (lc_no_ofparameters=17) THEN        l_argument18:=chr(0);     END IF;
   IF (lc_no_ofparameters=18) THEN        l_argument19:=chr(0);     END IF;
   IF (lc_no_ofparameters=19) THEN        l_argument20:=chr(0);     END IF;
   IF (lc_no_ofparameters=20) THEN        l_argument21:=chr(0);     END IF;
   IF (lc_no_ofparameters=21) THEN        l_argument22:=chr(0);     END IF;
   IF (lc_no_ofparameters=22) THEN        l_argument23:=chr(0);     END IF;
   IF (lc_no_ofparameters=23) THEN        l_argument24:=chr(0);     END IF;
   IF (lc_no_ofparameters=24) THEN        l_argument25:=chr(0);     END IF;
   IF (lc_no_ofparameters=25) THEN        l_argument26:=chr(0);     END IF;
   IF (lc_no_ofparameters=26) THEN        l_argument27:=chr(0);     END IF;
   IF (lc_no_ofparameters=27) THEN        l_argument28:=chr(0);     END IF;
   IF (lc_no_ofparameters=28) THEN        l_argument29:=chr(0);     END IF;
   IF (lc_no_ofparameters=29) THEN        l_argument30:=chr(0);     END IF;
   IF (lc_no_ofparameters=30) THEN        l_argument31:=chr(0);     END IF;
   IF (lc_no_ofparameters=31) THEN        l_argument32:=chr(0);     END IF;
   IF (lc_no_ofparameters=32) THEN        l_argument33:=chr(0);     END IF;
   IF (lc_no_ofparameters=33) THEN        l_argument34:=chr(0);     END IF;
   IF (lc_no_ofparameters=34) THEN        l_argument35:=chr(0);     END IF;
   IF (lc_no_ofparameters=35) THEN        l_argument36:=chr(0);     END IF;
   IF (lc_no_ofparameters=36) THEN        l_argument37:=chr(0);     END IF;
   IF (lc_no_ofparameters=37) THEN        l_argument38:=chr(0);     END IF;
   IF (lc_no_ofparameters=38) THEN        l_argument39:=chr(0);     END IF;
   IF (lc_no_ofparameters=39) THEN        l_argument40:=chr(0);     END IF;
   IF (lc_no_ofparameters=40) THEN        l_argument41:=chr(0);     END IF;
   IF (lc_no_ofparameters=41) THEN        l_argument42:=chr(0);     END IF;
   IF (lc_no_ofparameters=42) THEN        l_argument43:=chr(0);     END IF;
   IF (lc_no_ofparameters=43) THEN        l_argument44:=chr(0);     END IF;
   IF (lc_no_ofparameters=44) THEN        l_argument45:=chr(0);     END IF;
   IF (lc_no_ofparameters=45) THEN        l_argument46:=chr(0);     END IF;
   IF (lc_no_ofparameters=46) THEN        l_argument47:=chr(0);     END IF;
   IF (lc_no_ofparameters=47) THEN        l_argument48:=chr(0);     END IF;
   IF (lc_no_ofparameters=48) THEN        l_argument49:=chr(0);     END IF;
   IF (lc_no_ofparameters=49) THEN        l_argument50:=chr(0);     END IF;
   IF (lc_no_ofparameters=50) THEN        l_argument51:=chr(0);     END IF;
   IF (lc_no_ofparameters=51) THEN        l_argument52:=chr(0);     END IF;
   IF (lc_no_ofparameters=52) THEN        l_argument53:=chr(0);     END IF;
   IF (lc_no_ofparameters=53) THEN        l_argument54:=chr(0);     END IF;
   IF (lc_no_ofparameters=54) THEN        l_argument55:=chr(0);     END IF;
   IF (lc_no_ofparameters=55) THEN        l_argument56:=chr(0);     END IF;
   IF (lc_no_ofparameters=56) THEN        l_argument57:=chr(0);     END IF;
   IF (lc_no_ofparameters=57) THEN        l_argument58:=chr(0);     END IF;
   IF (lc_no_ofparameters=58) THEN        l_argument59:=chr(0);     END IF;
   IF (lc_no_ofparameters=59) THEN        l_argument60:=chr(0);     END IF;
   IF (lc_no_ofparameters=60) THEN        l_argument61:=chr(0);     END IF;
   IF (lc_no_ofparameters=61) THEN        l_argument62:=chr(0);     END IF;
   IF (lc_no_ofparameters=62) THEN        l_argument63:=chr(0);     END IF;
   IF (lc_no_ofparameters=63) THEN        l_argument64:=chr(0);     END IF;
   IF (lc_no_ofparameters=64) THEN        l_argument65:=chr(0);     END IF;
   IF (lc_no_ofparameters=65) THEN        l_argument66:=chr(0);     END IF;
   IF (lc_no_ofparameters=66) THEN        l_argument67:=chr(0);     END IF;
   IF (lc_no_ofparameters=67) THEN        l_argument68:=chr(0);     END IF;
   IF (lc_no_ofparameters=68) THEN        l_argument69:=chr(0);     END IF;
   IF (lc_no_ofparameters=69) THEN        l_argument70:=chr(0);     END IF;
   IF (lc_no_ofparameters=70) THEN        l_argument71:=chr(0);     END IF;
   IF (lc_no_ofparameters=71) THEN        l_argument72:=chr(0);     END IF;
   IF (lc_no_ofparameters=72) THEN        l_argument73:=chr(0);     END IF;
   IF (lc_no_ofparameters=73) THEN        l_argument74:=chr(0);     END IF;
   IF (lc_no_ofparameters=74) THEN        l_argument75:=chr(0);     END IF;
   IF (lc_no_ofparameters=75) THEN        l_argument76:=chr(0);     END IF;
   IF (lc_no_ofparameters=76) THEN        l_argument77:=chr(0);     END IF;
   IF (lc_no_ofparameters=77) THEN        l_argument78:=chr(0);     END IF;
   IF (lc_no_ofparameters=78) THEN        l_argument79:=chr(0);     END IF;
   IF (lc_no_ofparameters=79) THEN        l_argument80:=chr(0);     END IF;
   IF (lc_no_ofparameters=80) THEN        l_argument81:=chr(0);     END IF;
   IF (lc_no_ofparameters=81) THEN        l_argument82:=chr(0);     END IF;
   IF (lc_no_ofparameters=82) THEN        l_argument83:=chr(0);     END IF;
   IF (lc_no_ofparameters=83) THEN        l_argument84:=chr(0);     END IF;
   IF (lc_no_ofparameters=84) THEN        l_argument85:=chr(0);     END IF;
   IF (lc_no_ofparameters=85) THEN        l_argument86:=chr(0);     END IF;
   IF (lc_no_ofparameters=86) THEN        l_argument87:=chr(0);     END IF;
   IF (lc_no_ofparameters=87) THEN        l_argument88:=chr(0);     END IF;
   IF (lc_no_ofparameters=88) THEN        l_argument89:=chr(0);     END IF;
   IF (lc_no_ofparameters=89) THEN        l_argument90:=chr(0);     END IF;
   IF (lc_no_ofparameters=90) THEN        l_argument91:=chr(0);     END IF;
   IF (lc_no_ofparameters=91) THEN        l_argument92:=chr(0);     END IF;
   IF (lc_no_ofparameters=92) THEN        l_argument93:=chr(0);     END IF;
   IF (lc_no_ofparameters=93) THEN        l_argument94:=chr(0);     END IF;
   IF (lc_no_ofparameters=94) THEN        l_argument95:=chr(0);     END IF;
   IF (lc_no_ofparameters=95) THEN        l_argument96:=chr(0);     END IF;
   IF (lc_no_ofparameters=96) THEN        l_argument97:=chr(0);     END IF;
   IF (lc_no_ofparameters=97) THEN        l_argument98:=chr(0);     END IF;
   IF (lc_no_ofparameters=98) THEN        l_argument99:=chr(0);     END IF;
   IF (lc_no_ofparameters=99) THEN        l_argument100:=chr(0);    END IF;

   FND_GLOBAL.APPS_INITIALIZE(lc_user_id,lc_resp_id,lc_appl_id_resp);

       UTL_FILE.PUT_LINE(gt_file ,'Apps has been initialized with the details '||lc_user_id||','||lc_resp_id||','||lc_appl_id_resp);  --Added for the defect#1014
    x_requestid:= fnd_request.submit_request(p_Appl_short_name
                                            ,p_Conc_short_name
                                            ,''
                                            ,''
                                            ,lc_sub_request
                                            ,l_argument1
                                            ,l_argument2
                                            ,l_argument3
                                            ,l_argument4
                                            ,l_argument5
                                            ,l_argument6
                                            ,l_argument7
                                            ,l_argument8
                                            ,l_argument9
                                            ,l_argument10
                                            ,l_argument11
                                            ,l_argument12
                                            ,l_argument13
                                            ,l_argument14
                                            ,l_argument15
                                            ,l_argument16
                                            ,l_argument17
                                            ,l_argument18
                                            ,l_argument19
                                            ,l_argument20
                                            ,l_argument21
                                            ,l_argument22
                                            ,l_argument23
                                            ,l_argument24
                                            ,l_argument25
                                            ,l_argument26
                                            ,l_argument27
                                            ,l_argument28
                                            ,l_argument29
                                            ,l_argument30
                                            ,l_argument31
                                            ,l_argument32
                                            ,l_argument33
                                            ,l_argument34
                                            ,l_argument35
                                            ,l_argument36
                                            ,l_argument37
                                            ,l_argument38
                                            ,l_argument39
                                            ,l_argument40
                                            ,l_argument41
                                            ,l_argument42
                                            ,l_argument43
                                            ,l_argument44
                                            ,l_argument45
                                            ,l_argument46
                                            ,l_argument47
                                            ,l_argument48
                                            ,l_argument49
                                            ,l_argument50
                                            ,l_argument51
                                            ,l_argument52
                                            ,l_argument53
                                            ,l_argument54
                                            ,l_argument55
                                            ,l_argument56
                                            ,l_argument57
                                            ,l_argument58
                                            ,l_argument59
                                            ,l_argument60
                                            ,l_argument61
                                            ,l_argument62
                                            ,l_argument63
                                            ,l_argument64
                                            ,l_argument65
                                            ,l_argument66
                                            ,l_argument67
                                            ,l_argument68
                                            ,l_argument69
                                            ,l_argument70
                                            ,l_argument71
                                            ,l_argument72
                                            ,l_argument73
                                            ,l_argument74
                                            ,l_argument75
                                            ,l_argument76
                                            ,l_argument77
                                            ,l_argument78
                                            ,l_argument79
                                            ,l_argument80
                                            ,l_argument81
                                            ,l_argument82
                                            ,l_argument83
                                            ,l_argument84
                                            ,l_argument85
                                            ,l_argument86
                                            ,l_argument87
                                            ,l_argument88
                                            ,l_argument89
                                            ,l_argument90
                                            ,l_argument91
                                            ,l_argument92
                                            ,l_argument93
                                            ,l_argument94
                                            ,l_argument95
                                            ,l_argument96
                                            ,l_argument97
                                            ,l_argument98
                                            ,l_argument99
                                            ,l_argument100
);

       UTL_FILE.PUT_LINE(gt_file ,'Concurrent program has been submitted , Request ID is '||x_requestid);  --Added for the defect#1014
       UTL_FILE.fclose(gt_file);                                                                           --Added for the defect#1014

           
     EXCEPTION
       WHEN OTHERS
       THEN
           x_errbuff := 'Error Code: '||SQLCODE|| ' Error Msg: ' ||SQLERRM;          --Added for the defect#1014
           UTL_FILE.PUT_LINE(gt_file ,'Error in the program');                       --Added for the defect#1014
           UTL_FILE.PUT_LINE(gt_file ,'SQL error is '||SQLERRM||'-------'||SQLCODE); --Added for the defect#1014
           UTL_FILE.fclose(gt_file);  --Added for the defect#1014
   END submit_concurrent_program;

-- +===================================================================+
-- | Name  : GET_CONCURRENT_REQUEST_STATUS                             |
-- | Description      : This Program returns the status of a concurrent|
-- |                    Request                                        |
-- |                                                                   |
-- | Parameters :       Request Id                                     |
-- |                    Phase, Control                                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE get_concurrent_request_status ( p_request_id      IN             NUMBER
                                           , p_child_requests  IN             VARCHAR2 DEFAULT 'T'
                                           , x_phase_code      IN OUT  NOCOPY VARCHAR2
                                           , x_status_code     IN OUT  NOCOPY VARCHAR2
                                           , x_error_Desc      IN OUT  NOCOPY VARCHAR2
                                           )
   IS
    
     CURSOR c_child_requests ( p_request_id NUMBER)
     IS
        SELECT request_id
        FROM   fnd_concurrent_requests
        WHERE  parent_request_id =  p_request_id;
     
   BEGIN
      
       SELECT phase_code,
              status_code,
              completion_text
       INTO   x_phase_code,
              x_status_code,
              x_error_Desc
       FROM   fnd_concurrent_requests
       WHERE  request_id =  p_request_id;
        
       Exception When Others THEN
       x_error_Desc := 'Error Encountered in Package ' || SQLERRM ;
     
   END;
     
end XX_BPEL_INTEGRATION_PKG;
/

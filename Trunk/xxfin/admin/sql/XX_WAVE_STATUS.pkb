SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY XX_WAVE_STATUS
AS
FUNCTION VALIDATE_USER RETURN BOOLEAN;


-- +==========================================================================+
-- |                 EAS Oracle Center Of Excellence                          |
-- |                       WIPRO Technologies                                 |
-- |                                                                          |
-- +==========================================================================+
-- | Name :    VALIDATE_USER                                                  |
-- |                                                                          |
-- | Description : This function used to validate whether the user can access |
-- |               the page                                                   |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |  1.0    05-OCT-2010    Jude Felix Antony    Initial Version              |
-- |                                                                          |
-- +==========================================================================+

   
   FUNCTION VALIDATE_USER RETURN BOOLEAN
   AS

   ln_check   NUMBER DEFAULT 0;

   BEGIN
   IF (icx_sec.ValidateSession )  THEN

         SELECT XFTV.target_value1
         INTO   ln_check
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
         WHERE  XFTD.translate_id = XFTV.translate_id
         AND    XFTD.translation_name = 'XX_WAVE_USER_SECURITY'
         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
         AND    XFTV.enabled_flag = 'Y'
         AND    XFTD.enabled_flag = 'Y'
         AND    XFTV.target_value1 IN (SELECT USER_NAME FROM APPS.FND_USER
                                       WHERE  USER_ID = FND_PROFILE.VALUE('USER_ID'));
       

      IF(ln_check>0) THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;

   END IF;

   EXCEPTION

      WHEN OTHERS THEN

         RETURN FALSE;

   END;

-- +==========================================================================+
-- |                 EAS Oracle Center Of Excellence                          |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name :    PROCESS_REQUEST                                                |
-- |                                                                          |
-- | Description : Procedure is used to submit the wave status Program.       |
-- | Change Record:                                                           |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |  1.0    05-OCT-2010    Jude Felix Antony    Initial Version              |
-- |                                                                          |
-- +==========================================================================+
   
   PROCEDURE PROCESS_REQUEST(p_cycle_date        VARCHAR2  DEFAULT   NULL
                            ,p_mail_type         VARCHAR2  DEFAULT  'DEF'
                            ,p_mail_address      VARCHAR2  DEFAULT  ''
                            ,p_mail_flag         VARCHAR2  DEFAULT  'Y'
                            ,p_issues            CLOB      DEFAULT  'No Issues'
                            ,p_action            VARCHAR2)
   AS
   ln_prl_req_id NUMBER;
   ln_user_name  VARCHAR2(300);
   ln_resp_name  VARCHAR2(500);
   lc_error      VARCHAR2(300);
   BEGIN
      --- Printing the page header
   IF (icx_sec.ValidateSession ) AND (VALIDATE_USER)  THEN
      lc_error := 'Printing Header';
            htp.p('<html>'
                ||'<head>'
                ||'<TITLE>  WAVE STATUS MAILING  </TITLE>'
                ||'</head>'
                ||'<body>'
                ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
                ||'<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>'
                ||'<td align="right"><form name="para" action="XX_WAVE_STATUS.MAILING" method="POST"><br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''"><font size=2 face="arial" Color="blue"><u> Go to Main Page </u></font></a></form></td>'
                ||'<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td>'
                ||'<td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>'
                ||'</TABLE>'
                ||'<hr width=100% size="7" color="red" noshade="noshade">'
                ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
                ||'<tr><td width="25%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>'
                ||'<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> <h1> WAVE STATUS MAILING </h1> </b></font></td></tr>'
                ||'</TABLE>'
                ||'<br>');

    FND_GLOBAL.APPS_INITIALIZE(USER_ID      => FND_PROFILE.VALUE('USER_ID')                 
                              ,RESP_ID      => FND_PROFILE.VALUE('RESP_ID')
                              ,RESP_APPL_ID => FND_PROFILE.VALUE('RESP_APPL_ID'));


        BEGIN

        SELECT user_name 
        INTO   ln_user_name 
        FROM   apps.fnd_user 
        WHERE  user_id = FND_PROFILE.VALUE('USER_ID');

        EXCEPTION
            
            WHEN NO_DATA_FOUND THEN
             
             ln_user_name := 'USER NAME NOT FOUND';

            WHEN OTHERS THEN
            
             NULL;

        END;

        BEGIN

        SELECT responsibility_key  
        INTO   ln_resp_name
        FROM   apps.fnd_responsibility 
        where  responsibility_id = FND_PROFILE.VALUE('RESP_ID');

        EXCEPTION

            WHEN NO_DATA_FOUND THEN

              ln_resp_name := 'RESPONSIBILITY NAME NOT FOUND';

            WHEN OTHERS THEN
            
              NULL;

        END;

        --+--------------------------------------+--
        --+ Submitting the Wave status program   +--
        --+--------------------------------------+--

        ln_prl_req_id := FND_REQUEST.SUBMIT_REQUEST (application  => 'XXFIN' 
                                                    ,program      => 'XXWAVES' 
                                                    ,start_time   => sysdate 
                                                    ,sub_request  => false 
                                                    ,argument1    => p_cycle_date
                                                    ,argument2    => p_issues
                                                    ,argument3    => p_mail_type
                                                    ,argument4    => ''
                                                    ,argument5    => p_mail_address
                                                    ,argument6    => p_mail_flag
                                                    ); 
        COMMIT;
        htp.p('<table cellPadding="2" border="3" width = "100%">');
        htp.p('<tbody>');                        
        htp.p('<tr>'); 
        htp.p('<td colspan= "2" align="center" bgColor= "#C48793" ><font size="6"> PROGRAM DETIALS </font></td>');
        htp.p('</tr>'); 
        htp.p('<tr>'); 
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">Submitted by User </font></td>');
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">'||ln_user_name||'</font></td>');
        htp.p('</tr>'); 
        htp.p('<tr>'); 
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">Submitted from Responsibility </font></td>');
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">'||ln_resp_name||'</font></td>');
        htp.p('</tr>'); 
        htp.p('<tr>'); 
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">Submitted Request id </font></td>');
        htp.p('<td align="center" bgColor= "#FAAFBA" ><font size="6">'||ln_prl_req_id||'</font></td>');
        htp.p('</tr>'); 
        htp.p('</tbody>');   
        htp.p('</table>');   

     END IF;
END;
-- +==========================================================================+
-- |                 EAS Oracle Center Of Excellence                          |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name :    MAILING                                                        |
-- |                                                                          |
-- | Description : Procedure to generate the UI which is used to submit wave  |
-- |               status.                                                    |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |  1.0    05-OCT-2010   Jude Felix Antony    Initial Version               |
-- |                                                                          |
-- +==========================================================================+

  PROCEDURE MAILING
  AS
      BEGIN
       IF (icx_sec.ValidateSession) AND (VALIDATE_USER)  THEN
       -- Header
                htp.p('<HTML>');
                htp.p('<HEAD>');
                htp.p('<TITLE>  WAVE STATUS MAILING  </TITLE>');
                htp.p('</HEAD>');
                htp.p('<BODY MARGINHEIGHT=0 MARGINWIDTH=0 BGCOLOR="">');
                htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
                htp.p('<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>');
                htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
                htp.p('</TABLE>');
                htp.p('<hr width=100% size="7" color="red" noshade="noshade">');
                htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
                htp.p('<tr><td width="20%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>');
                htp.p('<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> <h1> WAVE STATUS MAILING </h1> </b></font></td></tr>');
                htp.p('</TABLE>');
                htp.p('</BODY>');
                htp.p('</HTML>');
      -- Main Body
      
      
 htp.print(' 
     
      <script type="text/javascript">
       function validate_form(thisform)
      {
      document.body.style.cursor=''wait'';
      with (thisform)
        {
        if (p_mail_flag.value == "")
          {
           p_mail_flag.focus();
           alert("Please select the Mailing Flag");
           return false;
          }
        }
      }
      </script>

      <script type="text/javascript">
      function checkSelect1(selVal) 
      {
        sel2 = document.getElementById("p_mail_address");
          if ((selVal == "DEF"))
          {
          sel2.value="";
          sel2.style.visibility= "hidden";
          } 
          else 
          {
          sel2.style.visibility= "visible";
          }
      }
      </script>
      

      <script type="text/javascript">
      function onloadDisable() 
      {
        
        sel2 = document.getElementById("p_mail_address");
        sel2.value="";
        sel2.style.visibility= "hidden";
      }
      </script>

      <!-- standalone page styling -->

      <style>
      body {
              padding:10px 50px;
              font-family:"Lucida Grande","Lucida Sans Unicode","bitstream vera sans","trebuchet ms",verdana;
      }
      /* get rid of those system borders being generated for A tags */
      a:active {
        outline:none;
      }
      :focus {
        -moz-outline-style:none;
      }
      </style>


      <!-- javascript coding -->
      <script>
      $(function() {
      // select all desired input fields and attach tooltips to them
      $("#myform :input").tooltip({
              // place tooltip on the right edge
              position: "center right",
              // a little tweaking of the position
              offset: [-2, 10],
              // use the built-in fadeIn/fadeOut effect
              effect: "fade",
              // custom opacity setting
              opacity: 0.7,
              // use this single tooltip element
              tip: ''.tooltip''
      });
      });
      </script>

      </head>
      <body>
      <style>
      .tooltip {
              background-color:#000;
              border:1px solid #fff;
              padding:10px 15px;
              width:200px;
              display:none;
              color:#fff;
              text-align:left;
              font-size:12px;

              /* outline radius for mozilla/firefox only */
              -moz-box-shadow:0 0 10px #000;
              -webkit-box-shadow:0 0 10px #000;
      }

      #myform {
              border:2px outset #ccc;
              padding:5px;
              margin:20px 0;
              width:800px;
              -moz-border-radius:4px;
      }

      #myform h3 {
              text-align:center;
              margin:0 0 10px 0;
      }

      #inputs label, #inputs input, #inputs textarea, #inputs select {
              display: block;
              width: 550px;
              float: left;
              margin-bottom: 4px;
      }

      #inputs label {
              text-align: right;
              width: 200px;
              padding-right: 1px;
      }

      #inputs br {
              clear: left;
      }
      </style>
      <body onload="onloadDisable();">
      <div class="tooltip"></div>
      <CENTER>
      <FORM NAME="myform" id="myform" ACTION="XX_WAVE_STATUS.PROCESS_REQUEST" METHOD="POST"  onsubmit="return validate_form(this)">
             
              <div id="inputs">
                        
                        <!-- Cycle Date -->
                        <label for="p_cycle_date"> <b> Cycle Date </b> (DD-MON-YYYY) </label>
                        <input id="p_cycle_date" maxLength=11  name="p_cycle_date" style="WIDTH: 87px; HEIGHT: 22px" size=12 title="Enter a Cycle Date in (DD-MON-YYYY) " /><br />
                      
                         <!-- Mailing Type -->
                        <label for="p_mail_type"> <b>Mailing Type </b></label>
                        <td align="left">
                        <SELECT NAME="p_mail_type" style="width:100px" title=" Enter the Mailing Type " onchange="checkSelect1(this.value);"><br />
                        <OPTION VALUE="ALL">All
                        <OPTION SELECTED VALUE="DEF">Default
                        <OPTION VALUE="SEL">Selected
                        </SELECT>
                        </td></tr><br />
                       
                        <!-- Mail Address -->
                        <label for="p_mail_address"> <b> Mailing Address </b></label>
                        <textarea id="p_mail_address" name="p_mail_address"  title="Enter the Mail Address "></textarea><br />

                        <!-- Mail Flag -->
                        <label for="p_mail_flag"><b> Mailing Flag </b> </label>
                        <td align="left">
                        <SELECT NAME="p_mail_flag"  style="width:100px" title=" Enter the Mailing Flag "><br />
                        <OPTION SELECTED VALUE="Y">Yes
                        <OPTION VALUE="N">No
                        </SELECT>
                        </td></tr> <br/>
                        
                        <!-- Issues -->
                        <label for="p_issues"> <b> Issues & Updates </b> </label>
                        <textarea id="p_issues" name="p_issues" rows="15" cols="1" title="Enter Issues and Updates "></textarea><br />
              </div>
              </p>
                        <INPUT TYPE=SUBMIT NAME="p_action" title="Submit Status Mail" VALUE="Submit">
                        <INPUT TYPE=RESET NAME="p_clear" VALUE="Clear" title="Reset Form" onClick="onloadDisable();">
              </form>
      </CENTER>
      ');

      htp.p('

      <div align=center>
      Usage : Click on the respective fields for instructions.
      </div>

      <p style=''margin-bottom:12.0pt''><o:p>&nbsp;</o:p></p>

      </div>');
      htp.p('</BODY>
      </HTML>');

      ELSE
      
      htp.p('<html>'
                ||'<head>'
                ||'<TITLE>  WAVE STATUS MAILING  </TITLE>'
                ||'</head>'
                ||'<body>'
                ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
                ||'<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>'
                ||'<td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>'
                ||'</TABLE>'
                ||'<hr width=100% size="7" color="red" noshade="noshade">'
                ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
                ||'<tr><td width="25%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>'
                ||'<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> <h1> WAVE STATUS MAILING </h1> </b></font></td></tr>'
                ||'</TABLE>'
                ||'<br>'
                ||'<br>'
                ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
                ||'<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" size="4"><b> <h1> You are not authorised to view this page, please contact System Administrator</h1> </b></font></td></tr>'
                ||'</TABLE>'
                ||'<br>');
      END IF;
      END;
  END;
/
SHOW ERR;
/
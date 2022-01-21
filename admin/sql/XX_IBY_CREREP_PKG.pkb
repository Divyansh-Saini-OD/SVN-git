SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating Package Body XX_IBY_CREREP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE BODY      XX_IBY_CREREP_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      Credit Card Settlement Report                         |
-- | Description : To generate a report of the Credit Card Settlement  |
-- |              History table which helps to analyze all previous    |
-- |              credit card settlement transactions.                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       25-MAY-2007  Anusha Ramanujam     Initial version        |
-- |1.1       06-DEC-2007  Aravind A.           Fixed defect 2925      |
-- |1.2       25-JAN-2008  Aravind A.           Fixed defect 3832      |
-- |1.3       17-MAR-2008  Anusha Ramanujam     Fix for defect 5436    |
-- |1.4       19-MAR-2008  Anitha Devarajulu    Manual Ref Defect 5127 |
-- |1.5       09-APR-2008  Ranjith Prabu T      Fix for defect 5436    |
-- |1.6       25-JUN-2008  Aravind A.           Fixed defect 8403      |
-- |1.7       06-APR-2010  Usha R   .           Fixed defect 4587      |
-- |1.8       06-MAY-2010  Rama Krishna K       Fixed defect 1111      |
-- |                                            to show POS key tranxs |
-- |1.9       10-MAY-2010  Rani Asaithambi      Modified for the Defect|
-- |                                            1111.                  |
-- |2.0       20-JUN0-2011 P.Sankaran           Defect 12161           |
-- |                                            Removed condition for  |
-- |                                            P_CASH_REC_ID          |
-- |2.1       06-NOV-2013  P.Marco              Added XX_DECRYPT_KEY   |
-- |                                            function               |
-- |2.2       02-Nov-2015  Avinash Baddam      R12.2 Compliance Changes|
-- +===================================================================+



    gn_user_id          NUMBER;
    gn_resp_id          NUMBER;
    gn_resp_appl_id     NUMBER;
    gc_sign             VARCHAR2(2) DEFAULT '<';

    lc_error_loc        VARCHAR2(250);
    
    
    FUNCTION XX_DECRYPT_KEY(P_RECEIPT_NUM   IN  VARCHAR2
                            ,P_BATCH_NUM    IN  VARCHAR2)
                            RETURN VARCHAR2 IS
     
     VTEST1 VARCHAR2(1000);
     LC_CC_SEGMENT_REF      VARCHAR2(200)  DEFAULT NULL;
     LC_CC_NUMBER           VARCHAR2(100)  DEFAULT NULL;
     LC_KEY_LABEL                    XX_IBY_BATCH_TRXNS.ATTRIBUTE8%TYPE :=NULL;
     x_error_message VARCHAR2(1000);
     
     BEGIN
     
                    SELECT DECODE(ixregisternumber,'54',ixaccount,'55',ixaccount,'56',ixaccount,'99',ixaccount                 -- Defect 5127
                                        ,NVL(SUBSTR(IXSWIPE,1,INSTR(IXSWIPE,'=',-1)-1), IXACCOUNT))
                ,ATTRIBUTE8
          INTO   lc_cc_segment_ref
                ,LC_KEY_LABEL
          FROM   xx_iby_batch_trxns_history
         WHERE IXRECEIPTNUMBER=P_RECEIPT_NUM
         AND IxIPaymentbatchnumber=p_batch_num;
     
         DBMS_SESSION.SET_CONTEXT(NAMESPACE => 'XX_IBY_RPT_CONTEXT'
                                 ,ATTRIBUTE => 'TYPE'
                                 ,value     => 'EBS');

                                     
          XX_OD_SECURITY_KEY_PKG.DECRYPT(
                                         p_module         => 'AJB'
                                        ,p_key_label      => lc_key_label 
                                        ,p_algorithm      => '3DES'
                                        ,p_encrypted_val  => lc_cc_segment_ref
                                        ,x_decrypted_val  => lc_cc_number
                                        ,x_error_message  => x_error_message
                                        );
           return lc_cc_number;
            
     END;    

-- +===================================================================+
-- | Name : VALIDATE_USER_RESP                                         |
-- | Description : Function to validate user for responsibility and    |
-- | function Added as part of defect 3832 fix                         |
-- +===================================================================+

   FUNCTION VALIDATE_USER_RESP RETURN BOOLEAN
   AS

   ln_check   NUMBER DEFAULT 0;

   BEGIN

      SELECT COUNT(*)
      INTO ln_check
      FROM fnd_user_resp_groups_direct
      WHERE user_id = FND_PROFILE.VALUE('USER_ID')
      AND  responsibility_id IN (
                                 SELECT FR.responsibility_id
                                 FROM  fnd_responsibility FR
                                      ,fnd_responsibility_tl FRT
                                 WHERE FRT.responsibility_id = FND_PROFILE.VALUE('RESP_ID')
                                 AND   FRT.language = USERENV('LANG')
                                 AND  SYSDATE BETWEEN start_date AND NVL(end_date,sysdate+1)
                                 AND   FRT.responsibility_name IN (SELECT XFTV.target_value1
                                                                   FROM   xx_fin_translatedefinition XFTD
                                                                         ,xx_fin_translatevalues XFTV
                                                                   WHERE  XFTD.translate_id = XFTV.translate_id
                                                                   AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
                                                                   AND    XFTV.source_value1 = 'OD Credit Card Resp'
                                                                   AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                                                                   AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                                                                   AND    XFTV.enabled_flag = 'Y'
                                                                   AND    XFTD.enabled_flag = 'Y')
                                  )
     AND  SYSDATE BETWEEN start_date AND NVL(end_date,sysdate+1);


      IF(ln_check>0) THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;

   EXCEPTION

      WHEN OTHERS THEN

         RETURN FALSE;

   END;

-- +===================================================================+
-- | Name : XX_IBY_DISPPAGE                                            |
-- | Description : To to create and display the frame structure only   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_IBY_DISPPAGE

    AS
       lc_url       VARCHAR2(2000);

    BEGIN

       htp.htmlOpen;

       htp.headOpen;
       htp.title(ctitle => 'Credit Card Settlement Report');
       htp.headClose;

       htp.framesetOpen (
                         crows       => '20%,80%'
                        ,cattributes => 'BORDER=0 FRAMESPACING=0'
                         );

       lc_url := owa_util.get_owa_service_path||'XX_IBY_CREREP_PKG.XX_IBY_PARAFORM';
       htp.frame (
                  csrc          => lc_url
                 ,cname         => 'XX_IBY_PARAFORM'
                 ,cmarginwidth  => '2'
                 ,cscrolling    => 'NO'
                 ,cnoresize     => 'NORESIZE'
                 ,cattributes   => 'FRAMEBORDER=NO'
                   );

       lc_url := owa_util.get_owa_service_path||'XX_IBY_CREREP_PKG.XX_IBY_HDRREC';
       htp.frame (
                  csrc          => lc_url
                 ,cname         => 'XX_IBY_HDRREC'
                 ,cmarginwidth  => '2'
                 ,cscrolling    => 'YES'
                 ,cnoresize     => 'NORESIZE'
                 ,cattributes   => 'FRAMEBORDER=NO'
                   );

       htp.p('<noframes>'
             ||'This page uses frames, but your browser doesn''t support them.'
             ||'</noframes>');

       htp.framesetClose;
       htp.htmlClose;

    EXCEPTION
        WHEN OTHERS THEN
           htp.strong('Error while displaying Credit Card Settlement Report frames: '||SQLERRM);

    END XX_IBY_DISPPAGE;


-- +===================================================================+
-- | Name : XX_IBY_PARAFORM                                            |
-- | Description : To create and display parameter form along with     |
-- |               "Go" and "Cancel" buttons.                          |
-- |               It will also verify if the date paramter values     |
-- |               entered by the user are valid or not.               |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE XX_IBY_PARAFORM
    AS
    lc_apl_url         VARCHAR2(240);
    lc_script CONSTANT VARCHAR2(4000) DEFAULT
         '<script language="javascript">
         var MONTH_NAMES=new Array("January","February","March","April","May","June","July","August","September","October","November","December","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
         var DAY_NAMES=new Array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sun","Mon","Tue","Wed","Thu","Fri","Sat");
         ';

    lc_script1 CONSTANT VARCHAR2(4000) DEFAULT
         'function compareDates()
        {
           var error_flag = 0;
           var format_string = "d-NNN-y";

           var ldate = document.getElementById("p_ldate").value;
           var hdate = document.getElementById("p_hdate").value;
           var damt  = document.getElementById("p_dollamt").value;
           var cond  = document.group.p_cond.selectedIndex;

           ldate = trim(ldate);
           hdate = trim(hdate);

           if (ldate == "")
             {
                     alert("A Value must be entered for Date Low");
                     error_flag = 1;
                     group.p_ldate.focus();
             }

            if (error_flag == 0)
            {
              if (hdate == "")
                {
                    alert("A Value must be entered for Date High");
                    error_flag = 1;
                    group.p_hdate.focus();
                }
            }

           var d1 = getDateFromFormat(ldate,format_string);
           var d2 = getDateFromFormat(hdate,format_string);

           if (error_flag == 0)
           {
               if (d1==0 || d2==0)
               {
                  alert("Invalid Date Format");
                  error_flag = 1;
               }
           }

           if (error_flag == 0)
           {
               if (d1 > d2)
               {
                  alert("Date Low cannot be greater than Date High");
                  error_flag = 1;
               }
           }

          if (error_flag == 0)
           {
               if ( (cond > 0) && (damt == "") )
               {
                  alert("Enter an amount in the Dollar Amount field");
                  error_flag = 1;
                  group.p_dollamt.focus();
               }
           }

           if (error_flag == 0)
           {
               if (!(_isCurrency(damt)))
               {
                  alert("A number value must be entered in the Dollar amount field");
                  error_flag = 1;
                  group.p_dollamt.focus();
               }
           }

           if (error_flag == 0)
           {
                  document.group.submit();
           }

        }';

    lc_script2 CONSTANT VARCHAR2(4000) DEFAULT
        'function _isInteger(val)
         {
             var digits="1234567890";
             for (var i=0; i < val.length; i++)
             {
                  if (digits.indexOf(val.charAt(i))==-1) { return false; }
             }
             return true;
         }

         function _isCurrency(val)
         {
             var digits="1234567890.";
             for (var i=0; i < val.length; i++)
             {
                  if (digits.indexOf(val.charAt(i))==-1) { return false; }
             }
             return true;
         }

          function _getInt(str,i,minlength,maxlength)
         {
              for (var x=maxlength; x>=minlength; x--)
             {
                   var token=str.substring(i,i+x);
                   if (token.length < minlength) { return null; }
                   if (_isInteger(token)) { return token; }
             }
             return null;
         }';

    lc_script3 CONSTANT VARCHAR2(2000) DEFAULT
        'function trim(input_string)
        {
         var str = input_string;

            while (str.charAt(0) == " ")
                str = str.substring(1,str.length);

            while (str.charAt(str.length - 1) == " ")
                str = str.substring(0, str.length - 1);

         return(str);
        }';

    lc_script4 CONSTANT VARCHAR2(4000) DEFAULT
        'function getDateFromFormat(val,format)
		{
		val=val+"";
		format=format+"";
		var i_val=0;
		var i_format=0;
		var c="";
		var token="";
		var token2="";
		var x,y;
		var now=new Date();
		var year=now.getYear();
		var month=now.getMonth()+1;
		var date=1;
		var hh=now.getHours();
		var mm=now.getMinutes();
		var ss=now.getSeconds();
		var ampm="";

		while (i_format < format.length) {
			c=format.charAt(i_format);
			token="";
			while ((format.charAt(i_format)==c) && (i_format < format.length)) {
				token += format.charAt(i_format++);
				}
			if (token=="yyyy" || token=="yy" || token=="y") {
				if (token=="yyyy") { x=4;y=4; }
				if (token=="yy")   { x=2;y=2; }
				if (token=="y")    { x=2;y=4; }
				year=_getInt(val,i_val,x,y);
				if (year==null) { return 0; }
				i_val += year.length;
				if (year.length==2) {
					if (year > 70) { year=1900+(year-0); }
					else { year=2000+(year-0); }
					}
				}
			else if (token=="MMM"||token=="NNN"){
				month=0;
				for (var i=0; i<MONTH_NAMES.length; i++) {
					var month_name=MONTH_NAMES[i];
					if (val.substring(i_val,i_val+month_name.length).toLowerCase()==month_name.toLowerCase()) {
						if (token=="MMM"||(token=="NNN"&&i>11)) {
							month=i+1;
							if (month>12) { month -= 12; }
							i_val += month_name.length;
							break;
							}
						}
					}
				if ((month < 1)||(month>12)){return 0;}
				}
			else if (token=="EE"||token=="E"){
				for (var i=0; i<DAY_NAMES.length; i++) {
					var day_name=DAY_NAMES[i];
					if (val.substring(i_val,i_val+day_name.length).toLowerCase()==day_name.toLowerCase()) {
						i_val += day_name.length;
						break;
						}
					}
				}
			else if (token=="MM"||token=="M") {
				month=_getInt(val,i_val,token.length,2);
				if(month==null||(month<1)||(month>12)){return 0;}
				i_val+=month.length;}
			else if (token=="dd"||token=="d") {
				date=_getInt(val,i_val,token.length,2);
				if(date==null||(date<1)||(date>31)){return 0;}
				i_val+=date.length;}
			else if (token=="hh"||token=="h") {
				hh=_getInt(val,i_val,token.length,2);
				if(hh==null||(hh<1)||(hh>12)){return 0;}
				i_val+=hh.length;}
			else if (token=="HH"||token=="H") {
				hh=_getInt(val,i_val,token.length,2);
				if(hh==null||(hh<0)||(hh>23)){return 0;}
				i_val+=hh.length;}
			else if (token=="KK"||token=="K") {
				hh=_getInt(val,i_val,token.length,2);
				if(hh==null||(hh<0)||(hh>11)){return 0;}
				i_val+=hh.length;}
			else if (token=="kk"||token=="k") {
				hh=_getInt(val,i_val,token.length,2);
				if(hh==null||(hh<1)||(hh>24)){return 0;}
				i_val+=hh.length;hh--;}
			else if (token=="mm"||token=="m") {
				mm=_getInt(val,i_val,token.length,2);
				if(mm==null||(mm<0)||(mm>59)){return 0;}
				i_val+=mm.length;}
			else if (token=="ss"||token=="s") {
				ss=_getInt(val,i_val,token.length,2);
				if(ss==null||(ss<0)||(ss>59)){return 0;}
				i_val+=ss.length;}
			else if (token=="a") {
				if (val.substring(i_val,i_val+2).toLowerCase()=="am") {ampm="AM";}
				else if (val.substring(i_val,i_val+2).toLowerCase()=="pm") {ampm="PM";}
				else {return 0;}
				i_val+=2;}
			else {
				if (val.substring(i_val,i_val+token.length)!=token) {return 0;}
				else {i_val+=token.length;}
				}
			}
		if (i_val != val.length) { return 0; }
		if (month==2) {
			if ( ( (year%4==0)&&(year%100 != 0) ) || (year%400==0) ) {
				if (date > 29){ return 0; }
				}
			else { if (date > 28) { return 0; } }
			}
		if ((month==4)||(month==6)||(month==9)||(month==11)) {
			if (date > 30) { return 0; }
			}
		if (hh<12 && ampm=="PM") { hh=hh-0+12; }
		else if (hh>11 && ampm=="AM") { hh-=12; }
		var newdate=new Date(year,month-1,date,hh,mm,ss);
		return newdate.getTime();
	}';

   CURSOR lcu_cntry_code
   IS
      SELECT XFTV.source_value1   cntry_code
            ,HOU.organization_id  org_id
      FROM  xx_fin_translatedefinition XFTD
            ,xx_fin_translatevalues XFTV
            ,hr_operating_units HOU
      WHERE XFTD.translate_id = XFTV.translate_id
         AND HOU.name = XFTV.target_value2
         AND XFTD.translation_name = 'OD_COUNTRY_DEFAULTS'
         AND SYSDATE BETWEEN XFTV.start_date_active
         AND NVL(xftv.end_date_active,   SYSDATE + 1)
         AND SYSDATE BETWEEN XFTD.start_date_active
         AND NVL(XFTD.end_date_active,   SYSDATE + 1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

    BEGIN

       IF (icx_sec.ValidateSession)
             AND (VALIDATE_USER_RESP) THEN

       -- Creating the page layout with report title, company name and date
          htp.p('<HTML>');
          htp.p('<HEAD>');
          htp.p('<TITLE> Credit Card Settlement Report </TITLE>');
          htp.p('</HEAD>');
          htp.p('<BODY MARGINHEIGHT=0 MARGINWIDTH=0 BGCOLOR="">');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>');
          htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('<hr width=100% size="7" color="red" noshade="noshade">');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="20%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>');
          htp.p('<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> Credit Card Settlement Report </b></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('</BODY>');
          htp.p('</HTML>');

       -- Parameters page
          htp.p('<html>');
          htp.p('<head>');
          htp.p(lc_script);
          htp.p(lc_script1);
          htp.p(lc_script2);
          htp.p(lc_script3);
          htp.p(lc_script4);
          htp.p('</script>');

          htp.p('<script language="javascript">');
          htp.p('void function onloadDisable(){');
              htp.p('if (document.group.p_ordtyp.selectedIndex==2){');
              htp.p('document.group.p_regnum.disabled =false;');
              htp.p('document.group.p_trannum.disabled=false;}');
              htp.p('else if (document.group.p_ordtyp.selectedIndex==3){');
              htp.p('document.group.p_regnum.disabled =true;');
              htp.p('document.group.p_trannum.disabled=false;}');
              htp.p('else{');
              htp.p('document.group.p_regnum.disabled =true;');
              htp.p('document.group.p_trannum.disabled=false;}');
          htp.p('}');
          htp.p('void function disableField(){');
          htp.p('if (document.group.p_ordtyp.selectedIndex==2){');
              htp.p('document.getElementById("p_regnum").value = "";');
              htp.p('document.getElementById("p_trannum").value = "";');
              htp.p('document.group.p_regnum.disabled =false;');
              htp.p('document.group.p_trannum.disabled=false;}');
          htp.p('else if (document.group.p_ordtyp.selectedIndex==3){');
              htp.p('document.getElementById("p_regnum").value = "";');
              htp.p('document.getElementById("p_trannum").value = "";');
              htp.p('document.group.p_regnum.disabled =true;');
              htp.p('document.group.p_trannum.disabled=false;}');
          htp.p('else {');
              htp.p('document.getElementById("p_regnum").value = "";');
              htp.p('document.getElementById("p_trannum").value = "";');
              htp.p('document.group.p_regnum.disabled =true;');
              htp.p('document.group.p_trannum.disabled=false;}');
          htp.p('}');
          htp.p('</script>');
          htp.p('</head>');

          htp.p('<body onload="onloadDisable();" BGCOLOR="#FFFFFF" LINK="blue" ALINK="RED" VLINK="PURPLE">');
          --htp.p('<body BGCOLOR="#FFFFFF" LINK="blue" ALINK="RED" VLINK="PURPLE">');
          htp.p('<br>');
          htp.p('<FORM NAME="group" ACTION="XX_IBY_CREREP_PKG.XX_IBY_HDRREC" METHOD="post">');

          htp.p('<TABLE border="0" bgcolor="#FAF0E6" cellspacing="0" cellpadding="0" align="center" width="80%">');
          htp.p('<tr><td colspan=3 height="15"></td></tr>');

       -- date low and date high
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Date Low <b>(DD-MON-YYYY)</b></font></td>');
          htp.p('<td align="left"><input type="DATE" name="p_ldate" value="" " size="10" >');

          htp.p('<td align="right" width="200"><font face="Arial" size="2">Date High <b>(DD-MON-YYYY)</b></font></td>');
          htp.p('<td align="center"><input type="DATE" name="p_hdate" value="" " size="10" ></td>');
          htp.p('</tr>');

       -- location/store number
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Location/Store Number</font></td>');
          htp.p('<td align="left"><input type="NUMBER(10)" name="p_locstrnum" value = "" "size="5"></td>');
          htp.p('</tr>');

       -- order type
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Order Type</font></td>');
          htp.p('<td align="left">');
          htp.formselectOpen('p_ordtyp',cattributes=>'onChange="disableField();"');
          htp.formselectOption('',cattributes=>'Selected');
          htp.formselectOption('iRec',cattributes=>'Value="55"');
          htp.formselectOption('POS',cattributes=>'Value="POS"');
          htp.formselectOption('AOPS', cattributes=>'Value="99"');
          htp.formselectOption('Manual Refunds', cattributes=>'Value="54"');  -- Defect 5127
          htp.formselectClose;
          htp.p('</td></tr>');

       -- register number
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Register Number</font></td>');
          htp.p('<td align="left"><input type="NUMBER(10)" name="p_regnum" value = "" "size="5"></td>');
          htp.p('</tr>');

       -- transaction number
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Transaction Number</font></td>');
          htp.p('<td align="left"><input type="NUMBER(10)" name="p_trannum" value = "" "size="5"></td>');
          htp.p('</tr>');

       -- batch number
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Batch Number</font></td>');
          htp.p('<td align="left"><input type="NUMBER(10)" name="p_batchnum" value = "" "size="5"></td>');
          htp.p('</tr>');

       -- dollar amount
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Dollar Amount</font></td>');
          htp.p('<td align="left">');
          htp.formselectOpen('p_cond','');
          htp.formselectOption('=',    cattributes=>'Value="=" SELECTED');
          htp.formselectOption('>',   cattributes=>'Value=">"');
          htp.formselectOption('<', cattributes=>'Value="<"');
          htp.formselectOption('!=', cattributes=>'Value="!="');
          htp.formselectClose;
          htp.p('<input type="text" name="p_dollamt" value = "" size="13"></td>');
          htp.p('</tr>');

       -- transaction type
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Transaction Type</font></td>');
          htp.p('<td align="left">');
          htp.formselectOpen('p_trantyp','');
          htp.formselectOption('ALL',    cattributes=>'Value="A" SELECTED');
          htp.formselectOption('SALE',   cattributes=>'Value="Sale"');
          htp.formselectOption('REFUND', cattributes=>'Value="Refund"');
          htp.formselectClose;
          htp.p('</td></tr>');

       -- receipt number
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Receipt Number</font></td>');
          htp.p('<td align="left"><input type="NUMBER(10)" name="p_recptnum" value = "" "size="5"></td>');
          htp.p('</tr>');

       -- Country code      --Added for defect 8403
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Country Code</font></td>');
          htp.p('<td align="left">');
          htp.formselectOpen('p_country_code');
          htp.formselectOption('ALL',    cattributes=>'Value="A" SELECTED');

          FOR cntry_code_rec IN lcu_cntry_code
          LOOP
             EXIT WHEN lcu_cntry_code%NOTFOUND;
             htp.formselectOption(cntry_code_rec.cntry_code, cattributes=>'Value="'||cntry_code_rec.org_id||'"');
          END LOOP;
          htp.formselectClose;
          htp.p('</tr>');

       -- records per page   --Added for defect 8403
          htp.p('<tr>');
          htp.p('<td align="left" width="200"><font face="Arial" size="2">Records Displayed Per Page</font></td>');
          htp.p('<td align="left">');
          htp.formselectOpen('p_rec_count');
          htp.formselectOption('100',cattributes=>'VALUE="100"');
          htp.formselectOption('500',cattributes=>'VALUE="500"');
          htp.formselectOption('1000','SELECTED',cattributes=>'Value="1000"');
          htp.formselectOption('2000', cattributes=>'Value="2000"');
          htp.formselectOption('5000', cattributes=>'Value="5000"');
          htp.formselectOption('10000', cattributes=>'Value="10000"');
          htp.formselectClose;
          htp.p('</td></tr>');
          htp.p('<tr><td colspan=3 height="10"></td></tr>');

       -- go and cancel buttons
          htp.p('<tr>');
          htp.p('<td></td>');
          htp.p('<td>');
          htp.p('<input type="BUTTON" value="Go" onClick="compareDates();">');
          htp.p('<input type="RESET"  value="Cancel" onClick="onloadDisable();">');
          htp.p('</td>');
          htp.p('</tr>');
          htp.p('<tr><td colspan=3 height="5"></td></tr>');

          htp.p('</TABLE>');
          htp.p('</FORM>');
          htp.p('</body></html>');

       ELSE

          htp.p('<html><body><h1>You are not authorised to view this page</h1></body></html>');

       END IF;


    EXCEPTION
        WHEN OTHERS THEN
           htp.strong('Error while displaying Credit Card Settlement Report Parameters Page: '||SQLERRM);

    END XX_IBY_PARAFORM;


-- +===================================================================+
-- | Name : XX_IBY_HDRREC                                              |
-- | Description : To display all the header records from the table    |
-- |               based on the input parameters provided by the user. |
-- |                                                                   |
-- | Parameters : p_ldate,p_hdate,p_locstrnum, p_ordtyp,p_regnum,      |
-- |              p_trannum,p_batchnum,p_dollamt,p_trantyp,p_recptnum  |
-- +===================================================================+
    PROCEDURE XX_IBY_HDRREC (
                             p_ldate        IN  DATE
                            ,p_hdate        IN  DATE
                            ,p_locstrnum    IN  VARCHAR2  DEFAULT NULL
                            ,p_ordtyp       IN  VARCHAR2
                            ,p_regnum       IN  VARCHAR2  DEFAULT NULL
                            ,p_trannum      IN  VARCHAR2  DEFAULT NULL
                            ,p_batchnum     IN  VARCHAR2
                            ,p_cond         IN  VARCHAR2
                            ,p_dollamt      IN  VARCHAR2
                            ,p_trantyp      IN  VARCHAR2
                            ,p_recptnum     IN  VARCHAR2
                            ,p_rec_count    IN  VARCHAR2  DEFAULT '1000'  -- Added for defect 8403
                            ,p_cash_rec_id  IN  VARCHAR2  DEFAULT '0'     -- Added for defect 8403
                            ,p_sign         IN  VARCHAR2  DEFAULT '>'     -- Added for defect 8403
                            ,p_country_code IN  VARCHAR2                  -- Added for defect 8403
                            ,p_cnt_exec     IN  VARCHAR2  DEFAULT '1'     -- Added for defect 8403
                            ,p_tot_cnt      IN  PLS_INTEGER DEFAULT NULL  -- Added for defect 8403
                            ,p_page_num     IN  NUMBER    DEFAULT  0      -- Added for defect 8403
                            ,p_cur_page_num IN  NUMBER    DEFAULT  0      -- Added for defect 8403
                            )
    AS
    TYPE c_ref IS REF CURSOR;
    c_ref_csr_type      c_ref;


    -- Start of fix for defect 2925
    /*lc_csr_query        VARCHAR2(2000)
      := 'SELECT rowid '
            ||' ,TO_CHAR(TO_DATE(SUBSTR(ixipaymentbatchnumber, 1, INSTR(ixipaymentbatchnumber,''-'',1)-1),''YYYYMMDD''),''DD-MON-YYYY'') date_val '
            ||' ,ixstorenumber     store_num '
            ||' ,ixregisternumber  ord_type '
            ||' ,DECODE(ixregisternumber,''55'', ''&nbsp;'' '
                                    ||' ,''56'', ''&nbsp;'' '
                                    ||' ,''99'', ''&nbsp;'' '
                                    ||' , SUBSTR(ixinvoice, INSTR(ixinvoice,''/'',1,1)+1, INSTR(ixinvoice,''/'',1,2)-INSTR(ixinvoice,''/'',1,1)-1)) reg_num '
            ||' ,DECODE(ixregisternumber,''55'', ''&nbsp;'' '
                                    ||' ,''56'', ''&nbsp;'' '
                                    ||' ,''99'', ixinvoice '
                                    ||' , SUBSTR(ixinvoice, INSTR(ixinvoice,''/'',1,2)+1, LENGTH(ixinvoice)) ) trx_num '
            ||' ,SUBSTR(ixipaymentbatchnumber, INSTR(ixipaymentbatchnumber,''-'',1)+1, INSTR(ixipaymentbatchnumber,''.'',1)-INSTR(ixipaymentbatchnumber,''-'',1)-1)  batch_num '
            ||' ,ixamount/100       dollar_amt '
            ||' ,ixtransactiontype  trx_type '
            ||' ,SUBSTR(ixreceiptnumber, 1, INSTR(ixreceiptnumber,''#'',1)-1)  recpt_num '
     ||' FROM  xx_iby_batch_trxns_history ';*/

     -- end of fix for  5436

      lc_csr_query        VARCHAR2(2000)
      := 'SELECT * FROM (SELECT * FROM (SELECT ixreceiptnumber receipt_num '
            ||' ,TO_DATE(ixsettlementdate) date_val '
            ||' ,ixstorenumber     store_num '
            ||' ,DECODE(ixregisternumber,''54'',''Manual Refunds'',''55'',''iRec'',''99'',''AOPS'',''POS'')  ord_type '    -- Defect 5127
            ||' ,ixregisternumber reg_num '
            ||' ,DECODE(ixregisternumber,''54'', NVL(ixinvoice,''&nbsp;''),''55'', NVL(ixinvoice,''&nbsp;'') '        -- Defect 5127
                                    ||' ,''56'', ''&nbsp;'' '
                                    ||' ,''99'', ixinvoice '
                                    ||' ,NVL(ixtransnumber,''&nbsp;'') ) trx_num '
            ||' ,NVL(ixipaymentbatchnumber,''&nbsp;'') batch_num'
            ||' ,ixamount/100       dollar_amt '
            ||' ,ixtransactiontype  trx_type '
            ||' ,ixrecptnumber  recpt_num '           --Added for defect 8403
            ||' ,attribute7 cash_rec_id '             --Added for defect 8403
     ||' FROM  xx_iby_batch_trxns_history a ';
    lc_where_clause     VARCHAR2(5000)
    := ' WHERE ixrecordtype = 101 '
--     ||' AND  TO_NUMBER(attribute7)'|| p_sign ||' TO_NUMBER(:p_cash_rec_id)'       --Added for defect 8403   -- Commented for Defect 12161 on 6/20/2011
     ||' AND  ixsettlementdate BETWEEN :p_ldate and :p_hdate '         --Added for defect 8403
     ||' AND  ixstorenumber LIKE NVL(:p_locstrnum,ixstorenumber)'
     ||' AND  ixregisternumber = (DECODE(NVL(:p_ordtyp,ixregisternumber),''POS'',(SELECT ixregisternumber FROM xx_iby_batch_trxns_history WHERE ixregisternumber = a.ixregisternumber AND ixregisternumber NOT IN(''54'',''55'',''56'',''99'') AND ROWNUM < 2),NVL(:p_ordtyp,ixregisternumber)))'; -- Defect 5127

    lc_cnt_query        VARCHAR2(2000)
    := 'SELECT COUNT(1) '
    ||' FROM  xx_iby_batch_trxns_history a ';

    lc_cnt_where_cls    VARCHAR2(5000)
    := ' WHERE ixrecordtype = 101 '
     ||' AND  attribute7 IS NOT NULL '
     ||' AND  ixsettlementdate BETWEEN :p_ldate and :p_hdate '         --Added for defect 8403
     ||' AND  ixstorenumber LIKE NVL(:p_locstrnum,ixstorenumber)'
     ||' AND  ixregisternumber = (DECODE(NVL(:p_ordtyp,ixregisternumber),''POS'',(SELECT ixregisternumber FROM xx_iby_batch_trxns_history WHERE ixregisternumber = a.ixregisternumber AND ixregisternumber NOT IN(''54'',''55'',''56'',''99'') AND ROWNUM < 2),NVL(:p_ordtyp,ixregisternumber)))';

    -- End of fix for defect 2925


   TYPE c_rec_type IS RECORD(
        receipt_num           xx_iby_batch_trxns_history.ixreceiptnumber%TYPE
       ,date_val              DATE
       ,store_num             xx_iby_batch_trxns_history.IxStoreNumber%TYPE
       ,ord_type              xx_iby_batch_trxns_history.IxRegisterNumber%TYPE
       ,reg_num               xx_iby_batch_trxns_history.IxInvoice%TYPE
       ,trx_num               xx_iby_batch_trxns_history.IxInvoice%TYPE
       ,batch_num             xx_iby_batch_trxns_history.IxIPaymentbatchnumber%TYPE
       ,dollar_amt            xx_iby_batch_trxns_history.IxAmount%TYPE
       ,trx_type              xx_iby_batch_trxns_history.IxTransactionType%TYPE
       ,recpt_num             xx_iby_batch_trxns_history.IxReceiptNumber%TYPE
       ,cash_rec_id           xx_iby_batch_trxns_history.attribute7%TYPE           --Added for defect 8403
        );

   lc_cash_rec_id        xx_iby_batch_trxns_history.attribute7%TYPE;               --Added for defect 8403
   lr_c_rec_type         c_rec_type;
   lc_prev_cash_rec_id   xx_iby_batch_trxns_history.attribute7%TYPE;
   lc_cash_rec_set       VARCHAR2(1) DEFAULT 'N';
   lc_cnt_exec           VARCHAR2(1) DEFAULT '1';
   ln_tot_cnt            PLS_INTEGER DEFAULT 0;
   ln_page_num           NUMBER      DEFAULT 0;
   ln_cur_page_num       NUMBER      DEFAULT 0;

    BEGIN

       IF (icx_sec.ValidateSession AND VALIDATE_USER_RESP) THEN

          htp.p('<html>'
          ||'<head>'
          ||'<TITLE> Credit Card Settlement Report - Header Records </TITLE>'
          ||'<script language="javascript">'
          ||'void function submitForm(){'
          ||'document.form.submit()'
          ||'}'
          ||'</script>'
          ||'</head>'
          ||'<body>'
          ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
          ||'<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>'
          ||'<td align="right"><form name="para" action="XX_IBY_CREREP_PKG.XX_IBY_PARAFORM" method="post"><br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''"><font size=2 face="arial" Color="blue"><u>Search Page</u></font></a></form></td>'
          ||'<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td>'
          ||'<td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>'
          ||'</TABLE>'
          ||'<hr width=100% size="7" color="red" noshade="noshade">'
          ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
          ||'<tr><td width="25%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>'
          ||'<tr><td width="75%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> Credit Card Settlement Report </b></font></td></tr>'
          ||'</TABLE>'
          ||'<br>'
          ||'<FORM NAME="form" ACTION="XX_IBY_CREREP_PKG.XX_IBY_DTLREC" METHOD="post">');
          --htp.print('<div style="width: 1000px; height: 500px; overflow: auto">');
          --Fixed defect 2925
          htp.print('<div style="width: 1000px; height: 500px">');
          htp.p ('<table align="left" border="1" bgcolor="#FAF0E6" cellpadding=2 cellspacing=2 >'
             ||'<tr align="center" valign="center" bgcolor="#FFEBCD" >'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Date </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Store Number </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Order Type </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Register Number </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Transaction Number </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Batch Number </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Dollar amount </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Transaction Type </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> Receipt Number </font></th>'
             ||'   <th><font face="Arial" color="#7F525D" size="2"> More Info </font></th>'
             ||'</tr>');

        --Building the Where clause
          lc_error_loc := 'Building the Where clause for the query, based on input values';

          IF (p_regnum   IS NOT NULL) THEN
             --lc_where_clause := lc_where_clause||' AND SUBSTR(ixinvoice, INSTR(ixinvoice,''#'',1,1)+2, INSTR(ixinvoice,''#'',1,2)-INSTR(ixinvoice,''#'',1,1)-2) = :p_regnum';

             --Fixed defect 2925
             --lc_where_clause := lc_where_clause||' AND NVL(SUBSTR(ixinvoice, INSTR(ixinvoice,''/'',1,3)+1, INSTR(ixinvoice,''/'',1,4)-INSTR(ixinvoice,''/'',1,3)-1),ixinvoice) LIKE :p_regnum';

             --Fixed defect 3832
             lc_where_clause := lc_where_clause||' AND ixregisternumber LIKE :p_regnum';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ixregisternumber LIKE :p_regnum';
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = NVL(:p_regnum,''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = NVL(:p_regnum,''1'')';
          END IF;

          IF (p_trannum  IS NOT NULL) THEN
             IF (p_ordtyp = 'POS') THEN
                --lc_where_clause := lc_where_clause||' AND SUBSTR(ixinvoice, INSTR(ixinvoice,''#'',1,2)+2, INSTR(ixinvoice,''#'',1,3)-INSTR(ixinvoice,''#'',1,2)-2) = :p_trannum';

                --Fixed defect 2925
                lc_where_clause := lc_where_clause||' AND ixtransnumber LIKE :p_trannum';

                lc_cnt_where_cls := lc_cnt_where_cls||' AND ixtransnumber LIKE :p_trannum';

             --ELSIF (p_ordtyp = 'Ecom-99') THEN

             --Fixed defect 2925
             ELSIF (p_ordtyp = '99') THEN
                lc_where_clause := lc_where_clause||' AND ixinvoice LIKE :p_trannum';
                lc_cnt_where_cls := lc_cnt_where_cls||' AND ixinvoice LIKE :p_trannum';
             ELSE
                lc_where_clause := lc_where_clause||' AND ixinvoice LIKE :p_trannum';
                lc_cnt_where_cls := lc_cnt_where_cls||' AND ixinvoice LIKE :p_trannum';
             END IF;
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = NVL(:p_trannum,''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = NVL(:p_trannum,''1'')';
          END IF;

          IF (p_batchnum IS NOT NULL) THEN
             --lc_where_clause := lc_where_clause||' AND SUBSTR(ixipaymentbatchnumber, INSTR(ixipaymentbatchnumber,''-'',1)+1, INSTR(ixipaymentbatchnumber,''.'',1)-INSTR(ixipaymentbatchnumber,''-'',1)-1) =  :p_batchnum ';

             --Fixed defect 2925
             --lc_where_clause := lc_where_clause||' AND NVL(SUBSTR(ixipaymentbatchnumber, INSTR(ixipaymentbatchnumber,''-'',1)+1, INSTR(ixipaymentbatchnumber,''.'',1)-INSTR(ixipaymentbatchnumber,''-'',1)-1),SUBSTR(ixipaymentbatchnumber, INSTR(ixipaymentbatchnumber,''-'',1)+1)) LIKE  :p_batchnum ';
             lc_where_clause := lc_where_clause||' AND ixipaymentbatchnumber LIKE :p_batchnum ';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ixipaymentbatchnumber LIKE :p_batchnum ';
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = NVL(:p_batchnum,''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = NVL(:p_batchnum,''1'')';
          END IF;

          IF (p_dollamt  IS NOT NULL AND p_cond IS NOT NULL) THEN
             lc_where_clause := lc_where_clause||' AND ixamount '||p_cond||' :p_dollamt * 100';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ixamount '||p_cond||' :p_dollamt * 100';
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' '||p_cond||' NVL(:p_dollamt, ''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' '||p_cond||' NVL(:p_dollamt, ''1'')';
          END IF;

          IF (p_trantyp  IS NOT NULL) THEN
             IF (p_trantyp <> 'A') THEN
             lc_where_clause := lc_where_clause||' AND ixtransactiontype LIKE :p_trantyp';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ixtransactiontype LIKE :p_trantyp';
             ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = DECODE(:p_trantyp, ''A'', ''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = DECODE(:p_trantyp, ''A'', ''1'')';
             END IF;
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = NVL(:p_trantyp, ''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = DECODE(:p_trantyp, ''A'', ''1'')';
          END IF;

          IF (p_recptnum IS NOT NULL) THEN
             lc_where_clause := lc_where_clause||' AND ixrecptnumber LIKE :p_recptnum';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ixrecptnumber LIKE :p_recptnum';
          ELSE
             lc_where_clause := lc_where_clause||' AND ''1'' = NVL(:p_recptnum,''1'')';
             lc_cnt_where_cls := lc_cnt_where_cls||' AND ''1'' = NVL(:p_recptnum,''1'')';
          END IF;

          IF (p_country_code <> 'A') THEN
             lc_where_clause := lc_where_clause||' AND org_id = '||p_country_code;
             lc_cnt_where_cls := lc_cnt_where_cls||' AND org_id = '||p_country_code;
          END IF;

          IF (p_sign = '>') THEN
             lc_where_clause := lc_where_clause||' ORDER BY TO_NUMBER(attribute7)) WHERE ROWNUM <= '||p_rec_count||') ORDER BY TO_NUMBER(cash_rec_id)';          --Modified for defect 8403
          ELSE
             lc_where_clause := lc_where_clause||' ORDER BY TO_NUMBER(attribute7) DESC) WHERE ROWNUM <= '||p_rec_count||') ORDER BY TO_NUMBER(cash_rec_id)';          --Modified for defect 8403
          END IF;

          -- Opening the cursor for pulling out records from the table
          lc_error_loc := 'Opening the Cursor to display records';

          ln_cur_page_num := p_cur_page_num;
          ln_page_num     := p_page_num;
          ln_tot_cnt      := p_tot_cnt;

          IF (p_cnt_exec = '1') THEN
             OPEN c_ref_csr_type FOR lc_cnt_query||' '||lc_cnt_where_cls
             USING p_ldate, p_hdate,p_locstrnum,p_ordtyp,p_ordtyp,p_regnum,p_trannum,p_batchnum,p_dollamt,p_trantyp,p_recptnum;

             LOOP
                FETCH c_ref_csr_type INTO ln_tot_cnt;
                EXIT WHEN c_ref_csr_type%NOTFOUND;
             END LOOP;

             CLOSE c_ref_csr_type;
             ln_page_num     := CEIL(ln_tot_cnt/p_rec_count);
          END IF;
             lc_cnt_exec := lc_cnt_exec + 1;

          OPEN c_ref_csr_type FOR lc_csr_query ||' '||lc_where_clause
--          USING p_cash_rec_id,p_ldate, p_hdate,p_locstrnum,p_ordtyp,p_ordtyp,p_regnum,p_trannum,p_batchnum,p_dollamt,p_trantyp,p_recptnum;  -- Remove P_CASH_REC_ID for defect 12161 on 6/20/2011
          USING p_ldate, p_hdate,p_locstrnum,p_ordtyp,p_ordtyp,p_regnum,p_trannum,p_batchnum,p_dollamt,p_trantyp,p_recptnum;

          LOOP

             lc_error_loc := 'Fetching the Cursor to display records';

             FETCH c_ref_csr_type INTO lr_c_rec_type;
             EXIT WHEN c_ref_csr_type%NOTFOUND;

                IF (lc_cash_rec_set = 'N') THEN
                   lc_prev_cash_rec_id := lr_c_rec_type.cash_rec_id;
                   lc_cash_rec_set := 'Y';
                END IF;
                lc_error_loc := 'Fetching the Cursor to display records';

                htp.p(
                      '<tr><td align=left nowrap><font  size="2">'|| lr_c_rec_type.date_val|| '</font></td>'
                      ||'<td align=right><font  size="2">'|| lr_c_rec_type.store_num|| '</font></td>'
                      ||'<td align=right><font  size="2">'|| lr_c_rec_type.ord_type|| '</font></td>'
                      ||'<td align=right> <font  size="2">'|| lr_c_rec_type.reg_num|| '</font></td>'
                      ||'<td align=right> <font  size="2">'|| lr_c_rec_type.trx_num|| '</font></td>'
                      ||'<td align=right><font  size="2">'|| lr_c_rec_type.batch_num|| '</font></td>'
                      ||'<td align=right><font  size="2">'|| lr_c_rec_type.dollar_amt|| '</font></td>'
                      ||'<td align=right><font  size="2">'|| lr_c_rec_type.trx_type|| '</font></td>'
                      ||'<td align=right ><font  size="2">'|| lr_c_rec_type.recpt_num|| '</font></td>'
                      ||'<td align=right>
                         <form name = "form" action="XX_IBY_CREREP_PKG.XX_IBY_DTLREC" method="post"><input type="hidden" name="p_receipt_num" value="'||lr_c_rec_type.receipt_num||'"><input type="hidden" name="p_batch_num" value="'||lr_c_rec_type.batch_num||'">
                         <u><font  size="2" color ="blue"><a onclick="submit()" onmouseover="this.style.cursor=''pointer''">More info</a></font><u>
                         </form></td></tr>'
                     );

                lc_cash_rec_id := lr_c_rec_type.cash_rec_id;

          END LOOP;
          --lc_prev_cash_rec_id := p_cash_rec_id;
         -- fix for defect 5436 No date found handler
         htp.p('</table><br><br><br><br><br>');
          IF  (c_ref_csr_type%NOTFOUND) and   (c_ref_csr_type%ROWCOUNT=0) then
             htp.p('<font face="Arial" color="#7F525D" size="5">No Data Found</font>');

            IF ( p_sign = gc_sign OR p_sign = '<=' ) THEN
               lc_cash_rec_id := '0';
            ELSE
               lc_prev_cash_rec_id := p_cash_rec_id;
               gc_sign := '<=';
            END IF;
          END IF;
          CLOSE c_ref_csr_type;

         IF (p_sign = '>') THEN
            ln_cur_page_num := ln_cur_page_num + 1;
         ELSE
            ln_cur_page_num := ln_cur_page_num - 1 ;
         END IF;

          htp.print('</div>');
          htp.p('</FORM>');
          htp.p('<br> <font face="Trebuchet MS" color="black" size="2.5"> <STRONG> Total Number of Records for the given Search Criteria : '||ln_tot_cnt||'</STRONG> </font>');
          htp.p('<br> <font face="Trebuchet MS" color="black" size="2.5"> <STRONG> Page Number : '||ln_cur_page_num||' Of '||ln_page_num||'</STRONG></font>');
          htp.p('<p>');

          htp.p('<table border="0" cellspacing="0" cellpadding="0" width="50%" align="right">');

          IF ( ln_cur_page_num > 1 ) THEN
          htp.p('<td align="right"><form name="form" action="XX_IBY_CREREP_PKG.XX_IBY_HDRREC" method="post">
                 <input type="hidden" name="p_ldate" value="'||p_ldate||'"><input type="hidden" name="p_hdate" value="'||p_hdate||'">
                 <input type="hidden" name="p_locstrnum" value="'||p_locstrnum||'"><input type="hidden" name="p_ordtyp" value="'||p_ordtyp||'">
                 <input type="hidden" name="p_regnum" value="'||p_regnum||'"><input type="hidden" name="p_trannum" value="'||p_trannum||'">
                 <input type="hidden" name="p_batchnum" value="'||p_batchnum||'"><input type="hidden" name="p_cond" value="'||p_cond||'"><input type="hidden" name="p_page_num" value="'||ln_page_num||'">
                 <input type="hidden" name="p_dollamt" value="'||p_dollamt||'"><input type="hidden" name="p_trantyp" value="'||p_trantyp||'"><input type="hidden" name="p_cur_page_num" value="'||ln_cur_page_num||'">
                 <input type="hidden" name="p_tot_cnt" value="'||ln_tot_cnt||'">
                 <input type="hidden" name="p_recptnum" value="'||p_recptnum||'"><input type="hidden" name="p_rec_count" value="'||p_rec_count||'"><input type="hidden" name="p_cnt_exec" value="'||lc_cnt_exec||'">
                 <input type="hidden" name="p_cash_rec_id" value="'||lc_prev_cash_rec_id||'"><input type="hidden" name="p_sign" value="'||gc_sign||'"><input type="hidden" name="p_country_code" value="'||p_country_code||'">
                 <br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''"><font size=2 face="arial" Color="blue"><u>Previous Records</u><font></a></form></body></html></td>');
          END IF;

          IF ( ln_cur_page_num = ln_page_num ) THEN
            NULL;
          ELSE
          htp.p('<td align="right"><form name="form" action="XX_IBY_CREREP_PKG.XX_IBY_HDRREC" method="post">
                 <input type="hidden" name="p_ldate" value="'||p_ldate||'"><input type="hidden" name="p_hdate" value="'||p_hdate||'">
                 <input type="hidden" name="p_locstrnum" value="'||p_locstrnum||'"><input type="hidden" name="p_ordtyp" value="'||p_ordtyp||'">
                 <input type="hidden" name="p_regnum" value="'||p_regnum||'"><input type="hidden" name="p_trannum" value="'||p_trannum||'">
                 <input type="hidden" name="p_batchnum" value="'||p_batchnum||'"><input type="hidden" name="p_cond" value="'||p_cond||'"><input type="hidden" name="p_page_num" value="'||ln_page_num||'">
                 <input type="hidden" name="p_dollamt" value="'||p_dollamt||'"><input type="hidden" name="p_trantyp" value="'||p_trantyp||'"><input type="hidden" name="p_cur_page_num" value="'||ln_cur_page_num||'">
                 <input type="hidden" name="p_tot_cnt" value="'||ln_tot_cnt||'">
                 <input type="hidden" name="p_recptnum" value="'||p_recptnum||'"><input type="hidden" name="p_rec_count" value="'||p_rec_count||'"><input type="hidden" name="p_cnt_exec" value="'||lc_cnt_exec||'">
                 <input type="hidden" name="p_cash_rec_id" value="'||lc_cash_rec_id||'"><input type="hidden" name="p_country_code" value="'||p_country_code||'"><br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''">
                 <font size=2 face="arial" Color="blue"><u>Next Records</u><font></a></form></body></html></td>');
          END IF;

          htp.p('<td align="right"><form name="para" action="XX_IBY_CREREP_PKG.XX_IBY_PARAFORM" method="post"><br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''"><font size=2 face="arial" Color="blue"><u>Search Page</u><font></a></form></td>
                 <td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td>');
          htp.p('<td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr></table>');

       ELSE

          htp.p('<html><body><h1>You are not authorised to view this page</h1></body></html>');

       END IF;

    EXCEPTION
        WHEN OTHERS THEN
           htp.p('Error Loc: '||lc_error_loc);
           htp.p('<br>');
           htp.strong('Error while displaying the records in the bottom frame:  '||SQLERRM);

    END XX_IBY_HDRREC;


-- +===================================================================+
-- | Name : XX_IBY_LABLNAME                                            |
-- | Description : To fetch the corresponding column label names for   |
-- |               all the column names to display it in the required  |
-- |               format in the bottom frame.                         |
-- | Parameters :  p_colname, x_lablname                               |
-- +===================================================================+
    PROCEDURE XX_IBY_LABLNAME(p_colname   IN  VARCHAR2
                             ,x_lablname  OUT NOCOPY VARCHAR2
                              )
    AS
    lc_lablname   VARCHAR2(100);

    BEGIN

       SELECT target_field1
       INTO   lc_lablname
       FROM   xx_fin_translatedefinition
       WHERE  translation_name = 'IBY_CREDIT_REPORT'
       AND    LOWER(source_field1) = p_colname ;

       x_lablname := lc_lablname;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
           x_lablname := p_colname;

    END XX_IBY_LABLNAME;


-- +===================================================================+
-- | Name : XX_IBY_DTLREC                                              |
-- | Description : To facilitate the user to see more detail records   |
-- |               on clicking the "More Info" Link on specific        |
-- |               record. It will display the records in a new page.  |
-- | Parameters :  p_receipt_num , p_batch_num                         |
-- +===================================================================+

--Fixed defect 5436
     PROCEDURE XX_IBY_DTLREC(p_receipt_num        IN  VARCHAR2
                            ,p_batch_num          IN  VARCHAR2
                          )
    AS
    lc_lablname            VARCHAR2(100);
    lc_value               VARCHAR2(25)  := NULL;
    lc_instrmask           VARCHAR2(1);
    lc_amtmask             VARCHAR2(1);
    lc_cc_segment_ref      VARCHAR2(200)  DEFAULT NULL;
    lc_cc_number           VARCHAR2(100)  DEFAULT NULL;
    lc_ordtype             VARCHAR2(100);
    lc_field1              VARCHAR2(100)  DEFAULT '';
    lc_field2              VARCHAR2(100) := 'ixamount';
    lc_field3              VARCHAR2(100)  DEFAULT '';
    lc_amt                 VARCHAR2(50);
    lc_exp_date            VARCHAR2(50);
    lc_ixswipe             xx_iby_batch_trxns_history.ixswipe%TYPE; --Added for the Defect 1111 on May 10,2010


   --Added for the defect 4587
    lc_key_label                    xx_iby_batch_trxns.attribute8%TYPE :=NULL;
  -- fix for defect 5436
    /*  lc_rowid               VARCHAR2(50);*/

    --Fixed defect 3832
    x_decrypted_val        VARCHAR2(1000);
    x_error_message        VARCHAR2(1000);

    CURSOR c_colname
    IS
    SELECT column_name
    FROM   dba_tab_columns
    WHERE  table_name='XX_IBY_BATCH_TRXNS_HISTORY'
    AND    UPPER(column_name) NOT IN ('IXBATCHNAME','PRE1','PRE2','PRE3','IXMERCHANTNUMBER'
                                      ,'IXINSTRSUBTYPE','LAST_UPDATED_BY','CREATED_BY'
                                      ,'LAST_UPDATE_LOGIN','IXCCNUMBER')
    ORDER BY column_id;

    TYPE c_ref IS REF CURSOR;
    csr_dtl_rec            c_ref;

    lc_val_qry             VARCHAR2(1000);
    lc_colvalue            VARCHAR2(100);

    BEGIN

     /*
       SELECT REPLACE(p_rowid, '~!@' ,'+')  -- changed for defect#5436
                INTO lc_rowid
                FROM dual;*/

       IF (icx_sec.ValidateSession AND VALIDATE_USER_RESP) THEN

          gn_user_id      := FND_PROFILE.VALUE('USER_ID');
          gn_resp_id      := FND_PROFILE.VALUE('RESP_ID');
          gn_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');

          FND_GLOBAL.APPS_INITIALIZE(gn_user_id
                                    ,gn_resp_id
                                    ,gn_resp_appl_id
                                    );

          lc_value := FND_PROFILE.VALUE('IBY_VISIBILITY_CLASS');

          lc_error_loc := 'Checking the Visibility Class id and the mask values';

          BEGIN

          SELECT instr_number_mask ,amount_mask
          INTO   lc_instrmask, lc_amtmask
          FROM   iby_visibility_classes
          WHERE  NVL(end_date_active, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
          AND    start_date_active  <= TRUNC(SYSDATE)
          AND    visibility_class_id = lc_value;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
               lc_instrmask := 'N';
               lc_amtmask   := 'Y';

          END;

          lc_error_loc := 'Fetching the cc no. holding field, ordtype and ixamount from table';

          -- Modified the decode in below SQL to show POS key trxns for #1111 by RK on 06-May-2010
          -- For version 1.8

          SELECT DECODE(ixregisternumber,'54',ixaccount,'55',ixaccount,'56',ixaccount,'99',ixaccount                 -- Defect 5127
                                        ,nvl(substr(ixswipe,1,instr(ixswipe,'=',-1)-1), ixaccount))
                ,ixregisternumber
                ,ixamount
                ,attribute8
                ,ixswipe                  --Added for the Defect 1111 on May 10,2010
          INTO   lc_cc_segment_ref
                ,lc_ordtype
                ,lc_amt
                ,lc_key_label
                ,lc_ixswipe               --Added for the Defect 1111 on May 10,2010
          FROM   xx_iby_batch_trxns_history
         -- defect  5436
         -- WHERE  rowid = lc_rowid;
         WHERE ixreceiptnumber=p_receipt_num
         AND IxIPaymentbatchnumber=p_batch_num ;

          --Fixed defect 2925

         -- lc_cc_number := lc_cc_segment_ref;

          /*lc_cc_number := XX_IBY_SECURITY_PKG.decrypt_credit_card(
                                                                  p_cc_segment_ref => lc_cc_segment_ref
                                                                 );*/

          --Fixed defect 3832

          lc_error_loc := 'Getting the credit card number using the OD Security API';


          XX_OD_SECURITY_KEY_PKG.DECRYPT(
                                         p_module         => 'AJB'
                                        --,p_key_label      => NULL       --Commented for defect 4587
                                        ,p_key_label      => lc_key_label --Added for the defect 4587
                                        ,p_algorithm      => '3DES'
                                        ,p_encrypted_val  => lc_cc_segment_ref
                                        ,p_format         => 'BASE64'
                                        ,x_decrypted_val  => lc_cc_number
                                        ,x_error_message  => x_error_message
                                        );

          lc_error_loc := 'Masking logic for credit card number';

          IF   ( lc_instrmask = 'A' ) THEN
             lc_cc_number := lc_cc_number;
          ELSIF ( lc_instrmask = 'N' ) THEN
             lc_cc_number := TRANSLATE(lc_cc_number,'1234567890','**********');
          ELSIF ( lc_instrmask = 'F' ) THEN
             lc_cc_number := RPAD(SUBSTR(lc_cc_number,1,4),16,'*');
          ELSIF ( lc_instrmask = 'L' ) THEN
             lc_cc_number := LPAD(SUBSTR(lc_cc_number,-4),16,'*');
          END IF;



          lc_error_loc := 'Deciding the cc no holding field ';

/*          IF ( lc_ordtype = 'POS' ) THEN
             lc_field1 := 'ixswipe';

             SELECT DECODE(ixregisternumber,'55',ixaccount,'56',ixaccount,'99',ixaccount
                                        ,substr(ixswipe,-4))
             INTO lc_exp_date
             FROM XX_IBY_BATCH_TRXNS_HISTORY;

          ELSE
             lc_field1 := 'ixaccount';
          END IF;*/


          --Expiry date for POS orders being taken from ixswipe

/*Added for the Defect 1111 on May 10,2010 Starts Here */
          IF ( lc_ordtype = '54' or lc_ordtype = '55' or lc_ordtype = '56' or lc_ordtype = '99' ) THEN         --Defect 5127
               lc_field1 := 'ixaccount';

          ELSIF (lc_ixswipe IS NULL) THEN
                 lc_field1 := 'ixaccount';
                 lc_field3 := 'ixexpdate';

	      SELECT DECODE(ixregisternumber,'54',ixaccount,'55',ixaccount,'56',ixaccount,'99',ixaccount        --Defect 5127
                           ,ixexpdate)
              INTO lc_exp_date
              FROM XX_IBY_BATCH_TRXNS_HISTORY
              -- defect  5436
              -- WHERE  rowid = lc_rowid;
              WHERE ixreceiptnumber=p_receipt_num
              AND IxIPaymentbatchnumber=p_batch_num ;

	  ELSIF (lc_ixswipe IS NOT NULL) THEN
                 lc_field1 := 'ixswipe';
                 lc_field3 := 'ixexpdate';

	      SELECT DECODE(ixregisternumber,'54',ixaccount,'55',ixaccount,'56',ixaccount,'99',ixaccount        --Defect 5127
                           ,substr(lc_ixswipe,-4))
              INTO lc_exp_date
              FROM XX_IBY_BATCH_TRXNS_HISTORY
              -- defect  5436
              -- WHERE  rowid = lc_rowid;
              WHERE ixreceiptnumber=p_receipt_num
              AND IxIPaymentbatchnumber=p_batch_num ;

	  END IF;
/*Added for the Defect 1111 on May 10,2010 Ends Here*/

           lc_error_loc := 'Masking logic for the amount field';

          IF ( lc_amtmask <> 'N' ) THEN
             lc_amt := TRANSLATE(lc_amt,'1234567890','**********');
          ELSE
             lc_amt := lc_amt;
          END IF;

          htp.p('<html>');
          htp.p('<head>');
          htp.p('<TITLE> Credit Card Settlement Report - Detail records </TITLE>');
          htp.p('<script language="javascript">');
          htp.p('void function sub(){');
          htp.p('document.frm.submit();');
          htp.p('}');
          htp.p('</script>');
          htp.p('</head>');

          htp.p('<body>');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>');
          htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:history.go(-1)">Previous</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('<hr width=100% size="7" color="red" noshade="noshade">');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="20%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>');
          htp.p('<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> Credit Card Settlement Report </b></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('<br>');

          htp.p('<FORM NAME="frm" ACTION="XX_IBY_CREREP_PKG.XX_IBY_CHDREC" METHOD="post">');
          htp.p('<table border="0" cellspacing="0" cellpadding="0" width="90%" align="center">');
        --  htp.p('<input type="hidden" name="p_rowid" value="'|| p_rowid || '">');
        -- dedefect 5346
        htp.p('<input type="hidden" name="p_receipt_num" value="'|| p_receipt_num || '">');
        htp.p('<input type="hidden" name="p_batch_num" value="'|| p_batch_num || '">');
        htp.p('<tr><td align="left"><font face="Arial" size="2"><a href="javascript:sub()"><b> 201 Record Info>> </b></a></font></td></tr>' );
          htp.p('</table>');
          htp.p('</FORM>');
          htp.p('<br>');

          lc_error_loc := 'Calling XX_IBY_LABLNAME to get the label name for all the columns';

          htp.p('<table border="0" cellspacing="0" cellpadding="0" width="90%" align="center">');

          FOR lcu_c_colname IN c_colname
          LOOP
             XX_IBY_LABLNAME(LOWER(lcu_c_colname.column_name)
                            ,lc_lablname
                             );

             htp.p('<tr>');
             htp.p('<td align=left width="6%"><font face="Arial" size="2">'||LOWER(lc_lablname)||'</font></td>');
             htp.p('<td align=center width="7%"> : </td>');

             IF ( LOWER(lcu_c_colname.column_name) <> lc_field1
                 AND LOWER(lcu_c_colname.column_name) <> lc_field2 ) THEN

                lc_error_loc := 'Getting the values for the columns from the table';

                --   defect 5436

             /*   lc_val_qry := 'SELECT '||lcu_c_colname.column_name
                           ||' FROM xx_iby_batch_trxns_history'
                           ||' WHERE rowid = :p_rowid';
               */


               lc_val_qry := 'SELECT '||lcu_c_colname.column_name
                           ||' FROM xx_iby_batch_trxns_history'
                           ||' WHERE ixreceiptnumber=:p_receipt_num'
                           ||' AND ixipaymentbatchnumber=:p_batch_num';


                OPEN csr_dtl_rec FOR lc_val_qry
                USING p_receipt_num,p_batch_num;

                LOOP

                   FETCH csr_dtl_rec INTO lc_colvalue;
                   EXIT WHEN csr_dtl_rec%NOTFOUND;

                   IF((lc_ordtype <> '54' OR lc_ordtype <> '55' OR lc_ordtype <> '56' OR lc_ordtype <> '99')  --Added to display correct ixexpdate for POS orders.   --Defect 5127
                       AND LOWER(lcu_c_colname.column_name) = lc_field3) THEN
                     htp.p('<td><font face="Arial" size="2">'||lc_exp_date||'</font></td></tr>');
                   ELSE
                     htp.p('<td><font face="Arial" size="2">'||lc_colvalue||'</font></td></tr>');
                   END IF;

                END LOOP;
                CLOSE csr_dtl_rec;

             ELSIF ( LOWER(lcu_c_colname.column_name) = lc_field1 ) THEN
                lc_colvalue := lc_cc_number;
                htp.p('<td><font face="Arial" size="2">'||lc_colvalue||'</font></td></tr>');

             ELSIF ( LOWER(lcu_c_colname.column_name) = lc_field2 ) THEN
                lc_colvalue := lc_amt;
                htp.p('<td><font face="Arial" size="2">'||lc_colvalue||'</font></td></tr>');

             END IF;

          END LOOP;

          htp.p('</table>');
          htp.p('<table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">');
          htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:history.go(-1)">Previous</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
          htp.p('</table>');

          htp.p('</body></html>');

       ELSE

          htp.p('<html><body><h1>You are not authorised to view this page</h1></body></html>');

       END IF;

    EXCEPTION
       WHEN OTHERS THEN
           htp.p('Error Loc: '||lc_error_loc);
           htp.p('<br>');
           htp.p('Error: '||SQLERRM ||' '||x_error_message);

    END XX_IBY_DTLREC;


-- +===================================================================+
-- | Name : XX_IBY_CHDREC                                              |
-- | Description : To facilitate the user to see more detail records   |
-- |               on clicking the "More Info" Link on specific        |
-- |               record. It will display the records in a new page.  |
-- | Parameters :  p_reciept_num                                       |
-- |               p_batch_num                                         |
-- +===================================================================+
--   defect 5436
   /* PROCEDURE XX_IBY_CHDREC(p_rowid   IN  VARCHAR2
                            )*/
     PROCEDURE XX_IBY_CHDREC(p_receipt_num   IN  VARCHAR2
                             ,p_batch_num          IN  VARCHAR2
                            )
    AS
    CURSOR c_child_rec
    IS
    SELECT IBY2.*
    FROM   xx_iby_batch_trxns_201_history  IBY2
          ,xx_iby_batch_trxns_history      IBY1
    WHERE
    --IBY2.ixstorenumber     = IBY1.ixstorenumber       -- defect 5436
    --AND    IBY2.ixtransactiontype = IBY1.ixtransactiontype
    --Fixed defect 2925
          IBY2.ixreceiptnumber = IBY1.ixreceiptnumber
    AND   IBY2.ixipaymentbatchnumber= IBY1.ixipaymentbatchnumber
   -- AND    IBY2.ixinvoice = IBY1.ixinvoice      -- defect 5436
-- defect 5436
    /*AND    IBY1.rowid = REPLACE(p_rowid,'~!@','+') --changed for defect#5436*/
    AND    IBY2.ixreceiptnumber = p_receipt_num
    AND    IBY2.ixipaymentbatchnumber= p_batch_num
    ORDER BY TO_NUMBER(Ixinvoicelinenum) ASC;


    BEGIN

       IF (icx_sec.ValidateSession AND VALIDATE_USER_RESP) THEN

       htp.p('<html>');

       htp.p('<head>');
       htp.p('<TITLE> Credit Card Settlement Report - Child records </TITLE>');
       htp.p('</head>');

       htp.p('<body>');
       htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
       htp.p('<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>');
       htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:history.go(-1)">Previous</a></fomt></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
       htp.p('</TABLE>');
       htp.p('<hr width=100% size="7" color="red" noshade="noshade">');
       htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
       htp.p('<tr><td width="20%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>');
       htp.p('<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> Credit Card Settlement Report </b></font></td></tr>');
       htp.p('</TABLE>');
       htp.p('<br>');

       htp.print('<div style="width: 900px; height: 125px">');
       htp.p ('<table align="left"  border=1  bgcolor="#FAF0E6"  cellpadding=2  cellspacing=2  style="" >');

       htp.p ('<tr align=center valign=center bgcolor= "#FFEBCD" >');
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxTransactionType </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxProductcode </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxSKUNumber </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxItemDescription  </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxItemQuantity </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitCost </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitMeasure </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitVATAmount  </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitVATRate  </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitDiscount </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxUnitDepartmentCode </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxInvoiceLineNum </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxCustPOLineNum </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxCustItemNum </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxCustItemDesc </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxCustUnitPrice </font></th>'
          );
       htp.p
          ('   <th><font face="Arial" color="#7F525D" size="2"> IxCustUOM </font></th>'
          );
       htp.p ('</tr>');

       lc_error_loc := 'Opening the cursor loop';

       FOR lcu_c_child_rec IN c_child_rec
       LOOP
            htp.p (   '<tr><td align=left><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.ixtransactiontype,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=left><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxProductcode,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxSKUNumber,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxItemDescription,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxItemQuantity,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(TO_NUMBER(lcu_c_child_rec.IxUnitCost)/100,0)
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxUnitMeasure,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxUnitVATAmount,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxUnitVATRate,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxUnitDiscount,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxUnitDepartmentCode,'&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxInvoiceLineNum, '&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxCustPOLineNum, '&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxCustItemNum, '&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxCustItemDesc, '&nbsp;')
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(TO_NUMBER(lcu_c_child_rec.IxCustUnitPrice)/100,0)
                   || '</font></td>'
                  );
            htp.p (   '<td align=right><font face="Arial" size="2">'
                   || NVL(lcu_c_child_rec.IxCustUOM, '&nbsp;')
                   || '</font></td>'
                  );
            htp.p ('</tr>');

       END LOOP;

       htp.p('</table>');
       htp.print('</div>');

       htp.p('<table width="100%" align="center">');
       htp.p('<tr><td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:history.go(-1)">Previous</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
       htp.p('</table>');

       htp.p('</body></html>');

      ELSE

       htp.p('<html><body><h1>You are not authorised to view this page</h1></body></html>');

      END IF;

    EXCEPTION
       WHEN OTHERS THEN
           htp.p('Error: '||SQLERRM);
           htp.p('<br>');
           htp.p('Error Loc: '||lc_error_loc);

    END XX_IBY_CHDREC;

END XX_IBY_CREREP_PKG;
/
SHOW ERROR
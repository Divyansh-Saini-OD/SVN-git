
function setDropDownValue(elemName, inVal){
var dl = document.getElementById(elemName);
var el =0;
for (var i=0; i<dl.options.length; i++){
   if (dl.options[i].value.substring(0,inVal.length) == inVal){ 
    el=i;
    break;
  }
}
dl.selectedIndex = el;
}

function init() {

var payccmsg;
var sMsg;
if ( (document.getElementById('XXOD_PAYCC_MSGS') != 'undefined')  && (document.getElementById('XXOD_PAYCC_MSGS') != null) ) {
  sMsg=document.getElementById('XXOD_PAYCC_MSGS').value;
}
payccmsg = $.xml2json(sMsg);


$("#submitId").click(function(e){
});

if (document.getElementById("NewCCMessageCompLayout")!=null){
document.getElementById("NewCCMessageCompLayout").style.display = "none";
}


document.getElementById("NewCreditCardNumber").style.display = "none";
document.getElementById("NewCreditCardExpMonth").style.display = "none";
document.getElementById("NewCreditCardExpYear").style.display = "none";
document.getElementById("NewCreditCardHolderName").style.display = "none";
document.getElementById('submitdiv').style.display = 'block';
document.getElementById("XXODStatus").style.display = "none";
document.getElementById("paypageRegistrationId").style.display = "none";
document.getElementById("XXOD_PAYCC_MSGS").style.display = "none";

var startTime;
var payframeClientCallback = function(response) {
if (response.timeout) {
var elapsedTime = new Date().getTime() - startTime;
document.getElementById('timeoutMessage').value = 'Timed out after ' + elapsedTime + 'ms';// handle timeout
var timeoutmsg=document.getElementById('timeoutMessage').value;

document.getElementById("submitId").style.display = "none";
document.getElementById("vantiv-payframe").style.display = "none";
document.getElementById('a_x200').style.display = 'block';
$('.alerterror').text(timeoutmsg);
}
else {
document.getElementById('response$code').value = response.response;
document.getElementById('response$message').value = response.message;
document.getElementById('response$responseTime').value =response.responseTime;
document.getElementById('response$reportGroup').value =response.reportGroup;
document.getElementById('response$merchantTxnId').value = response.id;
document.getElementById('response$orderId').value = response.orderId;
document.getElementById('response$litleTxnId').value =response.litleTxnId;
document.getElementById('response$type').value = response.type;
document.getElementById('response$lastFour').value = response.lastFour;
document.getElementById('response$firstSix').value = response.firstSix;
document.getElementById('paypageRegistrationId').value =response.paypageRegistrationId;
document.getElementById('bin').value = response.bin;
document.getElementById('response$expMonth').value = response.expMonth;
document.getElementById('response$expYear').value = response.expYear;


document.getElementById("NewCreditCardHolderName").value = document.getElementById("ODCardHolder").value;

document.getElementById('NewCreditCardNumber').value = response.paypageRegistrationId;
//document.getElementById('NewCreditCardExpMonth').value = response.expMonth;
//document.getElementById('NewCreditCardExpYear').value = response.expYear;
if(typeof response.expMonth != 'undefined' && response.expMonth != null && response.expMonth != '') {
    setDropDownValue('NewCreditCardExpMonth', response.expMonth);
}
if(typeof response.expYear != 'undefined' && response.expYear != null && response.expYear != '') {
    setDropDownValue('NewCreditCardExpYear', "20"+response.expYear);
}
document.getElementById('XXODStatus').value = response.response;
document.getElementById('a_x100').style.display = 'none';
document.getElementById('a_x200').style.display = 'none';

var message = response.message; 
if (response.response === '870') {

 var message = payccmsg.e870;

 document.getElementById('a_x100').style.display = 'block';

 $('.alertsuccess').text(message);

  $("#submitId").attr("disabled","disabled");



} 
else if (response.response === '871') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e871);


} 
else if (response.response === '872') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e872);


} 
else if (response.response === '873') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e873);


} 
else if (response.response === '874') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e874);


} 
else if (response.response === '875') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e875);


} 
else if (response.response === '876') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e876);


} 
else if (response.response === '881') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e881);


} 
else if (response.response === '882') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e882);


} 
else if (response.response === '883') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e883);


} 
else if (response.response === '884') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e884);
  document.getElementById("submitId").style.display = "none";
  document.getElementById("vantiv-payframe").style.display = "none";

} 
else if (response.response === '885') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e885);


} 
else if (response.response === '889') {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(payccmsg.e889);


} 
else {
  document.getElementById('a_x200').style.display = 'block';
  $('.alerterror').text(message);
}

}

};


var configure = {
"paypageId":document.getElementById("request$paypageId").value,
"style":"iRec7",
"reportGroup":document.getElementById("request$reportGroup").value,
"timeout":document.getElementById("request$timeout").value,
"htmlTimeout":"20000",
"div": "payframe",
"callback": payframeClientCallback,
"months": {
"1":"01",
"2":"02",
"3":"03",
"4":"04",
"5":"05",
"6":"06",
"7":"07",
"8":"08",
"9":"09",
"10":"10",
"11":"11",
"12":"12"
},
"numYears": 14,
"tabIndex": {
"accountNumber":2,
"expMonth":3,
"expYear":4
},
"placeholderText": {
"accountNumber":"Account Number"
}
};
if(typeof LitlePayframeClient === 'undefined') {
//This means we couldn't download the payframe-client javascript library
//alert("Couldn't download payframe-client javascript");
document.getElementById('a_x200').style.display = 'block';
$('.alerterror').text('Couldnot download payframe-client javascript');
 document.getElementById("submitId").style.display = "none";
  
}
var payframeClient = new LitlePayframeClient(configure);
payframeClient.autoAdjustHeight();



document.getElementById("DefaultFormName").onsubmit = function()
{
var message = {
"id":document.getElementById("request$merchantTxnId").value,
"orderId":document.getElementById("request$orderId").value
};


startTime = new Date().getTime();
payframeClient.getPaypageRegistrationId(message);




return false;
};

}



$(document).ready(function () {
init();
document.getElementById('a_x300').style.display = 'none'; 
});





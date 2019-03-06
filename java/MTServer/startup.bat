@echo off
set MTS_HOME=C:\OTC-FEC\MTServer

set CLASSPATH = %MTS_HOME%\deploy\MTServerDeploy.jar;%MTS_HOME%\lib\activation.jar;%MTS_HOME%\lib\ejb.jar;%MTS_HOME%\lib\ejbtest-bean.jar;%MTS_HOME%\lib\jaxb1-impl.jar;%MTS_HOME%\lib\jaxb-api.jar;%MTS_HOME%\lib\jaxb-impl.jar;%MTS_HOME%\lib\jaxb-xjc.jar;%MTS_HOME%\lib\jsr173_1.0_api.jar;%MTS_HO\ME%\lib\log4j-1.2.jar;%MTS_HOME%\lib\oc4j.jar;%MTS_HOME%\lib\oc4jclient.jar;%MTS_HOME%\lib\orcl-mts.jar;.;

echo %CLASSPATH%

java -classpath C:\OTC-FEC\MTServer\classes;C:\OTC-FEC\MTServer\lib\activation.jar;C:\OTC-FEC\MTServer\lib\ejb.jar;C:\OTC-FEC\MTServer\lib\ejbtest-bean.jarC:\OTC-FEC\MTServer\lib\jaxb1-impl.jar;C:\OTC-FEC\MTServer\lib\jaxb-api.jar;C:\OTC-FEC\MTServer\lib\jaxb-impl.jar;C:\OTC-FEC\MTServer\lib\jxb-xjc.jar;C:\OTC-FEC\MTServer\lib\jsr173_1.0_api.jar;C:\OTC-FEC\MTServer\lib\log4j-1.2.jar;C:\OTC-FEC\MTServer\lib\oc4j.jar;C:\OTC-FEC\MTSrver\lib\orcl-mts.jar;C:\OTC-FEC\MTServer\lib\oc4jclient.jar;.; od.otc.mts.MTServer %MTS_HOME%

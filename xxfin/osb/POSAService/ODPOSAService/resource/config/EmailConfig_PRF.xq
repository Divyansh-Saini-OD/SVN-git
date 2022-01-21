xquery version "1.0" encoding "Cp1252";
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://officedepot.com/ODPOSAService/resource/config/EmailConfig_DEV/";

declare function xf:EmailConfig_PRF()
as element(*) {
    fn:doc('/app/orclas/admin/osbfmwprf01_domain/osbfmwprf01_cluster/app-config/ODPOSAService/EmailConfig.xml')//emailParams
};


xf:EmailConfig_PRF()

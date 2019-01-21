xquery version "1.0" encoding "Cp1252";
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://officedepot.com/SerializeCouponService/resource/config/EmailConfig_DEV/";

declare function xf:EmailConfig_DEV()
as element(*) {
    fn:doc('/app/orclas/admin/osbfmwdev01_domain/osbfmwdev01_cluster/app-config/SerializeCouponService/EmailConfig.xml')//emailParams
};


xf:EmailConfig_DEV()

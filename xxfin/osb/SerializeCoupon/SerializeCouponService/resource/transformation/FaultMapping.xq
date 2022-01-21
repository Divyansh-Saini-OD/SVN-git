xquery version "1.0" encoding "Cp1252";
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://tempuri.org/SerializeCouponService/resource/transformation/faultMapping/";

declare function xf:faultMapping()
as element(*) {
    <errorMapConfig>
	<errorMap>
		<sourceErrorCodes>
			<code>CouponInformationNotFoundFault</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>2</code>
			<description>The coupon ID given is not found</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>UnknownReturnCode</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>4</code>
			<description>Unknown Return code received</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-381918</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3</code>
			<description>Could not receive response from system</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-380002</code>
			<code>BEA-382500</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>5</code>
			<description>Error trying to access queue</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-382000</code>
			<code>BEA-382030</code>
			<code>BEA-382510</code>
			<code>BEA-382513</code>
			<code>BEA-382515</code>
			<code>BEA-382516</code>
			<code>BEA-380001</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>6</code>
			<description>There was a Runtime exception</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-386200</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>7</code>
			<description>General web service security error</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-382505</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>8</code>
			<description>OSB Validate action failed. Please check the input request.</description>
		</destErrorCode>
	</errorMap>
	<unknownError>
		<destErrorCode>
			<code>9</code>
			<description>An unknown error has occurred</description>
		</destErrorCode>
	</unknownError>
</errorMapConfig>
};


xf:faultMapping()

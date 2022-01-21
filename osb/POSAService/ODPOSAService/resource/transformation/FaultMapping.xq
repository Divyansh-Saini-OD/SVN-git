xquery version "1.0" encoding "Cp1252";
(:: pragma  type="xs:anyType" ::)

declare namespace xf = "http://tempuri.org/ODPOSAService/resource/transformation/faultMapping/";

declare function xf:faultMapping()
as element(*) {
    <errorMapConfig>
	<errorMap>
		<sourceErrorCodes>
			<code>2001</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>2001</code>
			<description>The PIN provided has already been activated previously</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>2002</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>2002</code>
			<description>The PIN provided has already been deactivated previously</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>2003</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>2003</code>
			<description>PIN already consumed</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>2004</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>2004</code>
			<description>Pin No More Usable</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>3001</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3001</code>
			<description>Unknown PIN</description>
		</destErrorCode>
	</errorMap>
<errorMap>
		<sourceErrorCodes>
			<code>3002</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3002</code>
			<description>Unknown Thumbprint</description>
		</destErrorCode>
	</errorMap><errorMap>
		<sourceErrorCodes>
			<code>3003</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3003</code>
			<description>Unauthorized Dealer or Geography Mismatch</description>
		</destErrorCode>
	</errorMap><errorMap>
		<sourceErrorCodes>
			<code>3004</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3004</code>
			<description>Duplicate Vendor TransactionID</description>
		</destErrorCode>
	</errorMap><errorMap>
		<sourceErrorCodes>
			<code>3005</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3005</code>
			<description>Vendor TransactionID  Missing</description>
		</destErrorCode>
	</errorMap><errorMap>
		<sourceErrorCodes>
			<code>3006</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3006</code>
			<description>Empty Input Parameters</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>3007</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3007</code>
			<description>Invalid Certificate</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>4001</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>4001</code>
			<description>Invalid Token</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>5000</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>5000</code>
			<description>Generic Error</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>5001</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>5001</code>
			<description>POSAD Service Is Not Functional</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>5002</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>5002</code>
			<description>Invalid Certificate</description>
		</destErrorCode>
	</errorMap>
	<errorMap>
		<sourceErrorCodes>
			<code>BEA-381918</code>
		</sourceErrorCodes>
		<destErrorCode>
			<code>3</code>
			<description> Check Status Service Not Available</description>
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
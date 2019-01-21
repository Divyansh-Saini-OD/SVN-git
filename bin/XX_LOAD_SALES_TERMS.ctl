load data
CHARACTERSET UTF8
infile *
append
into table XXTPS.XXTPS_PARTY_SITE_AGG

fields terminated by "|" OPTIONALLY ENCLOSED BY '"'  TRAILING NULLCOLS
(
        PARTY_SITE_ID,
        SALES_TERM_ID,
        SALES,
        COST,
        QUANTITY,
        TRANSACTIONS
)


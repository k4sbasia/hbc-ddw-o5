load data
truncate
into table O5.edb_stage_sfcc_email_opt_data
fields terminated by ','
optionally enclosed by '"'
trailing nullcols
(
SOURCE_ID char "trim(:source_id)",
EMAIL_ADDRESS char "trim(upper(:email_address))",
FIRST_NAME char "trim(:first_name)",
MIDDLE_NAME char "trim(:middle_name)",
LAST_NAME char "trim(:last_name)",
ADDRESS char "trim(:address)",
ADDRESS_TWO char "trim(:address_two)",
CITY char "trim(:city)",
STATE char "trim(:state)",
ZIP_FULL char "trim(:zip_full)",
COUNTRY char "trim(:country)",
PHONE char "trim(:phone)",
OFF5TH_OPT_STATUS char "trim(:off5th_opt_status)",
SAKS_OPT_STATUS char "trim(:saks_opt_status)",
SAKS_CANADA_OPT_STATUS char "trim(:saks_canada_opt_status)",
OFF5TH_CANADA_OPT_STATUS char "trim(:off5th_canada_opt_status)",
THE_BAY_OPT_STATUS char "trim(:the_bay_opt_status)",
SUB_UNSUB_DATE "to_date(substr(:SUB_UNSUB_DATE,1,10),'YYYY-MM-DD')",
LANGUAGE char "DECODE(trim(:language),'en_CA','en-CA','fr_CA','fr-CA','en_US','en-US','fr_US','fr-US',trim(:language))",
BANNER char "trim(:banner)",
CANADA_FLAG char "trim(:canada_flag)",
SAKS_FAMILY_OPT_STATUS char "trim(:saks_family_opt_status)",
MORE_NUMBER char "trim(:more_number)",
HBC_REWARDS_NUMBER char "trim(:hbc_rewards_number)",
BIRTHDAY char "trim(:birthday)",
GENDER char "trim(:gender)"
)

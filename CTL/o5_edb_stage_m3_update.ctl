load data
truncate
into table O5.edb_stage_m3_update
when activity='U'
fields terminated by '|'
OPTIONALLY ENCLOSED BY '"'
(
source_id       constant 9165,
more_number     char "trim(:more_number)",
str_code        char "trim(to_char(:str_code,'000'))",
first_name      char "trim(:first_name)",
middle_name     char "trim(:middle_name)",
last_name       char "trim(:last_name)",
address         char "trim(:address)",
address_two     char "trim(:address_two)",
city            char "trim(:city)",
state           char "trim(:state)",
zip_full        char "trim(:zip_full)",
phone           char "trim(:phone)",
email_address   char "trim(upper(:email_address))",
associate_id    char "trim(:associate_id)",
subscribed      date 'MM-DD-YYYY' "trim(:subscribed)",
PROCESSED date 'MM-DD-YYYY' "trim(:PROCESSED)",
activity        filler char(2)
)

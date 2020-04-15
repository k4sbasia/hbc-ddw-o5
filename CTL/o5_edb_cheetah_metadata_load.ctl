LOAD DATA
truncate
INTO TABLE O5.email_mailing_metadata_wrk 
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  ISSUEID      char,
  ISSUENAME    char,
  TIMESENT     CHAR "to_date(substr(:timesent,1,14),'yyyymmddhh24miss')" ,
  MAILING_ID   char,
  SUBJECT      char,
  MAILING_NAME char
 )


WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
set SERVEROUT OFF
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT p.PRODUCT_ID    ||'|'||
GROUP_ID    ||'|'||
DEPARTMENT    ||'|'||
COST    ||'|'||
MORECOLORS    ||'|'||
PREORDER    ||'|'||
RATING_IMAGE_URL    ||'|'||
DISPLAY_REVIEW    ||'|'||
NOW_PRICE_RANGE    ||'|'||
WAS_PRICE_RANGE    ||'|'||
SALES_FLAG    ||'|'||
                        CASE
                           WHEN O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, 'A1')
                                   IS NOT NULL
                           THEN
                              'Y'
                           ELSE
                              'N'
                        END
                            ||'|'||
                         O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, '')   ||'|'||
                      O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, 'A1')  ||'|'||
                      concat('https://m.saksoff5th.com/pd.jsp?productCode=', p.PRODUCT_ID)
                           ||'|'||
                        concat('https://image.s5a.com/is/image/saksoff5th/',p.PRODUCT_ID) ||'|'||
BACKORDERABLE ||'|'||
BRANDNAME ||'|'||
DROPSHIP_IND ||'|'||
FEATUREDTYPE ||'|'||
GWP_FLAG ||'|'||
ISDESIGNERITEM ||'|'||
ISEGC ||'|'||
ISVIRTUAL ||'|'||
ITEM_GENDER ||'|'||
LIFESTYLECONTEMPORARY ||'|'||
LIFESTYLEMODERN ||'|'||
LIFESTYLEPREMIER ||'|'||
PD_RESTRICTEDCOUNTRY_TEXT ||'|'||
PD_RESTRICTEDSTATE_TEXT ||'|'||
PERSONALIZABLE ||'|'||
PRODUCTSHORTDESCRIPTION ||'|'||
REFAGE ||'|'||
REFCOLLECTION ||'|'||
REFCONCERN1 ||'|'||
REFCONCERN2 ||'|'||
REFCONCERN3 ||'|'||
REFCOVERAGE ||'|'||
REFCUFF ||'|'||
REFFINEFASHION ||'|'||
REFFINISH ||'|'||
REFGENDER ||'|'||
REFINEMENTFIT1 ||'|'||
REFINEMENTFIT2 ||'|'||
REFINEMENTHEELHEIGHT ||'|'||
REFINEMENTPRODUCTTYPE1 ||'|'||
REFINEMENTPRODUCTTYPE2 ||'|'||
REFINEMENTPRODUCTTYPE3 ||'|'||
REFINEMENTSTYLE1 ||'|'||
REFINEMENTSTYLE2 ||'|'||
REFINEMENTSTYLE3 ||'|'||
REFLENGTH ||'|'||
REFMATERIAL1 ||'|'||
REFMATERIAL2 ||'|'||
REFMATERIAL3 ||'|'||
REFOCCASION1 ||'|'||
REFOCCASION2 ||'|'||
REFPATTERNPRINT ||'|'||
REFRISE ||'|'||
REFSCENT1 ||'|'||
REFSCENT2 ||'|'||
REFSCENT3 ||'|'||
REFSILHOUETTE1 ||'|'||
REFSILHOUETTE2 ||'|'||
REFSILHOUETTE3 ||'|'||
REFSKINTYPE ||'|'||
REFSLEEVELENGTH ||'|'||
REFSPF ||'|'||
REFWASH ||'|'||
RETURNABLE
FROM
pim_exp_bm.ALL_PRODUCT_ATTR_RR_FEED_&2@&3 prd,
                        &1.FEED_RR_PRODUCT_DAILY P
                  WHERE
                         P.product_id = prd.product_id ;
EXIT;

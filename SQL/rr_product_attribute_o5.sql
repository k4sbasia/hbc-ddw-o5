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
SELECT 'product_id'||'|'||
'attribute.Group'||'|'||
'attribute.Department'||'|'||
'attribute.cost'||'|'||
'attribute.morecolors'||'|'||
'attribute.preorder'||'|'||
'attribute.rating_image_url'||'|'||
'attribute.display_review'||'|'||
'attribute.now_price_range'||'|'||
'attribute.was_price_range'||'|'||
'attribute.sale_flag'||'|'||
'attribute.alt_image_flag'||'|'||
'attribute.alt_image_1'||'|'||
'attribute.alt_image_2'||'|'||
'attribute.mobile_url'||'|'||
'attribute.mobile_url_alt'||'|'||
'attribute.backorderable'||'|'||
'attribute.brandname'||'|'||
'attribute.dropship_ind'||'|'||
'attribute.featuredtype'||'|'||
'attribute.gwp_flag'||'|'||
'attribute.item_gender'||'|'||
'attribute.pd_restrictedcountry_text'||'|'||
'attribute.pd_restrictedstate_text'||'|'||
'attribute.personalizable'||'|'||
'attribute.productshortdescription'||'|'||
'attribute.returnable'||'|'||
'attribute.totalreviewcount'||'|'||
'attribute.isdesigneritem'||'|'||
'attribute.isegc'||'|'||
'attribute.isvirtual'||'|'||
'attribute.lifestylecontemporary'||'|'||
'attribute.lifestylemodern'||'|'||
'attribute.lifestylepremier'||'|'||
'attribute.refinementproducttype1'||'|'||
'attribute.refinementproducttype2'||'|'||
'attribute.refinementproducttype3'||'|'||
'attribute.refinementstyle1'||'|'||
'attribute.refinementstyle2'||'|'||
'attribute.refinementstyle3'||'|'||
'attribute.refage'||'|'||
'attribute.refcollection'||'|'||
'attribute.refconcern1'||'|'||
'attribute.refconcern2'||'|'||
'attribute.refconcern3'||'|'||
'attribute.refcoverage'||'|'||
'attribute.refcuff'||'|'||
'attribute.reffinefashion'||'|'||
'attribute.reffinish'||'|'||
'attribute.refgender'||'|'||
'attribute.reflength'||'|'||
'attribute.refmaterial1'||'|'||
'attribute.refmaterial2'||'|'||
'attribute.refmaterial3'||'|'||
'attribute.refoccasion1'||'|'||
'attribute.refoccasion2'||'|'||
'attribute.refpatternprint'||'|'||
'attribute.refrise'||'|'||
'attribute.refspf'||'|'||
'attribute.refscent1'||'|'||
'attribute.refscent2'||'|'||
'attribute.refscent3'||'|'||
'attribute.refsilhouette1'||'|'||
'attribute.refsilhouette2'||'|'||
'attribute.refsilhouette3'||'|'||
'attribute.refskintype'||'|'||
'attribute.refsleevelength'||'|'||
'attribute.refwash'||'|'||
'attribute.refinementfit1'||'|'||
'attribute.refinementfit2'||'|'||
'attribute.refinementheelheight' FROM DUAL;

SELECT distinct p.PRODUCT_ID    ||'|'||
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
CASE   WHEN O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, 'A1')
                                 IS NOT NULL
                         THEN
                            'Y'
                         ELSE
                            'N'
                      END||'|'||
O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, 'A1')  ||'|'||
O5.F_GET_RR_ALT_IMAGE (p.PRODUCT_ID, 'A2')  ||'|'||
concat('https://m.saksoff5th.com/pd.jsp?productCode=', p.PRODUCT_ID) ||'|'||
concat('https://image.s5a.com/is/image/saksoff5th/',p.PRODUCT_ID) ||'|'||
BACKORDERABLE ||'|'||
BRANDNAME ||'|'||
DROPSHIP_IND ||'|'||
FEATUREDTYPE ||'|'||
nvl(GWP_FLAG,'F') ||'|'||
ITEM_GENDER ||'|'||
PD_RESTRICTEDCOUNTRY_TEXT ||'|'||
PD_RESTRICTEDSTATE_TEXT ||'|'||
nvl(PERSONALIZABLE,'F') ||'|'||
PRODUCTSHORTDESCRIPTION ||'|'||
RETURNABLE||'|'||
NUM_REVIEWS||'|'||
nvl(ISDESIGNERITEM,'F') ||'|'||
nvl(ISEGC,'F') ||'|'||
nvl(ISVIRTUAL,'F') ||'|'||
nvl(LIFESTYLECONTEMPORARY,'F') ||'|'||
LIFESTYLEMODERN ||'|'||
LIFESTYLEPREMIER ||'|'||
REFINEMENTPRODUCTTYPE1 ||'|'||
REFINEMENTPRODUCTTYPE2 ||'|'||
REFINEMENTPRODUCTTYPE3 ||'|'||
REFINEMENTSTYLE1 ||'|'||
REFINEMENTSTYLE2 ||'|'||
REFINEMENTSTYLE3 ||'|'||
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
REFLENGTH ||'|'||
REFMATERIAL1 ||'|'||
REFMATERIAL2 ||'|'||
REFMATERIAL3 ||'|'||
REFOCCASION1 ||'|'||
REFOCCASION2 ||'|'||
REFPATTERNPRINT ||'|'||
REFRISE ||'|'||
REFSPF ||'|'||
REFSCENT1 ||'|'||
REFSCENT2 ||'|'||
REFSCENT3 ||'|'||
REFSILHOUETTE1 ||'|'||
REFSILHOUETTE2 ||'|'||
REFSILHOUETTE3 ||'|'||
REFSKINTYPE ||'|'||
REFSLEEVELENGTH ||'|'||
REFWASH ||'|'||
REFINEMENTFIT1 ||'|'||
REFINEMENTFIT2 ||'|'||
REFINEMENTHEELHEIGHT
FROM
pim_exp_bm.ALL_PRODUCT_ATTR_RR_FEED_&2@&3 prd,
                        &1.FEED_RR_PRODUCT_DAILY P
                  WHERE
                         P.product_id = prd.product_id ;
EXIT;

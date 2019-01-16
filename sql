SET @year = 2019, @start_month = 1, @end_month = 1;
 select aa.ymd,Act_ACC,Act_CP,Act_ST,Act_WID,
    cc.imp
    ,cc.click
    ,100*cc.click/cc.imp as "CTR_%"
    ,cc.cv
    ,cc.cv/cc.click as CVR
    ,cc.sales
    ,1000*cc.sales/cc.imp as CPM
    ,cc.sales/cc.click as CPC
    ,cc.cost
    ,bb.w_imp
    ,cc.imp/bb.w_imp as Ave_adSLOT
    ,bb.inview_imp
    ,bb.inview_imp/bb.w_imp as InviewRate
    ,100*cc.click/bb.inview_imp as "InviewCTR_%"
 from
    (
    select
        ymd
        ,count(distinct account_id) as Act_ACC
        ,count(*) as Act_CP
    from
        (
        select
            DATE_FORMAT(CONCAT_WS('/', `target_year`, `target_month`, `target_day`), '%Y/%m/%d') AS ymd
            ,account_id
            ,rcp.campaign_id
            ,sum(imp) as c_imp 
            ,sum(click) as c_cl
        from
            report_campaign as rcp
            join campaign as cp on cp.campaign_id = rcp.campaign_id
            join advertiser as adv on cp.advertiser_id = adv.advertiser_id
        where
            target_year=@year and target_month BETWEEN @start_month and @end_month
        group by 
            target_year,target_month,target_day,account_id,campaign_id
        ) as a
    where
        c_imp > 3000 and c_cl > 5
    group by
        ymd
    ) aa
join 
    (
    select
        ymd
        ,count(distinct site_id) as Act_ST
        ,count(*) as Act_WID
        ,sum(wimp) as w_imp
        ,sum(inviewimp) as inview_imp
    from 
        (   
        select
            DATE_FORMAT(CONCAT_WS('/', `target_year`, `target_month`, `target_day`), '%Y/%m/%d') AS ymd
            ,site_id
            ,media_id
            ,sum(imp) as wimp
            ,sum(inview) as inviewimp
        from
            report_widget rwid
            join media_widget as wid on rwid.media_id = wid.widget_id
        where
            target_year=@year and target_month BETWEEN @start_month and @end_month and recommend_type = 2
        group by
            target_year,target_month,target_day,site_id,media_id
        ) b
    where
        wimp > 10
    group by
        ymd
    ) bb
on aa.ymd = bb.ymd
join
    (
    select
        DATE_FORMAT(CONCAT_WS('/', `target_year`, `target_month`, `target_day`), '%Y/%m/%d') AS ymd
        ,sum(imp) as imp
        ,sum(click) as click
        ,sum(used_cost) as sales
        ,sum(payout) as cost
        ,sum(cv) as cv
    from
        report_media
    where
        target_year=@year and target_month BETWEEN @start_month and @end_month
    group by
        target_year,target_month,target_day
    ) cc
on aa.ymd = cc.ymd

DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id          INT,
    name        VARCHAR,
    sex         VARCHAR,
    age         VARCHAR,
    height      VARCHAR,
    weight      VARCHAR,
    team        VARCHAR,
    noc         VARCHAR,
    games       VARCHAR,
    year        INT,
    season      VARCHAR,
    city        VARCHAR,
    sport       VARCHAR,
    event       VARCHAR,
    medal       VARCHAR
);

DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
    noc         VARCHAR,
    region      VARCHAR,
    notes       VARCHAR
);

select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;

----------------------------------------------------------------------------------------------

-- 1. Identify the sport which was played in all summer olympics.

with t1 as 
	( select count(distinct games) as total_summer_games
	from OLYMPICS_HISTORY 
	where season = 'Summer'
	
	),
t2 as 
	( select distinct sport, games
	from OLYMPICS_HISTORY
	where season = 'Summer' order by games

	),
t3 as 
	( select sport, count(games) as no_of_games
	from t2 
	group by sport

	)
select * 
from t3
join t1 
on t1.total_summer_games = t3.no_of_games;

-------------------------------------------------------------

-- 2. Fetch the top 5 athletes who have won the most gold medals.

with t1 as 
	(select name,count(*) as total_medals from 
	OLYMPICS_HISTORY 
	where medal = 'Gold'
	group by 1
	order by 2 desc),
t2 as 
	(select *, dense_rank() over(order by total_medals desc) as rnk
	from t1)

select * 
from t2
where rnk <=5;


-------------------------------------------------------------

-- List down total gold, silver and bronze medals won by each country.

create extension tablefunc;

select nr.region as country, medal, count(1) as total_medals 
from OLYMPICS_HISTORY oh
join OLYMPICS_HISTORY_noc_regions nr 
on oh.noc = nr.noc
where medal <> 'NA'
group by 1,2
order by 1,2;

select country,
coalesce(gold, 0) as gold,
coalesce(silver, 0 ) as silver,
coalesce(bronze, 0) as bronze
from crosstab('
				select nr.region as country, medal, count(1) as total_medals 
				from OLYMPICS_HISTORY oh
				join OLYMPICS_HISTORY_noc_regions nr 
				on oh.noc = nr.noc
				where medal <> ''NA''
				group by 1,2
				order by 1,2
				',
				'values (''Bronze''),(''Gold''),(''Silver'')'
				)
				as result (country varchar,Bronze Bigint, Gold Bigint, Silver Bigint)
order by gold desc, silver desc, bronze desc;

-------------------------------------------------------------

--  Identify which country won the most gold, most silver and most bronze medals in each olympic games.

WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;
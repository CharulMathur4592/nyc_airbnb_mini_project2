USE nyc_airbnb;

CREATE TABLE IF NOT EXISTS `host_df` (
	`host_id` INT NOT NULL UNIQUE,
	`host_name` VARCHAR(255) NOT NULL,
	`number_of_reviews` INT NOT NULL,
	`last_review` VARCHAR(255) NOT NULL,
	`reviews_per_month` FLOAT NOT NULL,
	`calculated_host_listings_count` INT NOT NULL,
	PRIMARY KEY(`host_id`)
);


CREATE TABLE IF NOT EXISTS `neighbourhood_df` (
	`neighbourhood` VARCHAR(255) NOT NULL UNIQUE,
	`neighbourhood_group` VARCHAR(255) NOT NULL,
	`listing_id` INT NOT NULL,
	PRIMARY KEY(`neighbourhood`)
);


CREATE TABLE IF NOT EXISTS `listing_df` (
	`listing_id` INT NOT NULL UNIQUE,
	`host_id` INT NOT NULL,
	`listing_name` VARCHAR(255) NOT NULL,
	`room_type` VARCHAR(255) NOT NULL,
    `neighbourhood` VARCHAR(255) NOT NULL,
	`price` INT NOT NULL,
	`minimum_nights` INT NOT NULL,
	`availability_365` INT NOT NULL,
	PRIMARY KEY(`listing_id`)
);







TRUNCATE TABLE listing_df;

SELECT COUNT(*) FROM neighbourhood_df;


-- Disable Foreign Key checks (Crucial for speed in normalized schemas)
SET FOREIGN_KEY_CHECKS = 0;

-- Disable Autocommit to allow bulk inserts (Improves index update efficiency)
SET autocommit = 0;

-- CHECK LISTING DF
SELECT *
FROM nyc_airbnb.listing_df;



-- Step 1: Commit the bulk data import transaction
COMMIT;

-- Step 2: Add the two correct Foreign Key constraints to the listing_df table.
-- (This links the 'many' side to the 'one' side, ensuring data integrity.)

-- Constraint A: listing_df (child) references host_df (parent) on host_id
ALTER TABLE listing_df
ADD CONSTRAINT fk_listing_host
FOREIGN KEY(host_id) REFERENCES host_df(host_id)
ON UPDATE NO ACTION ON DELETE NO ACTION;

-- Constraint B: listing_df (child) references neighbourhood_df (parent) on neighbourhood
ALTER TABLE listing_df
ADD CONSTRAINT fk_listing_neighbourhood
FOREIGN KEY(neighbourhood) REFERENCES neighbourhood_df(neighbourhood)
ON UPDATE NO ACTION ON DELETE NO ACTION;



-- Step 3: Restore system variables
SET autocommit = 1;
SET FOREIGN_KEY_CHECKS = 1;


-- TEST NEIG
select * from nyc_airbnb.neighbourhood_df;
select * from nyc_airbnb.host_df;
select * from nyc_airbnb.listing_df;



-- PROFITABILITY AND DEMAND ASSESSMENT 1
SELECT
    room_type,
    ROUND(AVG(l.price), 2) AS average_listing_price,
    ROUND(AVG(l.minimum_nights), 1) AS avg_minimum_nights,
    ROUND(AVG(l.minimum_nights * l.price), 2) AS avg_minimum_revenue_per_booking,
    ROUND(AVG(l.availability_365), 1) AS avg_availability_per_year
FROM
    listing_df l
GROUP BY
    room_type

ORDER BY
    average_listing_price DESC
LIMIT 10;


-- PROFITABILITY AND DEMAND ASSESSMENT 2
SELECT
    l.neighbourhood,
    ROUND(AVG(l.price),2) AS average_listing_price
FROM
    listing_df l
GROUP BY
    l.neighbourhood
ORDER BY
    average_listing_price DESC
LIMIT 10;

-- PROFITABILITY AND DEMAND ASSESSMENT 3
SELECT
    l.neighbourhood,
    ROUND(AVG(l.price),2) AS average_listing_price
FROM
    listing_df l
WHERE
	l.room_type = 'Entire home/apt'
GROUP BY
    l.neighbourhood
ORDER BY
    average_listing_price DESC
LIMIT 10;

-- HIGH DEMAND AND HIGH VALUE NEIGHBOURHOODS
SELECT
    l.neighbourhood,
    ROUND(AVG(l.price),2) AS average_price,
    ROUND(AVG(h.reviews_per_month),1) AS avg_reviews_per_month
FROM
    listing_df l
    
INNER JOIN
    host_df h ON l.host_id = h.host_id
WHERE
	l.room_type = 'Entire home/apt'
GROUP BY
    l.neighbourhood
    
HAVING
    AVG(l.price) > 150 -- Filters for listings above decent price
    
ORDER BY
    avg_reviews_per_month DESC, average_price DESC
LIMIT 5;

-- MARKET SATURATION AND COMPETITION
SELECT
    ndf.neighbourhood_group,
    COUNT(DISTINCT l.host_id) AS total_hosts,
    SUM(CASE WHEN h.calculated_host_listings_count > 5 THEN 1 ELSE 0 END) AS professional_host_count,
    ROUND(CAST(SUM(CASE WHEN h.calculated_host_listings_count > 5 THEN 1 ELSE 0 END) AS FLOAT) * 100 / COUNT(DISTINCT l.host_id),1) AS pct_professional_hosts
FROM
    listing_df l
INNER JOIN
    host_df h ON l.host_id = h.host_id
INNER JOIN
    neighbourhood_df ndf ON l.neighbourhood = ndf.neighbourhood
-- WHERE l.room_type = 'Entire home/apt'   >>>> FILTERING BY TYPE OF ROOM RETURNS ALMOST NOTHING
GROUP BY
    ndf.neighbourhood_group
ORDER BY
    total_hosts DESC;
    
-- MARKET SATURATION AND COMPETITION EXPANDED
    
    SELECT
    ndf.neighbourhood_group,
    ndf.neighbourhood, -- Included the neighbourhood column from ndf
    COUNT(DISTINCT l.host_id) AS total_hosts,
    SUM(CASE WHEN h.calculated_host_listings_count > 5 THEN 1 ELSE 0 END) AS professional_host_count,
    ROUND(CAST(SUM(CASE WHEN h.calculated_host_listings_count > 5 THEN 1 ELSE 0 END) AS FLOAT) * 100 / COUNT(DISTINCT l.host_id),1) AS pct_professional_hosts
FROM
    listing_df l
INNER JOIN
    host_df h ON l.host_id = h.host_id
INNER JOIN
    neighbourhood_df ndf ON l.neighbourhood = ndf.neighbourhood
WHERE
    l.room_type = 'Entire home/apt'
GROUP BY
    ndf.neighbourhood_group,
    ndf.neighbourhood -- Grouping by both neighbourhood_group and neighbourhood
ORDER BY
    total_hosts DESC;

-- HIGH DEMAND LOW COMPETITION
SELECT
    l.neighbourhood,
    ROUND(AVG(h.number_of_reviews),1) AS avg_total_reviews,
    ROUND(AVG(h.calculated_host_listings_count),1) AS avg_listings_per_host_in_neighbourhood
FROM
    listing_df l
INNER JOIN
    host_df h ON l.host_id = h.host_id
WHERE
    l.room_type = 'Entire home/apt'
GROUP BY
    l.neighbourhood
HAVING
    AVG(h.calculated_host_listings_count) < 2 -- areas where hosts typically have fewer than 2 listings
ORDER BY
    avg_total_reviews DESC
LIMIT 10;

-- OPTIMAL PRODUCT INVESTMENT
SELECT
    l.room_type,
    ROUND(CAST(AVG(l.price) AS DECIMAL(10, 2)),2) AS median_price_approx,
    ROUND(AVG(l.minimum_nights),2) AS avg_min_nights,
    ROUND(AVG(l.availability_365),2) AS avg_availability
FROM
    listing_df l
INNER JOIN
    neighbourhood_df ndf ON l.neighbourhood = ndf.neighbourhood
WHERE
    ndf.neighbourhood_group = 'Brooklyn' -- Substitute with the desired high-value group to analyse
GROUP BY
    l.room_type
ORDER BY
    median_price_approx DESC;
    
    
-- Opportunity for Re-Pricing (all property types)
    SELECT
    listing_name,
    neighbourhood,
    price,
    availability_365
FROM
    listing_df
WHERE
    price > 200 -- Listings that are priced high
    AND availability_365 > 300 -- Listings that are available for most of the year
 
ORDER BY
    availability_365 DESC, price DESC
LIMIT 10;

-- Opportunity for Re-Pricing (only entire homes)

SELECT
    l.listing_name,
    l.neighbourhood,
    ndf.neighbourhood_group, 
    l.price,
    l.availability_365
FROM
    listing_df l
INNER JOIN
    neighbourhood_df ndf ON l.neighbourhood = ndf.neighbourhood 
WHERE
    l.price > 200 -- Listings that are priced high
    AND l.availability_365 > 300 -- Listings that are available for most of the year
    AND l.room_type = 'Entire home/apt' -- only entire homes
ORDER BY    l.availability_365 DESC, l.price DESC
LIMIT 10;
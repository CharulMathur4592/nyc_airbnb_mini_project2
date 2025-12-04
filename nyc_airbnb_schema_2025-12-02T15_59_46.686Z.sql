CREATE TABLE IF NOT EXISTS `host_df` (
	`neighbourhood` VARCHAR(255) NOT NULL UNIQUE,
	`host_name` VARCHAR(255) NOT NULL,
	`number_of_reviews` INT NOT NULL,
	`last_review` VARCHAR(255) NOT NULL,
	`reviews_per_month` FLOAT NOT NULL,
	`calculated_host_listings_count` INT NOT NULL,
	`host_id` INT NOT NULL,
	PRIMARY KEY(`host_id`)
);


CREATE TABLE IF NOT EXISTS `neighbourhood_df` (
	`neighbourhood` VARCHAR(255) NOT NULL UNIQUE,
	`neighbourhood_group` VARCHAR(255) NOT NULL,
	`listing_id` INT NOT NULL,
	PRIMARY KEY(`neighbourhood`)
);


CREATE TABLE IF NOT EXISTS `listing_df` (
	`host_id` INT NOT NULL,
	`listing_name` VARCHAR(255) NOT NULL,
	`room_type` VARCHAR(255) NOT NULL,
	`neighbourhood` VARCHAR(255) NOT NULL,
	`price` INT NOT NULL,
	`minimum_nights` INT NOT NULL,
	`availability_365` INT NOT NULL,
	`latitude` FLOAT NOT NULL,
	`longitude` FLOAT NOT NULL,
	`listing_id` INT NOT NULL,
	PRIMARY KEY(`listing_id`)
);


ALTER TABLE `host_df`
ADD FOREIGN KEY(`host_id`) REFERENCES `listing_df`(`host_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `listing_df`
ADD FOREIGN KEY(`listing_id`) REFERENCES `neighbourhood_df`(`listing_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `neighbourhood_df`
ADD FOREIGN KEY(`neighbourhood`) REFERENCES `host_df`(`neighbourhood`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `neighbourhood_df`
ADD FOREIGN KEY(`neighbourhood`) REFERENCES `listing_df`(`neighbourhood`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
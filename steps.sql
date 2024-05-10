##########################################################################################################
# Steps.sql file defines the required steps in order to transform and clean the original data into a well-defined database.
# 
# This file takes into consideration that you've already loaded the sales_data_sample.csv file into a 
# database table.
# 
# The steps create the corresponding tables and insert data from the file into the corresponding table.
#
# After this, you can query this info in order to visualize it on Looker Studio.
#
# Ernesto Cantú
# 05-02-2024
#########################################################################################################


#step 1 - make sure the file is loaded
select * from `sales_data_sample.csv` sdsc;

#####################################################################################################

#step 2 - getting the posible status from the orders.
CREATE TABLE `status` (
  `status_id` int NOT NULL AUTO_INCREMENT,
  `status` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into status (status)
select distinct status from `sales_data_sample.csv`;

#####################################################################################################

#step 3 - product line catalog.
CREATE TABLE `product_line` (
  `pl_id` int NOT NULL AUTO_INCREMENT,
  `product_line` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`pl_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into product_line  (product_line)
select distinct PRODUCTLINE  from `sales_data_sample.csv` 

#####################################################################################################

#step 4 - product catalog

CREATE TABLE sales_data_example.product (
	id int auto_increment NOT NULL,
	product_id varchar(20) NOT NULL,
	pl_id int NOT NULL,
	unit_price decimal(18,2) NOT NULL,
	mrsp decimal(18,2) NULL,
	CONSTRAINT product_pk PRIMARY KEY (id),
	CONSTRAINT product_un UNIQUE KEY (product_id),
	CONSTRAINT product_FK FOREIGN KEY (pl_id) REFERENCES sales_data_example.product_line(pl_id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


#As mencioned on the main document of the project, as I was analyzing the product's unit prices, I found out that there were different
#prices for the same product. I could not tell that they were applied to a specific customer or other condition.
#So, as part of my project analysis, I decided to define a catalog's unit price for each product and a "sale unit price" for the product.
#This gave me the possibility to analyze both options in order to identify the difference between the highest price and the sales price.
INSERT INTO sales_data_example.product
(product_id, pl_id, unit_price, mrsp)
select 
	o.PRODUCTCODE,
	pl.pl_id,
	MAX(FORMAT(o.PRICEEACH,2,'es-MX')), #took the highest price
	o.MSRP
from `sales_data_sample.csv`  o
join product_line pl on pl.product_line = o.PRODUCTLINE 
group by o.PRODUCTCODE, pl.pl_id , o.PRODUCTLINE,o.MSRP


#####################################################################################################

#step 5 - customers catalog
CREATE TABLE sales_data_example.customer (
	customer_id INT auto_increment NOT NULL,
	name varchar(100) NOT NULL,
	phone varchar(20) NULL,
	address1 varchar(100) NULL,
	address2 varchar(50) NULL,
	city varchar(100) NULL,
	state varchar(20) NULL,
	pscode varchar(30) NULL,
	country varchar(30) NULL,
	terrytory varchar(10) NULL,
	contact varchar(30) NULL,
	CONSTRAINT NewTable_pk PRIMARY KEY (customer_id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;
COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO sales_data_example.customer
(name, phone, address1, address2, city, state, pscode, country, terrytory, contact)
select 
	CUSTOMERNAME,
	PHONE,
	ADDRESSLINE1,
	ADDRESSLINE2,
	CITY,
	STATE,
	POSTALCODE,
	COUNTRY,
	TERRITORY,
	concat(CONTACTFIRSTNAME,' ',CONTACTLASTNAME) 
from `sales_data_sample.csv`  o
group by CUSTOMERNAME,
	PHONE,
	ADDRESSLINE1,
	ADDRESSLINE2,
	CITY,
	STATE,
	POSTALCODE,
	COUNTRY,
	TERRITORY,
	concat(CONTACTFIRSTNAME,' ',CONTACTLASTNAME) 

#####################################################################################################

#step 6 - orders catalog
CREATE TABLE `order` (
  `order` varchar(30) NOT NULL,
  `order_date` date DEFAULT NULL,
  `quarter` int DEFAULT NULL,
  `month_id` int DEFAULT NULL,
  `year` int DEFAULT NULL,
  `customer` int DEFAULT NULL,
  `status` int DEFAULT NULL,
  `deal_size` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`order`),
  KEY `order_FK` (`status`),
  KEY `order_FK_1` (`customer`),
  CONSTRAINT `order_FK` FOREIGN KEY (`status`) REFERENCES `status` (`status_id`),
  CONSTRAINT `order_FK_1` FOREIGN KEY (`customer`) REFERENCES `customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

#
# As part of the treatment process, I had to use insert ignore (a particular mysql instruction) to manipulate the order dates. They were truncating.
#
insert IGNORE  INTO sales_data_example.`order`
(`order`, order_date, quarter, month_id, `year`, customer, status, deal_size)
select 
	o.ORDERNUMBER ,
	str_to_date(o.ORDERDATE, '%m/%d/%Y'),
	o.QTR_ID,
	o.MONTH_ID,
	o.YEAR_ID,
	c.customer_id,
	s.status_id,
	o.DEALSIZE 
from `sales_data_sample.csv`  o
join customer c on c.name = o.CUSTOMERNAME
join status s on s.status = o.STATUS
group by o.ORDERNUMBER ,
	o.ORDERDATE,
	o.QTR_ID,
	o.MONTH_ID,
	o.YEAR_ID,
	c.customer_id,
	s.status_id,
	o.DEALSIZE 

#####################################################################################################

#step 7 - order detail, which contains the products per order, with the units quantity and the final price
#Also, as mentioned before, I ignored the original "SALES" column form the file as I identified that almost 46% 
#of the records did not were correct.
CREATE TABLE sales_data_example.detail_order (
	`order` varchar(30) NOT NULL,
	product_id varchar(30) NOT NULL,
	quantity int NULL,
	sell_price decimal(18,2) NULL,
	order_line int NULL,
	CONSTRAINT detail_order_pk PRIMARY KEY (`order`,product_id),
	CONSTRAINT detail_order_FK FOREIGN KEY (`order`) REFERENCES sales_data_example.`order`(`order`),
	CONSTRAINT detail_order_FK_1 FOREIGN KEY (product_id) REFERENCES sales_data_example.product(product_id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO sales_data_example.detail_order
(`order`, product_id, quantity, sell_price, order_line)
select 
	o.ORDERNUMBER,
	o.PRODUCTCODE,
	o.QUANTITYORDERED,
	o.PRICEEACH, ## as mentioned before, I took the original's data sell price as the final sell price of a product, in order to compare it to the highest sale.
	o.ORDERLINENUMBER 
from `sales_data_sample.csv` o

#####################################################################################################
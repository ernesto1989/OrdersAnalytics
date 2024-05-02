#paso 1 - cargar datos en tabla "original"
select * from `sales_data_sample.csv` sdsc;

#paso 2 - crear tabla de estatus y obtener los distintos estatus
CREATE TABLE `status` (
  `status_id` int NOT NULL AUTO_INCREMENT,
  `status` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into status (status)
select distinct status from `sales_data_sample.csv` 

#paso 3 - generar catálogo de lineas de producto

CREATE TABLE `product_line` (
  `pl_id` int NOT NULL AUTO_INCREMENT,
  `product_line` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`pl_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into product_line  (product_line)
select distinct PRODUCTLINE  from `sales_data_sample.csv` 



#paso 4 - generar catálogo de productos

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

#Al llegar al catálogo de producto, me percaté que el precio unitario por producto es distinto en cada venta
#Se decidió tener un precio unitario por catálogo (buscando el precio máximo) y tener un precio de venta en la venta final
INSERT INTO sales_data_example.product
(product_id, pl_id, unit_price, mrsp)
select 
	o.PRODUCTCODE,
	pl.pl_id,
	MAX(FORMAT(o.PRICEEACH,2,'es-MX')),
	o.MSRP
from `sales_data_sample.csv`  o
join product_line pl on pl.product_line = o.PRODUCTLINE 
group by o.PRODUCTCODE, pl.pl_id , o.PRODUCTLINE,o.MSRP


#paso 5 - genero el catálogo de clientes
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


#paso 6 - creo la tabla de ordenes de compra
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

#nota: utilicé el insert ignore porque me está fallando el truncate de la fecha
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


	#paso 7 - creo el detalle de la venta
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
	o.PRICEEACH,
	o.ORDERLINENUMBER 
from `sales_data_sample.csv` o

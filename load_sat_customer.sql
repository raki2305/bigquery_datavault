-- Determine modified and new customer
DECLARE changed_customer ARRAY<STRUCT<source STRING, first_name	STRING, last_name STRING, age INT64, street STRING, city STRING, hash_customer BYTES, hash_diff BYTES>>; --Das Array enthält nachfolgend alle der veränderten und neuen Daten

SET changed_customer =
(SELECT
      ARRAY_AGG(STRUCT(customer.source, customer.first_name, customer.last_name, customer.age, customer.street, customer.city,
      MD5(customer.id_customer), 
      MD5(CONCAT(customer.first_name, customer.last_name, CAST(customer.age AS STRING), customer.street, customer.city)))
      )
    FROM
      `de-ist-energy-datalake.datavault_test.sat_customer` AS sat
    RIGHT JOIN
      `de-ist-energy-datalake.datavault_test.customer` AS customer
    ON
      MD5(customer.id_customer) = sat.hash_customer
    WHERE
      sat.hash_diff != MD5(CONCAT(customer.first_name, customer.last_name, CAST(customer.age AS STRING), customer.street, customer.city)) OR 
      sat.hash_customer is null);


--Delete obsolete data
DELETE
  `de-ist-energy-datalake.datavault_test.sat_customer` as sat
WHERE sat.hash_customer IN (SELECT hash_customer from UNNEST(changed_customer) as customer_id);

--Neue und veränderte Daten hinzufügen
INSERT INTO `de-ist-energy-datalake.datavault_test.sat_customer`
SELECT 
hash_customer, 
CURRENT_TIMESTAMP(),
* EXCEPT(hash_customer),
from (Select * from UNNEST(changed_customer)) --Read from the intermediate result

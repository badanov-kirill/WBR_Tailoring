CREATE TYPE [Ozon].[AttributesType] AS TABLE
(
	attribute_id INT,
	attribute_name VARCHAR(50) NOT NULL,
	attribute_descr VARCHAR(500) NOT NULL,
	data_type_name VARCHAR(100),
	oag_id INT,
	oag_name VARCHAR(100),
	is_collection BIT NOT NULL,
	dictionary_id INT
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[AttributesType] TO PUBLIC;
GO
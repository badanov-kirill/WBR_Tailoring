CREATE TYPE [Ozon].[AttributesType] AS TABLE
(
	category_id BIGINT,
	attribute_id BIGINT,
	attribute_name VARCHAR(50),
	attribute_descr VARCHAR(900),
	data_type_name VARCHAR(100),
	oag_id INT,
	oag_name VARCHAR(100),
	is_collection BIT,
	dictionary_id INT,
	is_required BIT
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[AttributesType] TO PUBLIC;
GO
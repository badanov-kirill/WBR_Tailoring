CREATE TYPE [Ozon].[AttributesRequiredType] AS TABLE
(

	attribute_id BIGINT,
	is_required_us BIT
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[AttributesRequiredType] TO PUBLIC;
GO
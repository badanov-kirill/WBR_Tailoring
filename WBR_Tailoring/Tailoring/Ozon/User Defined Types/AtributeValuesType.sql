CREATE TYPE [Ozon].[AttributeValuesType] AS TABLE
(
	av_id BIGINT,
	av_value VARCHAR(50),
	is_used BIT
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[AttributeValuesType] TO PUBLIC;
GO
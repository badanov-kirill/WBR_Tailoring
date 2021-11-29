CREATE TABLE [Ozon].[AttributeValues]
(
	av_id BIGINT CONSTRAINT [PK_AttributeValues] PRIMARY KEY CLUSTERED NOT NULL,
	av_value VARCHAR(50) NOT NULL,
	is_used BIT NOT NULL
)

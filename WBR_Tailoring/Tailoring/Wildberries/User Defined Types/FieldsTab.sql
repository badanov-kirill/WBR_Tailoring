CREATE TYPE [Wildberries].[FieldsTab] AS TABLE
(
	fields_id INT NOT NULL,
	fields_name VARCHAR(200) NOT NULL,
	kind_id INT NULL,
	si_name VARCHAR(50) NULL,
	is_required BIT NULL,
	is_readonly BIT NULL,
	regex NVARCHAR(25) NULL,
	header VARCHAR(200) NULL,
	max_count INT NULL
	PRIMARY KEY CLUSTERED(fields_id)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[FieldsTab] TO PUBLIC;
GO
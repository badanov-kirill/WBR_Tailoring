CREATE TYPE [Wildberries].[RequiredFields] AS TABLE
(
	fields_id INT NOT NULL,
    wb_subject_name NVARCHAR(100) NOT NULL, 
    PRIMARY KEY CLUSTERED (fields_id, wb_subject_name)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[RequiredFields] TO PUBLIC;
GO

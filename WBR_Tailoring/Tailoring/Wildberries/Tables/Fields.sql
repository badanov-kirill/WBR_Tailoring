CREATE TABLE [Wildberries].[Fields]
(
	fields_id INT CONSTRAINT [PK_WBFields] PRIMARY KEY CLUSTERED NOT NULL,
	fields_name VARCHAR(200) NOT NULL,
    kind_id INT NULL,
    si_name VARCHAR(50) NULL,
    is_required BIT NULL,
    is_readonly BIT NULL,
    regex VARCHAR(25) NULL,
    header VARCHAR(200) NULL,
    max_count INT NULL,
    dt DATETIME2(0) NOT NULL,
    is_deleted BIT NOT NULL
)

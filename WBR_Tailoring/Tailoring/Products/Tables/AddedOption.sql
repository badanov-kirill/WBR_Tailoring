CREATE TABLE [Products].[AddedOption]
(
	ao_id              INT IDENTITY(1, 1) CONSTRAINT [PK_AddedOption] PRIMARY KEY CLUSTERED NOT NULL,
	ao_id_parent       INT CONSTRAINT [FK_AddedOption_ao_id_parent] FOREIGN KEY REFERENCES Products.AddedOption (ao_id) NULL,
	ao_name            VARCHAR(50) NOT NULL,
	employee_id        INT NOT NULL,
	dt                 dbo.SECONDSTIME NOT NULL,
	isdeleted          BIT NOT NULL,
	ao_name_eng        VARCHAR(50) NULL,
	si_id              INT CONSTRAINT [FK_Products_AddedOption_si_id] FOREIGN KEY REFERENCES Products.SI (si_id) NULL,
	ao_type_id         INT CONSTRAINT [FK_Products_AddedOption_ao_type_id] FOREIGN KEY REFERENCES Products.AddedOptionType (ao_type_id) NULL,
	is_bool            BIT NULL,
	erp_id             INT NULL,
	is_constructor     BIT CONSTRAINT [DF_AddedOption_is_is_constructor] DEFAULT(0) NOT NULL,
	content_id         INT NULL,
	content_ext_id     INT NULL
);

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedOption_ao_id_parent_ao_name]
    ON Products.AddedOption(ao_id_parent ASC, ao_name ASC) WHERE ao_id_parent IS NOT NULL
    ON [Indexes];
    
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedOption_erp_id]
    ON Products.AddedOption(erp_id) WHERE isdeleted = 0 AND erp_id IS NOT NULL
    ON [Indexes];

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedOption_content_id]
    ON Products.AddedOption(content_id) WHERE content_id IS NOT NULL AND ao_id_parent IS NULL
    ON [Indexes];

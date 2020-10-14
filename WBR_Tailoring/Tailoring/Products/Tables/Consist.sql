CREATE TABLE [Products].[Consist]
(
	consist_id           INT IDENTITY(1, 1) CONSTRAINT [PK_Consist] PRIMARY KEY CLUSTERED NOT NULL,
	consist_name         VARCHAR(50) NOT NULL,
	employee_id          INT NOT NULL,
	dt                   dbo.SECONDSTIME NOT NULL,
	is_deleted           BIT NOT NULL,
	consist_name_eng     VARCHAR(50) NULL,
	erp_id               INT NOT NULL,
	consist_type_id                INT CONSTRAINT [FK_Consist_ct_id] FOREIGN KEY REFERENCES Products.ConsistType(consist_type_id) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Consist_consist_name] ON Products.Consist(consist_name) ON [Indexes]
GO
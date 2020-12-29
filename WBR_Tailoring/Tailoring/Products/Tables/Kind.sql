CREATE TABLE [Products].[Kind]
(
	kind_id         INT IDENTITY(1, 1) CONSTRAINT [PK_Kind] PRIMARY KEY CLUSTERED NOT NULL,
	kind_name       VARCHAR(25) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	isdeleted       BIT NOT NULL,
	erp_id          INT NOT NULL,
	age_id          INT CONSTRAINT [FK_Kind_age_id] FOREIGN KEY REFERENCES Products.Age(age_id) NULL,
	gender_id       INT CONSTRAINT [FK_Kind_gendr_id] FOREIGN KEY REFERENCES Products.Gender(gender_id) NULL,
	gs1_id			VARCHAR(20) NULL
);

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Kind_kind_name] ON Products.Kind(kind_name) ON [Indexes]
GO
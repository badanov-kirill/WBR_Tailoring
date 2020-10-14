CREATE TABLE [Products].[Subject]
(
	subject_id          INT IDENTITY(1, 1) NOT NULL CONSTRAINT [PK_Subject] PRIMARY KEY CLUSTERED(subject_id ASC),
	subject_name        VARCHAR(50) NOT NULL,
	employee_id         INT NOT NULL,
	dt                  dbo.SECONDSTIME NOT NULL,
	isdeleted           BIT NOT NULL,
	subject_name_sf     VARCHAR(50) NULL,
	erp_id              INT NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Subject_subject_name] ON Products.[Subject](subject_name) ON [Indexes]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Subject_erp_id] ON Products.[Subject](erp_id) ON [Indexes]
GO
CREATE TABLE [Material].[Consists]
(
	consist_id           INT CONSTRAINT [PK_Consists] PRIMARY KEY CLUSTERED NOT NULL,
	consist_name         VARCHAR(50) NOT NULL,
	employee_id          INT NOT NULL,
	dt                   dbo.SECONDSTIME CONSTRAINT [DF_Consists_dt] DEFAULT(GETDATE()) NOT NULL,
	isdeleted            BIT NOT NULL,
	rv                   ROWVERSION NOT NULL,
	consist_name_eng     VARCHAR(50) NULL,
	CONSTRAINT [CK_Consists_Length] CHECK(LEN(consist_name) > (0))
);

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Consist_name]
    ON Material.Consists(consist_name ASC)
    ON [Indexes];
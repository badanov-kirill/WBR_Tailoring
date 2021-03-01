CREATE TABLE [RefBook].[FiscalAccumulator]
(
	fa_id         INT IDENTITY(1, 1) CONSTRAINT [PK_FiscalAccumulator] PRIMARY KEY CLUSTERED NOT NULL,
	fa_number     VARCHAR(20) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_FiscalAccumulator_fa_number] ON RefBook.FiscalAccumulator(fa_number) ON [Indexes]
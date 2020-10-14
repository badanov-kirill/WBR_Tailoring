CREATE TABLE [Products].[SI]
(
	si_id             INT CONSTRAINT [PK_SI] PRIMARY KEY CLUSTERED NOT NULL,
	si_name           VARCHAR(50) NOT NULL,
	isdeleted         BIT NOT NULL,
	convert_koeff     SMALLINT CONSTRAINT [DF_SI_convert_koeff] DEFAULT(0) NOT NULL,
	multiplier        DECIMAL(19,8) CONSTRAINT [DF_SI_multiplier] DEFAULT(1) NOT NULL,
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SI_si_name] 
    ON Products.SI(si_name ASC) WHERE isdeleted = 0
    ON [Indexes]
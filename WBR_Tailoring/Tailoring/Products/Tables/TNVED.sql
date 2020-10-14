CREATE TABLE [Products].[TNVED]
(
	tnved_id       INT CONSTRAINT [PK_TNVED] PRIMARY KEY CLUSTERED NOT NULL,
	tnved_pid      INT NULL,
	tnved_cod      VARCHAR(15) NOT NULL,
	tnved_pcod     VARCHAR(15) NULL,
	tnved_desc     VARCHAR(1000) NOT NULL,
	excise         BIT NOT NULL,
)

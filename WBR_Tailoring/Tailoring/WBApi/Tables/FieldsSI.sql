CREATE TABLE [WBApi].[FieldsSI]
(
	fields_id     INT CONSTRAINT [FK_WBApiFieldsSI_fields_id] FOREIGN KEY REFERENCES WBApi.Fields(fields_id) NOT NULL,
	si_id         INT CONSTRAINT [FK_WBApiFieldsSI_si_id] FOREIGN KEY REFERENCES WBApi.SI(si_id) NOT NULL,
	dt            DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_WBApiFieldsSI] PRIMARY KEY CLUSTERED(fields_id, si_id)
)

CREATE TABLE [Products].[CareThingAddedOption]
(
	ao_id           INT CONSTRAINT [FK_CareThingAddedOption_ao_id] FOREIGN KEY REFERENCES Products.AddedOption(ao_id) NOT NULL,
	ctg_id          INT CONSTRAINT [FK_CareThingAddedOption_ctg_id] FOREIGN KEY REFERENCES Products.CareThingGroup(ctg_id) NOT NULL,
	img_name        VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_CareThingAddedOption] PRIMARY KEY CLUSTERED(ao_id)
)

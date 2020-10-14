CREATE TABLE [Products].[ConsistAddedOption]
(
	ao_id           INT CONSTRAINT [FK_ConsistAddedOption_ao_id] FOREIGN KEY REFERENCES Products.AddedOption(ao_id) NOT NULL,
	print_name      VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_ConsistAddedOption] PRIMARY KEY CLUSTERED(ao_id)
)

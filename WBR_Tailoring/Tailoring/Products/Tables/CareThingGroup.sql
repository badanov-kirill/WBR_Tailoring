CREATE TABLE [Products].[CareThingGroup]
(
	ctg_id          INT CONSTRAINT [PK_CareThingGroup_ctg_id] PRIMARY KEY CLUSTERED NOT NULL,
	ctg_name        VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)
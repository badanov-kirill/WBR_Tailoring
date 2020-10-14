CREATE TABLE [Products].[SketchTechnologyJobComment]
(
	stj_id      INT CONSTRAINT [FK_SketchTechnologyJobComment_stj_id] FOREIGN KEY REFERENCES Products.SketchTechnologyJob(stj_id) NOT NULL,
	comment     VARCHAR(200) NOT NULL,
	CONSTRAINT [PK_SketchTechnologyJobComment] PRIMARY KEY CLUSTERED(stj_id)
)

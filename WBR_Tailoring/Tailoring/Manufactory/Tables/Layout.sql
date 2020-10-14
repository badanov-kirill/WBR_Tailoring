CREATE TABLE [Manufactory].[Layout]
(
	layout_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_Layout] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt                  DATETIME2(0) NOT NULL,
	create_employee_id         INT NOT NULL,
	dt                         DATETIME2(0) NOT NULL,
	employee_id                INT NOT NULL,
	frame_width                SMALLINT NOT NULL,
	layout_length              DECIMAL(9, 3) NOT NULL,
	effective_percent          DECIMAL(5, 3) NOT NULL,
	base_sketch_id             INT CONSTRAINT [FK_Layout_base_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	base_completing_id         INT CONSTRAINT [FK_SketchCompleting_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	base_completing_number     TINYINT NOT NULL,
	base_consumption           DECIMAL(9, 3) NOT NULL,
	is_deleted                 BIT NOT NULL,
	comment					   VARCHAR(200) NULL
)

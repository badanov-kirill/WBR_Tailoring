CREATE TABLE [Ozon].[SubjectsCategories]
(
	subject_id      INT CONSTRAINT [FK_Ozon_SubjectsCategories_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	category_id     BIGINT CONSTRAINT [FK_Ozon_SubjectsCategories_category_id] FOREIGN KEY REFERENCES Ozon.Categories(category_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_Ozon_SubjectsCategories] PRIMARY KEY CLUSTERED(subject_id, category_id)
)

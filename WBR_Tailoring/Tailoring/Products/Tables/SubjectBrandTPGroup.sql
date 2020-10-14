CREATE TABLE [Products].[SubjectBrandTPGroup]
(
	subject_id      INT CONSTRAINT [FK_SubjectBrandTPGroup_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	brand_id        INT CONSTRAINT [FK_SubjectBrandTPGroup_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	kind_id         INT CONSTRAINT [FK_SubjectBrandTPGroup_kind_id] FOREIGN KEY REFERENCES Products.Kind(kind_id) NOT NULL,
	tpgroup_id      SMALLINT CONSTRAINT [FK_SubjectBrandTPGroup_tpgroup_id] FOREIGN KEY REFERENCES Products.TPGroup(tpgroup_id) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_SubjectBrandTPGroup] PRIMARY KEY CLUSTERED(subject_id, brand_id, kind_id, tpgroup_id)
)

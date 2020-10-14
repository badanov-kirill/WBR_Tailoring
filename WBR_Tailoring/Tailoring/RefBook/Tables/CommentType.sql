CREATE TABLE [RefBook].[CommentType]
(
	ct_id           TINYINT CONSTRAINT [PK_CommentType] PRIMARY KEY CLUSTERED NOT NULL,
	ct_name         VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)

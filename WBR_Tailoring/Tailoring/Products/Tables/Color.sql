CREATE TABLE [Products].[Color]
(
	color_cod            INT CONSTRAINT [PK_Color] PRIMARY KEY CLUSTERED NOT NULL,
	color_cod_parent     INT CONSTRAINT [FK_Color_color_cod_parent] FOREIGN KEY(color_cod_parent) REFERENCES Products.Color (color_cod) NULL,
	color_name           VARCHAR(25) NOT NULL,
	employee_id          INT NOT NULL,
	dt                   dbo.SECONDSTIME NOT NULL,
	isdeleted            BIT NOT NULL
)

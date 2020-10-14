CREATE TYPE [Warehouse].[StoragePlaces]  AS TABLE(
                                                 	place_id INT NULL,
                                                 	place_name VARCHAR(50) NOT NULL,
                                                 	stage INT NULL,
                                                 	street INT NULL,
                                                 	section INT NULL,
                                                 	rack INT NULL,
                                                 	field INT NULL,
                                                 	is_deleted BIT NOT NULL,
                                                 	place_type_id INT NOT NULL,
                                                 	zor_id INT NOT NULL
                                                 )

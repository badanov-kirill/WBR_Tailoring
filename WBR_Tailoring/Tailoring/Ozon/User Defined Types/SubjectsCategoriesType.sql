CREATE TYPE [Ozon].[SubjectsCategoriesType] AS TABLE
(subject_id INT, category_id BIGINT)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[SubjectsCategoriesType] TO PUBLIC;
GO
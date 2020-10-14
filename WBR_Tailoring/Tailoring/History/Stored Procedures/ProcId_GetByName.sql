CREATE PROCEDURE [History].[ProcId_GetByName]
	@procid INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @proc_name VARCHAR(257)
	DECLARE @proc_id INT
	
	SELECT	@proc_name = object_schema_name(syso.[object_id]) + '.' + syso.name
	FROM	sys.objects syso
	WHERE	syso.[object_id] = @procid
	
	IF @proc_name IS NULL
	BEGIN
	    SET @proc_name = ''
	END
	
	SELECT	@proc_id = sp.proc_id
	FROM	History.StoredProcedure sp
	WHERE	sp.proc_name = @proc_name
	
	IF @proc_id IS NULL
	BEGIN
	    INSERT INTO History.StoredProcedure
	      (
	        proc_name
	      )
	    SELECT	@proc_name
	    WHERE	NOT EXISTS (
	         		SELECT	1
	         		FROM	History.StoredProcedure sp
	         		WHERE	sp.proc_name = @proc_name
	         	)
	    
	    IF @@ROWCOUNT > 0
	    BEGIN
	        SET @proc_id = SCOPE_IDENTITY()
	    END
	    ELSE
	    BEGIN
	        SELECT	@proc_id = sp.proc_id
	        FROM	History.StoredProcedure sp
	        WHERE	sp.proc_name = @proc_name
	    END
	END
	
	RETURN @proc_id

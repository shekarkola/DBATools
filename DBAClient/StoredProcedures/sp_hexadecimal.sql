USE [DBAClient]
GO
/****** Object:  StoredProcedure [dbo].[sp_hexadecimal]    Script Date: 10/10/2024 12:03:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  ALTER PROCEDURE [dbo].[sp_hexadecimal]
  (
      @binvalue varbinary(256),
      @hexvalue varchar (514) OUTPUT
  )
  AS
  BEGIN
      DECLARE @charvalue varchar (514)
      DECLARE @i int
      DECLARE @length int
      DECLARE @hexstring char(16)
      SELECT @charvalue = '0x'
      SELECT @i = 1
      SELECT @length = DATALENGTH (@binvalue)
      SELECT @hexstring = '0123456789ABCDEF'

      WHILE (@i <= @length)
      BEGIN
            DECLARE @tempint int
            DECLARE @firstint int
            DECLARE @secondint int

            SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
            SELECT @firstint = FLOOR(@tempint/16)
            SELECT @secondint = @tempint - (@firstint*16)
            SELECT @charvalue = @charvalue + SUBSTRING(@hexstring, @firstint+1, 1) + SUBSTRING(@hexstring, @secondint+1, 1)

            SELECT @i = @i + 1
      END 
      SELECT @hexvalue = @charvalue
  END

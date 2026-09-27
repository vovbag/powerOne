USE [dbTOC_LEAN]
GO

/****** Object:  StoredProcedure [dbo].[rcsw_pro_rep_calc_page]    Script Date: 28.09.2026 1:38:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE
PROCEDURE [dbo].[rcsw_pro_rep_calc_page]
(
	@id_sess varchar(100)='', --id_Sess
	@id_buyer varchar(30)='', --id_user

	@xid int=0,
	@stype varchar(150)='',
	--@xip varchar(100)='',
	@xparam1 varchar(150)='0',
	@xparam2 varchar(150)='0',
	@xparam3 varchar(150)='0'--,
	--@zrest varchar(2000)=''
)
AS

SET XACT_ABORT ON
SET NOCOUNT ON; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  ;

	DECLARE @code int=1, @SQLString varchar(max)='', @ps int
	--DECLARE @dataType varchar(150)='ДДС', @iDataType int=1,  
	DECLARE @iPeriod int,@id_dv_profit int=CONVERT(int,@xparam2), @id_dv_balance int=CONVERT(int,@xparam3)

	IF (@id_sess<>'') 
	BEGIN
		print 'sess'
		IF dbo.CheckSessBuyer(@id_sess, @id_buyer)=1
		BEGIN
			IF 1=1
			BEGIN

				IF (@stype='main')
				BEGIN
					--print 'company'
					SELECT 
					1 as code,
					[Page] = (SELECT
								id_hash as id,
								(SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=2) as id_dvBal,
								(SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=1) as id_dvProfit,
								bc.comp_name as comp_name,
								bc.id_company as id_comp
							FROM rc_bank_company bc
							WHERE comp_visible=1 AND (bc.id_buyer = CONVERT(int,@id_buyer) OR ISNULL(bc.id_buyer,0)=0)
							AND bc.id_hash=@xid
							FOR JSON PATH
							) , 
					dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_calc_page.html' as tmp,
					'twig' as tmpType
				END

				IF (@stype='content')
				BEGIN
					IF @xid = 0 AND ISNUMERIC(@xparam1) = 1  SET @xid = CONVERT(int,@xparam1)
					--print @xid

					SELECT
						@id_dv_balance=ISNULL((SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=2),0),
						@id_dv_profit=ISNULL((SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=1),0)
					FROM rc_bank_company bc
					WHERE comp_visible=1 AND (bc.id_buyer = CONVERT(int,@id_buyer) OR ISNULL(bc.id_buyer,0)=0)
					AND bc.id_hash=@xid

					IF @xid = 0 OR @id_dv_profit=0 OR @id_dv_balance=0  
					BEGIN
						SELECT @code as code,
								[Page]='[]',--'[{"dataType":"'+@dataType+'"}]',
								dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_empty.html' as tmp,
								'twig' as tmpType

					END ELSE
					BEGIN
						SELECT TOP 1 @ps=CASE periodType WHEN 'Год' THEN 365 WHEN 'Полугодие' THEN 181 WHEN 'Квартал' THEN 90 ELSE 30 END, 
									 @iPeriod=(tgt.[period])
						FROM [pro_dataVariantContent] tgt 
						WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]='Revenue'
						ORDER BY tgt.[period] DESC

						SELECT @SQLString=
							'{"Operating_Profit":'+CONVERT(varchar(max), CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('Operating_Profit', @id_dv_profit, @iPeriod, '') ))+','
							--+'"Operating_Profit_str":"'+dbo.floatToStr(CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('Operating_Profit', @id_dv_profit, @iPeriod, '') ), 2)+'",'
							+'"Revenue":'+CONVERT(varchar(max), CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')))+','
							--+'"Operating_Cash_Flow":'+CONVERT(varchar(max), CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')- [dbo].[pro_getDiffBySID]('AccountsReceivable', @id_dv_balance, @iPeriod, '')))+','
							--+'"Gross_Margin_prc":'+CONVERT(varchar(max), CONVERT(decimal(18,2),CASE WHEN [dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')<> 0 THEN ([dbo].[pro_getValBySID]('Gross_Margin', @id_dv_profit, @iPeriod, '') / [dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')) ELSE 1 END ))+','
							--/*Валовая прибыль % 8,9*/
							+'"COGS":'+CONVERT(varchar(max), CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('COGS', @id_dv_profit, @iPeriod, '')))+','
							/*TVC*/
							+'"Overheads":'+CONVERT(varchar(max), (-1)*CONVERT(decimal(18,0),[dbo].[pro_getValBySID]('Overheads', @id_dv_profit, @iPeriod, '')))+','
							/*Overheads*/
							--+'"cntDay":'+CONVERT(varchar(max),@ps)+','
							--/*количество дней*/
							/*+'"workCapitalPer100":'+CONVERT(varchar(max),CONVERT(decimal(18,2),ABS(
							Рабочий капитал на 100 руб. 6,7	(CASE WHEN [dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')<> 0 THEN (([dbo].[pro_getValBySID]('Inventory', @id_dv_balance, @iPeriod, '')+[dbo].[pro_getValBySID]('AccountsReceivable', @id_dv_balance, @iPeriod, '')-[dbo].[pro_getValBySID]('AccountsPayable', @id_dv_balance, @iPeriod, '')) / [dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')) ELSE 1 END)
							--																)))+','*/
							/*+'"Net_Cash_Flow":'+CONVERT(varchar(max), CONVERT(decimal(18,0),
							Net Cash Flow 42,43										[dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')+(-1)* ABS([dbo].[pro_getValBySID]('COGS', @id_dv_profit, @iPeriod, ''))
																						+(-1)*(ABS([dbo].[pro_getValBySID]('Overheads', @id_dv_profit, @iPeriod, '')) - ABS([dbo].[pro_getValBySID]('DepreciationAmortisation', @id_dv_profit, @iPeriod, '')))
																						+(-1)* ABS([dbo].[pro_getValBySID]('DepreciationAmortisation', @id_dv_profit, @iPeriod, ''))
																						+(-1)* ABS([dbo].[pro_getValBySID]('InterestPaid', @id_dv_profit, @iPeriod, ''))
																						+[dbo].[pro_getValBySID]('ExtraordinaryIncome_Expenses', @id_dv_profit, @iPeriod, '')+(-1)* ABS([dbo].[pro_getValBySID]('DividendsPaid', @id_dv_profit, @iPeriod, ''))
																							))+',' */
							/*+'"Net_Cash_Flow_str":"'+dbo.floatToStr( CONVERT(decimal(18,0),
							Net Cash Flow 42,43									[dbo].[pro_getValBySID]('Revenue', @id_dv_profit, @iPeriod, '')+(-1)* ABS([dbo].[pro_getValBySID]('COGS', @id_dv_profit, @iPeriod, ''))
																						+(-1)*(ABS([dbo].[pro_getValBySID]('Overheads', @id_dv_profit, @iPeriod, '')) - ABS([dbo].[pro_getValBySID]('DepreciationAmortisation', @id_dv_profit, @iPeriod, '')))
																						+(-1)* ABS([dbo].[pro_getValBySID]('DepreciationAmortisation', @id_dv_profit, @iPeriod, ''))
																						+(-1)* ABS([dbo].[pro_getValBySID]('InterestPaid', @id_dv_profit, @iPeriod, ''))
																						+[dbo].[pro_getValBySID]('ExtraordinaryIncome_Expenses', @id_dv_profit, @iPeriod, '')+(-1)* ABS([dbo].[pro_getValBySID]('DividendsPaid', @id_dv_profit, @iPeriod, ''))
																							), 2)+'"'*/	
							+'"a":"1"}'

						SELECT 
							1 as code,
							[Page] = '['+@SQLString+']', 
							dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_calc_page_content.html' as tmp,
							'twig' as tmpType
						--Net Cash Flow Operating Profit
				
					/*
	Price Increase % 1 % 51,690 66,120
	Volume Increase % 1 % -4,855 19,175
	COGS Reduction % 1 % 56,545 46,945
	Overheads Reduction % 1 % 12,162 12,162
	Reduction in Accounts Receivable Days 1 days 18,115
	Reduction in Inventory Days 1 days 12,862
	Increase in Accounts Payable Days
					*/
					END --@xid = 0 OR @id_dv_profit=0 OR @id_dv_balance=0
				END--content
			END  ELSE 
				SELECT @code=-2, @SQLString = 'Ошибка: Нет данных.'
		END ELSE 
		BEGIN
			SET @code=-1
			SET @SQLString = 'Сессия завершена ранее. '
		END
	END ELSE
	BEGIN
		SET @code=-1
		SET @SQLString = 'Нет номера сессии. '
	END
	
	--INSERT INTO rcw_LogQuery (proc_name,BuyerC,db,code,descr )VALUES ('query', @usname, @itype,@code,@usname +'/'+@id_sess +'/'+@query+'/'+convert(varchar,@itype)+'/'+substring(@SQLString,1,250) )
	IF (@code<1)
	BEGIN
		--SET @code=-1
		SELECT @code as code, @SQLString as Error
	END
	



GO



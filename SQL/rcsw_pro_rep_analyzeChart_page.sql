USE [dbTOC_LEAN]
GO

/****** Object:  StoredProcedure [dbo].[rcsw_pro_rep_analyzeChart_page]    Script Date: 28.09.2026 1:39:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE
PROCEDURE [dbo].[rcsw_pro_rep_analyzeChart_page]
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
	BEGIN TRAN 
	DECLARE @code int=1, @SQLString varchar(250)='', @ps int, @iPeriod int, @id_dvc int, @cnt int
	DECLARE @dataType varchar(150)='ДДС', @iDataType int=1, @id_dv_profit int=CONVERT(int,@xparam2), @id_dv_balance int=CONVERT(int,@xparam3)
	DECLARE @hiNode1 varchar(max)='',  @hiSeries1 varchar(max)=''

	IF (@id_sess<>'') 
	BEGIN
		IF dbo.CheckSessBuyer(@id_sess, @id_buyer)=1
		BEGIN
			IF 1=1
			BEGIN
				IF (@stype='sankeyDDS')
				BEGIN 
					SELECT
						1 as code,
						[Page]= '[{'
									+'"Sankey":{'
									+'"name":"Структура ДДС",'
									+'"profit":{"hinodes":"'+ ISNULL(@hiNode1,'[]')+'","hiseries":"'+ ISNULL(@hiSeries1,'[]')+'"}'
									+'},'
								+'"a":1}]',
						dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_sankey.html' as tmp,
						'twig' as tmpType
				END
				---------sankey-----------------------
				IF (@stype='sankeyFlow')
				BEGIN 
					--print 'sankey--->'  
					/*profit*/
					SELECT @id_dv_profit=id_dv, @iPeriod=dv.periodCount 
					FROM rc_bank_company bc
					INNER JOIN pro_dataVariant dv ON dv.id_comp=bc.id_company AND iDataType=1--profit
					WHERE comp_visible=1 AND (bc.id_buyer = @id_buyer OR ISNULL(bc.id_buyer,0)=0)
					AND bc.id_hash=@xid
					
					/*balance*/
					SELECT @id_dv_balance=id_dv 
					FROM rc_bank_company bc
					INNER JOIN pro_dataVariant dv ON dv.id_comp=bc.id_company AND iDataType=2--balance
					WHERE comp_visible=1 AND (bc.id_buyer = @id_buyer OR ISNULL(bc.id_buyer,0)=0)
					AND bc.id_hash=@xid

					IF @id_dv_profit>0 AND @id_dv_balance >0
					BEGIN
						-- SELECT @sankeyNode
						SELECT @hiNode1=
							(
							SELECT * FROM (
								SELECT  DISTINCT
									var_name as id,
									TRIM(var_source) as [name],
									 ABS(direct)-1 as [column],--direct
									 ISNULL(vOffset, 0) as offsetVertical, 
									 ISNULL(sa.color, CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END)  as color, iSort
								FROM  [pro_reportSankey] sa
								LEFT JOIN pro_vocabulary pv ON ((pv.var_name=[target] AND direct<0) OR (pv.var_name=[source] AND direct>0)) AND lang='RU'
								WHERE sa.san_type='flow' AND sa.visible=1 --AND pv.var_name IN ('Equity','NetDebt', 'WorkingCapital','OtherCapital','Balance') AND lang='RU'
								UNION 
								SELECT  
									'Balance' as id,
									'Чистые операционные активы' as [name],
									 3 as [column],--direct
									 0 as offsetVertical, 
									 '#889DE0'  as color, /**/
									 250 as iSort
								
							) as tt
							ORDER BY iSort
							FOR JSON AUTO
							)
						SELECT @hiNode1=REPLACE(@hiNode1,'\r\n','')
						SELECT @hiNode1=REPLACE(@hiNode1,'"id"','id')
						SELECT @hiNode1=REPLACE(@hiNode1,'"name"','name')
						SELECT @hiNode1=REPLACE(@hiNode1,'"column"','column')
						SELECT @hiNode1=REPLACE(@hiNode1,'"color"','color')
						--SELECT @hiNode1=REPLACE(@hiNode1,'id:"Equity",','id:"Equity", level:5, offsetVertical: 60,')
						SELECT @hiNode1=REPLACE(@hiNode1,'}',', dataLabels : {format:''{point.name}<br>{point.sum} тыс. руб.''}}')
						SELECT @hiNode1=REPLACE(@hiNode1,'"','''')
						--'dataLabels : {	format: ''{point.name}<br>{point.sum} тыс. руб.''}' as
						SELECT @hiSeries1=(
							SELECT color, [from], [to], CONVERT(decimal(18,0), [weight]) as [weight], iSort 
							FROM (
								/*SELECT '#FBA1A1' as color,
									'Equity' as [from], 
									'Balance'  as [to], 
									 ABS( [dbo].[pro_getValBySID]('Equity', @id_dv_balance, @iPeriod, '')) /1000   as [weight]
								UNION */
								SELECT  
									ISNULL(sa.color, CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END ) as color,
									sa.[source] as [from], 
									ISNULL(sa.[target],'Balance') as [to], 
									CONVERT(int,CASE WHEN sa.direct > 0 THEN ISNULL(ABS(d.[value]),0)/1000 ELSE ISNULL(ABS(d1.[value]),0)/1000 END ) as [weight],
									sa.iSort
								FROM pro_reportSankey sa
								left JOIN [dbo].[pro_dataVariantContent] d ON sa.[source]=d.[sid] AND d.id_dv=@id_dv_balance AND d.[period]=@iPeriod 
								left JOIN [dbo].[pro_dataVariantContent] d1 ON sa.[target]=d1.[sid] AND d1.id_dv=@id_dv_balance AND d1.[period]=@iPeriod 
								WHERE sa.san_type='flow' AND sa.visible=1 AND (d.[sid] IS NOT NULL OR  d1.[sid] IS NOT NULL)
								UNION
								SELECT '#FBA1A1' as color,
									'General_liability' as [from], 
									'NetDebt'  as [to], 
									 ABS( [dbo].[pro_getValBySID]('BankLoans_Current', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('BankLoans_NonCurrent', @id_dv_balance, @iPeriod, '')
										 - [dbo].[pro_getValBySID]('Cash', @id_dv_balance, @iPeriod, '')) /1000   as [weight],
									210 as iSort
								UNION
								SELECT '#FBA1A1' as color,
									'NetDebt' as [from], 
									'Balance'  as [to], 
									 ABS( [dbo].[pro_getValBySID]('BankLoans_Current', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('BankLoans_NonCurrent', @id_dv_balance, @iPeriod, '')
										 - [dbo].[pro_getValBySID]('Cash', @id_dv_balance, @iPeriod, '')) /1000   as [weight],
									220 as iSort
								UNION
								SELECT '#88E09D' as color,
									'Balance'  as [from], 
									'WorkingCapital' as [to], 
									 ABS( [dbo].[pro_getValBySID]('AccountsReceivable', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('Inventory', @id_dv_balance, @iPeriod, '')
										 - [dbo].[pro_getValBySID]('AccountsPayable', @id_dv_balance, @iPeriod, '')) /1000   as [weight],
									230 as iSort 
								UNION
								SELECT '#88E09D' as color,
									'WorkingCapital'  as [from], 
									'CurrentAssets' as [to], 
									 ABS( [dbo].[pro_getValBySID]('AccountsReceivable', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('Inventory', @id_dv_balance, @iPeriod, '')
										 - [dbo].[pro_getValBySID]('AccountsPayable', @id_dv_balance, @iPeriod, '')) /1000   as [weight],
									240 as iSort 
								UNION
								SELECT '#88E09D' as color,
									'Balance'  as [from], 
									'OtherCapital' as [to], 
									 ABS( [dbo].[pro_getValBySID]('FixedAssets', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('OtherCurrentAssets', @id_dv_balance, @iPeriod, '')
										 + [dbo].[pro_getValBySID]('OtherNonCurrentAssets', @id_dv_balance, @iPeriod, '')
										 - ([dbo].[pro_getValBySID]('OtherCurrentLiabilities', @id_dv_balance, @iPeriod, '')
											+[dbo].[pro_getValBySID]('OtherNonCurrentLiabilities', @id_dv_balance, @iPeriod, '')
											)) /1000   as [weight],
									600 as iSort 
							) as tt
							ORDER BY iSort
							FOR JSON AUTO
						) --id:"Equity",
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"color"','color')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"from"','from')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"to"','to')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"weight"','weight')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"','''')
						--SELECT @sankeyedges
						--print @hiNode1
						SELECT
							1 as code,
							[Page]= '[{'
										+'"Sankey":{'
										+'"name":"Структура чистых операционных активов",'
										+'"profit":{"hinodes":"'+ ISNULL(@hiNode1,'[]')+'","hiseries":"'+ ISNULL(@hiSeries1,'[]')+'"}'
										+'},'
									+'"a":1}]',
							dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_sankey.html' as tmp,
							'twig' as tmpType
					--FROM [pro_dataVariantContent] ttt
					--WHERE id_dv=@id_dv_profit AND [period]=@iPeriod AND id_dvc=@id_dvc
					END ELSE SELECT @code=-3, @SQLString = 'Ошибка: Нет данных.'
				END ---------sankey-----------------------

				IF (@stype='sankeyProfit')
				BEGIN ---------sankey-----------------------
					--print 'sankey--->'  
					
					/*profit*/
					SELECT @id_dv_profit=id_dv, @iPeriod=dv.periodCount 
					FROM rc_bank_company bc
					INNER JOIN pro_dataVariant dv ON dv.id_comp=bc.id_company AND iDataType=1--profit
					WHERE comp_visible=1 AND (bc.id_buyer = @id_buyer OR ISNULL(bc.id_buyer,0)=0)
					AND bc.id_hash=@xid
					
					IF @id_dv_profit>0  
					BEGIN
						-- SELECT @sankeyNode
						SELECT @hiNode1=
						(SELECT var_name as id, 
								TRIM(var_source) as [name],
								ABS(direct)-1 as [column],
								ISNULL(sa.vOffset, ABS(direct)*7) as offsetVertical,
							
								CASE WHEN ABS(direct)<1 THEN '#889DE0'
									ELSE CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END 
								END as color --,*  
						FROM  [pro_reportSankey] sa
						INNER JOIN pro_vocabulary pv ON ((pv.var_name=[target] AND direct<0) OR (pv.var_name=[source] AND direct>0)) AND lang='RU'
						WHERE sa.san_type='2' AND (sa.visible=1 OR sa.[source]='Net_Profit')
						FOR JSON AUTO
						)
						SELECT @hiNode1=REPLACE(@hiNode1,'\r\n','')
						SELECT @hiNode1=REPLACE(@hiNode1,'"id"','id')
						SELECT @hiNode1=REPLACE(@hiNode1,'"name"','name')
						SELECT @hiNode1=REPLACE(@hiNode1,'"column"','column')
						SELECT @hiNode1=REPLACE(@hiNode1,'"color"','color')
						--SELECT @hiNode1=REPLACE(@hiNode1,'id:"Equity",','id:"Equity", level:5, offsetVertical: 60,')
						SELECT @hiNode1=REPLACE(@hiNode1,'}',', dataLabels : {format:''{point.name}<br>{point.sum} тыс. руб.''}}')
						SELECT @hiNode1=REPLACE(@hiNode1,'"','''')
						--'dataLabels : {	format: ''{point.name}<br>{point.sum} тыс. руб.''}' as
						SELECT @hiSeries1=(
							SELECT --sa.direct,sa.*,
							--ISNULL(ABS(d.[value]),0)/1000 , ISNULL(ABS(d1.[value]),0)/1000,
								--CASE WHEN sa.direct>0 THEN '#ffee37' ELSE '#00BB00' END as color,
								CASE WHEN sa.[target]='Equity' THEN '#889DE0'
									ELSE CASE WHEN d1.[value]<0 THEN '#FBA1A1'
											WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END 
								END as color,
								sa.[source] as [from], 
								ISNULL(sa.[target],'Balance') as [to], 
								CONVERT(int,CASE WHEN sa.direct IN (1) THEN ISNULL(ABS(d.[value]),0)/1000 ELSE ISNULL(ABS(d1.[value]),0)/1000 END ) as [weight]
							FROM pro_reportSankey sa
							LEFT JOIN [dbo].[pro_dataVariantContent] d ON sa.[source]=d.[sid] AND d.id_dv=@id_dv_profit AND d.[period]=@iPeriod 
							LEFT JOIN [dbo].[pro_dataVariantContent] d1 ON sa.[target]=d1.[sid] AND d1.id_dv=@id_dv_profit AND d1.[period]=@iPeriod 
							WHERE sa.san_type='2' AND sa.visible=1
							FOR JSON AUTO
						) --id:"Equity",
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"color"','color')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"from"','from')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"to"','to')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"weight"','weight')
						SELECT @hiSeries1=REPLACE(@hiSeries1,'"','''')
						--SELECT @sankeyedges
						--print @hiNode1
						SELECT
							1 as code,
							[Page]= '[{'
										+'"Sankey":{'
										+'"name":"Структура прибыли",'
										+'"profit":{"hinodes":"'+ ISNULL(@hiNode1,'[]')+'","hiseries":"'+ ISNULL(@hiSeries1,'[]')+'"}'
										+'},'
									+'"a":1}]',
							dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_sankey.html' as tmp,
							'twig' as tmpType
						--FROM [pro_dataVariantContent] ttt
						--WHERE id_dv=@id_dv_profit AND [period]=@iPeriod AND id_dvc=@id_dvc
					END ELSE SELECT @code=-3, @SQLString = 'Ошибка: Нет данных.'
				END ---------sankey-----------------------
				
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
	COMMIT TRAN 
	--INSERT INTO rcw_LogQuery (proc_name,BuyerC,db,code,descr )VALUES ('query', @usname, @itype,@code,@usname +'/'+@id_sess +'/'+@query+'/'+convert(varchar,@itype)+'/'+substring(@SQLString,1,250) )
	IF (@code<1)
	BEGIN
		--SET @code=-1
		SELECT @code as code, @SQLString as Error
	END
	



GO



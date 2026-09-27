USE [dbTOC_LEAN]
GO

/****** Object:  StoredProcedure [dbo].[rcsw_pro_rep_powerone_page]    Script Date: 28.09.2026 1:36:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE
PROCEDURE [dbo].[rcsw_pro_rep_powerone_page]
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

	IF (@id_sess<>'') 
	BEGIN
		IF dbo.CheckSessBuyer(@id_sess, @id_buyer)=1
		BEGIN
			IF 1=1
			BEGIN
				IF (@stype='main')
				BEGIN
				--company
					SELECT 
					1 as code,
					[Page] = (SELECT
								id_hash as id,
								(SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=2) as id_dvBal,
								(SELECT TOP 1 id_dv FROM pro_dataVariant p WHERE p.visible=1 AND p.id_comp = bc.id_company AND [iDataType]=1) as id_dvProfit,
								bc.comp_name as comp_name,
								bc.id_company as id_comp
							FROM rc_bank_company bc
							WHERE comp_visible=1 AND (bc.id_buyer = @id_buyer OR ISNULL(bc.id_buyer,0)=0)
							AND bc.id_hash=@xid
							FOR JSON PATH
							) , 
					dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_page.html' as tmp,
					'twig' as tmpType
				END

				IF (@stype='content')
				BEGIN

					IF @xid = 0 AND ISNUMERIC(@xparam1) = 1  SET @xid = CONVERT(int,@xparam1)
					--print @xid
					IF 1=1 --@xid = 0 OR @id_dv_profit=0 OR @id_dv_balance=0 --NOT EXISTS(SELECT id_dv FROM [pro_dataVariantContent] tgt WHERE tgt.id_dv=@xid)
					BEGIN
						SELECT @code as code,
								[Page]='[]',--'[{"dataType":"'+@dataType+'"}]',
								dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_empty.html' as tmp,
								'twig' as tmpType

					END 
				END

				IF (@stype='sankey')
				BEGIN ---------sankey-----------------------
					--print 'sankey--->'  
					DECLARE @hiNode1 varchar(max)='',  @hiSeries1 varchar(max)=''

					SELECT @id_dv_profit=id_dv, @iPeriod=dv.periodCount 
					FROM rc_bank_company bc
					INNER JOIN pro_dataVariant dv ON dv.id_comp=bc.id_company AND iDataType=1--profit
					WHERE comp_visible=1 AND (bc.id_buyer = @id_buyer OR ISNULL(bc.id_buyer,0)=0)
					AND bc.id_hash=@xid
					/*profit*/
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
								ELSE CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END 
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
									+'"profit":{"hinodes":"'+ ISNULL(@hiNode1,'[]')+'","hiseries":"'+ ISNULL(@hiSeries1,'[]')+'"}'
									+'},'
								+'"a":1}]',
						dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_sankey.html' as tmp,
						'twig' as tmpType
					--FROM [pro_dataVariantContent] ttt
					--WHERE id_dv=@id_dv_profit AND [period]=@iPeriod AND id_dvc=@id_dvc
				END ---------sankey-----------------------

				IF (@stype='variant')
				BEGIN
					IF  EXISTS(SELECT id_dv FROM pro_dataVariant tgt WHERE visible=1 AND id_comp=@xid )
					BEGIN
						SELECT 
						1 as code,
						[Page] = (SELECT
									@xid as id,
									'' as [name],
									'' as descr,
									'selected' as sel1,
									''  as sel2,
									JSON_QUERY( (SELECT id_dv as id, [name] as [name] FROM pro_dataVariant b WHERE b.visible=1 AND b.id_comp=@xid AND b.iDataType = 1 FOR JSON AUTO),'$') as profit,
									JSON_QUERY( (SELECT id_dv as id, [name] as [name] FROM pro_dataVariant b WHERE b.visible=1 AND b.id_comp=@xid AND b.iDataType = 2 FOR JSON AUTO),'$') as balance,
									'[]' as [period],
									'Выберите организацию' as comp_name,
									'0' as id_comp
								FOR JSON PATH
								)
					END ELSE BEGIN
						SELECT 
						1 as code,
						[Page] = (SELECT
									@xid as id,
									'' as [name],
									'' as descr,
									'selected' as sel1,
									''  as sel2,
									JSON_QUERY( '[]','$') as profit,
									JSON_QUERY( '[]','$') as balance,
									'[]' as [period],
									'Выберите организацию' as comp_name,
									'0' as id_comp
								FOR JSON PATH
								)
					END
				END
				
				IF (@stype='mainVariant')
				BEGIN
						SELECT 
						1 as code,
						[Page] = (SELECT
									'Изменить' as make,
									id_dv as id,
									[name],
									descr,
									CASE WHEN iDataType=1  THEN 'selected' ELSE '' END as sel1,
									CASE WHEN iDataType=2  THEN 'selected' ELSE '' END as sel2,
									JSON_QUERY( (SELECT id_company as id, comp_name as [name] FROM rc_bank_company b WHERE b.comp_visible=1 AND b.id_buyer = @id_buyer FOR JSON AUTO),'$') as companies1,
									JSON_QUERY( (SELECT id_company as id, comp_name as [name] FROM rc_bank_company b WHERE b.comp_visible=1 AND b.id_buyer = 0 FOR JSON AUTO),'$') as companies2,
									comp_name as comp_name,
									id_comp
								FROM pro_dataVariant p
								INNER JOIN rc_bank_company bc On bc.id_company=p.id_comp
								WHERE visible=1 AND p.id_dv=@xid 
								FOR JSON PATH
								) , 
						dbo.getGlobals('path_tmp_real')+'pages\pro\spr_rawdata_form.html' as tmp,
						'twig' as tmpType
				END
				
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



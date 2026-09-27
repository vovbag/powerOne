USE [dbTOC_LEAN]
GO

/****** Object:  StoredProcedure [dbo].[rcsw_pro_rep_analyze_page]    Script Date: 28.09.2026 1:40:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE
PROCEDURE [dbo].[rcsw_pro_rep_analyze_page]
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
				

				IF (@stype='content')
				BEGIN
					DECLARE @columns VARCHAR(MAX)='', @table VARCHAR(MAX)='', @table1 VARCHAR(MAX)='', @table2 VARCHAR(MAX)='', @table3 VARCHAR(MAX)='', @table4 VARCHAR(MAX)='', 
							@periodList VARCHAR(MAX)='', @table_bal VARCHAR(MAX)='', @table_balOper VARCHAR(MAX)='', @table_bal1 VARCHAR(MAX)='', @table_bal2 VARCHAR(MAX)='', @table_bal3 VARCHAR(MAX)='', 
							@cash VARCHAR(MAX)='', @BankLoans_Current VARCHAR(MAX)='', @BankLoans_NonCurrent VARCHAR(MAX)='', 
							@table_cash VARCHAR(MAX)='', @table_cash1 VARCHAR(MAX)='', @table_cash2 VARCHAR(MAX)='', @table_cash3 VARCHAR(MAX)='',

							@profibility_main VARCHAR(MAX)='', @profibility_table VARCHAR(MAX)='', @profibility_chart VARCHAR(MAX)='', 
							@tableCapitalPer100 varchar(max)='', @capital_chart VARCHAR(MAX)='',
							@table_other VARCHAR(MAX)='',  @other_chart VARCHAR(MAX)='',
							@table_funding VARCHAR(MAX)='',  @funding_chart VARCHAR(MAX)='',
							
							@diff decimal(18,2)=0, @diff1 decimal(18,2)=0, @diff2 decimal(18,2)=0, @diff3 decimal(18,2)=0, 
							@diff_bal decimal(18,2)=0, @diff_bal1 decimal(18,0)=0, @diff_bal2 decimal(18,0)=0, @diff_bal3 decimal(18,0)=0,
							@diff_cash decimal(18,2)=0, @diff_cash1 decimal(18,0)=0, @diff_cash2 decimal(18,0)=0, @diff_cash3 decimal(18,0)=0

					IF @xid = 0 AND ISNUMERIC(@xparam1) = 1  SET @xid = CONVERT(int,@xparam1)
					--print @xid
					IF @xid = 0 OR @id_dv_profit=0 OR @id_dv_balance=0 --NOT EXISTS(SELECT id_dv FROM [pro_dataVariantContent] tgt WHERE tgt.id_dv=@xid)
					BEGIN
						SELECT @code as code,
								[Page]='[]',--'[{"dataType":"'+@dataType+'"}]',
								dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content_empty.html' as tmp,
								'twig' as tmpType

					END ELSE
					BEGIN
						SELECT TOP 1 @ps=CASE periodType WHEN 'Год' THEN 365 WHEN 'Полугодие' THEN 181 WHEN 'Квартал' THEN 90 ELSE 30 END, 
									 @iDataType=(tgt.idataType), @id_dvc=(tgt.id_dvc),  
									 @cnt=(tgt.[period]),@iPeriod=(tgt.[period])
						FROM [pro_dataVariantContent] tgt 
						WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]='Revenue'
						ORDER BY tgt.[period] DESC

						--print @id_dv_profit
						--print @id_dv_balance
						--summary--profit
						SELECT 
							   @columns =STRING_AGG([dbo].[pro_getPeriodName](tgt.periodType, tgt.stdate),'</th><th class="text-center">')  WITHIN GROUP ( ORDER BY  tgt.[period]),

							   @profibility_chart=STRING_AGG([dbo].[pro_getPeriodName](tgt.periodType, tgt.stdate),'","')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   
							   @table = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table1 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt.[value] <> 0 THEN tgt1.[value] / tgt.[value] ELSE 1 END)*100
																								)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table2 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
								/*Operating_Profit 0,1*/		(CASE WHEN tgt.[value] <> 0 THEN tgt2.[value] / tgt.[value] ELSE 1 END)*100
																								)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),	
							   @table3 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt.[value] <> 0 THEN (tgt3.[value])/ tgt.[value] ELSE 1 END)*100
																								)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table4  = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt.[value] <> 0 THEN (tgt4.[value])/ tgt.[value] ELSE 1 END)*100
																								)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table_cash1 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt.[value]-tgt.diff <> 0 THEN (tgt.diff)/ (tgt.[value]-tgt.diff) ELSE 0 END)*100
																								))+','
														  +CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt5.[value]-tgt5.diff <> 0 THEN (tgt5.diff)/ (tgt5.[value]-tgt5.diff) ELSE 0 END)*100
																								))+','
														  +CONVERT(varchar(100), CONVERT(decimal(18,2),
																(CASE WHEN tgt6.[value]-tgt6.diff <> 0 THEN (tgt6.diff)/ (tgt6.[value]-tgt6.diff) ELSE 0 END)*100
																								))
														,',')  WITHIN GROUP ( ORDER BY  tgt.[period])


						FROM [pro_dataVariantContent] tgt 
						LEFT JOIN [pro_dataVariantContent] tgt1 ON tgt1.id_dv=tgt.id_dv AND tgt1.[sid]='Gross_Margin'  AND tgt1.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt2 ON tgt2.id_dv=tgt.id_dv AND tgt2.[sid]='Operating_Profit'  AND tgt2.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt3 ON tgt3.id_dv=tgt.id_dv AND tgt3.[sid]='Net_Profit'  AND tgt3.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt4 ON tgt4.id_dv=tgt.id_dv AND tgt4.[sid]='Net_Profit_Before_Tax'  AND tgt4.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt5 ON tgt5.id_dv=tgt.id_dv AND tgt5.[sid]='COGS'  AND tgt5.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt6 ON tgt6.id_dv=tgt.id_dv AND tgt6.[sid]='Overheads'  AND tgt6.[period]=tgt.[period]
						--LEFT JOIN [pro_dataVariantContent] tgt2 ON tgt2.id_dv=tgt.id_dv AND tgt2.[sid]='Operating_Profit'
						WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]='Revenue'  AND tgt.[period]> @cnt-2

						--считаем profitility------------------------------------------->
						--print @profibility_chart
						--print 1111
						SELECT @profibility_main=(
									SELECT
 										ISNULL(tmp.[NameRU],tmp.[Name]) as title,
										dbo.FloatToStr(tgt.[value],2) as snt,
										tgt.[value] as snt1, --current (last) value
										CASE WHEN tgt.[diff]>0 THEN 'success' ELSE 'danger' END as color,
										dbo.FloatToStr(tgt.[diff],2) as prc
									FROM [pro_dataVariantContent] tgt
									INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
									WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]IN('Revenue','Gross_Margin','Operating_Profit','Net_Profit_Before_Tax','Retained_Profit')  
										  AND tgt.[period]=@iPeriod
									ORDER BY tmp.sort
									FOR JSON PATH
								)
						--print @profibility_main
						--print 222
						SELECT @table_cash =STRING_AGG( ISNULL(tmp.[NameRU],tmp.[Name])+' %',''',''')  WITHIN GROUP ( ORDER BY  tmp.sort)
						FROM pro_dataVariantContentTMP tmp 
						WHERE tmp.visible=1 AND tmp.[sid]IN( 'Gross_Margin','Operating_Profit','Net_Profit_Before_Tax','Net_Profit') 
						--print @table_cash
						SELECT @table_cash2 =STRING_AGG( ISNULL(tmp.[NameRU],tmp.[Name])+' %','","')  WITHIN GROUP ( ORDER BY  tmp.sort)
						FROM pro_dataVariantContentTMP tmp 
						WHERE tmp.visible=1 AND tmp.[sid]IN( 'Revenue','COGS','Overheads' ) 
						--print @table_cash2
						select @profibility_chart='{"group":"'''+@table_cash+'''",'
											    +'"name1":"'+JSON_VALUE('["'+@profibility_chart+'"]','$[0]')+'",'
												+'"snt1":"' +JSON_VALUE('['+@table1+']','$[0]')+','+JSON_VALUE('['+@table2+']','$[0]')+','+JSON_VALUE('['+@table4+']','$[0]')+','+JSON_VALUE('['+@table3+']','$[0]')+'",'
												+'"name2":"'+JSON_VALUE('["'+@profibility_chart+'"]','$[1]')+'",'
												+'"snt2":"' +JSON_VALUE('['+@table1+']','$[1]')+','+JSON_VALUE('['+@table2+']','$[1]')+','+JSON_VALUE('['+@table4+']','$[1]')+','+JSON_VALUE('['+@table3+']','$[1]')+'",'
												+'"diffvs1":"'+ISNULL(JSON_VALUE('['+@table_cash1+']','$[0]'),'0')+','+ISNULL(JSON_VALUE('['+@table_cash1+']','$[3]'),'0')+'",'
												+'"diffvs2":"'+ISNULL(JSON_VALUE('['+@table_cash1+']','$[1]'),'0')+','+ISNULL(JSON_VALUE('['+@table_cash1+']','$[4]'),'0')+'",'
												+'"diffvs3":"'+ISNULL(JSON_VALUE('['+@table_cash1+']','$[2]'),'0')+','+ISNULL(JSON_VALUE('['+@table_cash1+']','$[5]'),'0')+'",'
												+'"groupvs":"'''+JSON_VALUE('["'+@profibility_chart+'"]','$[0]')+''','''+JSON_VALUE('["'+@profibility_chart+'"]','$[1]')+'''",'
												+'"namevs1":"'+JSON_VALUE('["'+@table_cash2+'"]','$[0]')+'",'
												+'"namevs2":"'+JSON_VALUE('["'+@table_cash2+'"]','$[1]')+'",'
												+'"namevs3":"'+JSON_VALUE('["'+@table_cash2+'"]','$[2]')+'"}'

						--print 1
						SELECT @profibility_table=(
										SELECT * FROM	
											(SELECT
													ISNULL(tmp.[NameRU],tmp.[Name])  as [name],  
													dbo.FloatToStr(tgt.[value],1) as snt1,
 													dbo.FloatToStr(ISNULL(tgt1.[value], tgt.[value]),1) as snt2,
													tgt.[value]  as snt,
													CASE WHEN tgt.[diff]>0 THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr(tgt.[diff],1) as prc,
													'' as txtclass,
													tmp.sort
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 
													AND tgt1.id_dvc = tmp.id_dvc 
												WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]IN('Revenue','Gross_Margin','Operating_Profit','Net_Profit_Before_Tax','Retained_Profit','Overheads','Net_Profit' )  
												AND tgt.[period]=@iPeriod
												UNION 
												SELECT
													ISNULL(tmp.[NameRU],tmp.[Name]) +', <span class="text-primary">%</span>' as [name],  
													dbo.FloatToStr((CASE WHEN tgt2.[value]  <> 0 THEN (tgt.[value])/ (tgt2.[value] ) ELSE 0 END)*100,0) as snt1,
 													dbo.FloatToStr(ISNULL((CASE WHEN tgt3.[value]  <> 0 THEN (tgt1.[value])/ (tgt3.[value]) ELSE 0 END)*100, 0),0) as snt2,
													tgt.[value]  as snt,
													CASE WHEN (CASE WHEN tgt2.[value]  <> 0 THEN (tgt.[value])/ (tgt2.[value] ) ELSE 0 END)*100
																-ISNULL((CASE WHEN tgt3.[value] <> 0 THEN (tgt1.[value])/ (tgt3.[value]) ELSE 0 END)*100, 0)>0 
															THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr((CASE WHEN tgt2.[value]  <> 0 THEN (tgt.[value])/ (tgt2.[value] ) ELSE 0 END)*100
																-ISNULL((CASE WHEN tgt3.[value] <> 0 THEN (tgt1.[value])/ (tgt3.[value]) ELSE 0 END)*100, 0)
													,0) as prc,
													'text-primary' as txtclass,
													tmp.sort+1
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												LEFT JOIN pro_dataVariantContent tgt2 ON tgt2.id_dv = tgt.id_dv  AND tgt2.[period]=tgt.[period]-0 AND tgt2.[sid]='Revenue'
												LEFT JOIN pro_dataVariantContent tgt3 ON tgt3.id_dv = tgt.id_dv  AND tgt3.[period]=tgt.[period]-1 AND tgt3.[sid]='Revenue'
												WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]IN('Gross_Margin','Operating_Profit','Net_Profit_Before_Tax','Retained_Profit','Overheads','Net_Profit' )  
												AND tgt.[period]=@iPeriod
												UNION
												SELECT
													ISNULL(tmp.[NameRU],tmp.[Name]) +', <span class="text-primary">%</span>' as [name],  
													dbo.FloatToStr((CASE WHEN tgt.[value]-tgt.diff  <> 0 THEN (tgt.diff)/(tgt.[value]-tgt.diff) ELSE 0 END)*100,0) as snt1,
 													dbo.FloatToStr(ISNULL((CASE WHEN tgt1.[value]-tgt1.diff  <> 0 THEN (tgt1.diff)/ (tgt1.[value]-tgt1.diff) ELSE 0 END)*100, 0),0) as snt2,
													tgt.[value]  as snt,
													CASE WHEN (CASE WHEN tgt.[value]-tgt.diff  <> 0 THEN (tgt.diff)/(tgt.[value]-tgt.diff) ELSE 0 END)*100
																-ISNULL((CASE WHEN tgt1.[value]-tgt1.diff  <> 0 THEN (tgt1.diff)/ (tgt1.[value]-tgt1.diff) ELSE 0 END)*100, 0)>0 
															THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr((CASE WHEN tgt.[value]-tgt.diff  <> 0 THEN (tgt.diff)/(tgt.[value]-tgt.diff) ELSE 0 END)*100
																-ISNULL((CASE WHEN tgt1.[value]-tgt1.diff  <> 0 THEN (tgt1.diff)/ (tgt1.[value]-tgt1.diff) ELSE 0 END)*100, 0)
													,0) as prc,
													'text-primary' as txtclass,
													tmp.sort+1
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]IN('Revenue' )  
												AND tgt.[period]=@iPeriod
												UNION 
												SELECT
													'Коэффициент покрытия процентов, <span class="text-dark">доля</span>' as [name],  
													dbo.FloatToStr(ABS(CASE WHEN tgt2.[value]  <> 0 THEN (tgt.[value])/ (tgt2.[value] ) ELSE 0 END),0) as snt1,
 													dbo.FloatToStr(ISNULL(ABS(CASE WHEN tgt3.[value]  <> 0 THEN (tgt1.[value])/ (tgt3.[value]) ELSE 0 END), 0),0) as snt2,
													tgt.[value]  as snt,
													CASE WHEN ABS(CASE WHEN tgt2.[value]  <> 0 THEN (tgt.[value])/ (tgt2.[value] ) ELSE 0 END)
																-ISNULL(ABS(CASE WHEN tgt3.[value] <> 0 THEN (tgt1.[value])/ (tgt3.[value]) ELSE 0 END), 0)>0 
															THEN 'success' ELSE 'danger' END as color,
													CONVERT(varchar(100),CONVERT(decimal(18,2), ABS(CASE WHEN tgt2.[value]  <> 0 THEN CONVERT(decimal(18,2),(tgt.[value])/ (tgt2.[value] )) ELSE 0 END)
																-ISNULL(ABS(CASE WHEN tgt3.[value] <> 0 THEN CONVERT(decimal(18,2),(tgt1.[value])/ (tgt3.[value])) ELSE 0 END), 0)
													)) as prc,
													'text-dark' as txtclass,
													1000 as sort
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												LEFT JOIN pro_dataVariantContent tgt2 ON tgt2.id_dv = tgt.id_dv  AND tgt2.[period]=tgt.[period]-0 AND tgt2.[sid]='InterestPaid'
												LEFT JOIN pro_dataVariantContent tgt3 ON tgt3.id_dv = tgt.id_dv  AND tgt3.[period]=tgt.[period]-1 AND tgt3.[sid]='InterestPaid'
												WHERE tgt.id_dv=@id_dv_profit AND tgt.[sid]IN('Operating_Profit' )  
												AND tgt.[period]=@iPeriod

												) as tt
									ORDER BY tt.sort
									FOR JSON PATH)
						--считаем profitility-------<


						--summary--balance
						SELECT 
							   --@columns_bal =STRING_AGG([dbo].[pro_getPeriodName](tgt.periodType, tgt.stdate),'</th><th>')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table_balOper = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
																							 ABS((CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt2.[value]*@ps / tgt5.[value]) ELSE 1 END))
																							+ABS((CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt3.[value]*@ps / tgt4.[value]) ELSE 1 END))
																							---ABS((CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt1.[value]*@ps / tgt5.[value]) ELSE 1 END))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							   @table_bal = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
																							 ABS((CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt2.[value]*@ps / tgt5.[value]) ELSE 1 END))
																							+ABS((CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt3.[value]*@ps / tgt4.[value]) ELSE 1 END))
																							-ABS((CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt1.[value]*@ps / tgt5.[value]) ELSE 1 END))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							    @table_bal1 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
																								(CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt1.[value]*@ps / tgt5.[value]) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							    @table_bal2 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
																								(CASE WHEN tgt5.[value] <> 0 THEN FLOOR(tgt2.[value]*@ps / tgt5.[value]) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							    @table_bal3 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
																								(CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt3.[value]*@ps / tgt4.[value]) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),

								@tableCapitalPer100= STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*0,1*/												(CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt2.[value] / tgt4.[value]*100.) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*2,3*/												(CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt3.[value] / tgt4.[value]*100.) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])	
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*4,5*/												(CASE WHEN tgt4.[value] <> 0 THEN FLOOR(tgt1.[value] / tgt4.[value]*100.) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])	
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),(
											/*Рабочий капитал на 100 руб. 6,7*/					(CASE WHEN tgt4.[value] <> 0 THEN ((tgt2.[value]+tgt3.[value]-tgt1.[value]) / tgt4.[value]*100.) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),(
											/*Валовая прибыль 8,9*/								(CASE WHEN tgt4.[value] <> 0 THEN (tgt9.[value] / tgt4.[value]*100.) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),(
											/*Рабочий капитал 10,11*/							(tgt2.[value]+tgt3.[value]-tgt1.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])	
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),(
											/*Оборачиваемость рабочего капитала, год 12,13*/	(CASE WHEN (tgt2.[value]+tgt3.[value]-tgt1.[value]) <> 0 THEN (tgt4.[value]/(tgt2.[value]+tgt3.[value]-tgt1.[value]) ) ELSE 0 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])	
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Коэффициент текущей ликвидности 14,15*/			(CASE WHEN tgt12.[value] <> 0 THEN (tgt11.[value] / tgt12.[value] ) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+','+STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Стоимость финансового цикла в день 16,17*/	(CASE WHEN @ps <> 0 THEN (tgt5.[value] / @ps )+(tgt10.[value] / @ps ) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Оборотные Активы 18,19*/							(tgt2.[value])+(tgt3.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*AccountsReceivable 20,21*/							 (tgt3.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Revenue 22,23*/									(tgt4.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*COGS 24,25*/										(tgt5.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*AccountsPayable 26,27*/							(tgt1.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*Overheads excl Depreciatione 28,29*/				ABS(tgt10.[value]) - ABS(ISNULL(tgt13.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*DepreciationAmortisation 30,31*/				 (-1)* ABS(ISNULL(tgt13.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*InterestPaid 32,33*/					 (-1)* ABS(ISNULL(tgt15.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*TaxPaid 34,35*/						(-1)* ABS(ISNULL(tgt16.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*ExtraordinaryIncome_Expenses 36,37*/			ISNULL(tgt14.[value],0)
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*DividendsPaid 38,39*/					(-1)* ABS(ISNULL(tgt17.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*Retained_Profit 40,41*/					ISNULL(tgt18.[value],0)
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
											+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),
											/*Net Cash Flow 42,43*/						tgt4.[value]+(-1)* ABS(ISNULL(tgt5.[value],0))
																						+(-1)*(ABS(tgt10.[value]) - ABS(ISNULL(tgt13.[value],0)))
																						+(-1)* ABS(ISNULL(tgt13.[value],0))
																						+(-1)* ABS(ISNULL(tgt15.[value],0))
																						+ISNULL(tgt14.[value],0)+(-1)* ABS(ISNULL(tgt17.[value],0))
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
																							,
/**/
--[dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' )+CONVERT( decimal(18,0), JSON_VALUE('['+@tableCapitalPer100+']','$[43]'))
								@table_cash = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt6.[value])+ABS(tgt7.[value])+ABS(tgt8.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
								@table_cash1 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt6.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
								@table_cash2 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt7.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
								@table_cash3 = STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt8.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])

						FROM [pro_dataVariantContent] tgt
						LEFT JOIN [pro_dataVariantContent] tgt1 ON tgt1.id_dv=tgt.id_dv AND tgt1.[sid]='AccountsPayable'  AND tgt1.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt2 ON tgt2.id_dv=tgt.id_dv AND tgt2.[sid]='Inventory'  AND tgt2.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt3 ON tgt3.id_dv=tgt.id_dv AND tgt3.[sid]='AccountsReceivable'  AND tgt3.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt4 ON tgt4.id_dv=@id_dv_profit AND tgt4.[sid]='Revenue'  AND tgt4.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt5 ON tgt5.id_dv=@id_dv_profit AND tgt5.[sid]='COGS'  AND tgt5.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt6 ON tgt6.id_dv=tgt.id_dv AND tgt6.[sid]='Cash'  AND tgt6.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt7 ON tgt7.id_dv=tgt.id_dv AND tgt7.[sid]='BankLoans_Current'  AND tgt7.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt8 ON tgt8.id_dv=tgt.id_dv AND tgt8.[sid]='BankLoans_NonCurrent'  AND tgt8.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt9 ON tgt9.id_dv=@id_dv_profit AND tgt9.[sid]='Gross_Margin'  AND tgt9.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt10 ON tgt10.id_dv=@id_dv_profit AND tgt10.[sid]='Overheads'  AND tgt10.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt11 ON tgt11.id_dv=tgt.id_dv AND tgt11.[sid]='CurrentAssets'  AND tgt11.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt12 ON tgt12.id_dv=tgt.id_dv AND tgt12.[sid]='CurrentLiabilities'  AND tgt12.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt13 ON tgt13.id_dv=tgt.id_dv AND tgt13.[sid]='DepreciationAmortisation'  AND tgt13.[period]=tgt.[period]

						LEFT JOIN [pro_dataVariantContent] tgt14 ON tgt14.id_dv=@id_dv_profit AND tgt14.[sid]='ExtraordinaryIncome_Expenses'  AND tgt14.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt15 ON tgt15.id_dv=@id_dv_profit AND tgt15.[sid]='InterestPaid'  AND tgt15.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt16 ON tgt16.id_dv=@id_dv_profit AND tgt16.[sid]='TaxPaid'  AND tgt16.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt17 ON tgt17.id_dv=@id_dv_profit AND tgt17.[sid]='DividendsPaid'  AND tgt17.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt18 ON tgt18.id_dv=@id_dv_profit AND tgt18.[sid]='Retained_Profit'  AND tgt18.[period]=tgt.[period]
						WHERE tgt.id_dv=@id_dv_balance  AND tgt.[sid]='Equity' AND tgt.[period]> @cnt-2



						--summary--cash
						SELECT @periodList = STRING_AGG([dbo].[pro_getPeriodName](tgt.periodType, tgt.stdate),''',''')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							  @cash=STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							  @BankLoans_Current=STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt1.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]),
							  @BankLoans_NonCurrent=STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(tgt2.[value]))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
						FROM [pro_dataVariantContent] tgt
						LEFT JOIN [pro_dataVariantContent] tgt1 ON tgt1.id_dv=tgt.id_dv AND tgt1.[sid]='BankLoans_Current'  AND tgt1.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt2 ON tgt2.id_dv=tgt.id_dv AND tgt2.[sid]='BankLoans_NonCurrent'  AND tgt2.[period]=tgt.[period]
						WHERE tgt.id_dv=@id_dv_balance  AND tgt.[sid]='Cash'  

						----print '["'+REPLACE(@periodList,''',''','","')+'"]'
						--print '--считаем capital ---------------->'
						--print @tableCapitalPer100
						select @capital_chart='{'+'"group":"'''+'Длит. кр. задолженности, дн.'+''','''+'Длит. запасов, дн.'+''','''+'Длит. деб. задолженности, дн.'+''','''+'Финансовый цикл, дн.'+'''",'
											    +'"name1":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-2)+']')+'",'
												+'"snt1":"' +JSON_VALUE('['+@table_bal1+']','$[0]')+','+JSON_VALUE('['+@table_bal2+']','$[0]')+','+JSON_VALUE('['+@table_bal3+']','$[0]')+','+JSON_VALUE('['+@table_bal+']','$[0]')+'",'
												+'"name2":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-1)+']')+'",'
												+'"snt2":"' +JSON_VALUE('['+@table_bal1+']','$[1]')+','+JSON_VALUE('['+@table_bal2+']','$[1]')+','+JSON_VALUE('['+@table_bal3+']','$[1]')+','+JSON_VALUE('['+@table_bal+']','$[1]')+'",'
												+'"tl_snt1":"-' +REPLACE(@table_bal1,',',',-') +'",'
												+'"tl_snt2":"' +@table_bal2 +'",'
												+'"tl_snt3":"' +@table_bal3 +'",'
												+'"tl_name1":"'+'Длит. кр. задолженности, дн.' +'",'
												+'"tl_name2":"'+'Длит. запасов, дн.'  +'",'
												+'"tl_name3":"'+'Длит. деб. задолженности, дн.' +'",'
												+'"tl_group":"'''+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-2)+']')+''','''+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-1)+']')+'''",'
												+'"wcap1":"'+JSON_VALUE('['+@table_bal+']','$[0]')+'",'
												+'"wcap2":"'+JSON_VALUE('['+@table_bal+']','$[1]')+'",'
												+'"wcap3":"'+JSON_VALUE('['+@table_balOper+']','$[0]')+'",'
												+'"wcap4":"'+JSON_VALUE('['+@table_balOper+']','$[1]')+'",'
												--formula
												+'"wcPer100":{"capital":"'+JSON_VALUE('['+@tableCapitalPer100+']','$[7]')+'","Inventory":"'+JSON_VALUE('['+@tableCapitalPer100+']','$[1]')
														+'", "Receivables":"'+JSON_VALUE('['+@tableCapitalPer100+']','$[3]')+'", "Payables":"'+JSON_VALUE('['+@tableCapitalPer100+']','$[5]')+'"},'
												--chart Investment in Working Capital per $100
												+'"groupPer100":"'''+'Кр. задолженность, руб.'+''','''+'Запасы, руб.'+''','''+'Деб. задолженность, руб.'+''','''+'Рабочий капитал, руб.'+'''",'
												+'"snt1Per100":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[0]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[2]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[4]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[6]')+'",'
												+'"snt2Per100":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[1]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[3]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[5]')+','+JSON_VALUE('['+@tableCapitalPer100+']','$[7]')+'",'
												--Gross Margin vs Working Capital
												+'"grossVSwork1":"'+ISNULL(JSON_VALUE('['+@tableCapitalPer100+']','$[6]'),'0')+','+ISNULL(JSON_VALUE('['+@tableCapitalPer100+']','$[7]'),'0')+'",'
												+'"grossVSwork2":"'+ISNULL(JSON_VALUE('['+@tableCapitalPer100+']','$[8]'),'0')+','+ISNULL(JSON_VALUE('['+@tableCapitalPer100+']','$[9]'),'0')+'",'
												+'"grossVSworkName1":["Рабочий капитал","Валовая прибыль"],'
												--Working Capital Ratios
												+'"capital_table":['
												+'{"name":"Длит. кр. задолженности, ","edizm":"дн.","txtclass":"text-info","snt2":"' +JSON_VALUE('['+@table_bal1+']','$[0]')+'","snt1":"' +JSON_VALUE('['+@table_bal1+']','$[1]')+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal1+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal1+']','$[0]')) )>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal1+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal1+']','$[0]')) ))+'"},'
												+'{"name":"Длит. запасов, ","edizm":"дн.","txtclass":"text-info","snt2":"' +JSON_VALUE('['+@table_bal2+']','$[0]')+'","snt1":"' +JSON_VALUE('['+@table_bal2+']','$[1]')+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal2+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal2+']','$[0]')) )<=0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal2+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal2+']','$[0]')) ))+'"},'
												+'{"name":"Длит. деб. задолженности, ","edizm":"дн.","txtclass":"text-info","snt2":"' +JSON_VALUE('['+@table_bal3+']','$[0]')+'","snt1":"' +JSON_VALUE('['+@table_bal3+']','$[1]')+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal3+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal3+']','$[0]')) )<=0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal3+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal3+']','$[0]')) ))+'"},'
												+'{"name":"Финансовый цикл, ","edizm":"дн.","txtclass":"text-info","snt2":"' +JSON_VALUE('['+@table_bal+']','$[0]')+'","snt1":"' +JSON_VALUE('['+@table_bal+']','$[1]')+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal+']','$[0]')) )<=0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), (CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal+']','$[1]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@table_bal+']','$[0]')) ))+'"},'
												+'{"name":"Рабочий капитал","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[10]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[11]'))+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[10]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[11]')) )>0 THEN 'success' ELSE 'danger' END + '","prc":"'+[dbo].[pro_setOtstup](CONVERT(varchar(100), (CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[10]'))-CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[11]')) )) )+'"},'
												+'{"name":"Рабочий капитал на 100 руб.","snt2":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[6]')+'","snt1":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[7]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,6,@tableCapitalPer100,7,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@tableCapitalPer100,6,@tableCapitalPer100,7,'-' ))+'"},'
												+'{"name":"Оборачиваемость рабочего капитала, год","snt2":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[12]')+'","snt1":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[13]')+'","color":"'+CASE WHEN (CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[12]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[13]')) )>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), (CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[12]'))-CONVERT( decimal(18,2),JSON_VALUE('['+@tableCapitalPer100+']','$[13]')) ))+'"},'
												+'{"name":"Изменение маржинального денежного потока","snt2":"' + CONVERT(varchar(100),[dbo].[pro_sumlistVal](@table1,0,@tableCapitalPer100,6,'-' )) +'","snt1":"' +CONVERT(varchar(100),[dbo].[pro_sumlistVal](@table1,1,@tableCapitalPer100,7,'-' ))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table1,0,@tableCapitalPer100,6,'-' )-[dbo].[pro_sumlistVal](@table1,1,@tableCapitalPer100,7,'-' ) )<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table1,0,@tableCapitalPer100,6,'-' )-[dbo].[pro_sumlistVal](@table1,1,@tableCapitalPer100,7,'-' ) )+'"},'
												+'{"name":"Коэффициент текущей ликвидности","snt2":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[14]')+'","snt1":"' +JSON_VALUE('['+@tableCapitalPer100+']','$[15]')+'","color":"'+CASE WHEN ( [dbo].[pro_sumlistVal](@tableCapitalPer100,15,@tableCapitalPer100,14,'-' ) )>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@tableCapitalPer100,15,@tableCapitalPer100,14,'-' ))+'"}'
												+'],'
												+'"capital_table_add":['
												+'{"name":"Стоимость финансового цикла в день","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[16]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[17]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,16,@tableCapitalPer100,17,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr( [dbo].[pro_sumlistVal](@tableCapitalPer100,16,@tableCapitalPer100,17,'-' ),1)+'"},'
												+'{"name":"Необходимый Оборотный Капитал, руб.","snt2":"'+ dbo.FloatToStr( [dbo].[pro_sumlistVal](@tableCapitalPer100,16,@table_bal,0,'*' ),1)+'","snt1":"' +dbo.FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,17,@table_bal,1,'*' ),1)+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,17,@table_bal,1,'*' )-[dbo].[pro_sumlistVal](@tableCapitalPer100,16,@table_bal,0,'*' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,17,@table_bal,1,'*' )-[dbo].[pro_sumlistVal](@tableCapitalPer100,16,@table_bal,0,'*' ),1)+'"},'
												+'{"name":"Оборотные Активы, руб.","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[18]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[19]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,18,@tableCapitalPer100,19,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,18,@tableCapitalPer100,19,'-' ),1)+'"},'
												+'{"name":"Изменение, руб.","snt2":"' +dbo.FloatToStr( [dbo].[pro_sumlistVal](@tableCapitalPer100,16,@table_bal,0,'*' ) - [dbo].[pro_sumlistVal](@tableCapitalPer100,18,'',0,'' ),1)+'","snt1":"' +dbo.FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,17,@table_bal,1,'*' )- [dbo].[pro_sumlistVal](@tableCapitalPer100,19,'',0,'' ),1)+'",'
													+'"txtclass2":"text-'+CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,16,@table_bal,0,'*' ) - [dbo].[pro_sumlistVal](@tableCapitalPer100,18,'',0,'' )>0 THEN 'success' ELSE 'danger' END+'","txtclass1":"text-'+CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,17,@table_bal,1,'*' ) - [dbo].[pro_sumlistVal](@tableCapitalPer100,19,'',0,'' )>0 THEN 'success' ELSE 'danger' END+'",'
													+'"color":"secondary","prc":""}'
												+'],'
												/**/
												+'"a":"q"}' 
						--print @capital_chart
						--print '--считаем capital ----------------<'
						--other capital ----------->
						SELECT
							@table_other= STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Прочие Активы 0,1*/			(tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										 +',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Рабочий капитал 2,3*/				(tgt12.[value]+tgt13.[value]-tgt11.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period]) /**/
										 +',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
											/*Asset Turnover 4,5*/				CASE WHEN 	((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value])<>0 THEN								
																					tgt4.[value]/(((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value]))
																					ELSE 1 END
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),
											/*Return on Capital % 6,7*/			--(CASE WHEN tgt4.[value] <> 0 THEN tgt5.[value] / tgt4.[value] ELSE 1 END)*
																				(CASE WHEN 	((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value])<>0 THEN								
																					tgt5.[value]/(((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value]))*100
																					ELSE 1 END)
																							)),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),ABS(
											/*Revenue 8,9*/						(tgt4.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),(
											/*Operating_Profit 10,11*/			(tgt5.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*other capital % 12,13*/						(CASE WHEN tgt4.[value] <> 0 THEN ((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))/tgt4.[value]  *100 ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*other capital Turnover 14,15*/				(CASE WHEN ((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value])) <> 0 THEN tgt4.[value] / ((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value])) ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Net Operating Assets % 16,17*/				(CASE WHEN tgt4.[value] <> 0 THEN (((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value]))/ tgt4.[value] *100 ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Asset Turnover 18,19*/						(CASE WHEN (((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value])) <> 0 THEN tgt4.[value]/ (((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value]))  ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Return on Capital %  20,21*/					(CASE WHEN (((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value])) <> 0 THEN tgt5.[value]/ (((tgt1.[value] + tgt2.[value] + tgt3.[value])-(tgt6.[value] + tgt7.[value]))+(tgt12.[value]+tgt13.[value]-tgt11.[value])) *100 ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Return on Total Assets %  22,23*/				(CASE WHEN (tgt14.[value]) <> 0 THEN tgt5.[value]/ tgt14.[value] *100 ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,2),ABS(
											/*Return on Equity %  24,25*/				(CASE WHEN (tgt.[value]) <> 0 THEN tgt10.[value]/ tgt.[value] *100 ELSE 1 END)
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),(
											/*Net_Profit 26,27*/			(tgt10.[value])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])
										+',' +STRING_AGG( CONVERT(varchar(100), CONVERT(decimal(18,0),(
											/*diff Equity 28,29*/			(tgt.[diff])
																							))),',')  WITHIN GROUP ( ORDER BY  tgt.[period])

						FROM [pro_dataVariantContent] tgt
						LEFT JOIN [pro_dataVariantContent] tgt1 ON tgt1.id_dv=tgt.id_dv AND tgt1.[sid]='FixedAssets'  AND tgt1.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt2 ON tgt2.id_dv=tgt.id_dv AND tgt2.[sid]='OtherCurrentAssets'  AND tgt2.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt3 ON tgt3.id_dv=tgt.id_dv AND tgt3.[sid]='OtherNonCurrentAssets'  AND tgt3.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt4 ON tgt4.id_dv=@id_dv_profit AND tgt4.[sid]='Revenue'  AND tgt4.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt5 ON tgt5.id_dv=@id_dv_profit AND tgt5.[sid]='Operating_Profit'  AND tgt5.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt6 ON tgt6.id_dv=tgt.id_dv AND tgt6.[sid]='OtherCurrentLiabilities'  AND tgt6.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt7 ON tgt7.id_dv=tgt.id_dv AND tgt7.[sid]='OtherNonCurrentLiabilities'  AND tgt7.[period]=tgt.[period]

						LEFT JOIN [pro_dataVariantContent] tgt10 ON tgt10.id_dv=@id_dv_profit AND tgt10.[sid]='Net_Profit'  AND tgt10.[period]=tgt.[period] 
						LEFT JOIN [pro_dataVariantContent] tgt11 ON tgt11.id_dv=tgt.id_dv AND tgt11.[sid]='AccountsPayable'  AND tgt11.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt12 ON tgt12.id_dv=tgt.id_dv AND tgt12.[sid]='Inventory'  AND tgt12.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt13 ON tgt13.id_dv=tgt.id_dv AND tgt13.[sid]='AccountsReceivable'  AND tgt13.[period]=tgt.[period]
						LEFT JOIN [pro_dataVariantContent] tgt14 ON tgt14.id_dv=tgt.id_dv AND tgt14.[sid]='TotalAssets'  AND tgt14.[period]=tgt.[period]
						WHERE tgt.id_dv=@id_dv_balance  AND tgt.[sid]='Equity' AND tgt.[period]> @cnt-2
						
						--print @periodList

						select @other_chart='{'
											+'"group":"'''+'Операционная прибыль %'+''','''+'Оборачиваемость активов'+''','''+'Рентабельность капитала, %'+'''",'
											+'"name1":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-2)+']')+'",'
											+'"snt1":"' +JSON_VALUE('['+@table2+']','$[0]')+','+JSON_VALUE('['+@table_other+']','$[4]')+','+JSON_VALUE('['+@table_other+']','$[6]')+'",'
											+'"name2":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-1)+']')+'",'
											+'"snt2":"' +JSON_VALUE('['+@table2+']','$[1]')+','+JSON_VALUE('['+@table_other+']','$[5]')+','+JSON_VALUE('['+@table_other+']','$[7]')+'",'

											+'"formula":{"Operating_Profit":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[11]'))+'","Revenue":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[9]'))+'","capital":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[3]'))+'",'
														+'"Other":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[1]'))+'","return_capital":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[7]'))+'","NetOperatingAssets":"'+dbo.FloatToStr( [dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ),1)+'"},'

											+'"other_table":['
											+'{"name":"Прочий капитал, ","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[0]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[1]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr( [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' ),1)+'"},'
											+'{"name":"Прочий капитал, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[12]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[13]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,13,@table_other,12,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,13,@table_other,12,'-' ))+'"},'
											
											+'{"name":"Оборачиваемость капитала, ","snt2":"' +JSON_VALUE('['+@table_other+']','$[14]')+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[15]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,14,@table_other,15,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100),  [dbo].[pro_sumlistVal](@table_other,15,@table_other,14,'-' ))+'"},'
											+'{"name":"Чистые операционные активы, руб.","snt2":"' +[dbo].[pro_setOtstup]([dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' ))+'","snt1":"' +[dbo].[pro_setOtstup]([dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' )-[dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr( ([dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' )-[dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' )),1)+'"},'
											+'{"name":"Чистые операционные активы, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[16]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[17]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,16,@table_other,17,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,17,@table_other,16,'-' ))+'"},'
											
											+'{"name":"Оборачиваемость активов, ","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[18]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[19]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,18,@table_other,19,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,19,@table_other,18,'-' ))+'"},'
											+'{"name":"Рентабельность капитала, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[20]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[21]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,20,@table_other,21,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,21,@table_other,20,'-' ))+'"},'
											
											+'{"name":"Рентабельность активов, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[22]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[23]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,22,@table_other,23,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,23,@table_other,22,'-' ))+'"},'
											+'{"name":"Рентабельность собственного капитала, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[24]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[25]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,24,@table_other,25,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,25,@table_other,24,'-' ))+'"}'
													
											+'],' 
											+'"a":"q"}' 

						--other capital -----------<
						
						--funding ----------->
						SELECT @table_funding=''+(
										SELECT * FROM	
											(SELECT
													ISNULL(tmp.[NameRU],tmp.[Name])  as title,  
													dbo.FloatToStr(tgt.[value],2) as snt,
													tgt.[value]  as snt1, -- [0], [2]  --[1], [0] --[2], [0]
													tgt1.[value]  as snt2,
													CASE WHEN tgt.[diff]>0 THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr(tgt.[diff],2) as prc,
													CASE WHEN tgt.[sid]='Equity' THEN 'plus' ELSE 'minus' END as icont,
													CASE WHEN tgt.[sid]='Equity' THEN 'display:none;' ELSE '' END as visiblet,
													--'' as txtclass,
													tmp.sort
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												WHERE tgt.id_dv=@id_dv_balance AND tgt.[sid]IN('Cash','Equity' )  
												AND tgt.[period]=@iPeriod --last period
												UNION
												SELECT
 													'Суммарный долг' as title,
													dbo.FloatToStr(SUM(tgt.[value] )  ,2) as snt,
													SUM(tgt.[value]) as snt1, -- [1] --[2] --[1]
													SUM(tgt1.[value]) as snt2,
													CASE WHEN SUM(tgt.[diff] )<0 THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr(SUM(tgt.[diff] ) ,2) as prc,
													'plus' as icont,
													'' as visiblet,
													300 as sort
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												WHERE tgt.id_dv=@id_dv_balance 
													  AND tgt.[sid]IN('BankLoans_Current','BankLoans_NonCurrent' )  
													  AND tgt.[period]=@iPeriod
												UNION
												SELECT
 													'Чистые операционные активы' as title,
													dbo.FloatToStr(SUM((CASE WHEN tgt.[sid]IN('Cash' ) THEN (-1) ELSE 1 END) * tgt.[value] )  ,2) as snt,
													SUM((CASE WHEN tgt.[sid]IN('Cash' ) THEN (-1) ELSE 1 END) *tgt.[value]) as snt1, -- [3]
													SUM((CASE WHEN tgt1.[sid]IN('Cash' ) THEN (-1) ELSE 1 END) *tgt1.[value]) as snt2,
													CASE WHEN SUM((CASE WHEN tgt1.[sid]IN('Cash' ) THEN (-1) ELSE 1 END) *tgt.[diff] )>0 THEN 'success' ELSE 'danger' END as color,
													dbo.FloatToStr(SUM((CASE WHEN tgt1.[sid]IN('Cash' ) THEN (-1) ELSE 1 END) *tgt.[diff] ) ,2) as prc,
													'equal' as icont,
													'' as visiblet,
													10 as sort
												FROM [pro_dataVariantContent] tgt
												INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
												LEFT JOIN pro_dataVariantContent tgt1 ON tgt1.id_dv = tgt.id_dv  AND tgt1.[period]=tgt.[period]-1 AND tgt1.id_dvc = tmp.id_dvc 
												WHERE tgt.id_dv=@id_dv_balance 
													  AND tgt.[sid]IN('BankLoans_Current','BankLoans_NonCurrent','Cash','Equity' )  
													  AND tgt.[period]=@iPeriod
												) as tt
									ORDER BY tt.sort desc
									FOR JSON PATH)
									+''

						----print @profibility_main
						--print @tableCapitalPer100

						----print @profibility_table

						select @funding_chart='{'
											/* 16112024
											+'"group":"'''+'Деньги'+''','''+'Суммарный долг'+''','''+'Собственный капитал'+'''",'
											+'"name1":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-2)+']')+'",'
											+'"snt1":"' +JSON_VALUE(@table_funding,'$[2].snt2')+','+JSON_VALUE(@table_funding,'$[1].snt2')+','+JSON_VALUE(@table_funding,'$[0].snt2')+'",'
											+'"name2":"'+JSON_VALUE('["'+REPLACE(@periodList,''',''','","')+'"]','$['+CONVERT(varchar(max),@iPeriod-1)+']')+'",'
											+'"snt2":"' +JSON_VALUE(@table_funding,'$[2].snt1')+','+JSON_VALUE(@table_funding,'$[1].snt1')+','+JSON_VALUE(@table_funding,'$[0].snt1')+'",'
											*/
											+'"funding_table":['
												+'{"name":"Прибыль",' + CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))> 0 THEN '"prc2":"' ELSE '"prc1":"' END + [dbo].floatToStr(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]')) + CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]')),2)  +'"},' --+'","prc1":"'
												+'{"name":"Изменение в рабочем капитале",' + CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )> 0 THEN '"prc2":"' ELSE '"prc1":"' END +dbo.floatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' ),2) +'"},'
												+'{"name":"Изменение в прочем капитале",' + CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )< 0 THEN '"prc2":"' ELSE '"prc1":"' END +dbo.FloatToStr( [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' ),2)+'"},'
												+'{"name":"Итого","rowclass":"table-light fw-bold","prc2":"' +dbo.floatToStr(
																							  CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))> 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))) ELSE 0 END
																							+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )> 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
																							+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )< 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END		
																											,2)+'",'
																								+ '"prc1":"'+
																							dbo.floatToStr(
																							  CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))< 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))) ELSE 0 END
																							+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )< 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
																							+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )> 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END		
																											,2)	
																								+'"}'
											+'],'
											+'"result":{'
											+CASE WHEN 
												(CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))> 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))) ELSE 0 END
												+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )> 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
												+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )< 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END)		
												-															
												(CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))< 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))) ELSE 0 END
												+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )< 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
												+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )> 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END)
												>= 0 THEN 
													 '"color":"#b7e8c0","text":"Вашему бизнесу не требуются дополнительные средства."'
												ELSE '"color":"#ffa7a7","text":"Дефицит средств:&nbsp;&nbsp;- '
													+dbo.floatToStr(
														ABS ((CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))> 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )> 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )< 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END)		
														-															
														(CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))< 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )< 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )> 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END))
													,2)+' руб. <br>' 
													+'Дивиденды:&nbsp;&nbsp;'+[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))+' руб.<br>'
													+'Общий отток капитала:&nbsp;&nbsp;- '
													+dbo.floatToStr(
														ABS ((CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))> 0 THEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]')) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )> 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )< 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END)		
														-															
														(CASE WHEN CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))< 0 THEN ABS(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )< 0 THEN  ABS([dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )) ELSE 0 END
														+ CASE WHEN [dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )> 0 THEN ABS([dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' )) ELSE 0 END))
														--+ABS (CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]')))
													,2)
													+' руб."'
												END--#F3ACA2
											+'},'
											+'"Equity":'+JSON_VALUE(@table_funding,'$[0].snt1')+',"EquityOtstup":"'+[dbo].FloatToStr(CONVERT( decimal(18,0),JSON_VALUE(@table_funding,'$[0].snt1')),2)+'",'
											+'"NetDebt":'+dbo.floatToStr(CONVERT( decimal(18,0),JSON_VALUE(@table_funding,'$[3].snt1')) - CONVERT( decimal(18,0),JSON_VALUE(@table_funding,'$[0].snt1')),0)+',"NetDebtOtstup":"'+dbo.floatToStr(CONVERT( decimal(18,0),JSON_VALUE(@table_funding,'$[3].snt1')) - CONVERT( decimal(18,0),JSON_VALUE(@table_funding,'$[0].snt1')),2)+'",'
											+'"WorkingCapital":'+JSON_VALUE('['+@tableCapitalPer100+']','$[11]')+',"WorkingCapitalOtstup":"'+[dbo].FloatToStr(CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[11]')),2)+'",'
											+'"OtherCapital":'+JSON_VALUE('['+@table_other+']','$[1]')+',"OtherCapitalOtstup":"'+[dbo].FloatToStr(CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[1]')),2)+'",'

											+'"funding_table2":['
												+'{"name2":"Выручка, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[23]'))+'",'
												+'"name1":"Денежные средства от клиентов, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].FloatToStr(CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[23]'))+ [dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' ),2)+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+[dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' ),2)+'"},'
												+'{"name2":"Абсолютно-переменные затраты, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[25]'))+'",'
												+'"name1":"Деньги поставщикам, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].FloatToStr(CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[25]'))+ [dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ),2)+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+[dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ),2)+'"},'
												+'{"name2":"Маржинальная прибыль, ","edizm2":"руб.","txtclass2":"","snt2":"' +JSON_VALUE(@profibility_table,'$[2].snt1')+'",'
												+'"name1":"Валовая денежная прибыль, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,23,@tableCapitalPer100,25,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ),2)+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+[dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ),2)+'"},'
												+'{"name2":"Накладные расходы без учета амортизации, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[29]'))+'",'
												+'"name1":"Накладные расходы без учета амортизации, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[29]')) +'","color":"","prc":""},'
												+'{"name2":"Операционная денежная прибыль, ","edizm2":"руб.","txtclass2":"fw-bold","snt2":"' +[dbo].FloatToStr( CONVERT( decimal(18,0),JSON_VALUE(@profibility_table,'$[2].snt'))-CONVERT( decimal(18,0), JSON_VALUE('['+@tableCapitalPer100+']','$[29]')),2)+'",'
												+'"name1":"Операционный денежный поток, ","edizm1":"руб.","txtclass1":"fw-bold","snt1":"' + [dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,23,@tableCapitalPer100,25,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' )-CONVERT( decimal(18,0), JSON_VALUE('['+@tableCapitalPer100+']','$[29]')),2) +'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+[dbo].FloatToStr([dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' ),2)+'"},'
												
												+'{"name2":"Платежи банку, заемщикам, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[33]'))+'",'
												+'"name1":"Платежи банку, заемщикам, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[33]')) +'","color":"","prc":""},'
												+'{"name2":"Налог на прибыль, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[35]'))+'",'
												+'"name1":"Налог на прибыль, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[35]')) +'","color":"","prc":""},'
												+'{"name2":"Прочие приходы, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[37]'))+'",'
												+'"name1":"Прочие приходы, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[37]')) +'","color":"","prc":""},'
												+'{"name2":"Распределения/Выплаченные дивиденды, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))+'",'
												+'"name1":"Распределения/Выплаченные дивиденды, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[39]')) +'","color":"","prc":""},'
												+'{"name2":"Амортизация, ","edizm2":"руб.","txtclass2":"","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[31]'))+'",'
												+'"name1":"Затраты на основные средства, ","edizm1":"руб.","txtclass1":"","snt1":"' + [dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[31]')) +'","color":"","prc":""},'
												+'{"name2":"Нераспределенная прибыль, ","edizm2":"руб.","txtclass2":"fw-bold","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@tableCapitalPer100+']','$[41]'))+'",'
												+'"name1":"Чистый денежный поток, ","edizm1":"руб.","txtclass1":"fw-bold","snt1":"' + [dbo].FloatToStr( CONVERT( decimal(18,0),JSON_VALUE('['+@table_other+']','$[27]'))+CONVERT( decimal(18,0),JSON_VALUE('['+@tableCapitalPer100+']','$[39]'))  +[dbo].[pro_sumlistVal](@tableCapitalPer100,10,@tableCapitalPer100,11,'-' )  +[dbo].[pro_sumlistVal](@table_other,1,@table_other,0,'-' ) ,2) +'","color":"","prc":""}'
/* */
--Чистый денежный поток^ [dbo].[pro_sumlistVal](@tableCapitalPer100,20,@tableCapitalPer100,21,'-' )+[dbo].[pro_sumlistVal](@tableCapitalPer100,26,@tableCapitalPer100,27,'-' )+CONVERT( decimal(18,0), JSON_VALUE('['+@tableCapitalPer100+']','$[43]'))
/*DepreciationAmortisation 30,31*/		/*InterestPaid 32,33*/	/*TaxPaid 34,35*/	/*ExtraordinaryIncome_Expenses 36,37*/	/*DividendsPaid 38,39*/		/*Retained_Profit 40,41*/		

											+'],'
/*		
											
											+'"formula":{"Operating_Profit":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[11]'))+'","Revenue":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[9]'))+'","capital":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[3]'))+'",'
														+'"Other":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[1]'))+'","return_capital":"'+[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[7]'))+'","NetOperatingAssets":"'+dbo.FloatToStr( [dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ),1)+'"},'

											
											+'{"name":"Other Capital, ","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[0]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[1]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,0,@table_other,1,'-' ))<=0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr( [dbo].[pro_sumlistVal](@table_other,0,@table_other,1,'-' ),1)+'"},'
											+'{"name":"Other Capital, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[12]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[13]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,12,@table_other,13,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,12,@table_other,13,'-' ))+'"},'
											
											+'{"name":"Other Capital Turnover, ","snt2":"' +JSON_VALUE('['+@table_other+']','$[14]')+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[15]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,14,@table_other,15,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100),  [dbo].[pro_sumlistVal](@table_other,14,@table_other,15,'-' ))+'"},'
											+'{"name":"Net Operating Assets, руб.","snt2":"' +[dbo].[pro_setOtstup]([dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' ))+'","snt1":"' +[dbo].[pro_setOtstup]([dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' )-[dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+dbo.FloatToStr( ([dbo].[pro_sumlistVal](@table_other,3,@table_other,1,'+' )-[dbo].[pro_sumlistVal](@table_other,2,@table_other,0,'+' )),1)+'"},'
											+'{"name":"Net Operating Assets, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[16]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[17]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,16,@table_other,17,'-' ))>0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,16,@table_other,17,'-' ))+'"},'
											
											+'{"name":"Asset Turnover, ","snt2":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[18]'))+'","snt1":"' +[dbo].[pro_setOtstup](JSON_VALUE('['+@table_other+']','$[19]'))+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,18,@table_other,19,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,18,@table_other,19,'-' ))+'"},'
											+'{"name":"Return on Capital, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[20]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[21]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,20,@table_other,21,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,20,@table_other,21,'-' ))+'"},'
											
											+'{"name":"Return on Total Assets, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[22]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[23]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,22,@table_other,23,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,22,@table_other,23,'-' ))+'"},'
											+'{"name":"Return on Equity, ","edizm":"%.","txtclass":"text-primary","snt2":"' +JSON_VALUE('['+@table_other+']','$[24]')+'","snt1":"' +JSON_VALUE('['+@table_other+']','$[25]')+'","color":"'+CASE WHEN ([dbo].[pro_sumlistVal](@table_other,24,@table_other,25,'-' ))<0 THEN 'success' ELSE 'danger' END + '","prc":"'+CONVERT(varchar(100), [dbo].[pro_sumlistVal](@table_other,24,@table_other,25,'-' ))+'"}'
													
											+'],' */
											+'"a":"q"}' 
						--funding -----------<

						SELECT @cnt=COUNT(*) FROM OPENJSON('['+@table1+']','$')

						IF @cnt > 1 -- больше чем один период
						BEGIN
							SELECT @diff=CONVERT(decimal(18,2), JSON_VALUE('['+@table+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,2), JSON_VALUE('['+@table+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff1=CONVERT(decimal(18,2), JSON_VALUE('['+@table1+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,2), JSON_VALUE('['+@table1+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff2=CONVERT(decimal(18,2), JSON_VALUE('['+@table2+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,2), JSON_VALUE('['+@table2+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff3=CONVERT(decimal(18,2), JSON_VALUE('['+@table3+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,2), JSON_VALUE('['+@table3+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_bal=CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_bal1=CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal1+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal1+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_bal2=CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal2+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal2+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_bal3=CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal3+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_bal3+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_cash=CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_cash1=CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash1+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash1+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_cash2=CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash2+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash2+']', '$['+CONVERT(varchar(100), @cnt - 2)+']')),
									@diff_cash3=CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash3+']', '$['+CONVERT(varchar(100), @cnt - 1)+']'))-CONVERT(decimal(18,0), JSON_VALUE('['+@table_cash3+']', '$['+CONVERT(varchar(100), @cnt - 2)+']'))
							----print @diff1

							SELECT @columns = @columns+'</th><th class="text-center">Изменение',
								   @table = '<td align="left">Выручка (Revenue), руб.</td><td>'+REPLACE(@table,',','</td><td>')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff>0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff,1)+'</span>'+'</td>',
								   @table1 = '<td align="left">Маржинальность, <span class="text-primary">%</span></td><td class="text-primary">'				   +REPLACE(@table1,',','</td><td class="text-primary">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff1>0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff1)+'</span>'+'</td>',
								   @table2 = '<td align="left">Операционная рентабельность <span class="text-primary">%</span></td><td class="text-primary">'	   +REPLACE(@table2,',','</td><td class="text-primary">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff2>0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff2)+'</span>'+'</td>',
								   @table3 = '<td align="left">Рентабельность чистой прибыли, <span class="text-primary">%</span></td><td class="text-primary">'   +REPLACE(@table3,',','</td><td class="text-primary">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff3>0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff3)+'</span>'+'</td>',
								   @table_bal = '<td align="left">Финансовый цикл, <span class="text-info">дн.</span></td><td class="text-info">'			       +REPLACE(@table_bal,',','</td><td class="text-info">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_bal<0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff_bal,1)+'</span>'+'</td>',
								   @table_bal1 = '<td align="left">Длит. кредиторской задолженности, <span class="text-info">дн.</span></td><td class="text-info">'+REPLACE(@table_bal1,',','</td><td class="text-info">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_bal1>0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff_bal1)+'</span>'+'</td>',
								   @table_bal2 = '<td align="left">Длит. запасов, <span class="text-info">дн.</span></td><td class="text-info">'				   +REPLACE(@table_bal2,',','</td><td class="text-info">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_bal2<0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff_bal2)+'</span>'+'</td>',
								   @table_bal3 = '<td align="left">Длит. дебиторской задолженности, <span class="text-info">дн.</span></td><td class="text-info">' +REPLACE(@table_bal3,',','</td><td class="text-info">')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_bal3<0 THEN 'success' ELSE 'danger' END + '">' + CONVERT(varchar(100),@diff_bal3)+'</span>'+'</td>',
								   @table_cash = '<td align="left">Деньги, руб.</td><td >'	   +REPLACE(@table_cash,',','</td><td >')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_cash<0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff_cash,1)+'</span>'+'</td>',
								   @table_cash1 = '<td align="left">Финансовая деятельность, руб.</td><td >' +REPLACE(@table_cash1,',','</td><td >')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_cash1<0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff_cash1,1)+'</span>'+'</td>',
								   @table_cash2 = '<td align="left">Краткосрочные кредиты, руб.</td><td >'   +REPLACE(@table_cash2,',','</td><td >')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_cash2<0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff_cash2,1)+'</span>'+'</td>',
								   @table_cash3 = '<td align="left">Долгосрочные кредиты, руб.</td><td >'	   +REPLACE(@table_cash3,',','</td><td >')+'</td><td>'+ '<span class="badge rounded-pill bg-label-'+CASE WHEN @diff_cash3<0 THEN 'success' ELSE 'danger' END + '">' + dbo.FloatToStr(@diff_cash3,1)+'</span>'+'</td>'
						END ELSE
							SELECT @table = '<td align="left">Выручка (Revenue), руб.</td><td>'+REPLACE(@table,',','</td><td>')+'</td>',
								   @table1 = '<td align="left">Маржинальность, %</td><td>'+REPLACE(@table1,',','</td><td>')+'</td>',
								   @table2 = '<td align="left">Операционная рентабельность %</td><td>'+REPLACE(@table2,',','</td><td>')+'</td>',
								   @table3 = '<td align="left">>Рентабельность чистой прибыли, %</td><td>'+REPLACE(@table3,',','</td><td>')+'</td>',
								   @table_bal = '<td align="left">Финансовый цикл, дн.</td><td>'+REPLACE(@table_bal,',','</td><td>')+'</td>',
								   @table_bal1 = '<td align="left">Длит. кредиторской задолженности, дн.</td><td>'+REPLACE(@table_bal1,',','</td><td>')+'</td>',
								   @table_bal2 = '<td align="left">Длит. запасов, дн.</td><td>'+REPLACE(@table_bal2,',','</td><td>')+'</td>',
								   @table_bal3 = '<td align="left">Длит. дебиторской задолженности, дн.</td><td>'+REPLACE(@table_bal3,',','</td><td>')+'</td>'

						--profit--main

						  ---------sankey-----------------------
						  DECLARE @hiNode varchar(max)='',  @hiSeries varchar(max)='' 

						  SELECT @hiNode=
							(SELECT var_name as id, 
								   TRIM(var_source) as [name],
								   ABS(direct)-1 as [column],
								   ISNULL(sa.vOffset, ABS(direct)*7) as offsetVertical,
							
								   CASE WHEN sa.[target]='Equity' THEN '#889DE0'
										ELSE CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END 
								   END as color --,*  
							FROM  [pro_reportSankey] sa
							INNER JOIN pro_vocabulary pv ON ((pv.var_name=[target] AND direct<0) OR (pv.var_name=[source] AND direct>0)) AND lang='RU'
							WHERE sa.san_type='1' AND (sa.visible=1 OR sa.[target]='TotalPassive')
							FOR JSON AUTO
							)
						  SELECT @hiNode=REPLACE(@hiNode,'\r\n','')
						  SELECT @hiNode=REPLACE(@hiNode,'"id"','id')
						  SELECT @hiNode=REPLACE(@hiNode,'"name"','name')
						  SELECT @hiNode=REPLACE(@hiNode,'"column"','column')
						  SELECT @hiNode=REPLACE(@hiNode,'"color"','color')
						  SELECT @hiNode=REPLACE(@hiNode,'id:"Equity",','id:"Equity", level:5, offsetVertical: 60,')
						  SELECT @hiNode=REPLACE(@hiNode,'}',', dataLabels : {format:''{point.name}<br>{point.sum} тыс. руб.''}}')
						  SELECT @hiNode=REPLACE(@hiNode,'"','''')
						  --'dataLabels : {	format: ''{point.name}<br>{point.sum} тыс. руб.''}' as
						  SELECT @hiSeries=(
							  SELECT --sa.direct,sa.*,
								  --CASE WHEN sa.direct>0 THEN '#ffee37' ELSE '#00BB00' END as color,
								  CASE WHEN sa.[target]='Equity' THEN '#889DE0'
										ELSE CASE WHEN sa.direct<0 THEN '#FBA1A1' ELSE '#88E09D' END 
								   END as color,
								  sa.[source] as [from], 
								  ISNULL(sa.[target],'Balance') as [to], 
								  CONVERT(int,CASE WHEN sa.direct>0 THEN ISNULL(ABS(d.[value]),0)/1000 ELSE ISNULL(ABS(d1.[value]),0)/1000 END ) as [weight]
							  FROM pro_reportSankey sa
							  LEFT JOIN [dbo].[pro_dataVariantContent] d ON sa.[source]=d.[sid] AND d.id_dv=@id_dv_balance AND d.[period]=@iPeriod
							  LEFT JOIN [dbo].[pro_dataVariantContent] d1 ON sa.[target]=d1.[sid] AND d1.id_dv=@id_dv_balance AND d1.[period]=@iPeriod 
							  WHERE sa.san_type='1' AND sa.visible=1
							  FOR JSON AUTO
							) --id:"Equity",
						  SELECT @hiSeries=REPLACE(@hiSeries,'"color"','color')
						  SELECT @hiSeries=REPLACE(@hiSeries,'"from"','from')
						  SELECT @hiSeries=REPLACE(@hiSeries,'"to"','to')
						  SELECT @hiSeries=REPLACE(@hiSeries,'"weight"','weight')
						  SELECT @hiSeries=REPLACE(@hiSeries,'"','''')
						
						---------sankey-----------------------
						--print '-----------------'
						SELECT @code as code,
								[Page]= '[{"periodDate":"'
										+RIGHT('0'+CONVERT(varchar(100), MONTH(ttt.stdate)),2)+'.'+CONVERT(varchar(100), YEAR(ttt.stdate)) 
								+' - '	+RIGHT('0'+CONVERT(varchar(100), MONTH(ttt.enddate)),2)+'.'+CONVERT(varchar(100), YEAR(ttt.enddate))
								+' ('+ ttt.periodType+')",'
								+'"column":"'+STRING_ESCAPE('<th>Наименование параметра</th><th class="text-center">'+@columns+'</th>','json')+'",'
								+'"table":"'+STRING_ESCAPE(@table,'json')+'",'
								+'"table1":"'+STRING_ESCAPE(@table1,'json')+'",'
								+'"table2":"'+STRING_ESCAPE(@table2,'json')+'",'
								+'"table3":"'+STRING_ESCAPE(@table3,'json')+'",'
								--balance
								+'"table_bal":"'+STRING_ESCAPE(@table_bal,'json')+'",'
								+'"table_bal1":"'+STRING_ESCAPE(@table_bal1,'json')+'",'
								+'"table_bal2":"'+STRING_ESCAPE(@table_bal2,'json')+'",'
								+'"table_bal3":"'+STRING_ESCAPE(@table_bal3,'json')+'",'
								+'"profit":{'+ ( SELECT STRING_AGG('"'+tt.[sid]+'":'+CONVERT(varchar(100), CONVERT(decimal(18,0),CASE WHEN isBase = 1 THEN ABS(tt.[value]) ELSE tt.[value] END))
																	+', "'+tt.[sid]+'_":"'+dbo.FloatToStr(CASE WHEN isBase = 1 THEN ABS(tt.[value]) ELSE tt.[value] END, 2)+'"', ',' ) 
												FROM [pro_dataVariantContent] tt 
												INNER JOIN pro_dataVariantContentTMP t ON t.[sid]=tt.[sid] AND t.iDataType=tt.iDataType 
												WHERE tt.id_dv=ttt.id_dv AND tt.[period]=ttt.[period])+'},'
								+'"balance":{'+ ( SELECT STRING_AGG('"'+tt.[sid]+'":'+CONVERT(varchar(100), CONVERT(decimal(18,0),CASE WHEN isBase = 1 THEN ABS(tt.[value]) ELSE tt.[value] END))
																+', "'+tt.[sid]+'_":"'+dbo.FloatToStr(CASE WHEN isBase = 1 THEN ABS(tt.[value]) ELSE tt.[value] END, 2)+'"', ',' ) 
												FROM [pro_dataVariantContent] tt 
												INNER JOIN pro_dataVariantContentTMP t ON t.[sid]=tt.[sid] AND t.iDataType=tt.iDataType 
												WHERE tt.id_dv=@id_dv_balance AND tt.[period]=@iPeriod )+'},'
								--cash
								+'"periodList":"'''+@periodList+'''",'
								+'"cash":"'+@cash+'",'
								+'"BankLoans_Current":"'+@BankLoans_Current+'",'
								+'"BankLoans_NonCurrent":"'+@BankLoans_NonCurrent+'",'
							    +'"table_cash":"'+STRING_ESCAPE(@table_cash,'json')+'",'
								+'"table_cash1":"'+STRING_ESCAPE(@table_cash1,'json')+'",'
								+'"table_cash2":"'+STRING_ESCAPE(@table_cash2,'json')+'",'
								+'"table_cash3":"'+STRING_ESCAPE(@table_cash3,'json')+'",'

								--profit -- main
								+'"profit_main":' +ISNULL(@profibility_main ,'[]')+','
								+'"profit_chart":' +@profibility_chart+','
								+'"profit_table":' +@profibility_table+','
								
								--capital---- main
								+'"capital_main":' +ISNULL((
									SELECT title, snt, color, prc, sort
									FROM (
										SELECT
 											ISNULL(tmp.[NameRU],tmp.[Name]) as title,
											dbo.FloatToStr(tgt.[value],2) as snt,
											CASE WHEN (CASE WHEN tgt.[sid]IN('AccountsReceivable')THEN (-1) ELSE 1 END)*tgt.[diff]>0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(tgt.[diff],2) as prc,
											tmp.sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('AccountsReceivable','Inventory','AccountsPayable')  
											  AND tgt.[period]=ttt.[period]
										UNION
										SELECT
 											'Рабочий капитал' as title,--Working Capital
											dbo.FloatToStr(SUM(tgt.[value]* CASE WHEN tgt.[sid]='AccountsPayable' THEN (-1) ELSE 1 END)  ,2) as snt,
											CASE WHEN SUM(tgt.[diff]* CASE WHEN tgt.[sid]='AccountsPayable' THEN (-1) ELSE 1 END)>0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(SUM(tgt.[diff]* CASE WHEN tgt.[sid]='AccountsPayable' THEN (-1) ELSE 1 END) ,2) as prc,
											1100 as sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('AccountsReceivable','Inventory','AccountsPayable')  
											  AND tgt.[period]=ttt.[period]
	
									) as tt_1
									ORDER BY sort
									FOR JSON PATH
								),'[]')+','
								 +'"capital_chart":' +@capital_chart+','
								
								--other---- main
								+'"other_main":' +ISNULL((
									SELECT title, snt, color, prc, sort
									FROM (
										SELECT
 											ISNULL(tmp.[NameRU],tmp.[Name]) as title,
											dbo.FloatToStr(tgt.[value],2) as snt,
											CASE WHEN  tgt.[diff]>0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(tgt.[diff],2) as prc,
											tmp.sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('FixedAssets','' )  
											  AND tgt.[period]=ttt.[period]
										UNION
										SELECT
 											'Прочие активы' as title, --Other Assets
											dbo.FloatToStr(SUM(tgt.[value] )  ,2) as snt,
											CASE WHEN SUM(tgt.[diff] )>0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(SUM(tgt.[diff] ) ,2) as prc,
											1100 as sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('OtherCurrentAssets','OtherNonCurrentAssets' )  
											  AND tgt.[period]=ttt.[period]
										UNION
										SELECT
 											'Прочие обязательства' as title,--Other Liabilities
											dbo.FloatToStr(SUM(tgt.[value] )  ,2) as snt,
											CASE WHEN SUM(tgt.[diff] )<0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(SUM(tgt.[diff] ) ,2) as prc,
											1100 as sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('OtherNonCurrentLiabilities','OtherCurrentLiabilities' )  
											  AND tgt.[period]=ttt.[period]
										UNION
										SELECT
 											'Прочий капитал' as title,
											dbo.FloatToStr(SUM(tgt.[value]* CASE WHEN tgt.[sid]IN( 'OtherNonCurrentLiabilities','OtherCurrentLiabilities' )THEN (-1) ELSE 1 END)  ,2) as snt,
											CASE WHEN SUM(tgt.[diff]* CASE WHEN tgt.[sid]IN( 'OtherNonCurrentLiabilities','OtherCurrentLiabilities' ) THEN (-1) ELSE 1 END)>0 THEN 'success' ELSE 'danger' END as color,
											dbo.FloatToStr(SUM(tgt.[diff]* CASE WHEN tgt.[sid]IN( 'OtherNonCurrentLiabilities','OtherCurrentLiabilities' ) THEN (-1) ELSE 1 END) ,2) as prc,
											1100 as sort
										FROM [pro_dataVariantContent] tgt
										INNER JOIN pro_dataVariantContentTMP tmp ON tmp.id_dvc=tgt.id_dvc AND tgt.iDataType=tmp.iDataType 
										WHERE tgt.id_dv=@id_dv_balance 
											  AND tgt.[sid]IN('FixedAssets','OtherCurrentAssets','OtherNonCurrentAssets','OtherNonCurrentLiabilities','OtherCurrentLiabilities')  
											  AND tgt.[period]=ttt.[period]
	
									) as tt_1
									ORDER BY sort
									FOR JSON PATH
								),'[]')+','
								+'"other_chart":' +@other_chart+','

								--funding---- main
								+'"funding_main":' + ISNULL(@table_funding,'[]') +','
								+'"funding_chart":' + ISNULL(@funding_chart,'{}')+','
								
								--sankey--------------@sankeyNode
								+'"Sankey":{"balance":{"hinodes":"'+ ISNULL(@hiNode,'[]')+'","hiseries":"'+ ISNULL(@hiSeries,'[]')+'"}},'
										 -- +'"profit":{"hinodes":"'+ ISNULL(@hiNode1,'[]')+'","hiseries":"'+ ISNULL(@hiSeries1,'[]')+'"}},'
								--+'"Sankey":"[{colors: [''#880000'', ''#AFAFAF'', ''#008800'', ''#000088'', ''#ffb238'', ''#ffee37''],keys: [''color'', ''from'', ''to'', ''weight''],'
								--			+'data: '+ISNULL(@sankeyNode,'[]')+', type: ''sankey'',name: ''Sankey demo series''}]",'
								/**/
								+'"id":"'+CONVERT(varchar(max), @xid)+'"}]',
								dbo.getGlobals('path_tmp_real')+'pages\pro\'+dbo.getGlobals('path_project')+'rep_power_one_content.html' as tmp,
								'twig' as tmpType
						FROM [pro_dataVariantContent] ttt
						WHERE id_dv=@id_dv_profit AND [period]=@iPeriod AND id_dvc=@id_dvc
					END 
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



USE [dbTOC_LEAN]
GO
/****** Object:  Table [dbo].[pro_companyByBuyer]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_companyByBuyer](
	[id_cbb] [int] IDENTITY(1,1) NOT NULL,
	[id_comp] [int] NULL,
	[id_buyer] [int] NULL,
	[iType] [int] NULL,
	[date_modify] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_dataFormulas]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_dataFormulas](
	[id_f] [int] IDENTITY(1,1) NOT NULL,
	[groupName] [varchar](150) NULL,
	[sid] [varchar](150) NULL,
	[formula] [varchar](2000) NULL,
	[value] [decimal](18, 0) NULL,
	[Name] [varchar](150) NULL,
	[descr] [varchar](500) NULL,
	[visible] [bit] NULL,
	[sort] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_dataVariant]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_dataVariant](
	[id_dv] [int] IDENTITY(1,1) NOT NULL,
	[id_buyer] [int] NULL,
	[id_comp] [int] NULL,
	[name] [varchar](250) NULL,
	[descr] [varchar](1000) NULL,
	[stDate] [date] NULL,
	[endDate] [date] NULL,
	[date_modify] [datetime] NULL,
	[visible] [bit] NULL,
	[fileName] [varchar](250) NULL,
	[iDataType] [int] NULL,
	[id_cpLast] [int] NULL,
	[periodType] [varchar](50) NULL,
	[periodCount] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_dataVariantContent]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_dataVariantContent](
	[id_dvcc] [int] IDENTITY(1,1) NOT NULL,
	[id_dvc] [bigint] NULL,
	[id_dvcParent] [bigint] NULL,
	[id_dv] [int] NULL,
	[sid] [varchar](50) NULL,
	[value] [decimal](18, 2) NULL,
	[idataType] [int] NULL,
	[periodType] [varchar](50) NULL,
	[period] [int] NULL,
	[stDate] [date] NULL,
	[endDate] [date] NULL,
	[diff] [decimal](18, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_dataVariantContentTMP]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_dataVariantContentTMP](
	[id_dvc] [bigint] IDENTITY(1,1) NOT NULL,
	[id_dvcParent] [int] NULL,
	[id_dv] [int] NULL,
	[parentName] [varchar](150) NULL,
	[Name] [varchar](150) NULL,
	[value] [decimal](18, 0) NULL,
	[dataType] [varchar](250) NULL,
	[idataType] [int] NULL,
	[isBase] [bit] NULL,
	[sid] [varchar](50) NULL,
	[znak] [varchar](10) NULL,
	[visible] [bit] NULL,
	[color] [varchar](10) NULL,
	[sort] [int] NULL,
	[nameRU] [varchar](250) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_Org]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_Org](
	[Id_org] [int] IDENTITY(1,1) NOT NULL,
	[id_orgParent] [int] NULL,
	[id_buyer] [int] NULL,
	[id_wh] [int] NULL,
	[id_user] [int] NULL,
	[name] [varchar](250) NULL,
	[visible] [bit] NULL,
	[id_userCreate] [int] NULL,
	[org_date] [datetime] NULL,
	[org_descr] [varchar](1000) NULL,
	[id_buyerStruct] [int] NULL,
	[org_Rekv] [varchar](max) NULL,
	[x01_name] [varchar](1000) NULL,
	[x02_shotName] [varchar](250) NULL,
	[x03_INN] [varchar](100) NULL,
	[x04_KPP] [varchar](100) NULL,
	[x05_BIK] [varchar](100) NULL,
	[x06_bankName] [varchar](250) NULL,
	[x07_KS] [varchar](100) NULL,
	[x08_RS] [varchar](100) NULL,
	[x09_adress] [varchar](1000) NULL,
	[x10_tel] [varchar](100) NULL,
	[x11_email] [varchar](100) NULL,
	[x12_site] [varchar](100) NULL,
	[reg_type] [int] NULL,
	[id_town] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_reportSankey]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_reportSankey](
	[id_san] [int] IDENTITY(1,1) NOT NULL,
	[san_type] [varchar](50) NULL,
	[source] [varchar](150) NULL,
	[target] [varchar](150) NULL,
	[visible] [bit] NULL,
	[direct] [int] NULL,
	[vOffset] [int] NULL,
	[iSort] [int] NULL,
	[color] [varchar](15) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_Rules]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_Rules](
	[id_rule] [int] IDENTITY(1,1) NOT NULL,
	[id_org] [int] NULL,
	[id_ut] [int] NULL,
	[id_u] [int] NULL,
	[param_name] [varchar](150) NULL,
	[value] [varchar](50) NULL,
	[param_group] [varchar](150) NULL,
	[param_label] [varchar](150) NULL,
	[param_descr] [varchar](500) NULL,
	[isPublic] [bit] NULL,
	[ret_Type] [int] NULL,
	[iSort] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pro_vocabulary]    Script Date: 28.09.2026 1:59:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_vocabulary](
	[id_voc] [int] IDENTITY(1,1) NOT NULL,
	[var_name] [varchar](150) NULL,
	[var_source] [varchar](250) NULL,
	[var_synonym] [varchar](1000) NULL,
	[lang] [varchar](20) NULL,
	[units] [varchar](20) NULL,
	[unitSort] [nvarchar](10) NULL,
	[class] [varchar](150) NULL,
	[thousand] [varchar](10) NULL,
	[million] [varchar](10) NULL,
	[billion] [varchar](10) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pro_companyByBuyer] ADD  CONSTRAINT [DF_pro_companyByBuyer_iType]  DEFAULT ((640)) FOR [iType]
GO
ALTER TABLE [dbo].[pro_companyByBuyer] ADD  CONSTRAINT [DF_pro_companyByBuyer_date_modify]  DEFAULT (getdate()) FOR [date_modify]
GO
ALTER TABLE [dbo].[pro_dataFormulas] ADD  CONSTRAINT [DF_pro_dataFormulas_value]  DEFAULT ((0)) FOR [value]
GO
ALTER TABLE [dbo].[pro_dataFormulas] ADD  CONSTRAINT [DF_pro_dataFormulas_visible]  DEFAULT ((1)) FOR [visible]
GO
ALTER TABLE [dbo].[pro_dataFormulas] ADD  CONSTRAINT [DF_pro_dataFormulas_sort]  DEFAULT ((100)) FOR [sort]
GO
ALTER TABLE [dbo].[pro_dataVariant] ADD  CONSTRAINT [DF_pro_dataVariant_date_modify]  DEFAULT (getdate()) FOR [date_modify]
GO
ALTER TABLE [dbo].[pro_dataVariant] ADD  CONSTRAINT [DF_pro_dataVariant_visible]  DEFAULT ((1)) FOR [visible]
GO
ALTER TABLE [dbo].[pro_dataVariant] ADD  CONSTRAINT [DF_pro_dataVariant_iDataType]  DEFAULT ((1)) FOR [iDataType]
GO
ALTER TABLE [dbo].[pro_dataVariant] ADD  CONSTRAINT [DF_pro_dataVariant_periodCount]  DEFAULT ((0)) FOR [periodCount]
GO
ALTER TABLE [dbo].[pro_dataVariantContent] ADD  CONSTRAINT [DF_pro_dataVariantContent_value]  DEFAULT ((0)) FOR [value]
GO
ALTER TABLE [dbo].[pro_dataVariantContentTMP] ADD  CONSTRAINT [DF_pro_dataVariantContentTMP_value]  DEFAULT ((0)) FOR [value]
GO
ALTER TABLE [dbo].[pro_dataVariantContentTMP] ADD  CONSTRAINT [DF_pro_dataVariantContentTMP_isBase]  DEFAULT ((0)) FOR [isBase]
GO
ALTER TABLE [dbo].[pro_dataVariantContentTMP] ADD  CONSTRAINT [DF_pro_dataVariantContentTMP_visible]  DEFAULT ((1)) FOR [visible]
GO
ALTER TABLE [dbo].[pro_dataVariantContentTMP] ADD  CONSTRAINT [DF_pro_dataVariantContentTMP_sort]  DEFAULT ((100)) FOR [sort]
GO
ALTER TABLE [dbo].[pro_Org] ADD  CONSTRAINT [DF_pro_Org_id_orgParent]  DEFAULT ((0)) FOR [id_orgParent]
GO
ALTER TABLE [dbo].[pro_Org] ADD  CONSTRAINT [DF_pro_Org_visible]  DEFAULT ((1)) FOR [visible]
GO
ALTER TABLE [dbo].[pro_Org] ADD  CONSTRAINT [DF_pro_Org_org_date]  DEFAULT (getdate()) FOR [org_date]
GO
ALTER TABLE [dbo].[pro_Org] ADD  CONSTRAINT [DF_pro_Org_reg_type]  DEFAULT ((0)) FOR [reg_type]
GO
ALTER TABLE [dbo].[pro_reportSankey] ADD  CONSTRAINT [DF_pro_reportSankey_visible]  DEFAULT ((1)) FOR [visible]
GO
ALTER TABLE [dbo].[pro_reportSankey] ADD  CONSTRAINT [DF_pro_reportSankey_vOffset]  DEFAULT ((0)) FOR [vOffset]
GO
ALTER TABLE [dbo].[pro_Rules] ADD  CONSTRAINT [DF_pro_Rules_isPublic]  DEFAULT ((1)) FOR [isPublic]
GO
ALTER TABLE [dbo].[pro_Rules] ADD  CONSTRAINT [DF_pro_Rules_ret_Type]  DEFAULT ((0)) FOR [ret_Type]
GO
ALTER TABLE [dbo].[pro_Rules] ADD  CONSTRAINT [DF_pro_Rules_iSort]  DEFAULT ((100)) FOR [iSort]
GO

USE [dbTOC_LEAN]
GO

/****** Object:  Table [dbo].[rc_bank_company]    Script Date: 28.09.2026 1:59:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[rc_bank_company](
	[id_company] [int] IDENTITY(1,1) NOT NULL,
	[id_companyParent] [int] NULL,
	[comp_name] [varchar](250) NULL,
	[comp_fullName] [varchar](500) NULL,
	[comp_date] [datetime] NULL,
	[id_user] [int] NULL,
	[id_buyer] [int] NULL,
	[comp_vid] [varchar](250) NULL,
	[num_diasoft] [varchar](100) NULL,
	[comp_type] [int] NULL,
	[id_vidDoing] [int] NULL,
	[hold_name] [varchar](250) NULL,
	[comp_tel] [varchar](150) NULL,
	[comp_site] [varchar](100) NULL,
	[comp_mail] [varchar](100) NULL,
	[comp_adress] [varchar](500) NULL,
	[id_city] [int] NULL,
	[comp_factAdress] [varchar](500) NULL,
	[id_factcity] [int] NULL,
	[comp_visible] [bit] NULL,
	[comp_OGRN] [varchar](50) NULL,
	[comp_INN] [varchar](50) NULL,
	[comp_KPP] [varchar](50) NULL,
	[comp_OKPO] [varchar](50) NULL,
	[comp_OKVED] [varchar](150) NULL,
	[comp_1podpDol] [varchar](250) NULL,
	[comp_1podpFIO] [varchar](250) NULL,
	[comp_2podpDol] [varchar](250) NULL,
	[comp_2podpFIO] [varchar](250) NULL,
	[comp_glavBuhFIO] [varchar](250) NULL,
	[comp_Rekv] [varchar](1000) NULL,
	[comp_Descr] [varchar](1000) NULL,
	[isMarket] [bit] NULL,
	[isLinkBank] [bit] NULL,
	[isZnachToBank] [int] NULL,
	[isOwnerLinkBusiness] [bit] NULL,
	[comp_segment] [varchar](100) NULL,
	[officialRating] [varchar](150) NULL,
	[comp_OKONH] [int] NULL,
	[comp_liveMinimum] [decimal](18, 2) NULL,
	[comp_ñontract] [varchar](250) NULL,
	[comp_ClearName] [varchar](250) NULL,
	[comp_dateApply] [datetime] NULL,
	[id_userApply] [int] NULL,
	[comp_estimateApply] [int] NULL,
	[needUpdateSince] [date] NULL,
	[id_hash] [int] NULL,
 CONSTRAINT [PK_rc_bank_company] PRIMARY KEY CLUSTERED 
(
	[id_company] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_comp_date]  DEFAULT (getdate()) FOR [comp_date]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_comp_type]  DEFAULT ((0)) FOR [comp_type]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_comp_visible]  DEFAULT ((1)) FOR [comp_visible]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_isMarket]  DEFAULT ((0)) FOR [isMarket]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_isLinkBank]  DEFAULT ((0)) FOR [isLinkBank]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_isZnachToBank]  DEFAULT ((0)) FOR [isZnachToBank]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_isOwnerLinkBusiness]  DEFAULT ((0)) FOR [isOwnerLinkBusiness]
GO

ALTER TABLE [dbo].[rc_bank_company] ADD  CONSTRAINT [DF_rc_bank_company_comp_liveMinimum]  DEFAULT ((0)) FOR [comp_liveMinimum]
GO



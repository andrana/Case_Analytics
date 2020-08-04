---(1.1 e 1.2) clientes por etapa do motor, considerando total de solicitantes
select 
	'volume' as [tipo],
	count(*) as [total_solicitantes],
	sum
	(case when CreditStatus in ('Reprovado') then 1 
		  else 0 
	end) as [clientes_reprovados],
	
	sum
	(case when CreditStatus in ('Bloqueado','Ativo','Aprovado') then 1 
		  else 0 
	end) as [clientes_aprovados],
	
	sum
	(case when CreditStatus in ('Bloqueado','Ativo') then 1 
		  else 0 
	end) as [clientes_contrataram_produto],
	
	sum 
	(case when CreditStatus in ('Bloqueado') then 1 
		  else 0 
	end) as [clientes_inadimplentes_bloqueados]
	from dbo.Tabela_CreditStatus

union
--calculando as taxas
select
	'taxa' as [tipo],
	(count(*)/count(*) * 1.00) as [total_solicitantes],
	cast((
	(sum
	(case when CreditStatus in ('Reprovado') then 1 
		  else 0 
	end)) * 1.0 / count(1)) as decimal(10,2)) as [clientes_reprovados],
	cast((
	(sum
	(case when CreditStatus in ('Bloqueado','Ativo','Aprovado') then 1 
		  else 0 
	end)) * 1.0 / count(1)) as decimal(10,2)) as [clientes_aprovados],
	cast((
	(sum
	(case when CreditStatus in ('Bloqueado','Ativo') then 1 
		  else 0 
	end)) * 1.0 / count(1)) as decimal(10,2)) as [clientes_contrataram_produto],
	cast((
	(sum 
	(case when CreditStatus in ('Bloqueado') then 1 
		  else 0 
	end)) * 1.0 / count(1)) as decimal(10,2)) as [clientes_inadimplentes_bloqueados]
	from dbo.Tabela_CreditStatus;

--porque descartar dezembro de 2018, e avaliar se considerarei novembro 2018:
select max(InvoiceDueDate) as ultima_fatura, dateadd(month, -2, max(InvoiceDueDate)) as data_limite_safra from dbo.Tabela_InvoiceStatus


---avaliando novembro, não considerarei a safra pois maior parte dela não teve tempo de chegar à terceira fatura
select (case when FirstInvoiceDate > '2018-11-05' then 'novembro acima data de corte’  else 'novembro abaixo data de corte end ) as contagem,
count(distinct ClientId) as qtd
from dbo.Tabela_InvoiceStatus, where FirstInvoiceDate between '2018-11-01' and '2018-11-30'
group by (case when FirstInvoiceDate > '2018-11-05' then 'novembro acima data de corte’ else 'novembro abaixo data de corte’ end )


------(2.1) Over 30 mob3 geral
select 
sum(entrantes.Qtd_clientes_safra) as Qtd_clientes_geral,
sum(inadimplentes.Qtd_clientes_inad_terceira ) as Qtd_clientes_inad_terceira
from
(
---entrantes por mês
select convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) as Safra,
count(distinct ClientId) as Qtd_clientes_safra
from dbo.Tabela_InvoiceStatus
where FirstInvoiceDate < '2018-11-01'
group by 
convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) 
)entrantes
inner join
(
----inadimplentes terceira fatura
select 
count(a.ClientId) as Qtd_clientes_terceira_fatura, 
a.Safra, b.Terceira_fatura, 
sum(b.flag_inadim) as Qtd_clientes_inad_terceira 
from
(
select
distinct ClientId,
convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) as Safra,
convert(varchar(3),dateadd(month, 2, FirstInvoiceDate),22) + convert(varchar(4),dateadd(month, 2, FirstInvoiceDate),120) as Terceiro_mes
from dbo.Tabela_InvoiceStatus
where FirstInvoiceDate < '2018-11-01'
)a
inner join
(
select 
ClientId,
convert(CHAR(3), [InvoiceDueDate], 22) + convert(CHAR(4),[InvoiceDueDate], 120) as Terceira_fatura,
(case when OverdueDays >=30 then 1 else 0 end) as flag_inadim
from dbo.Tabela_InvoiceStatus
)b
on a.ClientId = b.ClientId
and a.Terceiro_mes = b.Terceira_fatura 
group by
a.Safra, a.Terceiro_mes, b.Terceira_fatura
)inadimplentes
on entrantes.Safra = inadimplentes.Safra

------(2.2) Over 30 mob3 safras
select 
entrantes.Safra, 
entrantes.Qtd_clientes_safra,
inadimplentes.Terceira_fatura,
inadimplentes.Qtd_clientes_terceira_fatura, 
inadimplentes.Qtd_clientes_inad_terceira 
from
(
---entrantes por mês
select convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) as Safra,
count(distinct ClientId) as Qtd_clientes_safra
from dbo.Tabela_InvoiceStatus
where FirstInvoiceDate < '2018-11-01'
group by 
convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) 
)entrantes
inner join
(
----inadimplentes terceira fatura
select 
count(a.ClientId) as Qtd_clientes_terceira_fatura, 
a.Safra, b.Terceira_fatura, 
sum(b.flag_inadim) as Qtd_clientes_inad_terceira 
from
(
select
distinct ClientId,
convert(CHAR(3), FirstInvoiceDate, 22) + convert(CHAR(4),FirstInvoiceDate, 120) as Safra,
convert(varchar(3),dateadd(month, 2, FirstInvoiceDate),22) + convert(varchar(4),dateadd(month, 2, FirstInvoiceDate),120) as Terceiro_mes
from dbo.Tabela_InvoiceStatus
where FirstInvoiceDate < '2018-11-01'
)a
inner join
(
select 
ClientId,
convert(CHAR(3), [InvoiceDueDate], 22) + convert(CHAR(4),[InvoiceDueDate], 120) as Terceira_fatura,
(case when OverdueDays >=30 then 1 else 0 end) as flag_inadim
from dbo.Tabela_InvoiceStatus
)b
on a.ClientId = b.ClientId
and a.Terceiro_mes = b.Terceira_fatura 
group by
a.Safra, a.Terceiro_mes, b.Terceira_fatura
)inadimplentes
on entrantes.Safra = inadimplentes.Safra
order by entrantes.Safra asc


---(3.1)Situação das faturas por mês de vencimento, para comparar com Over30 Mob3, e constatando que dois meses
--apresentaram  taxa de inadimplência geral acima das demais para o período, tanto no aspecto geral quanto por Over 30 Mob3.
--São os meses de julho e agosto de 2018, impulsionados principalmente pela inadimplência das safras de maio e junho do mesmo ano, 
--significativas tanto em volume absoluto como por comportamento.
--Talvez seja o caso de rever a estratégia de aquisição adotada nestes meses em específico, 
--pois a tendência não se mantém nos meses imediatamente posteriores a eles.
select convert(CHAR(3), [InvoiceDueDate], 22) + convert(CHAR(4),[InvoiceDueDate], 120) as Mes_fatura, 
count(InvoiceId) as Qtd_faturas,  
InvoiceStatus 
from dbo.Tabela_InvoiceStatus
where FirstInvoiceDate < '2018-11-01'
and InvoiceDueDate <= '2018-12-31'
group by 
convert(CHAR(3), [InvoiceDueDate], 22) + convert(CHAR(4),[InvoiceDueDate], 120), 
InvoiceStatus
order by 
convert(CHAR(3), [InvoiceDueDate], 22) + convert(CHAR(4),[InvoiceDueDate], 120) asc

----(3.2) Analisando diferença de composição entre a base geral de clientes do cartão com fatura e
----aqueles que chegaram a ficar inadimplentes. Das características verificadas, a que indica diferença
----que merece análise é a PresumedIncome - Renda Presumida.
select a.ClientId, a.InvoiceStatus, b.PresumedIncome from
(
select distinct ClientId, InvoiceStatus
from dbo.Tabela_InvoiceStatus
where InvoiceStatus = 'INADIMPLENTE'
)a

inner join
(
select ClientId, PresumedIncome from dbo.Tabela_Client
)b
on a.ClientId = b.ClientId

union 

select a.ClientId, a.InvoiceStatus, b.PresumedIncome from
(
select distinct ClientId, 'GERAL' as InvoiceStatus
from dbo.Tabela_InvoiceStatus
)a

inner join
(
select ClientId, PresumedIncome from dbo.Tabela_Client
)b
on a.ClientId = b.ClientId
order by a.ClientId
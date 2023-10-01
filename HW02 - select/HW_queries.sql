USE WideWorldImporters

SELECT
	YEAR([InvoiceDate]) as [Year],
	MONTH([InvoiceDate]) as [Month],
	SUM([ExtendedPrice]) as [Revenue]
FROM [Sales].[Invoices] as i
JOIN [Sales].[InvoiceLines] as il on il.[InvoiceID] = i.[InvoiceID]
GROUP BY YEAR([InvoiceDate]), MONTH([InvoiceDate])
HAVING SUM([ExtendedPrice]) > 4600000 or 
ORDER BY [Year], [Month]
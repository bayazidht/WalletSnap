import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';

class PdfService {
  static Future<void> generateTransactionReport(
      List<TransactionModel> transactions,
      List<CategoryModel> categories,
      String date
      ) async {
    final pdf = pw.Document();

    for (var t in transactions) {
      debugPrint("Transaction: ${t.title}, Amount: ${t.amount}, Type: '${t.type}'");
    }

    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();
    incomes.sort((a, b) => a.date.compareTo(b.date));
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    expenses.sort((a, b) => a.date.compareTo(b.date));

    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final netBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("WalletSnap Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(date, style: pw.TextStyle(fontSize: 20,)),
                ]
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Net Balance: ${netBalance.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: netBalance >= 0 ? PdfColors.green : PdfColors.red)),
                  pw.Text("Generated on: ${DateTime.now().toString().split(' ')[0]}"),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          if (incomes.isNotEmpty) ...[
            pw.Text("Incomes", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            pw.Divider(color: PdfColors.green),
            _buildTransactionTable(incomes, categories),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total Income: ${totalIncome.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 30),
          ],

          if (expenses.isNotEmpty) ...[
            pw.Text("Expenses", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            pw.Divider(color: PdfColors.red),
            _buildTransactionTable(expenses, categories),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total Expense: ${totalExpense.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildTransactionTable(List<TransactionModel> items, List<CategoryModel> categories) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Title', 'Category', 'Amount'],
      data: items.map((t) {
        final category = categories.firstWhere(
              (c) => c.id == t.categoryId
        );
        return [
          t.date.toString().split(' ')[0],
          t.title,
          category.name,
          t.amount.toStringAsFixed(2),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }
}
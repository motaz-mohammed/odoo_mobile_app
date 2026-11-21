class CustomerInvoice {
  final int id;
  final String name;
  final String customerName;
  final String invoiceDate;
  final String dueDate;
  final double amountTotal;
  final double amountResidual;
  final String paymentState;

  CustomerInvoice({
    required this.id,
    required this.name,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    required this.amountTotal,
    required this.amountResidual,
    required this.paymentState,
  });

  factory CustomerInvoice.fromJson(Map<String, dynamic> json) {
    return CustomerInvoice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      customerName: json['customer_name'] ?? '',
      invoiceDate: json['invoice_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      amountResidual: (json['amount_residual'] as num?)?.toDouble() ?? 0.0,
      paymentState: json['payment_state'] ?? 'not_paid',
    );
  }
}

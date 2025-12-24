import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'supabase_tenants_service.dart';

class ExportService {
  final SupabaseTenantsService _tenantsService = SupabaseTenantsService();

  Future<void> exportTenantData() async {
    try {
      final tenants = await _tenantsService.fetchTenants();

      List<List<String>> csvData = [
        [
          'Tenant ID',
          'Name',
          'Email',
          'Phone',
          'Rent Due',
          'Last Payment Month',
          'Last Payment Date',
          'Payment History'
        ]
      ];

      for (var tenant in tenants) {
        String paymentHistoryStr = '';
        if (tenant['paymentHistory'] != null) {
          List<dynamic> paymentHistory = tenant['paymentHistory'];
          paymentHistoryStr = paymentHistory.map((p) {
            return '\${p["month"]}: \${p["status"]}';
          }).join('; ');
        }

        csvData.add([
          tenant['id'] ?? '',
          tenant['name'] ?? '',
          tenant['email'] ?? '',
          tenant['phone'] ?? '',
          tenant['rentDue']?.toString() ?? '',
          tenant['lastPaymentMonth'] ?? '',
          tenant['lastPaymentDate']?.toDate().toString() ?? '',
          paymentHistoryStr,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      const path = '\${directory.path}/tenant_data_export.csv';
      final file = File(path);

      await file.writeAsString(csv);

      // File saved to: $path
      print('Tenant data exported to: $path');

    } catch (e) {
      throw Exception('Failed to export tenant data: \$e');
    }
  }
}

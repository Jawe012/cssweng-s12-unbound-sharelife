import 'package:flutter/material.dart';

/// A reusable dropdown button widget for exporting data as PDF or XLSX
class ExportDropdownButton extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportXlsx;
  final double height;
  final double minWidth;

  const ExportDropdownButton({
    Key? key,
    this.onExportPdf,
    this.onExportXlsx,
    this.height = 28,
    this.minWidth = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'pdf' && onExportPdf != null) {
            onExportPdf!();
          } else if (value == 'xlsx' && onExportXlsx != null) {
            onExportXlsx!();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'pdf',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 18),
                SizedBox(width: 8),
                Text('Save as PDF'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'xlsx',
            child: Row(
              children: [
                Icon(Icons.table_chart, size: 18),
                SizedBox(width: 8),
                Text('Save as XLSX'),
              ],
            ),
          ),
        ],
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

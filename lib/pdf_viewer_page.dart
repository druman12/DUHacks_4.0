import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class PDFViewerPage extends StatelessWidget {
  final String filePath;

  const PDFViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        backgroundColor: Colors.blueGrey[400],
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        onPageChanged: (int? page, int? total) {
          // Optionally, you can show the current page
          print('Page $page of $total');
        },
      ),
    );
  }
}

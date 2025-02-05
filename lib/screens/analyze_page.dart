import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_analyzer/providers/history_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image_analyzer/models/history_item.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

class AnalyzePage extends StatefulWidget {
  final String? imagePath;

  const AnalyzePage({super.key, this.imagePath});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      _selectedImage = File(widget.imagePath!);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final analysisResult = {
      'tags': ['name: abubakar','age:22 ','color: black','Object: 95%', 'Vehicle: supra', 'Quality: Excellent'],
      'confidence': '92%',
      'resolution': '4000x3000',
      'fileSize': '2.4 MB'
    };

    setState(() {
      _analysisResult = analysisResult;
    });

    final newItem = HistoryItem(
      id: DateTime.now().toString(),
      imagePath: _selectedImage!.path,
      date: DateTime.now(),
      tags: (analysisResult['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );

    Provider.of<HistoryProvider>(context, listen: false).addItem(newItem);

    setState(() {
      _isAnalyzing = false;
      _selectedImage = null;
    });

    _showAnalysisDialog(analysisResult);
  }

  Future<void> _generatePdf() async {
    if (_analysisResult == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Image Analysis Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Analysis Results:',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              ..._analysisResult!['tags'].map((tag) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text('• $tag'),
                  )),
              pw.SizedBox(height: 20),
              pw.Text('Confidence: ${_analysisResult!['confidence']}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download =
            'analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      try {
        final Directory output = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final String fileName = 'analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final File file = File('${output.path}/$fileName');
        
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: ${file.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAnalysisDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AnalysisResultDialog(
        results: results,
        onDownload: _generatePdf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarGradientColors = [Colors.blue.shade900, Colors.indigo.shade700];
    final bodyGradientColors = isDark
        ? [const Color.fromARGB(255, 19, 19, 19), const Color.fromARGB(255, 19, 19, 19)]
        : [Colors.blue.shade50, Colors.white];
    final textColor = isDark ? Colors.white : Colors.blue.shade900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Analysis',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: appBarGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bodyGradientColors,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildImageSection(isDark, textColor),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedImage != null ? _startAnalysis : _pickImage,
        icon: Icon(
          _selectedImage != null ? Icons.analytics : Icons.add_photo_alternate,
          color: Colors.white,
        ),
        label: Text(
          _selectedImage != null
              ? (_isAnalyzing ? 'Analyzing...' : 'Start Analysis')
              : 'Pick Image',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _selectedImage != null ? Colors.indigo : Colors.blue.shade900,
      ),
    );
  }

  Widget _buildImageSection(bool isDark, Color textColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedImage != null
          ? Container(
              key: ValueKey(_selectedImage),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.blue.shade100,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selected Image',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      IconButton(
                        icon: Icon(Icons.close,
                            color:
                                isDark ? Colors.redAccent : Colors.red.shade700),
                        onPressed: () =>
                            setState(() => _selectedImage = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('placeholder'),
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color.fromARGB(255, 19, 19, 19) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark
                        ? Colors.grey[600]!
                        : Colors.blue.shade100, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera, size: 40, color: textColor),
                    const SizedBox(height: 15),
                    Text('No image selected',
                        style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
    );
  }
}

class AnalysisResultDialog extends StatelessWidget {
  final Map<String, dynamic> results;
  final VoidCallback onDownload;

  const AnalysisResultDialog({
    super.key,
    required this.results,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.blue.shade900;
    final backgroundColor = isDark ? Colors.grey[850] : Colors.white;
    final buttonColor = Colors.blue.shade900;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [Colors.grey[800]!, Colors.grey[850]!]
                  : [Colors.blue.shade50, Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Analysis Results',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    IconButton(
                      icon: Icon(Icons.download_rounded,
                          color: textColor, size: 30),
                      onPressed: onDownload,
                      tooltip: 'Download PDF Report',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...results['tags'].map<Widget>((tag) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(tag,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey[600]!
                            : Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: textColor, size: 28),
                      const SizedBox(width: 15),
                      Text('Confidence Level',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      const Spacer(),
                      Text(results['confidence'],
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text('Download Full Report',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dashed_border.dart';
import '../../widgets/section_card.dart';
import 'import_success_page.dart';

class ImportEmailPage extends StatefulWidget {
  const ImportEmailPage({super.key});

  @override
  State<ImportEmailPage> createState() => _ImportEmailPageState();
}

class _ImportEmailPageState extends State<ImportEmailPage> {
  final _pasteController = TextEditingController();
  static const _maxChars = 5000;
  String? _pickedFileName;
  String _fileContent = '';
  bool _importing = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  bool get _canImport =>
      !_importing &&
      (_pasteController.text.trim().isNotEmpty || _fileContent.isNotEmpty);

  Future<void> _pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result.isEmpty || result.single.path == null) return;
    final file = File(result.single.path!);
    final content = await file.readAsString();
    setState(() {
      _pickedFileName = result.single.name;
      _fileContent = content;
    });
  }

  Future<void> _import() async {
    final store = context.read<EmailStore>();
    final raw = [_fileContent, _pasteController.text]
        .where((e) => e.trim().isNotEmpty)
        .join('\n');
    setState(() => _importing = true);
    final result = await store.importFrom(raw);
    if (!mounted) return;
    setState(() => _importing = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ImportSuccessPage(result: result)),
    );
  }
  // _BODY_

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(title: Text(context.s.importEmail)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _uploadSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _pasteSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _formatSection(),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.c.textPrimary,
          ),
        ),
      );

  Widget _uploadSection() {
    final hasFile = _pickedFileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.s.importCsvSection),
        GestureDetector(
          onTap: _pickCsv,
          child: DashedBorderBox(
            color: hasFile ? AppColors.primary : context.c.border,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: hasFile
                    ? context.c.primarySoft.withValues(alpha: 0.5)
                    : context.c.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Icon(
                    hasFile
                        ? Icons.description_outlined
                        : Icons.file_upload_outlined,
                    size: 28,
                    color: hasFile ? AppColors.primary : context.c.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasFile ? _pickedFileName! : context.s.uploadHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasFile ? AppColors.primary : context.c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.s.uploadOnlyCsv,
                    style: TextStyle(fontSize: 12, color: context.c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  // _BODY2_

  Widget _pasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.s.pasteSection),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _pasteController,
                onChanged: (_) => setState(() {}),
                maxLines: 8,
                maxLength: _maxChars,
                buildCounter: (_,
                        {required currentLength, required isFocused, maxLength}) =>
                    null,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: context.c.textPrimary),
                decoration: InputDecoration(
                  hintText: context.s.pasteHint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: context.c.textSecondary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Text(
                '${_pasteController.text.length}/$_maxChars',
                style: TextStyle(fontSize: 12, color: context.c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // _BODY3_

  Widget _formatSection() {
    final rows = [
      (context.s.fieldEmail, context.s.fieldEmailDesc),
      (context.s.fieldPassword, context.s.fieldPasswordDesc),
      (context.s.fieldClientId, context.s.fieldClientIdDesc),
      (context.s.fieldRefreshToken, context.s.fieldRefreshTokenDesc),
      (context.s.fieldCreatedAt, context.s.fieldCreatedAtDesc),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.s.formatSection),
        SectionCard(
          child: Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          row.$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.c.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.$2,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.c.bg,
        border: Border(top: BorderSide(color: context.c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: _importing ? context.s.importing : context.s.importEmail,
            onPressed: _canImport ? _import : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              text: context.s.privacyPrefix,
              style: TextStyle(fontSize: 12, color: context.c.textSecondary),
              children: [
                TextSpan(
                  text: context.s.privacyPolicy,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

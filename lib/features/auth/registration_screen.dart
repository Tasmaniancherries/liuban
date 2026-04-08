import "dart:typed_data";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/session/app_session_scope.dart";
import "package:liuban/core/text/account_input_normalize.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";
import "package:liuban/data/api/auth_api.dart";

/// 註冊與身分審核：上傳 Offer／錄取證明或學生證擇一；頂部無障礙說明見 [ApiDevSemantics.registrationBanner]。
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _customId = TextEditingController();
  final _school = TextEditingController();
  final _studentId = TextEditingController();
  final _picker = ImagePicker();

  RegistrationVerificationDocumentKind _docKind =
      RegistrationVerificationDocumentKind.offerOrAdmissionProof;
  Uint8List? _documentBytes;
  String? _documentName;
  bool _submitting = false;

  bool get _hasDraft {
    return normalizeLeadingAtCustomId(_customId.text).isNotEmpty ||
        _school.text.trim().isNotEmpty ||
        _studentId.text.trim().isNotEmpty ||
        _documentBytes != null;
  }

  void _onInputChanged() => setState(() {});

  Future<void> _tryPop() async {
    if (_submitting) return;
    if (!_hasDraft) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: "捨棄註冊資料確認",
        hint: ApiDevSemantics.discardUnsavedLocalFormDialogHint,
        child: AlertDialog(
          title: const Text("捨棄註冊資料？"),
          content: const SelectionArea(child: Text("表單內容與已選圖片將不會儲存，確定離開？")),
          actions: [
            Tooltip(
              message: "繼續填寫",
              child: Semantics(
                button: true,
                label: "繼續填寫",
                hint: "關閉對話框並保留註冊表單",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("取消"),
                ),
              ),
            ),
            Tooltip(
              message: "捨棄註冊資料並離開",
              child: Semantics(
                button: true,
                label: "捨棄註冊資料並離開",
                hint: "離開並清除表單與已選圖片",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("捨棄"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && discard == true) context.pop();
  }

  @override
  void initState() {
    super.initState();
    _customId.addListener(_onInputChanged);
    _school.addListener(_onInputChanged);
    _studentId.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _customId.removeListener(_onInputChanged);
    _school.removeListener(_onInputChanged);
    _studentId.removeListener(_onInputChanged);
    _customId.dispose();
    _school.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _pickVerificationImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _documentBytes = bytes;
        _documentName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.registrationPickImageFailedMessage,
          semanticsHint: ApiDevSemantics.registrationPickImageFailedSnackHint,
        ),
      );
    }
  }

  String get _defaultMultipartFilename => switch (_docKind) {
    RegistrationVerificationDocumentKind.offerOrAdmissionProof => "offer.jpg",
    RegistrationVerificationDocumentKind.studentIdCard => "student_id_card.jpg",
  };

  String _uploadButtonLabelShort(bool hasFile) {
    if (!hasFile) {
      return switch (_docKind) {
        RegistrationVerificationDocumentKind.offerOrAdmissionProof =>
          "上傳 Offer／錄取證明",
        RegistrationVerificationDocumentKind.studentIdCard => "上傳學生證",
      };
    }
    return "重新選擇圖片";
  }

  String _uploadTooltip(bool hasFile) {
    if (!hasFile) {
      return switch (_docKind) {
        RegistrationVerificationDocumentKind.offerOrAdmissionProof =>
          "上傳 Offer 或錄取證明圖片",
        RegistrationVerificationDocumentKind.studentIdCard => "上傳學生證照片",
      };
    }
    return "重新選擇審核用圖片";
  }

  String _previewSemanticLabel() => switch (_docKind) {
    RegistrationVerificationDocumentKind.offerOrAdmissionProof =>
      "錄取證明或 Offer 預覽",
    RegistrationVerificationDocumentKind.studentIdCard => "學生證預覽",
  };

  Future<void> _submit(AppSession session) async {
    if (_submitting) return;
    final id = normalizeLeadingAtCustomId(_customId.text);
    final sch = _school.text.trim();
    final sid = _studentId.text.trim();
    if (id.isEmpty || sch.isEmpty || sid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "請填寫完整資料",
          semanticsHint: ApiDevSemantics.registrationIncompleteSnackHint,
        ),
      );
      return;
    }
    if (_documentBytes == null) {
      final msg = switch (_docKind) {
        RegistrationVerificationDocumentKind.offerOrAdmissionProof =>
          "請上傳 Offer 或錄取證明圖片",
        RegistrationVerificationDocumentKind.studentIdCard => "請上傳學生證照片",
      };
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          msg,
          semanticsHint: ApiDevSemantics.registrationDocumentRequiredSnackHint,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final container = AppContainerScope.of(context);
      final res = await container.auth.registerWithVerificationDocument(
        customId: id,
        schoolName: sch,
        studentId: sid,
        documentBytes: _documentBytes!,
        documentFilename: _documentName ?? _defaultMultipartFilename,
        verificationDocumentKind: _docKind,
      );
      final token = res.accessToken;
      if (token != null && token.isNotEmpty) {
        container.sessionTokens.applyPair(
          access: token,
          refresh: res.refreshToken,
        );
      }
      session.setPhase(AccountPhase.pendingVerification);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "已提交，審核中。通過前仍為訪客權限。",
          semanticsHint: ApiDevSemantics.registrationSubmitSuccessSnackHint,
        ),
      );
      context.pop();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.registrationApiErrorSnackHint,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.authSubmitGenericFailureMessage,
          semanticsHint: ApiDevSemantics.authSubmitGenericFailureSnackHint,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final hasDoc = _documentBytes != null;

    return PopScope(
      canPop: !_submitting && !_hasDraft,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("註冊 · 身分審核", semanticsLabel: "註冊與身分審核"),
          leading: Semantics(
            hint: "返回上一頁；表單有內容時會先詢問是否捨棄",
            child: IconButton(
              tooltip: "返回",
              icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
              onPressed: _submitting
                  ? null
                  : () =>
                        unawaitedDebug("RegistrationScreen._tryPop", _tryPop()),
            ),
          ),
        ),
        body: AutofillGroup(
          child: ListView(
            cacheExtent: kLiubanListCacheExtent,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              Semantics(
                header: true,
                label: ApiDevSemantics.registrationBanner,
                hint: "下方可選擇驗證文件類型並上傳圖片",
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    ApiDevSemantics.registrationBanner,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: "選擇審核用文件類型",
                hint: "切換後需重新選擇圖片；Offer 與學生證擇一上傳即可",
                excludeSemantics: true,
                child: SegmentedButton<RegistrationVerificationDocumentKind>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: RegistrationVerificationDocumentKind
                          .offerOrAdmissionProof,
                      label: Text("Offer／錄取"),
                      icon: Icon(Icons.description_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: RegistrationVerificationDocumentKind.studentIdCard,
                      label: Text("學生證"),
                      icon: Icon(Icons.badge_outlined, size: 18),
                    ),
                  ],
                  selected: {_docKind},
                  onSelectionChanged:
                      (Set<RegistrationVerificationDocumentKind> next) {
                        if (next.isEmpty) return;
                        setState(() {
                          _docKind = next.first;
                          _documentBytes = null;
                          _documentName = null;
                        });
                      },
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: "自訂 ID",
                hint: "作為留伴公開帳號；輸入時不需加 @",
                textField: true,
                child: TextField(
                  controller: _customId,
                  enabled: !_submitting,
                  autofillHints: const [AutofillHints.newUsername],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: "自訂 ID",
                    hintText: "例如 liuxin_2026",
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: "學校（主學校）",
                hint: "填寫主學校全名，供審核對照",
                textField: true,
                child: TextField(
                  controller: _school,
                  enabled: !_submitting,
                  autofillHints: const [AutofillHints.organizationName],
                  decoration: const InputDecoration(
                    labelText: "學校（主學校）",
                    hintText: "例如 香港大學",
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: "學號（機密，僅審核用）",
                hint: "學號為機密資料，僅用於審核；欄位已隱藏顯示",
                textField: true,
                child: TextField(
                  controller: _studentId,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: "學號（機密，僅審核用）",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_submitting) return;
                    unawaitedDebug(
                      "RegistrationScreen._submit",
                      _submit(session),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (!hasDoc)
                Semantics(
                  container: true,
                  label: switch (_docKind) {
                    RegistrationVerificationDocumentKind
                        .offerOrAdmissionProof =>
                      "請上傳 Offer 或錄取證明圖片，為必填項目",
                    RegistrationVerificationDocumentKind.studentIdCard =>
                      "請上傳學生證照片；須含可辨識之學籍資訊",
                  },
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      switch (_docKind) {
                        RegistrationVerificationDocumentKind
                            .offerOrAdmissionProof =>
                          "請上傳 Offer 或錄取證明圖片（必填）",
                        RegistrationVerificationDocumentKind.studentIdCard =>
                          "請上傳學生證照片，需清楚可辨識姓名、學校或學號（必填）",
                      },
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              if (hasDoc) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Semantics(
                    hint: switch (_docKind) {
                      RegistrationVerificationDocumentKind
                          .offerOrAdmissionProof =>
                        "已選取之 Offer 或證明圖預覽，僅供審核參考",
                      RegistrationVerificationDocumentKind.studentIdCard =>
                        "已選取之學生證預覽，僅供審核參考",
                    },
                    child: Image.memory(
                      _documentBytes!,
                      height: 160,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      semanticLabel: _previewSemanticLabel(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  container: true,
                  label: "已選檔案：${_documentName ?? "已選擇圖片"}",
                  hint: "目前選取之審核用圖檔名稱",
                  excludeSemantics: true,
                  child: Text(
                    _documentName ?? "已選擇圖片",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Tooltip(
                message: _uploadTooltip(hasDoc),
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: _uploadButtonLabelShort(hasDoc),
                  hint: "開啟相簿挑選圖片",
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                            "RegistrationScreen._pickVerificationImage",
                            _pickVerificationImage(),
                          ),
                    icon: const Icon(Icons.upload_file, semanticLabel: "上傳圖片"),
                    label: Text(_uploadButtonLabelShort(hasDoc)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Tooltip(
                message: "提交註冊資料審核",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "提交註冊資料審核",
                  hint: ApiDevSemantics.registrationSubmitHint(
                    submitting: _submitting,
                  ),
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                            "RegistrationScreen._submit",
                            _submit(session),
                          ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              semanticsLabel: "處理中",
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("提交審核"),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: "稍後再完成註冊",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "稍後再完成註冊",
                  hint: "離開註冊畫面且不提交",
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                            "RegistrationScreen._tryPop",
                            _tryPop(),
                          ),
                    child: const Text("稍後再說"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

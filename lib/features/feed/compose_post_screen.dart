import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_api_exception_snack_hint.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/feed/post_models.dart';

/// 發佈動態；若設定 [editingPostId] 則為編輯既有帖文（可帶 [initialPost] 預填）。
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key, this.editingPostId, this.initialPost});

  final String? editingPostId;
  final FeedPostDto? initialPost;

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _body = TextEditingController();
  bool _hideSchool = false;
  PostAudience _audience = PostAudience.publicSquare;
  bool _submitting = false;
  bool _formReady = false;
  bool _bootstrapping = false;

  /// 用於判斷是否需「捨棄草稿」確認（載入／建立表單後擷取一次）。
  String _baselineBody = '';
  bool _baselineHideSchool = false;
  PostAudience _baselineAudience = PostAudience.publicSquare;

  bool get _isEditing {
    final id = widget.editingPostId;
    return id != null && id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final seed = widget.initialPost;
      final id = widget.editingPostId!;
      if (seed != null && seed.id == id) {
        _applyPostToForm(seed);
        _formReady = true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaitedDebug(
            'ComposePostScreen._loadEditDraft',
            _loadEditDraft(),
          ),
        );
      }
    } else {
      _formReady = true;
      _captureBaseline();
    }
  }

  Future<void> _loadEditDraft() async {
    if (!_isEditing || !mounted) return;
    setState(() => _bootstrapping = true);
    try {
      final dto = await AppContainerScope.of(
        context,
      ).feed.getPost(widget.editingPostId!);
      if (!mounted) return;
      setState(() {
        _applyPostToForm(dto);
        _formReady = true;
        _bootstrapping = false;
      });
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      setState(() => _bootstrapping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.feedPostGetApiErrorSnackHint,
        ),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _bootstrapping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.feedPostDetailLoadFailedTitle,
          semanticsHint: ApiDevSemantics.feedPostDetailLoadFailedSemanticsHint,
        ),
      );
      if (mounted) context.pop();
    }
  }

  void _applyPostToForm(FeedPostDto dto) {
    _body.text = dto.body;
    _hideSchool = dto.hideSchool;
    final parsed = postAudienceFromApiValue(dto.audience);
    _audience = parsed ?? PostAudience.publicSquare;
    if (_hideSchool && _audience == PostAudience.schoolPeers) {
      _audience = PostAudience.friendsOnly;
    }
    _captureBaseline();
  }

  void _captureBaseline() {
    _baselineBody = _body.text;
    _baselineHideSchool = _hideSchool;
    _baselineAudience = _audience;
  }

  bool get _hasUnsavedChanges =>
      _body.text != _baselineBody ||
      _hideSchool != _baselineHideSchool ||
      _audience != _baselineAudience;

  bool get _hasValidBody {
    final text = _body.text.trim();
    return text.isNotEmpty &&
        text.length <= LiubanInputLimits.feedPostBodyMaxLength;
  }

  bool get _canSubmit => !_submitting && _hasValidBody;

  Future<void> _confirmDiscardIfNeeded() async {
    if (_submitting) return;
    if (!_hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: _isEditing ? '捨棄編輯確認' : '捨棄草稿確認',
        hint: ApiDevSemantics.discardComposeUnpublishedHint,
        child: AlertDialog(
          title: Text(_isEditing ? '捨棄編輯？' : '捨棄草稿？'),
          content: SelectionArea(
            child: Text(_isEditing ? '尚未儲存的修改將遺失。' : '內容尚未發佈，確定離開？'),
          ),
          actions: [
            Tooltip(
              message: '繼續編輯',
              child: Semantics(
                button: true,
                label: '繼續編輯',
                hint: '關閉對話框並保留目前內容',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: _isEditing ? '捨棄修改並關閉' : '捨棄草稿並關閉',
              child: Semantics(
                button: true,
                label: _isEditing ? '捨棄修改並關閉' : '捨棄草稿並關閉',
                hint: _isEditing ? '關閉並捨棄未儲存的修改' : '關閉並捨棄草稿',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('捨棄'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (discard == true) context.pop();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _onHideSchoolChanged(bool? v) {
    final next = v ?? false;
    setState(() {
      _hideSchool = next;
      if (_hideSchool && _audience == PostAudience.schoolPeers) {
        _audience = PostAudience.friendsOnly;
      }
    });
  }

  void _setAudience(PostAudience a) {
    if (a == PostAudience.schoolPeers && _hideSchool) return;
    setState(() => _audience = a);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _body.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.composePostBodyEmptyMessage,
          semanticsHint: ApiDevSemantics.composePostBodyEmptySnackHint,
        ),
      );
      return;
    }
    if (text.length > LiubanInputLimits.feedPostBodyMaxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.composePostBodyTooLongMessage(
            LiubanInputLimits.feedPostBodyMaxLength,
          ),
          semanticsHint: ApiDevSemantics.composePostBodyTooLongSnackHint(
            LiubanInputLimits.feedPostBodyMaxLength,
          ),
        ),
      );
      return;
    }
    if (_hideSchool && _audience == PostAudience.schoolPeers) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.composePostAudienceSchoolConflictMessage,
          semanticsHint:
              ApiDevSemantics.composePostAudienceSchoolConflictSnackHint,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final feed = AppContainerScope.of(context).feed;
      if (_isEditing) {
        await feed.updatePost(
          postId: widget.editingPostId!,
          body: text,
          audienceApiValue: _audience.apiValue,
          hideSchool: _hideSchool,
        );
      } else {
        await feed.createPost(
          body: text,
          audienceApiValue: _audience.apiValue,
          hideSchool: _hideSchool,
        );
      }
      if (!mounted) return;
      final summary = _isEditing
          ? "已更新 · ${_audience.shortLabel}${_hideSchool ? " · 隱藏學校" : ""}"
          : "可見：${_audience.shortLabel}${_hideSchool ? " · 隱藏學校" : ""}";
      context.pop<String>(summary);
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: liubanApiExceptionSnackHint(
            e,
            defaultHint: ApiDevSemantics.composePostApiErrorSnackHint,
            clientTooLongHint: ApiDevSemantics.composePostBodyTooLongSnackHint(
              LiubanInputLimits.feedPostBodyMaxLength,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.composePostSubmitGenericFailureMessage,
          semanticsHint:
              ApiDevSemantics.composePostSubmitGenericFailureSnackHint,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _isEditing;
    String audienceTooltip(PostAudience a) => switch (a) {
      PostAudience.publicSquare => '可見範圍：公開廣場',
      PostAudience.schoolPeers => '可見範圍：本校',
      PostAudience.friendsOnly => '可見範圍：雙向好友',
      PostAudience.selfOnly => '可見範圍：僅自己',
    };
    if (!_formReady || _bootstrapping) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            editing ? '編輯動態' : '發佈動態',
            semanticsLabel: editing ? '編輯廣場動態' : '發佈廣場動態',
          ),
          leading: Semantics(
            hint: '離開撰寫頁',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(semanticsLabel: '載入中'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscardIfNeeded();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing ? '編輯動態' : '發佈動態',
            semanticsLabel: editing ? '編輯廣場動態' : '發佈廣場動態',
          ),
          leading: Semantics(
            hint: '返回；若有未儲存變更將先詢問',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _submitting
                  ? null
                  : () => unawaitedDebug(
                      'ComposePostScreen._confirmDiscardIfNeeded',
                      _confirmDiscardIfNeeded(),
                    ),
            ),
          ),
          actions: [
            Tooltip(
              message: editing ? '儲存動態' : '發佈動態',
              child: Semantics(
                button: true,
                enabled: _canSubmit,
                label: editing ? '儲存動態' : '發佈動態',
                hint: ApiDevSemantics.composePostSubmitHint(
                  editing: editing,
                  submitting: _submitting,
                ),
                excludeSemantics: true,
                child: TextButton(
                  onPressed: !_canSubmit
                      ? null
                      : () => unawaitedDebug(
                          'ComposePostScreen._submit',
                          _submit(),
                        ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            semanticsLabel: '處理中',
                            strokeWidth: 2,
                          ),
                        )
                      : Text(editing ? '儲存' : '發佈'),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          cacheExtent: kLiubanListCacheExtent,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            Semantics(
              label: '動態內容',
              hint: editing ? '編輯此則動態正文；完成後可儲存' : '撰寫動態正文；發佈至下方所選可見範圍',
              textField: true,
              child: TextField(
                controller: _body,
                maxLines: 8,
                maxLength: LiubanInputLimits.feedPostBodyMaxLength,
                enabled: !_submitting,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: '動態內容',
                  hintText: '分享在港生活、選課、租房⋯⋯',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              label: '誰可以看',
              hint: '下方可選擇此則動態的可見對象',
              excludeSemantics: true,
              child: SelectionArea(
                child: Text(
                  '誰可以看',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...PostAudience.values.map((a) {
                  final blocked = _hideSchool && a == PostAudience.schoolPeers;
                  final chipEnabled = !_submitting && !blocked;
                  final chipLabel = blocked
                      ? '${audienceTooltip(a)}，因已隱藏學校目前不可選'
                      : '${audienceTooltip(a)}，${a.shortLabel}';
                  return Semantics(
                    button: true,
                    enabled: chipEnabled,
                    selected: _audience == a,
                    label: chipLabel,
                    hint: blocked
                        ? '已隱藏學校，同儕可見範圍暫不可用'
                        : (!_submitting ? '選取後設定此則動態的可見對象' : '送出中，暫時無法變更可見範圍'),
                    excludeSemantics: true,
                    child: ChoiceChip(
                      tooltip: audienceTooltip(a),
                      label: Text(a.shortLabel),
                      selected: _audience == a,
                      onSelected: chipEnabled ? (_) => _setAudience(a) : null,
                    ),
                  );
                }),
              ],
            ),
            if (_hideSchool) ...[
              const SizedBox(height: 4),
              Semantics(
                liveRegion: true,
                hint: '隱藏學校時「本校可見」選項不可用',
                child: SelectionArea(
                  child: Text(
                    '已開啟「隱藏學校」：不可選「本校」（僅好友或僅自己等）。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Tooltip(
              message: '切換是否在動態中顯示學校',
              child: Semantics(
                label: '動態上隱藏學校標籤',
                hint:
                    "讀者看不到你的校名；若開啟，「本校可見」將不可用。目前${_hideSchool ? "已隱藏學校標籤" : "會顯示學校標籤"}",
                enabled: !_submitting,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const SelectionArea(child: Text('動態上隱藏學校標籤')),
                  subtitle: const SelectionArea(
                    child: Text('讀者看不到你的校名；若開啟，「本校可見」將不可用。'),
                  ),
                  value: _hideSchool,
                  onChanged: _submitting ? null : _onHideSchoolChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../data/models/admin_story.dart';
import '../../data/models/admin_user_row.dart';
import '../../domain/api_providers.dart';
import '../admin/admin_users_provider.dart';
import 'story_poll_sticker.dart';
import 'story_providers.dart';

enum _TextStyleTool { size, font, color, background, alignment }

const int _targetStoryImageUploadBytes = 1536 * 1024;
const int _storyImageMaxDimension = 1440;
const Duration _shareLoadingChoiceDelay = Duration(seconds: 3);
const Duration _textStoryShareTimeout = Duration(seconds: 20);
const Duration _imageStoryShareTimeout = Duration(seconds: 55);

enum _ShareLoadingAction { stop, wait }

String _newStoryClientRequestId() {
  final nonce = math.Random().nextInt(0x7fffffff).toRadixString(16);
  return '${DateTime.now().microsecondsSinceEpoch}-$nonce';
}

Uint8List _compressStoryImageFallback(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final oriented = img.bakeOrientation(decoded);
  final longestSide = math.max(oriented.width, oriented.height);
  final scale = longestSide > _storyImageMaxDimension
      ? _storyImageMaxDimension / longestSide
      : 1.0;
  final resized = scale < 1
      ? img.copyResize(
          oriented,
          width: (oriented.width * scale).round(),
          height: (oriented.height * scale).round(),
          interpolation: img.Interpolation.average,
        )
      : oriented;
  var working = resized;
  for (final quality in const [78, 68, 58, 48]) {
    final jpg = img.encodeJpg(working, quality: quality);
    if (jpg.length <= _targetStoryImageUploadBytes || quality == 48) {
      return Uint8List.fromList(jpg);
    }
    working = img.copyResize(
      working,
      width: math.max(480, (working.width * 0.82).round()),
      height: math.max(480, (working.height * 0.82).round()),
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(working, quality: 48));
}

class AdminStoryCreateScreen extends ConsumerStatefulWidget {
  const AdminStoryCreateScreen({super.key});

  @override
  ConsumerState<AdminStoryCreateScreen> createState() =>
      _AdminStoryCreateScreenState();
}

class _AdminStoryCreateScreenState
    extends ConsumerState<AdminStoryCreateScreen> {
  final _selectedUsers = <int>{};
  final _editingCtrl = TextEditingController();
  final _editingFocus = FocusNode();

  var _mode = 'text';
  var _submitting = false;
  var _shareCanChoose = false;
  Timer? _shareChoiceTimer;
  Completer<void>? _shareStopCompleter;
  int _shareOperationId = 0;
  final _storyClientRequestId = _newStoryClientRequestId();
  Uint8List? _imageBytes;
  var _imageTransform = const StoryImageTransform();
  var _layers = <StoryTextLayer>[];
  StoryPoll? _poll;

  var _fontSize = 36.0;
  var _fontFamily = 'Default';
  var _textColor = 0xFFFFFFFF;
  var _bgStart = 0xFF833AB4;
  var _bgEnd = 0xFFF77737;
  var _alignment = 'center';
  _TextStyleTool? _activeTextTool;

  int? _editingIndex;
  StoryTextLayer? _editingDraft;
  int? _activeLayerGestureIndex;
  double? _activeLayerStartScale;
  double? _activePollStartScale;
  var _deleteTargetActive = false;
  Offset? _imageStartFocal;
  StoryImageTransform? _imageStartTransform;

  bool get _isEditingText => _editingDraft != null;

  StoryTextStyle get _style => StoryTextStyle(
    fontSize: _fontSize,
    fontFamily: _fontFamily,
    textColor: _textColor,
    backgroundStart: _bgStart,
    backgroundEnd: _bgEnd,
    alignment: _alignment,
    layers: _layers,
    imageTransform: _imageTransform,
    poll: _poll,
  );

  bool get _storyIsValid {
    if (_isEditingText || _submitting) return false;
    if (_mode == 'image') return _imageBytes != null;
    return _layers.any((layer) => layer.text.trim().isNotEmpty) ||
        _poll != null;
  }

  @override
  void dispose() {
    _shareChoiceTimer?.cancel();
    final stopCompleter = _shareStopCompleter;
    if (stopCompleter != null && !stopCompleter.isCompleted) {
      stopCompleter.complete();
    }
    _editingCtrl.dispose();
    _editingFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1080,
      maxHeight: 1920,
    );
    if (x == null) return;
    late final Uint8List compressed;
    try {
      final original = await x.readAsBytes();
      compressed = await _compressStoryImage(original);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanStoryError(e, 'Could not prepare image'))),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _imageBytes = compressed;
      _mode = 'image';
      _imageTransform = const StoryImageTransform();
    });
  }

  Future<Uint8List> _compressStoryImage(Uint8List bytes) async {
    Uint8List best = bytes;
    try {
      final out = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _storyImageMaxDimension,
        minHeight: _storyImageMaxDimension,
        quality: 72,
        keepExif: false,
      );
      if (out.isNotEmpty && out.length < best.length) {
        best = Uint8List.fromList(out);
      }
    } catch (_) {
      // Desktop builds may not support flutter_image_compress; use Dart fallback.
    }
    if (best.length <= _targetStoryImageUploadBytes) return best;
    final fallback = await compute(_compressStoryImageFallback, bytes);
    if (fallback.length < best.length) best = fallback;
    if (best.length > _targetStoryImageUploadBytes * 2) {
      throw Exception('Image is too large. Please choose a smaller photo.');
    }
    return best;
  }

  void _startNewText(Offset localPosition, Size canvasSize) {
    if (_isEditingText || _submitting) return;
    final x = (localPosition.dx / canvasSize.width).clamp(0.08, 0.92);
    final y = (localPosition.dy / canvasSize.height).clamp(0.08, 0.92);
    final layer = StoryTextLayer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
      x: x.toDouble(),
      y: y.toDouble(),
      fontSize: _fontSize,
      fontFamily: _fontFamily,
      textColor: _textColor,
      alignment: _alignment,
    );
    setState(() {
      _editingIndex = null;
      _editingDraft = layer;
      _editingCtrl.text = '';
      _activeTextTool = null;
    });
    _requestTextFocus();
  }

  void _editLayer(int index) {
    if (_submitting || index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    setState(() {
      _editingIndex = index;
      _editingDraft = layer;
      _editingCtrl.text = layer.text;
      _fontSize = layer.fontSize;
      _fontFamily = layer.fontFamily;
      _textColor = layer.textColor;
      _alignment = layer.alignment;
      _activeTextTool = null;
    });
    _requestTextFocus();
  }

  void _requestTextFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editingFocus.requestFocus();
    });
  }

  void _updateEditingText(String value) {
    final draft = _editingDraft;
    if (draft == null) return;
    setState(() => _editingDraft = draft.copyWith(text: value));
  }

  void _updateEditingStyle({
    double? fontSize,
    String? fontFamily,
    int? textColor,
    String? alignment,
  }) {
    final draft = _editingDraft;
    setState(() {
      if (fontSize != null) _fontSize = fontSize;
      if (fontFamily != null) _fontFamily = fontFamily;
      if (textColor != null) _textColor = textColor;
      if (alignment != null) _alignment = alignment;
      if (draft != null) {
        _editingDraft = draft.copyWith(
          fontSize: fontSize ?? draft.fontSize,
          fontFamily: fontFamily ?? draft.fontFamily,
          textColor: textColor ?? draft.textColor,
          alignment: alignment ?? draft.alignment,
        );
      }
    });
  }

  void _toggleTextTool(_TextStyleTool tool) {
    setState(() {
      _activeTextTool = _activeTextTool == tool ? null : tool;
    });
  }

  void _doneEditingText() {
    final draft = _editingDraft;
    if (draft == null) return;
    final text = _editingCtrl.text.trim();
    setState(() {
      if (text.isNotEmpty) {
        final finalized = draft.copyWith(text: text);
        final index = _editingIndex;
        if (index == null) {
          _layers = [..._layers, finalized];
        } else {
          _layers = [
            for (var i = 0; i < _layers.length; i++)
              i == index ? finalized : _layers[i],
          ];
        }
      }
      _clearEditing();
    });
  }

  void _cancelEditingText() {
    setState(() => _clearEditing());
  }

  void _clearEditing() {
    _editingIndex = null;
    _editingDraft = null;
    _editingCtrl.clear();
    _editingFocus.unfocus();
    _activeTextTool = null;
  }

  void _startLayerTransform(int index, ScaleStartDetails details) {
    if (_isEditingText || index < 0 || index >= _layers.length) return;
    setState(() {
      _activeLayerGestureIndex = index;
      _activeLayerStartScale = _layers[index].scale;
      _deleteTargetActive = false;
    });
  }

  void _transformLayer(int index, ScaleUpdateDetails details, Size canvasSize) {
    if (_isEditingText || index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    final startScale = _activeLayerGestureIndex == index
        ? _activeLayerStartScale ?? layer.scale
        : layer.scale;
    final nextX = (layer.x + details.focalPointDelta.dx / canvasSize.width)
        .clamp(0.02, 0.98)
        .toDouble();
    final nextY = (layer.y + details.focalPointDelta.dy / canvasSize.height)
        .clamp(0.02, 0.98)
        .toDouble();
    setState(() {
      _layers = [
        for (var i = 0; i < _layers.length; i++)
          i == index
              ? layer.copyWith(
                  x: nextX,
                  y: nextY,
                  scale: details.pointerCount > 1
                      ? (startScale * details.scale).clamp(0.55, 3.0)
                      : layer.scale,
                )
              : _layers[i],
      ];
      _deleteTargetActive = _isLayerOverDeleteTarget(
        x: nextX,
        y: nextY,
        canvasSize: canvasSize,
      );
    });
  }

  void _endLayerTransform(int index) {
    if (_activeLayerGestureIndex != index) {
      return;
    }
    setState(() {
      if (_deleteTargetActive && index >= 0 && index < _layers.length) {
        _layers = [
          for (var i = 0; i < _layers.length; i++)
            if (i != index) _layers[i],
        ];
      }
      _activeLayerGestureIndex = null;
      _activeLayerStartScale = null;
      _deleteTargetActive = false;
    });
  }

  bool _isLayerOverDeleteTarget({
    required double x,
    required double y,
    required Size canvasSize,
  }) {
    final layerCenter = Offset(x * canvasSize.width, y * canvasSize.height);
    final targetCenter = Offset(canvasSize.width / 2, canvasSize.height - 70);
    return (layerCenter - targetCenter).distance <= 72;
  }

  Future<void> _openPollEditor() async {
    if (_submitting || _isEditingText) return;
    final result = await showModalBottomSheet<_PollEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PollEditorSheet(existing: _poll),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.delete) {
        _poll = null;
      } else if (result.poll != null) {
        _poll = result.poll;
      }
    });
  }

  void _startPollTransform(ScaleStartDetails details) {
    if (_isEditingText || _poll == null) return;
    _activePollStartScale = _poll!.scale;
  }

  void _transformPoll(ScaleUpdateDetails details, Size canvasSize) {
    final poll = _poll;
    if (_isEditingText || poll == null) return;
    final startScale = _activePollStartScale ?? poll.scale;
    setState(() {
      _poll = poll.copyWith(
        x: (poll.x + details.focalPointDelta.dx / canvasSize.width)
            .clamp(0.08, 0.92)
            .toDouble(),
        y: (poll.y + details.focalPointDelta.dy / canvasSize.height)
            .clamp(0.12, 0.88)
            .toDouble(),
        scale: details.pointerCount > 1
            ? (startScale * details.scale).clamp(0.75, 1.45).toDouble()
            : poll.scale,
      );
    });
  }

  void _startImageTransform(ScaleStartDetails details) {
    if (_mode != 'image' || _imageBytes == null || _isEditingText) return;
    _imageStartFocal = details.focalPoint;
    _imageStartTransform = _imageTransform;
  }

  void _updateImageTransform(ScaleUpdateDetails details, Size canvasSize) {
    final start = _imageStartTransform;
    final focal = _imageStartFocal;
    if (_mode != 'image' ||
        _imageBytes == null ||
        _isEditingText ||
        start == null ||
        focal == null) {
      return;
    }
    final delta = details.focalPoint - focal;
    setState(() {
      _imageTransform = StoryImageTransform(
        x: start.x + delta.dx / canvasSize.width,
        y: start.y + delta.dy / canvasSize.height,
        scale: (start.scale * details.scale).clamp(0.45, 4.0),
      );
    });
  }

  void _scheduleShareChoices(int operationId) {
    _shareChoiceTimer?.cancel();
    _shareChoiceTimer = Timer(_shareLoadingChoiceDelay, () {
      if (!mounted || !_submitting || _shareOperationId != operationId) return;
      setState(() => _shareCanChoose = true);
    });
  }

  void _stopActiveShare() {
    final stopCompleter = _shareStopCompleter;
    if (stopCompleter != null && !stopCompleter.isCompleted) {
      stopCompleter.complete();
    }
    _shareChoiceTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _shareCanChoose = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing stopped.')));
  }

  void _waitForActiveShare() {
    if (!_submitting) return;
    setState(() => _shareCanChoose = false);
    _scheduleShareChoices(_shareOperationId);
  }

  Future<void> _showShareLoadingChoices() async {
    if (!_submitting || !_shareCanChoose) return;
    final action = await showDialog<_ShareLoadingAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Still sharing?'),
        content: const Text('You can stop sharing now, or wait a bit longer.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ShareLoadingAction.wait),
            child: const Text('Wait'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.of(context).pop(_ShareLoadingAction.stop),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ShareLoadingAction.stop:
        _stopActiveShare();
        break;
      case _ShareLoadingAction.wait:
        _waitForActiveShare();
        break;
    }
  }

  Future<void> _performSubmitStory({
    required String targetMode,
    required List<int> targetUserIds,
  }) async {
    final api = ref.read(apiServiceProvider);
    final textContent = _layers
        .map((layer) => layer.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
    if (_mode == 'image') {
      final path = await api.uploadStoryImage(_imageBytes!);
      await api.createAdminStory(
        clientRequestId: _storyClientRequestId,
        contentType: 'image',
        imagePath: path,
        textContent: textContent.isEmpty ? null : textContent,
        textStyle: _style,
        targetMode: targetMode,
        targetUserIds: targetUserIds,
      );
    } else {
      await api.createAdminStory(
        clientRequestId: _storyClientRequestId,
        contentType: 'text',
        textContent: textContent,
        textStyle: _style,
        targetMode: targetMode,
        targetUserIds: targetUserIds,
      );
    }
    if (!mounted) return;
    ref.invalidate(visibleStoriesProvider);
    ref.invalidate(adminStoriesProvider);
  }

  Future<bool> _submitStory({
    required String targetMode,
    List<int> targetUserIds = const [],
  }) async {
    if (!_storyIsValid) return false;
    final operationId = ++_shareOperationId;
    final stopCompleter = Completer<void>();
    _shareStopCompleter = stopCompleter;
    final timeout = _mode == 'image'
        ? _imageStoryShareTimeout
        : _textStoryShareTimeout;
    setState(() {
      _submitting = true;
      _shareCanChoose = false;
    });
    _scheduleShareChoices(operationId);
    final submitFuture = _performSubmitStory(
      targetMode: targetMode,
      targetUserIds: targetUserIds,
    );
    unawaited(submitFuture.catchError((_) {}));
    try {
      return await Future.any<bool>([
        submitFuture.then((_) => true),
        stopCompleter.future.then((_) => false),
        Future<void>.delayed(timeout).then<bool>((_) {
          throw TimeoutException(
            _mode == 'image'
                ? 'Image story sharing is taking too long. Please check your connection and try again.'
                : 'Story sharing is taking too long. Please check your connection and try again.',
          );
        }),
      ]);
    } catch (e) {
      if (mounted && !stopCompleter.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanStoryError(e, 'Could not share story'))),
        );
      }
      return false;
    } finally {
      if (mounted && _shareOperationId == operationId) {
        _shareChoiceTimer?.cancel();
        _shareStopCompleter = null;
        setState(() {
          _submitting = false;
          _shareCanChoose = false;
        });
      }
    }
  }

  String _cleanStoryError(Object error, String fallback) {
    final text = error.toString().trim();
    if (text.isEmpty) return fallback;
    return text
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^TimeoutException:\s*'), '');
  }

  Future<void> _shareToAll() async {
    final ok = await _submitStory(targetMode: 'all');
    if (!mounted || !ok) return;
    context.pop();
  }

  Future<void> _openSpecificUsersSheet() async {
    if (!_storyIsValid) return;
    final shared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpecificUsersSheet(
        selectedUsers: _selectedUsers,
        onSelectionChanged: () => setState(() {}),
        onStopShare: _stopActiveShare,
        onWaitShare: _waitForActiveShare,
        onShare: () => _submitStory(
          targetMode: 'specific',
          targetUserIds: _selectedUsers.toList(),
        ),
      ),
    );
    if (!mounted || shared != true) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _storyIsValid;
    return Scaffold(
      backgroundColor: const Color(0xFF07080D),
      body: Column(
        children: [
          Expanded(
            child: _StoryEditorCanvas(
              mode: _mode,
              imageBytes: _imageBytes,
              imageTransform: _imageTransform,
              layers: _layers,
              poll: _poll,
              editingIndex: _editingIndex,
              editingDraft: _editingDraft,
              editingController: _editingCtrl,
              editingFocus: _editingFocus,
              style: _style,
              submitting: _submitting,
              submittingCanChoose: _shareCanChoose,
              onSubmittingOverlayTap: _showShareLoadingChoices,
              onBack: () => context.pop(),
              onModeChanged: (mode) => setState(() => _mode = mode),
              onPickImage: _pickImage,
              onCanvasTap: _startNewText,
              onTextChanged: _updateEditingText,
              onDoneText: _doneEditingText,
              onCancelText: _cancelEditingText,
              onEditLayer: _editLayer,
              onLayerScaleStart: _startLayerTransform,
              onLayerScaleUpdate: _transformLayer,
              onLayerScaleEnd: _endLayerTransform,
              onPollTap: _openPollEditor,
              onPollScaleStart: _startPollTransform,
              onPollScaleUpdate: _transformPoll,
              onImageScaleStart: _startImageTransform,
              onImageScaleUpdate: _updateImageTransform,
              fontSize: _fontSize,
              fontFamily: _fontFamily,
              textColor: _textColor,
              bgStart: _bgStart,
              bgEnd: _bgEnd,
              alignment: _alignment,
              activeTextTool: _activeTextTool,
              showLayerDeleteTarget:
                  _activeLayerGestureIndex != null && !_isEditingText,
              layerDeleteTargetActive: _deleteTargetActive,
              onTextToolTap: _toggleTextTool,
              onAddPoll: _openPollEditor,
              onFontSize: (value) => _updateEditingStyle(fontSize: value),
              onFontFamily: (value) => _updateEditingStyle(fontFamily: value),
              onTextColor: (value) => _updateEditingStyle(textColor: value),
              onBackground: (start, end) => setState(() {
                _bgStart = start;
                _bgEnd = end;
              }),
              onAlignment: (value) => _updateEditingStyle(alignment: value),
            ),
          ),
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: !_isEditingText
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _submitting ? _showShareLoadingChoices : null,
                    child: _BottomShareBar(
                      canShare: canShare,
                      submitting: _submitting,
                      onYourStory: _shareToAll,
                      onSpecificUsers: _openSpecificUsersSheet,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StoryEditorCanvas extends StatelessWidget {
  const _StoryEditorCanvas({
    required this.mode,
    required this.imageBytes,
    required this.imageTransform,
    required this.layers,
    required this.poll,
    required this.editingIndex,
    required this.editingDraft,
    required this.editingController,
    required this.editingFocus,
    required this.style,
    required this.submitting,
    required this.submittingCanChoose,
    required this.onSubmittingOverlayTap,
    required this.onBack,
    required this.onModeChanged,
    required this.onPickImage,
    required this.onCanvasTap,
    required this.onTextChanged,
    required this.onDoneText,
    required this.onCancelText,
    required this.onEditLayer,
    required this.onLayerScaleStart,
    required this.onLayerScaleUpdate,
    required this.onLayerScaleEnd,
    required this.onPollTap,
    required this.onPollScaleStart,
    required this.onPollScaleUpdate,
    required this.onImageScaleStart,
    required this.onImageScaleUpdate,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.bgStart,
    required this.bgEnd,
    required this.alignment,
    required this.activeTextTool,
    required this.showLayerDeleteTarget,
    required this.layerDeleteTargetActive,
    required this.onTextToolTap,
    required this.onAddPoll,
    required this.onFontSize,
    required this.onFontFamily,
    required this.onTextColor,
    required this.onBackground,
    required this.onAlignment,
  });

  final String mode;
  final Uint8List? imageBytes;
  final StoryImageTransform imageTransform;
  final List<StoryTextLayer> layers;
  final StoryPoll? poll;
  final int? editingIndex;
  final StoryTextLayer? editingDraft;
  final TextEditingController editingController;
  final FocusNode editingFocus;
  final StoryTextStyle style;
  final bool submitting;
  final bool submittingCanChoose;
  final VoidCallback onSubmittingOverlayTap;
  final VoidCallback onBack;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onPickImage;
  final void Function(Offset localPosition, Size canvasSize) onCanvasTap;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDoneText;
  final VoidCallback onCancelText;
  final ValueChanged<int> onEditLayer;
  final void Function(int index, ScaleStartDetails details) onLayerScaleStart;
  final void Function(int index, ScaleUpdateDetails details, Size canvasSize)
  onLayerScaleUpdate;
  final ValueChanged<int> onLayerScaleEnd;
  final VoidCallback onPollTap;
  final ValueChanged<ScaleStartDetails> onPollScaleStart;
  final void Function(ScaleUpdateDetails details, Size canvasSize)
  onPollScaleUpdate;
  final ValueChanged<ScaleStartDetails> onImageScaleStart;
  final void Function(ScaleUpdateDetails details, Size canvasSize)
  onImageScaleUpdate;
  final double fontSize;
  final String fontFamily;
  final int textColor;
  final int bgStart;
  final int bgEnd;
  final String alignment;
  final _TextStyleTool? activeTextTool;
  final bool showLayerDeleteTarget;
  final bool layerDeleteTargetActive;
  final ValueChanged<_TextStyleTool> onTextToolTap;
  final VoidCallback onAddPoll;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onFontFamily;
  final ValueChanged<int> onTextColor;
  final void Function(int start, int end) onBackground;
  final ValueChanged<String> onAlignment;

  bool get isEditing => editingDraft != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeTop = MediaQuery.paddingOf(context).top;
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (!isEditing) {
                    onCanvasTap(details.localPosition, canvasSize);
                  }
                },
                onScaleStart: onImageScaleStart,
                onScaleUpdate: (details) =>
                    onImageScaleUpdate(details, canvasSize),
                child: _StoryBackground(
                  mode: mode,
                  imageBytes: imageBytes,
                  imageTransform: imageTransform,
                  style: style,
                  onPickImage: onPickImage,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < layers.length; i++)
                if (!(isEditing && editingIndex == i))
                  _PositionedTextLayer(
                    layer: layers[i],
                    canvasSize: canvasSize,
                    onTap: () => onEditLayer(i),
                    onScaleStart: (details) => onLayerScaleStart(i, details),
                    onScaleUpdate: (details) =>
                        onLayerScaleUpdate(i, details, canvasSize),
                    onScaleEnd: () => onLayerScaleEnd(i),
                  ),
              if (editingDraft != null)
                _EditingTextLayer(
                  layer: editingDraft!,
                  canvasSize: canvasSize,
                  controller: editingController,
                  focusNode: editingFocus,
                  onChanged: onTextChanged,
                ),
              if (poll != null && !isEditing)
                _PositionedPollSticker(
                  poll: poll!,
                  canvasSize: canvasSize,
                  onTap: onPollTap,
                  onScaleStart: onPollScaleStart,
                  onScaleUpdate: (details) =>
                      onPollScaleUpdate(details, canvasSize),
                ),
              if (showLayerDeleteTarget)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: _LayerDeleteTarget(active: layerDeleteTargetActive),
                ),
              Positioned(
                top: safeTop + 14,
                left: 14,
                right: 14,
                child: isEditing
                    ? _TextEditingTopBar(
                        onCancel: onCancelText,
                        onDone: onDoneText,
                      )
                    : _NormalTopBar(
                        mode: mode,
                        onBack: onBack,
                        onModeChanged: onModeChanged,
                      ),
              ),
              if (!isEditing)
                Positioned(
                  top: safeTop + 70,
                  right: 14,
                  child: _IdleToolRail(
                    mode: mode,
                    onPickImage: onPickImage,
                    onAddPoll: onAddPoll,
                  ),
                ),
              if (isEditing)
                Positioned(
                  top: safeTop + 70,
                  left: 14,
                  right: 14,
                  child: _TextStyleBar(
                    mode: mode,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    textColor: textColor,
                    bgStart: bgStart,
                    bgEnd: bgEnd,
                    alignment: alignment,
                    activeTool: activeTextTool,
                    onToolTap: onTextToolTap,
                    onFontSize: onFontSize,
                    onFontFamily: onFontFamily,
                    onTextColor: onTextColor,
                    onBackground: onBackground,
                    onAlignment: onAlignment,
                  ),
                ),
              if (submitting)
                Positioned.fill(
                  child: _ShareLoadingOverlay(
                    canChoose: submittingCanChoose,
                    onTap: onSubmittingOverlayTap,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShareLoadingOverlay extends StatelessWidget {
  const _ShareLoadingOverlay({required this.canChoose, required this.onTap});

  final bool canChoose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canChoose ? onTap : null,
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  if (canChoose) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Tap for Stop / Wait',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryBackground extends StatelessWidget {
  const _StoryBackground({
    required this.mode,
    required this.imageBytes,
    required this.imageTransform,
    required this.style,
    required this.onPickImage,
  });

  final String mode;
  final Uint8List? imageBytes;
  final StoryImageTransform imageTransform;
  final StoryTextStyle style;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    if (mode == 'image') {
      if (imageBytes == null) {
        return Material(
          color: const Color(0xFF1B1D24),
          child: InkWell(
            onTap: onPickImage,
            child: const Center(
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 62,
                color: Colors.white70,
              ),
            ),
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          return Transform.translate(
            offset: Offset(
              imageTransform.x * constraints.maxWidth,
              imageTransform.y * constraints.maxHeight,
            ),
            child: Transform.scale(
              scale: imageTransform.scale,
              child: Image.memory(
                imageBytes!,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(style.backgroundStart), Color(style.backgroundEnd)],
        ),
      ),
    );
  }
}

class _PositionedTextLayer extends StatelessWidget {
  const _PositionedTextLayer({
    required this.layer,
    required this.canvasSize,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final StoryTextLayer layer;
  final Size canvasSize;
  final VoidCallback onTap;
  final ValueChanged<ScaleStartDetails> onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  final VoidCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    final width = canvasSize.width * 0.78;
    const height = 170.0;
    return Positioned(
      left: (layer.x * canvasSize.width) - width / 2,
      top: (layer.y * canvasSize.height) - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: (_) => onScaleEnd(),
        child: Center(child: StoryLayerText(layer: layer)),
      ),
    );
  }
}

class _PositionedPollSticker extends StatelessWidget {
  const _PositionedPollSticker({
    required this.poll,
    required this.canvasSize,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  final StoryPoll poll;
  final Size canvasSize;
  final VoidCallback onTap;
  final ValueChanged<ScaleStartDetails> onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final width = poll.usesCompactTwoOptionLayout ? 330.0 : 280.0;
    final height = poll.usesCompactTwoOptionLayout ? 175.0 : 245.0;
    return Positioned(
      left: (poll.x * canvasSize.width) - width / 2,
      top: (poll.y * canvasSize.height) - height / 2,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: Transform.scale(
          scale: poll.scale,
          child: StoryPollSticker(poll: poll, showResults: false, onTap: onTap),
        ),
      ),
    );
  }
}

class _LayerDeleteTarget extends StatelessWidget {
  const _LayerDeleteTarget({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: active ? 78 : 58,
          height: active ? 78 : 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFFE53935).withValues(alpha: 0.92)
                : Colors.black.withValues(alpha: 0.48),
            border: Border.all(
              color: active ? Colors.white : Colors.white30,
              width: active ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (active ? const Color(0xFFE53935) : Colors.black)
                    .withValues(alpha: active ? 0.42 : 0.24),
                blurRadius: active ? 24 : 12,
                spreadRadius: active ? 3 : 0,
              ),
            ],
          ),
          child: AnimatedScale(
            scale: active ? 1.18 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            child: Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: active ? 38 : 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditingTextLayer extends StatelessWidget {
  const _EditingTextLayer({
    required this.layer,
    required this.canvasSize,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final StoryTextLayer layer;
  final Size canvasSize;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final width = canvasSize.width * 0.82;
    const height = 180.0;
    return Positioned(
      left: (layer.x * canvasSize.width) - width / 2,
      top: (layer.y * canvasSize.height) - height / 2,
      width: width,
      height: height,
      child: Center(
        child: Transform.scale(
          scale: layer.scale,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textAlign: _textAlign(layer.alignment),
            onChanged: onChanged,
            cursorColor: Color(layer.textColor),
            backgroundCursorColor: Colors.white24,
            style: StoryLayerText.textStyle(layer),
            maxLines: null,
            selectionColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class StoryLayerText extends StatelessWidget {
  const StoryLayerText({super.key, required this.layer});

  final StoryTextLayer layer;

  static TextStyle textStyle(StoryTextLayer layer) {
    return TextStyle(
      color: Color(layer.textColor),
      fontSize: layer.fontSize,
      fontFamily: layer.fontFamily == 'Default' ? null : layer.fontFamily,
      fontWeight: FontWeight.w900,
      height: 1.12,
      shadows: const [
        Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: layer.rotation,
      child: Transform.scale(
        scale: layer.scale,
        child: Text(
          layer.text,
          textAlign: _textAlign(layer.alignment),
          style: textStyle(layer),
        ),
      ),
    );
  }
}

TextAlign _textAlign(String alignment) {
  return switch (alignment) {
    'left' => TextAlign.left,
    'right' => TextAlign.right,
    _ => TextAlign.center,
  };
}

class _NormalTopBar extends StatelessWidget {
  const _NormalTopBar({
    required this.mode,
    required this.onBack,
    required this.onModeChanged,
  });

  final String mode;
  final VoidCallback onBack;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundToolButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: _GlassPanel(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'text', label: Text('Text')),
                ButtonSegment(value: 'image', label: Text('Image')),
              ],
              selected: {mode},
              onSelectionChanged: (v) => onModeChanged(v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextEditingTopBar extends StatelessWidget {
  const _TextEditingTopBar({required this.onCancel, required this.onDone});

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassTextButton(label: 'Cancel', onTap: onCancel),
        const Spacer(),
        _GlassTextButton(label: 'Done', onTap: onDone),
      ],
    );
  }
}

class _IdleToolRail extends StatelessWidget {
  const _IdleToolRail({
    required this.mode,
    required this.onPickImage,
    required this.onAddPoll,
  });

  final String mode;
  final VoidCallback onPickImage;
  final VoidCallback onAddPoll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundToolButton(icon: Icons.poll_rounded, onTap: onAddPoll),
        if (mode == 'image') ...[
          const SizedBox(height: 10),
          _RoundToolButton(
            icon: Icons.photo_library_rounded,
            onTap: onPickImage,
          ),
        ],
      ],
    );
  }
}

class _TextStyleBar extends StatelessWidget {
  const _TextStyleBar({
    required this.mode,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.bgStart,
    required this.bgEnd,
    required this.alignment,
    required this.activeTool,
    required this.onToolTap,
    required this.onFontSize,
    required this.onFontFamily,
    required this.onTextColor,
    required this.onBackground,
    required this.onAlignment,
  });

  final String mode;
  final double fontSize;
  final String fontFamily;
  final int textColor;
  final int bgStart;
  final int bgEnd;
  final String alignment;
  final _TextStyleTool? activeTool;
  final ValueChanged<_TextStyleTool> onToolTap;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onFontFamily;
  final ValueChanged<int> onTextColor;
  final void Function(int start, int end) onBackground;
  final ValueChanged<String> onAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: activeTool == null
                ? const SizedBox.shrink()
                : _GlassPanel(
                    key: ValueKey(activeTool),
                    child: _TextToolDetails(
                      activeTool: activeTool!,
                      mode: mode,
                      fontSize: fontSize,
                      fontFamily: fontFamily,
                      textColor: textColor,
                      bgStart: bgStart,
                      bgEnd: bgEnd,
                      alignment: alignment,
                      onFontSize: onFontSize,
                      onFontFamily: onFontFamily,
                      onTextColor: onTextColor,
                      onBackground: onBackground,
                      onAlignment: onAlignment,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        _VerticalTextToolRail(
          mode: mode,
          activeTool: activeTool,
          textColor: textColor,
          bgStart: bgStart,
          bgEnd: bgEnd,
          alignment: alignment,
          onToolTap: onToolTap,
        ),
      ],
    );
  }
}

class _VerticalTextToolRail extends StatelessWidget {
  const _VerticalTextToolRail({
    required this.mode,
    required this.activeTool,
    required this.textColor,
    required this.bgStart,
    required this.bgEnd,
    required this.alignment,
    required this.onToolTap,
  });

  final String mode;
  final _TextStyleTool? activeTool;
  final int textColor;
  final int bgStart;
  final int bgEnd;
  final String alignment;
  final ValueChanged<_TextStyleTool> onToolTap;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TextToolButton(
            icon: Icons.format_size_rounded,
            selected: activeTool == _TextStyleTool.size,
            onTap: () => onToolTap(_TextStyleTool.size),
          ),
          const SizedBox(height: 8),
          _TextToolButton(
            icon: Icons.font_download_rounded,
            selected: activeTool == _TextStyleTool.font,
            onTap: () => onToolTap(_TextStyleTool.font),
          ),
          const SizedBox(height: 8),
          _ColorToolButton(
            color: Color(textColor),
            selected: activeTool == _TextStyleTool.color,
            onTap: () => onToolTap(_TextStyleTool.color),
          ),
          if (mode == 'text') ...[
            const SizedBox(height: 8),
            _GradientToolButton(
              start: bgStart,
              end: bgEnd,
              selected: activeTool == _TextStyleTool.background,
              onTap: () => onToolTap(_TextStyleTool.background),
            ),
          ],
          const SizedBox(height: 8),
          _TextToolButton(
            icon: switch (alignment) {
              'left' => Icons.format_align_left,
              'right' => Icons.format_align_right,
              _ => Icons.format_align_center,
            },
            selected: activeTool == _TextStyleTool.alignment,
            onTap: () => onToolTap(_TextStyleTool.alignment),
          ),
        ],
      ),
    );
  }
}

class _TextToolDetails extends StatelessWidget {
  const _TextToolDetails({
    required this.activeTool,
    required this.mode,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.bgStart,
    required this.bgEnd,
    required this.alignment,
    required this.onFontSize,
    required this.onFontFamily,
    required this.onTextColor,
    required this.onBackground,
    required this.onAlignment,
  });

  final _TextStyleTool activeTool;
  final String mode;
  final double fontSize;
  final String fontFamily;
  final int textColor;
  final int bgStart;
  final int bgEnd;
  final String alignment;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onFontFamily;
  final ValueChanged<int> onTextColor;
  final void Function(int start, int end) onBackground;
  final ValueChanged<String> onAlignment;

  @override
  Widget build(BuildContext context) {
    return switch (activeTool) {
      _TextStyleTool.size => _SmallSizeSlider(
        value: fontSize,
        onChanged: onFontSize,
      ),
      _TextStyleTool.font => _FontPicker(
        value: fontFamily,
        onChanged: onFontFamily,
      ),
      _TextStyleTool.color => _ColorPicker(
        value: textColor,
        onChanged: onTextColor,
      ),
      _TextStyleTool.background =>
        mode == 'text'
            ? _BackgroundPicker(
                start: bgStart,
                end: bgEnd,
                onChanged: onBackground,
              )
            : const SizedBox.shrink(),
      _TextStyleTool.alignment => _AlignmentPicker(
        value: alignment,
        onChanged: onAlignment,
      ),
    };
  }
}

class _SmallSizeSlider extends StatelessWidget {
  const _SmallSizeSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          const Icon(Icons.format_size_rounded, color: Colors.white, size: 20),
          Expanded(
            child: Slider(
              value: value,
              min: 22,
              max: 54,
              divisions: 16,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextToolButton extends StatelessWidget {
  const _TextToolButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: selected ? Colors.black : Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _ColorToolButton extends StatelessWidget {
  const _ColorToolButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _GradientToolButton extends StatelessWidget {
  const _GradientToolButton({
    required this.start,
    required this.end,
    required this.selected,
    required this.onTap,
  });

  final int start;
  final int end;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(start), Color(end)]),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const fonts = ['Default', 'Roboto', 'Serif', 'Monospace'];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        dropdownColor: const Color(0xFF24242C),
        value: value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        items: [
          for (final f in fonts) DropdownMenuItem(value: f, child: Text(f)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const colors = [0xFFFFFFFF, 0xFF111111, 0xFFFFF176, 0xFFFF2D55];
    return Row(
      children: [
        for (final c in colors)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _ColorDot(
              color: Color(c),
              selected: value == c,
              onTap: () => onChanged(c),
            ),
          ),
      ],
    );
  }
}

class _BackgroundPicker extends StatelessWidget {
  const _BackgroundPicker({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final int start;
  final int end;
  final void Function(int start, int end) onChanged;

  @override
  Widget build(BuildContext context) {
    const backgrounds = [
      (0xFF833AB4, 0xFFF77737),
      (0xFF11998E, 0xFF38EF7D),
      (0xFF141E30, 0xFF243B55),
      (0xFFFF512F, 0xFFDD2476),
    ];
    return Row(
      children: [
        for (final bg in backgrounds)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _GradientDot(
              start: bg.$1,
              end: bg.$2,
              selected: start == bg.$1 && end == bg.$2,
              onTap: () => onChanged(bg.$1, bg.$2),
            ),
          ),
      ],
    );
  }
}

class _AlignmentPicker extends StatelessWidget {
  const _AlignmentPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left)),
        ButtonSegment(value: 'center', icon: Icon(Icons.format_align_center)),
        ButtonSegment(value: 'right', icon: Icon(Icons.format_align_right)),
      ],
      selected: {value},
      onSelectionChanged: (next) => onChanged(next.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(
          BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }
}

class _RoundToolButton extends StatelessWidget {
  const _RoundToolButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _GlassTextButton extends StatelessWidget {
  const _GlassTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({
    required this.start,
    required this.end,
    required this.selected,
    required this.onTap,
  });

  final int start;
  final int end;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(start), Color(end)]),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _PollEditorResult {
  const _PollEditorResult.save(this.poll) : delete = false;
  const _PollEditorResult.delete() : poll = null, delete = true;

  final StoryPoll? poll;
  final bool delete;
}

class _PollEditorSheet extends StatefulWidget {
  const _PollEditorSheet({required this.existing});

  final StoryPoll? existing;

  @override
  State<_PollEditorSheet> createState() => _PollEditorSheetState();
}

class _PollEditorSheetState extends State<_PollEditorSheet> {
  late final TextEditingController _question;
  late final List<TextEditingController> _options;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _question = TextEditingController(text: existing?.question ?? '');
    final initialOptions =
        existing?.options.map((o) => o.text).toList() ?? const ['Yes', 'No'];
    _options = [
      for (final text in initialOptions.take(4))
        TextEditingController(text: text),
    ];
    while (_options.length < 2) {
      _options.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _question.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 4) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    final controller = _options.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _save() {
    final question = _question.text.trim();
    final optionTexts = _options.map((c) => c.text.trim()).toList();
    final seen = <String>{};
    if (question.isEmpty) {
      setState(() => _error = 'Question is required');
      return;
    }
    if (question.length > 80) {
      setState(() => _error = 'Question is too long');
      return;
    }
    for (final option in optionTexts) {
      if (option.isEmpty) {
        setState(() => _error = 'All options need text');
        return;
      }
      if (option.length > 30) {
        setState(() => _error = 'Option is too long');
        return;
      }
      final key = option.toLowerCase();
      if (!seen.add(key)) {
        setState(() => _error = 'Options must be unique');
        return;
      }
    }
    const ids = ['a', 'b', 'c', 'd'];
    final existing = widget.existing;
    Navigator.of(context).pop(
      _PollEditorResult.save(
        StoryPoll(
          id: existing?.id ?? 0,
          question: question,
          options: [
            for (var i = 0; i < optionTexts.length; i++)
              StoryPollOption(id: ids[i], text: optionTexts[i]),
          ],
          x: existing?.x ?? 0.5,
          y: existing?.y ?? 0.58,
          scale: existing?.scale ?? 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.poll_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Poll',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (widget.existing != null)
                    IconButton(
                      tooltip: 'Delete poll',
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const _PollEditorResult.delete()),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _question,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Ask a question...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _options[i],
                          maxLength: 30,
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            counterText: '',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          onPressed: () => _removeOption(i),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                    ],
                  ),
                ),
              if (_options.length < 4)
                OutlinedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add option'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomShareBar extends StatelessWidget {
  const _BottomShareBar({
    required this.canShare,
    required this.submitting,
    required this.onYourStory,
    required this.onSpecificUsers,
  });

  final bool canShare;
  final bool submitting;
  final VoidCallback onYourStory;
  final VoidCallback onSpecificUsers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: _StoryPillButton(
                  icon: const Icon(Icons.circle_outlined, size: 16),
                  label: submitting ? 'Sharing...' : 'Your story',
                  enabled: canShare,
                  onTap: onYourStory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StoryPillButton(
                  icon: const Icon(Icons.group_add_rounded, size: 16),
                  label: 'Specific Users',
                  enabled: canShare,
                  onTap: onSpecificUsers,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryPillButton extends StatelessWidget {
  const _StoryPillButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 16),
                    child: icon,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecificUsersSheet extends ConsumerStatefulWidget {
  const _SpecificUsersSheet({
    required this.selectedUsers,
    required this.onSelectionChanged,
    required this.onStopShare,
    required this.onWaitShare,
    required this.onShare,
  });

  final Set<int> selectedUsers;
  final VoidCallback onSelectionChanged;
  final VoidCallback onStopShare;
  final VoidCallback onWaitShare;
  final Future<bool> Function() onShare;

  @override
  ConsumerState<_SpecificUsersSheet> createState() =>
      _SpecificUsersSheetState();
}

class _SpecificUsersSheetState extends ConsumerState<_SpecificUsersSheet> {
  final _search = TextEditingController();
  var _sharing = false;
  var _canChooseLoading = false;
  Timer? _choiceTimer;

  @override
  void dispose() {
    _choiceTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _scheduleLoadingChoices() {
    _choiceTimer?.cancel();
    _choiceTimer = Timer(_shareLoadingChoiceDelay, () {
      if (!mounted || !_sharing) return;
      setState(() => _canChooseLoading = true);
    });
  }

  Future<void> _showLoadingChoices() async {
    if (!_sharing || !_canChooseLoading) return;
    final action = await showDialog<_ShareLoadingAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Still sharing?'),
        content: const Text('You can stop sharing now, or wait a bit longer.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ShareLoadingAction.wait),
            child: const Text('Wait'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.of(context).pop(_ShareLoadingAction.stop),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ShareLoadingAction.stop:
        widget.onStopShare();
        _choiceTimer?.cancel();
        setState(() {
          _sharing = false;
          _canChooseLoading = false;
        });
        break;
      case _ShareLoadingAction.wait:
        widget.onWaitShare();
        setState(() => _canChooseLoading = false);
        _scheduleLoadingChoices();
        break;
    }
  }

  Future<void> _share() async {
    if (widget.selectedUsers.isEmpty || _sharing) return;
    setState(() {
      _sharing = true;
      _canChooseLoading = false;
    });
    _scheduleLoadingChoices();
    final ok = await widget.onShare();
    if (!mounted) return;
    _choiceTimer?.cancel();
    setState(() {
      _sharing = false;
      _canChooseLoading = false;
    });
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(adminUsersListProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.42,
        maxChildSize: 0.82,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Specific Users',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _sharing ? _showLoadingChoices : null,
                        child: FilledButton(
                          onPressed:
                              widget.selectedUsers.isNotEmpty && !_sharing
                              ? _share
                              : null,
                          child: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search users...',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: usersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Could not load users')),
                    data: (users) => _AudiencePicker(
                      users: users,
                      selected: widget.selectedUsers,
                      scrollController: scrollController,
                      query: _search.text,
                      onChanged: () {
                        widget.onSelectionChanged();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AudiencePicker extends StatelessWidget {
  const _AudiencePicker({
    required this.users,
    required this.selected,
    required this.scrollController,
    required this.query,
    required this.onChanged,
  });

  final List<AdminUserRow> users;
  final Set<int> selected;
  final ScrollController scrollController;
  final String query;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = users.where((u) {
      final label = '${u.email} ${u.displayName ?? ''}'.toLowerCase();
      return q.isEmpty || label.contains(q);
    }).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('No users match this search.'));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final u = filtered[i];
        final label = (u.displayName ?? '').trim().isEmpty
            ? u.email
            : u.displayName!.trim();
        return CheckboxListTile(
          value: selected.contains(u.id),
          title: Text(label),
          subtitle: Text(u.email),
          onChanged: (v) {
            if (v == true) {
              selected.add(u.id);
            } else {
              selected.remove(u.id);
            }
            onChanged();
          },
        );
      },
    );
  }
}

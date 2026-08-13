import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class SpeechToTextSearch extends StatefulWidget {
  const SpeechToTextSearch({Key? key}) : super(key: key);

  @override
  _SpeechToTextSearchState createState() => _SpeechToTextSearchState();
}

class _SpeechToTextSearchState extends State<SpeechToTextSearch>
    with SingleTickerProviderStateMixin {
  final SpeechToText speech = SpeechToText();
  String _currentLocaleId = '';
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  double level = 0.0;

  // Drives the pulsing rings around the mic while listening.
  late final AnimationController _pulse;

  // Ensures we return the recognized words exactly once.
  bool _handled = false;

  /// Whether this sheet has actually begun listening yet.
  ///
  /// The engine survives the sheet being closed, so on the SECOND open
  /// `initialize()` reports the existing session's status straight away —
  /// 'notListening' — before `listen()` has been called. Without this guard
  /// that was read as "finished with nothing heard", so the sheet showed the
  /// error state and never started the mic. First use worked, every use after
  /// it did not.
  bool _listeningStarted = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSpeechState();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    speech.cancel();
    super.dispose();
  }

  void errorListener(SpeechRecognitionError error) async {
    try {
      context
          .read<VoiceSearchProvider>()
          .changeState(state: VoiceSearchState.error);
    } catch (e) {
      setState(() {});
    }
  }

  void statusListener(String status) {
    if (!mounted) return;
    final vp = context.read<VoiceSearchProvider>();
    if (status == 'listening') {
      _listeningStarted = true;
      vp.changeState(state: VoiceSearchState.listening, result: vp.lastWords);
    } else if (status == 'done' || status == 'notListening') {
      // Ignore a status that arrives before this sheet started listening — it
      // belongs to the previous session, not this one.
      if (!_listeningStarted) return;

      // Listening finished: return whatever we heard (even if the engine
      // never set finalResult); otherwise prompt to retry.
      if (vp.lastWords.trim().isNotEmpty) {
        _finish(vp.lastWords);
      } else {
        vp.changeState(state: VoiceSearchState.error);
      }
    }
  }

  // Returns the recognized words to the caller exactly once and closes the sheet.
  // Falls back to whatever the provider has already heard, so a late/empty
  // final result from the engine can't drop the words we captured earlier.
  void _finish(String words) {
    if (_handled || !mounted) return;
    var clean = words.trim();
    if (clean.isEmpty) {
      clean = context.read<VoiceSearchProvider>().lastWords.trim();
    }
    if (clean.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(clean);
  }

  Future<void> initSpeechState() async {
    // SpeechToText is a shared instance that outlives this sheet, so a session
    // left over from the previous open can block a new listen(). Clearing it
    // first costs nothing when there is nothing to clear.
    try {
      await speech.cancel();
    } catch (_) {
      // Nothing to cancel — first open, or the engine is already idle.
    }

    final isInitialized = await speech.initialize(
      onError: errorListener,
      onStatus: statusListener,
      debugLogging: false,
      finalTimeout: const Duration(milliseconds: 0),
    );

    // Rebind the callbacks by hand. speech_to_text's initialize() returns early
    // when the engine is already initialized:
    //
    //     if (_initWorked) return Future.value(_initWorked);
    //     errorListener = onError;      // never reached the second time
    //     statusListener = onStatus;
    //
    // …so from the second time the sheet is opened onward, the plugin still
    // holds the FIRST sheet's callbacks. Those begin with `if (!mounted)
    // return`, so they silently do nothing: the new sheet never hears
    // 'listening' or 'done', never closes and never runs the search. Only
    // onResult is rebound, by listen(), which is why the mic appeared to work
    // and then did nothing at all.
    speech.errorListener = errorListener;
    speech.statusListener = statusListener;
    if (isInitialized) {
      context.read<VoiceSearchProvider>().changeState(
            state: VoiceSearchState.listening,
            hasSpeech: true,
          );

      await _resolveLocaleId();
      startListening();
    }
  }

  // The recognizer needs a real locale id (e.g. en_US / hi_IN), not the app's
  // 2-letter language code. Match the app language against the engine's
  // available locales, then fall back to the device's system locale, then to
  // the device default (null) — anything but an invalid id that breaks voice.
  Future<void> _resolveLocaleId() async {
    String appLang = Constant.session
        .getData(SessionManager.keySelectedLanguageCode)
        .toLowerCase()
        .trim();
    if (appLang.isEmpty) appLang = 'en';

    try {
      final locales = await speech.locales();
      String matched = '';

      // 1) Prefer the device's own locale when it's the same language
      //    (e.g. en_IN / en_US) so recognition matches the user's accent.
      final sys = await speech.systemLocale();
      final sysId = (sys?.localeId ?? '').toLowerCase().replaceAll('-', '_');
      if (sysId == appLang || sysId.startsWith('${appLang}_')) {
        matched = sys!.localeId;
      }

      // 2) Otherwise the first available locale for the app language.
      if (matched.isEmpty) {
        for (final l in locales) {
          final id = l.localeId.toLowerCase().replaceAll('-', '_');
          if (id == appLang || id.startsWith('${appLang}_')) {
            matched = l.localeId;
            break;
          }
        }
      }

      // 3) Otherwise the device default locale.
      if (matched.isEmpty) matched = sys?.localeId ?? '';

      _currentLocaleId = matched;
    } catch (_) {
      _currentLocaleId = '';
    }
  }

  void startListening() {
    context
        .read<VoiceSearchProvider>()
        .changeState(state: VoiceSearchState.listening, result: "");
    speech.listen(
      onResult: resultListener,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      // Omit the locale when we couldn't resolve a valid one so the engine
      // uses the device default instead of failing on an invalid id.
      localeId: _currentLocaleId.isEmpty ? null : _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
    );
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
  }

  void resultListener(SpeechRecognitionResult result) {
    if (!mounted) return;
    final vp = context.read<VoiceSearchProvider>();
    // Keep the best transcription we've seen: some engines deliver the final
    // result with empty recognizedWords after a good partial, and that empty
    // value must not wipe out what the user actually said.
    final words = result.recognizedWords.trim();
    final best = words.isNotEmpty ? words : vp.lastWords;
    vp.changeState(state: VoiceSearchState.listening, result: best);
    if (result.finalResult) {
      Future.delayed(const Duration(milliseconds: 500))
          .then((_) => _finish(best));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<VoiceSearchProvider>(
      builder: (context, vp, child) {
        final isError = vp.voiceSearchState == VoiceSearchState.error;
        final words = vp.lastWords.trim();
        final hasWords = words.isNotEmpty;

        // Title + helper line for the current state — kept short and clear.
        final String title = isError
            ? getTranslatedValue(context, sorryDidntHearTryAgainLabel)
            : hasWords
                ? getTranslatedValue(context, voiceHeardLabel)
                : getTranslatedValue(context, listeningLabel);
        final String helper = isError
            ? getTranslatedValue(context, tapMicrophoneToTryAgainLabel)
            : getTranslatedValue(context, voiceSearchHintLabel);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottomInset),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 32),

              // Animated mic — tap to (re)start listening.
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (context.read<VoiceSearchProvider>().hasSpeech ||
                      speech.isNotListening) {
                    startListening();
                  }
                },
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!isError) ...[
                            _ring(colorScheme, 0.0),
                            _ring(colorScheme, 0.5),
                          ],
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: isError ? null : colorScheme.primaryGradient,
                              color: isError ? colorScheme.surfaceVariant : null,
                              shape: BoxShape.circle,
                              boxShadow: isError
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              isError ? Icons.mic_off_rounded : Icons.mic_rounded,
                              color: isError
                                  ? colorScheme.iconSecondary
                                  : Colors.white,
                              size: 38,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Recognized words (prominent) or the helper hint.
              if (hasWords && !isError)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '"$words"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      height: 1.2,
                    ),
                  ),
                )
              else
                Text(
                  helper,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // A single expanding, fading ring. [phase] offsets the two rings in time.
  Widget _ring(AppColorScheme colorScheme, double phase) {
    final t = (_pulse.value + phase) % 1.0;
    final size = 84 + (66 * t);
    final opacity = (1 - t) * 0.30;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: opacity),
      ),
    );
  }
}

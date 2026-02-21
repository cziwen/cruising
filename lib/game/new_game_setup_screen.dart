import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'paper_button.dart';
import 'paper_input.dart';

class NewGameSetupData {
  final String playerName;
  final String shipName;
  final String favoriteThing;

  const NewGameSetupData({
    required this.playerName,
    required this.shipName,
    required this.favoriteThing,
  });
}

class NewGameSetupScreen extends StatefulWidget {
  final Future<void> Function(NewGameSetupData data) onConfirm;

  const NewGameSetupScreen({
    super.key,
    required this.onConfirm,
  });

  @override
  State<NewGameSetupScreen> createState() => _NewGameSetupScreenState();
}

class _NewGameSetupScreenState extends State<NewGameSetupScreen> {
  final _playerNameController = TextEditingController();
  final _shipNameController = TextEditingController();
  final _favoriteThingController = TextEditingController();

  final _playerNameFocus = FocusNode();
  final _shipNameFocus = FocusNode();
  final _favoriteThingFocus = FocusNode();

  double _layer1Opacity = 1.0;
  double _layer2Opacity = 1.0;
  bool _showForm = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _playerNameController.addListener(_onTextChanged);
    _shipNameController.addListener(_onTextChanged);
    _favoriteThingController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runTransition();
    });
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _runTransition() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _layer1Opacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _layer2Opacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _showForm = true;
    });
  }

  Future<void> _handleConfirm() async {
    final playerName = _playerNameController.text.trim();
    final shipName = _shipNameController.text.trim();
    final favoriteThing = _favoriteThingController.text.trim();

    if (playerName.isEmpty || shipName.isEmpty || favoriteThing.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await widget.onConfirm(
      NewGameSetupData(
        playerName: playerName,
        shipName: shipName,
        favoriteThing: favoriteThing,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _playerNameController.removeListener(_onTextChanged);
    _shipNameController.removeListener(_onTextChanged);
    _favoriteThingController.removeListener(_onTextChanged);
    _playerNameController.dispose();
    _shipNameController.dispose();
    _favoriteThingController.dispose();
    _playerNameFocus.dispose();
    _shipNameFocus.dispose();
    _favoriteThingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canConfirm = _showForm &&
        !_isSubmitting &&
        _playerNameController.text.trim().isNotEmpty &&
        _shipNameController.text.trim().isNotEmpty &&
        _favoriteThingController.text.trim().isNotEmpty;

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: SizedBox(
          width: 1120,
          height: 720,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildLayer('assets/paper_ui/Sprites/Book_Desk/3.png', 1.0),
              _buildLayer('assets/paper_ui/Sprites/Book_Desk/2.png', _layer2Opacity),
              _buildLayer('assets/paper_ui/Sprites/Book_Desk/1.png', _layer1Opacity),
              Center(
                child: AnimatedOpacity(
                  opacity: _showForm ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: IgnorePointer(
                    ignoring: !_showForm || _isSubmitting,
                    child: SizedBox(
                      width: 520,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.newGameSetupTitle,
                            style: const TextStyle(
                              color: Color(0xFF4E342E),
                              fontSize: 28,
                              fontFamily: 'ArkPixel',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PaperInput(
                            controller: _playerNameController,
                            hintText: l10n.newGamePlayerNameHint,
                            focusNode: _playerNameFocus,
                            onSubmitted: (_) => _shipNameFocus.requestFocus(),
                          ),
                          const SizedBox(height: 12),
                          PaperInput(
                            controller: _shipNameController,
                            hintText: l10n.newGameShipNameHint,
                            focusNode: _shipNameFocus,
                            onSubmitted: (_) => _favoriteThingFocus.requestFocus(),
                          ),
                          const SizedBox(height: 12),
                          PaperInput(
                            controller: _favoriteThingController,
                            hintText: l10n.newGameFavoriteThingHint,
                            focusNode: _favoriteThingFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleConfirm(),
                          ),
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.center,
                            child: PaperButton(
                              label: l10n.confirm,
                              width: 170,
                              height: 58,
                              style: PaperButtonStyle.green,
                              onPressed: canConfirm ? _handleConfirm : null,
                              textStyle: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 20,
                                fontFamily: 'ArkPixel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayer(String assetPath, double opacity) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

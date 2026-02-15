import 'package:flutter/material.dart';
import '../systems/save_system.dart';
import '../game/game_state.dart';
import '../game/paper_button.dart';
import '../game/paper_dialog.dart';
import '../utils/game_config_loader.dart';
import '../l10n/l10n.dart';
import 'game_screen.dart';

enum SaveLoadMode {
  save,
  load,
}

class SaveLoadScreen extends StatefulWidget {
  final SaveLoadMode mode;
  final GameState? gameState; // Only required for save mode
  final Function(Map<String, dynamic>)? onLoadConfirmed;

  const SaveLoadScreen({
    super.key,
    required this.mode,
    this.gameState,
    this.onLoadConfirmed,
  });

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  List<SaveSlot> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final slots = await SaveManager.getSaveSlots();
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveListLoadFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleSave(int slotId) async {
    if (widget.gameState == null) return;
    
    // Auto save slot (0) cannot be manually saved to
    if (slotId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.autoSlotManualBlocked)),
      );
      return;
    }

    try {
      await SaveManager.saveGame(slotId, widget.gameState!);
      await _loadSlots(); // Reload to show updated info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleLoad(int slotId) async {
    try {
      final gameData = await SaveManager.loadGame(slotId);
      if (mounted) {
        if (widget.onLoadConfirmed != null) {
          widget.onLoadConfirmed!(gameData);
          Navigator.of(context).pop();
        } else {
          // Navigate to GameScreen with loaded data
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => GameScreen(initialSaveData: gameData),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loadFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleDelete(int slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaperDialog(
        assetPath: 'assets/paper_ui/Sprites/Book_Desk/4.png',
        width: 400,
        height: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.deleteSaveTitle, style: const TextStyle(color: Color(0xFF4E342E), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(context.l10n.deleteSaveConfirm,
              style: const TextStyle(color: Color(0xFF5D4037)), textAlign: TextAlign.center),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PaperButton(
                  label: context.l10n.cancel,
                  onPressed: () => Navigator.of(context).pop(false),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
                PaperButton(
                  label: context.l10n.delete,
                  onPressed: () => Navigator.of(context).pop(true),
                  style: PaperButtonStyle.red,
                  width: 80,
                  height: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await SaveManager.deleteSave(slotId);
      await _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == SaveLoadMode.save ? l10n.saveGame : l10n.loadGame),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/images/background/oceanbg_1.png', // 使用有效的备用图片
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 如果备用图片也失败，使用渐变背景
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF87CEEB),
                          const Color(0xFF4682B4),
                          const Color(0xFF1E90FF),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4, // 0 (Auto) + 1, 2, 3 (Manual)
              itemBuilder: (context, index) {
                final slotId = index;
                final slotData = _slots.firstWhere(
                  (s) => s.id == slotId, 
                  orElse: () => SaveSlot(
                    id: slotId, 
                    timestamp: '', 
                    portName: l10n.emptySlot,
                    gold: 0,
                    day: 1,
                  ),
                );
                final isEmpty = slotData.timestamp.isEmpty;
                final isAutoSave = slotId == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white.withValues(alpha: 0.9),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAutoSave ? Colors.orange : Colors.blue[900]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isAutoSave ? 'AUTO' : '$slotId',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAutoSave ? Colors.orange[800] : Colors.blue[900],
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      isEmpty
                          ? l10n.emptySlot
                          : (isAutoSave ? l10n.autoSaveSlot : l10n.saveSlotLabel(slotId.toString())),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: isEmpty 
                      ? null 
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(l10n.locationLabel(_resolveLocalizedPortName(slotData))),
                            Text(l10n.timeLabel(slotData.formattedTime)),
                            Text(l10n.goldDayLabel(slotData.gold.toString(), slotData.day.toString())),
                          ],
                        ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isEmpty && !isAutoSave)
                           PaperButton(
                            icon: const Icon(Icons.delete, color: Color(0xFF4E342E), size: 20),
                            onPressed: () => _handleDelete(slotId),
                            style: PaperButtonStyle.red,
                            width: 32,
                            height: 32,
                          ),
                        const SizedBox(width: 8),
                        PaperButton(
                          onPressed: () {
                            if (widget.mode == SaveLoadMode.save) {
                              if (isAutoSave) {
                                // Cannot manually save to auto slot
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.autoSlotManualBlocked)),
                                );
                              } else {
                                _handleSave(slotId);
                              }
                            } else {
                              if (isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.slotEmpty)),
                                );
                              } else {
                                _handleLoad(slotId);
                              }
                            }
                          },
                          label: widget.mode == SaveLoadMode.save 
                                ? (isEmpty ? l10n.save : l10n.overwrite)
                                : l10n.load,
                          style: widget.mode == SaveLoadMode.save 
                                ? (isAutoSave ? PaperButtonStyle.brown : PaperButtonStyle.blue)
                                : (isEmpty ? PaperButtonStyle.brown : PaperButtonStyle.green),
                          width: 80,
                          height: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _resolveLocalizedPortName(SaveSlot slot) {
    final portId = slot.portId;
    if (portId != null) {
      try {
        final port = GameConfigLoader().portsList.firstWhere((p) => p.id == portId);
        return port.name;
      } catch (_) {}
    }
    return slot.portName;
  }
}

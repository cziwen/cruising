import 'package:flutter/material.dart';
import '../systems/save_system.dart';
import '../game/game_state.dart';
import '../game/paper_button.dart';
import '../game/paper_dialog.dart';
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
          SnackBar(content: Text('加载存档列表失败: $e')),
        );
      }
    }
  }

  Future<void> _handleSave(int slotId) async {
    if (widget.gameState == null) return;
    
    // Auto save slot (0) cannot be manually saved to
    if (slotId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自动存档位无法手动覆盖')),
      );
      return;
    }

    try {
      await SaveManager.saveGame(slotId, widget.gameState!);
      await _loadSlots(); // Reload to show updated info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
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
          SnackBar(content: Text('读取存档失败: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(int slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaperDialog(
        assetPath: 'assets/paper_ui/Sprites/Book Desk/4.png',
        width: 400,
        height: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('删除存档', style: TextStyle(color: Color(0xFF4E342E), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('确定要删除这个存档吗？此操作无法撤销。', 
              style: TextStyle(color: Color(0xFF5D4037)), textAlign: TextAlign.center),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PaperButton(
                  label: '取消',
                  onPressed: () => Navigator.of(context).pop(false),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
                PaperButton(
                  label: '删除',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == SaveLoadMode.save ? '保存游戏' : '读取游戏'),
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
                    portName: '空槽位', 
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
                      isEmpty ? '空槽位' : slotData.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: isEmpty 
                      ? null 
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('位置: ${slotData.portName}'),
                            Text('时间: ${slotData.formattedTime}'),
                            Text('金币: ${slotData.gold} | 天数: ${slotData.day}'),
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
                                  const SnackBar(content: Text('自动存档位无法手动覆盖')),
                                );
                              } else {
                                _handleSave(slotId);
                              }
                            } else {
                              if (isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('该槽位为空')),
                                );
                              } else {
                                _handleLoad(slotId);
                              }
                            }
                          },
                          label: widget.mode == SaveLoadMode.save 
                                ? (isEmpty ? '保存' : '覆盖') 
                                : '读取',
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
}


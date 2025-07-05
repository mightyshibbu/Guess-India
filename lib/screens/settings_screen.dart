import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Default values
  bool _isSoundOn = true;
  bool _isMusicOn = true;
  double _soundVolume = 0.8;
  double _musicVolume = 0.6;
  
  // Keys for SharedPreferences
  static const String _soundKey = 'sound_enabled';
  static const String _musicKey = 'music_enabled';
  static const String _soundVolumeKey = 'sound_volume';
  static const String _musicVolumeKey = 'music_volume';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isSoundOn = prefs.getBool(_soundKey) ?? true;
      _isMusicOn = prefs.getBool(_musicKey) ?? true;
      _soundVolume = prefs.getDouble(_soundVolumeKey) ?? 0.8;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.6;
    });
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    
    // Update the state to reflect the change
    if (mounted) {
      setState(() {
        if (key == _soundKey) {
          _isSoundOn = value as bool;
        } else if (key == _musicKey) {
          _isMusicOn = value as bool;
        } else if (key == _soundVolumeKey) {
          _soundVolume = value as double;
        } else if (key == _musicVolumeKey) {
          _musicVolume = value as double;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[400]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sound Settings Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sound Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sound Toggle
                        SwitchListTile(
                          title: const Text(
                            'Enable Sound Effects',
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('Play sound effects during the game'),
                          value: _isSoundOn,
                          onChanged: (value) {
                            _saveSetting(_soundKey, value);
                          },
                          activeColor: Colors.blue,
                        ),
                        
                        // Sound Volume Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sound Effects Volume',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.volume_down, color: Colors.blue),
                                  Expanded(
                                    child: Slider(
                                      value: _soundVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 10,
                                      label: '${(_soundVolume * 100).toInt()}%',
                                      onChanged: _isSoundOn
                                          ? (value) {
                                              _saveSetting(_soundVolumeKey, value);
                                            }
                                          : null,
                                      activeColor: Colors.blue,
                                      inactiveColor: Colors.blue[100],
                                    ),
                                  ),
                                  const Icon(Icons.volume_up, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 24, thickness: 1),
                        
                        // Music Toggle
                        SwitchListTile(
                          title: const Text(
                            'Enable Background Music',
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('Play music in the background'),
                          value: _isMusicOn,
                          onChanged: (value) {
                            _saveSetting(_musicKey, value);
                          },
                          activeColor: Colors.blue,
                        ),
                        
                        // Music Volume Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Music Volume',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.music_note, color: Colors.purple),
                                  Expanded(
                                    child: Slider(
                                      value: _musicVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 10,
                                      label: '${(_musicVolume * 100).toInt()}%',
                                      onChanged: _isMusicOn
                                          ? (value) {
                                              _saveSetting(_musicVolumeKey, value);
                                            }
                                          : null,
                                      activeColor: Colors.purple,
                                      inactiveColor: Colors.purple[100],
                                    ),
                                  ),
                                  const Icon(Icons.music_off, color: Colors.purple),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // App Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Party Charades',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Version: 1.0.0',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Party Charades is a fun game to play with friends and family. '
                          'Hold the phone to your forehead and guess the words based on clues from others!',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          ' 2025 Party Charades. All rights reserved.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Reset Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldReset = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Settings'),
                          content: const Text('Are you sure you want to reset all settings to default?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ) ?? false;
                      
                      if (shouldReset) {
                        // Reset to default values
                        await _saveSetting(_soundKey, true);
                        await _saveSetting(_musicKey, true);
                        await _saveSetting(_soundVolumeKey, 0.8);
                        await _saveSetting(_musicVolumeKey, 0.6);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings reset to default'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore, color: Colors.white),
                    label: const Text(
                      'Reset to Default',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

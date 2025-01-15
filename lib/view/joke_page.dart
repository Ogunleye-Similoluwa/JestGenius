import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

import '../jokes_model/model.dart';
import '../View/joke_page.dart';
import '../jokes_model/jokes_category.dart';
import '../provider/provider_services.dart';

class JokeHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('JestGenius', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(context.read<JokeProvider>().themeMode == ThemeMode.dark 
                  ? Icons.dark_mode
                  : context.read<JokeProvider>().themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto),
              onPressed: () {
                context.read<JokeProvider>().toggleTheme();
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Jokes'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.analytics), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            JokeTab(),
            FavoritesTab(),
            HistoryTab(),
            StatsTab(),
          ],
        ),
      ),
    );
  }
}

// Joke Tab
class JokeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CategorySelector(),
                        SizedBox(height: 16),
                        if (jokeProvider.isLoading)
                          JokeShimmer()
                        else if (jokeProvider.currentJoke != null) ...[
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            child: JokeCard(
                              key: ValueKey(jokeProvider.currentJoke!.id),
                              joke: jokeProvider.currentJoke!,
                            ),
                          ),
                          JokeActions(),
                          NextJokeButton(jokeProvider: jokeProvider),
                        ] else
                          EmptyJokeState(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: jokeProvider.confettiController,
                blastDirection: -pi / 2,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategorySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: JokeCategory.values.map((category) {
                  final isSelected = jokeProvider.selectedCategory == category;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: Duration(milliseconds: 200),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          category.icon,
                          size: 18,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(category.label),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        onSelected: (bool selected) {
                          jokeProvider.setCategory(category);
                          jokeProvider.fetchJoke(category: category);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class JokeShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 16,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Container(
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NextJokeButton extends StatelessWidget {
  final JokeProvider jokeProvider;

  const NextJokeButton({Key? key, required this.jokeProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () => jokeProvider.fetchJoke(
          category: jokeProvider.selectedCategory,
        ),
        icon: Icon(Icons.refresh),
        label: Text('Next Joke'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

class EmptyJokeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_very_satisfied,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Ready for a laugh?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Tap a category or the button below to get started!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class JokeCard extends StatelessWidget {
  final JokeModel joke;

  const JokeCard({Key? key, required this.joke}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 16 : 12,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.4 : 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isDark ? 5 : 10, sigmaY: isDark ? 5 : 10),
            child: Container(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Category Badge
                  if (joke.categories.isNotEmpty)
                    Chip(
                      label: Text(
                        joke.categories.first.toString().toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  SizedBox(height: 16),
                  
                  // Joke Icon or Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: joke.iconUrl != null
                      ? ClipOval(
                          child: Image.network(
                            joke.iconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildJokeIcon(context),
                          ),
                        )
                      : _buildJokeIcon(context),
                  ),
                  SizedBox(height: 24),

                  // Joke Content
                  if (joke.setup != null && joke.punchline != null) ...[
                    Text(
                      joke.setup!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        joke.punchline!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.5,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else
                    Text(
                      joke.value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJokeIcon(BuildContext context) {
    return Icon(
      _getJokeIcon(),
      size: 40,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  IconData _getJokeIcon() {
    if (joke.categories.isEmpty) return Icons.emoji_emotions;
    
    switch (joke.categories.first.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'dark':
        return Icons.dark_mode;
      case 'pun':
        return Icons.lightbulb;
      case 'spooky':
        return Icons.sports_kabaddi_outlined;
      case 'christmas':
        return Icons.celebration;
      case 'dad':
        return Icons.face;
      case 'chuck norris':
        return Icons.sports_kabaddi;
      default:
        return Icons.emoji_emotions;
    }
  }
}

// Enhanced JokeActions widget
class JokeActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Container(
          margin: EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                context,
                icon: jokeProvider.currentJoke!.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.red,
                onPressed: () {
                  jokeProvider.toggleFavorite();
                  if (jokeProvider.currentJoke!.isFavorite) {
                    _showSnackBar(context, 'Added to favorites!');
                  }
                },
                scale: jokeProvider.currentJoke!.isFavorite ? 1.2 : 1.0,
              ),
              SizedBox(width: 16),
              _buildActionButton(
                context,
                icon: Icons.volume_up,
                onPressed: jokeProvider.speakJoke,
              ),
              SizedBox(width: 16),
              _buildActionButton(
                context,
                icon: Icons.share,
                onPressed: () {
                  jokeProvider.shareJoke();
                  _showSnackBar(context, 'Joke shared!');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double scale = 1.0,
  }) {
    return AnimatedScale(
      scale: scale,
      duration: Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
          splashRadius: 24,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        if (jokeProvider.jokeHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'No joke history yet!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: jokeProvider.jokeHistory.length,
          itemBuilder: (context, index) {
            final joke = jokeProvider.jokeHistory[index];
            return Card(
              elevation: isDark ? 4 : 2,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [
                          Colors.grey[850]!,
                          Colors.grey[900]!,
                        ]
                      : [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                        ],
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    joke.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM d, yyyy HH:mm').format(joke.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard(
                context,
                icon: Icons.visibility,
                title: 'Jokes Read',
                value: jokeProvider.stats.jokesRead.toString(),
                isDark: isDark,
              ),
              _buildStatCard(
                context,
                icon: Icons.favorite,
                title: 'Jokes Favorited',
                value: jokeProvider.stats.favorited.toString(),
                isDark: isDark,
              ),
              _buildStatCard(
                context,
                icon: Icons.share,
                title: 'Jokes Shared',
                value: jokeProvider.stats.shared.toString(),
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Card(
      elevation: isDark ? 8 : 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer<JokeProvider>(
        builder: (context, jokeProvider, _) {
          return ListView(
            children: [
              ThemeColorSelector(),
              VoiceSettings(),
              // _buildNotificationSection(context, jokeProvider),
              _buildAutoPlaySection(context, jokeProvider),
              _buildDataManagementSection(context, jokeProvider),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, JokeProvider jokeProvider) {
    return SettingsSection(
      title: 'Appearance',
      children: [
        ListTile(
          title: Text('Theme'),
          subtitle: Text(jokeProvider.themeMode == ThemeMode.light
              ? 'Light'
              : jokeProvider.themeMode == ThemeMode.dark
              ? 'Dark'
              : 'System'),
          trailing: DropdownButton<ThemeMode>(
            value: jokeProvider.themeMode,
            onChanged: (ThemeMode? newValue) {
              if (newValue != null) {
                jokeProvider.setThemeMode(newValue);
              }
            },
            items: ThemeMode.values
                .map((mode) => DropdownMenuItem(
              value: mode,
              child: Text(mode.toString().split('.').last),
            ))
                .toList(),
          ),
        ),
        SwitchListTile(
          title: Text('Show Confetti'),
          subtitle: Text('Display confetti animation for new jokes'),
          value: jokeProvider.showConfetti,
          onChanged: (bool value) {
            jokeProvider.setShowConfetti(value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context, JokeProvider jokeProvider) {
    return SettingsSection(
      title: 'Notifications',
      children: [
        SwitchListTile(
          title: Text('Daily Joke Notification'),
          subtitle: Text('Get a new joke every day'),
          value: jokeProvider.dailyNotificationEnabled,
          onChanged: (bool value) async {
            if (value) {
              final granted = await _requestNotificationPermission();
              if (granted) {
                jokeProvider.setDailyNotification(true);
                jokeProvider.scheduleJokeNotification();
              }
            } else {
              jokeProvider.setDailyNotification(false);
              jokeProvider.cancelJokeNotification();
            }
          },
        ),
        ListTile(
          title: Text('Notification Time'),
          subtitle: Text(jokeProvider.notificationTime.format(context)),
          trailing: IconButton(
            icon: Icon(Icons.access_time),
            onPressed: () async {
              final TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: jokeProvider.notificationTime,
              );
              if (newTime != null) {
                jokeProvider.setNotificationTime(newTime);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutoPlaySection(BuildContext context, JokeProvider jokeProvider) {
    return SettingsSection(
      title: 'Auto Play',
      children: [
        SwitchListTile(
          title: Text('Auto Play Jokes'),
          subtitle: Text('Automatically fetch new jokes'),
          value: jokeProvider.autoPlayEnabled,
          onChanged: (bool value) {
            jokeProvider.setAutoPlay(value);
          },
        ),
        ListTile(
          title: Text('Auto Play Interval'),
          subtitle: Text('${jokeProvider.autoPlayInterval.inSeconds} seconds'),
          enabled: jokeProvider.autoPlayEnabled,
          trailing: DropdownButton<Duration>(
            value: jokeProvider.autoPlayInterval,
            onChanged: jokeProvider.autoPlayEnabled
                ? (Duration? newValue) {
              if (newValue != null) {
                jokeProvider.setAutoPlayInterval(newValue);
              }
            }
                : null,
            items: [
              DropdownMenuItem(value: Duration(seconds: 30), child: Text('30 seconds')),
              DropdownMenuItem(value: Duration(minutes: 1), child: Text('1 minute')),
              DropdownMenuItem(value: Duration(minutes: 5), child: Text('5 minutes')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextToSpeechSection(BuildContext context, JokeProvider jokeProvider) {
    return SettingsSection(
      title: 'Text to Speech',
      children: [
        SwitchListTile(
          title: Text('Auto Read Jokes'),
          subtitle: Text('Automatically read new jokes aloud'),
          value: jokeProvider.autoReadEnabled,
          onChanged: (bool value) {
            jokeProvider.setAutoRead(value);
          },
        ),
        ListTile(
          title: Text('Speech Rate'),
          subtitle: Slider(
            value: jokeProvider.speechRate,
            min: 0.5,
            max: 2.0,
            divisions: 3,
            label: jokeProvider.speechRate.toString(),
            onChanged: (double value) {
              jokeProvider.setSpeechRate(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context, JokeProvider jokeProvider) {
    return SettingsSection(
      title: 'Data Management',
      children: [
        ListTile(
          title: Text('Clear Favorite Jokes'),
          subtitle: Text('Remove all favorited jokes'),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Clear Favorites'),
                    content: Text('Are you sure you want to remove all favorited jokes?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text('Clear'),
                        onPressed: () {
                          jokeProvider.clearFavorites();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        ListTile(
          title: Text('Clear History'),
          subtitle: Text('Remove joke history'),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Clear History'),
                    content: Text('Are you sure you want to clear your joke history?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text('Clear'),
                        onPressed: () {
                          jokeProvider.clearHistory();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        ListTile(
          title: Text('Reset Statistics'),
          subtitle: Text('Reset all joke statistics'),
          trailing: IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Reset Statistics'),
                    content: Text('Are you sure you want to reset all statistics?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text('Reset'),
                        onPressed: () {
                          jokeProvider.resetStats();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return SettingsSection(
      title: 'About',
      children: [
        ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          title: Text('Licenses'),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'Ultimate Joke Generator',
              applicationVersion: '1.0.0',
            );
          },
        ),
        ListTile(
          title: Text('Privacy Policy'),
          onTap: () {
            // Implement privacy policy navigation
          },
        ),
        ListTile(
          title: Text('Terms of Service'),
          onTap: () {
            // Implement terms of service navigation
          },
        ),
      ],
    );
  }

  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }
}

class VoiceSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return SettingsSection(
          title: 'Voice Settings',
          children: [
            ListTile(
              title: Text('Voice Language'),
              subtitle: Text(jokeProvider.selectedVoice),
              trailing: DropdownButton<String>(
                value: jokeProvider.selectedVoice,
                items: [
                  DropdownMenuItem(value: 'en-US', child: Text('US English')),
                  DropdownMenuItem(value: 'en-GB', child: Text('British English')),
                  DropdownMenuItem(value: 'en-AU', child: Text('Australian English')),
                ],
                onChanged: (value) {
                  if (value != null) jokeProvider.setVoice(value);
                },
              ),
            ),
            ListTile(
              title: Text('Voice Pitch'),
              subtitle: Slider(
                value: jokeProvider.pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: jokeProvider.pitch.toStringAsFixed(1),
                onChanged: (value) => jokeProvider.setPitch(value),
              ),
            ),
            ListTile(
              title: Text('Voice Volume'),
              subtitle: Slider(
                value: jokeProvider.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (jokeProvider.volume * 100).toStringAsFixed(0) + '%',
                onChanged: (value) => jokeProvider.setVolume(value),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Add ColorScheme selector to SettingsPage
class ThemeColorSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return SettingsSection(
          title: 'Theme Colors',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                jokeProvider.themeColors.length,
                (index) => GestureDetector(
                  onTap: () => jokeProvider.setColorScheme(index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: jokeProvider.themeColors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == jokeProvider.selectedColorSchemeIndex
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        if (jokeProvider.favoriteJokes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'No favorite jokes yet!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the heart icon on jokes you like',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: jokeProvider.favoriteJokes.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final joke = jokeProvider.favoriteJokes[index];
            return Dismissible(
              key: Key(joke.id),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 24),
                child: Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                joke.isFavorite = false;
                jokeProvider.toggleFavorite();
              },
              child: Card(
                elevation: isDark ? 8 : 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                        ? [
                            Colors.grey[850]!,
                            Colors.grey[900]!,
                          ]
                        : [
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                          ],
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_emotions,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      joke.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: joke.createdAt != null 
                        ? Text(
                            'Added on ${DateFormat('MMM d, yyyy').format(joke.createdAt!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          )
                        : null,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.share,
                          onPressed: () => Share.share(joke.value),
                          isDark: isDark,
                        ),
                        SizedBox(width: 8),
                        _buildActionButton(
                          context,
                          icon: Icons.volume_up,
                          onPressed: () async {
                            await jokeProvider.flutterTts.speak(joke.value);
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    onTap: () => _showJokeDialog(context, joke),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark 
          ? Colors.grey[800] 
          : Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }

  void _showJokeDialog(BuildContext context, JokeModel joke) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_emotions,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                joke.value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class SearchJokeDelegate extends SearchDelegate<String> {
  final List<JokeModel> jokes;

  SearchJokeDelegate(this.jokes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? []
        : jokes.where((joke) =>
            joke.value.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final joke = suggestions[index];
        return ListTile(
          title: Text(joke.value),
          onTap: () {
            context.read<JokeProvider>().setCurrentJoke(joke);
            close(context, joke.value);
          },
        );
      },
    );
  }
}

class SocialShareSheet extends StatelessWidget {
  final JokeModel joke;

  const SocialShareSheet({Key? key, required this.joke}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.text_snippet),
            title: Text('Copy Text'),
            onTap: () => Clipboard.setData(ClipboardData(text: joke.value)),
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share as Image'),
            onTap: () => shareAsImage(joke),
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share to Social Media'),
            onTap: () => Share.share(joke.value),
          ),
        ],
      ),
    );
  }
}

Future<void> shareAsImage(JokeModel joke) async {
  // For now, just share the text since image sharing requires additional setup
  await Share.share(joke.value);
  // TODO: Implement actual image sharing functionality
}
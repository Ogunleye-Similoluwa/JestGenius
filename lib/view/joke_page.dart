import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
          title: Text('Ultimate Joke Generator'),
          actions: [
            IconButton(
              icon: Icon(Icons.brightness_6),
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
            Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConfettiWidget(
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
                    if (jokeProvider.isLoading)
                      CircularProgressIndicator()
                    else if (jokeProvider.currentJoke != null) ...[
                      CategoryChips(),
                      SizedBox(height: 20),
                      JokeCard(joke: jokeProvider.currentJoke!),
                      JokeActions(),
                    ],
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => jokeProvider.fetchJoke(),
                      child: Text(
                        jokeProvider.currentJoke == null
                            ? 'Get Joke'
                            : 'Next Joke',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: JokeCategory.values.map((category) {
        return FilterChip(
          label: Text(category.toString().split('.').last),
          onSelected: (bool selected) {
            context.read<JokeProvider>().fetchJoke(category: category);
          },
        );
      }).toList(),
    );
  }
}

class JokeCard extends StatelessWidget {
  final JokeModel joke;

  const JokeCard({Key? key, required this.joke}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (joke.iconUrl != null)
              Image.network(joke.iconUrl!, height: 100, width: 100),
            SizedBox(height: 16),
            if (joke.setup != null)
              Text(
                joke.setup!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            if (joke.setup != null) SizedBox(height: 8),
            if (joke.punchline != null)
              Text(
                joke.punchline!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            if (joke.value != null && joke.setup == null)
              Text(
                joke.value,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class JokeActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                jokeProvider.currentJoke!.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: jokeProvider.toggleFavorite,
            ),
            IconButton(
              icon: Icon(Icons.volume_up),
              onPressed: jokeProvider.speakJoke,
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: jokeProvider.shareJoke,
            ),
          ],
        );
      },
    );
  }
}

class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        if (jokeProvider.jokeHistory.isEmpty) {
          return Center(child: Text('No joke history yet!'));
        }
        return ListView.builder(
          itemCount: jokeProvider.jokeHistory.length,
          itemBuilder: (context, index) {
            final joke = jokeProvider.jokeHistory[index];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(joke.value),
                subtitle: Text(joke.createdAt.toString().split('.').first),
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
    return Consumer<JokeProvider>(
      builder: (context, jokeProvider, _) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatCard(
                icon: Icons.visibility,
                title: 'Jokes Read',
                value: jokeProvider.stats.jokesRead.toString(),
              ),
              StatCard(
                icon: Icons.favorite,
                title: 'Jokes Favorited',
                value: jokeProvider.stats.favorited.toString(),
              ),
              StatCard(
                icon: Icons.share,
                title: 'Jokes Shared',
                value: jokeProvider.stats.shared.toString(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 48),
            SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
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
              _buildThemeSection(context, jokeProvider),
              _buildNotificationSection(context, jokeProvider),
              _buildAutoPlaySection(context, jokeProvider),
              _buildTextToSpeechSection(context, jokeProvider),
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


class FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  color: Colors.grey,
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
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: jokeProvider.favoriteJokes.length,
          itemBuilder: (context, index) {
            final joke = jokeProvider.favoriteJokes[index];
            return Dismissible(
              key: Key(joke.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                jokeProvider.toggleFavorite();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joke removed from favorites'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        jokeProvider.toggleFavorite();
                      },
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: joke.iconUrl != null ?NetworkImage(joke.iconUrl!):NetworkImage("https://images.app.goo.gl/9wvNz6yPSD9feivb7"),
                    onBackgroundImageError: (_, __) {
                      // Handle error loading image
                    },
                  ),
                  title: Text(
                    joke.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Added on ${DateFormat('MMM d, yyyy').format(joke.createdAt!)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          Share.share(joke.value);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.volume_up),
                        onPressed: () {
                          jokeProvider.speakJoke();
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                joke.iconUrl!,
                                height: 100,
                                width: 100,
                                errorBuilder: (_, __, ___) => Icon(Icons.error),
                              ),
                              SizedBox(height: 16),
                              Text(joke.value),
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
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
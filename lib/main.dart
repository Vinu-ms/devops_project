import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MovieRatingApp());
}

class MovieRatingApp extends StatelessWidget {
  const MovieRatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Rating',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ), 
      home: const MovieListPage(),
    );
  }
}

// Movie Model
class Movie {
  String id;
  String title;
  String? description;
  double rating;
  String? comment; // New field for comment

  Movie({
    required this.id,
    required this.title,
    this.description,
    this.rating = 0.0,
    this.comment,
  });

  factory Movie.fromJson(Map<String, dynamic> j) => Movie(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        rating: (j['rating'] as num).toDouble(),
        comment: j['comment'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rating': rating,
        'comment': comment,
      };
}

// Repository for saving/loading movies
class MovieRepository {
  static const _key = 'movies_v1';
  final SharedPreferences prefs;

  MovieRepository(this.prefs);

  List<Movie> loadMovies() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _defaultMovies();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultMovies();
    }
  }

  Future<void> saveMovies(List<Movie> movies) async {
    final raw = jsonEncode(movies.map((m) => m.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  // Default movies
  List<Movie> _defaultMovies() {
    return [
      Movie(id: const Uuid().v4(), title: 'Inception Mind Heist', description: 'Dream enters mind', rating: 4.5),
      Movie(id: const Uuid().v4(), title: 'The Matrix Reloaded', description: 'Virtual world battle', rating: 4.0),
      Movie(id: const Uuid().v4(), title: 'Interstellar Space Journey', description: 'Beyond stars travel', rating: 4.2),
      Movie(id: const Uuid().v4(), title: 'The Dark Knight', description: 'Hero saves city', rating: 4.5),
      Movie(id: const Uuid().v4(), title: 'Back To Future', description: 'Time travel adventure', rating: 4.0),
      Movie(id: const Uuid().v4(), title: 'Forrest Gump Story', description: 'Life is journey', rating: 4.2),
      Movie(id: const Uuid().v4(), title: 'Jurassic Park Ride', description: 'Dinosaurs on island', rating: 3.8),
      Movie(id: const Uuid().v4(), title: 'Star Wars Saga', description: 'Space battle epic', rating: 4.7),
    ];
  }
}

// Movie List Page
class MovieListPage extends StatefulWidget {
  const MovieListPage({super.key});

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  late SharedPreferences _prefs;
  late MovieRepository _repo;
  List<Movie> _movies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _repo = MovieRepository(_prefs);
    _movies = _repo.loadMovies();
    setState(() => _loading = false);
  }

  Future<void> _addMovie() async {
    final newMovie = await showDialog<Movie?>(
      context: context,
      builder: (context) => const AddMovieDialog(),
    );

    if (newMovie != null) {
      setState(() {
        _movies.insert(0, newMovie);
      });
      await _repo.saveMovies(_movies);
    }
  }

  Future<void> _removeMovie(Movie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove movie?'),
        content: Text('Delete "${movie.title}" from list?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _movies.removeWhere((m) => m.id == movie.id);
      });
      await _repo.saveMovies(_movies);
    }
  }

  void _showDetails(Movie movie) async {
    final updatedMovie = await Navigator.push<Movie>(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsPage(movie: movie),
      ),
    );

    if (updatedMovie != null) {
      setState(() {
        final index = _movies.indexWhere((m) => m.id == updatedMovie.id);
        if (index != -1) _movies[index] = updatedMovie;
      });
      await _repo.saveMovies(_movies);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Ratings'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _movies.sort((a, b) => b.rating.compareTo(a.rating));
              });
            },
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by rating (desc)',
          ),
          IconButton(
            onPressed: () async {
              // reset to defaults
              final prefs = await SharedPreferences.getInstance();
              final repo = MovieRepository(prefs);
              setState(() {
                _movies = repo._defaultMovies();
              });
              await repo.saveMovies(_movies);
            },
            icon: const Icon(Icons.restore),
            tooltip: 'Reset sample movies',
          ),
        ],
      ),
      body: _movies.isEmpty
          ? const Center(child: Text('No movies. Tap + to add.'))
          : ListView.separated(
              itemCount: _movies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final movie = _movies[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 56,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(Icons.movie, size: 36, color: Colors.black54),
                  ),
                  title: Text(movie.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (movie.description != null) Text(movie.description!),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: movie.rating,
                            itemCount: 5,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                            itemSize: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(movie.rating.toStringAsFixed(1)),
                        ],
                      ),
                      if (movie.comment != null && movie.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Comment: ${movie.comment}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeMovie(movie),
                    tooltip: 'Delete',
                  ),
                  onTap: () => _showDetails(movie),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMovie,
        child: const Icon(Icons.add),
        tooltip: 'Add movie',
      ),
    );
  }
}

// Add Movie Dialog
class AddMovieDialog extends StatefulWidget {
  const AddMovieDialog({super.key});

  @override
  State<AddMovieDialog> createState() => _AddMovieDialogState();
}

class _AddMovieDialogState extends State<AddMovieDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  double _rating = 3.0;

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final movie = Movie(
      id: const Uuid().v4(),
      title: _titleCtl.text.trim(),
      description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      rating: _rating,
    );
    Navigator.of(context).pop(movie);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Movie'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _descCtl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Rating:'),
                  const SizedBox(width: 8),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 26,
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (r) => setState(() => _rating = r),
                  ),
                  const SizedBox(width: 8),
                  Text(_rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

// Movie Details Page with rating and comment
class MovieDetailsPage extends StatefulWidget {
  final Movie movie;
  const MovieDetailsPage({super.key, required this.movie});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  late double _rating;
  late TextEditingController _commentCtl;

  @override
  void initState() {
    super.initState();
    _rating = widget.movie.rating;
    _commentCtl = TextEditingController(text: widget.movie.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  void _save() {
    final updatedMovie = Movie(
      id: widget.movie.id,
      title: widget.movie.title,
      description: widget.movie.description,
      rating: _rating,
      comment: _commentCtl.text.trim(),
    );
    Navigator.of(context).pop(updatedMovie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movie.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.movie.description != null)
              Text(widget.movie.description!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Rating:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 0.5,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 32,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 16),
            const Text('Comment:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtl,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Write your comment...',
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

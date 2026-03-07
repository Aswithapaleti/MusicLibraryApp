import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/library/library_bloc.dart';
import 'repositories/music_repository.dart';
import 'screens/library/library_screen.dart';

void main() {
  runApp(const MusicLibraryApp());
}

class MusicLibraryApp extends StatelessWidget {
  const MusicLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => MusicRepository(),
      child: BlocProvider(
        create: (ctx) => LibraryBloc(repository: ctx.read<MusicRepository>()),
        child: MaterialApp(
          title: 'Music Library',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C47FF),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
          ),
          home: const LibraryScreen(),
        ),
      ),
    );
  }
}

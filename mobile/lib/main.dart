import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AppState()..initialize(),
      child: const TugVoteApp(),
    ),
  );
}

class TugVoteApp extends StatelessWidget {
  const TugVoteApp({
    super.key,
  });

  static const Color tugVotePurple =
      Color(0xFF6C4DFF);

  static const Color pageBackground =
      Color(0xFFF8F7FC);

  static const Color cardBackground =
      Color(0xFFFFFFFF);

  static const Color primaryText =
      Color(0xFF18171D);

  static const Color secondaryText =
      Color(0xFF686570);

  static const Color borderColor =
      Color(0xFFE4E1EA);

  @override
  Widget build(
    BuildContext context,
  ) {
    final appState =
        context.watch<AppState>();

    final colorScheme =
        ColorScheme.fromSeed(
      seedColor: tugVotePurple,
      brightness: Brightness.light,
    ).copyWith(
      primary: tugVotePurple,
      onPrimary: Colors.white,
      surface: cardBackground,
      onSurface: primaryText,
      outline: borderColor,
      outlineVariant:
          const Color(0xFFEDEAF2),
    );

    return MaterialApp(
      key: ValueKey(
        '${appState.isInitializing}-'
        '${appState.isLoggedIn}',
      ),
      title: 'TugVote',
      debugShowCheckedModeBanner:
          false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,

        scaffoldBackgroundColor:
            pageBackground,

        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              pageBackground,
          foregroundColor:
              primaryText,
          surfaceTintColor:
              Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle:
              TextStyle(
            color: primaryText,
            fontSize: 22,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        cardTheme: CardThemeData(
          color: cardBackground,
          surfaceTintColor:
              Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            side: const BorderSide(
              color: borderColor,
            ),
          ),
        ),

        navigationBarTheme:
            NavigationBarThemeData(
          backgroundColor:
              cardBackground,
          surfaceTintColor:
              Colors.transparent,
          elevation: 0,
          indicatorColor:
              const Color(
            0xFFECE7FF,
          ),
          indicatorShape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          iconTheme:
              WidgetStateProperty
                  .resolveWith(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return const IconThemeData(
                  color:
                      tugVotePurple,
                );
              }

              return const IconThemeData(
                color:
                    secondaryText,
              );
            },
          ),
          labelTextStyle:
              WidgetStateProperty
                  .resolveWith(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return const TextStyle(
                  color:
                      tugVotePurple,
                  fontWeight:
                      FontWeight.w700,
                );
              }

              return const TextStyle(
                color:
                    secondaryText,
                fontWeight:
                    FontWeight.w500,
              );
            },
          ),
        ),

        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor:
              cardBackground,
          hintStyle:
              const TextStyle(
            color: secondaryText,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color: tugVotePurple,
              width: 1.6,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor:
              cardBackground,
          selectedColor:
              const Color(
            0xFFECE7FF,
          ),
          disabledColor:
              const Color(
            0xFFF1EFF4,
          ),
          side: const BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          labelStyle:
              const TextStyle(
            color: primaryText,
            fontWeight:
                FontWeight.w500,
          ),
          secondaryLabelStyle:
              const TextStyle(
            color: tugVotePurple,
            fontWeight:
                FontWeight.w700,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 5,
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                tugVotePurple,
            foregroundColor:
                Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            textStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        filledButtonTheme:
            FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
            backgroundColor:
                tugVotePurple,
            foregroundColor:
                Colors.white,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            textStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        outlinedButtonTheme:
            OutlinedButtonThemeData(
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                tugVotePurple,
            side: const BorderSide(
              color: tugVotePurple,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            textStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        dividerTheme:
            const DividerThemeData(
          color: borderColor,
          thickness: 1,
          space: 1,
        ),

        textTheme:
            const TextTheme(
          headlineSmall:
              TextStyle(
            color: primaryText,
            fontWeight:
                FontWeight.w800,
          ),
          titleLarge:
              TextStyle(
            color: primaryText,
            fontWeight:
                FontWeight.w700,
          ),
          titleMedium:
              TextStyle(
            color: primaryText,
            fontWeight:
                FontWeight.w600,
          ),
          bodyLarge:
              TextStyle(
            color: primaryText,
          ),
          bodyMedium:
              TextStyle(
            color: primaryText,
          ),
          bodySmall:
              TextStyle(
            color: secondaryText,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
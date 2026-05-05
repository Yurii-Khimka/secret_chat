import '../tokens/tokens.dart';
import 'app_theme_name.dart';
import 'palettes/mint_palette.dart';
import 'palettes/ice_palette.dart';
import 'palettes/indigo_palette.dart';
import 'palettes/sand_palette.dart';
import 'palettes/lime_palette.dart';

class AppTheme {
  const AppTheme._({
    required this.palette,
    required this.name,
  });

  final AppPalette palette;
  final AppThemeName name;

  factory AppTheme.forName(AppThemeName name) {
    final palette = switch (name) {
      AppThemeName.mint => mintPalette,
      AppThemeName.ice => icePalette,
      AppThemeName.indigo => indigoPalette,
      AppThemeName.sand => sandPalette,
      AppThemeName.lime => limePalette,
    };
    return AppTheme._(palette: palette, name: name);
  }
}

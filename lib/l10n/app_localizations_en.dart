// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmpty => 'There\'s nothing to show...';

  @override
  String get librarySnackBarPasteErrorMsg => 'Cannot copy in current dir!';

  @override
  String get libraryDeletedMsg => 'Deleted';

  @override
  String get libraryTooltipPaste => 'Paste';

  @override
  String get libraryTooltipSearch => 'Search';

  @override
  String get libraryTooltipSettings => 'Settings';

  @override
  String get libraryTooltipOptions => 'Options';

  @override
  String get libraryOptionRename => 'Rename';

  @override
  String get libraryOptionEdit => 'Edit';

  @override
  String get libraryOptionCopy => 'Copy';

  @override
  String get libraryOptionCut => 'Cut';

  @override
  String get libraryOptionDelete => 'Delete';

  @override
  String get libraryAddOptionSong => 'Add song';

  @override
  String get libraryAddOptionFolder => 'Add folder';

  @override
  String get libraryAddOptionImport => 'Import';

  @override
  String get libraryRenameDialogTitle => 'Rename';

  @override
  String get libraryRenameDialogHint => 'New name...';

  @override
  String get libraryImportDialogTitle => 'Import';

  @override
  String get libraryNewFolderDialogTitle => 'Create new folder';

  @override
  String get libraryNewFolderDialogHint => 'Folder\'s name...';

  @override
  String get libraryAddSongDialogTitle => 'New song\'s name';

  @override
  String get libraryAddSongDialogHint => 'Song\'s name...';

  @override
  String get newSongDialogArtistHint => 'Artist...';

  @override
  String get newSongDialogTitleHint => 'Title...';

  @override
  String get newSongDialogTextHint => 'Song\'s text...';

  @override
  String get nameValidatorErrorEmptyText => 'Text cannot be empty!';

  @override
  String get nameValidatorErrorForbiddenChars =>
      'Text contains forbidden chars!';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';
}

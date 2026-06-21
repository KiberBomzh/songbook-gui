import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'There\'s nothing to show...'**
  String get libraryEmpty;

  /// No description provided for @librarySnackBarPasteErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Cannot copy in current dir!'**
  String get librarySnackBarPasteErrorMsg;

  /// No description provided for @libraryDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get libraryDeletedMsg;

  /// No description provided for @libraryTooltipPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get libraryTooltipPaste;

  /// No description provided for @libraryTooltipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get libraryTooltipSearch;

  /// No description provided for @libraryTooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get libraryTooltipSettings;

  /// No description provided for @libraryTooltipOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get libraryTooltipOptions;

  /// No description provided for @libraryOptionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get libraryOptionRename;

  /// No description provided for @libraryOptionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get libraryOptionEdit;

  /// No description provided for @libraryOptionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get libraryOptionCopy;

  /// No description provided for @libraryOptionCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get libraryOptionCut;

  /// No description provided for @libraryOptionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get libraryOptionDelete;

  /// No description provided for @libraryAddOptionSong.
  ///
  /// In en, this message translates to:
  /// **'Add song'**
  String get libraryAddOptionSong;

  /// No description provided for @libraryAddOptionFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get libraryAddOptionFolder;

  /// No description provided for @libraryAddOptionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get libraryAddOptionImport;

  /// No description provided for @libraryRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get libraryRenameDialogTitle;

  /// No description provided for @libraryRenameDialogHint.
  ///
  /// In en, this message translates to:
  /// **'New name...'**
  String get libraryRenameDialogHint;

  /// No description provided for @libraryImportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get libraryImportDialogTitle;

  /// No description provided for @libraryNewFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new folder'**
  String get libraryNewFolderDialogTitle;

  /// No description provided for @libraryNewFolderDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Folder\'s name...'**
  String get libraryNewFolderDialogHint;

  /// No description provided for @libraryAddSongDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New song\'s name'**
  String get libraryAddSongDialogTitle;

  /// No description provided for @libraryAddSongDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Song\'s name...'**
  String get libraryAddSongDialogHint;

  /// No description provided for @newSongDialogArtistHint.
  ///
  /// In en, this message translates to:
  /// **'Artist...'**
  String get newSongDialogArtistHint;

  /// No description provided for @newSongDialogTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title...'**
  String get newSongDialogTitleHint;

  /// No description provided for @newSongDialogTextHint.
  ///
  /// In en, this message translates to:
  /// **'Song\'s text...'**
  String get newSongDialogTextHint;

  /// No description provided for @nameValidatorErrorEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Text cannot be empty!'**
  String get nameValidatorErrorEmptyText;

  /// No description provided for @nameValidatorErrorForbiddenChars.
  ///
  /// In en, this message translates to:
  /// **'Text contains forbidden chars!'**
  String get nameValidatorErrorForbiddenChars;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

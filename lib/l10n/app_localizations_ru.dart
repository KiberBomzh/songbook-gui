// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get libraryTitle => 'Библеотека';

  @override
  String get libraryEmpty => 'Здесь ничего нет...';

  @override
  String get librarySnackBarPasteErrorMsg =>
      'Невозможно скопировать в текущую папку!';

  @override
  String get libraryDeletedMsg => 'Удалено';

  @override
  String get libraryTooltipPaste => 'Вставить';

  @override
  String get libraryTooltipSearch => 'Поиск';

  @override
  String get libraryTooltipSettings => 'Настройки';

  @override
  String get libraryTooltipOptions => 'Опции';

  @override
  String get libraryOptionRename => 'Переименовать';

  @override
  String get libraryOptionEdit => 'Редактировать';

  @override
  String get libraryOptionCopy => 'Копировать';

  @override
  String get libraryOptionCut => 'Вырезать';

  @override
  String get libraryOptionDelete => 'Удалить';

  @override
  String get libraryAddOptionSong => 'Добавить песню';

  @override
  String get libraryAddOptionFolder => 'Добавить папку';

  @override
  String get libraryAddOptionImport => 'Импорт';

  @override
  String get libraryRenameDialogTitle => 'Переименование';

  @override
  String get libraryRenameDialogHint => 'Новое имя...';

  @override
  String get libraryImportDialogTitle => 'Импорт';

  @override
  String get libraryNewFolderDialogTitle => 'Новая папка';

  @override
  String get libraryNewFolderDialogHint => 'Название папки...';

  @override
  String get libraryAddSongDialogTitle => 'Название новой песни';

  @override
  String get libraryAddSongDialogHint => 'Название песни...';

  @override
  String get newSongDialogArtistHint => 'Исполнитель...';

  @override
  String get newSongDialogTitleHint => 'Название...';

  @override
  String get newSongDialogTextHint => 'Текст песни...';

  @override
  String get nameValidatorErrorEmptyText => 'Текст не может быть пустым!';

  @override
  String get nameValidatorErrorForbiddenChars =>
      'Текст содержит запрещенные символы!';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Завершить';
}

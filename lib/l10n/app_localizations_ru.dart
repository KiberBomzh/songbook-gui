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
  String get songErrorMsg => 'Ошибка во время открытия песни...';

  @override
  String get songEmptyMsg => 'Песня пустая...';

  @override
  String get songTooltipExport => 'Экспорт';

  @override
  String get songExportOptionText => 'Текст';

  @override
  String get songTooltipSettings => 'Настройки';

  @override
  String get nameValidatorErrorEmptyText => 'Текст не может быть пустым!';

  @override
  String get nameValidatorErrorForbiddenChars =>
      'Текст содержит запрещенные символы!';

  @override
  String get settingsAppBarTitle => 'Настройки';

  @override
  String get settingsGlobalTitle => 'Глобальные';

  @override
  String get settingsEditorTitle => 'Редактор';

  @override
  String get settingsSongTitle => 'Песня';

  @override
  String get settingsOtherTitle => 'Другие';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsAmoled => 'Амолед';

  @override
  String get settingsAccent => 'Акцент';

  @override
  String get settingsBackgroundOpacity => 'Прозрачность фона';

  @override
  String get settingsBackgroundOpacityHint => 'Прозрачность...';

  @override
  String get settingsBackgroundImage => 'Заставка';

  @override
  String get settingsReset => 'Сбросить';

  @override
  String get settingsFontSize => 'Размер текста';

  @override
  String get settingsFontSizeHint => 'Размер текста...';

  @override
  String get settingsFontFamily => 'Шрифт';

  @override
  String get settingsEditorFontSize => 'Размер текста в редакторе';

  @override
  String get settingsSongFontSize => 'Размер текста в песне';

  @override
  String get settingsLineWrap => 'Перенос строк';

  @override
  String get settingsFingeringsSize => 'Размер аппликатур';

  @override
  String get settingsTitles => 'Заголовки';

  @override
  String get settingsNotes => 'Заметки';

  @override
  String get settingsFingerings => 'Аппликатуры';

  @override
  String get settingsTabs => 'Табы';

  @override
  String get settingsPlainText => 'Простой текст';

  @override
  String get settingsBold => 'Жирный';

  @override
  String get settingsItalic => 'Курсив';

  @override
  String get settingsChordsColor => 'Цвет аккордов';

  @override
  String get settingsRhythmColor => 'Цвет ритма';

  @override
  String get settingsTextColor => 'Цвет текста';

  @override
  String get settingsNotesColor => 'Цвет заметок';

  @override
  String get settingsTitlesColor => 'Цвет заголовков';

  @override
  String get settingsBackground => 'Фон';

  @override
  String get settingsExportBackup => 'Экспортировать бэкап';

  @override
  String get settingsImportBackup => 'Импортировать бэкап';

  @override
  String get settingsResetSettings => 'Сбросить настройки';

  @override
  String get settingsResetLibrary => 'Сбросить библиотеку';

  @override
  String get settingsExportSuccesMsg => 'Готово!';

  @override
  String get settingsImportSuccesMsg =>
      'Готово, песеннику нужно перезапуститься!';

  @override
  String get settingsErrorMsg => 'Ошибка!';

  @override
  String get fingeringsSizeSmall => 'Маленький';

  @override
  String get fingeringsSizeMedium => 'Средний';

  @override
  String get fingeringsSizeBig => 'Большой';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get done => 'Завершить';

  @override
  String get hintText => 'Напечатайте что-нибудь...';

  @override
  String get notValidInput => 'Неправильное значение!';

  @override
  String get valueMustBeBiggerThan0 => 'Значение должно быть больше 0!';

  @override
  String get valueMustBeSmallerThan100 => 'Значение должно быть меньше 100!';

  @override
  String get valueMustBe1OrSmaller => 'Значение должно быть 1 или меньше!';

  @override
  String get fontExampleText =>
      'Съешь ещё этих мягких французских булок, да выпей чаю.';

  @override
  String get chords => 'Аккорды';

  @override
  String get rhythm => 'Ритм';

  @override
  String get notes => 'Заметки';

  @override
  String get fingerings => 'Аппликатуры';
}

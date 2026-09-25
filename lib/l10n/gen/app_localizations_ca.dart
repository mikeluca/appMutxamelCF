// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get navHome => 'Inici';

  @override
  String get navNews => 'Notícies';

  @override
  String get navMatches => 'Partits';

  @override
  String get navStore => 'Botiga';

  @override
  String get navClub => 'Club';

  @override
  String get retry => 'Torna-ho a intentar';

  @override
  String get linkOpenError => 'No s\'ha pogut obrir l\'enllaç';

  @override
  String get homeNotificationsTooltip => 'Notificacions';

  @override
  String get homeAreaClub => 'Àrea Club';

  @override
  String get homeLatestNews => 'Darreres notícies';

  @override
  String get homeOurSponsors => 'Els nostres patrocinadors';

  @override
  String get homeSponsorsHint =>
      'Prem a les imatges per a conéixer més sobre els nostres patrocinadors.';

  @override
  String get homeNewsLoadError => 'No s\'han pogut carregar les notícies.';

  @override
  String get homeNoNewsAvailable => 'No hi ha notícies disponibles.';

  @override
  String get homeMatchLoadError => 'No s\'ha pogut carregar el partit.';

  @override
  String get homeMatchUnavailable =>
      'No hi ha informació disponible sobre el pròxim partit.';

  @override
  String get matchUpcoming => 'PRÒXIM PARTIT';

  @override
  String get matchUpcomingFirstTeam => 'PRÒXIM PARTIT PRIMER EQUIP';

  @override
  String get matchLastResult => 'ÚLTIM RESULTAT';

  @override
  String get matchLastResultFirstTeam => 'ÚLTIM RESULTAT PRIMER EQUIP';

  @override
  String get matchVs => 'VS';

  @override
  String get matchNoMatch => 'SENSE PARTIT';

  @override
  String get matchNoMatchFirstTeam => 'SENSE PARTIT PRIMER EQUIP';

  @override
  String get matchNoMatchThisRound => 'No hi ha partit esta jornada';

  @override
  String get matchTeamHasNoMatch => 'No té partit';

  @override
  String get matchesCalendarTitle => 'CALENDARI';

  @override
  String get matchesCalendarSubtitle =>
      'Partits i resultats dels nostres equips';

  @override
  String get matchesNoMatchesAvailable => 'No hi ha partits disponibles.';

  @override
  String get matchesLoadError => 'No s\'han pogut carregar els partits.';

  @override
  String get matchesNoCategory => 'Sense categoria';

  @override
  String get matchesResult => 'RESULTAT';

  @override
  String get matchesRestsThisRound => 'Descansa esta jornada';

  @override
  String get newsTitle => 'Notícies';

  @override
  String get newsDetailTitle => 'Notícia';

  @override
  String get newsLoadMore => 'Carregar més notícies';

  @override
  String get newsLoadMoreError => 'No s\'han pogut carregar més notícies.';

  @override
  String get storeTitle => 'Botiga';

  @override
  String get storeHeroKicker => 'MUTXAMEL CF';

  @override
  String get storeHeroTitle => 'Vesteix els colors';

  @override
  String get storeHeroSubtitle =>
      'La nova col·lecció del club ja està ací. Tria la teua peça, selecciona les teues talles i fes-nos arribar la teua comanda.';

  @override
  String get storeProductShirtTitle => 'Samarreta oficial';

  @override
  String get storeProductShirtDescription =>
      'L\'essència del Mutxamel CF, un any més, vestida de blau. La nostra primera equipació combina la tradició i la identitat del club amb un disseny modern.';

  @override
  String get storeProductSecondKitTitle => 'Segona equipació';

  @override
  String get storeProductSecondKitDescription =>
      'Molt més que una samarreta. La nostra segona equipació, de color rosa, naix d\'una col·laboració molt especial amb l\'Associació Espanyola Contra el Càncer, unint esport, compromís i solidaritat.';

  @override
  String get storeProductSecondKitNote =>
      'Col·laboració amb l\'Associació Espanyola Contra el Càncer';

  @override
  String get storeUnits => 'Unitats';

  @override
  String storeSizeUnitLabel(int n) {
    return 'Talla unitat $n';
  }

  @override
  String get storeSizeGuideTitle => 'Guia de talles';

  @override
  String get storeSizeGuideHint =>
      'Mesura una peça que et quede bé i compara-la amb estes mesures aproximades.';

  @override
  String get storeSizeGuideSize => 'Talla';

  @override
  String get storeSizeGuideChest => 'Pit (cm)';

  @override
  String get storeSizeGuideLength => 'Llarg (cm)';

  @override
  String get storeCustomerDataTitle => 'Les teues dades';

  @override
  String get storeCustomerDataHint =>
      'T\'escriurem per a confirmar disponibilitat i forma de pagament.';

  @override
  String get storeFullNameLabel => 'Nom i cognoms';

  @override
  String get storePhoneLabel => 'Telèfon (opcional)';

  @override
  String get storeEmailLabel => 'Correu electrònic';

  @override
  String get storePrivacyAcceptPrefix =>
      'Accepte el tractament de les meues dades segons la ';

  @override
  String get storePrivacyPolicyLink => 'política de privacitat';

  @override
  String get storeCreateOrderButton => 'CREAR COMANDA';

  @override
  String get storeSendingButton => 'Enviant...';

  @override
  String get storeErrorEnterName => 'Introdueix el teu nom i cognoms.';

  @override
  String get storeErrorInvalidEmail => 'Introdueix un correu electrònic vàlid.';

  @override
  String get storeErrorAcceptPrivacy =>
      'Has d\'acceptar la política de privacitat.';

  @override
  String storeErrorSelectSizeForProduct(String producto) {
    return 'Selecciona la talla de cada unitat de \"$producto\".';
  }

  @override
  String get storeErrorSelectAtLeastOne =>
      'Selecciona almenys una peça i les seues unitats.';

  @override
  String get storeOrderSentMessage =>
      'Comanda enviada. Ens posarem en contacte amb tu per a confirmar el pagament i la recollida/enviament.';

  @override
  String get clubTitle => 'Club';

  @override
  String get clubFullName => 'Mutxamel Club de Futbol';

  @override
  String get clubTagline => 'On estem i com contactar amb el club';

  @override
  String get clubSettingsTooltip => 'Ajustos';

  @override
  String get clubWhereWeAre => 'On estem';

  @override
  String get clubAddress => 'Adreça';

  @override
  String get clubWebsite => 'Pàgina web';

  @override
  String get clubPhone => 'Telèfon';

  @override
  String get clubEmail => 'Correu electrònic';

  @override
  String get clubFollowUs => 'Segueix-nos';

  @override
  String get clubViewOnGoogleMaps => 'Veure a Google Maps';

  @override
  String clubCopyright(int year) {
    return '© $year Mutxamel Club de Futbol';
  }

  @override
  String get settingsTitle => 'Ajustos';

  @override
  String get settingsSectionNotifications => 'Notificacions';

  @override
  String get settingsSectionApplication => 'Aplicació';

  @override
  String get settingsNotifAnonymousHint =>
      'Activa-les encara que no tingues un compte al club.';

  @override
  String get settingsNotifNewsAnon => 'Notícies';

  @override
  String get settingsNotifNewsAnonSubtitle => 'Rebre avisos de notícies noves';

  @override
  String get settingsNotifResultsFirstTeam =>
      'Resultats en directe del primer equip';

  @override
  String get settingsNotifResultsFirstTeamSubtitle =>
      'Avisos de gols i resultats en directe';

  @override
  String get settingsPreferencesLoadError =>
      'No s\'han pogut carregar les preferències';

  @override
  String get settingsPreferenceSaveError =>
      'No s\'ha pogut guardar la preferència';

  @override
  String get settingsNotifGeneral => 'Notificacions';

  @override
  String get settingsNotifGeneralSubtitleOn => 'Rebre notificacions del club';

  @override
  String get settingsNotifGeneralSubtitleOff => 'No rebre notificacions';

  @override
  String get settingsNotifNews => 'Notícies';

  @override
  String get settingsNotifNewsSubtitle => 'Rebre avisos sobre notícies noves';

  @override
  String get settingsNotifMessages => 'Missatges';

  @override
  String get settingsNotifMessagesSubtitle => 'Rebre avisos de missatges nous';

  @override
  String get settingsNotifResults => 'Resultats';

  @override
  String get settingsNotifResultsSubtitle => 'Rebre avisos sobre resultats';

  @override
  String get settingsAppearance => 'Aparença';

  @override
  String get settingsAppearanceSubtitle => 'Tria com vols veure l\'aplicació';

  @override
  String get settingsThemeAuto => 'Automàtic';

  @override
  String get settingsThemeLight => 'Clar';

  @override
  String get settingsThemeDark => 'Fosc';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Tria l\'idioma de l\'aplicació';

  @override
  String get settingsLanguageSpanish => 'Castellà';

  @override
  String get settingsLanguageValencian => 'Valencià';

  @override
  String get settingsAboutApp => 'Sobre appMTX';

  @override
  String get settingsAboutAppSubtitle => 'Informació de l\'aplicació';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ca'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navNews.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get navNews;

  /// No description provided for @navMatches.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get navMatches;

  /// No description provided for @navStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get navStore;

  /// No description provided for @navClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get navClub;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @linkOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido abrir el enlace'**
  String get linkOpenError;

  /// No description provided for @homeNotificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get homeNotificationsTooltip;

  /// No description provided for @homeAreaClub.
  ///
  /// In es, this message translates to:
  /// **'Área Club'**
  String get homeAreaClub;

  /// No description provided for @homeLatestNews.
  ///
  /// In es, this message translates to:
  /// **'Últimas noticias'**
  String get homeLatestNews;

  /// No description provided for @homeOurSponsors.
  ///
  /// In es, this message translates to:
  /// **'Nuestros patrocinadores'**
  String get homeOurSponsors;

  /// No description provided for @homeSponsorsHint.
  ///
  /// In es, this message translates to:
  /// **'Pulsa en las imágenes para conocer más acerca de nuestros patrocinadores.'**
  String get homeSponsorsHint;

  /// No description provided for @homeNewsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar las noticias.'**
  String get homeNewsLoadError;

  /// No description provided for @homeNoNewsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay noticias disponibles.'**
  String get homeNoNewsAvailable;

  /// No description provided for @homeMatchLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar el partido.'**
  String get homeMatchLoadError;

  /// No description provided for @matchUpcoming.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO PARTIDO'**
  String get matchUpcoming;

  /// No description provided for @matchUpcomingFirstTeam.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO PARTIDO PRIMER EQUIPO'**
  String get matchUpcomingFirstTeam;

  /// No description provided for @matchLastResult.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMO RESULTADO'**
  String get matchLastResult;

  /// No description provided for @matchLastResultFirstTeam.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMO RESULTADO PRIMER EQUIPO'**
  String get matchLastResultFirstTeam;

  /// No description provided for @matchVs.
  ///
  /// In es, this message translates to:
  /// **'VS'**
  String get matchVs;

  /// No description provided for @matchNoMatch.
  ///
  /// In es, this message translates to:
  /// **'SIN PARTIDO'**
  String get matchNoMatch;

  /// No description provided for @matchNoMatchFirstTeam.
  ///
  /// In es, this message translates to:
  /// **'SIN PARTIDO PRIMER EQUIPO'**
  String get matchNoMatchFirstTeam;

  /// No description provided for @matchNoMatchThisRound.
  ///
  /// In es, this message translates to:
  /// **'No hay partido esta jornada'**
  String get matchNoMatchThisRound;

  /// No description provided for @matchTeamHasNoMatch.
  ///
  /// In es, this message translates to:
  /// **'No tiene partido'**
  String get matchTeamHasNoMatch;

  /// No description provided for @matchTeamRests.
  ///
  /// In es, this message translates to:
  /// **'Descansa'**
  String get matchTeamRests;

  /// No description provided for @matchesCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'CALENDARIO'**
  String get matchesCalendarTitle;

  /// No description provided for @matchesCalendarSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Partidos y resultados de nuestros equipos'**
  String get matchesCalendarSubtitle;

  /// No description provided for @matchesNoMatchesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay partidos disponibles.'**
  String get matchesNoMatchesAvailable;

  /// No description provided for @matchesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los partidos.'**
  String get matchesLoadError;

  /// No description provided for @matchesNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get matchesNoCategory;

  /// No description provided for @matchesResult.
  ///
  /// In es, this message translates to:
  /// **'RESULTADO'**
  String get matchesResult;

  /// No description provided for @matchesRestsThisRound.
  ///
  /// In es, this message translates to:
  /// **'Descansa esta jornada'**
  String get matchesRestsThisRound;

  /// No description provided for @newsTitle.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get newsTitle;

  /// No description provided for @newsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Noticia'**
  String get newsDetailTitle;

  /// No description provided for @newsLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más noticias'**
  String get newsLoadMore;

  /// No description provided for @newsLoadMoreError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar más noticias.'**
  String get newsLoadMoreError;

  /// No description provided for @storeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get storeTitle;

  /// No description provided for @storeHeroKicker.
  ///
  /// In es, this message translates to:
  /// **'MUTXAMEL CF'**
  String get storeHeroKicker;

  /// No description provided for @storeHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Viste los colores'**
  String get storeHeroTitle;

  /// No description provided for @storeHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La nueva colección del club ya está aquí. Elige tu prenda, selecciona tus tallas y haznos llegar tu pedido.'**
  String get storeHeroSubtitle;

  /// No description provided for @storeProductShirtTitle.
  ///
  /// In es, this message translates to:
  /// **'Camiseta oficial'**
  String get storeProductShirtTitle;

  /// No description provided for @storeProductShirtDescription.
  ///
  /// In es, this message translates to:
  /// **'La esencia del Mutxamel CF, un año más, vestida de azul. Nuestra primera equipación combina la tradición y la identidad del club con un diseño moderno.'**
  String get storeProductShirtDescription;

  /// No description provided for @storeProductSecondKitTitle.
  ///
  /// In es, this message translates to:
  /// **'Segunda equipación'**
  String get storeProductSecondKitTitle;

  /// No description provided for @storeProductSecondKitDescription.
  ///
  /// In es, this message translates to:
  /// **'Mucho más que una camiseta. Nuestra segunda equipación, de color rosa, nace de una colaboración muy especial con la Asociación Española Contra el Cáncer, uniendo deporte, compromiso y solidaridad.'**
  String get storeProductSecondKitDescription;

  /// No description provided for @storeProductSecondKitNote.
  ///
  /// In es, this message translates to:
  /// **'Colaboración con la Asociación Española Contra el Cáncer'**
  String get storeProductSecondKitNote;

  /// No description provided for @storeUnits.
  ///
  /// In es, this message translates to:
  /// **'Unidades'**
  String get storeUnits;

  /// No description provided for @storeSizeUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Talla unidad {n}'**
  String storeSizeUnitLabel(int n);

  /// No description provided for @storeSizeGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía de tallas'**
  String get storeSizeGuideTitle;

  /// No description provided for @storeSizeGuideHint.
  ///
  /// In es, this message translates to:
  /// **'Mide una prenda que te quede bien y compara con estas medidas aproximadas.'**
  String get storeSizeGuideHint;

  /// No description provided for @storeSizeGuideSize.
  ///
  /// In es, this message translates to:
  /// **'Talla'**
  String get storeSizeGuideSize;

  /// No description provided for @storeSizeGuideChest.
  ///
  /// In es, this message translates to:
  /// **'Pecho (cm)'**
  String get storeSizeGuideChest;

  /// No description provided for @storeSizeGuideLength.
  ///
  /// In es, this message translates to:
  /// **'Largo (cm)'**
  String get storeSizeGuideLength;

  /// No description provided for @storeCustomerDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get storeCustomerDataTitle;

  /// No description provided for @storeCustomerDataHint.
  ///
  /// In es, this message translates to:
  /// **'Te escribiremos para confirmar disponibilidad y forma de pago.'**
  String get storeCustomerDataHint;

  /// No description provided for @storeFullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre y apellidos'**
  String get storeFullNameLabel;

  /// No description provided for @storePhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get storePhoneLabel;

  /// No description provided for @storeEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get storeEmailLabel;

  /// No description provided for @storePrivacyAcceptPrefix.
  ///
  /// In es, this message translates to:
  /// **'Acepto el tratamiento de mis datos según la '**
  String get storePrivacyAcceptPrefix;

  /// No description provided for @storePrivacyPolicyLink.
  ///
  /// In es, this message translates to:
  /// **'política de privacidad'**
  String get storePrivacyPolicyLink;

  /// No description provided for @storeCreateOrderButton.
  ///
  /// In es, this message translates to:
  /// **'CREAR PEDIDO'**
  String get storeCreateOrderButton;

  /// No description provided for @storeSendingButton.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get storeSendingButton;

  /// No description provided for @storeErrorEnterName.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nombre y apellidos.'**
  String get storeErrorEnterName;

  /// No description provided for @storeErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido.'**
  String get storeErrorInvalidEmail;

  /// No description provided for @storeErrorAcceptPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar la política de privacidad.'**
  String get storeErrorAcceptPrivacy;

  /// No description provided for @storeErrorSelectSizeForProduct.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la talla de cada unidad de \"{producto}\".'**
  String storeErrorSelectSizeForProduct(String producto);

  /// No description provided for @storeErrorSelectAtLeastOne.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una prenda y sus unidades.'**
  String get storeErrorSelectAtLeastOne;

  /// No description provided for @storeOrderSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Pedido enviado. Nos pondremos en contacto contigo para confirmar el pago y la recogida/envío.'**
  String get storeOrderSentMessage;

  /// No description provided for @clubTitle.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get clubTitle;

  /// No description provided for @clubFullName.
  ///
  /// In es, this message translates to:
  /// **'Mutxamel Club de Fútbol'**
  String get clubFullName;

  /// No description provided for @clubTagline.
  ///
  /// In es, this message translates to:
  /// **'Dónde estamos y cómo contactar con el club'**
  String get clubTagline;

  /// No description provided for @clubSettingsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get clubSettingsTooltip;

  /// No description provided for @clubWhereWeAre.
  ///
  /// In es, this message translates to:
  /// **'Dónde estamos'**
  String get clubWhereWeAre;

  /// No description provided for @clubAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get clubAddress;

  /// No description provided for @clubWebsite.
  ///
  /// In es, this message translates to:
  /// **'Página web'**
  String get clubWebsite;

  /// No description provided for @clubPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get clubPhone;

  /// No description provided for @clubEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get clubEmail;

  /// No description provided for @clubFollowUs.
  ///
  /// In es, this message translates to:
  /// **'Síguenos'**
  String get clubFollowUs;

  /// No description provided for @clubViewOnGoogleMaps.
  ///
  /// In es, this message translates to:
  /// **'Ver en Google Maps'**
  String get clubViewOnGoogleMaps;

  /// No description provided for @clubCopyright.
  ///
  /// In es, this message translates to:
  /// **'© {year} Mutxamel Club de Fútbol'**
  String clubCopyright(int year);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionApplication.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get settingsSectionApplication;

  /// No description provided for @settingsNotifAnonymousHint.
  ///
  /// In es, this message translates to:
  /// **'Actívalas aunque no tengas una cuenta en el club.'**
  String get settingsNotifAnonymousHint;

  /// No description provided for @settingsNotifNewsAnon.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get settingsNotifNewsAnon;

  /// No description provided for @settingsNotifNewsAnonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir avisos de nuevas noticias'**
  String get settingsNotifNewsAnonSubtitle;

  /// No description provided for @settingsNotifResultsFirstTeam.
  ///
  /// In es, this message translates to:
  /// **'Resultados en directo del primer equipo'**
  String get settingsNotifResultsFirstTeam;

  /// No description provided for @settingsNotifResultsFirstTeamSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de goles y resultados en directo'**
  String get settingsNotifResultsFirstTeamSubtitle;

  /// No description provided for @settingsPreferencesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar las preferencias'**
  String get settingsPreferencesLoadError;

  /// No description provided for @settingsPreferenceSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar la preferencia'**
  String get settingsPreferenceSaveError;

  /// No description provided for @settingsNotifGeneral.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifGeneral;

  /// No description provided for @settingsNotifGeneralSubtitleOn.
  ///
  /// In es, this message translates to:
  /// **'Recibir notificaciones del club'**
  String get settingsNotifGeneralSubtitleOn;

  /// No description provided for @settingsNotifGeneralSubtitleOff.
  ///
  /// In es, this message translates to:
  /// **'No recibir notificaciones'**
  String get settingsNotifGeneralSubtitleOff;

  /// No description provided for @settingsNotifNews.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get settingsNotifNews;

  /// No description provided for @settingsNotifNewsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir avisos sobre nuevas noticias'**
  String get settingsNotifNewsSubtitle;

  /// No description provided for @settingsNotifMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get settingsNotifMessages;

  /// No description provided for @settingsNotifMessagesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir avisos de nuevos mensajes'**
  String get settingsNotifMessagesSubtitle;

  /// No description provided for @settingsNotifResults.
  ///
  /// In es, this message translates to:
  /// **'Resultados'**
  String get settingsNotifResults;

  /// No description provided for @settingsNotifResultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir avisos sobre resultados'**
  String get settingsNotifResultsSubtitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres ver la aplicación'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma de la aplicación'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Castellano'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageValencian.
  ///
  /// In es, this message translates to:
  /// **'Valencià'**
  String get settingsLanguageValencian;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsAboutApp.
  ///
  /// In es, this message translates to:
  /// **'Acerca de Mutxamel CF'**
  String get settingsAboutApp;

  /// No description provided for @settingsAboutAppSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Información de la aplicación'**
  String get settingsAboutAppSubtitle;

  /// No description provided for @loginHeading.
  ///
  /// In es, this message translates to:
  /// **'Acceso al Área Club'**
  String get loginHeading;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tus datos para acceder'**
  String get loginSubtitle;

  /// No description provided for @loginEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get loginPasswordRequired;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginButton;

  /// No description provided for @activateAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Activar cuenta'**
  String get activateAccountButton;

  /// No description provided for @clubPageDefaultMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro del club'**
  String get clubPageDefaultMember;

  /// No description provided for @clubPageSectionClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get clubPageSectionClub;

  /// No description provided for @clubPageMyPlayers.
  ///
  /// In es, this message translates to:
  /// **'Mis jugadores'**
  String get clubPageMyPlayers;

  /// No description provided for @clubPageMyPlayersDesc.
  ///
  /// In es, this message translates to:
  /// **'Jugadores vinculados a tu cuenta'**
  String get clubPageMyPlayersDesc;

  /// No description provided for @clubPageFees.
  ///
  /// In es, this message translates to:
  /// **'Cuotas'**
  String get clubPageFees;

  /// No description provided for @clubPageFeesDesc.
  ///
  /// In es, this message translates to:
  /// **'Cuotas de tus jugadores y su estado'**
  String get clubPageFeesDesc;

  /// No description provided for @clubPageFeesComingSoonDesc.
  ///
  /// In es, this message translates to:
  /// **'Próximamente disponible'**
  String get clubPageFeesComingSoonDesc;

  /// No description provided for @clubPageFeesComingSoonMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos trabajando en esta funcionalidad. Estará operativa próximamente.'**
  String get clubPageFeesComingSoonMessage;

  /// No description provided for @clubPageMyTeams.
  ///
  /// In es, this message translates to:
  /// **'Mis equipos'**
  String get clubPageMyTeams;

  /// No description provided for @clubPageMyTeamsDesc.
  ///
  /// In es, this message translates to:
  /// **'Equipos vinculados a tu actividad en el club'**
  String get clubPageMyTeamsDesc;

  /// No description provided for @clubPageMyMatches.
  ///
  /// In es, this message translates to:
  /// **'Mis partidos'**
  String get clubPageMyMatches;

  /// No description provided for @clubPageMyMatchesDesc.
  ///
  /// In es, this message translates to:
  /// **'Próximos partidos y resultados'**
  String get clubPageMyMatchesDesc;

  /// No description provided for @clubPageCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get clubPageCalendar;

  /// No description provided for @clubPageCalendarDesc.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos y partidos de tus equipos'**
  String get clubPageCalendarDesc;

  /// No description provided for @clubPageLiveMatch.
  ///
  /// In es, this message translates to:
  /// **'Partido en directo'**
  String get clubPageLiveMatch;

  /// No description provided for @clubPageLiveMatchDesc.
  ///
  /// In es, this message translates to:
  /// **'Avisos en directo del primer equipo'**
  String get clubPageLiveMatchDesc;

  /// No description provided for @clubPageCommunications.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones'**
  String get clubPageCommunications;

  /// No description provided for @clubPageCommunicationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Avisos y comunicaciones del club'**
  String get clubPageCommunicationsDesc;

  /// No description provided for @clubPageSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get clubPageSectionAccount;

  /// No description provided for @clubSectionPlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get clubSectionPlayer;

  /// No description provided for @clubSectionFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get clubSectionFamily;

  /// No description provided for @clubSectionCoach.
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get clubSectionCoach;

  /// No description provided for @clubSectionCoordination.
  ///
  /// In es, this message translates to:
  /// **'Coordinación'**
  String get clubSectionCoordination;

  /// No description provided for @clubSectionAdministration.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get clubSectionAdministration;

  /// No description provided for @clubSectionBroadcast.
  ///
  /// In es, this message translates to:
  /// **'Retransmisión'**
  String get clubSectionBroadcast;

  /// No description provided for @clubPageMyProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get clubPageMyProfile;

  /// No description provided for @clubPageMyProfileDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus datos personales y configuración'**
  String get clubPageMyProfileDesc;

  /// No description provided for @clubPageLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get clubPageLogout;

  /// No description provided for @aboutVersionText.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String aboutVersionText(String version);

  /// No description provided for @aboutVersionTextWithBuild.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} ({build})'**
  String aboutVersionTextWithBuild(String version, String build);

  /// No description provided for @aboutSectionClub.
  ///
  /// In es, this message translates to:
  /// **'El club'**
  String get aboutSectionClub;

  /// No description provided for @aboutClubDescription.
  ///
  /// In es, this message translates to:
  /// **'La aplicación oficial del Mutxamel Club de Fútbol te mantiene al día de convocatorias, entrenamientos, resultados y comunicaciones del club, estés donde estés.'**
  String get aboutClubDescription;

  /// No description provided for @aboutSectionContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get aboutSectionContact;

  /// No description provided for @aboutSectionLegal.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get aboutSectionLegal;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutPrivacyPolicySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo tratamos tus datos'**
  String get aboutPrivacyPolicySubtitle;

  /// No description provided for @aboutThirdPartyLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias de terceros'**
  String get aboutThirdPartyLicenses;

  /// No description provided for @aboutThirdPartyLicensesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Software libre utilizado en la aplicación'**
  String get aboutThirdPartyLicensesSubtitle;

  /// No description provided for @aboutAppTagline.
  ///
  /// In es, this message translates to:
  /// **'Aplicación oficial del Mutxamel Club de Fútbol'**
  String get aboutAppTagline;

  /// No description provided for @mailAppOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir la aplicación de correo'**
  String get mailAppOpenError;

  /// No description provided for @profileLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar el perfil.'**
  String get profileLoadError;

  /// No description provided for @defaultUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get defaultUser;

  /// No description provided for @profileSectionMyData.
  ///
  /// In es, this message translates to:
  /// **'Mis datos'**
  String get profileSectionMyData;

  /// No description provided for @profileSectionSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profileSectionSettings;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones, apariencia y aplicación'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileRole.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get profileRole;

  /// No description provided for @roleFamiliar.
  ///
  /// In es, this message translates to:
  /// **'Familiar'**
  String get roleFamiliar;

  /// No description provided for @roleJugador.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get roleJugador;

  /// No description provided for @roleEntrenador.
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get roleEntrenador;

  /// No description provided for @roleCoordinador.
  ///
  /// In es, this message translates to:
  /// **'Coordinador'**
  String get roleCoordinador;

  /// No description provided for @roleRetransmision.
  ///
  /// In es, this message translates to:
  /// **'Retransmisión'**
  String get roleRetransmision;

  /// No description provided for @roleAdministrador.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdministrador;

  /// No description provided for @roleSocio.
  ///
  /// In es, this message translates to:
  /// **'Socio'**
  String get roleSocio;

  /// No description provided for @noPlayersLinked.
  ///
  /// In es, this message translates to:
  /// **'No tienes jugadores vinculados a tu cuenta.'**
  String get noPlayersLinked;

  /// No description provided for @playersLinkedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} jugador vinculado} other{{count} jugadores vinculados}}'**
  String playersLinkedCount(int count);

  /// No description provided for @fieldTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get fieldTeam;

  /// No description provided for @fieldSport.
  ///
  /// In es, this message translates to:
  /// **'Deporte'**
  String get fieldSport;

  /// No description provided for @sportFootball.
  ///
  /// In es, this message translates to:
  /// **'Fútbol'**
  String get sportFootball;

  /// No description provided for @fieldDorsal.
  ///
  /// In es, this message translates to:
  /// **'Dorsal'**
  String get fieldDorsal;

  /// No description provided for @fieldPosition.
  ///
  /// In es, this message translates to:
  /// **'Posición'**
  String get fieldPosition;

  /// No description provided for @allTeamsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todos los equipos'**
  String get allTeamsTitle;

  /// No description provided for @noTeamsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay equipos disponibles.'**
  String get noTeamsAvailable;

  /// No description provided for @noTeamsAssociated.
  ///
  /// In es, this message translates to:
  /// **'No tienes equipos asociados.'**
  String get noTeamsAssociated;

  /// No description provided for @playerCountLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de jugadores'**
  String get playerCountLabel;

  /// No description provided for @teamsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los equipos.'**
  String get teamsLoadError;

  /// No description provided for @markAllReadTooltip.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get markAllReadTooltip;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las notificaciones.'**
  String get notificationsLoadError;

  /// No description provided for @noNotifications.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones.'**
  String get noNotifications;

  /// No description provided for @notificationsSignedOutMessage.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en el Área Club para ver tus avisos personales (convocatorias, mensajes…)'**
  String get notificationsSignedOutMessage;

  /// No description provided for @notificationsPublicHint.
  ///
  /// In es, this message translates to:
  /// **'Los avisos de noticias y resultados se activan en Club → Ajustes'**
  String get notificationsPublicHint;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Ir a Ajustes'**
  String get notificationsOpenSettings;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Has olvidado tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @recoverTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recoverTitle;

  /// No description provided for @recoverSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un código por email para que elijas una contraseña nueva.'**
  String get recoverSubtitle;

  /// No description provided for @recoverSendCode.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get recoverSendCode;

  /// No description provided for @recoverCodeSent.
  ///
  /// In es, this message translates to:
  /// **'Si el email tiene una cuenta en el club, recibirás un código en unos minutos. Revisa también la carpeta de spam.'**
  String get recoverCodeSent;

  /// No description provided for @recoverResetHeading.
  ///
  /// In es, this message translates to:
  /// **'Elige tu nueva contraseña'**
  String get recoverResetHeading;

  /// No description provided for @recoverChangePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get recoverChangePassword;

  /// No description provided for @recoverResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get recoverResend;

  /// No description provided for @recoverResendIn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código ({time})'**
  String recoverResendIn(String time);

  /// No description provided for @recoverPasswordChanged.
  ///
  /// In es, this message translates to:
  /// **'Contraseña cambiada'**
  String get recoverPasswordChanged;

  /// No description provided for @recoverCodeInvalid.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto o caducado'**
  String get recoverCodeInvalid;

  /// No description provided for @recoverTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos y vuelve a probar.'**
  String get recoverTooManyAttempts;

  /// No description provided for @recoverChangedLoginHint.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña se ha cambiado. Entra con la nueva contraseña.'**
  String get recoverChangedLoginHint;

  /// No description provided for @recoverNotActivated.
  ///
  /// In es, this message translates to:
  /// **'¿Aún no has activado tu cuenta? Usa el código en'**
  String get recoverNotActivated;

  /// No description provided for @markAllReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron marcar las notificaciones como leídas.'**
  String get markAllReadError;

  /// No description provided for @todayAt.
  ///
  /// In es, this message translates to:
  /// **'Hoy, {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In es, this message translates to:
  /// **'Ayer, {time}'**
  String yesterdayAt(String time);

  /// No description provided for @noFeesRegistered.
  ///
  /// In es, this message translates to:
  /// **'No hay cuotas registradas para tus jugadores.'**
  String get noFeesRegistered;

  /// No description provided for @playersCountSimple.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} jugador} other{{count} jugadores}}'**
  String playersCountSimple(int count);

  /// No description provided for @feesCountLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cuota} other{{count} cuotas}}'**
  String feesCountLabel(int count);

  /// No description provided for @feesAllPaidSuffix.
  ///
  /// In es, this message translates to:
  /// **' · todas pagadas'**
  String get feesAllPaidSuffix;

  /// No description provided for @feesPendingSuffix.
  ///
  /// In es, this message translates to:
  /// **' · {pending} por pagar'**
  String feesPendingSuffix(int pending);

  /// No description provided for @noPaymentRegistered.
  ///
  /// In es, this message translates to:
  /// **'Esta cuota todavía no tiene ningún pago registrado.'**
  String get noPaymentRegistered;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @noDateRegistered.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha registrada'**
  String get noDateRegistered;

  /// No description provided for @methodNotIndicated.
  ///
  /// In es, this message translates to:
  /// **'Método no indicado'**
  String get methodNotIndicated;

  /// No description provided for @feeStatusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get feeStatusOverdue;

  /// No description provided for @feeStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagada'**
  String get feeStatusPaid;

  /// No description provided for @feeStatusPartial.
  ///
  /// In es, this message translates to:
  /// **'Pago parcial'**
  String get feeStatusPartial;

  /// No description provided for @feeStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get feeStatusPending;

  /// No description provided for @chatDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chatDefaultTitle;

  /// No description provided for @chatNoMessages.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay mensajes. Escribe el primero.'**
  String get chatNoMessages;

  /// No description provided for @chatMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatMessageHint;

  /// No description provided for @tabConversations.
  ///
  /// In es, this message translates to:
  /// **'Conversaciones'**
  String get tabConversations;

  /// No description provided for @tabReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibidas'**
  String get tabReceived;

  /// No description provided for @tabSent.
  ///
  /// In es, this message translates to:
  /// **'Enviadas'**
  String get tabSent;

  /// No description provided for @newButton.
  ///
  /// In es, this message translates to:
  /// **'Nueva'**
  String get newButton;

  /// No description provided for @noConversations.
  ///
  /// In es, this message translates to:
  /// **'No tienes conversaciones'**
  String get noConversations;

  /// No description provided for @noConversationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán tus chats privados.'**
  String get noConversationsSubtitle;

  /// No description provided for @noCommunicationsReceived.
  ///
  /// In es, this message translates to:
  /// **'No tienes comunicaciones'**
  String get noCommunicationsReceived;

  /// No description provided for @noCommunicationsReceivedSubtitleGlobal.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán las comunicaciones del club.'**
  String get noCommunicationsReceivedSubtitleGlobal;

  /// No description provided for @noCommunicationsReceivedSubtitleTeam.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán las comunicaciones de tus equipos.'**
  String get noCommunicationsReceivedSubtitleTeam;

  /// No description provided for @noCommunicationsSent.
  ///
  /// In es, this message translates to:
  /// **'No has enviado comunicaciones'**
  String get noCommunicationsSent;

  /// No description provided for @noCommunicationsSentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán las comunicaciones que hayas enviado.'**
  String get noCommunicationsSentSubtitle;

  /// No description provided for @splashTagline.
  ///
  /// In es, this message translates to:
  /// **'La app oficial del club'**
  String get splashTagline;

  /// No description provided for @activateHeading.
  ///
  /// In es, this message translates to:
  /// **'Activa tu cuenta'**
  String get activateHeading;

  /// No description provided for @activateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email y el código de 6 dígitos que te ha enviado el club por correo, y elige tu contraseña de acceso.'**
  String get activateSubtitle;

  /// No description provided for @codeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código de 6 dígitos'**
  String get codeLabel;

  /// No description provided for @codeRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código que te enviamos por email'**
  String get codeRequired;

  /// No description provided for @codeLength.
  ///
  /// In es, this message translates to:
  /// **'El código debe tener 6 dígitos'**
  String get codeLength;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPasswordLabel;

  /// No description provided for @passwordChooseRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige una contraseña'**
  String get passwordChooseRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 8 caracteres'**
  String get passwordMinLength;

  /// No description provided for @repeatPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get repeatPasswordLabel;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDontMatch;

  /// No description provided for @activateAndEnterButton.
  ///
  /// In es, this message translates to:
  /// **'Activar y entrar'**
  String get activateAndEnterButton;

  /// No description provided for @commDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunicación'**
  String get commDetailTitle;

  /// No description provided for @commLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar la comunicación.'**
  String get commLoadError;

  /// No description provided for @commNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva comunicación'**
  String get commNewTitle;

  /// No description provided for @commSelectRecipientError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona a quién quieres escribir.'**
  String get commSelectRecipientError;

  /// No description provided for @commSelectTeamError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un equipo.'**
  String get commSelectTeamError;

  /// No description provided for @commSelectCategoryError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una categoría.'**
  String get commSelectCategoryError;

  /// No description provided for @commSelectRecipientPersonError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un destinatario.'**
  String get commSelectRecipientPersonError;

  /// No description provided for @commCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Comunicación creada correctamente.'**
  String get commCreatedSuccess;

  /// No description provided for @commCreateError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido crear la comunicación: {error}'**
  String commCreateError(String error);

  /// No description provided for @titleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el título'**
  String get titleHint;

  /// No description provided for @titleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio.'**
  String get titleRequired;

  /// No description provided for @messageLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get messageLabel;

  /// No description provided for @messageHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el contenido de la comunicación'**
  String get messageHint;

  /// No description provided for @messageRequired.
  ///
  /// In es, this message translates to:
  /// **'El mensaje es obligatorio.'**
  String get messageRequired;

  /// No description provided for @recipientsTitle.
  ///
  /// In es, this message translates to:
  /// **'Destinatarios'**
  String get recipientsTitle;

  /// No description provided for @teamsSegment.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get teamsSegment;

  /// No description provided for @categoriesSegment.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoriesSegment;

  /// No description provided for @privateSegment.
  ///
  /// In es, this message translates to:
  /// **'Privado'**
  String get privateSegment;

  /// No description provided for @noRecipientsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No tienes ningún destinatario disponible para escribir una comunicación.'**
  String get noRecipientsAvailable;

  /// No description provided for @chooseTeamsHint.
  ///
  /// In es, this message translates to:
  /// **'Elige uno o varios equipos.'**
  String get chooseTeamsHint;

  /// No description provided for @chooseCategoriesHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una o varias categorías.'**
  String get chooseCategoriesHint;

  /// No description provided for @choosePrivateRecipientHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una única persona; el mensaje será privado solo para ella.'**
  String get choosePrivateRecipientHint;

  /// No description provided for @searchRecipientLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar destinatario'**
  String get searchRecipientLabel;

  /// No description provided for @searchRecipientHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre o apellidos'**
  String get searchRecipientHint;

  /// No description provided for @noRecipientsFound.
  ///
  /// In es, this message translates to:
  /// **'No se han encontrado destinatarios.'**
  String get noRecipientsFound;

  /// No description provided for @savingButton.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get savingButton;

  /// No description provided for @saveCommunicationButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar comunicación'**
  String get saveCommunicationButton;

  /// No description provided for @recipientsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los destinatarios.'**
  String get recipientsLoadError;

  /// No description provided for @liveMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Partido en directo'**
  String get liveMatchTitle;

  /// No description provided for @liveMatchWarning.
  ///
  /// In es, this message translates to:
  /// **'Cada botón manda un aviso en directo a todos los usuarios de la app. Puedes deshacer el último aviso durante 2 minutos; pasado ese tiempo ya no se puede.'**
  String get liveMatchWarning;

  /// No description provided for @liveEventKickoff.
  ///
  /// In es, this message translates to:
  /// **'Inicio de partido'**
  String get liveEventKickoff;

  /// No description provided for @liveConfirmKickoff.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar de que empieza el partido?'**
  String get liveConfirmKickoff;

  /// No description provided for @liveEventGoalAgainst.
  ///
  /// In es, this message translates to:
  /// **'Gol en contra'**
  String get liveEventGoalAgainst;

  /// No description provided for @liveConfirmGoalAgainst.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar de un gol en contra?'**
  String get liveConfirmGoalAgainst;

  /// No description provided for @liveEventHalftime.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get liveEventHalftime;

  /// No description provided for @liveConfirmHalftime.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar del descanso?'**
  String get liveConfirmHalftime;

  /// No description provided for @liveEventSecondHalf.
  ///
  /// In es, this message translates to:
  /// **'Segunda parte'**
  String get liveEventSecondHalf;

  /// No description provided for @liveConfirmSecondHalf.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar del inicio de la segunda parte?'**
  String get liveConfirmSecondHalf;

  /// No description provided for @liveEventFulltime.
  ///
  /// In es, this message translates to:
  /// **'Final de partido'**
  String get liveEventFulltime;

  /// No description provided for @liveConfirmFulltime.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar de que ha finalizado el partido?'**
  String get liveConfirmFulltime;

  /// No description provided for @liveLineupButton.
  ///
  /// In es, this message translates to:
  /// **'Alineación'**
  String get liveLineupButton;

  /// No description provided for @liveGoalForButton.
  ///
  /// In es, this message translates to:
  /// **'Gol a favor'**
  String get liveGoalForButton;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @liveStartingLineupLabel.
  ///
  /// In es, this message translates to:
  /// **'Once inicial'**
  String get liveStartingLineupLabel;

  /// No description provided for @liveSubstitutesLabel.
  ///
  /// In es, this message translates to:
  /// **'Suplentes'**
  String get liveSubstitutesLabel;

  /// No description provided for @liveFillLineupError.
  ///
  /// In es, this message translates to:
  /// **'Rellena el once inicial y los suplentes.'**
  String get liveFillLineupError;

  /// No description provided for @liveLineupSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Alineación enviada.'**
  String get liveLineupSentMessage;

  /// No description provided for @liveEnterGoalAuthorError.
  ///
  /// In es, this message translates to:
  /// **'Escribe el autor del gol.'**
  String get liveEnterGoalAuthorError;

  /// No description provided for @liveGoalSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Gol enviado.'**
  String get liveGoalSentMessage;

  /// No description provided for @liveNoMatchesToday.
  ///
  /// In es, this message translates to:
  /// **'No hay ningún partido del Primer Equipo hoy'**
  String get liveNoMatchesToday;

  /// No description provided for @liveChooseMatch.
  ///
  /// In es, this message translates to:
  /// **'Elige el partido que vas a retransmitir'**
  String get liveChooseMatch;

  /// No description provided for @liveMatchHome.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get liveMatchHome;

  /// No description provided for @liveMatchAway.
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get liveMatchAway;

  /// No description provided for @liveChangeMatch.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de partido'**
  String get liveChangeMatch;

  /// No description provided for @liveLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los partidos de hoy.'**
  String get liveLoadError;

  /// No description provided for @livePhaseNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Sin empezar'**
  String get livePhaseNotStarted;

  /// No description provided for @livePhaseFirstHalf.
  ///
  /// In es, this message translates to:
  /// **'1ª parte'**
  String get livePhaseFirstHalf;

  /// No description provided for @livePhaseHalftime.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get livePhaseHalftime;

  /// No description provided for @livePhaseSecondHalf.
  ///
  /// In es, this message translates to:
  /// **'2ª parte'**
  String get livePhaseSecondHalf;

  /// No description provided for @livePhaseFinished.
  ///
  /// In es, this message translates to:
  /// **'Final'**
  String get livePhaseFinished;

  /// No description provided for @liveScorers.
  ///
  /// In es, this message translates to:
  /// **'Goleadores'**
  String get liveScorers;

  /// No description provided for @liveNoScorersYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay goles a favor'**
  String get liveNoScorersYet;

  /// No description provided for @liveOwnGoalShort.
  ///
  /// In es, this message translates to:
  /// **'p.p. (propia puerta del rival)'**
  String get liveOwnGoalShort;

  /// No description provided for @liveGoalAuthorTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quién ha marcado?'**
  String get liveGoalAuthorTitle;

  /// No description provided for @liveGoalOther.
  ///
  /// In es, this message translates to:
  /// **'Otro…'**
  String get liveGoalOther;

  /// No description provided for @liveGoalOtherLabel.
  ///
  /// In es, this message translates to:
  /// **'Autor del gol (máx. 60 caracteres)'**
  String get liveGoalOtherLabel;

  /// No description provided for @liveGoalOwnGoal.
  ///
  /// In es, this message translates to:
  /// **'Propia puerta (rival)'**
  String get liveGoalOwnGoal;

  /// No description provided for @liveNoPlayersToPick.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores en la lista: elige \"Otro\" o \"Propia puerta\".'**
  String get liveNoPlayersToPick;

  /// No description provided for @liveUndoButton.
  ///
  /// In es, this message translates to:
  /// **'Deshacer ({time})'**
  String liveUndoButton(String time);

  /// No description provided for @liveUndoLast.
  ///
  /// In es, this message translates to:
  /// **'Último aviso: {event}'**
  String liveUndoLast(String event);

  /// No description provided for @liveUndoFulltimeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deshacer el final?'**
  String get liveUndoFulltimeTitle;

  /// No description provided for @liveUndoFulltimeMessage.
  ///
  /// In es, this message translates to:
  /// **'Se anulará el final del partido y se devolverá a como estaba el resultado guardado.'**
  String get liveUndoFulltimeMessage;

  /// No description provided for @liveUndoneMessage.
  ///
  /// In es, this message translates to:
  /// **'Aviso deshecho.'**
  String get liveUndoneMessage;

  /// No description provided for @liveUndoConfirm.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get liveUndoConfirm;

  /// No description provided for @liveEventAlert.
  ///
  /// In es, this message translates to:
  /// **'Aviso'**
  String get liveEventAlert;

  /// No description provided for @liveNotificationSentMessage.
  ///
  /// In es, this message translates to:
  /// **'Aviso de \"{titulo}\" enviado.'**
  String liveNotificationSentMessage(String titulo);

  /// No description provided for @liveSendError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido enviar el aviso: {error}'**
  String liveSendError(String error);

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @trainingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos'**
  String get trainingsTitle;

  /// No description provided for @newMasculineButton.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newMasculineButton;

  /// No description provided for @trainingsNextBadge.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO ENTRENAMIENTO'**
  String get trainingsNextBadge;

  /// No description provided for @noUpcomingTrainings.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamientos en las próximas dos semanas.'**
  String get noUpcomingTrainings;

  /// No description provided for @pastTrainingsButton.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos pasados'**
  String get pastTrainingsButton;

  /// No description provided for @pastTrainingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos pasados'**
  String get pastTrainingsTitle;

  /// No description provided for @noPastTrainings.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay entrenamientos anteriores.'**
  String get noPastTrainings;

  /// No description provided for @trainingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los entrenamientos.'**
  String get trainingsLoadError;

  /// No description provided for @editTrainingTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar entrenamiento'**
  String get editTrainingTitle;

  /// No description provided for @newTrainingTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo entrenamiento'**
  String get newTrainingTitle;

  /// No description provided for @noPlayersForTraining.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores para registrar el entrenamiento.'**
  String get noPlayersForTraining;

  /// No description provided for @trainingDateFutureError.
  ///
  /// In es, this message translates to:
  /// **'La fecha del entrenamiento no puede ser posterior a hoy.'**
  String get trainingDateFutureError;

  /// No description provided for @trainingUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento actualizado correctamente.'**
  String get trainingUpdatedSuccess;

  /// No description provided for @trainingSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento guardado correctamente.'**
  String get trainingSavedSuccess;

  /// No description provided for @trainingSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar: {error}'**
  String trainingSaveError(String error);

  /// No description provided for @trainingDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha del entrenamiento'**
  String get trainingDateLabel;

  /// No description provided for @attendanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get attendanceTitle;

  /// No description provided for @attendanceHint.
  ///
  /// In es, this message translates to:
  /// **'Marca el estado de cada jugador'**
  String get attendanceHint;

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In es, this message translates to:
  /// **'Presente'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusAbsent.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get attendanceStatusAbsent;

  /// No description provided for @attendanceStatusLate.
  ///
  /// In es, this message translates to:
  /// **'Retraso'**
  String get attendanceStatusLate;

  /// No description provided for @attendanceStatusJustifiedAbsence.
  ///
  /// In es, this message translates to:
  /// **'Falta justificada'**
  String get attendanceStatusJustifiedAbsence;

  /// No description provided for @attendanceStatusMisconduct.
  ///
  /// In es, this message translates to:
  /// **'Mal comportamiento'**
  String get attendanceStatusMisconduct;

  /// No description provided for @saveChangesButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChangesButton;

  /// No description provided for @saveTrainingButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar entrenamiento'**
  String get saveTrainingButton;

  /// No description provided for @noPlayersAvailableForTeam.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores disponibles para este equipo.'**
  String get noPlayersAvailableForTeam;

  /// No description provided for @playersLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los jugadores.'**
  String get playersLoadError;

  /// No description provided for @callupsTitle.
  ///
  /// In es, this message translates to:
  /// **'Convocatorias'**
  String get callupsTitle;

  /// No description provided for @noCallupsYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay convocatorias.'**
  String get noCallupsYet;

  /// No description provided for @createFirstCallupHint.
  ///
  /// In es, this message translates to:
  /// **'Crea la primera pulsando el botón Nueva.'**
  String get createFirstCallupHint;

  /// No description provided for @callupsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar las convocatorias.'**
  String get callupsLoadError;

  /// No description provided for @editCallupTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar convocatoria'**
  String get editCallupTitle;

  /// No description provided for @newCallupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva convocatoria'**
  String get newCallupTitle;

  /// No description provided for @rivalLabel.
  ///
  /// In es, this message translates to:
  /// **'Rival'**
  String get rivalLabel;

  /// No description provided for @fieldLabelCampo.
  ///
  /// In es, this message translates to:
  /// **'Campo'**
  String get fieldLabelCampo;

  /// No description provided for @matchTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora del partido'**
  String get matchTimeLabel;

  /// No description provided for @callupTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora de convocatoria'**
  String get callupTimeLabel;

  /// No description provided for @callupPlaceLabel.
  ///
  /// In es, this message translates to:
  /// **'Lugar de convocatoria'**
  String get callupPlaceLabel;

  /// No description provided for @matchDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha del partido'**
  String get matchDateLabel;

  /// No description provided for @selectMatchLabel.
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get selectMatchLabel;

  /// No description provided for @selectMatchHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un partido'**
  String get selectMatchHint;

  /// No description provided for @selectMatchError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un partido.'**
  String get selectMatchError;

  /// No description provided for @noMatchesAvailableForCallup.
  ///
  /// In es, this message translates to:
  /// **'No hay partidos disponibles para crear una convocatoria. Crea primero un partido.'**
  String get noMatchesAvailableForCallup;

  /// No description provided for @callupPlayersTitle.
  ///
  /// In es, this message translates to:
  /// **'Jugadores convocados'**
  String get callupPlayersTitle;

  /// No description provided for @selectedCountLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} seleccionados'**
  String selectedCountLabel(int count);

  /// No description provided for @saveCallupButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar convocatoria'**
  String get saveCallupButton;

  /// No description provided for @enterCallupPlaceError.
  ///
  /// In es, this message translates to:
  /// **'Introduce el lugar de convocatoria.'**
  String get enterCallupPlaceError;

  /// No description provided for @selectAtLeastOnePlayerError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un jugador.'**
  String get selectAtLeastOnePlayerError;

  /// No description provided for @callupUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria actualizada correctamente.'**
  String get callupUpdatedSuccess;

  /// No description provided for @callupCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria creada correctamente.'**
  String get callupCreatedSuccess;

  /// No description provided for @callupUpdateError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido actualizar la convocatoria: {error}'**
  String callupUpdateError(String error);

  /// No description provided for @callupCreateError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido crear la convocatoria: {error}'**
  String callupCreateError(String error);

  /// No description provided for @teamManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión del equipo'**
  String get teamManagementTitle;

  /// No description provided for @trainingsDesc.
  ///
  /// In es, this message translates to:
  /// **'Crear y consultar entrenamientos y asistencia'**
  String get trainingsDesc;

  /// No description provided for @callupsDesc.
  ///
  /// In es, this message translates to:
  /// **'Crear y consultar convocatorias de partidos'**
  String get callupsDesc;

  /// No description provided for @playersMenuLabel.
  ///
  /// In es, this message translates to:
  /// **'Jugadores'**
  String get playersMenuLabel;

  /// No description provided for @playersMenuDesc.
  ///
  /// In es, this message translates to:
  /// **'Consultar los jugadores del equipo'**
  String get playersMenuDesc;

  /// No description provided for @noPlayersInTeam.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores en este equipo.'**
  String get noPlayersInTeam;

  /// No description provided for @matchResultPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de resultado'**
  String get matchResultPending;

  /// No description provided for @viewStandings.
  ///
  /// In es, this message translates to:
  /// **'Ver clasificación'**
  String get viewStandings;

  /// No description provided for @seasonTitle.
  ///
  /// In es, this message translates to:
  /// **'Temporada {name}'**
  String seasonTitle(String name);

  /// No description provided for @seasonTitleNoName.
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get seasonTitleNoName;

  /// No description provided for @seasonNoData.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay datos de esta temporada'**
  String get seasonNoData;

  /// No description provided for @seasonGoals.
  ///
  /// In es, this message translates to:
  /// **'Goles'**
  String get seasonGoals;

  /// No description provided for @seasonAssists.
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get seasonAssists;

  /// No description provided for @seasonYellows.
  ///
  /// In es, this message translates to:
  /// **'Amarillas'**
  String get seasonYellows;

  /// No description provided for @seasonReds.
  ///
  /// In es, this message translates to:
  /// **'Rojas'**
  String get seasonReds;

  /// No description provided for @seasonCallupsCard.
  ///
  /// In es, this message translates to:
  /// **'Convocatorias'**
  String get seasonCallupsCard;

  /// No description provided for @seasonTrainingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos'**
  String get seasonTrainingsTitle;

  /// No description provided for @seasonTrainingsLine.
  ///
  /// In es, this message translates to:
  /// **'{attended} de {total} ({percent} %)'**
  String seasonTrainingsLine(int attended, int total, int percent);

  /// No description provided for @seasonTrainingsNone.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay entrenamientos'**
  String get seasonTrainingsNone;

  /// No description provided for @seasonAbsences.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 falta} other{{count} faltas}}'**
  String seasonAbsences(int count);

  /// No description provided for @seasonExcused.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 justificada} other{{count} justificadas}}'**
  String seasonExcused(int count);

  /// No description provided for @seasonShortTrainings.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos {attended}/{total}'**
  String seasonShortTrainings(int attended, int total);

  /// No description provided for @seasonShortGoals.
  ///
  /// In es, this message translates to:
  /// **'{goals, plural, =1{1 gol} other{{goals} goles}}'**
  String seasonShortGoals(int goals);

  /// No description provided for @clubPageMyCard.
  ///
  /// In es, this message translates to:
  /// **'Mi ficha'**
  String get clubPageMyCard;

  /// No description provided for @clubPageMyCardDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus datos de jugador'**
  String get clubPageMyCardDesc;

  /// No description provided for @callupMatchLine.
  ///
  /// In es, this message translates to:
  /// **'Partido: {date}'**
  String callupMatchLine(String date);

  /// No description provided for @callupMeetingLine.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria: {time} · {place}'**
  String callupMeetingLine(String time, String place);

  /// No description provided for @callupReasonShown.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String callupReasonShown(String reason);

  /// No description provided for @clubPageMyStandings.
  ///
  /// In es, this message translates to:
  /// **'Mis clasificaciones'**
  String get clubPageMyStandings;

  /// No description provided for @clubPageMyStandingsDesc.
  ///
  /// In es, this message translates to:
  /// **'Clasificación de tus equipos'**
  String get clubPageMyStandingsDesc;

  /// No description provided for @allStandingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clasificaciones'**
  String get allStandingsTitle;

  /// No description provided for @clubPageAllStandingsDesc.
  ///
  /// In es, this message translates to:
  /// **'Clasificación de todos los equipos'**
  String get clubPageAllStandingsDesc;

  /// No description provided for @standingsNone.
  ///
  /// In es, this message translates to:
  /// **'Sin clasificación todavía'**
  String get standingsNone;

  /// No description provided for @standingsSummary.
  ///
  /// In es, this message translates to:
  /// **'{pos}º · {pts} pts · J{round}'**
  String standingsSummary(int pos, int pts, int round);

  /// No description provided for @standingsSummaryNoRound.
  ///
  /// In es, this message translates to:
  /// **'{pos}º · {pts} pts'**
  String standingsSummaryNoRound(int pos, int pts);

  /// No description provided for @standingsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Jornada {round} · actualizado el {date}'**
  String standingsUpdated(int round, String date);

  /// No description provided for @standingsUpdatedNoRound.
  ///
  /// In es, this message translates to:
  /// **'Actualizado el {date}'**
  String standingsUpdatedNoRound(String date);

  /// No description provided for @standingsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Clasificación no disponible todavía'**
  String get standingsEmpty;

  /// No description provided for @standingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar la clasificación.'**
  String get standingsLoadError;

  /// No description provided for @standingsColPos.
  ///
  /// In es, this message translates to:
  /// **'Pos'**
  String get standingsColPos;

  /// No description provided for @standingsColTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get standingsColTeam;

  /// No description provided for @standingsColPlayed.
  ///
  /// In es, this message translates to:
  /// **'PJ'**
  String get standingsColPlayed;

  /// No description provided for @standingsColPoints.
  ///
  /// In es, this message translates to:
  /// **'Pts'**
  String get standingsColPoints;

  /// No description provided for @standingsColWon.
  ///
  /// In es, this message translates to:
  /// **'G'**
  String get standingsColWon;

  /// No description provided for @standingsColDrawn.
  ///
  /// In es, this message translates to:
  /// **'E'**
  String get standingsColDrawn;

  /// No description provided for @standingsColLost.
  ///
  /// In es, this message translates to:
  /// **'P'**
  String get standingsColLost;

  /// No description provided for @standingsColGoalsFor.
  ///
  /// In es, this message translates to:
  /// **'GF'**
  String get standingsColGoalsFor;

  /// No description provided for @standingsColGoalsAgainst.
  ///
  /// In es, this message translates to:
  /// **'GC'**
  String get standingsColGoalsAgainst;

  /// No description provided for @familiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Familiares'**
  String get familiesTitle;

  /// No description provided for @phoneAppOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir la aplicación de teléfono'**
  String get phoneAppOpenError;

  /// No description provided for @whatsappOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir WhatsApp'**
  String get whatsappOpenError;

  /// No description provided for @noFamiliesRegistered.
  ///
  /// In es, this message translates to:
  /// **'Este jugador no tiene familiares registrados'**
  String get noFamiliesRegistered;

  /// No description provided for @callButton.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get callButton;

  /// No description provided for @emailButton.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get emailButton;

  /// No description provided for @whatsappButton.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get whatsappButton;

  /// No description provided for @allMatchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Todos los partidos'**
  String get allMatchesTitle;

  /// No description provided for @matchDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partido eliminado correctamente.'**
  String get matchDeletedSuccess;

  /// No description provided for @matchCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partido creado correctamente.'**
  String get matchCreatedSuccess;

  /// No description provided for @matchUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partido actualizado correctamente.'**
  String get matchUpdatedSuccess;

  /// No description provided for @teamMatchesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los partidos de este equipo.'**
  String get teamMatchesLoadError;

  /// No description provided for @addMatchButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir partido'**
  String get addMatchButton;

  /// No description provided for @teamNoMatchesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay partidos disponibles para este equipo.'**
  String get teamNoMatchesAvailable;

  /// No description provided for @editMatchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar partido'**
  String get editMatchTooltip;

  /// No description provided for @matchTypeLiga.
  ///
  /// In es, this message translates to:
  /// **'Liga'**
  String get matchTypeLiga;

  /// No description provided for @matchTypeAmistoso.
  ///
  /// In es, this message translates to:
  /// **'Amistoso'**
  String get matchTypeAmistoso;

  /// No description provided for @matchTypeCopa.
  ///
  /// In es, this message translates to:
  /// **'Copa'**
  String get matchTypeCopa;

  /// No description provided for @matchTypeTorneo.
  ///
  /// In es, this message translates to:
  /// **'Torneo'**
  String get matchTypeTorneo;

  /// No description provided for @rivalRequiredError.
  ///
  /// In es, this message translates to:
  /// **'El rival es obligatorio.'**
  String get rivalRequiredError;

  /// No description provided for @deleteMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar partido'**
  String get deleteMatchTitle;

  /// No description provided for @deleteMatchConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este partido? Esta acción no se puede deshacer.'**
  String get deleteMatchConfirm;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @editMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar partido'**
  String get editMatchTitle;

  /// No description provided for @newMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo partido'**
  String get newMatchTitle;

  /// No description provided for @matchTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de partido'**
  String get matchTypeLabel;

  /// No description provided for @noDateSelected.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get noDateSelected;

  /// No description provided for @dateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get dateLabel;

  /// No description provided for @hourLabelHint.
  ///
  /// In es, this message translates to:
  /// **'Hora (ej. 18:00)'**
  String get hourLabelHint;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @calendarAllTeamsTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario de equipos'**
  String get calendarAllTeamsTitle;

  /// No description provided for @calendarLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar el calendario.'**
  String get calendarLoadError;

  /// No description provided for @calendarNoItems.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamientos ni partidos programados.'**
  String get calendarNoItems;

  /// No description provided for @calendarSessionLabel.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get calendarSessionLabel;

  /// No description provided for @calendarMatchLabel.
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get calendarMatchLabel;

  /// No description provided for @calendarCancelledBadge.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get calendarCancelledBadge;

  /// No description provided for @calendarJustifiedBadge.
  ///
  /// In es, this message translates to:
  /// **'Justificada'**
  String get calendarJustifiedBadge;

  /// No description provided for @calendarCalledUpBadge.
  ///
  /// In es, this message translates to:
  /// **'Convocado'**
  String get calendarCalledUpBadge;

  /// No description provided for @calendarNotCalledUpBadge.
  ///
  /// In es, this message translates to:
  /// **'No convocado'**
  String get calendarNotCalledUpBadge;

  /// No description provided for @matchResultLabel.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get matchResultLabel;

  /// No description provided for @calendarJustifyAbsenceButton.
  ///
  /// In es, this message translates to:
  /// **'Justificar falta'**
  String get calendarJustifyAbsenceButton;

  /// No description provided for @calendarEditJustificationButton.
  ///
  /// In es, this message translates to:
  /// **'Editar justificación'**
  String get calendarEditJustificationButton;

  /// No description provided for @calendarJustifyAbsenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Justificar falta a entrenamiento'**
  String get calendarJustifyAbsenceTitle;

  /// No description provided for @calendarEditJustificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar justificación de falta'**
  String get calendarEditJustificationTitle;

  /// No description provided for @calendarJustifyAbsenceHint.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo de la falta (opcional). Si ya habías justificado esta sesión, se actualizará el motivo.'**
  String get calendarJustifyAbsenceHint;

  /// No description provided for @calendarEditJustificationHint.
  ///
  /// In es, this message translates to:
  /// **'Ya has justificado esta falta. Puedes editar el motivo si quieres.'**
  String get calendarEditJustificationHint;

  /// No description provided for @calendarJustifyAbsenceReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get calendarJustifyAbsenceReasonLabel;

  /// No description provided for @calendarJustifyAbsenceSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get calendarJustifyAbsenceSubmit;

  /// No description provided for @calendarJustifyAbsenceSuccess.
  ///
  /// In es, this message translates to:
  /// **'Falta justificada correctamente.'**
  String get calendarJustifyAbsenceSuccess;

  /// No description provided for @calendarManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendarManagementTitle;

  /// No description provided for @calendarManagementDesc.
  ///
  /// In es, this message translates to:
  /// **'Horario semanal, sesiones y partidos del equipo'**
  String get calendarManagementDesc;

  /// No description provided for @calendarManagementLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar el calendario del equipo.'**
  String get calendarManagementLoadError;

  /// No description provided for @weeklyScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Horario semanal de entrenamientos'**
  String get weeklyScheduleTitle;

  /// No description provided for @weeklyScheduleEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha configurado ningún horario semanal para este equipo.'**
  String get weeklyScheduleEmpty;

  /// No description provided for @weeklyScheduleAddButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir horario'**
  String get weeklyScheduleAddButton;

  /// No description provided for @weeklyScheduleEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar horario'**
  String get weeklyScheduleEditTooltip;

  /// No description provided for @weeklyScheduleDeactivateTooltip.
  ///
  /// In es, this message translates to:
  /// **'Desactivar horario'**
  String get weeklyScheduleDeactivateTooltip;

  /// No description provided for @weeklyScheduleDeactivateConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Desactivar horario'**
  String get weeklyScheduleDeactivateConfirmTitle;

  /// No description provided for @weeklyScheduleDeactivateConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se desactivará este horario y se cancelarán sus sesiones futuras todavía programadas. ¿Continuar?'**
  String get weeklyScheduleDeactivateConfirmMessage;

  /// No description provided for @weeklyScheduleDeactivatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Horario desactivado.'**
  String get weeklyScheduleDeactivatedSuccess;

  /// No description provided for @weeklyScheduleDeactivateError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido desactivar el horario: {error}'**
  String weeklyScheduleDeactivateError(String error);

  /// No description provided for @weeklyScheduleSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Horario guardado correctamente.'**
  String get weeklyScheduleSavedSuccess;

  /// No description provided for @weeklyScheduleFormTitleNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo horario'**
  String get weeklyScheduleFormTitleNew;

  /// No description provided for @weeklyScheduleFormTitleEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar horario'**
  String get weeklyScheduleFormTitleEdit;

  /// No description provided for @weeklyScheduleDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de la semana'**
  String get weeklyScheduleDayLabel;

  /// No description provided for @weeklyScheduleTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get weeklyScheduleTimeLabel;

  /// No description provided for @weeklySchedulePlaceLabel.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get weeklySchedulePlaceLabel;

  /// No description provided for @weeklyScheduleActiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get weeklyScheduleActiveLabel;

  /// No description provided for @weeklyScheduleInactiveBadge.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get weeklyScheduleInactiveBadge;

  /// No description provided for @upcomingItemsTitle.
  ///
  /// In es, this message translates to:
  /// **'Próximas sesiones y partidos'**
  String get upcomingItemsTitle;

  /// No description provided for @upcomingItemsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamientos ni partidos programados en las próximas semanas.'**
  String get upcomingItemsEmpty;

  /// No description provided for @sessionEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar sesión'**
  String get sessionEditTooltip;

  /// No description provided for @sessionEditFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar sesión de entrenamiento'**
  String get sessionEditFormTitle;

  /// No description provided for @sessionEditSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión actualizada correctamente.'**
  String get sessionEditSavedSuccess;

  /// No description provided for @sessionCancelTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cancelar sesión'**
  String get sessionCancelTooltip;

  /// No description provided for @sessionCancelConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar sesión'**
  String get sessionCancelConfirmTitle;

  /// No description provided for @sessionCancelConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se avisará a los jugadores y familiares. Esta acción no se puede deshacer. Indica el motivo de la cancelación:'**
  String get sessionCancelConfirmMessage;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get cancelReasonLabel;

  /// No description provided for @cancelReasonRequiredError.
  ///
  /// In es, this message translates to:
  /// **'El motivo es obligatorio'**
  String get cancelReasonRequiredError;

  /// No description provided for @sessionCancelledSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión cancelada.'**
  String get sessionCancelledSuccess;

  /// No description provided for @sessionCancelError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cancelar la sesión: {error}'**
  String sessionCancelError(String error);

  /// No description provided for @matchCancelTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cancelar partido'**
  String get matchCancelTooltip;

  /// No description provided for @matchCancelConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar partido'**
  String get matchCancelConfirmTitle;

  /// No description provided for @matchCancelConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se cancelará este partido. Esta acción no se puede deshacer. ¿Continuar?'**
  String get matchCancelConfirmMessage;

  /// No description provided for @matchCancelledSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partido cancelado.'**
  String get matchCancelledSuccess;

  /// No description provided for @matchCancelError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cancelar el partido: {error}'**
  String matchCancelError(String error);

  /// No description provided for @viewJustificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver justificaciones'**
  String get viewJustificationsTooltip;

  /// No description provided for @viewJustificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Justificaciones de falta'**
  String get viewJustificationsTitle;

  /// No description provided for @viewJustificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ninguna justificación para esta sesión.'**
  String get viewJustificationsEmpty;

  /// No description provided for @viewJustificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar las justificaciones.'**
  String get viewJustificationsLoadError;

  /// No description provided for @justificationNoReasonGiven.
  ///
  /// In es, this message translates to:
  /// **'Sin motivo indicado'**
  String get justificationNoReasonGiven;

  /// No description provided for @matchResultFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Resultado del partido'**
  String get matchResultFormTitle;

  /// No description provided for @matchResultGoalsForLabel.
  ///
  /// In es, this message translates to:
  /// **'Goles a favor'**
  String get matchResultGoalsForLabel;

  /// No description provided for @matchResultGoalsAgainstLabel.
  ///
  /// In es, this message translates to:
  /// **'Goles en contra'**
  String get matchResultGoalsAgainstLabel;

  /// No description provided for @matchResultGoalsHelp.
  ///
  /// In es, this message translates to:
  /// **'Goles del Mutxamel – goles del rival'**
  String get matchResultGoalsHelp;

  /// No description provided for @matchResultOnlyScoreNote.
  ///
  /// In es, this message translates to:
  /// **'En este equipo solo se registra el resultado del partido'**
  String get matchResultOnlyScoreNote;

  /// No description provided for @matchResultPlayersTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas por jugador'**
  String get matchResultPlayersTitle;

  /// No description provided for @matchResultGoalsShort.
  ///
  /// In es, this message translates to:
  /// **'Goles'**
  String get matchResultGoalsShort;

  /// No description provided for @matchResultAssistsShort.
  ///
  /// In es, this message translates to:
  /// **'Asist.'**
  String get matchResultAssistsShort;

  /// No description provided for @matchResultYellowCardsShort.
  ///
  /// In es, this message translates to:
  /// **'T. amarillas'**
  String get matchResultYellowCardsShort;

  /// No description provided for @matchResultRedCardShort.
  ///
  /// In es, this message translates to:
  /// **'T. roja'**
  String get matchResultRedCardShort;

  /// No description provided for @matchResultSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar resultado'**
  String get matchResultSaveButton;

  /// No description provided for @matchResultSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Resultado guardado correctamente.'**
  String get matchResultSavedSuccess;

  /// No description provided for @matchResultSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el resultado: {error}'**
  String matchResultSaveError(String error);

  /// No description provided for @matchResultLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los datos del partido.'**
  String get matchResultLoadError;

  /// No description provided for @matchEnterResultTooltip.
  ///
  /// In es, this message translates to:
  /// **'Introducir resultado'**
  String get matchEnterResultTooltip;

  /// No description provided for @matchEditResultTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar resultado'**
  String get matchEditResultTooltip;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsSectionAccount;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Borra tu cuenta y tus datos personales'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán tu correo, tu contraseña, tus accesos al club, tus dispositivos y tus notificaciones. Las fichas del club (jugador, familiar o cuerpo técnico) se conservan, y los mensajes que enviaste se conservarán sin tu nombre. Esta acción no se puede deshacer.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña para confirmar'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get deleteAccountPasswordRequired;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es correcta.'**
  String get deleteAccountWrongPassword;

  /// No description provided for @deleteAccountTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos fallidos. Inténtalo de nuevo en unos minutos.'**
  String get deleteAccountTooManyAttempts;

  /// No description provided for @deleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido eliminar la cuenta. Inténtalo de nuevo.'**
  String get deleteAccountError;

  /// No description provided for @deleteAccountDone.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ha sido eliminada.'**
  String get deleteAccountDone;

  /// No description provided for @reportAction.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get reportAction;

  /// No description provided for @reportDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar mensaje'**
  String get reportDialogTitle;

  /// No description provided for @reportDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Se avisará al club para que revise este mensaje. Puedes indicar el motivo (opcional).'**
  String get reportDialogBody;

  /// No description provided for @reportReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get reportReasonHint;

  /// No description provided for @reportSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar reporte'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. El club lo revisará.'**
  String get reportSent;

  /// No description provided for @reportError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido enviar el reporte. Inténtalo de nuevo.'**
  String get reportError;

  /// No description provided for @matchAbsenceJustifyButton.
  ///
  /// In es, this message translates to:
  /// **'Justificar ausencia'**
  String get matchAbsenceJustifyButton;

  /// No description provided for @matchAbsenceJustifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Justificar ausencia al partido'**
  String get matchAbsenceJustifyTitle;

  /// No description provided for @matchAbsenceEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar motivo de la ausencia'**
  String get matchAbsenceEditTitle;

  /// No description provided for @matchAbsenceHint.
  ///
  /// In es, this message translates to:
  /// **'Avisa al cuerpo técnico de que el jugador no podrá jugar este partido. Puedes cambiar el motivo o retirarlo hasta la hora de convocatoria.'**
  String get matchAbsenceHint;

  /// No description provided for @matchAbsenceReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get matchAbsenceReasonLabel;

  /// No description provided for @matchAbsenceReasonRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo (mínimo 3 caracteres)'**
  String get matchAbsenceReasonRequired;

  /// No description provided for @matchAbsenceBadge.
  ///
  /// In es, this message translates to:
  /// **'Ausencia justificada'**
  String get matchAbsenceBadge;

  /// No description provided for @matchAbsenceEditButton.
  ///
  /// In es, this message translates to:
  /// **'Editar motivo'**
  String get matchAbsenceEditButton;

  /// No description provided for @matchAbsenceWithdrawButton.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get matchAbsenceWithdrawButton;

  /// No description provided for @matchAbsenceWithdrawTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Retirar la ausencia?'**
  String get matchAbsenceWithdrawTitle;

  /// No description provided for @matchAbsenceWithdrawBody.
  ///
  /// In es, this message translates to:
  /// **'El cuerpo técnico sabrá que el jugador ya puede jugar. El jugador podrá ser convocado de nuevo, pero no se añadirá a la convocatoria automáticamente.'**
  String get matchAbsenceWithdrawBody;

  /// No description provided for @matchAbsenceWithdrawConfirm.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get matchAbsenceWithdrawConfirm;

  /// No description provided for @matchAbsenceDeadlineClosed.
  ///
  /// In es, this message translates to:
  /// **'Plazo cerrado ({deadline})'**
  String matchAbsenceDeadlineClosed(String deadline);

  /// No description provided for @matchAbsenceJustifiedSnack.
  ///
  /// In es, this message translates to:
  /// **'Ausencia justificada'**
  String get matchAbsenceJustifiedSnack;

  /// No description provided for @matchAbsenceWithdrawnSnack.
  ///
  /// In es, this message translates to:
  /// **'Ausencia retirada'**
  String get matchAbsenceWithdrawnSnack;

  /// No description provided for @matchAbsenceError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar. Inténtalo de nuevo.'**
  String get matchAbsenceError;

  /// No description provided for @callupDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get callupDetailTitle;

  /// No description provided for @callupPlayersCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 convocado} other{{count} convocados}}'**
  String callupPlayersCount(int count);

  /// No description provided for @callupAbsentBanner.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 jugador convocado ha justificado su ausencia} other{{count} jugadores convocados han justificado su ausencia}}'**
  String callupAbsentBanner(int count);

  /// No description provided for @callupAbsentCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 ausencia justificada} other{{count} ausencias justificadas}}'**
  String callupAbsentCount(int count);

  /// No description provided for @seasonMatchAbsencesLine.
  ///
  /// In es, this message translates to:
  /// **'Partidos con ausencia justificada: {count}'**
  String seasonMatchAbsencesLine(int count);

  /// No description provided for @callupUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Esta convocatoria ya no está disponible'**
  String get callupUnavailable;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido conectar. Comprueba tu conexión e inténtalo de nuevo.'**
  String get connectionError;

  /// No description provided for @teamCardsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas'**
  String get teamCardsTitle;

  /// No description provided for @teamCardsDesc.
  ///
  /// In es, this message translates to:
  /// **'Amarillas y rojas de los jugadores y posibles sanciones'**
  String get teamCardsDesc;

  /// No description provided for @cardsNoPlayers.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores en este equipo'**
  String get cardsNoPlayers;

  /// No description provided for @cardsStatusOneAway.
  ///
  /// In es, this message translates to:
  /// **'A una de sanción'**
  String get cardsStatusOneAway;

  /// No description provided for @cardsStatusSanction.
  ///
  /// In es, this message translates to:
  /// **'Posible sanción'**
  String get cardsStatusSanction;

  /// No description provided for @cardsFooterNote.
  ///
  /// In es, this message translates to:
  /// **'Orientativo: la sanción la determina la FFCV.'**
  String get cardsFooterNote;

  /// No description provided for @yellowCardsLabel.
  ///
  /// In es, this message translates to:
  /// **'Amarillas'**
  String get yellowCardsLabel;

  /// No description provided for @redCardsLabel.
  ///
  /// In es, this message translates to:
  /// **'Rojas'**
  String get redCardsLabel;

  /// No description provided for @teamStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get teamStatsTitle;

  /// No description provided for @teamStatsDesc.
  ///
  /// In es, this message translates to:
  /// **'Goleadores, asistentes, asistencia y resultados'**
  String get teamStatsDesc;

  /// No description provided for @statsPlayedShort.
  ///
  /// In es, this message translates to:
  /// **'PJ'**
  String get statsPlayedShort;

  /// No description provided for @statsWonShort.
  ///
  /// In es, this message translates to:
  /// **'G'**
  String get statsWonShort;

  /// No description provided for @statsDrawnShort.
  ///
  /// In es, this message translates to:
  /// **'E'**
  String get statsDrawnShort;

  /// No description provided for @statsLostShort.
  ///
  /// In es, this message translates to:
  /// **'P'**
  String get statsLostShort;

  /// No description provided for @statsGoalsForShort.
  ///
  /// In es, this message translates to:
  /// **'GF'**
  String get statsGoalsForShort;

  /// No description provided for @statsGoalsAgainstShort.
  ///
  /// In es, this message translates to:
  /// **'GC'**
  String get statsGoalsAgainstShort;

  /// No description provided for @statsAttendanceAverage.
  ///
  /// In es, this message translates to:
  /// **'Asistencia media'**
  String get statsAttendanceAverage;

  /// No description provided for @statsTopScorers.
  ///
  /// In es, this message translates to:
  /// **'Goleadores'**
  String get statsTopScorers;

  /// No description provided for @statsTopAssisters.
  ///
  /// In es, this message translates to:
  /// **'Asistentes'**
  String get statsTopAssisters;

  /// No description provided for @statsTrainingAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia a entrenamientos'**
  String get statsTrainingAttendance;

  /// No description provided for @statsNoData.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay datos'**
  String get statsNoData;

  /// No description provided for @statsGoalsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} gol} other{{count} goles}}'**
  String statsGoalsCount(int count);

  /// No description provided for @statsAssistsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} asistencia} other{{count} asistencias}}'**
  String statsAssistsCount(int count);

  /// No description provided for @statsAttendedOf.
  ///
  /// In es, this message translates to:
  /// **'{asistidos} de {total}'**
  String statsAttendedOf(int asistidos, int total);

  /// No description provided for @statsPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent} %'**
  String statsPercent(int percent);

  /// No description provided for @trainingListNotReviewed.
  ///
  /// In es, this message translates to:
  /// **'Lista sin revisar'**
  String get trainingListNotReviewed;

  /// No description provided for @trainingNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este entrenamiento ya no está disponible'**
  String get trainingNotFound;

  /// No description provided for @clubPageWeekend.
  ///
  /// In es, this message translates to:
  /// **'Fin de semana'**
  String get clubPageWeekend;

  /// No description provided for @clubPageWeekendDesc.
  ///
  /// In es, this message translates to:
  /// **'Convocatorias, resultados y jornadas por revisar'**
  String get clubPageWeekendDesc;

  /// No description provided for @clubPagePlayerTracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de jugadores'**
  String get clubPagePlayerTracking;

  /// No description provided for @clubPagePlayerTrackingDesc.
  ///
  /// In es, this message translates to:
  /// **'Faltas y mal comportamiento en entrenamientos'**
  String get clubPagePlayerTrackingDesc;

  /// No description provided for @weekendPrevious.
  ///
  /// In es, this message translates to:
  /// **'Fin de semana anterior'**
  String get weekendPrevious;

  /// No description provided for @weekendNext.
  ///
  /// In es, this message translates to:
  /// **'Fin de semana siguiente'**
  String get weekendNext;

  /// No description provided for @weekendNoCallup.
  ///
  /// In es, this message translates to:
  /// **'Sin convocatoria'**
  String get weekendNoCallup;

  /// No description provided for @weekendPendingResults.
  ///
  /// In es, this message translates to:
  /// **'Resultados pendientes'**
  String get weekendPendingResults;

  /// No description provided for @weekendResting.
  ///
  /// In es, this message translates to:
  /// **'Descansan'**
  String get weekendResting;

  /// No description provided for @weekendNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Sin partido ni descanso'**
  String get weekendNoMatch;

  /// No description provided for @weekendNoMatchNote.
  ///
  /// In es, this message translates to:
  /// **'¿Falta importar la jornada?'**
  String get weekendNoMatchNote;

  /// No description provided for @weekendAllClear.
  ///
  /// In es, this message translates to:
  /// **'Todo al día'**
  String get weekendAllClear;

  /// No description provided for @weekendLastImport.
  ///
  /// In es, this message translates to:
  /// **'Última importación FFCV: {fecha}'**
  String weekendLastImport(String fecha);

  /// No description provided for @weekendDelayDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Hoy} one{Hace {count} día} other{Hace {count} días}}'**
  String weekendDelayDays(int count);

  /// No description provided for @weekendRound.
  ///
  /// In es, this message translates to:
  /// **'Jornada {jornada}'**
  String weekendRound(int jornada);

  /// No description provided for @trackingPeriodDays.
  ///
  /// In es, this message translates to:
  /// **'Últimos {count} días'**
  String trackingPeriodDays(int count);

  /// No description provided for @trackingExcusedChip.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} justificada} other{{count} justificadas}}'**
  String trackingExcusedChip(int count);

  /// No description provided for @trackingLateChip.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} retraso} other{{count} retrasos}}'**
  String trackingLateChip(int count);

  /// No description provided for @noPermission.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso'**
  String get noPermission;

  /// No description provided for @callupMatchUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este partido ya no admite convocatoria'**
  String get callupMatchUnavailable;

  /// No description provided for @statsUnreviewedNote.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} entrenamiento sin lista revisada no cuenta en la asistencia} other{{count} entrenamientos sin lista revisada no cuentan en la asistencia}}'**
  String statsUnreviewedNote(int count);

  /// No description provided for @trackingPeriodSeason.
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get trackingPeriodSeason;

  /// No description provided for @trackingAllTeams.
  ///
  /// In es, this message translates to:
  /// **'Todos los equipos'**
  String get trackingAllTeams;

  /// No description provided for @trackingFaultsChip.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} falta} other{{count} faltas}}'**
  String trackingFaultsChip(int count);

  /// No description provided for @trackingMisconductChip.
  ///
  /// In es, this message translates to:
  /// **'{count} mal comportamiento'**
  String trackingMisconductChip(int count);

  /// No description provided for @trackingLastIncident.
  ///
  /// In es, this message translates to:
  /// **'Última incidencia: {fecha}'**
  String trackingLastIncident(String fecha);

  /// No description provided for @trackingEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún jugador llega a los umbrales en este periodo'**
  String get trackingEmpty;

  /// No description provided for @trackingCoordinationOnly.
  ///
  /// In es, this message translates to:
  /// **'Datos solo para coordinación'**
  String get trackingCoordinationOnly;

  /// No description provided for @trackingNoIncidents.
  ///
  /// In es, this message translates to:
  /// **'Sin incidencias en este periodo'**
  String get trackingNoIncidents;

  /// No description provided for @clubPageModeration.
  ///
  /// In es, this message translates to:
  /// **'Moderación'**
  String get clubPageModeration;

  /// No description provided for @clubPageModerationDesc.
  ///
  /// In es, this message translates to:
  /// **'Mensajes reportados por los usuarios'**
  String get clubPageModerationDesc;

  /// No description provided for @clubPagePendingAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas pendientes'**
  String get clubPagePendingAccounts;

  /// No description provided for @clubPagePendingAccountsDesc.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones que todavía no se han activado'**
  String get clubPagePendingAccountsDesc;

  /// No description provided for @moderationTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get moderationTabPending;

  /// No description provided for @moderationTabResolved.
  ///
  /// In es, this message translates to:
  /// **'Resueltos'**
  String get moderationTabResolved;

  /// No description provided for @moderationEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No hay reportes pendientes'**
  String get moderationEmptyPending;

  /// No description provided for @moderationEmptyResolved.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay reportes resueltos'**
  String get moderationEmptyResolved;

  /// No description provided for @moderationAuthor.
  ///
  /// In es, this message translates to:
  /// **'Autor: {nombre}'**
  String moderationAuthor(String nombre);

  /// No description provided for @moderationReporter.
  ///
  /// In es, this message translates to:
  /// **'Reportado por: {nombre}'**
  String moderationReporter(String nombre);

  /// No description provided for @moderationReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {motivo}'**
  String moderationReason(String motivo);

  /// No description provided for @moderationNoReason.
  ///
  /// In es, this message translates to:
  /// **'sin motivo indicado'**
  String get moderationNoReason;

  /// No description provided for @moderationMessageDate.
  ///
  /// In es, this message translates to:
  /// **'Mensaje: {fecha}'**
  String moderationMessageDate(String fecha);

  /// No description provided for @moderationReportDate.
  ///
  /// In es, this message translates to:
  /// **'Reportado: {fecha}'**
  String moderationReportDate(String fecha);

  /// No description provided for @moderationAuthorReports.
  ///
  /// In es, this message translates to:
  /// **'El autor tiene {count} reportes'**
  String moderationAuthorReports(int count);

  /// No description provided for @moderationShowMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get moderationShowMore;

  /// No description provided for @moderationShowLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get moderationShowLess;

  /// No description provided for @moderationDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get moderationDiscard;

  /// No description provided for @moderationDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Borrar mensaje'**
  String get moderationDeleteMessage;

  /// No description provided for @moderationDeactivateAuthor.
  ///
  /// In es, this message translates to:
  /// **'Desactivar autor'**
  String get moderationDeactivateAuthor;

  /// No description provided for @moderationNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get moderationNoteLabel;

  /// No description provided for @moderationDiscardConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar este reporte? El mensaje se queda como está.'**
  String get moderationDiscardConfirm;

  /// No description provided for @moderationDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar el mensaje para todos los usuarios?'**
  String get moderationDeleteConfirm;

  /// No description provided for @moderationDeactivateConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar la cuenta del autor? Dejará de poder entrar en la app.'**
  String get moderationDeactivateConfirm;

  /// No description provided for @moderationAlsoDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Borrar también el mensaje'**
  String get moderationAlsoDeleteMessage;

  /// No description provided for @moderationConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get moderationConfirm;

  /// No description provided for @moderationResolvedDone.
  ///
  /// In es, this message translates to:
  /// **'Reporte resuelto'**
  String get moderationResolvedDone;

  /// No description provided for @moderationStateDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get moderationStateDiscarded;

  /// No description provided for @moderationStateMessageDeleted.
  ///
  /// In es, this message translates to:
  /// **'Mensaje borrado'**
  String get moderationStateMessageDeleted;

  /// No description provided for @moderationStateAuthorDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Autor desactivado'**
  String get moderationStateAuthorDeactivated;

  /// No description provided for @moderationResolvedBy.
  ///
  /// In es, this message translates to:
  /// **'Resuelto por {nombre} el {fecha}'**
  String moderationResolvedBy(String nombre, String fecha);

  /// No description provided for @pendingAccountsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay cuentas pendientes'**
  String get pendingAccountsEmpty;

  /// No description provided for @pendingAccountsSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o email'**
  String get pendingAccountsSearch;

  /// No description provided for @pendingAccountsInvited.
  ///
  /// In es, this message translates to:
  /// **'Invitado el {fecha}'**
  String pendingAccountsInvited(String fecha);

  /// No description provided for @pendingAccountsCodeExpired.
  ///
  /// In es, this message translates to:
  /// **'Código caducado'**
  String get pendingAccountsCodeExpired;

  /// No description provided for @pendingAccountsResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar activación'**
  String get pendingAccountsResend;

  /// No description provided for @pendingAccountsResendConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Reenviar la invitación de activación a {email}?'**
  String pendingAccountsResendConfirm(String email);

  /// No description provided for @pendingAccountsResent.
  ///
  /// In es, this message translates to:
  /// **'Invitación reenviada a {email}'**
  String pendingAccountsResent(String email);
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
      <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

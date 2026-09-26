import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
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

  /// No description provided for @homeMatchUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No hay información disponible sobre el próximo partido.'**
  String get homeMatchUnavailable;

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

  /// No description provided for @settingsAboutApp.
  ///
  /// In es, this message translates to:
  /// **'Acerca de appMTX'**
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
  /// **'Cada botón manda un aviso en directo a todos los usuarios de la app. Revisa bien antes de pulsar: no se puede deshacer.'**
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

  /// No description provided for @liveGoalAuthorLabel.
  ///
  /// In es, this message translates to:
  /// **'Autor del gol'**
  String get liveGoalAuthorLabel;

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

  /// No description provided for @noTrainingsYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay entrenamientos.'**
  String get noTrainingsYet;

  /// No description provided for @createFirstTrainingHint.
  ///
  /// In es, this message translates to:
  /// **'Crea el primero pulsando el botón Nuevo.'**
  String get createFirstTrainingHint;

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

  /// No description provided for @callupPlayersTitle.
  ///
  /// In es, this message translates to:
  /// **'Jugadores convocados'**
  String get callupPlayersTitle;

  /// No description provided for @notModifiable.
  ///
  /// In es, this message translates to:
  /// **'No modificables'**
  String get notModifiable;

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

  /// No description provided for @enterRivalError.
  ///
  /// In es, this message translates to:
  /// **'Introduce el rival.'**
  String get enterRivalError;

  /// No description provided for @enterFieldError.
  ///
  /// In es, this message translates to:
  /// **'Introduce el campo.'**
  String get enterFieldError;

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
      <String>['ca', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
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

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

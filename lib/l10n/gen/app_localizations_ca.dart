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

  @override
  String get loginHeading => 'Accés a l\'Àrea Club';

  @override
  String get loginSubtitle => 'Introdueix les teues dades per a accedir';

  @override
  String get loginEmailRequired => 'Introdueix el teu correu electrònic';

  @override
  String get loginEmailInvalid => 'Introdueix un correu electrònic vàlid';

  @override
  String get loginPasswordLabel => 'Contrasenya';

  @override
  String get loginPasswordRequired => 'Introdueix la teua contrasenya';

  @override
  String get loginButton => 'Inicia sessió';

  @override
  String get activateAccountButton => 'Activa el compte';

  @override
  String get clubPageDefaultMember => 'Membre del club';

  @override
  String get clubPageSectionClub => 'Club';

  @override
  String get clubPageMyPlayers => 'Els meus jugadors';

  @override
  String get clubPageMyPlayersDesc => 'Jugadors vinculats al teu compte';

  @override
  String get clubPageFees => 'Quotes';

  @override
  String get clubPageFeesDesc => 'Quotes dels teus jugadors i el seu estat';

  @override
  String get clubPageMyTeams => 'Els meus equips';

  @override
  String get clubPageMyTeamsDesc =>
      'Equips vinculats a la teua activitat al club';

  @override
  String get clubPageMyMatches => 'Els meus partits';

  @override
  String get clubPageMyMatchesDesc => 'Pròxims partits i resultats';

  @override
  String get clubPageLiveMatch => 'Partit en directe';

  @override
  String get clubPageLiveMatchDesc => 'Avisos en directe del primer equip';

  @override
  String get clubPageCommunications => 'Comunicacions';

  @override
  String get clubPageCommunicationsDesc => 'Avisos i comunicacions del club';

  @override
  String get clubPageSectionAccount => 'El meu compte';

  @override
  String get clubPageMyProfile => 'El meu perfil';

  @override
  String get clubPageMyProfileDesc =>
      'Les teues dades personals i configuració';

  @override
  String get clubPageLogout => 'Tanca la sessió';

  @override
  String aboutVersionText(String version) {
    return 'Versió $version';
  }

  @override
  String aboutVersionTextWithBuild(String version, String build) {
    return 'Versió $version ($build)';
  }

  @override
  String get aboutSectionClub => 'El club';

  @override
  String get aboutClubDescription =>
      'L\'aplicació oficial del Mutxamel Club de Futbol et manté al dia de convocatòries, entrenaments, resultats i comunicacions del club, estigues on estigues.';

  @override
  String get aboutSectionContact => 'Contacte';

  @override
  String get aboutSectionLegal => 'Legal';

  @override
  String get aboutPrivacyPolicy => 'Política de privacitat';

  @override
  String get aboutPrivacyPolicySubtitle => 'Com tractem les teues dades';

  @override
  String get aboutThirdPartyLicenses => 'Llicències de tercers';

  @override
  String get aboutThirdPartyLicensesSubtitle =>
      'Programari lliure utilitzat en l\'aplicació';

  @override
  String get aboutAppTagline => 'Aplicació oficial del Mutxamel Club de Futbol';

  @override
  String get mailAppOpenError => 'No es pot obrir l\'aplicació de correu';

  @override
  String get profileLoadError => 'No s\'ha pogut carregar el perfil.';

  @override
  String get defaultUser => 'Usuari';

  @override
  String get profileSectionMyData => 'Les meues dades';

  @override
  String get profileSectionSettings => 'Configuració';

  @override
  String get profileSettingsSubtitle => 'Notificacions, aparença i aplicació';

  @override
  String get profileRole => 'Rol';

  @override
  String get roleFamiliar => 'Familiar';

  @override
  String get roleJugador => 'Jugador';

  @override
  String get roleEntrenador => 'Entrenador';

  @override
  String get roleCoordinador => 'Coordinador';

  @override
  String get roleRetransmision => 'Retransmissió';

  @override
  String get roleAdministrador => 'Administrador';

  @override
  String get roleSocio => 'Soci';

  @override
  String get noPlayersLinked => 'No tens jugadors vinculats al teu compte.';

  @override
  String playersLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadors vinculats',
      one: '$count jugador vinculat',
    );
    return '$_temp0';
  }

  @override
  String get fieldTeam => 'Equip';

  @override
  String get fieldSport => 'Esport';

  @override
  String get sportFootball => 'Futbol';

  @override
  String get fieldDorsal => 'Dorsal';

  @override
  String get fieldPosition => 'Posició';

  @override
  String get allTeamsTitle => 'Tots els equips';

  @override
  String get noTeamsAvailable => 'No hi ha equips disponibles.';

  @override
  String get noTeamsAssociated => 'No tens equips associats.';

  @override
  String get playerCountLabel => 'Nombre de jugadors';

  @override
  String get teamsLoadError => 'No s\'han pogut carregar els equips.';

  @override
  String get markAllReadTooltip => 'Marca-les totes com a llegides';

  @override
  String get notificationsLoadError =>
      'No s\'han pogut carregar les notificacions.';

  @override
  String get noNotifications => 'No tens notificacions.';

  @override
  String get markAllReadError =>
      'No s\'han pogut marcar les notificacions com a llegides.';

  @override
  String todayAt(String time) {
    return 'Hui, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Ahir, $time';
  }

  @override
  String get noFeesRegistered =>
      'No hi ha quotes registrades per als teus jugadors.';

  @override
  String playersCountSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadors',
      one: '$count jugador',
    );
    return '$_temp0';
  }

  @override
  String feesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quotes',
      one: '$count quota',
    );
    return '$_temp0';
  }

  @override
  String get feesAllPaidSuffix => ' · totes pagades';

  @override
  String feesPendingSuffix(int pending) {
    return ' · $pending per pagar';
  }

  @override
  String get noPaymentRegistered =>
      'Esta quota encara no té cap pagament registrat.';

  @override
  String get close => 'Tanca';

  @override
  String get noDateRegistered => 'Sense data registrada';

  @override
  String get methodNotIndicated => 'Mètode no indicat';

  @override
  String get feeStatusOverdue => 'Vençuda';

  @override
  String get feeStatusPaid => 'Pagada';

  @override
  String get feeStatusPartial => 'Pagament parcial';

  @override
  String get feeStatusPending => 'Pendent';

  @override
  String get chatDefaultTitle => 'Xat';

  @override
  String get chatNoMessages => 'Encara no hi ha missatges. Escriu el primer.';

  @override
  String get chatMessageHint => 'Escriu un missatge...';

  @override
  String get tabConversations => 'Converses';

  @override
  String get tabReceived => 'Rebudes';

  @override
  String get tabSent => 'Enviades';

  @override
  String get newButton => 'Nova';

  @override
  String get noConversations => 'No tens converses';

  @override
  String get noConversationsSubtitle =>
      'Ací apareixeran els teus xats privats.';

  @override
  String get noCommunicationsReceived => 'No tens comunicacions';

  @override
  String get noCommunicationsReceivedSubtitleGlobal =>
      'Ací apareixeran les comunicacions del club.';

  @override
  String get noCommunicationsReceivedSubtitleTeam =>
      'Ací apareixeran les comunicacions dels teus equips.';

  @override
  String get noCommunicationsSent => 'No has enviat comunicacions';

  @override
  String get noCommunicationsSentSubtitle =>
      'Ací apareixeran les comunicacions que hages enviat.';

  @override
  String get splashTagline => 'L\'app oficial del club';

  @override
  String get activateHeading => 'Activa el teu compte';

  @override
  String get activateSubtitle =>
      'Introdueix el teu correu electrònic i el codi de 6 dígits que t\'ha enviat el club per correu, i tria la teua contrasenya d\'accés.';

  @override
  String get codeLabel => 'Codi de 6 dígits';

  @override
  String get codeRequired => 'Introdueix el codi que t\'hem enviat per correu';

  @override
  String get codeLength => 'El codi ha de tindre 6 dígits';

  @override
  String get newPasswordLabel => 'Contrasenya nova';

  @override
  String get passwordChooseRequired => 'Tria una contrasenya';

  @override
  String get passwordMinLength => 'Ha de tindre almenys 8 caràcters';

  @override
  String get repeatPasswordLabel => 'Repeteix la contrasenya';

  @override
  String get passwordsDontMatch => 'Les contrasenyes no coincideixen';

  @override
  String get activateAndEnterButton => 'Activa i entra';

  @override
  String get commDetailTitle => 'Comunicació';

  @override
  String get commLoadError => 'No s\'ha pogut carregar la comunicació.';

  @override
  String get commNewTitle => 'Nova comunicació';

  @override
  String get commSelectRecipientError => 'Selecciona a qui vols escriure.';

  @override
  String get commSelectTeamError => 'Selecciona almenys un equip.';

  @override
  String get commSelectCategoryError => 'Selecciona almenys una categoria.';

  @override
  String get commSelectRecipientPersonError => 'Selecciona un destinatari.';

  @override
  String get commCreatedSuccess => 'Comunicació creada correctament.';

  @override
  String commCreateError(String error) {
    return 'No s\'ha pogut crear la comunicació: $error';
  }

  @override
  String get titleLabel => 'Títol';

  @override
  String get titleHint => 'Escriu el títol';

  @override
  String get titleRequired => 'El títol és obligatori.';

  @override
  String get messageLabel => 'Missatge';

  @override
  String get messageHint => 'Escriu el contingut de la comunicació';

  @override
  String get messageRequired => 'El missatge és obligatori.';

  @override
  String get recipientsTitle => 'Destinataris';

  @override
  String get teamsSegment => 'Equips';

  @override
  String get categoriesSegment => 'Categories';

  @override
  String get privateSegment => 'Privat';

  @override
  String get noRecipientsAvailable =>
      'No tens cap destinatari disponible per a escriure una comunicació.';

  @override
  String get chooseTeamsHint => 'Tria un o diversos equips.';

  @override
  String get chooseCategoriesHint => 'Tria una o diverses categories.';

  @override
  String get choosePrivateRecipientHint =>
      'Tria una única persona; el missatge serà privat només per a ella.';

  @override
  String get searchRecipientLabel => 'Cercar destinatari';

  @override
  String get searchRecipientHint => 'Nom o cognoms';

  @override
  String get noRecipientsFound => 'No s\'han trobat destinataris.';

  @override
  String get savingButton => 'Guardant...';

  @override
  String get saveCommunicationButton => 'Guardar comunicació';

  @override
  String get recipientsLoadError =>
      'No s\'han pogut carregar els destinataris.';

  @override
  String get liveMatchTitle => 'Partit en directe';

  @override
  String get liveMatchWarning =>
      'Cada botó envia un avís en directe a tots els usuaris de l\'app. Revisa-ho bé abans de prémer: no es pot desfer.';

  @override
  String get liveEventKickoff => 'Inici de partit';

  @override
  String get liveConfirmKickoff => 'Avisar que comença el partit?';

  @override
  String get liveEventGoalAgainst => 'Gol en contra';

  @override
  String get liveConfirmGoalAgainst => 'Avisar d\'un gol en contra?';

  @override
  String get liveEventHalftime => 'Descans';

  @override
  String get liveConfirmHalftime => 'Avisar del descans?';

  @override
  String get liveEventSecondHalf => 'Segona part';

  @override
  String get liveConfirmSecondHalf => 'Avisar de l\'inici de la segona part?';

  @override
  String get liveEventFulltime => 'Final de partit';

  @override
  String get liveConfirmFulltime => 'Avisar que ha finalitzat el partit?';

  @override
  String get liveLineupButton => 'Alineació';

  @override
  String get liveGoalForButton => 'Gol a favor';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get send => 'Envia';

  @override
  String get liveStartingLineupLabel => 'Onze inicial';

  @override
  String get liveSubstitutesLabel => 'Suplents';

  @override
  String get liveFillLineupError => 'Omple l\'onze inicial i els suplents.';

  @override
  String get liveLineupSentMessage => 'Alineació enviada.';

  @override
  String get liveGoalAuthorLabel => 'Autor del gol';

  @override
  String get liveEnterGoalAuthorError => 'Escriu l\'autor del gol.';

  @override
  String get liveGoalSentMessage => 'Gol enviat.';

  @override
  String liveNotificationSentMessage(String titulo) {
    return 'Avís de \"$titulo\" enviat.';
  }

  @override
  String liveSendError(String error) {
    return 'No s\'ha pogut enviar l\'avís: $error';
  }
}

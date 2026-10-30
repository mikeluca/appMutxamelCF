// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navNews => 'Noticias';

  @override
  String get navMatches => 'Partidos';

  @override
  String get navStore => 'Tienda';

  @override
  String get navClub => 'Club';

  @override
  String get retry => 'Reintentar';

  @override
  String get linkOpenError => 'No se ha podido abrir el enlace';

  @override
  String get homeNotificationsTooltip => 'Notificaciones';

  @override
  String get homeAreaClub => 'Área Club';

  @override
  String get homeLatestNews => 'Últimas noticias';

  @override
  String get homeOurSponsors => 'Nuestros patrocinadores';

  @override
  String get homeSponsorsHint =>
      'Pulsa en las imágenes para conocer más acerca de nuestros patrocinadores.';

  @override
  String get homeNewsLoadError => 'No se han podido cargar las noticias.';

  @override
  String get homeNoNewsAvailable => 'No hay noticias disponibles.';

  @override
  String get homeMatchLoadError => 'No se ha podido cargar el partido.';

  @override
  String get matchUpcoming => 'PRÓXIMO PARTIDO';

  @override
  String get matchUpcomingFirstTeam => 'PRÓXIMO PARTIDO PRIMER EQUIPO';

  @override
  String get matchLastResult => 'ÚLTIMO RESULTADO';

  @override
  String get matchLastResultFirstTeam => 'ÚLTIMO RESULTADO PRIMER EQUIPO';

  @override
  String get matchVs => 'VS';

  @override
  String get matchNoMatch => 'SIN PARTIDO';

  @override
  String get matchNoMatchFirstTeam => 'SIN PARTIDO PRIMER EQUIPO';

  @override
  String get matchNoMatchThisRound => 'No hay partido esta jornada';

  @override
  String get matchTeamHasNoMatch => 'No tiene partido';

  @override
  String get matchTeamRests => 'Descansa';

  @override
  String get matchesCalendarTitle => 'CALENDARIO';

  @override
  String get matchesCalendarSubtitle =>
      'Partidos y resultados de nuestros equipos';

  @override
  String get matchesNoMatchesAvailable => 'No hay partidos disponibles.';

  @override
  String get matchesLoadError => 'No se han podido cargar los partidos.';

  @override
  String get matchesNoCategory => 'Sin categoría';

  @override
  String get matchesResult => 'RESULTADO';

  @override
  String get matchesRestsThisRound => 'Descansa esta jornada';

  @override
  String get newsTitle => 'Noticias';

  @override
  String get newsDetailTitle => 'Noticia';

  @override
  String get newsLoadMore => 'Cargar más noticias';

  @override
  String get newsLoadMoreError => 'No se han podido cargar más noticias.';

  @override
  String get storeTitle => 'Tienda';

  @override
  String get storeHeroKicker => 'MUTXAMEL CF';

  @override
  String get storeHeroTitle => 'Viste los colores';

  @override
  String get storeHeroSubtitle =>
      'La nueva colección del club ya está aquí. Elige tu prenda, selecciona tus tallas y haznos llegar tu pedido.';

  @override
  String get storeProductShirtTitle => 'Camiseta oficial';

  @override
  String get storeProductShirtDescription =>
      'La esencia del Mutxamel CF, un año más, vestida de azul. Nuestra primera equipación combina la tradición y la identidad del club con un diseño moderno.';

  @override
  String get storeProductSecondKitTitle => 'Segunda equipación';

  @override
  String get storeProductSecondKitDescription =>
      'Mucho más que una camiseta. Nuestra segunda equipación, de color rosa, nace de una colaboración muy especial con la Asociación Española Contra el Cáncer, uniendo deporte, compromiso y solidaridad.';

  @override
  String get storeProductSecondKitNote =>
      'Colaboración con la Asociación Española Contra el Cáncer';

  @override
  String get storeUnits => 'Unidades';

  @override
  String storeSizeUnitLabel(int n) {
    return 'Talla unidad $n';
  }

  @override
  String get storeSizeGuideTitle => 'Guía de tallas';

  @override
  String get storeSizeGuideHint =>
      'Mide una prenda que te quede bien y compara con estas medidas aproximadas.';

  @override
  String get storeSizeGuideSize => 'Talla';

  @override
  String get storeSizeGuideChest => 'Pecho (cm)';

  @override
  String get storeSizeGuideLength => 'Largo (cm)';

  @override
  String get storeCustomerDataTitle => 'Tus datos';

  @override
  String get storeCustomerDataHint =>
      'Te escribiremos para confirmar disponibilidad y forma de pago.';

  @override
  String get storeFullNameLabel => 'Nombre y apellidos';

  @override
  String get storePhoneLabel => 'Teléfono (opcional)';

  @override
  String get storeEmailLabel => 'Email';

  @override
  String get storePrivacyAcceptPrefix =>
      'Acepto el tratamiento de mis datos según la ';

  @override
  String get storePrivacyPolicyLink => 'política de privacidad';

  @override
  String get storeCreateOrderButton => 'CREAR PEDIDO';

  @override
  String get storeSendingButton => 'Enviando...';

  @override
  String get storeErrorEnterName => 'Introduce tu nombre y apellidos.';

  @override
  String get storeErrorInvalidEmail => 'Introduce un email válido.';

  @override
  String get storeErrorAcceptPrivacy =>
      'Debes aceptar la política de privacidad.';

  @override
  String storeErrorSelectSizeForProduct(String producto) {
    return 'Selecciona la talla de cada unidad de \"$producto\".';
  }

  @override
  String get storeErrorSelectAtLeastOne =>
      'Selecciona al menos una prenda y sus unidades.';

  @override
  String get storeOrderSentMessage =>
      'Pedido enviado. Nos pondremos en contacto contigo para confirmar el pago y la recogida/envío.';

  @override
  String get clubTitle => 'Club';

  @override
  String get clubFullName => 'Mutxamel Club de Fútbol';

  @override
  String get clubTagline => 'Dónde estamos y cómo contactar con el club';

  @override
  String get clubSettingsTooltip => 'Ajustes';

  @override
  String get clubWhereWeAre => 'Dónde estamos';

  @override
  String get clubAddress => 'Dirección';

  @override
  String get clubWebsite => 'Página web';

  @override
  String get clubPhone => 'Teléfono';

  @override
  String get clubEmail => 'Email';

  @override
  String get clubFollowUs => 'Síguenos';

  @override
  String get clubViewOnGoogleMaps => 'Ver en Google Maps';

  @override
  String clubCopyright(int year) {
    return '© $year Mutxamel Club de Fútbol';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsSectionApplication => 'Aplicación';

  @override
  String get settingsNotifAnonymousHint =>
      'Actívalas aunque no tengas una cuenta en el club.';

  @override
  String get settingsNotifNewsAnon => 'Noticias';

  @override
  String get settingsNotifNewsAnonSubtitle =>
      'Recibir avisos de nuevas noticias';

  @override
  String get settingsNotifResultsFirstTeam =>
      'Resultados en directo del primer equipo';

  @override
  String get settingsNotifResultsFirstTeamSubtitle =>
      'Avisos de goles y resultados en directo';

  @override
  String get settingsPreferencesLoadError =>
      'No se han podido cargar las preferencias';

  @override
  String get settingsPreferenceSaveError =>
      'No se ha podido guardar la preferencia';

  @override
  String get settingsNotifGeneral => 'Notificaciones';

  @override
  String get settingsNotifGeneralSubtitleOn =>
      'Recibir notificaciones del club';

  @override
  String get settingsNotifGeneralSubtitleOff => 'No recibir notificaciones';

  @override
  String get settingsNotifNews => 'Noticias';

  @override
  String get settingsNotifNewsSubtitle =>
      'Recibir avisos sobre nuevas noticias';

  @override
  String get settingsNotifMessages => 'Mensajes';

  @override
  String get settingsNotifMessagesSubtitle =>
      'Recibir avisos de nuevos mensajes';

  @override
  String get settingsNotifResults => 'Resultados';

  @override
  String get settingsNotifResultsSubtitle => 'Recibir avisos sobre resultados';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAppearanceSubtitle =>
      'Elige cómo quieres ver la aplicación';

  @override
  String get settingsThemeAuto => 'Automático';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige el idioma de la aplicación';

  @override
  String get settingsLanguageSpanish => 'Castellano';

  @override
  String get settingsLanguageValencian => 'Valencià';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get settingsAboutApp => 'Acerca de Mutxamel CF';

  @override
  String get settingsAboutAppSubtitle => 'Información de la aplicación';

  @override
  String get loginHeading => 'Acceso al Área Club';

  @override
  String get loginSubtitle => 'Introduce tus datos para acceder';

  @override
  String get loginEmailRequired => 'Introduce tu email';

  @override
  String get loginEmailInvalid => 'Introduce un email válido';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginPasswordRequired => 'Introduce tu contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get activateAccountButton => 'Activar cuenta';

  @override
  String get clubPageDefaultMember => 'Miembro del club';

  @override
  String get clubPageSectionClub => 'Club';

  @override
  String get clubPageMyPlayers => 'Mis jugadores';

  @override
  String get clubPageMyPlayersDesc => 'Jugadores vinculados a tu cuenta';

  @override
  String get clubPageFees => 'Cuotas';

  @override
  String get clubPageFeesDesc => 'Cuotas de tus jugadores y su estado';

  @override
  String get clubPageFeesComingSoonDesc => 'Próximamente disponible';

  @override
  String get clubPageFeesComingSoonMessage =>
      'Estamos trabajando en esta funcionalidad. Estará operativa próximamente.';

  @override
  String get clubPageMyTeams => 'Mis equipos';

  @override
  String get clubPageMyTeamsDesc =>
      'Equipos vinculados a tu actividad en el club';

  @override
  String get clubPageMyMatches => 'Mis partidos';

  @override
  String get clubPageMyMatchesDesc => 'Próximos partidos y resultados';

  @override
  String get clubPageCalendar => 'Calendario';

  @override
  String get clubPageCalendarDesc => 'Entrenamientos y partidos de tus equipos';

  @override
  String get clubPageLiveMatch => 'Partido en directo';

  @override
  String get clubPageLiveMatchDesc => 'Avisos en directo del primer equipo';

  @override
  String get clubPageCommunications => 'Comunicaciones';

  @override
  String get clubPageCommunicationsDesc => 'Avisos y comunicaciones del club';

  @override
  String get clubPageSectionAccount => 'Mi cuenta';

  @override
  String get clubSectionPlayer => 'Jugador';

  @override
  String get clubSectionFamily => 'Familia';

  @override
  String get clubSectionCoach => 'Entrenador';

  @override
  String get clubSectionCoordination => 'Coordinación';

  @override
  String get clubSectionAdministration => 'Administración';

  @override
  String get clubSectionBroadcast => 'Retransmisión';

  @override
  String get clubPageMyProfile => 'Mi perfil';

  @override
  String get clubPageMyProfileDesc => 'Tus datos personales y configuración';

  @override
  String get clubPageLogout => 'Cerrar sesión';

  @override
  String aboutVersionText(String version) {
    return 'Versión $version';
  }

  @override
  String aboutVersionTextWithBuild(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get aboutSectionClub => 'El club';

  @override
  String get aboutClubDescription =>
      'La aplicación oficial del Mutxamel Club de Fútbol te mantiene al día de convocatorias, entrenamientos, resultados y comunicaciones del club, estés donde estés.';

  @override
  String get aboutSectionContact => 'Contacto';

  @override
  String get aboutSectionLegal => 'Legal';

  @override
  String get aboutPrivacyPolicy => 'Política de privacidad';

  @override
  String get aboutPrivacyPolicySubtitle => 'Cómo tratamos tus datos';

  @override
  String get aboutThirdPartyLicenses => 'Licencias de terceros';

  @override
  String get aboutThirdPartyLicensesSubtitle =>
      'Software libre utilizado en la aplicación';

  @override
  String get aboutAppTagline =>
      'Aplicación oficial del Mutxamel Club de Fútbol';

  @override
  String get mailAppOpenError => 'No se puede abrir la aplicación de correo';

  @override
  String get profileLoadError => 'No se ha podido cargar el perfil.';

  @override
  String get defaultUser => 'Usuario';

  @override
  String get profileSectionMyData => 'Mis datos';

  @override
  String get profileSectionSettings => 'Configuración';

  @override
  String get profileSettingsSubtitle =>
      'Notificaciones, apariencia y aplicación';

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
  String get roleRetransmision => 'Retransmisión';

  @override
  String get roleAdministrador => 'Administrador';

  @override
  String get roleSocio => 'Socio';

  @override
  String get noPlayersLinked => 'No tienes jugadores vinculados a tu cuenta.';

  @override
  String playersLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores vinculados',
      one: '$count jugador vinculado',
    );
    return '$_temp0';
  }

  @override
  String get fieldTeam => 'Equipo';

  @override
  String get playerNoTeamThisSeason => 'Sin equipo esta temporada';

  @override
  String get fieldSport => 'Deporte';

  @override
  String get sportFootball => 'Fútbol';

  @override
  String get fieldDorsal => 'Dorsal';

  @override
  String get fieldPosition => 'Posición';

  @override
  String get allTeamsTitle => 'Todos los equipos';

  @override
  String get noTeamsAvailable => 'No hay equipos disponibles.';

  @override
  String get noTeamsAssociated => 'No tienes equipos asociados.';

  @override
  String get playerCountLabel => 'Número de jugadores';

  @override
  String get teamsLoadError => 'No se han podido cargar los equipos.';

  @override
  String get markAllReadTooltip => 'Marcar todas como leídas';

  @override
  String get notificationsLoadError =>
      'No se pudieron cargar las notificaciones.';

  @override
  String get noNotifications => 'No tienes notificaciones.';

  @override
  String get notificationsSignedOutMessage =>
      'Inicia sesión en el Área Club para ver tus avisos personales (convocatorias, mensajes…)';

  @override
  String get notificationsPublicHint =>
      'Los avisos de noticias y resultados se activan en Club → Ajustes';

  @override
  String get notificationsOpenSettings => 'Ir a Ajustes';

  @override
  String get loginForgotPassword => '¿Has olvidado tu contraseña?';

  @override
  String get recoverTitle => 'Recuperar contraseña';

  @override
  String get recoverSubtitle =>
      'Te enviaremos un código por email para que elijas una contraseña nueva.';

  @override
  String get recoverSendCode => 'Enviar código';

  @override
  String get recoverCodeSent =>
      'Si el email tiene una cuenta en el club, recibirás un código en unos minutos. Revisa también la carpeta de spam.';

  @override
  String get recoverResetHeading => 'Elige tu nueva contraseña';

  @override
  String get recoverChangePassword => 'Cambiar contraseña';

  @override
  String get recoverResend => 'Reenviar código';

  @override
  String recoverResendIn(String time) {
    return 'Reenviar código ($time)';
  }

  @override
  String get recoverPasswordChanged => 'Contraseña cambiada';

  @override
  String get recoverCodeInvalid => 'Código incorrecto o caducado';

  @override
  String get recoverTooManyAttempts =>
      'Demasiados intentos. Espera unos minutos y vuelve a probar.';

  @override
  String get recoverChangedLoginHint =>
      'Tu contraseña se ha cambiado. Entra con la nueva contraseña.';

  @override
  String get recoverNotActivated =>
      '¿Aún no has activado tu cuenta? Usa el código en';

  @override
  String get markAllReadError =>
      'No se pudieron marcar las notificaciones como leídas.';

  @override
  String todayAt(String time) {
    return 'Hoy, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Ayer, $time';
  }

  @override
  String get noFeesRegistered =>
      'No hay cuotas registradas para tus jugadores.';

  @override
  String playersCountSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '$count jugador',
    );
    return '$_temp0';
  }

  @override
  String feesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuotas',
      one: '$count cuota',
    );
    return '$_temp0';
  }

  @override
  String get feesAllPaidSuffix => ' · todas pagadas';

  @override
  String feesPendingSuffix(int pending) {
    return ' · $pending por pagar';
  }

  @override
  String get noPaymentRegistered =>
      'Esta cuota todavía no tiene ningún pago registrado.';

  @override
  String get close => 'Cerrar';

  @override
  String get noDateRegistered => 'Sin fecha registrada';

  @override
  String get methodNotIndicated => 'Método no indicado';

  @override
  String get feeStatusOverdue => 'Vencida';

  @override
  String get feeStatusPaid => 'Pagada';

  @override
  String get feeStatusPartial => 'Pago parcial';

  @override
  String get feeStatusPending => 'Pendiente';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get chatNoMessages => 'Aún no hay mensajes. Escribe el primero.';

  @override
  String get chatMessageHint => 'Escribe un mensaje...';

  @override
  String get tabConversations => 'Conversaciones';

  @override
  String get tabReceived => 'Recibidas';

  @override
  String get tabSent => 'Enviadas';

  @override
  String get newButton => 'Nueva';

  @override
  String get noConversations => 'No tienes conversaciones';

  @override
  String get noConversationsSubtitle => 'Aquí aparecerán tus chats privados.';

  @override
  String get noCommunicationsReceived => 'No tienes comunicaciones';

  @override
  String get noCommunicationsReceivedSubtitleGlobal =>
      'Aquí aparecerán las comunicaciones del club.';

  @override
  String get noCommunicationsReceivedSubtitleTeam =>
      'Aquí aparecerán las comunicaciones de tus equipos.';

  @override
  String get noCommunicationsSent => 'No has enviado comunicaciones';

  @override
  String get noCommunicationsSentSubtitle =>
      'Aquí aparecerán las comunicaciones que hayas enviado.';

  @override
  String get splashTagline => 'La app oficial del club';

  @override
  String get activateHeading => 'Activa tu cuenta';

  @override
  String get activateSubtitle =>
      'Introduce tu email y el código de 6 dígitos que te ha enviado el club por correo, y elige tu contraseña de acceso.';

  @override
  String get codeLabel => 'Código de 6 dígitos';

  @override
  String get codeRequired => 'Introduce el código que te enviamos por email';

  @override
  String get codeLength => 'El código debe tener 6 dígitos';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get passwordChooseRequired => 'Elige una contraseña';

  @override
  String get passwordMinLength => 'Debe tener al menos 8 caracteres';

  @override
  String get repeatPasswordLabel => 'Repite la contraseña';

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get activateAndEnterButton => 'Activar y entrar';

  @override
  String get commDetailTitle => 'Comunicación';

  @override
  String get commLoadError => 'No se ha podido cargar la comunicación.';

  @override
  String get commNewTitle => 'Nueva comunicación';

  @override
  String get commSelectRecipientError => 'Selecciona a quién quieres escribir.';

  @override
  String get commSelectTeamError => 'Selecciona al menos un equipo.';

  @override
  String get commSelectCategoryError => 'Selecciona al menos una categoría.';

  @override
  String get commSelectRecipientPersonError => 'Selecciona un destinatario.';

  @override
  String get commCreatedSuccess => 'Comunicación creada correctamente.';

  @override
  String commCreateError(String error) {
    return 'No se ha podido crear la comunicación: $error';
  }

  @override
  String get titleLabel => 'Título';

  @override
  String get titleHint => 'Escribe el título';

  @override
  String get titleRequired => 'El título es obligatorio.';

  @override
  String get messageLabel => 'Mensaje';

  @override
  String get messageHint => 'Escribe el contenido de la comunicación';

  @override
  String get messageRequired => 'El mensaje es obligatorio.';

  @override
  String get recipientsTitle => 'Destinatarios';

  @override
  String get teamsSegment => 'Equipos';

  @override
  String get categoriesSegment => 'Categorías';

  @override
  String get privateSegment => 'Privado';

  @override
  String get noRecipientsAvailable =>
      'No tienes ningún destinatario disponible para escribir una comunicación.';

  @override
  String get chooseTeamsHint => 'Elige uno o varios equipos.';

  @override
  String get chooseCategoriesHint => 'Elige una o varias categorías.';

  @override
  String get choosePrivateRecipientHint =>
      'Elige una única persona; el mensaje será privado solo para ella.';

  @override
  String get searchRecipientLabel => 'Buscar destinatario';

  @override
  String get searchRecipientHint => 'Nombre o apellidos';

  @override
  String get noRecipientsFound => 'No se han encontrado destinatarios.';

  @override
  String get savingButton => 'Guardando...';

  @override
  String get saveCommunicationButton => 'Guardar comunicación';

  @override
  String get recipientsLoadError =>
      'No se han podido cargar los destinatarios.';

  @override
  String get liveMatchTitle => 'Partido en directo';

  @override
  String get liveMatchWarning =>
      'Cada botón manda un aviso en directo a todos los usuarios de la app. Puedes deshacer el último aviso durante 2 minutos; pasado ese tiempo ya no se puede.';

  @override
  String get liveEventKickoff => 'Inicio de partido';

  @override
  String get liveConfirmKickoff => '¿Avisar de que empieza el partido?';

  @override
  String get liveEventGoalAgainst => 'Gol en contra';

  @override
  String get liveConfirmGoalAgainst => '¿Avisar de un gol en contra?';

  @override
  String get liveEventHalftime => 'Descanso';

  @override
  String get liveConfirmHalftime => '¿Avisar del descanso?';

  @override
  String get liveEventSecondHalf => 'Segunda parte';

  @override
  String get liveConfirmSecondHalf => '¿Avisar del inicio de la segunda parte?';

  @override
  String get liveEventFulltime => 'Final de partido';

  @override
  String get liveConfirmFulltime => '¿Avisar de que ha finalizado el partido?';

  @override
  String get liveLineupButton => 'Alineación';

  @override
  String get liveGoalForButton => 'Gol a favor';

  @override
  String get cancel => 'Cancelar';

  @override
  String get send => 'Enviar';

  @override
  String get liveStartingLineupLabel => 'Once inicial';

  @override
  String get liveSubstitutesLabel => 'Suplentes';

  @override
  String get liveFillLineupError => 'Rellena el once inicial y los suplentes.';

  @override
  String get liveLineupSentMessage => 'Alineación enviada.';

  @override
  String get liveEnterGoalAuthorError => 'Escribe el autor del gol.';

  @override
  String get liveGoalSentMessage => 'Gol enviado.';

  @override
  String get liveNoMatchesToday =>
      'No hay ningún partido del Primer Equipo hoy';

  @override
  String get liveChooseMatch => 'Elige el partido que vas a retransmitir';

  @override
  String get liveMatchHome => 'Local';

  @override
  String get liveMatchAway => 'Visitante';

  @override
  String get liveChangeMatch => 'Cambiar de partido';

  @override
  String get liveLoadError => 'No se han podido cargar los partidos de hoy.';

  @override
  String get livePhaseNotStarted => 'Sin empezar';

  @override
  String get livePhaseFirstHalf => '1ª parte';

  @override
  String get livePhaseHalftime => 'Descanso';

  @override
  String get livePhaseSecondHalf => '2ª parte';

  @override
  String get livePhaseFinished => 'Final';

  @override
  String get liveScorers => 'Goleadores';

  @override
  String get liveNoScorersYet => 'Todavía no hay goles a favor';

  @override
  String get liveOwnGoalShort => 'p.p. (propia puerta del rival)';

  @override
  String get liveGoalAuthorTitle => '¿Quién ha marcado?';

  @override
  String get liveGoalOther => 'Otro…';

  @override
  String get liveGoalOtherLabel => 'Autor del gol (máx. 60 caracteres)';

  @override
  String get liveGoalOwnGoal => 'Propia puerta (rival)';

  @override
  String get liveNoPlayersToPick =>
      'No hay jugadores en la lista: elige \"Otro\" o \"Propia puerta\".';

  @override
  String liveUndoButton(String time) {
    return 'Deshacer ($time)';
  }

  @override
  String liveUndoLast(String event) {
    return 'Último aviso: $event';
  }

  @override
  String get liveUndoFulltimeTitle => '¿Deshacer el final?';

  @override
  String get liveUndoFulltimeMessage =>
      'Se anulará el final del partido y se devolverá a como estaba el resultado guardado.';

  @override
  String get liveUndoneMessage => 'Aviso deshecho.';

  @override
  String get liveUndoConfirm => 'Deshacer';

  @override
  String get liveEventAlert => 'Aviso';

  @override
  String liveNotificationSentMessage(String titulo) {
    return 'Aviso de \"$titulo\" enviado.';
  }

  @override
  String liveSendError(String error) {
    return 'No se ha podido enviar el aviso: $error';
  }

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get trainingsTitle => 'Entrenamientos';

  @override
  String get newMasculineButton => 'Nuevo';

  @override
  String get trainingsNextBadge => 'PRÓXIMO ENTRENAMIENTO';

  @override
  String get noUpcomingTrainings =>
      'No hay entrenamientos en las próximas dos semanas.';

  @override
  String get pastTrainingsButton => 'Entrenamientos pasados';

  @override
  String get pastTrainingsTitle => 'Entrenamientos pasados';

  @override
  String get noPastTrainings => 'Todavía no hay entrenamientos anteriores.';

  @override
  String get trainingsLoadError =>
      'No se han podido cargar los entrenamientos.';

  @override
  String get editTrainingTitle => 'Editar entrenamiento';

  @override
  String get newTrainingTitle => 'Nuevo entrenamiento';

  @override
  String get noPlayersForTraining =>
      'No hay jugadores para registrar el entrenamiento.';

  @override
  String get trainingDateFutureError =>
      'La fecha del entrenamiento no puede ser posterior a hoy.';

  @override
  String get trainingUpdatedSuccess =>
      'Entrenamiento actualizado correctamente.';

  @override
  String get trainingSavedSuccess => 'Entrenamiento guardado correctamente.';

  @override
  String trainingSaveError(String error) {
    return 'No se ha podido guardar: $error';
  }

  @override
  String get trainingDateLabel => 'Fecha del entrenamiento';

  @override
  String get attendanceTitle => 'Asistencia';

  @override
  String get attendanceHint => 'Marca el estado de cada jugador';

  @override
  String get attendanceStatusPresent => 'Presente';

  @override
  String get attendanceStatusAbsent => 'Falta';

  @override
  String get attendanceStatusLate => 'Retraso';

  @override
  String get attendanceStatusJustifiedAbsence => 'Falta justificada';

  @override
  String get attendanceStatusMisconduct => 'Mal comportamiento';

  @override
  String get saveChangesButton => 'Guardar cambios';

  @override
  String get saveTrainingButton => 'Guardar entrenamiento';

  @override
  String get noPlayersAvailableForTeam =>
      'No hay jugadores disponibles para este equipo.';

  @override
  String get playersLoadError => 'No se han podido cargar los jugadores.';

  @override
  String get callupsTitle => 'Convocatorias';

  @override
  String get noCallupsYet => 'Todavía no hay convocatorias.';

  @override
  String get createFirstCallupHint =>
      'Crea la primera pulsando el botón Nueva.';

  @override
  String get callupsLoadError => 'No se han podido cargar las convocatorias.';

  @override
  String get editCallupTitle => 'Editar convocatoria';

  @override
  String get newCallupTitle => 'Nueva convocatoria';

  @override
  String get rivalLabel => 'Rival';

  @override
  String get fieldLabelCampo => 'Campo';

  @override
  String get matchTimeLabel => 'Hora del partido';

  @override
  String get callupTimeLabel => 'Hora de convocatoria';

  @override
  String get callupPlaceLabel => 'Lugar de convocatoria';

  @override
  String get matchDateLabel => 'Fecha del partido';

  @override
  String get selectMatchLabel => 'Partido';

  @override
  String get selectMatchHint => 'Selecciona un partido';

  @override
  String get selectMatchError => 'Selecciona un partido.';

  @override
  String get noMatchesAvailableForCallup =>
      'No hay partidos disponibles para crear una convocatoria. Crea primero un partido.';

  @override
  String get callupPlayersTitle => 'Jugadores convocados';

  @override
  String selectedCountLabel(int count) {
    return '$count seleccionados';
  }

  @override
  String get saveCallupButton => 'Guardar convocatoria';

  @override
  String get enterCallupPlaceError => 'Introduce el lugar de convocatoria.';

  @override
  String get selectAtLeastOnePlayerError => 'Selecciona al menos un jugador.';

  @override
  String get callupUpdatedSuccess => 'Convocatoria actualizada correctamente.';

  @override
  String get callupCreatedSuccess => 'Convocatoria creada correctamente.';

  @override
  String callupUpdateError(String error) {
    return 'No se ha podido actualizar la convocatoria: $error';
  }

  @override
  String callupCreateError(String error) {
    return 'No se ha podido crear la convocatoria: $error';
  }

  @override
  String get teamManagementTitle => 'Gestión del equipo';

  @override
  String get trainingsDesc => 'Crear y consultar entrenamientos y asistencia';

  @override
  String get callupsDesc => 'Crear y consultar convocatorias de partidos';

  @override
  String get playersMenuLabel => 'Jugadores';

  @override
  String get playersMenuDesc => 'Consultar los jugadores del equipo';

  @override
  String get noPlayersInTeam => 'No hay jugadores en este equipo.';

  @override
  String get matchResultPending => 'Pendiente de resultado';

  @override
  String get viewStandings => 'Ver clasificación';

  @override
  String seasonTitle(String name) {
    return 'Temporada $name';
  }

  @override
  String get seasonTitleNoName => 'Temporada';

  @override
  String get seasonNoData => 'Todavía no hay datos de esta temporada';

  @override
  String get seasonGoals => 'Goles';

  @override
  String get seasonAssists => 'Asistencias';

  @override
  String get seasonYellows => 'Amarillas';

  @override
  String get seasonReds => 'Rojas';

  @override
  String get seasonCallupsCard => 'Convocatorias';

  @override
  String get seasonTrainingsTitle => 'Entrenamientos';

  @override
  String seasonTrainingsLine(int attended, int total, int percent) {
    return '$attended de $total ($percent %)';
  }

  @override
  String get seasonTrainingsNone => 'Todavía no hay entrenamientos';

  @override
  String seasonAbsences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faltas',
      one: '1 falta',
    );
    return '$_temp0';
  }

  @override
  String seasonExcused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count justificadas',
      one: '1 justificada',
    );
    return '$_temp0';
  }

  @override
  String seasonShortTrainings(int attended, int total) {
    return 'Entrenamientos $attended/$total';
  }

  @override
  String seasonShortGoals(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals goles',
      one: '1 gol',
    );
    return '$_temp0';
  }

  @override
  String get clubPageMyCard => 'Mi ficha';

  @override
  String get clubPageMyCardDesc => 'Tus datos de jugador';

  @override
  String callupMatchLine(String date) {
    return 'Partido: $date';
  }

  @override
  String callupMeetingLine(String time, String place) {
    return 'Convocatoria: $time · $place';
  }

  @override
  String callupReasonShown(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get clubPageMyStandings => 'Mis clasificaciones';

  @override
  String get clubPageMyStandingsDesc => 'Clasificación de tus equipos';

  @override
  String get allStandingsTitle => 'Clasificaciones';

  @override
  String get clubPageAllStandingsDesc => 'Clasificación de todos los equipos';

  @override
  String get standingsNone => 'Sin clasificación todavía';

  @override
  String standingsSummary(int pos, int pts, int round) {
    return '$posº · $pts pts · J$round';
  }

  @override
  String standingsSummaryNoRound(int pos, int pts) {
    return '$posº · $pts pts';
  }

  @override
  String standingsUpdated(int round, String date) {
    return 'Jornada $round · actualizado el $date';
  }

  @override
  String standingsUpdatedNoRound(String date) {
    return 'Actualizado el $date';
  }

  @override
  String get standingsEmpty => 'Clasificación no disponible todavía';

  @override
  String get standingsLoadError => 'No se ha podido cargar la clasificación.';

  @override
  String get standingsColPos => 'Pos';

  @override
  String get standingsColTeam => 'Equipo';

  @override
  String get standingsColPlayed => 'PJ';

  @override
  String get standingsColPoints => 'Pts';

  @override
  String get standingsColWon => 'G';

  @override
  String get standingsColDrawn => 'E';

  @override
  String get standingsColLost => 'P';

  @override
  String get standingsColGoalsFor => 'GF';

  @override
  String get standingsColGoalsAgainst => 'GC';

  @override
  String get familiesTitle => 'Familiares';

  @override
  String get phoneAppOpenError => 'No se puede abrir la aplicación de teléfono';

  @override
  String get whatsappOpenError => 'No se puede abrir WhatsApp';

  @override
  String get noFamiliesRegistered =>
      'Este jugador no tiene familiares registrados';

  @override
  String get callButton => 'Llamar';

  @override
  String get emailButton => 'Email';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get allMatchesTitle => 'Todos los partidos';

  @override
  String get matchDeletedSuccess => 'Partido eliminado correctamente.';

  @override
  String get matchCreatedSuccess => 'Partido creado correctamente.';

  @override
  String get matchUpdatedSuccess => 'Partido actualizado correctamente.';

  @override
  String get teamMatchesLoadError =>
      'No se han podido cargar los partidos de este equipo.';

  @override
  String get addMatchButton => 'Añadir partido';

  @override
  String get teamNoMatchesAvailable =>
      'No hay partidos disponibles para este equipo.';

  @override
  String get editMatchTooltip => 'Editar partido';

  @override
  String get matchTypeLiga => 'Liga';

  @override
  String get matchTypeAmistoso => 'Amistoso';

  @override
  String get matchTypeCopa => 'Copa';

  @override
  String get matchTypeTorneo => 'Torneo';

  @override
  String get rivalRequiredError => 'El rival es obligatorio.';

  @override
  String get deleteMatchTitle => 'Eliminar partido';

  @override
  String get deleteMatchConfirm =>
      '¿Eliminar este partido? Esta acción no se puede deshacer.';

  @override
  String get delete => 'Eliminar';

  @override
  String get editMatchTitle => 'Editar partido';

  @override
  String get newMatchTitle => 'Nuevo partido';

  @override
  String get matchTypeLabel => 'Tipo de partido';

  @override
  String get noDateSelected => 'Sin fecha';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get hourLabelHint => 'Hora (ej. 18:00)';

  @override
  String get save => 'Guardar';

  @override
  String get calendarAllTeamsTitle => 'Calendario de equipos';

  @override
  String get calendarLoadError => 'No se ha podido cargar el calendario.';

  @override
  String get calendarNoItems =>
      'No hay entrenamientos ni partidos programados.';

  @override
  String get calendarSessionLabel => 'Entrenamiento';

  @override
  String get calendarMatchLabel => 'Partido';

  @override
  String get calendarCancelledBadge => 'Cancelado';

  @override
  String get calendarJustifiedBadge => 'Justificada';

  @override
  String get calendarCalledUpBadge => 'Convocado';

  @override
  String get calendarNotCalledUpBadge => 'No convocado';

  @override
  String get matchResultLabel => 'Resultado';

  @override
  String get calendarJustifyAbsenceButton => 'Justificar falta';

  @override
  String get calendarEditJustificationButton => 'Editar justificación';

  @override
  String get calendarJustifyAbsenceTitle => 'Justificar falta a entrenamiento';

  @override
  String get calendarEditJustificationTitle => 'Editar justificación de falta';

  @override
  String get calendarJustifyAbsenceHint =>
      'Indica el motivo de la falta (opcional). Si ya habías justificado esta sesión, se actualizará el motivo.';

  @override
  String get calendarEditJustificationHint =>
      'Ya has justificado esta falta. Puedes editar el motivo si quieres.';

  @override
  String get calendarJustifyAbsenceReasonLabel => 'Motivo';

  @override
  String get calendarJustifyAbsenceSubmit => 'Enviar';

  @override
  String get calendarJustifyAbsenceSuccess =>
      'Falta justificada correctamente.';

  @override
  String get calendarManagementTitle => 'Calendario';

  @override
  String get calendarManagementDesc =>
      'Horario semanal, sesiones y partidos del equipo';

  @override
  String get calendarManagementLoadError =>
      'No se ha podido cargar el calendario del equipo.';

  @override
  String get weeklyScheduleTitle => 'Horario semanal de entrenamientos';

  @override
  String get weeklyScheduleEmpty =>
      'Todavía no se ha configurado ningún horario semanal para este equipo.';

  @override
  String get weeklyScheduleAddButton => 'Añadir horario';

  @override
  String get weeklyScheduleEditTooltip => 'Editar horario';

  @override
  String get weeklyScheduleDeactivateTooltip => 'Desactivar horario';

  @override
  String get weeklyScheduleDeactivateConfirmTitle => 'Desactivar horario';

  @override
  String get weeklyScheduleDeactivateConfirmMessage =>
      'Se desactivará este horario y se cancelarán sus sesiones futuras todavía programadas. ¿Continuar?';

  @override
  String get weeklyScheduleDeactivatedSuccess => 'Horario desactivado.';

  @override
  String weeklyScheduleDeactivateError(String error) {
    return 'No se ha podido desactivar el horario: $error';
  }

  @override
  String get weeklyScheduleSavedSuccess => 'Horario guardado correctamente.';

  @override
  String get weeklyScheduleFormTitleNew => 'Nuevo horario';

  @override
  String get weeklyScheduleFormTitleEdit => 'Editar horario';

  @override
  String get weeklyScheduleDayLabel => 'Día de la semana';

  @override
  String get weeklyScheduleTimeLabel => 'Hora';

  @override
  String get weeklySchedulePlaceLabel => 'Lugar';

  @override
  String get weeklyScheduleActiveLabel => 'Activo';

  @override
  String get weeklyScheduleInactiveBadge => 'Inactivo';

  @override
  String get upcomingItemsTitle => 'Próximas sesiones y partidos';

  @override
  String get upcomingItemsEmpty =>
      'No hay entrenamientos ni partidos programados en las próximas semanas.';

  @override
  String get sessionEditTooltip => 'Editar sesión';

  @override
  String get sessionEditFormTitle => 'Editar sesión de entrenamiento';

  @override
  String get sessionEditSavedSuccess => 'Sesión actualizada correctamente.';

  @override
  String get sessionCancelTooltip => 'Cancelar sesión';

  @override
  String get sessionCancelConfirmTitle => 'Cancelar sesión';

  @override
  String get sessionCancelConfirmMessage =>
      'Se avisará a los jugadores y familiares. Esta acción no se puede deshacer. Indica el motivo de la cancelación:';

  @override
  String get cancelReasonLabel => 'Motivo';

  @override
  String get cancelReasonRequiredError => 'El motivo es obligatorio';

  @override
  String get sessionCancelledSuccess => 'Sesión cancelada.';

  @override
  String sessionCancelError(String error) {
    return 'No se ha podido cancelar la sesión: $error';
  }

  @override
  String get matchCancelTooltip => 'Cancelar partido';

  @override
  String get matchCancelConfirmTitle => 'Cancelar partido';

  @override
  String get matchCancelConfirmMessage =>
      'Se cancelará este partido. Esta acción no se puede deshacer. ¿Continuar?';

  @override
  String get matchCancelledSuccess => 'Partido cancelado.';

  @override
  String matchCancelError(String error) {
    return 'No se ha podido cancelar el partido: $error';
  }

  @override
  String get viewJustificationsTooltip => 'Ver justificaciones';

  @override
  String get viewJustificationsTitle => 'Justificaciones de falta';

  @override
  String get viewJustificationsEmpty =>
      'Todavía no hay ninguna justificación para esta sesión.';

  @override
  String get viewJustificationsLoadError =>
      'No se han podido cargar las justificaciones.';

  @override
  String get justificationNoReasonGiven => 'Sin motivo indicado';

  @override
  String get matchResultFormTitle => 'Resultado del partido';

  @override
  String get matchResultGoalsForLabel => 'Goles a favor';

  @override
  String get matchResultGoalsAgainstLabel => 'Goles en contra';

  @override
  String get matchResultGoalsHelp => 'Goles del Mutxamel – goles del rival';

  @override
  String get matchResultOnlyScoreNote =>
      'En este equipo solo se registra el resultado del partido';

  @override
  String get matchResultPlayersTitle => 'Estadísticas por jugador';

  @override
  String get matchResultGoalsShort => 'Goles';

  @override
  String get matchResultAssistsShort => 'Asist.';

  @override
  String get matchResultYellowCardsShort => 'T. amarillas';

  @override
  String get matchResultRedCardShort => 'T. roja';

  @override
  String get matchResultSaveButton => 'Guardar resultado';

  @override
  String get matchResultSavedSuccess => 'Resultado guardado correctamente.';

  @override
  String matchResultSaveError(String error) {
    return 'No se ha podido guardar el resultado: $error';
  }

  @override
  String get matchResultLoadError =>
      'No se han podido cargar los datos del partido.';

  @override
  String get matchEnterResultTooltip => 'Introducir resultado';

  @override
  String get matchEditResultTooltip => 'Editar resultado';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Borra tu cuenta y tus datos personales';

  @override
  String get deleteAccountDialogTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountWarning =>
      'Se borrarán tu correo, tu contraseña, tus accesos al club, tus dispositivos y tus notificaciones. Las fichas del club (jugador, familiar o cuerpo técnico) se conservan, y los mensajes que enviaste se conservarán sin tu nombre. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountPasswordLabel =>
      'Introduce tu contraseña para confirmar';

  @override
  String get deleteAccountPasswordRequired => 'Introduce tu contraseña';

  @override
  String get deleteAccountConfirm => 'Eliminar cuenta';

  @override
  String get deleteAccountWrongPassword => 'La contraseña no es correcta.';

  @override
  String get deleteAccountTooManyAttempts =>
      'Demasiados intentos fallidos. Inténtalo de nuevo en unos minutos.';

  @override
  String get deleteAccountError =>
      'No se ha podido eliminar la cuenta. Inténtalo de nuevo.';

  @override
  String get deleteAccountDone => 'Tu cuenta ha sido eliminada.';

  @override
  String get reportAction => 'Reportar';

  @override
  String get reportDialogTitle => 'Reportar mensaje';

  @override
  String get reportDialogBody =>
      'Se avisará al club para que revise este mensaje. Puedes indicar el motivo (opcional).';

  @override
  String get reportReasonHint => 'Motivo (opcional)';

  @override
  String get reportSend => 'Enviar reporte';

  @override
  String get reportSent => 'Reporte enviado. El club lo revisará.';

  @override
  String get reportError =>
      'No se ha podido enviar el reporte. Inténtalo de nuevo.';

  @override
  String get matchAbsenceJustifyButton => 'Justificar ausencia';

  @override
  String get matchAbsenceJustifyTitle => 'Justificar ausencia al partido';

  @override
  String get matchAbsenceEditTitle => 'Editar motivo de la ausencia';

  @override
  String get matchAbsenceHint =>
      'Avisa al cuerpo técnico de que el jugador no podrá jugar este partido. Puedes cambiar el motivo o retirarlo hasta la hora de convocatoria.';

  @override
  String get matchAbsenceReasonLabel => 'Motivo';

  @override
  String get matchAbsenceReasonRequired =>
      'Indica el motivo (mínimo 3 caracteres)';

  @override
  String get matchAbsenceBadge => 'Ausencia justificada';

  @override
  String get matchAbsenceEditButton => 'Editar motivo';

  @override
  String get matchAbsenceWithdrawButton => 'Retirar';

  @override
  String get matchAbsenceWithdrawTitle => '¿Retirar la ausencia?';

  @override
  String get matchAbsenceWithdrawBody =>
      'El cuerpo técnico sabrá que el jugador ya puede jugar. El jugador podrá ser convocado de nuevo, pero no se añadirá a la convocatoria automáticamente.';

  @override
  String get matchAbsenceWithdrawConfirm => 'Retirar';

  @override
  String matchAbsenceDeadlineClosed(String deadline) {
    return 'Plazo cerrado ($deadline)';
  }

  @override
  String get matchAbsenceJustifiedSnack => 'Ausencia justificada';

  @override
  String get matchAbsenceWithdrawnSnack => 'Ausencia retirada';

  @override
  String get matchAbsenceError =>
      'No se ha podido guardar. Inténtalo de nuevo.';

  @override
  String get callupDetailTitle => 'Convocatoria';

  @override
  String callupPlayersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convocados',
      one: '1 convocado',
    );
    return '$_temp0';
  }

  @override
  String callupAbsentBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores convocados han justificado su ausencia',
      one: '1 jugador convocado ha justificado su ausencia',
    );
    return '$_temp0';
  }

  @override
  String callupAbsentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausencias justificadas',
      one: '1 ausencia justificada',
    );
    return '$_temp0';
  }

  @override
  String seasonMatchAbsencesLine(int count) {
    return 'Partidos con ausencia justificada: $count';
  }

  @override
  String get callupUnavailable => 'Esta convocatoria ya no está disponible';

  @override
  String get connectionError =>
      'No se ha podido conectar. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get teamCardsTitle => 'Tarjetas';

  @override
  String get teamCardsDesc =>
      'Amarillas y rojas de los jugadores y posibles sanciones';

  @override
  String get cardsNoPlayers => 'No hay jugadores en este equipo';

  @override
  String get cardsStatusOneAway => 'A una de sanción';

  @override
  String get cardsStatusSanction => 'Posible sanción';

  @override
  String get cardsFooterNote => 'Orientativo: la sanción la determina la FFCV.';

  @override
  String get yellowCardsLabel => 'Amarillas';

  @override
  String get redCardsLabel => 'Rojas';

  @override
  String get teamStatsTitle => 'Estadísticas';

  @override
  String get teamStatsDesc => 'Goleadores, asistentes, asistencia y resultados';

  @override
  String get statsPlayedShort => 'PJ';

  @override
  String get statsWonShort => 'G';

  @override
  String get statsDrawnShort => 'E';

  @override
  String get statsLostShort => 'P';

  @override
  String get statsGoalsForShort => 'GF';

  @override
  String get statsGoalsAgainstShort => 'GC';

  @override
  String get statsAttendanceAverage => 'Asistencia media';

  @override
  String get statsTopScorers => 'Goleadores';

  @override
  String get statsTopAssisters => 'Asistentes';

  @override
  String get statsTrainingAttendance => 'Asistencia a entrenamientos';

  @override
  String get statsNoData => 'Todavía no hay datos';

  @override
  String statsGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goles',
      one: '$count gol',
    );
    return '$_temp0';
  }

  @override
  String statsAssistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count asistencias',
      one: '$count asistencia',
    );
    return '$_temp0';
  }

  @override
  String statsAttendedOf(int asistidos, int total) {
    return '$asistidos de $total';
  }

  @override
  String statsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get trainingListNotReviewed => 'Lista sin revisar';

  @override
  String get trainingNotFound => 'Este entrenamiento ya no está disponible';

  @override
  String get clubPageWeekend => 'Fin de semana';

  @override
  String get clubPageWeekendDesc =>
      'Convocatorias, resultados y jornadas por revisar';

  @override
  String get clubPagePlayerTracking => 'Seguimiento de jugadores';

  @override
  String get clubPagePlayerTrackingDesc =>
      'Faltas y mal comportamiento en entrenamientos';

  @override
  String get weekendPrevious => 'Fin de semana anterior';

  @override
  String get weekendNext => 'Fin de semana siguiente';

  @override
  String get weekendNoCallup => 'Sin convocatoria';

  @override
  String get weekendPendingResults => 'Resultados pendientes';

  @override
  String get weekendResting => 'Descansan';

  @override
  String get weekendNoMatch => 'Sin partido ni descanso';

  @override
  String get weekendNoMatchNote => '¿Falta importar la jornada?';

  @override
  String get weekendAllClear => 'Todo al día';

  @override
  String weekendLastImport(String fecha) {
    return 'Última importación FFCV: $fecha';
  }

  @override
  String weekendDelayDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace $count día',
      zero: 'Hoy',
    );
    return '$_temp0';
  }

  @override
  String weekendRound(int jornada) {
    return 'Jornada $jornada';
  }

  @override
  String trackingPeriodDays(int count) {
    return 'Últimos $count días';
  }

  @override
  String trackingExcusedChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count justificadas',
      one: '$count justificada',
    );
    return '$_temp0';
  }

  @override
  String trackingLateChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count retrasos',
      one: '$count retraso',
    );
    return '$_temp0';
  }

  @override
  String get noPermission => 'No tienes permiso';

  @override
  String get callupMatchUnavailable => 'Este partido ya no admite convocatoria';

  @override
  String statsUnreviewedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entrenamientos sin lista revisada no cuentan en la asistencia',
      one: '$count entrenamiento sin lista revisada no cuenta en la asistencia',
    );
    return '$_temp0';
  }

  @override
  String get trackingPeriodSeason => 'Temporada';

  @override
  String get trackingAllTeams => 'Todos los equipos';

  @override
  String trackingFaultsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faltas',
      one: '$count falta',
    );
    return '$_temp0';
  }

  @override
  String trackingMisconductChip(int count) {
    return '$count mal comportamiento';
  }

  @override
  String trackingLastIncident(String fecha) {
    return 'Última incidencia: $fecha';
  }

  @override
  String get trackingEmpty =>
      'Ningún jugador llega a los umbrales en este periodo';

  @override
  String get trackingCoordinationOnly => 'Datos solo para coordinación';

  @override
  String get trackingNoIncidents => 'Sin incidencias en este periodo';

  @override
  String get clubPageModeration => 'Moderación';

  @override
  String get clubPageModerationDesc => 'Mensajes reportados por los usuarios';

  @override
  String get clubPagePendingAccounts => 'Cuentas pendientes';

  @override
  String get clubPagePendingAccountsDesc =>
      'Invitaciones que todavía no se han activado';

  @override
  String get moderationTabPending => 'Pendientes';

  @override
  String get moderationTabResolved => 'Resueltos';

  @override
  String get moderationEmptyPending => 'No hay reportes pendientes';

  @override
  String get moderationEmptyResolved => 'Todavía no hay reportes resueltos';

  @override
  String moderationAuthor(String nombre) {
    return 'Autor: $nombre';
  }

  @override
  String moderationReporter(String nombre) {
    return 'Reportado por: $nombre';
  }

  @override
  String moderationReason(String motivo) {
    return 'Motivo: $motivo';
  }

  @override
  String get moderationNoReason => 'sin motivo indicado';

  @override
  String moderationMessageDate(String fecha) {
    return 'Mensaje: $fecha';
  }

  @override
  String moderationReportDate(String fecha) {
    return 'Reportado: $fecha';
  }

  @override
  String moderationAuthorReports(int count) {
    return 'El autor tiene $count reportes';
  }

  @override
  String get moderationShowMore => 'Ver más';

  @override
  String get moderationShowLess => 'Ver menos';

  @override
  String get moderationDiscard => 'Descartar';

  @override
  String get moderationDeleteMessage => 'Borrar mensaje';

  @override
  String get moderationDeactivateAuthor => 'Desactivar autor';

  @override
  String get moderationNoteLabel => 'Nota (opcional)';

  @override
  String get moderationDiscardConfirm =>
      '¿Descartar este reporte? El mensaje se queda como está.';

  @override
  String get moderationDeleteConfirm =>
      '¿Borrar el mensaje para todos los usuarios?';

  @override
  String get moderationDeactivateConfirm =>
      '¿Desactivar la cuenta del autor? Dejará de poder entrar en la app.';

  @override
  String get moderationAlsoDeleteMessage => 'Borrar también el mensaje';

  @override
  String get moderationConfirm => 'Confirmar';

  @override
  String get moderationResolvedDone => 'Reporte resuelto';

  @override
  String get moderationStateDiscarded => 'Descartado';

  @override
  String get moderationStateMessageDeleted => 'Mensaje borrado';

  @override
  String get moderationStateAuthorDeactivated => 'Autor desactivado';

  @override
  String moderationResolvedBy(String nombre, String fecha) {
    return 'Resuelto por $nombre el $fecha';
  }

  @override
  String get pendingAccountsEmpty => 'No hay cuentas pendientes';

  @override
  String get pendingAccountsSearch => 'Buscar por nombre o email';

  @override
  String pendingAccountsInvited(String fecha) {
    return 'Invitado el $fecha';
  }

  @override
  String get pendingAccountsCodeExpired => 'Código caducado';

  @override
  String get pendingAccountsResend => 'Reenviar activación';

  @override
  String pendingAccountsResendConfirm(String email) {
    return '¿Reenviar la invitación de activación a $email?';
  }

  @override
  String pendingAccountsResent(String email) {
    return 'Invitación reenviada a $email';
  }

  @override
  String get versionUpdateRequiredBody =>
      'Hay una nueva versión de la app. Actualízala para seguir usándola';

  @override
  String get versionUpdateButton => 'Actualizar';

  @override
  String get versionUpdateAvailableTitle => 'Nueva versión disponible';

  @override
  String get versionUpdateAvailableBody =>
      'Hay una versión más reciente de la app. ¿Quieres actualizarla ahora?';

  @override
  String get versionUpdateLater => 'Más tarde';

  @override
  String get directionsButton => 'Cómo llegar';

  @override
  String get directionsOpenError => 'No se ha podido abrir el mapa.';

  @override
  String get calendarWithdrawJustificationTitle => '¿Retirar la justificación?';

  @override
  String get calendarWithdrawJustificationBody =>
      'El cuerpo técnico sabrá que el jugador asistirá al entrenamiento.';

  @override
  String get calendarJustificationWithdrawnSnack => 'Justificación retirada.';

  @override
  String get calendarJustificationWithdrawError =>
      'No se ha podido retirar la justificación.';

  @override
  String get callupFamilyMeetingTitle => 'Citación';

  @override
  String callupFamilyMeetingTime(String time) {
    return 'Hora de citación: $time';
  }

  @override
  String callupFamilyMeetingPlace(String place) {
    return 'Lugar: $place';
  }

  @override
  String get callupFamilyHome => 'Local';

  @override
  String get callupFamilyAway => 'Visitante';

  @override
  String get callupFamilyYourPlayer => 'Tu jugador';

  @override
  String get callupFamilyLoadError => 'No se ha podido cargar la convocatoria.';

  @override
  String get callupDeleteButton => 'Eliminar convocatoria';

  @override
  String get callupDeleteConfirmTitle => '¿Eliminar la convocatoria?';

  @override
  String get callupDeleteConfirmBody => 'Se avisará a los convocados.';

  @override
  String get callupDeletedSnack => 'Convocatoria eliminada.';

  @override
  String get callupDeleteError => 'No se ha podido eliminar la convocatoria.';

  @override
  String get weekendRemind => 'Recordar';

  @override
  String get weekendReminded => 'Recordado';

  @override
  String weekendReminderSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recordatorio enviado a $count entrenadores',
      one: 'Recordatorio enviado a 1 entrenador',
    );
    return '$_temp0';
  }

  @override
  String get weekendReminderNoCoaches =>
      'El equipo no tiene entrenadores con cuenta en la app.';

  @override
  String get weekendReminderOnlyYou =>
      'Eres el único entrenador con cuenta de este equipo';

  @override
  String weekendReminderTooSoon(String time) {
    return 'Ya se envió este recordatorio a las $time. Podrás repetirlo pasadas 2 horas.';
  }

  @override
  String get weekendReminderError => 'No se ha podido enviar el recordatorio.';

  @override
  String get liveMinuteLabel => 'Minuto';

  @override
  String get liveMinuteInvalid => 'El minuto debe estar entre 0 y 150.';

  @override
  String get liveGoalAgainstRow => 'Gol en contra';

  @override
  String get liveMinuteEditTitle => 'Corregir el minuto';

  @override
  String get liveMinuteSave => 'Guardar';

  @override
  String get liveMinuteSaved => 'Minuto corregido.';

  @override
  String get inviteButton => 'Invitar';

  @override
  String get inviteTitle => 'Invitar usuario';

  @override
  String get inviteNameLabel => 'Nombre';

  @override
  String get inviteSurnameLabel => 'Apellidos';

  @override
  String get inviteEmailLabel => 'Email';

  @override
  String get inviteEmailFromFamily =>
      'Con un familiar vinculado se usa el email de su ficha.';

  @override
  String get inviteLinksTitle => 'Vínculos';

  @override
  String get inviteLinkPlayer => 'Jugador';

  @override
  String get inviteLinkFamily => 'Familiar';

  @override
  String get inviteLinkStaff => 'Cuerpo técnico';

  @override
  String get inviteSearchHint => 'Buscar por nombre';

  @override
  String get inviteNoResults => 'No hay personas sin cuenta que coincidan.';

  @override
  String get inviteRolesTitle => 'Roles adicionales';

  @override
  String get inviteSummaryTitle => 'Roles resultantes';

  @override
  String get inviteSummaryEmpty => 'Elige al menos un vínculo o un rol.';

  @override
  String get inviteSubmit => 'Enviar invitación';

  @override
  String get inviteNameRequired => 'Escribe el nombre de la persona.';

  @override
  String get inviteEmailRequired => 'Escribe un email válido.';

  @override
  String inviteSent(String email) {
    return 'Invitación enviada a $email';
  }

  @override
  String inviteCreatedNoEmail(String email) {
    return 'Cuenta creada para $email, pero no se ha podido enviar el email. Reenvíalo desde Cuentas pendientes.';
  }

  @override
  String get inviteLoadError =>
      'No se han podido cargar las personas del club.';

  @override
  String get clubPageAppStatus => 'Estado de la app';

  @override
  String get clubPageAppStatusDesc => 'Cuentas, dispositivos y versiones';

  @override
  String get appStatusActive => 'Cuentas activas';

  @override
  String get appStatusPending => 'Pendientes de activar';

  @override
  String get appStatusDeactivated => 'Desactivadas';

  @override
  String get appStatusNoDevice => 'Sin dispositivo (sin push)';

  @override
  String get appStatusNoNotifications => 'Notificaciones desactivadas';

  @override
  String get appStatusOldVersion => 'Dispositivos con versión antigua';

  @override
  String appStatusInactive(int days) {
    return 'Sin entrar en $days días';
  }

  @override
  String get appStatusVersionsTitle => 'Versiones por plataforma';

  @override
  String get appStatusPlatform => 'Plataforma';

  @override
  String get appStatusVersion => 'Versión';

  @override
  String get appStatusDevices => 'Dispositivos';

  @override
  String appStatusMinimum(String android, String ios) {
    return 'Versión mínima: Android $android · iOS $ios';
  }

  @override
  String get appStatusNoVersions => 'No hay dispositivos activos.';

  @override
  String get appStatusUsersEmpty => 'No hay cuentas en esta lista.';

  @override
  String get appStatusUsersMax => 'Se muestran como máximo 200 cuentas.';

  @override
  String appStatusLastAccess(String date) {
    return 'Último acceso: $date';
  }

  @override
  String get appStatusNeverAccessed => 'Sin accesos registrados';

  @override
  String get appStatusWriteTooltip => 'Escribirle por chat privado';

  @override
  String get moderationReactivate => 'Reactivar cuenta';

  @override
  String get moderationReactivateConfirm =>
      '¿Reactivar la cuenta del autor? Podrá volver a entrar con su contraseña; sus dispositivos se registrarán al volver a entrar.';

  @override
  String get moderationReactivated => 'Cuenta reactivada';

  @override
  String get continuityTitle => 'Continuidad';

  @override
  String continuityQuestion(String nombre, String temporada) {
    return '¿Seguirá $nombre en la temporada $temporada?';
  }

  @override
  String get continuityYes => 'Sí';

  @override
  String get continuityNo => 'No';

  @override
  String get continuityMaybe => 'Aún no lo sé';

  @override
  String get continuityNotAnswered => 'Sin contestar todavía';

  @override
  String continuityAnswered(String respuesta) {
    return 'Tu respuesta: $respuesta';
  }

  @override
  String continuityAnsweredOn(String respuesta, String fecha) {
    return 'Tu respuesta: $respuesta · $fecha';
  }

  @override
  String get continuityChangeHint =>
      'Puedes cambiarla hasta el cierre de la temporada.';

  @override
  String get continuitySaved => 'Respuesta guardada';

  @override
  String get continuityNothingToConfirm =>
      'No tienes nada que confirmar ahora.';

  @override
  String get rosterTitle => 'Reparto de equipos';

  @override
  String get rosterNoSeason =>
      'Todavía no hay una temporada disponible para esta acción. Créala antes en el panel.';

  @override
  String get rosterConfirm => 'Continuar';

  @override
  String get rosterSelectPlayers => 'Selecciona al menos un jugador.';

  @override
  String get rosterChooseTeam => 'Elige un equipo';

  @override
  String get rosterDorsalInvalid => 'El dorsal tiene que estar entre 0 y 99.';

  @override
  String rosterAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores asignados',
      one: '$count jugador asignado',
    );
    return '$_temp0';
  }

  @override
  String get rosterWarningsTitle => 'Avisos';

  @override
  String get rosterTrialDialogTitle => 'Jugadores de prueba';

  @override
  String rosterTrialDialogBody(String nombres) {
    return '$nombres pasarán a CONFIRMADO. ¿Continuar?';
  }

  @override
  String get rosterReturnTooltip => 'Devolver a la pretemporada';

  @override
  String rosterReturnConfirm(String nombre) {
    return '$nombre vuelve a la pretemporada de su categoría, sin dorsal. ¿Continuar?';
  }

  @override
  String rosterReturned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores devueltos a la pretemporada',
      one: '$count jugador devuelto a la pretemporada',
    );
    return '$_temp0';
  }

  @override
  String get rosterNewTeam => 'Nuevo equipo';

  @override
  String rosterNewTeamConfirm(String categoria) {
    return 'Se creará un equipo nuevo de $categoria con la siguiente letra libre. ¿Continuar?';
  }

  @override
  String rosterTeamCreated(String nombre) {
    return 'Equipo $nombre creado. Se activará al asignarle el primer jugador.';
  }

  @override
  String get rosterNoCategories =>
      'No hay categorías con equipos en la temporada activa.';

  @override
  String get rosterCategory => 'Categoría';

  @override
  String rosterToAssign(int count) {
    return 'Por asignar ($count)';
  }

  @override
  String rosterPreseasonTeam(String nombre) {
    return 'Equipo de pretemporada: $nombre';
  }

  @override
  String get rosterNothingToAssign =>
      'No queda ningún jugador por asignar en esta categoría.';

  @override
  String get rosterTargetTeam => 'Equipo destino';

  @override
  String rosterAssignButton(int count) {
    return 'Asignar seleccionados ($count)';
  }

  @override
  String get rosterTrialBadge => 'Prueba';

  @override
  String get rosterDorsalRepeated => 'Dorsal repetido';

  @override
  String get rosterTeamsTitle => 'Equipos';

  @override
  String get rosterNoTeams =>
      'Esta categoría no tiene equipos definitivos: crea el primero.';

  @override
  String get rosterActive => 'Activo';

  @override
  String get rosterInactive => 'Inactivo';

  @override
  String get rosterTeamEmpty => 'Sin jugadores todavía';

  @override
  String get trialTitle => 'Alta de prueba';

  @override
  String get trialIntro =>
      'Da de alta a un jugador de prueba en la temporada siguiente. Quedará en la categoría que le toque por edad, sin equipo, hasta que lo asignes en el reparto.';

  @override
  String get trialName => 'Nombre';

  @override
  String get trialSurname => 'Apellidos';

  @override
  String get trialBirthYear => 'Año de nacimiento';

  @override
  String get trialRequired => 'Campo obligatorio';

  @override
  String get trialYearInvalid => 'Escribe un año válido (por ejemplo, 2016)';

  @override
  String trialCreated(String categoria) {
    return 'Jugador de prueba creado en la categoría $categoria';
  }

  @override
  String get clubPageRoster => 'Reparto de equipos';

  @override
  String get clubPageRosterDesc => 'Asigna jugadores a su equipo definitivo';

  @override
  String get clubPageTrial => 'Alta de prueba';

  @override
  String get clubPageTrialDesc =>
      'Jugadores de prueba para la temporada siguiente';

  @override
  String playerPreseason(String categoria) {
    return '$categoria · Pretemporada';
  }

  @override
  String get invGuestsTitle => 'Jugadores de otros equipos';

  @override
  String invGuestsCounter(int count, int max) {
    return 'Invitados: $count de $max';
  }

  @override
  String get invGuestsHint =>
      'Coordinación tiene que aprobar a cada jugador invitado antes de que pueda jugar.';

  @override
  String get invAddButton => 'Añadir jugadores de otro equipo';

  @override
  String get invAddNeedsMatch =>
      'Elige primero el partido para poder invitar a jugadores de otros equipos.';

  @override
  String invMaxReached(int max) {
    return 'Máximo $max invitados por convocatoria';
  }

  @override
  String get invPickTeamPrompt => 'Elige un equipo';

  @override
  String get invNoTeams =>
      'Este equipo no puede invitar a jugadores de otros equipos.';

  @override
  String get invNoPlayers => 'No hay jugadores disponibles en este equipo.';

  @override
  String get invConfirmSelection => 'Listo';

  @override
  String get invBlockedDefault => 'Ya está invitado con otro equipo ese día';

  @override
  String get invRemoveGuest => 'Quitar';

  @override
  String invGuestTag(String team) {
    return 'Invitado · $team';
  }

  @override
  String get invGuestBadge => 'Invitado';

  @override
  String invGuestWith(String team) {
    return 'Invitado con $team';
  }

  @override
  String get invStateToSend => 'Se enviará a coordinación al guardar';

  @override
  String get invStatePendingCoordination => 'Pendiente de coordinación';

  @override
  String get invStatePendingCoach =>
      'Pendiente de que su entrenador lo autorice';

  @override
  String get invStateRejected => 'Rechazado por coordinación';

  @override
  String invRejectedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitados rechazados por coordinación',
      one: '1 invitado rechazado por coordinación',
    );
    return '$_temp0';
  }

  @override
  String get invGuestAbsentHint =>
      'La familia no puede ir. Quítalo y convoca a otro jugador.';

  @override
  String get invRemovedSnack => 'Jugador invitado quitado';

  @override
  String get invRemoveError => 'No se ha podido quitar al jugador.';

  @override
  String get invConflictTitle => 'No se puede continuar';

  @override
  String invConflictOwnPlayer(String player, String team) {
    return '$player ya va invitado con $team ese día, así que no puedes convocarlo con tu equipo.';
  }

  @override
  String invConflictAlreadyGuest(String player, String team) {
    return '$player ya está autorizado como invitado con $team ese día. Elige a otro jugador.';
  }

  @override
  String get invConflictOk => 'Entendido';

  @override
  String get clubPageInvitations => 'Invitaciones';

  @override
  String get clubPageInvitationsDesc =>
      'Jugadores de otros equipos pendientes de aprobar';

  @override
  String get invPageEmpty => 'No hay invitaciones pendientes';

  @override
  String invFromTo(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String invMatchLine(String date, String time, String rival) {
    return '$date · $time · contra $rival';
  }

  @override
  String invConvokedBy(String who) {
    return 'Convoca: $who';
  }

  @override
  String get invOverlapNone => 'Su equipo no juega ese día';

  @override
  String invOverlapYes(String matches) {
    return 'Su equipo juega ese día: $matches';
  }

  @override
  String get invOverlapConvoked => 'Su entrenador lo tiene convocado';

  @override
  String invOtherInvitation(String team) {
    return 'Tiene otra invitación ese día: $team';
  }

  @override
  String get invDeadlineExpired => 'Más de 12 h esperando a su entrenador';

  @override
  String get invApprove => 'Aprobar';

  @override
  String get invReject => 'Rechazar';

  @override
  String get invRelease => 'Liberar';

  @override
  String get invRejectTitle => 'Rechazar invitación';

  @override
  String get invRejectReasonLabel => 'Motivo (opcional)';

  @override
  String get invApprovedSnack => 'Invitación aprobada';

  @override
  String get invApprovedWaitingSnack =>
      'Aprobada: queda pendiente de su entrenador';

  @override
  String get invRejectedSnack => 'Invitación rechazada';

  @override
  String get invReleasedSnack => 'Jugador liberado';

  @override
  String get invActionError => 'No se ha podido completar la acción.';

  @override
  String invReleaseConfirmTitle(String player) {
    return '¿Liberar a $player?';
  }

  @override
  String invReleaseConfirmBody(String team) {
    return 'Se quitará de la convocatoria de $team ese día y se avisará a su entrenador.';
  }

  @override
  String invReleaseBanner(String player) {
    return '$player ha sido invitado por otro equipo el mismo día que juega el tuyo. Si puede jugar con ellos, libéralo de tu convocatoria.';
  }

  @override
  String invReleaseButton(String player) {
    return 'Liberar a $player';
  }

  @override
  String invReleasedOriginSnack(String player) {
    return '$player liberado';
  }

  @override
  String get invCannotGo => 'No puede ir';

  @override
  String get invCannotGoHint =>
      'El entrenador que lo convocó recibirá un aviso para convocar a otro jugador. El motivo solo lo verá él.';

  @override
  String get invCannotGoSnack => 'Aviso enviado al entrenador';
}

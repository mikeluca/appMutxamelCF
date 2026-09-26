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
  String get homeMatchUnavailable =>
      'No hay información disponible sobre el próximo partido.';

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
  String get settingsAboutApp => 'Acerca de appMTX';

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
  String get clubPageMyTeams => 'Mis equipos';

  @override
  String get clubPageMyTeamsDesc =>
      'Equipos vinculados a tu actividad en el club';

  @override
  String get clubPageMyMatches => 'Mis partidos';

  @override
  String get clubPageMyMatchesDesc => 'Próximos partidos y resultados';

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
      'Cada botón manda un aviso en directo a todos los usuarios de la app. Revisa bien antes de pulsar: no se puede deshacer.';

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
  String get liveGoalAuthorLabel => 'Autor del gol';

  @override
  String get liveEnterGoalAuthorError => 'Escribe el autor del gol.';

  @override
  String get liveGoalSentMessage => 'Gol enviado.';

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
  String get noTrainingsYet => 'Todavía no hay entrenamientos.';

  @override
  String get createFirstTrainingHint =>
      'Crea el primero pulsando el botón Nuevo.';

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
  String get callupPlayersTitle => 'Jugadores convocados';

  @override
  String get notModifiable => 'No modificables';

  @override
  String selectedCountLabel(int count) {
    return '$count seleccionados';
  }

  @override
  String get saveCallupButton => 'Guardar convocatoria';

  @override
  String get enterRivalError => 'Introduce el rival.';

  @override
  String get enterFieldError => 'Introduce el campo.';

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
}

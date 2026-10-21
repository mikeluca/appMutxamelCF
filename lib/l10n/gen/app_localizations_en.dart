// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navNews => 'News';

  @override
  String get navMatches => 'Matches';

  @override
  String get navStore => 'Store';

  @override
  String get navClub => 'Club';

  @override
  String get retry => 'Retry';

  @override
  String get linkOpenError => 'Could not open the link';

  @override
  String get homeNotificationsTooltip => 'Notifications';

  @override
  String get homeAreaClub => 'Club Area';

  @override
  String get homeLatestNews => 'Latest news';

  @override
  String get homeOurSponsors => 'Our sponsors';

  @override
  String get homeSponsorsHint =>
      'Tap the images to learn more about our sponsors.';

  @override
  String get homeNewsLoadError => 'The news could not be loaded.';

  @override
  String get homeNoNewsAvailable => 'No news available.';

  @override
  String get homeMatchLoadError => 'The match could not be loaded.';

  @override
  String get matchUpcoming => 'NEXT MATCH';

  @override
  String get matchUpcomingFirstTeam => 'NEXT MATCH FIRST TEAM';

  @override
  String get matchLastResult => 'LATEST RESULT';

  @override
  String get matchLastResultFirstTeam => 'LATEST RESULT FIRST TEAM';

  @override
  String get matchVs => 'VS';

  @override
  String get matchNoMatch => 'NO MATCH';

  @override
  String get matchNoMatchFirstTeam => 'NO MATCH FIRST TEAM';

  @override
  String get matchNoMatchThisRound => 'No match this matchday';

  @override
  String get matchTeamHasNoMatch => 'Has no match';

  @override
  String get matchTeamRests => 'Rest week';

  @override
  String get matchesCalendarTitle => 'CALENDAR';

  @override
  String get matchesCalendarSubtitle => 'Matches and results of our teams';

  @override
  String get matchesNoMatchesAvailable => 'No matches available.';

  @override
  String get matchesLoadError => 'The matches could not be loaded.';

  @override
  String get matchesNoCategory => 'No category';

  @override
  String get matchesResult => 'RESULT';

  @override
  String get matchesRestsThisRound => 'Resting this matchday';

  @override
  String get newsTitle => 'News';

  @override
  String get newsDetailTitle => 'News';

  @override
  String get newsLoadMore => 'Load more news';

  @override
  String get newsLoadMoreError => 'Could not load more news.';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeHeroKicker => 'MUTXAMEL CF';

  @override
  String get storeHeroTitle => 'Wear the colors';

  @override
  String get storeHeroSubtitle =>
      'The club\'s new collection is here. Choose your garment, select your sizes and send us your order.';

  @override
  String get storeProductShirtTitle => 'Official shirt';

  @override
  String get storeProductShirtDescription =>
      'The essence of Mutxamel CF, once again dressed in blue. Our home kit combines the club\'s tradition and identity with a modern design.';

  @override
  String get storeProductSecondKitTitle => 'Second kit';

  @override
  String get storeProductSecondKitDescription =>
      'Much more than a shirt. Our second kit, in pink, comes from a very special collaboration with the Spanish Association Against Cancer, bringing together sport, commitment and solidarity.';

  @override
  String get storeProductSecondKitNote =>
      'Collaboration with the Spanish Association Against Cancer';

  @override
  String get storeUnits => 'Units';

  @override
  String storeSizeUnitLabel(int n) {
    return 'Size for unit $n';
  }

  @override
  String get storeSizeGuideTitle => 'Size guide';

  @override
  String get storeSizeGuideHint =>
      'Measure a garment that fits you well and compare it with these approximate measurements.';

  @override
  String get storeSizeGuideSize => 'Size';

  @override
  String get storeSizeGuideChest => 'Chest (cm)';

  @override
  String get storeSizeGuideLength => 'Length (cm)';

  @override
  String get storeCustomerDataTitle => 'Your details';

  @override
  String get storeCustomerDataHint =>
      'We\'ll write to you to confirm availability and payment method.';

  @override
  String get storeFullNameLabel => 'Full name';

  @override
  String get storePhoneLabel => 'Phone (optional)';

  @override
  String get storeEmailLabel => 'Email';

  @override
  String get storePrivacyAcceptPrefix =>
      'I accept the processing of my data according to the ';

  @override
  String get storePrivacyPolicyLink => 'privacy policy';

  @override
  String get storeCreateOrderButton => 'PLACE ORDER';

  @override
  String get storeSendingButton => 'Sending...';

  @override
  String get storeErrorEnterName => 'Enter your full name.';

  @override
  String get storeErrorInvalidEmail => 'Enter a valid email.';

  @override
  String get storeErrorAcceptPrivacy => 'You must accept the privacy policy.';

  @override
  String storeErrorSelectSizeForProduct(String producto) {
    return 'Select the size for each unit of \"$producto\".';
  }

  @override
  String get storeErrorSelectAtLeastOne =>
      'Select at least one garment and its units.';

  @override
  String get storeOrderSentMessage =>
      'Order sent. We\'ll get in touch to confirm payment and pickup/delivery.';

  @override
  String get clubTitle => 'Club';

  @override
  String get clubFullName => 'Mutxamel Club de Fútbol';

  @override
  String get clubTagline => 'Where we are and how to contact the club';

  @override
  String get clubSettingsTooltip => 'Settings';

  @override
  String get clubWhereWeAre => 'Where we are';

  @override
  String get clubAddress => 'Address';

  @override
  String get clubWebsite => 'Website';

  @override
  String get clubPhone => 'Phone';

  @override
  String get clubEmail => 'Email';

  @override
  String get clubFollowUs => 'Follow us';

  @override
  String get clubViewOnGoogleMaps => 'View on Google Maps';

  @override
  String clubCopyright(int year) {
    return '© $year Mutxamel Club de Fútbol';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionApplication => 'Application';

  @override
  String get settingsNotifAnonymousHint =>
      'Turn these on even if you don\'t have a club account.';

  @override
  String get settingsNotifNewsAnon => 'News';

  @override
  String get settingsNotifNewsAnonSubtitle => 'Receive alerts for new news';

  @override
  String get settingsNotifResultsFirstTeam => 'Live results for the first team';

  @override
  String get settingsNotifResultsFirstTeamSubtitle =>
      'Live alerts for goals and results';

  @override
  String get settingsPreferencesLoadError => 'Could not load preferences';

  @override
  String get settingsPreferenceSaveError => 'Could not save the preference';

  @override
  String get settingsNotifGeneral => 'Notifications';

  @override
  String get settingsNotifGeneralSubtitleOn =>
      'Receive notifications from the club';

  @override
  String get settingsNotifGeneralSubtitleOff => 'Do not receive notifications';

  @override
  String get settingsNotifNews => 'News';

  @override
  String get settingsNotifNewsSubtitle => 'Receive alerts about new news';

  @override
  String get settingsNotifMessages => 'Messages';

  @override
  String get settingsNotifMessagesSubtitle => 'Receive alerts for new messages';

  @override
  String get settingsNotifResults => 'Results';

  @override
  String get settingsNotifResultsSubtitle => 'Receive alerts about results';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Choose how you want to see the app';

  @override
  String get settingsThemeAuto => 'Automatic';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageValencian => 'Valencian';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAboutApp => 'About Mutxamel CF';

  @override
  String get settingsAboutAppSubtitle => 'App information';

  @override
  String get loginHeading => 'Sign in to the Club Area';

  @override
  String get loginSubtitle => 'Enter your details to sign in';

  @override
  String get loginEmailRequired => 'Enter your email';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get activateAccountButton => 'Activate account';

  @override
  String get clubPageDefaultMember => 'Club member';

  @override
  String get clubPageSectionClub => 'Club';

  @override
  String get clubPageMyPlayers => 'My players';

  @override
  String get clubPageMyPlayersDesc => 'Players linked to your account';

  @override
  String get clubPageFees => 'Fees';

  @override
  String get clubPageFeesDesc => 'Your players\' fees and their status';

  @override
  String get clubPageFeesComingSoonDesc => 'Coming soon';

  @override
  String get clubPageFeesComingSoonMessage =>
      'We\'re working on this feature. It will be available soon.';

  @override
  String get clubPageMyTeams => 'My teams';

  @override
  String get clubPageMyTeamsDesc => 'Teams linked to your activity in the club';

  @override
  String get clubPageMyMatches => 'My matches';

  @override
  String get clubPageMyMatchesDesc => 'Upcoming matches and results';

  @override
  String get clubPageCalendar => 'Calendar';

  @override
  String get clubPageCalendarDesc => 'Trainings and matches for your teams';

  @override
  String get clubPageLiveMatch => 'Live match';

  @override
  String get clubPageLiveMatchDesc => 'Live alerts for the first team';

  @override
  String get clubPageCommunications => 'Communications';

  @override
  String get clubPageCommunicationsDesc => 'Club notices and communications';

  @override
  String get clubPageSectionAccount => 'My account';

  @override
  String get clubPageMyProfile => 'My profile';

  @override
  String get clubPageMyProfileDesc => 'Your personal details and settings';

  @override
  String get clubPageLogout => 'Sign out';

  @override
  String aboutVersionText(String version) {
    return 'Version $version';
  }

  @override
  String aboutVersionTextWithBuild(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutSectionClub => 'The club';

  @override
  String get aboutClubDescription =>
      'The official Mutxamel Club de Fútbol app keeps you up to date with call-ups, training sessions, results and club communications, wherever you are.';

  @override
  String get aboutSectionContact => 'Contact';

  @override
  String get aboutSectionLegal => 'Legal';

  @override
  String get aboutPrivacyPolicy => 'Privacy policy';

  @override
  String get aboutPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get aboutThirdPartyLicenses => 'Third-party licenses';

  @override
  String get aboutThirdPartyLicensesSubtitle =>
      'Open-source software used in the app';

  @override
  String get aboutAppTagline => 'Official app of Mutxamel Club de Fútbol';

  @override
  String get mailAppOpenError => 'The mail app could not be opened';

  @override
  String get profileLoadError => 'The profile could not be loaded.';

  @override
  String get defaultUser => 'User';

  @override
  String get profileSectionMyData => 'My details';

  @override
  String get profileSectionSettings => 'Settings';

  @override
  String get profileSettingsSubtitle => 'Notifications, appearance and app';

  @override
  String get profileRole => 'Role';

  @override
  String get roleFamiliar => 'Family member';

  @override
  String get roleJugador => 'Player';

  @override
  String get roleEntrenador => 'Coach';

  @override
  String get roleCoordinador => 'Coordinator';

  @override
  String get roleRetransmision => 'Broadcast';

  @override
  String get roleAdministrador => 'Administrator';

  @override
  String get roleSocio => 'Member';

  @override
  String get noPlayersLinked => 'You have no players linked to your account.';

  @override
  String playersLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked players',
      one: '$count linked player',
    );
    return '$_temp0';
  }

  @override
  String get fieldTeam => 'Team';

  @override
  String get fieldSport => 'Sport';

  @override
  String get sportFootball => 'Football';

  @override
  String get fieldDorsal => 'Number';

  @override
  String get fieldPosition => 'Position';

  @override
  String get allTeamsTitle => 'All teams';

  @override
  String get noTeamsAvailable => 'No teams available.';

  @override
  String get noTeamsAssociated =>
      'You have no teams associated with your account.';

  @override
  String get playerCountLabel => 'Number of players';

  @override
  String get teamsLoadError => 'The teams could not be loaded.';

  @override
  String get markAllReadTooltip => 'Mark all as read';

  @override
  String get notificationsLoadError => 'The notifications could not be loaded.';

  @override
  String get noNotifications => 'You have no notifications.';

  @override
  String get notificationsSignedOutMessage =>
      'Sign in to the Club Area to see your personal alerts (call-ups, messages…)';

  @override
  String get notificationsPublicHint =>
      'News and results alerts are turned on in Club → Settings';

  @override
  String get notificationsOpenSettings => 'Go to Settings';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get recoverTitle => 'Recover password';

  @override
  String get recoverSubtitle =>
      'We will email you a code so you can choose a new password.';

  @override
  String get recoverSendCode => 'Send code';

  @override
  String get recoverCodeSent =>
      'If the email has an account at the club, you will receive a code in a few minutes. Check your spam folder too.';

  @override
  String get recoverResetHeading => 'Choose your new password';

  @override
  String get recoverChangePassword => 'Change password';

  @override
  String get recoverResend => 'Resend code';

  @override
  String recoverResendIn(String time) {
    return 'Resend code ($time)';
  }

  @override
  String get recoverPasswordChanged => 'Password changed';

  @override
  String get recoverCodeInvalid => 'Wrong or expired code';

  @override
  String get markAllReadError =>
      'The notifications could not be marked as read.';

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday, $time';
  }

  @override
  String get noFeesRegistered =>
      'There are no fees registered for your players.';

  @override
  String playersCountSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '$count player',
    );
    return '$_temp0';
  }

  @override
  String feesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fees',
      one: '$count fee',
    );
    return '$_temp0';
  }

  @override
  String get feesAllPaidSuffix => ' · all paid';

  @override
  String feesPendingSuffix(int pending) {
    return ' · $pending pending';
  }

  @override
  String get noPaymentRegistered => 'This fee has no payments registered yet.';

  @override
  String get close => 'Close';

  @override
  String get noDateRegistered => 'No date registered';

  @override
  String get methodNotIndicated => 'Method not indicated';

  @override
  String get feeStatusOverdue => 'Overdue';

  @override
  String get feeStatusPaid => 'Paid';

  @override
  String get feeStatusPartial => 'Partial payment';

  @override
  String get feeStatusPending => 'Pending';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get chatNoMessages => 'No messages yet. Write the first one.';

  @override
  String get chatMessageHint => 'Write a message...';

  @override
  String get tabConversations => 'Conversations';

  @override
  String get tabReceived => 'Received';

  @override
  String get tabSent => 'Sent';

  @override
  String get newButton => 'New';

  @override
  String get noConversations => 'You have no conversations';

  @override
  String get noConversationsSubtitle => 'Your private chats will appear here.';

  @override
  String get noCommunicationsReceived => 'You have no communications';

  @override
  String get noCommunicationsReceivedSubtitleGlobal =>
      'The club\'s communications will appear here.';

  @override
  String get noCommunicationsReceivedSubtitleTeam =>
      'Your teams\' communications will appear here.';

  @override
  String get noCommunicationsSent => 'You haven\'t sent any communications';

  @override
  String get noCommunicationsSentSubtitle =>
      'The communications you send will appear here.';

  @override
  String get splashTagline => 'The official club app';

  @override
  String get activateHeading => 'Activate your account';

  @override
  String get activateSubtitle =>
      'Enter your email and the 6-digit code the club sent you by email, and choose your password.';

  @override
  String get codeLabel => '6-digit code';

  @override
  String get codeRequired => 'Enter the code we sent you by email';

  @override
  String get codeLength => 'The code must be 6 digits long';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get passwordChooseRequired => 'Choose a password';

  @override
  String get passwordMinLength => 'Must be at least 8 characters';

  @override
  String get repeatPasswordLabel => 'Repeat the password';

  @override
  String get passwordsDontMatch => 'The passwords don\'t match';

  @override
  String get activateAndEnterButton => 'Activate and sign in';

  @override
  String get commDetailTitle => 'Communication';

  @override
  String get commLoadError => 'The communication could not be loaded.';

  @override
  String get commNewTitle => 'New communication';

  @override
  String get commSelectRecipientError => 'Select who you want to write to.';

  @override
  String get commSelectTeamError => 'Select at least one team.';

  @override
  String get commSelectCategoryError => 'Select at least one category.';

  @override
  String get commSelectRecipientPersonError => 'Select a recipient.';

  @override
  String get commCreatedSuccess => 'Communication created successfully.';

  @override
  String commCreateError(String error) {
    return 'The communication could not be created: $error';
  }

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'Write the title';

  @override
  String get titleRequired => 'The title is required.';

  @override
  String get messageLabel => 'Message';

  @override
  String get messageHint => 'Write the content of the communication';

  @override
  String get messageRequired => 'The message is required.';

  @override
  String get recipientsTitle => 'Recipients';

  @override
  String get teamsSegment => 'Teams';

  @override
  String get categoriesSegment => 'Categories';

  @override
  String get privateSegment => 'Private';

  @override
  String get noRecipientsAvailable =>
      'You have no available recipients to write a communication.';

  @override
  String get chooseTeamsHint => 'Choose one or more teams.';

  @override
  String get chooseCategoriesHint => 'Choose one or more categories.';

  @override
  String get choosePrivateRecipientHint =>
      'Choose a single person; the message will be private to them only.';

  @override
  String get searchRecipientLabel => 'Search recipient';

  @override
  String get searchRecipientHint => 'First or last name';

  @override
  String get noRecipientsFound => 'No recipients found.';

  @override
  String get savingButton => 'Saving...';

  @override
  String get saveCommunicationButton => 'Save communication';

  @override
  String get recipientsLoadError => 'The recipients could not be loaded.';

  @override
  String get liveMatchTitle => 'Live match';

  @override
  String get liveMatchWarning =>
      'Each button sends a live alert to every app user. You can undo the last alert for 2 minutes; after that it cannot be undone.';

  @override
  String get liveEventKickoff => 'Kick-off';

  @override
  String get liveConfirmKickoff => 'Announce that the match is starting?';

  @override
  String get liveEventGoalAgainst => 'Goal against';

  @override
  String get liveConfirmGoalAgainst => 'Announce a goal against?';

  @override
  String get liveEventHalftime => 'Half-time';

  @override
  String get liveConfirmHalftime => 'Announce half-time?';

  @override
  String get liveEventSecondHalf => 'Second half';

  @override
  String get liveConfirmSecondHalf => 'Announce the start of the second half?';

  @override
  String get liveEventFulltime => 'Full-time';

  @override
  String get liveConfirmFulltime => 'Announce that the match has finished?';

  @override
  String get liveLineupButton => 'Line-up';

  @override
  String get liveGoalForButton => 'Goal for';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get liveStartingLineupLabel => 'Starting line-up';

  @override
  String get liveSubstitutesLabel => 'Substitutes';

  @override
  String get liveFillLineupError =>
      'Fill in the starting line-up and the substitutes.';

  @override
  String get liveLineupSentMessage => 'Line-up sent.';

  @override
  String get liveEnterGoalAuthorError => 'Enter the goal scorer.';

  @override
  String get liveGoalSentMessage => 'Goal sent.';

  @override
  String get liveNoMatchesToday => 'There is no First Team match today';

  @override
  String get liveChooseMatch => 'Choose the match you are going to broadcast';

  @override
  String get liveMatchHome => 'Home';

  @override
  String get liveMatchAway => 'Away';

  @override
  String get liveChangeMatch => 'Change match';

  @override
  String get liveLoadError => 'Today\'s matches could not be loaded.';

  @override
  String get livePhaseNotStarted => 'Not started';

  @override
  String get livePhaseFirstHalf => '1st half';

  @override
  String get livePhaseHalftime => 'Half-time';

  @override
  String get livePhaseSecondHalf => '2nd half';

  @override
  String get livePhaseFinished => 'Full time';

  @override
  String get liveScorers => 'Scorers';

  @override
  String get liveNoScorersYet => 'No goals scored yet';

  @override
  String get liveOwnGoalShort => 'o.g. (opponent\'s own goal)';

  @override
  String get liveGoalAuthorTitle => 'Who scored?';

  @override
  String get liveGoalOther => 'Other…';

  @override
  String get liveGoalOtherLabel => 'Goal scorer (max. 60 characters)';

  @override
  String get liveGoalOwnGoal => 'Own goal (opponent)';

  @override
  String get liveNoPlayersToPick =>
      'There are no players in the list: choose \"Other\" or \"Own goal\".';

  @override
  String liveUndoButton(String time) {
    return 'Undo ($time)';
  }

  @override
  String liveUndoLast(String event) {
    return 'Last alert: $event';
  }

  @override
  String get liveUndoFulltimeTitle => 'Undo full time?';

  @override
  String get liveUndoFulltimeMessage =>
      'Full time will be cancelled and the saved result will go back to how it was.';

  @override
  String get liveUndoneMessage => 'Alert undone.';

  @override
  String get liveUndoConfirm => 'Undo';

  @override
  String get liveEventAlert => 'Alert';

  @override
  String liveNotificationSentMessage(String titulo) {
    return '\"$titulo\" alert sent.';
  }

  @override
  String liveSendError(String error) {
    return 'The alert could not be sent: $error';
  }

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get trainingsTitle => 'Training sessions';

  @override
  String get newMasculineButton => 'New';

  @override
  String get trainingsNextBadge => 'NEXT TRAINING';

  @override
  String get noUpcomingTrainings =>
      'There are no trainings in the next two weeks.';

  @override
  String get pastTrainingsButton => 'Past trainings';

  @override
  String get pastTrainingsTitle => 'Past trainings';

  @override
  String get noPastTrainings => 'There are no previous trainings yet.';

  @override
  String get trainingsLoadError => 'The training sessions could not be loaded.';

  @override
  String get editTrainingTitle => 'Edit training session';

  @override
  String get newTrainingTitle => 'New training session';

  @override
  String get noPlayersForTraining =>
      'There are no players to register the training session.';

  @override
  String get trainingDateFutureError =>
      'The training date cannot be later than today.';

  @override
  String get trainingUpdatedSuccess => 'Training session updated successfully.';

  @override
  String get trainingSavedSuccess => 'Training session saved successfully.';

  @override
  String trainingSaveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String get trainingDateLabel => 'Training date';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceHint => 'Mark each player\'s status';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusAbsent => 'Absent';

  @override
  String get attendanceStatusLate => 'Late';

  @override
  String get attendanceStatusJustifiedAbsence => 'Justified absence';

  @override
  String get attendanceStatusMisconduct => 'Misconduct';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get saveTrainingButton => 'Save training session';

  @override
  String get noPlayersAvailableForTeam => 'No players available for this team.';

  @override
  String get playersLoadError => 'The players could not be loaded.';

  @override
  String get callupsTitle => 'Call-ups';

  @override
  String get noCallupsYet => 'There are no call-ups yet.';

  @override
  String get createFirstCallupHint =>
      'Create the first one using the New button.';

  @override
  String get callupsLoadError => 'The call-ups could not be loaded.';

  @override
  String get editCallupTitle => 'Edit call-up';

  @override
  String get newCallupTitle => 'New call-up';

  @override
  String get rivalLabel => 'Opponent';

  @override
  String get fieldLabelCampo => 'Ground';

  @override
  String get matchTimeLabel => 'Match time';

  @override
  String get callupTimeLabel => 'Call-up time';

  @override
  String get callupPlaceLabel => 'Call-up place';

  @override
  String get matchDateLabel => 'Match date';

  @override
  String get selectMatchLabel => 'Match';

  @override
  String get selectMatchHint => 'Select a match';

  @override
  String get selectMatchError => 'Select a match.';

  @override
  String get noMatchesAvailableForCallup =>
      'There are no matches available to create a call-up. Create a match first.';

  @override
  String get callupPlayersTitle => 'Called-up players';

  @override
  String selectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get saveCallupButton => 'Save call-up';

  @override
  String get enterCallupPlaceError => 'Enter the call-up place.';

  @override
  String get selectAtLeastOnePlayerError => 'Select at least one player.';

  @override
  String get callupUpdatedSuccess => 'Call-up updated successfully.';

  @override
  String get callupCreatedSuccess => 'Call-up created successfully.';

  @override
  String callupUpdateError(String error) {
    return 'The call-up could not be updated: $error';
  }

  @override
  String callupCreateError(String error) {
    return 'The call-up could not be created: $error';
  }

  @override
  String get teamManagementTitle => 'Team management';

  @override
  String get trainingsDesc =>
      'Create and view training sessions and attendance';

  @override
  String get callupsDesc => 'Create and view match call-ups';

  @override
  String get playersMenuLabel => 'Players';

  @override
  String get playersMenuDesc => 'View the team\'s players';

  @override
  String get noPlayersInTeam => 'There are no players in this team.';

  @override
  String get matchResultPending => 'Result pending';

  @override
  String get viewStandings => 'View standings';

  @override
  String seasonTitle(String name) {
    return 'Season $name';
  }

  @override
  String get seasonTitleNoName => 'Season';

  @override
  String get seasonNoData => 'There is no data for this season yet';

  @override
  String get seasonGoals => 'Goals';

  @override
  String get seasonAssists => 'Assists';

  @override
  String get seasonYellows => 'Yellows';

  @override
  String get seasonReds => 'Reds';

  @override
  String get seasonCallupsCard => 'Call-ups';

  @override
  String get seasonTrainingsTitle => 'Training';

  @override
  String seasonTrainingsLine(int attended, int total, int percent) {
    return '$attended of $total ($percent %)';
  }

  @override
  String get seasonTrainingsNone => 'No training sessions yet';

  @override
  String seasonAbsences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absences',
      one: '1 absence',
    );
    return '$_temp0';
  }

  @override
  String seasonExcused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excused',
      one: '1 excused',
    );
    return '$_temp0';
  }

  @override
  String seasonShortTrainings(int attended, int total) {
    return 'Training $attended/$total';
  }

  @override
  String seasonShortGoals(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals goals',
      one: '1 goal',
    );
    return '$_temp0';
  }

  @override
  String get clubPageMyCard => 'My player card';

  @override
  String get clubPageMyCardDesc => 'Your player details';

  @override
  String callupMatchLine(String date) {
    return 'Match: $date';
  }

  @override
  String callupMeetingLine(String time, String place) {
    return 'Meeting: $time · $place';
  }

  @override
  String callupReasonShown(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get clubPageMyStandings => 'My standings';

  @override
  String get clubPageMyStandingsDesc => 'Your teams\' standings';

  @override
  String get allStandingsTitle => 'Standings';

  @override
  String get clubPageAllStandingsDesc => 'All teams\' standings';

  @override
  String get standingsNone => 'No standings yet';

  @override
  String standingsSummary(int pos, int pts, int round) {
    return '#$pos · $pts pts · MD$round';
  }

  @override
  String standingsSummaryNoRound(int pos, int pts) {
    return '#$pos · $pts pts';
  }

  @override
  String standingsUpdated(int round, String date) {
    return 'Matchday $round · updated on $date';
  }

  @override
  String standingsUpdatedNoRound(String date) {
    return 'Updated on $date';
  }

  @override
  String get standingsEmpty => 'Standings not available yet';

  @override
  String get standingsLoadError => 'The standings could not be loaded.';

  @override
  String get standingsColPos => 'Pos';

  @override
  String get standingsColTeam => 'Team';

  @override
  String get standingsColPlayed => 'P';

  @override
  String get standingsColPoints => 'Pts';

  @override
  String get standingsColWon => 'W';

  @override
  String get standingsColDrawn => 'D';

  @override
  String get standingsColLost => 'L';

  @override
  String get standingsColGoalsFor => 'GF';

  @override
  String get standingsColGoalsAgainst => 'GA';

  @override
  String get familiesTitle => 'Family members';

  @override
  String get phoneAppOpenError => 'The phone app could not be opened';

  @override
  String get whatsappOpenError => 'WhatsApp could not be opened';

  @override
  String get noFamiliesRegistered =>
      'This player has no family members registered';

  @override
  String get callButton => 'Call';

  @override
  String get emailButton => 'Email';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get allMatchesTitle => 'All matches';

  @override
  String get matchDeletedSuccess => 'Match deleted successfully.';

  @override
  String get matchCreatedSuccess => 'Match created successfully.';

  @override
  String get matchUpdatedSuccess => 'Match updated successfully.';

  @override
  String get teamMatchesLoadError =>
      'This team\'s matches could not be loaded.';

  @override
  String get addMatchButton => 'Add match';

  @override
  String get teamNoMatchesAvailable => 'No matches available for this team.';

  @override
  String get editMatchTooltip => 'Edit match';

  @override
  String get matchTypeLiga => 'League';

  @override
  String get matchTypeAmistoso => 'Friendly';

  @override
  String get matchTypeCopa => 'Cup';

  @override
  String get matchTypeTorneo => 'Tournament';

  @override
  String get rivalRequiredError => 'The opponent is required.';

  @override
  String get deleteMatchTitle => 'Delete match';

  @override
  String get deleteMatchConfirm =>
      'Delete this match? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get editMatchTitle => 'Edit match';

  @override
  String get newMatchTitle => 'New match';

  @override
  String get matchTypeLabel => 'Match type';

  @override
  String get noDateSelected => 'No date';

  @override
  String get dateLabel => 'Date';

  @override
  String get hourLabelHint => 'Time (e.g. 18:00)';

  @override
  String get save => 'Save';

  @override
  String get calendarAllTeamsTitle => 'Teams calendar';

  @override
  String get calendarLoadError => 'The calendar could not be loaded.';

  @override
  String get calendarNoItems => 'There are no trainings or matches scheduled.';

  @override
  String get calendarSessionLabel => 'Training';

  @override
  String get calendarMatchLabel => 'Match';

  @override
  String get calendarCancelledBadge => 'Cancelled';

  @override
  String get calendarJustifiedBadge => 'Justified';

  @override
  String get calendarCalledUpBadge => 'Called up';

  @override
  String get calendarNotCalledUpBadge => 'Not called up';

  @override
  String get matchResultLabel => 'Result';

  @override
  String get calendarJustifyAbsenceButton => 'Justify absence';

  @override
  String get calendarEditJustificationButton => 'Edit justification';

  @override
  String get calendarJustifyAbsenceTitle => 'Justify training absence';

  @override
  String get calendarEditJustificationTitle => 'Edit absence justification';

  @override
  String get calendarJustifyAbsenceHint =>
      'Enter the reason for the absence (optional). If you had already justified this session, the reason will be updated.';

  @override
  String get calendarEditJustificationHint =>
      'You have already justified this absence. You can edit the reason if you want.';

  @override
  String get calendarJustifyAbsenceReasonLabel => 'Reason';

  @override
  String get calendarJustifyAbsenceSubmit => 'Send';

  @override
  String get calendarJustifyAbsenceSuccess => 'Absence justified successfully.';

  @override
  String get calendarManagementTitle => 'Calendar';

  @override
  String get calendarManagementDesc =>
      'Weekly schedule, sessions and matches for the team';

  @override
  String get calendarManagementLoadError =>
      'The team\'s calendar could not be loaded.';

  @override
  String get weeklyScheduleTitle => 'Weekly training schedule';

  @override
  String get weeklyScheduleEmpty =>
      'No weekly schedule has been set up for this team yet.';

  @override
  String get weeklyScheduleAddButton => 'Add schedule';

  @override
  String get weeklyScheduleEditTooltip => 'Edit schedule';

  @override
  String get weeklyScheduleDeactivateTooltip => 'Deactivate schedule';

  @override
  String get weeklyScheduleDeactivateConfirmTitle => 'Deactivate schedule';

  @override
  String get weeklyScheduleDeactivateConfirmMessage =>
      'This schedule will be deactivated and its future, still-scheduled sessions will be cancelled. Continue?';

  @override
  String get weeklyScheduleDeactivatedSuccess => 'Schedule deactivated.';

  @override
  String weeklyScheduleDeactivateError(String error) {
    return 'The schedule could not be deactivated: $error';
  }

  @override
  String get weeklyScheduleSavedSuccess => 'Schedule saved successfully.';

  @override
  String get weeklyScheduleFormTitleNew => 'New schedule';

  @override
  String get weeklyScheduleFormTitleEdit => 'Edit schedule';

  @override
  String get weeklyScheduleDayLabel => 'Day of the week';

  @override
  String get weeklyScheduleTimeLabel => 'Time';

  @override
  String get weeklySchedulePlaceLabel => 'Place';

  @override
  String get weeklyScheduleActiveLabel => 'Active';

  @override
  String get weeklyScheduleInactiveBadge => 'Inactive';

  @override
  String get upcomingItemsTitle => 'Upcoming sessions and matches';

  @override
  String get upcomingItemsEmpty =>
      'There are no trainings or matches scheduled for the coming weeks.';

  @override
  String get sessionEditTooltip => 'Edit session';

  @override
  String get sessionEditFormTitle => 'Edit training session';

  @override
  String get sessionEditSavedSuccess => 'Session updated successfully.';

  @override
  String get sessionCancelTooltip => 'Cancel session';

  @override
  String get sessionCancelConfirmTitle => 'Cancel session';

  @override
  String get sessionCancelConfirmMessage =>
      'Players and family members will be notified. This action cannot be undone. Enter the reason for the cancellation:';

  @override
  String get cancelReasonLabel => 'Reason';

  @override
  String get cancelReasonRequiredError => 'The reason is required';

  @override
  String get sessionCancelledSuccess => 'Session cancelled.';

  @override
  String sessionCancelError(String error) {
    return 'The session could not be cancelled: $error';
  }

  @override
  String get matchCancelTooltip => 'Cancel match';

  @override
  String get matchCancelConfirmTitle => 'Cancel match';

  @override
  String get matchCancelConfirmMessage =>
      'This match will be cancelled. This action cannot be undone. Continue?';

  @override
  String get matchCancelledSuccess => 'Match cancelled.';

  @override
  String matchCancelError(String error) {
    return 'The match could not be cancelled: $error';
  }

  @override
  String get viewJustificationsTooltip => 'View justifications';

  @override
  String get viewJustificationsTitle => 'Absence justifications';

  @override
  String get viewJustificationsEmpty =>
      'There are no justifications for this session yet.';

  @override
  String get viewJustificationsLoadError =>
      'The justifications could not be loaded.';

  @override
  String get justificationNoReasonGiven => 'No reason given';

  @override
  String get matchResultFormTitle => 'Match result';

  @override
  String get matchResultGoalsForLabel => 'Goals for';

  @override
  String get matchResultGoalsAgainstLabel => 'Goals against';

  @override
  String get matchResultGoalsHelp => 'Mutxamel goals – opponent goals';

  @override
  String get matchResultPlayersTitle => 'Player statistics';

  @override
  String get matchResultGoalsShort => 'Goals';

  @override
  String get matchResultAssistsShort => 'Assists';

  @override
  String get matchResultYellowCardsShort => 'Yellow cards';

  @override
  String get matchResultRedCardShort => 'Red card';

  @override
  String get matchResultSaveButton => 'Save result';

  @override
  String get matchResultSavedSuccess => 'Result saved successfully.';

  @override
  String matchResultSaveError(String error) {
    return 'The result could not be saved: $error';
  }

  @override
  String get matchResultLoadError => 'The match data could not be loaded.';

  @override
  String get matchEnterResultTooltip => 'Enter result';

  @override
  String get matchEditResultTooltip => 'Edit result';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsDeleteAccount => 'Delete my account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Deletes your account and personal data';

  @override
  String get deleteAccountDialogTitle => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'Your email, password, club access, devices and notifications will be deleted. Club records (player, family member or coaching staff) are kept, and messages you sent will be kept without your name. This cannot be undone.';

  @override
  String get deleteAccountPasswordLabel => 'Enter your password to confirm';

  @override
  String get deleteAccountPasswordRequired => 'Enter your password';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get deleteAccountWrongPassword => 'The password is incorrect.';

  @override
  String get deleteAccountTooManyAttempts =>
      'Too many failed attempts. Try again in a few minutes.';

  @override
  String get deleteAccountError =>
      'The account could not be deleted. Please try again.';

  @override
  String get deleteAccountDone => 'Your account has been deleted.';

  @override
  String get reportAction => 'Report';

  @override
  String get reportDialogTitle => 'Report message';

  @override
  String get reportDialogBody =>
      'The club will be notified so they can review this message. You can add a reason (optional).';

  @override
  String get reportReasonHint => 'Reason (optional)';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Report sent. The club will review it.';

  @override
  String get reportError => 'The report could not be sent. Please try again.';

  @override
  String get matchAbsenceJustifyButton => 'Justify absence';

  @override
  String get matchAbsenceJustifyTitle => 'Justify absence from the match';

  @override
  String get matchAbsenceEditTitle => 'Edit absence reason';

  @override
  String get matchAbsenceHint =>
      'Let the coaching staff know the player can\'t play this match. You can change the reason or withdraw it until the call-up time.';

  @override
  String get matchAbsenceReasonLabel => 'Reason';

  @override
  String get matchAbsenceReasonRequired =>
      'Enter the reason (at least 3 characters)';

  @override
  String get matchAbsenceBadge => 'Absence justified';

  @override
  String get matchAbsenceEditButton => 'Edit reason';

  @override
  String get matchAbsenceWithdrawButton => 'Withdraw';

  @override
  String get matchAbsenceWithdrawTitle => 'Withdraw the absence?';

  @override
  String get matchAbsenceWithdrawBody =>
      'The coaching staff will know the player can play. The player can be called up again, but won\'t be added to the call-up automatically.';

  @override
  String get matchAbsenceWithdrawConfirm => 'Withdraw';

  @override
  String matchAbsenceDeadlineClosed(String deadline) {
    return 'Deadline passed ($deadline)';
  }

  @override
  String get matchAbsenceJustifiedSnack => 'Absence justified';

  @override
  String get matchAbsenceWithdrawnSnack => 'Absence withdrawn';

  @override
  String get matchAbsenceError => 'Could not save. Please try again.';

  @override
  String get callupDetailTitle => 'Call-up';

  @override
  String callupPlayersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players called up',
      one: '1 player called up',
    );
    return '$_temp0';
  }

  @override
  String callupAbsentBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count called-up players have justified their absence',
      one: '1 called-up player has justified their absence',
    );
    return '$_temp0';
  }

  @override
  String callupAbsentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count justified absences',
      one: '1 justified absence',
    );
    return '$_temp0';
  }

  @override
  String seasonMatchAbsencesLine(int count) {
    return 'Matches with justified absence: $count';
  }

  @override
  String get callupUnavailable => 'This call-up is no longer available';

  @override
  String get connectionError =>
      'Could not connect. Check your connection and try again.';

  @override
  String get teamCardsTitle => 'Cards';

  @override
  String get teamCardsDesc =>
      'Players\' yellow and red cards and possible suspensions';

  @override
  String get cardsNoPlayers => 'There are no players in this team';

  @override
  String get cardsStatusOneAway => 'One away from suspension';

  @override
  String get cardsStatusSanction => 'Possible suspension';

  @override
  String get cardsFooterNote =>
      'For guidance only: the FFCV decides on suspensions.';

  @override
  String get yellowCardsLabel => 'Yellow';

  @override
  String get redCardsLabel => 'Red';

  @override
  String get teamStatsTitle => 'Statistics';

  @override
  String get teamStatsDesc => 'Top scorers, assists, attendance and results';

  @override
  String get statsPlayedShort => 'P';

  @override
  String get statsWonShort => 'W';

  @override
  String get statsDrawnShort => 'D';

  @override
  String get statsLostShort => 'L';

  @override
  String get statsGoalsForShort => 'GF';

  @override
  String get statsGoalsAgainstShort => 'GA';

  @override
  String get statsAttendanceAverage => 'Average attendance';

  @override
  String get statsTopScorers => 'Top scorers';

  @override
  String get statsTopAssisters => 'Top assisters';

  @override
  String get statsTrainingAttendance => 'Training attendance';

  @override
  String get statsNoData => 'No data yet';

  @override
  String statsGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals',
      one: '$count goal',
    );
    return '$_temp0';
  }

  @override
  String statsAssistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assists',
      one: '$count assist',
    );
    return '$_temp0';
  }

  @override
  String statsAttendedOf(int asistidos, int total) {
    return '$asistidos of $total';
  }

  @override
  String statsPercent(int percent) {
    return '$percent%';
  }

  @override
  String get trainingListNotReviewed => 'Attendance not reviewed';

  @override
  String get trainingNotFound => 'This training is no longer available';

  @override
  String get clubPageWeekend => 'Weekend';

  @override
  String get clubPageWeekendDesc => 'Call-ups, results and rounds to review';

  @override
  String get clubPagePlayerTracking => 'Player follow-up';

  @override
  String get clubPagePlayerTrackingDesc =>
      'Absences and misconduct in training';

  @override
  String get weekendPrevious => 'Previous weekend';

  @override
  String get weekendNext => 'Next weekend';

  @override
  String get weekendNoCallup => 'No call-up';

  @override
  String get weekendPendingResults => 'Pending results';

  @override
  String get weekendResting => 'Resting';

  @override
  String get weekendNoMatch => 'No match or rest';

  @override
  String get weekendNoMatchNote => 'Is the round missing from the import?';

  @override
  String get weekendAllClear => 'All up to date';

  @override
  String weekendLastImport(String fecha) {
    return 'Last FFCV import: $fecha';
  }

  @override
  String weekendDelayDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String weekendRound(int jornada) {
    return 'Round $jornada';
  }

  @override
  String trackingPeriodDays(int count) {
    return 'Last $count days';
  }

  @override
  String trackingExcusedChip(int count) {
    return '$count excused';
  }

  @override
  String trackingLateChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late arrivals',
      one: '$count late arrival',
    );
    return '$_temp0';
  }

  @override
  String get noPermission => 'You don\'t have permission';

  @override
  String get callupMatchUnavailable => 'This match no longer accepts a call-up';

  @override
  String statsUnreviewedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count trainings without a reviewed list do not count towards attendance',
      one:
          '$count training without a reviewed list does not count towards attendance',
    );
    return '$_temp0';
  }

  @override
  String get trackingPeriodSeason => 'Season';

  @override
  String get trackingAllTeams => 'All teams';

  @override
  String trackingFaultsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absences',
      one: '$count absence',
    );
    return '$_temp0';
  }

  @override
  String trackingMisconductChip(int count) {
    return '$count misconduct';
  }

  @override
  String trackingLastIncident(String fecha) {
    return 'Last incident: $fecha';
  }

  @override
  String get trackingEmpty => 'No player reaches the thresholds in this period';

  @override
  String get trackingCoordinationOnly => 'Data for coordination only';

  @override
  String get trackingNoIncidents => 'No incidents in this period';

  @override
  String get clubPageModeration => 'Moderation';

  @override
  String get clubPageModerationDesc => 'Messages reported by users';

  @override
  String get clubPagePendingAccounts => 'Pending accounts';

  @override
  String get clubPagePendingAccountsDesc =>
      'Invitations that have not been activated yet';

  @override
  String get moderationTabPending => 'Pending';

  @override
  String get moderationTabResolved => 'Resolved';

  @override
  String get moderationEmptyPending => 'There are no pending reports';

  @override
  String get moderationEmptyResolved => 'There are no resolved reports yet';

  @override
  String moderationAuthor(String nombre) {
    return 'Author: $nombre';
  }

  @override
  String moderationReporter(String nombre) {
    return 'Reported by: $nombre';
  }

  @override
  String moderationReason(String motivo) {
    return 'Reason: $motivo';
  }

  @override
  String get moderationNoReason => 'no reason given';

  @override
  String moderationMessageDate(String fecha) {
    return 'Message: $fecha';
  }

  @override
  String moderationReportDate(String fecha) {
    return 'Reported: $fecha';
  }

  @override
  String moderationAuthorReports(int count) {
    return 'The author has $count reports';
  }

  @override
  String get moderationShowMore => 'Show more';

  @override
  String get moderationShowLess => 'Show less';

  @override
  String get moderationDiscard => 'Dismiss';

  @override
  String get moderationDeleteMessage => 'Delete message';

  @override
  String get moderationDeactivateAuthor => 'Deactivate author';

  @override
  String get moderationNoteLabel => 'Note (optional)';

  @override
  String get moderationDiscardConfirm =>
      'Dismiss this report? The message stays as it is.';

  @override
  String get moderationDeleteConfirm => 'Delete the message for all users?';

  @override
  String get moderationDeactivateConfirm =>
      'Deactivate the author\'s account? They will no longer be able to use the app.';

  @override
  String get moderationAlsoDeleteMessage => 'Also delete the message';

  @override
  String get moderationConfirm => 'Confirm';

  @override
  String get moderationResolvedDone => 'Report resolved';

  @override
  String get moderationStateDiscarded => 'Dismissed';

  @override
  String get moderationStateMessageDeleted => 'Message deleted';

  @override
  String get moderationStateAuthorDeactivated => 'Author deactivated';

  @override
  String moderationResolvedBy(String nombre, String fecha) {
    return 'Resolved by $nombre on $fecha';
  }

  @override
  String get pendingAccountsEmpty => 'There are no pending accounts';

  @override
  String get pendingAccountsSearch => 'Search by name or email';

  @override
  String pendingAccountsInvited(String fecha) {
    return 'Invited on $fecha';
  }

  @override
  String get pendingAccountsCodeExpired => 'Code expired';

  @override
  String get pendingAccountsResend => 'Resend activation';

  @override
  String pendingAccountsResendConfirm(String email) {
    return 'Resend the activation invitation to $email?';
  }

  @override
  String pendingAccountsResent(String email) {
    return 'Invitation resent to $email';
  }
}

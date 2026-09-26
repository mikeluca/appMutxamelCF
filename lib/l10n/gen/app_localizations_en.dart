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
  String get homeMatchUnavailable =>
      'No information available about the next match.';

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
  String get settingsAboutApp => 'About appMTX';

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
  String get clubPageMyTeams => 'My teams';

  @override
  String get clubPageMyTeamsDesc => 'Teams linked to your activity in the club';

  @override
  String get clubPageMyMatches => 'My matches';

  @override
  String get clubPageMyMatchesDesc => 'Upcoming matches and results';

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
      'Each button sends a live alert to every app user. Check carefully before pressing: it cannot be undone.';

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
  String get liveGoalAuthorLabel => 'Goal scorer';

  @override
  String get liveEnterGoalAuthorError => 'Enter the goal scorer.';

  @override
  String get liveGoalSentMessage => 'Goal sent.';

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
  String get noTrainingsYet => 'There are no training sessions yet.';

  @override
  String get createFirstTrainingHint =>
      'Create the first one using the New button.';

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
  String get callupPlayersTitle => 'Called-up players';

  @override
  String get notModifiable => 'Not editable';

  @override
  String selectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get saveCallupButton => 'Save call-up';

  @override
  String get enterRivalError => 'Enter the opponent.';

  @override
  String get enterFieldError => 'Enter the ground.';

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
  String get teamsPageTitle => 'Teams';

  @override
  String get ourTeamsTitle => 'Our teams';

  @override
  String get teamsSubtitle =>
      'View the squads and information for each of the club\'s teams.';

  @override
  String get noPlayersInTeam => 'There are no players in this team.';

  @override
  String get squadTitle => 'Squad';

  @override
  String get staffTitle => 'Coaching staff';

  @override
  String get staffLoadError => 'The coaching staff could not be loaded.';

  @override
  String get noStaffAvailableForTeam =>
      'No coaching staff available for this team.';

  @override
  String get squadLoadError => 'The squad could not be loaded.';

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
  String get resultFormatError =>
      'The result must be in the format N-N (e.g. 2-1).';

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
  String get resultLabelHint => 'Result (e.g. 2-1)';

  @override
  String get save => 'Save';
}

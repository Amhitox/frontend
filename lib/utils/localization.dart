import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Common strings
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get emails => _localizedValues[locale.languageCode]!['emails']!;
  String get errorLoadingAnalytics => _localizedValues[locale.languageCode]!['errorLoadingAnalytics']!;
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get tasks => _localizedValues[locale.languageCode]!['tasks']!;
  String get completeTask => _localizedValues[locale.languageCode]!['completeTask']!;
  String get meetings => _localizedValues[locale.languageCode]!['meetings']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get analytics => _localizedValues[locale.languageCode]!['analytics']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get editProfile =>
      _localizedValues[locale.languageCode]!['editProfile']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get changed => _localizedValues[locale.languageCode]!['changed']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get errorOccurred => _localizedValues[locale.languageCode]!['errorOccurred']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get inProgress =>
      _localizedValues[locale.languageCode]!['inProgress']!;
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get tomorrow => _localizedValues[locale.languageCode]!['tomorrow']!;
  String get yesterday => _localizedValues[locale.languageCode]!['yesterday']!;
  String get thisWeek => _localizedValues[locale.languageCode]!['thisWeek']!;
  String get nextWeek => _localizedValues[locale.languageCode]!['nextWeek']!;
  String get thisMonth => _localizedValues[locale.languageCode]!['thisMonth']!;
  String get nextMonth => _localizedValues[locale.languageCode]!['nextMonth']!;
  String get priority => _localizedValues[locale.languageCode]!['priority']!;
  String get high => _localizedValues[locale.languageCode]!['high']!;
  String get medium => _localizedValues[locale.languageCode]!['medium']!;
  String get low => _localizedValues[locale.languageCode]!['low']!;
  String get dueDate => _localizedValues[locale.languageCode]!['dueDate']!;
  String get description =>
      _localizedValues[locale.languageCode]!['description']!;
  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get phone => _localizedValues[locale.languageCode]!['phone']!;
  String get location => _localizedValues[locale.languageCode]!['location']!;
  String get time => _localizedValues[locale.languageCode]!['time']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get duration => _localizedValues[locale.languageCode]!['duration']!;
  String get attendees => _localizedValues[locale.languageCode]!['attendees']!;
  String get notes => _localizedValues[locale.languageCode]!['notes']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get filter => _localizedValues[locale.languageCode]!['filter']!;
  String get sort => _localizedValues[locale.languageCode]!['sort']!;
  String get refresh => _localizedValues[locale.languageCode]!['refresh']!;
  String get sync => _localizedValues[locale.languageCode]!['sync']!;
  String get syncStatus =>
      _localizedValues[locale.languageCode]!['syncStatus']!;
  String get synced => _localizedValues[locale.languageCode]!['synced']!;
  String get syncing => _localizedValues[locale.languageCode]!['syncing']!;
  String get syncFailed =>
      _localizedValues[locale.languageCode]!['syncFailed']!;
  String get noData => _localizedValues[locale.languageCode]!['noData']!;
  String get noTasks => _localizedValues[locale.languageCode]!['noTasks']!;
  String get areYouSureYouWantToDelete =>
      _localizedValues[locale.languageCode]!['areYouSureYouWantToDelete']!;
  String get noMeetings =>
      _localizedValues[locale.languageCode]!['noMeetings']!;
  String get addTask => _localizedValues[locale.languageCode]!['addTask']!;
  String get addMeeting =>
      _localizedValues[locale.languageCode]!['addMeeting']!;
  String get editTask => _localizedValues[locale.languageCode]!['editTask']!;
  String get todayProgress =>
      _localizedValues[locale.languageCode]!['todayProgress']!;
  String get editMeeting =>
      _localizedValues[locale.languageCode]!['editMeeting']!;
  String get deleteTask =>
      _localizedValues[locale.languageCode]!['deleteTask']!;
  String get deleteMeeting =>
      _localizedValues[locale.languageCode]!['deleteMeeting']!;
  String get taskCompleted =>
      _localizedValues[locale.languageCode]!['taskCompleted']!;
  String get taskInProgress =>
      _localizedValues[locale.languageCode]!['taskInProgress']!;
  String get taskPending =>
      _localizedValues[locale.languageCode]!['taskPending']!;
  String get meetingScheduled =>
      _localizedValues[locale.languageCode]!['meetingScheduled']!;
  String get meetingCompleted =>
      _localizedValues[locale.languageCode]!['meetingCompleted']!;
  String get meetingCancelled =>
      _localizedValues[locale.languageCode]!['meetingCancelled']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get goodMorning =>
      _localizedValues[locale.languageCode]!['goodMorning']!;
  String get goodAfternoon =>
      _localizedValues[locale.languageCode]!['goodAfternoon']!;
  String get goodEvening =>
      _localizedValues[locale.languageCode]!['goodEvening']!;
  String get goodNight => _localizedValues[locale.languageCode]!['goodNight']!;
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get overview => _localizedValues[locale.languageCode]!['overview']!;
  String get statistics =>
      _localizedValues[locale.languageCode]!['statistics']!;
  String get recentActivity =>
      _localizedValues[locale.languageCode]!['recentActivity']!;
  String get upcoming => _localizedValues[locale.languageCode]!['upcoming']!;
  String get overdue => _localizedValues[locale.languageCode]!['overdue']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get preferences =>
      _localizedValues[locale.languageCode]!['preferences']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get privacy => _localizedValues[locale.languageCode]!['privacy']!;
  String get security => _localizedValues[locale.languageCode]!['security']!;
  String get help => _localizedValues[locale.languageCode]!['help']!;
  String get support => _localizedValues[locale.languageCode]!['support']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get version => _localizedValues[locale.languageCode]!['version']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get signOut => _localizedValues[locale.languageCode]!['signOut']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get light => _localizedValues[locale.languageCode]!['light']!;
  String get dark => _localizedValues[locale.languageCode]!['dark']!;
  String get system => _localizedValues[locale.languageCode]!['system']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get french => _localizedValues[locale.languageCode]!['french']!;
  String get voice => _localizedValues[locale.languageCode]!['voice']!;
  String get female => _localizedValues[locale.languageCode]!['female']!;
  String get male => _localizedValues[locale.languageCode]!['male']!;
  String get pushNotifications =>
      _localizedValues[locale.languageCode]!['pushNotifications']!;
  String get emailNotifications =>
      _localizedValues[locale.languageCode]!['emailNotifications']!;
  String get smsNotifications =>
      _localizedValues[locale.languageCode]!['smsNotifications']!;
  String get calendar => _localizedValues[locale.languageCode]!['calendar']!;
  String get schedule => _localizedValues[locale.languageCode]!['schedule']!;
  String get agenda => _localizedValues[locale.languageCode]!['agenda']!;
  String get week => _localizedValues[locale.languageCode]!['week']!;
  String get month => _localizedValues[locale.languageCode]!['month']!;
  String get year => _localizedValues[locale.languageCode]!['year']!;
  String get day => _localizedValues[locale.languageCode]!['day']!;
  String get monday => _localizedValues[locale.languageCode]!['monday']!;
  String get tuesday => _localizedValues[locale.languageCode]!['tuesday']!;
  String get wednesday => _localizedValues[locale.languageCode]!['wednesday']!;
  String get thursday => _localizedValues[locale.languageCode]!['thursday']!;
  String get friday => _localizedValues[locale.languageCode]!['friday']!;
  String get saturday => _localizedValues[locale.languageCode]!['saturday']!;
  String get sunday => _localizedValues[locale.languageCode]!['sunday']!;
  String get january => _localizedValues[locale.languageCode]!['january']!;
  String get february => _localizedValues[locale.languageCode]!['february']!;
  String get march => _localizedValues[locale.languageCode]!['march']!;
  String get april => _localizedValues[locale.languageCode]!['april']!;
  String get may => _localizedValues[locale.languageCode]!['may']!;
  String get june => _localizedValues[locale.languageCode]!['june']!;
  String get july => _localizedValues[locale.languageCode]!['july']!;
  String get august => _localizedValues[locale.languageCode]!['august']!;
  String get september => _localizedValues[locale.languageCode]!['september']!;
  String get october => _localizedValues[locale.languageCode]!['october']!;
  String get november => _localizedValues[locale.languageCode]!['november']!;
  String get december => _localizedValues[locale.languageCode]!['december']!;
  String get readyToAssistYou =>
      _localizedValues[locale.languageCode]!['readyToAssistYou']!;
  String get emailManagement =>
      _localizedValues[locale.languageCode]!['emailManagement']!;
  String get registrationEmail =>
      _localizedValues[locale.languageCode]!['registrationEmail']!;
  String get fixed => _localizedValues[locale.languageCode]!['fixed']!;
  String get workEmail => _localizedValues[locale.languageCode]!['workEmail']!;
  String get supportFeedback =>
      _localizedValues[locale.languageCode]!['supportFeedback']!;
  String get rateUs => _localizedValues[locale.languageCode]!['rateUs']!;
  String get loveTheApp =>
      _localizedValues[locale.languageCode]!['loveTheApp']!;
  String get shareApp => _localizedValues[locale.languageCode]!['shareApp']!;
  String get tellYourFriends =>
      _localizedValues[locale.languageCode]!['tellYourFriends']!;
  String get helpSupport =>
      _localizedValues[locale.languageCode]!['helpSupport']!;
  String get getHelp => _localizedValues[locale.languageCode]!['getHelp']!;
  String get legalInformation =>
      _localizedValues[locale.languageCode]!['legalInformation']!;
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]!['privacyPolicy']!;
  String get howWeProtectYourData =>
      _localizedValues[locale.languageCode]!['howWeProtectYourData']!;
  String get termsOfService =>
      _localizedValues[locale.languageCode]!['termsOfService']!;
  String get termsAndConditions =>
      _localizedValues[locale.languageCode]!['termsAndConditions']!;
  String get appVersion =>
      _localizedValues[locale.languageCode]!['appVersion']!;
  String get version123 =>
      _localizedValues[locale.languageCode]!['version123']!;
  String get appPreferences =>
      _localizedValues[locale.languageCode]!['appPreferences']!;
  String get selectDate =>
      _localizedValues[locale.languageCode]!['selectDate']!;
  String get pleaseEnterATaskTitle =>
      _localizedValues[locale.languageCode]!['pleaseEnterATaskTitle']!;
  String get pleaseEnterACustomCategoryName =>
      _localizedValues[locale.languageCode]!['pleaseEnterACustomCategoryName']!;
  String get taskDateCannotBeInThePast =>
      _localizedValues[locale.languageCode]!['taskDateCannotBeInThePast']!;
  String get taskTimeMustBeAtLeastOneHourFromNow =>
      _localizedValues[locale
          .languageCode]!['taskTimeMustBeAtLeastOneHourFromNow']!;
  String get taskUpdatedSuccessfully =>
      _localizedValues[locale.languageCode]!['taskUpdatedSuccessfully']!;
  String get taskCreatedSuccessfully =>
      _localizedValues[locale.languageCode]!['taskCreatedSuccessfully']!;
  String get newTask => _localizedValues[locale.languageCode]!['newTask']!;
  String get taskTitle => _localizedValues[locale.languageCode]!['taskTitle']!;
  String get whatNeedsToBeDone =>
      _localizedValues[locale.languageCode]!['whatNeedsToBeDone']!;
  String get addDetailsAboutThisTaskOptional =>
      _localizedValues[locale
          .languageCode]!['addDetailsAboutThisTaskOptional']!;
  String get customCategory =>
      _localizedValues[locale.languageCode]!['customCategory']!;
  String get enterYourCustomCategoryName =>
      _localizedValues[locale.languageCode]!['enterYourCustomCategoryName']!;
  String get dueDateTime =>
      _localizedValues[locale.languageCode]!['dueDateTime']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get work => _localizedValues[locale.languageCode]!['work']!;
  String get personal => _localizedValues[locale.languageCode]!['personal']!;
  String get finance => _localizedValues[locale.languageCode]!['finance']!;
  String get health => _localizedValues[locale.languageCode]!['health']!;
  String get education => _localizedValues[locale.languageCode]!['education']!;
  String get other => _localizedValues[locale.languageCode]!['other']!;
  String get updateTask =>
      _localizedValues[locale.languageCode]!['updateTask']!;
  String get createTask =>
      _localizedValues[locale.languageCode]!['createTask']!;
  String get legalPrivacyPolicy =>
      _localizedValues[locale.languageCode]!['legal_privacy_policy']!;
  String get legalTermsOfService =>
      _localizedValues[locale.languageCode]!['legal_terms_of_service']!;
  String get howCanWeHelp =>
      _localizedValues[locale.languageCode]!['howCanWeHelp']!;
  String get supportDescription =>
      _localizedValues[locale.languageCode]!['supportDescription']!;
  String get emailUs => _localizedValues[locale.languageCode]!['emailUs']!;

  // Notifications
  String get markAllAsRead => _localizedValues[locale.languageCode]!['markAllAsRead']!;
  String get clearAll => _localizedValues[locale.languageCode]!['clearAll']!;
  String get unread => _localizedValues[locale.languageCode]!['unread']!;
  String get noNotifications => _localizedValues[locale.languageCode]!['noNotifications']!;
  String get caughtUp => _localizedValues[locale.languageCode]!['caughtUp']!;
  String get playSummary => _localizedValues[locale.languageCode]!['playSummary']!;
  String get confirmMarkAllRead => _localizedValues[locale.languageCode]!['confirmMarkAllRead']!;
  String get confirmClearAll => _localizedValues[locale.languageCode]!['confirmClearAll']!;
  String get clearAllNotifications => _localizedValues[locale.languageCode]!['clearAllNotifications']!;
  
  // Analytics
  String get analyticsDashboard => _localizedValues[locale.languageCode]!['analyticsDashboard']!;
  String get analyticsSubtitle => _localizedValues[locale.languageCode]!['analyticsSubtitle']!;
  String get productivityScore => _localizedValues[locale.languageCode]!['productivityScore']!;
  String get emailsSent => _localizedValues[locale.languageCode]!['emailsSent']!;
  String get emailsReceived => _localizedValues[locale.languageCode]!['emailsReceived']!;
  String get tasksCompleted => _localizedValues[locale.languageCode]!['tasksCompleted']!;
  String get meetingDuration => _localizedValues[locale.languageCode]!['meetingDuration']!;
  String get focusTime => _localizedValues[locale.languageCode]!['focusTime']!;
  String get keyInsights => _localizedValues[locale.languageCode]!['keyInsights']!;
  String get activityTrends => _localizedValues[locale.languageCode]!['activityTrends']!;
  String get score => _localizedValues[locale.languageCode]!['score']!;
  String get savedTo => _localizedValues[locale.languageCode]!['savedTo']!;
  String get failedToGenerate => _localizedValues[locale.languageCode]!['failedToGenerate']!;
  String get thisYear => _localizedValues[locale.languageCode]!['thisYear']!;
  String get open => _localizedValues[locale.languageCode]!['open']!;
  String get shareAnalyticsMessage => _localizedValues[locale.languageCode]!['shareAnalyticsMessage']!;
  String get failedToGenerateShare => _localizedValues[locale.languageCode]!['failedToGenerateShare']!;
  String get avgResponseTime => _localizedValues[locale.languageCode]!['avgResponseTime']!;
  String get peakActivity => _localizedValues[locale.languageCode]!['peakActivity']!;
  String get noActivityData => _localizedValues[locale.languageCode]!['noActivityData']!;
  String get mostProductiveDay => _localizedValues[locale.languageCode]!['mostProductiveDay']!;
  String get consistentActivity => _localizedValues[locale.languageCode]!['consistentActivity']!;
  String get responsePattern => _localizedValues[locale.languageCode]!['responsePattern']!;
  String get excellentResponse => _localizedValues[locale.languageCode]!['excellentResponse']!;
  String get improvedResponse => _localizedValues[locale.languageCode]!['improvedResponse']!;
  String get automateResponses => _localizedValues[locale.languageCode]!['automateResponses']!;
  String get suggestion => _localizedValues[locale.languageCode]!['suggestion']!;
  String get shareTips => _localizedValues[locale.languageCode]!['shareTips']!;
  String get timeBlocking => _localizedValues[locale.languageCode]!['timeBlocking']!;

  // Auth
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get signup => _localizedValues[locale.languageCode]!['signup']!;
  String get or => _localizedValues[locale.languageCode]!['or']!;
  String get backToLogin => _localizedValues[locale.languageCode]!['backToLogin']!;
  String get submit => _localizedValues[locale.languageCode]!['submit']!;
  String get welcomeBack => _localizedValues[locale.languageCode]!['welcomeBack']!;
  String get rememberMe => _localizedValues[locale.languageCode]!['rememberMe']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get continueWithGoogle => _localizedValues[locale.languageCode]!['continueWithGoogle']!;
  String get continueWithApple => _localizedValues[locale.languageCode]!['continueWithApple']!;
  String get createAccount => _localizedValues[locale.languageCode]!['createAccount']!;
  String get joinUs => _localizedValues[locale.languageCode]!['joinUs']!;
  String get dateOfBirth => _localizedValues[locale.languageCode]!['dateOfBirth']!;
  String get confirmPassword => _localizedValues[locale.languageCode]!['confirmPassword']!;
  String get agreeToTerms => _localizedValues[locale.languageCode]!['agreeToTerms']!;
  String get enterEmail => _localizedValues[locale.languageCode]!['enterEmail']!;
  String get sendResetLink => _localizedValues[locale.languageCode]!['sendResetLink']!;
  String get emailSentSuccess => _localizedValues[locale.languageCode]!['emailSentSuccess']!;
  String get resendEmail => _localizedValues[locale.languageCode]!['resendEmail']!;
  String get needHelp => _localizedValues[locale.languageCode]!['needHelp']!;
  String get contactSupport => _localizedValues[locale.languageCode]!['contactSupport']!;
  String get createNewPassword => _localizedValues[locale.languageCode]!['createNewPassword']!;
  String get resetPasswordTitle => _localizedValues[locale.languageCode]!['resetPasswordTitle']!;
  String get passwordResetSuccess => _localizedValues[locale.languageCode]!['passwordResetSuccess']!;
  String get passwordResetFailed => _localizedValues[locale.languageCode]!['passwordResetFailed']!;
  String get verifyingEmail => _localizedValues[locale.languageCode]!['verifyingEmail']!;
  String get emailVerified => _localizedValues[locale.languageCode]!['emailVerified']!;
  String get verificationFailed => _localizedValues[locale.languageCode]!['verificationFailed']!;
  String get invalidLink => _localizedValues[locale.languageCode]!['invalidLink']!;
  String get goToLogin => _localizedValues[locale.languageCode]!['goToLogin']!;
  String get passwordMatchError => _localizedValues[locale.languageCode]!['passwordMatchError']!;
  String get passwordLengthError => _localizedValues[locale.languageCode]!['passwordLengthError']!;
  String get passwordRequired => _localizedValues[locale.languageCode]!['passwordRequired']!;
  String get enterPassword => _localizedValues[locale.languageCode]!['enterPassword']!;
  String get getStartedNow => _localizedValues[locale.languageCode]!['getStartedNow']!;
  String get loginSubtitle => _localizedValues[locale.languageCode]!['loginSubtitle']!;
  String get dataProcessingAgreement => _localizedValues[locale.languageCode]!['dataProcessingAgreement']!;
  String get and => _localizedValues[locale.languageCode]!['and']!;
  String get bySigningUpAgreeTo => _localizedValues[locale.languageCode]!['bySigningUpAgreeTo']!;
  String get enterFirstName => _localizedValues[locale.languageCode]!['enterFirstName']!;
  String get enterLastName => _localizedValues[locale.languageCode]!['enterLastName']!;
  String get enterPhone => _localizedValues[locale.languageCode]!['enterPhone']!;
  String get confirmPasswordHint => _localizedValues[locale.languageCode]!['confirmPasswordHint']!;
  String get checkYourEmail => _localizedValues[locale.languageCode]!['checkYourEmail']!;
  String get recoveryLinkSent => _localizedValues[locale.languageCode]!['recoveryLinkSent']!;
  String get dontWorryReset => _localizedValues[locale.languageCode]!['dontWorryReset']!;
  String get sendLinkReset => _localizedValues[locale.languageCode]!['sendLinkReset']!;
  String get sentLinkTo => _localizedValues[locale.languageCode]!['sentLinkTo']!;
  String get checkEmailInstruction => _localizedValues[locale.languageCode]!['checkEmailInstruction']!;
  String get resendIn => _localizedValues[locale.languageCode]!['resendIn']!;
  String get didntReceiveResend => _localizedValues[locale.languageCode]!['didntReceiveResend']!;
  String get newPasswordHint => _localizedValues[locale.languageCode]!['newPasswordHint']!;
  String get confirmNewPasswordHint => _localizedValues[locale.languageCode]!['confirmNewPasswordHint']!;
  String get verificationFailedMessage => _localizedValues[locale.languageCode]!['verificationFailedMessage']!;
  String get createSecurePassword => _localizedValues[locale.languageCode]!['createSecurePassword']!;
  String get passwordRequirements => _localizedValues[locale.languageCode]!['passwordRequirements']!;
  String get emailVerification => _localizedValues[locale.languageCode]!['emailVerification']!;

  // Email
  String get inbox => _localizedValues[locale.languageCode]!['inbox']!;
  String get sent => _localizedValues[locale.languageCode]!['sent']!;
  String get drafts => _localizedValues[locale.languageCode]!['drafts']!;
  String get important => _localizedValues[locale.languageCode]!['important']!;
  String get trash => _localizedValues[locale.languageCode]!['trash']!;
  String get searchMail => _localizedValues[locale.languageCode]!['searchMail']!;
  String get messages => _localizedValues[locale.languageCode]!['messages']!;
  String get markAsRead => _localizedValues[locale.languageCode]!['markAsRead']!;
  String get markAsUnread => _localizedValues[locale.languageCode]!['markAsUnread']!;
  String get emptyInbox => _localizedValues[locale.languageCode]!['emptyInbox']!;
  String get emptyDrafts => _localizedValues[locale.languageCode]!['emptyDrafts']!;
  String get emptySent => _localizedValues[locale.languageCode]!['emptySent']!;
  String get emptyTrash => _localizedValues[locale.languageCode]!['emptyTrash']!;
  String get emptySpam => _localizedValues[locale.languageCode]!['emptySpam']!;
  String get emptyImportant => _localizedValues[locale.languageCode]!['emptyImportant']!;
  String get emptyOther => _localizedValues[locale.languageCode]!['emptyOther']!;
  String get emptyPrimary => _localizedValues[locale.languageCode]!['emptyPrimary']!;
  String get connectGmail => _localizedValues[locale.languageCode]!['connectGmail']!;
  String get connectDescription => _localizedValues[locale.languageCode]!['connectDescription']!;
  String get deleteEmail => _localizedValues[locale.languageCode]!['deleteEmail']!;
  String get confirmDeleteEmail => _localizedValues[locale.languageCode]!['confirmDeleteEmail']!;
  String get connectEmailAccount => _localizedValues[locale.languageCode]!['connectEmailAccount']!;
  String get noEmailsFound => _localizedValues[locale.languageCode]!['noEmailsFound']!;
  String get somethingWentWrong => _localizedValues[locale.languageCode]!['somethingWentWrong']!;

  String get reply => _localizedValues[locale.languageCode]!['reply']!;
  String get replyAll => _localizedValues[locale.languageCode]!['replyAll']!;
  String get forward => _localizedValues[locale.languageCode]!['forward']!;
  String get vip => _localizedValues[locale.languageCode]!['vip']!;
  String get addedToVIP => _localizedValues[locale.languageCode]!['addedToVIP']!;
  String get removedFromVIP => _localizedValues[locale.languageCode]!['removedFromVIP']!;
  String get vipStatusUpdateFailed => _localizedValues[locale.languageCode]!['vipStatusUpdateFailed']!;
  String get loadingEmail => _localizedValues[locale.languageCode]!['loadingEmail']!;
  String get failedToLoadEmail => _localizedValues[locale.languageCode]!['failedToLoadEmail']!;
  String get noContentAvailable => _localizedValues[locale.languageCode]!['noContentAvailable']!;
  String get priorityAudioSummary => _localizedValues[locale.languageCode]!['priorityAudioSummary']!;
  String get primary => _localizedValues[locale.languageCode]!['primary']!;
  String get spam => _localizedValues[locale.languageCode]!['spam']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get emailDeletedSuccess => _localizedValues[locale.languageCode]!['emailDeletedSuccess']!;
  String get emailDeleteFailed => _localizedValues[locale.languageCode]!['emailDeleteFailed']!;
  String get emailDeleteError => _localizedValues[locale.languageCode]!['emailDeleteError']!;
  String get tapToPlay => _localizedValues[locale.languageCode]!['tapToPlay']!;

  String get compose => _localizedValues[locale.languageCode]!['compose']!;
  String get editMessage => _localizedValues[locale.languageCode]!['editMessage']!;
  String get to => _localizedValues[locale.languageCode]!['to']!;
  String get cc => _localizedValues[locale.languageCode]!['cc']!;
  String get bcc => _localizedValues[locale.languageCode]!['bcc']!;
  String get subject => _localizedValues[locale.languageCode]!['subject']!;
  String get send => _localizedValues[locale.languageCode]!['send']!;
  String get sending => _localizedValues[locale.languageCode]!['sending']!;
  String get attachments => _localizedValues[locale.languageCode]!['attachments']!;
  String get messageSent => _localizedValues[locale.languageCode]!['messageSent']!;
  String get draftSaved => _localizedValues[locale.languageCode]!['draftSaved']!;
  String get draftEmpty => _localizedValues[locale.languageCode]!['draftEmpty']!;
  String get attachmentRemoved => _localizedValues[locale.languageCode]!['attachmentRemoved']!;
  String get fileTooLarge => _localizedValues[locale.languageCode]!['fileTooLarge']!;
  String get voiceRefinementLimit => _localizedValues[locale.languageCode]!['voiceRefinementLimit']!;
  String get listeningTapStop => _localizedValues[locale.languageCode]!['listeningTapStop']!;
  String get transcribing => _localizedValues[locale.languageCode]!['transcribing']!;
  String get noVoiceDetected => _localizedValues[locale.languageCode]!['noVoiceDetected']!;
  String get refinementFailed => _localizedValues[locale.languageCode]!['refinementFailed']!;
  String get emailRefined => _localizedValues[locale.languageCode]!['emailRefined']!;
  String get pleaseAddRecipient => _localizedValues[locale.languageCode]!['pleaseAddRecipient']!;
  String get pleaseAddSubject => _localizedValues[locale.languageCode]!['pleaseAddSubject']!;
  String get unknownError => _localizedValues[locale.languageCode]!['unknownError']!;
  String get draftSaveFailed => _localizedValues[locale.languageCode]!['draftSaveFailed']!;
  String get filesAdded => _localizedValues[locale.languageCode]!['filesAdded']!;
  String get imagesAdded => _localizedValues[locale.languageCode]!['imagesAdded']!;
  String get errorPickingFiles => _localizedValues[locale.languageCode]!['errorPickingFiles']!;
  String get errorPickingImages => _localizedValues[locale.languageCode]!['errorPickingImages']!;

  String get errorSendingEmail => _localizedValues[locale.languageCode]!['errorSendingEmail']!;
  String get errorSavingDraft => _localizedValues[locale.languageCode]!['errorSavingDraft']!;
  String get errorSummarizing => _localizedValues[locale.languageCode]!['errorSummarizing']!;
  String get confirmDeleteEmailPermanent => _localizedValues[locale.languageCode]!['confirmDeleteEmailPermanent']!;
  String get unknownSender => _localizedValues[locale.languageCode]!['unknownSender']!;
  String get unknown => _localizedValues[locale.languageCode]!['unknown']!;
  String get wrote => _localizedValues[locale.languageCode]!['wrote']!;
  String get forwardedMessage => _localizedValues[locale.languageCode]!['forwardedMessage']!;
  String get from => _localizedValues[locale.languageCode]!['from']!;
  
  // Calendar
  String get meetingAddedSuccess => _localizedValues[locale.languageCode]!['meetingAddedSuccess']!;
  String get meetingAddFailed => _localizedValues[locale.languageCode]!['meetingAddFailed']!;
  String get meetingUpdatedSuccess => _localizedValues[locale.languageCode]!['meetingUpdatedSuccess']!;
  String get meetingUpdateFailed => _localizedValues[locale.languageCode]!['meetingUpdateFailed']!;
  String get meetingDeletedSuccess => _localizedValues[locale.languageCode]!['meetingDeletedSuccess']!;
  String get meetingDeleteFailed => _localizedValues[locale.languageCode]!['meetingDeleteFailed']!;
  String get confirmDeleteMeeting => _localizedValues[locale.languageCode]!['confirmDeleteMeeting']!;
  String get online => _localizedValues[locale.languageCode]!['online']!;
  String get onsite => _localizedValues[locale.languageCode]!['onsite']!;
  String get newSchedule => _localizedValues[locale.languageCode]!['newSchedule']!;
  String get meetingTitle => _localizedValues[locale.languageCode]!['meetingTitle']!;
  String get meetingTitleHint => _localizedValues[locale.languageCode]!['meetingTitleHint']!;
  String get meetingDescriptionHint => _localizedValues[locale.languageCode]!['meetingDescriptionHint']!;
  String get attendeesHint => _localizedValues[locale.languageCode]!['attendeesHint']!;
  String get dateTime => _localizedValues[locale.languageCode]!['dateTime']!;
  String get startTime => _localizedValues[locale.languageCode]!['startTime']!;
  String get endTime => _localizedValues[locale.languageCode]!['endTime']!;
  String get meetingType => _localizedValues[locale.languageCode]!['meetingType']!;
  String get addSchedule => _localizedValues[locale.languageCode]!['addSchedule']!;
  String get updateMeeting => _localizedValues[locale.languageCode]!['updateMeeting']!;
  String get pleaseEnterTitle => _localizedValues[locale.languageCode]!['pleaseEnterTitle']!;
  
  // Priority Emails
  String get priorityEmails => _localizedValues[locale.languageCode]!['priorityEmails']!;
  String get addVipEmail => _localizedValues[locale.languageCode]!['addVipEmail']!;
  String get vipEmailDescription => _localizedValues[locale.languageCode]!['vipEmailDescription']!;
  String get emailPlaceholder => _localizedValues[locale.languageCode]!['emailPlaceholder']!;
  String get pleaseEnterEmail => _localizedValues[locale.languageCode]!['pleaseEnterEmail']!;
  String get invalidEmailAddress => _localizedValues[locale.languageCode]!['invalidEmailAddress']!;
  String get failedToAddEmail => _localizedValues[locale.languageCode]!['failedToAddEmail']!;
  String get unexpectedError => _localizedValues[locale.languageCode]!['unexpectedError']!;
  String get failedToRemoveEmail => _localizedValues[locale.languageCode]!['failedToRemoveEmail']!;
  String get noVipEmails => _localizedValues[locale.languageCode]!['noVipEmails']!;
  String get quota => _localizedValues[locale.languageCode]!['quota']!;
  String get used => _localizedValues[locale.languageCode]!['used']!;
  
  // Security
  String get secure => _localizedValues[locale.languageCode]!['secure']!;
  String get accountSecure => _localizedValues[locale.languageCode]!['accountSecure']!;
  String get lastSecurityCheck => _localizedValues[locale.languageCode]!['lastSecurityCheck']!;
  String get authentication => _localizedValues[locale.languageCode]!['authentication']!;
  String get privacyLock => _localizedValues[locale.languageCode]!['privacyLock']!;
  String get securityActivity => _localizedValues[locale.languageCode]!['securityActivity']!;
  String get updateAccountPassword => _localizedValues[locale.languageCode]!['updateAccountPassword']!;
  String get viewLoginActivity => _localizedValues[locale.languageCode]!['viewLoginActivity']!;
  String get loginHistory => _localizedValues[locale.languageCode]!['loginHistory']!;
  String get activeSessions => _localizedValues[locale.languageCode]!['activeSessions']!;
  String get manageActiveSessions => _localizedValues[locale.languageCode]!['manageActiveSessions']!;
  String get securityAlerts => _localizedValues[locale.languageCode]!['securityAlerts']!;
  String get configureSecurityNotifications => _localizedValues[locale.languageCode]!['configureSecurityNotifications']!;
  String get dataExport => _localizedValues[locale.languageCode]!['dataExport']!;
  String get downloadAccountData => _localizedValues[locale.languageCode]!['downloadAccountData']!;
  String get passwordUpdatedSuccess => _localizedValues[locale.languageCode]!['passwordUpdatedSuccess']!;
  String get autoLockTimer => _localizedValues[locale.languageCode]!['autoLockTimer']!;
  String get minute => _localizedValues[locale.languageCode]!['minute']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get never => _localizedValues[locale.languageCode]!['never']!;
  String get currentDevice => _localizedValues[locale.languageCode]!['currentDevice']!;
  String get lastActive => _localizedValues[locale.languageCode]!['lastActive']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get signOutOthers => _localizedValues[locale.languageCode]!['signOutOthers']!;
  String get allSessionsSignedOut => _localizedValues[locale.languageCode]!['allSessionsSignedOut']!;
  String get configureSecurityDescription => _localizedValues[locale.languageCode]!['configureSecurityDescription']!;
  String get downloadDataDescription => _localizedValues[locale.languageCode]!['downloadDataDescription']!;
  String get dataExportStarted => _localizedValues[locale.languageCode]!['dataExportStarted']!;
  String get export => _localizedValues[locale.languageCode]!['export']!;
  String get configure => _localizedValues[locale.languageCode]!['configure']!;
  
  // Onboarding
  String get skip => _localizedValues[locale.languageCode]!['skip']!;
  String get voiceControl => _localizedValues[locale.languageCode]!['voiceControl']!;
  String get speakNaturally => _localizedValues[locale.languageCode]!['speakNaturally']!;
  String get voiceControlDesc => _localizedValues[locale.languageCode]!['voiceControlDesc']!;
  String get smartInsights => _localizedValues[locale.languageCode]!['smartInsights']!;
  String get trackProgress => _localizedValues[locale.languageCode]!['trackProgress']!;
  String get smartInsightsDesc => _localizedValues[locale.languageCode]!['smartInsightsDesc']!;
  String get privacyFirst => _localizedValues[locale.languageCode]!['privacyFirst']!;
  String get stayProtected => _localizedValues[locale.languageCode]!['stayProtected']!;
  String get privacyFirstDesc => _localizedValues[locale.languageCode]!['privacyFirstDesc']!;
  String get continueBtn => _localizedValues[locale.languageCode]!['continueBtn']!;
  String get getStarted => _localizedValues[locale.languageCode]!['getStarted']!;
  
  // Splash
  String get appTagline => _localizedValues[locale.languageCode]!['appTagline']!;
  
  // Subscription
  String get chooseYourPlan => _localizedValues[locale.languageCode]!['chooseYourPlan']!;
  String get upgradeExperience => _localizedValues[locale.languageCode]!['upgradeExperience']!;
  String get monthly => _localizedValues[locale.languageCode]!['monthly']!;
  String get annual => _localizedValues[locale.languageCode]!['annual']!;
  String get save20 => _localizedValues[locale.languageCode]!['save20']!;
  String get essential => _localizedValues[locale.languageCode]!['essential']!;
  String get premium => _localizedValues[locale.languageCode]!['premium']!;
  String get billedAnnually => _localizedValues[locale.languageCode]!['billedAnnually']!;
  String get whatsIncluded => _localizedValues[locale.languageCode]!['whatsIncluded']!;
  String get subscriptionActive => _localizedValues[locale.languageCode]!['subscriptionActive']!;
  String get paymentInitError => _localizedValues[locale.languageCode]!['paymentInitError']!;
  String get subscriptionFailed => _localizedValues[locale.languageCode]!['subscriptionFailed']!;
  String get subscriptionSuccess => _localizedValues[locale.languageCode]!['subscriptionSuccess']!;
  String get paymentCanceled => _localizedValues[locale.languageCode]!['paymentCanceled']!;
  String get paymentFailed => _localizedValues[locale.languageCode]!['paymentFailed']!;
  String get unexpectedPaymentError => _localizedValues[locale.languageCode]!['unexpectedPaymentError']!;
  
  // Plan Features
  String get sendReplyEmails => _localizedValues[locale.languageCode]!['sendReplyEmails']!;
  String get voiceTaskCreation => _localizedValues[locale.languageCode]!['voiceTaskCreation']!;
  String get voiceCalendarEvents => _localizedValues[locale.languageCode]!['voiceCalendarEvents']!;
  String get textNotifications => _localizedValues[locale.languageCode]!['textNotifications']!;
  String get centralizedDashboard => _localizedValues[locale.languageCode]!['centralizedDashboard']!;
  String get secureStorage2GB => _localizedValues[locale.languageCode]!['secureStorage2GB']!;
  String get priorityEmails10 => _localizedValues[locale.languageCode]!['priorityEmails10']!;
  String get basicVoiceRecognition => _localizedValues[locale.languageCode]!['basicVoiceRecognition']!;
  String get standardSupport => _localizedValues[locale.languageCode]!['standardSupport']!;
  String get voiceEmailReading => _localizedValues[locale.languageCode]!['voiceEmailReading']!;
  String get smartReminders => _localizedValues[locale.languageCode]!['smartReminders']!;
  String get completeVoiceTask => _localizedValues[locale.languageCode]!['completeVoiceTask']!;
  String get interactiveVoiceNotif => _localizedValues[locale.languageCode]!['interactiveVoiceNotif']!;
  String get advancedVoiceCommands => _localizedValues[locale.languageCode]!['advancedVoiceCommands']!;
  String get secureStorage1TB => _localizedValues[locale.languageCode]!['secureStorage1TB']!;
  String get hybridConcierge => _localizedValues[locale.languageCode]!['hybridConcierge']!;
  String get priorityEmails20 => _localizedValues[locale.languageCode]!['priorityEmails20']!;
  String get advancedVoiceContext => _localizedValues[locale.languageCode]!['advancedVoiceContext']!;
  String get prioritySupport => _localizedValues[locale.languageCode]!['prioritySupport']!;
  String get customVoiceTraining => _localizedValues[locale.languageCode]!['customVoiceTraining']!;
  String get productivityIntegration => _localizedValues[locale.languageCode]!['productivityIntegration']!;
  
  // Current Plan
  String get currentPlan => _localizedValues[locale.languageCode]!['currentPlan']!;
  String get essentialPlan => _localizedValues[locale.languageCode]!['essentialPlan']!;
  String get premiumPlan => _localizedValues[locale.languageCode]!['premiumPlan']!;
  String get essentialPlanDesc => _localizedValues[locale.languageCode]!['essentialPlanDesc']!;
  String get premiumPlanDesc => _localizedValues[locale.languageCode]!['premiumPlanDesc']!;
  String get backToHome => _localizedValues[locale.languageCode]!['backToHome']!;
  // Profile Screen
  String get personalInformation => _localizedValues[locale.languageCode]!['personalInformation']!;
  String get firstName => _localizedValues[locale.languageCode]!['firstName']!;
  String get lastName => _localizedValues[locale.languageCode]!['lastName']!;
  String get changePassword => _localizedValues[locale.languageCode]!['changePassword']!;
  String get enter => _localizedValues[locale.languageCode]!['enter']!;
  String get takePhoto => _localizedValues[locale.languageCode]!['takePhoto']!;
  String get chooseFromGallery => _localizedValues[locale.languageCode]!['chooseFromGallery']!;
  String get removePhoto => _localizedValues[locale.languageCode]!['removePhoto']!;
  String get cameraOpened => _localizedValues[locale.languageCode]!['cameraOpened']!;
  String get galleryOpened => _localizedValues[locale.languageCode]!['galleryOpened']!;
  String get photoRemoved => _localizedValues[locale.languageCode]!['photoRemoved']!;
  String get firstNameRequired => _localizedValues[locale.languageCode]!['firstNameRequired']!;
  String get lastNameRequired => _localizedValues[locale.languageCode]!['lastNameRequired']!;
  String get emailRequired => _localizedValues[locale.languageCode]!['emailRequired']!;
  String get invalidEmail => _localizedValues[locale.languageCode]!['invalidEmail']!;
  String get invalidWorkEmail => _localizedValues[locale.languageCode]!['invalidWorkEmail']!;
  String get workEmailUpdatedGmailDisconnected => _localizedValues[locale.languageCode]!['workEmailUpdatedGmailDisconnected']!;
  String get profileSaved => _localizedValues[locale.languageCode]!['profileSaved']!;
  String get errorSavingProfile => _localizedValues[locale.languageCode]!['errorSavingProfile']!;
  String get failedToUpdateProfile => _localizedValues[locale.languageCode]!['failedToUpdateProfile']!;
  String get currentPassword => _localizedValues[locale.languageCode]!['currentPassword']!;
  String get newPassword => _localizedValues[locale.languageCode]!['newPassword']!;
  String get passwordUpdated => _localizedValues[locale.languageCode]!['passwordUpdated']!;
  String get update => _localizedValues[locale.languageCode]!['update']!;



  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'retry': 'Retry',
      'emails': 'Emails',
      'errorLoadingAnalytics': 'Error loading analytics',
      'appTitle': 'Aixy',
      'tasks': 'Tasks',
      'completeTask': 'Complete Task',
      'meetings': 'Meetings',
      'settings': 'Settings',
      'home': 'Home',
      'analytics': 'Analytics',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'changed': 'changed to',
      'loading': 'Loading...',
      'error': 'Error',
      'errorOccurred': 'An error occurred',
      'success': 'Success',
      'all': 'All',
      'completed': 'Completed',
      'inProgress': 'In Progress',
      'pending': 'Pending',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'yesterday': 'Yesterday',
      'thisWeek': 'This Week',
      'nextWeek': 'Next Week',
      'thisMonth': 'This Month',
      'thisYear': 'This Year',
      'nextMonth': 'Next Month',
      'priority': 'Priority',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'dueDate': 'Due Date',
      'description': 'Description',
      'title': 'Title',
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'location': 'Location',
      'time': 'Time',
      'date': 'Date',
      'duration': 'Duration',
      'attendees': 'Attendees',
      'notes': 'Notes',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'refresh': 'Refresh',
      'sync': 'Sync',
      'syncStatus': 'Sync Status',
      'synced': 'Synced',
      'syncing': 'Syncing...',
      'syncFailed': 'Sync Failed',
      'noData': 'No Data',
      'noTasks': 'No Tasks',
      'noMeetings': 'No Meetings',
      'areYouSureYouWantToDelete': 'Are you sure you want to delete',
      'addTask': 'Add Task',
      'addMeeting': 'Add Meeting',
      'editTask': 'Edit Task',
      'editMeeting': 'Edit Meeting',
      'editProfile': 'Edit Profile',
      'deleteTask': 'Delete Task',
      'deleteMeeting': 'Delete Meeting',
      'taskCompleted': 'Task Completed',
      'taskInProgress': 'Task In Progress',
      'todayProgress': 'Today\'s Progress',
      'taskPending': 'Task Pending',
      'meetingScheduled': 'Meeting Scheduled',
      'meetingCompleted': 'Meeting Completed',
      'meetingCancelled': 'Meeting Cancelled',
      'welcome': 'Welcome',
      'goodMorning': 'Good Morning',
      'goodAfternoon': 'Good Afternoon',
      'goodEvening': 'Good Evening',
      'goodNight': 'Good Night',
      'dashboard': 'Dashboard',
      'overview': 'Overview',
      'statistics': 'Statistics',
      'recentActivity': 'Recent Activity',
      'upcoming': 'Upcoming',
      'overdue': 'Overdue',
      'profile': 'Profile',
      'account': 'Account',
      'preferences': 'Preferences',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'security': 'Security',
      'help': 'Help',
      'support': 'Support',
      'about': 'About',
      'version': 'Version',
      'logout': 'Logout',
      'signOut': 'Sign Out',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'english': 'English',
      'french': 'French',
      'voice': 'Voice',
      'female': 'Female',
      'male': 'Male',
      'pushNotifications': 'Push Notifications',
      'emailNotifications': 'Email Notifications',
      'smsNotifications': 'SMS Notifications',
      'calendar': 'Calendar',
      'schedule': 'Schedule',
      'agenda': 'Agenda',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'day': 'Day',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      'readyToAssistYou': 'Ready to assist you',
      'emailManagement': 'Email Management',
      'registrationEmail': 'Registration Email',
      'fixed': 'Fixed',
      'workEmail': 'Work Email',
      'supportFeedback': 'Support & Feedback',
      'rateUs': 'Rate Us',
      'loveTheApp': 'Love the app? Leave us a review',
      'shareApp': 'Share App',
      'tellYourFriends': 'Tell your friends about this app',
      'helpSupport': 'Help & Support',
      'getHelp': 'Get help and work support',
      'legalInformation': 'Legal & Information',
      'privacyPolicy': 'Privacy Policy',
      'howWeProtectYourData': 'How we protect your data',
      'termsOfService': 'Terms of Service',
      'termsAndConditions': 'Terms and conditions of use',
      'appVersion': 'App Version',
      'version123': 'Version 0.0.1',
      'appPreferences': 'App Preferences',
      'selectDate': 'Select Date',
      'pleaseEnterATaskTitle': 'Please enter a task title',
      'pleaseEnterACustomCategoryName': 'Please enter a custom category name',
      'taskDateCannotBeInThePast': 'Task date cannot be in the past',
      'taskTimeMustBeAtLeastOneHourFromNow':
          'Task time must be at least 1 hour from now',
      'taskUpdatedSuccessfully': 'Task updated successfully',
      'taskCreatedSuccessfully': 'Task created successfully',

      'newTask': 'New Task',
      'taskTitle': 'Task Title',
      'whatNeedsToBeDone': 'What needs to be done?',
      'addDetailsAboutThisTaskOptional':
          'Add details about this task (optional)',
      'customCategory': 'Custom Category',
      'enterYourCustomCategoryName': 'Enter your custom category name',
      'dueDateTime': 'DUE DATE & TIME',
      'category': 'CATEGORY',
      'work': 'Work',
      'personal': 'Personal',
      'finance': 'Finance',
      'health': 'Health',
      'education': 'Education',
      'other': 'Other',
      'updateTask': 'Update Task',
      'createTask': 'Create Task',
      'legal_privacy_policy': 'This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service...',
      'legal_terms_of_service': 'Please read these terms and conditions carefully before using Our Service...',
      'howCanWeHelp': 'How can we help?',
      'supportDescription': 'For any questions, feedback, or issues,\nplease contact our development team directly.',
      'emailUs': 'Email Us',

      // Notifications
      'markAllAsRead': 'Mark All as Read',
      'clearAll': 'Clear All',
      'clearAllNotifications': 'Clear All Notifications',
      'unread': 'Unread',
      'noNotifications': 'No Notifications',
      'caughtUp': 'You\'re all caught up!',
      'playSummary': 'Play Summary',
      'confirmMarkAllRead': 'Are you sure you want to mark all notifications as read?',
      'confirmClearAll': 'Are you sure you want to clear all notifications? This action cannot be undone.',

      // Analytics
      'analyticsDashboard': 'Analytics Dashboard',
      'analyticsSubtitle': 'Track your productivity & performance',

      // Auth
      'password': 'Password',
      'login': 'Login',
      'signup': 'Sign Up',
      'or': 'Or',
      'backToLogin': 'Back to Login',
      'submit': 'Submit',
      'welcomeBack': 'Welcome Back',
      'rememberMe': 'Remember me',
      'forgotPassword': 'Forgot Password?',
      'continueWithGoogle': 'Continue with Google',
      'continueWithApple': 'Continue with Apple',
      'createAccount': 'Create Account',
      'joinUs': 'Join us and start your productivity journey',
      'dateOfBirth': 'Date of Birth',
      'confirmPassword': 'Confirm Password',
      'agreeToTerms': 'I agree to the ',
      'enterEmail': 'Enter your email address',
      'sendResetLink': 'Send Reset Link',
      'emailSentSuccess': 'Email sent successfully!',
      'resendEmail': 'Resend Email',
      'needHelp': 'Need help?',
      'contactSupport': 'Contact Support',
      'createNewPassword': 'Create new password',
      'resetPasswordTitle': 'Reset Password',
      'passwordResetSuccess': 'Password reset successfully!',
      'passwordResetFailed': 'Password reset failed',
      'verifyingEmail': 'Verifying your email...',
      'emailVerified': 'Email verified successfully!',
      'verificationFailed': 'Email verification failed',
      'invalidLink': 'Invalid verification link',
      'goToLogin': 'Go to Login',
      'passwordMatchError': 'Passwords do not match',
      'passwordLengthError': 'Password must be at least 8 characters',
      'passwordRequired': 'Password is required',
      'enterPassword': 'Enter your password',
      'getStartedNow': 'Get Started now',
      'loginSubtitle': 'Create an account or log in to explore about our app',
      'dataProcessingAgreement': 'Data Processing Agreement',
      'and': 'and',
      'bySigningUpAgreeTo': 'By signing up, you agree to the ',
      'enterFirstName': 'Enter first name',
      'enterLastName': 'Enter last name',
      'enterPhone': 'Enter phone number',
      'confirmPasswordHint': 'Confirm your password',
      'checkYourEmail': 'Check your email',
      'recoveryLinkSent': 'We\'ve sent a recovery link to your email',
      'dontWorryReset': 'Don\'t worry, we\'ll help you reset it',
      'sendLinkReset': 'We\'ll send you a link to reset your password',
      'sentLinkTo': 'We\'ve sent a password reset link to:',
      'checkEmailInstruction': 'Check your email and click the reset link to create a new password. The link will expire in 1 hour.',
      'resendIn': 'Resend in',
      'didntReceiveResend': 'Didn\'t receive the email? Resend',
      'newPasswordHint': 'Enter your new password',
      'confirmNewPasswordHint': 'Confirm your new password',
      'verificationFailedMessage': 'Email verification failed: This can be caused by an invalid verification link or the email has already been verified.',
      'createSecurePassword': 'Create a new secure password for your account',
      'passwordRequirements': 'Your new password must be at least 8 characters long',
      'emailVerification': 'Email Verification',
      'productivityScore': 'Productivity Score',
      'emailsSent': 'Emails Sent',
      'emailsReceived': 'Emails Received',
      'tasksCompleted': 'Tasks Completed',
      'meetingDuration': 'Meeting Duration',
      'focusTime': 'Focus Time',
      'keyInsights': 'Key Insights',
      'activityTrends': 'Activity Trends',
      'score': 'Score',
      'savedTo': 'Saved to',
      'failedToGenerate': 'Failed to generate report',
      'open': 'OPEN',
      'shareAnalyticsMessage': 'Here is my analytics report from Aixy.',
      'failedToGenerateShare': 'Failed to generate report for sharing',
      'avgResponseTime': 'Avg Response Time',
      'peakActivity': 'Peak Activity',
      'noActivityData': 'No activity data',
      'mostProductiveDay': 'Your most productive day was',
      'consistentActivity': 'Consistent activity throughout the week',
      'responsePattern': 'Response Pattern',
      'excellentResponse': 'You maintain excellent response times consistently',
      'improvedResponse': 'Your response time could be improved during peak hours',
      'automateResponses': 'Consider setting up automated responses for better efficiency',
      'suggestion': 'Suggestion',
      'shareTips': 'Great work! Consider sharing your productivity tips with your team',
      'timeBlocking': 'Try time-blocking your calendar to improve focus and productivity',

      // Email
      'inbox': 'Inbox',
      'sent': 'Sent',
      'drafts': 'Drafts',
      'important': 'Important',
      'trash': 'Trash',
      'searchMail': 'Search mail...',
      'messages': 'messages',
      'markAsRead': 'Mark as Read',
      'markAsUnread': 'Mark as Unread',
      'emptyInbox': 'Your inbox is empty',
      'emptyDrafts': 'No drafts saved',
      'emptySent': 'No sent messages',
      'emptyTrash': 'Trash is empty',
      'emptySpam': 'No spam messages',
      'emptyImportant': 'No important messages',
      'emptyOther': 'No other messages',
      'emptyPrimary': 'Your primary inbox is empty',
      'connectGmail': 'Connect Gmail',
      'connectDescription': 'Connect your Gmail account to manage emails and get AI summaries.',
      'deleteEmail': 'Delete Email',
      'confirmDeleteEmail': 'Are you sure you want to delete this email?',
      'connectEmailAccount': 'Connect Email Account',
      'noEmailsFound': 'No emails found',
      'somethingWentWrong': 'Something went wrong',
      'reply': 'Reply',
      'replyAll': 'Reply All',
      'forward': 'Forward',
      'vip': 'VIP',
      'addedToVIP': 'Added to VIP list',
      'removedFromVIP': 'Removed from VIP list',
      'vipStatusUpdateFailed': 'Failed to update VIP status',
      'loadingEmail': 'Loading email...',
      'failedToLoadEmail': 'Failed to load email content',
      'noContentAvailable': 'No content available',
      'priorityAudioSummary': 'Priority Audio Summary',
      'primary': 'Primary',
      'spam': 'Spam',
      'other': 'Other',
      'total': 'Total',
      'emailDeletedSuccess': 'Email deleted successfully',
      'emailDeleteFailed': 'Failed to delete email',
      'emailDeleteError': 'Error deleting email',
      'tapToPlay': 'Tap to play',
      'compose': 'Compose',
      'editMessage': 'Edit Message',
      'to': 'To',
      'cc': 'Cc',
      'bcc': 'Bcc',
      'subject': 'Subject',
      'send': 'Send',
      'sending': 'Sending...',
      'attachments': 'Attachments',
      'total': 'Total',
      'messageSent': 'Message sent successfully',
      'draftSaved': 'Draft saved successfully',
      'draftEmpty': 'Draft is empty',
      'attachmentRemoved': 'Attachment removed',
      'fileTooLarge': 'File is too large (max 25MB)',
      'voiceRefinementLimit': 'Voice refinement limit reached (2/2). Edit manually.',
      'listeningTapStop': 'Listening... Tap stop to refine.',
      'transcribing': 'Transcribing...',
      'noVoiceDetected': 'No voice detected',
      'refinementFailed': 'Refinement failed',
      'emailRefined': 'Email refined by AI',
      'pleaseAddRecipient': 'Please add at least one recipient',
      'pleaseAddSubject': 'Please add a subject',
      'unknownError': 'Unknown error',
      'draftSaveFailed': 'Failed to save draft',
      'filesAdded': 'File(s) added',
      'imagesAdded': 'Image(s) added',
      'errorPickingFiles': 'Error picking files',
      'errorPickingImages': 'Error picking images',
      'errorSendingEmail': 'Error sending email',
      'errorSavingDraft': 'Error saving draft',
      'important': 'Important',
      'errorSummarizing': 'Error summarizing',
      'confirmDeleteEmailPermanent': 'Are you sure you want to delete this email? This action cannot be undone.',
      'unknownSender': 'Unknown Sender',
      'unknown': 'Unknown',
      'wrote': 'wrote',
      'forwardedMessage': 'Forwarded message',
      'from': 'From',
      'date': 'Date',
      'reply': 'Reply',
      'replyAll': 'Reply All',
      'forward': 'Forward',

      // Calendar
      'calendar': 'Calendar',
      'meetingAddedSuccess': 'Meeting added successfully!',
      'meetingAddFailed': 'Failed to add meeting',
      'meetingUpdatedSuccess': 'Meeting updated successfully!',
      'meetingUpdateFailed': 'Failed to update meeting',
      'meetingDeletedSuccess': 'Meeting deleted successfully!',
      'meetingDeleteFailed': 'Failed to delete meeting',
      'confirmDeleteMeeting': 'Are you sure you want to delete this meeting?',
      'online': 'Online',
      'onsite': 'On-site',
      'newSchedule': 'New Schedule',
      'editMeeting': 'Edit Meeting',
      'meetingTitle': 'MEETING TITLE',
      'meetingTitleHint': 'What is this meeting about?',
      'meetingDescriptionHint': 'Meeting agenda or details (optional)',
      'attendees': 'ATTENDEES',
      'attendeesHint': 'Enter email addresses separated by commas',
      'dateTime': 'DATE & TIME',
      'startTime': 'Start',
      'endTime': 'End',
      'meetingType': 'MEETING TYPE',
      'addSchedule': 'Add Schedule',
      'updateMeeting': 'Update Meeting',
      'pleaseEnterTitle': 'Please enter a title',
      
      // Priority Emails
      'priorityEmails': 'Priority Emails',
      'addVipEmail': 'Add VIP Email',
      'vipEmailDescription': 'Emails from these senders will trigger voice summaries.',
      'emailPlaceholder': 'partner@example.com',
      'pleaseEnterEmail': 'Please enter an email',
      'invalidEmailAddress': 'Invalid email address',
      'failedToAddEmail': 'Failed to add email',
      'unexpectedError': 'An unexpected error occurred',
      'failedToRemoveEmail': 'Failed to remove email',
      'noVipEmails': 'No VIP emails yet',
      'addedToVIP': 'Added',
      'removedFromVIP': 'Removed',
      'quota': 'Quota',
      'used': 'used',
      
      // Security
      'security': 'Security',
      'secure': 'Secure',
      'accountSecure': 'Your Account is Secure',
      'lastSecurityCheck': 'Last security check: Today at 3:24 PM',
      'authentication': 'Authentication',
      'privacyLock': 'Privacy & Lock',
      'securityActivity': 'Security Activity',
      'updateAccountPassword': 'Update your account password',
      'viewLoginActivity': 'View recent login activity',
      'loginHistory': 'Login History',
      'activeSessions': 'Active Sessions',
      'manageActiveSessions': 'Manage your active sessions',
      'securityAlerts': 'Security Alerts',
      'configureSecurityNotifications': 'Configure security notifications',
      'dataExport': 'Data Export',
      'downloadAccountData': 'Download your account data',
      'passwordUpdatedSuccess': 'Password updated successfully!',
      'autoLockTimer': 'Auto Lock Timer',
      'minute': 'minute',
      'minutes': 'minutes',
      'never': 'Never',
      'currentDevice': 'Current device',
      'lastActive': 'Last active:',
      'close': 'Close',
      'signOutOthers': 'Sign Out Others',
      'allSessionsSignedOut': 'All other sessions signed out',
      'configureSecurityDescription': 'Configure when you want to receive security notifications.',
      'downloadDataDescription': 'Download a copy of your account data. This may take a few minutes.',
      'dataExportStarted': 'Data export started. You will receive an email when ready.',
      'export': 'Export',
      'configure': 'Configure',
      
      // Onboarding
      'skip': 'Skip',
      'voiceControl': 'Voice Control',
      'speakNaturally': 'Speak Naturally',
      'voiceControlDesc': 'Transform your productivity with intuitive voice commands. Just speak and watch your tasks come to life.',
      'smartInsights': 'Smart Insights',
      'trackProgress': 'Track Progress',
      'smartInsightsDesc': 'Gain powerful insights into your productivity patterns with beautiful analytics and detailed reports.',
      'privacyFirst': 'Privacy First',
      'stayProtected': 'Stay Protected',
      'privacyFirstDesc': 'Your data is encrypted and secure. Experience powerful features while maintaining complete privacy.',
      'continueBtn': 'Continue',
      'getStarted': 'Get Started',
      
      // Splash
      'appTagline': 'Where your ideas become reality',
      
      // Subscription
      'chooseYourPlan': 'Choose Your Plan',
      'upgradeExperience': 'Upgrade your voice productivity experience',
      'monthly': 'Monthly',
      'annual': 'Annual',
      'save20': 'Save 20%',
      'essential': 'Essential',
      'premium': 'Premium',
      'billedAnnually': 'Billed annually',
      'whatsIncluded': 'What\'s included:',
      'subscriptionActive': 'Subscription is active!',
      'paymentInitError': 'Could not initialize payment. Please try again.',
      'subscriptionFailed': 'Subscription failed',
      'subscriptionSuccess': 'Success! Your subscription is active.',
      'paymentCanceled': 'Payment process was canceled.',
      'paymentFailed': 'Payment failed',
      'unexpectedPaymentError': 'An unexpected error occurred',
      
      // Plan Features  
      'sendReplyEmails': 'Send/Reply to Emails by Voice',
      'voiceTaskCreation': 'Voice Task Creation',
      'voiceCalendarEvents': 'Voice Calendar Events',
      'textNotifications': 'Text Notifications',
      'centralizedDashboard': 'Centralized Dashboard',
      'secureStorage2GB': 'Secure Storage (2 GB)',
      'priorityEmails10': 'Up to 10 Priority Emails',
      'basicVoiceRecognition': 'Basic voice recognition',
      'standardSupport': 'Standard customer support',
      'voiceEmailReading': 'Voice Email Reading + Smart Search',
      'smartReminders': 'Smart Reminders',
      'completeVoiceTask': 'Complete Voice Task Management',
      'interactiveVoiceNotif': 'Interactive Voice Notifications',
      'advancedVoiceCommands': 'Advanced Voice Commands + Natural AI',
      'secureStorage1TB': 'Extended Secure Storage (1 TB)',
      'hybridConcierge': 'Hybrid Concierge Service',
      'priorityEmails20': 'Up to 20 Priority Emails',
      'advancedVoiceContext': 'Advanced voice recognition with context',
      'prioritySupport': 'Priority customer support',
      'customVoiceTraining': 'Custom voice command training',
      'productivityIntegration': 'Integration with productivity tools',
      
      // Current Plan
      'currentPlan': 'Current Plan',
      'essentialPlan': 'Essential Plan',
      'premiumPlan': 'Premium Plan',
      'essentialPlanDesc': 'You have access to essential voice features and basic productivity tools.',
      'premiumPlanDesc': 'You have access to all premium features including advanced AI capabilities and unlimited storage.',
      'backToHome': 'Back to Home',
      
      // Profile Screen
      'personalInformation': 'Personal Information',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'changePassword': 'Change Password',
      'enter': 'Enter',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'removePhoto': 'Remove Photo',
      'cameraOpened': 'Camera opened for photo capture',
      'galleryOpened': 'Gallery opened for photo selection',
      'photoRemoved': 'Profile photo removed',
      'firstNameRequired': 'First name is required',
      'lastNameRequired': 'Last name is required',
      'emailRequired': 'Email is required',
      'invalidEmail': 'Please enter a valid email address',
      'invalidWorkEmail': 'Please enter a valid work email address',
      'workEmailUpdatedGmailDisconnected': 'Work email updated. Gmail disconnected.',
      'profileSaved': 'Profile saved successfully!',
      'errorSavingProfile': 'Error saving profile',
      'failedToUpdateProfile': 'Failed to update profile',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'passwordUpdated': 'Password updated successfully!',
      'update': 'Update',
      // MARKER

    },
    'fr': {
      'retry': 'Réessayer',
      'emails': 'Emails',
      'errorLoadingAnalytics': 'Erreur de chargement des analyses',
      'appTitle': 'Aixy',
      'tasks': 'Tâches',
      'completeTask': 'Terminer la tâche',
      'meetings': 'Réunions',
      'settings': 'Paramètres',
      'home': 'Accueil',
      'analytics': 'Analytics',
      'add': 'Ajouter',
      'edit': 'Modifier',
      'editProfile': 'Modifier le profil',
      'delete': 'Supprimer',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'changed': 'changé en',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'errorOccurred': 'Une erreur s\'est produite',
      'success': 'Succès',
      'all': 'Tout',
      'completed': 'Terminé',
      'inProgress': 'En cours',
      'pending': 'En attente',
      'today': 'Aujourd\'hui',
      'tomorrow': 'Demain',
      'yesterday': 'Hier',
      'thisWeek': 'Cette semaine',
      'nextWeek': 'Semaine prochaine',
      'thisMonth': 'Ce mois',
      'thisYear': 'Cette année',
      'nextMonth': 'Mois prochain',
      'avgResponseTime': 'Temps de réponse moyen',
      'peakActivity': 'Pic d\'activité',
      'noActivityData': 'Aucune donnée d\'activité',
      'mostProductiveDay': 'Votre journée la plus productive était',
      'consistentActivity': 'Activité constante tout au long de la semaine',
      'responsePattern': 'Modèle de réponse',
      'excellentResponse': 'Vous maintenez d\'excellents temps de réponse',
      'improvedResponse': 'Votre temps de réponse pourrait être amélioré aux heures de pointe',
      'automateResponses': 'Pensez à configurer des réponses automatiques pour plus d\'efficacité',
      'suggestion': 'Suggestion',
      'shareTips': 'Excellent travail ! Pensez à partager vos conseils de productivité',
      'timeBlocking': 'Essayez le blocage de temps pour améliorer la concentration',
      'priority': 'Priorité',
      'high': 'Élevée',
      'medium': 'Moyenne',
      'low': 'Faible',
      'dueDate': 'Date d\'échéance',
      'description': 'Description',
      'title': 'Titre',
      'name': 'Nom',
      'email': 'Email',
      'phone': 'Téléphone',
      'location': 'Lieu',
      'time': 'Heure',
      'date': 'Date',
      'duration': 'Durée',
      'attendees': 'Participants',
      'notes': 'Notes',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'sort': 'Trier',
      'refresh': 'Actualiser',
      'sync': 'Synchroniser',
      'syncStatus': 'État de synchronisation',
      'synced': 'Synchronisé',
      'syncing': 'Synchronisation...',
      'syncFailed': 'Échec de synchronisation',
      'noData': 'Aucune donnée',
      'noTasks': 'Aucune tâche',
      'noMeetings': 'Aucune réunion',
      'addTask': 'Ajouter une tâche',
      'addMeeting': 'Ajouter une réunion',
      'editTask': 'Modifier la tâche',
      'editMeeting': 'Modifier la réunion',
      'deleteTask': 'Supprimer la tâche',
      'deleteMeeting': 'Supprimer la réunion',
      'areYouSureYouWantToDelete': 'Êtes-vous sûr de vouloir supprimer',
      'taskCompleted': 'Tâche terminée',
      'taskInProgress': 'Tâche en cours',
      'todayProgress': 'Progression d\'aujourd\'hui',
      'taskPending': 'Tâche en attente',
      'meetingScheduled': 'Réunion programmée',
      'meetingCompleted': 'Réunion terminée',
      'meetingCancelled': 'Réunion annulée',
      'welcome': 'Bienvenue',
      'goodMorning': 'Bonjour',
      'goodAfternoon': 'Bon après-midi',
      'goodEvening': 'Bonsoir',
      'goodNight': 'Bonne nuit',
      'dashboard': 'Tableau de bord',
      'overview': 'Aperçu',
      'statistics': 'Statistiques',
      'recentActivity': 'Activité récente',
      'upcoming': 'À venir',
      'overdue': 'En retard',
      'profile': 'Profil',
      'account': 'Compte',
      'preferences': 'Préférences',
      'notifications': 'Notifications',
      'privacy': 'Confidentialité',
      'security': 'Sécurité',
      'help': 'Aide',
      'support': 'Support',
      'about': 'À propos',
      'version': 'Version',
      'logout': 'Déconnexion',
      'signOut': 'Se déconnecter',
      'language': 'Langue',
      'theme': 'Thème',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'english': 'Anglais',
      'french': 'Français',
      'voice': 'Voix',
      'female': 'Féminine',
      'male': 'Masculine',
      'pushNotifications': 'Notifications push',
      'emailNotifications': 'Notifications email',
      'smsNotifications': 'Notifications SMS',
      'calendar': 'Calendrier',
      'schedule': 'Planifier',
      'agenda': 'Ordre du jour',
      'week': 'Semaine',
      'month': 'Mois',
      'year': 'Année',
      'day': 'Jour',
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
      'january': 'Janvier',
      'february': 'Février',
      'march': 'Mars',
      'april': 'Avril',
      'may': 'Mai',
      'june': 'Juin',
      'july': 'Juillet',
      'august': 'Août',
      'september': 'Septembre',
      'october': 'Octobre',
      'november': 'Novembre',
      'december': 'Décembre',
      'readyToAssistYou': 'Prêt à vous aider',
      'emailManagement': 'Gestion des emails',
      'registrationEmail': 'Email de registration',
      'fixed': 'Fixe',
      'workEmail': 'Email professionnel',
      'supportFeedback': 'Support & Feedback',
      'rateUs': 'Noter l\'application',
      'loveTheApp': 'Aimez-vous l\'application ? Laissez-nous un avis',
      'shareApp': 'Partager l\'application',
      'tellYourFriends': 'Dites à vos amis sur cette application',
      'helpSupport': 'Aide & Support',
      'getHelp': 'Obtenir de l\'aide et du support',
      'legalInformation': 'Informations légales',
      'privacyPolicy': 'Politique de confidentialité',
      'howWeProtectYourData': 'Comment nous protégeons vos données',
      'termsOfService': 'Conditions d\'utilisation',
      'termsAndConditions': 'Conditions d\'utilisation',
      'appVersion': 'Version de l\'application',
      'version123': 'Version 1.0.0',
      'appPreferences': 'Préférences de l\'application',
      'selectDate': 'Sélectionner la date',
      'pleaseEnterATaskTitle': 'Veuillez saisir un titre de tâche',
      'pleaseEnterACustomCategoryName':
          'Veuillez saisir un nom de catégorie personnalisée',
      'taskDateCannotBeInThePast':
          'La date de la tâche ne peut pas être dans le passé',
      'taskTimeMustBeAtLeastOneHourFromNow':
          'L\'heure de la tâche doit être au moins 1 heure à partir de maintenant',
      'taskUpdatedSuccessfully': 'Tâche mise à jour avec succès',
      'taskCreatedSuccessfully': 'Tâche créée avec succès',

      'newTask': 'Nouvelle tâche',
      'taskTitle': 'Titre de la tâche',
      'whatNeedsToBeDone': 'Que faut-il faire ?',
      'addDetailsAboutThisTaskOptional':
          'Ajouter des détails sur cette tâche (optionnel)',
      'customCategory': 'Catégorie personnalisée',
      'enterYourCustomCategoryName':
          'Veuillez saisir un nom de catégorie personnalisée',
      
      // Profile Screen
      'personalInformation': 'Informations personnelles',
      'firstName': 'Prénom',
      'lastName': 'Nom',
      'changePassword': 'Changer le mot de passe',
      'enter': 'Entrer',
      'takePhoto': 'Prendre une photo',
      'chooseFromGallery': 'Choisir dans la galerie',
      'removePhoto': 'Supprimer la photo',
      'cameraOpened': 'Appareil photo ouvert pour la capture',
      'galleryOpened': 'Galerie ouverte pour la sélection',
      'photoRemoved': 'Photo de profil supprimée',
      'firstNameRequired': 'Le prénom est requis',
      'lastNameRequired': 'Le nom est requis',
      'emailRequired': 'L\'email est requis',
      'invalidEmail': 'Veuillez entrer une adresse email valide',
      'invalidWorkEmail': 'Veuillez entrer une adresse email professionnelle valide',
      'workEmailUpdatedGmailDisconnected': 'Email professionnel mis à jour. Gmail déconnecté.',
      'profileSaved': 'Profil enregistré avec succès !',
      'errorSavingProfile': 'Erreur lors de l\'enregistrement du profil',
      'failedToUpdateProfile': 'Échec de la mise à jour du profil',
      'currentPassword': 'Mot de passe actuel',
      'newPassword': 'Nouveau mot de passe',
      'passwordUpdated': 'Mot de passe mis à jour avec succès !',
      'update': 'Mettre à jour',

      'dueDateTime': 'DATE ET HEURE D\'ÉCHÉANCE',
      'category': 'CATÉGORIE',
      'work': 'Travail',
      'personal': 'Personnel',
      'finance': 'Finance',
      'health': 'Santé',
      'education': 'Éducation',
      'other': 'Autre',
      'updateTask': 'Mettre à jour la tâche',
      'createTask': 'Créer la tâche',
      'legal_privacy_policy': 'Cette Politique de Confidentialité décrit nos politiques et procédures sur la collecte, l\'utilisation et la divulgation de vos informations lorsque vous utilisez le Service...',
      'legal_terms_of_service': 'Veuillez lire attentivement ces termes et conditions avant d\'utiliser notre Service...',
      'howCanWeHelp': 'Comment pouvons-nous vous aider ?',
      'supportDescription': 'Pour toute question, retour ou problème,\nveuillez contacter notre équipe de développement directement.',
      'emailUs': 'Envoyez-nous un email',

      // Notifications
      'markAllAsRead': 'Tout marquer comme lu',
      'clearAll': 'Tout effacer',
      'clearAllNotifications': 'Effacer toutes les notifications',
      'unread': 'Non lu',
      'noNotifications': 'Aucune notification',
      'caughtUp': 'Vous êtes à jour !',
      'playSummary': 'Écouter le résumé',
      'confirmMarkAllRead': 'Êtes-vous sûr de vouloir marquer toutes les notifications comme lues ?',
      'confirmClearAll': 'Êtes-vous sûr de vouloir effacer toutes les notifications ? Cette action est irréversible.',

      // Analytics
      'analyticsDashboard': 'Tableau de bord',
      'analyticsSubtitle': 'Suivez votre productivité et performance',

      // Auth
      'password': 'Mot de passe',
      'login': 'Se connecter',
      'signup': 'S\'inscrire',
      'or': 'Ou',
      'backToLogin': 'Retour à la connexion',
      'submit': 'Soumettre',
      'welcomeBack': 'Bon retour',
      'rememberMe': 'Se souvenir de moi',
      'forgotPassword': 'Mot de passe oublié ?',
      'continueWithGoogle': 'Continuer avec Google',
      'continueWithApple': 'Continuer avec Apple',
      'createAccount': 'Créer un compte',
      'joinUs': 'Rejoignez-nous et commencez votre voyage de productivité',
      'dateOfBirth': 'Date de naissance',
      'confirmPassword': 'Confirmer le mot de passe',
      'agreeToTerms': 'J\'accepte les ',
      'enterEmail': 'Entrez votre adresse email',
      'sendResetLink': 'Envoyer le lien de réinitialisation',
      'emailSentSuccess': 'Email envoyé avec succès !',
      'resendEmail': 'Renvoyer l\'email',
      'needHelp': 'Besoin d\'aide ?',
      'contactSupport': 'Contacter le support',
      'createNewPassword': 'Créer un nouveau mot de passe',
      'resetPasswordTitle': 'Réinitialiser le mot de passe',
      'passwordResetSuccess': 'Mot de passe réinitialisé avec succès !',
      'passwordResetFailed': 'La réinitialisation du mot de passe a échoué',
      'verifyingEmail': 'Vérification de votre email...',
      'emailVerified': 'Email vérifié avec succès !',
      'verificationFailed': 'Échec de la vérification de l\'email',
      'invalidLink': 'Lien de vérification invalide',
      'goToLogin': 'Aller à la connexion',
      'passwordMatchError': 'Les mots de passe ne correspondent pas',
      'passwordLengthError': 'Le mot de passe doit contenir au moins 8 caractères',
      'passwordRequired': 'Le mot de passe est requis',
      'enterPassword': 'Entrez votre mot de passe',
      'getStartedNow': 'Commencer maintenant',
      'loginSubtitle': 'Créez un compte ou connectez-vous pour explorer notre application',
      'dataProcessingAgreement': 'Accord de traitement des données',
      'and': 'et',
      'bySigningUpAgreeTo': 'En vous inscrivant, vous acceptez les ',
      'enterFirstName': 'Entrez le prénom',
      'enterLastName': 'Entrez le nom',
      'enterPhone': 'Entrez le numéro de téléphone',
      'confirmPasswordHint': 'Confirmez votre mot de passe',
      'checkYourEmail': 'Vérifiez votre email',
      'recoveryLinkSent': 'Nous avons envoyé un lien de récupération à votre email',
      'dontWorryReset': 'Ne vous inquiétez pas, nous vous aiderons à le réinitialiser',
      'sendLinkReset': 'Nous vous enverrons un lien pour réinitialiser votre mot de passe',
      'sentLinkTo': 'Nous avons envoyé un lien de réinitialisation de mot de passe à :',
      'checkEmailInstruction': 'Vérifiez votre email et cliquez sur le lien de réinitialisation pour créer un nouveau mot de passe. Le lien expirera dans 1 heure.',
      'resendIn': 'Renvoyer dans',
      'didntReceiveResend': 'Vous n\'avez pas reçu l\'email ? Renvoyer',
      'newPasswordHint': 'Entrez votre nouveau mot de passe',
      'confirmNewPasswordHint': 'Confirmez votre nouveau mot de passe',
      'verificationFailedMessage': 'La vérification de l\'email a échoué : Cela peut être causé par un lien de vérification invalide ou l\'email a déjà été vérifié.',
      'createSecurePassword': 'Créez un nouveau mot de passe sécurisé pour votre compte',
      'passwordRequirements': 'Votre nouveau mot de passe doit contenir au moins 8 caractères',
      'emailVerification': 'Vérification de l\'email',
      'productivityScore': 'Score de productivité',
      'emailsSent': 'Emails envoyés',
      'emailsReceived': 'Emails reçus',
      'tasksCompleted': 'Tâches terminées',
      'meetingDuration': 'Durée des réunions',
      'focusTime': 'Temps de concentration',
      'keyInsights': 'Insights clés',
      'activityTrends': 'Tendances d\'activité',
      'score': 'Score',
      'savedTo': 'Enregistré dans',
      'failedToGenerate': 'Échec de la génération du rapport',

      // Email
      'inbox': 'Boîte de réception',
      'sent': 'Envoyés',
      'drafts': 'Brouillons',
      'important': 'Important',
      'trash': 'Corbeille',
      'searchMail': 'Rechercher un courriel...',
      'messages': 'messages',
      'markAsRead': 'Marquer comme lu',
      'markAsUnread': 'Marquer comme non lu',
      'emptyInbox': 'Votre boîte de réception est vide',
      'emptyDrafts': 'Aucun brouillon',
      'emptySent': 'Aucun message envoyé',
      'emptyTrash': 'La corbeille est vide',
      'connectGmail': 'Connecter Gmail',
      'connectDescription': 'Connectez votre compte Gmail pour gérer vos emails et obtenir des résumés IA.',
      'deleteEmail': 'Supprimer l\'email',
      'confirmDeleteEmail': 'Êtes-vous sûr de vouloir supprimer cet email ?',
      'connectEmailAccount': 'Connecter un compte email',
      'noEmailsFound': 'Aucun email trouvé',
      'somethingWentWrong': 'Quelque chose s\'est mal passé',
      'reply': 'Répondre',
      'replyAll': 'Répondre à tous',
      'forward': 'Transférer',
      'vip': 'VIP',
      'addedToVIP': 'Ajouté à la liste VIP',
      'removedFromVIP': 'Retiré de la liste VIP',
      'vipStatusUpdateFailed': 'Échec de la mise à jour du statut VIP',
      'loadingEmail': 'Chargement de l\'email...',
      'failedToLoadEmail': 'Échec du chargement du contenu de l\'email',
      'noContentAvailable': 'Aucun contenu disponible',
      'priorityAudioSummary': 'Résumé audio prioritaire',
      'primary': 'Principal',
      'spam': 'Spam',
      'other': 'Autre',
      'total': 'Total',
      'emailDeletedSuccess': 'Email supprimé avec succès',

      // Calendar
      'calendar': 'Calendrier',
      'meetingAddedSuccess': 'Réunion ajoutée avec succès !',
      'meetingAddFailed': 'Échec de l\'ajout de la réunion',
      'meetingUpdatedSuccess': 'Réunion mise à jour avec succès !',
      'meetingUpdateFailed': 'Échec de la mise à jour de la réunion',
      'meetingDeletedSuccess': 'Réunion supprimée avec succès !',
      'meetingDeleteFailed': 'Échec de la suppression de la réunion',
      'confirmDeleteMeeting': 'Êtes-vous sûr de vouloir supprimer cette réunion ?',
      'online': 'En ligne',
      'onsite': 'Sur place',
      'newSchedule': 'Nouvelle planification',
      'editMeeting': 'Modifier la réunion',
      'meetingTitle': 'TITRE DE LA RÉUNION',
      'meetingTitleHint': 'De quoi parle cette réunion ?',
      'meetingDescriptionHint': 'Ordre du jour ou détails (facultatif)',
      'attendees': 'PARTICIPANTS',
      'attendeesHint': 'Entrez les adresses emails séparées par des virgules',
      'dateTime': 'DATE ET HEURE',
      'startTime': 'Début',
      'endTime': 'Fin',
      'meetingType': 'TYPE DE RÉUNION',
      'addSchedule': 'Ajouter planification',
      'updateMeeting': 'Mettre à jour la réunion',
      'pleaseEnterTitle': 'Veuillez entrer un titre',
      
      // Priority Emails
      'priorityEmails': 'Emails prioritaires',
      'addVipEmail': 'Ajouter email VIP',
      'vipEmailDescription': 'Les emails de ces expéditeurs déclencheront des résumés vocaux.',
      'emailPlaceholder': 'partenaire@exemple.com',
      'pleaseEnterEmail': 'Veuillez entrer un email',
      'invalidEmailAddress': 'Adresse email invalide',
      'failedToAddEmail': 'Échec de l\'ajout de l\'email',
      'unexpectedError': 'Une erreur inattendue s\'est produite',
      'failedToRemoveEmail': 'Échec de la suppression de l\'email',
      'noVipEmails': 'Aucun email VIP pour l\'instant',
      'addedToVIP': 'Ajouté',
      'removedFromVIP': 'Retiré',
      'quota': 'Quota',
      'used': 'utilisé',
      
      // Security
      'security': 'Sécurité',
      'secure': 'Sécurisé',
      'accountSecure': 'Votre compte est sécurisé',
      'lastSecurityCheck': 'Dernière vérification : Aujourd\'hui à 15h24',
      'authentication': 'Authentification',
      'privacyLock': 'Confidentialité et verrouillage',
      'securityActivity': 'Activité de sécurité',
      'updateAccountPassword': 'Mettre à jour votre mot de passe',
      'viewLoginActivity': 'Voir l\'activité de connexion récente',
      'loginHistory': 'Historique de connexion',
      'activeSessions': 'Sessions actives',
      'manageActiveSessions': 'Gérer vos sessions actives',
      'securityAlerts': 'Alertes de sécurité',
      'configureSecurityNotifications': 'Configurer les notifications de sécurité',
      'dataExport': 'Export de données',
      'downloadAccountData': 'Télécharger vos données',
      'passwordUpdatedSuccess': 'Mot de passe mis à jour !',
      'autoLockTimer': 'Minuteur de verrouillage auto',
      'minute': 'minute',
      'minutes': 'minutes',
      'never': 'Jamais',
      'currentDevice': 'Appareil actuel',
      'lastActive': 'Dernière activité :',
      'close': 'Fermer',
      'signOutOthers': 'Déconnecter les autres',
      'allSessionsSignedOut': 'Toutes les autres sessions déconnectées',
      'configureSecurityDescription': 'Configurez quand vous souhaitez recevoir des notifications de sécurité.',
      'downloadDataDescription': 'Téléchargez une copie de vos données de compte. Cela peut prendre quelques minutes.',
      'dataExportStarted': 'Export de données démarré. Vous recevrez un email quand ce sera prêt.',
      'export': 'Exporter',
      'configure': 'Configurer',
      
      // Onboarding
      'skip': 'Passer',
      'voiceControl': 'Contrôle vocal',
      'speakNaturally': 'Parlez naturellement',
      'voiceControlDesc': 'Transformez votre productivité avec des commandes vocales intuitives. Parlez simplement et regardez vos tâches prendre vie.',
      'smartInsights': 'Informations intelligentes',
      'trackProgress': 'Suivre les progrès',
      'smartInsightsDesc': 'Obtenez des informations puissantes sur vos modèles de productivité avec de belles analyses et des rapports détaillés.',
      'privacyFirst': 'Confidentialité d\'abord',
      'stayProtected': 'Restez protégé',
      'privacyFirstDesc': 'Vos données sont cryptées et sécurisées. Profitez de fonctionnalités puissantes tout en maintenant une confidentialité complète.',
      'continueBtn': 'Continuer',
      'getStarted': 'Commencer',
      
      // Splash
      'appTagline': 'Où vos idées deviennent réalité',
      
      // Subscription
      'chooseYourPlan': 'Choisissez votre forfait',
      'upgradeExperience': 'Améliorez votre expérience de productivité vocale',
      'monthly': 'Mensuel',
      'annual': 'Annuel',
      'save20': 'Économisez 20%',
      'essential': 'Essentiel',
      'premium': 'Premium',
      'billedAnnually': 'Facturé annuellement',
      'whatsIncluded': 'Ce qui est inclus :',
      'subscriptionActive': 'L\'abonnement est actif !',
      'paymentInitError': 'Impossible d\'initialiser le paiement. Veuillez réessayer.',
      'subscriptionFailed': 'L\'abonnement a échoué',
      'subscriptionSuccess': 'Succès ! Votre abonnement est actif.',
      'paymentCanceled': 'Le processus de paiement a été annulé.',
      'paymentFailed': 'Le paiement a échoué',
      'unexpectedPaymentError': 'Une erreur inattendue s\'est produite',
      
      // Plan Features
      'sendReplyEmails': 'Envoyer/Répondre aux emails par voix',
      'voiceTaskCreation': 'Création de tâches vocales',
      'voiceCalendarEvents': 'Événements de calendrier vocaux',
      'textNotifications': 'Notifications texte',
      'centralizedDashboard': 'Tableau de bord centralisé',
      'secureStorage2GB': 'Stockage sécurisé (2 Go)',
      'priorityEmails10': 'Jusqu\'à 10 emails prioritaires',
      'basicVoiceRecognition': 'Reconnaissance vocale basique',
      'standardSupport': 'Support client standard',
      'voiceEmailReading': 'Lecture d\'emails vocale + Recherche intelligente',
      'smartReminders': 'Rappels intelligents',
      'completeVoiceTask': 'Gestion complète des tâches vocales',
      'interactiveVoiceNotif': 'Notifications vocales interactives',
      'advancedVoiceCommands': 'Commandes vocales avancées + IA naturelle',
      'secureStorage1TB': 'Stockage sécurisé étendu (1 To)',
      'hybridConcierge': 'Service de conciergerie hybride',
      'priorityEmails20': 'Jusqu\'à 20 emails prioritaires',
      'advancedVoiceContext': 'Reconnaissance vocale avancée avec contexte',
      'prioritySupport': 'Support client prioritaire',
      'customVoiceTraining': 'Formation personnalisée aux commandes vocales',
      'productivityIntegration': 'Intégration avec outils de productivité',
      
      // Current Plan
      'currentPlan': 'Forfait actuel',
      'essentialPlan': 'Forfait essentiel',
      'premiumPlan': 'Forfait premium',
      'essentialPlanDesc': 'Vous avez accès aux fonctionnalités vocales essentielles et aux outils de productivité de base.',
      'premiumPlanDesc': 'Vous avez accès à toutes les fonctionnalités premium, y compris les capacités d\'IA avancées et le stockage illimité.',
      'backToHome': 'Retour à l\'accueil',
      'emailDeleteFailed': 'Échec de la suppression de l\'email',
      'emailDeleteError': 'Erreur lors de la suppression de l\'email',
      'tapToPlay': 'Appuyez pour lire',
      'compose': 'Nouveau message',
      'editMessage': 'Modifier le message',
      'to': 'À',
      'cc': 'Cc',
      'bcc': 'Cci',
      'subject': 'Objet',
      'send': 'Envoyer',
      'sending': 'Envoi...',
      'attachments': 'Pièces jointes',
      'total': 'Total',
      'messageSent': 'Message envoyé avec succès',
      'draftSaved': 'Brouillon enregistré avec succès',
      'draftEmpty': 'Le brouillon est vide',
      'attachmentRemoved': 'Pièce jointe supprimée',
      'fileTooLarge': 'Le fichier est trop volumineux (max 25 Mo)',
      'voiceRefinementLimit': 'Limite de raffinement vocal atteinte (2/2). Modifiez manuellement.',
      'listeningTapStop': 'Écoute... Appuyez sur stop pour affiner.',
      'transcribing': 'Transcription...',
      'noVoiceDetected': 'Aucune voix détectée',
      'refinementFailed': 'Échec du raffinement',
      'emailRefined': 'Email affiné par l\'IA',
      'pleaseAddRecipient': 'Veuillez ajouter au moins un destinataire',
      'pleaseAddSubject': 'Veuillez ajouter un objet',
      'unknownError': 'Erreur inconnue',
      'draftSaveFailed': 'Échec de l\'enregistrement du brouillon',
      'filesAdded': 'Fichier(s) ajouté(s)',
      'imagesAdded': 'Image(s) ajoutée(s)',
      'errorPickingFiles': 'Erreur lors de la sélection des fichiers',
      'errorPickingImages': 'Erreur lors de la sélection des images',
      'errorSendingEmail': 'Erreur lors de l\'envoi de l\'email',
      'errorSavingDraft': 'Erreur lors de l\'enregistrement du brouillon',
      'important': 'Important',
      'errorSummarizing': 'Erreur lors du résumé',
      'confirmDeleteEmailPermanent': 'Êtes-vous sûr de vouloir supprimer cet email ? Cette action est irréversible.',
      'unknownSender': 'Expéditeur inconnu',
      'unknown': 'Inconnu',
      'wrote': 'a écrit',
      'forwardedMessage': 'Message transféré',
      'from': 'De',
      'date': 'Date',
      'reply': 'Répondre',
      'replyAll': 'Répondre à tous',
      'forward': 'Transférer',



    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

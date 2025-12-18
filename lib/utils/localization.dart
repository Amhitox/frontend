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
  String get total => _localizedValues[locale.languageCode]!['total']!;
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
      'unread': 'Unread',
      'noNotifications': 'No Notifications',
      'caughtUp': 'You\'re all caught up!',
      'playSummary': 'Play Summary',
      'confirmMarkAllRead': 'Are you sure you want to mark all notifications as read?',

      // Analytics
      'analyticsDashboard': 'Analytics Dashboard',
      'analyticsSubtitle': 'Track your productivity & performance',
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
      'nextMonth': 'Mois prochain',
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
          'Saisissez votre nom de catégorie personnalisée',
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
      'unread': 'Non lu',
      'noNotifications': 'Aucune notification',
      'caughtUp': 'Vous êtes à jour !',
      'playSummary': 'Écouter le résumé',
      'confirmMarkAllRead': 'Êtes-vous sûr de vouloir marquer toutes les notifications comme lues ?',

      // Analytics
      'analyticsDashboard': 'Tableau de bord',
      'analyticsSubtitle': 'Suivez votre productivité et performance',
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

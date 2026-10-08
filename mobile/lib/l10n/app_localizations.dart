import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Anbu Matrimony'**
  String get appName;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @shortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get shortlist;

  /// No description provided for @shortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get shortlisted;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful introductions, at your pace.'**
  String get discoverSubtitle;

  /// No description provided for @profilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'profiles to explore'**
  String get profilesAvailable;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @women.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get women;

  /// No description provided for @men.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get men;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @minimumAge.
  ///
  /// In en, this message translates to:
  /// **'Minimum age'**
  String get minimumAge;

  /// No description provided for @maximumAge.
  ///
  /// In en, this message translates to:
  /// **'Maximum age'**
  String get maximumAge;

  /// No description provided for @ageRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter ages from 18 to 100, with minimum not above maximum.'**
  String get ageRangeError;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @verifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles only'**
  String get verifiedOnly;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @noProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No profiles found'**
  String get noProfilesFound;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try broadening your filters to see more introductions.'**
  String get tryDifferentFilters;

  /// No description provided for @profilesCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be loaded'**
  String get profilesCouldNotLoad;

  /// No description provided for @discoveryNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery needs a server connection'**
  String get discoveryNotConfiguredTitle;

  /// No description provided for @discoveryNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Start the API and provide API_BASE_URL, ACCESS_TOKEN, and PROFILE_ID to browse active profiles.'**
  String get discoveryNotConfigured;

  /// No description provided for @loadMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'Load more profiles'**
  String get loadMoreProfiles;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @shortlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist is waiting'**
  String get shortlistEmptyTitle;

  /// No description provided for @shortlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save profiles you would like to revisit, and they will appear here.'**
  String get shortlistEmpty;

  /// No description provided for @addedToShortlist.
  ///
  /// In en, this message translates to:
  /// **'Added to your shortlist.'**
  String get addedToShortlist;

  /// No description provided for @removedFromShortlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from your shortlist.'**
  String get removedFromShortlist;

  /// No description provided for @expressInterest.
  ///
  /// In en, this message translates to:
  /// **'Express interest'**
  String get expressInterest;

  /// No description provided for @interestConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Send a respectful introduction? The other member can respond when ready.'**
  String get interestConfirmation;

  /// No description provided for @sendInterest.
  ///
  /// In en, this message translates to:
  /// **'Send interest'**
  String get sendInterest;

  /// No description provided for @interestSent.
  ///
  /// In en, this message translates to:
  /// **'Your interest has been sent.'**
  String get interestSent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for report'**
  String get reportReason;

  /// No description provided for @reportFakeDetails.
  ///
  /// In en, this message translates to:
  /// **'Incorrect or fake details'**
  String get reportFakeDetails;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportInappropriate;

  /// No description provided for @reportAlreadyMarried.
  ///
  /// In en, this message translates to:
  /// **'Already married'**
  String get reportAlreadyMarried;

  /// No description provided for @reportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get reportDetailsOptional;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your report was submitted for review.'**
  String get reportSubmitted;

  /// No description provided for @blockConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This member will no longer appear in your discovery, shortlist, or interest activity.'**
  String get blockConfirmation;

  /// No description provided for @profileBlocked.
  ///
  /// In en, this message translates to:
  /// **'This profile has been blocked.'**
  String get profileBlocked;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'A thoughtful connection starts here'**
  String get profileTagline;

  /// No description provided for @profileDetailsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A little more about them'**
  String get profileDetailsEyebrow;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetails;

  /// No description provided for @contactEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Get to know them better'**
  String get contactEyebrow;

  /// No description provided for @contactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact details are not available for this profile.'**
  String get contactUnavailable;

  /// No description provided for @profileNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Profile server settings are missing. Start the API and provide API_BASE_URL, ACCESS_TOKEN, and PROFILE_ID.'**
  String get profileNotConfigured;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @caste.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get caste;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get contactDetails;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'A 90-day Premium Pass is required to view this information.'**
  String get premiumRequired;

  /// No description provided for @premiumUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact details with a 90-day Premium Pass.'**
  String get premiumUnlockHint;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'View Premium Pass'**
  String get upgrade;

  /// No description provided for @profilePendingApproval.
  ///
  /// In en, this message translates to:
  /// **'This photo is awaiting approval.'**
  String get profilePendingApproval;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfile;

  /// No description provided for @blockProfile.
  ///
  /// In en, this message translates to:
  /// **'Block profile'**
  String get blockProfile;
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
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

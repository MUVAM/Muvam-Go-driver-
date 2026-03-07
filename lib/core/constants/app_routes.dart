enum AppRoutes {
  splash('/'),
  onboarding('/onboarding'),

  otp('/otp'),
  createAccount('/create-account'),
  deleteAccount('/delete-account'),
  stateSelection('/state-selection'),
  lgaSelection('/lga-selection'),

  home('/home'),

  activeTrip('/active-trip'),
  historyCompleted('/history-completed'),
  historyCancelled('/history-cancelled'),
  tripDetails('/trip-details'),
  editPrebooking('/edit-prebooking'),
  tip('/tip'),
  customTip('/custom-tip'),

  chat('/chat'),
  call('/call'),

  profile('/profile'),
  editProfile('/edit-profile'),
  editFullName('/edit-full-name'),
  biometricLock('/biometric-lock'),
  appLockSettings('/app-lock-settings'),

  addFavourite('/add-favourite'),
  addHome('/add-home'),
  mapPicker('/map-picker'),
  mapSelection('/map-selection'),
  services('/services'),
  comingSoon('/coming-soon'),
  paymentWebView('/payment-webview'),

  wallet('/wallet'),
  walletEmpty('/wallet-empty'),
  accountCreated('/account-created'),
  getAccount('/get-account'),
  howToFund('/how-to-fund'),
  buyGiftCard('/buy-gift-card'),

  referral('/referral'),
  referralRules('/referral-rules'),
  promoCode('/promo-code'),
  aboutUs('/about-us'),
  faq('/faq'),

  bankSelection('/bank-selection'),
  withdrawal('/withdrawal'),
  withdrawalSuccess('/withdrawal-success'),
  howToWithdraw('/how-to-withdraw'),

  ratings('/ratings'),
  carInformation('/car-information'),
  myCars('/my-cars'),
  appLock('/app-lock'),
  updateLocation('/update-location'),

  kycVerification('/kyc-verification'),

  driverLicense('/driver-license'),
  vehicleInsurance('/vehicle-insurance'),
  vehicleRegistration('/vehicle-registration'),
  vehiclePhotos('/vehicle-photos'),
  documentVerificationSuccess('/document-verification-success'),
  kycVerificationPage('/kyc-verification-page'),
  accountVerificationSuccess('/account-verification-success'),
  biometricSetup('/biometric-setup'),
  analytics('/analytics');

  const AppRoutes(this.urlPath);
  final String urlPath;
}

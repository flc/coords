angular.module 'app', [
  'ngSanitize',
  'ui.router',
  'mgcrea.ngStrap',
  'uiGmapgoogle-maps'  # https://github.com/angular-ui/angular-google-maps
]


# allow for use in controllers, unit tests
.constant('_', window._)


.config (uiGmapGoogleMapApiProvider) ->
  uiGmapGoogleMapApiProvider.configure
    # key: @@GOOGLE_MAPS_API_KEY
    v: '3.20'
    libraries: 'weather,geometry,visualization'
    # language: 'en'


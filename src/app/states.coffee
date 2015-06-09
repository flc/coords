angular.module "app"


.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider
    .state "home",
      url: "/",
      templateUrl: "app/main/main.html",
      controller: "MainCtrl"
      resolve:
        maps: (uiGmapGoogleMapApi) ->
          uiGmapGoogleMapApi

  $urlRouterProvider.otherwise '/'

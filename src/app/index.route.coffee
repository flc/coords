angular.module 'app'


.config ($stateProvider, $urlRouterProvider) ->
  'ngInject'
  $stateProvider
    .state 'home',
      url: '/'
      templateUrl: 'app/main/main.html'
      controller: 'MainCtrl'
      controllerAs: 'main'

  $urlRouterProvider.otherwise '/'

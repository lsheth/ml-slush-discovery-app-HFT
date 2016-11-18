(function () {
  'use strict';

  angular.module('app')
    .run(['loginService', function(loginService) {
      loginService.protectedRoutes(['root.create', 'root.profile', 'root.setup']);
    }])
    .config(Config);

  Config.$inject = ['$stateProvider', '$urlMatcherFactoryProvider',
    '$urlRouterProvider', '$locationProvider'
  ];

  function Config(
    $stateProvider,
    $urlMatcherFactoryProvider,
    $urlRouterProvider,
    $locationProvider) {

    $urlRouterProvider.otherwise('/');
    $locationProvider.html5Mode(true);

    function valToFromString(val) {
      return val !== null ? val.toString() : val;
    }

    function regexpMatches(val) { // jshint validthis:true
      return this.pattern.test(val);
    }

    $urlMatcherFactoryProvider.type('path', {
      encode: valToFromString,
      decode: valToFromString,
      is: regexpMatches,
      pattern: /.+/
    });

    $stateProvider
      .state('root', {
        url: '',
        // abstract: true,
        templateUrl: 'app/root/root.html',
        controller: 'RootCtrl',
        controllerAs: 'ctrl',
        resolve: {
          user: function(userService) {
            return userService.getUser();
          }
        }
      })
      .state('root.search', {
        url: '/',
        templateUrl: 'app/search/search.html',
        controller: 'SearchCtrl',
        controllerAs: 'ctrl'
      })
      .state('root.create', {
        url: '/create',
        templateUrl: 'app/create/create.html',
        controller: 'CreateCtrl',
        controllerAs: 'ctrl',
        resolve: {
          stuff: function() {
            return null;
          }
        }
      })
      .state('root.view', {
        url: '/detail{uri:path}',
        params: {
          uri: {
            squash: false,
            value: null
          }
        },
        templateUrl: 'app/detail/detail.html',
        controller: 'DetailCtrl',
        controllerAs: 'ctrl',
        resolve: {
          doc: function(MLRest, $stateParams) {
            var uri = $stateParams.uri;
            return MLRest
              .getDocument(uri, { format: 'json', transform: 'data-to-html-display' })
              .then(function(response) {
                return response;
              });
          }
        }
      })
      .state('root.profile', {
        url: '/profile',
        templateUrl: 'app/user/profile.html',
        controller: 'ProfileCtrl',
        controllerAs: 'ctrl'
      })
      .state('root.login', {
        url: '/login?state&params',
        templateUrl: 'app/login/login-full.html',
        controller: 'LoginFullCtrl',
        controllerAs: 'ctrl'
      })
      .state('root.setup', {
        url: '/setup',
        templateUrl: 'app/setup/index.html',
        controller: 'SetupCtrl',
        controllerAs: 'ctrl'
      })
      .state('root.analytics-dashboard', {
        url: '/analytics-dashboard',
        template: '<ml-analytics-dashboard></ml-analytics-dashboard>',
        controller: function() {}
      });
  }
}());

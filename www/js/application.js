angular.module('starter', ['ionic', 'starter.controllers', 'starter.services']).run(function($ionicPlatform) {
  $ionicPlatform.ready(function() {
    if (window.cordova && window.cordova.plugins.Keyboard) {
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
    }
    if (window.StatusBar) {
      StatusBar.styleDefault();
    }
  });
}).config(function($stateProvider, $urlRouterProvider) {
  $stateProvider.state('tab', {
    url: '/tab',
    abstract: true,
    templateUrl: 'templates/tabs.html'
  }).state('tab.compass', {
    url: '/compass',
    views: {
      'tab-compass': {
        templateUrl: 'templates/tab-compass.html',
        controller: 'CompassCtrl'
      }
    }
  }).state('tab.chats', {
    url: '/chats',
    views: {
      'tab-chats': {
        templateUrl: 'templates/tab-chats.html',
        controller: 'ChatsCtrl'
      }
    }
  }).state('tab.chat-detail', {
    url: '/chats/:chatId',
    views: {
      'tab-chats': {
        templateUrl: 'templates/chat-detail.html',
        controller: 'ChatDetailCtrl'
      }
    }
  }).state('tab.account', {
    url: '/account',
    views: {
      'tab-account': {
        templateUrl: 'templates/tab-account.html',
        controller: 'AccountCtrl'
      }
    }
  });
  $urlRouterProvider.otherwise('/tab/compass');
});

angular.module('starter.controllers', ['ngCordova']).controller('CompassCtrl', function($scope, $ionicPlatform, $cordovaDeviceMotion, $cordovaDeviceOrientation, $cordovaGeolocation) {
  var COLD_PATTERN, HEADING_RANGE, HOT_PATTERN, MAGNETIC_MODE, TRUE_HEADING_MODE, WARM_PATTERN, checkTraining, onAccelerometerError, onAccelerometerSuccess, onCompassError, onCompassSuccess, onGeoError, onGeoSuccess, self, startAccelerometer, startCompass, startGeolocation, stopAccelerometer, stopCompass, stopGeolocation;
  this.myLat = 0;
  this.myLng = 0;
  $scope.bearing = void 0;
  $scope.distance = void 0;
  $scope.cDirectionMagnetic = '';
  $scope.cDirection = '';
  $scope.cDirectionTrue = '';
  $scope.heading = null;
  this.dataStatus = 0;
  self = this;
  $scope.log = "";
  $scope.isTraining = false;
  $scope.trainingDir = null;
  this.dirIndexMagnetic = -1;
  this.dirIndexTrue = -1;
  HOT_PATTERN = [100, 50, 100, 50, 100];
  WARM_PATTERN = [50, 150, 50, 150, 50];
  COLD_PATTERN = [30, 200, 30, 200, 30];
  $scope.MODES = ["Magnetic", "True Heading"];
  MAGNETIC_MODE = 0;
  TRUE_HEADING_MODE = 1;
  $scope.compassMode = TRUE_HEADING_MODE;
  this.directions = ['N', 'NE', 'NE', 'E', 'E', 'SE', 'SE', 'S', 'S', 'SW', 'SW', 'W', 'W', 'NW', 'NW', 'N'];
  this.trainingDirections = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  $scope.toggleCompassMode = function() {
    return $scope.compassMode = $scope.compassMode === TRUE_HEADING_MODE ? MAGNETIC_MODE : TRUE_HEADING_MODE;
  };
  $scope.toggleTrainingMode = function() {
    return $scope.isTraining = !$scope.isTraining;
  };
  $scope.setTrainingDir = function(dir) {
    $scope.trainingDir = dir;
    navigator.vibrate(0);
    return checkTraining();
  };
  checkTraining = function() {
    var diff, dirDegree, trainingDegree;
    if ($scope.isTraining) {
      if ($scope.trainingDir) {
        if ($scope.trainingDir === $scope.cDirection) {
          return navigator.vibrate(1000);
        } else {
          trainingDegree = self.trainingDirections.indexOf($scope.trainingDir) * 45;
          dirDegree = $scope.compassMode === TRUE_HEADING_MODE ? $scope.heading.trueHeading : $scope.heading.magneticHeading;
          diff = Math.abs(trainingDegree - dirDegree);
          if (diff <= 35 || 360 - diff <= 35) {
            return navigator.vibrate(HOT_PATTERN);
          } else if (diff <= 55 || 360 - diff <= 55) {
            return navigator.vibrate(WARM_PATTERN);
          } else if (diff <= 75 || 360 - diff <= 75) {
            return navigator.vibrate(COLD_PATTERN);
          }
        }
      }
    }
  };
  startGeolocation = function() {
    var options;
    options = {
      timeout: 30000,
      enableHighAccuracy: true
    };
    self.geoWatch = $cordovaGeolocation.watchPosition(options);
    self.geoWatch.then(null, onGeoError, onGeoSuccess);
  };
  stopGeolocation = function() {
    if (self.geoWatch) {
      self.geoWatch.clearWatch();
      self.geoWatch = null;
    }
  };
  onGeoSuccess = function(position) {
    'use strict';
    $scope.position = position;
    self.myLat = position.coords.latitude;
    self.myLng = position.coords.longitude;
  };
  onGeoError = function() {
    $scope.log += 'onError=.';
  };
  startCompass = function() {
    var options;
    if (!navigator.compass) {
      return;
    }
    options = {
      frequency: 100
    };
    self.compassWatch = $cordovaDeviceOrientation.watchHeading(options);
    self.compassWatch.then(null, onCompassError, onCompassSuccess);
  };
  stopCompass = function() {
    if (self.compassWatch) {
      self.compassWatch.clearWatch();
      self.compassWatch = null;
    }
  };
  HEADING_RANGE = 22.5;
  onCompassSuccess = function(heading) {
    var oldDirection;
    $scope.heading = heading;
    self.dirIndexMagnetic = Math.abs(parseInt(heading.magneticHeading / HEADING_RANGE) + 0);
    self.dirIndexTrue = Math.abs(parseInt(heading.trueHeading / HEADING_RANGE) + 0);
    if (self.dirIndexMagnetic > self.directions.length) {
      self.dirIndexMagnetic = 0;
    }
    if (self.dirIndexTrue > self.directions.length) {
      self.dirIndexTrue = 0;
    }
    oldDirection = $scope.cDirection;
    if ($scope.compassMode === TRUE_HEADING_MODE) {
      self.dirIndex = self.dirIndexTrue;
      $scope.cDirection = $scope.cDirectionTrue;
    } else {
      self.dirIndex = self.dirIndexMagnetic;
      $scope.cDirection = $scope.cDirectionMagnetic;
    }
    if ($scope.cDirection !== oldDirection) {
      checkTraining();
    }
    $scope.cDirectionMagnetic = self.directions[self.dirIndexMagnetic];
    $scope.cDirectionTrue = self.directions[self.dirIndexTrue];
  };
  onCompassError = function(compassError) {
    $scope.log += 'onError=.' + compassError.code;
  };
  startAccelerometer = function() {
    var options;
    if (!navigator.accelerometer) {
      return;
    }
    options = {
      frequency: 100
    };
    self.motionWatch = $cordovaDeviceMotion.watchAcceleration(options);
    self.motionWatch.then(null, onAccelerometerError, onAccelerometerSuccess);
  };
  stopAccelerometer = function() {
    if (self.motionWatch) {
      self.motionWatch.clearWatch();
      self.motionWatch = null;
    }
  };
  onAccelerometerSuccess = function(acceleration) {
    $scope.acceleration = acceleration;
  };
  onAccelerometerError = function() {
    $scope.log += 'onError=.';
  };
  $ionicPlatform.ready(function() {
    startCompass();
    return startGeolocation();
  });
  $ionicPlatform.on('pause', function() {
    stopCompass();
    return stopGeolocation();
  });
  return $ionicPlatform.on('resume', function() {
    startCompass();
    return startGeolocation();
  });
}).controller('ChatsCtrl', function($scope, Chats) {
  $scope.chats = Chats.all();
  $scope.remove = function(chat) {
    Chats.remove(chat);
  };
}).controller('ChatDetailCtrl', function($scope, $stateParams, Chats) {
  $scope.chat = Chats.get($stateParams.chatId);
}).controller('AccountCtrl', function($scope) {
  $scope.settings = {
    enableFriends: true
  };
});

angular.module('starter.services', []).factory('Chats', function() {
  var chats;
  chats = [
    {
      id: 0,
      name: 'Ben Sparrow',
      lastText: 'You on your way?',
      face: 'https://pbs.twimg.com/profile_images/514549811765211136/9SgAuHeY.png'
    }, {
      id: 1,
      name: 'Max Lynx',
      lastText: 'Hey, it\'s me',
      face: 'https://avatars3.githubusercontent.com/u/11214?v=3&s=460'
    }, {
      id: 2,
      name: 'Andrew Jostlin',
      lastText: 'Did you get the ice cream?',
      face: 'https://pbs.twimg.com/profile_images/491274378181488640/Tti0fFVJ.jpeg'
    }, {
      id: 3,
      name: 'Adam Bradleyson',
      lastText: 'I should buy a boat',
      face: 'https://pbs.twimg.com/profile_images/479090794058379264/84TKj_qa.jpeg'
    }, {
      id: 4,
      name: 'Perry Governor',
      lastText: 'Look at my mukluks!',
      face: 'https://pbs.twimg.com/profile_images/491995398135767040/ie2Z_V6e.jpeg'
    }
  ];
  return {
    all: function() {
      return chats;
    },
    remove: function(chat) {
      chats.splice(chats.indexOf(chat), 1);
    },
    get: function(chatId) {
      var i;
      i = 0;
      while (i < chats.length) {
        if (chats[i].id === parseInt(chatId)) {
          return chats[i];
        }
        i++;
      }
      return null;
    }
  };
});

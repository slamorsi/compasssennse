angular.module('starter.controllers', [ 'ngCordova'])
.controller('CompassCtrl', 
($scope, $ionicPlatform, $cordovaDeviceMotion, $cordovaDeviceOrientation, $cordovaGeolocation) ->
  # calulate $scope.distance and $scope.bearing value for each of the points wrt gps lat/lng        
  @myLat = 0
  @myLng = 0
  $scope.bearing = undefined
  $scope.distance = undefined
  $scope.cDirectionMagnetic = ''
  $scope.cDirection = ''
  $scope.cDirectionTrue = ''
  $scope.heading = null
  @dataStatus = 0
  self = @
  $scope.log = ""
  $scope.isTraining = false;
  $scope.trainingDir = null;
  @dirIndexMagnetic = -1
  @dirIndexTrue = -1

  HOT_PATTERN = [100,50,100,50,100]
  WARM_PATTERN = [50,150,50,150,50]
  COLD_PATTERN = [30,200,30,200,30]
  $scope.MODES = ["Magnetic", "True Heading"]
  MAGNETIC_MODE = 0
  TRUE_HEADING_MODE = 1
  $scope.compassMode = TRUE_HEADING_MODE
  @directions = [
    'N'
    'NE'
    'NE'
    'E'
    'E'
    'SE'
    'SE'
    'S'
    'S'
    'SW'
    'SW'
    'W'
    'W'
    'NW'
    'NW'
    'N'
    ]

  @trainingDirections = [
    'N'
    'NE'
    'E'
    'SE'
    'S'
    'SW'
    'W'
    'NW'
    ]

  $scope.toggleCompassMode = ->
    $scope.compassMode = if $scope.compassMode == TRUE_HEADING_MODE then MAGNETIC_MODE else TRUE_HEADING_MODE

  $scope.toggleTrainingMode = ->
    $scope.isTraining = !$scope.isTraining

  $scope.setTrainingDir = (dir)->
    $scope.trainingDir = dir
    navigator.vibrate(0)
    checkTraining()

  checkTraining = ()->
    if ($scope.isTraining)
      if ($scope.trainingDir)
        if($scope.trainingDir == $scope.cDirection)
          navigator.vibrate(1000)
        else
          trainingDegree = self.trainingDirections.indexOf($scope.trainingDir) * 45
          dirDegree = if $scope.compassMode == TRUE_HEADING_MODE then $scope.heading.trueHeading else $scope.heading.magneticHeading

          diff = Math.abs(trainingDegree - dirDegree)
          if (diff <= 35 || 360-diff <= 35)
            navigator.vibrate(HOT_PATTERN)
          else if (diff <= 55 || 360-diff <= 55)
            navigator.vibrate(WARM_PATTERN)
          else if (diff <= 75 || 360-diff <= 75)
            navigator.vibrate(COLD_PATTERN)


  # relativePosition = (i) ->
  #   pinLat = pin[i].lat
  #   pinLng = pin[i].lng
  #   dLat = (myLat - pinLat) * Math.PI / 180
  #   dLon = (myLng - pinLng) * Math.PI / 180
  #   lat1 = pinLat * Math.PI / 180
  #   lat2 = myLat * Math.PI / 180
  #   y = Math.sin(dLon) * Math.cos(lat2)
  #   x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)
  #   $scope.bearing = Math.atan2(y, x) * 180 / Math.PI
  #   $scope.bearing = $scope.bearing + 180
  #   pin[i]['$scope.bearing'] = $scope.bearing
  #   a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2)
  #   c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  #   $scope.distance = 3958.76 * c
  #   pin[i]['$scope.distance'] = $scope.distance
  #   return

  # calculate direction of points and display        

  # calculateDirection = (degree) ->
  #   detected = 0
  #   # $('#spot').html ''
  #   i = undefined
  #   i = 0
  #   while i < pin.length
  #     if Math.abs(pin[i].$scope.bearing - degree) <= 20
  #       away = undefined
  #       fontSize = undefined
  #       fontColor = undefined
  #       # varry font size based on $scope.distance from gps location
  #       if pin[i].$scope.distance > 1500
  #         away = Math.round(pin[i].$scope.distance)
  #         fontSize = '16'
  #         fontColor = '#ccc'
  #       else if pin[i].$scope.distance > 500
  #         away = Math.round(pin[i].$scope.distance)
  #         fontSize = '24'
  #         fontColor = '#ddd'
  #       else
  #         away = pin[i].$scope.distance.toFixed(2)
  #         fontSize = '30'
  #         fontColor = '#eee'
  #       $('#spot').append '<div class="name" data-id="' + i + '" style="margin-left:' + (pin[i].$scope.bearing - degree) * 5 + 50 + 'px;width:' + $(window).width() - 100 + 'px;font-size:' + fontSize + 'px;color:' + fontColor + '">' + pin[i].name + '<div class="$scope.distance">' + away + ' miles away</div></div>'
  #       detected = 1
  #     else
  #       if !detected
  #         $('#spot').html ''
  #     i++
  #   return

  # Start watching the geolocation        

  startGeolocation = ->
    options = timeout: 30000, enableHighAccuracy: true
    self.geoWatch = $cordovaGeolocation.watchPosition(options)
    self.geoWatch.then(
      null,
      onGeoError, 
      onGeoSuccess
    )
    return

  # Stop watching the geolocation

  stopGeolocation = ->
    if self.geoWatch
      self.geoWatch.clearWatch()
      self.geoWatch = null
    return

  # onSuccess: Get the current location

  onGeoSuccess = (position) ->
    'use strict'
    $scope.position = position
    # document.getElementById('geolocation').innerHTML = 'Latitude: ' + position.coords.latitude + '<br />' + 'Longitude: ' + position.coords.longitude
    self.myLat = position.coords.latitude
    self.myLng = position.coords.longitude
    # if !dataStatus
    #   loadData()
    return

  # onError: Failed to get the location

  onGeoError = ->
    $scope.log += 'onError=.'
    # document.getElementById('log').innerHTML += 'onError=.'
    return

  # Start watching the compass

  startCompass = ->
    if !navigator.compass
      return
    options = frequency: 100
    self.compassWatch = $cordovaDeviceOrientation.watchHeading(options)
    self.compassWatch.then(null, onCompassError, onCompassSuccess)
    return

  # Stop watching the compass

  stopCompass = ->
    if self.compassWatch
      self.compassWatch.clearWatch();
      self.compassWatch = null

    return

  HEADING_RANGE = 22.5
  # onSuccess: Get the current heading
  onCompassSuccess = (heading) ->
    $scope.heading = heading
    self.dirIndexMagnetic = Math.abs(parseInt(heading.magneticHeading / HEADING_RANGE) + 0)
    self.dirIndexTrue = Math.abs(parseInt(heading.trueHeading / HEADING_RANGE) + 0)

    if self.dirIndexMagnetic > self.directions.length
      self.dirIndexMagnetic = 0

    if self.dirIndexTrue > self.directions.length
      self.dirIndexTrue = 0

    oldDirection = $scope.cDirection

    if($scope.compassMode == TRUE_HEADING_MODE)
      self.dirIndex = self.dirIndexTrue
      $scope.cDirection = $scope.cDirectionTrue
    else
      self.dirIndex = self.dirIndexMagnetic
      $scope.cDirection = $scope.cDirectionMagnetic

    #only check if direction completely changed
    if($scope.cDirection != oldDirection)
      checkTraining()

    $scope.cDirectionMagnetic = self.directions[self.dirIndexMagnetic]
    $scope.cDirectionTrue = self.directions[self.dirIndexTrue]
    # document.getElementById('compass').innerHTML = heading.magneticHeading + '<br>' + direction
    # document.getElementById('direction').innerHTML = direction
    # degree = heading.magneticHeading
    # if dataStatus != 'loading'
    # calculateDirection degree
    return

  # onError: Failed to get the heading

  onCompassError = (compassError) ->
    $scope.log += 'onError=.' + compassError.code
    # document.getElementById('log').innerHTML += 'onError=.' + compassError.code
    return

  # Start checking the accelerometer

  startAccelerometer = ->
    if !navigator.accelerometer
      return
    options = frequency: 100
    self.motionWatch = $cordovaDeviceMotion.watchAcceleration(options)
    self.motionWatch.then(null, onAccelerometerError, onAccelerometerSuccess
    )
    return

  # Stop checking the accelerometer

  stopAccelerometer = ->
    # if self.watchAccelerometerID
    #   $cordovaDeviceMotion.clearWatch self.watchAccelerometerID
    #   self.watchAccelerometerID = null
    if self.motionWatch
      self.motionWatch.clearWatch()
      self.motionWatch = null
    return

  # onSuccess: Get current accelerometer values

  onAccelerometerSuccess = (acceleration) ->
    # for debug purpose to print out accelerometer values
    # element = document.getElementById('accelerometer')
    # element.innerHTML = 'Acceleration X: ' + acceleration.x + '<br />' + 'Acceleration Y: ' + acceleration.y + '<br />' + 'Acceleration Z: ' + acceleration.z
    $scope.acceleration = acceleration
    # if acceleration.y > 7
    #   $('#arView').fadeIn()
    #   $('#topView').hide()
    #   document.getElementById('body').style.background = '#d22'
    # else
    #   $('#arView').hide()
    #   $('#topView').fadeIn()
    #   document.getElementById('body').style.background = '#fff'
    return

  # onError: Failed to get the acceleration

  onAccelerometerError = ->
    $scope.log += 'onError=.'
    # document.getElementById('log').innerHTML += 'onError.'
    return

  $ionicPlatform.ready(()->
    
    # startAccelerometer()
    startCompass()
    startGeolocation()
  )

  $ionicPlatform.on('pause', ()->
    # stopAccelerometer()
    stopCompass()
    stopGeolocation()
  )

  $ionicPlatform.on('resume', ()->
    # startAccelerometer()
    startCompass()
    startGeolocation()
  )

  
)
.controller('ChatsCtrl', ($scope, Chats) ->
  $scope.chats = Chats.all()

  $scope.remove = (chat) ->
    Chats.remove chat
    return

  return
).controller('ChatDetailCtrl', ($scope, $stateParams, Chats) ->
  $scope.chat = Chats.get($stateParams.chatId)
  return
).controller 'AccountCtrl', ($scope) ->
  $scope.settings = enableFriends: true
  return
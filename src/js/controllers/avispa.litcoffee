    vespaControllers = angular.module('vespaControllers')

    vespaControllers.controller 'avispaCtrl', ($scope, VespaLogger) ->

      $scope.objects ?= {}
      $scope.parent ?= [null]

      $scope.avispa = new Avispa
        el: $('#surface svg')

      $('#surface').append $scope.avispa.$el

When we update, first clear the Avispas stuff
TODO: Make avispa clear itself.

      $scope.$on 'lobsterUpdate', (event, data)->
        $('#surface svg .objects')[0].innerHTML = ''
        $('#surface svg .links')[0].innerHTML = ''
        $('#surface svg .labels')[0].innerHTML = ''
        $('#surface svg .groups')[0].innerHTML = ''
        $scope.json_lobster = JSON.parse(data.payload)
        $scope.avispa = new Avispa
          el: $('#surface svg')

        console.log "Got lobsterUpdate event!"
        $scope.parseDomain($scope.json_lobster)


The following is more or less mapped from the backbone style code.
ID's MUST be fully qualified, or Avispa renders horribly wrong.

      fqid = (id, parent)->
        if parent?
          return "#{parent.options._id}.#{id}"
        else
          return id

      $scope.createDomain = (id, parents, obj) ->
          uid = fqid(id, parents[0])
          domain = new Domain
              _id: uid
              parent: parents[0]
              name: obj.name
              position: obj.coords

          $scope.objects[uid] = domain

          #if parent
          #then parent.$el.append domain.$el
          #else vespa.avispa.$objects.append domain.$el
          $scope.avispa.$groups.append domain.$el

      $scope.createPort = (id, parents, obj) ->
          uid = fqid(id, parents[0])
          port = new Port
              _id: uid
              parent: parents[0]
              label: id
              position: obj.coords

          $scope.objects[uid] = port

          #parent.$el.append port.$el
          $scope.avispa.$objects.append port.$el

      $scope.createLink = (dir, left, right) ->
          link = new Avispa.Link
              direction: dir
              left: left
              right: right

          $scope.avispa.$links.append link.$el

      $scope.parseDomain = (domain) ->
          domains = x: 10
          bounds = x: 40, y: 40

          for id,subdomain of domain.subdomains
              subdomain.coords =
                  x: domains.x
                  y: 100
                  w: 220 * Object.keys(subdomain.subdomains).length || 200
                  h: 220 * Object.keys(subdomain.subdomains).length || 200

              $scope.createDomain subdomain.name, $scope.parent, subdomain

              $scope.parent.unshift($scope.objects[subdomain.name])
              $scope.parseDomain(subdomain)
              $scope.parent.shift()

              domains.x += 210

          for id, port of domain.ports
              port.coords =
                  x: bounds.x
                  y: bounds.y
                  radius: 30
                  fill: '#eeeeec'

              $scope.createPort id,  $scope.parent, port

              bounds.x += 70

          get_port_id = (parent, connection)->
            return "#{parent.subdomains[connection.domain].name}.#{connection.port}"

          for idx,connection of domain.connections
              left_port_id = 
              $scope.createLink connection.connection,
                  $scope.objects[get_port_id(domain,connection.left)],
                  $scope.objects[get_port_id(domain,connection.right)]

Lobster-specific definitions for Avispa

    class GenericModel
      constructor: (vals)->
        @observers = {}
        @data = vals

      bind: (event, func, _this)->
        @observers[event] ?= []
        @observers[event].push([ _this, func ])

      notify: (event)->
        for observer in @observers[event]
          do (observer)=>
            observer[1].apply observer[0], [@]

      get: (key)->
        return @data[key]

      set: (obj)->
        for k, v of obj
          @data[k] = v

        @notify(['change'])

    Port = Avispa.Node

    Domain = Avispa.Group.extend

        init: () ->
            @$label = $SVG('text')
                .attr('dx', '0.5em')
                .attr('dy', '1.5em')
                .text(@options.name)
                .appendTo(@$el)

            return @

        render: () ->
            @$rect
                .attr('x', @position.get('x'))
                .attr('y', @position.get('y'))
            @$label
                .attr('x', @position.get('x'))
                .attr('y', @position.get('y'))
            return @


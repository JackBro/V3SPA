
    window.Models = {}

    Views   = {}
    Dialogs = {}

    objects = {}

    models    = {}
    views     = {}
    templates = {}

    vespa = null

    #DT.Views.Plugins['controller'] = Backbone.View.extend
    #    initialize: () ->
    #        controller ?= new Controller()
    #        @$el = views.graph.$el
    #        return


This is the entry point into the V3SPA framework.

    $(document).ready () ->
        flip = true
        $('#expand').on 'click', () ->
            $('#status_pane').animate
                height: if flip then "+=8em" else "-=8em"
              ,
                200
              ,
                () ->
                    flip = !flip

        templates =
            editor: $( '#tmpl_editor' ).text()

        vespa ?= new Vespa()

        return

The main class for V3SPA framework.

    class Vespa
        constructor: () ->
            vespa = @

            @avispa = new Avispa
                el: $('#surface svg')
                #surface: $('#avispa')

            $('#surface').append @avispa.$el

            # instantiate the models
            models.nodes     = new Models.Nodes
            models.positions = new Models.Positions
            models.links     = new Models.Links
            models.tasks     = new Models.Tasks

            # setup the dispatcher for websocket messages
            @dispatch = _.clone(Backbone.Events)

            @dispatch.on 'CreateGroup', @OnCreateGroup, @
            @dispatch.on 'UpdateGroup', @OnUpdateGroup, @
            @dispatch.on 'DeleteGroup', @OnDeleteGroup, @

            @dispatch.on 'CreateNode', @OnCreateNode, @
            @dispatch.on 'UpdateNode', @OnUpdateNode, @
            @dispatch.on 'DeleteNode', @OnDeleteNode, @

            @dispatch.on 'UpdateNodeText', @OnUpdateNodeText, @

            @dispatch.on 'CreateLink', @OnCreateLink, @
            @dispatch.on 'UpdateLink', @OnUpdateLink, @
            @dispatch.on 'DeleteLink', @OnDeleteLink, @

            @dispatch.on 'UpdatePosition', @OnUpdatePosition, @
            @dispatch.on 'UpdateArc',      @OnUpdateArc,      @

            @connectionAttempts = 0
            @ConnectWS('lobster')

            @ParseTestData()

            # instantiate views and associate models
            #views.nodes = new Views.Node
            #    collection: models.nodes

            # load the boot-strapped model data
            #models.positions.reset _data.positions
            #models.nodes.reset     _data.nodes
            #models.links.reset     _data.links

            new Router()
            Backbone.history.start()

            return @

        ParseTestData: () ->
            parent = [@avispa.$objects]

            Iterate = (objs) =>
                for id,obj of objs
                    if obj.type is 'group'
                        @dispatch.trigger('CreateGroup', id, parent[0], obj)

                        parent.unshift(objects[id].$el)
                        if obj.children
                            Iterate(obj.children)
                        parent.shift()

                    else if obj.type is 'node'
                        @dispatch.trigger('CreateNode',  id, parent[0], obj)
                return

            Iterate(_data)
            return

        OnCreateGroup: (id, parent, obj) ->
            group = new Avispa.Group
                _id: id
                position: obj.position

            objects[id] = group

            parent.append group.$el
            return

        OnCreateNode: (id, parent, obj) ->
            node = new Avispa.Node
                _id: id
                parent: parent
                label: obj.label
                position: obj.position

            objects[id] = node

            parent.append node.$el
            return

Establish a websocket connection to the server.  When a connection closes it
automatically attempts to reconnect.

        ConnectWS: (channel) ->
            @timeout = Math.min(@timeout + 1, 30)

            try
                host = "ws://#{location.host}/ws/#{channel}"
                @ws = new WebSocket(host)
                @timeout = 0

            catch error
                console.log('Connection failed')
                return

            @ws.onmessage = (event) =>
                msg = JSON.parse(event.data)
                @dispatch.trigger(msg.action, msg)
                return

            @ws.onclose = (event) =>
                setTimeout () =>
                    @ConnectWS(channel)
                  ,
                    1000 * @timeout
                return

            return

Weaver  = require('weaver-sdk')
url     = require('url')

module.exports =
  class TurtleExport
    constructor: (@redis) ->

    setDatabase: (database) ->
      @database = database

    setWeaver: (weaver) ->
      @weaver = weaver

    wire: (app) ->
      self = @
      app.get('/turtle', (req, res) ->

        # Retrieve ID
        id = self.getDatasetId(req)

        if not id?
          res.end('Please supply a dataset id')
          return

        # Process and return
        self.process(id).then((result) ->
          res.attachment(id + '.ttl')
          res.setHeader('Content-Type', 'application/octet-stream')
          res.end(result, 'utf8')
        )
      )


    process: (id) ->
      # Init Weaver SDK
      if not @weaver?
        @weaver = new Weaver()
        @weaver.database(@database)

      content = @getPrefixes() + '\n\n'

      @weaver.get(id, {eagerness: -1}).bind(@).then((dataset)->

        for objId, object of dataset.objects.$links()
          for propId, property of object.properties.$links()

            value = null
            if property.object?
              value = """<#{property.object.$id()}>"""
            else
              value = """"#{property.value}"^^xsd:string"""

            content += """<#{objId}> <#{property.predicate}> #{value} .\n"""

        # Remove last new line character
        content = content.slice(0, -1)

        # Clean up Weaver SDK
        @weaver = null

        return content
      )


    getDatasetId: (request) ->
      url_parts = url.parse(request.url, true);
      query = url_parts.query;
      query.id


    getPrefixes: ->
      "@base <http://weaverplatform.com/#> .\n" +
      "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n" +
      "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n" +
      "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n" +
      "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."


    toRdfRelationName: (name) ->
      name.replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) ->
        if index is 0 then letter.toLowerCase() else letter.toUpperCase()
      ).replace(/\s+/g, '')
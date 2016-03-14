$      = require("./../test-suite")()
Weaver = require('weaver-sdk')
Turtle = require('../../src/index')

describe 'Turtle Exporting', ->
  weaver = null
  turtle = null

  beforeEach ->
    weaver = new Weaver()
    turtle = new Turtle()
    turtle.setWeaver(weaver)

  it 'should export a correct turtle file', ->

    add = (type, data, id) ->
      data = {} if not data?
      entity = new Weaver.Entity(data, type, true, id).$weaver(weaver)
      weaver.repository.add(entity)
      entity

    # Data
    dataset = add('dataset')
    dataset.objects = add('$COLLECTION')

    object = add('object', {}, 'cils31qhi00024dvail7giemn')
    dataset.objects.$push(object)

    object2 = add('object', {}, 'cils3pd7900003j6jjyxm94e0')
    dataset.objects.$push(object)

    object.properties = add('$COLLECTION')
    property = add('property', {subject: object, predicate: 'hasName', value: 'Mohamad'})
    object.properties.$push(property)
    object.name = property

    property = add('property', {subject: object, predicate: 'hasFriend', object: object2})
    object.properties.$push(property)

    # Expected turtle
    content =
      "@base <http://weaverplatform.com/#> .\n" +
      "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n" +
      "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n" +
      "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n" +
      "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n\n" +

      "<cils31qhi00024dvail7giemn> <hasName> \"Mohamad\"^^xsd:string .\n" +
      "<cils31qhi00024dvail7giemn> <hasFriend> <cils3pd7900003j6jjyxm94e0> ."

    turtle.process(dataset.$id()).should.eventually.equal(content)
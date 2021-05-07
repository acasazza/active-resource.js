# ActiveResource methods for managing attributes of resources
class ActiveResource::Attributes
  # Used to establish attribute fields for a resource class
  # @note Attribute fields are tracked along with relationships using `klass().fields()`
  # @see fields.coffee
  #
  # @example Add attributes
  #   class Order extends MyLibrary.Base {
  #     static define() {
  #       this.attributes('price', 'tax')
  #     }
  #   }
  #
  # @example Retrieve klass attributes
  #   resource.klass().attributes()
  #
  # @param [Array<String>] attributes the attributes to add to the list of attributes the class tracks
  # @return [Collection<String>] the klass attributes
  attributes: (attributes...) ->
    options = {}
    if _.isObject(_.last(attributes))
      options = attributes.pop();

    if !@__attributes?
      @__attributes = {
        all: ActiveResource::Collection.build(),
        read: ActiveResource::Collection.build(),
        readWrite: ActiveResource::Collection.build(),
      }

    if(options.readOnly)
      @__attributes.read.push(attributes...)
    else
      @__attributes.readWrite.push(attributes...)

    @__attributes.all.push(attributes...)

    @__attributes

  # Checks if the resource has an attribute
  #
  # @param [String] attribute the attribute to check the existence of on the resource
  # @return [Boolean] whether or not the resource has the attribute
  @hasAttribute: (attribute) ->
    @__readAttribute(attribute)?

  # Assigns `attributes` to the resource, using @__assignAttributes to allow this method
  #   to be overridden easier
  #
  # @param [Object] attributes the attributes to assign
  @assignAttributes: (attributes) ->
    @__assignAttributes(attributes)

  # Retrieves all the attributes of the resource
  #
  # @return [Object] the attributes of the resource
  @attributes: (options = {}) ->
    output = {}

    for k, v of @
      if @__validAttribute(k, v, options)
        output[k] = v

    output

  # Reloads all the attributes from the server, using saved @__queryParams
  # to ensure proper field and include reloading
  #
  # @example
  #   Order.includes('transactions').last().then (order) ->
  #     order.transactions.last().amount == 3.0 # TRUE
  #
  #     Transaction.find(order.transactions.last().id).then (transaction) ->
  #       transaction.update amount: 5, ->
  #         order.transactions.last().amount == 3.0 # TRUE
  #         order.reload().then ->
  #           order.transactions.last().amount == 5.0 # TRUE
  #
  # @return [Promise] a promise to return the reloaded ActiveResource **or** 404 NOT FOUND
  @reload: ->
    throw 'Cannot reload a resource that is not persisted or has an ID' unless @persisted() || @id?.toString().length > 0

    resource = this
    url = @links()['self'] || (ActiveResource::Links.__constructLink(@links()['related'], @id.toString()))

    @interface().get(url, @queryParams())
    .then (reloaded) ->
      resource.__assignFields(reloaded.attributes())
      resource.klass().reflectOnAllAssociations().each (reflection) ->
        target = reloaded.association(reflection.name).reader()
        target = target.toArray() if reflection.collection?()
        resource.association(reflection.name).writer(target, false)
      resource

  # private

  # Assigns `attributes` to the resource
  #
  # @param [Object] attributes the attributes to assign
  @__assignAttributes: (attributes) ->
    for k, v of attributes
      try
        @association(k).writer(v, false)
      catch
        @[k] = v

    null

  # Reads an attribute on the resource
  #
  # @param [String] attribute the attribute to read
  # @return [Object] the attribute
  @__readAttribute: (attribute) ->
    @attributes()[attribute]

  # Determines whether or not an attribute is a valid attribute on the resource class
  #
  # @note A property is valid to be in `attributes` if it meets these conditions:
  #   1. It must not be a function
  #   2. It must not be a reserved keyword
  #   3. It must not be an association
  #
  # @param [String] attribute the attribute to determine validity for
  # @param [Number,String,Object] value the value for the attribute, relevant for !strictAttributes mode
  # @param [Object] options the options to modify valid attributes with
  @__validAttribute: (attribute, value, options) ->
    reserved = ['__super__', '__associations', '__errors', '__fields', '__immutableId', '__links', '__queryParams']

    if @klass().resourceLibrary.strictAttributes
      if options.readOnly
        @klass().attributes().read.include(attribute)
      else if options.readWrite
        @klass().attributes().readWrite.include(attribute)
      else
        @klass().attributes().all.include(attribute)
    else
      !_.isFunction(value) && !_.includes(reserved, attribute) &&
        try !@association(attribute)? catch e then true

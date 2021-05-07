# Creates a library that holds resources classes
#
# @param [String] baseUrl the base url for the resource server
# @option [Object] headers the headers to send with each request made in this library
# @option [Interface] interface the interface to use when making requests and building responses
# @option [Object] constantizeScope the scope to use when calling #constantize
# @option [Boolean] immutable if true, resources will act as immutable structures
# @option [Boolean] includePolymorphicRepeats if true, primary data’s relationships will send polymorphic owner data to
#   the server despite that data also being the primary data (a repetition, some servers don't make the assumption)
# @option [Boolean] strictAttributes if true, only attributes defined in a class via the static attributes method will
#   be returned from resource.attributes()
# @return [ResourceLibrary] the created resource library
ActiveResource.createResourceLibrary = (baseUrl, options = {}) ->
  _interface = options.interface || ActiveResource.Interfaces.JsonApi

  library = class ResourceLibrary
    constructor: ->
      Object.defineProperties @,
        headers:
          get: () => return @_headers
          set: (value) =>
            @_headers = value
            @interface = new _interface(@)

      @baseUrl =
        if baseUrl.charAt(baseUrl.length - 1) == '/'
          baseUrl
        else
          "#{baseUrl}/"

      @_headers = options.headers
      @interface = new _interface(this)

      @constantizeScope = options['constantizeScope']
      @immutable = options.immutable
      @includePolymorphicRepeats = options.includePolymorphicRepeats
      @strictAttributes = options.strictAttributes

      base =
        if @immutable
          ActiveResource::Immutable::Base
        else
          ActiveResource::Base

      resourceLibrary = this
      @Base = class Base extends base
        this.resourceLibrary = resourceLibrary

    # Constantizes a className string into an actual ActiveResource::Base class
    #
    # @note If constantizeScope is null, checks the property on the resource library
    #
    # @note Throws exception if klass cannot be found
    #
    # @param [String] className the class name to look for a constant with
    # @return [Class] the class constant corresponding to the name provided
    constantize: (className) ->
      klass = null

      if !_.isUndefined(className) && !_.isNull(className)
        scope = @constantizeScope && _.values(@constantizeScope) || _.values(@)
        for v in scope
          klass = v if _.isObject(v) && v.className == className

      throw "NameError: klass #{className} does not exist" unless klass?
      klass

    # Creates an ActiveResource::Base class from klass provided
    #
    # @param [Class] klass the klass to create into an ActiveResource::Base class in the library
    # @return [Class] the klass now inheriting from ActiveResource::Base
    createResource: (klass) ->
      klass.className ||= klass.name
      klass.queryName ||= pluralize(_.snakeCase(klass.className))

      klass.define?()

      (@constantizeScope || @)[klass.className] = klass

      klass

  new library()

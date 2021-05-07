class ActiveResource::Associations::Builder::SingularAssociation extends ActiveResource::Associations::Builder::Association
  # Defines getter/setter methods on the model for the association
  #
  # @param [Class] model the ActiveResource class to apply the association to
  # @param [Reflection] reflection the reflection of the association to build accessors for
  @defineAccessors: (model, reflection) ->
    super(...arguments)
    @defineConstructors(model, reflection.name) if reflection.constructable?()

  # Defines setter methods on the model for the association
  #
  # @param [Class] mixin the class to mix getter methods into
  # @param [String] name the name of the association
  @defineWriters: (mixin, name) ->
    mixin::["assign#{_.capitalize(name)}"] = (value) ->
      @association(name).writer(value, false, true)

    mixin::["update#{_.capitalize(name)}"] = (value) ->
      @association(name).writer(value, true, true)

  # Defines builder methods on the model for the association
  #
  # @note This is only called on associations with reflections that are `constructable?`
  #   Polymorphic reflections are not constructable, because the type is ambiguous
  #
  # @param [Class] mixin the class to mix construction methods into
  # @param [String] name the name of the association
  @defineConstructors: (mixin, name) ->
    mixin::["build#{_.capitalize(name)}"] = (attributes) ->
      @association(name).build(attributes)

    mixin::["create#{_.capitalize(name)}"] = (attributes, callback) ->
      @association(name).create(attributes, callback)

utils = require './utils'
Relationship = require './Relationship'

Class = null

class BelongsToRelationship extends Relationship

  ###*
    Constructs a model relationship

    @since 0.0.7
    @method constructor
    @param {Model} model The model holding the attribute
    @param {String} name The name of the attribute in the model
    @param {Object} config The configuration of the relationship's destination
    @param {String} [config.model] Name of the destination's model
    @param {String} [config.attribute] Name of the destination's attribute
    @param {String} [config.inverse] Name of the destination's property corresponding to the inverse relation
  ###
  constructor: (ownerModel, ownerAttribute, {model, attribute, inverse}) ->
    super model, name, ':belongsTo'



module.exports = Class = BelongsToRelationship

Utils = require './utils'

module.exports = class Component
  element_type: require './element'
  constructor: (element, props) ->
    @__element = element
    @__release_callbacks = []

  bindDom: (node, context) ->
  unbindDom: (node) ->

  setProperty: (name, val) =>
    return unless name of @__element.props
    prop = @__element.props[name]
    return if prop.value is val and not Array.isArray(val)
    old_value = prop.value
    prop.value = val
    Utils.reflect(@__element, prop.attribute, val)
    if prop.notify
      Utils.scheduleMicroTask => @trigger('propertychange', {value: val, old_value, name})

  onPropertyChange: (name, val) ->
  onMounted: ->

  onRelease: =>
    return if @__released
    @__released = true
    callback(@) while callback = @__release_callbacks.pop()
    delete @__element

  wasReleased: => !!@__released

  addReleaseCallback: (fn) => @__release_callbacks.push(fn)

  renderTemplate: (template, context={}) =>
    el = document.createElement('div')
    el.innerHTML = template
    @bindDom(el, context)
    Array::slice.call(el.childNodes)

  ###
  # used by component-element to inject custom template/styles
  ###
  createComponent: (options) =>
    comp = @
    class CustomComponent extends Component
      @tag: 'component-element', @css_scope: options.css_scope
      constructor: ->
        super
        Object.assign(@, options.context) if options.context
      bindDom: comp.bindDom
      unbindDom: comp.unbindDom

    CustomComponent.template = options.template if options.template
    CustomComponent.styles = options.styles if options.styles
    return CustomComponent

    ###############
  # Integration Methods
  # Here to make sure asyncronous operations only last the lifetime of the component

  delay: (delay_time, callback) =>
    [delay_time, callback] = [0, delay_time] if Utils.isFunction(delay_time)
    timer = setTimeout callback, delay_time
    @addReleaseCallback -> clearTimeout(timer)
    return timer

  interval: (delay_time, callback) =>
    timer = setInterval callback, delay_time
    @addReleaseCallback -> clearInterval(timer)
    return timer

  trigger: (name, data) =>
    event = @__element.createEvent(name, {detail: data, bubbles: true, cancelable: true})
    not_cancelled = true
    not_cancelled = !!@__element['on'+name]?(event) if @__element['on'+name]
    not_cancelled and !!@__element.dispatchEvent(event)

  on: (name, handler) =>
    @__element.addEventListener(name, handler)
    @addReleaseCallback => @__element.removeEventListener(name, handler)

  listenTo: (emitter, key, fn) =>
    emitter.on key, fn
    @addReleaseCallback => emitter.off key, fn
